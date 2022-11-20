"""
Applet: NJ Transit Depature Vision
Summary: Shows the next departing trains of a station
Description: Shows the departing NJ Transit Trains of a selected station
Author: jason-j-hunt
"""
load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/csv.star", "csv")
load("encoding/base64.star", "base64")

#URL TO NJ TRANSIT DEPARTURE VISION WEBSITE
NJ_TRANSIT_DV_URL = "https://www.njtransit.com/dv-to"
STATIONS_ENCODED = "U1RBVElPTiBOQU1FLFNUQVRJT04gMkNIQVIKQWJlcmRlZW4tTWF0YXdhbixBTQpBYnNlY29uLEFCCkFsbGVuZGFsZSxBWgpBbGxlbmh1cnN0LEFICkFuZGVyc29uIFN0cmVldCxBUwpBbm5hbmRhbGUsQU4KQXNidXJ5IFBhcmssQVAKQXRjbyxBTwpBdGxhbnRpYyBDaXR5IFJhaWwgVGVybWluYWwsQUMKQXZlbmVsLEFWCkJhc2tpbmcgUmlkZ2UsQkkKQmF5IEhlYWQsQkgKQmF5IFN0cmVldCxNQwpCZWxtYXIsQlMKQmVya2VsZXkgSGVpZ2h0cyxCWQpCZXJuYXJkc3ZpbGxlLEJWCkJsb29tZmllbGQsQk0KQm9vbnRvbixCTgpCb3VuZCBCcm9vayxCSwpCcmFkbGV5IEJlYWNoLEJCCkJyaWNrIENodXJjaCxCVQpCcmlkZ2V3YXRlcixCVwpCcm9hZHdheS1GYWlybGF3bixCRgpDYW1wYmVsbCBIYWxsLENCCkNoYXRoYW0sQ00KQ2hlcnJ5IEhpbGwsQ1kKQ2xpZnRvbixJRgpDb252ZW50IFN0YXRpb24sQ04KQ3JhbmZvcmQsWEMKRGVsYXdhbm5hLERMCkRlbnZpbGxlLERWCkRvdmVyLERPCkR1bmVsbGVuLEROCkVhc3QgT3JhbmdlLEVPCkVkaXNvbixFRApFZ2cgSGFyYm9yIENpdHksRUgKRWxiZXJvbixFTApFbGl6YWJldGgsRVoKRW1lcnNvbixFTgpFc3NleCBTdHJlZXQsRVgKRmFud29vZCxGVwpGYXIgSGlsbHMsRkgKRmluZGVybmUsRkUKR2FyZmllbGQsR0QKR2Fyd29vZCxHVwpHaWxsZXR0ZSxHSQpHbGFkc3RvbmUsR0wKR2xlbiBSaWRnZSxHRwpHbGVuIFJvY2ssUlMKR2xlbiBSb2NrIEJvcm8gSGFsbCxHSwpHcmVhdCBOb3RjaCxHQQpIYWNrZXR0c3Rvd24sSFEKSGFtaWx0b24sSEwKSGFtbW9udG9uLEhOCkhhcnJpbWFuLEhSCkhhd3Rob3JuZSxIVwpIYXpsZXQsSFoKSGlnaCBCcmlkZ2UsSEcKSGlnaGxhbmQgQXZlbnVlLEhJCkhpbGxzZGFsZSxIRApIb2Jva2VuLEhCCkhvaG9rdXMsVUYKSmVyc2V5IEF2ZW51ZSxKQQpLaW5nc2xhbmQsS0cKTGFrZSBIb3BhdGNvbmcsSFAKTGViYW5vbixPTgpMaW5jb2xuIFBhcmssTFAKTGluZGVuLExJCkxpbmRlbndvbGQsTFcKTGl0dGxlIEZhbGxzLEZBCkxpdHRsZSBTaWx2ZXIsTFMKTG9uZyBCcmFuY2gsTEIKTHluZGh1cnN0LExOCkx5b25zLExZCk1hZGlzb24sTUEKTWFod2FoLE1aCk1hbmFzcXVhbixTUQpNYXBsZXdvb2QsTVcKTWV0cm8gUGFyayxNUApNZXR1Y2hlbixNVQpNaWRkbGV0b24gTkosTUkKTWlkZGxldG93biBOWSxNRApNaWxsYnVybixNQgpNaWxsaW5ndG9uLEdPCk1vbnRjbGFpciBTdGF0ZSBVLFVWCk1vbm1vdXRoIFBhcmssTUsKTW9udGNsYWlyIEhlaWdodHMsSFMKTW9udHZhbGUsWk0KTW9ycmlzIFBsYWlucyxNWApNb3JyaXN0b3duLE1SCk1vdW50IE9saXZlLE9MCk1vdW50IFRhYm9yLFRCCk1vdW50YWluIEF2ZW51ZSxNUwpNb3VudGFpbiBMYWtlcyxNTApNb3VudGFpbiBTdGF0aW9uLE1UCk1vdW50YWluIFZpZXcsTVYKTXVycmF5IEhpbGwsTUgKTmFudWV0LE5OCk5ldGNvbmcsTlQKTmV0aGVyd29vZCxORQpOZXcgQnJ1bnN3aWNrLE5CCk5ldyBQcm92aWRlbmNlLE5WCk5ld2FyayBBaXJwb3J0LE5BCk5ld2FyayBCcm9hZCBTdHJlZXQsTkQKTmV3YXJrIFBlbm4gU3RhdGlvbixOUApOb3J0aCBCcmFuY2gsT1IKTm9ydGggRWxpemFiZXRoLE5aCk5ldyBCcmlkZ2UgTGFuZGluZyxOSApPcmFkZWxsLE9ECk9yYW5nZSxPRwpPdHRpc3ZpbGxlLE9TClBhcmsgUmlkZ2UsUFYKUGFzc2FpYyxQUwpQYXRlcnNvbixSTgpQZWFwYWNrLFBDClBlYXJsIFJpdmVyLFBRCk5ldyB5b3JrIFBlbm4gU3RhdGlvbixOWQpQZXJ0aCBBbWJveSxQRQpQaGlsYWRlbHBoaWEsUEgKUGxhaW5maWVsZCxQRgpQbGF1ZGVydmlsbGUsUEwKUG9pbnQgUGxlYXNhbnQgQmVhY2gsUFAKUG9ydCBKZXJ2aXMsUE8KUHJpbmNldG9uLFBSClByaW5jZXRvbiBKdW5jdGlvbixQSgpSYWRidXJuLUZhaXJsYXduLEZaClJhaHdheSxSSApSYW1zZXksUlkKUmFtc2V5IFJ0IDE3LDE3ClJhcml0YW4sUkEKUmVkIEJhbmssUkIKUmlkZ2V3b29kLFJXClJpdmVyIEVkZ2UsUkcKUm9zZWxsZSBQYXJrLFJMClJ1dGhlcmZvcmQsUkYKU2FsaXNidXJ5IE1pbGxzLUNvcm53YWxsLENXClNlY2F1Y3VzIFVwcGVyIEx2bCxTRQpTZWNhdWN1cyBMb3dlciBMdmwsVFMKU2hvcnQgSGlsbHMsUlQKU2xvYXRzYnVyZyxYRwpTb21lcnZpbGxlLFNNClNvdXRoIEFtYm95LENIClNvdXRoIE9yYW5nZSxTTwpTcHJpbmcgTGFrZSxMQQpTcHJpbmcgVmFsbGV5LFNWClN0aXJsaW5nLFNHClN1ZmZlcm4sU0YKU3VtbWl0LFNUClRldGVyYm9ybyxURQpUb3dhY28sVE8KVHJlbnRvbixUUgpUdXhlZG8sVEMKVW5pb24sVVMKVXBwZXIgTW9udGNsYWlyLFVNCldhbGR3aWNrLFdLCldhbG51dCBTdHJlZXQsV0EKV2F0Y2h1bmcgQXZlbnVlLFdHCldhdHNlc3NpbmcgQXZlbnVlLFdUCldheW5lLVJvdXRlIDIzLDIzCldlc3RmaWVsZCxXRgpXZXN0d29vZCxXVwpXaGl0ZSBIb3VzZSxXSApXb29kIFJpZGdlLFdSCldvb2RicmlkZ2UsV0IKV29vZGNsaWZmIExha2UsV0w="
STATION_NAME_COL = 0
STATION_2CHAR_COL = 1

def main(config):

    return render.Root(
        child = render.Text("Hello, World!")
    )



def get_schema():
    
    options = getStationList()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Departing Station",
                desc = "The NJ Transit Station to get departure schedule for.",
                icon = "train",
                default = options[0].value,
                options = options,
            ),
        ],
    )

def getNJTransitHTML(station):

    station_suffix = station.replace(' ', "%20")
    station_url = "{}/{}".format(NJ_TRANSIT_DV_URL, station_suffix)

    nj_dv_page_response = http.get(station_url)

    if nj_dv_page_response.status_code != 200:
        print("Got code '%s' from page response" % nj_dv_page_response.status_code)
        return None

    html_response = html(wotd_page_response.body())

    return html_response


def getStationList():
    
    stations_csv_str = base64.decode(STATIONS_ENCODED)
    stations_list = csv.read_all(stations_csv_str, skip = 1) #Skips header row


    stations = []

    #Loop through CSV and get station name and create option
    for row in stations_list:
        stations.append(create_option(row[STATION_NAME_COL], row[STATION_NAME_COL]))

    return stations


def create_option(display_name, value):
    return schema.Option(
            display = display_name,
            value = value,
        )

