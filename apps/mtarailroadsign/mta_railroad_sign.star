"""
Applet: MTA Railroad Sign
Summary: Metro-North/LIRR next train
Description: Adds a realtime next train sign for any Metro-North or Long Island Rail Road station to your Tidbyt.
Author: nataliemakhijani
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# OBJECTS
STATION_NAMES = {
    "ALL": "No filter",
    "ABT": "Albertson",
    "AGT": "Amagansett",
    "AVL": "Amityville",
    "5AN": "Ansonia",
    "1AT": "Appalachian Trail",
    "0AR": "Ardsley-on-Hudson",
    "ATL": "Atlantic Term",
    "ADL": "Auburndale",
    "BTA": "Babylon",
    "BWN": "Baldwin",
    "BSR": "Bay Shore",
    "BSD": "Bayside",
    "0BC": "Beacon",
    "5BF": "Beacon Falls",
    "1BH": "Bedford Hills",
    "BRS": "Bellerose",
    "BMR": "Bellmore",
    "BPT": "Bellport",
    "BRT": "Belmont Pk",
    "4BE": "Bethel",
    "BPG": "Bethpage",
    "BOL": "Bolands-Crew",
    "1BG": "Botanical Garden",
    "4BV": "Branchville",
    "0BK": "Breakneck Rdg",
    "BWD": "Brentwood",
    "1BW": "Brewster",
    "BHN": "Bridgehampton",
    "2BP": "Bridgeport",
    "BDY": "Broadway",
    "1BX": "Bronxville",
    "4CA": "Cannondale",
    "CPL": "Carle Pl",
    "CHT": "Cedarhurst",
    "CI": "Cntrl Islip",
    "CAV": "Centre Av",
    "1CQ": "Chappaqua",
    "0CS": "Cold Spring",
    "CSH": "Cold Sprng Hbr",
    "CPG": "Copiague",
    "0CT": "Cortlandt",
    "2CC": "Cos Cob",
    "CLP": "Cty Life Press",
    "1CW": "Crestwood",
    "1CF": "Croton Falls",
    "0HM": "Croton-Harmon",
    "4DN": "Danbury",
    "2DA": "Darien",
    "DPK": "Deer Pk",
    "5DB": "Derby-Shelton",
    "0DF": "Dobbs Ferry",
    "DGL": "Douglaston",
    "1DO": "Dover Plains",
    "EHN": "East Hampton",
    "ENY": "East New York",
    "2EN": "East Norwalk",
    "ERY": "East Rockaway",
    "EWN": "East Williston",
    "EMT": "Elmont UBS",
    "2FF": "Fairfield",
    "2FM": "Fairfield-B Rock",
    "FRY": "Far Rockaway",
    "FMD": "Farmingdale",
    "1FW": "Fleetwood",
    "FPK": "Floral Pk",
    "FLS": "Flushing",
    "1FO": "Fordham",
    "FHL": "Forest Hills",
    "FPT": "Freeport",
    "GCY": "Garden City",
    "0GA": "Garrison",
    "GBN": "Gibson",
    "GCV": "Glen Cove",
    "GHD": "Glen Head",
    "GST": "Glen St",
    "3GB": "Glenbrook",
    "0GD": "Glenwood",
    "1GO": "Goldens Br",
    "GCT": "Grand Central",
    "0NY": "Grand Central",
    "_GC": "Grand Central",
    "GNK": "Great Neck",
    "GRV": "Great River",
    "2GF": "Green's Farms",
    "GWN": "Greenlawn",
    "GPT": "Greenport",
    "GVL": "Greenvale",
    "2GN": "Greenwich",
    "0GY": "Greystone",
    "HBY": "Hampton Bays",
    "1WI": "Harlem Valley-Wingdale",
    "0HL": "Halem-125 St",
    "2HS": "Harrison",
    "1HA": "Hartsdale",
    "0HS": "Hastings-on-Hudson",
    "1HN": "Hawthorne",
    "HEM": "Hempstead",
    "HGN": "Hempst'd Grdns",
    "HWT": "Hewlett",
    "HVL": "Hicksville",
    "0HB": "CREW-Highbridge",
    "HIL": "CREW-Hillside",
    "HOL": "Hollis",
    "HPA": "Hunterspoint Av",
    "HUN": "Huntington",
    "IWD": "Inwood",
    "0IV": "Irvington",
    "IPK": "Island Pk",
    "ISP": "Islip",
    "JAM": "Jamaica",
    "1KA": "Katonah",
    "KGN": "Kew Gardens",
    "KPK": "Kings Park",
    "LVW": "Lakeview",
    "2LA": "Larchmont",
    "LTN": "Laurelton",
    "LCE": "Lawrence",
    "LHT": "Lindenhurst",
    "LNK": "Little Neck",
    "LMR": "Locust Manor",
    "LVL": "Locust Valley",
    "LBH": "Long Beach",
    "LIC": "LI City",
    "0LU": "Ludlow",
    "LYN": "Lynbrook",
    "MVN": "Malverne",
    "2MA": "Mamaroneck",
    "MHT": "Manhasset",
    "0MN": "Manitou",
    "0MB": "Marble Hill",
    "MQA": "Massapequa",
    "MPK": "Massapequa Pk",
    "MSY": "Mastic-Sh'rl'y",
    "MAK": "Mattituck",
    "MFD": "Medford",
    "1ML": "Melrose",
    "MAV": "Merillon Av",
    "MRK": "Merrick",
    "4M7": "Merritt 7",
    "SSM": "Mets-Willets",
    "2MI": "Milford",
    "MIN": "Mineola",
    "MTK": "Montauk",
    "0MH": "Morris Hts",
    "1MK": "Mt Kisco",
    "1MP": "Mt Pleasant",
    "2ME": "Mt Vernon E",
    "1MW": "Mt Vernon W",
    "MHL": "Murray Hill",
    "NBD": "Nassau Bl",
    "5NG": "Naugatuck",
    "3NC": "New Canaan",
    "0NM": "New Hamburg",
    "2NH": "New Haven",
    "2SS": "N Haven-State",
    "NHP": "New Hyde Pk",
    "2NR": "New Rochelle",
    "2NO": "Noroton Hts",
    "1NW": "N White Plains",
    "NPT": "Northport",
    "NAV": "Nostrand Av",
    "ODL": "Oakdale",
    "ODE": "Oceanside",
    "2OG": "Old Greenwich",
    "0OS": "Ossining",
    "OBY": "Oyster Bay",
    "PGE": "Patchogue",
    "1PA": "Patterson",
    "1PW": "Pawling",
    "0PE": "Peekskill",
    "2PH": "Pelham",
    "NYK": "Penn Station",
    "0PM": "Philipse Manor",
    "PLN": "Pinelawn",
    "PDM": "Plandome",
    "1PV": "Pleasantville",
    "2PC": "Port Chester",
    "PJN": "Port Jefferson",
    "PWS": "Pt Washington",
    "0PO": "Poughkeepsie",
    "1PY": "Purdy's",
    "QVG": "Queens Village",
    "4RD": "Redding",
    "0RV": "Riverdale",
    "RHD": "Riverhead",
    "2RS": "Riverside",
    "RVC": "Rockville Ctr",
    "RON": "Ronkonkoma",
    "ROS": "Rosedale",
    "RSN": "Roslyn",
    "2RO": "Rowayton",
    "2RY": "Rye",
    "SVL": "Sayville",
    "0SB": "Scarborough",
    "1SC": "Scarsdale",
    "SCF": "Sea Cliff",
    "SFD": "Seaford",
    "5SY": "Seymour",
    "STN": "Smithtown",
    "2SN": "South Norwalk",
    "SHN": "Southampton",
    "1BR": "Southeast",
    "SHD": "Southold",
    "2SP": "Southport",
    "SPK": "Speonk",
    "3SD": "Springdale",
    "0DV": "Spuyten Duyvil",
    "SAB": "St. Albans",
    "SJM": "St. James",
    "2SM": "Stamford",
    "SMR": "Stewart Manor",
    "BK": "Stony Brook",
    "2SR": "Stratford",
    "SYT": "Syosset",
    "3TH": "Talmadge Hill",
    "0TT": "Tarrytown",
    "1TM": "Tenmile River",
    "1TR": "Tremont",
    "1TK": "Tuckahoe",
    "0UH": "University Hts",
    "1VA": "Valhalla",
    "VSM": "Valley Stream",
    "1WF": "Wakefield",
    "WGH": "Wantagh",
    "1WA": "Wassaic",
    "5WB": "Waterbury",
    "2WH": "W Haven",
    "WHD": "W Hempstead",
    "WBY": "Westbury",
    "WHN": "Westhampton",
    "2WP": "Westport",
    "WWD": "Westwood",
    "1WP": "White Plains",
    "1WG": "Williams Br",
    "4WI": "Wilton",
    "1WN": "Woodlawn",
    "WMR": "Woodmere",
    "WDD": "Woodside",
    "WYD": "Wyandanch",
    "0YS": "Yankees-E 153 St",
    "YPK": "Yaphank",
    "0YK": "Yonkers",
}
BRANCH_CODES = {
    "ALL": "All branches",
    "BY": "Babylon",
    # "":"Belmont", # Not sure what the branch code for Belmont is. Need to wait for horse racing season to find out.
    "CI": "City Terminal Zone",
    "FR": "Far Rockaway",
    "HM": "Hempstead",
    "LB": "Long Beach",
    "MK": "Montauk",
    "OB": "Oyster Bay",
    "HH": "Port Jefferson",
    "PJ": "Port Jefferson",
    "PW": "Port Washington",
    "RK": "Ronkonkoma",
    "WH": "West Hempstead",
    "HU": "Hudson",
    "NH": "New Haven",
    "HA": "Harlem",
    "NC": "New Canaan",
    "WB": "Waterbury",
    "DN": "Danbury",
    "??": "Unknown",
}
API_HEADERS = {
    "Accept-Version": "3.0",
}
TERMINAL_CODES = {
    "All": "All",
    "NYK NYP": "Penn Station",
    "GCT 0NY _GCT": "Grand Central",
    "JAM": "Jamaica",
    "HPA": "Hunterspoint Av",
    "ATL": "Atlantic Terminal",
    "LIC": "Long Island City",
    "0PO": "Poughkeepsie",
    "0HM": "Croton-Harmon",
    "2SM": "Stamford",
    "3NC": "New Canaan",
    "2NH": "New Haven",
    "2SS": "New Haven-State St",
    "4DN": "Danbury",
    "5WB": "Waterbury",
    "1WA": "Wassaic",
    "1BR": "Southeast",
}

# ERRORS
def NO_TRAINS(station):
    return render.Root(
        child = render.Column(
            children = [
                render.Text("No trains for"),
                render.Text("this station +"),
                render.Text("branch at this"),
                render.Text("time (%s)." % station),
            ],
        ),
    )

def API_ERROR(code):
    return render.Root(
        child = render.Column(
            children = [
                render.Text("An error (%s)" % code),
                render.Text("occured while"),
                render.Text("fetching data."),
            ],
        ),
    )

# DEFAULTS
DEFAULT_STATION = "JAM"
DEFAULT_DIRECTION = "NESW"
DEFAULT_BRANCH = "ALL"
DEFAULT_FILTER_STOP = "ALL"

# COLORS
OCCUPANCY_COLORS = {
    "EMPTY": "#00c164",  # #00c364
    "MANY_SEATS": "#e5a400",  # #fae100
    "FEW_SEATS": "#e6a500",  # #e6a500
    "SRO": "#ff1500",  # #ff1500
    "FULL": "#ff1500",
    "NO_DATA": "#aaaaaa",  # #ababab
    "NON_REVENUE": "#aaaaaa",  #rgb(67, 67, 67)
    "LOCOMOTIVE": "#0080ff",  # #0080ff
}
BRANCH_COLORS = {
    "Babylon": "#00985F",  #00985F
    "Belmont": "#60269E",  #60269E
    "City Terminal Zone": "#4D5357",  #4D5357
    "Far Rockaway": "#6E3219",  #6E3219
    "Hempstead": "#CE8E00",  #CE8E00
    "Long Beach": "#FF6319",  #FF6319
    "Montauk": "#00B2A9",  #00B2A9
    "Oyster Bay": "#00AF3F",  #00AF3F
    "Port Jefferson": "#006EC7",  #006EC7
    "Port Washington": "#C60C30",  #C60C30
    "Ronkonkoma": "#A626AA",  #A626AA
    "West Hempstead": "#00A1DE",  #00A1DE
    "Hudson": "#009B3A",  #009B3A
    "New Haven": "#EE0034",  #EE0034
    "New Canaan": "#EE0034",  #EE0034
    "Danbury": "#EE0034",  #EE0034
    "Waterbury": "#EE0034",  #EE0034
    "Harlem": "#0039A6",  #0039A6
    "Unknown": "#FFFFFF",  #FFFFFF
}
STATUS_COLORS = {
    "EN_ROUTE": "#808080",  #808080
    "ARRIVING": "#0064fa",  #0064fa
    "BERTHED": "#e3d218",  #e3d218
    "DEPARTED": "#C60C30",  #C60C30
}

# ICONS
TERMINAL_ICONS = {
    "HPA": base64.decode("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"),
    "NYK": base64.decode("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"),
    "NYP": base64.decode("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"),
    "GCT": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeUlEQVQ4jc2TwRGAMAgEhbEii7Aiy7Aii7AlfOEYXJCn9w3sEXIRM5tIx74MB+t2CtVJBMTGqAi6AeAYwQiawSFzRpB2xiZ5j3bcqxpN6tr6GSBumISvkKWsUpoDd/gKkmuIcjcPz4lff6EC0VXxFagw2xMCaIJsqgtNz0URrOj+YAAAAABJRU5ErkJggg=="),
    "0NY": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeUlEQVQ4jc2TwRGAMAgEhbEii7Aiy7Aii7AlfOEYXJCn9w3sEXIRM5tIx74MB+t2CtVJBMTGqAi6AeAYwQiawSFzRpB2xiZ5j3bcqxpN6tr6GSBumISvkKWsUpoDd/gKkmuIcjcPz4lff6EC0VXxFagw2xMCaIJsqgtNz0URrOj+YAAAAABJRU5ErkJggg=="),  # GCT
    "LIC": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAW0lEQVQ4jWP8//8/AyWABUqjm8KIRS1WNUww3s+pxgw/pxrjtQ2bGiYcaokGowYMCwNYcIgjpzpsqRK3AcgpjT37LEEXUOwFRmhuxJclYV7AmplY0BThtQybIAA/XhUngpgyGgAAAABJRU5ErkJggg=="),
    "ATL": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAkklEQVQ4jWP8//8/A5ngPwMDAyMTJZoZGBj+k2sAzBAGlvlLlxPlh8ToSEY0IUYGBob/LMRaB7NIS0WJwdzcHGYYI8uJQweINYPBws4BbhjMRSzGUYkMDAwMDGeXzWeAsXHxsQGSA/HanXuUGUCxCwafAYxpaWlkZYaZM2eSHo0wPuuT+3Bxyr1AQXZmYGBgYAAAL001ZFLLOJEAAAAASUVORK5CYII="),
    "JAM": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAU0lEQVQ4jWP8//8/AyWAiSLdDAwMLGh8Yp3DiM2A/8gSBABcLbFewOkyisNg1AD8BhCVJtATEjJgRDIEZ/rAZwBejdgMQLaREMCalImyER1QHAsAceQKK8p1C5UAAAAASUVORK5CYII="),
    "???": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAXUlEQVQ4jcWTwQ4AEAxDTfz/L89JIrS1hUQTF9a3ZjB3Lzdq4mwlGyqqQTPbg4BRaNOiEJZgFYyfAVChIaJu9KoiCWbzBj8BpDmagJozACr1EmXnZwkiQ5S/7f8MOgebDSaJuKC5AAAAAElFTkSuQmCC"),
}
BRANCH_ICONS = {
    "Port Jefferson": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAWklEQVQ4jWP8//8/AyWAiSLdRBrwH42N4mRiXYDuTzifFC9gNYQuYTB4DGDExifWAKyaGRgYGFhI1IxuEMSA48ZWJKdny7PHEF6AcUjVDDeAFEPQ1TEOeG4EABFsGFA01buVAAAAAElFTkSuQmCC"),
    "Montauk": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAgUlEQVQ4jWP8//8/Ay7gbGT8n4GBgWHvubOMuNSw4NTNwMCwe50mPmkGBgYGBiaCKgiB////Y+DO1tb/Pz8/QMGdra3/sallxBUGv748RJFg45HHGg4Ue4FiA3B6odHVHUWifvfOQeoFrAagOx+XGAMDjjBAj0IYwBaVgzQM6GoAALnHU+2DWDaGAAAAAElFTkSuQmCC"),
    "Ronkonkoma": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAc0lEQVQ4jWP8//8/AyWAiSLdw8MARmNjY5yheOzAWgYGBgYGK4dg0l0A04zOJugCZMVsPPKMDAwMDL++PISrQXcN48/PDzC8ANOIDpANghvQ4OKGIrjtyQ2Gk9cfYjXAXFP+v5eMBorYwEfjwBvAOOC5EQD5nCh/cREDWAAAAABJRU5ErkJggg=="),
    "Far Rockaway": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAc0lEQVQ4jd2TQQ6AMAgEF+Kj7ON6kcf1VRYvQiqpJoaTcqTMdkuBVBWZ4BT9M4EiXYv01x1lg1tlFwo1+iRO5zf6YZEOAGiVKYjM8v4EGmGDIhwcKgBdYsEY0XarbJc4wzPY+nEDX5zSuu2pWU7PAX1/mQ5DGkN2g4CZYQAAAABJRU5ErkJggg=="),
    "Long Beach": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAnUlEQVQ4jWP8//8/AyWAiSLd1DCABZvgg8OzsPpLwTaNkaALHhye9f/NV2YGBgYGBnT6zI65GAajGADTLML9lwEXje46JmTN2JyNDt58ZUZRy4QswcDAgNd2GI3VBSYeyYwwQwgB5MBkRE9IZ3bM/Y/PdvSYwIgFE49kjKiCeQ1bNGK4AAbQYwSXwVhTIrYYwRVLFCdlnF4gFlDsAgCnD2mvPDFZlwAAAABJRU5ErkJggg=="),
    "Babylon": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAW0lEQVQ4jWP8//8/AyWAiSLdw8MARlwSqSUpKKE7u2cOTrVYNSMbgM4nqJkUOUaiTcZnKswQYgxDVptakvKfoSo5hGjN6IZUJYf8h0ej6PsPRLsaWS3jaF5gAACVnDPbdc4FLwAAAABJRU5ErkJggg=="),
    "Hempstead": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAfklEQVQ4jWP8//8/Ay7w5trq/wwMDAwiWqGMuNQwEdKMzibKACSbGUS0QvEagtMFxAIWfJJvrq0maADFLsAwAF+AYZPDMABflGGTw+uF2gOfGWoPfManhAZhQHcD8KaDZgde2ruAETk34ksDyAA5OlEMaHR1J8qA+t074QYAAGVdM4zN7qVFAAAAAElFTkSuQmCC"),
    "West Hempstead": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAYElEQVQ4jdXRMQrAMAiF4WfpSUL2XsTLZy+5ip0Ea0Xckv6jkA+JJCKw3e0SAOhzEAqRBfSxpoide/jMdA9GHZU1fwb0Oah6AcBdwRecVAC88BQI+gAbfmIWMy/eYE/gAe8aJMshhRfQAAAAAElFTkSuQmCC"),
    "Oyster Bay": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAfUlEQVQ4jcWTwQ2AIAxFH8bBjBfPXmQBTdzJCWQDL66GV5S2kmAiN0jfy28BF2OkZjVV9BeC9mZbnVl8DtsO0I2zFwUWVJTAgKfkOKQ16gxKYFWgwAD0x+LTvXULGSytTPA2NFNgRUfoX0xgwc/+NUExDPI7yKJqMID7/Tde6IAks03vXnsAAAAASUVORK5CYII="),
    "Port Washington": base64.decode("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"),
    "New Haven": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAl0lEQVQ4jWP8//8/AyWAiSLd1DCABV3g790ZBP3ErJzBCGMzoofBIz9tvAZI9+eiGEKUF75H3ICznxZORpHDaQCyJs4VGijiyF7AaQCyJmQD1aP+MiKLYxggt+kqigKYRnQDCboAm0Z0w/EaANMIMwibZpwGICvG5XSCLsBlIAb4//8/TvzQV+s/Pvn///9jpkRSAcWZCQCliGCbIEGiWQAAAABJRU5ErkJggg=="),
    "Harlem": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAq0lEQVQ4ja2TMQ5CIQyGvxpXPYPxBCZu3MLDOBtnd6/h7GzS2SN4Bj1AXd4jwKNBxSYkwE+//LQgZkZPzD48Z8P4DaCqqGqXAzfmDb1ZIA9gQLQdQnABknQhTrz7FiBJAeYleTHAJAK+yk5cjF0QyNulqqy3L0xW2V7iVKAo4nOTF+t8W3DlwfKuVX0CGA8yFCuuHR3+/ZBKi5fTEYDd/lDVJ4CaxZYuvd/5DRntSyYAXS4qAAAAAElFTkSuQmCC"),
    "Hudson": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAX0lEQVQ4jWP8//8/AzqwK7+GIXioU4sRQyEDAwMTNkFsAJuhOA3AZRs2Q3C6AJchRBtALMBpAC4/U+QCbN7CagBNohEXwDCAWL+T5AJ8UUp9L2CzDZ+3aJMXSAEUZyYAh9Qlp5cl7HIAAAAASUVORK5CYII="),
    "New Canaan": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAfElEQVQ4jaVTWw7AIAhrvf+duy+TyopzG4kRCC0vBUwkyfXOdp2JgCQdPMX9JAkAwwOnM9kJLEkxUwV1Fd1aqHNIhI8EHUkCA8A4zdRJJHhDeETwu4LtYE+CWnDd727fHuNJP1XgJMPB3VOu95Ks+2U736JLmmdpIQYH/QLxQKXCZoE0WAAAAABJRU5ErkJggg=="),
}
ALERT_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAMAAAAICAYAAAA870V8AAAACXBIWXMAABYlAAAWJQFJUiTwAAAAK0lEQVQImYXJMQoAIAzAwLT/f6U+QyHdxKHQbEdQOQtVkq9QHxLg7rA/MwqE2hG8taxbkwAAAABJRU5ErkJggg==")

# MAIN CODE
def main(config):
    # get user settings
    station_code = config.str("station", DEFAULT_STATION)
    filter_direction = config.str("filter_direction", DEFAULT_DIRECTION)
    filter_branch = config.str("filter_branch", DEFAULT_BRANCH)
    filter_stop = config.str("filter_stop", DEFAULT_FILTER_STOP)

    # Make request
    RADAR_ARRIVALS_API_URL = "https://backend-unified.mylirr.org/arrivals/%s" % station_code
    rep = http.get(RADAR_ARRIVALS_API_URL, headers = API_HEADERS)
    if rep.status_code != 200:  # error checking
        return API_ERROR(rep.status_code)  # handle error
    json = rep.json()  # parse json

    # Pick apart data
    is_alert = True if len(json["alerts"]) > 0 or len(json["banners"]) > 0 else False
    trains = json["arrivals"]  # extract trains
    trains = [train for train in trains if train["direction"] in filter_direction]
    if filter_branch != "ALL":
        trains = [train for train in trains if train["branch"] == filter_branch]
    if filter_stop != "ALL":
        trains = [train for train in trains if filter_stop in train["stops"]]

    if len(trains) == 0:  # if there are no trains
        return NO_TRAINS(station_code)  # return the no trains error screen

    # train info extraction
    train = trains[0]  # select next to arrive train
    train_number = train["train_num"]
    train_id = train["train_id"]
    train_dest = train["stops"][-1]  # extract terminal
    is_peak = train["peak_code"] == "P"  # determine if this is a peak train

    # branch determination and settings
    branch_name = BRANCH_CODES[train["branch"]] if train["branch"] in BRANCH_CODES else "Unknown"
    branch_color = BRANCH_COLORS[branch_name] if branch_name in BRANCH_COLORS else "#ffffff"

    # find icons
    branch_icon = BRANCH_ICONS[branch_name] if branch_name in BRANCH_ICONS else TERMINAL_ICONS["???"]
    train_icon = TERMINAL_ICONS[train_dest] if train_dest in TERMINAL_ICONS else branch_icon

    # stop info
    track_change = False if not "track_change" in train else train["track_change"]  # Figure out if there has been a track change, with extra logic because sometimes there is no "track_change" key
    stop_track = train["track"] if "track" in train else "?"  # If there isn't a track assigned, show ?. This is often the case at Grand Central Madison and Penn Station
    stop_track_type = "Track" if len(stop_track) > 1 or stop_track.isdigit() else "Plat"  # Determine if it's a "Platform" or "Track"
    stop_status = train["stop_status"]  # Stop status
    status_color = STATUS_COLORS[stop_status]  # Assign correct status color

    # next stops
    next_stops = [STATION_NAMES[stop] if stop in STATION_NAMES else stop for stop in train["stops"]]

    # get more info from the location endpoint
    RADAR_LOCATION_API_URL = "https://backend-unified.mylirr.org/locations/%s?geometry=NONE&events=true" % train_id
    rep = http.get(RADAR_LOCATION_API_URL, headers = API_HEADERS)

    if rep.status_code != 200:  # error checking
        return API_ERROR(rep.status_code)  # handle error by returning error screen
    json = rep.json()  # parse json
    train_info = json

    # on-time-performance
    if not "otp" in train["status"]:  # if there isn't an otp value
        train_otp = 0  # assume it's on time. it probably hasn't left the terminal yet, and isn't scheduled to have.
    else:
        train_otp = train_info["status"]["otp"]  # otherwise, take MTA's word for it.

    if train_otp < -600:
        train_otp_color = OCCUPANCY_COLORS["SRO"]
    elif train_otp < -300:
        train_otp_color = OCCUPANCY_COLORS["FEW_SEATS"]
    elif train_otp <= -60:
        train_otp_color = OCCUPANCY_COLORS["MANY_SEATS"]
    else:
        train_otp_color = "#ffffff"

    # time stuff
    stop_time = time.from_timestamp(int(train["time"]))  # parse the time that
    eta = int(math.round(time.parse_duration(str(int(train["time"]) - time.now().unix) + "s").minutes))  # this could *maybe* break if the train is later than 59 minutes, but I haven't had a chance to test this yet, which is probably a good thing!
    eta_str = "%dm" % eta if eta > 0 else "Due"

    # consist rendering
    consist = train_info["consist"]["cars"]
    cars = [render_car(car, i) for i, car in enumerate(consist)]

    return render.Root(
        delay = 850,  # make sure we can make it through the stops before our window on the device ends
        child = render.Column(
            children = [
                render.Box(
                    # branch color
                    width = 64,
                    height = 1,
                    color = branch_color,
                ),
                render.Box(
                    # alerts, if any
                    width = 64,
                    height = 1,
                    color = "#ffe91f" if is_alert else "#000000",
                ),
                render.Row(
                    children = [
                        render.Padding(child = render.Image(train_icon), pad = (0, 0, 1, 0)),  # branch/terminal icon
                        render.Column(children = [
                            # train number, eta, peak info
                            render.Row(expanded = True, main_align = "space_between", children = [
                                render.Box(
                                    child = render.Marquee(
                                        child = render.Text(train_number),
                                        align = "center",
                                        width = 20,
                                    ),
                                    width = 20,
                                    height = 8,
                                    color = branch_color,
                                ),  # make the train number look nice, use a marquee to scroll it in case it's longer than usual (ie special gameday trains)
                                render.Animation(children = [
                                    render.Text(stop_time.in_location("America/New_York").format("3:04"), color = train_otp_color),  # janky way of slowing this animation down
                                    render.Text(stop_time.in_location("America/New_York").format("3:04"), color = train_otp_color),
                                    render.Text(stop_time.in_location("America/New_York").format("3:04"), color = train_otp_color),
                                    render.Text("%s %s" % ("▴" if is_peak else "▾", eta_str if eta != 0 else "Arr")),  # peak icon and eta, or "Arr"iving if it's zero.
                                    render.Text("%s %s" % ("▴" if is_peak else "▾", eta_str if eta != 0 else "Arr")),
                                    render.Text("%s %s" % ("▴" if is_peak else "▾", eta_str if eta != 0 else "Arr")),
                                ]),
                            ]),
                            render.Row(children = [
                                render.Text("%s " % stop_track_type),  # "Track" or "Platform"
                                render.Text(stop_track, color = "#ffffff" if not track_change else STATUS_COLORS["ARRIVING"]),  # change the color if there's a track change to draw attention to it.
                                render.Image(ALERT_ICON) if track_change else None,  # show the alert icon if there's been a track change
                            ]),
                        ]),
                    ],
                ),
                render.Animation(children = [
                    # stops
                    render.Text(stop, font = "tb-8")
                    for stop in next_stops[:-1]  # all but the last stop get 1 frame.
                ] + [render.Text(next_stops[-1], font = "tb-8")] * 3),  # hold the last stop on screen longer
                render.Padding(
                    # consist
                    child = render.Row(children = cars, expanded = True, main_align = "center"),
                    pad = (1, 2, 0, 0),
                ),
                render.Row(expanded = True, main_align = "center", children = [
                    # train loading and platform indicator
                    render.Padding(pad = (0, 1, 0, 0), child = render.Box(width = 62, height = 1, color = status_color) if stop_status != "ARRIVING" else render.Animation(children = [
                        # flash the "platform" if the train is arriving
                        render.Box(width = 62, height = 1, color = STATUS_COLORS["ARRIVING"]),
                        render.Box(width = 62, height = 1, color = STATUS_COLORS["BERTHED"]),
                    ])),
                ]),
            ],
        ),
    )

def render_car(car, i):
    if car["locomotive"]:
        locomotive_parts = [
            render.Column(children = [
                render.Box(height = 1, width = 1, color = "#000000"),
                render.Box(height = 1, width = 1, color = OCCUPANCY_COLORS["LOCOMOTIVE"]),
            ]),
            render.Box(height = 2, width = 3, color = OCCUPANCY_COLORS["LOCOMOTIVE"]),
        ]
        if not i == 0:  # if this isn't the first locomotive, reverse it.
            locomotive_parts = reversed(locomotive_parts)
        return render.Row(children = locomotive_parts + [render.Box(height = 2, width = 1, color = "#000000")])

    elif not car["revenue"]:
        car_color = OCCUPANCY_COLORS["NON_REVENUE"]
    else:
        car_color = OCCUPANCY_COLORS[car["loading"]] if car["loading"] in OCCUPANCY_COLORS else OCCUPANCY_COLORS["NO_DATA"]

    car["restroom"] = False if "restroom" not in car else car["restroom"]

    if car["restroom"]:
        return render.Row(children = [
            render.Column(children = [
                render.Box(height = 1, width = 1, color = car_color),
                render.Box(height = 1, width = 1, color = "#2540ed"),
            ]),
            render.Box(height = 2, width = 3, color = car_color),
            render.Box(height = 1, width = 1, color = "#000000"),
        ])
    else:
        return render.Row(children = [
            render.Box(height = 2, width = 4, color = car_color),
            render.Box(height = 1, width = 1, color = "#000000"),
        ])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Station to show arrivals for",
                icon = "houseFlag",
                default = "JAM",
                options = [schema.Option(display = "%s %s" % (key, value), value = key) for key, value in STATION_NAMES.items() if key != "ALL"],
            ),
            schema.Dropdown(
                id = "filter_direction",
                name = "Direction",
                desc = "Filter trains by direction (optional)",
                icon = "compass",
                default = "NESW",
                options = [
                    schema.Option(display = "Both", value = "NESW"),
                    schema.Option(display = "North/East", value = "NE"),
                    schema.Option(display = "South/West", value = "SW"),
                ],
            ),
            schema.Dropdown(
                id = "filter_branch",
                name = "Branch",
                desc = "Filter trains by branch or line (optional)",
                icon = "filter",
                default = "ALL",
                options = [
                    schema.Option(value = key, display = value)
                    for key, value in BRANCH_CODES.items()
                    if key != "??"
                ],
            ),
            schema.Dropdown(
                id = "filter_stop",
                name = "To station",
                desc = "Filter by stops (optional)",
                icon = "briefcase",
                default = "ALL",
                options = [schema.Option(display = "%s %s" % (key, value), value = key) for key, value in STATION_NAMES.items()],
            ),
        ],
    )
