"""
Applet: Wordlebyt
Summary: Your Wordle Score
Description: Display your daily Wordle score on your Tidbyt.
Author: skola28
"""

load("http.star", "http")
load("render.star", "render")
load("cache.star", "cache")
load("schema.star", "schema")
load("secret.star", "secret")

encrypted_bearer_token = "AV6+xWcEU2GW94vr5YQ4lb8IAtI8wmFy7+00IUDGkIuRKDO3k2DHXwyW15FbT/te1IGkiPyA2KXPCHhZ+Ffbj+cMQPtd/08t/IV1yEYIUUusBnZ6tWvCC6TnNN7xHazFx6riZaxR4ELS3oD5coY3rkd4CLamwYGAPMdZO42j9+54AwPK6+WX6+HGYDYO+pgXLjCxgQnJ972XfBuY5XO9k+7DIf0fSgj9CdCYW4DDCkBg16g+JDSnoVQ5nIoS7KMOkIimGkZ5kMi11QkgUpLmXmmMOV550A=="

def get_tweet(userid, api_key):
    res = http.get(
        url = "https://api.twitter.com/2/users/" + userid + "/tweets",
        headers = {
            "Authorization": "Bearer " + str(api_key),
        },
    )

    return res

def draw_box(color):
    return render.Box(
        width = 5,
        height = 5,
        color = "#000000",
        child = render.Box(width = 4, height = 4, color = color),
    )

def main(config):
    """Intent is to take the Wordle Score that you posted to Twitter, and have it automatically post to your Tidbyt"""

    #Constants
    EXAMPLETWEET = "Wordle Num G/T\n\n⬛⬛⬛⬛⬛\n⬛⬛⬛⬛⬛\n⬛⬛⬛⬛⬛\n⬛⬛⬛⬛⬛\n⬛⬛⬛⬛⬛\n⬛⬛⬛⬛⬛"

    #CACHE each user's last tweet
    userid = config.get("twitter_id")  #your Twitter UserID
    api_key = secret.decrypt(encrypted_bearer_token) or config.get("dev_api_key")  #encrypted Twitter API key

    cache_key = "{}_wordle".format(userid)  #unique id for each user

    #Check if data exists in cache for current userid
    cached_tweet = cache.get(cache_key)

    #If not expired, use cached value
    if cache.get(cache_key) != None:
        #print('Using cached tweet')
        latest_tweet = cached_tweet

        #Otherwise, get USERID's latest tweet
    else:
        #print('Getting new tweet')
        #get latest tweets via Twitter API
        raw_tweets = get_tweet(userid, api_key)

        #check if dictionary raw_tweets.jason() has a key "errors"
        if raw_tweets.json().get("errors") != None:
            #deal with error by filling latest_tweet with canned, valid data
            latest_tweet = EXAMPLETWEET

        else:
            #otherwise, grab latest tweet from the API's response
            latest_tweet = raw_tweets.json()["data"][0]["text"]
            cache.set(cache_key, latest_tweet, ttl_seconds = 60 * 15)  #15 minute cache TTL

    #Split the latest tweet up into individual words.
    TWEETTEST = latest_tweet.split()

    #Determine if latest tweet is actually a valid Worldle Score. If not, use canned (but valid) fake board.
    if TWEETTEST[0] != "Wordle":
        BOARD = EXAMPLETWEET.split()

        #Otherwise, start processing the valid Wordle score tweet
    else:
        #Split the Latest Tweet into Various Rows of Answers
        BOARD = latest_tweet.split()

    #Break the Latest Tweet into usable pieces
    #POP off the Wordle Title Text from the First Element
    WORDLETITLE = BOARD.pop(0)

    #POP off the Wordle Game Number from the New First Element
    WORDLENUMBER = BOARD.pop(0)

    #Pop off the Wordle Score Numeric from the New First Element(again!)
    WORDLESCORENUMBER = BOARD.pop(0)

    #Set the number of total guesses from what remains of BOARD
    NUMBEROFGUESSES = len(BOARD)

    #Creating a List with Each Entry from BOARD broken into individual squares
    #Ex: print(G)
    #[["⬛", "⬛", "⬛", "⬛", "⬛"],
    # ["⬛", "🟨", "⬛", "⬛", "⬛"],
    # ["⬛", "⬛", "🟨", "🟨", "🟨"],
    # ["🟩", "🟩", "🟩", "🟩", "🟩"]]

    G = [list(row.codepoints()) for row in BOARD]

    #Dictionary for Colors
    colordictionary = {
        "🟩": "#538d4e",
        "🟨": "#b59f3b",
        "⬛": "#3a3a3c",
    }

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Column(
                            children = [
                                render.Row(
                                    children = [
                                        draw_box(colordictionary[box])
                                        for box in G[row]
                                    ],
                                )
                                for row in range(NUMBEROFGUESSES)
                            ],
                        ),
                        render.Column(
                            main_align = "space_evenly",
                            children = [
                                render.Text(content = WORDLETITLE, color = "#FFFFFF"),
                                render.Text(content = WORDLENUMBER, color = "#FFFFFF"),
                                render.Text(content = WORDLESCORENUMBER, color = "#FFFFFF"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "twitter_id",
                name = "Twitter ID",
                icon = "twitter",
                desc = "To find your TwitterID, go to https://tweeterid.com/ (or similar), enter your Twitter Handle and click CONVERT",
            ),
            schema.Text(
                id = "dev_api_key",
                name = "Dev API Key",
                icon = "userSecret",
                desc = "Developer API Key for bypassing secret",
            ),
        ],
    )
