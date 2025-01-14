from typing import Literal, Any, TYPE_CHECKING

import pandas as pd

from system.common.steps.base import Step, StepExecutionError

if TYPE_CHECKING:
    from . import StepUnion


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
