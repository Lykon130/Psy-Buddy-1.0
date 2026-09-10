-- Phase 1 — Foundation: structured memory + minimal crisis safety core.
-- Run this against the Supabase project (SQL editor or migration tool).

create table if not exists memory_facts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    fact_text text not null,
    category text not null default 'other',
    confidence float not null default 0.5,
    source text not null default 'inferred',
    session_id text,
    confirmed boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists memory_facts_user_id_idx on memory_facts (user_id);

create table if not exists safety_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    session_id text,
    matched_terms text[] not null default '{}',
    severity text not null default 'medium',
    timestamp timestamptz not null default now()
);

create index if not exists safety_events_user_id_idx on safety_events (user_id);
