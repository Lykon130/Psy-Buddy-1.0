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
| L3 Cognitive Core (Cognitive Reasoning) | Cognitive Layer | Custom PsyBuddy LLM | **Partial (stub)** — a single pass-through call to an OpenRouter model with a persona system prompt; no planning, no retrieval-based reasoning. `get_ai_response` now accepts an unused `context` param reserved for Phase 3 |
| L4 Mental State Engine (Psych. Modeling) | Understanding/Relational Layer | Emotion AI (mental_state, stress_index) | **Partial (Phase 2)** — `backend/app/mental_states/service.py` computes a real vector (valence, stress, arousal, trend) per turn from the emotion distribution and persists it to `mental_states`; the old single 0.2–0.9 `mood_logs` score is kept only for backward compat, not superseded in the UI yet; no cognitive-load/motivation dimensions |
| L5 Identity Modeling (Psych. Modeling) | Relational Layer (Profile) | Personality AI | **Not started** |
| L6 Trust Model (Psych. Modeling) | — (implicit in consent) | — | **Not started** |
| L7 Life Direction Model (Psych. Modeling) | Relational Layer (Growth Timeline) | — | **Not started** — no goals/milestones data model at all |
| L8 Intervention Planner (Intervention) | Cognitive Layer (Orchestrator) | Persona Control Layer | **Not started** — no strategy selection beyond the persona the client sends |
| L9 Emotional Simulation (Intervention) | Response contract | Safety AI (implicit) | **Not started** |
| L10 Persona Router (Cognitive Reasoning) | Mode selection (Orchestrator) | Persona Control Layer | **Partial (Phase 2)** — 3 persona system prompts (Empath/Coach/Friend) exist and remain user-selectable/primary; a new rule-based orchestrator (`backend/app/orchestrator/service.py`) computes a `suggested_persona` + `suggested_retrieval_scope` from the fused context packet and returns it in the `/chat/` response, but it is advisory-only and never overrides the client's choice (per decision #3) |
| L11 Response Generation (Cognitive Reasoning) | Response contract | Custom PsyBuddy LLM | **Working** — functional, but ungrounded (no retrieval, no safety pass) |
| L12 Self-Reflection (Learning) | Evaluation framework | — | **Not started** |
| L13 Meta-Learning (Learning) | — | — | **Partial** — `continuous_trainer.py` re-fine-tunes the emotion classifier on the user's own labeled chat/journal text; a real, working sliver of self-improvement, just scoped to emotion detection, not dialogue quality |
| L14 Hybrid Memory (crosscutting) | Relational Memory | Memory Engine | **Partial (Phase 1)** — structured `memory_facts` store (`backend/app/memory/`) replaced the single-blob approach: per-fact `category`, `confidence`, `source` (provenance), `confirmed` flag; visible + deletable via `frontend/lib/screens/memory_settings_screen.dart` (editing is backend-only so far, no UI affordance yet). Still no vector/semantic store despite FAISS being in the architecture diagrams (deferred to Phase 4) |
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

*(Snapshot above predates Phase 1 and Phase 2 — see §2's per-layer status for current state of L2/L4/L10/L14/L17. Phase 1 (structured memory, crisis safety core, consent UX) and Phase 2 (Context Fusion, Mental State vector, extended emotion output, rule-based orchestrator) have both landed in code but neither has confirmed its Supabase migration applied to the live project or an end-to-end run against a live server; see `PHASE_TODO.md`'s "still open" items under each phase. Phase 1's memory view also still lacks an edit affordance in the UI, though the backend endpoint exists.)*

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

*See [`PHASE_TODO.md`](./PHASE_TODO.md) for the actionable, checkbox-level breakdown of each phase above.*
