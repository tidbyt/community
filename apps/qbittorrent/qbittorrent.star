"""
Applet: Qbittorrent
Summary: Monitor your torrent server
Description: Displays server stats (speeds and active counts) along with the progress of your newest torrents.
Author: DoubleGremlin181
"""

load("animation.star", "animation")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DEVICE_WIDTH = 64
DEVICE_HEIGHT = 32
HEADER_HEIGHT = 8
ROW_HEIGHT = 12
DELAY_MS = 60

def main(config):
    servername = config.get("servername", "My Seedbox")
    base_url = config.get("base_url", None)
    username = config.get("username", None)
    password = config.get("password", None)

    if not base_url or not username or not password:
        return render_header(servername, [render.WrappedText(content = "Enter server details")])

    else:
        base_url = base_url.rstrip("/")
        sid = server_login(base_url, username, password)

        if not sid:
            return render_header(servername, [render.WrappedText(content = "Login failed :(")])
        else:
            speeds = get_transfer_speeds(base_url, sid)
            active_counts = get_active_torrents(base_url, sid)
            torrents = get_latest_torrents(base_url, sid)

            if not speeds or not active_counts or not torrents:
                return render_header(servername, [render.WrappedText(content = "Failed to get data")])

            # Get pages frames for the list of torrents.
            pages = [[get_stats_frame(speeds, active_counts)] * 30] + [get_page_frames(t) for t in torrents]
            if not pages:
                return []

            # Generate the list of frames to render.
            frames = []
            if len(pages) > 1:
                # Multiple pages to show, yay!
                for i, page_frames in enumerate(pages):
                    next_page_frames = pages[(i + 1) % len(pages)]
                    frames.extend(page_frames)
                    frames.extend(get_scroll_frames(page_frames[0], next_page_frames[0]))
            else:
                # Just one page, but that's okay.
                frames.extend(pages[0])

            # Render the list of frames as an aniamtion.
            return render_header(servername, frames)

def server_login(base_url, username, password):
    # Login to the server and return the session ID
    url = "{}/api/v2/auth/login?username={}&password={}".format(base_url, username, password)
    response = http.get(url, ttl_seconds = 60)

    if response.body() == "Ok.":
        return response.headers["Set-Cookie"].split(";")[0][4:]
    else:
        return None

def get_transfer_speeds(base_url, sid):
    url = "{}/api/v2/transfer/info?SID={}".format(base_url, sid)
    headers = {"Cookie": "SID={}".format(sid)}
    response = http.get(url, headers = headers, ttl_seconds = 60)

    if response.status_code != 200:
        return None
    else:
        data = response.json()
        download_speed = speed_to_human(data["dl_info_speed"])
        upload_speed = speed_to_human(data["up_info_speed"])
        return {
            "download_speed": download_speed,
            "upload_speed": upload_speed,
        }

def get_active_torrents(base_url, sid):
    url = "{}/api/v2/torrents/info?filter=active&SID={}".format(base_url, sid)
    headers = {"Cookie": "SID={}".format(sid)}
    response = http.get(url, headers = headers, ttl_seconds = 60)

    if response.status_code != 200:
        return None
    else:
        data = response.json()
        active_torrents = len(data)
        active_downloads = len([torrent for torrent in data if torrent["progress"] < 1])
        active_uploads = len([torrent for torrent in data if torrent["progress"] == 1])
        return {
            "active_torrents": active_torrents,
            "active_downloads": active_downloads,
            "active_uploads": active_uploads,
        }

def get_latest_torrents(base_url, sid):
    url = "{}/api/v2/torrents/info?limit=3&sort=added_on&reverse=true&SID={}".format(base_url, sid)  # Get the 3 most recent torrents
    headers = {"Cookie": "SID={}".format(sid)}
    response = http.get(url, headers = headers, ttl_seconds = 60)

    if response.status_code != 200:
        return None
    else:
        data = response.json()
        torrents = []
        for torrent in data:
            torrents.append({
                "name": torrent["name"],
                "progress": torrent["progress"],
                "added_on": torrent["added_on"],
                "download_speed": speed_to_human(torrent["dlspeed"], 0),
                "upload_speed": speed_to_human(torrent["upspeed"], 0),
            })
        return torrents

def speed_to_human(speed, precision = 2):
    if speed < 1024:
        return "{}B/s".format(round(speed, precision))
    elif speed < 1024 * 1024:
        return "{}KB/s".format(round(speed / 1024, precision))
    elif speed < 1024 * 1024 * 1024:
        return "{}MB/s".format(round(speed / (1024 * 1024), precision))
    else:
        return "{}GB/s".format(round(speed / (1024 * 1024 * 1024), precision))

