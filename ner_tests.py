import pandas as pd

df = pd.read_json("ner_data.json")

# Convert the DataFrame to a list of dictionaries
examples = []
for idx, row in df.iterrows():
    examples.append({
        'id': idx,
        'tokens': row['tokens'],  # Convert string representation of list to actual list
        'ner_tags': row['ne'],  # Same for named entity tags
    })

label_list = sorted(list({label for example in examples for label in example['ner_tags']}))
label_to_id = {label: idx for idx, label in enumerate(label_list)}
id_to_label = {idx: label for label, idx in label_to_id.items()}
num_labels = len(label_list)

print("Label List:", label_list)

from transformers import BertTokenizerFast

tokenizer = BertTokenizerFast.from_pretrained('bert-base-cased')

from datasets import Dataset

dataset = Dataset.from_list(examples)

dataset = dataset.train_test_split(test_size=0.2, seed=42)
test_valid = dataset['test'].train_test_split(test_size=0.5, seed=42)

datasets = {
    'train': dataset['train'],
    'validation': test_valid['train'],
    'test': test_valid['test']
}


def tokenize_and_align_labels(examples):
    tokenized_inputs = tokenizer(
        examples['tokens'],
        is_split_into_words=True,
        truncation=True,
        padding='max_length',
        max_length=128  # You can adjust the max_length as needed
    )

    labels = []
    for i, label in enumerate(examples['ner_tags']):
        word_ids = tokenized_inputs.word_ids(batch_index=i)
        label_ids = []
        previous_word_idx = None
        for word_idx in word_ids:
            if word_idx is None:
                # Special tokens have a word_id of None
                label_ids.append(-100)
            elif word_idx != previous_word_idx:
                # Start of a new word
                label_ids.append(label_to_id[label[word_idx]])
            else:
                # Same word as previous token
                if label_all_tokens:
                    label_ids.append(label_to_id[label[word_idx]])
                else:
                    label_ids.append(-100)
            previous_word_idx = word_idx
        labels.append(label_ids)

    tokenized_inputs['labels'] = labels
    return tokenized_inputs


label_all_tokens = True

for split in ['train', 'validation', 'test']:
    datasets[split] = datasets[split].map(
        tokenize_and_align_labels,
        batched=True,
        remove_columns=['tokens', 'ner_tags', 'id']
    )

import torch
from transformers import BertForTokenClassification, TrainingArguments, Trainer

model = BertForTokenClassification.from_pretrained('bert-base-cased', num_labels=num_labels)
model.to('cuda')  # Move model to GPU

training_args = TrainingArguments(
    output_dir='./ner_training_results',  # Output directory
    overwrite_output_dir=True,  # Overwrite the content of the output directory
    num_train_epochs=3,  # Total number of training epochs
    per_device_train_batch_size=16,  # Batch size per device during training
    per_device_eval_batch_size=64,  # Batch size for evaluation
    eval_strategy='epoch',  # Evaluation strategy to adopt during training
    save_strategy='epoch',  # Save the model after each epoch
    logging_dir='./ner_training_results/logs',  # Directory for storing logs
    logging_steps=10,
    load_best_model_at_end=True,
    metric_for_best_model='f1',
)

import numpy as np
from seqeval.metrics import classification_report, f1_score


def compute_metrics(p):
    predictions, labels = p
    predictions = np.argmax(predictions, axis=2)

    true_labels = [[id_to_label[label_id] for label_id in label if label_id != -100]
                   for label in labels]
    true_predictions = [[id_to_label[pred_id] for pred_id, label_id in zip(prediction, label) if label_id != -100]
                        for prediction, label in zip(predictions, labels)]

    results = classification_report(true_labels, true_predictions, output_dict=True)
    return {
        'precision': results['macro avg']['precision'],
        'recall': results['macro avg']['recall'],
        'f1': results['macro avg']['f1-score'],
    }


from transformers import DataCollatorForTokenClassification

data_collator = DataCollatorForTokenClassification(tokenizer)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=datasets['train'],
    eval_dataset=datasets['validation'],
    tokenizer=tokenizer,
    data_collator=data_collator,
    compute_metrics=compute_metrics,
)

trainer.train()

eval_results = trainer.evaluate()
print(eval_results)

test_sentence = "Is there a transition from state A to state B on input '1'?"

# Tokenize the input text
tokenized_input = tokenizer(
    test_sentence,
    return_tensors='pt',
    truncation=True,
    is_split_into_words=False
).to('cuda')  # Move to GPU

# Get model predictions
with torch.no_grad():
    outputs = model(**tokenized_input)

# Get the predicted label IDs
predictions = torch.argmax(outputs.logits, dim=2)

# Convert IDs to labels
pred_labels = [id_to_label[label_id] for label_id in predictions[0].cpu().numpy()]
tokens = tokenizer.convert_ids_to_tokens(tokenized_input['input_ids'][0])

# Combine tokens and labels
results = list(zip(tokens, pred_labels))

final_results = []
for token, label in results:
    if token.startswith('##'):
        # Append subword token to previous token
        final_results[-1] = (final_results[-1][0] + token[2:], label)
    elif token in tokenizer.all_special_tokens:
        continue
    else:
        final_results.append((token, label))

print(final_results)
