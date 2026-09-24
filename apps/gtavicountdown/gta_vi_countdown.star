"""GTA VI release countdown for 64 x 32 Tidbyt displays.

Release date announced by Rockstar Games: November 19, 2026.
The countdown uses the viewer's local calendar date when a location is set.
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RELEASE_DATE = (2026, 11, 19)
DEFAULT_TIMEZONE = "Europe/Paris"

# Original 30 x 30 pixel art inspired by the VI lettering; no external asset.
VI_ICON = base64.decode("""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""")

def _day_number(year, month, day):
    """Gregorian civil-day number, independent of daylight saving time."""
    if month <= 2:
        year -= 1
    era = year // 400
    year_in_era = year - era * 400
    shifted_month = month + (9 if month <= 2 else -3)
    day_in_year = (153 * shifted_month + 2) // 5 + day - 1
    day_in_era = year_in_era * 365 + year_in_era // 4 - year_in_era // 100 + day_in_year
    return era * 146097 + day_in_era

def _remaining_days(iso_date):
    current = _day_number(int(iso_date[:4]), int(iso_date[5:7]), int(iso_date[8:10]))
    release = _day_number(RELEASE_DATE[0], RELEASE_DATE[1], RELEASE_DATE[2])
    return release - current

def main(config):
    location = config.get("location")
    timezone = json.decode(location).get("timezone") if location else DEFAULT_TIMEZONE
    language = config.get("language") or "en"
    today = time.now().in_location(timezone or DEFAULT_TIMEZONE).format("2006-01-02")
    days = _remaining_days(today)

    if days < 0:
        number = "SORTI" if language == "fr" else "OUT"
        number_font = "tb-8"
        label = "ENFIN" if language == "fr" else "NOW"
    else:
        number = str(days)
        number_font = "10x20" if days < 1000 else "6x13"
        if language == "fr":
            label = "JOUR" if days == 1 else "JOURS"
        else:
            label = "DAY" if days == 1 else "DAYS"

    return render.Root(
        child = render.Box(
            color = "#120B28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 31,
                        height = 32,
                        child = render.Image(src = VI_ICON),
                    ),
                    render.Box(
                        width = 33,
                        height = 32,
                        child = render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = number, font = number_font, color = "#FFE4BE"),
                                render.Text(content = label, font = "CG-pixel-3x5-mono", color = "#EF8FC6"),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used to count days in your local time zone.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "language",
                name = "Language",
                desc = "Language of the countdown label.",
                icon = "gear",
                default = "en",
                options = [
                    schema.Option(display = "English", value = "en"),
                    schema.Option(display = "Français", value = "fr"),
                ],
            ),
        ],
    )
