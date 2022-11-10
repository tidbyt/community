"""
Applet: WoW Token
Summary: Display WoW Token Price
Description: Displays the current price of the World of Warcraft token in various regions. Data provided by wowtokenprices.com and updated every 10 minutes
"""

print("----------------------------------------------------------------------------------------")

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("schema.star", "schema")
load("humanize.star", "humanize")

GOLD_ICON = base64.decode("""
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAATABIDAREAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD5l/Zs/ZEi8U+Gbbxj4qgkfS7l/wDRLbp5ig4LN3x9K/NuIeJp4GboYXc97A5f7b3qmx75rH7Hnw98V6KNOs9BfR9RkBH2pekZxgEeuePpXw+H4tzHD+9Vd0+57VbK6Dh7p+dPiPwjN4f8Q6ppchzJY3UtsxHqjlT/ACr9zoYlVaUKndJ/ej4qUeVtH66fsp634Y+Lvwa8OGzkmt5tItktmWDDIrLnJkXqpPb8K/C8/wAC6OOqSrXs9j6zDYiPs0kdZ8V/GHh74Q+F7rWtSnW0s7ZC6rcvtkmcfwIO5J6+gryMNlTzJqnBPc6pVoUk5Nn4y+KvFy+IPFGsaoIfLF9eTXITOdu9y2M/jX9E0ML7GjCnf4Ul9yPjJzUpOXcd4Q+IPiTwDPLJ4d1u90dpeH+yzFQ/1HQ1tXweHxNvbQTIhOUdmL4v+Inibx5Ij+IddvtXMf3PtUxYL9B0q6GFoUNKcEgnUnLdnN+WvpXTYg//2Q==
""")

WOW_TOKEN_URL = "https://wowtokenprices.com/current_prices.json"
REGION_LIST = ["us", "eu", "china", "korea", "taiwan"]

def get_schema():
    region_options = [
        schema.Option(display = region, value = region)
        for region in REGION_LIST
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Choose the World of Warcraft region.",
                icon = "moneyBill",
                default = "us",
                options = region_options,
            ),
        ],
    )

def main(config):
    region = config.get("region", "us")

    cache_id = "wowtoken_{}".format(region)
    token_price = cache.get(cache_id)

    if token_price != None:
        print("Cached price " + str(token_price))
        token_price = float(token_price)
        data_available = True
    else:
        print("Cache miss")

        query = http.get(WOW_TOKEN_URL)
        if query.status_code != 200:
            fail("API request failed with status %d", query.status_code)
        else:
            token_price = float(query.json()[region]["current_price"])
            print("Got price " + str(token_price))
            data_available = True
            cache.set(cache_id, str(token_price), ttl_seconds = 600)

    display = []

    if data_available:
        display.append(render.Row(
            children = [
                render.Text("{}".format(humanize.comma(token_price))),
            ],
        ))

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = GOLD_ICON),
                    render.Column(
                        main_align = "space_evenly",
                        expanded = True,
                        children = display,
                    ),
                ],
            ),
        ),
    )
