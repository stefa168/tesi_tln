import spacy

nlp = spacy.load('ner_model')

test_texts = [
    "Is there a transition between q2 and q0?",
    "What is the transition between q1 and q2?",
    "What happens if we input a 1 to q1?",
    "What happens if we input a 1 to q100?",
    "Do we have an 'epsilon' from q0 to q1?",
]

for test_text in test_texts:
    doc = nlp(test_text)
    print(f"Entities in '{test_text}':")
    for ent in doc.ents:
        print(ent.text, ent.start_char, ent.end_char, ent.label_)
