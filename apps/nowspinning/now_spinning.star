"""
Applet: Now Spinning
Summary: Showcase your music
Description: Displays the name and cover of an artist's album. Not connected to any music service, you need to manually change the album. Type the album name to view available options, include the artist's name to help refine results.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

RECORD_ICON = base64.decode("""
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
""")

DEFAULT_ALBUM = json.encode({"display": "none", "value": "none"})
DEFAULT_FONT_NAME = "tb-8"
DEFAULT_HEADER_COLOR = "#1db954"
DEFAULT_ALBUM_COLOR = "#e833f2"
DEFAULT_ARTIST_COLOR = "#ffffff"
DEFAULT_HIDE_APP = False

DEFAULT_USER_AGENT = "Tidbyt/1.0.0 ( https://www.tidbyt.dev )"

COVER_CACHE_TTL = 86400  # 1 day

DEBUG = False

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        widget: Root widget tree.
    """

    album_font_name = config.str("album_font_name", DEFAULT_FONT_NAME)
    artist_font_name = config.str("artist_font_name", DEFAULT_FONT_NAME)
    header_color = config.str("header_color", DEFAULT_HEADER_COLOR)
    album_color = config.str("album_color", DEFAULT_ALBUM_COLOR)
    artist_color = config.str("artist_color", DEFAULT_ARTIST_COLOR)
    album = json.decode(config.get("album", DEFAULT_ALBUM))
    hide_app = config.bool("hide_app", DEFAULT_HIDE_APP)
    dprint(album)

    # hides the app
    if hide_app:
        return []

    # if user has not selected an album yet, render default view
    if album["value"] == "none":
        return render_app(RECORD_ICON, "Select", "#fff", "album!", "#fff", header_color, DEFAULT_FONT_NAME, DEFAULT_FONT_NAME)

    # if there was an error, render default view
    if album["value"] == "error":
        return render_app(RECORD_ICON, "Error", "#f00", "try again", "#ff0", header_color, DEFAULT_FONT_NAME, DEFAULT_FONT_NAME)

    # split album, artist and cover url from config value
    album_name = album["value"].split("|")[0]
    artist_name = album["value"].split("|")[1]
    cover_url = album["value"].split("|")[2]
    dprint("{} by {} ({})".format(album_name, artist_name, cover_url))

    # get cover
    cover = get_cover(cover_url)

    # check if there was an error getting the cover
    if cover == None:
        cover = RECORD_ICON

    return render_app(cover, album_name, album_color, artist_name, artist_color, header_color, album_font_name, artist_font_name)

def get_cover(cover_url):
    """Retrieves the cover image for an album.

    Args:
        cover_url (str): URL of the cover image.

    Returns:
        blob: Retrieved image content or None if not found/error.
    """

    # if there was no cover, return the default spinning record icon
    if cover_url == "none":
        return RECORD_ICON

    # fetch cover from url
    dprint("Getting cover info: %s" % cover_url)
    res = http.get(cover_url, ttl_seconds = COVER_CACHE_TTL, headers = {
        "Accept": "application/json",
        "User-Agent": DEFAULT_USER_AGENT,
    })

    # if error, return default spinning record icon
    if res.status_code != 200:
        print("Error getting cover info, status %d" % res.status_code)
        dprint(res.body())
        return RECORD_ICON

    # get data
    data = res.json()

    # check if there are images
    if not "images" in data:
        dprint("No images field")
        return RECORD_ICON

    if (len(data["images"]) == 0):
        dprint("images field is an empty array")
        return RECORD_ICON

    # check if there is a small thumbnail
    if not "thumbnails" in data["images"][0]:
        dprint("No thumbnails field")
        return RECORD_ICON

    if not "small" in data["images"][0]["thumbnails"]:
        dprint("No small field inside thumbnails")
        return RECORD_ICON

    dprint("Getting small thumbnail from %s" % data["images"][0]["thumbnails"]["small"])
    res = http.get(data["images"][0]["thumbnails"]["small"], ttl_seconds = COVER_CACHE_TTL, headers = {
        "User-Agent": DEFAULT_USER_AGENT,
    })

    # if error, return default spinning record icon
    if res.status_code != 200:
        print("Error getting cover image, status %d" % res.status_code)
        dprint(res.body())
        return RECORD_ICON

    return res.body()

def render_header(header_color):
    """Renders the app header widgets.

    Args:
        header_color (str): The hex color for the header text.

    Returns:
        widget: Widgets to render the app header.
    """

    return render.Box(
        width = 64,
        height = 6,
        child = render.Text("now spinning", font = "tom-thumb", color = header_color),
    )

