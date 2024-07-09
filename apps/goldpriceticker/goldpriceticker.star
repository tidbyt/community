"""
Applet: GoldpriceTicker
Summary: Precious Metal Quotes
Description: Close to realtime precious metal prices and a graph comparing the price to the 5PM closing price from the day before.
Author: Aaron Brace
"""

load("cache.star", "cache")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

is_debug = True

PRECIOUS_METAL_NAMES = {
    "goldtwentyfourhour": "Gold",
    "gold30day": "Gold-30d",
    "gold90day": "Gold-90d",
    "gold1year": "Gold-1yr",
    "silvertwentyfourhour": "Silver",
    "silver30day": "Slvr-30d",
    "silver90day": "Slvr-90d",
    "silver1year": "Slvr-1yr",
    "platinumtwentyfourhour": "Platnm",
    "platinum30day": "Plat-30d",
    "platinum90day": "Plat-90d",
    "platinum1year": "Plat-1yr",
    "palladiumtwentyfourhour": "Palladm",
    "palladium30day": "Pldm-30d",
    "palladium90day": "Pldm-90d",
    "palladium1year": "Pldm-1yr",
    "rhodiumtwentyfourhour": "Rhodium",
    "rhodium30day": "Rhdm-30d",
    "rhodium90day": "Rhdm-90d",
    "rhodium1year": "Rhdm-1yr",
    "coppertwentyfourhour": "Copper",
    "copper30day": "Cppr-30d",
    "copper90day": "Cppr-90d",
    "copper1year": "Cppr-1yr",
}

timezone = "America/New_York"
closing_hour = 17
fnt = "tom-thumb"

#fnt="tb-8"
red_color_graph = "#f00"
green_color_graph = "#0f0"
red_color = "#aa0000"
green_color = "#006000"
white_color = "#cccccc"

PRICE_HISTORY_URL = "https://dpms.mcio.org/metals/v1/"
REALTIME_QUOTE = "https://dpms.mcio.org/metals/v1/latest"

