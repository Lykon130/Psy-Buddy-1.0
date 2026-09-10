# backend/app/utils/bert_emotion_api.py
import os
from transformers import pipeline

from app.utils.emotion_vad import VALENCE_AROUSAL

# Attempt to load the local custom fine-tuned model
# If the user hasn't trained it yet, fallback exactly to a pre-trained GoEmotions RoBERTa model
LOCAL_MODEL_PATH = "./ml_models/custom_goemotions_model"

try:
    if os.path.exists(LOCAL_MODEL_PATH):
        print(f"Loading custom model from {LOCAL_MODEL_PATH}")
        # top_k=None returns the full label distribution (needed for valence/arousal fusion)
        emotion_pipeline = pipeline("text-classification", model=LOCAL_MODEL_PATH, top_k=None)
    else:
        print("Loading fallback model: SamLowe/roberta-base-go_emotions")
        emotion_pipeline = pipeline("text-classification", model="SamLowe/roberta-base-go_emotions", top_k=None)
except Exception as e:
    print(f"Error loading emotion pipeline: {e}")
    emotion_pipeline = None

_EMPTY_RESULT = {"emotion": "neutral", "score": 0.0, "distribution": [], "valence": 0.0, "arousal": 0.0}


def detect_emotion(text: str) -> dict:
    """
    Returns:
    {
        "emotion": str,        # top label (backward compatible)
        "score": float,        # top label's score (backward compatible)
        "distribution": [{"label": str, "score": float}, ...],  # full sorted distribution
        "valence": float,      # -1.0 (very negative) .. 1.0 (very positive), distribution-weighted
        "arousal": float,      # 0.0 (calm) .. 1.0 (high arousal), distribution-weighted
    }
    """
    if not emotion_pipeline:
        return dict(_EMPTY_RESULT)
    try:
        # pipeline output for top_k=None is a list of lists e.g. [[{'label': 'joy', 'score': 0.9}, ...]]
        result = emotion_pipeline(text)
        if isinstance(result, list) and len(result) > 0 and isinstance(result[0], list):
            scores = result[0]
        elif isinstance(result, list):
            scores = result
        else:
            return dict(_EMPTY_RESULT)

        if not scores:
            return dict(_EMPTY_RESULT)

        scores = sorted(scores, key=lambda x: x["score"], reverse=True)
        top = scores[0]

        valence = sum(
            VALENCE_AROUSAL[s["label"]][0] * s["score"]
            for s in scores
            if s["label"] in VALENCE_AROUSAL
        )
        arousal = sum(
            VALENCE_AROUSAL[s["label"]][1] * s["score"]
            for s in scores
            if s["label"] in VALENCE_AROUSAL
        )

        return {
            "emotion": top["label"],
            "score": top["score"],
            "distribution": scores,
            "valence": round(valence, 4),
            "arousal": round(arousal, 4),
        }
    except Exception as e:
        print(f"[Emotion Detection Error] {e}")
        return dict(_EMPTY_RESULT)
