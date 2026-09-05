-- ============================================================
-- Corps Haven — Reports / Flagging feature
-- Run this once in Supabase's SQL Editor (new query).
-- Lets visitors flag a listing as fake/expired/scam; admins
-- review flagged items in admin.html.
-- ============================================================

create table reports (
  id uuid primary key default gen_random_uuid(),
  listing_type text not null check (listing_type in ('housing', 'placement')),
  listing_id uuid not null,
  reason text not null check (char_length(reason) between 3 and 500),
  status text not null default 'open' check (status in ('open', 'dismissed', 'resolved')),
  created_at timestamptz not null default now()
);

alter table reports enable row level security;

create policy "Public can submit reports"
  on reports for insert
  with check (status = 'open');

create policy "Admins can view reports"
  on reports for select
  using (is_admin());

create policy "Admins can update reports"
  on reports for update
  using (is_admin())
  with check (is_admin());
