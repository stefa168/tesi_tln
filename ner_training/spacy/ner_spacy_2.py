import json
import random
import spacy
from spacy.training.example import Example
from spacy.util import minibatch, compounding
import numpy as np
from sklearn.preprocessing import MultiLabelBinarizer
from iterstrat.ml_stratifiers import MultilabelStratifiedShuffleSplit
from pathlib import Path

def load_data(file_path):
    entities = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line.strip())
            text = data['text']
            labels = data.get('label', [])  # List of [start, end, label_name]
            entity_labels = set()
            for start, end, label in labels:
                entity_labels.add(label)
            entities.append({'text': text, 'labels': labels, 'entity_labels': list(entity_labels)})
    return entities

def prepare_multilabel_data(entities):
    mlb = MultiLabelBinarizer()
    all_labels = [e['entity_labels'] for e in entities]
    mlb.fit(all_labels)
    label_binarized = mlb.transform(all_labels)
    return label_binarized, mlb.classes_

def stratified_split(entities, label_binarized, test_size=0.2, random_state=42):
    msss = MultilabelStratifiedShuffleSplit(n_splits=1, test_size=test_size, random_state=random_state)
    train_indices, test_indices = next(msss.split(np.zeros(len(label_binarized)), label_binarized))
    train_data = [entities[i] for i in train_indices]
    test_data = [entities[i] for i in test_indices]
    return train_data, test_data

def convert_to_spacy_format(data):
    spacy_data = []
    for item in data:
        text = item['text']
        entities = []
        for start, end, label in item['labels']:
            entities.append((start, end, label))
        spacy_data.append((text, {"entities": entities}))
    return spacy_data

def train_spacy(train_data, val_data, iterations, output_dir):
    nlp = spacy.blank('en')
    ner = nlp.add_pipe('ner', last=True)

    # Add labels
    for _, annotations in train_data:
        for ent in annotations.get('entities'):
            ner.add_label(ent[2])

    # Disable other pipelines during training
    other_pipes = [pipe for pipe in nlp.pipe_names if pipe != 'ner']
    with nlp.disable_pipes(*other_pipes):
        optimizer = nlp.begin_training()

        for itn in range(iterations):
            random.shuffle(train_data)
            losses = {}
            batches = minibatch(train_data, size=compounding(4.0, 32.0, 1.001))
            for batch in batches:
                examples = []
                for text, annotations in batch:
                    doc = nlp.make_doc(text)
                    example = Example.from_dict(doc, annotations)
                    examples.append(example)
                nlp.update(
                    examples,
                    drop=0.5,
                    sgd=optimizer,
                    losses=losses,
                )
            print(f"Iteration {itn + 1}/{iterations} - Losses: {losses}")
            # Evaluate on validation data
            with nlp.use_params(optimizer.averages):
                examples = []
                for text, annotations in val_data:
                    doc = nlp.make_doc(text)
                    example = Example.from_dict(doc, annotations)
                    examples.append(example)
                scores = nlp.evaluate(examples)
                print(f"Validation F1-score: {scores['ents_f']:.2f}")

    # Save the model
    if output_dir is not None:
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        nlp.to_disk(output_dir)
        print(f"Saved model to {output_dir}")

script_dir = Path(__file__).resolve().parent
input_file = script_dir / '../corpus/ner_labels.jsonl'
input_file = str(input_file.resolve())

entities = load_data(input_file)
label_binarized, all_classes = prepare_multilabel_data(entities)
train_entities, test_entities = stratified_split(entities, label_binarized, test_size=0.2, random_state=42)

# Convert to spaCy format
train_data = convert_to_spacy_format(train_entities)
val_data = convert_to_spacy_format(test_entities)

# Train the model
output_dir = script_dir / 'ner_model'
train_spacy(train_data, val_data, iterations=20, output_dir=str(output_dir.resolve()))
