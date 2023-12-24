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
CACHE_TTL = 3600 # 6 hour

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
          child = two_line("Ntwk Error", "Status: " + str(rep.status_code)),
      )

    data = rep.json()

    # Update cache
    cache.set(timeframe, json.encode(data), ttl_seconds = CACHE_TTL)

  # Construct graph points
  price_points = []
  price_index_data = data["priceIndexData"]
  lowest_price = 0
  highest_price = 0
  first_price = 0 
  last_price = 0

  for index, price_data in enumerate(price_index_data):
    value = price_data["y"]["mean"]["value"]
    
    # on first, set highest and lowest
    if index == 0:
      lowest_price = value
      highest_price = value
      first_price = value

    # Update highest/lowest price
    if value < lowest_price:
      lowest_price = value
    if value > highest_price:
      highest_price = value

    if index == len(price_index_data) - 1:
      last_price = value

    price_points.append((index, value))

  primary_color = "#0f0" if last_price > first_price else "f00"

  return render.Root(
      child = render.Column(
        children = [
          # First row, timeframe and dollar change
          render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
              render.Text(content = get_pretty_timeframe_title(timeframe)),
              render.Text(content = str(make_two_decimal(last_price - first_price)), color = primary_color),
            ],
          ),

          # Second row, current value and percent change
          render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
              render.Text(content = str(make_two_decimal(last_price))),
              render.Text(content = str(make_two_decimal(((last_price - first_price) / first_price) * 100)) + "%", color = primary_color),
            ],
          ),

          # Graph
          render.Plot(
            data = price_points,
            width = 66,
            height = 15,
            color = primary_color,
            y_lim = (lowest_price, highest_price),
            fill = True,
          ),
        ]
      ),
  )

def two_line(line1, line2):
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

def make_two_decimal(value):
  return int(value * 100) / 100.0

def get_pretty_timeframe_title(value):
    titles = {
        "_1month": "1 mo",
        "_3months": "3 mo",
        "_6months": "6 mo",
        "_1year": "1 yr",
        "_3years": "3 yr",
        "max": "Max"
    }
    return titles.get(value, "Unknown")

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
