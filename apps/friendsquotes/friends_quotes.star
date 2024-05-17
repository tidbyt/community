"""
Applet: Friends Quotes
Summary: Displays Friends quotes
Description: Displays a random quote from the hit TV sitcom, Friends.
Author: kaffolder7
"""

### Special thanks to Marc ten Bosch for lobster facts code template

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

THE_LOGO = base64.decode("""
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
""")

QUOTES = {
    "Joey": [
        "How you doin'?",
        "Joey doesn't share food!",
        "Here come the meat sweats.",
        "Could I BE wearing any more clothes?!",
        "You can't just give up. Is that what a dinosaur would do?",
        "Some girl ate Monica!",
        "If he doesn't like you, this is all a moo-point.",
        "She's my friend and she needed help. If I had to, I'd pee on any one of you!",
        "Grab a spoon!",
        "You don't own a TV? What's all your furniture pointed at?",
        "What's not to like? Custard? Good. Jam? Good. Meat? Good.",
    ],
    "Chandler": [
        "I'm not great at the advice. Can I interest you in a sarcastic comment?",
        "Whapah!",
        "Dear God, this parachute is a knapsack!",
        "I'm hopeless and awkward and desperate for love!",
        "I'm Chandler. I make jokes when I'm uncomfortable.",
        # "I'm sorry, it was a one-time thing. I was very drunk, and it was someone else's subconscious.",
        "So it seems like this Internet thing's here to stay.",
        "I say more dumb things before 9 a.m. than most people say all day.",
        "Janice:\n\"What a small world.\"\nChandler:\n\"And yet I never run into Beyoncé.\"",
        "I have no idea what's going on, but I am excited.",
        "I had a very long, hard day.",
    ],
    "Ross": [
        "We were on a break!",
        "Unagi.",
        "Pivot!",
        "I'm gonna go out on a limb and say no divorces in '99!",
        "Ugly baby judges you!",
        # "I'm fine. Totally fine.",
        "No more falafel for you!",
        "I'm the holiday armadillo!",
        "I grew up with Monica. If you didn't eat fast, you didn't eat.",
        "Monica:\n\"Where've you been?\"\nRoss:\n\"Emotional hell.\"",
        "I am this close to tugging on my testicles again.",
        "You're over me? When were you...under me?",
    ],
    "Phoebe": [
        "See? He's her lobster.",
        "Come on, Ross, you're a paleontologist. Dig a little deeper.",
        "Oh, I wish I could, but I don't want to.",
        "Your collective dating record reads like a who's who of human crap.",
        "Monica:\n\"Do you have a plan?\"\nPhoebe:\n\"I don't even have a pla-.\"",
        "They don't know that we know they know we know.",
        "That is brand new information!",
        "Oh you like that? You should hear my phone number.",
        "Something is wrong with the left phalange.",
    ],
    "Rachel": [
        "Well, maybe I don't need your money. Wait, wait, I said maybe!",
        "Isn't that just kick-you-in- the-crotch, spit-on- your-neck fantastic?",
        "Ross:\n\"You got a job?\"\nRachel:\n\"Are you kidding? I'm trained for nothing!\"",
        "I got off the plane.",
        "He's so pretty, I want to cry.",
        "No uterus, no opinion.",
        "Oh I'm sorry. Did my back hurt your knife?",
        "It's like all of my life everyone has always told me you're a shoe, you're a shoe, you're a shoe, you're a shoe. And then today, I just stopped and I said, what if I don't want to be a shoe? What if I want to be a purse, you know, or a hat?",
        "Monica:\n\"You can't live off your parents your whole life.\"\nRachel:\n\"I know that, that's why I was getting married.\"",
        "Today, it's like there's rock bottom, 50 feet of crap, then me.",
        "Just so you know, it's not that common, it doesn't happen to every guy, and it is a big deal!",
        "We are dessert stealers. We are living outside the law.",
    ],
    "Monica": [
        "And I have to live with a boy!",
        "Welcome to the real world. It sucks. You're gonna love it.",
        "Is it me? Is it like I have some sort of beacon that only dogs and men with severe emotional problems can hear?",
        "I've got this uncontrollable need to please people.",
        "I KNOW!",
        "Now, I need you to be careful and efficient. And remember, if I am harsh with you, it is only because you're doing it wrong.",
        "Guys can fake it? Unbelieveable! The one thing that's ours!",
        "I'm gonna love you so much that no woman is ever gonna be good enough for you.",
        "It's baby time. Pants off, Bing.",
    ],
    "Mike H.": [
        "You're a strange kind of grown-up.",
    ],
    "Janice": [
        "OH MY GOD.",
        "Well, I got to buy a vowel because oh my god.",
    ],
    "Frank Jr.": [
        "My sister's gonna have my baby!",
    ],
}

