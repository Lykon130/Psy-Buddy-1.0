from app.context.models import ContextPacket
from app.simulation.models import SimulationNote

# Emotional Simulation (L9), tone/hedging pass only (per the Phase 3 scope
# decision) — no second generation round-trip, no draft-then-critique loop.
# Checks whether the manually-selected persona's default tone is likely to
# clash with the user's actual mental state this turn, since persona choice
# stays manual (decision #3) and can drift from what the state vector says.
# Rule-based, first match wins — mirrors app.orchestrator.service.suggest.


def simulate(persona: str, context: ContextPacket) -> SimulationNote:
    ms = context.mental_state
    persona = persona.lower()

    if context.risk_flagged:
        # Crisis safety core already forces empath + a static response;
        # this pass never runs against that reply.
        return SimulationNote()

    if persona == "coach" and ms.valence < -0.2:
        return SimulationNote(
            mismatch=True,
            reason="coach_tone_vs_low_valence",
            guidance="The user is in a low emotional place right now — acknowledge that first; soften any brisk, action-oriented coaching language until they feel heard.",
        )

    if persona == "friend" and ms.stress >= 0.6:
        return SimulationNote(
            mismatch=True,
            reason="friend_tone_vs_high_stress",
            guidance="This is a high-stress moment for the user — keep the tone warm but dial back pure lightness or humor; make room for what they're carrying.",
        )

    if persona == "empath" and ms.valence > 0.3 and ms.stress < 0.3:
        return SimulationNote(
            mismatch=True,
            reason="empath_tone_vs_positive_state",
            guidance="The user seems to be in a genuinely good place — a warm, lighter tone fits better here than a somber or overly careful one.",
        )

    return SimulationNote()
