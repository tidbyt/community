"""
Applet: ShowThis
Summary: Shows info from a URL
Description: This app displays information it retrieves from a custom URL that can be defined in the app settings. It can fetch and display data from your web services or low-code platforms such as Integromat or Zapier, without having to implement a custom Tidbyt app. For more information on how to use this app, visit https://github.com/janpi/tidbyt-showthis.
Author: Jan Pichler
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")

CACHE_TTL_MINUTES = 10
DEFAULT_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAF4mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS41LjAiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEuMC8iCiAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iCiAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgZXhpZjpDb2xvclNwYWNlPSIxIgogICBleGlmOlBpeGVsWERpbWVuc2lvbj0iMTMiCiAgIGV4aWY6UGl4ZWxZRGltZW5zaW9uPSIxMyIKICAgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIKICAgcGhvdG9zaG9wOklDQ1Byb2ZpbGU9InNSR0IgSUVDNjE5NjYtMi4xIgogICB0aWZmOkltYWdlTGVuZ3RoPSIxMyIKICAgdGlmZjpJbWFnZVdpZHRoPSIxMyIKICAgdGlmZjpSZXNvbHV0aW9uVW5pdD0iMiIKICAgdGlmZjpYUmVzb2x1dGlvbj0iMzAwLzEiCiAgIHRpZmY6WVJlc29sdXRpb249IjMwMC8xIgogICB4bXA6TWV0YWRhdGFEYXRlPSIyMDIyLTAxLTIxVDE1OjAzOjIyKzAxOjAwIgogICB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wMS0yMVQxNTowMzoyMiswMTowMCI+CiAgIDx4bXBNTTpIaXN0b3J5PgogICAgPHJkZjpTZXE+CiAgICAgPHJkZjpsaQogICAgICB4bXBNTTphY3Rpb249InByb2R1Y2VkIgogICAgICB4bXBNTTpzb2Z0d2FyZUFnZW50PSJBZmZpbml0eSBEZXNpZ25lciAxLjEwLjQiCiAgICAgIHhtcE1NOndoZW49IjIwMjItMDEtMjFUMTQ6MTk6MjUrMDE6MDAiLz4KICAgICA8cmRmOmxpCiAgICAgIHN0RXZ0OmFjdGlvbj0icHJvZHVjZWQiCiAgICAgIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFmZmluaXR5IFBob3RvIDEuMTAuNCIKICAgICAgc3RFdnQ6d2hlbj0iMjAyMi0wMS0yMVQxNTowMzoyMiswMTowMCIvPgogICAgPC9yZGY6U2VxPgogICA8L3htcE1NOkhpc3Rvcnk+CiAgIDxkYzp0aXRsZT4KICAgIDxyZGY6QWx0PgogICAgIDxyZGY6bGkgeG1sOmxhbmc9IngtZGVmYXVsdCI+TWFydmluIDEzcHg8L3JkZjpsaT4KICAgIDwvcmRmOkFsdD4KICAgPC9kYzp0aXRsZT4KICA8L3JkZjpEZXNjcmlwdGlvbj4KIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9InIiPz77fXVqAAABgmlDQ1BzUkdCIElFQzYxOTY2LTIuMQAAKJF1kc8rw2Ecx1+2aWKLQjk4LOE0YmpxcdhiFA7blOGyfe2H2o9v3++WlqtyXVHi4teBv4CrclaKSMlRzsQFfX2+ttqSfZ6ez/N63s/n8+l5Pg9Ywmklo9uGIJPNa8GAz7UQWXTZn2mgEydebFFFV2dDk2Hq2sedRIvdDJi16sf9ay0rcV2BhibhcUXV8sJTwjNredXkbeEOJRVdET4VdmtyQeFbU4+V+cXkZJm/TNbCQT9Y2oRdyRqO1bCS0jLC8nJ6M+mCUrmP+RJHPDsfkrVHZjc6QQL4cDHNBH7pyTBj4r0M4GFQdtTJH/rNnyMnuYp4lSIaqyRJkcctakGqx2VNiB6XkaZo9v9vX/XEiKdc3eGDxifDeOsD+xZ8lwzj89Awvo/A+ggX2Wp+7gBG30UvVbXefWjdgLPLqhbbgfNN6HpQo1r0V7LKtCQS8HoCzgi0X0PzUrlnlXOO7yG8Ll91Bbt70C/xrcs/YM5n49z0/xEAAAAJcEhZcwAALiMAAC4jAXilP3YAAADkSURBVCiRfZDRTQNBDESf9/JPBXxQCJFyaSL0gYjSQq4QUgQCcVcIH1RAAfbwkXizl0OMtFrv2GPP2riglKKMI8JokLnkVwBmprfnx1q0HUZJqsLMJW9mpveXq6A/Tkh1KGZnbdb0xwnLSY01IgKA8bBBGNthrE1aB5e3lHfGEa6P/Vpt48IfSEvnJXSL/OqWcHfco8bjYbNsmtbcnVLKbEric78mBP0wIalWKDcWEXTd1VI2a2wvRf/hVlSFZoa7V7LrOpJvvjOD3F1APc17sYiK1/sHAexOd5x2PwA8fX/N6n4BsXuHvE8o460AAAAASUVORK5CYII="

def main(config):

	url = config.get("url")
	# url = "test" # query a test url


	if url == "test":
		url = "https://hook.integromat.com/ujwv9g2ug7budr8stcb5tvn9bjtrrb5m"

	if url == "" or url == None:
		print("Error: No URL configured")

		display_vals = {}
		display_vals["text_left"] = "ShowThis"
		display_vals["text_right"] = "Err"
		display_vals["text_large"] = "Please"
		display_vals["text_small"] = "configure URL"
		display_vals["icon"] = DEFAULT_ICON

	else:
		display_vals_json = cache.get("showthis_url " + url) 

		if  display_vals_json != None:
			print("Cache hit! Displaying cached data.")
			
			display_vals = json.decode(display_vals_json)

		else:
			print("No cache => Querying web service...")
			
			rep = http.get(url)
		
			if rep.status_code == 200:
				display_vals = rep.json()

				if display_vals != None:
					cache_ttl_sec = CACHE_TTL_MINUTES * 60
					cache.set("showthis_url " + url, json.encode(display_vals), ttl_seconds=cache_ttl_sec)

				else:
					display_vals["text_large"] = "Error"
					display_vals["text_small"] = "Invalid obj"
					display_vals["text_left"] = "ShowThis"
					display_vals["text_right"] = "Err"
					display_vals["icon"] = DEFAULT_ICON

			else:
				display_vals["text_large"] = "Error"
				display_vals["text_small"] = "code " + rep.status_code
				display_vals["text_left"] = "ShowThis"
				display_vals["text_right"] = "Err"
				display_vals["icon"] = DEFAULT_ICON


	return render.Root(
		child = render.Stack(
			children = [
				render.Column(
					expanded=True,
					main_align="start",
					children = [ 
						render.Padding(
							pad=1,
							child=render.Row(
								expanded=True,
								main_align="space_between",
								children = [ 
									render.Text(content=display_vals["text_left"], font="CG-pixel-3x5-mono", color="#999999"), 
									render.Text(content=display_vals["text_right"], font="CG-pixel-3x5-mono", color="#999999")
								]
							)
						)
					]
				),
				render.Column(
					expanded=True,
					main_align="center",
					children = [ 
						render.Row(
							expanded=True,
							main_align="space_evenly",
							children = [ 
								render.Image(src=base64.decode(display_vals["icon"]), width=13, height=13),
								render.Text(content=display_vals["text_large"], font="6x13") 
							]
						)
					]
				),
				render.Column(
					expanded=True,
					main_align="end",
					children = [ 
						render.Row(
							expanded=True,
							main_align="center",
							children = [ 
								render.Padding(
									child=render.Text(display_vals["text_small"], font="5x8"),
									pad=1
								)
							]
						)
					]
				)
			]
		)
	)
    
    
def get_schema():
	return schema.Schema(
		version = "1",
		fields = [
			schema.Text(
				id = "url",
				name = "URL",
				desc = "URL returning the information that should be displayed",
				icon = "link",
			)
		]
	)
 