def render_app(cover, album, album_color, artist, artist_color, header_color, album_font_name, artist_font_name):
    """Renders the app widget structure.

    Args:
        cover (blob): The album's cover art.
        album (str): The album's name.
        album_color (str): The hex color for the album name.
        artist (str): The artist' name.
        artist_color (str): The hex color for the artist name.
        header_color (str): The hex color for the app header.

    Returns:
        widget: Root widget structure.
    """

    return render.Root(
        delay = 80,
        child = render.Column(
            children = [
                render_header(header_color),
                render.Box(width = 64, height = 1, color = "#fff"),
                render.Padding(
                    pad = 1,
                    child = render.Row(
                        children = [
                            render.Image(height = 23, src = cover),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 39,
                                            child = render.Text(album, color = album_color, font = album_font_name),
                                        ),
                                        render.Marquee(
                                            width = 39,
                                            child = render.Text(artist, color = artist_color, font = artist_font_name),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    """Setup the schema for the configuration screen.

    Returns:
        schema: Schema for the configuration screen.
    """

    font_options = [
        schema.Option(display = "Small", value = "tom-thumb"),
        schema.Option(display = "Medium", value = DEFAULT_FONT_NAME),
        schema.Option(display = "Large", value = "Dina_r400-6"),
        schema.Option(display = "Extra Large", value = "6x13"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "album",
                name = "Album",
                desc = "Name of the album (add artist to refine).",
                icon = "compactDisc",
                handler = album_search,
            ),
            schema.Color(
                id = "header_color",
                name = "Header color",
                desc = "Color of the app name.",
                icon = "brush",
                default = DEFAULT_HEADER_COLOR,
            ),
            schema.Color(
                id = "album_color",
                name = "Album color",
                desc = "Color of the album name.",
                icon = "brush",
                default = DEFAULT_ALBUM_COLOR,
            ),
            schema.Dropdown(
                id = "album_font_name",
                name = "Album text size",
                desc = "Size of the album name text.",
                icon = "font",
                default = DEFAULT_FONT_NAME,
                options = font_options,
            ),
            schema.Color(
                id = "artist_color",
                name = "Artist color",
                desc = "Color of the artist name.",
                icon = "brush",
                default = DEFAULT_ARTIST_COLOR,
            ),
            schema.Dropdown(
                id = "artist_font_name",
                name = "Artist text size",
                desc = "Size of the artist name text.",
                icon = "font",
                default = DEFAULT_FONT_NAME,
                options = font_options,
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide app",
                desc = "Removes the app from your rotation.",
                icon = "toggleOff",
                default = DEFAULT_HIDE_APP,
            ),
        ],
    )

def album_search(album_name):
    """Searches for albums based on a name.

    Args:
        album_name (str): The album name to search.

    Returns:
        schema.Option[]: List of album options for the user to pick.
    """

    # fake field to signal error to the user
    fake_error_field = schema.Option(display = "ERROR: Please close this screen and try adding the app again.", value = "error")

    # strip spaces
    stripped_name = album_name.strip()

    # we need at least 3 characters to proceed
    if len(stripped_name) < 3:
        return []

    # build url
    url = "https://musicbrainz.org/ws/2/release-group/?query=releasegroup:{}%20AND%20status:official&limit=50&fmt=json".format(humanize.url_encode(stripped_name))
    dprint("Calling %s" % url)
    res = http.get(url, headers = {
        "User-Agent": DEFAULT_USER_AGENT,
    })
    dprint("Response: %d" % res.status_code)

    if res.status_code != 200:
        print("API Error {}: {}".format(res.status_code, res.body()))

        # return the fake field to signal error to the user
        return [fake_error_field]

    # get data
    data = res.json()

    # validate if something was returned
    if not "release-groups" in data:
        dprint("release-groups field not returned")
        return []

    if len(data["release-groups"]) == 0:
        dprint("release-groups array is empty")
        return []

    dprint("Found %d albums" % len(data["release-groups"]))

    # sort by release date, newest first
    sorted_releases = sorted(data["release-groups"], key = get_release_date, reverse = True)

    options = []
    for release in sorted_releases:
        title = release["title"]
        type = release.get("primary-type", "Unknown").capitalize()
        artist = release["artist-credit"][0]["name"]
        date = release.get("first-release-date", "0000")[0:4]
        cover_url = "https://coverartarchive.org/release-group/{}/".format(release["id"])
        options.append(schema.Option(
            display = "{} by {} ({}, {})".format(title, artist, type, date),
            value = "|".join([title, artist, cover_url]),  # concatenate album|artist|cover
        ))

    return options

def get_release_date(release):
    """Returns the year of a release.

    Args:
        release (dict): The release object.
    """
    return release.get("first-release-date", "0000")[0:4]

def dprint(message):
    """Prints messages when in debug mode.

    Args:
        message (str): The message to print.
    """
    if DEBUG:
        print(message)
