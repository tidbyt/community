"""
Applet: Mastodon Counter
Summary: Shows your follower count
Description: Shows how many followers you've got on Mastodon. If you want, it can even promote your Mastodon handle and encourage people to follow you.
Author: meejle
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

MASTODON_ICON = base64.decode("""
R0lGODlhEgAQAMQAAIyN/1tc/3l6/97e/+Xl//r6/1NU//Dw/9ra/83N/9TV//39/2Fi/+vr/7u8/2pr/5KT/7Ky/5qb//X1/8bG/66v/7a3/15g/1dY/9DQ/09Q/3Bx/5+g/6Ki/2Nk/////yH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjMuMyAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6REUyMTVGMUQ3NTk4MTFFREFENjk5ODhCODI4NzQyMDkiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6REUyMTVGMUU3NTk4MTFFREFENjk5ODhCODI4NzQyMDkiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpERTIxNUYxQjc1OTgxMUVEQUQ2OTk4OEI4Mjg3NDIwOSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpERTIxNUYxQzc1OTgxMUVEQUQ2OTk4OEI4Mjg3NDIwOSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovq6ejn5uXk4+Lh4N/e3dzb2tnY19bV1NPS0dDPzs3My8rJyMfGxcTDwsHAv769vLu6ubi3trW0s7KxsK+urayrqqmop6alpKOioaCfnp2cm5qZmJeWlZSTkpGQj46NjIuKiYiHhoWEg4KBgH9+fXx7enl4d3Z1dHNycXBvbm1sa2ppaGdmZWRjYmFgX15dXFtaWVhXVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj08Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQQDAgEAACH5BAAAAAAALAAAAAASABAAAAWtoMcEgKMMRDoolMRcXnxFX23fX/bEHlcvg8zhU1AoCjUHb1CrBDQbAsRgACAPPGSDIcgAPIKExED5LHg1BIaGMFQ+g3WNt/ioLXB5nHaOTewYeAMXgnIFPEMIGjQFDX8DGm8TPAQfBAAJOA2YdjwKOKA1EDwONgV1NwtSATwQNgoCEBISEAACHqw8Hp9EAAEBFw8PFwy6HsEZPw0EQx25xhcXEBQEEwcDFRvFuiEAOw==
""")

DEFAULT_SERVER = "server_unset"
DEFAULT_API_KEY = "api_key_unset"

def instanceError():
    return render.Root(
        delay = 0,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 18,
                    color = "#6364ff",
                    child = render.Row(
                        expanded = True,
                        children = [
                            render.Image(
                                width = 18,
                                height = 16,
                                src = MASTODON_ICON,
                            ),
                            render.WrappedText("MASTODON FOLLOWERS"),
                        ],  #children
                    ),  #render.Row
                ),  #render.Box
                render.Box(
                    width = 64,
                    height = 14,
                    color = "#000000",
                    child = render.Row(
                        expanded = True,
                        children = [
                            render.Marquee(
                                width = 64,
                                offset_start = 64,
                                child = render.Text(
                                    font = "6x13",
                                    content = "Something's up with your Mastodon instance or API key. Check your settings in the Tidbyt mobile app.",
                                ),
                            ),
                        ],  #children
                    ),  #render.Row
                ),  #render.Box
            ],  #children
        ),  #render.Column
    )  #render.Root

def connectionError():
    return render.Root(
        delay = 0,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 18,
                    color = "#6364ff",
                    child = render.Row(
                        expanded = True,
                        children = [
                            render.Image(
                                width = 18,
                                height = 16,
                                src = MASTODON_ICON,
                            ),
                            render.WrappedText("MASTODON FOLLOWERS"),
                        ],  #children
                    ),  #render.Row
                ),  #render.Box
                render.Box(
                    width = 64,
                    height = 14,
                    color = "#000000",
                    child = render.Row(
                        expanded = True,
                        children = [
                            render.Marquee(
                                width = 64,
                                offset_start = 64,
                                child = render.Text(
                                    font = "6x13",
                                    content = "We couldn't reach Mastodon. If you're sure your settings are correct, your instance might be having issues.",
                                ),
                            ),
                        ],  #children
                    ),  #render.Row
                ),  #render.Box
            ],  #children
        ),  #render.Column
    )  #render.Root

def main(config):
    theapi = "https://%s/api/v1/accounts/verify_credentials" % config.str("instance", DEFAULT_SERVER)
    stringapikey = config.str("apikey", DEFAULT_API_KEY)
    stringserver = config.str("instance", DEFAULT_SERVER)
    headers = {"Authorization": "Bearer " + stringapikey}

    count_cached = cache.get("cached_count")
    name_cached = cache.get("cached_name")
    plusone_cached = cache.get("cached_plusone")

    if count_cached != None and name_cached != None:
        followercount = str(count_cached)
        finalusername = str(name_cached)
        plusone = str(plusone_cached)
    else:
        if stringserver == "server_unset":
            return instanceError()
        if stringapikey == "api_key_unset":
            return instanceError()
        GET_MASTODON = http.get(theapi, headers = headers)
        if GET_MASTODON.status_code != 200:
            return connectionError()
        GET_FOLLOWERS = GET_MASTODON.json()["followers_count"]
        GET_USERNAME = GET_MASTODON.json()["username"]
        finalusername = str(GET_USERNAME)
        cache.set("cached_name", finalusername, ttl_seconds = 900)
        removedecimal = int(GET_FOLLOWERS)
        extraone = removedecimal + +1
        followercount = str(removedecimal)
        cache.set("cached_count", followercount, ttl_seconds = 900)
        plusone = str(extraone)
        cache.set("cached_plusone", plusone, ttl_seconds = 900)

    if config.bool("pronoun"):
        thepronoun = "We're"
    else:
        thepronoun = "I'm"

    if config.bool("scrolly"):
        themessage = followercount + " and counting! Want to be number " + plusone + "? " + thepronoun + " @" + finalusername + "@" + stringserver
    else:
        themessage = followercount

    return render.Root(
        delay = 0,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 18,
                    color = "#6364ff",
                    child = render.Row(
                        expanded = True,
                        children = [
                            render.Image(
                                width = 18,
                                height = 16,
                                src = MASTODON_ICON,
                            ),
                            render.WrappedText("MASTODON FOLLOWERS"),
                        ],  #children
                    ),  #render.Row
                ),  #render.Box
                render.Box(
                    width = 64,
                    height = 14,
                    color = "#000000",
                    child = render.Row(
                        expanded = True,
                        children = [
                            render.Marquee(
                                width = 64,
                                offset_start = 64,
                                child = render.Text(
                                    font = "6x13",
                                    content = themessage,
                                ),
                            ),
                        ],  #children
                    ),  #render.Row
                ),  #render.Box
            ],  #children
        ),  #render.Column
    )  #render.Root

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "instance",
                name = "Your Mastodon instance",
                desc = "The Mastodon server you use, e.g. ohai.social or mastodon.social",
                icon = "mastodon",
            ),
            schema.Text(
                id = "apikey",
                name = "Your access token",
                desc = "To get this, log into Mastodon (you'll probably want to do this on your desktop browser) then go to Preferences, Development, and add a 'New Application'. The details don't really matter but, for safety's sake, only select 'read' in the list of Scopes.",
                icon = "key",
            ),
            schema.Toggle(
                id = "scrolly",
                name = "Show Lovely Scrolly Message™",
                desc = "Would you like to promote your Mastodon username and encourage more people to follow you? If not, we'll just show the number of followers.",
                icon = "faceSmile",
            ),
            schema.Toggle(
                id = "pronoun",
                name = "Use plural pronouns",
                desc = "If enabled, your Lovely Scrolly Message™ will say 'we're' instead of 'I'm'.",
                icon = "peopleGroup",
            ),
        ],
    )
