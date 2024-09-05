"""
Applet: Chicago Tribune
Summary: Chicago News
Description: Latest headlines from the Chicago Tribune. Choose from either the latest headlines or latest stories.
Author: sgomez72
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Declare Constants
DEFAULT_NEWS = "news_breaking"
DEFAULT_SETTING = "0"

# This is the URL that contains the RSS Feed
TRIBUNE_URL = "https://www.chicagotribune.com/arc/outboundfeeds/rss/section/{}/range/display_date/now-5d/now/?outputType=json&size=3"

def main(config):
    channel = config.get("tribune_feed", DEFAULT_NEWS)
    type = config.get("news_format", DEFAULT_SETTING)

    stories = get_cacheable_data(channel)

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    height = 9,
                    width = 64,
                    color = "#000",
                    child = render.Text(
                        content = "Chicago Tribune",
                        font = "tom-thumb",
                        color = "#1162a5",
                    ),
                ),
                render.Box(
                    height = 1,
                    width = 64,
                    color = "#fff",
                ),
                render.Marquee(
                    height = 30,
                    offset_start = 30,
                    child = render.Column(
                        main_align = "space_between",
                        children = render_content(stories, type),
                    ),
                    scroll_direction = "vertical",
                ),
            ],
        ),
    )

def render_content(stories, style):
    # renders the display based on the user's choice
    news_content = []

    if style == "0":  # Display the three latest headlines
        for eachStory in stories:
            news_content.append(render.WrappedText(content = eachStory[0], color = "#fa0"))
            news_content.append(render.Box(width = 64, height = 2, color = "#000"))
    else:  # Display the latest story
        news_content.append(render.WrappedText(content = stories[0][0], color = "#fa0"))
        news_content.append(render.WrappedText(content = stories[0][1], color = "#fff"))

    return news_content

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "tribune_feed",
                name = "Category",
                desc = "Select which category to display.",
                icon = "newspaper",
                default = "trib_breaking",
                options = [
                    schema.Option(
                        display = "Beaking News",
                        value = "news_breaking",
                    ),
                    schema.Option(
                        display = "Business",
                        value = "business",
                    ),
                    schema.Option(
                        display = "Dining",
                        value = "dining",
                    ),
                    schema.Option(
                        display = "Entertainment",
                        value = "entertainment",
                    ),
                    schema.Option(
                        display = "Theater Loop",
                        value = "entertainment_theater",
                    ),
                    schema.Option(
                        display = "Lifestyle",
                        value = "people",
                    ),
                    schema.Option(
                        display = "Nation & World",
                        value = "nation-world",
                    ),
                    schema.Option(
                        display = "News",
                        value = "news",
                    ),
                    schema.Option(
                        display = "Opinion",
                        value = "opinion",
                    ),
                    schema.Option(
                        display = "Politics",
                        value = "politics",
                    ),
                    schema.Option(
                        display = "Real Estate",
                        value = "real-estate",
                    ),
                    schema.Option(
                        display = "Sports",
                        value = "sports",
                    ),
                    schema.Option(
                        display = "Chicago Bears",
                        value = "sports_bears",
                    ),
                    schema.Option(
                        display = "Chicago Blackhawks",
                        value = "sports_blackhawks",
                    ),
                    schema.Option(
                        display = "Chicago Bulls",
                        value = "sports_bulls",
                    ),
                    schema.Option(
                        display = "Chicago Cubs",
                        value = "sports_cubs",
                    ),
                    schema.Option(
                        display = "Chicago White Sox",
                        value = "sports_white-sox",
                    ),
                    schema.Option(
                        display = "Sports Betting",
                        value = "betting",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "news_format",
                name = "News Format",
                desc = "Display the latest article or latest headlines.",
                icon = "circleQuestion",
                default = "0",
                options = [
                    schema.Option(
                        display = "Top Headlines",
                        value = "0",
                    ),
                    schema.Option(
                        display = "Top Story",
                        value = "1",
                    ),
                ],
            ),
        ],
    )

def get_cacheable_data(url):
    key = url
    data = cache.get(key)
    headlines = []
    if data == None:
        print("No Cache Found, Calling Chicago Tribune RSS at " + TRIBUNE_URL.format(url))
        rep = http.get(TRIBUNE_URL.format(url))
        if rep.status_code != 200:
            fail("Could not pull stories from the Chicago Tribune. Request failed with status %d", rep.status_code)
        data = json.encode(rep.json()["rss"]["channel"]["item"])

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(key, data, ttl_seconds = 1800)

    data_json = json.decode(data)

    for eachArticle in data_json:
        title = eachArticle["title"]
        desc = eachArticle["description"]
        headlines.append([title, desc])

    return headlines
