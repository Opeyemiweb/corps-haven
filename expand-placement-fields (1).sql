-- ============================================================
-- Corps Haven — Expand placements with richer fields
-- Run this once in Supabase's SQL Editor (new query).
-- Every new column is optional/defaulted, so existing listings
-- are unaffected — they'll just show blank/default values.
-- ============================================================

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
  add column if not exists work_mode text check (work_mode in ('On-site', 'Hybrid', 'Remote')),
  add column if not exists dress_code text check (char_length(dress_code) <= 80),
  add column if not exists office_address text check (char_length(office_address) <= 200),
  add column if not exists issues_ppa_letter boolean default false,
  add column if not exists retention_possible boolean default false,
  add column if not exists interview_required boolean default false,
  add column if not exists previous_corpers_accepted boolean default false,
  add column if not exists last_confirmed_accepting date,
  add column if not exists company_cac_number text check (char_length(company_cac_number) <= 40),
  add column if not exists company_cac_status text default 'Not yet verified' check (
    company_cac_status in ('Not yet verified', 'CAC number provided - unverified by admin', 'CAC verified by admin')
  );
