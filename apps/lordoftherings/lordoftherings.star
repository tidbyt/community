"""
Applet: LordOfTheRings
Summary: Displays LOTR quotes
Description: Displays random quotes from LOTR trilogy.
Author: Jake Manske
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# using "lordoftherings"
ENCRYPTED_API_KEY = "AV6+xWcE4VltFa9T2uqMvHJJvQmY+pl+upIgaFFPddIeaqFrJOg8lTPlzBnd4jN+EFw9k+ixYNjfzmJSCjYl4NLIw3NTUq96cWO0erM1BTMMh5SsurAc+4R2LZQ2iI+YHAlP5Go0Y5oe1WtMAfv3Zc47AaCh5Xl61QM="

MOVIE_FONT = "CG-pixel-3x5-mono"
MOVIE_COLOR = "#701010"

LOTR_URL = "https://the-one-api.dev/v2"

HTTP_OK = 200

CACHE_TIMEOUT = 600  # ten minutes

def main(config):
    char_id = config.get("character") or RANDOM

    # if character is set to random, choose one at random based on timestamp
    if char_id == RANDOM:
        rand_char = int(time.now().nanosecond / 1000) % len(CHARACTER_LOOKUP)
        char_id = CHARACTER_LOOKUP.keys()[rand_char]

    # see if there is quote info in the cache for that character
    quote_info = cache.get(char_id) or None

    # if there is no quote info in the cache, get it via API
    if quote_info == None:
        api_key = secret.decrypt(ENCRYPTED_API_KEY)
        headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer {0}".format(api_key),
        }
        resp = http.get("https://the-one-api.dev/v2/character/{0}/quote".format(char_id), headers = headers)

        # check the HTTP response code
        # if we fail, send back "shall not pass"
        status_code = resp.status_code
        if (status_code != HTTP_OK):
            char_id = GANDALF_ID
            quote = SHALL_NOT_PASS_QUOTE.format(status_code, resp.json()["message"])
            movie = SHALL_NOT_PASS_MOVIE
        else:
            quotes = resp.json()["docs"]

            # get a "random" quote_id based on the current timestamp
            quote_id = int(time.now().nanosecond / 1000) % len(quotes)

            quote = quotes[quote_id].get("dialog")

            # clean up the quote if necessary, the db is not perfect
            if not quote_has_punctuation(quote):
                quote = quote + "."

            # map it to the right movie
            movie = MOVIE_LOOKUP[quotes[quote_id].get("movie")]

        # save info to dict to serialize to cache if we were successful
        quote_info = {"quote": quote, "movie": movie}

        # cache the quote if we successfully got it from endpoint
        # if we didn't, we will want to just try again
        if (status_code == HTTP_OK):
            cache.set(char_id, json.encode(quote_info), ttl_seconds = CACHE_TIMEOUT)

        print("cache miss, remaining: " + str(resp.headers.get("X-Ratelimit-Remaining")))
    else:
        print("cache hit")
        quote_info = json.decode(quote_info)

    # get the character we are using out of the character metadata dictionary
    character_to_use = CHARACTER_LOOKUP[char_id]

    # render the image
    return render.Root(
        delay = 200,
        child = render.Column(
            main_align = "start",
            children = [
                render.Box(
                    height = 16,
                    width = 64,
                    child = render.Marquee(
                        child = render.WrappedText(
                            content = quote_info.get("quote"),
                            font = "CG-pixel-3x5-mono",
                            linespacing = 1,
                            width = 64,
                        ),
                        height = 16,
                        scroll_direction = "vertical",
                        offset_start = 16,
                        align = "center",
                    ),
                ),
                render.Row(
                    main_align = "start",
                    children = [
                        render.Image(
                            src = character_to_use.Img,
                        ),
                        render.Column(
                            cross_align = "start",
                            children = [
                                render.Text(
                                    content = character_to_use.Name,
                                    font = character_to_use.Font,
                                    color = character_to_use.Color,
                                ),
                                render.WrappedText(
                                    content = quote_info.get("movie"),
                                    font = MOVIE_FONT,
                                    color = MOVIE_COLOR,
                                    linespacing = 1,
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def quote_has_punctuation(quote):
    """make sure the quote ends with some punctuation

    Args:
        quote (string): the quote to check
    """
    if quote.endswith(".") or quote.endswith("!") or quote.endswith("?"):
        return True
    return False

def struct_Char(name, id, font, color, img):
    return struct(Name = name, Id = id, Font = font, Color = color, Img = img)

# failed to ping endpoint quote info
GANDALF_ID = "5cd99d4bde30eff6ebccfea0"
SHALL_NOT_PASS_QUOTE = "HTTP response code {0}: {1}"
SHALL_NOT_PASS_MOVIE = "YOU SHALL NOT PASS"

### images
ARAGORN_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAUVJREFUOBGFkqFLBEEUxr93QbgogkGwGQQFF/wLTDaTeGBbg8VgNBguiE2sJxduk2GN/gParCt4YDeLSTws43xv9w3jOes+ePvevHnfb2ZnRpA2ly6HqlgWEiv46DYWo1EinX5oUbXzgE6x8QzSs0JbfHkodYrR8rg33sGf1SnY3BmkhdmAHGndga2mcesAoNMs1iO0App5FYgI6DSNEaQbEEjppBvwfAfnnDoRzOFrKeMhqrPPcleVjh6POW9ut+BOzs7xOL7EtJfV8PcK8YOyQ+WtXF+s4P4tx/b6GghQca0C9lYL7A6XA8TqBovFnJNJUfx690d5Diw1u/AN1biP7PjLOFj4fMXNaBTG4pvd5OpUCypm1gAoNjMIAbTv2UyjAjTjx/+3mgfYyvORgH2pxeyVw76eKG6fSkj9PP/dARfxmmA/xvaF5m8/lV0AAAAASUVORK5CYII=
""")
ARWEN_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAASFJREFUOBGNUkuuQUEQrX5hYAkSIwNiRLAJG/AmBnLFFnxiH2bvxcAAG7AJL2FkZiSxCIPWp9wq3friVdK3qk+dc/r2x1ActlXMx2iK/F2uqIwQtEiBt2IR+SY5AV/l3XYZtUzjW7EvrYii1bPEHp9L34CBSFTvEmEgJN9n/I0MgKqJExhjeABH/WySaRCYYPImIoN2p/egHzZkreUBEDU5zA//GvUQcU12v2be8XTmXCuXOHs3wNroD8D6+V2QECH0xehhuHC/QyTvwKYgzWdD4DSaTNWEAfcRDuaoB0nfwkDFaKSvDKVuA/V4tUeCSI1gEmwBzf+Ez5MtBDpZRVZFs1qp8uoB0U3YIGkWGE/cycvhAYAoK+SG0Au2kEX+hN0A0M5gO9RH3/QAAAAASUVORK5CYII=
""")
BILBO_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAASdJREFUOBGNUjFOA0EMtEmqKK9IkyYKkXgCD6ALdcQf0tHmGUE0SKFBPIAaUUQKiCYNn0iUDm081s3Ke7cSWFp5PLbH3r1TqVuq05lVogxImE+LWS+EXfiw+wXpvW2BP5spR5ELEub/3Rx6JApEPuP145Pjtm+uWbwVNkjpc+OeGHE2YvOm6s3coFif03z0dC6q6gcxsBhHo4A2j0JeCpHMdgEFkHERvbwtq76exa7gBwlgMY5vED9jGg6uvPl42ord3XEUrHC4kFtubmKJIuTgIRgHQaDTjMLr0V5ev4+AhbGZZL9NYDK5j5c71snqfiNvP2PfjHlPWoAN/Bjh35fxzWSYTCTBk4s1+Ef6h/dlnhIfjCQmV0xt0+JHqtSIr4wEVq+YYuAZCp+X3X5gGN0AAAAASUVORK5CYII=
""")
BOROMIR_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAYxJREFUOBGFU7tKA0EUPbvRZIMGsdAiPxBjoRYWighC/sAiYhpBEf0BG/uAYCcWsTDBJhILW1GxVUGQBEHUwlQGFCGEbaJixjljZvJgk1y4zzn33NmZWQudRXReUisWrTIeQLExbnuUG6WDxxoTy4ugZ7OmIUn3MRopfSp7rDJ6HbPQvgPP6c0NiqVurKkl2JEhdD0s0zwZB6gU7WVoDweAXiRssORxUSnK10ns8hfQicRMV23exn6uwNIk3hBZLZxACKGUGMasUfpoSEI/M9o4D15RikUtsmEzsayyVFZ+hjzAdhGhmE+QhJ4qAULkc0rlw2qJE0GI8/2w0NfIBEdbJUX6GgLyIor+iRe4V79mkH6dbrGGld0w3gaS8HFKOpOB649hfuEOhUsXZxVgevATpfcxBGfLWI9v48m5xkPIwn0xgp2kXzVrZrVtSUIitW2SOiNRVafndum1+h1HUInjJxBo5PbjP5RgU1tbXcRh+tTkNbeIwNyPylv+hZuLnAE1B+W9ZHOK72rV5H828aOOE6APZAAAAABJRU5ErkJggg==
""")
ELROND_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAS9JREFUOBGNU8FKA0EMzdRW1oN/4F1vCp57X3rxpCL6D4J/0q+Q6sVT2XvPhXqrPyGIHgTBmJedDJmdUQxMk7zkvZmEbaC6cR1OaLAoBQaI58P9kUvL8OX9G6Byh51V8vxxmVQQxwv0lcMXcNd1qfmvoG1blIMXKG7fru5/1QgnlyowHIGqpOMLIhyY+T6jQgB4JiKEIA/Fgal3IlUB7fznTyFwNL3Kqc8PxMx6UEBMgpkVAijEBWkPYj8CyL4+jkp8OpEZP5k+mkBnjezBCptFjHoHsvZKuv5ixmZ6sms72GHaTkYUvzhXoUQ2cGxqBoiqhIHmT0vae3s1WP3dzTVuzUSyHfTkjJMSkM18XyZgDfC35zMyknngu40syFngzSL9dW27w7Fcv46AXHgK/wCXGFuW+Dd1YgAAAABJRU5ErkJggg==
""")
EOMER_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAXBJREFUOBFjZMAN/uOWAsswgkgwgUXh/51TpLAII4Tcc56BOIzYDCCoGWYMyBAWGAcf7WbTj0M6HMMADNtBml0y2uAG7JlRhcKHS0AZIAPg+P+Flf+dLfT/g2g4gLGBNFDPfyZ0E9D5IBsZ9MOAocUIxiB5EBskBgIEDQCrwkMQZ8DFVQxAL4AxyCwQmwEoBgJ4DUAOPJAGF0sDSAAC2YwG4WADkNPBf38OsBhDVg8kEYHiGRiIEEEgCQ4PIA0yWPziRQZ2XR14SoRrhqkGGZKX/5Lh5t+/MCG4YTDNIAmQC/4nmunAFYEY809dYbBhZ2R4/YeJQYP1L8Pb/4wMwoyQrAFiq+prw9WDDYA5XUhPB6wZJNuYLsCwe8FHsCGiLP/AGlwT+MF068IfYPrXjx8QF8AMAIluhMgxgMSM4gUYls35DHYFWAeU2M7AwQDUDA4/FBfc+M0M9zPICyAAcjpIHOSVi+LyYLEHDx+CaLACAMYLlXVkNZ/4AAAAAElFTkSuQmCC
""")
FRODO_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAATFJREFUOBFjZMAO/mMXhosywlhwBkwASP/XFcMmjFBx+RXcfEZ0lQQ1I4xhYAAZxIQsQAob6gpGZAOw2n5p9wqwuTAaxAGxod6E+wUkDjLg//+LK8E0jA3iwwGMDaRB6kGaYC5AsR3ZNga9MAaWoG4wBmkAsUFiMAAzgBEpZMFyKIbAVBNBg50GdjbIuTAM8wOSF0BeBJr3Hzka/7N4Q6z4sxUoc3ElmMOoHw63F4sYPB3ANcNUIxsCEwPRIAORLQK54P+mFcXIahj2TZwC5k84/hNFHMRBV8sIFABHB0ylX0QvQ4ElO5gr4FbBYKT5heHcdR6GD7s6wGIgQ5ENgcUCWBKkGRmANJswTQcbgiwOU+eracbAAiLwgTP/MjGkQWEAMgQUqCguwFCJRwBkCChAAV8Tn+nXMJ8QAAAAAElFTkSuQmCC
""")
GALADIREL_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAShJREFUOBGFUjFOAzEQXEcnpbuGhAqaVHRQQOoUvCHwEf6AhMQ7gCZfoE4ooIICpQkVkIaOyng2Hp+9DrCS49nZmfHFd07q8jWVGJdQBJbwq5tjq0n9/vkDcOHJmz/NTLEhDQfYXweXefsLPi14PsHW0/cOLlR8/7kjk8FasTs6w06f9JSNPzSgVXw4FQlLzcBbqgjAPIUEg3NOF3hghNmqAqzgv74IeHu56vRPd+K91wUSWAJnqwjAMF6S6p5n14KlFcz5bEN2t+nfl0ty8j2fdncRWZip2R2NwOqbwHdQmKO+Oo1mzIFDCD551+QDJLP3j7fMko/2RHE+Z0i6g/hYlYlmDqwuBVhBr231ZOwoa6S+GX4tFOORecv98eZ10Uwxdv1r0YP+BxRGYS1uGyd2AAAAAElFTkSuQmCC
""")
GANDALF_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAOVJREFUOBGlU8ERgjAQTBiq8eFQAmMHPhzKSSiH8WEHDliB48NyiNkLF04TUMY8uM3d3t6SgFbpcoe6TrMic+173mnNyEcH/K1Z8BWESm6UhS242ELOcbW3TNZzxV9yOAMSsMYkfHPcUc7tTxT146yAEbF01dAZRBHKTg80c2NRhDd1904Bj+M4sRqFistNl2JrGLewuNhqnOitA3MejX/fwqqD9vIkd7aa51gTcmy7zH15tm19fb6VpTNCL0nfhoEFKeZE3whiE71hapgcqp+iokehxvUoIAlbMB2i+D2j8pqI5L8AOFJISGZGHRcAAAAASUVORK5CYII=
""")
GIMLI_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAATZJREFUOBFjZMAO/mMXhosywlhwBkwASP/Xl2BmcDX9y7D7NDNcGJl/8cVfkDhYL7oBWDXDTMFmCBNMklwawwUlvsQZ1bMZrI4Rpws0rjAwdPfsYADRMDZIC0wMlzX/gS4A4/83d/z/f3HlfxAAKgZjEB/ERhJjwOkCXDagi2MYAPUbQ2mJBwMDBz8Dw6VVICvBGKQZ7CCgGDbwn8Ub4tQ5ihBvgGiQHhgG8WHegInBYgGkGQXMuIbCReFkaEG4RZolDCxA5v+ykhK4gs8TJ0LYMr/hYugMkEYYYMq0EWH4fGIBjM8w/TdujXBFSAxGoAEgPzIwnPwI15zJygoWMsbiipT7YCk4AfICGNySB0bIHRgPP40cXiy3XnzGUH1M+B9Y7Nh3ZoZcTnDOA/MnA/kMDAg+SBAAELeEmEkT3jgAAAAASUVORK5CYII=
""")
GOLLUM_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAASBJREFUOBF9UjFOA0EM9J5S5gO06ZCCeABPQCBBSX5wT0GUKCnoKWlQpHRUPABITcp8ImK5MR7Lt7vEUs5z3vF41rkkxyP/c5xY7wgaOX9/LOV0KhIz8BAu7EqFQEbj+l3JfnR50Xttdt6jnloOXN07G4BOSgG1DX45nTW4iNG6gouQuN1+KZzPz1gS1K4XK6kcOMMAiFd3S7l5mmoTyqwBRwGdjLvZgnA+CoogMyYGKtskwHZKSXL+2+3rcy+Ht3vZfa6Ugh00m+HCNq3E6Cq4HKQLgdgYsarYw8T0D5jEKZFEHCezFjN3EGsjzAGlm+EdS6m/xHA/3QEazUWyPBqQbk+66tN92f/4AtkcunzpOOseNo+CH4OY0+wK1RDyfwEX/IfaxWGo0QAAAABJRU5ErkJggg==
""")
LEGOLAS_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAWNJREFUOBGFUjtLA0EQnl1tgqKFjagEfLSiVmITtbK40lIjVoKlhf9FBCEYLG2E2PpoxMYg/oOAIhY+wEeVW+/7NrtuLrc4sHvz+OabudlREhcTDzGicPMqAJqrw1jIopd3yK+KUP8mu4Ig6YexUh40l63PIjJiK4vHLif3rYpeHRX20vn2VI8nWy6do6TZk9ROxcxu8AAA3UkhAYIhiZnPWtWaBzHojkRfPNuXOD9KEOuSkKQrEBjoAAOUUtLw7uvbLa9DUQ8nkqYpD2zo8EH4Cz+NRHBCUXNVb0IPfwHJLs5nBBIdTK5NZNojE7FIAJn7upi7On3ugt9i/zbROAdAtXVLAr2zcVC9hFjOIHQAFSZNVcqyub8nM0OaVfNYbJ/JNtGzY6CQ4YUBOdv9lu3Tcem7eZL20hj9ry9v8tH8oo4rugcIhskgyQmKKw6xOWLkvXbAuJsujLAyOiDJdIk4d/0Cbo51CLliJlMAAAAASUVORK5CYII=
""")
SAMWISE_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAQxJREFUOBGNUjEOAUEUnZGNQ1BIHIC4AqWEaLiAToeoFOpNuAeNSqHgCrIOIFFwCJGM+Z83+TNG7CST//77772dnV2t4svEacdqIAdA2GqWvbJov+FkeyOSvWHAXzPiECIDcptlSAHNrzperHgkK3DooRMYk625AlPvFrCt1swXHT2B94RaX2mtedMTCSvLYUUDaOiFQB2pMkDTzer6wJedN8q+Am8aEFaWw/K+QtJ+08+dFWZrbmRgjEOAgRnJMgQcVQqEdj9M+W8yh20qNWo6mnN/uj88nppQWwiJVm/mTDSjY1NtlIq83fADEklIM/jj5QrINdQkzWrFE+RpcAeklZ+Rvd1OJ0+G07wAnaZ1Gnn6pboAAAAASUVORK5CYII=
""")
SARUMAN_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAAQJJREFUOBGlUr0OgjAQPoiTi1Ew6uzmYIhhdvEhfCtfxAdwYtCZQV1ddDDEICbsBvS7cKVBiiY2Kb1ev58eV6I/h/WFnzecM7dJII/iu5E/6rs4s0wCjWRRhUhLNtpaSx5eAw1ShnYZmiMTGYyvAiBb3pKnboHcTwIAZVnGYCFhlVz1BrX1M9vwqQrUwqzjmh3FFStyGHVd+BA5PMfk2aVXELg0mS4Yp7+DHMq35KEE0Od9GFKSpiongdPp0HQ2U11gMg4HTk8wtN2sVGwKcC9FFlDxTHmbxjuCmz7EHbmysAJhF7XqN+m2T0oEZM/3CTjMn37i+RK95SNy+nOuG17SkRdW+1Nb7npefQAAAABJRU5ErkJggg==
""")
SAURON_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAACaIX+wAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC+kEAAAALNJREFUOBG1U0EOgzAMCxNfYJd+gv3/EfCJXsYjWF3qymqKtA1RCSWkjrHbYHas/TXPe0prRB5CyDXGDsYeheDv4AiWdT0l6+05giTzlCBZcXuDVODf3ttmz2nKZeZtLEpyr1MghF+lYw+lXqkGuBhjfrTnHgU8SHiHGhweIxSpwssK7iegHUY9QOSqYFBvLZDvBVPnB9eIH+bXVXvGVhq+oHevzJiDFu8GCQBa6c2+EiL/AGaxTB4BcdCiAAAAAElFTkSuQmCC
""")

