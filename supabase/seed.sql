-- Caspr — Seed Data for Development
-- Note: Run this AFTER migrations. Uses a test user UUID.

-- Test user profile (must match an auth.users entry in your Supabase dashboard)
-- Create a test user via Supabase Auth dashboard first, then use their UUID here.
-- INSERT INTO public.profiles (id, email, full_name, tier, cloud_minutes_limit)
-- VALUES (
--     '00000000-0000-0000-0000-000000000001',
--     'test@caspr.app',
--     'Test User',
--     'pro',
--     600  -- 10 hours = 600 minutes
-- );

-- Example recording
-- INSERT INTO public.recordings (id, user_id, title, duration_seconds)
-- VALUES (
--     '10000000-0000-0000-0000-000000000001',
--     '00000000-0000-0000-0000-000000000001',
--     'Team Standup — March 10',
--     1845
-- );

-- Example transcript
-- INSERT INTO public.transcripts (recording_id, full_text, segments, source)
-- VALUES (
--     '10000000-0000-0000-0000-000000000001',
--     'Good morning everyone. Let''s go through our updates...',
--     '[{"startTime": 0.0, "endTime": 3.5, "text": "Good morning everyone.", "speaker": "Speaker 1"}, {"startTime": 3.5, "endTime": 7.2, "text": "Let''s go through our updates.", "speaker": "Speaker 1"}]'::jsonb,
--     'cloud'
-- );

-- Uncomment and adjust UUIDs after creating a test user in Supabase Auth.
