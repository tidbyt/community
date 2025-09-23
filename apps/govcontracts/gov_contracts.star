"""
Applet: Government Contracts
Summary: Latest government contract awards from USAspending.gov
Description: Shows the most recent government contract awards from USAspending.gov with animated patriotic display. Select from multiple agencies.
Author: Anders Heie
Version: Final - Uses USAspending.gov API (actual contract awards, no API key required)
"""

load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# USAspending.gov API endpoint
USASPENDING_API_BASE = "https://api.usaspending.gov/api/v2/search/spending_by_award/"
CACHE_TTL = 3600  # Cache for 1 hour
DEFAULT_COLOR = "#FFFFFF"
DEFAULT_SPEED = 45

def main(config):
    # SHOW LOADING STATE UNTIL ALL DATA IS COMPLETELY READY
    # This prevents any animation artifacts during data preparation

    # Get configuration
    random_count = int(config.str("random_count", "5"))  # Default to 5 contracts
    main_color = config.str("main_color", DEFAULT_COLOR)  # Scrolling text color
    header_color = config.str("header_color", DEFAULT_COLOR)  # Top agency text color
    footer_color = config.str("footer_color", "#00FF00")  # Default to green
    speed = int(config.str("speed", str(DEFAULT_SPEED)))
    agency = config.str("agency", "Department of Defense")  # Default to DOD
    min_value = config.str("min_value", "ALL")  # Minimum contract value filter

    print("STARTING: Configuration loaded - agency=%s, random_count=%d, main_color=%s, header_color=%s, footer_color=%s, speed=%d, min_value=%s" % (agency, random_count, main_color, header_color, footer_color, speed, min_value))

    # CACHE DISABLED - Always fetch fresh data to eliminate inconsistencies
    print("LOADING: Fetching fresh %s contracts from USAspending.gov API (no cache) with min value: %s" % (agency, min_value))
    contracts = fetch_contracts(agency, min_value)  # Always get 50 contracts to have enough for any selection mode

    # Error handling - return immediately if no data
    if contracts == None or len(contracts) == 0:
        print("ERROR: No contracts available")
        return render_error()

    print("DATA READY: Got %d contracts from API/cache" % len(contracts))

    # SELECT CONTRACT BASED ON USER PREFERENCE (no more testing mode)
    if random_count == 1:
        # Latest only - always show the most recent contract
        final_contract = contracts[0]
        print("LATEST MODE: Showing most recent contract - contracts[0]: %s (Date: %s)" % (
            final_contract["recipient"][:30],
            final_contract["start_date"],
        ))
    else:
        # Random from recent contracts
        # Use time-based randomization that changes daily
        now = time.now()

        # Combine day, hour, and minute for a seed that changes throughout the day
        time_seed = now.day * 10000 + now.hour * 100 + now.minute
        available_contracts = min(random_count, len(contracts))
        selected_index = time_seed % available_contracts
        final_contract = contracts[selected_index]
        print("RANDOM MODE: Selected contract %d of %d available: %s (Date: %s)" % (
            selected_index + 1,
            available_contracts,
            final_contract["recipient"][:30],
            final_contract["start_date"],
        ))

    # FINAL CHECK: Ensure we have a contract selected before rendering
    if final_contract == None:
        print("ERROR: No contract selected after processing")
        return render_error()

    print("RENDERING NOW: All data prepared, starting render with final contract")

    # NOW render with the final determined contract and settings - no more data processing after this point
    return render_final_display(final_contract, main_color, header_color, footer_color, speed, agency)

