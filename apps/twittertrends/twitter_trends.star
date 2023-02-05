"""
Applet: Twitter Trends
Summary: Displays top twitter trends
Description: Displays the top N number of Trending Hashtags on Twitter. Colors of the trends text determine how many tweets it has. White: No Volume Data, Green: Less then 25K, Blue: 25K - 100K, Orange: 100K - 250K, Purple: 250K - 500K, Red: More than 500K.
Author: Joseph Esposito
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#In my implementation, this is how I connect to the Twitter API using my account Key:Secret Key
#I don't know if this works with the OAuth2 Schema because I didn't have a way of testing it.
#In order to get the twitter API keys I applied for an elevated developer account. This was easy and free at the time.

TWITTER_TRENDS_URL = "https://api.twitter.com/1.1/trends/place.json"

TWITTER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAAAXNSR0IArs4c6
QAAAGJJREFUKFNj5Dj+3OGHpeQBBiQAEmNiZNoPEvr3/58jSJ4RJvjNQpwRpp
brxMv/yBpBbLAkTAKmGF0hSBxuIroJMD7canzWobgRxEF2PLLJMNPgbsRmKrI
iuEJ0E9EVgRQCADNVQsMdRdaKAAAAAElFTkSuQmCC
""")

EXAMPLE_TRENDS = [
    {
        "trends": [
            {
                "name": "Hello World",
                "tweet_volume": 1521525
            },
            {
                "name": "Something Funny",
                "tweet_volume": 201321
            },
            {
                "name": "Cool Thing",
                "tweet_volume": 384002
            },
            {
                "name": "Can You Believe It!",
                "tweet_volume": 99025
            },
            {
                "name": "#TidbytRocks",
                "tweet_volume": 958164
            },
            {
                "name": "Coding is cool",
                "tweet_volume": 15000
            },
            {
                "name": "Famous-Person-Here",
                "tweet_volume": 250652
            },
            {
                "name": "Twilight",
                "tweet_volume": 169539
            },
            {
                "name": "Breaking News",
                "tweet_volume": 42000
            },
            {
                "name": "Top Twitter Trend",
                "tweet_volume": 201321
            },
        ],
    },
]


def main(config):
    """_summary_

    Args:
        config (_type_): _description_

    Returns:
        render: The render for the Tidbyt's display.
    """

    #Check for cache
    trends_cached = cache.get("twitter_trends_rate")
    top_trends = {}

    if trends_cached != None:
        print("Hit! Displaying cached data.")

        top_trends = json.decode(trends_cached)
    else:
        print("Miss! Calling Twitter data.")

        #Check for API keys

        if config.get("key", None) != None and config.get("secret", None) != None:
            api_parameters = {
                "client_id": "{}:{}".format(config.get("key", None), config.get("secret", None)),
            }

            #Used for testing (replace the values with your keys but keep the colon)
            #test_api_parameters = {
            #    "client_id": "key:secret_key",
            #}

            #Submit authentication request to Twitter
            token = oauth_handler(json.encode(api_parameters))

            #Submit request to Twitter API v1.1
            rep = get_data(token)

            #Check result
            if rep.status_code != 200:
                return render.Root(
                    render.WrappedText("Something went wrong getting twitter data!"),
                )

            #Parse data
            for trend in rep.json()[0]["trends"]:
                top_trends[trend["name"]] = trend["tweet_volume"]

            #Save to cache for 1 Minute
            cache.set("twitter_trends_rate", json.encode(top_trends), ttl_seconds = 60)

        else:
            #Use EXAMPLE_TRENDS if API keys are blank
            for trend in EXAMPLE_TRENDS[0]["trends"]:
                top_trends[trend["name"]] = trend["tweet_volume"]

    #Get limit, default to 15

    if config.get("key", None) != None:
        limit = int(config.get("key", None))
    else:
        limit = 15

    top_trends_formatted = format_trends(top_trends, limit)

    #Render Screen
    return render.Root(
        delay = 200,
        child =
            render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Image(TWITTER_ICON),
                            render.Text("  Trending", color = "#0ac6e9", font = "tb-8"),
                        ],
                    ),
                    render.Box(
                        height = 1,
                        color = "#227d9c",
                    ),
                    render.Marquee(
                        height = 32,
                        offset_start = 15,
                        scroll_direction = "vertical",
                        child = render.Column(
                            main_align = "space_between",
                            children = top_trends_formatted[0:],
                        ),
                    ),
                ],
            ),
    )


