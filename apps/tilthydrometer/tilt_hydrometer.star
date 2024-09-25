"""
Applet: Tilt Hydrometer
Summary: Shows Tilt hydrometer data
Description: The Tilt hydrometer tracks brewing stats (specific gravity, temperature, attenuation, ABV, etc.) and logs to a Google Sheet. This app displays pertinent information from the logs.
Author: DSUmjham
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64") 
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("re.star", "re")
load("schema.star", "schema")

CACHE_TTL_SECONDS = 300
DEFAULT_SHEET_LINK = ""
DEFAULT_GOOGLE_API = ""
DEFAULT_FG = 1.0
REGULAR_FONT = "tom-thumb"
TILT_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAANCAYAAACZ3F9/AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAY
dpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADqADAAQAAAABAAAADQAAAAD6UEMqAAAA
qElEQVQoFb1SsQ3DQAi8WN4gbcoskR1+EJceJWUG+R2yhEu3mcHmUE66f7lJCiMh4DjgwQaAjVprTfu53bdePS
/+5QuilIIowPv1DKiVxzTjui6I5snLrE+SH4mcLkucr2BsHCRoQFN0VJwYO3lRv58maZriMYBGuAslCLlXk7Rg
MP8n9/xCPu/wqjoC81T/JInpoiTKF1nWi8T5/8/xrvQ5uVfimiT+Dsl6xQaBxswDAAAAAElFTkSuQmCC
""") 

def main(config):
	api = config.str("googleAPI", DEFAULT_GOOGLE_API)
	link = config.str("link", DEFAULT_SHEET_LINK)
	if (link == ""):
		fail("Must provide a link to a Google Sheet")
		
	id = re.findall("[\\w\\-]{40,50}", link)[0]
	b_fg = float(config.str("fg", DEFAULT_FG))

	# parse cells B8:B23
	json = get_json(id, "B2:B23", api)
	b_dob = json[0][0].split()[0]
	b_sg = float(json[6][0])		# B8 Current (gravity)
	b_og = float(json[7][0])		# B9 First (gravity)
	b_dur = json[9][0]				# B11 Duration (days)
	b_temp_cur = json[13][0]		# B15 Current (temp)
	b_temp_avg = json[14][0]		# B16 Average (temp)
	b_abv = json[20][0]				# B22 Standard Method ABV
	b_dur_cg = float(json[21][0])	# B23 Days at Current SG
	# parse cells F2 and G2
	json = get_json(id, "F2:G2", api)
	t_color = hex_color(json[0][0])	# F2
	b_name = json[0][1]				# G2

	# ensure the user-specified fg is possible
	if b_fg < 1 or b_fg >= b_og:
		fail("Final gravity must be > 1 and less than OG")

	return render.Root(
		child = render.Column(
			expanded=True,
			main_align="space_around",
			cross_align = "center",
			children = [
				render_title(b_name, t_color),
				render.Sequence(
					children = [
						render_animation(render_ferm(b_og, b_sg, b_fg, b_dur_cg)),
						render_animation(render_misc(b_abv, b_temp_avg, b_dob)),
					],
				),
			],
		),
	)

def hex_color(t_color):
	color = ("#000000", "#FFFFFF")
	if t_color == "BLUE":
		return ("#0000FF", "#FFFFFF")
	elif t_color == "BLACK":
		return ("#808080", "#FFFFFF")
	elif t_color == "RED":
		return ("#FF0000", "#FFFFFF")
	elif t_color == "GREEN":
		return ("#00FF00", "#808080")
	elif t_color == "ORANGE": 
		return ("#FFA500", "#808080")
	elif t_color == "YELLOW":
		return ("#FFFF00", "#808080")
	elif t_color == "PURPLE":
		return ("#9D00FF", "#FFFFFF")
	elif t_color == "PINK": 
		return ("#FFC0CB", "#808080")
	return color

