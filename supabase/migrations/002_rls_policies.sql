-- Caspr — Row Level Security Policies
-- Users can only access their own data

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transcripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.summaries ENABLE ROW LEVEL SECURITY;

-- Profiles: users see and update only their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Recordings: users CRUD only their own recordings
CREATE POLICY "Users can view own recordings"
    ON public.recordings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recordings"
    ON public.recordings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recordings"
    ON public.recordings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own recordings"
    ON public.recordings FOR DELETE
    USING (auth.uid() = user_id);

-- Transcripts: users access only transcripts for their recordings
CREATE POLICY "Users can view own transcripts"
    ON public.transcripts FOR SELECT
    USING (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own transcripts"
    ON public.transcripts FOR INSERT
    WITH CHECK (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own transcripts"
    ON public.transcripts FOR UPDATE
    USING (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own transcripts"
    ON public.transcripts FOR DELETE
    USING (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

-- Summaries: users access only summaries for their recordings
CREATE POLICY "Users can view own summaries"
    ON public.summaries FOR SELECT
    USING (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own summaries"
    ON public.summaries FOR INSERT
    WITH CHECK (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own summaries"
    ON public.summaries FOR UPDATE
    USING (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own summaries"
    ON public.summaries FOR DELETE
    USING (
        recording_id IN (
            SELECT id FROM public.recordings WHERE user_id = auth.uid()
        )
    );

-- Service role bypass: Edge Functions use the service_role key
-- which bypasses RLS automatically — no extra policies needed.
