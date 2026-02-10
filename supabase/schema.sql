-- ============================================
-- LOOK & COOK - SUPABASE DATABASE SCHEMA
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  profile_image_url TEXT,
  bio TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  recipe_ids TEXT[] DEFAULT '{}',
  follower_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  recipe_count INTEGER DEFAULT 0,
  is_admin BOOLEAN DEFAULT FALSE
);

-- Index for search
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_follower_count ON users(follower_count DESC);

-- 2. RECIPES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  image_url TEXT,
  video_url TEXT,
  ingredients TEXT[] DEFAULT '{}',
  instructions TEXT[] DEFAULT '{}',
  cook_time INTEGER DEFAULT 0,
  servings INTEGER DEFAULT 1,
  author_id UUID REFERENCES users(id) ON DELETE CASCADE,
  author_name TEXT,
  average_rating DECIMAL(3,2) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_recipes_author_id ON recipes(author_id);
CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category);
CREATE INDEX IF NOT EXISTS idx_recipes_average_rating ON recipes(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_favorite_count ON recipes(favorite_count DESC);

-- 3. REVIEWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT,
  rating DECIMAL(2,1) CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(recipe_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_recipe_id ON reviews(recipe_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);

-- 4. RECIPE LIKES TABLE (Beğenme - Kalp)
-- ============================================
CREATE TABLE IF NOT EXISTS recipe_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(recipe_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_recipe_likes_recipe_id ON recipe_likes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_likes_user_id ON recipe_likes(user_id);

-- 5. USER FAVORITES TABLE (Kaydetme - Bookmark)
-- ============================================
CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(recipe_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_favorites_recipe_id ON user_favorites(recipe_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);

-- 6. FOLLOWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function: Increment recipe views
CREATE OR REPLACE FUNCTION increment_recipe_views(recipe_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE recipes SET view_count = view_count + 1 WHERE id = recipe_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Update recipe like count
CREATE OR REPLACE FUNCTION update_recipe_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE recipes SET like_count = like_count + 1 WHERE id = NEW.recipe_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE recipes SET like_count = like_count - 1 WHERE id = OLD.recipe_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_like_count
AFTER INSERT OR DELETE ON recipe_likes
FOR EACH ROW EXECUTE FUNCTION update_recipe_like_count();

-- Function: Update recipe favorite count
CREATE OR REPLACE FUNCTION update_recipe_favorite_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE recipes SET favorite_count = favorite_count + 1 WHERE id = NEW.recipe_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE recipes SET favorite_count = favorite_count - 1 WHERE id = OLD.recipe_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_favorite_count
AFTER INSERT OR DELETE ON user_favorites
FOR EACH ROW EXECUTE FUNCTION update_recipe_favorite_count();

-- Function: Update user follower/following counts
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    UPDATE users SET follower_count = follower_count + 1 WHERE id = NEW.following_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET following_count = following_count - 1 WHERE id = OLD.follower_id;
    UPDATE users SET follower_count = follower_count - 1 WHERE id = OLD.following_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_follow_counts
AFTER INSERT OR DELETE ON follows
FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Function: Update user recipe count
CREATE OR REPLACE FUNCTION update_user_recipe_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET recipe_count = recipe_count + 1 WHERE id = NEW.author_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET recipe_count = recipe_count - 1 WHERE id = OLD.author_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_recipe_count
AFTER INSERT OR DELETE ON recipes
FOR EACH ROW EXECUTE FUNCTION update_user_recipe_count();

-- Function: Update recipe rating after review
CREATE OR REPLACE FUNCTION update_recipe_rating()
RETURNS TRIGGER AS $$
DECLARE
  avg_rating DECIMAL(3,2);
  total_reviews INTEGER;
BEGIN
  SELECT AVG(rating), COUNT(*) INTO avg_rating, total_reviews
  FROM reviews WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);

  UPDATE recipes
  SET average_rating = COALESCE(avg_rating, 0),
      review_count = total_reviews
  WHERE id = COALESCE(NEW.recipe_id, OLD.recipe_id);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_recipe_rating
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_recipe_rating();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid()::text = id::text);
CREATE POLICY "Anyone can insert users" ON users FOR INSERT WITH CHECK (true);

-- Recipes policies
CREATE POLICY "Recipes are viewable by everyone" ON recipes FOR SELECT USING (true);
CREATE POLICY "Users can insert own recipes" ON recipes FOR INSERT WITH CHECK (auth.uid()::text = author_id::text);
CREATE POLICY "Users can update own recipes" ON recipes FOR UPDATE USING (auth.uid()::text = author_id::text);
CREATE POLICY "Users can delete own recipes" ON recipes FOR DELETE USING (auth.uid()::text = author_id::text);

-- Reviews policies
CREATE POLICY "Reviews are viewable by everyone" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can insert own reviews" ON reviews FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid()::text = user_id::text);
CREATE POLICY "Users can delete own reviews" ON reviews FOR DELETE USING (auth.uid()::text = user_id::text);

-- Recipe likes policies
CREATE POLICY "Likes are viewable by everyone" ON recipe_likes FOR SELECT USING (true);
CREATE POLICY "Users can like recipes" ON recipe_likes FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "Users can unlike recipes" ON recipe_likes FOR DELETE USING (auth.uid()::text = user_id::text);

-- User favorites policies
CREATE POLICY "Favorites are viewable by everyone" ON user_favorites FOR SELECT USING (true);
CREATE POLICY "Users can add favorites" ON user_favorites FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "Users can remove favorites" ON user_favorites FOR DELETE USING (auth.uid()::text = user_id::text);

-- Follows policies
CREATE POLICY "Follows are viewable by everyone" ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON follows FOR INSERT WITH CHECK (auth.uid()::text = follower_id::text);
CREATE POLICY "Users can unfollow others" ON follows FOR DELETE USING (auth.uid()::text = follower_id::text);

-- ============================================
-- DONE! Tabloları Supabase Dashboard'da kontrol edin.
-- ============================================