def main(config):
    API_KEY = secret.decrypt("AV6+xWcEXpR9hD3BS4eRwb8BRQcDiK9luQOfbbmE0O2NsiSKUif/WZ9Ooptn5uZh6HKbo0vDZVrluhuNE7/dzRWrxoPBQyIfdk2Y2o7DvxGnEbM1yLPziFGJ+D0Yo0sfztGgMlVCqn/eCCTywDQ2a7wBhs2BhF+i91MIdKTueUgZsDtJtmU=") or config.get("dev_api_key") or ""
    PRECIOUS_METAL = "gold"
    GRAPH_PERIOD = "twentyfourhour"
    GOLDPRICETICKER_VERSION = "2.0"

    #Lets check the config to see if they passed a precious metal
    if (config.str("metal") == "gold" or config.str("metal") == "silver" or config.str("metal") == "platinum" or config.str("metal") == "palladium" or config.str("metal") == "rhodium" or config.str("metal") == "copper"):
        PRECIOUS_METAL = config.str("metal")

    #Same with graph period
    if (config.str("period") == "twentyfourhour" or config.str("period") == "30day" or config.str("period") == "90day" or config.str("period") == "1year"):
        GRAPH_PERIOD = config.str("period")

    if (config.str("metal") == "version"):
        return render.Root(
            child = render.Column(
                children = [
                    render.Marquee(
                        child = render.Text("Goldpriceticker version " + GOLDPRICETICKER_VERSION + "."),
                        width = 64,
                    ),
                    render.Marquee(
                        child = render.Text("New Features: 30,90 and 365 day charts."),
                        width = 64,
                    ),
                    render.Marquee(
                        child = render.Text("New base metal copper."),
                        width = 64,
                    ),
                ],
            ),
        )

    # Precious metal markets are open almost 24x5, so its hard to determine what a closing price is. However according to Kitco, its 5PM
    # So we will pull down the price history for the PM and look for the first quote after 5PM and use that as our closing price
    # We wont grab the new closing price until midnight Eastern time (why we always go back a day) to give time for people to see the results against todays close
    # at midnight we will start again
    # This means our graph will be for an X axis of 30 hours. When it starts over at midnight it will start with 7 hours of data

    HistoricalPrices = {}
    is_cached = True

    ClosingPrice = 0
    CurrentTime = time.now().in_location("America/New_York")
    RealtimePrice = 0

    Yesterday = CurrentTime - time.parse_duration("24h")
    if (GRAPH_PERIOD == "30day"):
        Yesterday = CurrentTime - time.parse_duration("720h")
    if (GRAPH_PERIOD == "90day"):
        Yesterday = CurrentTime - time.parse_duration("2160h")
    if (GRAPH_PERIOD == "1year"):
        Yesterday = CurrentTime - time.parse_duration("8760h")

    ClosingTime = time.time(year = Yesterday.year, month = Yesterday.month, day = Yesterday.day, hour = closing_hour, minute = 0, second = 0, location = "America/New_York")
    NextSessionStartTime = time.time(year = Yesterday.year, month = Yesterday.month, day = Yesterday.day, hour = (closing_hour + 1), minute = 0, second = 0, location = "America/New_York")

    if (is_debug == True):
        print("Using " + ClosingTime.format("January 2, 15:04:05, 2006 TZ Z07:00") + " As Precious Metal closing time")
        print("Using " + NextSessionStartTime.format("January 2, 15:04:05, 2006 TZ Z07:00") + " As Precious Metal session start time")

    ClosingTimeMili = int(ClosingTime.unix_nano) / 1000000
    NextSessionStartMili = int(NextSessionStartTime.unix_nano) / 1000000

    sessionstart_price_period = NextSessionStartMili / 1000 / (20 * 60)
    if (GRAPH_PERIOD == "30day" or GRAPH_PERIOD == "90day" or GRAPH_PERIOD == "1year"):
        sessionstart_price_period = NextSessionStartMili / 1000 / (360 * 60)

    if (is_debug == True):
        print("%d" % (ClosingTimeMili))

    closing_cache_key = "%d" % (ClosingTimeMili) + PRECIOUS_METAL + GRAPH_PERIOD
    closing_cache = cache.get(closing_cache_key)
    graphstart_cache = cache.get(PRECIOUS_METAL + GRAPH_PERIOD + ":GRAPHSTART")
    graphend_cache = cache.get(PRECIOUS_METAL + GRAPH_PERIOD + ":GRAPHEND")

    if (graphstart_cache == None or graphstart_cache == "" or graphend_cache == None or graphend_cache == "" or closing_cache == None):
        is_cached = False

    if (is_cached == False):
        if (is_debug == True):
            print("Fetching " + GRAPH_PERIOD + " price history for " + PRECIOUS_METAL)

        httpresponse = http.get(PRICE_HISTORY_URL + GRAPH_PERIOD + "/" + PRECIOUS_METAL + "?API_KEY=" + API_KEY)

        if (httpresponse.status_code == 401):
            return render.Root(
                child = render.Marquee(
                    child = render.Text("API Key Invalid"),
                    width = 64,
                ),
            )
        if httpresponse.status_code != 200:
            fail("Could not fetch " + GRAPH_PERIOD + " spot price history for URL " + PRICE_HISTORY_URL + GRAPH_PERIOD + "/" + PRECIOUS_METAL + " Error code %d" % (httpresponse.status_code))

        if (is_debug == True):
            print("Fetch complete")

        #We need to read the entire json and look for the entry closest to our target time. Dont assume its sorted

        last_matched_time_delta = -1

        for json_entry in httpresponse.json():
            # Lets put this value in the historical prices dictionary, but lets do it in 20 minute chunks and not miliseconds to reduce entries
            # We may have more than one match in 20 minutes, but this isn't perfect. One price over a 20 minute period is enough.
            # Afterall the tidbit only has 64 pixels width

            ChunkTimestamp = int(int(json_entry["timestamp"]) / 1000 / (20 * 60))

            #If its a 30 day chart, lets do 6 hours (360 minutes)
            if (GRAPH_PERIOD == "30day" or GRAPH_PERIOD == "90day" or GRAPH_PERIOD == "1year"):
                ChunkTimestamp = int(int(json_entry["timestamp"]) / 1000 / (360 * 60))

            HistoricalPrices[ChunkTimestamp] = float(json_entry["price"])
            print("Setting price %f" % ChunkTimestamp + "to %f" % float(json_entry["price"]))

            if (last_matched_time_delta != -1 and abs(int(json_entry["timestamp"]) - ClosingTimeMili) > last_matched_time_delta):
                # We should ignore this value, our current closing price is closer to 5PM
                continue
            ClosingPrice = float(json_entry["price"])
            last_matched_time_delta = abs(int(json_entry["timestamp"]) - ClosingTimeMili)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(closing_cache_key, "%f" % (ClosingPrice), ttl_seconds = (60 * 60))  #We will stretch this one since its really graphstart that handles state of cache

    else:
        ClosingPrice = float(closing_cache)

    if (is_debug == True):
        print("Closing Price %f" % (ClosingPrice))

    realtime_cache = cache.get(PRECIOUS_METAL)

    if (realtime_cache == None):
        # Now lets get the current realtime price

        if (is_debug == True):
            print("Fetching realtime price")

        httpresponse = http.get(REALTIME_QUOTE + "?API_KEY=" + API_KEY)
        if httpresponse.status_code != 200:
            fail("Could not fetch realtime spot price for URL " + REALTIME_QUOTE + " Error code %d" % (httpresponse.status_code))

        for json_entry in httpresponse.json():
            if (json_entry.get(PRECIOUS_METAL) == None):
                continue
            RealtimePrice = float(json_entry[PRECIOUS_METAL])

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(PRECIOUS_METAL, json_entry[PRECIOUS_METAL], ttl_seconds = 180)
            if (is_debug == True):
                print("Fetching realtime price completed")
            break
        if (RealtimePrice == 0):
            fail("Could not parse out spot price for " + PRECIOUS_METAL)

    else:
        RealtimePrice = float(realtime_cache)

    PercentageChange = ((RealtimePrice / ClosingPrice) - 1) * 100
    AmountChange = RealtimePrice - ClosingPrice

    NumPrefix = ""
    PercentageColor = green_color

    if (PercentageChange < 0):
        PercentageColor = red_color
        NumPrefix = ""

    plot_array = []

    last_timekey = 0
    last_timekey_value = 0
    mingraph = 0
    maxgraph = 0

    # Now lets build the plot array if we arent cached
    if (is_cached == False):
        for timekey in sorted(HistoricalPrices):
            if (int(timekey) < sessionstart_price_period):
                # This entry is from before our established session start time of 6PM, not part of graph
                print("Discarding")
                continue
            if ((int(timekey) != last_timekey + 1) and last_timekey != 0):
                for x in range(last_timekey + 1, int(timekey)):
                    plot_array.append((x, last_timekey_value))
                    if (is_debug == True):
                        print("%d %f" % (x, last_timekey_value))

                    # TODO: Determine if this cache call can be converted to the new HTTP cache.
                    cache.set(PRECIOUS_METAL + GRAPH_PERIOD + ":" + "%d" % (x), "%f" % (last_timekey_value), 172800)

            PercentageChange_hist = (float(HistoricalPrices[timekey]) / ClosingPrice - 1) * 100
            last_timekey_value = PercentageChange_hist
            last_timekey = int(timekey)
            plot_array.append((int(timekey), PercentageChange_hist))

            if (is_debug == True):
                print("%d %f" % (int(timekey), float(PercentageChange_hist)))

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(PRECIOUS_METAL + GRAPH_PERIOD + ":" + "%d" % (timekey), "%f" % (PercentageChange_hist), 172800)
            if (mingraph == 0):
                mingraph = int(timekey)

                maxgraph = mingraph + (30 * 3)  # 20 minute intervals means 3 per hour, a total of 30 hours between 6PM and Midnight the next night
                if (GRAPH_PERIOD == "30day"):
                    maxgraph = mingraph + (4 * 30)  # 6 hour intervals for 30day, which is 4 per day or 120 positions
                if (GRAPH_PERIOD == "90day"):
                    maxgraph = mingraph + (4 * 90)  # 6 hour intervals for 90day, which is 4 per day or 360 positions
                if (GRAPH_PERIOD == "1year"):
                    maxgraph = mingraph + (4 * 365)  # 6 hour intervals for 365day, which is 4 per day or 1460 positions

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(PRECIOUS_METAL + GRAPH_PERIOD + ":GRAPHSTART", "%d" % (mingraph), (20 * 60))

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(PRECIOUS_METAL + GRAPH_PERIOD + ":GRAPHEND", "%d" % (last_timekey), (20 * 60))
        if (is_debug == True):
            print(PRECIOUS_METAL + ":GRAPHSTART=" + "%d" % (mingraph))
            print(PRECIOUS_METAL + ":GRAPHEND=" + "%d" % (last_timekey))

    elif (int(graphstart_cache) != 0):  #If graphstart_cache is 0, market is probably closed
        mingraph = int(graphstart_cache)
        graphend = int(graphend_cache)

        maxgraph = mingraph + (30 * 3)
        if (GRAPH_PERIOD == "30day"):
            maxgraph = mingraph + (4 * 30)  # 6 hour intervals for 30day, which is 4 per day or 120 positions
        if (GRAPH_PERIOD == "90day"):
            maxgraph = mingraph + (4 * 90)  # 6 hour intervals for 90day, which is 4 per day or 360 positions
        if (GRAPH_PERIOD == "1year"):
            maxgraph = mingraph + (4 * 365)  # 6 hour intervals for 365day, which is 4 per day or 1460 positions

        for timekey in range(mingraph, graphend + 1):
            percent_cache = cache.get(PRECIOUS_METAL + GRAPH_PERIOD + ":" + "%d" % (timekey))

            if (percent_cache == None):
                # TODO: Determine if this cache call can be converted to the new HTTP cache.
                cache.set(PRECIOUS_METAL + GRAPH_PERIOD + ":GRAPHSTART", "")

                # TODO: Determine if this cache call can be converted to the new HTTP cache.
                cache.set(PRECIOUS_METAL + GRAPH_PERIOD + ":GRAPHEND", "")
                fail("Tried to fetch cache key " + PRECIOUS_METAL + GRAPH_PERIOD + ":" + "%d" % (timekey) + "but failed, invalidating cache")

            if (is_debug == True):
                print("%d %f" % (timekey, float(cache.get(PRECIOUS_METAL + GRAPH_PERIOD + ":" + "%d" % (timekey)))))
            plot_array.append((int(timekey), float(cache.get(PRECIOUS_METAL + GRAPH_PERIOD + ":" + "%d" % (timekey)))))

    PLOT_SECTION = ""

    # When the market is closed, we wont have anything to graph so lets put a single set of zeroes in the graph
    if (mingraph == 0):
        PLOT_SECTION = render.Text(
            content = "Market Closed",
            color = (white_color),
        )
    else:
        PLOT_SECTION = render.Plot(
            data = plot_array,
            width = 64,
            height = 20,
            x_lim = (mingraph, maxgraph),
            color = green_color_graph,
            color_inverted = red_color_graph,
            fill = True,
        )

    return render.Root(
        child = render.Column(
            cross_align = "start",
            children = [
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Row(
                        main_align = "space_between",
                        expanded = True,
                        children = [
                            render.Text(
                                content = (PRECIOUS_METAL_NAMES[PRECIOUS_METAL + GRAPH_PERIOD]),
                                font = (fnt),
                                color = (white_color),
                            ),
                            render.Text(
                                content = (NumPrefix + "%s" % humanize.float("#.##", AmountChange)),
                                font = (fnt),
                                color = (PercentageColor),
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Row(
                        main_align = "space_between",
                        expanded = True,
                        children = [
                            render.Text(
                                content = ("%s" % humanize.float("#.##", RealtimePrice)),
                                font = (fnt),
                                color = (white_color),
                            ),
                            render.Text(
                                content = (NumPrefix + "%s%%" % humanize.float("#.##", PercentageChange)),
                                font = (fnt),
                                color = (PercentageColor),
                            ),
                        ],
                    ),
                ),
                PLOT_SECTION,
                # ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "metal",
                name = "Precious Metal",
                desc = "The precious metal to provide quotes for and to graph.",
                icon = "coins",
                options = [
                    schema.Option(
                        display = "Silver",
                        value = "silver",
                    ),
                    schema.Option(
                        display = "Gold",
                        value = "gold",
                    ),
                    schema.Option(
                        display = "Platinum",
                        value = "platinum",
                    ),
                    schema.Option(
                        display = "Palladium",
                        value = "palladium",
                    ),
                    schema.Option(
                        display = "Rhodium",
                        value = "rhodium",
                    ),
                    schema.Option(
                        display = "Copper",
                        value = "copper",
                    ),
                    schema.Option(
                        display = "Version & Credits",
                        value = "version",
                    ),
                ],
                default = "gold",
            ),
            schema.Dropdown(
                id = "period",
                name = "Graph Period",
                desc = "The timeline to graph for",
                icon = "clock",
                options = [
                    schema.Option(
                        display = "24 Hours",
                        value = "twentyfourhour",
                    ),
                    schema.Option(
                        display = "30 Days",
                        value = "30day",
                    ),
                    schema.Option(
                        display = "90 Days",
                        value = "90day",
                    ),
                    schema.Option(
                        display = "1 Year",
                        value = "1year",
                    ),
                ],
                default = "twentyfourhour",
            ),
            schema.Text(
                id = "dev_api_key",
                name = "API Key",
                desc = "Test use only",
                icon = "bomb",
            ),
        ],
    )
