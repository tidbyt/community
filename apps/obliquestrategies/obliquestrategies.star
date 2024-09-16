"""
Applet: ObliqueStrategies
Summary: 100+ Worthwhile Dilemmas
Description: Picks an Oblique Strategy at random and displays it.
Author: @parsnbl
"""

load("random.star", "random")
load("render.star", "render")

MARQUEE_HEIGHT = 32
MARQUEE_OFFSET_END = 32
MARQUEE_OFFSET_START = 0
MARQUEE_ALIGN = "center"

QUOTE_CONTAINER_PADDING = (1, 0, 1, 0)
SPACER_SPACING = 7

FONT = "tb-8"
BLACK = "#000"
WHITE = "#FFF"

MAIN_FONT_COLOR = WHITE
HEADER_FONT_COLOR = BLACK
HEADER_BOX_COLOR = WHITE
BACKGROUND_COLOR = BLACK

def main():
    select = random.number(0, len(OBLIQUE_STRATEGIES) - 1)  #11
    children = [
        header(),
        quote_spacer(),
        quote_container(select),
        quote_spacer(),
        footer(select),
    ]
    marquee_queue = render.Column(
        main_align = "start",
        cross_align = "center",
        children = children,
    )
    return render.Root(
        delay = 100,
        child = marquee(marquee_queue),
    )

def header():
    return render.Box(
        color = BACKGROUND_COLOR,
        width = 64,
        height = 18,
        padding = 1,
        child = render.Box(
            color = HEADER_BOX_COLOR,
            padding = 0,
            child = render.Box(
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = "OBLIQUE",
                            font = FONT,
                            color = HEADER_FONT_COLOR,
                        ),
                        render.Text(
                            content = "STRATEGIES",
                            font = FONT,
                            color = HEADER_FONT_COLOR,
                        ),
                    ],
                ),
            ),
        ),
    )

def quote_spacer():
    return render.Box(
        color = BACKGROUND_COLOR,
        height = SPACER_SPACING,
    )

def footer(num):
    num_s = str(num + 1)
    num_texts = str(len(OBLIQUE_STRATEGIES))
    return render.Column(
        cross_align = "center",
        children = [
            render.Padding(
                pad = QUOTE_CONTAINER_PADDING,
                child = render.Box(
                    color = MAIN_FONT_COLOR,
                    height = 1,
                ),
            ),
            render.Text(
                content = num_s + "/" + num_texts,
                color = MAIN_FONT_COLOR,
                font = FONT,
            ),
        ],
    )

def quote_container(selector):
    quote = OBLIQUE_STRATEGIES[selector]
    return render.Padding(
        pad = QUOTE_CONTAINER_PADDING,
        child = render.Column(
            main_align = "top",
            cross_align = "center",
            children = [
                render.WrappedText(
                    content = "{}".format(quote),
                    font = FONT,
                    color = MAIN_FONT_COLOR,
                    align = "center",
                ),
            ],
        ),
    )

def marquee(child):
    return render.Marquee(
        scroll_direction = "vertical",
        height = MARQUEE_HEIGHT,
        offset_end = MARQUEE_OFFSET_END,
        offset_start = MARQUEE_OFFSET_START,
        align = MARQUEE_ALIGN,
        child = child,
    )

