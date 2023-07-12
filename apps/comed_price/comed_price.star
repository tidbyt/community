"""
Applet: ComEd Price
Summary: ComEd Hourly Pricing
Description: Pulls the current hour average price from hourlypricing.comed.com.
Author: Andrew Hill
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")

COMED_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAACXBIWXMAAAsTAAALEwEAmpwYAAAF0WlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4xLWMwMDEgNzkuYThkNDc1MzQ5LCAyMDIzLzAzLzIzLTEzOjA1OjQ1ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjQuNiAoTWFjaW50b3NoKSIgeG1wOkNyZWF0ZURhdGU9IjIwMjMtMDctMDFUMTU6NDA6MTItMDU6MDAiIHhtcDpNb2RpZnlEYXRlPSIyMDIzLTA3LTAxVDE2OjIxOjE3LTA1OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIzLTA3LTAxVDE2OjIxOjE3LTA1OjAwIiBkYzpmb3JtYXQ9ImltYWdlL3BuZyIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDozMDg0YjMwOS1mNWYzLTQxMjktODNkZS0zYTMyMGZmMDRjMGIiIHhtcE1NOkRvY3VtZW50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
""")

CURRENT_HOUR_AVG = "https://hourlypricing.comed.com/api?type=currenthouraverage&format=text"

def main():
    rep = http.get(CURRENT_HOUR_AVG, ttl_seconds = 360)
    if rep.status_code != 200:
        fail("ComEd request failed with status %d", rep.status_code)

    price = float(rep.body().split(":")[1].split(",")[0])

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(src = COMED_ICON, width = 17, height = 17),
                        render.Text(content = "%s¢" % humanize.float("0.#", price), font = "6x13"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "end",
                    children = [
                        render.Text(content = "ComEd Price", offset = -1, font = "tb-8"),
                    ],
                ),
            ],
            main_align = "center",
            cross_align = "center",
            expanded = True,
        ),
    )
