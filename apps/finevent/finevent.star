"""
Applet: Finevent
Summary: Upcoming financial events
Description: Displays the daily economic or earnings calendar.
Author: Rob Kimball
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://api.tradingeconomics.com"
AUTH = "guest:guest"
SAMPLE_DATA = [
    {"Actual": "6.2%", "CalendarId": "292068", "Category": "Inflation Rate", "Country": "United Kingdom", "Currency": "", "Date": "2022-03-23T07:00:00", "DateSpan": "0", "Event": "Inflation Rate YoY", "Forecast": "5.9%", "Importance": 3, "LastUpdate": "2022-03-23T07:00:00", "Previous": "5.5%", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "", "Source": "Office for National Statistics", "SourceURL": "http://www.ons.gov.uk/", "Symbol": "UKRPCJYR", "TEForecast": "6.1%", "Ticker": "UKRPCJYR", "URL": "/united-kingdom/inflation-cpi", "Unit": "%"},
    {"Actual": "0.772M", "CalendarId": "292037", "Category": "New Home Sales", "Country": "United States", "Currency": "", "Date": "2022-03-23T14:00:00", "DateSpan": "0", "Event": "New Home Sales", "Forecast": "0.81M", "Importance": 3, "LastUpdate": "2022-03-23T14:00:00", "Previous": "0.788M", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "0.801M", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov", "Symbol": "UNITEDSTANEWHOMSAL", "TEForecast": "0.81M", "Ticker": "UNITEDSTANEWHOMSAL", "URL": "/united-states/new-home-sales", "Unit": "M"},
    {"Actual": "", "CalendarId": "310998", "Category": "Calendar", "Country": "Belgium", "Currency": "", "Date": "2022-03-24T00:00:00", "DateSpan": "1", "Event": "Extraordinary NATO Summit", "Forecast": "", "Importance": 3, "LastUpdate": "2022-03-18T11:24:00", "Previous": "", "Reference": "", "ReferenceDate": None, "Revised": "", "Source": "", "SourceURL": "", "Symbol": "", "TEForecast": "", "Ticker": "BEL CALENDAR", "URL": "/belgium/calendar", "Unit": ""},
    {"Actual": "", "CalendarId": "292083", "Category": "Manufacturing PMI", "Country": "Germany", "Currency": "", "Date": "2022-03-24T08:30:00", "DateSpan": "0", "Event": "Markit Manufacturing PMI Flash", "Forecast": "55.8", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "58.4", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Revised": "", "Source": "Markit Economics", "SourceURL": "https://www.markiteconomics.com", "Symbol": "GERMANYMANPMI", "TEForecast": "56.2", "Ticker": "GERMANYMANPMI", "URL": "/germany/manufacturing-pmi", "Unit": ""},
    {"Actual": "", "CalendarId": "292088", "Category": "Manufacturing PMI", "Country": "United Kingdom", "Currency": "", "Date": "2022-03-24T09:30:00", "DateSpan": "0", "Event": "Markit/CIPS Manufacturing PMI Flash", "Forecast": "56.7", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "58", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Revised": "", "Source": "Markit Economics", "SourceURL": "https://www.markiteconomics.com", "Symbol": "UNITEDKINMANPMI", "TEForecast": "57.1", "Ticker": "UNITEDKINMANPMI", "URL": "/united-kingdom/manufacturing-pmi", "Unit": ""},
    {"Actual": "", "CalendarId": "292089", "Category": "Services PMI", "Country": "United Kingdom", "Currency": "", "Date": "2022-03-24T09:30:00", "DateSpan": "0", "Event": "Markit/CIPS UK Services PMI Flash", "Forecast": "58", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "60.5", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Revised": "", "Source": "Markit Economics", "SourceURL": "https://www.markiteconomics.com", "Symbol": "UNITEDKINSERPMI", "TEForecast": "58.8", "Ticker": "UNITEDKINSERPMI", "URL": "/united-kingdom/services-pmi", "Unit": ""},
    {"Actual": "", "CalendarId": "292098", "Category": "Durable Goods Orders", "Country": "United States", "Currency": "", "Date": "2022-03-24T12:30:00", "DateSpan": "0", "Event": "Durable Goods Orders MoM", "Forecast": "-0.5%", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "1.6%", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov/", "Symbol": "UNITEDSTADURGOOORD", "TEForecast": "-0.5%", "Ticker": "UNITEDSTADURGOOORD", "URL": "/united-states/durable-goods-orders", "Unit": "%"},
    {"Actual": "", "CalendarId": "291879", "Category": "Consumer Confidence", "Country": "United Kingdom", "Currency": "", "Date": "2022-03-25T00:01:00", "DateSpan": "0", "Event": "Gfk Consumer Confidence", "Forecast": "-30", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "-26", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Revised": "", "Source": "GfK Group", "SourceURL": "https://www.gfk.com", "Symbol": "UKCCI", "TEForecast": "-35", "Ticker": "UKCCI", "URL": "/united-kingdom/consumer-confidence", "Unit": ""},
    {"Actual": "", "CalendarId": "292119", "Category": "Retail Sales MoM", "Country": "United Kingdom", "Currency": "", "Date": "2022-03-25T07:00:00", "DateSpan": "0", "Event": "Retail Sales MoM", "Forecast": "0.6%", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "1.9%", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "", "Source": "Office for National Statistics", "SourceURL": "http://www.ons.gov.uk/", "Symbol": "GBRRetailSalesMoM", "TEForecast": "0.7%", "Ticker": "GBRRETAILSALESMOM", "URL": "/united-kingdom/retail-sales", "Unit": "%"},
    {"Actual": "", "CalendarId": "292169", "Category": "Business Confidence", "Country": "Germany", "Currency": "", "Date": "2022-03-25T09:00:00", "DateSpan": "0", "Event": "Ifo Business Climate", "Forecast": "94.2", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "98.9", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Revised": "", "Source": "Ifo Institute", "SourceURL": "https://www.ifo.de", "Symbol": "GRIFPBUS", "TEForecast": "92.2", "Ticker": "GRIFPBUS", "URL": "/germany/business-confidence", "Unit": ""},
    {"Actual": "0.772M", "CalendarId": "292037", "Category": "New Home Sales", "Country": "United States", "Currency": "", "Date": "2022-03-23T14:00:00", "DateSpan": "0", "Event": "New Home Sales", "Forecast": "0.81M", "Importance": 3, "LastUpdate": "2022-03-23T14:00:00", "Previous": "0.788M", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "0.801M", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov", "Symbol": "UNITEDSTANEWHOMSAL", "TEForecast": "0.81M", "Ticker": "UNITEDSTANEWHOMSAL", "URL": "/united-states/new-home-sales", "Unit": "M"},
    {"Actual": "", "CalendarId": "292098", "Category": "Durable Goods Orders", "Country": "United States", "Currency": "", "Date": "2022-03-24T12:30:00", "DateSpan": "0", "Event": "Durable Goods Orders MoM", "Forecast": "-0.5%", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Previous": "1.6%", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov/", "Symbol": "UNITEDSTADURGOOORD", "TEForecast": "-0.5%", "Ticker": "UNITEDSTADURGOOORD", "URL": "/united-states/durable-goods-orders", "Unit": "%"},
    {"Actual": "", "CalendarId": "292693", "Category": "Job Offers", "Country": "United States", "Currency": "", "Date": "2022-03-29T14:00:00", "DateSpan": "0", "Event": "JOLTs Job Openings", "Forecast": "", "Importance": 3, "LastUpdate": "2022-03-17T16:37:00", "Previous": "11.263M", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Revised": "", "Source": "U.S. Bureau of Labor Statistics", "SourceURL": "http://www.bls.gov", "Symbol": "UNITEDSTAJOBOFF", "TEForecast": "", "Ticker": "UNITEDSTAJOBOFF", "URL": "/united-states/job-offers", "Unit": "M"},
]
DATEFMT = "2006-01-02T15:04:05"
MAX_RELEASE_SECONDS = 60 * 90  # we only show releases occurring the last/next N minutes
DEFAULT_HIDDEN = False
REGIONS = {
    "Global": [],
    "US-only": ["United States"],
    # "North America": ["United States", "Canada"],
    # "EAFE": [
    #     "Austria",
    #     "Belgium",
    #     "Denmark",
    #     "Finland",
    #     "France",
    #     "Germany",
    #     "Ireland",
    #     "Israel",
    #     "Italy",
    #     "Netherlands",
    #     "Norway",
    #     "Portugal",
    #     "Spain",
    #     "Sweden",
    #     "Switzerland",
    #     "United Kingdom",
    #     "Australia",
    #     "New Zealand",
    #     "Hong Kong",
    #     "Singapore",
    #     "Japan",
    # ],
    # "EM": [
    #     "Brazil",
    #     "Chile",
    #     "China",
    #     "Colombia",
    #     "Czech Republic",
    #     "Egypt",
    #     "Greece",
    #     "Hungary",
    #     "India",
    #     "Indonesia",
    #     "Korea",
    #     "Kuwait",
    #     "Malaysia",
    #     "Mexico",
    #     "Peru",
    #     "Philippines",
    #     "Poland",
    #     "Qatar",
    #     "Russia",
    #     "Saudi Arabia",
    #     "South Africa",
    #     "Taiwan",
    #     "Thailand",
    #     "Turkey",
    #     "United Arab Emirates",
    # ],
    # "G7": ["United States", "Canada", "France", "Germany", "Italy", "Japan", "United Kingdom"],
}

ISO3166 = {
    "Afghanistan": "af",
    "Albania": "al",
    "Algeria": "dz",
    "American Samoa": "as",
    "Andorra": "ad",
    "Angola": "ao",
    "Anguilla": "ai",
    "Antarctica": "aq",
    "Antigua and Barbuda": "ag",
    "Argentina": "ar",
    "Armenia": "am",
    "Aruba": "aw",
    "Australia": "au",
    "Austria": "at",
    "Azerbaijan": "az",
    "Bahamas": "bs",
    "Bahrain": "bh",
    "Bangladesh": "bd",
    "Barbados": "bb",
    "Belarus": "by",
    "Belgium": "be",
    "Belize": "bz",
    "Benin": "bj",
    "Bermuda": "bm",
    "Bhutan": "bt",
    "Bolivia": "bo",
    "Bolivia, Plurinational State of": "bo",
    "Bosnia and Herzegovina": "ba",
    "Botswana": "bw",
    "Bouvet Island": "bv",
    "Brazil": "br",
    "British Indian Ocean Territory": "io",
    "British Virgin Islands": "vg",
    "Brunei": "bn",
    "Brunei Darussalam": "bn",
    "Bulgaria": "bg",
    "Burkina Faso": "bf",
    "Burundi": "bi",
    "Cambodia": "kh",
    "Cameroon": "cm",
    "Canada": "ca",
    "Cape Verde": "cv",
    "Cayman Islands": "ky",
    "Central African Republic": "cf",
    "Chad": "td",
    "Chile": "cl",
    "China": "cn",
    "Christmas Island": "cx",
    "Cocos (Keeling) Islands": "cc",
    "Colombia": "co",
    "Comoros": "km",
    "Congo": "cg",
    "Congo, the Democratic Republic of the": "cd",
    "Cook Islands": "ck",
    "Costa Rica": "cr",
    "Croatia": "hr",
    "Cuba": "cu",
    "Cyprus": "cy",
    "Czech Republic": "cz",
    "Côte d'Ivoire": "ci",
    "Democratic Republic of the Congo": "cd",
    "Denmark": "dk",
    "Djibouti": "dj",
    "Dominica": "dm",
    "Dominican Republic": "do",
    "Ecuador": "ec",
    "Egypt": "eg",
    "El Salvador": "sv",
    "Equatorial Guinea": "gq",
    "Eritrea": "er",
    "Estonia": "ee",
    "Ethiopia": "et",
    "Euro Area": "eu",
    "European Union": "eu",
    "Falkland Islands (Malvinas)": "fk",
    "Faroe Islands": "fo",
    "Federated States of Micronesia": "fm",
    "Fiji": "fj",
    "Finland": "fi",
    "France": "fr",
    "French Guiana": "gf",
    "French Polynesia": "pf",
    "French Southern Territories": "tf",
    "Gabon": "ga",
    "Gambia": "gm",
    "Georgia": "ge",
    "Germany": "de",
    "Ghana": "gh",
    "Gibraltar": "gi",
    "Greece": "gr",
    "Greenland": "gl",
    "Grenada": "gd",
    "Guadeloupe": "gp",
    "Guam": "gu",
    "Guatemala": "gt",
    "Guernsey": "gg",
    "Guinea": "gn",
    "Guinea-Bissau": "gw",
    "Guyana": "gy",
    "Haiti": "ht",
    "Heard Island and McDonald Islands": "hm",
    "Holy See (Vatican City State)": "va",
    "Honduras": "hn",
    "Hong Kong": "hk",
    "Hungary": "hu",
    "Iceland": "is",
    "India": "in",
    "Indonesia": "id",
    "Iran": "ir",
    "Iran, Islamic Republic of": "ir",
    "Iraq": "iq",
    "Ireland": "ie",
    "Isle of Man": "im",
    "Israel": "il",
    "Italy": "it",
    "Ivory Coast": "ci",
    "Jamaica": "jm",
    "Japan": "jp",
    "Jersey": "je",
    "Jordan": "jo",
    "Kazakhstan": "kz",
    "Kenya": "ke",
    "Kiribati": "ki",
    "Korea, Democratic People's Republic of": "kp",
    "Korea, Republic of": "kr",
    "Kuwait": "kw",
    "Kyrgyzstan": "kg",
    "Lao People's Democratic Republic": "la",
    "Latvia": "lv",
    "Lebanon": "lb",
    "Lesotho": "ls",
    "Liberia": "lr",
    "Libyan Arab Jamahiriya": "ly",
    "Liechtenstein": "li",
    "Lithuania": "lt",
    "Luxembourg": "lu",
    "Macao": "mo",
    "Macedonia": "mk",
    "Macedonia, the former Yugoslav Republic of": "mk",
    "Madagascar": "mg",
    "Malawi": "mw",
    "Malaysia": "my",
    "Maldives": "mv",
    "Mali": "ml",
    "Malta": "mt",
    "Marshall Islands": "mh",
    "Martinique": "mq",
    "Mauritania": "mr",
    "Mauritius": "mu",
    "Mayotte": "yt",
    "Mexico": "mx",
    "Micronesia": "fm",
    "Micronesia, Federated States of": "fm",
    "Moldova": "md",
    "Moldova, Republic of": "md",
    "Monaco": "mc",
    "Mongolia": "mn",
    "Montenegro": "me",
    "Montserrat": "ms",
    "Morocco": "ma",
    "Mozambique": "mz",
    "Myanmar": "mm",
    "Namibia": "na",
    "Nauru": "nr",
    "Nepal": "np",
    "Netherlands": "nl",
    "Netherlands Antilles": "an",
    "New Caledonia": "nc",
    "New Zealand": "nz",
    "Nicaragua": "ni",
    "Niger": "ne",
    "Nigeria": "ng",
    "Niue": "nu",
    "Norfolk Island": "nf",
    "Northern Mariana Islands": "mp",
    "Norway": "no",
    "Oman": "om",
    "Pakistan": "pk",
    "Palau": "pw",
    "Palestine": "ps",
    "Palestinian Territory, Occupied": "ps",
    "Panama": "pa",
    "Papua New Guinea": "pg",
    "Paraguay": "py",
    "Peru": "pe",
    "Philippines": "ph",
    "Pitcairn": "pn",
    "Poland": "pl",
    "Portugal": "pt",
    "Puerto Rico": "pr",
    "Qatar": "qa",
    "Republic of Korea": "kr",
    "Republic of Moldova": "md",
    "Romania": "ro",
    "Russian Federation": "ru",
    "Rwanda": "rw",
    "Réunion": "re",
    "Saint Barthélemy": "bl",
    "Saint Helena": "sh",
    "Saint Helena, Ascension and Tristan da Cunha": "sh",
    "Saint Kitts and Nevis": "kn",
    "Saint Lucia": "lc",
    "Saint Martin": "mf",
    "Saint Martin (French part)": "mf",
    "Saint Pierre and Miquelon": "pm",
    "Saint Vincent and the Grenadines": "vc",
    "Samoa": "ws",
    "San Marino": "sm",
    "Sao Tome and Principe": "st",
    "Saudi Arabia": "sa",
    "Senegal": "sn",
    "Serbia": "rs",
    "Seychelles": "sc",
    "Sierra Leone": "sl",
    "Singapore": "sg",
    "Slovakia": "sk",
    "Slovenia": "si",
    "Solomon Islands": "sb",
    "Somalia": "so",
    "South Africa": "za",
    "South Georgia": "gs",
    "South Georgia and the South Sandwich Islands": "gs",
    "South Korea": "kr",
    "Spain": "es",
    "Sri Lanka": "lk",
    "Sudan": "sd",
    "Suriname": "sr",
    "Svalbard and Jan Mayen": "sj",
    "Swaziland": "sz",
    "Sweden": "se",
    "Switzerland": "ch",
    "Syrian Arab Republic": "sy",
    "Taiwan": "tw",
    "Taiwan, Province of China": "tw",
    "Tajikistan": "tj",
    "Tanzania": "tz",
    "Tanzania, United Republic of": "tz",
    "Thailand": "th",
    "Timor-Leste": "tl",
    "Togo": "tg",
    "Tokelau": "tk",
    "Tonga": "to",
    "Trinidad and Tobago": "tt",
    "Tunisia": "tn",
    "Turkey": "tr",
    "Turkmenistan": "tm",
    "Turks and Caicos Islands": "tc",
    "Tuvalu": "tv",
    "U.S. Virgin Islands": "vi",
    "Uganda": "ug",
    "Ukraine": "ua",
    "United Arab Emirates": "ae",
    "United Kingdom": "gb",
    "United States": "us",
    "United States Minor Outlying Islands": "um",
    "Uruguay": "uy",
    "Uzbekistan": "uz",
    "Vanuatu": "vu",
    "Venezuela": "ve",
    "Venezuela, Bolivarian Republic of": "ve",
    "Viet Nam": "vn",
    "Vietnam": "vn",
    "Virgin Islands, British": "vg",
    "Virgin Islands, U.S.": "vi",
    "Wallis and Futuna": "wf",
    "Western Sahara": "eh",
    "Yemen": "ye",
    "Zambia": "zm",
    "Zimbabwe": "zw",
    "Åland Islands": "ax",
}

IMPORTANCE_ICONS = {
    1: base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAEpJREFUKFNjZCASMOJTV1pa+h8k393dzYhXoZOT0395eXmG+fPnU6AQ2Tq8JiJLYij8n88AdjTjRAZG/ArDlf5/0/jKwN34ko4KAUofUQvpr/OmAAAAAElFTkSuQmCC"),
    2: base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAFpJREFUKFNjZCASMOJTV1pa+h8k393dzYhXoZOT0395eXmG+fPnU6Dw/3I1sHWMkbcY8Zr4c4Xqf7YPtxkYMxgwFf7PZ4CYMpGBEb/CcKX/3zS+MnA3vqSjQgB3tVYLtGTHpgAAAABJRU5ErkJggg=="),
    3: base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAFpJREFUKFNjZCASMOJT9/9j2X+QPCN/FyN+hT+P/Gf4c5OBkTuZAoX/l6tBrIu8xfgfn4k/V6j+Z/twm4ExgwFT4f98BogpExkY8SsMV/r/TeMrA3fjSzoqBABNA2YLBoHQ+QAAAABJRU5ErkJggg=="),
}

def flag_api(country_name):
    cache_prefix = "%s/%s/%s/" % ("finevent", "econ", "flags")
    flag = cache.get(cache_prefix + country_name)
    if not flag:
        print("Getting %s flag from the flag CDN, ISO3166 code: %s" % (country_name, ISO3166.get(country_name)))
        flag_resp = http.get("https://flagcdn.com/w20/%s.png" % ISO3166.get(country_name))
        if flag_resp.status_code != 200:
            flag = ISO3166.get(country_name)
        else:
            flag = flag_resp.body()
            cache.set(cache_prefix + country_name, flag, ttl_seconds = 60 * 60 * 24 * 30)  # keep for a month
    return flag

def random(max):
    """Borrowed from nipterink's nft.star"""
    return (time.now().nanosecond // 1000) % max

def main(config):
    timezone = config.get("$tz", "America/New_York")
    countries = REGIONS.get(config.get("region"), [])
    future_events = config.bool("future")
    self_hide = config.bool("self-hide", DEFAULT_HIDDEN)
    importance = int(config.get("importance", "2"))
    title_font = "CG-pixel-3x5-mono"
    NULL = "--"

    now = time.now()

    # Events are cached globally for 30 minutes, individualization is not necessary
    cache_id = "%s/%s/%s/%s" % ("finevent", "econ", config.get("region", "all"), importance)
    data = cache.get(cache_id)
    filtered_events = []
    if not data:
        url_countries = "all"
        if len(countries):
            url_countries = ",".join([country.lower().replace(" ", "%20") for country in countries])

        for imp in range(importance, 4):
            request_url = "%s/calendar/country/%s?c=%s&f=json&importance=%s" % (BASE_URL, url_countries, AUTH, imp)
            print("Getting latest events from API %s" % request_url)

            response = http.get(request_url)
            if response.status_code != 200:
                print("API Error.")
            else:
                data = response.json()
                if countries:
                    for evt in data:
                        if evt["Country"] in countries:
                            filtered_events.append(evt)
                        else:
                            print(evt["Country"], " is not in ", countries)
                else:
                    filtered_events.extend(data)

        if len(filtered_events):
            times = []
            for event in filtered_events:
                times.append(time.parse_time(event.get("Date", ""), format = DATEFMT).in_location(timezone))
            next_release = abs(max([int((now - t).seconds) for t in times if t > now]))
            print("Caching %s results as %s until next release in %s seconds" % (len(filtered_events), cache_id, next_release))
            cache.set(cache_id, json.encode(filtered_events), ttl_seconds = next_release)
    else:
        print("Displaying cached data from %s" % cache_id)
        filtered_events = json.decode(data)

    for event in filtered_events:
        event["ReleaseTime"] = time.parse_time(event.get("Date", ""), format = DATEFMT).in_location(timezone)
        event["TimeFromNow"] = int(abs((now - event["ReleaseTime"]).seconds))

    if self_hide:
        filtered_events = [e for e in filtered_events if e["TimeFromNow"] < MAX_RELEASE_SECONDS]

    sorted_events = sorted(filtered_events, key = lambda x: x["TimeFromNow"], reverse = False)

    if not future_events:
        _events = []
        for e in sorted_events:
            if e.get("ReleaseTime") <= now:
                _events.append(e)
        sorted_events = _events

    if not len(sorted_events):
        print("No upcoming or recently-reported data.")
        return []
    else:
        for event in sorted_events:
            print(
                event.get("Importance", NULL) or NULL,
                event.get("ReleaseTime", NULL),
                event.get("Country", NULL) or NULL,
                event.get("Event", NULL) or NULL,
                event.get("Previous", NULL) or NULL,
                "|",
                event.get("Forecast", NULL) or NULL,
                event.get("TEForecast", NULL) or NULL,
                "|",
                event.get("Actual", NULL) or NULL,
                ">>",
                event.get("Revised", NULL) or NULL,
            )

    choice = random(len(sorted_events))
    right_title = "Prior"
    right_color = "#fb8b1e"

    # If there are multiple events at this importance level, display a random one each time the app rotates
    event = sorted_events[choice]
    importance = event.get("Importance", 1)
    name = event.get("Event")

    # Localize UTC time
    release_time_format = "3:04 PM" if event.get("TimeFromNow") < (60 * 60 * 24 - 1) else "1/2 PM"
    display_time = event.get("ReleaseTime", NULL).format(release_time_format)

    survey = str(event.get("Forecast", NULL) or event.get("TEForecast", NULL))
    if survey == "":
        survey = NULL

    right = str(event.get("Previous", "--"))
    if right == "":
        right = NULL
    if event.get("ReleaseTime", now) <= now and event.get("Actual", "") != "":
        right_title = "Actual"
        right_color = "#fff"
        right = str(event.get("Actual", "--"))
        if right == "":
            right = NULL

    country = event.get("Country", None)

    flag = flag_api(country)
    print(importance, display_time, country, name, survey, right)

    defaults = {
        "cross_align": "start",
        "expanded": True,
        "main_align": "space_between",
    }

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_around",
                    children = [
                        render.Image(IMPORTANCE_ICONS[importance], width = 10, height = 10),
                        render.Image(flag, width = 15, height = 10),
                        render.Row(expanded = True, main_align = "center", children = [render.Text(display_time)]),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(name),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = [
                        render.Column(
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Text("Survey", color = "#fb8b1e", font = title_font),
                                render.Text(survey, color = "#fb8b1e"),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Text(right_title, color = right_color, font = title_font),
                                render.Text(right, color = right_color),
                            ],
                        ),
                    ],
                ),
            ],
            **defaults
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Event Region",
                desc = "Filter economic events by countries within the region of interest.",
                icon = "earthEurope",
                options = [schema.Option(value = k, display = k) for k in REGIONS.keys()],
                default = "US-only",
            ),
            schema.Dropdown(
                id = "importance",
                name = "Minimum importance",
                desc = "Only show events rated over a certain level of importance.",
                icon = "bell",
                options = [schema.Option(value = v, display = d) for d, v in [
                    ("Low", "1"),
                    ("Medium", "2"),
                    ("High", "3"),
                ]],
                default = "3",
            ),
            schema.Toggle(
                id = "future",
                name = "Include unreleased?",
                desc = "If turned off, we will hide any upcoming releases and only show events after data is available.",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "self-hide",
                name = "Nearby events only?",
                desc = "If turned on, the app will show a blank screen unless there is an event within 90 minutes.",
                icon = "gear",
                default = DEFAULT_HIDDEN,
            ),
        ],
    )