OBLIQUE_STRATEGIES = [
    "The inconsistency principle",
    "How would you have done it?",
    "Put in earplugs",
    "Ask your body",
    "Towards the insignificant",
    "Faced with a choice, do both",
    "Overtly resist change",
    "Emphasize repetitions",
    "Give the game away",
    "Remove ambiguities and convert to specifics",
    "Would anybody want it?",
    "Bridges \n- build\n- burn",
    "Give way to your worst impulse",
    "Are there sections? Consider transitions",
    "Disciplined self- \nindulgence",
    "Lowest common denominator check\n- single beat\n- single note\n- single riff",
    "Only one element of each kind",
    "What is the reality of the situation?",
    "Balance the consistency principle\nwith the inconsistency principle",
    "Decorate, decorate",
    "It is quite possible (after all)",
    "Allow an easement \n(an easement is the abandonment of a stricture)",
    "Disconnect from desire",
    "Feedback recordings into an acoustic situation",
    "Be extravagant",
    "Is there something missing?",
    "Use fewer notes",
    "Define an area as 'safe' and use it as an anchor",
    "Intentions\n- credibility of\n- nobility of\n- humility of",
    "Retrace your steps",
    "Emphasize differences",
    "Tape your mouth \nTwist the spine",
    "You can only make one dot at a time",
    "Use filters",
    "Accept advice",
    "Distorting time",
    "Use an unacceptable color",
    "What are you really thinking about just now?",
    "Take a break",
    "Use an old idea",
    "Imagine the music as a moving chain or caterpillar",
    "What wouldn't you do?",
    "Question the heroic approach",
    "Take away the elements in order of \napparent non-\nimportance",
    "Only a part, not the whole",
    "Not building a wall but making a brick",
    "Courage!",
    "Look at a very small object, look at its centre",
    "A line has \ntwo sides",
    "Don't be afraid of things because they're easy to do",
    "Don't stress one thing more than another",
    "What would your closest friend do?",
    "Always first steps",
    "The tape is \nnow the \nmusic",
    "Emphasize \nthe flaws",
    "Ghost echoes",
    "State the problem in words as clearly as possible",
    "Get your neck massaged",
    "Don't be frightened to display your talents",
    "Repetition is a form of change",
    "Do we need holes?",
    "Reverse",
    "Make a blank valuable\nby putting it in an exquisite frame",
    "The most important thing is the thing\nmost easily forgotten",
    "Cascades",
    "Discover the recipes you are using and abandon them",
    "Destroy\n- nothing\n- the most important thing",
    "Use unqualified people",
    "Don't break the silence",
    "Go slowly all the way round the outside",
    "Do the washing up",
    "From nothing to more than nothing",
    "Humanize something free of error",
    "Discard an axiom",
    "Look closely at the most embarrassing\ndetails and amplify them",
    "Make a sudden, destructive unpredictable action; incorporate",
    "Idiot glee",
    "Imagine the music as \na set of \ndisconnected events",
    "You don't have to be ashamed of using your own ideas",
    "Consult \nother \nsources",
    "Is the tuning appropriate?",
    "Always give yourself credit for having\nmore than personality",
    "Work at a different speed",
    "Remove specifics and convert to ambiguities",
    "Remember those quiet evenings",
    "Make an exhaustive list of everything you might do\nand do the last thing on the list",
    "Go to an extreme,\nmove back to a more comfortable place",
    "Simple subtraction",
    "Simply a matter of work",
    "Don't be frightened \nof clichés",
    "Tidy up",
    "Do the \nwords need changing?",
    "Look at the order in which you \ndo things",
    "Listen to the quiet voice",
    "What mistakes did you make last time?",
    "Consider different fading systems",
    "Turn it \nupside down",
    "Abandon normal instruments",
    "Mechanicalize something idiosyncratic",
    "Fill every beat with something",
    "Shut the door and listen from outside",
    "Revaluation (a warm feeling)",
    "Think of \nthe radio",
    "Convert a melodic element into a rhythmic element",
    "Do\nsomething\nboring",
    "Honor thy error as a hidden intention",
    "Is it finished?",
    "Go outside. \nShut the door.",
    "Into the impossible",
    "Once the search is in progress, something will be \nfound",
    "Children's voices\n- speaking\n- singing",
    "Be less critical \nmore often",
    "Trust in the you of now",
    "Spectrum analysis",
    "Change nothing and continue with immaculate consistency",
    "Ask people to work against their better judgment",
    "Do nothing \nfor as long \nas possible",
    "You are an engineer",
    "Just carry on",
    "Incorporate.",
    "Breathe more deeply",
    "Infinitesimal gradations",
    "Accretion",
    "Change instrument roles",
    "Cluster analysis",
    "Short circuit\n (example: \na man eating peas with the idea that they will\n improve his \nvirility shovels them straight into his lap)",
    "Mute and continue",
    "Assemble \nsome of the instruments in a group \nand treat \nthe group",
    "Imagine the piece as \na set of disconnected events",
    "Water",
    "Listen in total darkness,\nor in a very large room, very quietly",
    "(Organic) machinery",
]
