import logging
import re
from pathlib import Path
from typing import Literal, Any

import pandas as pd
from transformers import AutoTokenizer, PreTrainedModel, PreTrainedTokenizerBase, Trainer

from system.common.steps.base import Step, StepExecutionError
from system.compiler.fine_tuning import LabelInfo, prepare_model, prepare_dataset, run_fine_tuning

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class TrainBertSequenceClassifierStep(Step):
    """
    TrainBertSequenceClassifierStep is a step within a pipeline designed to train a BERT-based sequence classifier.
    This step facilitates the use of a BERT pretrained model, processes the associated datasets,
    and fine-tunes the model on the provided data. It also ensures the proper management of dependencies
    and verifies correct execution outputs.

    :ivar type: Defines the type of the step as "train_model", which follows a specific pipeline convention.
    :type type: Literal["train_model"]
    :ivar dataframe: Specifies the name of the dataframe to be used for training, formatted as "step_name.dataframe".
    :type dataframe: str
    :ivar pretrained_model: Indicates the BERT pretrained model to use for fine-tuning.
    :type pretrained_model: str
    :ivar labels_column: Name of the column in the dataframe that contains the labels for training.
    :type labels_column: str
    :ivar examples_column: Name of the column in the dataframe that contains the input examples for the model.
    :type examples_column: str
    :ivar resulting_model_name: Specifies the name or path used for saving the trained model.
                                If None, a default naming scheme will be used based on the configuration.
    :type train_epochs: The number of training epochs to be run. Defaults to 20.
    :type resulting_model_name: str | None
    """
    type: Literal["train_model"]
    dataframe: str
    pretrained_model: str
    labels_column: str
    examples_column: str
    train_epochs: int = 20
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

        # noinspection PyTypeChecker
        artifacts_base_dir: Path = context["artifacts_dir"]
        model_pipeline_path = artifacts_base_dir / config_name / model_pipeline_name / "trained_model"

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
            trainer = run_fine_tuning(base_model, tokenizer, train_dataset, eval_dataset, self.train_epochs)

            logger.info(f"Saving the model to {model_pipeline_path}")

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
