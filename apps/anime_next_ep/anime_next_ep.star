"""
Applet: Anime Next Ep
Summary: Anime next episode
Description: Tells when the next episode of an anime is via anilist.
Author: brianmakesthings
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ANILIST_ENDPOINT = "https://graphql.anilist.co"
DEFAULT_ANIME_ID = 21  # One Piece

def main(config):
    unsanitized_anime_id = config.str("anime_id", str(DEFAULT_ANIME_ID))
    id = DEFAULT_ANIME_ID
    if is_numeric(unsanitized_anime_id):
        id = int(unsanitized_anime_id)

    airing_info = fetch_airing_info(id)

    if airing_info == None:
        return not_found(id)

    media = airing_info["data"]["Media"]
    title = media["title"]["romaji"]
    cover_url = media["coverImage"]["medium"]
    next_episode = media.get("nextAiringEpisode")
    status = media["status"]  # Get the status field

    # Full-width title at the top
    title_display = render.Marquee(
        child = render.Text(title, font = "tb-8", color = "#FFFFFF"),
        scroll_direction = "horizontal",
        width = 64,  # Full width
    )

    return render.Root(
        child = render.Column(
            # Stack title + image/text row
            children = [
                title_display,  # Top: Full-width title
                render.Row(
                    # Bottom: Image + Episode Info
                    children = [
                        render_cover(cover_url),
                        next_episode_info(next_episode, status),  # Right: Airing Info OR "Finished Airing"
                    ],
                ),
            ],
        ),
    )

def is_numeric(string):
    return len(re.findall("\\d+", string)) > 0

def fetch_image(image_url):
    response = http.get(image_url)

    if response.status_code != 200:
        return None  # Fail gracefully if image request fails

    return response.body()

def render_cover(image_url):
    cover_image = fetch_image(image_url)
    if cover_image == None:
        return None
    return render.Padding(
        child = render.Image(
            # Left: Anime Cover Image
            width = 18,
            src = cover_image,
        ),
        pad = (0, 0, 1, 0),
    )

def not_found(id):
    return render.Root(
        child = render.WrappedText("Anime ID {} not found".format(id), color = "#FF0000"),
    )

def next_episode_info(next_episode, status):
    if status == "FINISHED":
        return render.WrappedText("Finished Airing", font = "tom-thumb", color = "#FF0000")  # Red text

    if next_episode == None:
        return render.WrappedText("Next Air Date Unknown", font = "tom-thumb", color = "#FFFF00")  # Yellow text

    # If still airing, display next episode info
    episode = int(next_episode["episode"])
    nextAirDate = time.from_timestamp(int(next_episode["airingAt"]))
    humanized_time = humanize.time(nextAirDate)

    episode_text = "Ep {}: {}".format(episode, humanized_time)

    return (
        render.Marquee(
            child = render.WrappedText(episode_text, font = "tom-thumb", color = "#FFA500"),
            scroll_direction = "vertical",
            height = 32,
        )
    )

def fetch_airing_info(anime_id):
    query = {
        "query": """
        query ($id: Int) {
          Media(id: $id, type: ANIME) {
            title {
              romaji
            }
            coverImage {
              medium
            }
            nextAiringEpisode {
              episode
              airingAt
            }
            status
          }
        }
        """,
        "variables": {"id": anime_id},
    }

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    response = http.post(ANILIST_ENDPOINT, headers = headers, json_body = query, ttl_seconds = 3600)

    if response.status_code != 200:
        return None

    return response.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "anime_id",
                name = "id",
                desc = "Anilist Anime ID ex. 21",
                icon = "tv",
            ),
        ],
    )
