"""
Applet: Helldivers 2
Summary: View current player count
Description: Shows the current player count.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

H2_LOGO = base64.decode("""
UklGRiwBAABXRUJQVlA4TB8BAAAvE8AEEA4GbSM5Ov5I3zi+UZi9Ov8BV9v2880X27aT08icrLa2nEJOwc6Muh1t23a7cbLbbwLyqFSndW+8Hjorr1eCch3m3PBFrCqf3TCrY0loIFFk3iM/62M83AobiCZvxZ9jJyo8+7N7osDtP2skspz/c9JApDr0x0GpiUS7/9g1klgXPbTpsr+349L0ULTWQKLEKXe0RrH9N/tWtA0nlUSlXaKZBhIjN8NJzJZdKh0Ry2G5DUg0fxsS0x2uinm/yp9jyoYvog8+VrduygF/RL/MybQiPvphwqQf9WhZZgMKj+izd2K5reu4U+XtLPsUJFFnWrs+P8X4tP2qHO2m1TXwrMJT8dGT3sBHiVb8ui3LEr9EqS4bnqaO0gYeAQA=
""")

H2_URL = "https://api.live.prod.thehelldiversgame.com/api/WarSeason/801/Status"

def main():
    res = http.get(H2_URL, ttl_seconds = 900)

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(res.status_code)

    data = res.json()

    player_count = 0
    for planet in data["planetStatus"]:
        player_count += int(planet["players"])

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = H2_LOGO),
                    render.Text(content = str(player_count), color = "#fcea3f"),
                ],
            ),
        ),
    )

def render_error(status_code):
    message = "API error %d" % status_code

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = H2_LOGO),
                    render.Marquee(
                        align = "center",
                        width = 38,
                        child = render.Text(content = message, color = "#f00"),
                    ),
                ],
            ),
        ),
    )
