from app.context.models import ContextPacket
from app.intervention.models import InterventionPlan

# Guidance text folded into the persona system prompt (see chat/gpt_service.py)
# — one short, concrete instruction per strategy, never shown to the user
# verbatim.
STRATEGY_GUIDANCE: dict[str, str] = {
    "reflective_listening": "Reflect back what the user seems to be feeling before offering anything else — prioritize being heard over being helpful right now.",
    "grounding_exercise": "Gently offer a brief, concrete grounding or breathing exercise the user can try right now, alongside your reply.",
    "goal_check_in": "Naturally check in on the user's active goal(s) if it fits the conversation, without forcing it.",
    "reframe": "Where appropriate, offer a gentle alternative framing of the situation — never dismissive, always after acknowledging the feeling first.",
    "validate_and_normalize": "Focus on validating and normalizing what the user is going through — avoid problem-solving or advice until they've felt heard.",
    "psychoeducation_light": "If it fits naturally, share one small, relevant, non-clinical insight — keep it light, not lecture-y.",
}


def plan(
    context: ContextPacket,
    active_goals: list[dict],
) -> InterventionPlan:
    """
    Rule-based, deterministic strategy selection — mirrors
    app.orchestrator.service.suggest's style (first match wins). Runs even
    on risk-flagged turns for observability, though those turns bypass the
    LLM call entirely via the crisis safety core's static response.
    """
    ms = context.mental_state

    if context.risk_flagged:
        return InterventionPlan(strategy="validate_and_normalize", rationale="risk_flagged")

    if ms.stress >= 0.7:
        return InterventionPlan(strategy="grounding_exercise", rationale="high_stress")

    if ms.stress >= 0.5 and ms.valence < -0.2 and ms.trend == "worsening":
        return InterventionPlan(strategy="reframe", rationale="negative_worsening_moderate_stress")

    if ms.stress >= 0.4 and ms.valence < 0:
        return InterventionPlan(strategy="reflective_listening", rationale="elevated_stress_negative_valence")

    if active_goals and ms.stress < 0.4 and ms.valence >= 0:
        goal_title = active_goals[0].get("title")
        return InterventionPlan(
            strategy="goal_check_in",
            rationale="has_active_goals_low_stress",
            focus=goal_title,
        )

    if ms.valence > 0.2 and ms.stress < 0.4:
        return InterventionPlan(strategy="psychoeducation_light", rationale="positive_low_stress")

    return InterventionPlan(strategy="reflective_listening", rationale="default_fallback")
