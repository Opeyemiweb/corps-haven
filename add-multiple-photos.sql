-- ============================================================
-- Corps Haven — Support multiple photos per housing listing
-- Run this once in Supabase's SQL Editor (new query).
-- Keeps the old image_url column for backward compatibility
-- (older listings still work); new submissions populate both.
-- ============================================================

alter table housing_listings
  add column if not exists image_urls text[];
