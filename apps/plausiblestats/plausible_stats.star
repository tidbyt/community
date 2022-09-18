load("render.star", "render")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("schema.star", "schema")
load("cache.star", "cache")
load("time.star", "time")
load("humanize.star", "humanize")

METRIC_OPTIONS = [
	schema.Option(
		display = "Pageviews",
		value = "pageviews"
	),
	schema.Option(
		display = "Visitors",
		value = "visitors"
	),
	schema.Option(
		display = "Bounce Rate",
		value = "bounce_rate"
	),
	schema.Option(
		display = "Visit Duration",
		value = "visit_duration"
	),
	schema.Option(
		display = "Visits/Session",
		value = "visits"
	)
]

TIME_PERIOD_OPTIONS = [
	schema.Option(
		display = "Today",
		value = "day"
	),
	schema.Option(
		display = "Last 7 days",
		value = "7d"
	),
	schema.Option(
		display = "Last 30 days",
		value = "30d"
	),
	schema.Option(
		display = "This Month",
		value = "month"
	),
	schema.Option(
		display = "Last 6 months",
		value = "6mo"
	),
	schema.Option(
		display = "Last 12 months",
		value = "12mo"
	),
	schema.Option(
		display = "All Time",
		value = "custom"
	)
]

CHART_TIME_PERIOD_OPTIONS = [
	schema.Option(
		display = "Last 7 days",
		value = "7d"
	),
	schema.Option(
		display = "Last 30 days",
		value = "30d"
	),
	schema.Option(
		display = "This Month",
		value = "month"
	),
	schema.Option(
		display = "Last 6 months",
		value = "6mo"
	),
	schema.Option(
		display = "Last 12 months",
		value = "12mo"
	),
]

# Config/Schema Keys
DOMAIN_KEY = "domain"
PLAUSIBLE_API_KEY = "plausible_api_key"
METRIC_KEY = "metric"
TIME_PERIOD_KEY = "time_period"

SHOULD_SHOW_CHART_KEY = "should_show_chart"
CHART_TIME_PERIOD_KEY = "chart_time_period"
GENERATED_CHART_KEY = "generated_chart"

USE_CUSTOM_FAVICON_KEY = "use_custom_favicon"
FAVICON_PATH = "favicon_path"
GENERATED_FAVICON_KEY = "generated_favicon"
FAVICON_FILENAMES =  ["/favicon.png", "/favicon-16x16.png","/favicon-32x32.png"]

# Cache identifiers and TTL values
REQUEST_CACHE_ID = "request"
REQUEST_CACHE_TTL = 600 # 10 minutes
FAVICON_CACHE_ID = "favicon" 
FAVICON_CACHE_TTL = 86400 # 1 day

# Fallback Images
GLOBE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgBAMAAACBVGfHAAAAG1BMVEUAAQD//v/+/v/+///+//7///////7+/v7//v5gSunGAAAAAXRSTlMAQObYZgAAASRJREFUeAEFwTFz0mAAANAXwpdmhGKqI5yyJ7ZQR9RCHVNCYsdwEi4jnrrXO6N/2/cAAACu75Z3AIi7abMqbnMAT0W1GWVFA3DTjE68ztfPQNKUVxOiNl6UINuYvRAqcQcyeqhYQjTwFwoOJRYTXkFFOkVF/BGeL+zxdr/dDZ+O2fr3avXuO2H3uTov6v2XrspWHxal5IUoh1FLmotL0jkkG8JcuBC1MHohzKUl4QLjlpBLW8YXSEuSVrQhymHcElrJe5ISxiXnOcW6zh6ezj+afZNN/+BYz5rT46HrpqfDQ49dSQ8/ie8RFwww8G0CawY4sgTDxCpn3Av/wFW/iSfEeRhaoO/ClqrMfgHM7uvL6M3sBkDY1sXt4esGANf14xQAAPAf0R82TFufV44AAAAASUVORK5CYII=
""")

ERROR_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAQCAYAAAAmlE46AAAAi0lEQVR4AY3RgQUDURCE4b+SFBEgqSCFpJcnANLOAakkLQSCIxtPGCuz1hvG4XzOzQLESscYwV+ChUw4a3DbHtFUKGGH3A6zJRQWzOh1+T1B0P/boZqgyoxDvXTUQy/XXQXqVeNEDfdPD9/np2F97XjPyKGwr2kmQ8Ok1OPYrTztqjVozrGeDHscVb+iSEfRNbvdGAAAAABJRU5ErkJggg==
""")

