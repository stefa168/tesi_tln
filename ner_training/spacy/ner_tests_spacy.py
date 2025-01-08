from typing import Literal

import spacy
from spacy.training.example import Example
from spacy.util import minibatch, compounding
import random
import json


def load_training_data(training_data_file):
    """
    Load training data from a JSON file.

    Args:
        training_data_file (str): Path to the JSON file containing training data.

    Returns:
        list: A list of training data.
    """
    with open(training_data_file, 'r', encoding='utf-8') as f:
        training_data = json.load(f)
    return training_data


def train_spacy(data, language, iterations, result_model_name, output_dir):
    """
    Train a spaCy NER model.

        :param data: Training data in spaCy format.
        :param iterations: Number of training iterations.
        :param result_model_name: Name of the trained model.
        :param output_dir: Directory to save the trained model to.
    """
    nlp = spacy.blank(language)  # Create a blank Language class
    if 'ner' not in nlp.pipe_names:
        ner = nlp.add_pipe('ner', last=True)  # Add NER pipeline if not present
    else:
        ner = nlp.get_pipe('ner')

    # Find all possible labels and add them to the NER pipeline
    for _, annotations in data:
        for ent in annotations.get('entities'):
            ner.add_label(ent[2])

    # Disable other pipelines during training
    other_pipes = [pipe for pipe in nlp.pipe_names if pipe != 'ner']
    with nlp.disable_pipes(*other_pipes):
        # Initialize the model with random weights
        optimizer = nlp.begin_training()

        for itn in range(iterations):
            random.shuffle(data)  # Shuffle the training data
            losses = {}
            # Create batches of training data
            batches = minibatch(data, size=compounding(4.0, 32.0, 1.001))
            for batch in batches:
                examples = []
                for text, annotations in batch:
                    doc = nlp.make_doc(text)
                    example = Example.from_dict(doc, annotations)
                    examples.append(example)
                # Update the model with the current batch
                nlp.update(
                    examples,
                    drop=0.5,  # Dropout rate
                    sgd=optimizer,
                    losses=losses,
                )
            print(f"Iteration {itn + 1}/{iterations} - Losses: {losses}")

    save_location = f'../{output_dir}/{result_model_name}'

    # Save the trained model to the specified directory
    nlp.to_disk(save_location)
    print(f"Saved model to {save_location}")


def init_spacy_device(device: Literal['cpu', 'prefer_gpu', 'gpu'] = 'prefer_gpu') -> bool:
    """
    Initialize spaCy with the specified device.

    Args:
        device (str): Device to use for spaCy. Can be 'cpu', 'gpu', or 'prefer_gpu'.

    Returns:
        bool: True if the device was successfully initialized, False otherwise.
    """
    if device == 'cpu':
        return spacy.require_cpu()
    elif device == 'gpu':
        return spacy.require_gpu()
    else:
        if not spacy.prefer_gpu():
            print("WARNING: GPU not available. Using CPU for spaCy. Check if CUDA and Cupy are installed.")

            return spacy.require_cpu()
        else:
            return True


# Example usage:
training_data_file = '../corpus/spacy_training_data.json'
training_data = load_training_data(training_data_file)

init_spacy_device()

train_spacy(training_data, language="en", iterations=20, output_dir='ner_model2', result_model_name="ner_model2")
