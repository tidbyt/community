"""
Applet: Chicago Tribune
Summary: Chicago Tribune News
Description: Latest news, sports and other topics from the Chicago Tribune. Choose from either the latest headlines or latest stories.
Author: sgomez72
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

# Declare Constants
DEFAULT_NEWS = "news"
DEFAULT_SETTING = "0"

# This is the URL that contains the RSS Feed
TRIBUNE_URL = "https://www.chicagotribune.com/{}/feed/"

def main(config):
    channel = config.get("tribune_feed", DEFAULT_NEWS)
    type = config.get("news_format", DEFAULT_SETTING)

    stories = get_cacheable_data(channel)

    return render.Root(
        show_full_animation = True,
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
                name = "News Page",
                desc = "Select which category to display.",
                icon = "newspaper",
                default = "news",
                options = [
                    schema.Option(
                        display = "News",
                        value = "news",
                    ),
                    schema.Option(
                        display = "Business",
                        value = "business",
                    ),
                    schema.Option(
                        display = "Things to Do Around Chicago",
                        value = "things-to-do",
                    ),
                    schema.Option(
                        display = "Food & Drink",
                        value = "things-to-do/restaurants-food-drink",
                    ),
                    schema.Option(
                        display = "National",
                        value = "nation",
                    ),
                    schema.Option(
                        display = "World",
                        value = "news/world",
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
                        display = "Sports",
                        value = "sports",
                    ),
                    schema.Option(
                        display = "Noticias en Español",
                        value = "espanol",
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
        jsonData = []

        rep = http.get(TRIBUNE_URL.format(url))
        if rep.status_code != 200:
            fail("Could not pull stories from the Chicago Tribune. Request failed with status %d", rep.status_code)

        data_xml = xpath.loads(rep.body())
        nodeData = data_xml.query_all_nodes("/rss/channel/item[position()<4]")

        for eachNode in nodeData:
            nodeHeadline = eachNode.query("/title")
            nodeArticle = eachNode.query("/description")
            jsonData.append({"title": nodeHeadline, "description": nodeArticle})

        data = json.encode(jsonData)

        cache.set(key, data, ttl_seconds = 1800)

    data_json = json.decode(data)

    for eachArticle in data_json:
        title = eachArticle["title"]
        desc = eachArticle["description"]
        headlines.append([title, desc])

    return headlines
