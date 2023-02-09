"""
Applet: Baby Steps
Summary: Financial Baby Steps
Description: Tracks your baby steps to financial freedom.
Author: Robert Ison
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

steps = {
    0: {
        "step": "Baby Step 0",
        "color": "#ffffff",
        "name": "Preparing",
        "info": "Written budget, agree with spouse on plan, get current on food, utilities, shelter, basic transportation, sell toys, cut lifestyle.",
    },
    1: {
        "step": "Baby Step 1",
        "color": "#0074bf",
        "name": "Emergency Fnd",
        "info": "Save $1000 for your Starter Emergency Fund, chop up credit cards, get health and life insurance, sell cars, raise deductibles, get a will, get long-term disability.",
    },
    2: {
        "step": "Baby Step 2",
        "color": "#00d0e1",
        "name": "Debt Snowball",
        "info": "Pay off debt (except the house) from lowest balance to highest.",
    },
    3: {
        "step": "Baby Step 3",
        "color": "#00b0a0",
        "name": "Full Emergency Fund",
        "info": "Save 3-6 months of expenses in a fully funded emergency fund.",
    },
    4: {
        "step": "Baby Step 4",
        "color": "#00c049",
        "name": "Invest for Retirement",
        "info": "Invest 15% of your income in retirement funds. Fund 401k to company match, then fund Roth IRA to max, then contribute more to 401k to total 15% of your income.",
    },
    5: {
        "step": "Baby Step 5",
        "color": "#ecb500",
        "name": "College Fund",
        "info": "Invest in college funds for your children with Education Savings Accounts, 529 Plans, etc.",
    },
    6: {
        "step": "Baby Step 6",
        "color": "#f99600",
        "name": "Pay off house",
        "info": "Pay off your house early with extra payments.",
    },
    7: {
        "step": "Baby Step 7",
        "color": "#e85c00",
        "name": "Build Wealth and Give",
        "info": "Have fun by giving, building wealth and enjoying life!",
    },
}

def get_progress_bar(step):
    """ get_progress_bar

    Args:
        step: Get the step selected by the user
    Returns:
        Progress Bar
    """
    box_list = []

    for i in range(0, step + 1):
        width = 8
        if i == 7:
            width = 8

        box_list.append(render.Box(width = width, height = 1, color = steps[i]["color"]))

    return render.Row(
        children =
            box_list,
    )

def main(config):
    """ main

    Args:
        config: Configuration object
    Returns:
        Tidbyt Display
    """
    current_step = int(config.get("step", 3))

    #pick random if requested
    if current_step > 7:
        current_step = random.number(0, 7)
    display_text = steps[current_step]["info"]
    if (current_step < 7):
        display_text = display_text + " Next Step: " + steps[(current_step + 1)]["name"]
    return render.Root(
        render.Column(
            children = [
                render.Text(content = steps[current_step]["step"], color = steps[current_step]["color"], font = "tb-8"),
                render.Marquee(width = 64, child = render.Text(content = steps[current_step]["name"], color = "#ffff00", font = "tb-8")),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(content = display_text, color = "#ffff00", font = "tb-8"),
                        ),
                    ],
                ),
                render.Box(width = 1, height = 4, color = "#000000"),
                get_progress_bar(current_step),
                get_progress_bar(7),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    step_options = [
        schema.Option(value = "0", display = "0 - Preparing"),
        schema.Option(value = "1", display = "1 - Starter Emergency Fund"),
        schema.Option(value = "2", display = "2 - Debt Snowball"),
        schema.Option(value = "3", display = "3 - Full Emergency Fund"),
        schema.Option(value = "4", display = "4 - Invest for Retirement"),
        schema.Option(value = "5", display = "5 - College Fund"),
        schema.Option(value = "6", display = "6 - Pay off Home"),
        schema.Option(value = "7", display = "7 - Build Wealth and Give"),
        schema.Option(value = "8", display = "Just Display a Step at Random"),
    ]

    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "step",
                name = "Step",
                desc = "Baby Step to Display",
                icon = "stairs",
                options = step_options,
                default = step_options[3].value,
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
