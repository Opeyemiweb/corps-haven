-- ============================================================
-- Corps Haven — Expand housing_listings with richer fields
-- Run this once in Supabase's SQL Editor (new query).
-- Every new column is optional/defaulted, so existing listings
-- are unaffected — they'll just show blank/default values.
-- ============================================================

alter table housing_listings
  add column if not exists caution_fee numeric default 0,
  add column if not exists agency_fee numeric default 0,
  add column if not exists agreement_fee numeric default 0,
  add column if not exists bathrooms integer,
  add column if not exists is_furnished boolean default false,
  add column if not exists available_from date,
  add column if not exists minimum_tenancy text,
  add column if not exists electricity_type text check (
    electricity_type in ('Prepaid meter', 'Estimated billing', 'Generator only', 'NEPA + Generator', 'Solar', 'Other')
  ),
  add column if not exists has_borehole boolean default false,
  add column if not exists has_generator boolean default false,
  add column if not exists internet_available boolean default false,
  add column if not exists is_gated boolean default false,
  add column if not exists flood_prone boolean default false,
  add column if not exists nearest_landmark text check (char_length(nearest_landmark) <= 120);
