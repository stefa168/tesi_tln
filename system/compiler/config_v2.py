import json
from abc import ABC, abstractmethod
from enum import Enum
from pathlib import Path
from typing import Literal, Any, Union

import pandas as pd
import yaml
from pandas import DataFrame
from pydantic import BaseModel
from transformers import AutoTokenizer, Trainer, PreTrainedTokenizerBase, PreTrainedModel

from system.compiler.fine_tuning import LabelInfo, prepare_model, prepare_dataset, run_fine_tuning

ARTIFACTS_BASE_DIR = Path("artifacts")

# Registry for step execution functions
STEP_REGISTRY = {}


def register_step(step_cls: type["Step"]):
    if not issubclass(step_cls, Step):
        raise ValueError("Only subclasses of Step can be registered.")

    if step_cls.__name__ in STEP_REGISTRY:
        raise ValueError(f"Step '{step_cls.__name__}' is already registered.")

    STEP_REGISTRY[step_cls.__name__] = step_cls
    return step_cls


class StepType(str, Enum):
    LOAD_CSV = "load_csv"
    SPLIT_DATA = "split_data"
    TRAIN_MODEL = "train_model"
    MAP = "map"
    EVALUATE_MODELS = "evaluate_models"


# define step execution error:
class StepExecutionError(Exception):
    pass


def get_item_by_path(obj: dict[str, Any], path: str) -> Any:
    """
    Get an item from a nested dictionary using a path string.

    Args:
        obj (dict): The dictionary to search.
        path (str): The path to the item.

    Returns:
        Any: The item at the specified path.
    """
    keys = path.split(".")
    for key in keys:
        obj = obj[key]
    return obj


