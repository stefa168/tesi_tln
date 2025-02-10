import json
import random
import time
from typing import Generator, Literal

import spacy
import wandb
from numpy import ndarray
from spacy.training.example import Example
from spacy.util import minibatch, compounding
import numpy as np
from sklearn.preprocessing import MultiLabelBinarizer
from iterstrat.ml_stratifiers import MultilabelStratifiedShuffleSplit
from pathlib import Path

from wandb.apis.public import Run

SpacyEntity = tuple[int, int, str]


# heh, nerdata ;)
class NERData:
    """
    A class to represent NER data in Doccano JSONL format.
    """

    def __init__(self, line: str):
        data = json.loads(line.strip())

        self.text: str = data['text']

        # Extract entities from the Doccano annotation.
        # Each entity is a tuple containing the start char, end char, and the label type.
        self.labels: list[SpacyEntity] = data.get('label', [])  # List of [start, end, label_name]

        # Extract unique entity labels
        self.entity_labels = list({label for (_, _, label) in self.labels})

    @staticmethod
    def load_jsonl_data(file_path: Path) -> list['NERData']:
        """
        Convert Doccano JSONL format to spaCy training data format.

        Args:
            file_path (str): Path to the input JSONL file containing Doccano annotations.

        Returns:
            list: A list of tuples where each tuple contains a text and its corresponding entities.
        """
        with file_path.open('r', encoding='utf-8') as f:
            return [NERData(line) for line in f]

    def make_example(self, nlp):
        doc = nlp.make_doc(self.text)
        annotations = {"entities": self.labels}

        return Example.from_dict(doc, annotations)


def prepare_multilabel_data(entities: list[NERData]) -> tuple[ndarray, list[str]]:
    """
    Prepare multilabel data for NER entities.

    This function takes a list of NERData objects, extracts their entity labels,
    and converts them into a binary matrix format suitable for multilabel classification.

    :arg entities: A list of NERData objects containing entity labels.

    :returns: A tuple containing the binary matrix and the list of unique entity labels.
    """
    binarizer = MultiLabelBinarizer()

    # Extract entity labels from each NERData object
    all_labels = [e.entity_labels for e in entities]

    # Fit the MultiLabelBinarizer to the extracted labels
    binarizer.fit(all_labels)

    # Transform the labels into a binary matrix format
    label_matrix = binarizer.transform(all_labels)

    # Return the binary matrix and the list of unique entity labels
    return label_matrix, binarizer.classes_


def stratified_split(entities: list[NERData], label_matrix, val_size=0.2, random_state=42) -> tuple[
    list[NERData], list[NERData]
]:
    """
    Perform a stratified split on multilabel data.

    This function uses MultilabelStratifiedShuffleSplit to split the data into training and testing sets,
    ensuring that each label is represented in both sets.

    :arg entities: A list of NERData objects.
    :arg label_binarized: A binary matrix of the entity labels.
    :arg test_size: The proportion of the dataset to include in the test split.
    :arg random_state: The seed used by the random number generator.

    Returns:
        tuple: A tuple containing:
            - train_data (list[NERData]): The training dataset.
            - test_data (list[NERData]): The testing dataset.
    """
    # We use a MultilabelStratifiedShuffleSplit to ensure that each label is sufficiently
    # represented in the training and testing datasets
    msss = MultilabelStratifiedShuffleSplit(n_splits=1, test_size=val_size, random_state=random_state)

    # Perform the split to get train and test indices
    train_indices: ndarray
    test_indices: ndarray
    # We call next() because msss.split() returns a generator of tuples
    train_indices, test_indices = next(msss.split(np.zeros(len(label_matrix)), label_matrix))

    # Create training and testing datasets based on the indices
    train_data: list[NERData] = [entities[i] for i in train_indices]
    test_data: list[NERData] = [entities[i] for i in test_indices]

    # Return the training and testing datasets
    return train_data, test_data


#
#
# NERSpacyData = tuple[str, dict[str, list[SpacyEntity]]]
#
#
# def to_spacy(data: list[NERData]) -> list[NERSpacyData]:
#     spacy_data = []
#
#     for item in data:
#         entities = [label for label in item.labels]
#         spacy_data.append((item.text, {"entities": entities}))
#
#     return spacy_data


def train_spacy(train_data: list[NERData],
                val_data: list[NERData],
                label_list: set[str],
                iterations: int,
                language: str,
                output_path: Path,
                wandb_run: Run):
    """
    Train a spaCy NER model.

    :param train_data: Training data in spaCy format.
    :param val_data: Validation data in spaCy format.
    :param label_list: Set of unique entity labels.
    :param iterations: Number of training iterations.
    :param language: Language of the model.
    :param output_path: Directory to save the trained model to.
    """
    nlp = spacy.blank(language)
    ner = nlp.add_pipe('ner', last=True)

    # Add unique labels to the NER pipeline
    for label in label_list:
        ner.add_label(label)

    # Disable other pipelines during training
    other_pipes = [pipe for pipe in nlp.pipe_names if pipe != 'ner']
    with nlp.disable_pipes(*other_pipes):
        optimizer = nlp.begin_training()

        for itn in range(iterations):
            # Start timing the epoch
            start_time = time.time()

            random.shuffle(train_data)
            losses = {}
            batches = minibatch(items=train_data, size=compounding(4.0, 32.0, 1.001))

            batch: list[NERData]
            for batch in batches:
                examples = [el.make_example(nlp) for el in batch]

                nlp.update(examples, drop=0.5, sgd=optimizer, losses=losses, )

            print(f"Iteration {itn + 1}/{iterations} - Losses: {losses}", end=' ')

            # Evaluate on validation data
            with nlp.use_params(optimizer.averages):
                examples = [el.make_example(nlp) for el in val_data]
                scores = nlp.evaluate(examples)
                print(f"F1-score: {scores['ents_f']:.2f}", end=' ')

            # End timing the epoch
            end_time = time.time()
            epoch_time = end_time - start_time

            print(f"Epoch time: {epoch_time:.2f} seconds")

            wandb.log({
                "iteration": itn + 1,
                "losses": losses,
                "f1_score": scores["ents_f"],
                "precision": scores["ents_p"],
                "recall": scores["ents_r"],
                "ents_per_type": scores["ents_per_type"],
                "epoch_time": epoch_time
            })

    # Save the model
    save_location = Path(output_path)
    save_location.mkdir(parents=True, exist_ok=True)
    nlp.to_disk(output_path)
    print(f"Saved model to {output_path}")

    wandb.save(output_path / "*")


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
