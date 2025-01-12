import time
from pathlib import Path
from pprint import pprint

import torch

from system.common.config import CompilerConfigV2, Interaction, Reply
from transformers import AutoTokenizer, PreTrainedModel, PreTrainedTokenizer, BertForSequenceClassification, pipeline, \
    Pipeline


class ModelTokenizerPair:
    def __init__(self, model: PreTrainedModel, tokenizer: PreTrainedTokenizer, classifier: Pipeline):
        self.model = model
        self.tokenizer = tokenizer
        self.classifier = classifier

    def classify(self, text: str) -> str:
        print(f"Using model: {self.model.config.name_or_path} to classify: \"{text}\"...")

        start_time = time.time()
        predict = self.classifier.predict(text)[0]
        end_time = time.time()

        print(f"Classification took {end_time - start_time} seconds.\nIt returned: {predict}")

        return predict[0]["label"]

    def __repr__(self):
        return f"ModelTokenizerPair(model={self.model}, tokenizer={self.tokenizer})"


def load_models(conf_artifact_path: Path, root_interaction: Interaction) -> dict[str, ModelTokenizerPair]:
    def load_model(model_name: str, conf_artifact_path: Path, subdir: str = "trained_model") -> ModelTokenizerPair:
        path = conf_artifact_path / model_name / subdir
        model = BertForSequenceClassification.from_pretrained(path)
        tokenizer = AutoTokenizer.from_pretrained(path)
        classifier = pipeline(model=model, tokenizer=tokenizer, task="text-classification", top_k=None,
                              device=torch.cuda.current_device())
        return ModelTokenizerPair(model, tokenizer, classifier)

    required_models = root_interaction.discover_model_names()
    models: dict[str, ModelTokenizerPair] = {}
    for r in required_models:
        models[r] = load_model(r, conf_artifact_path)

    return models


def main():
    artifacts_dir = Path("../compiler/artifacts")
    config = CompilerConfigV2.load_from_file('../compiler/test_config v2.yml')
    conf_artifact_path = artifacts_dir / config.name

    models = load_models(conf_artifact_path, config.interaction)

    while True:
        user_input = input("Enter a prompt: ")
        if user_input == "exit":
            break

        interaction_traversal_stack: list[Interaction | Reply] = []
        next_interaction: Interaction | Reply = config.interaction

        while True:
            interaction_traversal_stack.append(next_interaction)
            interaction_model = models[next_interaction.use]
            predicted_interaction_branch = interaction_model.classify(user_input)
            next_interaction = next_interaction.cases[predicted_interaction_branch]

            if isinstance(next_interaction, Reply):
                r: Reply = next_interaction
                print(f"Stack: {repr(map(lambda i: i.name, interaction_traversal_stack))}")
                print(f"Reply: {r.get_reply()}")
                break


if __name__ == '__main__':
    main()
