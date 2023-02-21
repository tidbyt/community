"""
Applet: Wordlebyt
Summary: Your Wordle Score
Description: Display your daily Wordle score on your Tidbyt.
Author: skola28
"""

load("render.star", "render")
load("schema.star", "schema")

def draw_box(color):
    return render.Box(
        width = 5,
        height = 5,
        color = "#000000",
        child = render.Box(width = 4, height = 4, color = color),
    )

#Constants
EXAMPLETWEET = "Paste Your Wordle\n\n⬛⬛🟩⬛⬛\n⬛⬛⬛🟩⬛\n🟩🟩🟩🟩🟩\n⬛⬛⬛🟩⬛\n⬛⬛🟩⬛⬛"
#EXAMPLETWEET2 = "Wordle 383 4/6  ⬛⬛🟩⬛⬛ 🟨⬛🟩⬛🟩 🟩🟨🟩⬛🟩 🟩🟩🟩🟩🟩"

def main(config):
    """Intent is to take your Wordle Score and have it display on your Tidbyt"""

    board = str(config.get("wordle_score", "Paste Your Wordle\n\n⬛⬛🟩⬛⬛\n⬛⬛⬛🟩⬛\n🟩🟩🟩🟩🟩\n⬛⬛⬛🟩⬛\n⬛⬛🟩⬛⬛")).replace("\\n", "\n").split()

    #To avoid errors, check that the board is at least 3 elements long (Worldle-Title, Wordle-Game-Number, Guesses)
    if len(board) > 3:
        #Break the Latest Tweet into usable pieces
        #POP off the Wordle Title Text from the First Element
        wordle_title = board.pop(0)

        #POP off the Wordle Game Number from the New First Element
        wordle_number = board.pop(0)

        #Pop off the Wordle Score Numeric from the New First Element(again!)
        wordle_score_number = board.pop(0)

        #If not 3 elements long, fill with static, valid text
    else:
        wordle_title = "Paste"

        #POP off the Wordle Game Number from the New First Element
        wordle_number = "Your"

        #Pop off the Wordle Score Numeric from the New First Element(again!)
        wordle_score_number = "Wordle"

    #Set the number of total guesses from what remains of board
    number_of_guesses = len(board)

    #Creating board_as_list with Each Entry from board broken into individual squares
    #Ex: print(board_as_list)
    #[["⬛", "⬛", "⬛", "⬛", "⬛"],
    # ["⬛", "🟨", "⬛", "⬛", "⬛"],
    # ["⬛", "⬛", "🟨", "🟨", "🟨"],
    # ["🟩", "🟩", "🟩", "🟩", "🟩"]]

    board_as_list = [list(row.codepoints()) for row in board]

    #Dictionary for Colors
    colordictionary = {
        "🟩": "#538d4e",
        "🟨": "#b59f3b",
        "⬛": "#3a3a3c",
    }

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Column(
                            children = [
                                render.Row(
                                    children = [
                                        draw_box(colordictionary.get(box, "#3a3a3c"))
                                        for box in board_as_list[row]
                                    ],
                                )
                                for row in range(number_of_guesses)
                            ],
                        ),
                        render.Column(
                            main_align = "space_evenly",
                            children = [
                                render.Text(content = wordle_title, color = "#FFFFFF"),
                                render.Text(content = wordle_number, color = "#FFFFFF"),
                                render.Text(content = wordle_score_number, color = "#FFFFFF"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "wordle_score",
                name = "Wordle Score",
                desc = "Paste your Wordle Score from the Wordle App",
                icon = "paste",
                default = "Paste Your Wordle\n\n⬛⬛🟩⬛⬛\n⬛⬛⬛🟩⬛\n🟩🟩🟩🟩🟩\n⬛⬛⬛🟩⬛\n⬛⬛🟩⬛⬛",
            ),
        ],
    )
