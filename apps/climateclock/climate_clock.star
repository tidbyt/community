"""
Applet: Climate Clock
Summary: ClimateClock.world
Description: The most important number in the world.
Author: Rob Kimball
"""

load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# This is everything we would get from the API if we were to retrieve it over HTTP. In reality, the data here is only
# updated every couple of years so pinging the API isn't really necessary. I've pasted a recent JSON pull below, which
# makes updating the app easier and means fewer code changes if we do decide to start pulling it directly.
# This might be helpful if we add a screen to this app that displays their climate change news feed or the fund AUM.
# Source: https://api.climateclock.world/v1/clock
ALL_DATA = {
    "data": {
        "api_version": "v1.0",
        "config": {
            "device": "generic",
            "display": {
                "deadline": {
                    "color_primary": "#eb1c23",
                    "color_secondary": "#eb1c23",
                },
                "lifeline": {
                    "color_primary": "#4aa1cc",
                    "color_secondary": "#4aa1cc",
                },
                "neutral": {
                    "color_primary": "#ffffff",
                    "color_secondary": "#ffffff",
                },
                "newsfeed": {
                    "separator": " | ",
                },
                "timer": {
                    "unit_labels": {
                        "day": [
                            "DAY",
                            "D",
                        ],
                        "days": [
                            "DAYS",
                            "D",
                        ],
                        "year": [
                            "YEAR",
                            "YR",
                            "Y",
                        ],
                        "years": [
                            "YEARS",
                            "YRS",
                            "Y",
                        ],
                    },
                },
            },
            "modules": [
                "carbon_deadline_1",
                "renewables_1",
                "newsfeed_1",
            ],
        },
        "modules": {
            "carbon_deadline_1": {
                "description": "Time to act before we reach irreversible 1.5°C global temperature rise",
                "flavor": "deadline",
                "labels": [
                    "TIME LEFT TO LIMIT GLOBAL WARMING TO 1.5°C",
                    "TIME LEFT BEFORE 1.5°C GLOBAL WARMING",
                    "TIME TO ACT",
                ],
                "lang": "en",
                "timestamp": "2029-07-23T00:46:03+00:00",
                "type": "timer",
                "update_interval_seconds": 604800,
            },
            "green_climate_fund_1": {
                "description": "USD in the Green Climate Fund",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 9.52,
                "labels": [
                    "GREEN CLIMATE FUND",
                    "CLIMATE FUND",
                    "GCF",
                ],
                "lang": "en",
                "rate": "0",
                "resolution": "0.01",
                "timestamp": "2021-09-20T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "$B",
                ],
                "update_interval_seconds": 86400,
            },
            "indigenous_land_1": {
                "description": "Despite threats and lack of recognition, indigenous people are protecting this much land.",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 43.5,
                "labels": [
                    "LAND PROTECTED BY INDIGENOUS PEOPLE",
                    "INDIGENOUS PROTECTED LAND",
                    "INDIGENOUS PROTECTED",
                ],
                "lang": "en",
                "rate": "0",
                "resolution": "0.1",
                "timestamp": "2021-10-01T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "M KM²",
                ],
                "update_interval_seconds": 86400,
            },
            "newsfeed_1": {
                "description": "A newsfeed of hope: good news about climate change.",
                "flavor": "lifeline",
                "lang": "en",
                "newsfeed": [
                    {
                        "date": "2022-02-03T14:48:23+00:00",
                        "headline": "Snoqualmie Tribe Acquires 12,000 Acres of Ancestral Forestland in King County",
                        "headline_original": "Snoqualmie Tribe Acquires 12,000 Acres of Ancestral Forestland in King County ",
                        "link": "https://snoqualmietribe.us/snoqualmie-tribe-acquires-12000-acres-of-ancestral-forestland-in-king-county/?fbclid=IwAR390NwqMLsCso8T0gI1OYcOyxEJjOvCGgHUXEQmDjK78Aq6vW_ehPdJpu4 ",
                        "source": "Snoqualmie Tribe",
                        "summary": "",
                    },
                    {
                        "date": "2022-02-01T14:48:23+00:00",
                        "headline": "Earth has 14% more tree species than previously thought",
                        "headline_original": "Earth has more tree species than we thought ",
                        "link": "https://www.bbc.com/news/science-environment-60198433 ",
                        "source": "BBC",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-28T14:48:23+00:00",
                        "headline": "US federal judge blocks leasing more than 80 million acres for oil and gas production by the US Depa",
                        "headline_original": "In blow to Biden administration, judge halts oil and gas leases in Gulf of Mexico",
                        "link": "https://grist.org/energy/in-blow-to-biden-administration-judge-halts-oil-and-gas-leases-in-gulf-of-mexico/  ",
                        "source": "Grist",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-28T14:48:23+00:00",
                        "headline": "Australia pledges $700 million to protect Great Barrier Reef amid climate change threat",
                        "headline_original": "Australia pledges $700 million to protect Great Barrier Reef amid climate change threat  ",
                        "link": "https://edition.cnn.com/2022/01/27/australia/australia-great-barrier-reef-intl-hnk/index.html ",
                        "source": "CNN",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-27T14:48:23+00:00",
                        "headline": "China’s renewable energy sources may make up 50% of the country’s power capacity in 2022",
                        "headline_original": "Non-fossil fuels forecast to be 50% of China’s power capacity in 2022",
                        "link": "https://www.reuters.com/world/china/non-fossil-fuels-forecast-be-50-chinas-power-capacity-2022-2022-01-28/ ",
                        "source": "Reuters",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-26T14:48:23+00:00",
                        "headline": "Los Angeles City Council will ban new oil and gas wells and phase out existing wells",
                        "headline_original": "In historic vote, Los Angeles will phase out oil drilling",
                        "link": "https://grist.org/energy/in-historic-vote-los-angeles-will-phase-out-oil-drilling/ ",
                        "source": "Grist",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-24T14:48:23+00:00",
                        "headline": "China to cut energy consumption intensity by 13.5% in five years",
                        "headline_original": "China to cut energy consumption intensity by 13.5% pct in five years",
                        "link": "http://www.xinhuanet.com/english/20220124/b53f7dc6f5c246569cb440d87e387d83/c.html ",
                        "source": "Xinhua",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-13T14:48:23+00:00",
                        "headline": "Container shipping giant, Maersk, speeds up decarbonisation target by a decade",
                        "headline_original": "Maersk speeds up decarbonisation target by a decade",
                        "link": "https://www.reuters.com/markets/commodities/maersk-moves-net-zero-target-forward-by-decade-2040-2022-01-12/",
                        "source": "Reuters",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-02T14:48:23+00:00",
                        "headline": "France bans plastic packaging for most fruits and vegetables",
                        "headline_original": "France bans plastic packaging for most fruits and vegetables",
                        "link": "https://www.aljazeera.com/news/2022/1/2/france-bans-plastic-packaging-for-most-fruits-and-vegetables ",
                        "source": "AlJazeera",
                        "summary": "",
                    },
                ],
                "type": "newsfeed",
                "update_interval_seconds": 3600,
            },
            "renewables_1": {
                "description": "The percentage share of global energy consumption currently generated by renewable resources (solar, wind, hydroelectricity, wave and tidal, and bioenergy).",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 11.4,
                "labels": [
                    "WORLD'S ENERGY FROM RENEWABLES",
                    "GLOBAL RENEWABLE ENERGY",
                    "RENEWABLES",
                ],
                "lang": "en",
                "rate": "2.0428359571070087e-8",
                "resolution": "1e-9",
                "timestamp": "2020-01-01T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "%",
                ],
                "update_interval_seconds": 86400,
            },
        },
        "retrieval_timestamp": "2022-04-05T22:19:55+00:00",
    },
    "status": "success",
}

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def duration_to_string(sec):
    """
    Builds a prettier duration display from the total seconds than what is natively available in Go.
    This function was adapted from LukiLeu's Google Traffic app.

    :param sec: numeric type, total seconds of the trip duration
    :return: tuple of strings, years, days and a HH:MM:SS timestamp
    """
    seconds_in_year = 60 * 60 * 24 * 365
    seconds_in_day = 60 * 60 * 24
    seconds_in_hour = 60 * 60
    seconds_in_minute = 60

    years = sec // seconds_in_year
    days = (sec - (years * seconds_in_year)) // seconds_in_day
    hours = (sec - (years * seconds_in_year) - (days * seconds_in_day)) // seconds_in_hour
    minutes = (sec - (years * seconds_in_year) - (days * seconds_in_day) - (hours * seconds_in_hour)) // seconds_in_minute
    seconds = (sec - (years * seconds_in_year) - (days * seconds_in_day) - (hours * seconds_in_hour) - (minutes * seconds_in_minute))

    str_years, str_days, timestamp = "", "", ""
    for part in (hours, minutes, seconds):
        if part < 10:
            timestamp = timestamp + "0%i:" % part
        else:
            timestamp = timestamp + "%i:" % part
    timestamp = timestamp[:-1]  # final colon

    if years > 0:
        str_years = "%i Years" % years
    if days > 0:
        str_days = "%i Days" % days

    return str_years, str_days, timestamp

