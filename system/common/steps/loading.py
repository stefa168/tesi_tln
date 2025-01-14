from pathlib import Path
from typing import Literal, Any

import pandas as pd

from system.common.steps.base import Step, StepExecutionError


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
