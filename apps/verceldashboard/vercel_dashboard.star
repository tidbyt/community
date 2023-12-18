"""
Applet: Vercel Dashboard
Summary: Monitor Vercel information
Description: Monitor your Vercel deployments and view important information.
Author: Chase Roossin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_DEPLOYMENT_URL = "https://api.vercel.com/v6/deployments"
CACHE_KEY = "vercel-cache-{}"
SPACE = "   "

# Config
CONFIG_API_KEY = "api-key"
CONFIG_CLOCK_FORMAT = "time-format"
CONFIG_TIMEZONE = "time-zone"

def main(config):
    apikey = config.str(CONFIG_API_KEY)
    showIn24hr = config.bool(CONFIG_CLOCK_FORMAT, True)

    if apikey == None:
        return render.Root(
            child = twoLine("No API", "Key Found"),
        )

    formattedCacheKey = CACHE_KEY.format(hash.sha1(apikey))
    cached_data = cache.get(formattedCacheKey)

    # Check for cached data
    if cached_data != None:
        print("Hit! Displaying cached data.")
        data = json.decode(cached_data)
    else:
        print("Miss cache! Calling Vercel")
        rep = http.get(
            BASE_DEPLOYMENT_URL,
            headers = {"Authorization": "Bearer " + apikey, "Accept": "application/json"},
        )

        # Ensure valid response
        if rep.status_code != 200:
            return render.Root(
                child = twoLine("Vercel Error", "Status: " + str(rep.status_code)),
            )

        data = rep.json()

        # Update cache
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(formattedCacheKey, json.encode(data), ttl_seconds = 240)

    # Grab latest deployment
    deployment = data["deployments"][0]
    project = deployment["name"]
    state = deployment["state"]  # Looking for either READY or ERROR
    commitMsg = deployment["meta"]["githubCommitMessage"]
    author = deployment["meta"]["githubCommitAuthorName"]

    createdAt = time.from_timestamp(int(deployment["created"] / 1000)).in_location(config.str(CONFIG_TIMEZONE))
    createdAtDate = createdAt.format("Jan. 2")

    if showIn24hr:
        createdAtTime = createdAt.format("15:04")
    else:
        createdAtTime = createdAt.format("3:04 PM")

    if state == "READY":
        subheader = "Success at"
        color = "#3CB043"
    else:
        subheader = "Failure at"
        color = "#D30000"

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 64,
                            height = 9,
                            color = "#243a5e",
                            child = render.Text(content = "Vercel", font = "CG-pixel-4x5-mono"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 64,
                            height = 10,
                            child = render.Marquee(
                                width = 64,
                                child = render.Row(
                                    children = [
                                        render.Text(content = commitMsg, color = color),
                                        render.Text(content = SPACE + project + SPACE + author, color = "#636363"),
                                    ],
                                ),
                            ),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 6, color = "#243a5e", child = render.Text(content = subheader, font = "CG-pixel-3x5-mono")),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 7, color = "#243a5e", child = render.Text(content = createdAtDate + " " + createdAtTime, font = "CG-pixel-3x5-mono")),
                    ],
                ),
            ],
        ),
    )

def twoLine(line1, line2):
    return render.Box(
        width = 64,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(content = line1, font = "CG-pixel-4x5-mono"),
                render.Text(content = line2, font = "CG-pixel-4x5-mono", height = 10),
            ],
        ),
    )

def get_schema():
    timezones = [
        schema.Option(display = "Hawaii (-10)", value = "Pacific/Honolulu"),
        schema.Option(display = "Alaska (-9)", value = "America/Anchorage"),
        schema.Option(display = "Pacific (-8)", value = "America/Los_Angeles"),
        schema.Option(display = "Mountain (-7)", value = "America/Denver"),
        schema.Option(display = "Central (-6)", value = "America/Chicago"),
        schema.Option(display = "Eastern (-5)", value = "America/New_York"),
        schema.Option(display = "Atlantic (-4)", value = "America/Halifax"),
        schema.Option(display = "Newfoundland (-3.5)", value = "America/St_Johns"),
        schema.Option(display = "Brazil (-3)", value = "America/Sao_Paulo"),
        schema.Option(display = "UTC (0)", value = "UTC"),
        schema.Option(display = "Central Europe (+1)", value = "Europe/Berlin"),
        schema.Option(display = "Eastern Europe (+2)", value = "Europe/Moscow"),
        schema.Option(display = "India (+5.5)", value = "Asia/Kolkata"),
        schema.Option(display = "China (+8)", value = "Asia/Shanghai"),
        schema.Option(display = "Japan (+9)", value = "Asia/Tokyo"),
        schema.Option(display = "Australia Eastern (+10)", value = "Australia/Sydney"),
        schema.Option(display = "New Zealand (+12)", value = "Pacific/Auckland"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = CONFIG_API_KEY,
                name = "API Key",
                desc = "Your Vercel API key generated via the Vercel dashboard",
                icon = "key",
            ),
            schema.Dropdown(
                id = CONFIG_TIMEZONE,
                name = "Timezone",
                desc = "Choose your timezone (default UTC)",
                icon = "globe",
                default = "UTC",
                options = timezones,
            ),
            schema.Toggle(
                id = CONFIG_CLOCK_FORMAT,
                name = "24-hr",
                desc = "Show time in 24hr",
                icon = "clock",
                default = True,
            ),
        ],
    )
