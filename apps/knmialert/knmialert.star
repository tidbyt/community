"""
Applet: KNMIalert
Summary: Weather alerts Netherlands
Description: Only displays active live weather alerts by KNMI for The Netherlands.
Author: PMK (@pmk)
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")

COLOR_CODES = {
    "yellow": "#ffe959",
    "orange": "#ef5d12",
    "red": "#ce1f00",
}

def get_page(ttl_seconds = 60 * 5):
    url = "https://knmi.nl/home"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("KNMI request failed with status %d @ %s", response.status_code, url)
    return response.body()

def get_alert(page_contents):
    alert_element = html(page_contents).find("main > .wrapper--alert > .alert")
    if alert_element.len() != 1:
        return {
            "is_active": False,
        }

    return {
        "is_active": True,
        "type": alert_element.attr("class").replace("alert", "").replace("--", "").strip(),
        "title": alert_element.find(".alert__heading").text().strip(),
        "text": alert_element.find(".alert__description").text().strip(),
    }

def main():
    knmi_page_contents = get_page()
    alert = get_alert(knmi_page_contents)

    if alert["is_active"]:
        alert_title_fill = [render.Text(content = alert["title"], color = "#000", offset = 1)] * 12
        alert_title_empty = [render.Text(content = alert["title"], color = COLOR_CODES[alert["type"]], offset = 1)] * 12

        return render.Root(
            show_full_animation = True,
            max_age = 60 * 60,
            child = render.Stack(
                children = [
                    render.Box(
                        width = 64,
                        height = 32,
                        color = COLOR_CODES[alert["type"]],
                    ),
                    render.Padding(
                        pad = (2, 4, 2, 2),
                        child = render.Animation(
                            children = alert_title_fill + alert_title_empty,
                        ),
                    ),
                    render.Padding(
                        pad = (2, 14, 2, 2),
                        child = render.Box(
                            width = 60,
                            height = 14,
                            color = "#000",
                            child = render.Marquee(
                                width = 56,
                                align = "center",
                                offset_start = 56,
                                offset_end = 56,
                                child = render.Text(
                                    content = "KNMI: {}".format(alert["text"]),
                                    color = "#fff",
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        )

    return []
