"""
Applet: FitbitWeight
Summary: Displays recent weigh-ins
Description: Displays your Fitbit recent weigh-ins.
Author: Robert Ison
"""

# https://appauth.tidbyt.com/FitbitWeight
# https://localhost:8080/?code=42bd56d416272e67a8a23d98d7e73962862d01a2#_=_
#42bd56d416272e67a8a23d98d7e73962862d01a2
#238FC5 OAuth2 Client ID
# Client Secret 13c1038cdd434febc86318cd4322b489

#Does this change?
#MjM4RkM1OjEzYzEwMzhjZGQ0MzRmZWJjODYzMThjZDQzMjJiNDg5

#API Calls
#https://api.fitbit.com/1/user/-/weight_json/weight/date/today/7d.json
#https://api.fitbit.com/1/user/-/body/log/fat/date/today/7d.json

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

#OAuth Information
FITBIT_CLIENT_ID = "238FC5"
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcE74PvLnAK9o2UbKXs4mvqPOtEMJzu/AvYJQzd9Ngjvk/N5Ee2G3YD4+EF5TMJyWSs85/MoOk2VZWddwZh7+Zld7+ySKsF49sF+4tFGEQjOqVOebCiKpL1YpwFcBmC0em2bLFO890zJRjVUHDDLfXXkasbIftnKofwR49Kpga5oAY=") or "13c1038cdd434febc86318cd4322b489"
TEST_AUTHORIZATION_CODE = "3a7f1e0d25299c84aa2376969f1bd1719205e4aa"

#Notes:
#FITBIT_CODE_VERIFIER = "01234567890123456789012345678901234567890123456789"
#FITBIT_CODE_CHALLENGE = "-4cf-Mzo_qg9-uq0F4QwWhRh4AjcAqNx7SbYVsdmyQM"
#FITBIT_LAUNCH_CACHE_NAME = "UniqueIDOfUser"

#Fitbit Data
FITBIT_BASE = "https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=238FC5&redirect_uri=https%3A%2F%2Fappauth.tidbyt.com%2FFitbitWeight&scope=profile%20weight&expires_in=604800"
FITBIT_SCOPES = "profile weight activity"
FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"

#Fitbit Data Display
DISPLAY_FONT = "CG-pixel-3x5-mono"
FAT_COLOR = "#B9D9EB"
FITBIT_LOGO = """
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
"""
KILOGRAMS_TO_POUNDS_MULTIPLIER = float(2.2)
WEIGHT_COLOR = "#00B0B9"
WHITE_COLOR = "#FFF"

def main(config):
    #get user settings
    authorization_code = config.get("code")
    print("Authorization Code: %s" % authorization_code)
    period = config.get("period")
    system = config.get("system")
    show_fat = config.bool("show_fat", False)

    #Let's get data from Fitbit!! Needs help
    #get tokens from code
    if authorization_code:
        token_information = get_access_token_information(authorization_code)
        if token_information != None:
            print(token_information["access_token"])
            print(token_information["refresh_token"])
            print(token_information["user_id"])
 
    #get data from tokens
    #refresh token if need be

    weight_json = json.decode(EXAMPLE_DATA)
    fat_json = json.decode(EXAMPLE_DATA_FAT)

    #Process Data
    current_weight = float(weight_json['body-weight'][-1]["value"])
    current_fat = float(fat_json['body-fat'][-1]["value"])
    first_weight = float(weight_json['body-weight'][0]["value"])

    if system == "metric":
        displayUnits = "KG"
    else:
        displayUnits = "LB"
        current_weight = current_weight * KILOGRAMS_TO_POUNDS_MULTIPLIER
        first_weight = first_weight * KILOGRAMS_TO_POUNDS_MULTIPLIER

    weight_change = current_weight - first_weight
    
    # The - sign is part of the number, but I want a "+" sign if there is a gain
    sign = ""
    if weight_change > 0:
        sign = "+"

    weight_plot = get_plot_from_data(weight_json)
    fat_plot = get_plot_from_data(fat_json)
    display_weight = "%s%s " % ((humanize.comma(int(current_weight * 100) / 100.0)), displayUnits)
    if show_fat == True:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                    render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT), 
                    render.Text(("%s%%" % (humanize.comma(int(current_fat * 100) / 100.0))), color = FAT_COLOR, font = DISPLAY_FONT),
                ],
        )
    else:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                    render.Text(display_weight, color = WHITE_COLOR, font = DISPLAY_FONT), 
                    render.Text("%s%s" % (sign, humanize.comma(int(weight_change * 100) / 100.0)), color = WEIGHT_COLOR, font = DISPLAY_FONT),
                ],
        )
    
    #Build the display in rows
    rows = [numbers_row]
    rows.append(render.Box(height = 1))
    if show_fat == True:
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

