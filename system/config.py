from pathlib import Path

from pydantic import BaseModel, Field


class ArtifactConfig(BaseModel):
    """
    Configuration for artifact paths such as model directories and configuration files.

    :ivar base_path: Base directory for all artifacts.
    :ivar subdir: Subdirectory inside the artifact where trained models are located.
    """
    base_path: Path = Field(..., description="Base directory for an artifact.")
    subdir: str = Field("trained_model", description="Subdirectory containing trained model data.")


class AcceleratorConfig(BaseModel):
    """
    Configuration for hardware accelerators such as GPUs (e.g., PyTorch configuration).

    :ivar use_cuda: Flag indicating if CUDA-enabled GPUs should be utilized.
    :ivar device_id: ID of the GPU device to be used. Defaults to 0.
    """
    use_cuda: bool = Field(True, description="Whether to use GPU acceleration.")
    device_id: int = Field(0, description="GPU device ID to use.")


class LoggingConfig(BaseModel):
    """
    Configuration for logging.

    :ivar level: Logging level (e.g., DEBUG, INFO, WARNING).
    :ivar format: Format string for log messages.
    """
    level: str = Field("INFO", description="Logging level.")
    format: str = Field("%(asctime)s - %(levelname)s - %(message)s", description="Format for log messages.")


class APIServiceConfig(BaseModel):
    """
    Configuration for external API services.

    :ivar provider: The name of the service provider.
    :ivar api_key: API key for authentication.
        This can either be the key itself as a string or a path to a file containing the key.
    """
    provider: str = Field(..., description="Name of the API service provider.")
    api_key: str = Field(...,
                         description="API key used for authentication. Can be a direct value or a path to a file containing the key.")

    def get_api_key(self) -> str:
        """
        Retrieves the API key. If the `api_key` field contains a path, the key is read from the file.

        :return: The API key as a string.
        :raises ValueError: If the file path is invalid or the file cannot be read.
        """
        if Path(self.api_key).is_file():
            try:
                with open(self.api_key, 'r') as file:
                    return file.read().strip()
            except OSError as e:
                raise ValueError(f"Failed to read API key from file {self.api_key}: {e}")

        return self.api_key


class BackendConfig(BaseModel):
    """
    Configuration for FastAPI backend (if used in future versions).

    :ivar host: Host for the backend server.
    :ivar port: Port for the backend server.
    """
    host: str = Field("127.0.0.1", description="Backend server host.")
    port: int = Field(8000, description="Backend server port.")


class RunnerConfig(BaseModel):
    """
    This class provides the model all the necessary informations to run:
        - Artifacts location for model loading (in the future the models might be packaged together with the chatbot configuration)
        - Remote API service providers (like OpenAI or Google if separate organizations, or Ollama if local)
        - Hardware Accelerators configuration for pytorch/huggingface transformers/spacy
        - Logging configuration
        - (FUTURE) FastAPI backend configuration to provide a backend for the chatbot
    """
    artifacts: dict[str, ArtifactConfig] = Field(..., description="Settings for artifact paths and models.")
    accelerators: AcceleratorConfig = Field(..., description="Hardware accelerator settings.")
    logging: LoggingConfig = Field(..., description="Logging configurations.")
    api_service: dict[str, APIServiceConfig] = Field(...,
                                                     description="Dictionary of external API service configurations.")
    backend: BackendConfig = Field(..., description="Backend server configuration.")
