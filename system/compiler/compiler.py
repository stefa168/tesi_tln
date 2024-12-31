import pandas as pd
import torch
import numpy as np
from datasets import Dataset
from pandas import DataFrame
from sklearn.model_selection import StratifiedShuffleSplit
from spacy.lang.ja.syntax_iterators import labels
from transformers import TrainingArguments, Trainer, AutoModelForSequenceClassification, AutoTokenizer
from sklearn.metrics import accuracy_score, precision_recall_fscore_support


def run_fine_tuning(model: AutoModelForSequenceClassification,
                    tokenizer: AutoTokenizer,
                    train_dataset: Dataset,
                    eval_dataset: Dataset) -> bool:
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

    return True


def get_device() -> torch.device:
    return torch.device('cuda' if torch.cuda.is_available() else 'cpu')


def prepare_dataset(df: DataFrame, tok_column="Question", lab_column='Global Subject') -> tuple[Dataset, Dataset]:
    labels = df[lab_column].unique()
    id2label = {i: label for i, label in enumerate(labels)}
    label2id = {label: i for i, label in enumerate(labels)}

    # todo improve types
    def tokenize_and_label(example: dict) -> dict:
        question = example[tok_column]

        # https://huggingface.co/docs/transformers/v4.46.2/en/main_classes/tokenizer#transformers.PreTrainedTokenizer.__call__
        encodings = tokenizer(question, padding="max_length", truncation=True, max_length=128)
        label = label2id[example[lab_column]]

        encodings.update({'labels': label})

        return encodings

    # Create the stratified split for train and validation sets
    split = StratifiedShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_index, val_index = next(split.split(df, df[lab_column]))
    strat_train_set = df.loc[train_index]
    strat_val_set = df.loc[val_index].reset_index(drop=True)

    # Convert to Hugging Face Dataset
    train_dataset = Dataset.from_pandas(strat_train_set)
    eval_dataset = Dataset.from_pandas(strat_val_set)

    # Tokenize the datasets
    train_dataset = train_dataset.map(tokenize_and_label, remove_columns=train_dataset.column_names)
    eval_dataset = eval_dataset.map(tokenize_and_label, remove_columns=eval_dataset.column_names)

    return train_dataset, eval_dataset


if __name__ == '__main__':
    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    print(f"Current CUDA device: {torch.cuda.current_device()}")
    print(f"Device name: {torch.cuda.get_device_name(torch.cuda.current_device())}")

    # todo extract the labels_qi to have it accessible by other parts of the compiler while training
    model = AutoModelForSequenceClassification.from_pretrained('bert-base-uncased', num_labels=7)
    model.to(get_device())
    tokenizer = AutoTokenizer.from_pretrained('bert-base-uncased')

    # Load the dataset
    df = pd.read_csv('../../multitask_training/data_cleaned_manual_combined.csv')

    train_dataset, eval_dataset = prepare_dataset(df, tok_column="Question", lab_column="Global Subject")

    run_fine_tuning(model, tokenizer, train_dataset, eval_dataset)