def get_plot_display_from_plot(plot, color = WHITE_COLOR, height=13):
    return render.Plot(
            data = plot,
            width = 64,
            height = height,
            color = color,
            ylim = (0.0, 1.0),
            xlim = (0.0, 1.0),
            fill = True,
        )

def get_plot_from_data(json_data):
    #Loop through data and get max and mins
    oldest_date = None
    newest_date = None
    smallest = None
    largest = None
    starting_value = None 
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])

            #get starting value
            if starting_value == None: starting_value = current_value

            #get the oldest date
            if oldest_date == None: oldest_date = current_date 
            elif current_date < oldest_date: oldest_date = current_date 

            #get the newest date
            if newest_date == None: newest_date = current_date 
            elif current_date > newest_date: newest_date = current_date

            #get smallest
            if smallest == None: smallest = current_value 
            elif current_value < smallest: smallest = current_value

            #get largest
            if largest == None: largest = current_value 
            elif current_value > largest: largest = current_value

    date_range = newest_date - oldest_date
    value_range = largest - smallest 

    #now plot the data:
    plot = [(0.0, float((starting_value - smallest)/(largest - smallest)))]
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])
            x_val =  (current_date - oldest_date).hours/(newest_date - oldest_date).hours
            y_val = (current_value - smallest)/(largest - smallest)
            plot.append((float(x_val), plot[-1][1]))
            plot.append((float(x_val), float(y_val)))

    return plot



def get_timestamp_from_date(date_string):
    date_parts = str(date_string).split("-")
    return time.time(year = int(date_parts[0]), month = int(date_parts[1]), day = int(date_parts[2]))

def oauth_handler(params):
    # deserialize oauth2 parameters, see example aboce.
    params = json.decode(params)
    print("oauth_handler")
    print(str(params))
    # exchange parameters and client secret for an access token
    res = http.post(
        url = "https://api.fitbit.com/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_weight_json = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
            scope = FITBIT_SCOPES,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.weight_json()))

    token_params = res.json()
    authorization_code = token_params["authorization_code"]
    cache.set(authorization_code, token_params["access_token"], ttl_seconds = int(token_params["expires_in"] - 30))

    return authorization_code

def get_data_from_fitbit(access_token):

    #CRAP - Can't even get the access token yet

        res = http.get(
            url = FITBIT_TOKEN_URL,
            headers = {
                "Accept": "application/json",
                "Authorization": "Bearer %s" % token_information["access_token"],
            },
        )

        if res.status_code != 200:
            weight_json = json.decode(EXAMPLE_DATA)
            #fail("bad request for station infomation: %s %s" %
            #     (res.status_code, res.weight_json()))
        weight_json = json.decode(EXAMPLE_DATA)
        fat_json = json.decode(EXAMPLE_DATA_FAT)


