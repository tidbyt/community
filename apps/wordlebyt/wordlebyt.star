"""
Applet: Wordlebyt
Summary: Your Wordle Score
Description: Display your daily Wordle score on your Tidbyt.
Author: skola28
"""

load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

def draw_box(color):
    return render.Box(
        width = 5,
        height = 5,
        color = "#000000",
        child = render.Box(width = 4, height = 4, color = color),
    )

def main(config):
    """Intent is to take your Wordle Score and have it display on your Tidbyt"""

    #Constants
    #EXAMPLETWEET = "Paste Your Wordle\n\n⬛⬛🟩⬛⬛\n⬛⬛⬛🟩⬛\n🟩🟩🟩🟩🟩\n⬛⬛⬛🟩⬛\n⬛⬛🟩⬛⬛"
    #EXAMPLETWEET2 = "Wordle 383 4/6  ⬛⬛🟩⬛⬛ 🟨⬛🟩⬛🟩 🟩🟨🟩⬛🟩 🟩🟩🟩🟩🟩"
    #board = str(config.get("wordle_score", "Paste Your Wordle\n\n⬛⬛🟩⬛⬛\n⬛⬛⬛🟩⬛\n🟩🟩🟩🟩🟩\n⬛⬛⬛🟩⬛\n⬛⬛🟩⬛⬛")).replace("\\n", "\n").split()
    #Original Board Print = ["Paste", "Your", "Wordle", "⬛⬛🟩⬛⬛", "⬛⬛⬛🟩⬛", "🟩🟩🟩🟩🟩", "⬛⬛⬛🟩⬛", "⬛⬛🟩⬛⬛"]

    shared_text = config.get("wordle_score", "Paste Your Wordle⬛⬛🟩⬛⬛⬛⬛⬛🟩⬛🟩🟩🟩🟩🟩⬛⬛⬛🟩⬛⬛⬛🟩⬛⬛")

    #Take shared text (that the user pasted into the Wordlebyt Schema field) and remove all the boxes)
    score_text = re.sub(r"[⬛🟩🟨]", "", shared_text)

    #Check that "score_text" has 3 elements: The Wordle Title, The Game Number, and the Number of Guesses
    if len(score_text.split()) >= 3:
        score_text = score_text.split()

        #If it doesn't, prefil the score_text with canned text to make the app happy
    else:
        score_text = ["Paste", "Your", "Wordle"]

    #Next, take shared_text (that the user pasted into the Wordlebyt Schema field) and remove everything except the boxes...
    boxes_text = re.sub(r"[^⬛🟩🟨]", "", shared_text)

    #count the number of boxex....
    number_of_boxes = boxes_text.count("⬛") + boxes_text.count("🟩") + boxes_text.count("🟨")

    #Make sure that the board has between 30 and 5 total boxes since max guesses is 6 with 5 boxes per guess which comes out to 30.  5 is the least as that is a single guess.
    #Also makes sure that the total number of boxes is divisible by 5.  Otherwise, you clearly have a bad input as only full guesses are allowed.
    if 5 <= number_of_boxes and number_of_boxes <= 30 and number_of_boxes % 5 == 0:
        #Make a list of boxes by looking for groups of five and generating a list.
        boxes_list = re.findall(".....", boxes_text)
    else:
        #Since the user input failed error handling above, prefill some data into the necessary variables to allow the program to continue gracefully
        boxes_list = ("⬛⬛🟩⬛⬛", "⬛⬛⬛🟩⬛", "🟩🟩🟩🟩🟩", "⬛⬛⬛🟩⬛", "⬛⬛🟩⬛⬛")

    #Fill the Text Variables out of elements of score_text
    wordle_title = score_text[0]
    wordle_number = score_text[1]
    wordle_score_number = score_text[2]

    #Set the number of total guesses from elements in boxes_list
    number_of_guesses = len(boxes_list)

    #Creating board_as_list with Each Entry from board broken into individual squares
    #Ex: print(board_as_list)
    #[["⬛", "⬛", "⬛", "⬛", "⬛"],
    # ["⬛", "🟨", "⬛", "⬛", "⬛"],
    # ["⬛", "⬛", "🟨", "🟨", "🟨"],
    # ["🟩", "🟩", "🟩", "🟩", "🟩"]]

    board_as_list = [list(row.codepoints()) for row in boxes_list]

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
                default = "Paste Your Wordle⬛⬛🟩⬛⬛⬛⬛⬛🟩⬛🟩🟩🟩🟩🟩⬛⬛⬛🟩⬛⬛⬛🟩⬛⬛",
            ),
        ],
    )
