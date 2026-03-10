// Caspr — Stripe Webhook Edge Function
// Handles subscription lifecycle events from Stripe

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";

serve(async (req) => {
  try {
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY")!;
    const stripeWebhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2023-10-16" });
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify webhook signature
    const body = await req.text();
    const signature = req.headers.get("stripe-signature");

    if (!signature) {
      return new Response("Missing signature", { status: 400 });
    }

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        body,
        signature,
        stripeWebhookSecret
      );
    } catch (err) {
      console.error("[Caspr] Webhook signature verification failed:", err);
      return new Response("Invalid signature", { status: 400 });
    }

    console.log(`[Caspr] Webhook event: ${event.type}`);

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.subscription
          ? (
              await stripe.subscriptions.retrieve(
                session.subscription as string
              )
            ).metadata.supabase_user_id
          : session.metadata?.supabase_user_id;

        if (userId) {
          await supabaseAdmin
            .from("profiles")
            .update({
              tier: "pro",
              stripe_subscription_id: session.subscription as string,
              cloud_minutes_limit: 600, // 10 hours = 600 minutes
              cloud_minutes_used: 0,
            })
            .eq("id", userId);

          console.log(`[Caspr] User ${userId} upgraded to Pro`);
        }
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata.supabase_user_id;

        if (userId) {
          const isActive = ["active", "trialing"].includes(
            subscription.status
          );

          await supabaseAdmin
            .from("profiles")
            .update({
              tier: isActive ? "pro" : "free",
              stripe_subscription_id: subscription.id,
              cloud_minutes_limit: isActive ? 600 : 0,
            })
            .eq("id", userId);

          console.log(
            `[Caspr] Subscription updated for ${userId}: ${subscription.status}`
          );
        }
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata.supabase_user_id;

        if (userId) {
          await supabaseAdmin
            .from("profiles")
            .update({
              tier: "free",
              stripe_subscription_id: null,
              cloud_minutes_limit: 0,
            })
            .eq("id", userId);

          console.log(`[Caspr] User ${userId} downgraded to Free`);
        }
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        const subscriptionId = invoice.subscription as string;

        if (subscriptionId) {
          const subscription =
            await stripe.subscriptions.retrieve(subscriptionId);
          const userId = subscription.metadata.supabase_user_id;

          if (userId) {
            console.log(
              `[Caspr] Payment failed for user ${userId} — subscription ${subscriptionId}`
            );
            // Don't immediately downgrade — Stripe will retry.
            // Downgrade happens on customer.subscription.deleted
          }
        }
        break;
      }

      default:
        console.log(`[Caspr] Unhandled event type: ${event.type}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[Caspr] Webhook error:", err);
    return new Response(
      JSON.stringify({ error: "Webhook handler failed" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
