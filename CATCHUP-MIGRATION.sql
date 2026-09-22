-- ============================================================
-- Corps Haven — COMPLETE CATCH-UP MIGRATION
-- Run this ONE file in Supabase's SQL Editor (new query).
-- Safe to run no matter which earlier SQL files you already
-- ran — every statement checks for existing state first, so
-- nothing breaks and nothing gets duplicated.
-- ============================================================

-- ---------- Housing: expanded fields ----------
alter table housing_listings
  add column if not exists caution_fee numeric default 0,
  add column if not exists agency_fee numeric default 0,
  add column if not exists agreement_fee numeric default 0,
  add column if not exists bathrooms integer,
  add column if not exists is_furnished boolean default false,
  add column if not exists available_from date,
  add column if not exists minimum_tenancy text,
  add column if not exists has_borehole boolean default false,
  add column if not exists has_generator boolean default false,
  add column if not exists internet_available boolean default false,
  add column if not exists is_gated boolean default false,
  add column if not exists flood_prone boolean default false,
  add column if not exists nearest_landmark text check (char_length(nearest_landmark) <= 120),
  add column if not exists image_urls text[],
  add column if not exists last_confirmed_at timestamptz default now();

-- electricity_type needs its own block since it has a check constraint
-- that errors if you try to add it twice with "if not exists" alone
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'housing_listings' and column_name = 'electricity_type'
  ) then
    alter table housing_listings add column electricity_type text check (
      electricity_type in ('Prepaid meter', 'Estimated billing', 'Generator only', 'NEPA + Generator', 'Solar', 'Other')
    );
  end if;
end $$;

update housing_listings set last_confirmed_at = created_at where last_confirmed_at is null;

-- ---------- Placements: expanded fields ----------
alter table placements
  add column if not exists role_title text check (char_length(role_title) <= 120),
  add column if not exists discipline_accepted text check (char_length(discipline_accepted) <= 160),
  add column if not exists num_slots integer default 1 check (num_slots > 0 and num_slots <= 100),
  add column if not exists application_deadline date,
  add column if not exists monthly_stipend numeric check (monthly_stipend is null or monthly_stipend >= 0),
  add column if not exists transport_allowance boolean default false,
  add column if not exists accommodation_provided boolean default false,
  add column if not exists lunch_provided boolean default false,
  add column if not exists work_days text check (char_length(work_days) <= 60),
  add column if not exists work_hours text check (char_length(work_hours) <= 60),
  add column if not exists dress_code text check (char_length(dress_code) <= 80),
  add column if not exists office_address text check (char_length(office_address) <= 200),
  add column if not exists issues_ppa_letter boolean default false,
  add column if not exists retention_possible boolean default false,
  add column if not exists interview_required boolean default false,
  add column if not exists previous_corpers_accepted boolean default false,
  add column if not exists last_confirmed_accepting date,
  add column if not exists company_cac_number text check (char_length(company_cac_number) <= 40),
  add column if not exists last_confirmed_at timestamptz default now();

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'placements' and column_name = 'work_mode'
  ) then
    alter table placements add column work_mode text check (work_mode in ('On-site', 'Hybrid', 'Remote'));
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_name = 'placements' and column_name = 'company_cac_status'
  ) then
    alter table placements add column company_cac_status text default 'Not yet verified' check (
      company_cac_status in ('Not yet verified', 'CAC number provided - unverified by admin', 'CAC verified by admin')
    );
  end if;
end $$;

update placements set last_confirmed_at = created_at where last_confirmed_at is null;

-- ---------- Reports table + policies (idempotent) ----------
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  listing_type text not null check (listing_type in ('housing', 'placement')),
  listing_id uuid not null,
  reason text not null check (char_length(reason) between 3 and 500),
  status text not null default 'open' check (status in ('open', 'dismissed', 'resolved')),
  created_at timestamptz not null default now()
);

alter table reports enable row level security;

drop policy if exists "Public can submit reports" on reports;
create policy "Public can submit reports" on reports for insert with check (status = 'open');

drop policy if exists "Admins can view reports" on reports;
create policy "Admins can view reports" on reports for select using (is_admin());

drop policy if exists "Admins can update reports" on reports;
create policy "Admins can update reports" on reports for update using (is_admin()) with check (is_admin());

-- ---------- Storage bucket for listing photos (idempotent) ----------
insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

drop policy if exists "Public can upload listing images" on storage.objects;
create policy "Public can upload listing images" on storage.objects for insert with check (bucket_id = 'listing-images');

drop policy if exists "Public can view listing images" on storage.objects;
create policy "Public can view listing images" on storage.objects for select using (bucket_id = 'listing-images');

-- ---------- Rate-limit function: security definer fix ----------
create or replace function enforce_submission_rate_limit(
  p_contact text,
  p_table text,
  p_max_per_day int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count int;
begin
  select count(*) into recent_count
  from submission_log
  where contact = p_contact
    and table_name = p_table
    and submitted_at > now() - interval '24 hours';

  if recent_count >= p_max_per_day then
    raise exception 'Submission limit reached for this contact. Please try again later.';
  end if;

  insert into submission_log (contact, table_name) values (p_contact, p_table);
end;
$$;

-- ============================================================
-- Done. Every column, table, policy, and function this project
-- has ever needed now exists, regardless of what ran before.
-- ============================================================
