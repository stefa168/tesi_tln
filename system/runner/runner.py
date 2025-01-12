import logging
import time
from pathlib import Path

import torch
from transformers import AutoTokenizer, PreTrainedModel, PreTrainedTokenizer, BertForSequenceClassification, pipeline, \
    Pipeline

from system.common.config import CompilerConfigV2, Interaction, Reply

# Initialize logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class ModelComponents:
    def __init__(self, model: PreTrainedModel, tokenizer: PreTrainedTokenizer, classifier: Pipeline):
        self.model = model
        self.tokenizer = tokenizer
        self.classifier = classifier

    def classify(self, text: str) -> str:
        logger.debug(f"Using model: {self.model.config.name_or_path} to classify: \"{text}\"...")

        start_time = time.time()
        predict = self.classifier.predict(text)[0]
        end_time = time.time()

        logger.debug(f"Classification took {end_time - start_time} seconds. It returned: {predict}")

        return predict[0]["label"]

    def __repr__(self):
        return f"ModelTokenizerPair(model={self.model}, tokenizer={self.tokenizer})"


def load_models(conf_artifact_path: Path, root_interaction: Interaction) -> dict[str, ModelComponents]:
    def load_model(model_name: str, conf_artifact_path: Path, subdir: str = "trained_model") -> ModelComponents:
        path = conf_artifact_path / model_name / subdir
        model = BertForSequenceClassification.from_pretrained(path)
        tokenizer = AutoTokenizer.from_pretrained(path)
        classifier = pipeline(model=model, tokenizer=tokenizer, task="text-classification", top_k=None,
                              device=torch.cuda.current_device())
        return ModelComponents(model, tokenizer, classifier)

    required_models = root_interaction.discover_model_names()
    models: dict[str, ModelComponents] = {}
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

        next_interaction: Interaction | Reply = config.interaction
        interaction_traversal_stack: list[(str, Interaction | Reply)] = [("root", next_interaction)]

        while True:
            interaction_model = models[next_interaction.use]
            predicted_interaction_branch = interaction_model.classify(user_input)
            next_interaction = next_interaction.cases[predicted_interaction_branch]
            interaction_traversal_stack.append((predicted_interaction_branch, next_interaction))

            if isinstance(next_interaction, Reply):
                r: Reply = next_interaction

                stack = [(i[0], f"{type(i[1]).__name__}: {i[1].name}") for i in interaction_traversal_stack]
                logger.info(f"Stack: {stack}")

                print(f"Reply: {r.get_reply()}")
                break


if __name__ == '__main__':
    main()
