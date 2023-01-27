load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BACKGROUND_COLOR = "#638475"
ERROR_BACKGROUND_COLOR = "#540B0E"
API_KEY = "api_key"

def render_error_message(message):
    return render.Root(
        render.Box(
            color = ERROR_BACKGROUND_COLOR,
            child = render.Column(children = [
                render.Text(content = "Error", font = "6x13"),
                render.Marquee(child = render.Text(content = message), align = "center", width = 50),
            ]),
        ),
    )

def render_sales(count, total):
    return render.Root(
        render.Box(
            color = BACKGROUND_COLOR,
            child = render.Column(children = [
                render.Text(content = "Sales Today", color = "#FFFECB"),
                render.Text(content = total, font = "6x13"),
                render.Text(content = "{} orders".format(count)),
            ]),
        ),
    )

def get_beginning_of_today():
    now = time.now()

    year = now.year
    month = now.month
    day = now.day

    return time.time(year = year, month = month, day = day, hour = 0)

def get_total(charges):
    total = 0

    for charge in charges:
        total = total + charge["amount"]

    return total // 100

def stripe_api(endpoint, params, api_key):
    url = "https://api.stripe.com/v1/{}".format(endpoint)

    headers = {"Content-Type": "application/json", "Authorization": "Bearer {}".format(api_key)}

    response = http.get(url = url, headers = headers, params = params)

    return response.json()

def get_charges(api_key):
    beginning_of_today = get_beginning_of_today().unix

    query = "status:\"succeeded\" AND created >= {}".format(beginning_of_today)

    res = stripe_api(endpoint = "charges/search", params = {"limit": "100", "query": query}, api_key = api_key)

    return res

def get_sales(api_key):
    res = get_charges(api_key)

    data = res.get("data")

    if data != None:
        total = get_total(data)
        return {"total": "$" + humanize.comma(total), "count": len(data)}

    return {"error": res["error"]["message"]}

def get_content(api_key):
    content = cache.get(api_key)

    if content == None:
        response = get_sales(api_key)
        cache.set(api_key, json.encode(response), ttl_seconds = 300)
        content = response
    else:
        content = json.decode(content)

    return content

def main(config):
    api_key = config.get(API_KEY)

    if api_key == None:
        return render_error_message("API Key required.")

    content = get_content(api_key)

    error = content.get("error")

    if error:
        return render_error_message(error)

    total = content.get("total")
    count = content.get("count")

    return render_sales(count = count, total = total)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = API_KEY,
                name = "API Key",
                desc = "Your Stripe secret key",
                icon = "user",
            ),
        ],
    )