def render_ferm(og, sg, fg, dur_cg):
	# should not have more than 100% fermentation or the FG was specified incorrectly
	percent = int((og - sg) / (og - fg) * 100)
	
	# ensure the progress bar does not exceed the bounds of the border
	if percent > 100:
		percent = 100

	green_box_width = int(percent/100*43)
	if (green_box_width == 0):
		green_box_width = -1

	# if fermentation is stable for > 3 days, it's complete
	dur_color = "#FFFFFF"
	if percent >= 100 and dur_cg >= 3:
		dur_color = "#00FF00"
		
	return render.Row(
		children = [	
			render.Column(
				expanded = True,
				main_align="center",
				cross_align="center",
				children = [
					render.Text("SG: {0}".format(humanize.float("#.###", sg)), font=REGULAR_FONT),
					render.Text("FG: {0}".format(humanize.float("#.###", fg)), font = REGULAR_FONT),
					render.Row(
						expanded=True,
						main_align="center",
						children = [
							render.Stack(
								children = [
									render.Box(
										color = "#FFFFFF",
										height = 5,
										width = 45,
										padding = 1,
										child = render.Box(
											color = "#000000",
										)
									),
									render.Padding(
										pad = (1, 1, 0, 0),
										child = render.Box(
											color = "#00FF00",
											height = 3,
											width = green_box_width,
										),	
									),
								],
							),
							render.Text(" {}%".format(percent), font = "CG-pixel-3x5-mono", color = dur_color),
						],
					),
				],
			),
		],
	)

def render_misc(abv, temp_avg, dob):
	return render.Row(
		expanded=True,
		main_align="center",
		children = [
			render.Column(
				expanded=True,
				cross_align="left",
				main_align="end",
					children = [
						render.Text("ABV: {}".format(abv), font=REGULAR_FONT),
						render.Text(" °F: {}".format(temp_avg), font=REGULAR_FONT),
						render.Text("DOB: {}".format(dob), font=REGULAR_FONT)
				],
			),
		],
	)

def render_title(b_name, t_color):
	return render.Row(
			children = [
				render.Image(src=TILT_LOGO),
				render.Box(
					color = t_color[0],
					height = 13,
					width = 50,
					child = render.Padding(
						pad = (0, 1, 0, 0),
						child = render.Marquee(
							scroll_direction = "vertical",
							height = 12,
							offset_start = 12,
							offset_end = 0,
							align = "center",
							child = render.WrappedText(
								align = "center",
								font = REGULAR_FONT,
								content = b_name,
								color = t_color[1],
							),
						)

					),
				),
			],
		)

def render_animation(test):
	return animation.Transformation(
		child = test,
		duration =99,
		origin = animation.Origin(0,0),
		keyframes = [
			animation.Keyframe(
				percentage = 0.0,
				transforms = [animation.Translate(0, 0)],
				curve = "ease_in_out",
			),
			animation.Keyframe(
				percentage = 0.8,
				transforms = [animation.Translate(0, 0)],
				curve = "ease_in_out",
			),
			animation.Keyframe(
				percentage = 1.0,
				transforms = [animation.Translate(0, -51)],
				curve = "ease_in_out",
			),
		],
	)

def get_json(id, range, api):
	url = "https://sheets.googleapis.com/v4/spreadsheets/{0}/values/Report!{1}?key={2}".format(id, range, api)

	# download the JSON data 
	rep = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
	if rep.status_code != 200:
		fail("Could not retrieve tilt data. Failed with status %d", rep.status_code)

	return rep.json()["values"]
	
def get_schema():
	return schema.Schema(
		version = "1",
		fields = [
			schema.Text(
				id = "link",
				name = "Shared Sheet",
				desc = "Link to your Tilt's shared Google Sheet",
				icon = "link",
			),
			schema.Text(
				id = "googleAPI",
				name = "API Key",
				desc = "Google API key with access to Sheets",
				icon = "key",
			),
			schema.Text(
				id = "fg",
				name = "Final Gravity",
				desc = "Expected final gravity",
				icon = "flagCheckered",
			)
		],
	)