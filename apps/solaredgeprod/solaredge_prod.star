"""
Applet: SolarEdge_Prod
Summary: SolarEdge daily production
Description: Monitor SolarEdge PV panel daily current and daily production.
Author: Billy_McSkintos
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")

# ICONS --------------------------------- https://easy64.org/icons/material-ui-filled/
#POWER_ICON = base64.decode("""PHN2ZyBmaWxsPSIjZmZmZjAwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJNMTEgMjFoLTFsMS03SDcuNWMtLjU4IDAtLjU3LS4zMi0uMzgtLjY2LjE5LS4zNC4wNS0uMDguMDctLjEyQzguNDggMTAuOTQgMTAuNDIgNy41NCAxMyAzaDFsLTEgN2gzLjVjLjQ5IDAgLjU2LjMzLjQ3LjUxbC0uMDcuMTVDMTIuOTYgMTcuNTUgMTEgMjEgMTEgMjF6Ii8+PC9zdmc+""")
POWER_ICON = base64.decode("""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""")

#TODAY_ICON = base64.decode("""PHN2ZyBmaWxsPSIjZmY4MDAwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJNMTkgM2gtMVYxaC0ydjJIOFYxSDZ2Mkg1Yy0xLjExIDAtMS45OS45LTEuOTkgMkwzIDE5YTIgMiAwIDAgMCAyIDJoMTRjMS4xIDAgMi0uOSAyLTJWNWMwLTEuMS0uOS0yLTItMnptMCAxNkg1VjhoMTR2MTF6TTcgMTBoNXY1SDd6Ii8+PC9zdmc+""")
TODAY_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAATFSURBVHhe7Z0LctMwFEVDQ8u04MLADtgGC2ALXheryKpYATN8wnegBT0sUZPGjj96P+memdryDE1t3aMn2WnDg00p7Pa/Y0uHtnHZlz4F0A77FI5k8COA9dAPaZuzsDV/zrYF8Bb6MYxXA3snV0LohxiWgMqUFV4VGT5h+LosCfAojJTXsV0eRiXwswg8hreKYXAq8C3AIR6EMCZBWQL0sSgDKoASVmSAAAbQksHorWB9AiSkRYAARpESAQKY5iyIcBPb+TEaPmHpQZAmt5ZD4gQCcGNcLAhQORCAEwfTCgSoHAhQORCACyd3FRAgYfHNIwEgQOVAgMqBAESl5Z+AAJUDAbhwUlUgAC/ncW+WKt8B+w/ukYo3gyrH+FQAAWR4GPfmwBQgOUINTgcQQLNEGxACAji5XftHZmmwBvAGCdtJm2VdAQG8stv/DNsX3cFyIIBndvt3YXvZHSwDAnhnt/8attvuYD5YBHpbBI6xYIEIAUoSoM9EGSAAUaoEiREZsAaogbtbx3trBVQAooQKsPABEQQgPAqQ6YkgBPAUfqbQ+9S+BvBx/RQ8Q/hEzRXgIoz+H7FtD6bAD6lVgKch/A+xbQuh4BP1CWB1zhcOPlGXABbDVwo+UY8ACP8oNdwF0CeAIfwByq4Alu/xjQhQbgWwHL4hyqsAXoLHFJAZbyMeU0A2bC7ynOC7AngOHlPACkoZ8QYk8CUAR/DHQpASDAJMJGcgUzpdssIoS2BXAOnQD5GrAldh+607kMeeANrBJ2SrwPOwfd8dyGJDgNydnausSkpAKEwHugJYDT4hLQAhLIG8ABydytlpOhJchC399S87cgJ4Cz6hIUBC4Pp4fwBX5wmXyZIl4HnxqR2WLm7uv9dAVwJ6z4bl5+ft0Cmd1A/RQ/B3bMP5/optedrmWdh+7A7ysb5j54aeWPp9ulyF8/4S2/IwVILlHXwqwLHw1nyvPo/D+X+ObXky9838F6s3+D5PwrXsY1sWNQHGwjt9UuPzp5/g+zThmj7FthwqAhwLf+qJrBPHOtfh+rIvzEZREWCzeRm+3nbNiZQd/B2nprXcKAkwnVqC7yMpgVkBagy+j4QEDP24/gVrD74PtwSmBEDw96lCAAQ/DqcEqgIg+GkUJwCCnweXAEx9PfyiCH4ZRQgwdBEIfhyu8AnxCgDm42z0EzV8RAwYAQJYp21Y/9NJCJALvvn/Ju5ZgACWEVh0Q4AccK7+mYEAVhG65cZt4Fo4Rr/g8xZUgMqBANYQHP0EpoA15C7/wuETqABWYH7gMwQEsAPrA58hIIAFFEp/AmuApeSa/xXDJ1ABKgcCaKI8+glMAUvIUf4NhE+gAmjQNpexpQ4E0OF73KuDKWAua8u/kdKfQAWQpG22sWUGCDCH9Yu/27g3AwSQwljpT0AACYyGT2AROJWl5d9w+AQqACfGwycgABdtcx5bpoEAU5hb/tumCVu9zxWeAQTgQe+jZGeCReAp5o9+V32KCpATZ+ETqABjzBn9DsMnUAHW0jbXXsMnUAGGmDL6u1s9F6v9IVABltKNetfhE6gAxzg1+h2X/EMgwCEVhU9gCpgK/TJHYeETqAB9hkZ/gcEnIEDiWPgFBw/u8+avBJ0IlQS/2fwBsgaX/Btb228AAAAASUVORK5CYII=""")
GRAPH_ICON = base64.decode("""PHN2ZyBmaWxsPSIjZmYwMDAwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJtMjAuMzggOC41Ny0xLjIzIDEuODVhOCA4IDAgMCAxLS4yMiA3LjU4SDUuMDdBOCA4IDAgMCAxIDE1LjU4IDYuODVsMS44NS0xLjIzQTEwIDEwIDAgMCAwIDMuMzUgMTlhMiAyIDAgMCAwIDEuNzIgMWgxMy44NWEyIDIgMCAwIDAgMS43NC0xIDEwIDEwIDAgMCAwLS4yNy0xMC40NHptLTkuNzkgNi44NGEyIDIgMCAwIDAgMi44MyAwbDUuNjYtOC40OS04LjQ5IDUuNjZhMiAyIDAgMCAwIDAgMi44M3oiLz48L3N2Zz4=""")
TREE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAABuwAAAbsBOuzj4gAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAydSURBVHic5ZtrcF3Vdcd/a59zH7pXss3TpMZAC3jycEoGGCzZjSyVMM1r0slk8JCaYotISnEpD8uEh0k0ygSrBsuBUBLANrYpTUI0YdLpBJpSYsvYsjzB08FpmxY8jAmBQsAPrNd9nLNXP5x7r6/uS1fWvZ7p9P9Bts7ae+211tlr7bXW2RJV5f8z3NqzFBkYWf5ZsBdjQy/0LH3pzdqvUTtIrXfAwEjrnahszvyqwPMYeaRnye4Xa7pQjVAzA2ze19auRr8HLC4z5LmelqGvAGzev/wmFW5BWQSkgFdRfVVFXjXYk2AWKDIf7KGelpf/se/gVQ2xRONVxvUnUhI5ErHpu6zq78aTztbetl2J2chdEwP0IaZx//JDoJ8oN0aF59c1D31h4EDrx7Hy74BUJaDoFlWztAzvEwLPqLqbTtfVzOlMysfGfZ++qHF4+bZKygMpsWwEUJXFTKO8l7JYP3gxqtJVxFshnbBYq/MUbkW81wdG2j53OvLPOgg6xvwz6MfKDlDecoxpvaNl15E+xDRq6+cr8UtO+KQmLADGEdyw4EYMjis5uvUCIwFE4g7hBhNCWQO8MFP5Z20AEd5F+RjKBwgOcFbBgAN3NO868uCB9gsbbetPgWsKeahCasLHS2nuzQNYX0lNKqlJixhBDFhvqssmx32MATdilvchphe1M5F/xi7Qd/DqWP7vF701/zqr7mU9S4fOs4YlxTP0S5tHln/JUfs0JZQHmDzpkZq0U5Qv4mK1SPksksGOaZqzv7WSG5ZE1UHwoV+1X2DS/iAil6lwu1j3gJC+2opcJ7AcGAU9H+TiEtNTBLutyOBqlbFj3kzlLkLTOSEw2tXTvGfrTOZNa4Dv7vuTT1jH/QKqncDlsxGyFHxPmTgxewPE5rk4jjyrmO9YTb/5jWV7R6uZV9EAm/e3XqvILwBnOkbWV/y0ohZUNRPADDKNk6nC+PH0DD23GGKE+DwHMQLwPxizomfJrr3TzasYBBVzB2hF5b2Ukpr08dOlDOkjAoiAKuGYQ7hhqkVEoKHJJTHmY31FTKBM9py0vlKNl6pV0kkl3CAAH8Hax4ArpptX0gBPHrw6NJqM343wxSKVPMVLWRzXYH0lOe5XFkyzP4KIbT0l2uhMyQSckBA/y0U1MEg+kuM+qcky20OgocnBGAFD8O8pXAowOLjCuf76n5QVssgFNg23/rmIbAA+nn2Wjc5ihPHjHmpnlz06ISE2x60qF5z80MMrubtyOUC5qWngbSAmlo61y4aeLzUotwMeGmm90qh8X0SmHGVeyjJ5svJbnin8tOKlFTc8vQWiTS5e2mK9IL4gIAZCEYNxKs4PAZcAqOFuoLwBNu779EWumF8gnFs4IJ2ofb8gHDVVKQ+nlCUymxX17XIUA+CKub6U8gC+N8vwXAAxEI5Ne6jUEklrpLcc0WR+zitFVKuzPp6KeQb5/OnC94LAmxgLgmMufVYyR3DRlIixvDIw3LamFD9RVQZG2j6HapGPaKbq8lK2zDFXPRxXMI5gXCEcNRUDYHbdbPB1w8HcdMKWPxGyCpngWHVCxQsY6y++c9ne/5gyXlV5aPjaS414hysxTictidHiN2dcIRJzcMOCn1YmTnpBHyireCiglxKoFLykJTHmV3X2l0UmtyiMMwpPG+wgYq6wlv3rlg79Ujbtb12J8iiFVVwJ+GklkTnLRSDUYIgU+HM6ESgAEIk5hGPV11v5c2uBaJMTBNDS8NXhchdlE1UoD5mEZV7phCWLUPRU+uuGq1deLdNu75kiMRr0Fkwmu4w2TXlZ1qb9pCtwtxW5TqwKwhLgskpyAu+LcH6lhWeieBZigjdWi8IoH9ZXrA+gRBqd/Be35xvL9r4zJRPcPNx6owqrQM4lMERjjqi8qC5fF5XLsPpzgkSj5hg/7lXsC1QNmRpnnZChYU7B8Svy47LV4MD+5berchbG7HWxb3+YMK/Hw7pGRAeoVEQpeOngeDKu4IakKGPLHa1S7ErjxzzsLFJtMUFdUc5FM3gdeE3RfdP2A/p2t0fjEbtS4B7y3MN6QZVmnKBV5XsaHJlJWxTBjRMYAhME0vwj1Q0LkbiTM1Jqws4qTzBGiJ9d9v34Iqxc2zz0bPZBWQM8PNJ+iY+9FWU1cE4+LTHmk06cCliZavf0IRCNO4SiQezwPSU55uOXaYFNh/g8F+MWbwER3bK2eU93/rOSptp06M/iov6/glxaip6vPMxSeQANjCom6AI7rhCb55KazOyGGfKfHPVpmOMUF0sqRQ2S0uF6YmJxOeWz7eh6IJ2cyjvcYIjNnXnj2vpBm60wjbclAncR94H9bd2CuaoUY9/TGZfG2Y5QYQ/BCUkujuSEKZW+ljlR3bAgRlCFSMwESVpeEqWAooiwXVR2W7H/va755QNFfIpZ6y3Ap0otWrj1IQhw4QaDCKQSp2oGkaCWz6WjCl7Gt62vufTY+kHBJU5RRwcAP8/eIkGiFYoW9wLy37ZxJHABI6C8t7Zl6OlS+kAJFxDhZ8Ab5SbkwwkJsbkuoajBjQTbNfsFJ9LoZJU/geqjCMfcTOsrNtfNKWAcwQlJSeUh2BWRuEMk7hA/O5R/YhwGTuTLEokFiU60cYr/rxocXFG2/i4ywNrmob6elqFLBX5YSAs3mFx0DUUNsTkuxuhnVEx7dkzD3EDBTA5+RODXPUv33GZIX+iMhZ/LCjtdt7hw3ewuA1RFnulp2bPIHHUXOx+GJ3LjYobGc0KFhVe4Uk+wrBij4fEuIDllsBPUAo2NkQMNMfdPRU3L2pY9L43/FyPYYFERcgKIlZvXtgy1AtzZMjwZf2nBt2IjF2DGq08inZNhxDePoXq9qn5RHPvRdc27/xJUG4cXdsRfXhALH577T8CREtMTIH9TiX/ZENt71SsTm0baBkX1xikEK8R/c+6V7luxa+ZFJ7/LMviD1xYuGVvwDrYxDfArRJ9CjSWsU0ps9VLvue830Di0gMlPHnssvXD096pqRLgGyH3dFYu678Yl/MZcnGOR17v6d9xaKN+T61e1C3I/Ssr59TndF0Wj7/92wdELjaQvUbQJh9dGJ9w3ett2VSwuKmaCff+5OBw/cfbDglyLkDLHwy/GDs4/z0y6XwbiwGFjZK317T3eBZNL7Zz0gQ86fra07AdKEdly76o04KByS1f/9sezpE3Dy85HQsscz9jGf1n4FL6cnSEd6tqwY0p/f+v61X+tysOAK/CDzg07SnZ7qsFpXZB46u6vNfnGW4PIeqApjzTp+M78mzduK/tZast9qxNABKG/64Ed9xXR13fcgOqP8h55YD/TteHpocG+FeETyYa/A+kKpOen+kHkq91PPJGesRIZnNYFiZs3bhvt6t+5Me3JIkF2cipXa/Ade0O5eY/23TiHTH9XLQsL6U/2fT2Gan/BYxfML7fcu2rfiWTsdznl4cfvhN+8YTbKwyxviKx5cPu7nRu2rxbVrwKZuzr6wJPr/qJkhznsheZn/y8iRQYwycQ3yfTyi+QUWQqcB0yqsO6dyB+u7O2t7N/VYNZXZAA6+3c+K0bagd8D50k4/L1S41xf8xopuqivrz0XhLetv2mxIj2VV5Iho/4fdz+wY6C3t7cmOXlNr8k9fm/HJY7oMPARVVnR3b99MJ++5d5VX0bkudwDlUdM1Pm2P+kvEKP/AHyyDOtxhbu6+3c+To3v9dVkB2TxV/3bj2hQPquIPrP1vo4p94FUZOr9AtHbbdI7KkYPUUZ5gVdAr+zesOMHtVY+EKEOV2W33rf6EYXbgCRI17zD4z88fnnjFUbtzxUuqJKNFfRBezT6rdkGukqoiwF29HVE00l9Bcje2bHMYLcpvGVUburs37675sIVoKYukMXq3u0JRDadzjoiDPqavuJMKA91uSwdQHBfUNJKlTdCM5P6O0skR/VEXXYAQOcDW94TODiDKd8plRnWG3UzAICWuZRQAt/u2rDjm/WUpRzqawCr016RF3ipa8OOst/v6426GsANue9PM0RF9a56yjAd6rsDVCrf5Vf+/mv9O/+tnjJMh7oaIO37lU8A0cGK9DOAuhrAEb/UveEc1HKonutXg7oaQDB/VIE81v23O39bz/WrQV0NYLXCH1JAdHBF+Xb1mUJ9d4DIZyuQ3aOLGqotjOqGuhlg2/2dF1O+vgfA8Uv/AcWZRN0MoOoVXbQugsht9Vq/WtTRAHRWMaxty/qOkt8hzxTqYoAn7lndSpkPrIUQ5Y56yFAt6mIAMXp7tWMVXbn1/o7meshRDWreD+jra3cXyMW/UWRjtXPU51PASK1lqQZ1aYn9X8L/AoLwJjjnUPp/AAAAAElFTkSuQmCC""")

