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
*The layer everything else depends on.*

**Structured memory**
- [x] Design 2-tier memory model: working/session memory + explicit user-confirmed facts — session history stays in `chats`; durable facts move to `memory_facts`
- [x] Replace single-text-blob memory store with structured schema — old single-blob `global_memory` session replaced by `backend/app/memory/` (`memory_facts` table)
- [x] Add confidence/provenance fields to stored memory items — `MemoryFact.confidence` (float) + `source` ("user_stated"|"inferred") in `backend/app/memory/models.py`
- [x] Build user-facing memory view (visible, deletable per the contract's consent principle) — `frontend/lib/screens/memory_settings_screen.dart`
- [ ] **Editable** is not yet exposed in the UI — `PATCH /memory/{username}/{fact_id}` exists in `backend/app/memory/routes.py` (`MemoryFactUpdate`), but `memory_settings_screen.dart` only offers view + delete, no edit affordance

**Minimal Crisis Safety Core (L17)**
- [x] Define risk keyword/phrase list + classifier-based risk flag on incoming messages — `backend/app/safety/keywords.py` + `assess_risk()` in `safety/service.py`
- [x] Build static crisis-resource response (forces Empath persona, surfaces professional help resources) — `CRISIS_RESPONSE_TEXT` in `safety/service.py`
- [x] Wire risk flag into the message pipeline ahead of persona/LLM response — `assess_risk` runs before `get_ai_response` in `chat/routes.py`
- [x] Add escalation/logging path for flagged messages (internal monitoring, not user-facing diagnosis) — `log_safety_event()` writes to `safety_events`

**Consent UX**
- [x] Add in-app explanation of what gets remembered and why — intro card in `memory_settings_screen.dart`
- [x] Add ability to view/delete stored memory from settings — done (see editable gap above)

**Still open before calling Phase 1 fully closed:**
- [ ] Apply `phase1_memory_safety.sql` to the live Supabase project (creates `memory_facts` + `safety_events`) — confirm it's actually been run, since Phase 2's migration is still pending as of this writing
- [ ] Expose fact editing in `memory_settings_screen.dart` (backend endpoint already exists)
- [ ] Run an end-to-end verification pass: confirm a crisis-phrase message forces Empath + logs to `safety_events`, and that facts stated in chat appear/are deletable in the Memory & Privacy screen

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
