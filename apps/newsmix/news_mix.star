"""
Applet: News Mix
Summary: News from multiple sources
Description: Display rotating headlines from your choice of major news sources. See up to 9 top stories from 3 different feeds. 
             Customize colors and scroll speed for your perfect news reading experience.
Author: Weiqi Ma
"""

load("cache.star", "cache")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

# Default feed configurations
AVAILABLE_FEEDS = {
    # WSJ feeds
    "WSJ US News": "https://feeds.content.dowjones.io/public/rss/RSSUSnews",
    "WSJ World News": "https://feeds.content.dowjones.io/public/rss/RSSWorldNews",
    "WSJ Markets": "https://feeds.content.dowjones.io/public/rss/RSSMarketsMain",
    "WSJ Technology": "https://feeds.content.dowjones.io/public/rss/RSSWSJD",
    "WSJ US Business": "https://feeds.content.dowjones.io/public/rss/WSJcomUSBusiness",
    "WSJ Economy": "https://feeds.content.dowjones.io/public/rss/socialeconomyfeed",
    "WSJ Politics": "https://feeds.content.dowjones.io/public/rss/socialpoliticsfeed",
    # NYT feeds
    "NYT Home Page": "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
    "NYT World": "https://rss.nytimes.com/services/xml/rss/nyt/World.xml",
    "NYT Politics": "https://rss.nytimes.com/services/xml/rss/nyt/Politics.xml",
    "NYT Technology": "https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml",
    "NYT Business": "https://rss.nytimes.com/services/xml/rss/nyt/Business.xml",
    "NYT Science": "https://rss.nytimes.com/services/xml/rss/nyt/Science.xml",
    # Other news sources...
    "BBC Top Stories": "http://feeds.bbci.co.uk/news/rss.xml",
    "CNN Top Stories": "http://rss.cnn.com/rss/cnn_topstories.rss",
    "NPR News": "https://feeds.npr.org/1001/rss.xml",
    "The Guardian": "https://www.theguardian.com/international/rss",
    "TechCrunch": "https://techcrunch.com/feed/",
}

# Default colors
DEFAULT_COLORS = {
    "header": "#00ff00",  # Green for feed name
    "headline": "#ffa500",  # Orange for headlines
    "desc": "#ffffff",  # White for descriptions
    "separator": "#666666",  # Gray for separator
}

# Number of headlines to keep and display
TOP_N_HEADLINES = 3

# Cache time-to-live in seconds for the parsed feed content
CACHE_TTL_SECONDS = 600  # 10 minutes

# Cache errors for a shorter time
CACHE_ERROR_TTL_SECONDS = 180  # 3 minutes

def main(config):
    """Displays news headlines and descriptions from RSS feeds.

    Args:
        config: Configuration dictionary from Tidbyt

    Returns:
        render.Root: A display containing scrolling news content.
    """
    selected_feeds = {
        config.str("feed1", "WSJ US News"): AVAILABLE_FEEDS[config.str("feed1", "WSJ US News")],
        config.str("feed2", "WSJ World News"): AVAILABLE_FEEDS[config.str("feed2", "WSJ World News")],
        config.str("feed3", "NYT Home Page"): AVAILABLE_FEEDS[config.str("feed3", "NYT Home Page")],
    }

    feed_names = list(selected_feeds.keys())

    colors = {
        "header": config.str("header_color", DEFAULT_COLORS["header"]),
        "headline": config.str("headline_color", DEFAULT_COLORS["headline"]),
        "desc": config.str("desc_color", DEFAULT_COLORS["desc"]),
        "separator": DEFAULT_COLORS["separator"],
    }

    scroll_speed = int(config.str("scroll_speed", "75"))  # Default to normal speed

    # Get the stored index from cache, default to 0 if not found
    current_index = int(cache.get("feed_index") or "0")
    feed_name = feed_names[current_index]
    feed_url = selected_feeds[feed_name]

    # Increment and store the new index for next rotation
    next_index = (current_index + 1) % len(selected_feeds)
    cache.set("feed_index", str(next_index), ttl_seconds = 3600)

    headline, description = get_feed_content(feed_url)

    # If primary feed fails, try others as fallback
    if not headline or not description:
        headline, description = try_other_feeds(feed_name, selected_feeds)

    if not headline or not description:
        return render.Root(
            child = render.Text("Unable to load news", color = "#ff0000"),
        )

    return render.Root(
        delay = scroll_speed,
        child = render.Marquee(
            height = 32,
            scroll_direction = "vertical",
            offset_start = 32,
            child = render.Column(
                expanded = True,
                children = [
                    # Feed name at top
                    render.Text(
                        content = feed_name,
                        color = colors["header"],
                    ),
                    render.Box(height = 1),
                    # Separator line
                    render.Box(
                        height = 1,
                        color = colors["separator"],
                    ),
                    render.Box(height = 1),
                    # Headline
                    render.WrappedText(
                        content = headline,
                        width = 64,
                        color = colors["headline"],
                    ),
                    render.Box(height = 1),
                    # Description
                    render.WrappedText(
                        content = description,
                        width = 64,
                        color = colors["desc"],
                    ),
                ],
            ),
        ),
    )

