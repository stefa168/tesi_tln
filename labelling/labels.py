LABELS: dict[str, str] = {
    "START": "Initial greetings or meta-questions, such as 'hi' or 'hello'.",
    "GEN_INFO": "General questions about the automaton that don't focus on specific components or functionalities.",
    "STATE_COUNT": "Questions asking about the number of states in the automaton.",
    "FINAL_STATE": "Questions about final states of the automaton.",
    "STATE_ID": "Questions about the identity of a particular state.",
    "TRANS_DETAIL": "General questions about the transitions within the automaton.",
    "SPEC_TRANS": "Specific questions about particular transitions or arcs between states.",
    "TRANS_BETWEEN": "Specific question about a transition between two states",
    "LOOPS": "Questions about loops or self-referencing transitions within the automaton.",
    "GRAMMAR": "Questions about the language or grammar recognized by the automaton.",
    "INPUT_QUERY": "Questions about the input or simulation of the automaton.",
    "OUTPUT_QUERY": "Questions specifically asking about the output of the automaton.",
    "IO_EXAMPLES": "Questions asking for examples of inputs and outputs.",
    "SHAPE_AUT": "Questions about the spatial or graphical representation of the automaton.",
    "OTHER": "Questions not related to the automaton or off-topic questions.",
    "ERROR_STATE": "Questions related to error states or failure conditions within the automaton.",
    "START_END_STATE": "Questions about the initial or final states of the automaton.",
    "PATTERN_RECOG": "Questions that aim to identify patterns in the automaton's structure or behavior.",
    "REPETITIVE_PAT": "Questions focusing on repetitive patterns, especially in transitions.",
    "OPT_REP": "Questions about the optimal spatial or minimal representation of the automaton.",
    "EFFICIENCY": "Questions about the efficiency or minimal representation of the automaton."
}

# LABELS: list[dict[str, str]] = [
#     {
#         "label": "Automaton Structure",
#         "label_explanation": "Questions about the general structure, states, or transitions of the automaton.",
#         "enumerator": "AUTOMATON_STRUCTURE"
#     },
#     {
#         "label": "States",
#         "label_explanation": "Questions specifically asking about the automaton's states, such as their number or names.",
#         "enumerator": "STATES"
#     },
#     {
#         "label": "Transitions",
#         "label_explanation": "Questions specifically focused on the transitions between states, including direction and details.",
#         "enumerator": "TRANSITIONS"
#     },
#     {
#         "label": "Initial/Final States",
#         "label_explanation": "Questions related to identifying the initial or final states of the automaton.",
#         "enumerator": "INITIAL_FINAL_STATES"
#     },
#     {
#         "label": "Alphabet/Accepted Language",
#         "label_explanation": "Questions about the input symbols (alphabet) or the language recognized by the automaton.",
#         "enumerator": "ALPHABET_ACCEPTED_LANGUAGE"
#     },
#     {
#         "label": "Patterns and Loops",
#         "label_explanation": "Questions regarding patterns or loops found within the automaton's structure or transitions.",
#         "enumerator": "PATTERNS_AND_LOOPS"
#     },
#     {
#         "label": "Shape/Structure",
#         "label_explanation": "Questions regarding the shape or spatial structure of the automaton.",
#         "enumerator": "SHAPE_STRUCTURE"
#     },
#     {
#         "label": "Miscellaneous",
#         "label_explanation": "Questions that do not fit into the above categories or are unrelated to automata.",
#         "enumerator": "MISCELLANEOUS"
#     },
#     {
#         "label": "Interaction Starter",
#         "label_explanation": "General interaction questions to initiate the conversation about automata.",
#         "enumerator": "INTERACTION_STARTER"
#     }
# ]
