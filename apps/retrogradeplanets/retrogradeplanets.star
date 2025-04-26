"""
Applet: Planets Retrograde
Summary: Planets Retrograde
Description: Show whether a planet is direct or retrograde; when it became direct or retrograde; when it will again switch. 
Author: TDeveloper
"""
# Starlark Code - Corrected Indicator/Date Placement (Rx TR/D BR, Next BL)

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/base64.star", "base64")

IMAGE_BASE_URL = "https://raw.githubusercontent.com/tidbytdev/retrogradeplanets/main/base64/"
JSON_URL = "https://raw.githubusercontent.com/tidbytdev/retrogradeplanets/refs/heads/main/RetroHardCoded/retrograde_data_2020_to_2124.json"

RETROGRADE_COLOR = "#FF0000"; DIRECT_COLOR = "#00FF00"
PLANETS = [ {"name": "Mercury", "abbr": "Mercury"}, {"name": "Venus", "abbr": "Venus"}, {"name": "Mars", "abbr": "Mars"}, {"name": "Jupiter", "abbr": "Jupiter"}, {"name": "Saturn", "abbr": "Saturn"}, {"name": "Uranus", "abbr": "Uranus"}, {"name": "Neptune", "abbr": "Neptune"}, {"name": "Pluto", "abbr": "Pluto"}, ] # Earth Removed

AVAILABLE_FONTS = sorted([ "tb-8", "Dina_r400-6", "5x8", "6x13", "6x10", "6x10-rounded", "10x20", "tom-thumb", "CG-pixel-3x5-mono", "CG-pixel-4x5-mono" ])
FONT_HEIGHTS = { "tb-8": 8, "Dina_r400-6": 10, "5x8": 8, "6x13": 13, "6x10": 10, "6x10-rounded": 10, "10x20": 20, "tom-thumb": 6, "CG-pixel-3x5-mono": 5, "CG-pixel-4x5-mono": 5 }
APPROX_CHAR_WIDTHS = { "tb-8": 6, "Dina_r400-6": 6, "5x8": 5, "6x13": 6, "6x10": 6, "6x10-rounded": 6, "10x20": 10, "tom-thumb": 4, "CG-pixel-3x5-mono": 4, "CG-pixel-4x5-mono": 5 }
DEFAULT_FONT = "CG-pixel-3x5-mono"
DEFAULT_FONT_HEIGHT = FONT_HEIGHTS.get(DEFAULT_FONT, 5)
DEFAULT_CHAR_WIDTH = APPROX_CHAR_WIDTHS.get(DEFAULT_FONT, 4)
DEFAULT_IMAGE_SIZE = "32"
DEFAULT_DELAY = "1500"



def date_to_int(date_str):
    parts = date_str.split("-");
    if len(parts) != 3: fail("Invalid date format: %s" % date_str)
    y, m, d = int(parts[0]), int(parts[1]), int(parts[2])
    if m < 1 or m > 12 or d < 1 or d > 31: fail("Invalid date components: %s" % date_str)
    return y * 10000 + m * 100 + d

def format_date_mm_dd_yy(date_str):
    parts = date_str.split("-");
    if len(parts) != 3: return "?? ?? ??"
    yy = parts[0][2:]; mm = parts[1]; dd = parts[2]
    return mm + " " + dd + " " + yy

def get_schema_options(default_font):
    fonts_list = sorted(AVAILABLE_FONTS)
    if default_font not in fonts_list: fonts_list.append(default_font); fonts_list.sort()
    opts = []; default_found = False
    for f in fonts_list:
        display_name_parts = f.split('-'); display_name = display_name_parts[0]
        if len(display_name_parts) > 1:
            rest = display_name_parts[1];
            if rest.isdigit() or rest in ["mono", "rounded"] or rest.startswith("r"): display_name += " " + rest
        if f == default_font: display_name += " (Default)"; default_found = True
        opts.append(schema.Option(value=f, display=display_name))
    if not default_found: opts.append(schema.Option(value=default_font, display=default_font + " (Default)"))
    return opts

