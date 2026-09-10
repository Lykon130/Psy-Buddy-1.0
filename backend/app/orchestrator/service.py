from app.context.models import ContextPacket
from app.orchestrator.models import OrchestratorSuggestion

# Crude placeholder keyword check for goal-oriented turns — real goal/intent
# detection belongs to Phase 3's Growth Timeline (L7); this only checks the
# current emotion label and recent journal emotion labels, so it will rarely
# fire until a real topic signal exists.
GOAL_MARKERS = ("goal", "plan", "motivat", "achieve", "productiv", "habit")


def suggest(context: ContextPacket) -> OrchestratorSuggestion:
    """
    Rule-based, deterministic persona/retrieval-scope suggestion — advisory
    only. The client's manually-selected persona is never overridden by this
    output (per roadmap decision #3); the crisis safety core's forced-empath
    override also stays independent of this function.

    Rules are evaluated top-to-bottom, first match wins — mirrors
    app.safety.service.assess_risk's style.
    """
    ms = context.mental_state

    # Rule 1 — risk-flagged turns always suggest empath + deep scope, even
    # though the safety core has already forced empath for the actual reply.
    if context.risk_flagged:
        return OrchestratorSuggestion(
            suggested_persona="empath",
            suggested_retrieval_scope="deep",
            reason="risk_flagged",
        )

    # Rule 2 — high stress + negative valence + worsening trend -> empath, deep
    if ms.stress >= 0.6 and ms.valence < -0.2 and ms.trend == "worsening":
        return OrchestratorSuggestion(
            suggested_persona="empath",
            suggested_retrieval_scope="deep",
            reason="high_stress_negative_worsening",
        )

    # Rule 3 — moderate/high stress, negative valence -> empath, standard
    if ms.stress >= 0.5 and ms.valence < 0:
        return OrchestratorSuggestion(
            suggested_persona="empath",
            suggested_retrieval_scope="standard",
            reason="elevated_stress_negative_valence",
        )

    # Rule 4 — low stress, neutral-to-positive valence, goal-oriented signal -> coach
    haystack = f"{context.emotion or ''} {' '.join(context.recent_journal_themes)}".lower()
    if ms.stress < 0.4 and ms.valence >= 0 and any(m in haystack for m in GOAL_MARKERS):
        return OrchestratorSuggestion(
            suggested_persona="coach",
            suggested_retrieval_scope="standard",
            reason="low_stress_goal_oriented",
        )

    # Rule 5 — positive valence, low stress -> friend, minimal scope
    if ms.stress < 0.4 and ms.valence > 0.2:
        return OrchestratorSuggestion(
            suggested_persona="friend",
            suggested_retrieval_scope="minimal",
            reason="positive_low_stress",
        )

    # Rule 6 — default fallback: keep it gentle, standard scope
    return OrchestratorSuggestion(
        suggested_persona="empath",
        suggested_retrieval_scope="standard",
        reason="default_fallback",
    )
