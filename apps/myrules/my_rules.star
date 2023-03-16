"""
Applet: My Rules
Summary: Set rules for yourself
Description: Display one of several rules you set for yourself.
Author: hloeding
"""

# ################################
# ###### App module loading ######
# ################################

# Required modules
load("render.star", "render")
load("random.star", "random")
load("http.star", "http")
load("encoding/csv.star", "csv")
load("humanize.star", "humanize")
load("cache.star", "cache")
load("schema.star", "schema")

# ###########################
# ###### App constants ######
# ###########################

DEFAULT_RULES = """
"Thou shall provide a valid URL"
"Thou shall provide rules as valid CSV"
"""

DEFAULT_RULES_URL = \
    "https://raw.githubusercontent.com/hloeding/" + \
    "tidbyt_community_apps/myrules/apps/myrules/rules.csv"

RULES_CACHE_KEY = "my_rules_%s"
RULES_CACHE_TTL = 5 * 60

# ###############################################
# ###### Functions to construct app schema ######
# ###############################################

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "url",
                name = "URL",
                desc = "URL of your rules file (in CSV format)",
                icon = "database",
                default = DEFAULT_RULES_URL,
            ),
        ],
    )

# #########################################
# ###### Functions to retrieve rules ######
# #########################################

def getRules(url):
    rulesData = getCachedRulesData(url)
    if rulesData == None:
        rulesData = getRawRulesData(url)
        setCachedRulesData(url, rulesData)
    # TODO: There seems to be no try/except in starlark.
    # For now, the applet will just have to fail in case
    # csv.read_all fails in its turn.
    ret = []
    for rule in csv.read_all(rulesData):
        ret.append(rule[0])
    return ret

# ###############################
# ###### Caching functions ######
# ###############################

def getCacheKey(url):
    return RULES_CACHE_KEY % humanize.url_encode(url)

def getCachedRulesData(url):
    return cache.get(getCacheKey(url))

def setCachedRulesData(url, data):
    return cache.set(
        getCacheKey(url),
        data,
        RULES_CACHE_TTL
    )

# ##################################################
# ###### Functions to retrieve raw rules data ######
# ##################################################

def getRawRulesData(url):
    # TODO: There seems to be no try/except in starlark. Nor does 
    # there seem a way to check for the existence of URLs.
    # I can see no way around letting the applet fail, if http.get()
    # fails in its turn.
    response = http.get(url)
    if response != None and response.status_code == 200:
        return response.body()
    return DEFAULT_RULES

# #######################################
# ###### Functions to render rules ######
# #######################################

def renderRule(url):
    rules = getRules(url)
    ruleIdx = random.number(0, len(rules) - 1)
    rule = rules[ruleIdx]
    return render.Column(
        children = [
            render.Marquee(
                child = render.Text(
                    content = "Rule %d:" % (ruleIdx + 1),
                    font = "Dina_r400-6",
                    color = "#00bbff",
                ),
                width = 62,
            ),
            render.Marquee(
                child = render.Text(
                    content = rule,
                    # font = "6x13",
                    font = "10x20"
                ),
                width = 62,
            ),
        ],
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center"
    )

# #############################
# ###### App entry point ######
# #############################

# Main entrypoint
def main(config):
    url = config.str(
        "url",
        DEFAULT_RULES_URL,
    )
    return render.Root(
        render.Box(
            child = renderRule(url),
            padding = 1,
        ),
        show_full_animation = True,
    )
