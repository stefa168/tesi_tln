from pathlib import Path

import click
import torch
import yaml

from system.common.config import CompilerConfigV2, Interaction, Reply, save_schema_to_file
from system.compiler.compiler import ModelPipelineCompiler
from system.config import RunnerConfig, ArtifactConfig, AcceleratorConfig, LoggingConfig, APIServiceConfig, \
    BackendConfig
from system.runner import load_bert_models, logger


@click.group()
def cli():
    pass


def run_runner(config_path: Path, artifacts_dir: Path = Path(".")):
    config = CompilerConfigV2.load_from_file(config_path)
    conf_artifact_path = artifacts_dir / config.name

    models = load_bert_models(conf_artifact_path, config.interaction)

    while True:
        user_input = input("Enter a prompt: ")
        if user_input == "exit":
            break

        next_interaction: Interaction | Reply = config.interaction
        interaction_traversal_stack: list[(str, Interaction | Reply)] = [("root", next_interaction)]

        while True:
            interaction_model = models[next_interaction.use]
            predictions = interaction_model.classify(user_input)
            next_interaction = next_interaction.cases[predictions[0]["label"]]

            interaction_traversal_stack.append((predictions, next_interaction))

            if isinstance(next_interaction, Reply):
                r: Reply = next_interaction

                stack = [(i[0], f"{type(i[1]).__name__}: {i[1].name}") for i in interaction_traversal_stack]
                logger.info(f"Stack: {stack}")

                print(f"Reply: {r.get_reply()}")
                break


@cli.command(name="serve")
@click.argument('config_path', type=click.Path(exists=True, dir_okay=False, path_type=Path), required=True)
@click.option('--artifacts_dir',
              type=click.Path(file_okay=False, writable=True, path_type=Path),
              default=Path("."),
              help="Directory for loading artifacts.")
def serve(config_path: Path, artifacts_dir: Path):
    """
    Starts the Runner with the specified configuration and artifacts directory. This command is
    invoked via a CLI tool, and it initializes the Runner using the provided options.

    :param config_path: Path to the configuration file. Must exist and be a valid file path.
    :param artifacts_dir: Optional. Path to the directory for loading artifacts. Defaults
        to the current working directory. Must be writable and a valid directory path.
    :return: None
    """
    logger.info("Starting the Runner...")
    try:
        run_runner(config_path, artifacts_dir)
    except Exception as exc:
        logger.error(f"An error occurred while running the Runner: {exc}")


@cli.command(name="compile")
@click.argument('config_path',
                type=click.Path(exists=True, dir_okay=False, path_type=Path),
                required=True)
@click.option('--artifacts_dir',
              type=click.Path(file_okay=False, writable=True, path_type=Path),
              default=Path("./artifacts"),
              show_default=True,
              help="Directory to save compilation artifacts.")
def compile_command(config_path: Path, artifacts_dir: Path):
    """
    Compiles the given configuration file and saves the resulting artifacts to the specified folder.

    CONFIG_PATH: Path to the configuration file.
    """
    try:
        # Load the configuration
        config = CompilerConfigV2.load_from_file(config_path)
        artifacts_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"CUDA available: {torch.cuda.is_available()}")
        logger.info(f"Number of GPUs: {torch.cuda.device_count()}")
        logger.info(f"Current CUDA device: {torch.cuda.current_device()}")
        logger.info(f"Device name: {torch.cuda.get_device_name(torch.cuda.current_device())}")
        logger.info(f"Compiling configuration file: {config_path}")
        logger.info(f"Artifacts will be saved in: {artifacts_dir.resolve()}")

        # Process each model in the configuration
        for model in config.models:
            runner = ModelPipelineCompiler(model, config)
            runner.run(config_path.absolute(), artifacts_dir.absolute())

    except Exception as exc:
        logger.error(f"An error occurred during compilation: {exc}", exc_info=True)


@cli.command(name="generate-config")
@click.argument('filepath', type=click.Path(dir_okay=False, writable=True, path_type=Path))
def generate_runner_config(filepath: Path):
    """
    Generates a default configuration file.

    FILEPATH: The path where the configuration file should be saved.
    """
    try:
        # Create default configuration
        default_config = RunnerConfig(
            artifacts=ArtifactConfig(base_path=Path("./artifacts"), subdir="trained_model"),
            accelerators=AcceleratorConfig(use_cuda=True, device_id=0),
            logging=LoggingConfig(level="INFO", format="%(asctime)s - %(levelname)s - %(message)s"),
            api_service={
                "example_service": APIServiceConfig(provider="ExampleProvider", api_key="your-api-key")
            },
            backend=BackendConfig(host="127.0.0.1", port=34198)
        )

        # Convert to YAML and write to file
        filepath.write_text(yaml.dump(default_config.model_dump(), default_flow_style=False, sort_keys=False))
        logger.info(f"Default configuration written to {filepath.resolve()}")

    except Exception as exc:
        logger.error(f"Failed to generate configuration file: {exc}")


@cli.command(name="export-schema")
@click.argument('filepath',
                type=click.Path(dir_okay=False, writable=True, path_type=Path), default=Path("./compiler_schema.yaml"))
def export_schema(filepath: Path):
    """
    Saves the JSON schema of the CompilerConfigV2 to a file.

    FILEPATH: The path where the schema should be saved.
    """
    try:
        # Save the schema to the specified file
        save_schema_to_file(str(filepath))

        # Log success (if a logger is available)
        logger.info(f"Schema successfully saved to {filepath.resolve()}")

    except Exception as exc:
        # Log the error and provide traceback
        logger.error(f"An error occurred while saving the schema to {filepath}: {exc}", exc_info=True)


if __name__ == '__main__':
    cli()
