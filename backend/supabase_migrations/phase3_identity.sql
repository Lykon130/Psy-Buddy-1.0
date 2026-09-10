-- Phase 3 — Companionship, step 1: Identity/preference modeling (L5).
-- Run this against the Supabase project (SQL editor or migration tool).

create table if not exists identity_profile (
    user_id uuid primary key references users(id) on delete cascade,
    communication_style text,
    default_persona_preference text,
    topics_to_avoid text[] not null default '{}',
    coping_preferences text[] not null default '{}',
    updated_at timestamptz not null default now()
);
