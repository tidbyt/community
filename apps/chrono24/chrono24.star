"""
Applet: Chrono24
Summary: Watch market performance
Description: Gives ability to show watch market performance over multiple durations as well as seeing brand performance.
Author: Chase Roossin
"""

load("render.star", "render")
load("schema.star", "schema")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")

DEFAULT_WHO = "world"
BASE_URL = "https://www.chrono24.com/api/priceindex/performance-chart.json?type=Market&period="
CONFIG_TIMEFRAME = "config-timeframe"
CACHE_TTL = 21600 # 6 hour

def main(config):
  timeframe = config.str(CONFIG_TIMEFRAME, "_1month")

  # Check for cached data
  cached_data = cache.get(timeframe)

  if cached_data != None:
    print("Hit! Displaying cached data.")
    data = json.decode(cached_data)
  else:
    print("Miss cache!")
    rep = http.get(BASE_URL + timeframe)

    # Ensure valid response
    if rep.status_code != 200:
      return render.Root(
          child = twoLine("Ntwk Error", "Status: " + str(rep.status_code)),
      )

    data = rep.json()

    # Update cache
    cache.set(timeframe, json.encode(data), ttl_seconds = CACHE_TTL)

  return render.Root(
      child = render.Text(timeframe),
  )

def twoLine(line1, line2):
  return render.Box(
      width = 64,
      child = render.Column(
          cross_align = "center",
          children = [
              render.Text(content = line1, font = "CG-pixel-4x5-mono"),
              render.Text(content = line2, font = "CG-pixel-4x5-mono", height = 10),
          ],
      ),
  )

def get_schema():
  timeframes = [
      schema.Option(display = "1 month", value = "_1month"),
      schema.Option(display = "3 months", value = "_3months"),
      schema.Option(display = "6 months", value = "_6months"),
      schema.Option(display = "1 year", value = "_1year"),
      schema.Option(display = "3 years", value = "_3years"),
      schema.Option(display = "Max", value = "max"),
  ]
  return schema.Schema(
      version = "1",
      fields = [
          schema.Dropdown(
              id = CONFIG_TIMEFRAME,
              name = "Timeframe",
              desc = "The timeframe of the market performance",
              icon = "clock",
              default = "_1month",
              options = timeframes
          ),
      ],
  )
