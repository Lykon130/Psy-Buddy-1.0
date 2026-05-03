# backend/continuous_trainer.py
import torch
import numpy as np
from datasets import Dataset
from transformers import RobertaTokenizerFast, RobertaForSequenceClassification, Trainer, TrainingArguments, DataCollatorWithPadding
from app.utils.config import supabase

# Complete list of the 28 GoEmotions labels
GOEMOTIONS_LABELS = [
    "admiration", "amusement", "anger", "annoyance", "approval", "caring",
    "confusion", "curiosity", "desire", "disappointment", "disapproval", 
    "disgust", "embarrassment", "excitement", "fear", "gratitude", "grief", 
    "joy", "love", "nervousness", "optimism", "pride", "realization", 
    "relief", "remorse", "sadness", "surprise", "neutral"
]

def main():
    print("Fetching recent chats and journal entries from database for continuous learning...")
    
    # We pull down all chats and journal entries
    chats_resp = supabase.table("chats").select("message, emotion").execute()
    journal_resp = supabase.table("journal_entries").select("content, emotion").execute()
    
    texts = []
    labels = []
    
    # Process chats
    if chats_resp.data:
        for row in chats_resp.data:
            if row.get("message") and row.get("emotion") and row["emotion"] != "neutral":
                texts.append(row["message"])
                labels.append(row["emotion"])
                
    # Process journals
    if journal_resp.data:
        for row in journal_resp.data:
            if row.get("content") and row.get("emotion") and row["emotion"] != "neutral":
                texts.append(row["content"])
                labels.append(row["emotion"])
                
    if not texts:
        print("No distinctly tracked emotion data found in DB. Skipping continuous training.")
        return
        
    print(f"Found {len(texts)} behavioral records targeting user's specific vocabulary.")
    
    dataset_dict = {"text": texts, "label_str": labels}
    dataset = Dataset.from_dict(dataset_dict)
    
    model_name = "./ml_models/custom_goemotions_model"
    
    try:
        tokenizer = RobertaTokenizerFast.from_pretrained(model_name)
    except:
        print("Model has not been trained yet. Please run train_emotion_model.py first!")
        return

    def preprocess_function(examples):
        encodings = tokenizer(examples["text"], truncation=True, padding="max_length", max_length=64)
        
        batch_labels = []
        for em in examples["label_str"]:
            multihot = [0.0] * len(GOEMOTIONS_LABELS)
            lb = em.lower()
            if lb in GOEMOTIONS_LABELS:
                multihot[GOEMOTIONS_LABELS.index(lb)] = 1.0
            else:
                multihot[GOEMOTIONS_LABELS.index("neutral")] = 1.0
            batch_labels.append(multihot)
            
        encodings["labels"] = batch_labels
        return encodings

    print("Tokenizing target arrays...")
    tokenized_dataset = dataset.map(preprocess_function, batched=True, remove_columns=["text", "label_str"])
    tokenized_dataset.set_format("torch", columns=["input_ids", "attention_mask", "labels"])

    model = RobertaForSequenceClassification.from_pretrained(
        model_name,
        num_labels=len(GOEMOTIONS_LABELS),
        problem_type="multi_label_classification"
    )

    training_args = TrainingArguments(
        output_dir="./ml_models/continuous_checkpoints",
        learning_rate=1e-5, # Gentle learning rate to prevent catastrophic forgetting
        per_device_train_batch_size=8,
        num_train_epochs=1, # Just 1 epoch per continuous cycle
        weight_decay=0.01,
        save_strategy="no",
    )

    class CustomDataCollator(DataCollatorWithPadding):
        def __call__(self, features):
            batch = super().__call__(features)
            if "labels" in batch:
                batch["labels"] = batch["labels"].to(torch.float32)
            return batch

    data_collator = CustomDataCollator(tokenizer=tokenizer)

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_dataset,
        data_collator=data_collator,
    )

    print("Executing Continuous Background Training Loop...")
    trainer.train()

    print("Feedback Training Complete. Saving fine-tuned checkpoints to ./ml_models/custom_goemotions_model")
    trainer.save_model("./ml_models/custom_goemotions_model")
    tokenizer.save_pretrained("./ml_models/custom_goemotions_model")
    print("Done!")

if __name__ == "__main__":
    main()
