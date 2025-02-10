from datetime import datetime
from pathlib import Path

from system.common.config import CompilerConfigV2, Model
from system.common.steps.base import Step, StepExecutionError


class ModelPipelineCompiler:
    def __init__(self, model: Model, config: CompilerConfigV2):
        """
        Initialize the runner with a validated pipeline configuration.
        """
        self.model = model
        self.config = config

    def run(self, config_path: Path, artifacts_dir: Path):
        """
        Run the pipeline, executing its steps in sequence.
        """

        if self.model.disabled:
            print(f"Skipping disabled model '{self.model.name}'")
            return

        print(f"Running pipeline '{self.model.name}'")

        # Shared context for intermediate outputs
        context: dict[str, dict[str, object]] = {
            'model_metadata': self.model.model_dump(exclude={'steps'}),
            "config": self.config.model_dump(exclude={'models'}),
            "config_path": config_path,
            "artifacts_dir": artifacts_dir,
            "compilation_start_time": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

        step: Step
        for step in self.model.steps:
            try:
                retrieved_inputs = step.resolve_requirements(context)
                execution_results = step.execute(retrieved_inputs, context)
                checked_outputs = step.verify_execution(execution_results)

                context[step.name] = checked_outputs
            except StepExecutionError as e:
                print(f"Error executing step '{step.name}': {e}")
                raise