# END ICONS ----------------------------------------
# API ENDPOINTS
SE_DETAILS_URL = "https://monitoringapi.solaredge.com/site/{}/details"
SE_OVERVIEW_URL = "https://monitoringapi.solaredge.com/sites/{}/overview"
SE_POWER_URL = "https://monitoringapi.solaredge.com/sites/{}/power"
SE_ENVBEN_URL = "https://monitoringapi.solaredge.com/site/{}/envBenefits"

# SolarEdge API limit is 300 requests per day, which is about
# one per 5 minutes
CACHE_TTL = 300

# END API ENDPOINTS

def main(config):
    api_key = "78IJF13RCZREMHW0ZQ2MEDOJ6AHRQYZ1"  #config.str("api_key")
    site_id = "540914"  #humanize.url_encode(config.str("site_id", ""))
    headers = {"X-API-Key": api_key, "content-type": "application/json"}

    # API CALLS ----------------------------------------
    #   Details ---------------------------------------
    url_details = SE_DETAILS_URL.format(site_id)
    res_details = http.get(url_details, headers = headers, ttl_seconds = CACHE_TTL)
    if res_details.status_code != 200:
        fail("SolarEdge Monitoring: Overview request failed with status %d", res_details.status_code)

    #   Overview ---------------------------------------
    url_overview = SE_OVERVIEW_URL.format(site_id)
    res_overview = http.get(url_overview, headers = headers, ttl_seconds = CACHE_TTL)
    if res_overview.status_code != 200:
        fail("SolarEdge Monitoring: Overview request failed with status %d", res_overview.status_code)

    #   PARSE Time and Timezone for use in Power call ----
    # timezone = config.get("timezone") or "America/Los_Angeles"
    tz = res_details.json()["details"]["location"]["timeZone"]
    timezone = tz  #config.get("timezone") or "America/Los_Angeles"
    startTime = time.now().in_location(timezone).format("2006-01-02 00:00:00")
    endTime = time.now().in_location(timezone).format("2006-01-02") + " 23:59:59"

    #   Power ---------------------------------------
    url_power = SE_POWER_URL.format(site_id)
    params = {"startTime": startTime, "endTime": endTime}
    res_power = http.get(url_power, params = params, headers = headers, ttl_seconds = CACHE_TTL)
    if res_power.status_code != 200:
        fail("SolarEdge Monitoring: Power request failed with status %d", res_power.status_code)

    #   Environmental Benefits ---------------------------------------
    url_envben = SE_ENVBEN_URL.format(site_id)
    res_envben = http.get(url_envben, headers = headers, ttl_seconds = 43200)
    if res_envben.status_code != 200:
        fail("SolarEdge Monitoring: Overview request failed with status %d", res_envben.status_code)

    # PARSE RESPONSES
    peak_power = math.round(res_details.json()["details"]["peakPower"])
    current_power = str(float(math.round(res_overview.json()["sitesOverviews"]["siteEnergyList"][0]["siteOverview"]["currentPower"]["power"] / 100) / 10))
    energy_today = math.round(res_overview.json()["sitesOverviews"]["siteEnergyList"][0]["siteOverview"]["lastDayData"]["energy"] * 0.001)
    trees_planted = math.round(res_envben.json()["envBenefits"]["treesPlanted"])

    # Extract the values
    values = res_power.json()["powerDateValuesList"]["siteEnergyList"][0]["powerDataValueSeries"]["values"]

    # Create the data array
    data_array = []
    for i, entry in enumerate(values):
        value = entry["value"] if entry["value"] != None else 0.0
        data_array.append((i, value * 0.001))

    # RENDER APP
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Image(src = POWER_ICON, height = 10, width = 8),
                        render.Text(content = "%s" % current_power),
                        render.Text(font = "tom-thumb", color = "#717171", content = "kW"),
                        render.Image(src = TODAY_ICON, height = 10, width = 9),
                        render.Text(content = "%d" % energy_today),
                        render.Text(font = "tom-thumb", color = "#717171", content = "kWh"),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Row(
                            children = [
                                render.Plot(
                                    data = data_array,
                                    width = 64,
                                    height = 22,
                                    color = "#0f0",
                                    x_lim = (0, 95),
                                    y_lim = (0, peak_power),
                                    fill = True,
                                ),
                            ],
                        ),
                        render.Box(
                            padding = 1,
                            height = 24,
                            width = 20,
                            child =
                                render.Column(
                                    #main_align="end",
                                    children = [
                                        render.Row(
                                            main_align = "center",
                                            children = [
                                                render.Text(content = "%d" % trees_planted, font = "CG-pixel-3x5-mono"),
                                            ],
                                        ),
                                        render.Box(
                                            #padding=2,
                                            height = 13,
                                            width = 16,
                                            child =
                                                render.Row(
                                                    main_align = "center",
                                                    children = [
                                                        render.Image(src = TREE_ICON, height = 13, width = 14),
                                                    ],
                                                ),
                                        ),
                                    ],
                                ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "API key for the SolarEdge monitoring API.",
                icon = "key",
                default = "78IJF13RCZREMHW0ZQ2MEDOJ6AHRQYZ1",
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID, available from the monitoring portal.",
                icon = "solarPanel",
                default = "540914",
            ),
        ],
    )
