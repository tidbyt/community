"""
Applet: FitbitWeight
Summary: Displays recent weigh-ins
Description: Displays your Fitbit recent weigh-ins.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
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
FITBIT_REDIRECT_URI = "https://appauth.tidbyt.com/fitbitweight"  #"https://localhost:8080/"
FITBIT_BASE = "https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=238FC5&redirect_uri=https%3A%2F%2Fappauth.tidbyt.com%2FFitbitWeight&scope=profile%20weight&expires_in=604800"
FITBIT_SCOPES = "profile weight activity"
FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"
FITBIT_DATA_URL = "https://api.fitbit.com/1/user/-/body/%s/date/today/max.json"
FITBIT_DATA_KEYS = ("weight", "fat", "bmi")

#Fitbit Data Display
DISPLAY_FONT = "CG-pixel-3x5-mono"
FAT_COLOR = "#b9d9eb"
FITBIT_LOGO = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAJBlWElmTU0AKgAAAAgABgEGAAMAAAABAAIAAAESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAIdpAAQAAAABAAAAZgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAABCgAwAEAAAAAQAAABAAAAAAjw+h1QAAAAlwSFlzAAALEwAACxMBAJqcGAAAAm1pVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpQaG90b21ldHJpY0ludGVycHJldGF0aW9uPjI8L3RpZmY6UGhvdG9tZXRyaWNJbnRlcnByZXRhdGlvbj4KICAgICAgICAgPHRpZmY6WFJlc29sdXRpb24+NzI8L3RpZmY6WFJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOllSZXNvbHV0aW9uPjcyPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8dGlmZjpDb21wcmVzc2lvbj4xPC90aWZmOkNvbXByZXNzaW9uPgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KsVruIwAAArRJREFUOBGFU01IVFEUvufeN786VGqbHFvVjIMRoakwQVqmhlQzFVpU7qxNQbkMWrgMWuTCCiUipI1j5OiUzIxJY1QYjm1MbBEU+MKFllHTvJnxvXs79w2Ff9HZvHd+7jnfd34IWS+hEJMmz1C8oTwcNbzDsdtmiBB0fajU1xq7uqibEKt0MAZ7HR4fBUIOSr2qr4+1yuRCoGkz2cThC0ePeCIvSjaEr4pVTCdWJgB899Mxn6KLw3OBxnt7Rsa368JoAZ41KkKzr3WrOoCl06mcq0MF0EwkAHle9XV1JhVmiB5n5f4e30i8weD8UmF1bScQuMvtCx02d1nQusN9rsCWOi2LugcH7aRLUIkAEouLwkQiRPevd1MLFsWZNEhmKTX1NkCAPsxxI8LV+YuIQFMYfSlj1bY2TX43NGTX6KjtY0tLVjo9kfGadLFjRvX7NUTVTrjIzQWbB7wjYwHgImAocAvKw7FJTPPjQ6C5yRuO91u2bW3Xl5cPYOZ9ltKyO7kvahwoeURdW/q5liY8p98Awq8rxSUF+telT8gdXESQwjwc4aQ2ByGCWgmlVlCQIQg7Nt0OjCEbimbuwIYzwg2Jv3ADhYrom6LZo/5vMqEcoyZsyc8nD333heOX0ZSdCzbdx+U6j809xYHezCeQc8WRlD+JHcPcZ6hNXCUa3cmB9GJ3H+iG/kxR2DAizSCms++DzfOygBQ5PqhPJMz1JQw6nZXVF3gWqjghxwuqa2uQwjWLhZ2wlpZV4hj9hoB6+dAdCjlwF8wxisTEBMYTYjC4kp5O4iI1jVcMjs78TE4WIc8Iy7hfZdX5RoSbTq24HstYtbU1I1HL/7ysWs8/JnlQ/1tlcwPNBzKbPCYJDcUXjnU6vZ7n1FiJSr2qt9fy95jWVJbe1bLmnGOGbyjabbr/cc6/AQthFXUlFgcaAAAAAElFTkSuQmCC
"""
KILOGRAMS_TO_POUNDS_MULTIPLIER = float(2.2)
WEIGHT_COLOR = "#00B0B9"
WHITE_COLOR = "#FFF"

def main(config):
    #get user settings
    #authorization_code = config.get("code")

    #As part of getting "Auth", this will also run oauth_handler
    #which in turn sets some cached items, so this line
    #is deceptive in that it does more than just get the refresh token
    refresh_token = config.get("auth")
    print("Refresh Token: %s" % (refresh_token))
    period = config.get("period") or "30"
    system = config.get("system") or "imperial"
    secondary_display = config.get("second") or "none"

    #default to demo data
    weight_json = None
    fat_json = None
    bmi_json = None
    fitbit_json_items = (weight_json, fat_json, bmi_json)

    if not refresh_token:
        print("Use Default Data")
        weight_json = json.decode(EXAMPLE_DATA)
        fat_json = json.decode(EXAMPLE_DATA_FAT)
        bmi_json = json.decode(EXAMPLE_DATA_BMI)
    else:
        access_token = cache.get(refresh_token)
        if not access_token:
            print("Generating new access token")
            access_token = get_access_token(refresh_token)

        #Get logged in user
        user_id = cache.get(get_cache_user_identifier(refresh_token))

        #Now we have an access token, either from cache or using refresh_token
        #so let's get  data from cache, then if it's not there
        #We'll go reload it with our access_token
        i = 0
        for item in FITBIT_DATA_KEYS:
            print(item)
            i = i + 1
            cache_item_name = "%s_%s" % refresh_token, item
            fitbit_json_items[i] = cache.get(cache_item_name)
            if fitbit_json_items[i] == None:
                #nothing in cache, so we'll load it from Fitbit, then cache it
                fitbit_json_items[i] = get_data_from_fitbit(access_token, (FITBIT_DATA_URL % (item)))
                cache.set(cache_item_name, json.encode(fitbit_json_items[i]), ttl_seconds = CACHE_TTL)

    #Defalt Values
    current_weight = 0
    first_weight = 0
    current_fat = 0
    current_bmi = 0
    first_weight_date = None

    #Process Data
    if len(weight_json["body-weight"]) > 0:
        current_weight = float(weight_json["body-weight"][-1]["value"])
        first_weight = float(get_starting_value(weight_json, period, "value"))
        first_weight_date = get_starting_value(weight_json, period, "dateTime")
    if len(fat_json["body-fat"]) > 0:
        current_fat = float(fat_json["body-fat"][-1]["value"])
    if len(bmi_json["body-bmi"]) > 0:
        current_bmi = float(bmi_json["body-bmi"][-1]["value"])

    #convert to imperial if need be
    if system == "metric":
        displayUnits = "KGs"
    else:
        displayUnits = "LBs"
        current_weight = current_weight * KILOGRAMS_TO_POUNDS_MULTIPLIER
        first_weight = first_weight * KILOGRAMS_TO_POUNDS_MULTIPLIER

    weight_change = current_weight - first_weight

    # The - sign is part of the number, but I want a "+" sign if there is a gain
    sign = ""
    if weight_change > 0:
        sign = "+"

    weight_plot = get_plot_from_data(weight_json, period)
    fat_plot = get_plot_from_data(fat_json, period)
    bmi_plot = get_plot_from_data(bmi_json, period)

    display_weight = "%s%s " % ((humanize.comma(int(current_weight * 100) / 100.0)), displayUnits)
    if secondary_display == "bodyfat" and current_fat > 0:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = 32,
                    child =
                        render.Text(("%s%% body fat" % (humanize.comma(int(current_fat * 100) / 100.0))), color = FAT_COLOR, font = DISPLAY_FONT),
                ),
            ],
        )
    elif secondary_display == "bmi" and current_bmi > 0:
        display_color = get_bmi_display(current_bmi)
        print(display_color[0])
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = 32,
                    child = render.Text(("BMI: %s %s" % (humanize.comma(int(current_bmi * 100) / 100.0), display_color[0])), color = display_color[1], font = DISPLAY_FONT),
                ),
            ],
        )
    else:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WHITE_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = 32,
                    child = render.Text("%s%s %s since %s" % (sign, humanize.comma(int(weight_change * 100) / 100.0), displayUnits, first_weight_date), color = WEIGHT_COLOR, font = DISPLAY_FONT),
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

