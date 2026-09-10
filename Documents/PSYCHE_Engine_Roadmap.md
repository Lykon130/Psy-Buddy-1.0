# PSYCHE Engine — Unified Architecture & Roadmap

Prepared from: `PSYCHE Research.pdf`, `PsyBuddy 2.0.pdf` (+ `psybuddy_master_document.pdf`, `Architecture Design.png`), `PsyBuddy_2_Relational_Intelligence_Architecture_and_Product_Vision.docx`, and a line-by-line audit of the live codebase at `D:\Psy-Buddy-1.0`. Last updated: September 2026.

This is a living document — update it as scope decisions get made and phases land. The companion checklist is [`PHASE_TODO.md`](./PHASE_TODO.md).

---

## 1. The synthesis: what "merging" actually means

The three source documents aren't three different products — they're three passes at the same idea, at different levels of abstraction and different points in the thinking behind it:

- **`PSYCHE Research.pdf` is the cognitive engine** — an 18-layer, 6-zone reasoning architecture (perception → psychological modeling → cognitive reasoning → intervention planning → learning → safety/governance) with academic grounding (SOAR, ACT-R, affective computing) and a competitive novelty analysis. It answers *"how does the brain work?"*
- **`PsyBuddy 2.0.pdf` (+ its diagrams) is an early product spec** built on that brain — it names the same capabilities in product terms (Emotion AI, Personality AI, Predictive Engine, Triple Persona) and adds the delivery layer: Flutter/FastAPI/MongoDB/FAISS, psychological testing, offline mode, training datasets. It answers *"what do we ship, and on what stack?"*
- **The Relational Intelligence docx is a later, more careful rewrite** of the same product (v0.1) that keeps almost all the same capabilities but wraps them in an explicit safety/consent contract, and deliberately drops clinical/diagnostic language (*"we do not diagnose a person"*, non-clinical support). It answers *"what is this system allowed to claim, and what guardrails does every layer need?"*

So the merge isn't "pick one." **PSYCHE is the engine. PsyBuddy (per the docx) is the product contract** that governs what the engine is allowed to surface and how. Internally, the system can still model stress, mood trends, and risk signals with real depth (that's PSYCHE's job) — but externally, per the docx, those signals stay hypotheses (*"does this feel related?"*), never diagnoses, and every durable memory stays visible/editable/deletable by the user.

This single principle resolves the one real conflict between the docs: the PDF's "Predictive Mental Health Engine" and "psychiatrist-informed" language, and PSYCHE's "Mental Health Forecast," are both fine to build — as long as they're internal reasoning aids that route into calibrated, hedged, user-correctable output, never a labeled diagnosis or score shown to the user as fact.

---

## 2. Unified architecture map

Each PSYCHE layer, matched to its product-layer name in the docx and its module name in the PDF, plus its actual status in `D:\Psy-Buddy-1.0` today.

