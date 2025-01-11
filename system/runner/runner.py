from pathlib import Path
from pprint import pprint

from system.common.config import CompilerConfigV2, Interaction
from transformers import AutoModel, AutoTokenizer


class ModelTokenizerPair:
    def __init__(self, model: AutoModel, tokenizer: AutoTokenizer):
        self.model = model
        self.tokenizer = tokenizer

    def __repr__(self):
        return f"ModelTokenizerPair(model={self.model}, tokenizer={self.tokenizer})"


def load_models(conf_artifact_path: Path, root_interaction: Interaction) -> dict[str, ModelTokenizerPair]:
    def load_model(model_name: str, conf_artifact_path: Path, subdir: str = "trained_model") -> ModelTokenizerPair:
        path = conf_artifact_path / model_name / subdir
        model = AutoModel.from_pretrained(path)
        tokenizer = AutoTokenizer.from_pretrained(path)
        return ModelTokenizerPair(model, tokenizer)

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

    pprint(models)


if __name__ == '__main__':
    main()
