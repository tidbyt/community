"""
Applet: Madison Metro Bus
Summary: Track Madison Buses
Description: Check arrivals for a given stop in Madison.
Author: Corey Johnsen
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

key = secret.decrypt("AV6+xWcE/7e28gqrgBzHffwU7Lqfe7ofS8MnQtKIcjgUk3BVlrc1H0+oI42zaCBrVcNM+hk/NBRzXbo+9cSb4k/QQWBbvzGwlL0PR6yJYb1nhhiv431Ic2WOactNFxN4APmVpn9gqI6viTaG")
URL = "https://api.smsmybus.com/v1/getarrivals?key=" + str(key) + "&stopID="

def main(config):
    next_n = int(config.get("next_n", 3))
    stop = config.get("stopID", 863)
    min_mins = int(config.get("min_mins", 2))
    updates = []

    rep = http.get(URL + str(stop), ttl_seconds = 60)

    json = rep.json()
    if int(json["status"]) < 0:
        return render.Root(
            child = render.Marquee(width = 64, child = render.Text("Error: %s" % (json["description"]["msg"]), color = "#FF0000"), offset_start = 5, offset_end = 32),
        )

    for i in range(next_n):
        bus = json["stop"]["route"][i]
        if bus["minutes"] < min_mins:
            i -= 1
        else:
            updates.append(render.Row(children = [
                render.Text(bus["routeID"] + ": "),
                render.Marquee(width = 64, child = render.Text("%s min (%s)" % (int(bus["minutes"]), bus["arrivalTime"]))),
            ]))

    children = [render.Text("Stop %s Arrivals" % (stop), color = "#2222FF", font = "tom-thumb")]
    for update in updates:
        children.append(update)
    return render.Root(
        child = render.Column(
            children = children,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stopID",
                name = "Stop ID",
                desc = "The stop ID to display arrivals for.",
                icon = "gear",
            ),
            schema.Text(
                id = "next_n",
                name = "Num Buses",
                desc = "Number of buses to display.",
                icon = "gear",
            ),
            schema.Text(
                id = "min_mins",
                name = "Minimum Mins",
                desc = "Minimum minutes for bus arrival to display.",
                icon = "gear",
            ),
        ],
    )