| PSYCHE layer (zone) | docx platform layer | PDF "AI Brain" module | Codebase status |
|---|---|---|---|
| L1 Multimodal Perception (Perception) | Interaction Layer | Emotion AI | **Partial** — text-only GoEmotions classifier (`utils/bert_emotion_api.py`); no voice/behavioral/vision signals |
| L2 Context Fusion (Perception) | Understanding Layer | — | **Partial (Phase 2)** — `backend/app/context/service.py::build_context_packet` fuses current emotion + Mental State vector + recent journal themes + confirmed memory facts + risk flag into one per-turn `ContextPacket`; no cognitive-load/motivation signals yet |
| L3 Cognitive Core (Cognitive Reasoning) | Cognitive Layer | Custom PsyBuddy LLM | **Partial (Phase 3)** — still a single OpenRouter call, no retrieval-based reasoning, but it's no longer a bare pass-through: `get_ai_response` now takes a `strategy_guidance` list (from L8/L9 below) folded into the system prompt, still exactly one call per turn |
| L4 Mental State Engine (Psych. Modeling) | Understanding/Relational Layer | Emotion AI (mental_state, stress_index) | **Partial (Phase 2)** — `backend/app/mental_states/service.py` computes a real vector (valence, stress, arousal, trend) per turn from the emotion distribution and persists it to `mental_states`; the old single 0.2–0.9 `mood_logs` score is kept only for backward compat, not superseded in the UI yet; no cognitive-load/motivation dimensions |
| L5 Identity Modeling (Psych. Modeling) | Relational Layer (Profile) | Personality AI | **Partial (Phase 3)** — `backend/app/identity/` derives a single structured `identity_profile` row (communication style, default persona preference, topics to avoid, coping preferences) from the user's *confirmed* memory facts via an LLM aggregation pass, re-run whenever the confirmed set changes; read-only "About you" card in `memory_settings_screen.dart` |
| L6 Trust Model (Psych. Modeling) | — (implicit in consent) | — | **Not started** |
| L7 Life Direction Model (Psych. Modeling) | Relational Layer (Growth Timeline) | — | **Partial (Phase 3)** — `backend/app/growth/` adds `goals`/`milestones` tables; `category="goal"` memory facts seed a draft goal that only becomes real once the user confirms it in the new `growth_timeline_screen.dart` (separate consent step from confirming the underlying fact) |
| L8 Intervention Planner (Intervention) | Cognitive Layer (Orchestrator) | Persona Control Layer | **Partial (Phase 3)** — `backend/app/intervention/` rule-based selector (mirrors the L10 orchestrator's deterministic style) picks one of 6 strategies (reflective_listening, grounding_exercise, goal_check_in, reframe, validate_and_normalize, psychoeducation_light) from the fused context + active goals, folded into the reply prompt as guidance — still not retrieval- or plan-driven |
| L9 Emotional Simulation (Intervention) | Response contract | Safety AI (implicit) | **Partial (Phase 3), scoped down** — `backend/app/simulation/` is a cheap rule-based tone/hedging check (persona vs. mental state mismatch), not the draft-then-critique loop the layer name implies; deliberate scope cut to avoid a second LLM call per turn |
| L10 Persona Router (Cognitive Reasoning) | Mode selection (Orchestrator) | Persona Control Layer | **Partial (Phase 2)** — 3 persona system prompts (Empath/Coach/Friend) exist and remain user-selectable/primary; a new rule-based orchestrator (`backend/app/orchestrator/service.py`) computes a `suggested_persona` + `suggested_retrieval_scope` from the fused context packet and returns it in the `/chat/` response, but it is advisory-only and never overrides the client's choice (per decision #3) |
| L11 Response Generation (Cognitive Reasoning) | Response contract | Custom PsyBuddy LLM | **Working** — functional, but ungrounded (no retrieval, no safety pass) |
| L12 Self-Reflection (Learning) | Evaluation framework | — | **Partial (Phase 3)** — `backend/app/reflection/` scores every assistant reply in the background on empathy markers, user/reply word-overlap relevance, crisis-protocol adherence, and persona consistency, storing to `response_scores`. Heuristic only (no LLM judge yet), and observability-only — not yet wired into automatic prompt/rule refinement |
| L13 Meta-Learning (Learning) | — | — | **Partial** — `continuous_trainer.py` re-fine-tunes the emotion classifier on the user's own labeled chat/journal text; a real, working sliver of self-improvement, just scoped to emotion detection, not dialogue quality |
| L14 Hybrid Memory (crosscutting) | Relational Memory | Memory Engine | **Partial (Phase 1)** — structured `memory_facts` store (`backend/app/memory/`) replaced the single-blob approach: per-fact `category`, `confidence`, `source` (provenance), `confirmed` flag; visible + deletable + editable via `frontend/lib/screens/memory_settings_screen.dart`. Still no vector/semantic store despite FAISS being in the architecture diagrams (deferred to Phase 4) |
| L15 Predictive Mental Health Engine (Safety/Governance) | explicitly deferred (docx "what will not ship early") | Predictive Engine | **Not started** — correctly matches docx's own phasing |
| L16 Cognitive Load Monitor (Learning) | — | — | **Not started** |
| L17 Crisis Safety Core (Safety/Governance) | Safety Layer | Safety AI / Crisis Detection | **Partial (Phase 1)** — keyword/phrase-based `assess_risk()` (`backend/app/safety/`) runs ahead of the persona/LLM call, forces Empath, returns a static crisis-resource response, and logs to `safety_events` for internal monitoring. Still keyword-only (no classifier), no human escalation workflow beyond the log table. The onboarding disclaimer (`disclaimer_screen.dart`) remains as the separate legal notice it always was |
| L18 Ethical Governance (Safety/Governance) | Privacy & Governance sections | Security & Privacy System | **Not started** — and worse than absent: `Documents/Configurations.odt` has live Supabase/OAuth/Facebook secrets committed to git (see §5) |
| Enterprise Foundation (docx-only) | Enterprise Foundation | Cross-Platform Architecture | **Partial** — JWT auth + Supabase exist; no API gateway, RBAC, audit log, encryption-at-rest, or tenant isolation |

---

## 3. Status by the numbers

- **Working today:** text-based emotion detection with a real continual-fine-tuning loop, 3-persona chat via an LLM, basic journal/dream/mood CRUD, JWT auth, a one-time legal disclaimer, a Flutter shell across chat/journal/dream/mood screens.
- **Stubbed or too thin to count as "built":** memory (a single string), persona selection (static, not orchestrated), mental state (one label, not a vector), two empty frontend widgets (`chat_bubble.dart`, `persona_toggle.dart`).
- **Not started at all:** identity modeling, trust modeling, life/goal tracking, intervention planning, emotional simulation, self-reflection/meta-learning on dialogue quality, cognitive load monitoring, predictive mental-health engine, crisis safety core, ethical governance, offline mode, sync engine, push notifications, semantic/vector memory, psychological testing suite.
- **Actively broken / urgent:** live credentials committed to git in `Documents/Configurations.odt` (Supabase password, Google OAuth client secret, Facebook app secret) — see §5.

**Rough read:** of PSYCHE's 18 layers, 2 are genuinely working (Response Generation, and the emotion-classifier's continual learning), 4 are partial/stub (Perception, Cognitive Core, Persona Router, Memory), and 12 are not started. The product is closer to "a persona-flavored chatbot with an emotion tag" than to either vision document right now — completely normal for this stage, but worth seeing plainly.

