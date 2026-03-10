-- Caspr — Initial Database Schema
-- Creates core tables: profiles, recordings, transcripts, summaries

-- Profiles (extends auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    full_name TEXT,
    tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'team')),
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    cloud_minutes_used INTEGER NOT NULL DEFAULT 0,
    cloud_minutes_limit INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recordings
CREATE TABLE public.recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    audio_storage_path TEXT,
    is_cloud_synced BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Transcripts
CREATE TABLE public.transcripts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES public.recordings ON DELETE CASCADE NOT NULL,
    full_text TEXT NOT NULL DEFAULT '',
    segments JSONB DEFAULT '[]'::jsonb,
    source TEXT NOT NULL DEFAULT 'local' CHECK (source IN ('local', 'cloud')),
    language TEXT NOT NULL DEFAULT 'en',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Summaries
CREATE TABLE public.summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES public.recordings ON DELETE CASCADE NOT NULL,
    overview TEXT NOT NULL DEFAULT '',
    decisions JSONB DEFAULT '[]'::jsonb,
    action_items JSONB DEFAULT '[]'::jsonb,
    follow_ups JSONB DEFAULT '[]'::jsonb,
    parking_lot JSONB DEFAULT '[]'::jsonb,
    model TEXT NOT NULL DEFAULT 'claude-sonnet-4-5-20250929',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for common queries
CREATE INDEX idx_recordings_user_id ON public.recordings (user_id);
CREATE INDEX idx_recordings_created_at ON public.recordings (created_at DESC);
CREATE INDEX idx_transcripts_recording_id ON public.transcripts (recording_id);
CREATE INDEX idx_summaries_recording_id ON public.summaries (recording_id);

-- Updated_at trigger for profiles
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();
