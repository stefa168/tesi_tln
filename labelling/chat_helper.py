from typing import Literal, Iterator

import ollama
from ollama import ProgressResponse, Message, ChatResponse
from tqdm import tqdm


def model_init(model: str):
    d = ollama.pull(model=model, stream=True)
    progress_bar = tqdm(total=100, desc="Downloading model", )
    chunk: ProgressResponse
    for chunk in d:
        # if keys contain completed and total, among other keys
        if "completed" in chunk and "total" in chunk:
            progress = chunk['completed'] / chunk["total"] * 100
            progress_bar.n = progress
            progress_bar.refresh()
    progress_bar.clear()
    progress_bar.close()


def ensure_model_present(model: str):
    try:
        ollama.show(model=model)
    except Exception as e:
        print(e)
        print(f"Model '{model}' not found. Downloading...")
        model_init(model)


class Chat:
    model = "mistral"
    messages: list[Message]

    def __init__(self, model: str = "mistral"):
        self.model = model
        self.messages = []

        ensure_model_present(self.model)

    @staticmethod
    def new_message(text: str, role: Literal['user', 'assistant', 'system', 'tool'] = 'user') -> Message:
        return Message(content=text, role=role)

    # This method interacts with the model to generate a response which will be appended to the messages list
    def interact(self, message: str,
                 role: Literal['user', 'assistant', 'system', 'tool'] = 'user',
                 print_output: bool = True,
                 use_in_context: bool = True,
                 stream: bool = False) -> str:
        user_msg = self.new_message(message, role)
        self.messages.append(user_msg)

        text = ""
        if stream:
            response: Iterator[ChatResponse] = ollama.chat(model=self.model, messages=self.messages, stream=True)
            for chunk in response:
                chunk = chunk['message']['content']
                text += chunk
                if print_output:
                    print(chunk, end='')

        else:
            response: ChatResponse = ollama.chat(model=self.model, messages=self.messages)
            text = response['message']['content']
            if print_output:
                print(text)

        if use_in_context:
            self.messages.append(Message(content=text, role='assistant'))
        else:
            # Remove the last message from the list, we only used it to generate the response
            self.messages.pop()

        return text

    def get_messages(self):
        return self.messages

    def clear_messages(self):
        self.messages = []
