// Caspr — AI Summarisation Edge Function
// Fetches transcript → sends to Claude API → saves structured summary

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUMMARISATION_PROMPT = `You are summarising a meeting transcript. Extract:

1. **Meeting Summary** — 3-5 sentence overview of what was discussed
2. **Key Decisions** — Bullet list of decisions made (with who decided if clear)
3. **Action Items** — Bullet list with [Owner] and [Due date if mentioned]
4. **Follow-ups** — Topics that need further discussion
5. **Parking Lot** — Ideas or topics raised but intentionally deferred

Keep language concise and professional. Use Australian English spelling.
Preserve speaker names/labels if present in the transcript.

Respond ONLY with valid JSON in this exact format:
{
  "overview": "3-5 sentence summary...",
  "decisions": ["Decision 1", "Decision 2"],
  "action_items": [{"text": "Action description", "owner": "Person name or null", "due_date": "Date or null"}],
  "follow_ups": ["Topic 1", "Topic 2"],
  "parking_lot": ["Deferred idea 1"]
}`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY")!;

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    const supabaseUser = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Verify user
    const {
      data: { user },
      error: authError,
    } = await supabaseUser.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check user tier (summaries are Pro only)
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("tier")
      .eq("id", user.id)
      .single();

    if (!profile || profile.tier === "free") {
      return new Response(
        JSON.stringify({ error: "AI summaries require a Pro subscription" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request
    const { recording_id } = await req.json();
    if (!recording_id) {
      return new Response(
        JSON.stringify({ error: "Missing recording_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify recording belongs to user
    const { data: recording, error: recError } = await supabaseAdmin
      .from("recordings")
      .select("id, user_id, title")
      .eq("id", recording_id)
      .single();

    if (recError || !recording || recording.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "Recording not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Fetch transcript
    const { data: transcript, error: txError } = await supabaseAdmin
      .from("transcripts")
      .select("full_text, segments")
      .eq("recording_id", recording_id)
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (txError || !transcript) {
      return new Response(
        JSON.stringify({ error: "No transcript found for this recording" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Build formatted transcript for Claude
    let formattedTranscript = "";
    if (transcript.segments && Array.isArray(transcript.segments)) {
      for (const seg of transcript.segments) {
        const time = formatTime(seg.startTime ?? 0);
        const speaker = seg.speaker ? `${seg.speaker}: ` : "";
        formattedTranscript += `[${time}] ${speaker}${seg.text}\n`;
      }
    } else {
      formattedTranscript = transcript.full_text;
    }

    // Call Claude API
    const claudeResponse = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 2048,
          messages: [
            {
              role: "user",
              content: `${SUMMARISATION_PROMPT}\n\n--- TRANSCRIPT ---\n\n${formattedTranscript}`,
            },
          ],
        }),
      }
    );

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      console.error("[Caspr] Claude API error:", errorText);
      return new Response(
        JSON.stringify({ error: "Summarisation failed", details: errorText }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const claudeResult = await claudeResponse.json();
    const assistantMessage = claudeResult.content?.[0]?.text ?? "";

    // Parse Claude's JSON response
    let summary;
    try {
      // Extract JSON from response (Claude might wrap it in markdown code blocks)
      const jsonMatch = assistantMessage.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error("No JSON found in response");
      summary = JSON.parse(jsonMatch[0]);
    } catch (parseError) {
      console.error("[Caspr] Failed to parse Claude response:", assistantMessage);
      return new Response(
        JSON.stringify({
          error: "Failed to parse summary",
          details: String(parseError),
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Save summary to database
    const { data: savedSummary, error: insertError } = await supabaseAdmin
      .from("summaries")
      .insert({
        recording_id,
        overview: summary.overview ?? "",
        decisions: summary.decisions ?? [],
        action_items: summary.action_items ?? [],
        follow_ups: summary.follow_ups ?? [],
        parking_lot: summary.parking_lot ?? [],
        model: "claude-sonnet-4-5-20250929",
      })
      .select()
      .single();

    if (insertError) {
      console.error("[Caspr] DB insert error:", insertError);
      return new Response(
        JSON.stringify({
          error: "Failed to save summary",
          details: insertError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[Caspr] Summary complete: ${recording_id}`);

    return new Response(
      JSON.stringify({
        summary_id: savedSummary.id,
        overview: summary.overview,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("[Caspr] Summarise function error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}
