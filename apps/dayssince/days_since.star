"""
Applet: Days Since
Summary: Days since last incident
Description: Displays the number of days since the incident supplied in the free text box. Default is the Noodle Incident from Calvin & Hobbes. Based on AccidentFreeDays by Robert Ison.
Author: Drew Tschetter
"""

load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_DATE_TIME = "1987-04-22T00:00:00Z"  # Unconfirmed date of the Noodle Incident from Calvin & Hobbes; https://www.gocomics.com/calvinandhobbes/1987/04/22
DEFAULT_COLOR = "#EEFF33"
DEFAULT_TEXT = "the Noodle Incident."  # No one can prove Calvin did it, maybe except Santa

def main(config):
    last_incident = time.parse_time(config.get("last_incident", DEFAULT_DATE_TIME))
    time_zone = config.get("$tz", "US/Eastern")  # Utilize special time_zone variable
    todays_date = time.now().in_location(time_zone)
    duration = todays_date - last_incident
    days_since = math.round(duration.hours / 24)
    if days_since < 0:
        days_since = 0.0

    day_or_days = "days"
    if days_since == 1.0:
        day_or_days = "day"

    num_color = config.get("color", DEFAULT_COLOR)
    message = config.get("text", DEFAULT_TEXT)

    return render.Root(
        render.Box(
            render.Column(
                cross_align = "center",
                main_align = "center",
                children = [
                    render.Text(
                        "%s" % humanize.float("#,###.", days_since),
                        color = num_color,
                        font = "6x13",
                    ),
                    render.Text("%s since" % day_or_days, color = "#ffffff", font = "tb-8"),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(message, color = "#ffffff", font = "tb-8"),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "last_incident",
                name = "Last_incident",
                desc = "Date of the last incident",
                icon = "calendar",
            ),
            schema.Text(
                id = "text",
                name = "Text",
                desc = "Brief description of the incident",
                icon = "font",
                default = "the Noodle Incident.",
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Color of the incident-free duration number",
                icon = "brush",
                default = "#EEFF33",
            ),
        ],
    )