def fetch_contracts(agency_name, min_value = "ALL"):
    """Search USAspending.gov for recent government contract awards with progressive date fallback"""

    # Try progressively longer date ranges: 90 days, 180 days, 365 days
    now = time.now()
    end_date = now.format("2006-01-02")  # YYYY-MM-DD format for USAspending.gov

    # Date ranges to try (in days back from today)
    date_ranges = [90, 180, 365]

    for days_back in date_ranges:
        start_timestamp = now.unix - (days_back * 24 * 60 * 60)
        start_time = time.from_timestamp(start_timestamp)
        start_date = start_time.format("2006-01-02")

        print("=== SEARCHING USASPENDING.GOV FOR RECENT %s CONTRACTS ===" % agency_name.upper())
        print("Date range: %s to %s (%d days back - searching for recent awards)" % (start_date, end_date, days_back))

        # POST request payload using the working PowerShell parameters
        payload = {
            "subawards": False,
            "limit": 100,  # Get more results to find recent $5M+ contracts
            "page": 1,
            "fields": [
                "Award ID",
                "Recipient Name",
                "Base Obligation Date",
                "Award Amount",
                "Awarding Agency",
            ],
            "sort": "Base Obligation Date",  # Sort by most recent first
            "order": "desc",
            "filters": {
                "agencies": [
                    {
                        "type": "awarding",
                        "tier": "toptier",
                        "name": agency_name,
                    },
                ],
                "award_type_codes": ["A", "B", "C", "D"],
                "time_period": [
                    {
                        "start_date": start_date,
                        "end_date": end_date,
                        "date_type": "new_awards_only",
                    },
                ],
            },
        }

        # Make POST request with retries
        response = None
        max_retries = 3
        for attempt in range(max_retries):
            print("API request attempt %d of %d" % (attempt + 1, max_retries))
            response = http.post(
                USASPENDING_API_BASE,
                headers = {"Content-Type": "application/json"},
                json_body = payload,
            )

            if response != None:
                print("USAspending.gov API response status: %d" % response.status_code)
                if response.status_code == 200:
                    break  # Success, exit retry loop
                else:
                    print("USAspending.gov API error: %d" % response.status_code)
            else:
                print("No response received (connection failed)")

            # If not the last attempt, wait before retrying
            if attempt < max_retries - 1:
                print("Retrying in 1 second...")
                # Note: Starlark doesn't have time.sleep, so we just retry immediately

        if response == None or response.status_code != 200:
            print("Failed to get valid response after %d attempts for %d days back" % (max_retries, days_back))
            continue  # Try next date range

        data = response.json()

        print("=== USASPENDING.GOV API RESPONSE STRUCTURE ===")
        for key in data.keys():
            if key != "results":
                print("  %s: %s" % (key, str(data[key])))

        results = data.get("results", [])
        print("USAspending.gov returned %d contract awards for %d days back" % (len(results), days_back))

        if len(results) > 0:
            print("=== FULL RAW JSON FOR FIRST 3 CONTRACT AWARDS ===")
            for i in range(min(3, len(results))):
                print("=== CONTRACT %d RAW JSON ===" % (i + 1))
                contract = results[i]
                for key, value in contract.items():
                    print("  %s: %s" % (key, str(value)))

        # Process the results into our contract format - already filtered by date range in API
        contracts = []

        for result in results:
            # Format award amount
            award_amount = result.get("Award Amount", 0)
            formatted_amount = ""
            if award_amount and award_amount > 0:
                if award_amount >= 1000000000:  # Billion
                    formatted_amount = "$" + str(int(award_amount / 100000000) / 10) + "B"
                elif award_amount >= 1000000:  # Million
                    formatted_amount = "$" + str(int(award_amount / 100000) / 10) + "M"
                elif award_amount >= 1000:  # Thousand
                    formatted_amount = "$" + str(int(award_amount / 100) / 10) + "K"
                else:
                    formatted_amount = "$" + str(int(award_amount))

            # Get recipient and other data first
            recipient = result.get("Recipient Name", "Unknown Contractor")
            description = result.get("Award Description", "Contract Award")

            # Get Base Obligation Date and filter out old contracts
            obligation_date = result.get("Base Obligation Date", "")

            # Filter for recent contracts within the current date range (no year restriction)
            # The API already filtered by date range, so we'll accept all results from this range

            # Apply minimum value filter
            if min_value != "ALL":
                min_amount = 0
                if min_value == "10K":
                    min_amount = 10000
                elif min_value == "50K":
                    min_amount = 50000
                elif min_value == "200K":
                    min_amount = 200000
                elif min_value == "500K":
                    min_amount = 500000
                elif min_value == "1M":
                    min_amount = 1000000
                elif min_value == "2M":
                    min_amount = 2000000
                elif min_value == "5M":
                    min_amount = 5000000
                elif min_value == "10M":
                    min_amount = 10000000

                if award_amount < min_amount:
                    print("Skipping contract below minimum value %s: $%s for %s" % (min_value, str(award_amount), recipient))
                    continue

            # Contract meets minimum value requirement, include it

            print("Including %s contract $%s: %s (Obligation: %s) - meets min value %s from %d days back" % (agency_name, str(award_amount), recipient, obligation_date, min_value, days_back))

            # Show raw JSON for NOBLE SUPPLY & LOGISTICS, LLC
            if "NOBLE SUPPLY" in recipient.upper():
                print("=== RAW JSON FOR NOBLE SUPPLY & LOGISTICS, LLC ===")
                for key, value in result.items():
                    print("  %s: %s" % (key, str(value)))

            # Create a news-style title
            agency_short = agency_name.replace("Department of ", "").replace("Department of the ", "")
            if formatted_amount:
                title = "%s awards %s contract to %s" % (agency_short, formatted_amount, recipient)
            else:
                title = "%s awards contract to %s" % (agency_short, recipient)

            # Full title preserved (no truncation - let Marquee handle long text)

            contract_data = {
                "title": title,
                "recipient": recipient,
                "amount": formatted_amount,
                "description": description[:200] if description else "",
                "start_date": obligation_date,  # Use Base Obligation Date
                "end_date": "",  # Not available with minimal fields
                "award_id": result.get("Award ID", ""),
                "awarding_agency": result.get("Awarding Agency", "DOD"),
                "contract_type": "",  # Not available with minimal fields
            }
            contracts.append(contract_data)

        if len(contracts) > 0:
            # DEDUPLICATION: Remove duplicate contracts by recipient name
            seen_recipients = {}
            deduped_contracts = []

            for contract in contracts:
                recipient = contract["recipient"]

                # Keep the first occurrence of each unique recipient
                if recipient not in seen_recipients:
                    seen_recipients[recipient] = True
                    deduped_contracts.append(contract)
                else:
                    print("Removing duplicate contract for: %s" % recipient)

            contracts = deduped_contracts
            print("After deduplication: %d unique contracts from %d days back" % (len(contracts), days_back))
            print("Processed %d recent %s contract awards from %d days back" % (len(contracts), agency_name, days_back))

            # CRITICAL: Sort contracts by start_date (Base Obligation Date) DESC to ensure latest first
            # This ensures contracts[0] is ALWAYS the most recent contract
            # Manual sorting since Starlark doesn't have built-in sort()
            sorted_contracts = []
            for contract in contracts:
                date_str = contract.get("start_date", "")

                # Convert date to sortable integer (YYYYMMDD format)
                sort_key = 0
                if date_str and len(date_str) >= 10:
                    sort_key = int(date_str.replace("-", ""))

                # Insert in correct position (DESC order - highest date first)
                inserted = False
                for i, sorted_contract in enumerate(sorted_contracts):
                    sorted_date = sorted_contract.get("start_date", "")
                    sorted_key = 0
                    if sorted_date and len(sorted_date) >= 10:
                        sorted_key = int(sorted_date.replace("-", ""))

                    if sort_key > sorted_key:  # Higher date should come first
                        sorted_contracts.insert(i, contract)
                        inserted = True
                        break

                if not inserted:
                    sorted_contracts.append(contract)

            contracts = sorted_contracts

            print("=== TOP CONTRACTS FROM %d DAYS BACK (FINAL SORTED BY DATE DESC) ===" % days_back)
            for i, contract in enumerate(contracts):
                print("  %d. %s (Obligation: %s)" % (i + 1, contract["recipient"], contract["start_date"]))

            print("SUCCESS: Found %d contracts from %d days back, returning results" % (len(contracts), days_back))
            return contracts

        print("No contracts found from %d days back that meet minimum value %s" % (days_back, min_value))

    # If we reach here, no date ranges worked
    print("No contracts found after 1 year back")
    return None

