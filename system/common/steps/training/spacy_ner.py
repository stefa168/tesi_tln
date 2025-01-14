import re
from pathlib import Path
from typing import Literal, Any

from pydantic import Field

from system.common.steps import ARTIFACTS_BASE_DIR
from system.common.steps.base import Step, StepExecutionError
from system.compiler.spacy_ner import init_spacy_device, NERData, prepare_multilabel_data, stratified_split, train_spacy


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
        train_spacy(train_data, val_data, set(label_list), self.iterations, self.language, model_pipeline_path)

        return {}
