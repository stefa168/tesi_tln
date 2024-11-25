import torch
from torch.utils.data import Dataset, DataLoader
from transformers import AutoModel, AutoTokenizer
import torch.nn.functional as F
import torch.optim as optim
from tqdm import tqdm
import random
import numpy as np

from multitask_training.MultiTaskModel import MultiTaskModel


def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)

set_seed(42)

class MultiTaskDataset(Dataset):
    def __init__(self, tokenizer, texts, labels_a, labels_b, max_length=128):
        self.tokenizer = tokenizer
        self.texts = texts
        self.labels_a = labels_a
        self.labels_b = labels_b
        self.max_length = max_length

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        # Tokenize the text
        encoding = self.tokenizer(
            self.texts[idx],
            truncation=True,
            padding='max_length',
            max_length=self.max_length,
            return_tensors='pt'
        )
        item = {key: val.squeeze(0) for key, val in encoding.items()}
        item['labels_a'] = torch.tensor(self.labels_a[idx], dtype=torch.long)
        item['labels_b'] = torch.tensor(self.labels_b[idx], dtype=torch.long)
        return item

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# https://huggingface.co/datasets/rajpurkar/squad_v2
splits = {'train': 'squad_v2/train-00000-of-00001.parquet', 'validation': 'squad_v2/validation-00000-of-00001.parquet'}
df_squad_v2 = pd.read_parquet("hf://datasets/rajpurkar/squad_v2/" + splits["train"])

# Pick 150 random questions, then divide in two groups of 100 and 50 to save in two variables
# Double square parenthesis to get a dataframe
sampled_ot_examples = df_squad_v2.sample(150, random_state=34197)[['question']]
sampled_ot_examples.rename(columns={'question': 'Question'}, inplace=True)

sampled_ot_examples['Global Subject'] = 'off_topic'
sampled_ot_examples['Question Intent'] = 'off_topic'

sampled_ot_examples_100 = sampled_ot_examples[:100]
sampled_ot_examples_50 = sampled_ot_examples[100:]

# Load your data
df = pd.read_csv('./labelling/data_cleaned_manual.csv')
ds_automaton = pd.read_csv('./new_questions/automaton_questions.csv')
ds_state = pd.read_csv('./new_questions/state_questions.csv')
ds_transition = pd.read_csv('./new_questions/transition_questions.csv')
ds_grammar = pd.read_csv('./new_questions/grammar_questions.csv')

# Combine datasets
df = pd.concat([df, ds_automaton, ds_state, ds_transition, ds_grammar, sampled_ot_examples_100], ignore_index=True)

# Encode labels
le_gs = LabelEncoder()
df['gs'] = le_gs.fit_transform(df['Global Subject'])

le_qi = LabelEncoder()
df['qi'] = le_qi.fit_transform(df['Question Intent'])

# Split data
train_questions, val_questions, train_labels_gs, val_labels_gs, train_labels_qi, val_labels_qi = train_test_split(
    df['Question'],
    df['gs'],
    df['qi'],
    test_size=0.2,
    random_state=34197,
    stratify=df['gs']
)

# Initialize tokenizer
from transformers import AutoTokenizer

model_name_or_path = 'distilbert-base-uncased'
tokenizer = AutoTokenizer.from_pretrained(model_name_or_path)

# Create datasets
train_dataset = MultiTaskDataset(
    tokenizer=tokenizer,
    texts=train_questions.tolist(),
    labels_a=train_labels_gs.tolist(),
    labels_b=train_labels_qi.tolist(),
    max_length=128
)

val_dataset = MultiTaskDataset(
    tokenizer=tokenizer,
    texts=val_questions.tolist(),
    labels_a=val_labels_gs.tolist(),
    labels_b=val_labels_qi.tolist(),
    max_length=128
)

# Create DataLoaders
from torch.utils.data import DataLoader

batch_size = 16

train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
val_loader = DataLoader(val_dataset, batch_size=batch_size)

# Define model
import torch
from transformers import AutoModel

num_labels_gs = df['gs'].nunique()
num_labels_qi = df['qi'].nunique()

num_labels_dict = {
    'task_a': num_labels_gs,
    'task_b': num_labels_qi
}

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

model = MultiTaskModel(model_name_or_path, num_labels_dict)
model.to(device)

# Define optimizer and loss functions
import torch.optim as optim
import torch.nn.functional as F

optimizer = optim.AdamW(model.parameters(), lr=2e-5, weight_decay=1e-2)
loss_fn_task_a = torch.nn.CrossEntropyLoss()
loss_fn_task_b = torch.nn.CrossEntropyLoss()

# Training loop
from tqdm import tqdm

num_epochs = 20

for epoch in range(num_epochs):
    model.train()
    total_loss = 0
    for batch in tqdm(train_loader, desc=f"Training Epoch {epoch+1}"):
        optimizer.zero_grad()

        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels_a = batch['labels_a'].to(device)
        labels_b = batch['labels_b'].to(device)

        logits = model(input_ids=input_ids, attention_mask=attention_mask)

        loss_a = loss_fn_task_a(logits['task_a'], labels_a)
        loss_b = loss_fn_task_b(logits['task_b'], labels_b)
        loss = loss_a + loss_b

        loss.backward()
        optimizer.step()

        total_loss += loss.item()

    avg_loss = total_loss / len(train_loader)
    print(f"Epoch {epoch+1}/{num_epochs}, Training Loss: {avg_loss:.4f}")

    # Validation
    model.eval()
    correct_a = 0
    total_a = 0
    correct_b = 0
    total_b = 0

    with torch.no_grad():
        for batch in tqdm(val_loader, desc=f"Validation Epoch {epoch+1}"):
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels_a = batch['labels_a'].to(device)
            labels_b = batch['labels_b'].to(device)

            logits = model(input_ids=input_ids, attention_mask=attention_mask)

            preds_a = torch.argmax(logits['task_a'], dim=1)
            correct_a += (preds_a == labels_a).sum().item()
            total_a += labels_a.size(0)

            preds_b = torch.argmax(logits['task_b'], dim=1)
            correct_b += (preds_b == labels_b).sum().item()
            total_b += labels_b.size(0)

    accuracy_a = correct_a / total_a
    accuracy_b = correct_b / total_b
    print(f"Validation Accuracy - Task A: {accuracy_a:.4f}, Task B: {accuracy_b:.4f}")

# Inference example
def predict(model, tokenizer, text):
    model.eval()
    encoding = tokenizer(
        text,
        truncation=True,
        padding='max_length',
        max_length=128,
        return_tensors='pt'
    )
    input_ids = encoding['input_ids'].to(device)
    attention_mask = encoding['attention_mask'].to(device)

    with torch.no_grad():
        logits = model(input_ids=input_ids, attention_mask=attention_mask)

    pred_task_a = torch.argmax(logits['task_a'], dim=1).item()
    pred_task_b = torch.argmax(logits['task_b'], dim=1).item()

    # Decode labels
    global_subject = le_gs.inverse_transform([pred_task_a])[0]
    question_intent = le_qi.inverse_transform([pred_task_b])[0]

    return global_subject, question_intent

# Example usage
text = "What is the capital of France?"
global_subject, question_intent = predict(model, tokenizer, text)
print(f"Predicted Global Subject: {global_subject}")
print(f"Predicted Question Intent: {question_intent}")

torch.save(model.state_dict(), './multi_task_model_distil.pt')