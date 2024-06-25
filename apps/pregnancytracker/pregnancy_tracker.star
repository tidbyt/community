"""
Applet: Pregnancy Tracker
Summary: Track your baby's size
Description: Track your baby's size throughout the duration of your pregnancy. Provide your baby's due date and see the fruit or vegetable to which your baby is closest in size each week.
Author: William Cougan
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    config_date = config.get("due_date", get_default_due_date())
    due_date = time.parse_time(config_date)
    weeks_pregnant = calculate_weeks_pregnant(due_date)

    if weeks_pregnant < 0:
        return render_marquee("You selected a due date that is more than 40 weeks in the future.")

    if weeks_pregnant > 40:
        return render_marquee("Congratulations! Your baby is the size of a baby!")

    return render.Root(
        child = render.Box(
            render.Column(
                children = [
                    render.Row(
                        children = [
                            render_image(weeks_pregnant),
                            render.Column(
                                children = [
                                    render.WrappedText("WEEK " + str(weeks_pregnant)),
                                    render.Text("DUE " + format_due_date(due_date)),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        children = [render_marquee(get_baby_size_message(weeks_pregnant), False)],
                    ),
                ],
            ),
        ),
    )

def render_marquee(text, render_root = True):
    marquee = render.Marquee(child = render.Text(text), width = 64)
    return render.Root(child = render.Box(marquee)) if render_root else marquee

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "due_date",
                name = "Due Date",
                desc = "When is the baby due?",
                icon = "calendar",
            ),
        ],
    )

def calculate_weeks_pregnant(due_date):
    current_date = time.now()
    time_until_due = due_date - current_date
    days_until_due = time_until_due.hours / 24
    weeks_until_due = days_until_due / 7
    return int(40 - weeks_until_due)

def format_due_date(date):
    month_number = date.month
    day_number = date.day
    month_abbreviation = month_abbreviations.get(month_number)
    return "{} {}".format(month_abbreviation, day_number)

def render_image(weeks_pregnant):
    url = "https://tidbyt-pregnancy-tracker.s3.amazonaws.com/" + str(weeks_pregnant) + ".png"
    response = http.get(url)
    if response.status_code != 200:
        return render.Text("")
    return render.Column(
        children = [
            render.Image(src = response.body(), height = 16),
        ],
    )

def get_baby_size_message(weeks_pregnant):
    if weeks_pregnant < 4:
        return "Baby is still a glimmer in your eye!"
    return "Baby is the size of " + fruit_names[weeks_pregnant] + "!"

def get_default_due_date():
    current_time = time.now()
    hours_in_week = 7 * 24
    duration = time.parse_duration(str(hours_in_week * 30) + "h")
    default_due_date = current_time + duration
    return default_due_date.format("2006-01-02T15:04:05Z07:00")

month_abbreviations = {
    1: "Jan",
    2: "Feb",
    3: "Mar",
    4: "Apr",
    5: "May",
    6: "Jun",
    7: "Jul",
    8: "Aug",
    9: "Sep",
    10: "Oct",
    11: "Nov",
    12: "Dec",
}

fruit_names = [
    "",
    "",
    "",
    "",
    "A POPPYSEED",
    "AN APPLESEED",
    "A SWEET PEA",
    "A BLUEBERRY",
    "A RASPBERRY",
    "A CHERRY",
    "A STRAWBERRY",
    "A LIME",
    "A PLUM",
    "A LEMON",
    "A PEACH",
    "A NAVEL ORANGE",
    "AN AVOCADO",
    "A POMEGRANATE",
    "AN ARTICHOKE",
    "A MANGO",
    "A BANANA",
    "AN ENDIVE",
    "A COCONUT",
    "A GRAPEFRUIT",
    "A CANTALOUPE",
    "A CAULIFLOWER",
    "KALE",
    "LETTUCE",
    "AN EGGPLANT",
    "AN ACORN SQUASH",
    "A ZUCCHINI",
    "ASPARAGUS",
    "A SQUASH",
    "CELERY",
    "A BUTTERNUT SQUASH",
    "A PINEAPPLE",
    "A PAPAYA",
    "ROMAINE LETTUCE",
    "A WINTER MELON",
    "A PUMPKIN",
    "A WATERMELON",
]