def renewables(DATA):
    fps = 20

    data = DATA["data"]["modules"]["renewables_1"]
    initial = data["initial"]  # 11.4
    units = data["unit_labels"][0]
    rate = float(data["rate"])
    start = time.parse_time(data["timestamp"])
    resolution = int(data["rate"][-1]) + 1

    end = time.now()
    elapsed = end - start
    current = elapsed.seconds * rate + initial

    def generate_data(x):
        # Decimal; generate {speed} values per second to animate over
        d = current + ((x * rate) / fps)

        # String; convert each one to a string, rounded to {resolution} digits
        s = "%s" % round(d, resolution)

        # Formatted; pad each string if it isn't at least {resolution + 3} long, so the animation doesn't jump
        f = s + "0" * (resolution - len(s) + 3) + units

        return render.Box(
            # expanded=True,
            # main_align="center",
            child = render.Text(f, color = "#050"),
            height = 16,
            width = 64,
        )

    # Generate enough frames to fill 15 seconds
    frames = [generate_data(x) for x in range(15 * 1000 // fps)]

    return render.Root(
        delay = 1000 // fps,
        child = render.Stack(
            children = [
                render.Image(BG_RENEWABLES),
                # render.Box(width = 64, height = 32, color = "#0006"),
                render.Column(
                    expanded = True,
                    main_align = "top",
                    cross_align = "center",
                    children = [render.Animation(children = frames)],
                ),
            ],
        ),
    )

def global_warming(DATA):
    fps = 1

    data = DATA["data"]["modules"]["carbon_deadline_1"]
    deadline = time.parse_time(data["timestamp"])
    rate = -1

    start = time.now()
    if deadline <= start:
        frames = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text("FIN", color = "#00094d"),
                ],
            ),
        ]
    else:
        remaining = int((deadline - start).seconds)

        frames = []

        for i in range(1, 15 * fps):
            years, days, stamp = duration_to_string(remaining + (rate * i))
            childs = []
            for element in (years, days, stamp):
                if len(element):
                    childs.append(
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Text(element, color = "#00094d"),
                            ],
                        ),
                    )
            frames.append(
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = childs,
                ),
            )

    return render.Root(
        delay = 1000 // fps,
        child = render.Stack(
            children = [
                render.Image(BG_WARMING),
                # render.Box(width = 64, height = 32, color = "#0003"),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [render.Animation(children = frames)],
                ),
            ],
        ),
    )