def oauth_handler(params):
    """Handles the authentication of the API keys from user.

    Args:
        params (json): parameters from the schema input

    Returns:
        string: The bearer token for Twitter API access
    """

    # deserialize oauth2 parameters and grab keys
    params = json.decode(params)
    key_secret = params["client_id"]

    #Encode the keys
    b64_encoded_key = base64.encode(key_secret)

    #Set up authentication values
    base_url = "https://api.twitter.com/"
    auth_url = "{}oauth2/token".format(base_url)

    auth_headers = {
        "Authorization": "Basic {}".format(b64_encoded_key),
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-6",
    }
    auth_data = {
        "grant_type": "client_credentials",
    }

    auth_resp = http.post(auth_url, headers = auth_headers, form_body = auth_data)

    if auth_resp.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (auth_resp.status_code, auth_resp.body()))

    return auth_resp.json()["access_token"]


def get_data(access_token):
    """get_data will request the top trending hashtags from Twitter.

    Args:
        access_token (string): The access token from the authentication request.

    Returns:
        json: The returned data in json format.
    """

    #Set GET request values
    trend_headers = {"Authorization": "Bearer {}".format(access_token)}
    trend_params = {"id": "23424977"}

    return http.get(TWITTER_TRENDS_URL, params = trend_params, headers = trend_headers)


def format_trends(trends_dict, limit):
    """formats the data in the right way to display. Assigns color based on the volume of tweets for a given trend

    Args:
        trends_dict (dict): A dictionary of twitter trends, key (string): name, value (string): Volume of tweets
        limit (int): The limit of trends to display

    Returns:
        list: A list of the render objects that should display on the Tidbyt.
    """
    #White: #ffffff No Volume Data
    #Green: #0c6e11 Less then 25K
    #Blue: #173e99 Less than 100K
    #Orange: #ff8c00 Less than 250K
    #Purple: #4d0b80 Less than 500K
    #Red: #a30707 More than 500K
    #Gold: #cfc91f More than 1M

    text_list = []

    for key in trends_dict:
        #Default color to white
        color = "#ffffff"

        #Check for volume
        if trends_dict[key] != None:
            vol = int(trends_dict[key])

            #Set color of text based on volume
            if vol < 25000:
                color = "#0c6e11"  #Green
            elif vol < 100000:
                color = "#173e99"  #Blue
            elif vol < 250000:
                color = "#ff8c00"  #Orange
            elif vol < 500000:
                color = "#4d0b80"  #Purple
            elif vol < 999999:
                color = "#a30707"  #Red
            else:
                color = "#cfc91f"  #Gold

        #Adjust font if text is long
        if len(key) < 14:
            font = "tb-8"
        else:
            font = "tom-thumb"

        #append the trending tag
        text_list.append(render.WrappedText(key, font = font, color = color, linespacing = -1))

        #append a separator
        text_list.append(render.Box(height = 1, color = "#00eeff"))

        #End if the list exceeds the limit
        if len(text_list) == (limit * 2):
            return text_list + text_list

    #Doubles the list up for continuous scrolling

    return text_list + text_list

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "limit",
                name = "Limit",
                desc = "How many trends should display? Max of 50.",
                icon = "asterisk",
            ),
            schema.Text(
                id = "key",
                name = "Key",
                desc = "The API Key from your Elevated Twitter Development Account.",
                icon = "key",
            ),
            schema.Text(
                id = "secret",
                name = "Secret Key",
                desc = "The API Secret Key from your Elevated Twitter Development Account.",
                icon = "key",
            ),
        ],
    )
