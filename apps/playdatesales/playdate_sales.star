"""
Applet: Playdate Sales
Summary: See Playdate games on sale
Description: Check what's on sale over in the Playdate Catalog.
Author: UnBurn
"""

load("bsoup.star", "bsoup")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

PLAYDATE_BASE_URL = "https://play.date"
SALES_URL = "https://play.date/games/tags/on-sale/"

PLAYDATE_YELLOW = "#FFC500"
TTL_TIME = 43200

def get_text_size_for_price(txt):
    return len(txt[1:]) * 4

def get_games_on_sale():
    sales_page = http.get(SALES_URL, ttl_seconds = TTL_TIME).body()
    games = []

    games_list = bsoup.parseHtml(sales_page).find("ul", {"class": "gameCards"}).find_all("li")
    for game_item in games_list:
        game = {}
        url = game_item.find("a").attrs()["href"]
        name = game_item.find("h2", {"class": "gameTitle"}).find("a").get_text().strip()
        retail_price = game_item.find("span", {"class": "prices"}).find("s").get_text().strip()
        sale_price = game_item.find("span", {"class": "prices"}).find("span", {"class": "discountedPrice"}).get_text().strip()

        game["url"] = PLAYDATE_BASE_URL + url
        game["name"] = name
        game["retail_price"] = retail_price
        game["sale_price"] = sale_price

        games.append(game)

    return games

def get_game_screenshots(game_url):
    game_page = http.get(game_url, ttl_seconds = TTL_TIME).body()
    screenshot_list_items = bsoup.parseHtml(game_page).find_all("li", {"class": "screenshot"})
    screenshot_tags = []
    for screenshot in screenshot_list_items:
        screenshot_tags.append(screenshot.find("img"))
    screenshots = []
    image_urls = []

    for img in screenshot_tags:
        image_urls.append(img.attrs()["src"])
    only_gifs = [img for img in image_urls if img.endswith(".gif")]
    if len(only_gifs) > 0:
        image_urls = only_gifs
    for screenshot in image_urls:
        screenshots.append(screenshot)

    return screenshots

def get_gif_data(url):
    gif_body = http.get(url, ttl_seconds = TTL_TIME).body()
    return gif_body

def main(config):
    show_retail_price = config.bool("show_retail")
    games_on_sale = get_games_on_sale()

    if len(games_on_sale) == 0:
        return None

    selected_game = games_on_sale[random.number(0, len(games_on_sale) - 1)]
    screenshots = get_game_screenshots(selected_game["url"])
    selected_screenshot = screenshots[random.number(0, len(screenshots) - 1)]
    gif_data = get_gif_data(selected_screenshot)

    stickers = []
    size_of_sticker = 6 + get_text_size_for_price(selected_game["sale_price"])
    if show_retail_price:
        size_of_sticker = size_of_sticker + (6 + get_text_size_for_price(selected_game["retail_price"]))
        stickers.append(render.Text(content = selected_game["retail_price"], color = PLAYDATE_YELLOW))
    stickers.append(render.Text(content = selected_game["sale_price"], color = "#ff0000"))

    sticker = render.Row(
        children = stickers,
    )

    return render.Root(
        delay = 20,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 6, 0, 0),
                    color = PLAYDATE_YELLOW,
                    child = render.Image(src = gif_data, width = 64, height = 26),
                ),
                render.Marquee(
                    child = render.Padding(
                        child = render.Text(content = selected_game["name"], font = "tom-thumb", color = "#000000"),
                        pad = (1, 0, 0, 0),
                    ),
                    width = 64,
                    delay = 30,
                ),
                render.Padding(
                    pad = (64 - size_of_sticker, 24, 0, 0),
                    child = sticker,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_retail",
                name = "Show retail price?",
                desc = "Show retail price as well as the sale price.",
                icon = "dollarSign",
                default = False,
            ),
        ],
    )
