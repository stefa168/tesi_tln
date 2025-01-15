import re
from pathlib import Path
from typing import Literal, Any

from pydantic import Field

from system.common.steps.base import Step, StepExecutionError
from system.compiler.spacy_ner import init_spacy_device, NERData, prepare_multilabel_data, stratified_split, train_spacy


class TrainSpacyNerModelStep(Step):
    """
    The TrainSpacyNerModelStep class orchestrates the training of a SpaCy NER model.

    This class provides functionalities to train a named entity recognition (NER)
    model using SpaCy. It facilitates handling training data, configuration,
    context handling, and model training processes. By specifying parameters
    like language, training iterations, and device preferences, the model
    training process can be controlled and customized. The resulting model can
    be stored and named based on provided or derived naming strategies.

    :ivar type: Fixed literal type identifier for the step.
    :type type: Literal["ner_spacy"]
    :ivar language: Language for the SpaCy NER model, default is "en".
    :type language: str
    :ivar training_data_path: Path to the dataset used for training, required and must not be empty.
    :type training_data_path: Path
    :ivar iterations: Number of iterations for model training, must be at least 1.
    :type iterations: int
    :ivar training_device: Device preference for training, allows values 'cpu',
        'prefer_gpu', or 'gpu'.
    :type training_device: Literal['cpu', 'prefer_gpu', 'gpu']
    :ivar resulting_model_name: Name of the resulting trained model, can use
        template variables and be dynamically set. If None, a default naming
        strategy will be applied.
    :type resulting_model_name: str | None
    """
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

        # noinspection PyTypeChecker
        artifacts_base_dir: Path = context["artifacts_dir"]
        model_pipeline_path = artifacts_base_dir / config_name / model_pipeline_name / "trained_model"

        data = NERData.load_jsonl_data(self.training_data_path)
        label_matrix, label_list = prepare_multilabel_data(data)
        train_data, val_data = stratified_split(data, label_matrix)
        train_spacy(train_data, val_data, set(label_list), self.iterations, self.language, model_pipeline_path)

        return {}