# API URL for Plausible
PLAUSIBLE_API_URL = "https://plausible.io/api/v1/stats/"

def main(config):
	
	time_period = config.get(TIME_PERIOD_KEY) or TIME_PERIOD_OPTIONS[0].value
	metric = config.get(METRIC_KEY) or METRIC_OPTIONS[0].value
	token = config.get(PLAUSIBLE_API_KEY)
	raw_domain = config.get(DOMAIN_KEY)
	use_custom_favicon = config.bool(USE_CUSTOM_FAVICON_KEY)
	favicon_path = config.get(FAVICON_PATH)
	should_show_chart = config.bool(SHOULD_SHOW_CHART_KEY)
	chart_time_period = config.get(CHART_TIME_PERIOD_KEY) or CHART_TIME_PERIOD_OPTIONS[0].value
	domain = sanitize_domain(config.get(DOMAIN_KEY))
	
	# Alert the user that the domain is bad
	if domain == None:
		print("The domain that was passed in was bad, showing error screen")
		return render_error_screen("Bad URL")
	
	# Alert the user if the Plausible API Token is missing
	if token == None:
		print("Plausible API Token is missing, showing error screen")
		return render_error_screen("No API Key")
	
	# Get the favicon based on if the user wants to set a custom favicon or not
	if use_custom_favicon:
		favicon = get_favicon(domain, favicon_path)
	else:
		favicon = get_favicon(domain, None)
	
	# Fetch the stat for the given metric from Plausible.io, grab the int value
	stats_results = get_plausible_data("aggregate", token, domain, time_period, metric)
	stat = "%d" % stats_results[metric]["value"]
	
	# Bounce rate and visit duration need special suffixes, otherwise run the compact_number
	# method on the value to get a string that fits into 6 digits.
	formatted_stat = ""
	if metric == "bounce_rate":
		formatted_stat = stat + "%"
	elif metric == "visit_duration":
		formatted_stat = stat + "s"
	else:
		formatted_stat = compact_number(stat)
	
	# Determine if the user wants to show the historical chart or not.
	# If yes, fetch the data from Plausible.io's API and convert it to the format render.Plot needs
	# If no, do nothing
	# Either way, the end result is a list of children that will be rendered later
	data_children = []
	if should_show_chart == True:
		results = get_plausible_data("timeseries", token, domain, chart_time_period, metric)
		plot_data = convert_result_for_plot(results, metric)
		number_of_data_points = len(plot_data[0]) - 1
		largest_value = plot_data[1]
		data_children = [
			render.Text(formatted_stat, font = "6x13"),
			render.Plot(
			  data = plot_data[0],
			  width = 35,
			  height = 10,
			  color = "#0F0",
			  x_lim = (0, number_of_data_points),
			  y_lim = (0, largest_value),
			  fill = True,
			),
		]
	else:
		data_children = [
			render.Padding(
				pad = (0, 3, 0, 0),
				child = render.Marquee(
					width = 37,
					align = "center",
					child = render.Text(formatted_stat, font = "10x20") 
				)
			)
		]
	
	return render.Root(
		render.Column(
			expanded = True,
			main_align = "center",
			cross_align = "center",
			children = [
				render.Row(
					expanded = True,
					main_align = "space_around",
					cross_align = "center",
					children = [
						render.Padding(
							pad = (0, 2, 0, 0),
							child = render.Image(favicon, width = 20, height = 20)
						),
						render.Column(
							main_align = "center",
							cross_align = "center",
							children = data_children
						)
					]
				),
				render.Box(
					width = 1,
					height = 3
				),
				render.Marquee(
					width = 64,
					height = 6,
					align = "center",
					child = render.Text(
						metric.replace("_", " ") + " " + make_description_text(time_period), 
						font = "CG-pixel-3x5-mono")
				)
			]
		)
	)

