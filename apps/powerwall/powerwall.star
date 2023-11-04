"""
Applet: Powerwall
Summary: Tesla Powerwall Monitor
Description: Show Tesla Powerwall state.
Author: tabrindle (based off jweier & marcusb's work on Tesla Solar)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

TESLA_AUTH_URL = "https://auth.tesla.com/oauth2/v3/token"
URL = "https://owner-api.teslamotors.com/api/1/energy_sites/{}/live_status?language=en"

IMG = ""

CACHE_TTL = 25200

DUMMY_DATA = {
    "response": {
        "solar_power": 0,
        "energy_left": 28288.9652631579,
        "total_pack_energy": 40502,
        "percentage_charged": 69.84584776840128,
        "backup_capable": True,
        "battery_power": 690,
        "load_power": 690,
        "grid_status": "Active",
        "grid_services_active": False,
        "grid_power": 0,
        "grid_services_power": 0,
        "generator_power": 0,
        "island_status": "on_grid",
        "storm_mode_active": False,
        "timestamp": "2023-11-02T23:36:20-04:00",
        "wall_connectors": [],
    },
}

def get_access_token(refresh_token, site_id):
    #Try to load access token from cache
    access_token_cached = cache.get(site_id)

    if access_token_cached != None:
        print("Hit! Using cached access token " + access_token_cached)
        return {"status_code": "Cached", "access_token": str(access_token_cached)}
    else:
        print("Miss! Getting new access token from Tesla API.")

        auth_rep = http.post(TESLA_AUTH_URL, json_body = {
            "grant_type": "refresh_token",
            "client_id": "ownerapi",
            "refresh_token": refresh_token,
            "scope": "openid email offline_access",
        })

        #Check the HTTP response code
        if auth_rep.status_code != 200:
            return {"status_code": str(auth_rep.status_code), "access_token": "None"}
        else:
            access_token = auth_rep.json()["access_token"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(site_id, access_token, ttl_seconds = CACHE_TTL)
            return {"status_code": str(auth_rep.status_code), "access_token": str(access_token)}

def main(config):
    print("-------Starting new update-------")

    site_id = humanize.url_encode(config.str("site_id", ""))
    refresh_token = config.str("refresh_token")
    error_in_http_calls = False
    error_details = {}
    o = ""

    if refresh_token and site_id:
        url = URL.format(site_id)
        print("Refresh Token: " + refresh_token)
        print("Site ID: " + site_id)
        print("Tesla Auth URL: " + TESLA_AUTH_URL)
        print("Tesla Data URL: " + url)

        access_token = get_access_token(refresh_token, site_id)

        if access_token["access_token"] == "None":
            error_details = {"error_section": "refresh_token", "error": "HTTP error " + str(access_token["status_code"])}
            error_in_http_calls = True
        else:
            rep = http.get(url, headers = {"Authorization": "Bearer " + access_token["access_token"]})
            if rep.status_code != 200:
                response_error = rep.json()
                error_details = {"error_section": "site_id", "error": "Error " + response_error["error"]}
                error_in_http_calls = True
            data = rep.body()
            o = json.decode(data)
    else:
        print("Using Dummy Data")
        o = DUMMY_DATA

    if error_in_http_calls == False:
        charge = int(o["response"]["percentage_charged"])

        return render.Root(
            child = render.Box(
                height = 32,
                width = 64,
                color = "#000000",
                child = render.Stack(
                    children = [
                        render.Box(
                            child = render.PieChart(
                                colors = ["004400", "0f0"],
                                weights = [100 - charge, charge],
                                diameter = 30,
                            ),
                        ),
                        render.Box(
                            child = render.Circle(
                                color = "#000",
                                diameter = 22,
                            ),
                        ),
                        render.Box(
                            child = render.Text(
                                content = str(charge)[0:3] + "%",
                                color = "#ffffff",
                            ),
                        ),
                    ],
                ),
            ),
        )
    else:
        error_message = "Check " + error_details["error_section"] + ". " + error_details["error"]
        return render.Root(
            child = render.Marquee(
                width = 64,
                child = render.Text(error_message),
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "refresh_token",
                name = "Refresh Token",
                desc = "Refresh Token for the Tesla Owner API.",
                icon = "key",
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID that should be monitored.",
                icon = "solarPanel",
            ),
        ],
    )
