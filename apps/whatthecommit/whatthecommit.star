load("http.star", "http")
load("render.star", "render")

CHARS_PER_LINE = 13

TIDBYT_WIDTH = 64
TIDBYT_HEIGHT = 32

def format_text(original_text):
    lines = []
    for line in original_text.split("\n"):
        new_line = []
        for word in line.split(" "):
            append = word
            if len(word) > CHARS_PER_LINE:
                append = word[:CHARS_PER_LINE] + " " + word[CHARS_PER_LINE:]
            new_line.append(append)
        lines.append(" ".join(new_line))
    return "\n".join(lines)

def get_terminal_frame_characters(line, frame_index, frame_buffer_size, shell_prefix):
    max_index = min(frame_index, len(line))

    if frame_index <= frame_buffer_size:
        out = line[0:frame_index]

    else:
        if (len(line) < frame_buffer_size):
            return line[0:max_index]
        out = line[max_index - frame_buffer_size:max_index]

    space_left = frame_buffer_size - len(out)
    if space_left > 0:
        # add last characters of shell prefix before the out
        out = shell_prefix[-space_left:] + out

    return out

def get_delayed_terminal_character_frame(line, frame_delay, frame_buffer_size, hold_first_frame_count, hold_last_frame_count, shell_prefix):
    original = [get_terminal_frame_characters(line, i, frame_buffer_size, shell_prefix) for i in range(len(line) + 1)]

    # duplicate each frame
    out = []
    for i in range(len(original)):
        out += [original[i]] * frame_delay

    # hold first frame
    out = [original[0]] * hold_first_frame_count + out

    # hold last frame
    out += [original[-1]] * hold_last_frame_count

    return out

def write_command(line, frame_delay, frame_buffer_size, hold_first_frame_count, hold_last_frame_count, shell_prefix = "> "):
    # padded = "" if len(command)<=frame_buffer_size else command + " " * (frame_buffer_size - len(command))
    # last_element = command[len(command)-frame_buffer_size:len(command)]
    # print(last_element)

    return render.Row([
        render.Animation(
            [
                render.Text(
                    w,
                    font = "tom-thumb",
                )
                #for w in ([] + [line[0:i] for i in range(len(line) + 1)] + [line for _ in range(20)])
                for w in get_delayed_terminal_character_frame(line, frame_delay, frame_buffer_size, hold_first_frame_count, hold_last_frame_count, shell_prefix)
            ],
        ),
        render.Animation(
            [
                render.Row(
                    [
                        render.Text(
                            "_",
                        ) if i % 6 in [0, 1, 2] else render.Box(
                            width = 4,
                            height = 7,
                        ),
                    ],
                )
                for i in range(6)
            ],
        ),
        # render.Text(padding)
    ], expanded = True)

def main():
    resp = http.get("https://whatthecommit.com/index.json", headers = {"accept": "application/json"})
    data = resp.json()
    if not "commit_message" in data:
        return render.Root(
            render.WrappedText(
                "Error pulling funny commit msg :/",
                font = "5x8",
            ),
        )
    msg = data["commit_message"]
    frame_buffer_size = 15

    return render.Root(
        render.Padding(
            render.Column(
                [
                    render.Sequence(
                        [
                            write_command("git commit -m \"", 3, frame_buffer_size, 5, 16),
                            write_command(msg, 4, frame_buffer_size, 30, 20, "dquote> "),
                        ],
                    ),
                ],
                expanded = True,
                main_align = "center",
                cross_align = "center",
            ),
            pad = (0, 4, 0, 0),
        ),
        delay = 40,
        show_full_animation = True,
    )
