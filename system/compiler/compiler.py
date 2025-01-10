import torch

from system.compiler.config import CompilerConfigV2, Model, Step, StepExecutionError


class ModelPipelineRunner:
    def __init__(self, model: Model, config: CompilerConfigV2):
        """
        Initialize the runner with a validated pipeline configuration.
        """
        self.model = model
        self.config = config

    def run(self):
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
            "config": self.config.model_dump(exclude={'models'})
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


def mainv2():
    config = CompilerConfigV2.load_from_file('./test_config v2.yml')

    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    print(f"Current CUDA device: {torch.cuda.current_device()}")
    print(f"Device name: {torch.cuda.get_device_name(torch.cuda.current_device())}")

    for model in config.models:
        runner = ModelPipelineRunner(model, config)
        runner.run()


if __name__ == '__main__':
    mainv2()
