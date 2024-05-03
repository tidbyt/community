"""
Applet: CA Renewables
Summary: Track CA's power grid
Description: See how California is using renewable energy in its power grid right now. (Solar, wind, batteries are shown by default.)
Author: @sloanesturz
"""

load("cache.star", "cache")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

FUEL_URL = "https://www.caiso.com/outlook/SP/fuelsource.csv"

# Large hydro and batteries are not officially 'green' but are certainly "clean" -- these can be excluded via the config

GREEN_FUEL_TYPES = {
    "Solar": "#ffa300",
    "Wind": "#aaff00",
    "Batteries": "#dd00dd",
    "Large Hydro": "#00dddd",
    "Geothermal": "#8f500d",
    "Biomass": "#8d8b00",
    "Biogas": "#b7b464",
    "Small hydro": "#89d1ca",
    }

CACHE_KEY = "FUEL_USAGE_DATA"

DEFAULT_DELAY = "2" # if this gets too large, not enough time to display all energy sources given app rotation

def sum(input_list):
    total = 0
    for i in input_list:
        if float(i) >= 0: # don't count negative values (exports and charging batteries) in total power supply
            total += float(i)
#         else:
#             print("charging battery or export", i)
#     print(total)
    return total

def clean_percent(amount):
    if amount < 0.01 and amount > 0: # handle charging batteries
        return humanize.float("#.##", amount * 100).lstrip("0")
    return humanize.float("#.", amount * 100)

def title(name, amount, color):
    return render.Row(children = [
        render.Text(name, color = color, font = "tom-thumb"),
        render.Text("%s%%" % clean_percent(amount), color = color, font = "tb-8"),
    ], expanded = True, main_align = "space_between", cross_align = "center")

# API returns a CSV with a title row, followed by data in 5-minute increments.
# Ex:
# Time,Solar,Wind,Geothermal,Biomass,Biogas,Small hydro,Coal,Nuclear,Natural Gas,Large Hydro,Batteries,Imports,Other
# 00:00,-4,3657,904,315,210,157,3,2244,10272,1816,84,6645,0
# 00:05,-4,3653,905,313,210,155,4,2244,10116,1756,322,6679,0
# ...
def get_raw_data():
    cached = cache.get(CACHE_KEY)
    if cached != None:
        data = cached
    else:
        rep = http.get(FUEL_URL)
        if rep.status_code != 200:
            fail("Request failed with status %d", rep.status_code)
        data = rep.body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(CACHE_KEY, data, ttl_seconds = 60 * 5)

    return data

# Turn the raw CSV into a useable data structure.
# Returns a 2-tuple
# (
#   map of fuel name -> [period-by-period array of supply MW],
#   [period-by-period array of total supply MW including non-renewables]
# )
def process_data(csv_body, display_fuel_types):
    data = csv.read_all(csv_body)
    header, rows = data[0], data[1:]
    indexes = {k: header.index(k) for k in display_fuel_types}
    totals = [sum(row[1:]) for row in rows]
    segmented = {k: [float(row[indexes[k]]) for row in rows] for k in display_fuel_types}
    return segmented, totals

# Sum the green values at each period
def get_green_total(segmented, periods):
    total = [0.0 for _ in range(periods)]
    for fuel_type in segmented.values():
        for i, value in enumerate(fuel_type):
            if value > 0: # don't count negative values (charging batteries) in total power supply
                total[i] += value
    return total