SCREENS = {
    "Renewable Energy": renewables,
    "Global Warming": global_warming,
}

def main(config):
    display = config.get("display", list(SCREENS.keys())[0])
    print(display)
    return SCREENS.get(display)(ALL_DATA)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display type",
                desc = "",
                icon = "chartPie",
                options = [
                    schema.Option(value = k, display = k)
                    for k, v in SCREENS.items()
                ],
                default = list(SCREENS.keys())[0],
            ),
        ],
    )

BG_RENEWABLES = base64.decode("""
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
""")

BG_WARMING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAABMJJREFUaEPlWd1vG0UQn7X6UCGkQlXxQv1URPiohBCExAnn89mJ0zbky+RCJV56f9mhAqJgSBOnJa1T++y4UQMtoEDcJIU39wlVrSqhigeUQbMfd+uzLwZRkUt6L3ezMz7N77e/md09s5NHAUFe9/9UTwAnjwbPrV/OBAYPZ4GNCMA0+4D4jYE6x8B0AjSU/uMrzwH89qSbB6CdmO4xcRs1B67zlBqPRGacAAJJlw5UjfUC4H2nq6NX9P77rYFrPInaQ0lA5nhQAt3T0+VNEX7F8PA4EmD2lyGR2O1Qrl7imeMaAd1AWFIqPCyRANjdlfwIAuIIXE0gzXJU2aoYRQbDe2fap3T/VfqfM7AGhczDZa3G9L7GcGssmgBS/170xMxvpCoc45HEXz1JVAph2BxDvqqp1e0Q3M3hFYDELiQkDap4ExIo2crH8OdR5Ou4Ws8PwX18cB2urg+K/UkPPAw3RjWRhzV9+G2GP4484wTc0QnYu3dY+Rt8eWndHOnZZA5KAKONkLeck7uCUNcPVUDSFF22Vf9n8X5zVWzEsKIY3sqhNV4RM1vLRa4G1jkZ4+XEWegArxZJS0wkXQzXsmhNVP2dU6uS7VBvL3+c5M6Gq4BrnRj0HJO5qlByJQsMG1neBK0pQUJrpQsB0kc7KG9x75fvJxnMEMCw0T1HwkgXHYTouE/bYYa1DB3owSp4goBrGXneFxqPGo9jDbBMDbDWnr/Kk3DoW2OaTCKCYVUSMCsJ+DZEQMR4HAnYqzlZs55/BFYnQUHAisl3gtZcTShgyZRfeBCsuXrQG66YkPxAfEVpXSGSZBf0vwjF105OiLxJ8gTe+yoDbKQmm2DZFD3gvADbKplaGTOwztfAu2RCclK8hBPgx8RrXWP5OmA5yJ9yVic/dfyl2lfyx3IGGC6nBQEfrwoCLqfb+hiNq9ohX3JmtSNmPxtfW3fXclN41Mwr4ISRN/PPBU6GVwUBUZezPgHu4BKoe/LDVfGCT9uJigMJlFvrm/a8aExdet729fehOHYTGJYMnwDn9iS4/SX/B/YNA54/9iIf4773Su3fB+JVAWBdaID3icHzz1/qg2MnXuL50/XH40fw+MHv/PnlU33cLo42gOGC4X8PsKsGFLMN3kydO5P+j8of7XDbfbcEdsWAYq4Ry0XA+WES3HdK/mJAeMIElOd2uF/hYDg/zPcBdi0NxUwgF+enqYCA2W0g2317sSMuYCKqCEL/I3SEPT2/yjmMQylAjetxDL+WBKymoZgmAkRCzoZGQGGb2+5bi2CH4uIkBWdjWkg7hMMnQBtXOBh+OYTO5gy4py+DvZbhdVKe2gJnU7xMt9WLSFbkU/JyTy/E4nREODgBw7Rky4ncnPZ7gBrX4xh+MYTO3Rke5L6xAPml16E8sQXOXY0AaZPfvmVCMVUX96E6OM1p/ruuSlCfpKKOj0/ZTzg4ASlJAGM8P18BapxKXubP8LMUOjsFcPvmwf7eEjM+3gRnuxAoQNqRCnhtPhaVQDg4AQMez4fwdDTBc03Q4xheTKHzawHcV+fBvi0JONsE555GgLRVTLHf436y1d3vbeGe9j/aKmfKL7/8ZuQyWD7b5Fgpjp144cih+2Pk32zKnnkC/gamm/tRuDLkTAAAAABJRU5ErkJggg==
""")
