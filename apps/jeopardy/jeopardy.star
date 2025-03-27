load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

def get_question():
    if cache.get("jeopardy_question") != None:
        return json.decode(cache.get("jeopardy_question"))

    res = http.get("https://raw.githubusercontent.com/abochnak/tidbyt-jeopardy/main/data/questions.json")
    if res.status_code != 200:
        fail("Failed with status_code %d" % res.status_code)

    questions = res.json()
    question = questions[random.number(0, len(questions))]
    cache.set("jeopardy_question", json.encode(question), ttl_seconds = 900)

    return question

def display_for(duration, child):
    return render.Box(
        child = animation.Transformation(
            child = child,
            duration = duration,
            delay = 0,
            origin = animation.Origin(0, 0),
            direction = "normal",
            fill_mode = "forwards",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [],
                ),
            ],
        ),
    )

def category_section(category, category_duration):
    return render.Box(
        child = animation.Transformation(
            child = render.Box(
                color = "#00f",
                child = render.WrappedText(
                    content = "%s" % category.upper(),
                    font = "tb-8",
                    align = "center",
                    linespacing = 0,
                ),
            ),
            duration = category_duration,
            delay = 0,
            origin = animation.Origin(0.5, 0.5),
            direction = "normal",
            fill_mode = "forwards",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Scale(0.01, 0.01), animation.Translate(2, 2)],
                ),
                animation.Keyframe(
                    percentage = 0.5,
                    transforms = [],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [],
                ),
            ],
        ),
    )

def answer_section(answer):
    return render.Box(
        color = "#00f",
        child = render.Marquee(
            height = 32,
            offset_start = 32,
            offset_end = 0,
            child = render.WrappedText(
                content = answer,
                width = 64,
                font = "tb-8",
                align = "center",
            ),
            scroll_direction = "vertical",
        ),
    )

def what_is_section():
    return render.Box(
        child = render.WrappedText(
            content = "WHAT IS...",
            width = 64,
            font = "tb-8",
            align = "center",
        ),
    )

def response_section(response, air_date):
    return render.Box(
        color = "#00f",
        child = render.Marquee(
            height = 32,
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(
                content = response + "\n \n(" + air_date + ")",
                width = 64,
                font = "tb-8",
                align = "center",
            ),
            scroll_direction = "vertical",
        ),
    )

def main(config):
    data = get_question()

    part_one = [
        category_section(data["category"], int(config.str("category_duration", "20"))),
        display_for(int(config.str("answer_duration", "100")), answer_section(data["answer"])),
    ]

    part_two = [
        display_for(int(config.str("what_is_delay", "20")), what_is_section()),
        display_for(int(config.str("response_delay", "100")), response_section(data["response"], data["air_date"])),
    ]

    return render.Root(
        delay = int(config.str("delay", "100")),
        show_full_animation = True,
        child = render.Sequence(
            children = part_one + part_two if config.bool("show_all") else (
                part_one if not config.bool("show_response") else part_two
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_all",
                name = "Show All",
                desc = "Show answer and response.",
                icon = "plus",
            ),
            schema.Toggle(
                id = "show_response",
                name = "Show Response",
                desc = "Show response if set, otherwise only show the answer.",
                icon = "plus",
            ),
            schema.Text(
                id = "category_duration",
                name = "Category duration",
                desc = "Duration to show the category",
                icon = "plus",
            ),
            schema.Text(
                id = "answer_duration",
                name = "Answer duration",
                desc = "Duration to show the answer",
                icon = "plus",
            ),
            schema.Text(
                id = "what_is_delay",
                name = "What Is delay",
                desc = "Duration to show 'what is'",
                icon = "plus",
            ),
            schema.Text(
                id = "response_delay",
                name = "Response delay",
                desc = "Duration to show the response",
                icon = "plus",
            ),
        ],
    )
