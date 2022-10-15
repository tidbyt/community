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

load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("http.star", "http")
load("cache.star", "cache")

def main(config):

    # Require secrets
    if config["clientId"] == "" or config["clientSecret"] == "" or config["serialNumber"] == "":
        return render.Root(
            child = render.WrappedText(
                content = "AirThings credentials missing."
            )
        )

    access_token = cache.get("access_token")
    if access_token == None:
        print("[+] Refreshing Token...")
        access_token = client_credentials_grant_flow(config)
    else:
        print("[+] Using Cached Token...")
    
    # https://developer.airthings.com/consumer-api-docs/#operation/Device%20samples%20latest-values
    samples = get_samples(config, access_token)

    co2 = samples["data"]["co2"]
    pm25 = samples["data"]["pm25"]
    temp = samples["data"]["temp"]
    voc = samples["data"]["voc"]

    # https://help.airthings.com/en/articles/5367327-view-understanding-the-sensor-thresholds
    co2_color = "#0f0"
    pm25_color = "#0f0"
    temp_color = "#0f0"
    voc_color = "#0f0"

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
    elif temp > 20:
        temp_color = "#ff0"
    
    if voc > 2000:
        voc_color = "#f00"
    elif voc > 250:
        voc_color = "#ff0"

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded=True,
                    main_align = "space_between",
                    children = [
                        render.Text(
                            content = "CO2",
                            color = co2_color
                        ),
                        render.Text(
                            content = str(co2),
                            color = co2_color
                        ),
                    ],
                ),
                render.Row(
                    expanded=True,
                    main_align = "space_between",
                    children = [
                        render.Text(
                            content = "Pm2.5",
                            color = pm25_color
                        ),
                        render.Text(
                            content = str(pm25),
                            color = pm25_color
                        ),
                    ],
                ),
                render.Row(
                    expanded=True,
                    main_align = "space_between",
                    children = [
                        render.Text(
                            content = "Temp",
                            color = temp_color
                        ),
                        render.Text(
                            content = str(temp),
                            color = temp_color
                        ),
                    ],
                ),
                render.Row(
                    expanded=True,
                    main_align = "space_between",
                    children = [
                        render.Text(
                            content = "VOC",
                            color = voc_color
                        ),
                        render.Text(
                            content = str(voc),
                            color = voc_color
                        ),
                    ],
                ),
            ],
        ),
    )

def get_samples(config, access_token):
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
    return status


def client_credentials_grant_flow(config):
    clientSecret = config.str("clientSecret")
    clientId = config.str("clientId")

    form_body = dict(
        client_id =  clientId,
        client_secret = clientSecret,
        grant_type = "client_credentials",
        scope = "read:device:current_values"
    )

    res = http.post(
        url = "https://accounts-api.airthings.com/v1/token",
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "*/*",
        },
        form_body = form_body
    )

    if res.status_code == 200:
        print("Success")
    else:
        print("Error Fetching access_token: %s" % (res.body()))
        fail("token request failed with status code: %d - %s" % (res.status_code, res.body()))
        return None

    token_params = res.json()
    access_token = token_params["access_token"]
    token_type = token_params["token_type"]
    expires_in = token_params["expires_in"]

    cache.set("access_token", access_token, ttl_seconds = int(expires_in) - 30)
    return access_token


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "clientSecret",
                name = "AirThings API Client Secret",
                desc = "API secret from https://dashboard.airthings.com/integrations/api-integration",
                icon = "gear",
            ),
            schema.Text(
                id = "clientId",
                name = "AirThings API Client Id",
                desc = "Client Id from https://dashboard.airthings.com/integrations/api-integration",
                icon = "gear",
            ),
            schema.Text(
                id = "serialNumber",
                name = "Serial Number for AirThings Device",
                desc = "Taken from the target device on https://dashboard.airthings.com/",
                icon = "gear",
            ),
        ],
    )