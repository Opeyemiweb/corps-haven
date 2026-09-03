-- ============================================================
-- Corps Haven — FULL SETUP (paste this whole file, run once)
-- ============================================================
-- This clears any old tables from your earlier attempt, builds
-- the full production schema, and registers
-- danielopeyemi1954@gmail.com as your super_admin.
-- ============================================================

-- 000: CLEAN SLATE — remove anything from earlier versions
drop table if exists housing_listings cascade;
drop table if exists placements cascade;
drop table if exists admin_emails cascade;
drop table if exists admin_users cascade;
drop table if exists submission_log cascade;
drop function if exists is_admin();
drop function if exists is_super_admin();
drop function if exists current_admin_email();
drop function if exists set_updated_at();
drop function if exists enforce_submission_rate_limit(text, text, int);
drop function if exists review_housing(uuid, text, text);
drop function if exists review_placement(uuid, text, text);

-- ============================================================


-- ============================================================
-- 001: EXTENSIONS
-- ============================================================
create extension if not exists pgcrypto; -- gen_random_uuid()


-- ============================================================
-- 002: ADMIN ROLES
-- Two tiers: moderators can approve/reject; super_admins can
-- also hard-delete and manage other admins.
-- ============================================================
create table admin_users (
  email text primary key,
  role text not null default 'moderator' check (role in ('moderator', 'super_admin')),
  created_at timestamptz not null default now()
);

-- Add your first admin manually after running this file:
-- insert into admin_users (email, role) values ('you@example.com', 'super_admin');

create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from admin_users where email = auth.jwt() ->> 'email'
  );
$$;

create or replace function is_super_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from admin_users
    where email = auth.jwt() ->> 'email' and role = 'super_admin'
  );
$$;

create or replace function current_admin_email()
returns text
language sql
security definer
stable
as $$
  select auth.jwt() ->> 'email';
$$;


-- ============================================================
-- 003: SHARED TRIGGER — auto-update `updated_at`
-- ============================================================
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ============================================================
-- 004: RATE LIMITING
-- Blocks spam submissions from the same contact within a
-- rolling 24-hour window. Adjust the limits to taste.
-- ============================================================
create table submission_log (
  id uuid primary key default gen_random_uuid(),
  contact text not null,       -- phone or email used for the submission
  table_name text not null,
  submitted_at timestamptz not null default now()
);

create index idx_submission_log_contact_time
  on submission_log (contact, submitted_at desc);

create or replace function enforce_submission_rate_limit(
  p_contact text,
  p_table text,
  p_max_per_day int
)
returns void
language plpgsql
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
-- 005: HOUSING LISTINGS
-- ============================================================
create table housing_listings (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 3 and 120),
  description text check (char_length(description) <= 2000),
  area text not null check (char_length(area) between 2 and 80),
  price numeric not null check (price > 0 and price < 100000000),
  house_type text not null check (
    house_type in ('Self-contain', '1 Bedroom', '2 Bedroom', '3 Bedroom', 'Shared Apartment', 'Other')
  ),
  contact_phone text not null check (contact_phone ~ '^\+?[0-9]{10,14}$'),
  image_url text,

  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by text,               -- admin email who last actioned this
  reviewed_at timestamptz,
  rejection_reason text,

  deleted_at timestamptz,         -- soft delete: null = active

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_housing_updated_at
  before update on housing_listings
  for each row execute function set_updated_at();

create index idx_housing_status on housing_listings (status) where deleted_at is null;
create index idx_housing_area on housing_listings (area) where deleted_at is null;
create index idx_housing_created_at on housing_listings (created_at desc) where deleted_at is null;

alter table housing_listings enable row level security;

create policy "Public can view approved housing"
  on housing_listings for select
  using ((status = 'approved' and deleted_at is null) or is_admin());

create policy "Public can submit housing as pending"
  on housing_listings for insert
  with check (status = 'pending');

create policy "Admins can update housing"
  on housing_listings for update
  using (is_admin())
  with check (is_admin());

create policy "Super admins can hard-delete housing"
  on housing_listings for delete
  using (is_super_admin());


-- ============================================================
-- 006: PLACEMENTS
-- ============================================================
create table placements (
  id uuid primary key default gen_random_uuid(),
  company_name text not null check (char_length(company_name) between 2 and 120),
  industry text not null check (char_length(industry) between 2 and 80),
  role_description text not null check (char_length(role_description) <= 2000),
  area text not null check (char_length(area) between 2 and 80),
  requirements text check (char_length(requirements) <= 1000),
  contact_phone text check (contact_phone ~ '^\+?[0-9]{10,14}$'),
  contact_email text check (contact_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),

  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by text,
  reviewed_at timestamptz,
  rejection_reason text,

  deleted_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint has_contact_method check (contact_phone is not null or contact_email is not null)
);

create trigger trg_placements_updated_at
  before update on placements
  for each row execute function set_updated_at();

create index idx_placements_status on placements (status) where deleted_at is null;
create index idx_placements_area on placements (area) where deleted_at is null;
create index idx_placements_created_at on placements (created_at desc) where deleted_at is null;

alter table placements enable row level security;

create policy "Public can view approved placements"
  on placements for select
  using ((status = 'approved' and deleted_at is null) or is_admin());

create policy "Public can submit placements as pending"
  on placements for insert
  with check (status = 'pending');

create policy "Admins can update placements"
  on placements for update
  using (is_admin())
  with check (is_admin());

create policy "Super admins can hard-delete placements"
  on placements for delete
  using (is_super_admin());


-- ============================================================
-- 007: REVIEW HELPER FUNCTIONS
-- Call these from your admin panel instead of raw updates —
-- they stamp reviewed_by / reviewed_at automatically so you
-- always have an audit trail of who approved or rejected what.
-- ============================================================
create or replace function review_housing(
  p_id uuid,
  p_status text,
  p_reason text default null
)
returns void
language plpgsql
security invoker
as $$
begin
  if not is_admin() then
    raise exception 'Not authorized';
  end if;

  update housing_listings
  set status = p_status,
      reviewed_by = current_admin_email(),
      reviewed_at = now(),
      rejection_reason = p_reason
  where id = p_id;
end;
$$;

create or replace function review_placement(
  p_id uuid,
  p_status text,
  p_reason text default null
)
returns void
language plpgsql
security invoker
as $$
begin
  if not is_admin() then
    raise exception 'Not authorized';
  end if;

  update placements
  set status = p_status,
      reviewed_by = current_admin_email(),
      reviewed_at = now(),
      rejection_reason = p_reason
  where id = p_id;
end;
$$;

-- ============================================================
-- 008: REGISTER YOUR ADMIN ACCOUNT
-- ============================================================
insert into admin_users (email, role) values ('danielopeyemi1954@gmail.com', 'super_admin');

-- ============================================================
-- 009: IMAGE STORAGE
-- Creates a public storage bucket for housing listing photos,
-- and lets anyone upload to it (submissions) while only the
-- public bucket read stays open (viewing photos).
-- ============================================================
insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

create policy "Public can upload listing images"
  on storage.objects for insert
  with check (bucket_id = 'listing-images');

create policy "Public can view listing images"
  on storage.objects for select
  using (bucket_id = 'listing-images');
