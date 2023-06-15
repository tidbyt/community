"""
Applet: Income Counter
Summary: Realtime income counter
Description: Realtime income counter for salaried workers.
Author: Thomas R. Novak
"""

load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_SALARY = "100000"
DEFAULT_BONUS = "15000"
DEFAULT_CURRENCY = "$"
DEFAULT_LOCATION = json.encode({
    "lat": "37.7749295",
    "lng": "-122.4194155",
    "description": "San Francisco, CA, USA",
    "locality": "San Francisco",
    "place_id": "ChIJIQBpAG2ahYAR_6128GcTUEo",
    "timezone": "America/Los_Angeles",
})

RUNTIME_MILLISECONDS = 15000
REFRESH_MILLISECONDS = 40

COLOR_OF_MONEY = "#22b14c"

DAYS_PER_WEEK = 7
WEEKDAYS_PER_WEEK = 5
HOURS_PER_DAY = 24
WORKHOURS_PER_DAY = 8
MINUTES_PER_HOUR = 60
SECONDS_PER_MINUTE = 60
MILLISECONDS_PER_SECOND = 1000
NANOSECONDS_PER_SECOND = 1000000000
NANOSECONDS_PER_MILLISECOND = 1000000

COUNTER_START_HOUR = 8
COUNTER_PAUSE_HOUR = 12
COUNTER_RESUME_HOUR = 13
COUNTER_STOP_HOUR = 17

STATIC = 0
STATIC_TO_INCR = 1
INCR_TO_STATIC = 2
INCR = 3

def main(config):
    salary = config.str("salary", DEFAULT_SALARY)
    bonus = config.str("bonus", DEFAULT_BONUS)
    currency = config.str("currency", DEFAULT_CURRENCY)
    location_cfg = config.str("location", DEFAULT_LOCATION)

    location = json.decode(location_cfg)
    timezone = location["timezone"]
    now = time.now().in_location(timezone)
    jan_first = time.time(
        year = now.year,
        month = 1,
        day = 1,
        location = timezone,
    )

    weekdays_per_year = calc_weekdays(jan_first)
    millisecond_salary = (float(salary) / weekdays_per_year /
                          WORKHOURS_PER_DAY / MINUTES_PER_HOUR /
                          SECONDS_PER_MINUTE / MILLISECONDS_PER_SECOND)
    start_state = calc_start_state(
        jan_first,
        now,
        timezone,
        weekdays_per_year,
        salary,
        bonus,
        millisecond_salary,
    )

    frames = []
    for frame_num in range(int(RUNTIME_MILLISECONDS / REFRESH_MILLISECONDS)):
        frame_income = calc_frame_income(
            start_state,
            frame_num,
            millisecond_salary,
        )
        frames.append(render_frame(now.year, currency, frame_income))

    return render.Root(
        delay = REFRESH_MILLISECONDS,
        child = render.Animation(
            children = frames,
        ),
    )

def calc_weekdays(jan_first):
    weekdays = 0

    if is_leap_year(jan_first):
        if (humanize.day_of_week(jan_first) == 0 or
            humanize.day_of_week(jan_first) == 5):  # Sunday or Friday
            weekdays = 261
        elif (humanize.day_of_week(jan_first) == 6):  # Saturday
            weekdays = 260
        else:
            weekdays = 262
    elif (humanize.day_of_week(jan_first) == 0 or
          humanize.day_of_week(jan_first) == 6):  # Saturday or Sunday
        weekdays = 260
    else:
        weekdays = 261

    return weekdays

def is_leap_year(now):
    return (math.mod(now.year, 400) == 0 or
            (math.mod(now.year, 4) == 0 and
             math.mod(now.year, 100) != 0))

