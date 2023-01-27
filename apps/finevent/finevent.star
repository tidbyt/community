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
    {"CalendarId": "292068", "Date": "2022-03-23T07:00:00", "Country": "United Kingdom", "Category": "Inflation Rate", "Event": "Inflation Rate YoY", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "Office for National Statistics", "SourceURL": "http://www.ons.gov.uk/", "Actual": "6.2%", "Previous": "5.5%", "Forecast": "5.9%", "TEForecast": "6.1%", "URL": "/united-kingdom/inflation-cpi", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-23T07:00:00", "Revised": "", "Currency": "", "Unit": "%", "Ticker": "UKRPCJYR", "Symbol": "UKRPCJYR"},
    {"CalendarId": "292037", "Date": "2022-03-23T14:00:00", "Country": "United States", "Category": "New Home Sales", "Event": "New Home Sales", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov", "Actual": "0.772M", "Previous": "0.788M", "Forecast": "0.81M", "TEForecast": "0.81M", "URL": "/united-states/new-home-sales", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-23T14:00:00", "Revised": "0.801M", "Currency": "", "Unit": "M", "Ticker": "UNITEDSTANEWHOMSAL", "Symbol": "UNITEDSTANEWHOMSAL"},
    {"CalendarId": "310998", "Date": "2022-03-24T00:00:00", "Country": "Belgium", "Category": "Calendar", "Event": "Extraordinary NATO Summit", "Reference": "", "ReferenceDate": None, "Source": "", "SourceURL": "", "Actual": "", "Previous": "", "Forecast": "", "TEForecast": "", "URL": "/belgium/calendar", "DateSpan": "1", "Importance": 3, "LastUpdate": "2022-03-18T11:24:00", "Revised": "", "Currency": "", "Unit": "", "Ticker": "BEL CALENDAR", "Symbol": ""},
    {"CalendarId": "292083", "Date": "2022-03-24T08:30:00", "Country": "Germany", "Category": "Manufacturing PMI", "Event": "Markit Manufacturing PMI Flash", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Source": "Markit Economics", "SourceURL": "https://www.markiteconomics.com", "Actual": "", "Previous": "58.4", "Forecast": "55.8", "TEForecast": "56.2", "URL": "/germany/manufacturing-pmi", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "", "Ticker": "GERMANYMANPMI", "Symbol": "GERMANYMANPMI"},
    {"CalendarId": "292088", "Date": "2022-03-24T09:30:00", "Country": "United Kingdom", "Category": "Manufacturing PMI", "Event": "Markit/CIPS Manufacturing PMI Flash", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Source": "Markit Economics", "SourceURL": "https://www.markiteconomics.com", "Actual": "", "Previous": "58", "Forecast": "56.7", "TEForecast": "57.1", "URL": "/united-kingdom/manufacturing-pmi", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "", "Ticker": "UNITEDKINMANPMI", "Symbol": "UNITEDKINMANPMI"},
    {"CalendarId": "292089", "Date": "2022-03-24T09:30:00", "Country": "United Kingdom", "Category": "Services PMI", "Event": "Markit/CIPS UK Services PMI Flash", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Source": "Markit Economics", "SourceURL": "https://www.markiteconomics.com", "Actual": "", "Previous": "60.5", "Forecast": "58", "TEForecast": "58.8", "URL": "/united-kingdom/services-pmi", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "", "Ticker": "UNITEDKINSERPMI", "Symbol": "UNITEDKINSERPMI"},
    {"CalendarId": "292098", "Date": "2022-03-24T12:30:00", "Country": "United States", "Category": "Durable Goods Orders", "Event": "Durable Goods Orders MoM", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov/", "Actual": "", "Previous": "1.6%", "Forecast": "-0.5%", "TEForecast": "-0.5%", "URL": "/united-states/durable-goods-orders", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "%", "Ticker": "UNITEDSTADURGOOORD", "Symbol": "UNITEDSTADURGOOORD"},
    {"CalendarId": "291879", "Date": "2022-03-25T00:01:00", "Country": "United Kingdom", "Category": "Consumer Confidence", "Event": "Gfk Consumer Confidence", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Source": "GfK Group", "SourceURL": "https://www.gfk.com", "Actual": "", "Previous": "-26", "Forecast": "-30", "TEForecast": "-35", "URL": "/united-kingdom/consumer-confidence", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "", "Ticker": "UKCCI", "Symbol": "UKCCI"},
    {"CalendarId": "292119", "Date": "2022-03-25T07:00:00", "Country": "United Kingdom", "Category": "Retail Sales MoM", "Event": "Retail Sales MoM", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "Office for National Statistics", "SourceURL": "http://www.ons.gov.uk/", "Actual": "", "Previous": "1.9%", "Forecast": "0.6%", "TEForecast": "0.7%", "URL": "/united-kingdom/retail-sales", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "%", "Ticker": "GBRRETAILSALESMOM", "Symbol": "GBRRetailSalesMoM"},
    {"CalendarId": "292169", "Date": "2022-03-25T09:00:00", "Country": "Germany", "Category": "Business Confidence", "Event": "Ifo Business Climate", "Reference": "Mar", "ReferenceDate": "2022-03-31T00:00:00", "Source": "Ifo Institute", "SourceURL": "https://www.ifo.de", "Actual": "", "Previous": "98.9", "Forecast": "94.2", "TEForecast": "92.2", "URL": "/germany/business-confidence", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "", "Ticker": "GRIFPBUS", "Symbol": "GRIFPBUS"},
    {"CalendarId": "292037", "Date": "2022-03-23T14:00:00", "Country": "United States", "Category": "New Home Sales", "Event": "New Home Sales", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov", "Actual": "0.772M", "Previous": "0.788M", "Forecast": "0.81M", "TEForecast": "0.81M", "URL": "/united-states/new-home-sales", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-23T14:00:00", "Revised": "0.801M", "Currency": "", "Unit": "M", "Ticker": "UNITEDSTANEWHOMSAL", "Symbol": "UNITEDSTANEWHOMSAL"},
    {"CalendarId": "292098", "Date": "2022-03-24T12:30:00", "Country": "United States", "Category": "Durable Goods Orders", "Event": "Durable Goods Orders MoM", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "U.S. Census Bureau", "SourceURL": "https://www.census.gov/", "Actual": "", "Previous": "1.6%", "Forecast": "-0.5%", "TEForecast": "-0.5%", "URL": "/united-states/durable-goods-orders", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-21T14:15:00", "Revised": "", "Currency": "", "Unit": "%", "Ticker": "UNITEDSTADURGOOORD", "Symbol": "UNITEDSTADURGOOORD"},
    {"CalendarId": "292693", "Date": "2022-03-29T14:00:00", "Country": "United States", "Category": "Job Offers", "Event": "JOLTs Job Openings", "Reference": "Feb", "ReferenceDate": "2022-02-28T00:00:00", "Source": "U.S. Bureau of Labor Statistics", "SourceURL": "http://www.bls.gov", "Actual": "", "Previous": "11.263M", "Forecast": "", "TEForecast": "", "URL": "/united-states/job-offers", "DateSpan": "0", "Importance": 3, "LastUpdate": "2022-03-17T16:37:00", "Revised": "", "Currency": "", "Unit": "M", "Ticker": "UNITEDSTAJOBOFF", "Symbol": "UNITEDSTAJOBOFF"},
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
    "Åland Islands": "ax",
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
    "Brunei Darussalam": "bn",
    "Brunei": "bn",
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
    "Democratic Republic of the Congo": "cd",
    "Cook Islands": "ck",
    "Costa Rica": "cr",
    "Côte d'Ivoire": "ci",
    "Ivory Coast": "ci",
    "Croatia": "hr",
    "Cuba": "cu",
    "Cyprus": "cy",
    "Czech Republic": "cz",
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
    "Jamaica": "jm",
    "Japan": "jp",
    "Jersey": "je",
    "Jordan": "jo",
    "Kazakhstan": "kz",
    "Kenya": "ke",
    "Kiribati": "ki",
    "Korea, Democratic People's Republic of": "kp",
    "Korea, Republic of": "kr",
    "Republic of Korea": "kr",
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
    "Federated States of Micronesia": "fm",
    "Moldova": "md",
    "Moldova, Republic of": "md",
    "Republic of Moldova": "md",
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
    "Réunion": "re",
    "Romania": "ro",
    "Russian Federation": "ru",
    "Rwanda": "rw",
    "Saint Barthélemy": "bl",
    "Saint Helena": "sh",
    "Saint Helena, Ascension and Tristan da Cunha": "sh",
    "Saint Kitts and Nevis": "kn",
    "Saint Lucia": "lc",
    "Saint Martin (French part)": "mf",
    "Saint Martin": "mf",
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
    "South Korea": "kr",
    "South Georgia": "gs",
    "South Georgia and the South Sandwich Islands": "gs",
    "Spain": "es",
    "Sri Lanka": "lk",
    "Sudan": "sd",
    "Suriname": "sr",
    "Svalbard and Jan Mayen": "sj",
    "Swaziland": "sz",
    "Sweden": "se",
    "Switzerland": "ch",
    "Syrian Arab Republic": "sy",
    "Taiwan, Province of China": "tw",
    "Taiwan": "tw",
    "Tajikistan": "tj",
    "Tanzania, United Republic of": "tz",
    "Tanzania": "tz",
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
    "Uganda": "ug",
    "Ukraine": "ua",
    "United Arab Emirates": "ae",
    "United Kingdom": "gb",
    "United States": "us",
    "United States Minor Outlying Islands": "um",
    "Uruguay": "uy",
    "Uzbekistan": "uz",
    "Vanuatu": "vu",
    "Venezuela, Bolivarian Republic of": "ve",
    "Venezuela": "ve",
    "Viet Nam": "vn",
    "Vietnam": "vn",
    "Virgin Islands, British": "vg",
    "British Virgin Islands": "vg",
    "Virgin Islands, U.S.": "vi",
    "U.S. Virgin Islands": "vi",
    "Wallis and Futuna": "wf",
    "Western Sahara": "eh",
    "Yemen": "ye",
    "Zambia": "zm",
    "Zimbabwe": "zw",
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
        "main_align": "space_between",
        "expanded": True,
        "cross_align": "start",
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
