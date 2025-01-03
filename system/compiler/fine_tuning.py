import numpy as np
import torch
from datasets import Dataset
from pandas import DataFrame
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.model_selection import StratifiedShuffleSplit
from transformers import AutoModelForSequenceClassification, AutoTokenizer, Trainer, TrainingArguments, \
    PreTrainedTokenizer, BatchEncoding


def run_fine_tuning(model: AutoModelForSequenceClassification,
                    tokenizer: AutoTokenizer,
                    train_dataset: Dataset,
                    eval_dataset: Dataset) -> Trainer:
    """
    Fine-tunes a pre-trained model on the provided training dataset and evaluates it on the evaluation dataset.

    Args:
        model (AutoModelForSequenceClassification): The pre-trained model to be fine-tuned.
        tokenizer (AutoTokenizer): The tokenizer associated with the pre-trained model.
        train_dataset (Dataset): The dataset used for training.
        eval_dataset (Dataset): The dataset used for evaluation.

    Returns:
        Trainer: The Trainer object after training.
    """

    def compute_metrics(eval_pred):
        """
        Compute evaluation metrics for the model predictions.

        Args:
            eval_pred (tuple): A tuple containing the model predictions and the true labels.
                - predictions (numpy.ndarray): The predicted logits from the model.
                - labels (numpy.ndarray): The true labels.

        Returns:
            dict: A dictionary containing the computed metrics:
                - accuracy (float): The accuracy of the predictions.
                - precision (float): The weighted precision of the predictions.
                - recall (float): The weighted recall of the predictions.
                - f1 (float): The weighted F1 score of the predictions.
        """
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
        output_dir='./temp',  # Directory to save the model and other outputs
        num_train_epochs=20,  # Number of training epochs
        learning_rate=2e-5,  # Learning rate for the optimizer
        warmup_ratio=0.1,  # Warmup for the first 10% of steps
        lr_scheduler_type='linear',  # Linear scheduler
        per_device_train_batch_size=16,  # Batch size for training
        per_device_eval_batch_size=16,  # Batch size for evaluation
        save_strategy='epoch',  # Save the model at the end of each epoch
        logging_strategy='epoch',  # Log metrics at the end of each epoch
        eval_strategy='epoch',  # Evaluate the model at the end of each epoch
        logging_dir='./temp/logs',  # Directory to save the logs
        load_best_model_at_end=True,  # Load the best model at the end based on evaluation metric
        metric_for_best_model='f1',  # Use subtopic F1-score to determine the best model
        greater_is_better=True,  # Higher metric indicates a better model
        save_total_limit=1,  # Limit the total number of saved models
        save_only_model=True  # Save only the model weights
    )

    trainer = Trainer(
        model=model,  # The model to be trained
        args=training_args,  # Training arguments
        train_dataset=train_dataset,  # Training dataset
        eval_dataset=eval_dataset,  # Evaluation dataset
        processing_class=tokenizer,  # Tokenizer for processing the data
        compute_metrics=compute_metrics  # Function to compute evaluation metrics
    )

    print(f"Trainer is using device: {trainer.args.device}")

    trainer.train()  # Start the training process

    return trainer


def get_device() -> torch.device:
    """
    Gets the device (CPU or GPU) to be used for computation.

    Returns:
        torch.device: The device to be used for computation.
    """
    return torch.device('cuda' if torch.cuda.is_available() else 'cpu')


class LabelInfo:
    """
    A class to handle label information for a dataset.

    Attributes:
        labels (numpy.ndarray): An array of unique labels from the dataset.
        id2label (dict): A dictionary mapping label IDs to label names.
        label2id (dict): A dictionary mapping label names to label IDs.
    """

    def __init__(self, df: DataFrame, lab_column: str):
        """
        Initializes the LabelInfo object by extracting unique labels from the specified column of the DataFrame.

        Args:
            df (DataFrame): The DataFrame containing the data.
            lab_column (str): The name of the column containing the labels.
        """
        self.labels = df[lab_column].unique()
        self.id2label = {i: label for i, label in enumerate(self.labels)}
        self.label2id = {label: i for i, label in enumerate(self.labels)}

    def get_label(self, id: int) -> str | None:
        """
        Retrieves the label name corresponding to the given label ID.

        Args:
            id (int): The label ID.

        Returns:
            str | None: The label name if the ID exists, otherwise None.
        """
        return self.id2label.get(id, None)

    def get_id(self, label: str) -> int | None:
        """
        Retrieves the label ID corresponding to the given label name.

        Args:
            label (str): The label name.

        Returns:
            int | None: The label ID if the label exists, otherwise None.
        """
        return self.label2id.get(label, None)

    def __len__(self):
        return len(self.labels)


def prepare_dataset(df: DataFrame,
                    tokenizer: PreTrainedTokenizer,
                    label_info: LabelInfo,
                    examples_column: str,
                    labels_column: str) -> tuple[Dataset, Dataset]:
    """
    Prepares the dataset for training and evaluation by tokenizing the text and encoding the labels.

    Args:
        df (DataFrame): The DataFrame containing the data.
        tokenizer (PreTrainedTokenizer): The tokenizer to be used for tokenizing the text.
        label_info (LabelInfo): The LabelInfo object containing label mappings.
        examples_column (str): The name of the column containing the text data.
        labels_column (str): The name of the column containing the labels.

    Returns:
        tuple[Dataset, Dataset]: A tuple containing the training and evaluation datasets.
    """

    def tokenize_and_label(example: dict) -> BatchEncoding:
        """
        Tokenizes the text and encodes the label for a single example.

        Args:
            example (dict): A dictionary containing a single example with text and label.

        Returns:
            BatchEncoding: The tokenized text and encoded label.
        """
        question = example[examples_column]

        # Tokenize the text
        encodings = tokenizer(question, padding="max_length", truncation=True, max_length=128)
        label = label_info.get_id(example[labels_column])

        # Add the label to the encodings
        encodings.update({'labels': label})

        return encodings

    # Create the stratified split for train and validation sets
    split = StratifiedShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_index, val_index = next(split.split(df, df[labels_column]))
    strat_train_set = df.loc[train_index]
    strat_val_set = df.loc[val_index].reset_index(drop=True)

    # Convert to Hugging Face Dataset
    train_dataset = Dataset.from_pandas(strat_train_set)
    eval_dataset = Dataset.from_pandas(strat_val_set)

    # Convert all the examples in the datasets to tokenized encodings with numerical labels
    train_dataset = train_dataset.map(tokenize_and_label, remove_columns=train_dataset.column_names)
    eval_dataset = eval_dataset.map(tokenize_and_label, remove_columns=eval_dataset.column_names)

    return train_dataset, eval_dataset


def prepare_model(model_name: str, label_info: LabelInfo) -> AutoModelForSequenceClassification:
    """
    Prepares a pre-trained model for sequence classification by setting the number of labels and moving it to the appropriate device.

    Args:
        model_name (str): The name or path of the pre-trained model.
        label_info (LabelInfo): The LabelInfo object containing label mappings.

    Returns:
        AutoModelForSequenceClassification: The prepared model for sequence classification.
    """
    model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=len(label_info))

    # Move the model to the appropriate device (CPU or GPU)
    model.to(get_device())

    # Update the model's configuration with the custom label mappings
    model.config.id2label = label_info.id2label
    model.config.label2id = label_info.label2id

    return model