def get_agency_abbreviation(agency_name):
    """Convert agency name to abbreviation for header display"""
    agency_abbrevs = {
        "Department of Defense": "DOD",
        "Department of Health and Human Services": "HHS",
        "Department of Veterans Affairs": "VA",
        "Department of Energy": "DOE",
        "Department of Homeland Security": "DHS",
        "Department of Agriculture": "USDA",
        "Department of Transportation": "DOT",
        "Department of the Treasury": "TREAS",
        "Department of the Interior": "DOI",
        "Department of Justice": "DOJ",
        "Department of State": "STATE",
        "Department of Labor": "DOL",
        "Department of Commerce": "DOC",
        "Department of Housing and Urban Development": "HUD",
        "Department of Education": "ED",
    }
    return agency_abbrevs.get(agency_name, "GOV")

def get_agency_colors(agency_name):
    """Get representative colors for each government agency"""
    agency_colors = {
        # Defense - Military greens, olive, camouflage browns
        "Department of Defense": ["#4B5320", "#355E3B", "#8B4513", "#556B2F"],  # Olive drab, forest green, saddle brown, dark olive

        # Health & Human Services - Medical blues, whites, healing greens
        "Department of Health and Human Services": ["#1E90FF", "#00CED1", "#20B2AA", "#4682B4"],  # Dodger blue, dark turquoise, light sea green, steel blue

        # Veterans Affairs - Patriotic red, white, blue with gold
        "Department of Veterans Affairs": ["#B22222", "#FFFFFF", "#000080", "#DAA520"],  # Fire brick red, white, navy blue, goldenrod

        # Energy - Nuclear yellow, electric blue, uranium green, solar orange
        "Department of Energy": ["#FFD700", "#1E90FF", "#32CD32", "#FF8C00"],  # Gold, dodger blue, lime green, dark orange

        # Homeland Security - Security blues, alert orange, steel gray
        "Department of Homeland Security": ["#191970", "#FF4500", "#708090", "#4169E1"],  # Midnight blue, orange red, slate gray, royal blue

        # Agriculture - Farm greens, earth browns, grain gold
        "Department of Agriculture": ["#228B22", "#8B4513", "#DAA520", "#6B8E23"],  # Forest green, saddle brown, goldenrod, olive drab

        # Transportation - Highway orange, road gray, sky blue, warning yellow
        "Department of Transportation": ["#FF8C00", "#696969", "#87CEEB", "#FFFF00"],  # Dark orange, dim gray, sky blue, yellow

        # Treasury - Money green, gold, federal blue, silver
        "Department of the Treasury": ["#006400", "#FFD700", "#191970", "#C0C0C0"],  # Dark green, gold, midnight blue, silver

        # Interior - National park browns, canyon orange, forest green, sky blue
        "Department of the Interior": ["#8B4513", "#CD853F", "#228B22", "#87CEEB"],  # Saddle brown, peru, forest green, sky blue

        # Justice - Law enforcement blue, court burgundy, badge gold, justice gray
        "Department of Justice": ["#000080", "#800020", "#DAA520", "#708090"],  # Navy blue, burgundy, goldenrod, slate gray

        # State - Diplomatic blue, embassy gold, international white, formal gray
        "Department of State": ["#191970", "#DAA520", "#F5F5DC", "#778899"],  # Midnight blue, goldenrod, beige, light slate gray

        # Labor - Industrial blue, worker orange, union red, steel gray
        "Department of Labor": ["#4682B4", "#FF8C00", "#B22222", "#708090"],  # Steel blue, dark orange, fire brick, slate gray

        # Commerce - Business blue, trade gold, market green, corporate gray
        "Department of Commerce": ["#1E90FF", "#FFD700", "#32CD32", "#696969"],  # Dodger blue, gold, lime green, dim gray

        # Housing & Urban Development - Urban blue, housing brown, development green, community gold
        "Department of Housing and Urban Development": ["#4169E1", "#8B4513", "#228B22", "#DAA520"],  # Royal blue, saddle brown, forest green, goldenrod

        # Education - School blue, academic red, knowledge gold, learning green
        "Department of Education": ["#0000CD", "#DC143C", "#FFD700", "#32CD32"],  # Medium blue, crimson, gold, lime green
    }

    # Default to patriotic military colors if agency not found
    return agency_colors.get(agency_name, ["#4B5320", "#C19A6B", "#355E3B", "#8B4513"])

