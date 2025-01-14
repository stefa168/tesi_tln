from pathlib import Path

ARTIFACTS_BASE_DIR = Path("../compiler/artifacts")

from .base import Step
from .loading import LoadCsvStep
from .splitting import SplitDataStep
from .training.spacy_ner import NerSpacy
from .training.bert_sequence_classifier import TrainModelStep


StepUnion = LoadCsvStep | SplitDataStep | TrainModelStep | NerSpacy
