"""
Applet: Victron
Summary: Show energy stats
Description: This app uses the Victron VRM API to get SOC, Solar Watts and DC Watts.
Author: jduncc
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

VRM_URL_USER = "https://vrmapi.victronenergy.com/v2/users/me"
VRM_URL_INSTALLATIONS = "https://vrmapi.victronenergy.com/v2/users/%s/installations"
VRM_URL_DIAG = "https://vrmapi.victronenergy.com/v2/installations/%s/diagnostics"

def main(config):
    token = config.get("token")
    if not "token" in config:
        # dummy data if no token provided
        installation_name = "Installation"
        parsed_diag = {
            "SOCRaw": 100,
            "SOC": "100 %",
            "PVPRaw": 100,
            "PVP": "100%",
            "DCRaw": 100,
            "DC": "100%",
        }

    else:
        installationIndex = int(config.get("installation_index", 0))
        user = vrm_api(VRM_URL_USER, token, 600)

        if (user["success"] != True):
            fail("failed to check for user %s" % user)

        user_id = str(user["user"]["id"])

        if (int(user_id) < 0):
            fail("failed to get user id %s" % user_id)

        installations = vrm_api(VRM_URL_INSTALLATIONS % user_id, token, 600)

        if (installations["success"] != True):
            fail("failed to check for installations %s" % installations)

        installation = installations["records"][installationIndex]
        installation_id = installation["idSite"]
        installation_name = installation["name"]

        diag = vrm_api(VRM_URL_DIAG % str(int(installation_id)), token, 0)
        if (diag["success"] != True):
            fail("failed to check for diagnostics %s" % diag)

        parsed_diag = parse_diag(diag)

    #print(parsed_diag)
    if (float(parsed_diag["SOCRaw"]) > 50):
        soc_color = "00FF00"
    else:
        soc_color = "FF0000"

    if (float(parsed_diag["PVPRaw"]) > 0):
        pvp_color = "00FF00"
    else:
        pvp_color = "FFFFFF"

    return render.Root(
        child = render.Box(
            padding = 1,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        #main_align="center",
                        children = [
                            render.Text("%s" % installation_name),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                children = [
                                    render.Text(font = "6x13", color = soc_color, content = "%s" % parsed_diag["SOC"]),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                children = [
                                    render.Text("%s DC" % math.floor(float(parsed_diag["DCRaw"]))),
                                    render.Text(color = pvp_color, content = "%s PV" % math.floor(float(parsed_diag["PVPRaw"]))),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def parse_diag(diag):
    records = diag["records"]
    soc = ""
    soc_raw = ""
    pvp = ""
    pvp_raw = ""
    dc = ""
    dc_raw = ""

    for element in records:
        if (element["code"] == "SOC"):
            #fail("element %s" % element)
            soc = element["formattedValue"]
            soc_raw = element["rawValue"]
        elif (element["code"] == "PVP"):
            pvp = element["formattedValue"]
            pvp_raw = element["rawValue"]
        elif (element["code"] == "dc"):
            dc = element["formattedValue"]
            dc_raw = element["rawValue"]

    return {
        "SOC": soc,
        "SOCRaw": soc_raw,
        "PVP": pvp,
        "PVPRaw": pvp_raw,
        "DC": dc,
        "DCRaw": dc_raw,
    }

def vrm_api(url, token, ttl_seconds):
    res = http.get(
        url,
        ttl_seconds = ttl_seconds,
        headers = {
            "x-authorization": "Token %s" % token,
            "Content-Type": "applicaiton/json",
        },
    )
    if res.status_code != 200:
        fail("vrm request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    return res.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "VRM API Token",
                desc = "Please provide your API token to access VRM",
                icon = "user",
            ),
            schema.Text(
                id = "installation_index",
                name = "Installation Index",
                desc = "This is which installation you would like to be shown (if you have more than one installation on your account).  Defaults to 0",
                icon = "layerGroup",
                default = "0",
            ),
        ],
    )