def get_schema():
	return schema.Schema(
		version = "1",
		fields = [
			schema.Text(
				id = DOMAIN_KEY,
				name = "Domain",
				desc = "Your domain to get metrics for. ",
				icon = "gear",
				default = ""
			),
			schema.Toggle(
				id = USE_CUSTOM_FAVICON_KEY,
				name = "Custom Favicon Path",
				desc = "Toggle if your favicon image isn't at the root of your site",
				icon = "image",
				default = False
			),
			schema.Generated(
				id = GENERATED_FAVICON_KEY,
				source = USE_CUSTOM_FAVICON_KEY,
				handler = custom_favicon_options
			),
			schema.Text(
				id = PLAUSIBLE_API_KEY,
				name = "Plausible API Key",
				desc = "Get it at plausible.io/settings",
				icon = "key",
				default = ""
			),
			schema.Dropdown(
				id = METRIC_KEY,
				name = "Metric",
				desc = "Choose the site metric you'd like to display",
				icon = "chart-simple",
				default = METRIC_OPTIONS[0].value,
				options = METRIC_OPTIONS
			),
			schema.Dropdown(
				id = TIME_PERIOD_KEY,
				name = "Time Period",
				desc = "Choose the time period for the counter display",
				icon = "calendar",
				default = TIME_PERIOD_OPTIONS[0].value,
				options = TIME_PERIOD_OPTIONS
			),
			schema.Toggle(
				id = SHOULD_SHOW_CHART_KEY,
				name = "Show Chart?",
				desc = "Toggles the display of the historical chart under the count",
				icon = "chart-line",
				default = True
			),
            schema.Generated(
                id = GENERATED_CHART_KEY,
                source = SHOULD_SHOW_CHART_KEY,
                handler = chart_period_options,
            )
		]
	)

# Generates the options to choose the time period to chart.
def chart_period_options(should_show_chart):
	if should_show_chart:
		return [
			schema.Dropdown(
				id = CHART_TIME_PERIOD_KEY,
				name = "Chart Time Period",
				desc = "Customize the time period for the chart",
				icon = "calendar-days",
				default = CHART_TIME_PERIOD_OPTIONS[0].value,
				options = CHART_TIME_PERIOD_OPTIONS
			)
		]
	else:
		return []
# Generates a text input for the user to add the URL to their favicon.
def custom_favicon_options(use_custom_favicon):
	if use_custom_favicon:
		return [
			schema.Text(
				id = FAVICON_PATH,
				name = "Relative Path",
				desc = "Relative path from your site root to a .png favicon eg. /favicons/favicon.png",
				icon = "link",
				default = ""
			)
		]
	else:
		return []

# These values are unfortunately duplicated from the options constants defined for the schema
def make_description_text(time_period):
	if time_period == "day":
		return "Today"
	
	if time_period == "7d":
		return "Last 7 days"
	
	if time_period == "30d":
		return "Last 30 days"
	
	if time_period == "month":
		return "This month"
	
	if time_period == "6mo":
		return "Last 6 months"
	
	if time_period == "12mo":
		return "Last 12 months"
	
	return "Total"

# Converts a large number into a compact string that is 6 characters or less.
# Values under 1,000 will be returned as-is eg. 120 stays 120
# Values over 1,000 will have the suffix "K" eg. 1,234 becomes 1.234K
# Values over 1,000,000 will have the suffix "M" eg. 1,234,567 becomes 1.23M
# Values over 1,000,000,000 will have the suffix "B" eg, 1,234,456,789 becomes 1.23B
# Values over a billion will return the string "A LOT!" (What are you? Google?)
def compact_number(number):
	value_string = str(number)
	
	# Get length of string
	character_count = len(value_string)
	
	# Return the string if it's less than 4
	if character_count <= 3:
		return value_string
	
	# Thousands
	if character_count <= 6:
		return decorate_value(value_string, character_count - 3, "K")
	
	# Millions
	if character_count <= 9:
		return decorate_value(value_string, character_count - 6, "M")
		
	# Billions
	if character_count <= 12:
		return decorate_value(value_string, character_count - 9, "B")
	
	# Yikes, that's a lot
	return "A LOT!"

# Takes a string, grabs the first 4 characters,  and decorates it with the decimal separator
# and the correct suffix eg. "1234" becomes "1.234K". 
# It will also remove any trailing "0" eg. 1010 becomes "1.01K" and 1000 becomes "1K".
# characters 
#	value: Any string to decorate
#	decimal_index: The index in the string where to place the decimal separator (1, 2, or 3)
#	suffix: The character to place at the end of the string ("K", "M", or "B")
def decorate_value(value, decimal_index, suffix):
	# Convert the string to a list
	value_list = list(value.elems())
	
	# Take the first 4 characters
	cropped_list = value_list[:4]
	
	# Insert the "." character at the decimal_index 
	cropped_list.insert(decimal_index, ".")
	
	# Smash it back into a string
	joined = "".join(cropped_list)
	
	# Loop through and remove any and all trailing "0" characters
	while joined.endswith("0"):
		joined = joined.removesuffix("0")
	
	# Remove a trailing decimal separator if present
	joined = joined.removesuffix(".")
	
	# Return the joined string, with the suffix added
	return joined + suffix

