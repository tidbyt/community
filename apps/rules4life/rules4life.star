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

RULES = {
    1: {
        "quote": "To stand up straight with your shoulders back is to accept the terrible responsibility of life, with eyes wide open. It means deciding to voluntarily transform the chaos of potential into the realities of habitable order … It means willingly undertaking the sacrifices necessary to generate a productive and meaningful reality.",
        "rule": "Stand up straight with your shoulders back",
    },
    2: {
        "quote": "You must help a child become a virtuous, responsible, awake being, capable of full reciprocity – able to take care of himself and others, and to thrive while doing so. Why would you think it acceptable to do anything less for yourself?",
        "rule": "Treat yourself like you are someone you are responsible for helping",
    },
    3: {
        "quote": "It’s a good thing, not a selfish thing to choose people who are good for you.",
        "rule": "Make friends with people who want the best for you",
    },
    4: {
        "quote": "You are finding that the solutions to your particular problems have to be tailored to you, personally and precisely.",
        "rule": "Compare yourself to who you were yesterday, not to who someone else is today",
    },
    5: {
        "quote": "Friends have very limited authority to correct.",
        "rule": "Do not let your children do anything that makes you dislike them",
    },
    6: {
        "quote": "Start to stop doing what you know to be wrong.",
        "rule": "Set your house in perfect order before you criticize the world.",
    },
    7: {
        "quote": "Life is suffering. That’s clear. There is no more basic, irrefutable truth.",
        "rule": "Pursue what is meaningful (not what is expedient)",
    },
    8: {
        "quote": "I have seen people define their utopia and then bend their lives into knots trying to make it reality.",
        "rule": "Tell the truth – or, at least, don’t lie",
    },
    9: {
        "quote": "[Good] conversation [is] the best preparation for proper living.",
        "rule": "Assume that the person you are listening to might know something you don’t",
    },
    10: {
        "quote": "[Speech] can give structure and re-establish order",
        "rule": "Be precise in your speech",
    },
    11: {
        "quote": "If you think tough men are dangerous, wait until you see what weak men are capable of.",
        "rule": "Do not bother children when they are skate-boarding",
    },
    12: {
        "quote": "If you pay careful attention, even on a bad day, you may be fortunate enough to be confronted with small opportunities of just that sort. Maybe you will see a little girl dancing on the street because she is all dressed up in a ballet costume. Maybe you will have a particularly good cup of coffee in a cafe that cares about their customers. Maybe you can steal ten or twenty minutes to do some ridiculous thing that distracts you or reminds you that you can laugh at the absurdity of existence.",
        "rule": "Pet a cat when you encounter one on the street.",
    },
}

def main(config):
    display = config.get("display") or DISPLAY_OPTIONS[0].value
    print(display)

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
                    child = render.Text("%s" % (RULES[display_item]["quote"]), color = "#e77c05", font = "Dina_r400-6"),
                ),
            ],
        ),
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
        ],
    )