def calc_start_state(
        start,
        now,
        timezone,
        weekdays_per_year,
        salary,
        bonus,
        millisecond_salary):
    # initialize default state
    start_state = {}
    start_state["starting_income"] = 0
    start_state["display_type"] = STATIC
    start_state["transition_frame"] = 0

    # calendar days since Jan 1
    calendar_days = calc_calendar_days(now)

    # calculate full weeks passed
    weeks = math.floor(calendar_days / DAYS_PER_WEEK)
    workdays = weeks * WEEKDAYS_PER_WEEK

    # calculate partial week
    workdays += calc_partial_week(start, now)

    # prior income based on days passed
    prior_income = float(bonus) + (float(salary) / weekdays_per_year) * workdays

    # calculate todays salary and animation type
    milliseconds = 0
    runtime = time.parse_duration(str(RUNTIME_MILLISECONDS) + "ms")
    end = now + runtime
    if (is_the_weekend(now)):
        start_state["display_type"] = STATIC
    elif (is_before_work_hours(now, end)):
        start_state["display_type"] = STATIC
    elif (is_starting_work_hours(now, end)):
        start_state["display_type"] = STATIC_TO_INCR
        start_state["transition_frame"] = calc_transition_frame(now, timezone)
    elif (is_morning_work_hours(now, end)):
        start_state["display_type"] = INCR
        milliseconds = calc_milliseconds(
            now.hour - COUNTER_START_HOUR,
            now.minute,
            now.second,
            now.nanosecond,
        )
    elif (is_starting_lunch_hour(now, end)):
        start_state["display_type"] = INCR_TO_STATIC
        milliseconds = calc_milliseconds(
            now.hour - COUNTER_START_HOUR,
            now.minute,
            now.second,
            now.nanosecond,
        )
        start_state["transition_frame"] = calc_transition_frame(now, timezone)
    elif (is_lunch_hour(now, end)):
        start_state["display_type"] = STATIC
        milliseconds = calc_milliseconds(
            COUNTER_PAUSE_HOUR - COUNTER_START_HOUR,
            0,
            0,
            0,
        )
    elif (is_restarting_work_hours(now, end)):
        start_state["display_type"] = STATIC_TO_INCR
        milliseconds = calc_milliseconds(
            COUNTER_PAUSE_HOUR - COUNTER_START_HOUR,
            0,
            0,
            0,
        )
        start_state["transition_frame"] = calc_transition_frame(now, timezone)
    elif (is_afternoon_work_hours(now, end)):
        start_state["display_type"] = INCR
        milliseconds = calc_milliseconds(
            COUNTER_PAUSE_HOUR - COUNTER_START_HOUR,
            0,
            0,
            0,
        )
        milliseconds += calc_milliseconds(
            now.hour - COUNTER_RESUME_HOUR,
            now.minute,
            now.second,
            now.nanosecond,
        )
    elif (is_finishing_work_hours(now, end)):
        start_state["display_type"] = INCR_TO_STATIC
        milliseconds = calc_milliseconds(
            COUNTER_PAUSE_HOUR - COUNTER_START_HOUR,
            0,
            0,
            0,
        )
        milliseconds += calc_milliseconds(
            now.hour - COUNTER_RESUME_HOUR,
            now.minute,
            now.second,
            now.nanosecond,
        )
        start_state["transition_frame"] = calc_transition_frame(now, timezone)
    else:  # after work hours
        start_state["display_type"] = STATIC
        milliseconds = calc_milliseconds(WORKHOURS_PER_DAY, 0, 0, 0)

    todays_income = milliseconds * millisecond_salary
    start_state["starting_income"] = prior_income + todays_income

    return start_state

def calc_calendar_days(now):
    # considered doing this using Time objects and Duration from Jan 1, but
    # the largest Duration granularity is hours, and daylight savings time
    # would unnecessarily mess with hours --> days calculations
    common_calendar = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    leap_calendar = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    if is_leap_year(now):
        calendar = leap_calendar
    else:
        calendar = common_calendar

    days = 0
    for month in range(now.month - 1):
        days += calendar[month]
    days += now.day - 1

    return days

def calc_partial_week(start, now):
    partial_week_table = {
        0: [0, 0, 1, 2, 3, 4, 5],
        1: [5, 0, 1, 2, 3, 4, 5],
        2: [4, 4, 0, 1, 2, 3, 4],
        3: [3, 3, 4, 0, 1, 2, 3],
        4: [2, 2, 3, 4, 0, 1, 2],
        5: [1, 1, 2, 3, 4, 0, 1],
        6: [0, 0, 1, 2, 3, 4, 0],
    }

    return partial_week_table[humanize.day_of_week(start)][humanize.day_of_week(now)]

def is_the_weekend(now):
    return (humanize.day_of_week(now) == 0 or
            humanize.day_of_week(now) == 6)

def is_before_work_hours(now, end):
    return (now.hour < COUNTER_START_HOUR and
            end.hour < COUNTER_START_HOUR)

def is_starting_work_hours(now, end):
    return (now.hour < COUNTER_START_HOUR and
            end.hour >= COUNTER_START_HOUR)

def is_morning_work_hours(now, end):
    return (now.hour >= COUNTER_START_HOUR and
            now.hour < COUNTER_PAUSE_HOUR and
            end.hour < COUNTER_PAUSE_HOUR)