# Removes the chance for human error. Does its best to remove
# the scheme and "www" subdomain if present.
def sanitize_domain(domain):
	
	# Check for empty at first
	if domain == "" or domain == None:
		return None
	
	# Remove whitespace
	stripped_domain = domain.lstrip()

	# Strip out "http://" or "https://"
	prefix_free_domain = stripped_domain.split("://").pop()
	
	# Remove "www."
	final_url = prefix_free_domain.removeprefix("www.")
	
	# Don't bother 
	
	return final_url

# Makes a request to the domain, and will attempt to return the site's favicon
# icon by assuming the three most common favicon filenames.
# Defaults to GLOBE_IMAGE if it fails.
def get_favicon(domain, favicon_path):

	cache_id = FAVICON_CACHE_ID + "_" + domain
	
	cached_favicon = cache.get(cache_id)
	
	if cached_favicon != None:
		print("Returning cached favicon")
		return cached_favicon
	
	base_url = "http://" + domain
	
	if favicon_path != None:
		print("Using custom favicon path")
		favicon_url = base_url + favicon_path
		response = http.get(favicon_url)
		if response.status_code != 200:
			print("Failed to get favicon: %d" % response.status_code)
			return None
		favicon = response.body()
		cache.set(cache_id, favicon, ttl_seconds = FAVICON_CACHE_TTL)
		print("Got custom favicon")
		return favicon
	
	for f in FAVICON_FILENAMES:
		response = http.get(base_url + f)
		if response.status_code != 200:
			continue
		favicon = response.body()
		cache.set(cache_id, favicon, ttl_seconds = FAVICON_CACHE_TTL)
		return favicon
	
	return GLOBE_IMAGE

# Makes a call to the plausible.io stats endpoint.
# 	endpoint: the path to the API to call eg. "/aggregate" or "/timeseries"
#	toke: The Auth token
#	domain: The domain to check
#	time_period: The time period to check (doesn't support custom date ranges)
#	metric: The metric value to return
def get_plausible_data(endpoint, token, domain, time_period, metric):
	
	print("Getting data from Plausible API")
	
	cache_id = "_".join([REQUEST_CACHE_ID, endpoint, domain, time_period, metric])
	
	print("Checking cache")
	
	cached_request = cache.get(cache_id)
	if cached_request != None:
		print("Returning cached data")
		return cached_request
	
	print("Building new request")
	site_id_param = "?site_id=" + domain
	time_period_param = "&period=" + time_period
	metrics_param = "&metrics=" + metric
	request_url = PLAUSIBLE_API_URL + endpoint + site_id_param + time_period_param + metrics_param
	
	# If the user selected "all", we have to add an additional "date" query parameter
	if time_period == "custom":
		past = "2000-01-01"
		now = humanize.time_format("yyyy-MM-dd", time.now())
		request_url = request_url + "&date=" + past + "," + now
		print(past, now)
	
	print("Final URL:" + request_url)
	print("Making request")
	response = http.get(
		request_url,
		headers = {
			"Authorization": "Bearer " + token
		}
	)
	
	if response.status_code != 200:
		print("Request failed with %d" % response.status_code)
		return None
	
	results = response.json()["results"]
	cache.set(REQUEST_CACHE_ID, str(results), ttl_seconds = REQUEST_CACHE_TTL)
	print(results)
	return results

# Takes the API result from Plausible and converts it to the
# list required by the render.Plot method.
# Could probably be optimized by the zip method.
def convert_result_for_plot(results, metric):
	final_data = []
	largest_value = 0
	for i, r in enumerate(results):
		safe_value = 0
		if r[metric] != None:
			safe_value = r[metric]
		final_data.append((i, safe_value))
		if safe_value > largest_value:
			largest_value = safe_value
	return (final_data, largest_value)

def render_error_screen(message):
	return render.Root(
		child = render.Box(
			color = "#000",
			padding = 1,
			child = render.Box(
				color = "#fff",
				padding = 1,
				child = render.Box(
					color = "#000",
					padding = 1,
					child = render.Row(
						main_align = "start",
						expanded = True,
						cross_align = "top",
						children = [
							render.Column(
								children = [
									render.Stack(
										children = [
											render.Box(color = "#fff", width = 14, height = 15),
											render.Image(ERROR_IMAGE)
										]
									),
									render.Box(width = 1)
								]
							),
							render.Box(width = 2),
							render.Column (
								children = [
									render.Text(content = "Uh oh"),
									render.WrappedText(content = message)
								]
							)
						]
					)
				)
			)
		)
	)