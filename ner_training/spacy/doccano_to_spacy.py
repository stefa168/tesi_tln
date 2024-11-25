import json

def convert_doccano_to_spacy(input_file, output_file):
    training_data = []

    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            text = data['text']
            entities = []
            for label in data.get('label', []):
                start_char = label[0]
                end_char = label[1]
                label_type = label[2]
                entities.append((start_char, end_char, label_type))
            training_data.append((text, {"entities": entities}))

    # Save the training data
    with open(output_file, 'w', encoding='utf-8') as out_f:
        json.dump(training_data, out_f)

    return training_data

input_file = '../corpus/ner_labels.jsonl'
output_file = '../corpus/spacy_training_data.json'
training_data = convert_doccano_to_spacy(input_file, output_file)
