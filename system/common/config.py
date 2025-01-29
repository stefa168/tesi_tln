import enum
import json
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Literal, Any, Union, override

import yaml
from pydantic import BaseModel, Field

from system.common.steps import StepUnion


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


class Model(BaseModel):
    name: str = Field(..., min_length=1, description="The name of the model.")
    disabled: bool = Field(False, description="Whether model training should be disabled.")
    steps: list[StepUnion] = Field(..., min_length=1, description="The steps to execute for training the model.")
    type: Literal["classification", "ner"] = Field(..., description="The type of the model.")


class ResourceDiscoveryMixin(ABC):
    @abstractmethod
    # todo improve by returning a set of tuples/objects that specify the type of resource (bert model, spacy NER model,
    #  online or offline LLM, etc)
    def discover_resources_to_load(self) -> set[str]:
        """
        An abstract method to discover resources to load.
        Different classes can implement this method based on their specific logic.
        """
        pass


class Reply(BaseModel, ResourceDiscoveryMixin):
    name: str = Field(..., min_length=1, description="The name of the reply object.")
    reply: str | list[str] = Field(..., description="The reply to send to the user.")

    # todo improve with random reply picking and remember to keep track of the already used replies!
    def get_reply(self) -> str:
        if isinstance(self.reply, str):
            return self.reply
        elif isinstance(self.reply, list):
            return self.reply[0]
        else:
            raise ValueError("Invalid reply type.")

    @override
    def discover_resources_to_load(self) -> set[str]:
        return set()


type InteractionCases = Union["Interaction", list[Reply]]


class Interaction(BaseModel, ResourceDiscoveryMixin):
    use: str = Field(..., min_length=1, description="The model to use to produce a branching interaction.")
    name: str = Field(..., min_length=1, description="The name of the interaction node.")
    cases: dict[str, InteractionCases] = Field(..., description="The cases for the interaction node.")

    @override
    def discover_resources_to_load(self) -> set[str]:
        """
        Perform a DFS to discover all model names required in the interaction tree.

        Returns:
            set[str]: A set of all resource names required in children interactions.
        """
        models: set[str] = {self.use}
        for case in self.cases.values():
            models.update(case.discover_resources_to_load())

        return models


class FlowStepTypes(enum.StrEnum):
    USER_INPUT = "user_input"
    BOT_MESSAGE = "bot_message"
    MODEL_APPLICATION = "model_application"
    BRANCHING = "jump_to_step_by_condition"


class BaseFlowStep(BaseModel, ABC):
    type: str
    # name: str = Field(..., min_length=1, description="The name of the flow step.")
    next_step: str | None = Field(None, description="The name of the next step in this flow.")

    @abstractmethod
    def execute(self, context: dict[str, Any]) -> tuple[str | None, str | None]:
        """
        Runs the step.
        :param context: The context on which to run the step.

        :returns: A tuple containing the next step to be run and the corresponding flow.
        The flow can be omitted if it has to stay the same.
        If the next step is not specified, it means that the flow ends here.
        """
        pass

    def next_step_list(self) -> list[str] | None:
        if self.next_step is None:
            return None
        return [self.next_step]


class UserInputStep(BaseFlowStep):
    """
    Waits for user input. Will run any model specified on it after the user input.

    If the validation fails, the `if_invalid_goto` step is used instead.
    This means that the two fields (`valid_if` and `if_invalid_goto`) require each other.
    """
    type: Literal[FlowStepTypes.USER_INPUT]
    apply_models: list[str] | dict[str, str] | None = Field(None)
    valid_if: str | None = Field(None)
    if_invalid_goto: str | None = Field(None)

    @override
    def execute(self, context: dict[str, Any]) -> tuple[str | None, str | None]:
        user_reply = input("> ")
        return self.next_step, None


class ModelPrompt(BaseModel):
    """
    Represents the configuration that will be sent to an external model to generate a prompt.
    """
    model: str
    prompt: str


class BotMessageStep(BaseFlowStep):
    type: Literal[FlowStepTypes.BOT_MESSAGE]
    message: str | list[str] | ModelPrompt = Field(...)

    @override
    def execute(self, context: dict[str, Any]) -> tuple[str | None, str | None]:
        if isinstance(self.message, str):
            print(self.message)
        elif isinstance(self.message, list):
            print(self.message[0])
        else:
            print(self.message.prompt)

        return self.next_step, None


class ModelApplicationStep(BaseFlowStep):
    """
    Manual call for one or more model on the latest user input.
    """
    type: Literal[FlowStepTypes.MODEL_APPLICATION]
    # can apply a model and save the results with its original name or map it to another name.
    models: list[str] | dict[str, str] = Field(...)

    @override
    def execute(self, context: dict[str, Any]) -> tuple[str | None, str | None]:
        return self.next_step, None


class BranchingStep(BaseFlowStep):
    """
    This step can perform jumps to different steps or flows, depending on the condition.

    The cases dictionary can contain only literals as keys, and the values can be either:
     - Other steps in the same flow
     - Other flows
    """
    type: Literal[FlowStepTypes.BRANCHING]
    expression: str = Field(...)
    cases: dict[str, str] = Field(...)

    @override
    def next_step_list(self) -> list[str] | None:
        return list(self.cases.values())

    @override
    def execute(self, context: dict[str, Any]) -> tuple[str | None, str | None]:
        return self.next_step, None


FlowStepUnion = UserInputStep | BotMessageStep | ModelApplicationStep | BranchingStep


class Flow(BaseModel):
    # name: str = Field(..., min_length=1, description="The name of the flow.")
    start_step: str = Field(..., min_length=1, description="The name of the starting step.")
    steps: dict[str, FlowStepUnion]


class CompilerConfigV2(BaseModel):
    name: str = Field(..., min_length=1, description="The name of the compiler configuration.")
    models: list[Model] = Field(..., description="The models to compile.")
    flows: dict[str, Flow] | None = Field(None)

    @staticmethod
    def load_from_file(file_path: Path) -> 'CompilerConfigV2':
        """
        Load the compiler configuration from a YAML file.

        Args:
            file_path (str): The path to the YAML configuration file.

        Returns:
            CompilerConfig: The loaded compiler configuration.
        """
        with file_path.open("r") as file:
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
