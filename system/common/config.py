import json
from abc import ABC, abstractmethod
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


type InteractionCases = Union["Interaction", Reply]


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
