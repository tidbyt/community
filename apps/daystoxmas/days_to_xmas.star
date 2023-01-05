"""
Applet: Days to Xmas
Summary: Displays Days to Xmas
Description: Display a countdown of days left til Christmas Day.
Author: Godfrey Systems Web Development
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

PRESENT_ICON = base64.decode("R0lGODlhEgAOAPeWAP8AAPYVGP8AAQF1Ef8lMv8mM4swD0FYCgCLEwBUCAttBP85QQBRB+AZDv8UHACEE/8DBP8DB/oNDfwiJRVxBdgCAv8aM/8gLgCfF/8VHuUAABB8D/AAAQ5tBACMDgCPDP8qLQCeGPwpKzplDgyRHQCTFj5oD/9FS/8KFDVyEwKjGP85TQCADkVWCgCCC/81OO4XF/AMDPQ5OgBwCApoDf8iK/8wM/IsLo9IIwCICu4AAD9LAACsEv9RXf9QVBpjCxh1ChxlABRhC9IPCGNlIRBzCgmHEAB5EACDEQtxCixPAACQC/QxPABtDkBaCv8ACgSRFAN1EP8tNgCNEwBmDP8tNNkAAOMjHf8RFw96EP9ITOYDAyZ0CxN4DPwUF+8CAuwAAP8PGB96CvEoKBSADwB2D0hxFgCPCxN2EACZFTRNCWw/Bu81NQCZFlY+BwCAEeBANwtsBP88PgCcF+8BAf+LlAB5BwCGEgBhC/8VK/UiI/8WGpM2ByRxD/8eJqhOPhpoBv9AQ+8AAACFCf8MJQCaF/8JF/8iLACGBP8XM/QAAP82QTJMAvAgIuElHQBuDv8lLf8+Tf9ETgCCEQFwDQCYEgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjJhOGJlNzFjLTdhOGEtNzU0MC04Mjg2LWQzNDg5ZWUxMGUxOCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpFNzA3RTA5QzY0M0QxMUVEOTNEQ0QwNjUwRTJDNUEwOCIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpFNzA3RTA5QjY0M0QxMUVEOTNEQ0QwNjUwRTJDNUEwOCIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjMuMyAoV2luZG93cykiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDoxOWIzNTdlNi1mM2ZjLTQxNDktOTYyOC1mMWRjYzFhNDAyMTUiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MmE4YmU3MWMtN2E4YS03NTQwLTgyODYtZDM0ODllZTEwZTE4Ii8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+Af/+/fz7+vn49/b19PPy8fDv7u3s6+rp6Ofm5eTj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66trKuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVVRTUlFQT05NTEtKSUhHRkVEQ0JBQD8+PTw7Ojk4NzY1NDMyMTAvLi0sKyopKCcmJSQjIiEgHx4dHBsaGRgXFhUUExIREA8ODQwLCgkIBwYFBAMCAQAAIfkEAQAAlgAsAAAAABIADgAACM0ALQkU+CjEwDJHBipsMrAQJSSWqGBo80ChJQYIpnhwMceSGid9LNFQoTDBQD5EhKRhYWfGGyhZ3Fi6UwKPQBSJDKBRsuYPjh0DoojhMknhDQJBPjCxYCgPoSIKFl2wyCFDikFsqoABsaDDhgJYLDaKNKKSBj8wIAAg0cWBCIsxnpg4c2WPoECSklA4NMHiGCkHljjSQsfHiThAwnixKGNFC0Rw6nwBEMEIoB42LFpSZIZHAwE6XkDKQSaA5oE/htSQIEcPo9OaK2yxAjsgADs=")

def main(config):
    timezone = config.get("$tz", "America/Chicago")  # Utilize special timezone variable
    now = time.now().in_location(timezone)
    today = time.time(year = now.year, month = now.month, day = now.day, location = timezone)
    current_xmas = time.time(year = today.year, month = 12, day = 25, location = timezone)

    if today > current_xmas:
        current_xmas = time.time(year = today.year + 1, month = 12, day = 25, location = timezone)

    xmas_datestring = current_xmas.format("Jan 02, 2006")

    date_diff = current_xmas - now
    days = math.ceil(date_diff.hours / 24)

    description = "{} left".format("Day" if days == 1 else "Days")

    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 32,
                        height = 16,
                        child = render.Image(
                            src = PRESENT_ICON,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (32, 0, 0, 0),
                    child = render.Box(
                        width = 32,
                        height = 16,
                        child = render.Text(
                            content = str(days),
                            color = "#FFFFFF",
                            font = "10x20",
                            height = 0,
                            offset = 0,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, 16, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 8,
                        child = render.Text(
                            content = description,
                            color = "#FFFFFF",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, 24, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 8,
                        child = render.Text(
                            content = xmas_datestring,
                            color = "#FFFFFF",
                            font = "CG-pixel-4x5-mono",
                        ),
                    ),
                ),
            ],
        ),
    )
