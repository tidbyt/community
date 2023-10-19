"""
Applet: AirThings
Summary: Environment sensor readings
Description: Environment sensor readings from an AirThings sensor.
Author: joshspicer
"""

# AirThings Environment Sensor Applet
#
# Copyright (c) 2022 Josh Spicer <hello@joshspicer.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    # Require secrets
    clientId = config.get("clientId")
    clientSecret = config.get("clientSecret")
    serialNumber = config.get("serialNumber")

    # Options
    skipRenderIfAllGreen = config.bool("skipRenderIfAllGreen")
    onlyDisplayNotNormal = config.bool("onlyDisplayNotNormal")

    hidePm25 = config.bool("hidePm25")
    hideVoc = config.bool("hideVoc")
    hideTemp = config.bool("hideTemp")
    hideCo2 = config.bool("hideCo2")
    hideHumidity = config.bool("hideHumidity")

    if not clientId or not clientSecret or not serialNumber:
        return render.Root(
            child = render.WrappedText(
                content = "AirThings credentials missing.",
            ),
        )

    # Key unique to the user to fetch cached access_token
    ACCESS_TOKEN_CACHE_KEY = "%s-%s-%s" % (clientId, serialNumber, clientSecret)
    SAMPLES_CACHE_KEY = "samples-%s-%s" % (clientId, serialNumber)

    access_token = cache.get(ACCESS_TOKEN_CACHE_KEY)
    if access_token == None or access_token == "":
        print("[+] Refreshing Token...")
        access_token = client_credentials_grant_flow(config, ACCESS_TOKEN_CACHE_KEY)
    else:
        print("[+] Using Cached Token...")

    # Read samples from cache if available
    samplesString = cache.get(SAMPLES_CACHE_KEY)

    if samplesString == None or samplesString == "":
        print("[+] Fetching Samples...")

        # https://developer.airthings.com/consumer-api-docs/#operation/Device%20samples%20latest-values
        samples = get_samples(config, access_token, SAMPLES_CACHE_KEY)
    else:
        print("[+] Using Cached Samples...")
        samples = json.decode(samplesString)

    print(samples)

    co2 = samples["data"]["co2"]
    if "pm25" in samples["data"]:
        pm25 = samples["data"]["pm25"]
    else:
        pm25 = -1
    temp = samples["data"]["temp"]
    voc = samples["data"]["voc"]
    humidity = samples["data"]["humidity"]

    # https://help.airthings.com/en/articles/5367327-view-understanding-the-sensor-thresholds
    co2_color = "#0f0"
    pm25_color = "#0f0"
    temp_color = "#0f0"
    voc_color = "#0f0"
    humidity_color = "#0f0"

    if co2 > 1000:
        co2_color = "#f00"
    elif co2 > 800:
        co2_color = "#ff0"

    if pm25 > 25:
        pm25_color = "#f00"
    elif pm25 > 10:
        pm25_color = "#ff0"

    if temp > 25:
        temp_color = "#f00"
    elif temp > 22:
        temp_color = "#ff0"

    if voc > 2000:
        voc_color = "#f00"
    elif voc > 250:
        voc_color = "#ff0"

    if humidity > 70 or humidity < 30:
        humidity_color = "#f00"
    elif humidity > 60:
        humidity_color = "#ff0"

    allGreen = True
    nonNormalValues = []
    for (sample, hidden, displayName) in [
        (co2_color, hideCo2, "Co2"),
        (pm25_color, hidePm25, "Pm2.5"),
        (temp_color, hideTemp, "Temp"),
        (voc_color, hideVoc, "VOC"),
        (humidity_color, hideHumidity, "Humidity"),
    ]:
        if not onlyDisplayNotNormal and hidden:
            continue

        if not sample == "#0f0":
            allGreen = False
            if onlyDisplayNotNormal:
                nonNormalValues.append(displayName)
            break

    if skipRenderIfAllGreen and allGreen:
        # Skip rendering
        print("All green, nothing to report!")
        return []

    items = []
    if pm25 == -1:
        pm25 = "n/a"
    for (hide, reading, color, displayName) in [
        (hideCo2, co2, co2_color, "Co2"),
        (hidePm25, pm25, pm25_color, "Pm2.5"),
        (hideTemp, temp, temp_color, "Temp"),
        (hideVoc, voc, voc_color, "VOC"),
        (hideHumidity, humidity, humidity_color, "Humidity"),
    ]:
        if not onlyDisplayNotNormal and hide:
            continue

        if onlyDisplayNotNormal and not displayName in nonNormalValues:
            continue

        items.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Text(
                        content = displayName,
                        color = color,
                    ),
                    render.Text(
                        content = str(reading),
                        color = color,
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            children = items,
        ),
    )

