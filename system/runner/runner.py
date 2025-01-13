import logging
import time
from pathlib import Path
from typing import TypedDict

import torch
from transformers import AutoTokenizer, PreTrainedModel, PreTrainedTokenizer, BertForSequenceClassification, pipeline, \
    Pipeline

from system.common.config import CompilerConfigV2, Interaction, Reply

# Initialize logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class Prediction(TypedDict):
    label: str
    prediction: float


class ModelComponents:
    def __init__(self, model: PreTrainedModel, tokenizer: PreTrainedTokenizer, classifier: Pipeline):
        self.model = model
        self.tokenizer = tokenizer
        self.classifier = classifier

    def classify(self, text: str) -> list[Prediction]:
        logger.debug(f"Using model: {self.model.config.name_or_path} to classify: \"{text}\"...")

        start_time = time.time()
        # The Pipeline object implements __call__, so this is valid.
        # The object returned is
        predictions: list[Prediction] = self.classifier(text)[0]
        end_time = time.time()

        logger.debug(f"Classification took {end_time - start_time} seconds. It returned: {predictions}")

        return predictions

    def __repr__(self):
        return f"ModelTokenizerPair(model={self.model}, tokenizer={self.tokenizer})"

def load_models(conf_artifact_path: Path, root_interaction: Interaction) -> dict[str, ModelComponents]:
    def load_model(model_name: str, conf_artifact_path: Path, subdir: str = "trained_model") -> ModelComponents:
        try:
            path = conf_artifact_path / model_name / subdir
            model = BertForSequenceClassification.from_pretrained(path)
            tokenizer = AutoTokenizer.from_pretrained(path)
            classifier = pipeline(model=model, tokenizer=tokenizer, task="text-classification",
                                  top_k=None,  # by setting top_k to None we get all the predictions.
                                  device=torch.cuda.current_device())
            return ModelComponents(model, tokenizer, classifier)
        except Exception as er:
            logger.error(f"Error loading model '{model_name}': {er}")
            raise

    required_models = root_interaction.discover_resources_to_load()
    models: dict[str, ModelComponents] = {}
    errors = []

    for r in required_models:
        try:
            models[r] = load_model(r, conf_artifact_path)
        except Exception as e:
            errors.append(f"Model '{r}' failed to load: {e}")

    if errors:
        error_message = "\n".join(errors)
        logger.error(f"Failed to load all required models:\n{error_message}")
        raise RuntimeError(f"Startup process halted due to model loading errors:\n{error_message}")

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
            predictions = interaction_model.classify(user_input)
            next_interaction = next_interaction.cases[predictions[0]["label"]]

            interaction_traversal_stack.append((predictions, next_interaction))

            if isinstance(next_interaction, Reply):
                r: Reply = next_interaction

                stack = [(i[0], f"{type(i[1]).__name__}: {i[1].name}") for i in interaction_traversal_stack]
                logger.info(f"Stack: {stack}")

                print(f"Reply: {r.get_reply()}")
                break


if __name__ == '__main__':
    main()
