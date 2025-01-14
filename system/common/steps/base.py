from abc import ABC, abstractmethod
from typing import Any

from pydantic import BaseModel


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


class StepExecutionError(Exception):
    pass
