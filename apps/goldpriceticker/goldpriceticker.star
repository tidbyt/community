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
load("time.star", "time")

is_debug = True

PRECIOUS_METAL_NAMES = {
    "gold": "Gold",
    "silver": "Silver",
    "platinum": "Platnm",
    "palladium": "Palladm",
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

TFOURHR = "https://api.metals.live/v1/spot/"
REALTIME_QUOTE = "https://api.metals.live/v1/spot"

def main(config):
    PRECIOUS_METAL = "gold"

    #Lets check the config to see if they passed a precious metal
    if (config.str("metal") == "gold" or config.str("metal") == "silver" or config.str("metal") == "platinum" or config.str("metal") == "palladium"):
        PRECIOUS_METAL = config.str("metal")

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

    ClosingTime = time.time(year = Yesterday.year, month = Yesterday.month, day = Yesterday.day, hour = closing_hour, minute = 0, second = 0, location = "America/New_York")
    NextSessionStartTime = time.time(year = Yesterday.year, month = Yesterday.month, day = Yesterday.day, hour = (closing_hour + 1), minute = 0, second = 0, location = "America/New_York")

    if (is_debug == True):
        print("Using " + ClosingTime.format("January 2, 15:04:05, 2006 TZ Z07:00") + " As Precious Metal closing time")
        print("Using " + NextSessionStartTime.format("January 2, 15:04:05, 2006 TZ Z07:00") + " As Precious Metal session start time")

    ClosingTimeMili = int(ClosingTime.unix_nano) / 1000000
    NextSessionStartMili = int(NextSessionStartTime.unix_nano) / 1000000
    sessionstart_price_twenty = NextSessionStartMili / 1000 / 20 / 60

    if (is_debug == True):
        print("%d" % (ClosingTimeMili))

    closing_cache_key = "%d" % (ClosingTimeMili) + PRECIOUS_METAL
    closing_cache = cache.get(closing_cache_key)
    graphstart_cache = cache.get(PRECIOUS_METAL + ":GRAPHSTART")
    graphend_cache = cache.get(PRECIOUS_METAL + ":GRAPHEND")

    if (graphstart_cache == None or graphstart_cache == "" or graphend_cache == None or graphend_cache == "" or closing_cache == None):
        is_cached = False

    if (is_cached == False):
        if (is_debug == True):
            print("Fetching 24 hour price history for " + PRECIOUS_METAL)

        httpresponse = http.get(TFOURHR + PRECIOUS_METAL)

        if httpresponse.status_code != 200:
            fail("Could not fetch 24 hour spot price history for URL " + TFOURHR + PRECIOUS_METAL + " Error code %d" % (httpresponse.status_code))

        if (is_debug == True):
            print("Fetch complete")

        #We need to read the entire json and look for the entry closest to our target time. Dont assume its sorted

        last_matched_time_delta = -1

        for json_entry in httpresponse.json():
            # Lets put this value in the historical prices dictionary, but lets do it in 20 minute chunks and not miliseconds to reduce entries
            # We may have more than one match in 20 minutes, but this isn't perfect. One price over a 20 minute period is enough.
            # Afterall the tidbit only has 64 pixels width
            TwentyMinuteTimestamp = int(int(json_entry["timestamp"]) / 1000 / (20 * 60))
            HistoricalPrices[TwentyMinuteTimestamp] = float(json_entry["price"])

            if (last_matched_time_delta != -1 and abs(int(json_entry["timestamp"]) - ClosingTimeMili) > last_matched_time_delta):
                # We should ignore this value, our current closing price is closer to 5PM
                continue
            ClosingPrice = float(json_entry["price"])
            last_matched_time_delta = abs(int(json_entry["timestamp"]) - ClosingTimeMili)

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

        httpresponse = http.get(REALTIME_QUOTE)
        if httpresponse.status_code != 200:
            fail("Could not fetch realtime spot price for URL " + REALTIME_QUOTE + " Error code %d" % (httpresponse.status_code))

        for json_entry in httpresponse.json():
            if (json_entry.get(PRECIOUS_METAL) == None):
                continue
            RealtimePrice = float(json_entry[PRECIOUS_METAL])
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
            if (int(timekey) < sessionstart_price_twenty):
                # This entry is from before our established session start time of 6PM, not part of graph
                continue
            if ((int(timekey) != last_timekey + 1) and last_timekey != 0):
                for x in range(last_timekey + 1, int(timekey)):
                    plot_array.append((x, last_timekey_value))
                    if (is_debug == True):
                        print("%d %f" % (x, last_timekey_value))
                    cache.set(PRECIOUS_METAL + ":" + "%d" % (x), "%f" % (last_timekey_value), 172800)

            PercentageChange_hist = (float(HistoricalPrices[timekey]) / ClosingPrice - 1) * 100
            last_timekey_value = PercentageChange_hist
            last_timekey = int(timekey)
            plot_array.append((int(timekey), PercentageChange_hist))

            if (is_debug == True):
                print("%d %f" % (int(timekey), float(PercentageChange_hist)))

            cache.set(PRECIOUS_METAL + ":" + "%d" % (timekey), "%f" % (PercentageChange_hist), 172800)
            if (mingraph == 0):
                mingraph = int(timekey)
                maxgraph = mingraph + (30 * 3)  # 20 minute intervals means 3 per hour, a total of 30 hours between 6PM and Midnight the next night

        cache.set(PRECIOUS_METAL + ":GRAPHSTART", "%d" % (mingraph), (20 * 60))
        cache.set(PRECIOUS_METAL + ":GRAPHEND", "%d" % (last_timekey), (20 * 60))
        if (is_debug == True):
            print(PRECIOUS_METAL + ":GRAPHSTART=" + "%d" % (mingraph))
            print(PRECIOUS_METAL + ":GRAPHEND=" + "%d" % (last_timekey))

    elif (int(graphstart_cache) != 0):  #If graphstart_cache is 0, market is probably closed
        mingraph = int(graphstart_cache)
        graphend = int(graphend_cache)
        maxgraph = mingraph + (30 * 3)

        for timekey in range(mingraph, graphend + 1):
            percent_cache = cache.get(PRECIOUS_METAL + ":" + "%d" % (timekey))

            if (percent_cache == None):
                cache.set(PRECIOUS_METAL + ":GRAPHSTART", "")
                cache.set(PRECIOUS_METAL + ":GRAPHEND", "")
                fail("Tried to fetch cache key " + PRECIOUS_METAL + ":" + "%d" % (timekey) + "but failed, invalidating cache")

            if (is_debug == True):
                print("%d %f" % (timekey, float(cache.get(PRECIOUS_METAL + ":" + "%d" % (timekey)))))
            plot_array.append((int(timekey), float(cache.get(PRECIOUS_METAL + ":" + "%d" % (timekey)))))

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
                    width = 60,
                    height = 6,
                    child = render.Row(
                        main_align = "space_between",
                        expanded = True,
                        children = [
                            render.Text(
                                content = (PRECIOUS_METAL_NAMES[PRECIOUS_METAL]),
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
                ],
                default = "gold",
            ),
        ],
    )
