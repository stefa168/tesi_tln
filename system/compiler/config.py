from enum import Enum
from pathlib import Path
from typing import List

import yaml
from pydantic import BaseModel


class ModelType(Enum):
    BERT = "bert"
    SPACY_NER = "spacy_ner"


class ColumnsConfig(BaseModel):
    """
    Configuration for the dataset columns.

    Attributes:
        examples_column (str): The name of the column containing the examples.
        labels_column (str): The name of the column containing the labels.
        map_split_on (str, optional): The name of the column to split the dataset on. Defaults to None.
    """
    examples_column: str
    labels_column: str
    map_split_on: str = None


class ModelConfig(BaseModel):
    """
    Model configuration object.

    Attributes:
        name (str): The name of the model.
        type (ModelType): The type of the model, restricted to values defined in the ModelType enum.
        pretrained_model (str, optional): The name of the pretrained model to use. Defaults to None.
        dataset_path (pathlib.Path): The path to the dataset to use for training.
        columns (ColumnsConfig): The configuration for the dataset columns that are needed for training.
    """
    name: str
    type: ModelType
    pretrained_model: str = None
    dataset_path: Path
    columns: ColumnsConfig


class CompilerConfig(BaseModel):
    """
    Compiler configuration object.

    Attributes:
        models (List[ModelConfig]): A list of model configurations.
    """
    models: List[ModelConfig]

    @staticmethod
    def load_from_file(file_path: str) -> 'CompilerConfig':
        """
        Load the compiler configuration from a YAML file.

        Args:
            file_path (str): The path to the YAML configuration file.

        Returns:
            CompilerConfig: The loaded compiler configuration.
        """
        with open(file_path, 'r') as file:
            config_data = yaml.safe_load(file)
        return CompilerConfig(**config_data)
