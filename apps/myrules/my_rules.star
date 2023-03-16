"""
Applet: My Rules
Summary: Set rules for yourself
Description: Display one of several rules you set for yourself.
Author: hloeding
"""

# ################################
# ###### App module loading ######
# ################################

# Required modules
load("render.star", "render")
load("random.star", "random")
# ###########################
# ###### App constants ######
# ###########################

DEFAULT_RULES = [
    "Be kind",
    "Be the change you wish to see in the world",
    "Live each day as if it were your last",
    "The grass is green where you water it",
    "Breathe in courage, breathe out fear",
    "This too shall pass",
    "I am what I think about",
    "Tomorrow is another day",
    "Progress, not perfection",
    "Honesty is the best policy",
    "We are all a work in progress",
    "Be intentional in all that you do",
    "Eyes on the prize",
    "You miss 100 percent of the shots you don't take",
    "Fake it 'till you make it",
    "Remember your why",
    "Life begins at the end of the comfort zone",
    "There is always something to be grateful for",
    "Vision without action is a daydream",
    "There is no time like the present",
    "Don't sweat the small stuff",
    "It doesn't matter how slowly you go, just don't stop",
    "Be a rainbow in someone else's cloud",
    "Let go of who you think you should be",
    "When life gives you lemons, make lemonade"
]

# #######################################
# ###### Functions to render rules ######
# #######################################

def renderRule():
    ruleIdx = random.number(0, len(DEFAULT_RULES ) - 1)
    rule = DEFAULT_RULES[ruleIdx]
    return render.Column(
        children = [
            render.Marquee(
                child = render.Text(
                    content = "Rule %d:" % (ruleIdx + 1),
                    font = "Dina_r400-6",
                    color = "#00bbff",
                ),
                width = 62,
            ),
            render.Marquee(
                child = render.Text(
                    content = rule,
                    # font = "6x13",
                    font = "10x20"
                ),
                width = 62,
            ),
        ],
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center"
    )

# #############################
# ###### App entry point ######
# #############################

# Main entrypoint
def main(config):
    return render.Root(
        render.Box(
            child = renderRule(),
            padding = 1,
        ),
        show_full_animation = True,
    )
