"""
Applet: WaniKani Reminder
Summary: WaniKani reminders
Description: Provides lesson and review counts for WaniKani.
Author: Bardiches
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Config
API_TOKEN_ID = "api_token"
API_TOKEN_NAME = "API Token"
API_TOKEN_DESC = "Your WaniKani API token, found in your WaniKani settings."
API_TOKEN_ICON = "key"

# WaniKani API
WK_SUMMARY_URL = "https://api.wanikani.com/v2/summary"
WK_AUTHORIZATION_HEADER = "Bearer %s"
WK_TTL = 300
DEFAULT_WK_DATA = {
    "lesson_count": 69,
    "review_count": 420,
    "next_review": None,
}

# Display Colors
LESSON_COLOR = "#ff00aa"
REVIEW_COLOR = "#00aaff"
ERROR_COLOR = "#ff5d5d"
MARQUEE_COLOR = "#5dc9ff33"

# Display Fonts
LARGE_FONT = "6x13"
SMALL_FONT = "tom-thumb"

# Display Text
WANIKANI_TITLE_TEXT = "WaniKani"
LESSONS_TITLE_TEXT = "Lessons"
REVIEWS_TITLE_TEXT = "Reviews"
NEXT_REVIEW_TEXT = "%s available %s"
ERROR_SUFFIX_TEXT = "error: "
NO_REVIEWS_TEXT = "no new reviews in 24 hours"
NO_API_TOKEN_ERROR_TEXT = "please set your API token"
API_ERROR_TEXT = "your API token is malformed or there is an issue with the WaniKani API"
NEW_REVIEW_SINGULAR = "new review"
NEW_REVIEW_PLURAL = "new reviews"
ERROR_COUNT_TEXT = "?"

def get_wk_summary(headers):
    return http.get(WK_SUMMARY_URL, headers = headers, ttl_seconds = WK_TTL).json().get("data")

def get_next_wk_review(reviews):
    for review in reviews[1:]:
        new_reviews = len(review["subject_ids"])
        if new_reviews > 0:
            return [new_reviews, review["available_at"]]
    return None

def get_wk_data(api_token):
    if api_token == None:
        return dict({"error": NO_API_TOKEN_ERROR_TEXT}, **DEFAULT_WK_DATA)

    headers = {"AUTHORIZATION": WK_AUTHORIZATION_HEADER % api_token}
    summary = get_wk_summary(headers)

    if summary == None:
        return dict({"error": API_ERROR_TEXT}, **DEFAULT_WK_DATA)

    next_review = get_next_wk_review(summary["reviews"])

    return {
        "lesson_count": len(summary.get("lessons", {})[0].get("subject_ids", [])),
        "review_count": len(summary.get("reviews", {})[0].get("subject_ids", [])),
        "next_review": next_review,
    }

def format_count(count):
    int_count = max(0, int(count))
    if int_count < 1000:
        return str(int_count)

    return "%dk" % min(99, int_count // 1000)

def count_box(title, count, color, has_error = False):
    formatted_count = ERROR_COUNT_TEXT if has_error else format_count(count)
    return render.Column(
        cross_align = "center",
        children = [
            render.Text(title, offset = -1, font = SMALL_FONT),
            render.Box(
                child = render.Text(formatted_count, font = LARGE_FONT, color = "#000"),
                width = 32,
                height = 11,
                color = color,
            ),
        ],
    )

def review_display(wk_data, has_error = False):
    return render.Row(
        children = [
            count_box(LESSONS_TITLE_TEXT, wk_data["lesson_count"], LESSON_COLOR, has_error),
            count_box(REVIEWS_TITLE_TEXT, wk_data["review_count"], REVIEW_COLOR, has_error),
        ],
    )

def next_review_text(next_review):
    if next_review == None:
        return NO_REVIEWS_TEXT

    humanized_time = humanize.time(time.parse_time(next_review[1]))

    return NEXT_REVIEW_TEXT % (humanize.plural(next_review[0], NEW_REVIEW_SINGULAR, NEW_REVIEW_PLURAL), humanized_time)

def bottom_marquee(text, has_error = False):
    return render.Box(
        height = 5,
        child = render.Marquee(
            width = 64,
            align = "start",
            child = render.Row(
                children = [
                    render.Text(ERROR_SUFFIX_TEXT, height = 5, offset = -1, font = SMALL_FONT, color = ERROR_COLOR) if has_error else None,
                    render.Text(text, height = 5, offset = -1, font = SMALL_FONT),
                ],
            ),
        ),
        color = MARQUEE_COLOR,
    )

def render_app(wk_data):
    error = wk_data.get("error")
    has_error = error != None
    reviews = review_display(wk_data, has_error)
    marquee = bottom_marquee(error, True) if has_error else bottom_marquee(next_review_text(wk_data["next_review"]))

    return render.Root(
        child = render.Column(
            main_align = "end",
            cross_align = "center",
            expanded = True,
            children = [
                render.Text(
                    WANIKANI_TITLE_TEXT,
                    height = 8,
                    offset = -2,
                    font = LARGE_FONT,
                ),
                reviews,
                marquee,
            ],
        ),
    )

def main(config):
    wk_data = get_wk_data(config.str(API_TOKEN_ID))
    return render_app(wk_data)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = API_TOKEN_ID,
                name = API_TOKEN_NAME,
                desc = API_TOKEN_DESC,
                icon = API_TOKEN_ICON,
            ),
        ],
    )