*(Snapshot above predates Phase 1, 2, and 3 — see §2's per-layer status for current state of L2/L4/L5/L7/L8/L9/L10/L12/L14/L17. Phase 1 (structured memory, crisis safety core, consent UX), Phase 2 (Context Fusion, Mental State vector, extended emotion output, rule-based orchestrator), and Phase 3 (identity profile, Growth Timeline, Intervention Planner, Emotional Simulation, self-reflection scoring) have all landed in code, but none has confirmed its Supabase migration applied to the live project or an end-to-end run against a live server — that step is deliberately on hold pending Supabase credentials; see `PHASE_TODO.md`'s "still open"/migration items under each phase. Phase 1's memory view now has its edit affordance built.)*

---

## 4. Decisions to make before building further

Forks where the three documents disagree or leave a gap, and where the product owner's call is needed rather than an assumption.

1. **Framing.** Commit to the docx's non-clinical "Relational Intelligence" language everywhere (rewrite the persona prompt that currently says "a mental health assistant," drop "psychiatrist-informed" and diagnostic-sounding copy), while keeping PSYCHE's deeper modeling as internal-only machinery. *Recommended — the only version of the merge that avoids real regulatory/liability exposure for a solo/small project.*
2. **Memory architecture.** Move from the single text blob to at least a 2-tier model (working continuity + explicit/user-confirmed facts) before adding anything else — nearly every other layer (identity, trust, growth) depends on memory having structure.
3. **Orchestrator vs. persona toggle.** Decide whether persona selection stays a manual user choice (simpler, ships faster) or becomes intent/risk-driven per the docx's Conversation Orchestrator (more ambitious, needs L3/L4/L8 first). *Recommended — keep manual selection for now and layer light automatic suggestions later, rather than blocking on a full orchestrator.*
4. **Safety layer priority.** Given this product touches mood/emotion data, treat L17 (Crisis Safety Core) as the single highest-priority new capability to build — even a simple keyword/classifier-based risk flag plus a static crisis-resource response — before adding personality modeling, prediction, or testing modules. *Recommended — right now there is no safety net in the conversation path at all, only a one-time disclaimer at signup.*
5. **Predictive/testing modules.** The PDF's psychological testing suite (IQ/MMPI/MCMI-style tests) is the highest-liability item in any of the three docs. *Recommended — flag this as something to explicitly scope out or heavily caveat rather than build as described; administering clinical-style assessments without professional oversight is a different risk category from journaling/mood tracking.*

---

## 5. Immediate priorities (do these first, regardless of the above)

1. **Rotate every credential in `Documents/Configurations.odt`** (Supabase password, Google OAuth web client secret, Facebook app secret) and scrub the file from git history — it's in the initial commit and duplicated under two `.kilo/worktrees/` paths. This isn't part of the architecture merge, it's live exposure.
2. **Reconcile the persona system prompt language** with whichever framing you pick in decision #1 above — quick fix, immediate consistency win.
3. **Fill the two empty frontend stubs** (`chat_bubble.dart`, `persona_toggle.dart`) — small, but currently blocking a coherent chat UI.

---

## 6. Recommended merged roadmap

Folds the docx's 4-phase roadmap (Core → Mind → Companion → Studio) and the PDF's 7-phase build plan into one sequence, adjusted for what's already built.

### Phase 0 — Stabilize (now)
Rotate secrets, remove them from git history, reconcile safety language, fill UI stubs. No new capabilities — just making what exists safe and consistent.

### Phase 1 — Foundation (≈ docx "PsyBuddy Core" / PDF Phase 1–2)
Structured memory (session / working / explicit tiers), a minimal Crisis Safety Core (keyword + classifier-based risk flag → static resource response, overriding persona), consent UX for what's remembered. This is the layer everything else depends on, and it's also the layer with zero coverage today.

### Phase 2 — Understanding (≈ docx "PsyBuddy Mind" / PSYCHE Perception + Psych. Modeling zones)
Context Fusion (L2) combining emotion + journal + mood into one per-turn context packet; a real Mental State vector (stress, valence, trend) instead of a single label; a lightweight Cognitive Core / orchestrator that chooses persona and retrieval scope instead of the client picking it.

### Phase 3 — Companionship (≈ docx "PsyBuddy Companion" / PSYCHE Intervention + Identity zones)
Identity/preference modeling, Growth Timeline (goals, milestones, journal themes), Intervention Planner + Emotional Simulation before responses, self-reflection scoring on response quality (extending the pattern `continuous_trainer.py` already proves works for emotion).

### Phase 4 — Depth & Scale (≈ PDF's advanced modules, heavily gated)
Predictive signals (burnout/stress trend forecasting, framed as internal hypotheses only, never shown as diagnosis), semantic/vector memory (FAISS, as the diagrams already plan), offline mode + sync, enterprise-grade security (KMS, audit, tenant isolation). **Psychological testing suite deliberately left out of this roadmap pending a separate legal/clinical review** — see decision #5.

---

## 7. Phase 3 detailed design (Companionship)

Decided 2026-09: close Phase 1/2's open items first (blocked on live Supabase credentials — see `PHASE_TODO.md`), build Phase 3 data-layers-before-reasoning, and ship Emotional Simulation (L9) as a tone/hedging pass rather than a draft-then-critique loop. Each module follows the `models.py` / `service.py` / `routes.py` shape already used by `memory/`, `mental_states/`, `context/`, `orchestrator/`, wired into `chat/routes.py` the same way.

**Build order:** Identity (L5) → Growth Timeline (L7, data + UI) → Intervention Planner (L8) → Emotional Simulation (L9) → Self-reflection scoring (L12). Each stage has a working output the next stage can read.

### 7.1 Identity/preference modeling (L5) — `backend/app/identity/`
- Single-row-per-user `identity_profile` table (structured fields, not a list) — distinct from `memory_facts`: memory facts are discrete/raw, identity is the aggregated, stable profile derived from them. Candidate fields: `communication_style` (direct/gentle/humorous/…), `default_persona_preference`, `topics_to_avoid: list[str]`, `coping_preferences: list[str]`, `updated_at`.
- Populated by a periodic/background aggregation over confirmed `memory_facts` (categories `preference`/`identity`) — reuse the extraction-call pattern already in `memory/service.py` rather than inventing a new one.
- Exposed read-only in a new "About you" section of `memory_settings_screen.dart` to start (edit affordance can follow once the shape is validated).

### 7.2 Growth Timeline (L7) — data model + UI
- `goals` table: `id, user_id, title, description, status (active/completed/archived), created_at, target_date`.
- `milestones` table: `id, goal_id, user_id, description, achieved_at, source (user_stated/inferred)`.
- Chat-driven capture: extend `store_new_facts`'s extraction pass so `category="goal"` facts can seed a *draft* goal, promoted to a real row only on user confirmation (mirrors the existing `confirmed` flag pattern on `memory_facts`) — keeps the consent contract consistent.
- New `growth_timeline_screen.dart`: list of active goals with their milestones, simple add/complete/archive actions. Reachable from the sidebar next to Memory & Privacy.

### 7.3 Intervention Planner (L8) — `backend/app/intervention/`
- Rule-based (same style as `orchestrator/service.py`), not LLM-based, to start. Input: `ContextPacket` + `identity_profile` + active goals + the orchestrator's existing suggestion. Output: `InterventionPlan{strategy, rationale, focus}`.
- Small fixed playbook to start: `reflective_listening`, `grounding_exercise`, `goal_check_in`, `reframe`, `validate_and_normalize`, `psychoeducation_light`.
- The chosen strategy is injected into the persona system prompt as guidance text (same mechanism `confirmed_facts` already uses in `gpt_service.get_ai_response`) — it *steers* the single LLM call, it doesn't replace it or add a round-trip.

### 7.4 Emotional Simulation (L9) — `backend/app/simulation/`, tone/hedging pass only
- Per the scope decision: no second generation round-trip. A rule-based check (mirrors `orchestrator`'s deterministic style) over `InterventionPlan` + `MentalStateVector` flags foreseeable mismatches — e.g. an upbeat `coach`-toned strategy against very negative valence gets a "could land as dismissive, soften" note.
- Output is one more guidance string folded into the same prompt-assembly step as §7.3 — still exactly one LLM call per turn.
- Explicitly deferred: an actual draft-then-critique loop (second LLM pass simulating user reaction to a drafted reply) — revisit only if the cheap heuristic proves too crude in practice.

### 7.5 Self-reflection scoring (L12) — `backend/app/reflection/`
- Extends the `continuous_trainer.py` pattern (already proven for the emotion classifier) to dialogue quality instead of building a new pattern from scratch.
- Background task (same `BackgroundTasks` mechanism `store_new_facts` already uses in `chat/routes.py`) scores each assistant reply after the fact on a few axes: empathy/tone fit, relevance, crisis-protocol adherence when `risk_flagged`, persona consistency. Start heuristic (keyword/length/protocol checks); an async LLM-judge call can be added later once the heuristic's ceiling is understood.
- Stores to a new `response_scores` table — observability only in this phase. Closing the loop into automatic prompt/rule refinement is a Phase 4-scale stretch goal, not in scope here.

---

*See [`PHASE_TODO.md`](./PHASE_TODO.md) for the actionable, checkbox-level breakdown of each phase above.*
