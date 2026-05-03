# backend/app/utils/bert_emotion_api.py
import os
from transformers import pipeline

# Attempt to load the local custom fine-tuned model
# If the user hasn't trained it yet, fallback exactly to a pre-trained GoEmotions RoBERTa model
LOCAL_MODEL_PATH = "./ml_models/custom_goemotions_model"

try:
    if os.path.exists(LOCAL_MODEL_PATH):
        print(f"Loading custom model from {LOCAL_MODEL_PATH}")
        # Use top_k=1 to just extract the most prominent emotion easily
        emotion_pipeline = pipeline("text-classification", model=LOCAL_MODEL_PATH, top_k=1)
    else:
        print("Loading fallback model: SamLowe/roberta-base-go_emotions")
        emotion_pipeline = pipeline("text-classification", model="SamLowe/roberta-base-go_emotions", top_k=1)
except Exception as e:
    print(f"Error loading emotion pipeline: {e}")
    emotion_pipeline = None

def detect_emotion(text: str):
    if not emotion_pipeline:
        return {"emotion": "neutral", "score": 0.0}
    try:
        # pipeline output for top_k is generally a list of lists e.g. [[{'label': 'joy', 'score': 0.9}]]
        result = emotion_pipeline(text)
        if isinstance(result, list) and len(result) > 0:
            item = result[0]
            if isinstance(item, list) and len(item) > 0:
                 return {"emotion": item[0]["label"], "score": item[0]["score"]}
            elif isinstance(item, dict):
                 return {"emotion": item.get("label", "neutral"), "score": item.get("score", 0.0)}
        return {"emotion": "neutral", "score": 0.0}
    except Exception as e:
        print(f"[Emotion Detection Error] {e}")
        return {"emotion": "neutral", "score": 0.0}