def round(num, precision):
    if precision == 0:
        return int(num)
    else:
        return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def get_stats_frame(speeds, active_counts):
    return render.Box(
        child = render.Column(
            expanded = True,
            main_align = "space_bewteen",
            cross_align = "start",
            children = [
                render.Box(
                    height = ROW_HEIGHT,
                    child = render.Row(main_align = "start", children = [
                        render.Box(width = 1),
                        render.Text("↓ ", color = "#00FF00"),
                        render.Column(children = [
                            render.Box(height = 1),  # Aligning tom-thumb font with tb-8
                            render.Row(children = [
                                render.Text("{}".format(speeds["download_speed"]), font = "tom-thumb"),
                                render.Text("({})".format(active_counts["active_downloads"]), font = "tom-thumb"),
                            ]),
                        ]),
                    ]),
                ),
                render.Box(
                    height = ROW_HEIGHT,
                    child = render.Row(main_align = "start", children = [
                        render.Box(width = 1),
                        render.Text("↑ ", color = "#FF0000"),
                        render.Column(children = [
                            render.Box(height = 1),  # Aligning tom-thumb font with tb-8
                            render.Row(children = [
                                render.Text("{}".format(speeds["upload_speed"]), font = "tom-thumb"),
                                render.Text("({})".format(active_counts["active_uploads"]), font = "tom-thumb"),
                            ]),
                        ]),
                    ]),
                ),
            ],
        ),
        height = DEVICE_HEIGHT,
    )

def get_page_frames(torrent):
    # This function is derived from a similar function in the
    # USGS Earthquakes Applet by Chris Silverberg (csilv).
    # https://github.com/tidbyt/community/blob/main/apps/usgsearthquakes/usgs_earthquakes.star

    name_str = torrent["name"]
    dw_speed = torrent["download_speed"]
    up_speed = torrent["upload_speed"]

    # Get the length of the place string.
    name_len = render.Text(name_str).size()[0]

    # Generate the pie chart segments.
    download_percent = torrent["progress"] * 100

    # Rotating the pie chart to start from the top
    if download_percent <= 25:
        pie_segments = [0, 75, download_percent, 25 - download_percent]
    else:
        pie_segments = [download_percent - 25, 100 - download_percent, 25, 0]

    if name_len > DEVICE_WIDTH:
        # Place string requires scrolling, so generate the first set of frames.
        frames_a = [
            get_page_frame(name_str, place_x, dw_speed, up_speed, pie_segments)
            for place_x in range(0, -name_len, -1)
        ]

        # Followup with the next set of frames.
        frames_b = [
            get_page_frame(name_str, place_x, dw_speed, up_speed, pie_segments)
            for place_x in range(DEVICE_WIDTH, -1, -1)
        ]

        # Return the combination.
        return frames_a + frames_b

    else:
        place_x = int((DEVICE_WIDTH - name_len) / 2)
        return [
            get_page_frame(name_str, place_x, dw_speed, up_speed, pie_segments),
        ] * DEVICE_WIDTH

def get_page_frame(name_str, name_x, dw_speed, up_speed, pie_segments):
    # This function is derived from a similar function in the
    # USGS Earthquakes Applet by Chris Silverberg (csilv).
    # https://github.com/tidbyt/community/blob/main/apps/usgsearthquakes/usgs_earthquakes.star

    return render.Box(
        child = render.Column(
            expanded = True,
            main_align = "space_bewteen",
            cross_align = "start",
            children = [
                render.Box(
                    render.Row(children = [
                        render.Box(width = 1),
                        render.PieChart(weights = pie_segments, colors = ["#51CB20", "#808080"], diameter = 8),
                        render.Box(width = 1),
                        render.Box(
                            child = animation.AnimatedPositioned(
                                child = render.Text(name_str),
                                curve = "linear",
                                duration = 0,
                                x_start = name_x,
                                x_end = name_x,
                            ),
                        ),
                    ]),
                    width = DEVICE_WIDTH,
                    height = ROW_HEIGHT - 2,
                ),
                render.Box(render.Row(
                    children = [
                        render.Text(content = dw_speed, color = "#51CB20", font = "tom-thumb"),
                        render.Text(content = up_speed, color = "#E3170A", font = "tom-thumb"),
                    ],
                    expanded = True,
                    main_align = "space_around",
                ), height = ROW_HEIGHT),
            ],
        ),
        height = DEVICE_HEIGHT,
    )

def get_scroll_frames(item, next_item):
    # This function is derived from a similar function in the
    # BGG Hotness Applet by Henry So, Jr.
    # https://github.com/tidbyt/community/tree/main/apps/bgghotness
    return [
        render.Padding(
            pad = (0, offset, 0, 0),
            child = render.Stack([
                item,
                render.Padding(
                    pad = (0, DEVICE_HEIGHT, 0, 0),
                    child = next_item,
                ),
            ]),
        )
        for offset in range(-1, -DEVICE_HEIGHT - 1, -1)
    ]

def render_header(servername, frames):
    return render.Root(
        child = render.Column(children = [
            render.Box(
                height = HEADER_HEIGHT,
                width = DEVICE_WIDTH,
                color = "#004080",
                child = render.Text(servername),
            ),
            render.Box(height = 2, width = DEVICE_WIDTH),
            render.Animation(frames),
        ]),
        delay = DELAY_MS,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "servername",
                name = "Server Name",
                desc = "Enter the name of your server",
                icon = "font",
            ),
            schema.Text(
                id = "base_url",
                name = "Server Host or IP",
                desc = "Enter the URL of your server",
                icon = "server",
            ),
            schema.Text(
                id = "username",
                name = "username",
                desc = "Enter your username",
                icon = "user",
            ),
            schema.Text(
                id = "password",
                name = "password",
                desc = "Enter your password",
                icon = "lock",
            ),
        ],
    )
