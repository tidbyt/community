"""
Applet: Rules4Life
Summary: Display Rules for Life
Description: Display Jordan B. Peterson's Rules for Life from his book.
Author: Robert Ison
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DISPLAY_OPTIONS = [
    schema.Option(value = "random", display = "Display Random Rule every time"),
    schema.Option(value = "hourly", display = "Display new rule each Hour"),
    schema.Option(value = "daily", display = "Display new rule each Day"),
    schema.Option(value = "monthly", display = "Display new rule each Month"),
]

scroll_speed_options = [
    schema.Option(
        display = "Slow",
        value = "60",
    ),
    schema.Option(
        display = "Medium",
        value = "45",
    ),
    schema.Option(
        display = "Fast",
        value = "30",
    ),
]

#####################################################################################################################################################################################
RULES = {
    1: {
        "rule": "Stand up straight with your shoulders back",
        "quote": "Accept the terrible responsibility of life, with eyes wide open. Voluntarily transform the chaos of potential into the realities of habitable order",
    },
    2: {
        "rule": "Treat yourself like you are someone you are responsible for helping",
        "quote": "You must help a child become a virtuous, responsible, awake being, capable of full reciprocity - able to care for himself and others, and to thrive while doing so.",
    },
    3: {
        "rule": "Make friends with people who want the best for you",
        "quote": "It's a good thing, not a selfish thing to choose people who are good for you.",
    },
    4: {
        "rule": "Compare yourself to who you were yesterday, not to who someone else is today",
        "quote": "You are finding that the solutions to your particular problems have to be tailored to you, personally and precisely.",
    },
    5: {
        "rule": "Do not let your children do anything that makes you dislike them",
        "quote": "Friends have very limited authority to correct.",
    },
    6: {
        "rule": "Set your house in perfect order before you criticize the world",
        "quote": "Stop doing what you know to be wrong.",
    },
    7: {
        "rule": "Pursue what is meaningful (not what is expedient)",
        "quote": "Life is suffering. That is clear. There is no more basic, irrefutable truth.",
    },
    8: {
        "rule": "Tell the truth - or, at least, do not lie",
        "quote": "I have seen people define their utopia and then bend their lives into knots trying to make it reality.",
    },
    9: {
        "rule": "Assume that the person you are listening to might know something you don't",
        "quote": "Good conversation is the best preparation for proper living.",
    },
    10: {
        "rule": "Be precise in your speech",
        "quote": "Speech can give structure and re-establish order",
    },
    11: {
        "rule": "Do not bother children when they are skate-boarding",
        "quote": "If you think tough men are dangerous, wait until you see what weak men are capable of.",
    },
    12: {
        "rule": "Pet a cat when you encounter one on the street",
        "quote": "If you pay careful attention, even on a bad day, you may be fortunate enough to be confronted with small opportunities of just that sort. ",
    },
}

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The Tidbyt display
    """
    display = config.get("display") or DISPLAY_OPTIONS[0].value

    if (display == "daily"):
        seed = time.now().year + time.now().month + time.now().day
    elif (display == "hourly"):
        seed = time.now().year + time.now().month + time.now().day + time.now().hour
    elif (display == "monthly"):
        seed = time.now().year + time.now().month
    else:
        seed = time.now().nanosecond

    display_item = random_based_on_seed(seed, 1, 12)

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("Rule %s" % (display_item), color = "#fff", font = "Dina_r400-6"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text("%s" % (RULES[display_item]["rule"]), color = "#f4a306", font = "Dina_r400-6"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(RULES[display_item]["rule"]) * 5,
                    child = render.Text("   %s" % (RULES[display_item]["quote"]), color = "#e77c05", font = "Dina_r400-6"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def random_based_on_seed(seed, min, max):
    remainder = seed % (max - min + 1)
    return remainder + min

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "How often do you want the displayed rule to change?",
                icon = "clock",
                options = DISPLAY_OPTIONS,
                default = DISPLAY_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
