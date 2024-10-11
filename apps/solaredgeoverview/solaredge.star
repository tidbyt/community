load("render.star", "render")
load("http.star", "http")
load("xpath.star", "xpath")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")

# we shouldn't need these with proper handling??

# TODO: Uncomment these before PR
#API_KEY = "XXXXXX"
#SITE_ID = "XXXX"

# TODO: DEMO ONLY - Remove before PR


# to-do: 
# handle missing key
# limit calls to every 10 minutes

# nice-to-have:
# alternate colors for labels?
# Red "solaredge" / grey background banner at top
REGULAR_FONT = "tom-thumb"
DATETIME_FONT = "tb-8"
DEFAULT_TEXT_COLOR = "#ffffff"

ANIMATION_FRAMES = 30
ANIMATION_HOLD_FRAMES = 75

DATA_BOX_BKG = "#000"
SLIDE_DURATION = 99

DATA_BOX_WIDTH = 64
DATA_BOX_HEIGHT = 20
TITLE_BOX_WIDTH = 64
TITLE_BOX_HEIGHT = 6


def main(config):
	url = "https://monitoringapi.solaredge.com/site/" + config.str("siteid", SITE_ID) + "/overview?api_key=" + config.str("apikey", API_KEY)
	response = http.get(url)

	if response.status_code != 200:
		result = "oops"
	else:		
		result = "good!"
	print(response.body())
	doc = xpath.loads(response.body())

	json_data = response.json()

	current_power = int(json_data["overview"]["currentPower"]["power"])
	current_power_unit = "W"
	if current_power > 1000:
		current_power = math.round(int(current_power) / 100) / 10
		current_power_unit = "kW"
	
	# convert to kWh already
	last_day_energy = math.round(json_data["overview"]["lastDayData"]["energy"] / 100) / 10
	lastMonthData = math.round(int(json_data["overview"]["lastMonthData"]["energy"]) / 10000) / 10
	# convert to MWh
	lastYearData = math.round(int(json_data["overview"]["lastYearData"]["energy"]) / 100000) / 10
	lifeTimeData = int(math.round(int(json_data["overview"]["lifeTimeData"]["energy"]) / 1000000))

	lifeTime_unit = "MWh"
	if lifeTimeData > 1000:
		lifeTimeData = math.round(int(lifeTimeData) / 100) / 10
		lifeTime_unit = "GWh"


	print(int(lifeTimeData))
	lastupdate = time.parse_time(json_data["overview"]["lastUpdateTime"], format = "2006-01-02 15:04:05") 

	return render.Root(
		render.Column(
            children = [
        		render.Box(
        			width = TITLE_BOX_WIDTH,
        			height = TITLE_BOX_HEIGHT,
        			color = "#333",
        			child = render.Padding(
            			pad = (0, 0, 0, 0),
            			child = render.Text("solarEdge", font = REGULAR_FONT),
        		    )
				),
				# Basic Option 1
				# render.Box(
        		# 	width = 64,
        		# 	height = 6,
        		# 	color = "#000",
        		# 	child = render.Padding(
            	# 		pad = (0, 0, 0, 0),
            	# 		child = render.Text("Now : {} {}".format(str(current_power), current_power_unit), font = REGULAR_FONT),
        		#     )
				# ),
				# render.Box(
        		# 	width = 64,
        		# 	height = 6,
        		# 	color = "#000",
        		# 	child = render.Padding(
            	# 		pad = (0, 0, 0, 0),
            	# 		child = render.Text("Day : {} kWh".format(str(last_day_energy)), font = REGULAR_FONT),
        		#     )
				# ),
				# render.Box(
        		# 	width = 64,
        		# 	height = 6,
        		# 	color = "#000",
        		# 	child = render.Padding(
            	# 		pad = (0, 0, 0, 0),
            	# 		child = render.Text("Life: {} MWh".format(str(lifeTimeData)), font = REGULAR_FONT),
        		#     )
				# ),
				# end of basic option 1
				# begin option 2 - with 2 columns and animation of 2nd colum to swap back & forth between the measurement options
				render.Box(width = 64, height = 1, color = "#000"),
				render.Row(expanded = True, 
					children = [
						render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(current_power), font = "6x13", color = "#00ff00", align = "center", width = 27), render.WrappedText(content = "{} now".format(current_power_unit), font = REGULAR_FONT, color = "#fff", align = "center", width = 27)]),
						#render.Box(width = 27, height = 20, child = render.WrappedText("{}\n{} now".format(current_power, current_power_unit), font = REGULAR_FONT, align = "center", width = 27)),
						render.Box(width = 1, height = 19, color = "#333"),
						#render.Box(width = 36, height = 20, child = render.WrappedText("{}\nkWh year".format(last_day_energy), font = REGULAR_FONT, align = "center", width = 36)),
						#render.Box(width = 1, height = 19, color = "#333"),
						#render.Box(width = 21, height = 20, child = render.WrappedText("Life\n{}\nMWh".format(lifeTimeData), font = REGULAR_FONT, align = "center", width = 21))
						fade_child(last_day_energy, "KWh", lastMonthData, lastYearData, lifeTimeData, lifeTime_unit)
					]
				),
				#end of option 2
				# This will be at bottom for all formats - shows last time the data was sent to the API back-end
				render.Box(
        			width = 64,
        			height = 6,
        			color = "#000",
        			child = render.Padding(
            			pad = (0, 0, 0, 0),
            			child = render.Text("{}".format(lastupdate.format("Jan 2 3:04PM")[:-1]), font = REGULAR_FONT),
        		    )
				)
			]
		)
	)

def fade_child(day_power, day_unit, month_power, year_power, life_power, life_power_unit):
    return render.Animation(
        children =
            createfadelist(day_power, "{} day".format(day_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd") +
            createfadelist(month_power, "MWh month", ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd") +
            createfadelist(year_power, "MWh year", ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd") +
			createfadelist(life_power, "{} life".format(life_power_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd"),
    )

def createfadelist(text, textline2, cycles, text_font, text_color):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color + x))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color + x))
    return cycle_list

def fadelistchildcolumn(text, textline2, font, color):
    return render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(text), font = "6x13", color = "#00ff00", align = "center", width = 27), render.WrappedText(content = "{}".format(textline2), font = REGULAR_FONT, color = "#fff", align = "center", width = 36)])




def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "apiversion",
                name = "APIVersion",
                desc = "Select which API Version",
                icon = "hashtag",
                default = "1",
                options = [
                    schema.Option(
                        display = "API v1",
                        value = "1",
                    ) #,
					# we don't support v2 yet, but stub it out here for now
                    #schema.Option(
                    #    display = "API v1",
                    #    value = "1",
                    #)
					#
                ],
            ),
            schema.Text(
                id = "siteid",
                name = "Site ID",
                desc = "Can be found in the mobile app under Site Details",
                icon = "eye",
            ),
			schema.Generated(
                id = "apiversion_key",
                source = "apiversion",
                handler = show_apikey_options,
            ),
        ],
    )
def show_apikey_options(apiversion):
    print("in show api key")
    if apiversion == "1":
        return [
            schema.Text(
                id = "apikey",
                name = "v1 API KEY",
                desc = "Contact your solar installer if necessary to obtain an API key",
                icon = "key",
            )
		]
    else:
        return [
            schema.Text(
                id = "apikey",
                name = "v2 User KEY",
                desc = "Contact your solar installer if necessary to obtain an API key",
                icon = "key",
            )
		]
