# backend/app/utils/bert_emotion_api.py
from transformers import pipeline

# Load the emotion detection pipeline from Hugging Face
# This uses a pre-trained BERT-like model fine-tuned for emotions
emotion_pipeline = pipeline(
    "text-classification",
    model="j-hartmann/emotion-english-distilroberta-base",
    return_all_scores=False
)

def detect_emotion(text: str):
    try:
        result = emotion_pipeline(text)
        if isinstance(result, list) and len(result) > 0:
            return {
                "emotion": result[0]["label"],
                "score": result[0]["score"]
            }
        else:
            return {"emotion": "neutral", "score": 0.0}
    except Exception as e:
        print(f"[Emotion Detection Error] {e}")
        return {"emotion": "neutral", "score": 0.0}
