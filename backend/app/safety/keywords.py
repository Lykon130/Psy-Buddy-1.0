# Risk phrase list for the Minimal Crisis Safety Core (PSYCHE L17).
# Deliberately simple keyword/phrase matching for Phase 1 — a classifier-based
# second pass can be layered on top of `assess_risk` later without changing
# call sites.

RISK_PHRASES = {
    "suicidal_ideation": [
        "kill myself",
        "end my life",
        "want to die",
        "wish i was dead",
        "wish i were dead",
        "suicide",
        "suicidal",
        "not want to be alive",
        "don't want to be alive",
        "better off dead",
        "no reason to live",
        "no reason to keep living",
    ],
    "self_harm": [
        "hurt myself",
        "cutting myself",
        "self harm",
        "self-harm",
        "harming myself",
    ],
    "crisis": [
        "can't go on",
        "cannot go on",
        "can't take it anymore",
        "cannot take it anymore",
        "give up on everything",
        "no way out",
    ],
}

SEVERITY_BY_CATEGORY = {
    "suicidal_ideation": "high",
    "self_harm": "high",
    "crisis": "medium",
}
