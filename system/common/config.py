import json
import re
from abc import ABC, abstractmethod
from enum import Enum
from pathlib import Path
from typing import Literal, Any, Union

import pandas as pd
import yaml
from pydantic import BaseModel, Field
from transformers import AutoTokenizer, Trainer, PreTrainedTokenizerBase, PreTrainedModel

from system.compiler.fine_tuning import LabelInfo, prepare_model, prepare_dataset, run_fine_tuning
from system.compiler.spacy_ner import NERData, init_spacy_device, prepare_multilabel_data, stratified_split, train_spacy

ARTIFACTS_BASE_DIR = Path("../compiler/artifacts")

# Registry for step execution functions
STEP_REGISTRY = {}


def register_step(step_cls: type["Step"]):
    if not issubclass(step_cls, Step):
        raise ValueError("Only subclasses of Step can be registered.")

    if step_cls.__name__ in STEP_REGISTRY:
        raise ValueError(f"Step '{step_cls.__name__}' is already registered.")

    STEP_REGISTRY[step_cls.__name__] = step_cls
    return step_cls


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

        if "config" not in context:
            raise StepExecutionError("Global Configuration metadata not found in context.")

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
    for_each: list["StepUnion"]

    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, pd.DataFrame]:
        context = super().resolve_requirements(context)

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

    def execute(self, inputs: dict[str, Any], context: dict[str, Any]) -> dict[str, dict[str, Any]]:
        df = inputs["dataframe"]

        splits: list[str] = df[self.on_column].unique()

        split_base_context = {
            "parent_context": context,
            "model_metadata": context["model_metadata"],
            "config": context["config"]
        }

        split_results = {}
        for split in splits:
            print(f"Processing split '{split}'")
            split_df = df[df[self.on_column] == split]
            split_context = split_base_context.copy()

            split_context["on_column"] = split
            split_context[self.name] = {"dataframe": split_df}

            for step in self.for_each:
                retrieved_inputs = step.resolve_requirements(split_context)
                execution_results = step.execute(retrieved_inputs, split_context)

                if "break" in execution_results:
                    print(f"Breaking execution at step '{step.name}'")
                    break

                checked_outputs = step.verify_execution(execution_results)

                split_base_context[step.name] = checked_outputs

            split_results[split] = split_base_context

        return {"split_contexts": split_results, }

    def verify_execution(self, outputs: dict[str, Any]) -> dict[str, dict[str, pd.DataFrame]]:
        split_contexts = outputs["split_contexts"]

        for split, context in split_contexts.items():
            for step in self.for_each:
                step_outputs = context[step.name]

                if "break" in step_outputs:
                    continue

                step.verify_execution(step_outputs)

        return {"split_contexts": split_contexts}


@register_step
class TrainModelStep(Step):
    type: Literal["train_model"]
    dataframe: str
    pretrained_model: str
    labels_column: str
    examples_column: str
    resulting_model_name: str | None = None

    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, Any]:
        context = super().resolve_requirements(context)

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

        config_name: str = context["config"]["name"]

        if self.resulting_model_name is None:
            model_pipeline_name: str = context["model_metadata"]["name"]
        else:
            def find_template_variables(template: str) -> list[str]:
                # Regular expression to find all {variables} in the template
                pattern = r'(?<!\\)\{(\w+)\}'
                matches = re.findall(pattern, template)
                return matches

            # Find all variables in the model name
            variables = find_template_variables(self.resulting_model_name)
            if len(variables) > 0:
                # Replace all variables with their values
                # todo resolve nested variables
                model_pipeline_name = self.resulting_model_name.format(**context)
            else:
                model_pipeline_name = self.resulting_model_name

        model_pipeline_path = ARTIFACTS_BASE_DIR / config_name / model_pipeline_name / "trained_model"

        # Check if the model is cached
        # todo check the checksum of the input data to determine if the model is still valid; same thing for the
        #  configuration of the model if it has changed
        if model_pipeline_path.exists() and any(model_pipeline_path.iterdir()):
            print(f"Model '{model_pipeline_name}' already exists. Skipping step!")
        else:
            model_pipeline_path.mkdir(parents=True, exist_ok=True)

            # Create a LabelInfo object using the dataset and the labels column
            label_info = LabelInfo(df, self.labels_column)

            if len(label_info) == 1:
                print("Only one label found in the dataset. Please check the dataset and labels column.")
                return {"break": True}
                # raise StepExecutionError("Only one label found in the dataset. Please check the dataset and labels column.")

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


@register_step
class NerSpacy(Step):
    type: Literal["ner_spacy"]
    language: str = Field("en", min_length=1)
    training_data_path: Path = Field(..., min_length=1)
    iterations: int = Field(20, ge=1)
    training_device: Literal['cpu', 'prefer_gpu', 'gpu'] = Field('prefer_gpu')
    resulting_model_name: str | None = None

    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, Any]:
        context = super().resolve_requirements(context)

        init_spacy_device(self.training_device)

        if not self.training_data_path.exists():
            raise StepExecutionError(f"Training data not found at '{self.training_data_path}'")

        return context

    def execute(self, inputs: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        config_name: str = context["config"]["name"]

        if self.resulting_model_name is None:
            model_pipeline_name: str = context["model_metadata"]["name"]
        else:
            def find_template_variables(template: str) -> list[str]:
                # Regular expression to find all {variables} in the template
                pattern = r'(?<!\\)\{(\w+)\}'
                matches = re.findall(pattern, template)
                return matches

            # Find all variables in the model name
            variables = find_template_variables(self.resulting_model_name)
            if len(variables) > 0:
                # Replace all variables with their values
                # todo resolve nested variables
                model_pipeline_name = self.resulting_model_name.format(**context)
            else:
                model_pipeline_name = self.resulting_model_name

        model_pipeline_path = ARTIFACTS_BASE_DIR / config_name / model_pipeline_name / "trained_model"

        data = NERData.load_jsonl_data(self.training_data_path)
        label_matrix, label_list = prepare_multilabel_data(data)
        train_data, val_data = stratified_split(data, label_matrix)
        train_spacy(train_data, val_data, self.iterations, self.language, model_pipeline_path)

        return {}


StepUnion = Union[tuple(STEP_REGISTRY.values())]


class Model(BaseModel):
    name: str = Field(..., min_length=1, description="The name of the model.")
    disabled: bool = Field(False, description="Whether model training should be disabled.")
    steps: list[StepUnion] = Field(..., min_length=1, description="The steps to execute for training the model.")
    type: Literal["classification", "ner"] = Field(..., description="The type of the model.")


class Reply(BaseModel):
    reply: str | list[str] = Field(..., description="The reply to send to the user.")


class Interaction(BaseModel):
    use: str = Field(..., min_length=1, description="The model to use to produce a branching interaction.")
    name: str = Field(..., min_length=1, description="The name of the interaction node.")
    cases: dict[str, Union["Interaction", Reply]] = Field(..., description="The cases for the interaction node.")


class CompilerConfigV2(BaseModel):
    name: str = Field(..., min_length=1, description="The name of the compiler configuration.")
    models: list[Model] = Field(..., description="The models to compile.")
    interaction: Interaction | None = Field(None,
                                            description="The interactions tree to be handled by the runner.")

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
    save_schema_to_file("../compiler/step_config_schema.json")
