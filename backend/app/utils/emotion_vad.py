# backend/app/utils/emotion_vad.py
"""
Approximate valence/arousal mapping for GoEmotions' 28 labels.

Not an official VAD lexicon — a documented, reasonable Ekman-cluster
approximation. Good enough to derive a "stress" signal for internal
reasoning (Phase 2 Mental State vector); never surfaced as a clinical
measurement.

valence: -1.0 (very negative) .. 1.0 (very positive)
arousal:  0.0 (calm)          .. 1.0 (high arousal)
"""

VALENCE_AROUSAL: dict[str, tuple[float, float]] = {
    "admiration": (0.7, 0.4),
    "amusement": (0.8, 0.6),
    "anger": (-0.8, 0.8),
    "annoyance": (-0.5, 0.5),
    "approval": (0.6, 0.3),
    "caring": (0.6, 0.4),
    "confusion": (-0.2, 0.4),
    "curiosity": (0.3, 0.5),
    "desire": (0.4, 0.6),
    "disappointment": (-0.6, 0.3),
    "disapproval": (-0.5, 0.4),
    "disgust": (-0.7, 0.5),
    "embarrassment": (-0.4, 0.5),
    "excitement": (0.7, 0.8),
    "fear": (-0.7, 0.8),
    "gratitude": (0.8, 0.4),
    "grief": (-0.9, 0.5),
    "joy": (0.9, 0.7),
    "love": (0.9, 0.6),
    "nervousness": (-0.5, 0.7),
    "optimism": (0.7, 0.5),
    "pride": (0.8, 0.5),
    "realization": (0.1, 0.4),
    "relief": (0.6, 0.3),
    "remorse": (-0.6, 0.4),
    "sadness": (-0.7, 0.3),
    "surprise": (0.2, 0.7),
    "neutral": (0.0, 0.2),
}
