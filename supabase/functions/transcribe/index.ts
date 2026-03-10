// Caspr — Cloud Transcription Edge Function
// Downloads audio from Storage → sends to Deepgram → saves transcript to DB

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
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

    // Create Supabase client with user's JWT
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const deepgramApiKey = Deno.env.get("DEEPGRAM_API_KEY")!;

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    const supabaseUser = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Get user from JWT
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

    // Check cloud minutes
    const { data: hasMinutes } = await supabaseAdmin.rpc("has_cloud_minutes", {
      p_user_id: user.id,
    });
    if (!hasMinutes) {
      return new Response(
        JSON.stringify({ error: "Cloud transcription minutes exhausted" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const { recording_id, audio_storage_path } = await req.json();
    if (!recording_id || !audio_storage_path) {
      return new Response(
        JSON.stringify({ error: "Missing recording_id or audio_storage_path" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Download audio from Supabase Storage
    const { data: audioData, error: downloadError } =
      await supabaseAdmin.storage
        .from("recordings")
        .download(audio_storage_path);

    if (downloadError || !audioData) {
      return new Response(
        JSON.stringify({
          error: "Failed to download audio",
          details: downloadError?.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Send to Deepgram for transcription
    const audioBuffer = await audioData.arrayBuffer();

    const deepgramResponse = await fetch(
      "https://api.deepgram.com/v1/listen?" +
        new URLSearchParams({
          model: "nova-2",
          language: "en-AU",
          punctuate: "true",
          diarize: "true",
          utterances: "true",
          smart_format: "true",
        }),
      {
        method: "POST",
        headers: {
          Authorization: `Token ${deepgramApiKey}`,
          "Content-Type": "audio/mp4",
        },
        body: audioBuffer,
      }
    );

    if (!deepgramResponse.ok) {
      const errorText = await deepgramResponse.text();
      console.error("[Caspr] Deepgram error:", errorText);
      return new Response(
        JSON.stringify({
          error: "Transcription failed",
          details: errorText,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const deepgramResult = await deepgramResponse.json();

    // Extract transcript data from Deepgram response
    const utterances = deepgramResult.results?.utterances ?? [];
    const fullText =
      deepgramResult.results?.channels?.[0]?.alternatives?.[0]?.transcript ??
      "";

    // Build segments from utterances (includes speaker labels)
    const segments = utterances.map(
      (u: {
        start: number;
        end: number;
        transcript: string;
        speaker: number;
        confidence: number;
      }) => ({
        startTime: u.start,
        endTime: u.end,
        text: u.transcript,
        speaker: `Speaker ${u.speaker + 1}`,
        confidence: u.confidence,
      })
    );

    // Calculate duration in minutes for billing
    const durationSeconds =
      deepgramResult.metadata?.duration ?? 0;
    const durationMinutes = Math.ceil(durationSeconds / 60);

    // Save transcript to database
    const { data: transcript, error: insertError } = await supabaseAdmin
      .from("transcripts")
      .insert({
        recording_id,
        full_text: fullText,
        segments,
        source: "cloud",
        language: "en",
      })
      .select()
      .single();

    if (insertError) {
      console.error("[Caspr] DB insert error:", insertError);
      return new Response(
        JSON.stringify({
          error: "Failed to save transcript",
          details: insertError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Increment cloud minutes used
    await supabaseAdmin.rpc("increment_cloud_minutes", {
      p_user_id: user.id,
      p_minutes: durationMinutes,
    });

    console.log(
      `[Caspr] Transcription complete: ${recording_id} (${durationMinutes} min)`
    );

    return new Response(
      JSON.stringify({
        transcript_id: transcript.id,
        duration_minutes: durationMinutes,
        segment_count: segments.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("[Caspr] Transcribe function error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
