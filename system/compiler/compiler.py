import torch
import numpy as np
from datasets import Dataset
from transformers import TrainingArguments, Trainer, AutoModelForSequenceClassification, AutoTokenizer
from sklearn.metrics import accuracy_score, precision_recall_fscore_support


def run_training(model: AutoModelForSequenceClassification,
                 tokenizer: AutoTokenizer,
                 train_dataset: Dataset,
                 eval_dataset: Dataset):
    def compute_metrics(eval_pred):
        predictions, labels = eval_pred
        preds = np.argmax(predictions, axis=1)
        acc = accuracy_score(labels, preds)
        precision, recall, f1, _ = precision_recall_fscore_support(labels, preds, average='weighted', zero_division=0)
        metrics = {
            'accuracy': acc,
            'precision': precision,
            'recall': recall,
            'f1': f1,
        }
        return metrics

    training_args = TrainingArguments(
        # todo save to a "temp" directory of some sort, maybe specified in the compiler configuration, which is
        #  different from the compilation configuration
        output_dir='./results',
        num_train_epochs=20,
        learning_rate=2e-5,
        warmup_ratio=0.1,  # Warmup for the first 10% of steps
        lr_scheduler_type='linear',  # Linear scheduler
        per_device_train_batch_size=16,
        per_device_eval_batch_size=16,
        save_strategy='epoch',
        logging_strategy='epoch',
        eval_strategy='epoch',
        logging_dir='./logs',  # todo save to specific folder
        load_best_model_at_end=True,  # Load the best model at the end based on evaluation metric
        metric_for_best_model='f1',  # Use subtopic F1-score to determine the best model
        greater_is_better=True,  # Higher metric indicates a better model,
        save_total_limit=1,
        save_only_model=True
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        processing_class=tokenizer,
        compute_metrics=compute_metrics
    )

    print(f"Trainer is using device: {trainer.args.device}")

    trainer.train()

    # todo save model correctly to a folder for the specific compilation configuration
    trainer.save_model()


def get_device() -> torch.device:
    return torch.device('cuda' if torch.cuda.is_available() else 'cpu')


if __name__ == '__main__':
    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    print(f"Current CUDA device: {torch.cuda.current_device()}")
    print(f"Device name: {torch.cuda.get_device_name(torch.cuda.current_device())}")
