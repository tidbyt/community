"""
Applet: The Tracker
Summary: Show your internet stats
Description: Flexible counter to display your numbers via ilo.so: X, YouTube, TikTok, Bluesky, Ghost, Kit, and more!
Author: Steve Rybka
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")  # Added to parse JSON responses
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL = 300
DEFAULT_CODE = "n1bmw0og"  # Updated to a sample ilo.so counter ID
DEFAULT_COLOR = "#1DA1F2"
DEFAULT_LAYOUT = "Number"
DEFAULT_FONT = "tb-8"
DEFAULT_BANNER = "Followers"
DEFAULT_FORMAT = "Full"
DEFAULT_ICON = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA4dpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMS1jMDAyIDc5LmE2YTYzOTY4YSwgMjAyNC8wMy8wNi0xMTo1MjowNSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo4MDNmNDJjMS1kMzcwLTQwYWYtODA4Mi0wNjBiODAzMjUzMWIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6M0ZBOEM5RURDODBDMTFFRkJCMjE4MzM3QTM2MDM3MTciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6M0ZBOEM5RUNDODBDMTFFRkJCMjE4MzM3QTM2MDM3MTciIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI1LjEyIChNYWNpbnRvc2gpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6ZDNjNGVhMDQtZDNkZC00NzY0LTgzMjEtZmVjYTk1MThhMTUzIiBzdFJlZjpkb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6MDFiOTVmNjQtYmFhMC0zMjQxLThkZjMtYjE0NTEzMDMxZjUxIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+scETfwAAAM9JREFUeNqMUwENxCAMRAISJgEJSEDCJCABB5MwCZOABCS8hEngWXJ8Lv2ytAlLytprd3dzvffW/yO5lxjvz1/deAQkz2UE4D2OXzRn1O/a5QO2AaAqzTvqDg25Yrqnwkzv49x09V1z8oH8Qh5w1K0kSJrkYJMPcdJWvEiQOdnT2repGQBzckVeABKdNWhyRt4Aat6ikKlY2svSPCUsmCylTRYVTuSBjUMEb1pz0NYklyZJsGYiVWu4VEqbWbZXluX/QSQHR04LRpdytK8AAwBMGuwGXzA6/wAAAABJRU5ErkJggg=="""
DEFAULT_MULTIPLY_BY_12 = False
DEFAULT_ADD_DOLLAR_SIGN = False
DEFAULT_SHOW_COMMA = True

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong!"),
    )

def main(config):
    # Load the Counter ID from the config
    code = config.str("code", DEFAULT_CODE).strip()

    # If the Counter ID is blank, show an error message
    if code == "":
        return render.Root(
            render.WrappedText(
                content = "Error: Counter ID is blank.",
            ),
        )

    # Load user settings from Tidbyt app, or grab defaults
    layout = config.str("layout", DEFAULT_LAYOUT)
    color = config.str("color", DEFAULT_COLOR)
    code = config.str("code", DEFAULT_CODE)
    banner = config.str("banner", DEFAULT_BANNER)
    font = config.str("font", DEFAULT_FONT)
    icon = base64.decode(config.get("icon", DEFAULT_ICON))
    multiply_by_12 = config.str("multiply_by_12", "false") == "true"
    add_dollar_sign = config.str("add_dollar_sign", "false") == "true"  # New toggle for dollar sign
    show_comma = config.str("show_comma", "true") == "true"  # New toggle for commas

    # Cache checker
    cache_key = code + "_multiplier_" + str(multiply_by_12) + str(add_dollar_sign) + "_comma_" + str(show_comma)  # Create a unique cache key based on multiplier
    cached_data = cache.get(cache_key)

    if cached_data != None:
        print("Cache hit!")
        body_content = cached_data
    else:
        print("Cache miss! Getting Data...")

        # Get data from ilo.so API with user's counter ID
        ILO_URL = "https://api.ilo.so/v2/counters/" + code + "/"
        response = http.get(ILO_URL)

        # Attempt to parse JSON response
        data = json.decode(response.body())

        if "count" in data:
            # Extract the count value as an integer
            count_value = int(data["count"])

            # Apply the multiplier if enabled
            if multiply_by_12:
                count_value *= 12

            # Format the count with or without commas based on the toggle
            if show_comma:
                formatted_count = humanize.comma(count_value)
            else:
                formatted_count = str(count_value)

            # Prepend the dollar sign if the toggle is enabled
            if add_dollar_sign:
                formatted_count = "$" + formatted_count

            # Use the formatted count as the body content
            body_content = formatted_count

            # Cache the result with a unique key
            cache.set(cache_key, body_content, CACHE_TTL)
        else:
            print("Error: 'count' key missing in API response")
            body_content = "Error"

    # Use the final content
    final_content = body_content

    # If user has entered a bad or empty counter ID
    if code == "" or code.strip() == "":
        final_content = "no ID"
    elif body_content == "No counter":
        final_content = "bad ID"

    print(final_content)

    # Top & bottom layout
    if layout == "Top":
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = banner,
                        font = font,
                    ),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = color,
                    ),
                    render.Text(
                        content = final_content,
                        font = font,
                    ),
                ],
            ),
        )
        # Side by side layout

    elif layout == "Side":
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(src = icon),
                        render.Text(
                            content = final_content,
                            color = "#fff",
                            font = font,
                        ),
                    ],
                ),
            ),
        )
        # Number only layout

    elif layout == "Number":
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = final_content,
                            font = font,
                        ),
                    ],
                ),
            ),
        )
        # Fallback layout

    else:
        return render.Root(
            render.WrappedText(content = "Error: Invalid layout"),
        )

