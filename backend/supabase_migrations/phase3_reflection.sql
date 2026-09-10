-- Phase 3 — Companionship, step 5: Self-reflection scoring (L12).
-- Observability only in this phase — not yet wired into automatic
-- retraining. Run this against the Supabase project (SQL editor or
-- migration tool).

create table if not exists response_scores (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    session_id text,
    message_id uuid,
    persona text,
    risk_flagged boolean not null default false,
    empathy_score float,
    relevance_score float,
    persona_consistency_score float,
    protocol_adherence_score float,
    created_at timestamptz not null default now()
);

create index if not exists response_scores_user_id_idx on response_scores (user_id);