CHARACTER_LOOKUP = {
    "5cd99d4bde30eff6ebccfc07": struct_Char("Arwen", "5cd99d4bde30eff6ebccfc07", MOVIE_FONT, "#9d9ea0", ARWEN_IMG),
    "5cd99d4bde30eff6ebccfbe6": struct_Char("Aragorn", "5cd99d4bde30eff6ebccfbe6", MOVIE_FONT, "#d0ad39", ARAGORN_IMG),
    "5cd99d4bde30eff6ebccfc38": struct_Char("Bilbo", "5cd99d4bde30eff6ebccfc38", MOVIE_FONT, "#703a07", BILBO_IMG),
    "5cd99d4bde30eff6ebccfc57": struct_Char("Boromir", "5cd99d4bde30eff6ebccfc57", MOVIE_FONT, "#d0ad39", BOROMIR_IMG),
    "5cd99d4bde30eff6ebccfcc8": struct_Char("Elrond", "5cd99d4bde30eff6ebccfcc8", MOVIE_FONT, "#eadede", ELROND_IMG),
    "5cdbdecb6dc0baeae48cfa5a": struct_Char("Eomer", "5cdbdecb6dc0baeae48cfa5a", MOVIE_FONT, "#b9941a", EOMER_IMG),
    "5cd99d4bde30eff6ebccfc15": struct_Char("Frodo", "5cd99d4bde30eff6ebccfc15", MOVIE_FONT, "#703a07", FRODO_IMG),
    "5cd99d4bde30eff6ebccfd06": struct_Char("Galadriel", "5cd99d4bde30eff6ebccfd06", MOVIE_FONT, "#eadede", GALADIREL_IMG),
    "5cd99d4bde30eff6ebccfea0": struct_Char("Gandalf", "5cd99d4bde30eff6ebccfea0", MOVIE_FONT, "#807f7f", GANDALF_IMG),
    "5cd99d4bde30eff6ebccfd23": struct_Char("Gimli", "5cd99d4bde30eff6ebccfd23", MOVIE_FONT, "#9c2200", GIMLI_IMG),
    "5cd99d4bde30eff6ebccfe9e": struct_Char("Gollum", "5cd99d4bde30eff6ebccfe9e", MOVIE_FONT, "#b2a569", GOLLUM_IMG),
    "5cd99d4bde30eff6ebccfd81": struct_Char("Legolas", "5cd99d4bde30eff6ebccfd81", MOVIE_FONT, "#21471c", LEGOLAS_IMG),
    "5cd99d4bde30eff6ebccfd0d": struct_Char("Samwise", "5cd99d4bde30eff6ebccfd0d", MOVIE_FONT, "#ffd1a9", SAMWISE_IMG),
    "5cd99d4bde30eff6ebccfea4": struct_Char("Saruman", "5cd99d4bde30eff6ebccfea4", MOVIE_FONT, "#FFFFFF", SARUMAN_IMG),
    "5cd99d4bde30eff6ebccfea5": struct_Char("Sauron", "5cd99d4bde30eff6ebccfea5", MOVIE_FONT, "#c90000", SAURON_IMG),
}

MOVIE_LOOKUP = {
    "5cd95395de30eff6ebccde5b": "The Two Towers",
    "5cd95395de30eff6ebccde5c": "Fellowship of the Ring",
    "5cd95395de30eff6ebccde5d": "The Return of the King",
}

RANDOM = "Random"

def get_schema():
    options = []
    for character in CHARACTER_LOOKUP.values():
        options.append(
            schema.Option(
                display = character.Name,
                value = character.Id,
            ),
        )

    # add a "random" option
    options.append(
        schema.Option(
            display = RANDOM,
            value = RANDOM,
        ),
    )
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "character",
                name = "Character",
                desc = "The character to display a quote for.",
                icon = "quoteRight",
                default = RANDOM,  # random default
                options = options,
            ),
        ],
    )
