import torch

from system.compiler.config import ModelType, CompilerConfig
from system.compiler.fine_tuning import train_model


def main():
    config = CompilerConfig.load_from_file('./test_config.yml')

    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    print(f"Current CUDA device: {torch.cuda.current_device()}")
    print(f"Device name: {torch.cuda.get_device_name(torch.cuda.current_device())}")

    for model_config in config.models:
        if model_config.type == ModelType.BERT:
            train_model(model_config)
        elif model_config.type == ModelType.SPACY_NER:
            # train_spacy_ner_model(model_config)
            pass
        else:
            raise ValueError(f"Unknown model type: {model_config.type}")


if __name__ == '__main__':
    main()
