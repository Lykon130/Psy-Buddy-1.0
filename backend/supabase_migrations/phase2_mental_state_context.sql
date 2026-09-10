-- Phase 2 — Understanding: mental state vector, context fusion support.
-- Run this against the Supabase project (SQL editor or migration tool).

create table if not exists mental_states (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    session_id text,
    source text not null default 'chat',       -- 'chat' | 'journal'
    valence float not null default 0.0,        -- -1.0 .. 1.0
    stress float not null default 0.0,         -- 0.0 .. 1.0
    arousal float not null default 0.0,        -- 0.0 .. 1.0
    trend text not null default 'insufficient_data',
    trend_delta float not null default 0.0,
    timestamp timestamptz not null default now()
);

create index if not exists mental_states_user_id_idx on mental_states (user_id);
create index if not exists mental_states_user_id_timestamp_idx on mental_states (user_id, timestamp desc);