def is_starting_lunch_hour(now, end):
    return (now.hour >= COUNTER_START_HOUR and
            now.hour < COUNTER_PAUSE_HOUR and
            end.hour >= COUNTER_PAUSE_HOUR)

def is_lunch_hour(now, end):
    return (now.hour >= COUNTER_PAUSE_HOUR and
            now.hour < COUNTER_RESUME_HOUR and
            end.hour < COUNTER_RESUME_HOUR)

def is_restarting_work_hours(now, end):
    return (now.hour >= COUNTER_PAUSE_HOUR and
            now.hour < COUNTER_RESUME_HOUR and
            end.hour >= COUNTER_RESUME_HOUR)

def is_afternoon_work_hours(now, end):
    return (now.hour >= COUNTER_RESUME_HOUR and
            now.hour < COUNTER_STOP_HOUR and
            end.hour < COUNTER_STOP_HOUR)

def is_finishing_work_hours(now, end):
    return (now.hour >= COUNTER_RESUME_HOUR and
            now.hour < COUNTER_STOP_HOUR and
            end.hour >= COUNTER_STOP_HOUR)

def calc_transition_frame(now, timezone):
    # assumes runtime is less than one minute, transition is on an hour
    # boundary, and transition hour does not cross day boundary
    transition_time = time.time(
        year = now.year,
        month = now.month,
        day = now.day,
        hour = now.hour + 1,
        minute = 0,
        second = 0,
        nanosecond = 0,
        location = timezone,
    )
    time_till_transition = transition_time - now

    transition_frame = math.ceil(time_till_transition.nanoseconds /
                                 NANOSECONDS_PER_MILLISECOND /
                                 REFRESH_MILLISECONDS)

    return transition_frame

def calc_milliseconds(hour, minute, second, nanosecond):
    return ((hour * MINUTES_PER_HOUR * SECONDS_PER_MINUTE * MILLISECONDS_PER_SECOND) +
            (minute * SECONDS_PER_MINUTE * MILLISECONDS_PER_SECOND) +
            (second * MILLISECONDS_PER_SECOND) +
            (math.floor(nanosecond / NANOSECONDS_PER_MILLISECOND)))

def calc_frame_income(start_state, frame_num, millisecond_salary):
    incrementing = False
    start_frame = 1  #first frame that should show an incremented salary
    stop_frame = 0  #first frame that should be static

    if (start_state["display_type"] == INCR):
        incrementing = True
    elif (start_state["display_type"] == INCR_TO_STATIC):
        if (frame_num < start_state["transition_frame"]):
            incrementing = True
        else:
            stop_frame = start_state["transition_frame"]
    elif (start_state["display_type"] == STATIC_TO_INCR and
          frame_num >= start_state["transition_frame"]):
        incrementing = True
        start_frame = start_state["transition_frame"]

    if (incrementing):
        frame_income = start_state["starting_income"] + ((frame_num - start_frame + 1) *
                                                         REFRESH_MILLISECONDS *
                                                         millisecond_salary)
    else:
        frame_income = start_state["starting_income"] + (stop_frame *
                                                         REFRESH_MILLISECONDS *
                                                         millisecond_salary)

    return frame_income

def render_frame(year, currency, frame_income):
    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.WrappedText(
                        content = "Earned Income (%d)" % year,
                        font = "tom-thumb",
                        align = "center",
                    ),
                ],
            ),
            render.Box(
                width = 64,
                height = 1,
                color = COLOR_OF_MONEY,
            ),
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "%s" % currency,
                        font = "6x13",
                        color = COLOR_OF_MONEY,
                    ),
                    render.Text(
                        content = "%s" % humanize.float(
                            "#,###.##",
                            float(frame_income),
                        ),
                    ),
                ],
            ),
        ],
    )

def get_schema():
    options = [
        schema.Option(
            display = "US Dollar",
            value = "$",
        ),
        schema.Option(
            display = "Euro",
            value = "€",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "currency",
                name = "Currency",
                desc = "Your preferred currency.",
                icon = "coins",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "salary",
                name = "Annual Salary",
                desc = "Your annual salary.",
                icon = "circleDollarToSlot",
                default = DEFAULT_SALARY,
            ),
            schema.Text(
                id = "bonus",
                name = "Bonuses Year To Date",
                desc = "Total of one-time bonuses year to date.",
                icon = "moneyCheckDollar",
                default = DEFAULT_BONUS,
            ),
        ],
    )
