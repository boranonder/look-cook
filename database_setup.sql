-- ============================================
-- LOOK & COOK - DATABASE SETUP
-- Bu SQL'i Supabase SQL Editor'da calistir
-- ============================================

-- ============================================
-- 1. TABLOLAR
-- ============================================

-- Users tablosu (zaten varsa atla)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  profile_image_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  follower_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  recipe_count INTEGER DEFAULT 0,
  is_admin BOOLEAN DEFAULT FALSE
);

-- Recipes tablosu (zaten varsa atla)
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  ingredients TEXT[] DEFAULT '{}',
  instructions TEXT[] DEFAULT '{}',
  image_url TEXT,
  author_id UUID REFERENCES users(id) ON DELETE CASCADE,
  author_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  average_rating DECIMAL(3,2) DEFAULT 0.0,
  review_count INTEGER DEFAULT 0,
  category TEXT DEFAULT 'evYemekleri',
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  tags TEXT[] DEFAULT '{}'
);

-- Reviews tablosu
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT,
  rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(recipe_id, user_id)
);

-- Follows tablosu (TAKIP SISTEMI)
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- User Favorites tablosu (KAYDETME SISTEMI)
CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, recipe_id)
);

-- Recipe Likes tablosu (BEGENI SISTEMI)
CREATE TABLE IF NOT EXISTS recipe_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(recipe_id, user_id)
);

-- ============================================
-- 2. INDEXLER (Performans icin)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_recipes_author_id ON recipes(author_id);
CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category);
CREATE INDEX IF NOT EXISTS idx_recipes_average_rating ON recipes(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_recipe_id ON reviews(recipe_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_recipe_id ON user_favorites(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_likes_recipe_id ON recipe_likes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_likes_user_id ON recipe_likes(user_id);

-- ============================================
-- 3. TRIGGER FUNCTIONS
-- ============================================

-- Follow count trigger function
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET follower_count = follower_count + 1 WHERE id = NEW.following_id;
    UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET follower_count = GREATEST(follower_count - 1, 0) WHERE id = OLD.following_id;
    UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Favorite count trigger function
CREATE OR REPLACE FUNCTION update_favorite_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE recipes SET favorite_count = favorite_count + 1 WHERE id = NEW.recipe_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE recipes SET favorite_count = GREATEST(favorite_count - 1, 0) WHERE id = OLD.recipe_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Like count trigger function
CREATE OR REPLACE FUNCTION update_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE recipes SET like_count = like_count + 1 WHERE id = NEW.recipe_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE recipes SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.recipe_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Recipe count trigger function (when user adds/removes recipe)
CREATE OR REPLACE FUNCTION update_recipe_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET recipe_count = recipe_count + 1 WHERE id = NEW.author_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET recipe_count = GREATEST(recipe_count - 1, 0) WHERE id = OLD.author_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- View count RPC function
CREATE OR REPLACE FUNCTION increment_recipe_views(p_recipe_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE recipes SET view_count = view_count + 1 WHERE id = p_recipe_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. TRIGGERS
-- ============================================

-- Drop existing triggers if they exist (to avoid duplicates)
DROP TRIGGER IF EXISTS trigger_follow_counts ON follows;
DROP TRIGGER IF EXISTS trigger_favorite_count ON user_favorites;
DROP TRIGGER IF EXISTS trigger_like_count ON recipe_likes;
DROP TRIGGER IF EXISTS trigger_recipe_count ON recipes;

-- Create triggers
CREATE TRIGGER trigger_follow_counts
AFTER INSERT OR DELETE ON follows
FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

CREATE TRIGGER trigger_favorite_count
AFTER INSERT OR DELETE ON user_favorites
FOR EACH ROW EXECUTE FUNCTION update_favorite_count();

CREATE TRIGGER trigger_like_count
AFTER INSERT OR DELETE ON recipe_likes
FOR EACH ROW EXECUTE FUNCTION update_like_count();

CREATE TRIGGER trigger_recipe_count
AFTER INSERT OR DELETE ON recipes
FOR EACH ROW EXECUTE FUNCTION update_recipe_count();

-- ============================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_likes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users are viewable by everyone" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

DROP POLICY IF EXISTS "Recipes are viewable by everyone" ON recipes;
DROP POLICY IF EXISTS "Users can insert own recipes" ON recipes;
DROP POLICY IF EXISTS "Users can update own recipes" ON recipes;
DROP POLICY IF EXISTS "Users can delete own recipes" ON recipes;

DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON reviews;
DROP POLICY IF EXISTS "Users can insert own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON reviews;

DROP POLICY IF EXISTS "Follows are viewable by everyone" ON follows;
DROP POLICY IF EXISTS "Users can follow others" ON follows;
DROP POLICY IF EXISTS "Users can unfollow" ON follows;

DROP POLICY IF EXISTS "Favorites are viewable by owner" ON user_favorites;
DROP POLICY IF EXISTS "Users can add favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can remove favorites" ON user_favorites;

DROP POLICY IF EXISTS "Likes are viewable by everyone" ON recipe_likes;
DROP POLICY IF EXISTS "Users can like recipes" ON recipe_likes;
DROP POLICY IF EXISTS "Users can unlike recipes" ON recipe_likes;

-- Users policies
CREATE POLICY "Users are viewable by everyone" ON users
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Recipes policies
CREATE POLICY "Recipes are viewable by everyone" ON recipes
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own recipes" ON recipes
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own recipes" ON recipes
  FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own recipes" ON recipes
  FOR DELETE USING (auth.uid() = author_id);

-- Reviews policies
CREATE POLICY "Reviews are viewable by everyone" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own reviews" ON reviews
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews" ON reviews
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews" ON reviews
  FOR DELETE USING (auth.uid() = user_id);

-- Follows policies
CREATE POLICY "Follows are viewable by everyone" ON follows
  FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow" ON follows
  FOR DELETE USING (auth.uid() = follower_id);

-- User favorites policies
CREATE POLICY "Favorites are viewable by owner" ON user_favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add favorites" ON user_favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove favorites" ON user_favorites
  FOR DELETE USING (auth.uid() = user_id);

-- Recipe likes policies
CREATE POLICY "Likes are viewable by everyone" ON recipe_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like recipes" ON recipe_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike recipes" ON recipe_likes
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 6. STORAGE BUCKETS (Supabase Dashboard'dan olustur)
-- ============================================
-- Bu bucketlari Supabase Dashboard > Storage > New bucket ile olustur:
-- 1. profile-images (Public)
-- 2. recipe-images (Public)
-- 3. recipe-videos (Public)

-- ============================================
-- KURULUM TAMAMLANDI!
-- ============================================
-- Simdi uygulamayi test edebilirsin.
-- Herhangi bir hata olursa bu SQL'i tekrar calistirabilirsin.
