load("render.star", "render")
load("http.star", "http")
load("xpath.star", "xpath")
load("schema.star", "schema")

# we shouldn't need these with proper handling??
API_KEY = "XXXXXX"
SITE_ID = "XXXX"

# to-do: 
# handle missing key
# limit calls to every 10 minutes

# nice-to-have:
# alternate colors for labels?
# Red "solaredge" / grey background banner at top



def main(config):
	url = "https://monitoringapi.solaredge.com/site/" + config.str("siteid", SITE_ID) + "/overview?api_key=" + config.str("apikey", API_KEY)
	response = http.get(url)

	if response.status_code != 200:
		result = "oops"
	else:		
		result = "good!"
		
	doc = xpath.loads(response.body())

	json_data = response.json()
	current_power = json_data["overview"]["currentPower"]["power"]
	last_day_energy = json_data["overview"]["lastDayData"]["energy"]
	lastMonthData = json_data["overview"]["lastMonthData"]["energy"]
	lastYearData = json_data["overview"]["lastYearData"]["energy"]
	lifeTimeData = json_data["overview"]["lifeTimeData"]["energy"]
	lastupdate = json_data["overview"]["lastUpdateTime"]

	return render.Root(

		child = render.Marquee(
		height = 40,
		scroll_direction = "vertical",
		child = render.WrappedText("Current:\n" + str(current_power) + "\n" + 
		"Today:\n" + str(last_day_energy) + "\n" + 
		"Last Year:\n" + str(lastYearData) + "\n" + 
		"Life Time:\n" + str(lifeTimeData) + "\n" +
		"Last Update:\n" + str(lastupdate))
		)

	)



def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apikey",
                name = "API KEY",
                desc = "Contact your solar installer if necessary to obtain an API key",
                icon = "key",
            ),
            schema.Text(
                id = "siteid",
                name = "Site ID",
                desc = "Can be found in the mobile app under Site Details",
                icon = "monitor",
            ),
        ],
    )
