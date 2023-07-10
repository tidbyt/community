"""
Applet: Maya Calendar
Summary: Displays Maya calendar
Description: Displays Maya Long Count, Tzolk’in, and Haab’ calendars.
Author: Doug Ewell
Version: 1.0.1
Date: 2023-06-30 (13.0.10.12.3 12 Ak’b’al 11 Sek)
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/Merida"
# could have chosen America/Guatemala instead

IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAAQCAIAAACZeshMAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAADCSURBVDhPY2TABjYXSkNZMODb/xTKQgLYNT+fpAxlwYBk3l0oCwkMHpvhdgoErdjbGwBkOBdv+LAuAiKIZj8TlIYBE0UOCILywQCrIBCgaAZae+b+DwiCCoEBXBAtLFA0w21AswSXOAuUhlkL5QD9bAhlAAGyOFAZ3OcIm5GNR7MBlxTUZjRrgQCXzUAAtxyqGdk8CLgDpUEAUxYCQJoxrQUCPDYDAcRykGasBhNlM1ZrgQC/zUAA1MiCy1TCNjMwAACNWFpLrbT+OAAAAABJRU5ErkJggg==""")

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    days_since_creation = get_days_since_creation(now)
    long_count = get_long_count(days_since_creation)
    tzolkin = get_tzolkin(days_since_creation)
    haab = get_haab(days_since_creation)
    return show_calendars(long_count, tzolkin, haab)

def get_days_since_creation(date):
    jd = get_julian_date(date)

    # gmt = Goodman–Martinez–Thompson correlation, not Greenwich Mean Time :)
    gmt_correlation = 584283
    return jd - gmt_correlation

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
                        pad = (1, 3, 0, 2),
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