def get_feed_content(url):
    """Fetch and parse RSS feed content with caching.

    Args:
      url: RSS feed URL to fetch content from

    Returns:
      tuple: (headline, description) or (None, None) on error
    """
    cached = cache.get(url)
    if cached != None:
        if cached == "ERROR":  # Special marker for cached errors
            return (None, None)
        parts = cached.split("||||")
        if len(parts) >= 6:
            headlines = [parts[i] for i in range(0, len(parts), TOP_N_HEADLINES - 1)]
            descriptions = [parts[i] for i in range(1, len(parts), TOP_N_HEADLINES - 1)]
            return get_random_pair(headlines, descriptions)

    headlines, descriptions = fetch_and_parse_feed(url)
    if headlines == None:
        cache.set(url, "ERROR", ttl_seconds = CACHE_ERROR_TTL_SECONDS)
        return (None, None)

    cache_parts = []
    for i in range(TOP_N_HEADLINES):
        cache_parts.extend([headlines[i], descriptions[i]])
    cache_content = "||||".join(cache_parts)
    cache.set(url, cache_content, ttl_seconds = CACHE_TTL_SECONDS)

    return get_random_pair(headlines, descriptions)

def try_other_feeds(current_feed_name, selected_feeds):
    """Try other feeds if current feed fails.

    Args:
      current_feed_name: Name of the failed feed
      selected_feeds: Dictionary of feed name to feed URL

    Returns:
      tuple: (headline, description) or (None, None) if all feeds fail
    """
    for feed_name, feed_url in selected_feeds.items():
        if feed_name != current_feed_name:
            headline, description = get_feed_content(feed_url)
            if headline and description:
                return (headline, description)

    return (None, None)

def fetch_and_parse_feed(url):
    """Fetch and parse RSS feed content.

    Args:
      url: RSS feed URL to fetch and parse

    Returns:
      tuple: (headlines, descriptions) lists or (None, None) on error
    """
    resp = http.get(url)

    if resp.status_code != 200:
        return (None, None)

    feed = xpath.loads(resp.body())
    headlines = feed.query_all("//item/title")
    descriptions = feed.query_all("//item/description")

    if len(headlines) < TOP_N_HEADLINES or len(descriptions) < TOP_N_HEADLINES:
        return (None, None)

    return (headlines, descriptions)

def get_random_pair(headlines, descriptions):
    """Get a random headline/description pair from the lists.

    Args:
      headlines: List of headlines to choose from
      descriptions: List of descriptions to choose from

    Returns:
      tuple: (headline, description) at random index
    """
    idx = random.number(0, TOP_N_HEADLINES - 1)
    return (headlines[idx], descriptions[idx])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "feed1",
                name = "First Feed",
                desc = "Choose your first news feed",
                icon = "newspaper",
                options = [
                    schema.Option(display = name, value = name)
                    for name in AVAILABLE_FEEDS.keys()
                ],
                default = "WSJ US News",
            ),
            schema.Dropdown(
                id = "feed2",
                name = "Second Feed",
                desc = "Choose your second news feed",
                icon = "newspaper",
                options = [
                    schema.Option(display = name, value = name)
                    for name in AVAILABLE_FEEDS.keys()
                ],
                default = "WSJ World News",
            ),
            schema.Dropdown(
                id = "feed3",
                name = "Third Feed",
                desc = "Choose your third news feed",
                icon = "newspaper",
                options = [
                    schema.Option(display = name, value = name)
                    for name in AVAILABLE_FEEDS.keys()
                ],
                default = "NYT Home Page",
            ),
            schema.Color(
                id = "header_color",
                name = "Feed Name Color",
                desc = "Color for the feed name header",
                icon = "paintbrush",
                default = DEFAULT_COLORS["header"],
            ),
            schema.Color(
                id = "headline_color",
                name = "Headline Color",
                desc = "Color for news headlines",
                icon = "paintbrush",
                default = DEFAULT_COLORS["headline"],
            ),
            schema.Color(
                id = "desc_color",
                name = "Description Color",
                desc = "Color for news descriptions",
                icon = "paintbrush",
                default = DEFAULT_COLORS["desc"],
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll Speed",
                desc = "Speed of text scrolling",
                icon = "gear",
                default = "75",
                options = [
                    schema.Option(
                        display = "Faster",
                        value = "50",
                    ),
                    schema.Option(
                        display = "Normal",
                        value = "75",
                    ),
                    schema.Option(
                        display = "Slower",
                        value = "100",
                    ),
                ],
            ),
        ],
    )
