# backend/train_emotion_model.py
import torch
import numpy as np
from datasets import load_dataset
from transformers import RobertaTokenizerFast, RobertaForSequenceClassification, Trainer, TrainingArguments, DataCollatorWithPadding

# Complete list of the 28 GoEmotions labels
GOEMOTIONS_LABELS = [
    "admiration", "amusement", "anger", "annoyance", "approval", "caring",
    "confusion", "curiosity", "desire", "disappointment", "disapproval", 
    "disgust", "embarrassment", "excitement", "fear", "gratitude", "grief", 
    "joy", "love", "nervousness", "optimism", "pride", "realization", 
    "relief", "remorse", "sadness", "surprise", "neutral"
]

def main():
    print("Loading GoEmotions dataset...")
    # Load dataset
    dataset = load_dataset("go_emotions")

    model_name = "roberta-base"
    tokenizer = RobertaTokenizerFast.from_pretrained(model_name)

    # Multi-label classification requires turning integer lists into a strict multihot array of shape [28]
    def preprocess_function(examples):
        texts = examples["text"]
        encodings = tokenizer(texts, truncation=True, padding="max_length", max_length=64)
        
        # GoEmotions provides a list of label IDs for each row because a text can have multiple emotions.
        # We need to construct a FloatTensor for BCEWithLogitsLoss
        batch_labels = []
        for label_list in examples["labels"]:
            # Create a 28-dim array of zeros
            multihot = [0.0] * len(GOEMOTIONS_LABELS)
            for idx in label_list:
                multihot[idx] = 1.0
            batch_labels.append(multihot)
            
        encodings["labels"] = batch_labels
        return encodings

    print("Tokenizing and formatting datasets. This takes a few moments...")
    tokenized_datasets = dataset.map(preprocess_function, batched=True, remove_columns=["text", "id", "labels"])
    tokenized_datasets.set_format("torch")

    # Define model
    model = RobertaForSequenceClassification.from_pretrained(
        model_name,
        num_labels=len(GOEMOTIONS_LABELS),
        problem_type="multi_label_classification"
    )

    # Define id2label and label2id config
    model.config.id2label = {i: label for i, label in enumerate(GOEMOTIONS_LABELS)}
    model.config.label2id = {label: i for i, label in enumerate(GOEMOTIONS_LABELS)}

    # Training arguments
    training_args = TrainingArguments(
        output_dir="./ml_models/custom_goemotions_model_checkpoints",
        eval_strategy="epoch",
        learning_rate=2e-5,
        per_device_train_batch_size=32,
        per_device_eval_batch_size=32,
        num_train_epochs=3,
        weight_decay=0.01,
        save_strategy="epoch",
        load_best_model_at_end=True,
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
        train_dataset=tokenized_datasets["train"],
        eval_dataset=tokenized_datasets["validation"],
        data_collator=data_collator,
    )

    print("Starting Training...")
    trainer.train()

    print("Training Complete. Saving model to ./ml_models/custom_goemotions_model")
    trainer.save_model("./ml_models/custom_goemotions_model")
    tokenizer.save_pretrained("./ml_models/custom_goemotions_model")
    print("Done!")

if __name__ == "__main__":
    main()