def get_samples(config, access_token, SAMPLES_CACHE_KEY):
    serial_number = config["serialNumber"]
    if serial_number == None:
        fail("serial_number is required")

    url = "https://ext-api.airthings.com/v1/devices/" + serial_number + "/latest-samples"
    headers = {
        "Authorization": "Bearer " + access_token,
    }
    res = http.get(url, headers = headers)

    if res.status_code != 200:
        print("Error fetching samples: %s" % (res.body()))
        fail("fetching samples failed with status code: %d - %s" % (res.status_code, res.body()))

    status = res.json()

    # Cache samples for 5 minutes
    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(SAMPLES_CACHE_KEY, res.body(), 60 * 5)

    return status

def client_credentials_grant_flow(config, access_token_cache_key):
    clientSecret = config.str("clientSecret")
    clientId = config.str("clientId")

    form_body = dict(
        client_id = clientId,
        client_secret = clientSecret,
        grant_type = "client_credentials",
        scope = "read:device:current_values",
    )

    res = http.post(
        url = "https://accounts-api.airthings.com/v1/token",
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "*/*",
        },
        form_body = form_body,
    )

    if res.status_code == 200:
        print("Success")
    else:
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(access_token_cache_key, "")
        print("Error Fetching access_token: %s" % (res.body()))
        fail("token request failed with status code: %d - %s" % (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]
    expires_in = token_params["expires_in"]

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(access_token_cache_key, access_token, ttl_seconds = int(expires_in) - 30)
    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "clientSecret",
                name = "AirThings API Client Secret",
                desc = "REQUIRED: API secret from https://dashboard.airthings.com/integrations/api-integration",
                icon = "gear",
            ),
            schema.Text(
                id = "clientId",
                name = "AirThings API Client Id",
                desc = "REQUIRED: Client Id from https://dashboard.airthings.com/integrations/api-integration",
                icon = "gear",
            ),
            schema.Text(
                id = "serialNumber",
                name = "Serial Number for AirThings Device",
                desc = "REQUIRED: Taken from the target device on https://dashboard.airthings.com/",
                icon = "gear",
            ),
            schema.Toggle(
                id = "skipRenderIfAllGreen",
                name = "Skip Render If All Green",
                desc = "If all readings are normal, skip rendering this applet",
                icon = "arrowLeft",
                default = False,
            ),
            schema.Toggle(
                id = "onlyDisplayNotNormal",
                name = "Only display non-normal readings",
                desc = "Only displays readings that are not normal (green). NOTE: Ignores individual preferences below when enabled.",
                icon = "arrowLeft",
                default = False,
            ),
            schema.Toggle(
                id = "hidePm25",
                name = "Hide Pm2.5",
                desc = "Hide Pm2.5 reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideVoc",
                name = "Hide VOC",
                desc = "Hide VOC reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideHumidity",
                name = "Hide Humidity",
                desc = "Hide Humidity reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideTemp",
                name = "Hide Temperature",
                desc = "Hide Temperature reading",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "hideCo2",
                name = "Hide CO2",
                desc = "Hide CO2 reading",
                icon = "gear",
                default = False,
            ),
        ],
    )