def get_schema():
    colors = [
        schema.Option(display = "Ghost White", value = "#FFFFFF"),
        schema.Option(display = "Twitter Blue", value = "#1DA1F2"),
        schema.Option(display = "Instagram Purple", value = "#833AB4"),
        schema.Option(display = "YouTube Red", value = "#FF0000"),
        schema.Option(display = "Gumroad Pink", value = "#FF90E8"),
        schema.Option(display = "Paddle Yellow", value = "#FFE450"),
        schema.Option(display = "Money Green", value = "#2E7E74"),
        schema.Option(display = "Slime Orange", value = "#FE4D00"),
    ]
    icons = [
        schema.Option(display = "Logo - X", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA4dpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMS1jMDAyIDc5LmE2YTYzOTY4YSwgMjAyNC8wMy8wNi0xMTo1MjowNSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo4MDNmNDJjMS1kMzcwLTQwYWYtODA4Mi0wNjBiODAzMjUzMWIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6M0ZBOEM5RURDODBDMTFFRkJCMjE4MzM3QTM2MDM3MTciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6M0ZBOEM5RUNDODBDMTFFRkJCMjE4MzM3QTM2MDM3MTciIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI1LjEyIChNYWNpbnRvc2gpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6ZDNjNGVhMDQtZDNkZC00NzY0LTgzMjEtZmVjYTk1MThhMTUzIiBzdFJlZjpkb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6MDFiOTVmNjQtYmFhMC0zMjQxLThkZjMtYjE0NTEzMDMxZjUxIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+scETfwAAAM9JREFUeNqMUwENxCAMRAISJgEJSEDCJCABB5MwCZOABCS8hEngWXJ8Lv2ytAlLytprd3dzvffW/yO5lxjvz1/deAQkz2UE4D2OXzRn1O/a5QO2AaAqzTvqDg25Yrqnwkzv49x09V1z8oH8Qh5w1K0kSJrkYJMPcdJWvEiQOdnT2repGQBzckVeABKdNWhyRt4Aat6ikKlY2svSPCUsmCylTRYVTuSBjUMEb1pz0NYklyZJsGYiVWu4VEqbWbZXluX/QSQHR04LRpdytK8AAwBMGuwGXzA6/wAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Logo - X Verified", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAOBJREFUeNpiZMACZBd+EgBS64HYASp0AIgDH8fzfUBXy4imKQGIQbQ9kmYGJEMOAjHIkAUwwxiRNN+HaiYGgDQrggxhggokkKCZAaoWpIeBCUmAVADWwwR1vj0RGhqhTocBe5BeJrTQxgUSgXgCmhhIz3omLJpBtlxA07wBiPdj8aoDExbbJgKxI9SQCUiaDbA5jQkav8igHogDQIYAo6kQ6kUDHF47wIgl1SE73R4WXdg0g1InEzRFHcSiYD4ezSBwEDkhfWAgE8AMWECiIR9g0UpOZgKBCSiZiZLsDBBgAFuLRzv95mBJAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Logo - BlueSky", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA3lpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMS1jMDAyIDc5LmE2YTYzOTY4YSwgMjAyNC8wMy8wNi0xMTo1MjowNSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo4MDNmNDJjMS1kMzcwLTQwYWYtODA4Mi0wNjBiODAzMjUzMWIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MjFEQjcyODhDODBCMTFFRkJCMjE4MzM3QTM2MDM3MTciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MjFEQjcyODdDODBCMTFFRkJCMjE4MzM3QTM2MDM3MTciIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI1LjEyIChNYWNpbnRvc2gpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6ODAzZjQyYzEtZDM3MC00MGFmLTgwODItMDYwYjgwMzI1MzFiIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjgwM2Y0MmMxLWQzNzAtNDBhZi04MDgyLTA2MGI4MDMyNTMxYiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PvvmFjEAAADaSURBVHjaYvz//z8DJYBFqO1/AZD2B+IHQNwIpfEBBSCuh9IbWaCaHaCSAUBcCMQLcGhOAOJ+IBaAuwBNAUhiPpS9AIvm+egmMuGwCWSLARLfACrGQKwBMJcIoLExAxGIDyKFAQOarfVIbGzgIMiAD3hCvIBAjHxgggbWBTKSAEjPAiaoCxyhaeADERo/QNU6wlwAE5THFVBYAlgeZhkTUiAlkOD8BFjAwgzAlXwPQDE28ADZgA/QJIwOGqEYHRSiewEEJiBLQDXCXFCIZFEiVC0YMFKanQECDADhzjIeFn0a0AAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Logo - Instagram", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA4dpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMC1jMDAxIDc5LjE0ZWNiNDJmMmMsIDIwMjMvMDEvMTMtMTI6MjU6NDQgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6YTcyYmVhZjYtMjI0Zi00NTYzLTliNjEtMTBhODkxNDJmZTMzIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjE5QUM2N0U5QkUyMTExRUQ5NzVDREMwQUE3MjM2QTBEIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjE5QUM2N0U4QkUyMTExRUQ5NzVDREMwQUE3MjM2QTBEIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyNC4yIChNYWNpbnRvc2gpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6YmQ3NzU4YWUtODZhMS00MjgyLTg0MjctNDg3ZDM3MDM0NzUyIiBzdFJlZjpkb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6Y2VjZWYwNTEtZTJkYi05NjQxLWJjYzYtMGIwNjRjZTIyMjhhIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+IK4mlwAAA0xJREFUeNqEU21oFEcYfmdnb293b+8j9xFzUdMGYkgaTqRSSUEMUYxSPUKkJBIlSmghRf0hAUXS1h/h1DYGRUTxoyTU2jTWfyH+0CtpiCRGiR6JgmiN0ETTHveRy+V2dje3u927ZC34x4Fnhpd53mee950ZBMZgEE23C8ETjez2b5xQ7BdVK+RAVBaIZiAfsyCpHMT1eHQM+q8NQnenAkRGHFiYHm/zz018bdMzORmNyNGnokZnZc0CigFZY1bWXGxFHr3yk2I9sPoB/D7QA4f3QmhVzbd6+Xn9N++Bm4XY4YEPDBcUulug+2ovZPQG6AhBsqYtFlt/9J8CirW9T3YiweFCDpcZH2NCfV1M34QTPM5ONPKqC54mKdda5JliX08lNSljEqssxZW/uI/cHvWdmxlyX37zk/1MeANdVa1AOmVFGiawSObQkydu5HHR4FkE1UE0MzlgKaq4W3RouAj5fYOZvx4saEjaYv1s20b6xy1t6ZN1F7I/tGmgA0tlKQ4IUOAxDrZL72yfWVNzuojlfK3xKy2746c+b06GalsXvq9lMFHbbQcvUoBxjmelssBhaUXAIS83iGHsWz/21j3Gkw97MuM3TNERZfLPO0q4fyOztqoE+8vyV08t5QVoKBDfOcAUomifiGUxLb3fUBWJRMAK0AjRywIKcJRsOHARAGHZQUKWU+NLM6PVFd7NX/hKtv3fl+KKZmFD46z2enZWjU4vP74l4PMOcgK8kifqOkDHRKTjj4bC4cGddeFbUzM3yTwmX6JNTTadsx9P9h4WdYnkuJaVEihwGpOgIPO04b9jY8GB8M4p9e1EY6B034HKqq9iXPzf1tj1/b+K430mz2gishkloYVH/gRJ0aQs+KYsTTRiErAhWe5yrsMaxq8WU9NEVRVzjwEa3y8MveTB7cUeny5s38PuKuEt/qFH8pCk6HmiUQ3EJDkRlUksq+uqmexALH/WXd9dz3+643rm3kUk2BB3+5Kjf0fQHpx7iGYiES2STTNZEBmAjIE0C7BoNVYr0GkOB+SPAmuU8tK788/DjbHePfnabTxiO9tt3x2st39dwPE+SBlJKQ5g3kCCN2B8k3gOAizMosSNF9M9HXNDJ1OanPlPgAEAcPheP0TTVRgAAAAASUVORK5CYII="""),
        schema.Option(display = "Logo - YouTube", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAM1BMVEX/////AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/4OD/QED/////sLD/ICD/wMD/UFD/EBCDEFz4AAAACHRSTlMAEECAYDBQcJt0SmoAAAABYktHRACIBR1IAAAAB3RJTUUH5wMWFzQsZdzZ6AAAAAFvck5UAc+id5oAAABPSURBVBjTY2AgAjAyMTGDARMTI4jPwoEEWBgYWDlQACsDG6oACwMzhMHJBaGZYQLc3Dy8aAJ8qAKc/DAtUEMF4IZiWIvhMLDT2ZGdTggAAKVMBQDy4NHaAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTAzLTIyVDIzOjUyOjQyKzAwOjAw//0zcAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0wMy0yMlQyMzo1Mjo0MiswMDowMI6gi8wAAAAASUVORK5CYII="""),
        schema.Option(display = "Logo - Ghost", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAt1BMVEVHcExvM//dAPLaAPJiPP+PIf9URv9gPv9bQf+0Kff5BfJvNf+KIv+qDP+ZF//kCfS/AfyUG//hAPH/HvBdQf96LP9lOv/2BvJ7Kv/yAPLCAPy1A/6+AvudFP+yEfn/Q+juLOz/ROjnAPH/Sub/Qen/Lu1kPP9VRf9vNP9VR/9vNP+EJf95Lf/NAPbXAPH0APKIJP+0Bf+lD/+WGf/jAPDjAO6kEP+6AP/OAPXXAPLMAPb/Nuz/SuaY9v4LAAAAPXRSTlMAHiA2PQZce0wLXRFmI1UTZDJ5jo1/WKxDTYFJP2guJCyJXTyWb7ZupDKTdomxb2fCsZelqTyFWFe/o6lVoJ2UwgAAAKZJREFUGJVFjtUWg0AMRAO7rOBeCuXgdXf7/+8qUGSeMjcnkwGohQlhKw69OPUxZoQS4e8lDwdrSl3qLpjSADXYeFKzYHPaECVW9e42WPoMwNLvQ5q6FQR4mLMBwFGwwAyNEVx0C57vsYB0jjVIX+IAtFOkgXHNB2CGUV3gMJl2Xtyh5oHhtIQj296jNi/JPo4syzmyb31cmpVlVTnyGA+8+BZJO/0AM8MK7K02+ZoAAAAASUVORK5CYII="""),
        schema.Option(display = "Logo - Paddle", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAByUExURQAAAA8VFQ4UFA4UFA4UFA8WFg0TEw4UFA0TEw0TEw4UFCQmFycpF4x9JZqJJ862L9m/MBAWFGNcIP3dNW9mIg8VFGhfIPTWNPfYNHFoIpuKJ9e9MNvBMSstGJiHJ9W8L5yLJ2ZeIWFaH25lIcy0Lv///ymZXt4AAAAKdFJOUwBVz/rOU1DNT1FFS96bAAAAAWJLR0QlwwHJDwAAAAd0SU1FB+cDFgE7MgDgJ4YAAAB4SURBVBjTZY/ZFoIwDESnhVoouJQgaJHF5f+/UaFBKMxLcu7JJBlAyMiwolgBBxNIQPomy32NwfPHE7vAo+eL9Q2DgqhcgWtVE93ulkHmGpr0cK0HXc9gaGfLc7SUdrX0RfQOrpjP/+zusc3rGkkY7hdX6SW+TvEFOVQL4prCEKkAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDMtMjJUMDE6NTk6NTArMDA6MDDdGqjWAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAzLTIyVDAxOjU5OjUwKzAwOjAwrEcQagAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyMy0wMy0yMlQwMTo1OTo1MCswMDowMPtSMbUAAAAASUVORK5CYII="""),
        schema.Option(display = "Logo - Gumroad", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAylpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMC1jMDAxIDc5LjE0ZWNiNDJmMmMsIDIwMjMvMDEvMTMtMTI6MjU6NDQgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyNC4yIChNYWNpbnRvc2gpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkZDMDMzRDc5QzA3OTExRURBOEYxQzFCNUVCNTdCODk4IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkZDMDMzRDdBQzA3OTExRURBOEYxQzFCNUVCNTdCODk4Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RkMwMzNENzdDMDc5MTFFREE4RjFDMUI1RUI1N0I4OTgiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RkMwMzNENzhDMDc5MTFFREE4RjFDMUI1RUI1N0I4OTgiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz56c3/iAAADO0lEQVR42mRTWUhUYRT+7p2Z62w6qy3aZKOpZWlRkQiVIEkLTBBBlPWQLZgULQ9tZA9FUb0ULZjZQkkaafhgZRBESqBWE5aURjqlpYWjTprXmWb9O/ObEPjDucs531m/8wuYfAw2U+Lm7KRFBVkJGXMFQQi/6/3gbHQ1VQ3Knmqyh/4HC///mDWGdcXLtx/funTjkhTTTFGlVHJ9IBRAh7vLf7u5svFG870SX/DPm0kB0qekHKsuvH0mK3mpgOCfcaViPADCQUISVKVB/dta35aK4k3DvpE6Dok+4vUWR33R/ZuZ9iUCAmOAqMDX/k6862lFz8AXqAQRcToL4JeRaluoyrDYHA/fP34SYZF+7n/OUdLGrnsZuzzAvBd62Z5lhUwraRjZuFh1ZnZx/SnGrgwxdsnNWJnMtmdvbiJbDBKN0/e6TryOsKsexq6NsmMr93Gn/LQVrOngU/aoqIrNMCZwXd3Ou4yV/ua4VwfrmVJU7FY6MvK32s02ASwCz68+3GypRIJhGh5sK4cp3k45JJjUsbjVUoVAmAiIhElCmD99DpItSYXKtCkpWQL1CFGJ78N9GJCHkJuSA5PVjiG3C9WtddBIaqyZmwd9jA4s6IcgCtDqzLDqLWmiP+QP8kkzBr2khaRQ4ZdvhNj2Q0HfGrUejV3N2HhnFw7VnSRn8R95jFyYQXR+b2sLRSgGlZdkTcaCxHlo+9GO8hdlMOqtKFi8AbLfC0kpIYaEH2JpTPbALQ+GxZZu5z3XYA/nXEmlnl93AmpVDIpqDiPt5GKkklj1Zpi1Roz4RscDkL217yO6h74NKEb9cpdBHZebl7naFuXZPjUda9NzYVTH8Yw7cgpwNH8fiErkpS5HFlUYrWB/zRF09He+5Juok7Q5T4oqG3Iz10jwDlMGNQdNzIZvJmXlvdO7oqEM26oORGewiqOC4WBvffvzT3OsSY502jTiiQ+RS3SNo4OjgUYDVLy8hWLKTj5nSVGumLgLYwFve+37x889v/tnJ8TGzzJTCwpNLHeUvSNwdjtxuLYEp59djATDoTPkUjLpNk5cMOrdkRqfXGjSGhdSmWaaduSz2/WTbB9ISkkaJsB/BRgADeRRlrdTYsgAAAAASUVORK5CYII="""),
        schema.Option(display = "Logo - ChartMogul", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAylpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMC1jMDAxIDc5LjE0ZWNiNDJmMmMsIDIwMjMvMDEvMTMtMTI6MjU6NDQgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyNC4yIChNYWNpbnRvc2gpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkZDMDMzRDdEQzA3OTExRURBOEYxQzFCNUVCNTdCODk4IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkZDMDMzRDdFQzA3OTExRURBOEYxQzFCNUVCNTdCODk4Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RkMwMzNEN0JDMDc5MTFFREE4RjFDMUI1RUI1N0I4OTgiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RkMwMzNEN0NDMDc5MTFFREE4RjFDMUI1RUI1N0I4OTgiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6O8G3aAAACKElEQVR42qRTTWgTURD+3nu722yTxtDSRKw/1JJC0BaRgAcrIlYQpL3oRQS9WQ+ak60H6SmUtkgFf6l4slC8KILerCgFQVpE6aEUg1hQQfRglTQ/m93sOm+zm7r21DowvJ15OzPfNzOP6W2pI6HE7nsMSGIDwpiAWVi5xpr3n/hAdic2J7/4fwRLiXH/y3YcFEtl2LZdg0hqVEyUykYgQtrSzzyb+8ERXUfvwTS2NIVdu0w/pTp24fCBfcSXwSGfaVXRk+5Gd6oDllfITWCaFnZsi+PRnSyS7TuRXy0g3hLDk8kR3B8ZhKoI5AtFHEp34fmDCWTOniIklbUEUmQFCa9arZLaGB08j+1bW/E7X0CF0MRbmnFjOOPRKAcp1EdDKiudO3kc/Ud78PDZC3DOUbEsjF8ZgEP3s3Pv0aBp9ZhAAsM0sTfZjutXL2Fschozr99SP2yc7uvFmf5juDA8gS/ffkAhSusSSAoSw9jQAHKfPmOcEmiqgrZEKyW8iFtTj/Fydg7hRj0wlQAC2bhoUwSZ7E0YhgHBBWLRCHLLX5G9PQUR0gi+6qovisudMxSpgW/eLWL66QwWlj5CDzfi+88VzC8s4fLoXawWSy73xdwyLGoyF7XacpUdn4Kcszz9CnKpLJqK3ANNUdwmStutLMQagtrjYO685VnnRxNQyXYXyfMJIf7pAef4O8n6Vxf0MU+9Swg1mghztWEPmSFs7D3DNo1XfwQYAFMzyp62Ng0LAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Logo - Twitter Bird", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAABLUlEQVR4nK1SPUsDQRBdd3JaWSkWdlYWdiL4MyzE3k7xB9gKNlqk0FIQLMTL2xM/Ku38ARFJZy9iIQEh9+ZQJLhyBpJcvFwSyMCwMLPv7XuzY8xYwvuJQVeCkEtSSdZM1FhsF0988Hdax6pFvJOLjPykQCFOfTuh5wLui9NnYy7i2VaRTRvpZi/eQvcy4K604L0JoMs9jbK5rU93CFjLJQCbKdaUwmQ150JdwMPUszi+9SF4bT1xxTkBf/rJLJBf6/h0rI5OoJdtAkG8PjKBS7Yz0xanlaEJoDTXjZl//20db4Yj4EH+ukVe0maxdD6ZOz+VXVFwwyLZEvBUnH4UTj5M5rPewbPBsvkt0OPuBctEKUxWBHpkHR8F+i7gl4Av1umDhe6a6HMh3/MY4hcwAZqpRCof8AAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Fire", value = """iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAACXBIWXMAAAsTAAALEwEAmpwYAAABSElEQVR4nI2QO0vDYBSGv9C5mw7dFEsHQU3tRWrbpBdDQ23TSC8Kbv4DFwdxEl0cHISqi4gg+AMcGsFF/CdCG9Om+dKvtUo7vJLVtOoDB1447zOcQ8gEOsqe1xnyH1CtelhhW2OFWsPJ5C9YrnLE5AqYXIadKx/+WqZSibclddSTtmBvqKBZZUTFEj9VsDPKM00roOkiaKoIKhZgifmniWUrmRcsYROWkMfwJICP4wC6cRnd9RysNTnhEsy4fOUs7d0oxq8cxi8caC0MM5JFO5Spu4RONKN1IlkMb734ahB8PhIM6l60eQHtFUFzCQYvXpupCAYPBP17gv4dAbshMGKr0Bdjly5BX07OG/HggF4QWOcE3TMO5ikHPbQ0NBaC/omHt/xh8X1nlhkHHPR9Dk11ptea48Wpb3UAqXreEj61mfSVnPyz8A0s+58mcDA2swAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Lightning", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA1klEQVR4nK2SMQrCQBBFF7H0BIK1M7HRE1hbmYsouUnQi2hl6w20ESQzVoJ1ipQyGdkkgoYku4Iftpv35sOOMR3RBNc5owpB2jXXGL3hQhiehYDhbH6JEs6EIbNw1WDnD1/HQyG4v+GyAcZ+8CUY2LqfsH1KELlhNT0h2NfhQsAYOgVCsG2CC0ESTJ2CvAVue/8X1GNrt8HCsHELGMNGmOCgx3nfLSCIGjaf7FcbnwhjXDumh/Jk5AUXAoLdx+bM6yu/G5QXKYSijMuf4KpBWl5hsOoafAHe1CwuMkCgpAAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Checkmark", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAnUlEQVR4nNWRSwoCMRBE62SCG0FEvIKIi66AAwpzs+6cTJEsdIQwTsYfMcGNDb0JVfWaCvB/o9JCuaszGw8wdlBeodKUk43dsDGEroz8uCcop0nkOYO6VZYc6XKEusmIIHMozzAGeC7LyMpFb74LQnz7yhwD3BomlydhyJ89Hi+bNyEZ8kvTso1fU2XG0HhTb06d7OvN6ZL2c2E/nhvi4bFIkTdT4AAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Lightbulb", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAuklEQVR4nLWQPwrCYAzFvzs4OovJ4kkUvYndHKWD4AE61tVjaI/QSTA5gpu6ppEUClL6/Snog7ckeb+EOPcPKeNaGCtheLcmvCrNV0lhYTw2jDpkIThENzeecGclWIa2VzGAEF4CAHhFAYzPZICeF63HAOo4AOrQD/KEC3IvQG8wEcaHD2A9m/ECTMq4EcKmD7Ca9VyKhLAYABRJYWdX3GfTPsBqyQDTKVP99qjwTwDlVndduMx07xv8AEo7TNPXQVHiAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Money", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAABCElEQVR4nGNgQAfbs7QZtmY2MGzJvMqwJfMZw9bMVQxbMtMYtmQqMRAFtmbuZ9ia+R8rJgpsTnegzAAGBoZPTYL/sWE6GLA5XZphS+ZenF7YkrGQYVUoG3bN29K1GLZkvsSpGY4ztmAaciaNlWFrxjVkhTU3N/3//vfXfxhAM2QSqgFbshLQbfr4+ztcMxYD/jJsTtdHMiBzM7oBm19eAmuc8+goLu/MQDIg4xG6Aq2DTf9///v7/++/f/8ND7dhC9DbyAb8wGYLyHYQALkG04DM7wgDtma+RleADD78/obNBa+QDMg4gcuAb39+/a+4sQFbdJ5AdkEH4fjHwB3I0WhAsgEgPUC9AFY8mXb6FDVPAAAAAElFTkSuQmCC"""),
        schema.Option(display = "USD", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAABKUlEQVR4nJVTQU5CMRB9G/UuiidQj+EVdEYlJngNv8FA4AK4kOjKFheKS42GHXxu8F0rmujiwzdTEdrfX4KTTNK0ndd5b16BfOjDTWg+h6IBFH1OU9ZV3FAJweiU16C4AU1jaM4CmUJxHe3dVb9Y08OCQjcVd10QRc2ii38RAKlZnMlp+zhuZ6/fbzOAAFCK24MNGMGsg52nyCsMd0JngOLY3jwZXpvLreR5GT36wv/D3tx+PPVeFjrl+LIIYCQURvkDuZx8uRpMsokBd4Wkd49CUV4kLwakMrwqpFANjS/fwZbfQQRjTxnJAgChczTwNEjR2V+fGonr/zaSjH8WYktF90tbWfMdensr7n8wIFzL0/Halpe9YjvEnuIwUVg88usTWUdzzvP4AXhkEFi6q3STAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Plant", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA50lEQVR4nGMQ/uT3H4F93wh/8tsl8tkvguE/AyMDMUAYxQAUw3YIvfHgI2zAR79/uA3x287wn4GJYWtmHMOWjFMMWzK/M2zN/A/GCBf4vsFjwH+Oi7H74JqQMZIXduEzgO9hKKbmrZlf4QaIfPaLwGeA0NsATAO2ZB5HBML/eiZQgOEzBMOAbenRKAEp9MaDDxRgRBmwJWMW9uj4z8Ao+Nk3TPiT307hj36vUQ3I+MawNeMEhs3EphEGcoEwuQb8X67r+X+p3p53qw3/v11j+P//Mr3d/5fpeWBXvEwPpIBsPAgMoBQAAAVUgtSQelqmAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Potted Plant", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA5UlEQVR4nMXQMQ6CMBQG4MfkKAVN9BJeRMDFzaCj9BQI8RQaVw+g1CuIeA5cTRvUsQaiKLQhaRz8k39q3te+ArxiMofnNajzMJiTmNRyiwMOGhA8hchLIMIPIJgXrcd8AZVSew0R3pRD363HoPZdhrTOM3GY4JvkBfZJBrTTsQhE+CgC1HJlgHEdicBhPhEA4KDlO8uQ6u3eShwWXmLH338CxLsD8WL5zQ0pgabw7YD/Uvg/kIcG+oWFiKuUhnoK77AA7VUBFqJdCdAALdQB3f8AoW4prxCgYQlkfrenCmTLTj8ffgL7RtuB0udv3QAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Bubbly", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAgElEQVR4nGNgwAE+NQn+R8YMpIJPlBrwf5nef2Q81AzYnO6wf6UNXHP9Op//IDHiDdiaud9hUzRC89ZMEN5PtO0MEA2YmChXbM1Yi9OALRmrCRuwJfMtHgNeEeP//2zHE/8Lvg4EY9ZjiaiGEALCn/z+48NDwAAGXAFIbBiQagAAOMXsHKsff1EAAAAASUVORK5CYII="""),
        schema.Option(display = "Confetti", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAABgElEQVR4nGNgwAa2Zv4HYzRgfvybjdmJr7vNTnw9YnLsuwtY8J9h6H8QJsYAsxPf/kMwIQNwAJgBDKQC8+NfzSFOJ2DAj/yEA1+8Wlbjstn0xNfDZie+O+LU/H+Z3v8/E53/v+HZ30OS098ynJL9WRL7H2QACH8Nrf7/hvlEB0ze9Pi3cvwGMB0Leyex9f+/eaZgA/4tMP7/XnIziiFmJ77VIetBCfw3/LunvGE58f+rfwPcFT9LY/6DxJANwWnAz7KoN2+5D/1/w37s/+8Ob7ghn0xm4TUEYnt0Lt+/hUYQf7Oc+P9Ba8n//0v1/8MC9C3nYfyGfE8sSAP7e6HR//fSm8CKf2RkogYoyABchnwNrpwH93cZxN9vBfb+/zvDCjVAIYbUYxjwmvXY6l+1IRj+/uzUgx6gKJphcgyvWY4/fi+/7v//xYZwf7/hPPz7DeuxM9/TM459S8ib8i243grdYoQBzMcbQIZ8Da068z0ndcP3+MLUl/b1PDhDHQ0AAGzYZo9VxMOOAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Balloons", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAABVklEQVR4nKWSO0sDQRSFp1FT+gckYKfmTmHAWEhKK0NqKwux8k+IoEgaCVlCfECaZFdDZpLKSrITrBQLsXATQey0jwlmzS5XZk1AzAwb8MBpDnO+ufMgZCjggzQwT8SY15UG5tm0NkhhCdJoUoEmdAOXwcYyTY16gYD7R8B9VDlbOUU0qcoHw/IgrSuPLC531ZAS3SBy7DDAdvVWMwU0CHDvIwywyjq6Y3RIcGH/AQDz7sMAm9VHNaAMd/IF9sMA+UpeB9gjC1WMAvdcXTnOP/HdWleUaR+tpbkJ/sGZbvfDn19ECFms4DRwv/G3TNlXwzWXbcXu13gSnyK/FS1iJMb8zEqt7yfqLiZ4vyAzLEYjaNJMz1rzexdJ7FrJgsyITjnh1I1mC3PNp61J8jEZdnsnWCicl/xNez4sH1P26nnGEM6DXCwdlit1bL/OGsI5z4nWW1j+DTLCMmUQLmPUAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Heart", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAwUlEQVR4nK2SzQrCMAyAc/TnIuw9XIIMvPkCgjs0N8FHkcl8tJ0UvOv0OUSNlSD4MzrXbRZyafp9SdMC/GPZMXeFzErQ5IJ8FeSjIKd2NO3Z4bwvZNZCfHrmTC7EiTIfMGd3YlsMQd5qOHPEmZ0sOqCVXQd84oZmCdpuU4EQ70HQXFoIzqDDaSxAPugV0hYdJKBPVTbpiuqb91OGs4Fu1Ki8s1EcfH+m0E/ihH0lP2GokHjBZZJacFHSCH5Jojiogh9P+KuoZdT7dgAAAABJRU5ErkJggg=="""),
        schema.Option(display = "Storefront", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeElEQVR4nGNgoAZQbX7/nxw8SAz4v1zf4f8yvf8gvH+lzX+GrZlgDBODYZg4SA1cfLm+A8P/pbr7YQIOm6IJGgBSAxdfqruf4d9tzf8wLPzJD46RxfHJMVBsAAgsevLlPzkYrBkEYALooUxIfCQZsIjSQCRoACUAAG4YRrHv30ITAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Megaphone", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAk0lEQVR4nGNgoCf4tO2c6JdN51d93Xz+PwiTpPnblvOhXzedfwXTTLQBn9BsJcmAb1hsxTDgg4DPf3SMSwPVDfhvEOxJkQF/DUIeDawB/w1DPSgPRBh4z++9GWYATOzrpgu+Xzedf0asAQ3oBoDAhy2XBL9uOjeToAEfBXx9sBmAzzUoCr6IekngMwCba3CpIwkAAK2I09xYTb8DAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Green Box", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAGRJREFUeNpi1KsrYSAFsCBzLjZ2Qxj69aW42AxAG/4TDYCKmaD6YCTCJGxsIGCE+wFoL5ocsjhclhHZ08T4gYmBRECyBkas8YDpn6HhByLjgQm/ajQ/QDXgUY2ZOhhJTd4AAQYAmvV1vwf5/YoAAAAASUVORK5CYII="""),
        schema.Option(display = "The Letter P", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMtJREFUeNpiFFNwYSAFMDGQCEjWwILGz8+JszDVg3M/ff567cbdtet3Pnn6EiLCiOaHQ3uWyEiLYxocFV9y4tRFdCfx8fJgVQ0EiXFBWPygpakMZ9u5xChpugLdAzOLG4sfzM304WwZaQlNDWW4hUDPYNGgpYGwYdnCHmSpXXuPYnGSuZkeVg+sXb8LiNBtANoO9DRcxZNn0HDcveco3CcoGjSR3NPcPv3T5y8EYtoC5mNgHOFSjWID0N6JUxeDNbzAkzQYaZ5aAQIMAENAQ6U0j5ejAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Hands - Finger Gun", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAkElEQVR4nGNgQAP/l+oa/1+m9/j/cl1PBnLA/2V6M/8v0/v/f6neI9I1r9Li+b9M9yPYgGV6/0k3YKl+Okwz0QaoNr//D8JQ558h24D/SBqJx7qHKTRA7z/pBizRS/6/VM/9/zJ97f+LzfhIM2Cp7hVKw6CeMgMWG2iRb8BSLM4n0QX1lBmAzfnIBhCR5mgDAPnOeKTjoJxhAAAAAElFTkSuQmCC"""),
        schema.Option(display = "Hands - Pray", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAABX0lEQVR4nGNgwAL+L9X7/H+ZXiuCr9sGEsOmFgP8X6XF83+Z3v//S/V+wMWW6v0Ei63S4iFswHJ9BbDiZXr/4WJQ/v8lhvKEDViha4TTgGV6hoQNWKbjitOApbouRHhBLxy3C/TDCBuwVK8Ctwv0Kogx4CIeL1zBr3mxgSlSgGELxP//l+mYYNc805j1/1K9ZQQNAKmZacwK16je9FHdtu3m/vdLrK+i2oTLBXr/3y+xvu3Qdu0QSC+DavO7farN7//XTVr4n1gDQGpBekB6GdRaX2uoNb/9odb87v/xuQlICnWvIgXsNZj4yblx/0FqVZvf/lJueqsNVqDS/K4OZKJrx6X/35eagEL7CXJggdggsZ9LTf57dF4A267S9K4WHg5a9f/ZVJveXwZJVPQvufh/lZYQZgyZ8RX3rToJUqPW+O4KSA+KAtXGj+Yaza9Xy9e/lMAVzSA5kBqQWpggAA3ZUoHzkYX5AAAAAElFTkSuQmCC"""),
        schema.Option(display = "Hands - Peace", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA5klEQVR4nK3OMUuCURQG4AsK/gdpCXSK93zU0CS0tIhzg1P/wAiSfoCzS6PgopyjOFuT6NhvaAjXNocGp3oj7+0zEP0+uB44wz3c85zXuVA0NGnyzvFZks6GOKFiScPcZRVNJjQhDd1/s5afyWsOAPebzyofXFwVA/DsZ+hnA2NchGvkCHW+VEpU+fRvecgGJjcFGlYhhVFxnYKWNDKB36JiGpbWVDylwEBOXZ6ior29+tf4okqPijuf6rx8AEgud4Hd3rMsNZrMYoDvPMsHALzFAYbbKMD5FI9RgE8SAVQ7K+btowE/yeeFOvmRptkAAAAASUVORK5CYII="""),
        schema.Option(display = "Hands - Shaka", value = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAjElEQVR4nGNgQAP/l+oa/1+m9/j/cl1PBnLA/2V6M/8v0/v/f6neI9I1r9Li+b9M9yPYgGV6/0k3YKl+Okwz0QaoNr//D8JQ558h24D/SBoJ4aFuwFLdK5S6oJ4yAxYbaJFvwFLdp/+X6vn+X6pn83+Zvvb/pbqCZAUiAuv+osAA3V//l+p2o6TEAQEAAFiTBKrY0ckAAAAASUVORK5CYII="""),
    ]
    layouts = [
        schema.Option(display = "Top and Bottom (With Banner and Divider)", value = "Top"),
        schema.Option(display = "Side by Side (With Icon)", value = "Side"),
        schema.Option(display = "Number Only", value = "Number"),
    ]
    fonts = [
        schema.Option(display = "Small", value = "tom-thumb"),
        schema.Option(display = "Medium (Default)", value = "tb-8"),
        schema.Option(display = "Large", value = "Dina_r400-6"),
        schema.Option(display = "XL", value = "6x13"),
        schema.Option(display = "XXL", value = "10x20"),
        schema.Option(display = "Mono Small", value = "CG-pixel-3x5-mono"),
        schema.Option(display = "Mono Medium", value = "CG-pixel-4x5-mono"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "code",
                icon = "fingerprint",
                name = "Counter ID",
                desc = "Enter your ilo.so counter ID",
                default = DEFAULT_CODE,
            ),
            schema.Dropdown(
                id = "layout",
                icon = "grip",
                name = "Layout",
                desc = "The layout of your display",
                options = layouts,
                default = DEFAULT_LAYOUT,
            ),
            schema.Dropdown(
                id = "font",
                icon = "font",
                name = "Font",
                desc = "Font used for text and numbers",
                options = fonts,
                default = DEFAULT_FONT,
            ),
            schema.Text(
                id = "banner",
                icon = "message",
                name = "Banner",
                desc = "Text to display in banner",
                default = DEFAULT_BANNER,
            ),
            schema.Dropdown(
                id = "color",
                icon = "eyeDropper",
                name = "Divider Color",
                desc = "The color of the divider",
                options = colors,
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "icon",
                icon = "icons",
                name = "Icon",
                desc = "The icon to display",
                options = icons,
                default = DEFAULT_ICON,
            ),
            schema.Toggle(
                id = "show_comma",
                icon = "toggleOn",
                name = "Show Comma",
                desc = "Enable commas in the number display",
                default = DEFAULT_SHOW_COMMA,
            ),
            schema.Toggle(
                id = "multiply_by_12",
                icon = "toggleOn",
                name = "Annual Multiplier",
                desc = "Multiply the counter by 12",
                default = DEFAULT_MULTIPLY_BY_12,
            ),
            schema.Toggle(
                id = "add_dollar_sign",
                icon = "toggleOn",
                name = "Add Dollar Sign",
                desc = "Add a dollar sign to the number",
                default = DEFAULT_ADD_DOLLAR_SIGN,
            ),
        ],
    )