def get_starting_value(json_data, period, itemName = "value"):
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])

            date_diff = time.now() - current_date
            days = math.floor(date_diff.hours / 24)

            number_of_days = int(period)

            if number_of_days == 0 or days < number_of_days:
                return item[itemName]

def get_bmi_display(bmi):
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
    return render.Plot(
        data = plot,
        width = 64,
        height = height,
        color = color,
        ylim = (0.0, 1.0),
        xlim = (0.0, 1.0),
        fill = True,
    )

def get_plot_from_data(json_data, period):
    #Loop through data and get max and mins
    oldest_date = None
    newest_date = None
    smallest = None
    largest = None
    starting_value = None
    item_count = 0
    for i in json_data:
        for item in json_data[i]:
            item_count = item_count + 1
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])

            date_diff = time.now() - current_date
            days = math.floor(date_diff.hours / 24)

            number_of_days = int(period)

            if number_of_days == 0 or days < number_of_days:
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

    #can't do much with no data
    if item_count == 0:
        plot = [(0.0, 0.0)]
        return plot

    date_range = newest_date - oldest_date
    value_range = largest - smallest

    #If they happened to have stayed the exact same weight/fat%/bmi, it's a straight
    #line and we need to avoid a div by zero error as well.
    if value_range == 0:
        value_range = 1

    #now plot the data:
    plot = [(0.0, float((starting_value - smallest) / (value_range)))]
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])
            x_val = (current_date - oldest_date).hours / (newest_date - oldest_date).hours
            y_val = (current_value - smallest) / (value_range)
            plot.append((float(x_val), plot[-1][1]))
            plot.append((float(x_val), float(y_val)))

    return plot

def get_timestamp_from_date(date_string):
    date_parts = str(date_string).split("-")
    return time.time(year = int(date_parts[0]), month = int(date_parts[1]), day = int(date_parts[2]))

def oauth_handler(params):
    params = json.decode(params)
    authorization_code = params.get("code")
    return get_refresh_token(authorization_code)

def get_data_from_fitbit(access_token, data_url):
    res = http.get(
        url = data_url,
        headers = {
            "Authorization": "Bearer %s" % access_token,
        },
    )

    if res.status_code == 200:
        print("Received Data from Fitbit!")
        return res.json()
    else:
        print("token request failed with status code: %d - %s" % (res.status_code, res.body()))
        return None

def get_refresh_token(authorization_code):
    print("get_refresh_token")
    print("Authorization Code: %s" % authorization_code)
    print("Fitbit SECRET: %s" % FITBIT_SECRET)
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

    if res.status_code == 200:
        print("Success")
    else:
        print("Error Calling Fitbit Token: %s" % (res.body()))
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))
        return None

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

    if res.status_code == 200:
        print("Success")
    else:
        print("Error Calling Fitbit Token: %s" % (res.body()))
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))
        return None

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
                icon = "userClock",
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
                icon = "poll",
                options = secondary_options,
                default = "none",
            ),
        ],
    )