def get_access_token_information(authorization_code):
    print("get_access_token_information")
    print("Authorization Code: %s" % authorization_code)

    params = dict(
        client_id = FITBIT_CLIENT_ID,
        grant_type = "authorization_code",
        redirect_uri = "http://localhost:8080/",
        code = authorization_code,
    )

    res = http.post(
            url = "https://api.fitbit.com/oauth2/token",
            params = params,
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": "Basic MjM4RkM1OjEzYzEwMzhjZGQ0MzRmZWJjODYzMThjZDQzMjJiNDg5",
            },
        )

    if res.status_code != 200:
        return None
        print("bad request for station infomation: %s %s" %
                (res.status_code, res.weight_json()))

    token_params = res.json()

    token_information = {
        "access": token_params["access_token"],
        "refresh": token_params["refresh_token"],
        "user_id": token_params["user_id"],
    }

    return token_information

def get_schema():
    period_options = [
        schema.Option(value = "7d", display = "7 Days"),
        schema.Option(value = "30d", display = "30 Days"),
        schema.Option(value = "1m", display = "1 Month"),
        schema.Option(value = "3m", display = "3 Months"),
        schema.Option(value = "6m", display = "6 Months"),
        schema.Option(value = "1y", display = "1 Year"),
        schema.Option(value = "max", display = "Maximum Allowed"),
    ]

    measurement_options = [
        schema.Option(value = "metric", display = "Metric"),
        schema.Option(value = "imperial", display = "Imperial"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                icon = "cloud",
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
                icon = "pencilRuler",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "system",
                name = "Measurement",
                desc = "Choose Imperial or Metric",
                icon = "gear",
                options = measurement_options,
                default = "metric",
            ),
            schema.Toggle(
                id = "show_fat",
                name = "Show Fat %",
                desc = "Do you want to display the fat percentage and trend?",
                icon = "cog",
                default = False,
            ),
        ],
    )

EXAMPLE_DATA_FAT = """
{"body-fat":[{"dateTime":"2022-04-09","value":"31.676000595092773"},{"dateTime":"2022-04-10","value":"31.38599967956543"},{"dateTime":"2022-04-11","value":"30.805999755859375"},{"dateTime":"2022-04-12","value":"31.423999786376953"},{"dateTime":"2022-04-13","value":"31.444000244140625"},{"dateTime":"2022-04-14","value":"31.30500030517578"},{"dateTime":"2022-04-15","value":"30.363000869750977"}]}
"""

EXAMPLE_DATA = """
{
  "body-weight": [
    { "dateTime": "2022-03-13", "value": "104.53" },
    { "dateTime": "2022-03-14", "value": "103.57" },
    { "dateTime": "2022-03-15", "value": "104.37" },
    { "dateTime": "2022-03-16", "value": "104.9" },
    { "dateTime": "2022-03-17", "value": "104.37" },
    { "dateTime": "2022-03-18", "value": "103.51" },
    { "dateTime": "2022-03-19", "value": "103.34" },
    { "dateTime": "2022-03-20", "value": "102.46" },
    { "dateTime": "2022-03-21", "value": "105.6" },
    { "dateTime": "2022-03-22", "value": "104.34" },
    { "dateTime": "2022-03-23", "value": "103.9" },
    { "dateTime": "2022-03-24", "value": "103.46" },
    { "dateTime": "2022-03-25", "value": "103.42" },
    { "dateTime": "2022-03-26", "value": "102.26" },
    { "dateTime": "2022-03-27", "value": "102.435" },
    { "dateTime": "2022-03-28", "value": "102.61" },
    { "dateTime": "2022-03-29", "value": "103.73" },
    { "dateTime": "2022-03-30", "value": "101.59" },
    { "dateTime": "2022-03-31", "value": "101.48" },
    { "dateTime": "2022-04-01", "value": "100.93" },
    { "dateTime": "2022-04-02", "value": "102.07" },
    { "dateTime": "2022-04-03", "value": "101.89" },
    { "dateTime": "2022-04-04", "value": "101.4" },
    { "dateTime": "2022-04-05", "value": "100.73" },
    { "dateTime": "2022-04-06", "value": "100.88" },
    { "dateTime": "2022-04-07", "value": "100.25" },
    { "dateTime": "2022-04-08", "value": "100.59" },
    { "dateTime": "2022-04-09", "value": "100.41" }
  ]
}
"""