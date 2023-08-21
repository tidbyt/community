"""
Applet: Money Made
Summary: Shows your earnings today
Description: Calculates how much you've madee today based on your paycheck.
Author: klar
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_BAR_COLOR = "#B92A0C"
DEFAULT_BAR_TEXT_COLOR = "#FFF"
DEFAULT_PAYCHECK_WITHOUT_BONUS = "1000"
DEFAULT_PAYCHECK_WITH_BONUS = "1000"
DEFAULT_DAYS_TO_CALC = "10"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "BarColor",
                name = "BarColor",
                desc = "Color of the top bar.",
                icon = "brush",
                default = "#B92A0C",
            ),
            schema.Color(
                id = "TextColor",
                name = "TextColor",
                desc = "Color of the top bar text.",
                icon = "brush",
                default = "#000",
            ),
            schema.Text(
                id = "PaycheckWithoutBonus",
                name = "PaycheckWithoutBonus",
                desc = "Paycheck Total Without Bonus.",
                icon = "gear",
                default = "1000",
            ),
            schema.Text(
                id = "PaycheckWithBonus",
                name = "PaycheckWithBonus",
                desc = "Paycheck Total With Bonus.",
                icon = "gear",
                default = "1000",
            ),
            schema.Text(
                id = "DaysToCalculate",
                name = "DaysToCalculate",
                desc = "Number of work days to calculate.",
                icon = "gear",
                default = "10",
            ),
        ],
    )

def main(config):
    timezone = config.get("timezone") or "America/New_York"
    barColor = config.str("BarColor", DEFAULT_BAR_COLOR)
    textColor = config.str("TextColor", DEFAULT_BAR_TEXT_COLOR)
    totalNoBonus = float(config.str("PaycheckWithoutBonus", DEFAULT_PAYCHECK_WITHOUT_BONUS))
    totalWithBonus = float(config.str("PaycheckWithBonus", DEFAULT_PAYCHECK_WITH_BONUS))
    daysToCalc = float(config.str("DaysToCalculate", DEFAULT_DAYS_TO_CALC))

    now = time.now().in_location(timezone)
    start = time.time(year = now.year, month = now.month, day = now.day, hour = 8, minute = 30, location = timezone)

    timeTilEnd = 36000
    timePassed = now - start
    ratio = timePassed.seconds / timeTilEnd
    if ratio > 1:
        ratio = 1

    noBonusMoneySoFarToday = (totalNoBonus / daysToCalc) * ratio
    noBonusMoneySoFarToday = math.round(noBonusMoneySoFarToday * 100) / 100
    withBonusMoneySoFarToday = (totalWithBonus / daysToCalc) * ratio
    withBonusMoneySoFarToday = math.round(withBonusMoneySoFarToday * 100) / 100

    return render.Root(
        delay = 1000,
        child = render.Box(
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(
                                color = barColor,
                                height = 10,
                                child = render.Text(
                                    color = textColor,
                                    font = "Dina_r400-6",
                                    content = now.format("3:04 PM"),
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (2, 2, 2, 0),
                                child = render.Text(
                                    font = "Dina_r400-6",
                                    content = "$ " + str(noBonusMoneySoFarToday),
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (2, 2, 2, 0),
                                child = render.Text(
                                    font = "Dina_r400-6",
                                    content = "$ " + str(withBonusMoneySoFarToday),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
