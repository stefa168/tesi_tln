from .base import Step
from .loading import LoadCsvStep
from .splitting import SplitDataStep
from .training.spacy_ner import TrainSpacyNerModelStep
from .training.bert_sequence_classifier import TrainBertSequenceClassifierStep


StepUnion = LoadCsvStep | SplitDataStep | TrainBertSequenceClassifierStep | TrainSpacyNerModelStep
