import pandas as pd
import torch
from transformers import AutoTokenizer

from system.compiler.config import ModelType, ModelConfig, CompilerConfig
from system.compiler.fine_tuning import run_fine_tuning, LabelInfo, prepare_dataset, prepare_model


def main():
    # Usage
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


def train_model(model_config: ModelConfig):
    """
    Trains a model using the provided dataset and configuration.

    Args:
        model_config (ModelConfig): The configuration for the model.

    Returns:
        None
    """

    # Load the dataset
    df = pd.read_csv(model_config.dataset_path)

    # Create a LabelInfo object using the dataset and the labels column
    labels_column = model_config.columns.labels_column
    label_info = LabelInfo(df, labels_column)

    # Prepare the model using the base model name and label information
    pretrained_model_name = model_config.pretrained_model
    model = prepare_model(pretrained_model_name, label_info)

    # Load the tokenizer for the base model
    tokenizer = AutoTokenizer.from_pretrained(pretrained_model_name)

    # Prepare the training and evaluation datasets
    examples_column = model_config.columns.examples_column
    train_dataset, eval_dataset = prepare_dataset(df, tokenizer, label_info, examples_column, labels_column)

    # Run the fine-tuning process on the model
    trainer = run_fine_tuning(model, tokenizer, train_dataset, eval_dataset)

    # Save the trained model to the specified path
    trainer.save_model(f'./results/{model_config.name}')


if __name__ == '__main__':
    main()
