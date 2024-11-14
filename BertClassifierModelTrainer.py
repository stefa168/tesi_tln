import time
from collections import Counter

import pandas as pd
import torch
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from torch.utils.data import Dataset, DataLoader
from torch.nn import functional
from torch.optim import AdamW
from tqdm import tqdm
from transformers import AutoModelForSequenceClassification, AutoTokenizer, PreTrainedTokenizerBase, PreTrainedModel


class SentimentDataset(Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels.tolist()

    def __getitem__(self, idx):
        item = {
            key: torch.tensor(val[idx]) for key, val in self.encodings.items()
        }
        item['labels'] = torch.tensor(self.labels[idx], dtype=torch.long)
        return item

    def __len__(self):
        return len(self.labels)


# For fine tuning stability paper: https://arxiv.org/abs/2006.04884
class BertClassifierModelTrainer:
    model_tokenizer: PreTrainedTokenizerBase
    model: PreTrainedModel
    stats: pd.DataFrame | None

    def __init__(self, model_name: str, num_labels: int, learning_rate: float, train_data, train_labels,
                 validation_data, validation_labels, epochs=20):
        self.model_name = model_name
        self.num_labels = num_labels
        self.stats = None
        self.learning_rate = learning_rate
        self.epochs = epochs
        self.model_tokenizer = AutoTokenizer.from_pretrained(model_name)
        self.model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=num_labels)

        # Check if GPU is available
        self.device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
        self.model.to(self.device)

        # Tokenize the data
        train_encodings = self.model_tokenizer(train_data, truncation=True, padding=True)
        validation_encodings = self.model_tokenizer(validation_data, truncation=True, padding=True)

        # Create the dataset
        self.train_dataset = SentimentDataset(train_encodings, train_labels)
        self.validation_dataset = SentimentDataset(validation_encodings, validation_labels)

    def train(self):
        from transformers import get_linear_schedule_with_warmup

        # Create data loaders
        train_loader = DataLoader(self.train_dataset, batch_size=16, shuffle=True)
        val_loader = DataLoader(self.validation_dataset, batch_size=16, shuffle=False)

        optimizer = AdamW(self.model.parameters(), lr=self.learning_rate, betas=(0.9, 0.999), eps=1e-8)

        # Total number of training steps
        total_steps = len(train_loader) * self.epochs

        # Scheduler to linearly increase for the first 10% of steps and then linearly decay to zero
        scheduler = get_linear_schedule_with_warmup(
            optimizer,
            num_warmup_steps=int(0.1 * total_steps),
            num_training_steps=total_steps
        )

        training_stats = []

        progress_bar = tqdm(total=self.epochs, desc=f"Training model...", unit="epochs")

        for epoch in range(self.epochs):
            start_time = time.time()

            # Training
            self.model.train()
            total_train_loss = 0
            for batch in train_loader:
                # Move batch to device
                batch = {k: v.to(self.device) for k, v in batch.items()}

                # Zero the gradients
                optimizer.zero_grad()

                # Forward pass
                outputs = self.model(**batch)
                loss = outputs.loss
                total_train_loss += loss.item()

                # Backward pass
                loss.backward()

                # Update parameters
                optimizer.step()
                scheduler.step()

            avg_train_loss = total_train_loss / len(train_loader)

            # Evaluation
            self.model.eval()
            total_eval_accuracy = 0
            total_eval_loss = 0
            predictions, true_labels = [], []

            with torch.no_grad():
                for batch in val_loader:
                    batch = {k: v.to(self.device) for k, v in batch.items()}
                    outputs = self.model(**batch)

                    loss = outputs.loss
                    total_eval_loss += loss.item()

                    logits = outputs.logits
                    preds = torch.argmax(logits, dim=-1)

                    predictions.extend(preds.cpu().numpy())
                    true_labels.extend(batch['labels'].cpu().numpy())

            avg_val_loss = total_eval_loss / len(val_loader)
            val_accuracy = accuracy_score(true_labels, predictions)

            end_time = time.time()
            epoch_duration = end_time - start_time

            training_stats.append(
                {
                    'epoch': epoch + 1,
                    'training_loss': avg_train_loss,
                    'validation_loss': avg_val_loss,
                    'validation_accuracy': val_accuracy,
                    'epoch_duration': epoch_duration,
                    'true_labels_distribution': Counter(true_labels),
                    'predicted_labels_distribution': Counter(predictions)
                }
            )

            progress_bar.update()

        progress_bar.close()

        # Create a DataFrame from the training statistics
        stats_df = pd.DataFrame(training_stats)
        # Use the 'epoch' as the index
        stats_df = stats_df.set_index('epoch')
        self.stats = stats_df

    def predict_top(self, text: str, label_map: dict[int, str], top_k=5):
        # Tokenize input
        inputs = self.model_tokenizer(text, return_tensors='pt', truncation=True, padding=True)
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        # Get model outputs
        with torch.no_grad():
            outputs = self.model(**inputs)
            logits = outputs.logits
            top_k_logits, top_k_indices = torch.topk(logits, top_k, dim=-1)

        # Apply softmax to get confidence scores
        softmax_scores = functional.softmax(logits, dim=-1)
        top_k_scores = torch.gather(softmax_scores, 1, top_k_indices)

        # Map indices to labels and pair with confidence scores
        top_k_results = [(label_map[idx.item()], score.item()) for idx, score in zip(top_k_indices[0], top_k_scores[0])]

        return top_k_results


if __name__ == '__main__':
    model_name = 'bert-base-cased'

    df = pd.read_csv('./labelling/data_cleaned_manual.csv')

    le = LabelEncoder()
    df['gs'] = le.fit_transform(df['Global Subject'])
    df['qi'] = le.fit_transform(df['Question Intent'])

    label_count = df['gs'].nunique()

    train_questions, val_questions, train_labels, val_labels = train_test_split(
        df['Question'], df['gs'],
        test_size=0.2,
        random_state=34197
    )

    trainer = BertClassifierModelTrainer(model_name, label_count, 5e-5,
                                         train_questions.tolist(),
                                         train_labels,
                                         val_questions.tolist(),
                                         val_labels)
    trainer.train()
