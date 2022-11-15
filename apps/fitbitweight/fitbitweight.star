"""
Applet: FitbitWeight
Summary: Displays recent weigh-ins
Description: Displays your Fitbit recent weigh-ins.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

#App Settings
CACHE_TTL = 60 * 60 * 24  # updates once daily

#OAuth Information
FITBIT_CLIENT_ID = "238FC5"
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcE74PvLnAK9o2UbKXs4mvqPOtEMJzu/AvYJQzd9Ngjvk/N5Ee2G3YD4+EF5TMJyWSs85/MoOk2VZWddwZh7+Zld7+ySKsF49sF+4tFGEQjOqVOebCiKpL1YpwFcBmC0em2bLFO890zJRjVUHDDLfXXkasbIftnKofwR49Kpga5oAY=")
FITBIT_SECRET = "MjM4RkM1OjEzYzEwMzhjZGQ0MzRmZWJjODYzMThjZDQzMjJiNDg5"  # secret.decrypt("AV6+xWcEqLZ1+KzoRlbZYXgEWLJLeCrHXA6fcqjagRi/gRlH7Wmj8QWepc+JB5HCy40CzovjbZM1zV3VFuVvATRXmtLsalSRWwwwc6Wrh00dfUGD/xK7eZLyA3Oua2rvnzD1QguqODgWr57RguybEGXEfaPc6McM0L10raV3xJS8cGJgGlT3lR67z1EeyybGYMMlAwDnopGKBQ==")
FITBIT_REDIRECT_URI = "https://appauth.tidbyt.com/fitbitweight"  #https://localhost:8080/ or https://appauth.tidbyt.com/fitbitweight
FITBIT_BASE = "https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=238FC5&redirect_uri=https%3A%2F%2Fappauth.tidbyt.com%2FFitbitWeight&scope=profile%20weight&expires_in=604800"
FITBIT_SCOPES = "profile weight activity"
FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"
FITBIT_DATA_URL = "https://api.fitbit.com/1/user/-/body/%s/date/today/max.json"
FITBIT_DATA_KEYS = ("weight", "fat", "bmi")

#Fitbit Data Display
DISPLAY_FONT = "CG-pixel-3x5-mono"
FAT_COLOR = "#b9d9eb"
FITBIT_LOGO = """
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
"""
KILOGRAMS_TO_POUNDS_MULTIPLIER = float(2.2)
WEIGHT_COLOR = "#00B0B9"
WHITE_COLOR = "#FFF"

# buildifier: disable=function-docstring
def main(config):
    #get user settings
    #authorization_code = config.get("code")

    #As part of getting "Auth", this will also run oauth_handler
    #which in turn sets some cached items, so this line
    #is deceptive in that it does mo"re than just get the refresh token
    refresh_token = config.get("auth")  # or "putvalidrefresh_tokenhere"

    period = config.get("period") or "0"
    system = config.get("system") or "imperial"
    secondary_display = config.get("second") or "none"

    weight_json = None
    fat_json = None
    bmi_json = None

    fitbit_json_items = [weight_json, fat_json, bmi_json]

    if not refresh_token:
        weight_json = json.decode(EXAMPLE_DATA)
        fat_json = json.decode(EXAMPLE_DATA_FAT)
        bmi_json = json.decode(EXAMPLE_DATA_BMI)
    else:
        access_token = cache.get(refresh_token)

        if not access_token:
            access_token = get_access_token(refresh_token)

        #Now we have an access token, either from cache or using refresh_token
        #so let's get  data from cache, then if it's not there
        #We'll go reload it with our access_token
        #We need data for weight, bmi and body fat %
        i = 0

        # For weight, fat % and bmi, let's get the data from cache, and if it doesn't exist, get it from fitbit
        for item in FITBIT_DATA_KEYS:
            cache_item_name = "%s_%s" % (refresh_token, item)
            fitbit_json_items[i] = cache.get(cache_item_name)

            if fitbit_json_items[i] == None:
                #nothing in cache, so we'll load it from Fitbit, then cache it
                fitbit_json_items[i] = get_data_from_fitbit(access_token, (FITBIT_DATA_URL % (item)))
                cache.set(cache_item_name, json.encode(fitbit_json_items[i]), ttl_seconds = CACHE_TTL)
            else:
                fitbit_json_items[i] = json.decode(fitbit_json_items[i])

            i = i + 1

        # Ugh, fix to actually put data into what I'm checking
        weight_json = fitbit_json_items[0]
        fat_json = fitbit_json_items[1]
        bmi_json = fitbit_json_items[2]

    #Defalt Values
    current_weight = 0
    first_weight = 0
    current_fat = 0
    current_bmi = 0
    first_weight_date = None

    #Process Data
    if weight_json != None:
        if len(weight_json["body-weight"]) > 0:
            current_weight = float(weight_json["body-weight"][-1]["value"])
            first_weight = float((get_starting_value(weight_json, period, "value")))
            if first_weight < 0:
                first_weight = 0
            first_weight_date = get_starting_value(weight_json, period, "dateTime")

    if (fat_json != None):
        if len(fat_json["body-fat"]) > 0:
            current_fat = float(fat_json["body-fat"][-1]["value"])

    if (bmi_json != None):
        if len(bmi_json["body-bmi"]) > 0:
            current_bmi = float(bmi_json["body-bmi"][-1]["value"])

    #convert to imperial if need be
    if system == "metric":
        display_units = "KGs"
    else:
        display_units = "LBs"
        current_weight = float(current_weight) * KILOGRAMS_TO_POUNDS_MULTIPLIER
        first_weight = float(first_weight) * KILOGRAMS_TO_POUNDS_MULTIPLIER

    weight_change = current_weight - first_weight

    # The - sign is part of the number, but I want a "+" sign if there is a gain
    sign = ""
    if weight_change > 0:
        sign = "+"

    weight_plot = get_plot_from_data(weight_json, period)
    fat_plot = get_plot_from_data(fat_json, period)
    # Unless your height is changing, the weight_plot and bmi_plot is identical, and looks stupid
    # So let's just show the weight with current BMI info added, but not the second plot
    #bmi_plot = get_plot_from_data(bmi_json, period)

    display_weight = "%s%s " % ((humanize.comma(int(current_weight * 100) // 100.0)), display_units)
    if secondary_display == "bodyfat" and current_fat > 0:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = 32,
                    child =
                        render.Text(("%s%% body fat" % (humanize.comma(int(current_fat * 100) // 100.0))), color = FAT_COLOR, font = DISPLAY_FONT),
                ),
            ],
        )
    elif secondary_display == "bmi" and current_bmi > 0:
        display_color = get_bmi_display(current_bmi)

        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = 32,
                    child = render.Text(("BMI: %s %s" % (humanize.comma(int(current_bmi * 100) // 100.0), display_color[0])), color = display_color[1], font = DISPLAY_FONT),
                ),
            ],
        )
    else:
        if first_weight_date == -1:
            first_weight_display = ""
        else:
            first_weight_display = "since %s " % first_weight_date

        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WHITE_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = 32,
                    child = render.Text("%s%s %s %s" % (sign, humanize.comma(int(weight_change * 100) // 100.0), display_units, first_weight_display), color = WEIGHT_COLOR, font = DISPLAY_FONT),
                ),
            ],
        )

    #Build the display in rows
    rows = [numbers_row]

    #1 pixel tall horizontal separator
    rows.append(render.Box(height = 1))
    if secondary_display == "bmi":
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, 26))
    elif secondary_display == "bodyfat":
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR))
        rows.append(get_plot_display_from_plot(fat_plot, FAT_COLOR))
    else:
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, 26))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = rows,
        ),
    )

# buildifier: disable=function-docstring
def get_starting_value(json_data, period, itemName = "value"):
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])

            date_diff = time.now() - current_date
            days = math.floor(date_diff.hours // 24)

            number_of_days = int(period)

            if number_of_days == 0 or days < number_of_days:
                return item[itemName]
    return -1

def get_bmi_display(bmi):
    """ Gets BMI Display

    Args:
        bmi: bmi data
    Returns:
        Bmi status (underweight, overweight etc.)
    """
    if bmi < 19:
        #Underweight
        return ("Underweight", "#01b0f1")
    elif bmi < 25:
        #Healthy
        return ("Healthy", "#5fa910")
    elif bmi < 30:
        #Overweight
        return ("Overweight", "#ff0")
    elif bmi < 40:
        #obese
        return ("Obese", "#e77a22")
    else:
        #Extremely Obese
        return ("Extremely Obese", "#f00")

def get_plot_display_from_plot(plot, color = WHITE_COLOR, height = 13):
    # x_lim and y_lim not required. The render.plot is smart enough to figure out the limits based on the data provided in plot
    return render.Plot(
        data = plot,
        width = 64,
        height = height,
        color = color,
        fill = True,
    )

def get_plot_from_data(json_data, period):
    """ Gets the plot from the json_data for the given period

    Args:
        json_data: from FitBit
        period: to determine what date range to display
    Returns:
        Plot
    """

    #initialize
    oldest_date = None
    newest_date = None
    smallest = None
    largest = None
    starting_value = None
    item_count = 0
    number_of_days = int(period)

    # initialize -- reinitialize if we find we have data to present
    plot = [(0, 0)]

    if json_data != None:
        # loop through data, find the bounds needed to plot the points
        for i in json_data:
            for item in json_data[i]:
                current_date = get_timestamp_from_date(item["dateTime"])
                current_value = float(item["value"])
                date_diff = time.now() - current_date
                days = math.floor(date_diff.hours // 24)

                if number_of_days == 0 or days < number_of_days:
                    item_count = item_count + 1

                    #get starting value
                    if starting_value == None:
                        starting_value = current_value

                    #get the oldest date
                    if oldest_date == None:
                        oldest_date = current_date
                    elif current_date < oldest_date:
                        oldest_date = current_date

                    #get the newest date
                    if newest_date == None:
                        newest_date = current_date
                    elif current_date > newest_date:
                        newest_date = current_date

                    #get smallest
                    if smallest == None:
                        smallest = current_value
                    elif current_value < smallest:
                        smallest = current_value

                    #get largest
                    if largest == None:
                        largest = current_value
                    elif current_value > largest:
                        largest = current_value

            # initialize graph
            plot = [(0, starting_value)]
            for item in json_data[i]:
                item_count = item_count + 1
                current_date = get_timestamp_from_date(item["dateTime"])
                current_value = float(item["value"])
                days = get_days_between(time.now(), current_date)

                if number_of_days == 0 or days < number_of_days:
                    y_val = current_value
                    x_val = get_days_between(current_date, oldest_date)
                    plot.append((x_val, y_val))

    return plot

def get_timestamp_from_date(date_string):
    date_parts = str(date_string).split("-")
    return time.time(year = int(date_parts[0]), month = int(date_parts[1]), day = int(date_parts[2]))

def get_days_between(day1, day2):
    date_diff = day1 - day2
    days = math.floor(date_diff.hours // 24)
    return days

def oauth_handler(params):
    params = json.decode(params)
    authorization_code = params.get("code")
    return get_refresh_token(authorization_code)

# buildifier: disable=function-docstring
def get_data_from_fitbit(access_token, data_url):
    res = http.get(
        url = data_url,
        headers = {
            "Authorization": "Bearer %s" % access_token,
        },
    )

    if res.status_code == 200:
        return res.json()
    else:
        return None

# buildifier: disable=function-docstring
def get_refresh_token(authorization_code):
    form_body = dict(
        clientId = FITBIT_CLIENT_ID,
        grant_type = "authorization_code",
        redirect_uri = FITBIT_REDIRECT_URI,
        code = authorization_code,
    )

    headers = dict(
        Authorization = "Basic %s" % FITBIT_SECRET,
        ContentType = "application/x-www-form-urlencoded",
    )

    res = http.post(
        url = FITBIT_TOKEN_URL,
        headers = headers,
        form_body = form_body,
    )

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]
    user_id = token_params["user_id"]
    expires_in = token_params["expires_in"]

    cache.set(refresh_token, access_token, ttl_seconds = int(expires_in - 30))
    cache.set(get_cache_user_identifier(refresh_token), str(user_id), ttl_seconds = CACHE_TTL)

    return refresh_token

def get_cache_user_identifier(refresh_token):
    return "%s/user_id" % refresh_token

def get_access_token(refresh_token):
    """ Gets the access token

    Args:
        refresh_token: refersh token that was saved off earlier

    Returns:
        access token
    """

    headers = dict(
        Authorization = "Basic %s" % FITBIT_SECRET,
        ContentType = "application/x-www-form-urlencoded",
    )

    form_body = dict(
        grant_type = "refresh_token",
        refresh_token = refresh_token,
    )

    res = http.post(
        url = FITBIT_TOKEN_URL,
        headers = headers,
        form_body = form_body,
    )

    if res.status_code != 200:
        #print("Error Calling Fitbit Token: %s" % (res.body()))
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))

    return access_token

def get_schema():
    period_options = [
        schema.Option(value = "7", display = "7 Days"),
        schema.Option(value = "30", display = "30 Days"),
        schema.Option(value = "60", display = "2 Months"),
        schema.Option(value = "90", display = "3 Months"),
        schema.Option(value = "180", display = "6 Months"),
        schema.Option(value = "360", display = "1 Year"),
        schema.Option(value = "720", display = "2 Years"),
        schema.Option(value = "1825", display = "5 Years"),
        schema.Option(value = "0", display = "Maximum Allowed"),
    ]

    measurement_options = [
        schema.Option(value = "metric", display = "Metric"),
        schema.Option(value = "imperial", display = "Imperial"),
    ]

    secondary_options = [
        schema.Option(value = "none", display = "None - just display weight"),
        schema.Option(value = "bodyfat", display = "Body Fat Percentage"),
        schema.Option(value = "bmi", display = "BMI"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                icon = "user",
                name = "Fitbit",
                desc = "Connect to your Fitbit account.",
                handler = oauth_handler,
                client_id = str(FITBIT_CLIENT_ID),
                authorization_endpoint = "https://www.fitbit.com/oauth2/authorize",
                scopes = [
                    FITBIT_SCOPES,
                ],
            ),
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "The length of time to chart.",
                icon = "stopwatch",  #"calendarCheck",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "system",
                name = "Measurement",
                desc = "Choose Imperial or Metric",
                icon = "ruler",
                options = measurement_options,
                default = "metric",
            ),
            schema.Dropdown(
                id = "second",
                name = "Secondary Measurement",
                desc = "Choose the secondary item to plot",
                icon = "squarePollVertical",
                options = secondary_options,
                default = "none",
            ),
        ],
    )

EXAMPLE_DATA_FAT = """
{
    "body-fat": [{
        "dateTime": "2022-09-02",
        "value": "32.423999786376953"
    }, {
        "dateTime": "2022-09-04",
        "value": "31.444000244140625"
    }, {
        "dateTime": "2022-09-06",
        "value": "30.30500030517578"
    }, {
        "dateTime": "2022-09-08",
        "value": "27.204999923706055"
    }]
}
"""
EXAMPLE_DATA_BMI = """
{
    "body-bmi": [{
        "dateTime": "2022-09-02",
        "value": "40.607765197753906"
    }, {
        "dateTime": "2022-09-04",
        "value": "30.561622619628906"
    }, {
        "dateTime": "2022-09-06",
        "value": "20.626222610473633"
    }, {
        "dateTime": "2022-09-08",
        "value": "20.592384338378906"
    }]
}
"""
EXAMPLE_DATA = """
{
    "body-weight": [{
        "dateTime": "2022-09-02",
        "value": "150"
    }, {
        "dateTime": "2022-09-04",
        "value": "110"
    }, {
        "dateTime": "2022-09-06",
        "value": "100"
    }, {
        "dateTime": "2022-09-08",
        "value": "90"
    }]
}
"""
