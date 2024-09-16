"""
Applet: Gen Con Countdown
Summary: Counts down to Gen Con
Description: Counts down the days until the next Gen Con.
Author: nikmd23
"""

load("encoding/base64.star", "base64")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

GENCON_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAYAAADiHqZbAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAALiIAAC4iAari3ZIAAAZLaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/Pg0KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDUgNzkuMTYzNDk5LCAyMDE4LzA4LzEzLTE2OjQwOjIyICAgICAgICAiPg0KICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPg0KICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChNYWNpbnRvc2gpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAxOS0wMS0yMVQxOTozMDo1OC0wODowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAxOS0wMS0yMVQxOTozMDo1OC0wODowMCIgeG1wOk1vZGlmeURhdGU9IjIwMTktMDEtMjFUMTk6MzA6NTgtMDg6MDAiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NGI4OTY3MGMtN2Y5MS00NzExLWFmN2EtYzlmZGMyNDMyOTc4IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6OTI4ZjY3NGQtNTBmMS1jNjQ2LWE5ZTItOTA3ZDI1ZWY0YWVkIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ODZjMzc4NDEtNGY5OS00YTNhLTlkNmMtYjExODc3Y2Q3Njg5IiBkYzpmb3JtYXQ9ImltYWdlL3BuZyIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgcGhvdG9zaG9wOklDQ1Byb2ZpbGU9InNSR0IgSUVDNjE5NjYtMi4xIj4NCiAgICAgIDx4bXBNTTpIaXN0b3J5Pg0KICAgICAgICA8cmRmOlNlcT4NCiAgICAgICAgICA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo4NmMzNzg0MS00Zjk5LTRhM2EtOWQ2Yy1iMTE4NzdjZDc2ODkiIHN0RXZ0OndoZW49IjIwMTktMDEtMjFUMTk6MzA6NTgtMDg6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChNYWNpbnRvc2gpIiAvPg0KICAgICAgICAgIDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo0Yjg5NjcwYy03ZjkxLTQ3MTEtYWY3YS1jOWZkYzI0MzI5NzgiIHN0RXZ0OndoZW49IjIwMTktMDEtMjFUMTk6MzA6NTgtMDg6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChNYWNpbnRvc2gpIiBzdEV2dDpjaGFuZ2VkPSIvIiAvPg0KICAgICAgICA8L3JkZjpTZXE+DQogICAgICA8L3htcE1NOkhpc3Rvcnk+DQogICAgPC9yZGY6RGVzY3JpcHRpb24+DQogIDwvcmRmOlJERj4NCjwveDp4bXBtZXRhPg0KPD94cGFja2V0IGVuZD0iciI/Poa6dHAAAATmSURBVFhHzZh7iJVFGIf3qJWXqEi7aJSK3Swzu9GNkKI00rALRlGkFpH9k38EIbFJEUZEEFRGkhRJV5Ks6KKGEBUSW1GUdrVyrejmrdTaNT2n55lv5uyc75zd6J/aHzw77/d+M9+83zcz78zZShuq1WonUyyEM2Avff+TdkMHtFcqlY5KDOxtGAr9RV1wrsG9jnFhcDXrd9gBI2BvHf+h3jS4rRgHFNdBf8FDsBi+5PNSpbYP9nmwCRbAdDgFdkJf+hAegMfDVaFTYSkMgOfhdsj1LEyCbufbDnuP6oYLrEE5DF6CLbAc9o/+p0Ctgcn6FPZ8WAFPw+jo2wmdcCuEegq7HdRmeAyGwGhYBbZRVSvmwd0Z2+u/o3DVFd6eMgWnbgmVEXbyb4IXwU+eOlKHxqrW9d6y4C00GeYUZl1VP21SFRYVZtCMWCZdQ4NR0e5Ld4Hz+AcYoiNqMO2P13CqUMyGT7xGLkanToPy4DbQ6BcNHmIxzj+ZBsG7MC1cNcu5MhceCVdtbSMhpKpMN/LsqzToy4V2KWzxGpXrNgRXntzpTZ6ByyLzYA5cDnsg159gh45AbzKAJQR4UrioVL6muBLKzwrKgxtFoxA9jSw2+wedAJPwLRfsd8DUk7dVBv1kLNVvkIYtl0P4An2ZnuzrDYrV2mXlHQyHMwszaE0sJ8DNhRk0Fm6ApmGImg8Or4vLtJPkF01faAw8R4BOFQP8xy+n7qVB2r7uhjTUbitJPTmhcThSXYPvBnNlyp/bwRz5UbgqZN68j/6Kq1biZp5K1KvgZPbe4TDDMl4fCc4ZdTbUV5g2mKucHuGlKefBYjgwVELY1vkZkq6N/puKy7qq5hsn8TArZHJvWwlrwa9mcB4KjoMk9+OWw5HpCDDQDeGqR06f9GL2tQoc6ok6okIybBWc8+MteB8cEvPbVHDZHwaHQJK+18CV5xxyAU2BwaDWg/eSHPajC7Pte1hXmHWdDk6Hmp+zPKzvwXhrUY6FK2AMDABfJt8hnDNucwPhIjgLbOfQvgLKYa0nY+zh8I03kHUOin4ZD+tANW1fn8F+sfJp8IfOWJ4T/Sm4haBL36PBU+j66BsEK4OnVlsP+fycCKnfLvDlp4SrHjUFd3Fsr99clGstpC/3HYQjFOUI2A1JvmB6hgtoj07kQqinH+yZUPUGmgruHrka9lbn3goNbljkOU+5L14HB8PL5KZdOpHHm4GFGXQM7KtBHedbSh8GNpdnh5Hhnsele7SRcZTTWoOjkwae5ZLqyz/TEjgf8tVXrmcQua8zlsrV/gQBpn7bwcXUUnlwIVtnyhNvWWklqlb1cl/5tHEJhAMmH8OscDXkL1BXHpwrMw2HxVf+Kelz+Bb83ZG0MZZJ5q10uvH5DntS2g4WcC8cyehrG3wavCXlwTnBZxVm0P2xTDLfeYJwnkzj4UfpRM6pnwozaDWdpS83E9IZ0C0tbXH2u5RnhJTVq6iQr9ZtcGK85T2D8Bj9IBwL48CTrvoAwtyinA4b4WNwQeibANZ1ZT8MrnTzmKfkXaC+gLD/UjZtXzq3FnZd28HfAyPBdtYZCrMh3xOVvw9mQcqNYgK+DXyOWgTmtZwfIclE7JRKvyuSunybvn4aujU5HGbx8oLJ5R77K1jHo1dvx6l/o/DTsP/+qNaKAfazf0dUOv4G33q0GEO42gwAAAAASUVORK5CYII=
""")
NOW = time.now().in_location("Etc/UTC")
START_DATES = [
    1659589200,  #2022
    1691038800,  #2023
    1722488400,  #2024
    1753938000,  #2025
    1785387600,  #2026
]

def main():
    GENCON_START = None
    for start_date in START_DATES:
        if start_date > NOW.unix:
            GENCON_START = time.from_timestamp(start_date)
            break

    DIFF = GENCON_START - NOW
    DAYS = math.ceil(DIFF.hours / 24)

    if DAYS <= 360:
        OUTPUT = render.WrappedText("{} more {}".format(DAYS, humanize.plural_word(DAYS, "day!", "days")), align = "center")
    else:
        OUTPUT = render.WrappedText("Go now!", align = "center")

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Padding(pad = 2, child = render.Image(src = GENCON_LOGO)),
                OUTPUT,
            ],
        ),
    )