# Make a plot that shows the % of `totals` represented by `values` at each period
def make_plot(values, totals, color):
    return render.Plot(
        data = [(x, y / t) for x, (y, t) in enumerate(zip(values, totals))],
        width = 64,
        height = 32,
        x_lim = (0, 24 * 60 // 5),
        y_lim = (0, 1.0),
        color = color,
        fill = True,
        fill_color = color,
    )
    #TODO: might be interesting to show batteries charging below the x-axis

def main(config):
    
    delay = int(config.get("delay", DEFAULT_DELAY))    
    display_fuel_types = dict(GREEN_FUEL_TYPES)
    
    # Large hydro isn't on the official renewable list (not sure why, but that's how CAISO breaks it out) but is interesting enough to include
    # but if we want to exclude it or batteries from the green list, we need to remove it from the green total, and not just hide it like biogas, etc
    
    if config.get("large_hydro") == "false":
        display_fuel_types.pop("Large Hydro")
        print("removing large hydro")    
    if config.get("batteries") == "false":
        display_fuel_types.pop("Batteries")   
        print("removing batteries")    
        
    raw_csv = get_raw_data()
    segmented, totals = process_data(raw_csv,display_fuel_types)

    baseline = get_green_total(segmented, len(totals))
    baseline_plot = make_plot(baseline, totals, "#84bd00")
    baseline_stack = render.Stack([
        baseline_plot,
        title("Clean", baseline[-1] / totals[-1], "#84bd00"),
    ])
    
    
    # remove fuel sources from animation (note they are still included in the total). 
    # probably a more elegant way to do this, maybe add display options to the dictionary?)
    # also, why aren't these config values really booleans?
    
    if config.get("biogas") == "false":
        display_fuel_types.pop("Biogas")
        print("hiding biogas")
    if config.get("biomass") == "false":
        display_fuel_types.pop("Biomass")
        print("hiding biomass")
    if config.get("small_hydro") == "false":
        display_fuel_types.pop("Small hydro")
        print("hiding small hydro")
    if config.get("geothermal") == "false":
        display_fuel_types.pop("Geothermal")
        print("hiding geothermal")
    if config.get("solar") == "false":
        display_fuel_types.pop("Solar")
        print("hiding solar")
    if config.get("wind") == "false":
        display_fuel_types.pop("Wind")   
        print("hiding wind")
    if config.get("wind") == "false":
        display_fuel_types.pop("Wind")   
        print("hiding wind")    

    print("displaying", display_fuel_types)  

    background_plot = make_plot(baseline, totals, "#ffffff")
    segmented_plots = [
        render.Stack([
            background_plot,
            make_plot(segmented[name], totals, color),
            title(name, segmented[name][-1] / totals[-1], color),
        ])
        for name, color in display_fuel_types.items()
    ]
    # note that large delays, large number of stacks can prevent plots from being displayed in the app cycle
    return render.Root(delay = delay * 1000, child = render.Animation(
        [baseline_stack] + segmented_plots,
    ))

# hiding Biogas, Biomass, Geothermal, Small hydro by default -- relatively small and too many sources cause the animations to get cut off.
# Solar / wind-powered batteries are becoming a thing, often the highest source of supply in the evenings
# TO DO: Is it possible to store the display defaults in the GREEN_FUEL_TYPES along with the colors and reference them here?

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "delay",
                name = "Animation timing",
                desc = "How long to show each fuel supply",
                icon = "stopwatch",
                default = "2",
                options = [
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                    schema.Option(
                        display = "4",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5",
                        value = "5",
                    ),
                    schema.Option(
                        display = "10",
                        value = "10",
                    )
                ]
            ),        
            schema.Toggle(
                id = "solar",
                name = "Solar",
                desc = "Display solar power",
                icon = "solarPanel",
                default = True,
            ),  
            schema.Toggle(
                id = "wind",
                name = "Wind",
                desc = "Display wind power",
                icon = "wind",
                default = True,
            ), 
            schema.Toggle(
                id = "batteries",
                name = "Batteries",
                desc = "Display battery power (charged by wind/solar, negative while charging, not official renewable)",
                icon = "batteryThreeQuarters",
                default = True,
            ), 
             schema.Toggle(
                id = "geothermal",
                name = "Geothermal",
                desc = "Display geothermal power",
                icon = "mugHot",
                default = False,
            ),  
            schema.Toggle(
                id = "biogas",
                name = "Biogas",
                desc = "Display biogas power",
                icon = "fireDlameSimple",
                default = False,
            ),  
             schema.Toggle(
                id = "biomass",
                name = "Biomass",
                desc = "Display biomass power",
                icon = "leaf",
                default = False,
            ),      
             schema.Toggle(
                id = "small_hydro",
                name = "Small hydro",
                desc = "Display small hydro energy",
                icon = "glassWaterDroplet",
                default = False,
            ),  
             schema.Toggle(
                id = "large_hydro",
                name = "Large hydro",
                desc = "Display large hydro energy (not official renewable)",
                icon = "water",
                default = True,
            )              
        ],
    )
