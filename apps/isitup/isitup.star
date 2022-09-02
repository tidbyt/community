load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("cache.star", "cache")
load("humanize.star", "humanize")
load("time.star", "time")

DEFAULT_TIMEZONE = "Pacific/Auckland"
DEFAULT_URL = ""
DEFAULT_NAME = ""

# config parameters
P_LOCATION = "location"
P_URL = "url"
P_NAME = "name"
P_TTL = "ttl"
P_EXPECT_VERSION = "expect_version"

# cache keys
CK_LASTURL = "url"
CK_VERSIONCHECK = "versioncheck"
CK_LASTCHECK = "last_checked"
CK_RESPONSECODE = "last_response"
CK_VERSION = "version"
CK_FAIL = "failed"

# response properties
R_NAME = "name"
R_URL = "url"
R_FAILED = "failed"
R_RESPONSECODE = "responsecode"
R_VERSION = "version"
R_LASTCHECK = "lastcheck"

FONT_TITLE = "6x13"
FONT_DETAIL = "tom-thumb"

COLOR_TITLE = "#ababab"
COLOR_FAIL = "#330000"
COLOR_DETAIL = "#ffffff"
COLOR_OK = "#003300"

TTL_FREQUENT = "freq"
TTL_NORMAL = "norm"
TTL_LOW = "low"

TTL_VALUES = {
    TTL_FREQUENT: 60,
    TTL_NORMAL: 240,
    TTL_LOW: 600,
}

def main(config):
    response = make_request(config)

    if response == None:
        return render.Root(
            child = render.Box(
                color = COLOR_FAIL,
                child = render.WrappedText(content = "No Configuration", font = FONT_DETAIL, color = COLOR_DETAIL),
            ),
        )
    elif response[R_FAILED]:
        return render.Root(
            child = render.Box(
                color = COLOR_FAIL,
                child =
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(content = response[R_NAME], font = FONT_TITLE, color = COLOR_TITLE),
                            render.Text(content = "Failed: %s " % response[R_RESPONSECODE], font = FONT_DETAIL, color = COLOR_DETAIL),
                        ],
                    ),
            ),
        )

    else:
        return render.Root(
            child = render.Box(
                color = COLOR_OK,
                child =
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(content = response[R_NAME], font = FONT_TITLE, color = COLOR_TITLE),
                            render.Text(content = "OK", font = FONT_DETAIL, color = COLOR_DETAIL),
                            render.Text(content = response[R_VERSION], font = FONT_DETAIL, color = COLOR_DETAIL),
                        ],
                    ),
            ),
        )

def make_request(config):
    # get some config
    url = config.get(P_URL)
    checkversion = config.get(P_EXPECT_VERSION)

    # check the config is valid
    if url != None:
        url = url.strip()

    if url == None or url == "":
        print("URL Missing")
        return None

    # is the cache still valid
    vc = cache.get(CK_VERSIONCHECK)
    cachevalid = cache.get(CK_LASTURL) == url and checkversion == ("%s" % vc)

    if not cachevalid:
        ttl = TTL_VALUES[config.get(P_TTL)]

        # fill the cache
        rep = http.get(url)
        cache.set(CK_RESPONSECODE, ("%s" % rep.status_code), ttl_seconds = ttl)
        cache.set(CK_VERSION, "", ttl_seconds = ttl)
        cache.set(CK_VERSIONCHECK, "0", ttl_seconds = ttl)

        if rep.status_code >= 200 and rep.status_code < 300:
            cache.set(CK_FAIL, "0", ttl_seconds = ttl)

            # try to get the version
            if checkversion == "true":
                cache.set(CK_VERSIONCHECK, "1", ttl_seconds = ttl)

                body = rep.body().lstrip()
                if body[0] == "{":
                    json = rep.json()
                    if json != None:
                        version = json["version"]
                        cache.set(CK_VERSION, version, ttl_seconds = ttl)
        else:
            cache.set(CK_FAIL, "1", ttl_seconds = ttl)

        cache.set(CK_LASTURL, url, ttl_seconds = ttl)
        cache.set(CK_LASTCHECK, get_time_in_zone(config), ttl_seconds = ttl)

    # fill the response from the cache
    response = {
        R_URL: cache.get(CK_LASTURL),
        R_NAME: config.get(P_NAME).strip(),
        R_FAILED: (cache.get(CK_FAIL) == "1"),
        R_RESPONSECODE: cache.get(CK_RESPONSECODE),
        R_VERSION: cache.get(CK_VERSION),
        R_LASTCHECK: cache.get(CK_LASTCHECK),
    }

    return response

def get_time_in_zone(config):
    location = config.get(P_LOCATION)
    location = json.decode(location) if location else {}
    timezone = location.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))

    when_time = time.now().in_location(timezone)
    return humanize.time_format("EEE MMM d HH:mm", when_time)

def get_schema():
    ttlOptions = [
        schema.Option(display = "Frequent (%s secs)" % TTL_VALUES[TTL_FREQUENT], value = TTL_FREQUENT),
        schema.Option(display = "Normal (%s secs)" % TTL_VALUES[TTL_NORMAL], value = TTL_NORMAL),
        schema.Option(display = "Low (%s secs)" % TTL_VALUES[TTL_LOW], value = TTL_LOW),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = P_LOCATION,
                name = "Location",
                desc = "Location defining the timezone.",
                icon = "locationDot",
            ),
            schema.Text(
                id = P_NAME,
                name = "Site Name",
                icon = "input-text",
                desc = "Provide a nice name for this site.",
                default = DEFAULT_NAME,
            ),
            schema.Text(
                id = P_URL,
                name = "URL",
                icon = "input-text",
                desc = "Specify the URL of the web site to check.",
                default = DEFAULT_URL,
            ),
            schema.Dropdown(
                id = P_TTL,
                icon = "",
                name = "Scan Frequency",
                desc = "How often if the site checked.",
                options = ttlOptions,
                default = TTL_NORMAL,
            ),
            schema.Toggle(
                id = P_EXPECT_VERSION,
                name = "Expect Version",
                desc = "Does the response include a JSON formatted version value?",
                icon = "toggle-on",
                default = False,
            ),
        ],
    )
