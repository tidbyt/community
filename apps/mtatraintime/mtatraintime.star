"""
Applet: MTATrainTime
Summary: Displays next trains
Description: Displays the next train between 2 stations for Metro North or Long Island Rail Road.
Author: rai
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STATIONS = {
    "ABT": {"name": "Albertson", "branch": "OysterBay", "railroad": "LIRR"},
    "AGT": {"name": "Amagansett", "branch": "Montauk", "railroad": "LIRR"},
    "AVL": {"name": "Amityville", "branch": "Babylon", "railroad": "LIRR"},
    "5AN": {"name": "Ansonia", "branch": "Waterbury", "railroad": "MNR"},
    "1AT": {"name": "Appalachian Trail", "branch": "Wassaic", "railroad": "MNR"},
    "0AR": {"name": "Ardsley-on-Hudson", "branch": "Hudson", "railroad": "MNR"},
    "ATL": {"name": "Atlantic Terminal", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "ADL": {"name": "Auburndale", "branch": "PortWashington", "railroad": "LIRR"},
    "BTA": {"name": "Babylon", "branch": "Babylon", "railroad": "LIRR"},
    "BWN": {"name": "Baldwin", "branch": "Babylon", "railroad": "LIRR"},
    "BSR": {"name": "Bay Shore", "branch": "Montauk", "railroad": "LIRR"},
    "BSD": {"name": "Bayside", "branch": "PortWashington", "railroad": "LIRR"},
    "0BC": {"name": "Beacon", "branch": "Hudson", "railroad": "MNR"},
    "5BF": {"name": "Beacon Falls", "branch": "Waterbury", "railroad": "MNR"},
    "1BH": {"name": "Bedford Hills", "branch": "Harlem", "railroad": "MNR"},
    "BRS": {"name": "Bellerose", "branch": "Hempstead", "railroad": "LIRR"},
    "BMR": {"name": "Bellmore", "branch": "Babylon", "railroad": "LIRR"},
    "BPT": {"name": "Bellport", "branch": "Montauk", "railroad": "LIRR"},
    "BRT": {"name": "Belmont Park", "branch": "Belmont", "railroad": "LIRR"},
    "4BE": {"name": "Bethel", "branch": "Danbury", "railroad": "MNR"},
    "BPG": {"name": "Bethpage", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "BOL": {"name": "Bolands-Employees", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "1BG": {"name": "Botanical Garden", "branch": "Harlem", "railroad": "MNR"},
    "4BV": {"name": "Branchville", "branch": "Danbury", "railroad": "MNR"},
    "0BK": {"name": "Breakneck Ridge", "branch": "Hudson", "railroad": "MNR"},
    "BWD": {"name": "Brentwood", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "1BW": {"name": "Brewster", "branch": "Harlem", "railroad": "MNR"},
    "BHN": {"name": "Bridgehampton", "branch": "Montauk", "railroad": "LIRR"},
    "2BP": {"name": "Bridgeport", "branch": "NewHaven", "railroad": "MNR"},
    "BDY": {"name": "Broadway", "branch": "PortWashington", "railroad": "LIRR"},
    "1BX": {"name": "Bronxville", "branch": "Harlem", "railroad": "MNR"},
    "4CA": {"name": "Cannondale", "branch": "Danbury", "railroad": "MNR"},
    "CPL": {"name": "Carle Place", "branch": "PortJefferson", "railroad": "LIRR"},
    "CHT": {"name": "Cedarhurst", "branch": "FarRockaway", "railroad": "LIRR"},
    "CI": {"name": "Central Islip", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "CAV": {"name": "Centre Av", "branch": "LongBeach", "railroad": "LIRR"},
    "1CQ": {"name": "Chappaqua", "branch": "Harlem", "railroad": "MNR"},
    "0CS": {"name": "Cold Spring", "branch": "Hudson", "railroad": "MNR"},
    "CSH": {"name": "Cold Spring Harbor", "branch": "PortJefferson", "railroad": "LIRR"},
    "CPG": {"name": "Copiague", "branch": "Babylon", "railroad": "LIRR"},
    "0CT": {"name": "Cortlandt", "branch": "Hudson", "railroad": "MNR"},
    "2CC": {"name": "Cos Cob", "branch": "NewHaven", "railroad": "MNR"},
    "CLP": {"name": "Country Life Press", "branch": "Hempstead", "railroad": "LIRR"},
    "1CW": {"name": "Crestwood", "branch": "Harlem", "railroad": "MNR"},
    "1CF": {"name": "Croton Falls", "branch": "Harlem", "railroad": "MNR"},
    "0HM": {"name": "Croton-Harmon", "branch": "Hudson", "railroad": "MNR"},
    "4DN": {"name": "Danbury", "branch": "Danbury", "railroad": "MNR"},
    "2DA": {"name": "Darien", "branch": "NewHaven", "railroad": "MNR"},
    "DPK": {"name": "Deer Park", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "5DB": {"name": "Derby-Shelton", "branch": "Waterbury", "railroad": "MNR"},
    "0DF": {"name": "Dobbs Ferry", "branch": "Hudson", "railroad": "MNR"},
    "DGL": {"name": "Douglaston", "branch": "PortWashington", "railroad": "LIRR"},
    "1DO": {"name": "Dover Plains", "branch": "Wassaic", "railroad": "MNR"},
    "EHN": {"name": "East Hampton", "branch": "Montauk", "railroad": "LIRR"},
    "ENY": {"name": "East New York", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "2EN": {"name": "East Norwalk", "branch": "NewHaven", "railroad": "MNR"},
    "ERY": {"name": "East Rockaway", "branch": "LongBeach", "railroad": "LIRR"},
    "EWN": {"name": "East Williston", "branch": "OysterBay", "railroad": "LIRR"},
    "EMT": {"name": "Elmont-UBS Arena", "branch": "Hempstead", "railroad": "LIRR"},
    "2FF": {"name": "Fairfield", "branch": "NewHaven", "railroad": "MNR"},
    "2FM": {"name": "Fairfield Metro", "branch": "NewHaven", "railroad": "MNR"},
    "FRY": {"name": "Far Rockaway", "branch": "FarRockaway", "railroad": "LIRR"},
    "FMD": {"name": "Farmingdale", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "1FW": {"name": "Fleetwood", "branch": "Harlem", "railroad": "MNR"},
    "FPK": {"name": "Floral Park", "branch": "Hempstead", "railroad": "LIRR"},
    "FLS": {"name": "Flushing Main Street", "branch": "PortWashington", "railroad": "LIRR"},
    "1FO": {"name": "Fordham", "branch": "Harlem", "railroad": "MNR"},
    "FHL": {"name": "Forest Hills", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "FPT": {"name": "Freeport", "branch": "Babylon", "railroad": "LIRR"},
    "GCY": {"name": "Garden City", "branch": "Hempstead", "railroad": "LIRR"},
    "0GA": {"name": "Garrison", "branch": "Hudson", "railroad": "MNR"},
    "GBN": {"name": "Gibson", "branch": "FarRockaway", "railroad": "LIRR"},
    "GCV": {"name": "Glen Cove", "branch": "OysterBay", "railroad": "LIRR"},
    "GHD": {"name": "Glen Head", "branch": "OysterBay", "railroad": "LIRR"},
    "GST": {"name": "Glen Street", "branch": "OysterBay", "railroad": "LIRR"},
    "3GB": {"name": "Glenbrook", "branch": "NewCanaan", "railroad": "MNR"},
    "0GD": {"name": "Glenwood", "branch": "Hudson", "railroad": "MNR"},
    "1GO": {"name": "Goldens Bridge", "branch": "Harlem", "railroad": "MNR"},
    "GCT": {"name": "Grand Central Madison", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "0NY": {"name": "Grand Central", "branch": "CityTerminalZone", "railroad": "MNR"},
    "GNK": {"name": "Great Neck", "branch": "PortWashington", "railroad": "LIRR"},
    "GRV": {"name": "Great River", "branch": "Montauk", "railroad": "LIRR"},
    "2GF": {"name": "Green's Farms", "branch": "NewHaven", "railroad": "MNR"},
    "GWN": {"name": "Greenlawn", "branch": "PortJefferson", "railroad": "LIRR"},
    "GPT": {"name": "Greenport", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "GVL": {"name": "Greenvale", "branch": "OysterBay", "railroad": "LIRR"},
    "2GN": {"name": "Greenwich", "branch": "NewHaven", "railroad": "MNR"},
    "0GY": {"name": "Greystone", "branch": "Hudson", "railroad": "MNR"},
    "HBY": {"name": "Hampton Bays", "branch": "Montauk", "railroad": "LIRR"},
    "1WI": {"name": "Harlem Valley-Wingdale", "branch": "Wassaic", "railroad": "MNR"},
    "0HL": {"name": "Harlem-125 St", "branch": "CityTerminalZone", "railroad": "MNR"},
    "2HS": {"name": "Harrison", "branch": "NewHaven", "railroad": "MNR"},
    "1HA": {"name": "Hartsdale", "branch": "Harlem", "railroad": "MNR"},
    "0HS": {"name": "Hastings-on-Hudson", "branch": "Hudson", "railroad": "MNR"},
    "1HN": {"name": "Hawthorne", "branch": "Harlem", "railroad": "MNR"},
    "HEM": {"name": "Hempstead", "branch": "Hempstead", "railroad": "LIRR"},
    "HGN": {"name": "Hempstead Gardens", "branch": "WestHempstead", "railroad": "LIRR"},
    "HWT": {"name": "Hewlett", "branch": "FarRockaway", "railroad": "LIRR"},
    "HVL": {"name": "Hicksville", "branch": "PortJefferson", "railroad": "LIRR"},
    "0HB": {"name": "Highbridge-Employees", "branch": "Hudson", "railroad": "MNR"},
    "HIL": {"name": "Hillside-Employees", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "HOL": {"name": "Hollis", "branch": "Hempstead", "railroad": "LIRR"},
    "HPA": {"name": "Hunterspoint Av", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "HUN": {"name": "Huntington", "branch": "PortJefferson", "railroad": "LIRR"},
    "IWD": {"name": "Inwood", "branch": "FarRockaway", "railroad": "LIRR"},
    "0IV": {"name": "Irvington", "branch": "Hudson", "railroad": "MNR"},
    "IPK": {"name": "Island Park", "branch": "LongBeach", "railroad": "LIRR"},
    "ISP": {"name": "Islip", "branch": "Montauk", "railroad": "LIRR"},
    "JAM": {"name": "Jamaica", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "1KA": {"name": "Katonah", "branch": "Harlem", "railroad": "MNR"},
    "KGN": {"name": "Kew Gardens", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "KPK": {"name": "Kings Park", "branch": "PortJefferson", "railroad": "LIRR"},
    "LVW": {"name": "Lakeview", "branch": "WestHempstead", "railroad": "LIRR"},
    "2LA": {"name": "Larchmont", "branch": "NewHaven", "railroad": "MNR"},
    "LTN": {"name": "Laurelton", "branch": "FarRockaway", "railroad": "LIRR"},
    "LCE": {"name": "Lawrence", "branch": "FarRockaway", "railroad": "LIRR"},
    "LHT": {"name": "Lindenhurst", "branch": "Babylon", "railroad": "LIRR"},
    "LNK": {"name": "Little Neck", "branch": "PortWashington", "railroad": "LIRR"},
    "LMR": {"name": "Locust Manor", "branch": "FarRockaway", "railroad": "LIRR"},
    "LVL": {"name": "Locust Valley", "branch": "OysterBay", "railroad": "LIRR"},
    "LBH": {"name": "Long Beach", "branch": "LongBeach", "railroad": "LIRR"},
    "LIC": {"name": "Long Island City", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "0LU": {"name": "Ludlow", "branch": "Hudson", "railroad": "MNR"},
    "LYN": {"name": "Lynbrook", "branch": "LongBeach", "railroad": "LIRR"},
    "MVN": {"name": "Malverne", "branch": "WestHempstead", "railroad": "LIRR"},
    "2MA": {"name": "Mamaroneck", "branch": "NewHaven", "railroad": "MNR"},
    "MHT": {"name": "Manhasset", "branch": "PortWashington", "railroad": "LIRR"},
    "0MN": {"name": "Manitou", "branch": "Hudson", "railroad": "MNR"},
    "0MB": {"name": "Marble Hill", "branch": "Hudson", "railroad": "MNR"},
    "MQA": {"name": "Massapequa", "branch": "Babylon", "railroad": "LIRR"},
    "MPK": {"name": "Massapequa Park", "branch": "Babylon", "railroad": "LIRR"},
    "MSY": {"name": "Mastic-Shirley", "branch": "Montauk", "railroad": "LIRR"},
    "MAK": {"name": "Mattituck", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "MFD": {"name": "Medford", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "1ML": {"name": "Melrose", "branch": "Harlem", "railroad": "MNR"},
    "MAV": {"name": "Merillon Av", "branch": "PortJefferson", "railroad": "LIRR"},
    "MRK": {"name": "Merrick", "branch": "Babylon", "railroad": "LIRR"},
    "4M7": {"name": "Merritt 7", "branch": "Danbury", "railroad": "MNR"},
    "SSM": {"name": "Mets-Willets Point", "branch": "PortWashington", "railroad": "LIRR"},
    "2MI": {"name": "Milford", "branch": "NewHaven", "railroad": "MNR"},
    "MIN": {"name": "Mineola", "branch": "PortJefferson", "railroad": "LIRR"},
    "MTK": {"name": "Montauk", "branch": "Montauk", "railroad": "LIRR"},
    "0MH": {"name": "Morris Heights", "branch": "Hudson", "railroad": "MNR"},
    "1MK": {"name": "Mt Kisco", "branch": "Harlem", "railroad": "MNR"},
    "1MP": {"name": "Mt Pleasant", "branch": "Harlem", "railroad": "MNR"},
    "2ME": {"name": "Mt Vernon East", "branch": "NewHaven", "railroad": "MNR"},
    "1MW": {"name": "Mt Vernon West", "branch": "Harlem", "railroad": "MNR"},
    "MHL": {"name": "Murray Hill", "branch": "PortWashington", "railroad": "LIRR"},
    "NBD": {"name": "Nassau Blvd", "branch": "Hempstead", "railroad": "LIRR"},
    "5NG": {"name": "Naugatuck", "branch": "Waterbury", "railroad": "MNR"},
    "3NC": {"name": "New Canaan", "branch": "NewCanaan", "railroad": "MNR"},
    "0NM": {"name": "New Hamburg", "branch": "Hudson", "railroad": "MNR"},
    "2NH": {"name": "New Haven", "branch": "NewHaven", "railroad": "MNR"},
    "2SS": {"name": "New Haven-State St", "branch": "NewHaven", "railroad": "MNR"},
    "NHP": {"name": "New Hyde Park", "branch": "PortJefferson", "railroad": "LIRR"},
    "2NR": {"name": "New Rochelle", "branch": "NewHaven", "railroad": "MNR"},
    "2NO": {"name": "Noroton Heights", "branch": "NewHaven", "railroad": "MNR"},
    "1NW": {"name": "North White Plains", "branch": "Harlem", "railroad": "MNR"},
    "NPT": {"name": "Northport", "branch": "PortJefferson", "railroad": "LIRR"},
    "NAV": {"name": "Nostrand Av", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "ODL": {"name": "Oakdale", "branch": "Montauk", "railroad": "LIRR"},
    "ODE": {"name": "Oceanside", "branch": "LongBeach", "railroad": "LIRR"},
    "2OG": {"name": "Old Greenwich", "branch": "NewHaven", "railroad": "MNR"},
    "0OS": {"name": "Ossining", "branch": "Hudson", "railroad": "MNR"},
    "OBY": {"name": "Oyster Bay", "branch": "OysterBay", "railroad": "LIRR"},
    "PGE": {"name": "Patchogue", "branch": "Montauk", "railroad": "LIRR"},
    "1PA": {"name": "Patterson", "branch": "Wassaic", "railroad": "MNR"},
    "1PW": {"name": "Pawling", "branch": "Wassaic", "railroad": "MNR"},
    "0PE": {"name": "Peekskill", "branch": "Hudson", "railroad": "MNR"},
    "2PH": {"name": "Pelham", "branch": "NewHaven", "railroad": "MNR"},
    "NYK": {"name": "Penn Station", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "0PM": {"name": "Philipse Manor", "branch": "Hudson", "railroad": "MNR"},
    "PLN": {"name": "Pinelawn", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "PDM": {"name": "Plandome", "branch": "PortWashington", "railroad": "LIRR"},
    "1PV": {"name": "Pleasantville", "branch": "Harlem", "railroad": "MNR"},
    "2PC": {"name": "Port Chester", "branch": "NewHaven", "railroad": "MNR"},
    "PJN": {"name": "Port Jefferson", "branch": "PortJefferson", "railroad": "LIRR"},
    "PWS": {"name": "Port Washington", "branch": "PortWashington", "railroad": "LIRR"},
    "0PO": {"name": "Poughkeepsie", "branch": "Hudson", "railroad": "MNR"},
    "1PY": {"name": "Purdy's", "branch": "Harlem", "railroad": "MNR"},
    "QVG": {"name": "Queens Village", "branch": "Hempstead", "railroad": "LIRR"},
    "4RD": {"name": "Redding", "branch": "Danbury", "railroad": "MNR"},
    "0RV": {"name": "Riverdale", "branch": "Hudson", "railroad": "MNR"},
    "RHD": {"name": "Riverhead", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "2RS": {"name": "Riverside", "branch": "NewHaven", "railroad": "MNR"},
    "RVC": {"name": "Rockville Centre", "branch": "Babylon", "railroad": "LIRR"},
    "RON": {"name": "Ronkonkoma", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "ROS": {"name": "Rosedale", "branch": "FarRockaway", "railroad": "LIRR"},
    "RSN": {"name": "Roslyn", "branch": "OysterBay", "railroad": "LIRR"},
    "2RO": {"name": "Rowayton", "branch": "NewHaven", "railroad": "MNR"},
    "2RY": {"name": "Rye", "branch": "NewHaven", "railroad": "MNR"},
    "SVL": {"name": "Sayville", "branch": "Montauk", "railroad": "LIRR"},
    "0SB": {"name": "Scarborough", "branch": "Hudson", "railroad": "MNR"},
    "1SC": {"name": "Scarsdale", "branch": "Harlem", "railroad": "MNR"},
    "SCF": {"name": "Sea Cliff", "branch": "OysterBay", "railroad": "LIRR"},
    "SFD": {"name": "Seaford", "branch": "Babylon", "railroad": "LIRR"},
    "5SY": {"name": "Seymour", "branch": "Waterbury", "railroad": "MNR"},
    "STN": {"name": "Smithtown", "branch": "PortJefferson", "railroad": "LIRR"},
    "2SN": {"name": "South Norwalk", "branch": "NewHaven", "railroad": "MNR"},
    "SHN": {"name": "Southampton", "branch": "Montauk", "railroad": "LIRR"},
    "1BR": {"name": "Southeast", "branch": "Harlem", "railroad": "MNR"},
    "SHD": {"name": "Southold", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "2SP": {"name": "Southport", "branch": "NewHaven", "railroad": "MNR"},
    "SPK": {"name": "Speonk", "branch": "Montauk", "railroad": "LIRR"},
    "3SD": {"name": "Springdale", "branch": "NewCanaan", "railroad": "MNR"},
    "0DV": {"name": "Spuyten Duyvil", "branch": "Hudson", "railroad": "MNR"},
    "SAB": {"name": "St. Albans", "branch": "WestHempstead", "railroad": "LIRR"},
    "SJM": {"name": "St. James", "branch": "PortJefferson", "railroad": "LIRR"},
    "2SM": {"name": "Stamford", "branch": "NewHaven", "railroad": "MNR"},
    "SMR": {"name": "Stewart Manor", "branch": "Hempstead", "railroad": "LIRR"},
    "BK": {"name": "Stony Brook", "branch": "PortJefferson", "railroad": "LIRR"},
    "2SR": {"name": "Stratford", "branch": "NewHaven", "railroad": "MNR"},
    "SYT": {"name": "Syosset", "branch": "PortJefferson", "railroad": "LIRR"},
    "3TH": {"name": "Talmadge Hill", "branch": "NewCanaan", "railroad": "MNR"},
    "0TT": {"name": "Tarrytown", "branch": "Hudson", "railroad": "MNR"},
    "1TM": {"name": "Tenmile River", "branch": "Wassaic", "railroad": "MNR"},
    "1TR": {"name": "Tremont", "branch": "Harlem", "railroad": "MNR"},
    "1TK": {"name": "Tuckahoe", "branch": "Harlem", "railroad": "MNR"},
    "0UH": {"name": "University Heights", "branch": "Hudson", "railroad": "MNR"},
    "1VA": {"name": "Valhalla", "branch": "Harlem", "railroad": "MNR"},
    "VSM": {"name": "Valley Stream", "branch": "FarRockaway", "railroad": "LIRR"},
    "1WF": {"name": "Wakefield", "branch": "Harlem", "railroad": "MNR"},
    "WGH": {"name": "Wantagh", "branch": "Babylon", "railroad": "LIRR"},
    "1WA": {"name": "Wassaic", "branch": "Wassaic", "railroad": "MNR"},
    "5WB": {"name": "Waterbury", "branch": "Waterbury", "railroad": "MNR"},
    "2WH": {"name": "West Haven", "branch": "NewHaven", "railroad": "MNR"},
    "WHD": {"name": "West Hempstead", "branch": "WestHempstead", "railroad": "LIRR"},
    "WBY": {"name": "Westbury", "branch": "PortJefferson", "railroad": "LIRR"},
    "WHN": {"name": "Westhampton", "branch": "Montauk", "railroad": "LIRR"},
    "2WP": {"name": "Westport", "branch": "NewHaven", "railroad": "MNR"},
    "WWD": {"name": "Westwood", "branch": "WestHempstead", "railroad": "LIRR"},
    "1WP": {"name": "White Plains", "branch": "Harlem", "railroad": "MNR"},
    "1WG": {"name": "Williams Bridge", "branch": "Harlem", "railroad": "MNR"},
    "4WI": {"name": "Wilton", "branch": "Danbury", "railroad": "MNR"},
    "1WN": {"name": "Woodlawn", "branch": "Harlem", "railroad": "MNR"},
    "WMR": {"name": "Woodmere", "branch": "FarRockaway", "railroad": "LIRR"},
    "WDD": {"name": "Woodside", "branch": "CityTerminalZone", "railroad": "LIRR"},
    "WYD": {"name": "Wyandanch", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "0YS": {"name": "Yankees-E 153 St", "branch": "Hudson", "railroad": "MNR"},
    "YPK": {"name": "Yaphank", "branch": "Ronkonkoma", "railroad": "LIRR"},
    "0YK": {"name": "Yonkers", "branch": "Hudson", "railroad": "MNR"},
}

LINE_COLORS = {
    "NoBranch": "#ffffff",
    "Harlem": "#0039a6",
    "Babylon": "#00985f",
    "FarRockaway": "#6e3219",
    "Hempstead": "#ce8e00",
    "LongBeach": "#ff6319",
    "Montauk": "#00b2a9",
    "OysterBay": "#00af3f",
    "PortJefferson": "#006ec7",
    "PortWashington": "#c60c30",
    "Ronkonkoma": "#a626aa",
    "WestHempstead": "#00a1de",
    "Belmont": "#60269e",
    "Hudson": "#009b3a",
    "Wassaic": "#0039a6",
    "NewHaven": "#ee0034",
    "NewCanaan": "#ee0034",
    "Danbury": "#ee0034",
    "Waterbury": "#ee0034",
    "PascackValley": "#8e258d",
    "PortJervis": "#ff7900",
    "CityTerminalZone": "#4d5357",
}

API_ENDPOINT = "https://backend-unified.mylirr.org"

DEFAULT_STATION_ID = "1CW"
DEFAULT_END_STATION_ID = "0NY"
DEFAULT_LOCATION = """ 
{ 
    "lat": "40.6781784", 
    "lng": "-73.9441579", 
    "description": "Brooklyn, NY, USA", 
    "locality": "Brooklyn", 
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI", 
    "timezone": "America/New_York" 
} 
"""

CACHE_TIMEOUT = 60  # will display inaccurate on-time performance if not 60 seconds.

def main(config):
    config_location = config.get("location", DEFAULT_LOCATION)
    location = json.decode(config_location)
    timezone = location["timezone"]
    station_id = config.str("station_id", DEFAULT_STATION_ID)
    end_station_id = config.str("end_station_id", DEFAULT_END_STATION_ID)
    cached_station = cache.get("%s" % station_id + "_arrivals")

    if cached_station != None:
        print("Displaying cached data.")
        arrivals = json.decode(cached_station)
    else:
        print("Calling LIRR API.")
        rep = http.get(
            "%s" % API_ENDPOINT + "/arrivals/" + station_id,
            headers = {
                "authority": "backend-unified.mylirr.org",
                "accept": "application/json, text/plain, */*",
                "accept-language": "en-US,en;q=0.9",
                "accept-version": "3.0",
            },
        )
        arrivals = rep.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("%s" % station_id + "_arrivals", rep.body(), ttl_seconds = CACHE_TIMEOUT)

    count = 0
    display = []

    #print(arrivals)

    for arrival in arrivals["arrivals"]:
        #print(arrival["stops"])
        if count < 4:
            if (STATIONS[station_id]["railroad"] == "LIRR"):
                # Long Island Rail Road uses a different format for their arrivals.
                if (end_station_id in arrival["stops"] and station_id not in arrival["stops"]):
                    display.append(arrival)
                    count += 1
            elif (station_id in arrival["stops"] and end_station_id in arrival["stops"]) and arrival["stops"].index(station_id) < arrival["stops"].index(end_station_id):
                display.append(arrival)
                count += 1

    children = [
        render.Box(
            width = 64,
            height = 1,
            color = LINE_COLORS[STATIONS[station_id]["branch"]],
        ),
        render.Marquee(
            width = 64,
            child = render.Text(STATIONS[station_id]["name"] + " to " + STATIONS[end_station_id]["name"], font = "CG-pixel-3x5-mono"),
        ),
        render.Box(
            width = 64,
            height = 1,
            color = LINE_COLORS[STATIONS[station_id]["branch"]],
        ),
    ]
    print("Trains: %d" % count)
    if count > 0:
        for arrival in display:
            late = False
            late_seconds = 0

            if "otp" in arrival["status"] and arrival["status"]["otp"] < -60:
                late = True
                late_seconds = abs(arrival["status"]["otp"])
            children.append(render.Text("%s" %
                                        time.from_timestamp(int(arrival["time"])).in_location(timezone).format("3:04pm") + " " +
                                        ((str(int(time.parse_duration(str(late_seconds) + "s").minutes)) + "m Late") if late else "On Time"), color = ("#dc143c" if late else "#ccc"), font = "tom-thumb"))
    else:
        children.append(render.Text("No trains", color = "#ccc", font = "6x13"))
        children.append(render.Text(" found.", color = "#ccc", font = "6x13"))

    return render.Root(
        child = render.Column(
            children = children,
        ),
    )

def get_schema():
    options = []
    for station in STATIONS:
        options.append(schema.Option(
            display = STATIONS[station]["name"],
            value = station,
        ))
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station_id",
                name = "Origin Station",
                desc = "The station to display departures for.",
                icon = "train",
                default = DEFAULT_STATION_ID,
                options = options,
            ),
            schema.Dropdown(
                id = "end_station_id",
                name = "Destination Station",
                desc = "The station to display departures to.",
                icon = "train",
                default = DEFAULT_END_STATION_ID,
                options = options,
            ),
        ],
    )
