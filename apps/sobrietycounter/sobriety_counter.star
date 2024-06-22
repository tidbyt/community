"""
Applet: Sobriety Counter
Summary: Show your sober day count
Description: Show how many days you've been sober from any addiction.
Author: elliotstoner
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"

COMMA_10x20 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAIAAABvrngfAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAI0lEQVQImWNkYGBgYGD4//8/hMHIyMjEgAEY0ZRAtcCFSAEAVKQL/9I+OiMAAAAASUVORK5CYII=")
SPACE_6x13 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAIAAAASFvFNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAC0lEQVQImWNgwAQAABQAAWX1h1kAAAAASUVORK5CYII=")
EXCLAMATION_6x13 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAALCAIAAAAx7HC4AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAHElEQVQImWP4//8/EwMDAzbMwMDAwPD//38YEwCc+AYH2051aAAAAABJRU5ErkJggg==")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "sober_date",
                name = "Sober Start Date",
                desc = "When was your sober start date?",
                icon = "calendar",
            ),
            schema.Dropdown(
                id = "addiction",
                name = "Addiction",
                desc = "What are you getting sober from?",
                icon = "poo",
                # Options are defined at the end of this file
                options = options,
                default = options[0].value,
            ),
            schema.Generated(
                id = "generated",
                source = "addiction",
                handler = other_addiction,
            ),
        ],
    )

def other_addiction(option):
    if option == "other":
        return [
            schema.Text(
                id = "addiction_other",
                name = "Other Addiction",
                desc = "Enter your custom addiction.",
                icon = "pen",
            ),
        ]
    else:
        return []

def get_addiction(config):
    addiction = config.get("addiction")
    if (addiction == "other"):
        addiction = config.get("addiction_other")
    if (addiction == None or addiction == "none" or len(addiction) == 0):
        return None
    return addiction

# Max is 99,999
def get_sober_day_count(config):
    user_sober_datetime = config.get("sober_date")
    if (user_sober_datetime == None):
        return None

    timezone = config.get("$tz") or DEFAULT_TIMEZONE
    now = time.now().in_location(timezone)
    user_sober_date = user_sober_datetime.partition("T")[0]
    sober_date = time.parse_time(user_sober_date, format = "2006-01-02", location = timezone).in_location(timezone)

    sober_days = (now - sober_date).hours // 24
    if (sober_days > 99999 or sober_days < 0):
        return None

    return int("%d" % (sober_days))

def format_days(days):
    if (days <= 999):
        return [
            render.Text(
                content = str(days),
                font = "10x20",
            ),
        ]
    else:
        pre = days // 1000
        post = days % 1000

        post_text = str(post)
        if (post <= 9):
            post_text = "00%s" % (post)
        elif (post <= 99):
            post_text = "0%s" % (post)

        return [
            render.Text(
                content = str(pre),
                font = "10x20",
            ),
            render.Image(
                src = COMMA_10x20,
            ),
            render.Text(
                content = post_text,
                font = "10x20",
            ),
        ]

def get_subtext(addiction, isSingular):
    day_text = "Days"
    if isSingular:
        day_text = "Day"

    if (addiction == None):
        return render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "end",
            children = [
                render.Text(
                    content = day_text,
                    font = "6x13",
                ),
                render.Image(
                    src = SPACE_6x13,
                ),
                render.Text(
                    content = "Sober",
                    font = "6x13",
                ),
                render.Image(
                    src = EXCLAMATION_6x13,
                ),
            ],
        )
    else:
        addiction_text = addiction
        for o in options:
            if (o.value == addiction):
                addiction_text = o.display
                break

        return render.Marquee(
            width = 64,
            offset_start = 10,
            child = render.Row(
                main_align = "left",
                cross_align = "end",
                children = [
                    render.Text(
                        content = day_text,
                        font = "6x13",
                    ),
                    render.Image(
                        src = SPACE_6x13,
                    ),
                    render.Text(
                        content = "Without",
                        font = "6x13",
                    ),
                    render.Image(
                        src = SPACE_6x13,
                    ),
                    render.Text(
                        content = addiction_text,
                        font = "6x13",
                    ),
                    render.Image(
                        src = EXCLAMATION_6x13,
                    ),
                ],
            ),
        )

def main(config):
    addiction = get_addiction(config)
    sober_days = get_sober_day_count(config)

    if (sober_days == None):
        return render.Root(
            child = render.WrappedText(
                content = "Provide your sober date in app config.",
                width = 64,
            ),
        )

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Padding(
                    pad = (0, -1, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "end",
                        children = format_days(sober_days),
                    ),
                ),
                get_subtext(addiction, sober_days == 1),
            ],
        ),
    )

# --- Options Begin ---

options = [
    schema.Option(
        display = "-- Don't Show --",
        value = "none",
    ),
    schema.Option(
        display = "Adderall",
        value = "adderall",
    ),
    schema.Option(
        display = "Alcohol",
        value = "alcohol",
    ),
    schema.Option(
        display = "Amphetamines",
        value = "amphetamines",
    ),
    schema.Option(
        display = "Benzodiazepines",
        value = "benzodiazepines",
    ),
    schema.Option(
        display = "Binge Drinking",
        value = "bingedrinking",
    ),
    schema.Option(
        display = "Binge Eating",
        value = "bingeeating",
    ),
    schema.Option(
        display = "Binging & Purging",
        value = "bingingpurging",
    ),
    schema.Option(
        display = "Caffeine",
        value = "caffeine",
    ),
    schema.Option(
        display = "Cannabis",
        value = "cannabis",
    ),
    schema.Option(
        display = "Cigarettes",
        value = "cigarettes",
    ),
    schema.Option(
        display = "Cocaine",
        value = "cocaine",
    ),
    schema.Option(
        display = "Drugs",
        value = "drugs",
    ),
    schema.Option(
        display = "DXM",
        value = "dxm",
    ),
    schema.Option(
        display = "Ecstasy",
        value = "ecstasy",
    ),
    schema.Option(
        display = "Energy Drinks",
        value = "energydrinks",
    ),
    schema.Option(
        display = "Fast Food",
        value = "fastfood",
    ),
    schema.Option(
        display = "Fentanyl",
        value = "fentanyl",
    ),
    schema.Option(
        display = "Gambling",
        value = "gambling",
    ),
    schema.Option(
        display = "GHB",
        value = "ghb",
    ),
    schema.Option(
        display = "Hair Pulling",
        value = "hairpulling",
    ),
    schema.Option(
        display = "Heroin",
        value = "heroin",
    ),
    schema.Option(
        display = "Junk Food",
        value = "junkfood",
    ),
    schema.Option(
        display = "Ketamine",
        value = "ketamine",
    ),
    schema.Option(
        display = "Kratom",
        value = "kratom",
    ),
    schema.Option(
        display = "Masturbation",
        value = "masturbation",
    ),
    schema.Option(
        display = "Meth",
        value = "meth",
    ),
    schema.Option(
        display = "Methadone",
        value = "methadone",
    ),
    schema.Option(
        display = "Nail Biting",
        value = "nailbiting",
    ),
    schema.Option(
        display = "Nicotine",
        value = "nicotine",
    ),
    schema.Option(
        display = "Online Shopping",
        value = "onlineshopping",
    ),
    schema.Option(
        display = "Opiates",
        value = "opiates",
    ),
    schema.Option(
        display = "Pornography",
        value = "pornography",
    ),
    schema.Option(
        display = "Purging",
        value = "purging",
    ),
    schema.Option(
        display = "Self-harm",
        value = "selfharm",
    ),
    schema.Option(
        display = "Sex",
        value = "sex",
    ),
    schema.Option(
        display = "Shopping",
        value = "shopping",
    ),
    schema.Option(
        display = "Skin Picking",
        value = "skinpicking",
    ),
    schema.Option(
        display = "Social Media",
        value = "socialmedia",
    ),
    schema.Option(
        display = "Soft Drinks",
        value = "softdrinks",
    ),
    schema.Option(
        display = "Suboxone",
        value = "suboxone",
    ),
    schema.Option(
        display = "Sugar",
        value = "sugar",
    ),
    schema.Option(
        display = "Sweets",
        value = "sweets",
    ),
    schema.Option(
        display = "Tobacco",
        value = "tobacco",
    ),
    schema.Option(
        display = "Vaping",
        value = "vaping",
    ),
    schema.Option(
        display = "Video Games",
        value = "videogames",
    ),
    schema.Option(
        display = "Xanax",
        value = "xanax",
    ),
    schema.Option(
        display = "- Other -",
        value = "other",
    ),
]
