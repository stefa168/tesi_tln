from typing import Literal, Any, TYPE_CHECKING

import pandas as pd

from system.common.steps.base import Step, StepExecutionError

if TYPE_CHECKING:
    from . import StepUnion


class SplitDataStep(Step):
    """
    This class represents a step in a pipeline that splits a DataFrame based on a column's unique values
    and executes a series of steps for each split.

    The `SplitDataStep` class is responsible for dividing a given DataFrame into multiple subsets based
    on the unique values of a specified column. For each subset, the specified sequence of steps is
    executed. The primary use case for this class is in pipelines where data needs to be processed
    differently for each group within the DataFrame. The class also handles verifying the execution output
    to ensure correctness.

    :ivar type: Specifies the type of the step as a literal "split_data".
    :type type: Literal["split_data"]
    :ivar dataframe: The name of the dataframe in the context to be processed.
    :type dataframe: str
    :ivar on_column: The column name in the dataframe used for splitting.
    :type on_column: str
    :ivar for_each: A list of steps or step unions to execute for each split.
    :type for_each: list["StepUnion"]
    """
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
            "config": context["config"],
            "config_path": context["config_path"],
            "artifacts_dir": context["artifacts_dir"],
            "compilation_start_time": context["compilation_start_time"]
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
