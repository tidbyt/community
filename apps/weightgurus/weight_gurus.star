"""
Applet: Weight Gurus
Summary: Displays recent weigh-ins
Description: Displays the most recent weigh-ins from your Weight Gurus scale.
Author: grantmd
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#App Settings
CACHE_TTL = 60 * 60 * 24  # updates once daily

#API information from https://gist.github.com/MarkWalters-pw/08ea0e8737e3e4d11f70427ef8fdc7df and https://github.com/merval/weightgurus
WEIGHTGURUS_LOGIN = "https://api.weightgurus.com/v3/account/login"
WEIGHTGURUS_HISTORY = "https://api.weightgurus.com/v3/operation/?%s"

#Weight Gurus Data Display
DISPLAY_FONT = "CG-pixel-3x5-mono"
FAT_COLOR = "#b9d9eb"
KILOGRAMS_TO_POUNDS_MULTIPLIER = float(2.205)
WEIGHT_COLOR = "#00B0B9"
WHITE_COLOR = "#FFF"

# buildifier: disable=function-docstring
def main(config):
    #get user settings
    email = config.get("email")
    password = config.get("password")

    period = config.get("period") or "0"
    system = config.get("system") or "imperial"
    secondary_display = config.get("second") or "none"

    #setup our variables for holding the data we get back and display
    operations = None

    if not email or not password:
        print("No email and password set, using example data")
        operations = json.decode(EXAMPLE_DATA)
    else:
        #get an access token
        access_token = get_access_token(email, password)

        #Now we have an access token, either from cache or using email and password
        #so let's get data from cache, then if it's not there
        #We'll go reload it with our access_token
        #We need data for weight, bmi and body fat %

        # For weight, fat % and bmi, let's get the data from cache, and if it doesn't exist, get it from weight gurus
        print("Checking cache for weight data")
        cache_item_name = "%s_operations" % access_token
        cached_operations = cache.get(cache_item_name)
        if cached_operations == None:
            print("No weight data in cache, fetching from weight gurus")

            #TODO: Filter this based on requested period to reduce data size
            operations = get_data_from_weightgurus(access_token)

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(cache_item_name, json.encode(operations), ttl_seconds = CACHE_TTL)
        else:
            print("Using cached weight data")
            operations = json.decode(cached_operations)

    #Default Values
    current_weight = 0
    first_weight = 0
    current_fat = 0
    current_bmi = 0
    first_weight_date = None

    #Process Data
    if operations != None:
        if len(operations) > 0:
            #TODO: Skip operationType not "create"?
            current_weight = float(operations[-1]["weight"] / 10)
            first_weight = float(get_starting_value(operations, period, "weight") / 10)
            if first_weight < 0:
                first_weight = 0
            first_weight_date = get_starting_value(operations, period, "entryTimestamp")

            current_fat = float(operations[-1]["bodyFat"] / 10)
            current_bmi = float(operations[-1]["bmi"] / 10)

    #convert to imperial if need be
    if system == "metric":
        display_units = "KGs"
        current_weight = float(current_weight) / KILOGRAMS_TO_POUNDS_MULTIPLIER
        first_weight = float(first_weight) / KILOGRAMS_TO_POUNDS_MULTIPLIER
    else:
        display_units = "LBs"

    weight_change = current_weight - first_weight

    # The - sign is part of the number, but I want a "+" sign if there is a gain
    sign = ""
    if weight_change > 0:
        sign = "+"

    weight_plot = get_plot_from_data(operations, "weight", period)
    fat_plot = get_plot_from_data(operations, "bodyFat", period)
    # Unless your height is changing, the weight_plot and bmi_plot is identical, and looks stupid
    # So let's just show the weight with current BMI info added, but not the second plot
    #bmi_plot = get_plot_from_data(operations, "bmi", period)

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
            first_weight_display = "since %s " % get_timestamp_from_date(first_weight_date).format("Jan 2, 2006")

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
def get_starting_value(operations, period, itemName):
    for item in operations:
        current_date = get_timestamp_from_date(item["entryTimestamp"])

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

def get_plot_from_data(json_data, key, period):
    """ Gets the plot from the json_data for the given key and period

    Args:
        json_data: from weight gurus
        key: the key to measure, like `weight`
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
        for item in json_data:
            #TODO: What to do with operationType=="delete"?
            if not item["operationType"] == "create":
                continue

            current_date = get_timestamp_from_date(item["entryTimestamp"])
            current_value = float(item[key] / 10)
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
        for item in json_data:
            #TODO: What to do with operationType=="delete"?
            if not item["operationType"] == "create":
                continue

            item_count = item_count + 1
            current_date = get_timestamp_from_date(item["entryTimestamp"])
            current_value = float(item[key] / 10)
            days = get_days_between(time.now(), current_date)

            if number_of_days == 0 or days < number_of_days:
                y_val = current_value
                x_val = get_days_between(current_date, oldest_date)
                plot.append((x_val, y_val))

    return plot

