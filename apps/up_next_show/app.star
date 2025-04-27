import requests
from bs4 import BeautifulSoup
import datetime
import os

# Logo
logo_url     = "https://www.930.com/wp-content/themes/930-wc/assets/images/930-logo-drop.svg"
logo_w, logo_h = 16, 16        # 9:30 logo size

# Sold-out badge
sold_w, sold_h     = 18, 16    # sold-out box size
sold_text_h       = 8         # Sold/Out text height

# Spacing
spacer_w          = 3         # horizontal gap between columns
vert_spacer       = 4         # vertical gap between artist marquee and date

# Text heights
prefix_h          = 8         # “Up Next” / “Tonight” height
artist_h          = 12        # artist name height
date_h            = 8         # date height

# Marquee
marq_w            = 46        # marquee visible width
marq_offset       = 22        # initial pause (pixels off-screen)

# Global animation speed
root_delay        = 98       # ms per frame (higher = slower)  
# ──────────────────────────────────────────────────────────────────────────────

# 1. Scrape the “Up Next” block
resp = requests.get("https://www.930.com/", headers={"User-Agent": "Mozilla/5.0"})
resp.raise_for_status()
soup = BeautifulSoup(resp.text, "html.parser")
up = soup.select_one("div.up-next")

date_str = up.select_one("span.dates").get_text(strip=True)      # e.g. "Mon 4/28"
artist   = up.select_one("h3.event-name.headliners a").get_text(strip=True)
sold_out = bool(up.select_one("span.sold-out"))

# 2. Decide “Tonight” vs “Up Next”
m, d      = map(int, date_str.split()[1].split("/"))
today     = datetime.date.today()
show_date = datetime.date(today.year, m, d)
prefix    = "Tonight" if show_date == today else "Up Next"

# 3. Build the Sold Out block (solid)
if sold_out:
    sold_block = f"""
    render.Box(
      width={sold_w}, height={sold_h},
      child=render.Column(children=[
        render.Text(content="Sold", color="#FF0000", height={sold_text_h}),
        render.Text(content="Out",  color="#FF0000", height={sold_text_h})
      ])
    )
    """
else:
    sold_block = f"render.Box(width={sold_w}, height={sold_h})"

# 4. Assemble the Starlark script
star = f'''
load("render.star", "render")
load("http.star",   "http")

def main():
    logo = http.get("{logo_url}").body()

    return render.Root(
        delay = {root_delay},

        child = render.Row(
            children = [

                # Left column: logo + sold-out badge
                render.Column(children=[
                    render.Image(src=logo, width={logo_w}, height={logo_h}),
                    {sold_block}
                ]),

                render.Box(width={spacer_w}),  # horizontal gap

                # Right column: prefix, marquee, spacer, date
                render.Column(children=[
                    render.Text(content="{prefix}", height={prefix_h}),
                    render.Marquee(
                        width={marq_w},
                        child=render.Text(content="{artist}", height={artist_h}),
                        offset_start={marq_offset}
                    ),
                    render.Box(height={vert_spacer}),   # vertical gap
                    render.Text(content="{date_str}", height={date_h})
                ])
            ]
        )
    )
'''

# 5. Write out the script
os.makedirs("tidbyt_app", exist_ok=True)
with open("tidbyt_app/my_app.star", "w") as f:
    f.write(star)

print("Final")
