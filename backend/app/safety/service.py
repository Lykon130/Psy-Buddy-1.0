from datetime import datetime
from pydantic import BaseModel
from typing import List

from app.safety.keywords import RISK_PHRASES, SEVERITY_BY_CATEGORY
from app.utils.config import supabase

CRISIS_RESPONSE_TEXT = (
    "I'm really glad you told me this, and I want to make sure you get support "
    "that goes beyond what I can offer. If you're in immediate danger, please "
    "contact your local emergency number right now.\n\n"
    "You can also reach out to a crisis line, for example:\n"
    "- US: call or text 988 (Suicide & Crisis Lifeline)\n"
    "- UK & ROI: Samaritans, 116 123\n"
    "- Elsewhere: befrienders.org has a directory of local crisis lines\n\n"
    "You don't have to go through this alone — a trained counselor can help "
    "in ways I'm not able to. I'm here to keep talking with you too, if that helps."
)


class RiskAssessment(BaseModel):
    flagged: bool
    severity: str = "none"
    matched_terms: List[str] = []


def assess_risk(text: str) -> RiskAssessment:
    lowered = text.lower()
    matched_terms = []
    severities = []

    for category, phrases in RISK_PHRASES.items():
        for phrase in phrases:
            if phrase in lowered:
                matched_terms.append(phrase)
                severities.append(SEVERITY_BY_CATEGORY.get(category, "medium"))

    if not matched_terms:
        return RiskAssessment(flagged=False)

    severity = "high" if "high" in severities else "medium"
    return RiskAssessment(flagged=True, severity=severity, matched_terms=matched_terms)


def log_safety_event(user_id: str, session_id: str, assessment: RiskAssessment) -> None:
    """Internal-monitoring log only — never surfaced to the end user."""
    try:
        supabase.table("safety_events").insert(
            {
                "user_id": user_id,
                "session_id": session_id,
                "matched_terms": assessment.matched_terms,
                "severity": assessment.severity,
                "timestamp": datetime.utcnow().isoformat(),
            }
        ).execute()
    except Exception as e:
        print("[Safety Event Log Error]", e)
