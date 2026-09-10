-- Phase 3 — Companionship, step 2: Growth Timeline (L7).
-- Run this against the Supabase project (SQL editor or migration tool).

create table if not exists goals (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    title text not null,
    description text,
    status text not null default 'active',
    source text not null default 'user_stated',
    confirmed boolean not null default true,
    memory_fact_id uuid references memory_facts(id) on delete set null,
    target_date date,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists goals_user_id_idx on goals (user_id);

create table if not exists milestones (
    id uuid primary key default gen_random_uuid(),
    goal_id uuid not null references goals(id) on delete cascade,
    user_id uuid not null references users(id) on delete cascade,
    description text not null,
    source text not null default 'user_stated',
    achieved_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists milestones_goal_id_idx on milestones (goal_id);
create index if not exists milestones_user_id_idx on milestones (user_id);
