-- ============================================
-- LOOK & COOK - STORAGE BUCKET POLICIES
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- 1. CREATE BUCKETS (Dashboard > Storage > Create Bucket ile de yapabilirsiniz)
-- ============================================

-- Profile Images Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Recipe Images Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'recipe-images',
  'recipe-images',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Recipe Videos Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'recipe-videos',
  'recipe-videos',
  true,
  104857600, -- 100MB
  ARRAY['video/mp4', 'video/quicktime', 'video/webm']
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. STORAGE POLICIES
-- ============================================

-- Profile Images Policies
CREATE POLICY "Profile images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

CREATE POLICY "Users can upload profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete their profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

-- Recipe Images Policies
CREATE POLICY "Recipe images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'recipe-images');

CREATE POLICY "Users can upload recipe images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'recipe-images'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their recipe images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'recipe-images'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete their recipe images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'recipe-images'
  AND auth.role() = 'authenticated'
);

-- Recipe Videos Policies
CREATE POLICY "Recipe videos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'recipe-videos');

CREATE POLICY "Users can upload recipe videos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'recipe-videos'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their recipe videos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'recipe-videos'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete their recipe videos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'recipe-videos'
  AND auth.role() = 'authenticated'
);

-- ============================================
-- DONE! Storage bucketları Supabase Dashboard'da kontrol edin.
-- ============================================
