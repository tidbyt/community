"""
Applet: Sellands Specials
Summary: Selland's weekly specials
Description: Show weekly dinner for two specials at Selland's restaurants.
Author: Matt Kent
"""

load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("time.star", "time")

SELLANDS_MENU_URL = "https://www.sellands.com/menu/specials"

UPCASE_MONTH_TO_INT = {
    "JANUARY": 1,
    "FEBRUARY": 2,
    "MARCH": 3,
    "APRIL": 4,
    "MAY": 5,
    "JUNE": 6,
    "JULY": 7,
    "AUGUST": 8,
    "SEPTEMBER": 9,
    "OCTOBER": 10,
    "NOVEMBER": 11,
    "DECEMBER": 12,
}

def get_data(url):
    res = http.get(url, ttl_seconds = 3600)  # cache for 1 hour
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res

def month_to_int(month):
    return UPCASE_MONTH_TO_INT[month]

# Convert "FEBRUARY 7" to a Time object at 2024-02-07T00:00:00
def partial_date_str_to_time(today, date_str):
    month, day = date_str.split(" ")
    return time.time(year = today.year, month = month_to_int(month), day = int(day))

def main():
    resp = get_data(SELLANDS_MENU_URL)

    doc = html(resp.body())
    items = doc.find("[name=\"dinner-for-two\"]").parent().find(".cafe-menu-item")

    monthly_menu = []
    today = time.now()

    for i in range(items.len()):
        item = items.eq(i)

        # Ex: FEBRUARY 26 - MARCH 2
        date_range = item.find(".menu-item-title").first().text()
        start_date_str, end_date_str = re.findall("\\w+\\s+\\d+", date_range)
        start_date = partial_date_str_to_time(today, start_date_str.strip())
        end_date = partial_date_str_to_time(today, end_date_str.strip())

        # Adjust end date to midnight of the next day
        end_date = end_date + (time.hour * 24)

        monthly_menu.append({
            "description": item.find(".menu-item-description").first().text(),
            "start_date": start_date,
            "end_date": end_date,
        })

    title_text = "@Sellands"
    menu_text = "No menu today"

    for item in monthly_menu:
        if today >= item["start_date"] and today < item["end_date"]:
            menu_text = item["description"]

    if humanize.day_of_week(today) == 0:
        menu_text = "Spaghetti Sunday!"

    return render.Root(
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 16,
            offset_end = 32,
            align = "start",
            child = render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Text(
                        content = title_text,
                        color = "5c462d",
                    ),
                    render.WrappedText(
                        content = menu_text,
                        color = "bca529",
                    ),
                ],
            ),
        ),
    )
