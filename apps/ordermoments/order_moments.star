"""
Applet: Order Moments
Summary: Celebrate major moments
Description: Get celebratory notifications when you hit specific order milestones.
Author: Shopify
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("cache.star", "cache")
load("hash.star", "hash")

# Messages
ERROR_TEXT = "We hit a snag. Please check your app."

# Endpoints
REST_ENDPOINT = "https://{}.myshopify.com/admin/api/2022-10/{}.json"
COUNT_ENDPOINT = "orders/count"

# Metafield definitions
METAFIELD_ENDPOINT = "metafields"
METAFIELD_UPDATE_ENDPOINT = "metafields/{}"
METAFIELD_DESCRIPTION = "A number of sales last celebrated by this store's TidByt Display"
METAFIELD_NAMESPACE = "tidbyt"
METAFIELD_KEY = "lastcelebration"
METAFIELD_OWNER = "shop"

# Cache definitions
CACHE_TTL = 600
CACHE_ID_ORDERS = "{}-orders"
CACHE_ID_METAFIELD = "{}-metafields"

# Milestone definitions are a list of Tuples where the first element is a base number of sales
# and the second element is an increment at which celebrations happen after that base.
MILESTONE_DEFINITIONS = [
    (0, 10),
    (100, 25),
    (500, 50),
    (1000, 100),
    (2000, 250),
    (5000, 500),
    (10000, 1000),
    (100000, 5000),
    (500000, 10000),
    (1000000, 100000)
]

# MAIN
# ----
def main(config):

    store_name = config.get("store_name")
    api_token = config.get("api_token")

    # If applet isn't configured, say so
    if not store_name or not api_token:
        print("Error ❌: Missing store name (%s) or API token (%s)" % (store_name, api_token))
        return error_view(ERROR_TEXT)

    # Get our current order count, and if it failed skip rendering
    order_count = get_order_count(store_name, api_token)
    if order_count < 0:
        return []

    # Get our latest celebration, and if it failed skip rendering
    celebration = get_latest_celebration(store_name, api_token)
    if celebration.get("error"):
        return []

    # Get our latest milestone based on our orders and update
    # our celebration if we passed a new one
    milestone = get_milestone(order_count)
    if milestone > celebration["orders"]:
        new_celebration = {
            "orders": milestone
        }
        if celebration.get("id"):
            new_celebration["id"] = celebration["id"]
        store_latest_celebration(new_celebration, store_name, api_token)
        celebration = new_celebration

    if should_celebrate(celebration):
        print("Celebrating.")
        return render.Root(
            render.Stack(
                children = [
                    render.Image(CELEBRATE_FIREWORKS),
                    render.Box(
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(get_formatted_number(milestone)),
                                render.Text("orders!")
                            ]
                        )
                    )
                ],
            ),
        )

    # There's nothing to celebrate today, so skip rendering.
    print("Skipping celebration.")
    return []

# GET FORMATTED NUMBER
# Takes a milestone number and formats it in a friendly way
# -----------------------------------------------------------------------------------------
# milestone: A number to be formatted
# Returns: A string representing a friendly formatted number
def get_formatted_number(number):

    if number % 1000000000 == 0:
        return "%sB" % humanize.comma(number // 1000000000)
    elif number % 1000000 == 0:
        return "%sM" % humanize.comma(number // 1000000)
    elif number % 1000  == 0:
        return "%sk" % humanize.comma(number // 1000)
    else:
        return humanize.comma(number)

# GET MILESTONE
# Returns a milestone based on our milestone definitions for a provided order count
# -----------------------------------------------------------------------------------------
# Returns: a number representing the most applicable milestone for a number of orders.
def get_milestone(order_count):
 
    previous = MILESTONE_DEFINITIONS[0]
    for base, step in MILESTONE_DEFINITIONS:

        if order_count > base:
            previous = (base, step)
            continue

        return ((order_count - previous[0]) // previous[1]) * previous[1] + previous[0]

# SHOULD CELEBRATE
# Returns whether or not we should celebrate now, given the previous celebration milestone
# -----------------------------------------------------------------------------------------
# last_celebration: A dict with data from the last celebration
# orders: A number of current orders
def should_celebrate(last_celebration):

    # If we don't have a date for our last celebration, we know it's new
    if last_celebration.get("date") == None:
        return True

    now = time.now().in_location("utc")
    lcd = last_celebration["date"]
    day_of_week = lcd.format("Mon")
    time_since = now - lcd

    print("Last celebrated %d orders on %s (%s, %d hours ago - currently %s)" % (last_celebration["orders"], lcd, day_of_week, time_since.hours, now))

    # We want to celebrate for 24 hours of weekday time. So:
    # - If the order milestone happened on a Friday, add 48 hours to the
    #   celebration time.
    # - If the order milestone happened on a Saturday or Sunday, celebrate
    #   until the end of the day on Monday.
    additional_time = 0
    if day_of_week == "Fri":
        additional_time = 48
    elif day_of_week[0] == "S":
        if day_of_week == "Sat":
            additional_time = (time.time(year=lcd.year, month=lcd.month, day=lcd.day + 1, hour=23, minute=59) - lcd).hours
        else:
            additional_time = (time.time(year=lcd.year, month=lcd.month, day=lcd.day, hour=23, minute=59) - lcd).hours

    # We celebrate if the time since the last milestone is less than the celebration duration
    return time_since.hours < (24 + additional_time)


# GET LATEST CELEBRATION
# Retrieves remote data representing our latest celebration from a shop metafield.
# -----------------------------------------------------------------------------------------
# store_name: A name of a Shopify store for the API call
# api_token: A Shopify API token
# Returns: A dict with id, date, and orders keys, or a dict with an error key if failed
def get_latest_celebration(store_name, api_token):
    
    # Check our cache
    cache_key = CACHE_ID_METAFIELD.format(hash.sha1(store_name))
    cached_metafields = cache.get(cache_key)

    if not cached_metafields:
        # Nothing was cached, so fetch it now
        url = REST_ENDPOINT.format(store_name,METAFIELD_ENDPOINT)
        headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}
        response = http.get(url = url, params = {"owner-resource": METAFIELD_OWNER}, headers = headers)
        
        if response.status_code != 200:
            print("get_latest_celebration Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return {"error": response.status_code}

        # Store the new value in cache
        print("Cache 💾: Storing value for key %s" % cache_key)
        cache.set(cache_key, response.body(), ttl_seconds = CACHE_TTL)
        metafields = response.json()

    else:
        # Use our cached value
        print("Cache 💾: Found cached value for key %s" % cache_key)
        metafields = json.decode(cached_metafields)

    # Find the metafield with our namespace and key and return it
    for metafield in metafields["metafields"]:
        if metafield["namespace"] == METAFIELD_NAMESPACE and metafield["key"] == METAFIELD_KEY:
            return {
                "id": metafield["id"],
                "date": time.parse_time(metafield["updated_at"]).in_location("utc"),
                "orders": metafield["value"]
            }

    # If nothing was celebrated yet, our last number of celebrated orders is 0 on the epoch
    return {
        "orders": 0,
        "date": time.from_timestamp(0)
    }


# STORE LATEST CELEBRATION
# Creates or updates remote data representing our latest celebration as a shop metafield.
# -----------------------------------------------------------------------------------------
# celebration: A dict with 'id' and 'orders' keys
# store_name: A name of a Shopify store for the API call
# api_token: A Shopify API token
# Returns: True if successful, False otherwise
def store_latest_celebration(celebration, store_name, api_token):

    headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}

    if not celebration.get("id"):

        # An ID isn't already available, so we're storing our data as a metafield
        # for the first time.

        url = REST_ENDPOINT.format(store_name, METAFIELD_ENDPOINT)

        payload = {
            "namespace": METAFIELD_NAMESPACE,
            "type": "number_integer",
            "key": METAFIELD_KEY,
            "description": METAFIELD_DESCRIPTION,
            "value": celebration["orders"]
        }

        response = http.post(url = url, headers = headers, json_body = {"metafield": payload})
        if response.status_code != 201:
            print("store_latest_celebration Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return False

        return True

    else:

        # An ID is available, so we're updating our existing metafield with a new order count.

        url = REST_ENDPOINT.format(store_name, METAFIELD_UPDATE_ENDPOINT.format("%d" % celebration["id"]))
        payload = {"value": celebration["orders"]}
        response = http.put(url = url, headers = headers, json_body = {"metafield": payload})

        if response.status_code != 200:
            print("store_latest_celebration Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return False

        return True
        
# GET ORDER COUNT
# Gets a number of orders for a provided store name using a provided API token
# -----------------------------------------------------------------------------------------
# store_name: A store name
# api_token: An API token
# Returns: A number representing the order count for a store, or -1 if the count couldn't be fetched
def get_order_count(store_name, api_token):

    # Check our cache
    cache_key = CACHE_ID_ORDERS.format(hash.sha1(store_name))
    cached_orders = cache.get(cache_key)

    if not cached_orders:
        # Nothing was in the cache, so fetch our orders now
        url = REST_ENDPOINT.format(store_name,COUNT_ENDPOINT)
        headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}
        response = http.get(url = url, params = {"status": "any"}, headers = headers)

        # If there was any error, return -1
        if response.status_code != 200:
            print("get_order_count Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return -1

        # Store the new value in cache
        print("Cache 💾: Storing value for key %s" % cache_key)
        cache.set(cache_key, response.body(), ttl_seconds = CACHE_TTL)
        order_count = response.json()

    else:
        # Use our cached value
        print("Cache 💾: Found cached value for key %s" % cache_key)
        order_count = json.decode(cached_orders)
    
    # Return our count value
    return order_count["count"]

# Error View
# Renders an error message
# -----------------------------------------------------------------------------------------
# message: A message to display as a rendered error
# Returns: A Pixlet root element
def error_view(message):
    return render.Root(
        render.Stack(
            children = [
                render.Image(STARFIELD),
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(ALIEN_ERROR),
                        render.Marquee(
                            width = 64,
                            offset_start = 64,
                            child = render.Text(content = message, color = "#FF0"),
                        )
                    ],
                )
            ]
        )
        
            
    )

# Get Schema
# Return a Pixlet Schema for this Celebrate Applet
# -----------------------------------------------------------------------------------------
# Returns: A Pixlet schema
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "The API Token for your Shopify Private App",
                icon = "key",
            ),
            schema.Text(
                id = "store_name",
                name = "Shopify Store Name",
                desc = "The Shopify store name used for API access",
                icon = "store",
            ),
        ],
    )

STARFIELD = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAIAAAAt/+nTAAAANklEQVR4Ae3UgQUAMAwEwKL7b9c9OkIGCIKA5w6A4OP9aeC/uz9Ojp6fYQAYWTsJWuWzAABAAdE/FW2ODnXTAAAAAElFTkSuQmCC
""")

