-- Caspr — Database Functions & Triggers

-- Auto-create a profile row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, tier, cloud_minutes_limit)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
        'free',
        0  -- free tier gets 0 cloud minutes
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Increment cloud transcription minutes used
CREATE OR REPLACE FUNCTION public.increment_cloud_minutes(
    p_user_id UUID,
    p_minutes INTEGER
)
RETURNS void AS $$
BEGIN
    UPDATE public.profiles
    SET cloud_minutes_used = cloud_minutes_used + p_minutes,
        updated_at = now()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has remaining cloud minutes
CREATE OR REPLACE FUNCTION public.has_cloud_minutes(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_used INTEGER;
    v_limit INTEGER;
    v_tier TEXT;
BEGIN
    SELECT cloud_minutes_used, cloud_minutes_limit, tier
    INTO v_used, v_limit, v_tier
    FROM public.profiles
    WHERE id = p_user_id;

    -- Free tier has no cloud minutes
    IF v_tier = 'free' THEN
        RETURN false;
    END IF;

    -- Team tier has unlimited
    IF v_tier = 'team' THEN
        RETURN true;
    END IF;

    -- Pro tier: check against limit
    RETURN v_used < v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reset cloud minutes (called monthly by cron or webhook)
CREATE OR REPLACE FUNCTION public.reset_cloud_minutes()
RETURNS void AS $$
BEGIN
    UPDATE public.profiles
    SET cloud_minutes_used = 0,
        updated_at = now()
    WHERE tier IN ('pro', 'team');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create Supabase Storage bucket for audio files
INSERT INTO storage.buckets (id, name, public)
VALUES ('recordings', 'recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies: users can upload/download their own audio files
CREATE POLICY "Users can upload own audio"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'recordings'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view own audio"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'recordings'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete own audio"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'recordings'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Service role can access all audio (for edge functions)
CREATE POLICY "Service role can access all audio"
    ON storage.objects FOR ALL
    USING (bucket_id = 'recordings' AND auth.role() = 'service_role');
