import spacy
from spacy.training.example import Example
from spacy.util import minibatch, compounding
import random
import json

def load_training_data(training_data_file):
    with open(training_data_file, 'r', encoding='utf-8') as f:
        training_data = json.load(f)
    return training_data

def train_spacy(data, iterations, output_dir):
    nlp = spacy.blank('en')  # Create a blank Language class
    if 'ner' not in nlp.pipe_names:
        ner = nlp.add_pipe('ner', last=True)
    else:
        ner = nlp.get_pipe('ner')

    # Add labels
    for _, annotations in data:
        for ent in annotations.get('entities'):
            ner.add_label(ent[2])

    # Disable other pipelines during training
    other_pipes = [pipe for pipe in nlp.pipe_names if pipe != 'ner']
    with nlp.disable_pipes(*other_pipes):
        # Initialize the model with random weights
        optimizer = nlp.begin_training()

        for itn in range(iterations):
            random.shuffle(data)
            losses = {}
            batches = minibatch(data, size=compounding(4.0, 32.0, 1.001))
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

    # Save the model
    if output_dir is not None:
        nlp.to_disk(output_dir)
        print(f"Saved model to {output_dir}")

# Example usage:
training_data_file = '../corpus/spacy_training_data.json'
training_data = load_training_data(training_data_file)
train_spacy(training_data, iterations=20, output_dir='ner_model')