ALIEN_ERROR = base64.decode("""
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
""")

CELEBRATE_FIREWORKS = base64.decode("""
R0lGODlhQAAgAPcAAAAAAAEDCwkdZgQQKBA0aXE9PD03eVtAbAwmggcXTwMJIRAxqdjACdVj6QoidAgaWgYTRBdObjvKchE1tQQNLQ0pjQEFFMheNhZKXw8wo5tNuousTRRFTjoqOZ6RFwIIHAskfAwqRQ4unjKoZUTmf1cyhbvaKAUSPggYVWp+JQkcYBAzsAMLJxEv
lA0rkxE2uwwniAYVSAofax5oYQQOMimLbe1r+OvPB2+QYVo9qFBtXTQmQ5JLPTNJTgkeIBQcUyBrbm2KS9lkMxAsg0j3hCyShr6uHldVJsrsJRIfXiMth6CZNF5oZlJxbSQynRZIrZ1SzSMvkyJyhLBWOQ0XQlIzRjSvfmuCMjVOYVxEwB1jURMcTVJnUedrMj46hA4e
WBtdPOLJCDYrVBpVhhA4OD3OfiI6ehcpZRxhSKTAJCeGXCY0qH5MZYijLxIZSH5+R7GhExNBlp9VVb1eRyAkcx8jbBU3qpaLIgUQOA4vVSEneU9mR1k4mS87Ip9W2xsjLj5WijctWzOscnVzNyqPeyR6nhNBQUv+hcayEhI8gg4smFM1TjY/QSeDVCQ8g31LX1tBtkxg
NCoqTYqoPh42aRYnYPDVBCY2rx0fUyU0p0PleREymSEpgSIriaXFN3NtI4CEWjtOazW1kQMLKBAqedDxJDGmXRIcO1xmXwsdU9ZlOw4ncic5txQdQA8vWhpZkTzMejQ6MiVCltZk7gogbXNASJxPxNnDEz3Qhw4gYCFveETohThTdxE4dlpYN7+xKA0tTxUiUAoWPJ5U
1B4rRO1sMSc5uD7RdCBuTSU+ix0zXxYeWA8gZAolNH18PN5mM1g1kHZwLW6NV11Fe6GaOg4kaVIwPl89RRYiYwgVNF1FxhhReBQYQh8gZhwwVLKjGydEnoBIOTWyhjxJXDFCOA4aTiMtjtvECl9rcJ5UOwkXQWyGPxwlN1k7oiN0jA8uiyyVjjhCUFs+rQogWx0fTB1d
oYuqRQYUL6TCLLvcLg0aVDOueRI+iiE4dO5zLhYgXCH/C05FVFNDQVBFMi4wAwEAAAAh+QQFCgAAACwAAAAAQAAgAAAI/wBfCBxIsKDBgwgTKkw4oaHDhxAjSpxIsSLFFRgzatzIsaPHjyA/LhhJsqTJkyhTqlypMoPLlzBjypxJs6bNmiJy6tzJs6fPn0CDAlVEtKjR
o0iTKl3KdKmLp1CjSp1KtarVq1YraN3KtavXr2DDig0Lo6zZs2jTql3Lti1bBHDjyp1Lt67du3jvgtjLt6/fv4ADCx4s2IHhw4gTK17MuLHjx5AjS57MmJaMy5gza97MubPnz50FiB5NurTp06hTq06torXr17Bjy55NuzbtB7hz697Nu7fv38B/oxhOvLjx48iTK1+u
PIHz59CjS59Ovbr16jGya9/Ovbv37+DDg56HQL68+fPo06tfz379iffw48ufT7++/fv28ejfz7+///8ABihggDQUaOCBCCao4IIMNsggBRBGKOGEFFZo4YUYXsjChhuOwsIoIHrI4YcifjgiiSeWyCGIHbYYoosvbqjAjDTWaOONOOao4446fuDjj0AGKeSQRBZpZJEW
JKnkkkw26eSTUEYp5ZRUVmnlkwFkqeWWXHbp5ZdghglmQAAh+QQFCgAAACwHABgAAQABAAAIBAD/BAQAIfkEBQoAAAAsBwAWAAEAAwAACAYA2QE4EhAAIfkEBQoAAAAsBwAUAAEABQAACAgAlwE4AsBDQAAh+QQFCgAAACwHABIAAQAHAAAICwC7ASiByQMABgEBACH5
BAUKAAAALAcAEgABAAcAAAgLAKEB0FCCAQBLAQEAIfkEBQoAAAAsBwARAAEABgAACAkA62gA0ECDpYAAIfkEBQoAAAAsBwARAAEABQAACAgAoTUAYKNBQAAh+QQFCgAAACwHABAAAQAGAAAICQDp2LIBAICNgAAh+QQFCgAAACwHABAAAQACAAAIBQD5NAgIACH5BAUK
AAAALAcADwABAAMAAAgGAOnYshEQACH5BAUKAAAALAcADwABAAoAAAgLAPk0AECwIAAGAQEAIfkEBQoAAAAsBwAOAAEACwAACA0A9diyAaBgQQYAPAQEACH5BAUKAAAALAcADgABAAsAAAgNAPk0AEAQwEAPAI4EBAAh+QQFCgAAACwHAA4AAQALAAAIDwBt2QAAoAEA
DQ2OAPgTEAAh+QQFCgAAACwHAA4AAQALAAAIDgAbABioAUAJDewA0AgIACH5BAUKAAAALAcADgABAAkAAAgNAG0AANAAGoBlJU4EBAAh+QQFCgAAACwHABEAAQAFAAAICABtdQMQA1NAACH5BAUKAAAALAcAEAAzAAcAAAgpABsAGEiwoMGDCBMqNAhtocOHEAuiiEix
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
""")