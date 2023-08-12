"""
Applet: AccidentFreeDays
Summary: Days Since Last Accident
Description: Displays the days since the last accident.
Author: Robert Ison
"""

load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_DATE_TIME = "2020-01-01T00:00:00Z"

def main(config):
    last_accident = time.parse_time(config.get("last_accident", DEFAULT_DATE_TIME))
    time_zone = config.get("$tz", "America/Chicago")  # Utilize special time_zone variable
    todays_date = time.now().in_location(time_zone)
    accident_free_duration = todays_date - last_accident
    accident_free_days = math.round(accident_free_duration.hours / 24)
    if accident_free_days < 0:
        accident_free_days = 0.0

    day_or_days = "DAYS"
    if accident_free_days == 1.0:
        day_or_days = "DAY"

    return render.Root(
        render.Column(
            cross_align = "center",
            children = [
                render.Text(" ACCIDENT FREE", color = "#fff", font = "tb-8"),
                render.Text("FOR %s" % humanize.float("#.", accident_free_days), color = "#f4a306", font = "6x13"),
                render.Text(day_or_days, color = "#fff", font = "tb-8"),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "last_accident",
                name = "Last_accident",
                desc = "Date of the Last Accident",
                icon = "calendar",
            ),
        ],
    )