def get_timestamp_from_date(date_string):
    return time.parse_time(date_string)

def get_days_between(day1, day2):
    date_diff = day1 - day2
    days = math.floor(date_diff.hours // 24)
    return days

# buildifier: disable=function-docstring
def get_data_from_weightgurus(access_token):
    res = http.get(
        url = WEIGHTGURUS_HISTORY,
        headers = {
            "Authorization": "Bearer %s" % access_token,
        },
    )

    if res.status_code == 200:
        return res.json()["operations"]
    else:
        return None

def get_access_token(email, password):
    """ Gets the access token

    Args:
        email: weight gurus account email address
        password: weight gurus account password

    Returns:
        access token
    """

    cache_key = "access_token_%s" % hash.sha256(email + password)
    access_token = cache.get(cache_key)
    #print("Cached access token: %s" % access_token)

    if not access_token:
        #print("No access token found in cache, logging in with %s / %s" % (email, password))
        print("No access token found in cache, logging in with email and password")

        login_data = dict(
            email = email,
            password = password,
            web = True,
        )

        headers = dict(
            ContentType = "application/json",
        )

        res = http.post(
            url = WEIGHTGURUS_LOGIN,
            headers = headers,
            json_body = login_data,
        )

        if res.status_code != 200:
            #print("Error Calling Weight Gurus Token: %s" % (res.body()))
            fail("token request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        token_params = res.json()
        access_token = token_params["accessToken"]
        expires = get_timestamp_from_date(token_params["expiresAt"])
        ttl = expires - time.now()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_key, access_token, ttl_seconds = int(ttl.seconds - 30))

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
            schema.Text(
                id = "email",
                name = "Email",
                desc = "Your Weight Gurus email address.",
                icon = "envelope",
            ),
            schema.Text(
                id = "password",
                name = "Password",
                desc = "Your Weight Gurus password.",
                icon = "lock",
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

EXAMPLE_DATA = """
[
    {
        "operationType": "create",
        "entryTimestamp": "2023-03-24T14:27:18.000Z",
        "serverTimestamp": "2023-03-24T14:28:32.008Z",
        "weight": 2116,
        "bodyFat": 238,
        "muscleMass": 359,
        "water": 586,
        "source": "wifi scale",
        "bmi": 304
    },
    {
        "operationType": "create",
        "entryTimestamp": "2023-03-25T16:33:44.000Z",
        "serverTimestamp": "2023-03-25T16:35:18.181Z",
        "weight": 2104,
        "bodyFat": 236,
        "muscleMass": 360,
        "water": 588,
        "source": "wifi scale",
        "bmi": 302
    },
    {
        "operationType": "create",
        "entryTimestamp": "2023-03-26T15:53:37.000Z",
        "serverTimestamp": "2023-03-26T15:54:52.553Z",
        "weight": 2112,
        "bodyFat": 236,
        "muscleMass": 360,
        "water": 587,
        "source": "wifi scale",
        "bmi": 303
    },
    {
        "operationType": "create",
        "entryTimestamp": "2023-03-27T14:27:49.000Z",
        "serverTimestamp": "2023-03-27T14:28:59.178Z",
        "weight": 2105,
        "bodyFat": 235,
        "muscleMass": 361,
        "water": 588,
        "source": "wifi scale",
        "bmi": 302
    }
]
"""
