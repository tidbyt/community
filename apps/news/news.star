"""
Applet: News
Summary: News feed display
Description: Select an RSS feed and receive the latest headlines in return.
Author: JeffLac (Recreation of Tidbyt Original)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

# News source logos as base64-encoded images
BBC_LOGO = """iVBORw0KGgoAAAANSUhEUgAAAB8AAAAPCAYAAAAceBSiAAAAAXNSR0IArs4c6QAAAHxJREFUSEtj3Cwh8p9hgADjyLbc5/lrggG/RVKUgdrqwMEOMxRkAQygW4RsObHqQGYhqwXxke3CaTmyQpgh2BxJijqCliNbgOx7dJ8TUgfzMa6oAsnTzOdkWY4etNh8iC3+0dUNCsvR43lwJjh8mZ1m+ZxgCUMjBSO3bAcAX6vBEjaz3NoAAAAASUVORK5CYII="""
LA_TIMES_LOGO = """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
"""
WSJ_LOGO = """iVBORw0KGgoAAAANSUhEUgAAACAAAAARCAYAAAC8XK78AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAL9SURBVEhLhZVNiNZVFMZ/58rQImGEUMkJs3Zq2dhIBkEEUZFtilwIQZtp0a6gbQa1CIRo+lgIFhJDLUKCVrUSAxfZvOGMgtLnYgSjRNNF9DFvPY+L/7lvtz9vr8/mnPPcc8593nPve/8h6Q3gAB0uAS8CBg4DG4Ah8G4p5U1Je4FXgJ3AQinlbUk3A4ciYr3tv4EBcA04WUr5KfsCIGkemM++Bj6tC8u2Lelwk7zgDl/3mjwq6VgTL0r6vIlfy7pto6IGkg7mXt8AlOSPp22LBgC2t9qOht8AnKBrthl4BliqixHxuu0rTX4fa2mHVAER8VWSu+tmEXE67UbbM7kOsKvmR8TdEVGA2+piRPwJjCZyI9QJDOiKN9fNbK/aVvJ7mpodwNkmJiKelrSpoUYTuRGqgFXbl9K/j67p7fnrsL07bQFuiohh5q7kxZsGPrQ9lfzA9h/pT0Q9AgP1GPbQbTZrezm5e9NuBX5Mn4i4HBEfpf+I7UXb60opp0opv9S8SagToBnbXNp7gCPp1wnM9cdr+yXbq3QiDtg+2ru0EzFJwDbgmG1HxIykjTmdU00NpZQrwD7bl+lEPGv75TZnEkYCImKQm91i+05gKpvXkc8Bd0TE6AgqSinngcdsX0vqoKTtvbSxaAVcBX6gG+s+oL5ig7RzXVq41rQopZyOiKdsDyNiCnihnzMO7RHQXMR54Ez6VcB+4Pv0oXuItkjaUeOI+AI4lOFD/2b+P/oClugazQLL6dc3YrYRUzEN7O1xC/nX3EQ3zfWSPpN0RtKtvdzxAmyvAeeSW7H9T96POqEWD7RBKeVX4AJwNan9EfF4ROwC7mpS1xgj4KztIfBtKeUvul/+G3AeuBgRP/fyAZ7MLyJ04gOYjoiTGa9LezQiTgD1sfqu1vwHkpYkLfa49yR90nLJb88v2zsN96Ck3yXtzHhG0oUqRNLH6vAwYyZAXsSVlsh7MO59l+154EvbH0h6C3gVeKKUco7uSC4Cz9t+X9IR4H7guVLKcYDrxryiC6eSXQgAAAAASUVORK5CYII=
"""

# News sources and their RSS feeds
NEWS_SOURCES = {
    # BBC feeds
    "BBC": {
        "url": "https://feeds.bbci.co.uk/news/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Business": {
        "url": "https://feeds.bbci.co.uk/news/business/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Education": {
        "url": "https://feeds.bbci.co.uk/news/education/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Entertainment": {
        "url": "https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Health": {
        "url": "https://feeds.bbci.co.uk/news/health/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Politics": {
        "url": "https://feeds.bbci.co.uk/news/politics/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Science": {
        "url": "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Technology": {
        "url": "https://feeds.bbci.co.uk/news/technology/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC UK": {
        "url": "https://feeds.bbci.co.uk/news/uk/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC World": {
        "url": "https://feeds.bbci.co.uk/news/world/rss.xml",
        "logo": BBC_LOGO,
    },

    # LA Times feeds
    "LA Times": {
        "url": "https://www.latimes.com/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Business": {
        "url": "https://www.latimes.com/business/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times California": {
        "url": "https://www.latimes.com/california/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Entertainment": {
        "url": "https://www.latimes.com/entertainment-arts/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Politics": {
        "url": "https://www.latimes.com/politics/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Science": {
        "url": "https://www.latimes.com/science/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Sports": {
        "url": "https://www.latimes.com/sports/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times World": {
        "url": "https://www.latimes.com/world-nation/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },

    # WSJ feeds
    "WSJ US Business": {
        "url": "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml",
        "logo": WSJ_LOGO,
    },
    "WSJ Markets": {
        "url": "https://feeds.content.dowjones.io/public/rss/RSSMarketsMain",
        "logo": WSJ_LOGO,
    },
    "WSJ Technology": {
        "url": "https://feeds.a.dj.com/rss/RSSWSJD.xml",
        "logo": WSJ_LOGO,
    },
    "WSJ World": {
        "url": "https://feeds.a.dj.com/rss/RSSWorldNews.xml",
        "logo": WSJ_LOGO,
    },
}

# Default settings
DEFAULT_COLORS = {
    "date": "#ff0000",  # Red for date text
    "headline": "#ffcc00",  # Yellow for headlines
    "desc": "#ffffff",  # White for descriptions
}

# Cache time in seconds
CACHE_TTL = 900  # 15 minutes

def main(config):
    # Get the selected news source from config (default to BBC News)
    source_name = config.get("source", "BBC News")
    source_info = NEWS_SOURCES.get(source_name)

    if not source_info:
        return render.Root(
            child = render.Text("News source not found"),
        )

    # Get the current date in the desired format (e.g., "13 Mar")
    now = time.now()
    date_text = "%d %s" % (now.day, now.format("Jan")[:3])

    # Fetch and parse the RSS feed
    headlines = get_headlines(source_info["url"])

    if headlines == None or len(headlines) == 0:
        return render.Root(
            child = render.Text("Failed to load news"),
        )

    # Create header with logo and centered, larger date
    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",  # Vertically center the elements
        children = [
            render.Image(src = base64.decode(source_info["logo"]), width = 31, height = 15),
            render.Text(
                date_text,
                color = config.get("date_color", DEFAULT_COLORS["date"]),
                font = "5x8",
            ),
        ],
    )

    # Create text display for the first headline only
    headline_widget = render.Column(
        children = [
            # Title in yellow
            render.WrappedText(
                content = headlines[0]["title"],
                color = config.get("headline_color", DEFAULT_COLORS["headline"]),
                width = 64,
            ),
            # Description in white
            render.WrappedText(
                content = headlines[0]["description"],
                color = config.get("desc_color", DEFAULT_COLORS["desc"]),
                width = 64,
            ),
        ],
    )

    # Combine all elements into one scrollable column
    all_content = render.Column(
        children = [
            header,
            render.Box(width = 64, height = 1, color = "#333333"),  # Separator
            headline_widget,
        ],
    )

    # Render the full display with everything scrolling in one block
    return render.Root(
        delay = int(config.get("scroll_speed", "75")),
        child = render.Marquee(
            height = 32,  # Increased height to accommodate all content
            scroll_direction = "vertical",
            offset_start = 32,
            child = all_content,
        ),
    )

def get_headlines(feed_url):
    """Fetch and parse headlines from an RSS feed using xpath."""

    # Try to get cached data
    cached = cache.get("headlines_%s" % feed_url)
    if cached != None:
        cached_data = []

        # Parse the cached data
        items = cached.split("||||")
        for i in range(0, len(items) - 1, 2):
            cached_data.append({
                "title": items[i],
                "description": items[i + 1],
            })
        return cached_data

    # Fetch the RSS feed
    resp = http.get(feed_url, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return None

    # Parse the XML using xpath
    feed = xpath.loads(resp.body())

    # Extract titles and descriptions
    titles = feed.query_all("//item/title")
    descriptions = feed.query_all("//item/description")

    if len(titles) == 0 or len(descriptions) == 0:
        return None

    items = []

    # Changed: Only process the first item instead of multiple
    process_count = 1  # Only get the first item

    for i in range(process_count):
        title = titles[i]
        description = clean_html(descriptions[i])

        if title and description:
            items.append({
                "title": title,
                "description": description,
            })

    # Cache the results as pipe-delimited string
    if len(items) > 0:
        cache_parts = []
        for item in items:
            cache_parts.append(item["title"])
            cache_parts.append(item["description"])
        cache_content = "||||".join(cache_parts)
        cache.set("headlines_%s" % feed_url, cache_content, ttl_seconds = CACHE_TTL)

    return items

def clean_html(text):
    """Remove HTML tags from text without loops."""

    # Use string.replace() repeatedly for commonly found HTML tags
    # (This is not comprehensive but handles common cases)
    cleaned = text

    # Replace common HTML tags with space
    common_tags = [
        "<p>",
        "</p>",
        "<div>",
        "</div>",
        "<span>",
        "</span>",
        "<strong>",
        "</strong>",
        "<em>",
        "</em>",
        "<a",
        "</a>",
        "<br>",
        "<br/>",
        "<br />",
        "<img",
        "/>",
        ">",
        "&nbsp;",
        "&amp;",
        "&quot;",
        "&lt;",
        "&gt;",
    ]

    for tag in common_tags:
        cleaned = cleaned.replace(tag, " ")

    # Handle any remaining tags with < and > by replacing blocks
    # Use string splitting as an alternative to loops
    parts = cleaned.split("<")
    if len(parts) > 1:
        result_parts = [parts[0]]

        for i in range(1, len(parts)):
            part = parts[i]
            tag_end = part.find(">")
            if tag_end >= 0:
                # Only keep text after the tag
                result_parts.append(part[tag_end + 1:])
            else:
                # No closing bracket, keep as is
                result_parts.append(part)

        cleaned = " ".join(result_parts)

    # Clean up excessive spaces by splitting and rejoining
    words = cleaned.split()
    return " ".join(words)

def get_schema():
    """Define the app configuration schema."""
    sources = []
    for name in NEWS_SOURCES:
        sources.append(
            schema.Option(
                display = name,
                value = name,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "News Source",
                desc = "Select a news source to display headlines from.",
                icon = "newspaper",
                default = "BBC",
                options = sources,
            ),
        ],
    )
