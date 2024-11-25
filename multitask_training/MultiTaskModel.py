import torch
from transformers import AutoModel, AutoTokenizer, get_linear_schedule_with_warmup


class MultiTaskModel(torch.nn.Module):
    def __init__(self, model_name_or_path, num_labels_dict):
        super(MultiTaskModel, self).__init__()
        self.encoder = AutoModel.from_pretrained(model_name_or_path)
        hidden_size = self.encoder.config.hidden_size

        # Create a classification head for each task
        self.classifiers = torch.nn.ModuleDict({
            task_name: torch.nn.Linear(hidden_size, num_labels)
            for task_name, num_labels in num_labels_dict.items()
        })

    def forward(self, input_ids, attention_mask):
        outputs = self.encoder(input_ids=input_ids, attention_mask=attention_mask)

        # Use appropriate representation based on model
        if hasattr(outputs, 'pooler_output') and outputs.pooler_output is not None:
            cls_output = outputs.pooler_output
        else:
            cls_output = outputs.last_hidden_state[:, 0, :]  # First token ([CLS])

        logits = {
            task_name: classifier(cls_output)
            for task_name, classifier in self.classifiers.items()
        }
        return logits
