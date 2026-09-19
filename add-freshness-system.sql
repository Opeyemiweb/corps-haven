-- ============================================================
-- Corps Haven — Listing freshness system
-- Run this once in Supabase's SQL Editor (new query).
-- Adds a "last confirmed" timestamp to both tables. Public
-- pages will only show listings confirmed within the last
-- 30 days (housing) / 45 days (placements) — enforced by the
-- app's queries, not by deleting anything.
-- ============================================================

alter table housing_listings
  add column if not exists last_confirmed_at timestamptz default now();

alter table placements
  add column if not exists last_confirmed_at timestamptz default now();

-- Backfill: for any listing that already exists, treat its
-- original creation date as its last confirmation, so nothing
-- disappears unexpectedly the moment this runs.
update housing_listings set last_confirmed_at = created_at where last_confirmed_at is null;
update placements set last_confirmed_at = created_at where last_confirmed_at is null;