def render_final_display(contract, main_color, header_color, footer_color, speed, agency_name):
    """Render with patriotic theme - GUARANTEED no pre-rendering artifacts"""

    print("RENDER START: Final display render beginning")
    title = contract["title"]
    start_date = contract.get("start_date", "")
    amount = contract.get("amount", "")
    print("RENDER DATA: Title=%s, Date=%s, Amount=%s, MainColor=%s, HeaderColor=%s, FooterColor=%s" % (title[:40], start_date, amount, main_color, header_color, footer_color))

    # Create agency abbreviation for header
    agency_abbrev = get_agency_abbreviation(agency_name)

    # Get agency-specific colors for the animated bands
    agency_colors = get_agency_colors(agency_name)

    # Format the date (assuming it comes in YYYY-MM-DD format)
    formatted_date = "No date"
    if start_date and len(str(start_date)) >= 10:
        # Convert YYYY-MM-DD to DD MMM, YYYY
        parts = str(start_date).split("-")
        if len(parts) == 3:
            year = parts[0]
            month = parts[1]
            day = parts[2]
            month_names = [
                "Jan",
                "Feb",
                "Mar",
                "Apr",
                "May",
                "Jun",
                "Jul",
                "Aug",
                "Sep",
                "Oct",
                "Nov",
                "Dec",
            ]
            month_num = int(month) - 1  # Convert to 0-based index
            if 0 <= month_num and month_num <= 11:
                # Format as dd MMM, yyyy (e.g., "01 Aug, 2016")
                formatted_date = day + " " + month_names[month_num] + ", " + year
            else:
                formatted_date = day + "/" + month + "/" + year
        else:
            formatted_date = str(start_date)

    # Keep date only in footer like Executive Orders app
    # Amount is already shown in the scrolling title

    # Create agency-themed line animation with representative colors
    patriotic_frames = []

    # Use agency-specific colors
    colors = agency_colors
    print("RENDER: Using agency colors for %s: %s" % (agency_name, str(colors)))

    # Create 28 frames for smooth animation (7 pixels per color * 4 colors)
    for frame in range(28):
        frame_boxes = []
        for pixel in range(62):  # 62 pixels wide (64 - 2 for margins)
            color_index = (pixel + frame) // 7 % 4  # Each color is 7 pixels wide
            frame_boxes.append(render.Box(width = 1, height = 2, color = colors[color_index]))

        patriotic_frames.append(render.Row(children = frame_boxes))

    patriotic_line = render.Animation(children = patriotic_frames)
    patriotic_line_bottom = render.Animation(children = patriotic_frames)

    # CONSISTENT SCROLLING: Force fresh start by adding padding to ensure text starts off-screen right
    print("RENDER: Creating scrolling text with FULL content (length %d): %s" % (len(title), title))

    if len(title) > 11:
        # Add enough spaces to push text off-screen to the right, ensuring consistent start position
        padded_title = "        " + title  # 8 spaces to ensure start from right edge
        print("RENDER: Final padded scrolling text: %s" % padded_title)
        scrolling_title = render.Marquee(
            width = 62,
            child = render.Text(content = padded_title, color = main_color, font = "tb-8"),
            scroll_direction = "horizontal",
        )
    else:
        scrolling_title = render.Text(content = title, color = main_color, font = "tb-8")

    # Main display with 1 pixel margin all around
    return render.Root(
        delay = speed,  # Use configured speed for animations
        child = render.Padding(
            pad = (1, 1, 1, 1),  # 1 pixel margin on all sides
            child = render.Stack(
                children = [
                    # Government Contracts header at top, centered
                    render.Box(
                        width = 62,
                        height = 6,
                        child = render.Row(
                            main_align = "center",
                            children = [
                                render.Text(
                                    content = agency_abbrev + " Contracts",
                                    color = header_color,
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                    # Scrolling elements centered in middle
                    render.Padding(
                        pad = (0, 10, 0, 6),  # Push content down slightly
                        child = render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                patriotic_line,
                                scrolling_title,
                                patriotic_line_bottom,
                            ],
                        ),
                    ),
                    # Date and amount centered at bottom
                    render.Padding(
                        pad = (0, 24, 0, 0),
                        child = render.Box(
                            width = 62,
                            height = 7,
                            child = render.Row(
                                main_align = "center",
                                children = [
                                    render.Text(
                                        content = formatted_date,
                                        color = footer_color,
                                        font = "tom-thumb",
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        ),
    )

def int_to_hex(value):
    """Convert integer to 2-digit hex string"""
    if value >= 255:
        return "FF"
    elif value <= 0:
        return "00"
    else:
        hex_chars = "0123456789ABCDEF"
        high = value // 16
        low = value % 16
        return hex_chars[high] + hex_chars[low]

def compile_patriotic_cells():
    """Create transparency levels for patriotic firework colors"""
    cells = []

    # Massive collection of vibrant colors
    patriotic_colors = (
        # Primary patriotic
        "#F00",
        "#FFF",
        "#00F",
        "#FD0",  # Red, White, Blue, Gold
        # Bright variations
        "#F44",
        "#F0F",
        "#0FF",
        "#FF0",  # Pink, Magenta, Cyan, Yellow
        "#F80",
        "#8F0",
        "#80F",
        "#0F8",  # Orange, Lime, Purple, Teal
        "#FA0",
        "#AF0",
        "#A0F",
        "#0FA",  # Amber, Green, Violet, Mint
        # Electric colors
        "#F4F",
        "#4FF",
        "#FF4",
        "#4F4",  # Electric Pink, Cyan, Yellow, Green
        "#E0E",
        "#0EE",
        "#EE0",
        "#E00",  # Bright Purple, Cyan, Yellow, Red
        # Neon variations
        "#F0A",
        "#A0F",
        "#0AF",
        "#AF0",  # Neon Pink, Purple, Blue, Green
        "#FAA",
        "#AFA",
        "#AAF",
        "#FFA",  # Light Pink, Green, Blue, Yellow
        # Additional spectral
        "#F66",
        "#6F6",
        "#66F",
        "#FF6",  # Light Red, Green, Blue, Yellow
        "#6FF",
        "#F6F",
        "#6F0",
        "#F06",  # Light Cyan, Magenta, Lime, Orange
    )
    for c in patriotic_colors:
        color_group = []
        for i in range(16):
            color_group.append(render.Box(width = 1, height = 1, color = c + "%X" % i))
        cells.append(color_group)
    return cells

def create_patriotic_rockets():
    """Create spectacular firework rockets with massive explosions"""
    random.seed(42)  # Consistent fireworks for error screen

    ROCKET_COUNT = 6  # Perfect number with great staggered timing
    ROCKET_FUSE_SPACING = 800  # Well-spaced staggered launches

    patriotic_cells = compile_patriotic_cells()
    rockets = []

    for rocket_i in range(ROCKET_COUNT):
        # Random explosion sizes - some massive, some small
        explosion_size = random.number(1, 4)  # 1=small, 2=medium, 3=large, 4=massive

        if explosion_size == 1:  # Small burst - but bigger than before
            flares_count = random.number(80, 120)
            flares_radius = random.number(6, 8)
        elif explosion_size == 2:  # Medium burst - much bigger
            flares_count = random.number(140, 200)
            flares_radius = random.number(8, 12)
        elif explosion_size == 3:  # Large burst - screen filling
            flares_count = random.number(200, 300)
            flares_radius = random.number(12, 18)
        else:  # MASSIVE burst - absolutely enormous
            flares_count = random.number(300, 400)
            flares_radius = random.number(16, 24)

        max_altitude = 32 - flares_radius
        min_altitude = max_altitude - 6

        rockets.append({
            "cells": patriotic_cells[random.number(0, len(patriotic_cells) - 1)],
            "fuse": ROCKET_FUSE_SPACING * rocket_i + random.number(0, 200),  # Random timing
            "position_x": random.number(flares_radius, 64 - flares_radius),
            "altitude": -1,
            "max_altitude": random.number(min_altitude, max_altitude),
            "burst_frame_ms": -1,
            "flares_done_frame_ms": -1,
            "flares": [],
            "flares_done": False,
            "fades_done": False,
            "flares_count": flares_count,
            "flares_radius": flares_radius,
        })

        # Create more chaotic flare patterns
        radii_odds = 0
        layers_twist = []

        for r in range(flares_radius):
            # More random twist angles for chaotic spread
            layers_twist.append(random.number(0, 0xFFFFFFFF) / 0xFFFFFFFF * 4 * math.pi)  # Double the twist
            radii_odds += (r + 1) * (r + 1)

        # Create more flares with random distribution
        for _ in range(flares_count):
            rand_shell = random.number(1, radii_odds)
            shell = 0
            dist = 0

            for _ in range(rand_shell):
                dist += 1
                shell += dist * dist
                if shell >= rand_shell:
                    break

            # Add randomness to flare angles for more chaotic spread
            random_twist = (random.number(0, 100) - 50) / 100.0 * math.pi / 4  # ±45 degrees random

            new_flare = {
                "angle": layers_twist[dist - 1] + random_twist,
                "max_dist": dist,
                "speed_multiplier": random.number(80, 120) / 100.0,  # Varied speeds
            }
            rockets[-1]["flares"].append(new_flare)

        # Spread flares with more randomness
        for shell in range(1, flares_radius + 1):
            flares_in_shell = []
            for flare in rockets[-1]["flares"]:
                if flare["max_dist"] == shell:
                    flares_in_shell.append(flare)

            # Add random spacing instead of perfectly even distribution
            for i, flare in enumerate(flares_in_shell):
                base_angle = ((2 * math.pi) / len(flares_in_shell)) * i
                random_offset = (random.number(0, 100) - 50) / 100.0 * math.pi / 6  # Random spread
                flare["angle"] = base_angle + random_offset
                flare["cos"] = math.cos(flare["angle"])
                flare["sin"] = math.sin(flare["angle"])

    return rockets

def render_patriotic_rocket(timestamp_ms, frame_delay, rocket):
    """Render a single spectacular patriotic firework rocket"""
    ROCKET_SPEED = 15  # Faster rockets
    ROCKET_FLARE_SPEED = 12  # Faster explosion spread
    ROCKET_FLARES_DECAY = 800  # Longer fade time for bigger explosions

    cells = []
    if rocket["fuse"] > 0:
        rocket["fuse"] = max(0, rocket["fuse"] - frame_delay)
    elif rocket["fades_done"]:
        pass
    elif rocket["altitude"] < rocket["max_altitude"]:
        # Draw ascending rocket
        rocket["altitude"] += frame_delay / 1000 * ROCKET_SPEED
        rocket["altitude"] = min(rocket["altitude"], rocket["max_altitude"])
        r_pad = (
            rocket["position_x"],
            32 - int(rocket["altitude"]),
            0,
            0,
        )
        cells.append(render.Padding(child = rocket["cells"][15], pad = r_pad))
    else:
        # Draw massive explosion with different patterns
        rocket["altitude"] = rocket["max_altitude"]
        flares_radius = rocket["flares_radius"]
        burst_length_ms = flares_radius / ROCKET_FLARE_SPEED * 1000

        if rocket["burst_frame_ms"] == -1:
            rocket["burst_frame_ms"] = timestamp_ms

        if rocket["burst_frame_ms"] > -1:
            burst_percent = min(1, (timestamp_ms - rocket["burst_frame_ms"]) / burst_length_ms)
        else:
            burst_percent = 0

        if burst_percent == 1 and rocket["flares_done_frame_ms"] == -1:
            rocket["flares_done_frame_ms"] = timestamp_ms
            rocket["flares_done"] = True

        # Create different explosion patterns based on rocket index
        pattern_type = len(rocket["flares"]) % 4  # 4 different patterns

        for flare in rocket["flares"]:
            # Create smooth brightness transition from center (bright) to edge (dim)
            distance_ratio = flare["max_dist"] / flares_radius  # 0.0 (center) to 1.0 (edge)

            # Base brightness decreases with distance from center
            base_brightness = 1.0 - (distance_ratio * 0.6)  # Center=1.0, Edge=0.4

            if rocket["flares_done"]:
                # Fade out with distance-based brightness
                fade_time = ROCKET_FLARES_DECAY * (0.8 + flare.get("speed_multiplier", 1.0) * 0.4)
                time_fade = 1 - min(1, (timestamp_ms - rocket["flares_done_frame_ms"]) / fade_time)

                # Combine time fade with distance fade
                total_brightness = base_brightness * time_fade
                fade_idx = int(total_brightness * 15)
                fade_idx = max(0, min(15, fade_idx))  # Clamp to valid range

                rocket["fades_done"] = fade_idx == 0
                cell = rocket["cells"][fade_idx]
            else:
                # During explosion, apply distance-based brightness
                fade_idx = int(base_brightness * 15)
                fade_idx = max(0, min(15, fade_idx))  # Clamp to valid range
                cell = rocket["cells"][fade_idx]

            # Apply speed multiplier and pattern modifications
            speed_mult = flare.get("speed_multiplier", 1.0)
            base_distance = burst_percent * flare["max_dist"] * speed_mult

            if pattern_type == 0:  # Standard circular
                flare_distance = base_distance
            elif pattern_type == 1:  # Expanding ring
                flare_distance = base_distance * (1 + 0.3 * math.sin(burst_percent * 2 * math.pi))
            elif pattern_type == 2:  # Spiral burst
                spiral_angle = flare["angle"] + burst_percent * 2 * math.pi
                flare_distance = base_distance
                flare["cos"] = math.cos(spiral_angle)
                flare["sin"] = math.sin(spiral_angle)
            else:  # Chaotic explosion
                chaos_factor = 1 + 0.5 * math.sin(burst_percent * 4 * math.pi + flare["angle"])
                flare_distance = base_distance * chaos_factor

            flare_pad = (
                int(rocket["position_x"] + flare["cos"] * flare_distance),
                int(32 - rocket["altitude"] + flare["sin"] * flare_distance),
                0,
                0,
            )

            # Only draw flares that are on screen
            if (0 <= flare_pad[0] and flare_pad[0] < 64) and (0 <= flare_pad[1] and flare_pad[1] < 32) and not rocket["fades_done"]:
                cells.append(render.Padding(child = cell, pad = flare_pad))

    return render.Stack(children = cells)

def render_error():
    """Render spectacular patriotic fireworks error display"""

    # Animation settings for perfectly timed staggered show
    frame_delay = 60  # Smooth 60fps animation
    duration_ms = 12000  # Longer duration for staggered timing (12 seconds)
    frame_count = int(duration_ms / frame_delay)

    # Create spectacular patriotic fireworks
    rockets = create_patriotic_rockets()

    # Generate animation frames
    fireworks_frames = []
    timestamp_ms = 0

    for _ in range(frame_count):
        frame_stack = []

        # Render all rockets for this frame
        for rocket in rockets:
            rocket_render = render_patriotic_rocket(timestamp_ms, frame_delay, rocket)
            frame_stack.append(rocket_render)

        fireworks_frames.append(render.Stack(children = frame_stack))
        timestamp_ms += frame_delay

    fireworks_animation = render.Animation(children = fireworks_frames)

    # Main error display with fireworks background
    return render.Root(
        delay = 100,  # Fast animation
        child = render.Stack(
            children = [
                # Fireworks background
                fireworks_animation,
                # Error text overlay
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Box(height = 8),  # Top spacer
                        render.Box(
                            width = 64,
                            height = 16,
                            child = render.Row(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = "No contracts found",
                                        color = "#FFFFFF",
                                        width = 60,
                                        font = "tb-8",
                                        align = "center",
                                    ),
                                ],
                            ),
                        ),
                        render.Box(height = 8),  # Bottom spacer
                    ],
                ),
            ],
        ),
    )

def get_schema():
    """Configuration schema for the app"""

    # All major government agencies available in USAspending.gov
    agency_options = [
        schema.Option(
            display = "Defense",
            value = "Department of Defense",
        ),
        schema.Option(
            display = "Health and Human Services",
            value = "Department of Health and Human Services",
        ),
        schema.Option(
            display = "Veterans Affairs",
            value = "Department of Veterans Affairs",
        ),
        schema.Option(
            display = "Energy",
            value = "Department of Energy",
        ),
        schema.Option(
            display = "Homeland Security",
            value = "Department of Homeland Security",
        ),
        schema.Option(
            display = "Agriculture",
            value = "Department of Agriculture",
        ),
        schema.Option(
            display = "Transportation",
            value = "Department of Transportation",
        ),
        schema.Option(
            display = "Treasury",
            value = "Department of the Treasury",
        ),
        schema.Option(
            display = "Interior",
            value = "Department of the Interior",
        ),
        schema.Option(
            display = "Justice",
            value = "Department of Justice",
        ),
        schema.Option(
            display = "State",
            value = "Department of State",
        ),
        schema.Option(
            display = "Labor",
            value = "Department of Labor",
        ),
        schema.Option(
            display = "Commerce",
            value = "Department of Commerce",
        ),
        schema.Option(
            display = "Housing and Urban Development",
            value = "Department of Housing and Urban Development",
        ),
        schema.Option(
            display = "Education",
            value = "Department of Education",
        ),
    ]

    color_options = [
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
        schema.Option(
            display = "Light Blue",
            value = "#00BFFF",
        ),
        schema.Option(
            display = "Blue",
            value = "#0099FF",
        ),
        schema.Option(
            display = "Navy Blue",
            value = "#000080",
        ),
        schema.Option(
            display = "Cyan",
            value = "#00FFFF",
        ),
        schema.Option(
            display = "Light Green",
            value = "#90EE90",
        ),
        schema.Option(
            display = "Green",
            value = "#00FF00",
        ),
        schema.Option(
            display = "Forest Green",
            value = "#228B22",
        ),
        schema.Option(
            display = "Red",
            value = "#FF0000",
        ),
        schema.Option(
            display = "Orange Red",
            value = "#FF4500",
        ),
        schema.Option(
            display = "Orange",
            value = "#FFA500",
        ),
        schema.Option(
            display = "Yellow",
            value = "#FFFF00",
        ),
        schema.Option(
            display = "Gold",
            value = "#FFD700",
        ),
        schema.Option(
            display = "Pink",
            value = "#FF69B4",
        ),
        schema.Option(
            display = "Purple",
            value = "#9932CC",
        ),
        schema.Option(
            display = "Silver",
            value = "#C0C0C0",
        ),
    ]

    speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
    ]

    random_options = [
        schema.Option(
            display = "Latest only (1)",
            value = "1",
        ),
        schema.Option(
            display = "Random from last 5",
            value = "5",
        ),
        schema.Option(
            display = "Random from last 10",
            value = "10",
        ),
        schema.Option(
            display = "Random from last 25",
            value = "25",
        ),
    ]

    min_value_options = [
        schema.Option(
            display = "All Contracts",
            value = "ALL",
        ),
        schema.Option(
            display = "$10K+",
            value = "10K",
        ),
        schema.Option(
            display = "$50K+",
            value = "50K",
        ),
        schema.Option(
            display = "$200K+",
            value = "200K",
        ),
        schema.Option(
            display = "$500K+",
            value = "500K",
        ),
        schema.Option(
            display = "$1M+",
            value = "1M",
        ),
        schema.Option(
            display = "$2M+",
            value = "2M",
        ),
        schema.Option(
            display = "$5M+",
            value = "5M",
        ),
        schema.Option(
            display = "$10M+",
            value = "10M",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "agency",
                name = "Government Agency",
                desc = "Select which government agency contracts to display",
                icon = "building",
                default = agency_options[0].value,  # Default to Defense
                options = agency_options,
            ),
            schema.Dropdown(
                id = "random_count",
                name = "Contract Selection",
                desc = "Show latest contract or randomize from recent contracts",
                icon = "dice",
                default = random_options[1].value,  # Default to "Random from last 5"
                options = random_options,
            ),
            schema.Dropdown(
                id = "min_value",
                name = "Minimum Contract Value",
                desc = "Filter contracts by minimum dollar amount",
                icon = "dollar-sign",
                default = min_value_options[0].value,  # Default to "All Contracts"
                options = min_value_options,
            ),
            schema.Dropdown(
                id = "main_color",
                name = "Main Color",
                desc = "Color of the scrolling contract text",
                icon = "palette",
                default = color_options[0].value,  # White
                options = color_options,
            ),
            schema.Dropdown(
                id = "header_color",
                name = "Header Color",
                desc = "Color of the agency header text",
                icon = "palette",
                default = color_options[0].value,  # White
                options = color_options,
            ),
            schema.Dropdown(
                id = "footer_color",
                name = "Footer Color",
                desc = "Color of the date footer text",
                icon = "palette",
                default = color_options[6].value,  # Green
                options = color_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Speed of text scrolling animation",
                icon = "gauge",
                default = speed_options[1].value,
                options = speed_options,
            ),
        ],
    )