def main(config):
    random.seed(time.now().unix)
    animation_style = config.get("animationStyle", "style1")
    font_style = config.get("fontStyle", "tb-8")
    quotes_list, root = [], ""

    for person in QUOTES:
        if config.get("enableQuotesBy" + person.replace(".", "").replace(" ", ""), True) == "true":
            for quote in QUOTES[person]:
                quote_str = quote if "\"" in quote else ("\"" + quote + "\"\n-" + person)
                quotes_list.append(quote_str)

    idx = random.number(0, len(quotes_list) - 1)
    current_quote = quotes_list[idx]

    style1 = render.Padding(
        pad = 1,
        child = render.Marquee(
            height = 30,
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Image(src = THE_LOGO, width = 52),
                    render.Box(height = 4),
                    render.WrappedText(current_quote, font = "tom-thumb", width = 62, linespacing = 2, align = "center") if font_style == "tom-thumb" else render.WrappedText(current_quote, width = 62, align = "center"),
                ],
            ),
            scroll_direction = "vertical",
        ),
    )

    style2 = render.Padding(
        pad = 1,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = THE_LOGO, width = 52),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Box(height = 3),
                render.Marquee(
                    height = 19,
                    child = render.WrappedText(current_quote, font = "tom-thumb", width = 62, linespacing = 2, align = "center") if font_style == "tom-thumb" else render.WrappedText(current_quote, width = 62, align = "center"),
                    scroll_direction = "vertical",
                ),
            ],
            expanded = True,
        ),
    )

    if animation_style == "style1":
        root = render.Root(
            child = style1,
        )
    elif animation_style == "style2":
        root = render.Root(
            child = style2,
        )
    return root

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "animationStyle",
                name = "Animation style",
                desc = "Choose your preferred animation style",
                icon = "brush",
                default = "style1",
                options = [
                    schema.Option(
                        display = "Default",
                        value = "style1",
                    ),
                    schema.Option(
                        display = "Static logo",
                        value = "style2",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "fontStyle",
                name = "Font style",
                desc = "Choose your preferred font style",
                icon = "font",
                default = "tb-8",
                options = [
                    schema.Option(
                        display = "tb-8",
                        value = "tb-8",
                    ),
                    schema.Option(
                        display = "tom-thumb",
                        value = "tom-thumb",
                    ),
                ],
            ),
            schema.Toggle(
                id = "enableQuotesByJoey",
                name = "Joey",
                desc = "Displays quotes by Joey",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByChandler",
                name = "Chandler",
                desc = "Displays quotes by Chandler",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByRoss",
                name = "Ross",
                desc = "Displays quotes by Ross",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByPhoebe",
                name = "Phoebe",
                desc = "Displays quotes by Phoebe",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByRachel",
                name = "Rachel",
                desc = "Displays quotes by Rachel",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByMonica",
                name = "Monica",
                desc = "Displays quotes by Monica",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByMikeH",
                name = "Mike H.",
                desc = "Displays quotes by Mike H.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "enableQuotesByJanice",
                name = "Janice",
                desc = "Displays quotes by Janice",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "enableQuotesByFrankJr",
                name = "Frank Jr.",
                desc = "Displays quotes by Frank Jr.",
                icon = "gear",
                default = False,
            ),
        ],
    )