EXAMPLE_DATA_FAT = """
{
    "body-fat": [{
        "dateTime": "2021-10-12",
        "value": "28.566001892089844"
    }, {
        "dateTime": "2021-10-13",
        "value": "32.53900146484375"
    }, {
        "dateTime": "2021-10-14",
        "value": "32.512001037597656"
    }, {
        "dateTime": "2021-10-15",
        "value": "32.48500061035156"
    }, {
        "dateTime": "2021-10-16",
        "value": "32.45800018310547"
    }, {
        "dateTime": "2021-10-17",
        "value": "32.430999755859375"
    }, {
        "dateTime": "2021-10-18",
        "value": "32.40399932861328"
    }, {
        "dateTime": "2021-10-19",
        "value": "32.37699890136719"
    }, {
        "dateTime": "2021-10-20",
        "value": "32.349998474121094"
    }, {
        "dateTime": "2021-10-21",
        "value": "32.323001861572266"
    }, {
        "dateTime": "2021-10-22",
        "value": "32.29600143432617"
    }, {
        "dateTime": "2021-10-23",
        "value": "32.26900100708008"
    }, {
        "dateTime": "2021-10-24",
        "value": "32.242000579833984"
    }, {
        "dateTime": "2021-10-25",
        "value": "32.198001861572266"
    }, {
        "dateTime": "2021-10-26",
        "value": "32.145999908447266"
    }, {
        "dateTime": "2021-10-27",
        "value": "32.09400177001953"
    }, {
        "dateTime": "2021-10-28",
        "value": "32.04199981689453"
    }, {
        "dateTime": "2021-10-29",
        "value": "31.989999771118164"
    }, {
        "dateTime": "2021-10-30",
        "value": "31.937999725341797"
    }, {
        "dateTime": "2021-10-31",
        "value": "31.88599967956543"
    }, {
        "dateTime": "2021-11-01",
        "value": "31.829999923706055"
    }, {
        "dateTime": "2021-11-02",
        "value": "31.702999114990234"
    }, {
        "dateTime": "2021-11-03",
        "value": "31.576000213623047"
    }, {
        "dateTime": "2021-11-04",
        "value": "31.448999404907227"
    }, {
        "dateTime": "2021-11-05",
        "value": "31.32200050354004"
    }, {
        "dateTime": "2021-11-06",
        "value": "31.194000244140625"
    }, {
        "dateTime": "2021-11-07",
        "value": "31.277999877929688"
    }, {
        "dateTime": "2021-11-08",
        "value": "31.36199951171875"
    }, {
        "dateTime": "2021-11-09",
        "value": "31.445999145507812"
    }, {
        "dateTime": "2021-11-10",
        "value": "31.530000686645508"
    }, {
        "dateTime": "2021-11-11",
        "value": "31.618000030517578"
    }, {
        "dateTime": "2021-11-12",
        "value": "31.615999221801758"
    }, {
        "dateTime": "2021-11-13",
        "value": "31.61400032043457"
    }, {
        "dateTime": "2021-11-14",
        "value": "31.61199951171875"
    }, {
        "dateTime": "2021-11-15",
        "value": "31.610000610351562"
    }, {
        "dateTime": "2021-11-16",
        "value": "31.607999801635742"
    }, {
        "dateTime": "2021-11-17",
        "value": "31.606000900268555"
    }, {
        "dateTime": "2021-11-18",
        "value": "31.604000091552734"
    }, {
        "dateTime": "2021-11-19",
        "value": "31.601999282836914"
    }, {
        "dateTime": "2021-11-20",
        "value": "31.600000381469727"
    }, {
        "dateTime": "2021-11-21",
        "value": "31.597999572753906"
    }, {
        "dateTime": "2021-11-22",
        "value": "31.59600067138672"
    }, {
        "dateTime": "2021-11-23",
        "value": "31.5939998626709"
    }, {
        "dateTime": "2021-11-24",
        "value": "31.591999053955078"
    }, {
        "dateTime": "2021-11-25",
        "value": "31.59000015258789"
    }, {
        "dateTime": "2021-11-26",
        "value": "31.58799934387207"
    }, {
        "dateTime": "2021-11-27",
        "value": "31.586000442504883"
    }, {
        "dateTime": "2021-11-28",
        "value": "31.583999633789062"
    }, {
        "dateTime": "2021-11-29",
        "value": "31.582000732421875"
    }, {
        "dateTime": "2021-11-30",
        "value": "31.579999923706055"
    }, {
        "dateTime": "2021-12-01",
        "value": "31.577999114990234"
    }, {
        "dateTime": "2021-12-02",
        "value": "31.576000213623047"
    }, {
        "dateTime": "2021-12-03",
        "value": "31.573999404907227"
    }, {
        "dateTime": "2021-12-04",
        "value": "31.57200050354004"
    }, {
        "dateTime": "2021-12-05",
        "value": "31.56999969482422"
    }, {
        "dateTime": "2021-12-06",
        "value": "31.56800079345703"
    }, {
        "dateTime": "2021-12-07",
        "value": "31.56599998474121"
    }, {
        "dateTime": "2021-12-08",
        "value": "31.56399917602539"
    }, {
        "dateTime": "2021-12-09",
        "value": "31.562000274658203"
    }, {
        "dateTime": "2021-12-10",
        "value": "31.559999465942383"
    }, {
        "dateTime": "2021-12-11",
        "value": "31.558000564575195"
    }, {
        "dateTime": "2021-12-12",
        "value": "31.555999755859375"
    }, {
        "dateTime": "2021-12-13",
        "value": "31.554000854492188"
    }, {
        "dateTime": "2021-12-14",
        "value": "31.552000045776367"
    }, {
        "dateTime": "2021-12-15",
        "value": "31.549999237060547"
    }, {
        "dateTime": "2021-12-16",
        "value": "31.54800033569336"
    }, {
        "dateTime": "2021-12-17",
        "value": "31.54599952697754"
    }, {
        "dateTime": "2021-12-18",
        "value": "31.54400062561035"
    }, {
        "dateTime": "2021-12-19",
        "value": "31.54199981689453"
    }, {
        "dateTime": "2021-12-20",
        "value": "31.540000915527344"
    }, {
        "dateTime": "2021-12-21",
        "value": "31.510000228881836"
    }, {
        "dateTime": "2021-12-22",
        "value": "31.525999069213867"
    }, {
        "dateTime": "2021-12-23",
        "value": "31.54199981689453"
    }, {
        "dateTime": "2021-12-24",
        "value": "31.558000564575195"
    }, {
        "dateTime": "2021-12-25",
        "value": "31.573999404907227"
    }, {
        "dateTime": "2021-12-26",
        "value": "31.59000015258789"
    }, {
        "dateTime": "2021-12-27",
        "value": "31.606000900268555"
    }, {
        "dateTime": "2021-12-28",
        "value": "31.621999740600586"
    }, {
        "dateTime": "2021-12-29",
        "value": "31.63800048828125"
    }, {
        "dateTime": "2021-12-30",
        "value": "31.65399932861328"
    }, {
        "dateTime": "2021-12-31",
        "value": "31.670000076293945"
    }, {
        "dateTime": "2022-01-01",
        "value": "31.68600082397461"
    }, {
        "dateTime": "2022-01-02",
        "value": "31.70199966430664"
    }, {
        "dateTime": "2022-01-03",
        "value": "31.718000411987305"
    }, {
        "dateTime": "2022-01-04",
        "value": "31.733999252319336"
    }, {
        "dateTime": "2022-01-05",
        "value": "31.75"
    }, {
        "dateTime": "2022-01-06",
        "value": "31.766000747680664"
    }, {
        "dateTime": "2022-01-07",
        "value": "31.781999588012695"
    }, {
        "dateTime": "2022-01-08",
        "value": "31.79800033569336"
    }, {
        "dateTime": "2022-01-09",
        "value": "31.81399917602539"
    }, {
        "dateTime": "2022-01-10",
        "value": "31.83300018310547"
    }, {
        "dateTime": "2022-01-11",
        "value": "31.868999481201172"
    }, {
        "dateTime": "2022-01-12",
        "value": "31.905000686645508"
    }, {
        "dateTime": "2022-01-13",
        "value": "31.94099998474121"
    }, {
        "dateTime": "2022-01-14",
        "value": "31.976999282836914"
    }, {
        "dateTime": "2022-01-15",
        "value": "32.01300048828125"
    }, {
        "dateTime": "2022-01-16",
        "value": "32.04899978637695"
    }, {
        "dateTime": "2022-01-17",
        "value": "32.084999084472656"
    }, {
        "dateTime": "2022-01-18",
        "value": "32.12300109863281"
    }, {
        "dateTime": "2022-01-19",
        "value": "32.132999420166016"
    }, {
        "dateTime": "2022-01-20",
        "value": "32.143001556396484"
    }, {
        "dateTime": "2022-01-21",
        "value": "32.15299987792969"
    }, {
        "dateTime": "2022-01-22",
        "value": "32.16299819946289"
    }, {
        "dateTime": "2022-01-23",
        "value": "32.17300033569336"
    }, {
        "dateTime": "2022-01-24",
        "value": "32.18299865722656"
    }, {
        "dateTime": "2022-01-25",
        "value": "32.19300079345703"
    }, {
        "dateTime": "2022-01-26",
        "value": "32.202999114990234"
    }, {
        "dateTime": "2022-01-27",
        "value": "32.2130012512207"
    }, {
        "dateTime": "2022-01-28",
        "value": "32.222999572753906"
    }, {
        "dateTime": "2022-01-29",
        "value": "32.233001708984375"
    }, {
        "dateTime": "2022-01-30",
        "value": "32.24800109863281"
    }, {
        "dateTime": "2022-01-31",
        "value": "32.13999938964844"
    }, {
        "dateTime": "2022-02-01",
        "value": "32.03200149536133"
    }, {
        "dateTime": "2022-02-02",
        "value": "31.923999786376953"
    }, {
        "dateTime": "2022-02-03",
        "value": "31.81599998474121"
    }, {
        "dateTime": "2022-02-04",
        "value": "31.70800018310547"
    }, {
        "dateTime": "2022-02-05",
        "value": "31.600000381469727"
    }, {
        "dateTime": "2022-02-06",
        "value": "31.486000061035156"
    }, {
        "dateTime": "2022-02-07",
        "value": "31.466999053955078"
    }, {
        "dateTime": "2022-02-08",
        "value": "31.447999954223633"
    }, {
        "dateTime": "2022-02-09",
        "value": "31.429000854492188"
    }, {
        "dateTime": "2022-02-10",
        "value": "31.40999984741211"
    }, {
        "dateTime": "2022-02-11",
        "value": "31.391000747680664"
    }, {
        "dateTime": "2022-02-12",
        "value": "31.371999740600586"
    }, {
        "dateTime": "2022-02-13",
        "value": "31.35300064086914"
    }, {
        "dateTime": "2022-02-14",
        "value": "31.333999633789062"
    }, {
        "dateTime": "2022-02-15",
        "value": "31.315000534057617"
    }, {
        "dateTime": "2022-02-16",
        "value": "31.29199981689453"
    }, {
        "dateTime": "2022-02-17",
        "value": "30.732999801635742"
    }, {
        "dateTime": "2022-02-18",
        "value": "30.17300033569336"
    }, {
        "dateTime": "2022-02-19",
        "value": "30.34000015258789"
    }, {
        "dateTime": "2022-02-20",
        "value": "30.506999969482422"
    }, {
        "dateTime": "2022-02-21",
        "value": "30.673999786376953"
    }, {
        "dateTime": "2022-02-22",
        "value": "30.840999603271484"
    }, {
        "dateTime": "2022-02-23",
        "value": "31.496000289916992"
    }, {
        "dateTime": "2022-02-24",
        "value": "31.854999542236328"
    }, {
        "dateTime": "2022-02-25",
        "value": "32.21500015258789"
    }, {
        "dateTime": "2022-02-26",
        "value": "32.41699981689453"
    }, {
        "dateTime": "2022-02-27",
        "value": "32.430999755859375"
    }, {
        "dateTime": "2022-02-28",
        "value": "32.400001525878906"
    }, {
        "dateTime": "2022-03-01",
        "value": "32.465999603271484"
    }, {
        "dateTime": "2022-03-02",
        "value": "32.82600021362305"
    }, {
        "dateTime": "2022-03-03",
        "value": "32.95100021362305"
    }, {
        "dateTime": "2022-03-04",
        "value": "33.00199890136719"
    }, {
        "dateTime": "2022-03-05",
        "value": "33.05400085449219"
    }, {
        "dateTime": "2022-03-06",
        "value": "33.4119987487793"
    }, {
        "dateTime": "2022-03-07",
        "value": "33.77000045776367"
    }, {
        "dateTime": "2022-03-08",
        "value": "34.20000076293945"
    }, {
        "dateTime": "2022-03-09",
        "value": "34.630001068115234"
    }, {
        "dateTime": "2022-03-10",
        "value": "34.492000579833984"
    }, {
        "dateTime": "2022-03-11",
        "value": "36.5629997253418"
    }, {
        "dateTime": "2022-03-12",
        "value": "36.62200164794922"
    }, {
        "dateTime": "2022-03-13",
        "value": "36.57600021362305"
    }, {
        "dateTime": "2022-03-14",
        "value": "36.55500030517578"
    }, {
        "dateTime": "2022-03-15",
        "value": "35.902000427246094"
    }, {
        "dateTime": "2022-03-16",
        "value": "35.56100082397461"
    }, {
        "dateTime": "2022-03-17",
        "value": "34.63999938964844"
    }, {
        "dateTime": "2022-03-18",
        "value": "34.382999420166016"
    }, {
        "dateTime": "2022-03-19",
        "value": "33.43199920654297"
    }, {
        "dateTime": "2022-03-20",
        "value": "33.18299865722656"
    }, {
        "dateTime": "2022-03-21",
        "value": "34.0369987487793"
    }, {
        "dateTime": "2022-03-22",
        "value": "32.92100143432617"
    }, {
        "dateTime": "2022-03-23",
        "value": "33.111000061035156"
    }, {
        "dateTime": "2022-03-24",
        "value": "33.020999908447266"
    }, {
        "dateTime": "2022-03-25",
        "value": "32.762001037597656"
    }, {
        "dateTime": "2022-03-26",
        "value": "32.59199905395508"
    }, {
        "dateTime": "2022-03-27",
        "value": "32.595001220703125"
    }, {
        "dateTime": "2022-03-28",
        "value": "32.597999572753906"
    }, {
        "dateTime": "2022-03-29",
        "value": "32.874000549316406"
    }, {
        "dateTime": "2022-03-30",
        "value": "32.99700164794922"
    }, {
        "dateTime": "2022-03-31",
        "value": "33.19499969482422"
    }, {
        "dateTime": "2022-04-01",
        "value": "34.35499954223633"
    }, {
        "dateTime": "2022-04-02",
        "value": "33.52299880981445"
    }, {
        "dateTime": "2022-04-03",
        "value": "32.922000885009766"
    }, {
        "dateTime": "2022-04-04",
        "value": "33.11199951171875"
    }, {
        "dateTime": "2022-04-05",
        "value": "31.82200050354004"
    }, {
        "dateTime": "2022-04-06",
        "value": "31.44700050354004"
    }, {
        "dateTime": "2022-04-07",
        "value": "31.71500015258789"
    }, {
        "dateTime": "2022-04-08",
        "value": "31.86400032043457"
    }, {
        "dateTime": "2022-04-09",
        "value": "31.676000595092773"
    }, {
        "dateTime": "2022-04-10",
        "value": "31.38599967956543"
    }, {
        "dateTime": "2022-04-11",
        "value": "30.805999755859375"
    }, {
        "dateTime": "2022-04-12",
        "value": "31.423999786376953"
    }, {
        "dateTime": "2022-04-13",
        "value": "31.444000244140625"
    }, {
        "dateTime": "2022-04-14",
        "value": "31.30500030517578"
    }, {
        "dateTime": "2022-04-15",
        "value": "27.204999923706055"
    }]
}
"""
EXAMPLE_DATA_BMI = """
{
    "body-bmi": [{
        "dateTime": "2021-10-12",
        "value": "25.335277557373047"
    }, {
        "dateTime": "2021-10-13",
        "value": "31.35280990600586"
    }, {
        "dateTime": "2021-10-14",
        "value": "31.370344161987305"
    }, {
        "dateTime": "2021-10-15",
        "value": "31.387880325317383"
    }, {
        "dateTime": "2021-10-16",
        "value": "31.405414581298828"
    }, {
        "dateTime": "2021-10-17",
        "value": "31.422948837280273"
    }, {
        "dateTime": "2021-10-18",
        "value": "31.440481185913086"
    }, {
        "dateTime": "2021-10-19",
        "value": "31.45801544189453"
    }, {
        "dateTime": "2021-10-20",
        "value": "31.475549697875977"
    }, {
        "dateTime": "2021-10-21",
        "value": "31.493083953857422"
    }, {
        "dateTime": "2021-10-22",
        "value": "31.510618209838867"
    }, {
        "dateTime": "2021-10-23",
        "value": "31.52815055847168"
    }, {
        "dateTime": "2021-10-24",
        "value": "31.545686721801758"
    }, {
        "dateTime": "2021-10-25",
        "value": "31.564451217651367"
    }, {
        "dateTime": "2021-10-26",
        "value": "31.644432067871094"
    }, {
        "dateTime": "2021-10-27",
        "value": "31.724411010742188"
    }, {
        "dateTime": "2021-10-28",
        "value": "31.804391860961914"
    }, {
        "dateTime": "2021-10-29",
        "value": "31.88437271118164"
    }, {
        "dateTime": "2021-10-30",
        "value": "31.964351654052734"
    }, {
        "dateTime": "2021-10-31",
        "value": "32.04433059692383"
    }, {
        "dateTime": "2021-11-01",
        "value": "32.12431335449219"
    }, {
        "dateTime": "2021-11-02",
        "value": "32.05909729003906"
    }, {
        "dateTime": "2021-11-03",
        "value": "31.993881225585938"
    }, {
        "dateTime": "2021-11-04",
        "value": "31.928667068481445"
    }, {
        "dateTime": "2021-11-05",
        "value": "31.863452911376953"
    }, {
        "dateTime": "2021-11-06",
        "value": "31.798240661621094"
    }, {
        "dateTime": "2021-11-07",
        "value": "31.805620193481445"
    }, {
        "dateTime": "2021-11-08",
        "value": "31.813003540039062"
    }, {
        "dateTime": "2021-11-09",
        "value": "31.82038688659668"
    }, {
        "dateTime": "2021-11-10",
        "value": "31.827770233154297"
    }, {
        "dateTime": "2021-11-11",
        "value": "31.83515167236328"
    }, {
        "dateTime": "2021-11-12",
        "value": "31.838844299316406"
    }, {
        "dateTime": "2021-11-13",
        "value": "31.8425350189209"
    }, {
        "dateTime": "2021-11-14",
        "value": "31.846227645874023"
    }, {
        "dateTime": "2021-11-15",
        "value": "31.849918365478516"
    }, {
        "dateTime": "2021-11-16",
        "value": "31.85361099243164"
    }, {
        "dateTime": "2021-11-17",
        "value": "31.8572998046875"
    }, {
        "dateTime": "2021-11-18",
        "value": "31.860992431640625"
    }, {
        "dateTime": "2021-11-19",
        "value": "31.864683151245117"
    }, {
        "dateTime": "2021-11-20",
        "value": "31.868375778198242"
    }, {
        "dateTime": "2021-11-21",
        "value": "31.872066497802734"
    }, {
        "dateTime": "2021-11-22",
        "value": "31.87575912475586"
    }, {
        "dateTime": "2021-11-23",
        "value": "31.87944984436035"
    }, {
        "dateTime": "2021-11-24",
        "value": "31.883142471313477"
    }, {
        "dateTime": "2021-11-25",
        "value": "31.886831283569336"
    }, {
        "dateTime": "2021-11-26",
        "value": "31.89052391052246"
    }, {
        "dateTime": "2021-11-27",
        "value": "31.894214630126953"
    }, {
        "dateTime": "2021-11-28",
        "value": "31.897907257080078"
    }, {
        "dateTime": "2021-11-29",
        "value": "31.90159797668457"
    }, {
        "dateTime": "2021-11-30",
        "value": "31.905290603637695"
    }, {
        "dateTime": "2021-12-01",
        "value": "31.908981323242188"
    }, {
        "dateTime": "2021-12-02",
        "value": "31.912670135498047"
    }, {
        "dateTime": "2021-12-03",
        "value": "31.916362762451172"
    }, {
        "dateTime": "2021-12-04",
        "value": "31.920055389404297"
    }, {
        "dateTime": "2021-12-05",
        "value": "31.92374610900879"
    }, {
        "dateTime": "2021-12-06",
        "value": "31.927438735961914"
    }, {
        "dateTime": "2021-12-07",
        "value": "31.931129455566406"
    }, {
        "dateTime": "2021-12-08",
        "value": "31.93482208251953"
    }, {
        "dateTime": "2021-12-09",
        "value": "31.93851089477539"
    }, {
        "dateTime": "2021-12-10",
        "value": "31.942201614379883"
    }, {
        "dateTime": "2021-12-11",
        "value": "31.945894241333008"
    }, {
        "dateTime": "2021-12-12",
        "value": "31.9495849609375"
    }, {
        "dateTime": "2021-12-13",
        "value": "31.953277587890625"
    }, {
        "dateTime": "2021-12-14",
        "value": "31.956968307495117"
    }, {
        "dateTime": "2021-12-15",
        "value": "31.960660934448242"
    }, {
        "dateTime": "2021-12-16",
        "value": "31.964351654052734"
    }, {
        "dateTime": "2021-12-17",
        "value": "31.968042373657227"
    }, {
        "dateTime": "2021-12-18",
        "value": "31.97173309326172"
    }, {
        "dateTime": "2021-12-19",
        "value": "31.975425720214844"
    }, {
        "dateTime": "2021-12-20",
        "value": "31.979116439819336"
    }, {
        "dateTime": "2021-12-21",
        "value": "31.985885620117188"
    }, {
        "dateTime": "2021-12-22",
        "value": "31.97081184387207"
    }, {
        "dateTime": "2021-12-23",
        "value": "31.955739974975586"
    }, {
        "dateTime": "2021-12-24",
        "value": "31.940664291381836"
    }, {
        "dateTime": "2021-12-25",
        "value": "31.92559051513672"
    }, {
        "dateTime": "2021-12-26",
        "value": "31.910518646240234"
    }, {
        "dateTime": "2021-12-27",
        "value": "31.895444869995117"
    }, {
        "dateTime": "2021-12-28",
        "value": "31.880373001098633"
    }, {
        "dateTime": "2021-12-29",
        "value": "31.865299224853516"
    }, {
        "dateTime": "2021-12-30",
        "value": "31.85022735595703"
    }, {
        "dateTime": "2021-12-31",
        "value": "31.83515167236328"
    }, {
        "dateTime": "2022-01-01",
        "value": "31.820079803466797"
    }, {
        "dateTime": "2022-01-02",
        "value": "31.80500602722168"
    }, {
        "dateTime": "2022-01-03",
        "value": "31.789934158325195"
    }, {
        "dateTime": "2022-01-04",
        "value": "31.774860382080078"
    }, {
        "dateTime": "2022-01-05",
        "value": "31.759788513183594"
    }, {
        "dateTime": "2022-01-06",
        "value": "31.744712829589844"
    }, {
        "dateTime": "2022-01-07",
        "value": "31.72964096069336"
    }, {
        "dateTime": "2022-01-08",
        "value": "31.714567184448242"
    }, {
        "dateTime": "2022-01-09",
        "value": "31.699495315551758"
    }, {
        "dateTime": "2022-01-10",
        "value": "31.681344985961914"
    }, {
        "dateTime": "2022-01-11",
        "value": "31.722257614135742"
    }, {
        "dateTime": "2022-01-12",
        "value": "31.76317024230957"
    }, {
        "dateTime": "2022-01-13",
        "value": "31.8040828704834"
    }, {
        "dateTime": "2022-01-14",
        "value": "31.84499740600586"
    }, {
        "dateTime": "2022-01-15",
        "value": "31.885910034179688"
    }, {
        "dateTime": "2022-01-16",
        "value": "31.926822662353516"
    }, {
        "dateTime": "2022-01-17",
        "value": "31.967735290527344"
    }, {
        "dateTime": "2022-01-18",
        "value": "32.010494232177734"
    }, {
        "dateTime": "2022-01-19",
        "value": "32.04002380371094"
    }, {
        "dateTime": "2022-01-20",
        "value": "32.069557189941406"
    }, {
        "dateTime": "2022-01-21",
        "value": "32.09908676147461"
    }, {
        "dateTime": "2022-01-22",
        "value": "32.12862014770508"
    }, {
        "dateTime": "2022-01-23",
        "value": "32.15814971923828"
    }, {
        "dateTime": "2022-01-24",
        "value": "32.187679290771484"
    }, {
        "dateTime": "2022-01-25",
        "value": "32.21721267700195"
    }, {
        "dateTime": "2022-01-26",
        "value": "32.246742248535156"
    }, {
        "dateTime": "2022-01-27",
        "value": "32.276275634765625"
    }, {
        "dateTime": "2022-01-28",
        "value": "32.30580520629883"
    }, {
        "dateTime": "2022-01-29",
        "value": "32.33533477783203"
    }, {
        "dateTime": "2022-01-30",
        "value": "32.36732864379883"
    }, {
        "dateTime": "2022-01-31",
        "value": "32.41562271118164"
    }, {
        "dateTime": "2022-02-01",
        "value": "32.46391677856445"
    }, {
        "dateTime": "2022-02-02",
        "value": "32.51221466064453"
    }, {
        "dateTime": "2022-02-03",
        "value": "32.56051254272461"
    }, {
        "dateTime": "2022-02-04",
        "value": "32.60880661010742"
    }, {
        "dateTime": "2022-02-05",
        "value": "32.6571044921875"
    }, {
        "dateTime": "2022-02-06",
        "value": "32.70570373535156"
    }, {
        "dateTime": "2022-02-07",
        "value": "32.730621337890625"
    }, {
        "dateTime": "2022-02-08",
        "value": "32.75553894042969"
    }, {
        "dateTime": "2022-02-09",
        "value": "32.78045654296875"
    }, {
        "dateTime": "2022-02-10",
        "value": "32.80537033081055"
    }, {
        "dateTime": "2022-02-11",
        "value": "32.83028793334961"
    }, {
        "dateTime": "2022-02-12",
        "value": "32.85520553588867"
    }, {
        "dateTime": "2022-02-13",
        "value": "32.880123138427734"
    }, {
        "dateTime": "2022-02-14",
        "value": "32.9050407409668"
    }, {
        "dateTime": "2022-02-15",
        "value": "32.92995834350586"
    }, {
        "dateTime": "2022-02-16",
        "value": "32.954872131347656"
    }, {
        "dateTime": "2022-02-17",
        "value": "32.98563766479492"
    }, {
        "dateTime": "2022-02-18",
        "value": "33.01639938354492"
    }, {
        "dateTime": "2022-02-19",
        "value": "32.968101501464844"
    }, {
        "dateTime": "2022-02-20",
        "value": "32.91980743408203"
    }, {
        "dateTime": "2022-02-21",
        "value": "32.87150955200195"
    }, {
        "dateTime": "2022-02-22",
        "value": "32.82259750366211"
    }, {
        "dateTime": "2022-02-23",
        "value": "32.834903717041016"
    }, {
        "dateTime": "2022-02-24",
        "value": "32.87489318847656"
    }, {
        "dateTime": "2022-02-25",
        "value": "32.91488265991211"
    }, {
        "dateTime": "2022-02-26",
        "value": "32.714935302734375"
    }, {
        "dateTime": "2022-02-27",
        "value": "32.496524810791016"
    }, {
        "dateTime": "2022-02-28",
        "value": "32.804141998291016"
    }, {
        "dateTime": "2022-03-01",
        "value": "32.650333404541016"
    }, {
        "dateTime": "2022-03-02",
        "value": "32.73954391479492"
    }, {
        "dateTime": "2022-03-03",
        "value": "32.71800994873047"
    }, {
        "dateTime": "2022-03-04",
        "value": "32.58265686035156"
    }, {
        "dateTime": "2022-03-05",
        "value": "32.44730758666992"
    }, {
        "dateTime": "2022-03-06",
        "value": "32.72416305541992"
    }, {
        "dateTime": "2022-03-07",
        "value": "33.001014709472656"
    }, {
        "dateTime": "2022-03-08",
        "value": "32.68571090698242"
    }, {
        "dateTime": "2022-03-09",
        "value": "32.37040710449219"
    }, {
        "dateTime": "2022-03-10",
        "value": "32.25966262817383"
    }, {
        "dateTime": "2022-03-11",
        "value": "32.30580520629883"
    }, {
        "dateTime": "2022-03-12",
        "value": "32.376556396484375"
    }, {
        "dateTime": "2022-03-13",
        "value": "32.15507125854492"
    }, {
        "dateTime": "2022-03-14",
        "value": "31.85976219177246"
    }, {
        "dateTime": "2022-03-15",
        "value": "32.10585403442383"
    }, {
        "dateTime": "2022-03-16",
        "value": "32.268890380859375"
    }, {
        "dateTime": "2022-03-17",
        "value": "32.10585403442383"
    }, {
        "dateTime": "2022-03-18",
        "value": "31.841306686401367"
    }, {
        "dateTime": "2022-03-19",
        "value": "31.78900909423828"
    }, {
        "dateTime": "2022-03-20",
        "value": "31.518308639526367"
    }, {
        "dateTime": "2022-03-21",
        "value": "32.484222412109375"
    }, {
        "dateTime": "2022-03-22",
        "value": "32.09662628173828"
    }, {
        "dateTime": "2022-03-23",
        "value": "31.961275100708008"
    }, {
        "dateTime": "2022-03-24",
        "value": "31.825923919677734"
    }, {
        "dateTime": "2022-03-25",
        "value": "31.81361961364746"
    }, {
        "dateTime": "2022-03-26",
        "value": "31.456787109375"
    }, {
        "dateTime": "2022-03-27",
        "value": "31.510618209838867"
    }, {
        "dateTime": "2022-03-28",
        "value": "31.564451217651367"
    }, {
        "dateTime": "2022-03-29",
        "value": "31.908981323242188"
    }, {
        "dateTime": "2022-03-30",
        "value": "31.250680923461914"
    }, {
        "dateTime": "2022-03-31",
        "value": "31.216846466064453"
    }, {
        "dateTime": "2022-04-01",
        "value": "31.047657012939453"
    }, {
        "dateTime": "2022-04-02",
        "value": "31.398338317871094"
    }, {
        "dateTime": "2022-04-03",
        "value": "31.342967987060547"
    }, {
        "dateTime": "2022-04-04",
        "value": "31.192235946655273"
    }, {
        "dateTime": "2022-04-05",
        "value": "30.986133575439453"
    }, {
        "dateTime": "2022-04-06",
        "value": "31.03227424621582"
    }, {
        "dateTime": "2022-04-07",
        "value": "30.838478088378906"
    }, {
        "dateTime": "2022-04-08",
        "value": "30.943065643310547"
    }, {
        "dateTime": "2022-04-09",
        "value": "30.887697219848633"
    }, {
        "dateTime": "2022-04-10",
        "value": "30.85693359375"
    }, {
        "dateTime": "2022-04-11",
        "value": "30.820022583007812"
    }, {
        "dateTime": "2022-04-12",
        "value": "30.607765197753906"
    }, {
        "dateTime": "2022-04-13",
        "value": "30.561622619628906"
    }, {
        "dateTime": "2022-04-14",
        "value": "30.626222610473633"
    }, {
        "dateTime": "2022-04-15",
        "value": "30.592384338378906"
    }]
}
"""
EXAMPLE_DATA = """
{
    "body-weight": [{
        "dateTime": "2021-10-12",
        "value": "96.865"
    }, {
        "dateTime": "2021-10-13",
        "value": "101.922"
    }, {
        "dateTime": "2021-10-14",
        "value": "101.979"
    }, {
        "dateTime": "2021-10-15",
        "value": "102.036"
    }, {
        "dateTime": "2021-10-16",
        "value": "102.093"
    }, {
        "dateTime": "2021-10-17",
        "value": "102.15"
    }, {
        "dateTime": "2021-10-18",
        "value": "102.207"
    }, {
        "dateTime": "2021-10-19",
        "value": "102.264"
    }, {
        "dateTime": "2021-10-20",
        "value": "102.321"
    }, {
        "dateTime": "2021-10-21",
        "value": "102.378"
    }, {
        "dateTime": "2021-10-22",
        "value": "102.435"
    }, {
        "dateTime": "2021-10-23",
        "value": "102.492"
    }, {
        "dateTime": "2021-10-24",
        "value": "102.549"
    }, {
        "dateTime": "2021-10-25",
        "value": "102.61"
    }, {
        "dateTime": "2021-10-26",
        "value": "102.87"
    }, {
        "dateTime": "2021-10-27",
        "value": "103.13"
    }, {
        "dateTime": "2021-10-28",
        "value": "103.39"
    }, {
        "dateTime": "2021-10-29",
        "value": "103.65"
    }, {
        "dateTime": "2021-10-30",
        "value": "103.91"
    }, {
        "dateTime": "2021-10-31",
        "value": "104.17"
    }, {
        "dateTime": "2021-11-01",
        "value": "104.43"
    }, {
        "dateTime": "2021-11-02",
        "value": "104.218"
    }, {
        "dateTime": "2021-11-03",
        "value": "104.006"
    }, {
        "dateTime": "2021-11-04",
        "value": "103.794"
    }, {
        "dateTime": "2021-11-05",
        "value": "103.582"
    }, {
        "dateTime": "2021-11-06",
        "value": "103.37"
    }, {
        "dateTime": "2021-11-07",
        "value": "103.394"
    }, {
        "dateTime": "2021-11-08",
        "value": "103.418"
    }, {
        "dateTime": "2021-11-09",
        "value": "103.442"
    }, {
        "dateTime": "2021-11-10",
        "value": "103.466"
    }, {
        "dateTime": "2021-11-11",
        "value": "103.49"
    }, {
        "dateTime": "2021-11-12",
        "value": "103.502"
    }, {
        "dateTime": "2021-11-13",
        "value": "103.514"
    }, {
        "dateTime": "2021-11-14",
        "value": "103.526"
    }, {
        "dateTime": "2021-11-15",
        "value": "103.538"
    }, {
        "dateTime": "2021-11-16",
        "value": "103.55"
    }, {
        "dateTime": "2021-11-17",
        "value": "103.562"
    }, {
        "dateTime": "2021-11-18",
        "value": "103.574"
    }, {
        "dateTime": "2021-11-19",
        "value": "103.586"
    }, {
        "dateTime": "2021-11-20",
        "value": "103.598"
    }, {
        "dateTime": "2021-11-21",
        "value": "103.61"
    }, {
        "dateTime": "2021-11-22",
        "value": "103.622"
    }, {
        "dateTime": "2021-11-23",
        "value": "103.634"
    }, {
        "dateTime": "2021-11-24",
        "value": "103.646"
    }, {
        "dateTime": "2021-11-25",
        "value": "103.658"
    }, {
        "dateTime": "2021-11-26",
        "value": "103.67"
    }, {
        "dateTime": "2021-11-27",
        "value": "103.682"
    }, {
        "dateTime": "2021-11-28",
        "value": "103.694"
    }, {
        "dateTime": "2021-11-29",
        "value": "103.706"
    }, {
        "dateTime": "2021-11-30",
        "value": "103.718"
    }, {
        "dateTime": "2021-12-01",
        "value": "103.73"
    }, {
        "dateTime": "2021-12-02",
        "value": "103.742"
    }, {
        "dateTime": "2021-12-03",
        "value": "103.754"
    }, {
        "dateTime": "2021-12-04",
        "value": "103.766"
    }, {
        "dateTime": "2021-12-05",
        "value": "103.778"
    }, {
        "dateTime": "2021-12-06",
        "value": "103.79"
    }, {
        "dateTime": "2021-12-07",
        "value": "103.802"
    }, {
        "dateTime": "2021-12-08",
        "value": "103.814"
    }, {
        "dateTime": "2021-12-09",
        "value": "103.826"
    }, {
        "dateTime": "2021-12-10",
        "value": "103.838"
    }, {
        "dateTime": "2021-12-11",
        "value": "103.85"
    }, {
        "dateTime": "2021-12-12",
        "value": "103.862"
    }, {
        "dateTime": "2021-12-13",
        "value": "103.874"
    }, {
        "dateTime": "2021-12-14",
        "value": "103.886"
    }, {
        "dateTime": "2021-12-15",
        "value": "103.898"
    }, {
        "dateTime": "2021-12-16",
        "value": "103.91"
    }, {
        "dateTime": "2021-12-17",
        "value": "103.922"
    }, {
        "dateTime": "2021-12-18",
        "value": "103.934"
    }, {
        "dateTime": "2021-12-19",
        "value": "103.946"
    }, {
        "dateTime": "2021-12-20",
        "value": "103.958"
    }, {
        "dateTime": "2021-12-21",
        "value": "103.98"
    }, {
        "dateTime": "2021-12-22",
        "value": "103.931"
    }, {
        "dateTime": "2021-12-23",
        "value": "103.882"
    }, {
        "dateTime": "2021-12-24",
        "value": "103.833"
    }, {
        "dateTime": "2021-12-25",
        "value": "103.784"
    }, {
        "dateTime": "2021-12-26",
        "value": "103.735"
    }, {
        "dateTime": "2021-12-27",
        "value": "103.686"
    }, {
        "dateTime": "2021-12-28",
        "value": "103.637"
    }, {
        "dateTime": "2021-12-29",
        "value": "103.588"
    }, {
        "dateTime": "2021-12-30",
        "value": "103.539"
    }, {
        "dateTime": "2021-12-31",
        "value": "103.49"
    }, {
        "dateTime": "2022-01-01",
        "value": "103.441"
    }, {
        "dateTime": "2022-01-02",
        "value": "103.392"
    }, {
        "dateTime": "2022-01-03",
        "value": "103.343"
    }, {
        "dateTime": "2022-01-04",
        "value": "103.294"
    }, {
        "dateTime": "2022-01-05",
        "value": "103.245"
    }, {
        "dateTime": "2022-01-06",
        "value": "103.196"
    }, {
        "dateTime": "2022-01-07",
        "value": "103.147"
    }, {
        "dateTime": "2022-01-08",
        "value": "103.098"
    }, {
        "dateTime": "2022-01-09",
        "value": "103.049"
    }, {
        "dateTime": "2022-01-10",
        "value": "102.99"
    }, {
        "dateTime": "2022-01-11",
        "value": "103.123"
    }, {
        "dateTime": "2022-01-12",
        "value": "103.256"
    }, {
        "dateTime": "2022-01-13",
        "value": "103.389"
    }, {
        "dateTime": "2022-01-14",
        "value": "103.522"
    }, {
        "dateTime": "2022-01-15",
        "value": "103.655"
    }, {
        "dateTime": "2022-01-16",
        "value": "103.788"
    }, {
        "dateTime": "2022-01-17",
        "value": "103.921"
    }, {
        "dateTime": "2022-01-18",
        "value": "104.06"
    }, {
        "dateTime": "2022-01-19",
        "value": "104.156"
    }, {
        "dateTime": "2022-01-20",
        "value": "104.252"
    }, {
        "dateTime": "2022-01-21",
        "value": "104.348"
    }, {
        "dateTime": "2022-01-22",
        "value": "104.444"
    }, {
        "dateTime": "2022-01-23",
        "value": "104.54"
    }, {
        "dateTime": "2022-01-24",
        "value": "104.636"
    }, {
        "dateTime": "2022-01-25",
        "value": "104.732"
    }, {
        "dateTime": "2022-01-26",
        "value": "104.828"
    }, {
        "dateTime": "2022-01-27",
        "value": "104.924"
    }, {
        "dateTime": "2022-01-28",
        "value": "105.02"
    }, {
        "dateTime": "2022-01-29",
        "value": "105.116"
    }, {
        "dateTime": "2022-01-30",
        "value": "105.22"
    }, {
        "dateTime": "2022-01-31",
        "value": "105.377"
    }, {
        "dateTime": "2022-02-01",
        "value": "105.534"
    }, {
        "dateTime": "2022-02-02",
        "value": "105.691"
    }, {
        "dateTime": "2022-02-03",
        "value": "105.848"
    }, {
        "dateTime": "2022-02-04",
        "value": "106.005"
    }, {
        "dateTime": "2022-02-05",
        "value": "106.162"
    }, {
        "dateTime": "2022-02-06",
        "value": "106.32"
    }, {
        "dateTime": "2022-02-07",
        "value": "106.401"
    }, {
        "dateTime": "2022-02-08",
        "value": "106.482"
    }, {
        "dateTime": "2022-02-09",
        "value": "106.563"
    }, {
        "dateTime": "2022-02-10",
        "value": "106.644"
    }, {
        "dateTime": "2022-02-11",
        "value": "106.725"
    }, {
        "dateTime": "2022-02-12",
        "value": "106.806"
    }, {
        "dateTime": "2022-02-13",
        "value": "106.887"
    }, {
        "dateTime": "2022-02-14",
        "value": "106.968"
    }, {
        "dateTime": "2022-02-15",
        "value": "107.049"
    }, {
        "dateTime": "2022-02-16",
        "value": "107.13"
    }, {
        "dateTime": "2022-02-17",
        "value": "107.23"
    }, {
        "dateTime": "2022-02-18",
        "value": "107.33"
    }, {
        "dateTime": "2022-02-19",
        "value": "107.173"
    }, {
        "dateTime": "2022-02-20",
        "value": "107.016"
    }, {
        "dateTime": "2022-02-21",
        "value": "106.859"
    }, {
        "dateTime": "2022-02-22",
        "value": "106.7"
    }, {
        "dateTime": "2022-02-23",
        "value": "106.74"
    }, {
        "dateTime": "2022-02-24",
        "value": "106.87"
    }, {
        "dateTime": "2022-02-25",
        "value": "107.0"
    }, {
        "dateTime": "2022-02-26",
        "value": "106.35"
    }, {
        "dateTime": "2022-02-27",
        "value": "105.64"
    }, {
        "dateTime": "2022-02-28",
        "value": "106.64"
    }, {
        "dateTime": "2022-03-01",
        "value": "106.14"
    }, {
        "dateTime": "2022-03-02",
        "value": "106.43"
    }, {
        "dateTime": "2022-03-03",
        "value": "106.36"
    }, {
        "dateTime": "2022-03-04",
        "value": "105.92"
    }, {
        "dateTime": "2022-03-05",
        "value": "105.48"
    }, {
        "dateTime": "2022-03-06",
        "value": "106.38"
    }, {
        "dateTime": "2022-03-07",
        "value": "107.28"
    }, {
        "dateTime": "2022-03-08",
        "value": "106.255"
    }, {
        "dateTime": "2022-03-09",
        "value": "105.23"
    }, {
        "dateTime": "2022-03-10",
        "value": "104.87"
    }, {
        "dateTime": "2022-03-11",
        "value": "105.02"
    }, {
        "dateTime": "2022-03-12",
        "value": "105.25"
    }, {
        "dateTime": "2022-03-13",
        "value": "104.53"
    }, {
        "dateTime": "2022-03-14",
        "value": "103.57"
    }, {
        "dateTime": "2022-03-15",
        "value": "104.37"
    }, {
        "dateTime": "2022-03-16",
        "value": "104.9"
    }, {
        "dateTime": "2022-03-17",
        "value": "104.37"
    }, {
        "dateTime": "2022-03-18",
        "value": "103.51"
    }, {
        "dateTime": "2022-03-19",
        "value": "103.34"
    }, {
        "dateTime": "2022-03-20",
        "value": "102.46"
    }, {
        "dateTime": "2022-03-21",
        "value": "105.6"
    }, {
        "dateTime": "2022-03-22",
        "value": "104.34"
    }, {
        "dateTime": "2022-03-23",
        "value": "103.9"
    }, {
        "dateTime": "2022-03-24",
        "value": "103.46"
    }, {
        "dateTime": "2022-03-25",
        "value": "103.42"
    }, {
        "dateTime": "2022-03-26",
        "value": "102.26"
    }, {
        "dateTime": "2022-03-27",
        "value": "102.435"
    }, {
        "dateTime": "2022-03-28",
        "value": "102.61"
    }, {
        "dateTime": "2022-03-29",
        "value": "103.73"
    }, {
        "dateTime": "2022-03-30",
        "value": "101.59"
    }, {
        "dateTime": "2022-03-31",
        "value": "101.48"
    }, {
        "dateTime": "2022-04-01",
        "value": "100.93"
    }, {
        "dateTime": "2022-04-02",
        "value": "102.07"
    }, {
        "dateTime": "2022-04-03",
        "value": "101.89"
    }, {
        "dateTime": "2022-04-04",
        "value": "101.4"
    }, {
        "dateTime": "2022-04-05",
        "value": "100.73"
    }, {
        "dateTime": "2022-04-06",
        "value": "100.88"
    }, {
        "dateTime": "2022-04-07",
        "value": "100.25"
    }, {
        "dateTime": "2022-04-08",
        "value": "100.59"
    }, {
        "dateTime": "2022-04-09",
        "value": "100.41"
    }, {
        "dateTime": "2022-04-10",
        "value": "100.31"
    }, {
        "dateTime": "2022-04-11",
        "value": "100.19"
    }, {
        "dateTime": "2022-04-12",
        "value": "99.5"
    }, {
        "dateTime": "2022-04-13",
        "value": "99.35"
    }, {
        "dateTime": "2022-04-14",
        "value": "99.56"
    }, {
        "dateTime": "2022-04-15",
        "value": "99.45"
    }]
}
"""
