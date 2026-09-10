# PSYCHE / PsyBuddy — Phase-Wise To-Do List

Companion checklist to [`PSYCHE_Engine_Roadmap.md`](./PSYCHE_Engine_Roadmap.md). Check items off as they land; this file is the working tracker, the roadmap doc is the reasoning behind it. Last updated: September 2026.

---

## Phase 0 — Stabilize (now)
*No new capability — make what exists safe and consistent.*

- [ ] Rotate Supabase database password
- [ ] Rotate Google OAuth web client secret
- [ ] Rotate Facebook app secret
- [ ] Scrub `Documents/Configurations.odt` from git history (initial commit + both `.kilo/worktrees/` copies) — confirm collaborators/remotes before rewriting history
- [ ] Add `Configurations.odt` (or a redacted template) to `.gitignore` going forward
- [ ] Reconcile persona system prompts to non-clinical "Relational Intelligence" language — drop "mental health assistant," "psychiatrist-informed," and diagnostic-sounding copy
- [ ] Implement `frontend/lib/widgets/chat_bubble.dart` (currently empty)
- [ ] Implement `frontend/lib/widgets/persona_toggle.dart` (currently empty)

---

## Phase 1 — Foundation
*The layer everything else depends on. Zero coverage today.*

**Structured memory**
- [ ] Design 2-tier memory model: working/session memory + explicit user-confirmed facts
- [ ] Replace single-text-blob memory store with structured schema
- [ ] Add confidence/provenance fields to stored memory items
- [ ] Build user-facing memory view (visible, editable, deletable per the contract's consent principle)

**Minimal Crisis Safety Core (L17)**
- [ ] Define risk keyword/phrase list + classifier-based risk flag on incoming messages
- [ ] Build static crisis-resource response (forces Empath persona, surfaces professional help resources)
- [ ] Wire risk flag into the message pipeline ahead of persona/LLM response
- [ ] Add escalation/logging path for flagged messages (internal monitoring, not user-facing diagnosis)

**Consent UX**
- [ ] Add in-app explanation of what gets remembered and why
- [ ] Add ability to view/delete stored memory from settings

---

## Phase 2 — Understanding
*Stop treating each signal in isolation; replace the single mood label with a real state vector.*

- [x] Build Context Fusion (L2): combine emotion + journal + mood into one per-turn context packet — `backend/app/context/`
- [x] Replace single 0.2–0.9 mood score with a Mental State vector (stress, valence, trend over time) — `backend/app/mental_states/`, `supabase_migrations/phase2_mental_state_context.sql`
- [x] Extend `utils/bert_emotion_api.py` output to feed the fused context packet — full label distribution + distribution-weighted valence/arousal via `utils/emotion_vad.py`
- [x] Build a lightweight Cognitive Core / orchestrator that selects persona + retrieval scope (replacing pure client-side persona selection) — `backend/app/orchestrator/`, rule-based
- [x] Decide and implement: manual persona toggle stays primary, orchestrator offers *suggestions* only (per decision #3) — `suggested_persona`/`suggested_retrieval_scope` returned advisory-only in `/chat/` response, never overrides client-selected or crisis-forced persona

**Still open before calling Phase 2 fully closed:**
- [ ] Apply `phase2_mental_state_context.sql` to the live Supabase project
- [ ] Run the end-to-end verification pass against a running server (crisis/negative/positive message cases, trend-over-time check, journal → mental_states feed, `mood_logs` regression check)

---

## Phase 3 — Companionship
*Continuity across sessions, and a way for the system to judge its own replies.*

- [ ] Identity/preference modeling (L5) — track stable user traits/preferences separate from session state
- [ ] Growth Timeline data model — goals, milestones, recurring journal themes (L7)
- [ ] Growth Timeline UI — surface goals/milestones in the dashboard
- [ ] Intervention Planner (L8) — basic strategy selection beyond raw persona choice
- [ ] Emotional Simulation pass (L9) before response generation
- [ ] Self-reflection scoring on response quality (L12) — extend the `continuous_trainer.py` pattern from emotion-only to dialogue quality

---

## Phase 4 — Depth & Scale
*Heavily gated. Everything here is internal reasoning only, never a surfaced diagnosis.*

- [ ] Predictive burnout/stress trend forecasting — internal hypotheses only, hedged language, never shown as a score or diagnosis
- [ ] Semantic/vector memory via FAISS (matches existing architecture diagrams)
- [ ] Offline mode (local SQLite storage path)
- [ ] Sync engine (offline → cloud reconciliation)
- [ ] Push notification system
- [ ] Enterprise-grade security: API gateway, RBAC, audit log, encryption-at-rest, tenant isolation
- [ ] **Explicitly out of scope pending separate legal/clinical review:** IQ / MMPI / MCMI-style psychological testing suite (decision #5)

---

## Open decisions blocking downstream work

These aren't tasks — they're calls that gate the phases above. See §4 of the roadmap doc for full reasoning.

- [ ] **Decision 1:** Confirm non-clinical framing as the permanent product language (blocks Phase 0 prompt fix)
- [ ] **Decision 2:** Approve 2-tier memory model shape (blocks Phase 1 memory work)
- [ ] **Decision 3:** Confirm manual persona selection stays primary through Phase 2 (blocks orchestrator scope)
- [ ] **Decision 4:** Confirm Crisis Safety Core is top priority over personality/prediction/testing (blocks Phase 1 vs. Phase 3/4 sequencing)
- [ ] **Decision 5:** Confirm psychological testing suite stays out of scope pending legal/clinical review (blocks any Phase 4 testing work)
