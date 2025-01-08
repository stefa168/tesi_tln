import json
from pathlib import Path


def convert_doccano_to_spacy(input_file: Path, output_file: Path):
    """
    Convert Doccano JSONL format to spaCy training data format.

    Args:
        input_file (str): Path to the input JSONL file containing Doccano annotations.
        output_file (str): Path to the output JSON file to save the converted spaCy training data.

    Returns:
        list: A list of tuples where each tuple contains a text and its corresponding entities.
    """
    training_data = []

    # Open the input file and read line by line
    with open(input_file, 'r', encoding='utf-8') as f:
        # Each line in the file is a JSON object
        for line in f:
            data = json.loads(line)
            text = data['text']
            entities = []
            # Extract entities from the Doccano annotation.
            # Each entity is a tuple containing the start char, end char, and the label type.
            for label in data.get('label', []):
                start_char: int = label[0]
                end_char: int = label[1]
                label_type: str = label[2]
                entities.append((start_char, end_char, label_type))
            training_data.append((text, {"entities": entities}))

    # Save the training data to the output file
    with open(output_file, 'w', encoding='utf-8') as out_f:
        json.dump(training_data, out_f)

    return training_data


input_file = Path('../corpus/ner_labels.jsonl')
output_file = Path('../corpus/spacy_training_data.json')
training_data = convert_doccano_to_spacy(input_file, output_file)
