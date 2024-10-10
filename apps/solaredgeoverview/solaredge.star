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
TITLE_BOX_HEIGHT = 7


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
	lastMonthData = json_data["overview"]["lastMonthData"]["energy"]
	# convert to MWh
	lastYearData = math.round(int(json_data["overview"]["lastYearData"]["energy"]) / 100000) / 10
	lifeTimeData = math.round(int(json_data["overview"]["lifeTimeData"]["energy"]) / 100000) / 10

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
				render.Box(
        			width = 64,
        			height = 6,
        			color = "#000",
        			child = render.Padding(
            			pad = (0, 0, 0, 0),
            			child = render.Text("Now : {} {}".format(str(current_power), current_power_unit), font = REGULAR_FONT),
        		    )
				),
				render.Box(
        			width = 64,
        			height = 6,
        			color = "#000",
        			child = render.Padding(
            			pad = (0, 0, 0, 0),
            			child = render.Text("Day : {} kWh".format(str(last_day_energy)), font = REGULAR_FONT),
        		    )
				),
				render.Box(
        			width = 64,
        			height = 6,
        			color = "#000",
        			child = render.Padding(
            			pad = (0, 0, 0, 0),
            			child = render.Text("Life: {} MWh".format(str(lifeTimeData)), font = REGULAR_FONT),
        		    )
				),
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
