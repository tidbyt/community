load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def get_next_lunch(school_name):
    start = time.now()
    end = start + time.parse_duration("%sh" % 24 * 7)

    url = "https://api.mealviewer.com/api/v4/school/{}/{}/{}/0".format(
        school_name,
        start.format("01-02-2006"),
        end.format("01-02-2006"),
    )

    body = cache.get(url)
    if body == None:
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        response = http.get(url, headers = headers)
        body = response.body()
        cache.set(url, body, ttl_seconds = 3600)

    data = json.decode(body)

    num_schedules = len(data["menuSchedules"])

    if (num_schedules == 0):
        return "ERROR", "Invalid school ID"

    for i in range(num_schedules):
        if i == 0 and start.hour >= 12:
            pass
        else:
            schedule = data["menuSchedules"][i]
            title = "LUNCH TODAY" if i == 0 else "LUNCH TOMORROW" if i == 1 else "LUNCH " + schedule["dateInformation"]["weekDayName"].upper()
            if (len(schedule["menuBlocks"]) >= 2):
                lunch = schedule["menuBlocks"][1]["cafeteriaLineList"]["data"][0]["foodItemList"]["data"][0]
                name = lunch["item_Name"] if lunch["item_Type"] == "Entrée" else lunch["item_Type"]
                return title, name

    return "NEXT LUNCH", "No upcoming lunch"

def main(config):
    school_name = config.get("school_id", "KingstonCitySchoolDistrictElementarySchools")

    title, name = get_next_lunch(school_name)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    color = "#7f2629",
                    child = render.Padding(
                        pad = (0, 2, 0, 0),
                        child = render.Text(
                            title,
                            color = "#000000",
                            font = "tom-thumb",
                        ),
                    ),
                ),
                render.Box(
                    child = render.WrappedText(
                        name,
                        color = "#ADD8E6",
                        width = 64,
                        align = "center",
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "school_id",
                name = "School MealViewer ID",
                desc = "The ID of your school, the last part of your MealViewer URL",
                icon = "gear",
                default = "KingstonCitySchoolDistrictElementarySchools",
            ),
        ],
    )