# Main app logic
def main(config):
    location_json_str = config.get("timezone"); timezone_id = "America/Dallas"
    if location_json_str:
        location_data = json.decode(location_json_str)
        if location_data and "timezone" in location_data and location_data["timezone"]: timezone_id = location_data["timezone"]
    now = time.now(location=timezone_id)
    current_year_int = now.year;
    current_year = str(current_year_int)

    rep = http.get(url=JSON_URL, ttl_seconds=86400)  # Cache for 24 hours
    if rep.status_code != 200: fail("Failed fetch '%s'. Code: %d" % (JSON_URL, rep.status_code))
    all_data = json.decode(rep.body())

    month_int = now.month; month_str = str(month_int);
    if month_int < 10: month_str = "0" + month_str
    day_int = now.day; day_str = str(day_int);
    if day_int < 10: day_str = "0" + day_str
    current_date_str = current_year + "-" + month_str + "-" + day_str
    current_date_int = date_to_int(current_date_str)


    selected_font = DEFAULT_FONT # Hardcoded default font
    selected_size_str = DEFAULT_IMAGE_SIZE
    selected_size = int(selected_size_str)
    font_height = FONT_HEIGHTS.get(selected_font, DEFAULT_FONT_HEIGHT)
    char_width = APPROX_CHAR_WIDTHS.get(DEFAULT_FONT, 4)

    frames = []
    search_years = [str(current_year_int - 2), str(current_year_int-1), current_year, str(current_year_int + 1), str(current_year_int+2)]

    for planet in PLANETS:
        # --- Status/Date Calculation ---
        is_retrograde = False; next_change_date_str = "..."; prior_date_str = "..."
        next_change_end_date_str = "..."
        min_future_start_int = 99999999; last_retro_end_date = ""; last_retro_end_int = 0
        current_period_start_date = ""
        planet_periods = [];
        for year in search_years:
            year_data = all_data.get(year, {}); planet_data = year_data.get(planet["name"])
            if planet_data != None: planet_periods.extend(planet_data)
        period_tuples = []
        for p in planet_periods:
            if len(p) == 2 and type(p[0]) == "string" and type(p[1]) == "string":
                start_int = date_to_int(p[0]); period_tuples.append((start_int, p[0], p[1]))
            else: print("Skipping malformed period data:", p)
        n = len(period_tuples);
        for i in range(n): # Bubble Sort
            swapped = False;
            for j in range(0, n-i-1):
                if period_tuples[j][0] > period_tuples[j+1][0]:
                    period_tuples[j], period_tuples[j+1] = period_tuples[j+1], period_tuples[j]; swapped = True
            if not swapped: break
        found_current_period = False
        last_retro_end_date = ""
        last_retro_end_int = 0
        for start_int, start_date, end_date in period_tuples:
            end_int = date_to_int(end_date)
            if (start_int <= current_date_int) and (current_date_int <= end_int):
                is_retrograde = True; current_period_start_date = start_date; found_current_period = True
            if end_int < current_date_int:
                last_retro_end_int = end_int; last_retro_end_date = end_date

        for start_int, start_date, end_date in period_tuples:
            end_int = date_to_int(end_date)
            if is_retrograde:
              if start_int > current_date_int:
                next_change_date_str = format_date_mm_dd_yy(start_date)
                next_change_end_date_str = format_date_mm_dd_yy(end_date)
                break
            else:
               if end_int > current_date_int:
                 next_change_date_str = format_date_mm_dd_yy(start_date)
                 next_change_end_date_str = format_date_mm_dd_yy(end_date)
                 break
        if is_retrograde:
            if current_period_start_date: prior_date_str = format_date_mm_dd_yy(current_period_start_date)
            else:
                if period_tuples: prior_date_str = "<" + format_date_mm_dd_yy(period_tuples[0][1])
                else: prior_date_str = "?? ?? ??"
        else:
            if last_retro_end_date: prior_date_str = format_date_mm_dd_yy(last_retro_end_date)
            else: prior_date_str = "ancient"
        planet_color = RETROGRADE_COLOR if is_retrograde else DIRECT_COLOR
        prior_date_color = planet_color; next_change_date_color = DIRECT_COLOR if is_retrograde else RETROGRADE_COLOR
        next_change_end_date_color = planet_color # Color of the current status

        # --- Restore plain Rx/D indicator text ---
        status_indicator = "Rx" if is_retrograde else "D"
        # --- End Status Calculation & Indicator ---

        # --- Fetch Image ---
        image_filename = "%s_%sx%s.base64" % (planet["name"].lower(), selected_size_str, selected_size_str)
        image_url = IMAGE_BASE_URL + image_filename
        image_widget = render.Box(width=selected_size, height=selected_size, color="#FF0") # Yellow placeholder
        img_rep = http.get(url=image_url, ttl_seconds=86400)
        if img_rep.status_code == 200:
            fetched_base64_data = img_rep.body()
            if fetched_base64_data:
                image_data = base64.decode(fetched_base64_data)
                if image_data: image_widget = render.Image(src=image_data)
                else: print("Failed base64 decode for %s size %s" % (planet["name"], selected_size_str))
            else: print("Empty image body for %s size %s" % (planet["name"], selected_size_str))
        else: print("Failed image fetch for %s size %s (%s). Status: %d" % (planet["name"], selected_size_str, image_url, img_rep.status_code))
        # --- End Image Fetch ---

        # --- Calculate Padding for Layout (Stack Based - Revised Positions) ---
        # Image Right Aligned (Vertically Centered)
        img_x = 64 - selected_size; img_y = max(0, (32 - selected_size) // 2)
        img_pad = (img_x, img_y, 0, 0) # L, T, R, B

        # Abbreviation Bottom Left
        abbr_y =  32 - font_height -1
        abbr_pad = (1, abbr_y, 0, 0) # L=1, T= approx bottom

        # Prior Date Top Left
        prior_pad = (1, 1, 0, 0) # L=1, T=1 (Kept low Y as requested)

        # --- Repositioned: Next Change Date Top Left (moved up) ---
        next_change_y = prior_pad[1] + font_height + 1 # Below prior date
        next_change_pad = (1, next_change_y, 0, 0)

        # --- New: Next Change End Date Below ---
        next_change_end_y = next_change_pad[1] + font_height + 1
        next_change_end_pad = (1, next_change_end_y, 0, 0)

        # --- Repositioned: Conditional Indicator Padding ---
        indicator_pad = (0,0,0,0)
        indicator_len = len(status_indicator) # Length of "Rx" or "D"
        indicator_width_approx = indicator_len * char_width
        if is_retrograde: # Rx goes Top Right
            rx_x = max(1, 64 - indicator_width_approx - 1) # Approx X pos for TR
            indicator_pad = (rx_x, 1, 0, 0) # L=Approx TR X, T=1 (Kept low Y as requested)
        else: # D goes Bottom Right (NEW POSITION)
            d_y = max(0, 32 - font_height - 1) # Approx Y pos for BR (Pad B=1)
            d_x = max(1, 64 - indicator_width_approx - 1) # Approx X pos for BR
            indicator_pad = (d_x, d_y, 0, 0) # L=Approx BR X, T=Approx BR Y
        # --- End Padding Calculation ---

        # --- Create Frame Layout using Stack ---
        planet_frame = render.Stack(
            children = [
                render.Padding(pad=img_pad, child=image_widget), # Image Right, V-Centered
                render.Padding(pad=prior_pad, child=render.Text(prior_date_str, color=prior_date_color, font=selected_font)), # Prior TL
                render.Padding(pad=abbr_pad, child=render.Text(planet["abbr"], color=planet_color, font=selected_font)), # Abbr Bottom-Left
                render.Padding(pad=next_change_pad, child=render.Text(next_change_date_str, color=next_change_date_color, font=selected_font)), # Next Change Date (Moved Up)
                render.Padding(pad=next_change_end_pad, child=render.Text(next_change_end_date_str, color=next_change_end_date_color, font=selected_font)), # Next Change End Date
                # Use actual status text, color, and NEW conditional padding
                render.Padding(pad=indicator_pad, child=render.Text(status_indicator, color=planet_color, font=selected_font)), # Indicator TR(Rx) or BR(D) (Approx X)
            ]
        )
        frames.append(planet_frame)
        # --- End Planet Loop ---

    # Return Animation, including render.Root delay as requested
    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", DEFAULT_DELAY)), # Use new default
        child = render.Animation(children=frames)
    )

def get_schema():
    # Use new defaults set globally
    default_font_schema = DEFAULT_FONT
    default_delay_schema = DEFAULT_DELAY

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "font", name = "Font", desc = "Select text font", icon = "font",
                default = default_font_schema,
                options = get_schema_options(default_font_schema)
            ),
            schema.Location(
                id = "timezone", name = "Location", desc = "Select location for accurate dates.", icon = "locationDot",
            ),
            schema.Text(
                id = "scroll",
                name = "Animation Delay",
                desc = "Custom delay for Root animation (Default: %s)" % default_delay_schema,
                icon = "timer",
                default = default_delay_schema, # Use variable for default
            ),
        ],
    )