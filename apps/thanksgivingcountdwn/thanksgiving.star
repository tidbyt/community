load("encoding/base64.star", "base64")
load("render.star", "render")
load("time.star", "time")
load("math.star", "math")  # Load the math module


def main(config):


    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)

    thanksgiving_year = now.year
    if now.month > 11 or (now.month == 11 and now.day > 23):
        thanksgiving_year += 1

    thanksgiving = time.time(year=thanksgiving_year, month=11, day=23, hour=0, minute=0, location=timezone)
    days_until_thanksgiving = math.ceil(time.parse_duration(thanksgiving - now).seconds / 86400)

    turkey_gif = base64.decode("R0lGODlhGQAgALMJAGAsBl8pAda0FYYNDf7SBAAAAP///7dOAF0oAf///wAAAAAAAAAAAAAAAAAAAAAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMwNjcgNzkuMTU3NzQ3LCAyMDE1LzAzLzMwLTIzOjQwOjQyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjI1NzkwNjNkLTc2ZWMtNGE0ZC05ZTFhLWQ0OWY4NWM4YjZjZCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo5OTE3RDU0NzVDMDIxMUVFQjc1RkM1OTQ1N0YzRDdGQiIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo5OTE3RDU0NjVDMDIxMUVFQjc1RkM1OTQ1N0YzRDdGQiIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxNSAoV2luZG93cykiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo4ZDZlZmVkZi1kYjcxLTMwNDctODg1MS1mZDQxNDQxMDQ4MjYiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MjU3OTA2M2QtNzZlYy00YTRkLTllMWEtZDQ5Zjg1YzhiNmNkIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+Af/+/fz7+vn49/b19PPy8fDv7u3s6+rp6Ofm5eTj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66trKuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVVRTUlFQT05NTEtKSUhHRkVEQ0JBQD8+PTw7Ojk4NzY1NDMyMTAvLi0sKyopKCcmJSQjIiEgHx4dHBsaGRgXFhUUExIREA8ODQwLCgkIBwYFBAMCAQAAIfkEBQoACQAsAAAAABkAIAAABMKQkEOrvNNeXTXuHxV6mQdu3YGKUqpuSCzPyHrSuNxaVe4jJ0rgJzMYDUAMIXY80prGWosJjVKrQAqi6rxCs4ctF+n9SsTGgtqZXjelaIO6wJa7ndrmvL5/a+NfY1EXZXVcMVNENAMzKDMCkJGSA4wyGo+SmZSWl5iZAgibiByemaGVSh2lkDGiLBmEMqaUjCUtGDSRp4wiJBm5rZuvr785tLapFsaUO8kvSzO0zM07z2HRtM+wyBOL2Sw81tcy0iAdEQAh+QQFAAAJACwMABMACQANAAAEHzDJOaZN9cqs+fXIBooWEg7oZBJoZZpY+iItOtfDXUcAIfkEBQAACQAsAAADABkAHQAABLaQSHLqQThrRG2d1CZmnjWNKGJ6QJoZsKFKFhbH2w1ztK3vvt+MgPjhgrph0ShDJg/EW2GKg00Lz4uUurNycZWlF9s1XJMS501s5BHZa2az53J1whmBfr8fCDZ3bxh8fAMDGx8nGoR6hockUBMXeYyOkJEmi4SWGJImaZR9hhiRHSCToQiOA5+ldxt/qwOBpzUisrOmnlCoGrIgNCu9vo7Anx0ov8GltiPKx80iB6u8zB8pFY4VEQAh+QQFAAAJACwAAAAAAQABAAAEAjBFACH5BAUAAAkALAAAAAABAAEAAAQCMEUAIfkEBQAACQAsAAAAAAEAAQAABAIwRQAh+QQFAAAJACwAAAAAAQABAAAEAjBFACH5BAUAAAkALAAAAAABAAEAAAQCMEUAIfkEBQAACQAsAAAAAAEAAQAABAIwRQAh+QQFAAAJACwBAAMAGAAdAAAEozDJmc4h2FpMuzxex4VkSIAeUk5Ia3VB0s4qiYxlm3N1WBs+EALokxA7CMuQYmjKes2jjLCUFIyS5TUhvVUTW6IWyzoMiYU0C5jellvOlNRDkHGj+Ds+StGxaDR2E3VZEwIrOYaHiBV9PYuMSDUCkCSEkhKUfZGCCZoSAywrfp6VH4g9nh4Xo6khKIkrsDYhoR+zKbW2FbibHgPAt7EdwMEvCREAIfkEBQAACQAsAAAEABgAHAAABJAwyYmmneTeqnXuXKcdWhCKBkVSSWqdLvVV8SvVaoLgbAuSOxGHJ0EQgpLCrZhS+mTIhNMVnL4OUauuuVTRhMRi5quJbhJjkRrTSwjWl5Vu8l5z5HM6qCj5tOtnc342EoB8FniEbopoaid1J3B5hZGSlSNwlwMDEollHZxog3sXm30Eo4EWpgkHqHYapgezfhEAIfkEBQAACQAsAAAEABgAHAAABIUwyXmmneheonvuVedpRyBik/FJ1SoZlpuoEie/0j1nhD7nHdrBB0sQEcOUpPDKFJkp5OrZ/CWgzZ7yWqVGbSJamGcMEsuh02mV9o1qKHUcPrcILrJ2516fcIB2eCJ/ZRN8gCAxEgIDchZpRneNjiwdA5OUkBKYmRaXnI6Ql5SPnqChpmoRADs=")
    
    if days_until_thanksgiving == 0:
        content_text = "Today is\nThanks\nGiving"
    else:
        content_text = "{} days\nuntil\nThanks\nGiving".format(days_until_thanksgiving)

    return render.Root(
        delay=200,
        child=render.Row(
            main_align="left",
            cross_align="center",
            expanded=True,
            children=[
                render.Padding(
                    child=render.Image(
                        src=turkey_gif,
                        width=25,
                        height=32,
                    ),
                    pad=(0, 0, 2, 0),
                ),
                render.WrappedText(
                    content=content_text,
                    font="5x8",
                    color="#ff751a",
                    align="center",
                ),
            ],
        ),
    )

