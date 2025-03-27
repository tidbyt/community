load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ARD_LOGO_ENCODED_WHITE = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAFeSURBVHgBtVSBcYMwDBS5DuBOUG/QjMAGZYOyQdmgyQTpBrBB6QTQCegGsEHoBK5UnovP2JjkLn/3Z1uWX7Itm+gOSEITxhjFTcZ8ZmqmjEfmN7NOkmSga8CC78yzmdAxS7Cx7DLWW8Q0RAQHZOvzy5k9AmQxwR7cUzwBxayQQBpyKiGoI0KFHINlq5Cxcp1TRMwDQqlznsaZF3vpzdIT6GQL2XB8D4tsYSjQz0JCK6LK3ukOlyIRfuAzjwUDbQDX7Ahf/S/qERDxI/MR7VYMzCfpPND0SmgW56g1NzW2RVdA1v/OmQ4wRmszgv2stcN5tMwXuhFW8be2scDtacc591z82S5++DXMzo2k8JqaFdEGwZXj82aX02ILmCwd29rH8oo1HxSClVln4n/ACb6VO594FsgtftJUyC3ziy4PQ2zyaecYH/miw1kGsm7M8sn2a0fizTQQQKM7ogRX8QerO/tFhV/1pgAAAABJRU5ErkJggg=="
ARD_LOGO_ENCODED = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAKASURBVHgBtZRNctpAEIW7Rww/VV6QEwTvEuSqaJkYXAUnAJ8AOEHICQgnMJzA9gnsnCBKxWatRSh7F90gpCqxhATT6RkBAYIcOyn3RqOemW96Wk8P4AkC0yZqDhWjOGxaYL2akyohQpEIJojqk5R46XoF/1HQw/K0h0hdICgyzCNCzyxGKhGAo/P8cial6u+Cb0BfO0HJisQFADkI1M/c5Qeuj5M/DrWDNhL2eHtREHQ+3+Qud0ITIH7UY8LZ8Wi858E9odsTx+GAF7dQUP3qS8FdzmWWAysWfDKBVFR3b/f8dFDQBhAN18M6p9oVOwBS4oLn9jk3WUGrB0GNFLUJqePebvZIg2az0OG+9uJ4yv0UxfV5KfNdzjfiODrh147OCXNdEi1++KNx4Wy5WB90ZEcnvOErKW4LQc18oK3Q1SHRkOeauoAVlLFNTg716OjltFmxw28apEh1d4G2I5PND5hRnLMEDfTQjoxE0CLzYQiVswby4QGx6KXPOi4ZqMC5AWRmCQBJeFpO8i73jHvch4cGMhTEc8NSZE0QFESWZeALzRndsR4fwdS3o++m0qyUvh5YMHfgP4KvzgpJbitMPxDcOWED/jG0UgxYCNdAk7T6wOWzJILSXwmoTQXczSr5l2WPGI2z3goqpdGnH8d4msrSIFTv5M/c/tU4X1/m3xyEb7WGCWi48wqVckgVe3q6nquWg/e1Eu3UasWOWnpPtcwesHGZtVi4D0PRk1l1nOaZiQdMe1xhlzV4fj0utFOhCfiHg5Rh+2Mhm95xvzHxU8Xi1qatQCUQBf3rm/xgm5Hq/LpqAdhamfLv8PnnOE/z2nuh61F7sVBFmJ+kgdbjF/18Nbj16wNhAAAAAElFTkSuQmCC"

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64
HEADING_HEIGHT = 12
TEXT_HEIGHT = TIDBYT_HEIGHT - HEADING_HEIGHT - 4
TEXT_WIDTH = TIDBYT_WIDTH - 2
CHARS_PER_LINE = 13

def is_breaking(newsEntry):
    if "breakingNews" in newsEntry and newsEntry["breakingNews"]:
        return True

    # if "tags" in newsEntry and any([("tag" in tag and tag["tag"] == "Eilmeldung") for tag in newsEntry["tags"]]):
    #     return True
    return False

def format_text(original_text):
    lines = []
    for line in original_text.split("\n"):
        new_line = []
        for word in line.split(" "):
            append = word
            if len(word) > CHARS_PER_LINE:
                append = word[:CHARS_PER_LINE] + " " + word[CHARS_PER_LINE:]
            new_line.append(append)
        lines.append(" ".join(new_line))
    return "\n".join(lines)

def format_time(original_time):
    if "T" in original_time:
        time_part = original_time.split("T")[1].split(":")
        formatted_time = time_part[0] + ":" + time_part[1]
        return formatted_time
    return "n/a"

def get_most_important_headline():
    response = http.get(
        "https://www.tagesschau.de/api2u/homepage/",
        headers = {"accept": "application/json"},
        ttl_seconds = 300,
    )

    data = response.json()
    if "news" in data:
        for entry in data["news"]:
            if is_breaking(entry):
                return entry
        return data["news"][0]
    return None

def main(config):
    headline = get_most_important_headline()
    if not headline:
        return render.Root(render.Text(
            "Cannot refresh news",
            # font family
            font = "CG-pixel-3x5-mono",
        ))
    title = headline["title"]
    topline = headline["topline"]
    date = headline["date"]
    formatted_date = format_time(date) if date else "No time available"
    news_is_urgent = is_breaking(headline)

    if config and not news_is_urgent and config.bool("hide_if_not_urgent"):
        return []

    return render.Root(
        render.Stack([
            render.Box(
                color = "#1e283f",
                width = TIDBYT_WIDTH,
                height = TIDBYT_HEIGHT,
            ),
            render.Padding(pad = 1, child =
                                        render.Column(
                                            expanded = True,
                                            children = [
                                                render.Padding(
                                                    child =
                                                        render.Row(
                                                            expanded = True,
                                                            main_align = "space_between",
                                                            children = [
                                                                render.Image(height = HEADING_HEIGHT, src = base64.decode(ARD_LOGO_ENCODED_WHITE)),
                                                                render.Text(
                                                                    formatted_date,
                                                                    # font family
                                                                    font = "CG-pixel-3x5-mono",
                                                                ),
                                                            ],
                                                            cross_align = "center",
                                                        ),
                                                    pad = 1,
                                                ),
                                                render.Marquee(
                                                    height = TEXT_HEIGHT,
                                                    scroll_direction = "vertical",
                                                    delay = 20,
                                                    child = render.Column(children = [
                                                        render.WrappedText(
                                                            content = ("+++ " if news_is_urgent else "") + format_text(topline) + ":",
                                                            color = "#FFFF00" if news_is_urgent else "#FFFFFF",
                                                            font = "5x8",
                                                        ),
                                                        render.Padding(
                                                            render.WrappedText(
                                                                content = format_text(title) + (" +++" if news_is_urgent else ""),
                                                                color = "#FFFF00" if news_is_urgent else "#FFFFFF",
                                                                font = "5x8",
                                                            ),
                                                            pad = (0, 2, 0, 0),
                                                        ),
                                                    ]),
                                                ),
                                            ],
                                        )),
        ]),
        delay = 100,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "hide_if_not_urgent",
                name = "Don't show if not urgent",
                desc = "Don't show the news if it's not an urgent headline",
                default = False,
                icon = "eyeSlash",
            ),
        ],
    )