class Step(BaseModel, ABC):
    name: str
    type: str
    description: str | None = None

    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, Any]:
        """
        Expect and retrieve the inputs for the step from the context.
        """

        # expect to have a "model_metadata" key in the context.
        if "model_metadata" not in context:
            raise StepExecutionError("Model metadata not found in context.")

        return context

    @abstractmethod
    def execute(self, inputs: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        """
        Execute the step and return its output.
        """
        pass

    def verify_execution(self, outputs: dict[str, Any]) -> dict[str, Any]:
        """
        Checks to run on the output of the step after its execution.
        """
        return outputs


@register_step
class LoadCsvStep(Step):
    type: Literal["load_csv"]
    path: Path

    def execute(self, inputs: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        df = pd.read_csv(self.path)

        return {"dataframe": df}

    def verify_execution(self, outputs: dict[str, Any]) -> dict[str, Any]:
        df = outputs["dataframe"]

        if not isinstance(df, pd.DataFrame):
            raise StepExecutionError("Output is not a pandas DataFrame.")

        return {"dataframe": df}


@register_step
class SplitDataStep(Step):
    type: Literal["split_data"]
    dataframe: str
    on_column: str

    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, pd.DataFrame]:
        super().resolve_requirements(context)

        step_name, df_name = self.dataframe.split(".", 1)

        if step_name not in context:
            raise StepExecutionError(f"Step '{step_name}' not found in context.")

        if df_name not in context[step_name]:
            raise StepExecutionError(f"Dataframe '{df_name}' not found in context of step '{step_name}'.")

        df = context[step_name][df_name]

        if not isinstance(df, pd.DataFrame):
            raise StepExecutionError(f"Object '{self.dataframe}' is not a pandas DataFrame.")

        if self.on_column not in df.columns:
            raise StepExecutionError(f"Column '{self.on_column}' not found in dataframe.")

        return {"dataframe": df}

    def execute(self, inputs: dict[str, Any], context: dict[str, Any]) -> dict[str, dict[str, DataFrame]]:
        df = inputs["dataframe"]

        subsets: dict[str, pd.DataFrame] = {group: data for group, data in df.groupby(self.on_column)}
        return {"subsets": subsets}

    def verify_execution(self, outputs: dict[str, Any]) -> dict[str, dict[str, pd.DataFrame]]:
        subsets = outputs["subsets"]

        if not all(isinstance(v, pd.DataFrame) for v in subsets.values()):
            raise StepExecutionError("Values in the dictionary are not pandas DataFrames.")

        return outputs


@register_step
class TrainModelStep(Step):
    type: Literal["train_model"]
    dataframe: str
    pretrained_model: str
    labels_column: str
    examples_column: str

    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, Any]:
        super().resolve_requirements(context)

        step_name, df_name = self.dataframe.split(".", 1)

        if step_name not in context:
            raise StepExecutionError(f"Step '{step_name}' not found in context.")

        if df_name not in context[step_name]:
            raise StepExecutionError(f"Dataframe '{df_name}' not found in context of step '{step_name}'.")

        df = context[step_name][df_name]

        if not isinstance(df, pd.DataFrame):
            raise StepExecutionError(f"Object '{self.dataframe}' is not a pandas DataFrame.")

        if self.labels_column not in df.columns:
            raise StepExecutionError(f"Training Labels Column '{self.labels_column}' not found in dataframe.")

        if self.examples_column not in df.columns:
            raise StepExecutionError(f"Training Examples Column '{self.examples_column}' not found in dataframe.")

        return {"dataframe": df}

    def execute(self, inputs: dict[str, Any], context: dict[str, dict[str, Any]]) -> dict[str, Any]:
        df = inputs["dataframe"]
        model_pipeline_name: str = context["model_metadata"]["name"]

        model_pipeline_path = ARTIFACTS_BASE_DIR / model_pipeline_name / "trained_model"

        # Check if the model is cached
        # todo check the checksum of the input data to determine if the model is still valid; same thing for the
        #  configuration of the model if it has changed
        if not model_pipeline_path.exists():
            model_pipeline_path.mkdir(parents=True, exist_ok=True)

            # Create a LabelInfo object using the dataset and the labels column
            label_info = LabelInfo(df, self.labels_column)

            # Prepare the model using the base model name and label information
            base_model = prepare_model(self.pretrained_model, label_info)

            # Load the tokenizer for the base model
            tokenizer = AutoTokenizer.from_pretrained(self.pretrained_model)

            # Prepare the training and evaluation datasets
            train_dataset, eval_dataset = prepare_dataset(df, tokenizer, label_info,
                                                          self.examples_column,
                                                          self.labels_column)

            # Run the fine-tuning process on the model
            trainer = run_fine_tuning(base_model, tokenizer, train_dataset, eval_dataset)

            # Save the model
            trainer.save_model(model_pipeline_path.as_posix())

            return {"base_model": base_model, "tokenizer": tokenizer, "trainer": trainer, "cached": False}

        return {"base_model": None, "tokenizer": None, "trainer": None, "cached": True}

    def verify_execution(self, outputs: dict[str, Any]) -> dict[str, Any]:
        cached: bool = outputs["cached"]

        if not cached:
            base_model: PreTrainedModel = outputs["base_model"]
            tokenizer: PreTrainedTokenizerBase = outputs["tokenizer"]
            trainer: Trainer = outputs["trainer"]

            if not isinstance(base_model, PreTrainedModel):
                raise StepExecutionError("Output is not a model.")

            if not isinstance(tokenizer, PreTrainedTokenizerBase):
                raise StepExecutionError("Output is not a tokenizer.")

            if not isinstance(trainer, Trainer):
                raise StepExecutionError("Output is not a trainer.")

        return outputs


StepUnion = Union[tuple(STEP_REGISTRY.values())]


class Model(BaseModel):
    name: str
    steps: list[StepUnion]


class CompilerConfigV2(BaseModel):
    name: str
    models: list[Model]

    @staticmethod
    def load_from_file(file_path: str) -> 'CompilerConfigV2':
        """
        Load the compiler configuration from a YAML file.

        Args:
            file_path (str): The path to the YAML configuration file.

        Returns:
            CompilerConfig: The loaded compiler configuration.
        """
        with open(file_path, 'r') as file:
            config_data = yaml.safe_load(file)
            return CompilerConfigV2(**config_data)


def save_schema_to_file(filepath: str):
    schema = CompilerConfigV2.model_json_schema()
    with open(filepath, "w") as f:
        # noinspection PyTypeChecker
        json.dump(schema, f, indent=2)
    print(f"JSON Schema saved to {filepath}")


if __name__ == '__main__':
    save_schema_to_file("step_config_schema.json")
