from pathlib import Path
from typing import Literal, Any

import pandas as pd

from system.common.steps.base import Step, StepExecutionError


class LoadCsvStep(Step):
    """
    LoadCsvStep is a class for loading a CSV file into a pandas DataFrame and validating
    the output. It is intended to be used in a workflow where CSV data needs to be input
    as a DataFrame for further processing.

    :ivar type: Specifies the type of the step. It is always set to "load_csv".
    :type type: Literal["load_csv"]
    :ivar path: The file path for the CSV file to be loaded.
    :type path: Path
    """
    type: Literal["load_csv"]
    path: Path
    label_columns: list[str] | str | None = None

    def execute(self, inputs: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        df = pd.read_csv(self.path)

        if self.label_columns is not None:
            if isinstance(self.label_columns, str):
                df[[self.label_columns]] = df[[self.label_columns]].apply(
                    lambda col: col.str.strip().str.lower()
                )
            else:
                df[self.label_columns] = df[self.label_columns].apply(
                    lambda col: col.str.strip().str.lower()
                )

        return {"dataframe": df}

    def verify_execution(self, outputs: dict[str, Any]) -> dict[str, Any]:
        df = outputs["dataframe"]

        if not isinstance(df, pd.DataFrame):
            raise StepExecutionError("Output is not a pandas DataFrame.")

        return {"dataframe": df}
