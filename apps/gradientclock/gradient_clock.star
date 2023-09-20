load("render.star", "render")
load("time.star", "time")
load("math.star", "math")
load("encoding/json.star", "json")
load("random.star", "random")


width = 64
height = 32

APP_DURATION_MILLISECONDS = 16000
REFRESH_MILLISECONDS = 200

digits = {
"0":
[
"..######..",
".########.",
".##....##.",
".##....##.",
".##....##.",
".##....##.",
".##....##.",
".##....##.",
".##....##.",
".##....##.",
".########.",
"..######..",
],
"1":
[
"....##....",
"...###....",
"..####....",
".##.##....",
".#..##....",
"....##....",
"....##....",
"....##....",
"....##....",
"....##....",
".########.",
".########.",
],
"2":
[
"..######..",
".########.",
".##....##.",
".......##.",
"......##..",
".....##...",
"....##....",
"...##.....",
"..##......",
".###......",
".########.",
".########."
],
"3":
[
"..######..",
".########.",
".##....##.",
".......##.",
".......##.",
"....####..",
"....####..",
".......##.",
".......##.",
".##....##.",
".########.",
"..######..",
],
"4":
[
".....##...",
"....###...",
"...###....",
"..###.....",
".###......",
".##..##...",
".##..##...",
".########.",
".########.",
".....##...",
".....##...",
".....##...",
],
"5":
[
".########.",
".########.",
".##.......",
".##.......",
".##.......",
".#######..",
"..#######.",
".......##.",
".......##.",
".......##.",
".########.",
".#######..",
],
"6":
[
"..######..",
".#######..",
".##.......",
".##.......",
".##.......",
".#######..",
".########.",
".##....##.",
".##....##.",
".##....##.",
".########.",
"..######..",
],
"7":
[
".########.",
".########.",
".......##.",
"......##..",
"......##..",
".....###..",
".....##...",
".....##...",
"....###...",
"....##....",
"....##....",
"....##....",
],
"8":
[
"..######..",
".########.",
".##....##.",
".##....##.",
".##....##.",
"..######..",
"..######..",
".##....##.",
".##....##.",
".##....##.",
".########.",
"..######..",
],
"9":
[
"..######..",
".########.",
".##....##.",
".##....##.",
".##....##.",
".########.",
"..#######.",
".......##.",
".......##.",
".......##.",
"..#######.",
"..######..",
],
":":
[
"....",
"....",
"....",
".##.",
".##.",
"....",
"....",
".##.",
".##.",
"....",
"....",
"....",
],
" ":
[
"....",
"....",
"....",
"....",
"....",
"....",
"....",
"....",
"....",
"....",
"....",
"....",
]}





def render_pixels_str(src, cmap):
    """
    Renders a frame for a given board. Use this in an animation to display each round.
    """
    children = [
        render.Column(
            children = [render_row_str(row, cmap) for row in src],
        ),
    ]


    return render.Stack(
        children = children,
    )

def render_row_str(row, cmap):
    """
    Helper to render a row.
    """
    return render.Row(children = [render_cell_str(cell, cmap) for cell in row.elems()])

def render_cell_str(cell, cmap):
    """
    Helper to render a cell.
    """
    if cell in cmap:
       return render.Box(width = 1, height = 1, color = cmap[cell])
    else:
       return render.Box(width = 1, height = 1)    

P_LOCATION = "location"
P_USE_12H = "use_12h"
P_BLINK_TIME = "blink_time"
P_DAY_START = "day_start"
P_NIGHT_START = "night_start"
P_SEASON_THEME = "season_theme"

DEFAULT_TIMEZONE = "Europe/London"
DEFAULT_DAY_START = "06:00"
DEFAULT_NIGHT_START = "18:00"
DEFAULT_SEASON_THEME = "nh"

DEFAULT_TIME_COLOR = {
    "d": "#ffd",
    "n": "#900",
}


		     

def main(config):
    random.seed(time.now().unix)
    rates = []
    for _ in range(9):
    	rates.append(random.number(0, 100)/13.)
    for _ in range(3):
    	rates.append(random.number(0, 1000))
    location = config.get(P_LOCATION)
    location = json.decode(location) if location else {}
    blink_time = config.bool(P_BLINK_TIME)
    timezone = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    now = config.get("time")
    now = (time.parse_time(now) if now else time.now()).in_location(timezone)
    now_date = now.format("2 Jan")
    board = []
    for _ in range(height):
    	board.append(["#ff0000"] * width)
    frames = []
    generation_cache = {}
    frame_cache = {}
    fade_rate = 12

    # Generate enough frames to last for the maximum time the app can be on screen.
    time_rate = 90
    for i in range(0, APP_DURATION_MILLISECONDS, REFRESH_MILLISECONDS):
    	cx = width/2
	cy = height/2
    	for y in range(height):
    	    for x in range(width):
	    	board[y][x] = get_hex(rates[9] + rates[0] * x + rates[1] * y + rates[2] * i/time_rate, rates[10] + rates[3] * x + rates[4] * y + rates[5] * i/time_rate, rates[11] + rates[6] * x + rates[7] * y + rates[8] * i/time_rate)

        frames.append(render.Stack(children=
	[render_frame(board),
	render.Column(children=
		[render.Box(height = 18, child=render.Row(
                     children=[render_pixels_str(digits[digit], {"#": "#000000"}) for digit in (now.format("15:04") if i % 1000 < 500 else now.format("15 04")).elems()])),
		render.Box(child=render.Box(child=render.Text(offset=2, content=now_date, color="#000000"o, font="6x13")))])]))
    # for fading  + pad_0("%X" % int(min(1, i/APP_DURATION_MILLISECONDS*fade_rate) * 0xFF)    
    return render.Root(render.Animation(children = frames), delay=REFRESH_MILLISECONDS)


def render_frame(board, text = None):
    """
    Renders a frame for a given board. Use this in an animation to display each round.
    """
    children = [
        render.Column(
            children = [render_row(row) for row in board],
        ),
    ]

    if text:
        children.append(
            render.Box(
                child = render.Text(
                    content = text,
                    font = "6x13",
		    color="#000000"
                ),
                width=width,
		height=height
            ),
        )
    return render.Stack(
        children = children,
    )

def render_row(row):
    """
    Helper to render a row.
    """
    return render.Row(children = [render_cell(cell) for cell in row])

def render_cell(cell):
    """
    Helper to render a cell.
    """
    return render.Box(width = 1, height = 1, color = cell)

def pad_0(num):
    return ("0" + str(num))[-2:]

m = 101

def get_rgb_val(x):
    return pad_0("%X" % int(boomerang(x) * 0xFF))

def boomerang(x):
    return math.sin(x/m)/4 + 0.75

#    y = x % (2*m) / m


 #   return min(y, 2-y)

def get_hex(r, g, b):
    return "#" + get_rgb_val(r) + get_rgb_val(g) + get_rgb_val(b)

def cmap(x):

    return "#" + get_rgb_val(x * 2.) + get_rgb_val(x*3.) + get_rgb_val(x*5.)