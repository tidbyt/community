"""
Applet: Maya Calendar
Summary: Current Maya calendar date
Description: Displays today’s date in the Maya Long Count, Tzolk’in, and Haab’ calendars.
Author: Doug Ewell
Version: 1.1.0
Date: 2023-12-20 (13.0.11.2.16  3 K’ib’ 4 K’ank’in)
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_CORRELATION = "584283"
DEFAULT_TIMEZONE = "America/Merida"  # could have chosen America/Guatemala instead

IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAAQCAIAAACZeshMAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAADCSURBVDhPY2TABjYXSkNZMODb/xTKQgLYNT+fpAxlwYBk3l0oCwkMHpvhdgoErdjbGwBkOBdv+LAuAiKIZj8TlIYBE0UOCILywQCrIBCgaAZae+b+DwiCCoEBXBAtLFA0w21AswSXOAuUhlkL5QD9bAhlAAGyOFAZ3OcIm5GNR7MBlxTUZjRrgQCXzUAAtxyqGdk8CLgDpUEAUxYCQJoxrQUCPDYDAcRykGasBhNlM1ZrgQC/zUAA1MiCy1TCNjMwAACNWFpLrbT+OAAAAABJRU5ErkJggg==""")

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    days_since_creation = get_days_since_creation(now, config)
    long_count = get_long_count(days_since_creation)
    tzolkin = get_tzolkin(days_since_creation)
    haab = get_haab(days_since_creation)
    return show_calendars(long_count, tzolkin, haab)

# Date conversions cross-checked with http://research.famsi.org/date_mayaLC.php

def get_days_since_creation(date, config):
    jd = get_julian_date(date)
    correlation = int(config.get("correlation", DEFAULT_CORRELATION))
    return jd - correlation

def get_julian_date(date):
    Y = date.year
    M = date.month
    D = date.day
    M1 = (M + 9) // 12 - 1
    jd = (1461 * (Y + 4800 + M1)) // 4 + (367 * (M - 2 - 12 * M1)) // 12 - (3 * ((Y + 4900 + M1) // 100)) // 4 + D - 32075
    return jd

def get_long_count(days):
    kin = days % 20
    days = int(days / 20)
    winal = days % 18
    days = int(days / 18)
    tun = days % 20
    days = int(days / 20)
    katun = days % 20
    baktun = int(days / 20)
    return "%s.%s.%s.%s.%s" % (baktun, katun, tun, winal, kin)

# Curly apostrophes (’) are not supported in the tom-thumb font,
# so we must use straight apostrophes (') for day and month names.

def get_tzolkin(days):
    day_names = [
        "Imix'",
        "Ik'",
        "Ak'b'al",
        "K'an",
        "Chikchan",
        "Kimi",
        "Manik'",
        "Lamat",
        "Muluk",
        "Ok",
        "Chuwen",
        "Eb'",
        "B'en",
        "Ix",
        "Men",
        "K'ib'",
        "Kab'an",
        "Etz'nab'",
        "Kawak",
        "Ajaw",
    ]
    day_number = ((days + 3) % 13) + 1
    day_name = (days + 19) % 20
    return "%s %s" % (day_number, day_names[day_name])

def get_haab(days):
    month_names = [
        "Pop",
        "Wo'",
        "Sip",
        "Sotz'",
        "Sek",
        "Xul",
        "Yaxk'in",
        "Mol",
        "Ch'en",
        "Yax",
        "Sak'",
        "Keh",
        "Mak",
        "K'ank'in",
        "Muwan",
        "Pax",
        "K'ayab",
        "Kumk'u",
        "Wayeb'",
    ]
    haab_day = (days - 17) % 365
    day = haab_day % 20
    month = int(haab_day / 20)
    return "%s %s" % (day, month_names[month])

def show_calendars(long_count, tzolkin, haab):
    return render.Root(
        max_age = 60,
        child = render.Box(
            padding = 0,
            child = render.Column(
                children = [
                    render.Padding(
                        pad = (2, 3, 0, 2),
                        child = render.Text(
                            content = long_count,
                            color = "#fff",
                        ),
                    ),
                    render.Row(
                        children = [
                            render.Column(
                                children = [
                                    render.Padding(
                                        pad = (2, 1, 0, 2),
                                        child = render.Text(
                                            content = tzolkin,
                                            font = "tom-thumb",
                                            color = "#e79223",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (2, 0, 0, 0),
                                        child = render.Text(
                                            content = haab,
                                            font = "tom-thumb",
                                            color = "#56a0a0",
                                        ),
                                    ),
                                ],
                            ),
                            render.Box(
                                child = render.Padding(
                                    pad = (0, 0, 0, 2),
                                    child = render.Image(
                                        width = 20,
                                        src = IMAGE,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    show_options = [
        schema.Option(
            display = "Bowditch — 394483",
            value = "394483",
        ),
        schema.Option(
            display = "Makemson — 489138",
            value = "489138",
        ),
        schema.Option(
            display = "Spinden — 489384",
            value = "489384",
        ),
        schema.Option(
            display = "Martínez-Hernández — 584281",
            value = "584281",
        ),
        schema.Option(
            display = "GMT (Goodman-Martínez-Thompson) — 584283",
            value = "584283",
        ),
        schema.Option(
            display = "Thompson (Lounsbury) — 584285",
            value = "584285",
        ),
        schema.Option(
            display = "Martin-Skidmore — 584286",
            value = "584286",
        ),
        schema.Option(
            display = "Fuls et al. — 660208",
            value = "660208",
        ),
        # Other correlations exist, but are even less credible than these. Use GMT.
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "correlation",
                name = "Correlation",
                desc = "Julian day number of the current creation",
                icon = "calculator",
                default = show_options[4].value,  # GMT
                options = show_options,
            ),
        ],
    )
