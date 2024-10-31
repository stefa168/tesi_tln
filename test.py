import curses
import sys
import json

class NERAnnotator:
    def __init__(self, phrase_file='phrases.txt', annotation_file='annotations.json'):
        self.phrase_file = phrase_file
        self.annotation_file = annotation_file
        self.phrases = self.load_phrases()
        self.annotations = []
        self.token_types = ['PERSON', 'LOCATION', 'ORGANIZATION']
        self.current_phrase_idx = 0
        self.stdscr = None
        self.label2id = {'O': 0}
        self.id2label = {0: 'O'}
        self.next_label_id = 1  # Start assigning IDs from 1
        self.assigned_colors = {}  # Map labels to color pair numbers
        self.next_color_pair = 1  # Start from 1

    def load_phrases(self):
        with open(self.phrase_file, 'r') as f:
            phrases = [line.strip() for line in f if line.strip()]
        return phrases

    def save_annotations(self):
        with open(self.annotation_file, 'w') as f:
            json.dump(self.annotations, f, indent=2)
        # Save label mapping
        with open('labels.json', 'w') as f:
            json.dump(self.id2label, f, indent=2)

    def select_token_type(self):
        selected_idx = 0
        while True:
            self.stdscr.clear()
            self.stdscr.addstr(0, 0, "Select token type:")
            for idx, ttype in enumerate(self.token_types):
                if idx == selected_idx:
                    self.stdscr.attron(curses.A_REVERSE)
                    self.stdscr.addstr(idx + 1, 2, f"{idx+1}. {ttype}")
                    self.stdscr.attroff(curses.A_REVERSE)
                else:
                    self.stdscr.addstr(idx + 1, 2, f"{idx+1}. {ttype}")
            self.stdscr.addstr(len(self.token_types) + 2, 0, "Press Enter to select, 'n' to add new token type.")
            self.stdscr.refresh()
            key = self.stdscr.getch()
            if key == curses.KEY_UP and selected_idx > 0:
                selected_idx -= 1
            elif key == curses.KEY_DOWN and selected_idx < len(self.token_types) - 1:
                selected_idx += 1
            elif key in [curses.KEY_ENTER, 10, 13]:
                token_type = self.token_types[selected_idx]
                return token_type
            elif key == ord('n'):
                # Add new token type
                self.stdscr.addstr(len(self.token_types) + 3, 0, "Enter new token type: ")
                curses.echo()
                new_type = self.stdscr.getstr(len(self.token_types) + 3, len("Enter new token type: ")).decode('utf-8')
                new_type = new_type.strip()
                curses.noecho()
                if new_type and new_type not in self.token_types:
                    self.token_types.append(new_type)
                    selected_idx = len(self.token_types) - 1
                else:
                    self.stdscr.addstr(len(self.token_types) + 4, 0, "Invalid or existing token type. Press any key to continue.")
                    self.stdscr.getch()
            elif key == ord('q'):
                self.save_annotations()
                sys.exit()

    def display_phrase(self, words, tags, pos, selecting, selection_start):
        self.stdscr.clear()
        height, width = self.stdscr.getmaxyx()

        self.stdscr.addstr(0, 0, f"Phrase {self.current_phrase_idx+1}/{len(self.phrases)}: Navigate with arrow keys. Press Enter to select.")
        self.stdscr.addstr(1, 0, "Press 'q' to quit.")
        self.stdscr.addstr(2, 0, "Press Down Arrow to move to next phrase.")

        # Calculate how many words can fit per line
        max_word_length = max(len(word) for word in words) + 2  # Adding padding
        words_per_line = max(1, width // max_word_length)

        # Display words with highlighting
        for idx, word in enumerate(words):
            line = idx // words_per_line + 4  # Starting from line 4
            col = (idx % words_per_line) * max_word_length

            if line >= height - 4:
                self.stdscr.addstr(height - 3, 0, "Screen too small to display all words.")
                break

            attributes = 0

            if tags[idx] != 'O':
                label = tags[idx]
                color_pair = self.assigned_colors.get(label, 0)
                if color_pair != 0:
                    attributes |= curses.color_pair(color_pair)

            if selecting and min(selection_start, pos) <= idx <= max(selection_start, pos):
                attributes |= curses.A_STANDOUT
            elif idx == pos:
                attributes |= curses.A_REVERSE

            self.stdscr.addstr(line, col, word.ljust(max_word_length - 1), attributes)

        self.stdscr.refresh()

    def annotate_phrase(self, phrase):
        words = phrase.split()
        tags = ['O'] * len(words)
        pos = 0  # Cursor position
        selecting = False
        selection_start = 0

        while True:
            self.display_phrase(words, tags, pos, selecting, selection_start)
            key = self.stdscr.getch()

            if key == ord('q'):
                self.save_annotations()
                sys.exit()

            elif key == curses.KEY_RIGHT and pos < len(words) - 1:
                pos += 1

            elif key == curses.KEY_LEFT and pos > 0:
                pos -= 1

            elif key == curses.KEY_DOWN:
                break  # Move to next phrase

            elif key == curses.KEY_ENTER or key in [10, 13]:
                if selecting:
                    selecting = False
                    # Assign token type
                    token_type = self.select_token_type()
                    # Create labels
                    b_label = f"B-{token_type}"
                    i_label = f"I-{token_type}"
                    # Ensure labels are in label2id
                    for label in [b_label, i_label]:
                        if label not in self.label2id:
                            self.label2id[label] = self.next_label_id
                            self.id2label[self.next_label_id] = label
                            self.next_label_id += 1
                            # Assign color
                            if self.next_color_pair < curses.COLOR_PAIRS:
                                curses.init_pair(self.next_color_pair, curses.COLOR_BLACK, self.next_color_pair % 7 + 1)
                                self.assigned_colors[label] = self.next_color_pair
                                self.next_color_pair += 1
                            else:
                                self.assigned_colors[label] = 0  # Default color
                    # Tag the words
                    start = min(selection_start, pos)
                    end = max(selection_start, pos) + 1
                    for i in range(start, end):
                        if i == start:
                            tags[i] = b_label
                        else:
                            tags[i] = i_label
                else:
                    selecting = True
                    selection_start = pos

    def run(self, stdscr):
        self.stdscr = stdscr
        curses.curs_set(0)  # Hide cursor

        # Initialize colors if supported
        if curses.has_colors():
            curses.start_color()
            # Predefine a list of colors to use (excluding COLOR_BLACK)
            color_list = [
                curses.COLOR_RED, curses.COLOR_GREEN, curses.COLOR_YELLOW,
                curses.COLOR_BLUE, curses.COLOR_MAGENTA, curses.COLOR_CYAN, curses.COLOR_WHITE
            ]
            self.max_colors = min(len(color_list), curses.COLOR_PAIRS - 1)
            # Initialize color pairs
            for idx, color in enumerate(color_list):
                curses.init_pair(idx + 1, curses.COLOR_BLACK, color)
        else:
            self.max_colors = 0

        for self.current_phrase_idx, phrase in enumerate(self.phrases):
            self.annotate_phrase(phrase)

        self.save_annotations()
        height, _ = self.stdscr.getmaxyx()
        self.stdscr.addstr(height - 2, 0, f"Annotations saved to '{self.annotation_file}'. Press any key to exit.")
        self.stdscr.getch()

def main():
    annotator = NERAnnotator()
    curses.wrapper(annotator.run)

if __name__ == '__main__':
    main()
