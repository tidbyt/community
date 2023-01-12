"""
Applet: Random Slackmoji
Summary: Displays a random Slackmoji
Description: Displays a random image from slackmojis.com!
Author: btjones
"""

# Copyright 2022 Brandon Jones

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

SLACKMOJI_PAGE_COUNT = 112
SLACKMOJI_IMAGES_PER_PAGE = 499
SLACKMOJIS_URL_RANDOM = "https://slackmojis.com/emojis.json?page="
SLACKMOJIS_URL_QUERY = "https://slackmojis.com/emojis/search?query="
FAIL_IMAGE = "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"
USE_CACHE = True
CACHE_SECONDS_URL = 60  # 60 seconds
CACHE_SECONDS_IMAGE = 60 * 60 * 24 * 30  # 30 days
SCHEMA_QUERY_ID = "query"

# fetches a random slackmoji url from all slackmojis
def get_random_url():
    page_url = SLACKMOJIS_URL_RANDOM + str(random.number(0, SLACKMOJI_PAGE_COUNT))
    response = http.get(page_url)
    if response.status_code == 200:
        body = response.body()
        data = json.decode(body) if body else None
        if data:
            slackmoji = data[random.number(0, SLACKMOJI_IMAGES_PER_PAGE)]
            if slackmoji and slackmoji["image_url"]:
                return slackmoji["image_url"]

    # something went wrong, no image url to return
    return None

# fetches a random slackmoji url from the query results
def get_query_url(query):
    page_url = SLACKMOJIS_URL_QUERY + query
    response = http.get(page_url)
    if response.status_code == 200:
        html_body = html(response.body())
        images = html_body.find("img")
        image_count = images.len()
        if image_count > 0:
            random_index = random.number(0, image_count - 1)
            return images.eq(random_index).attr("src")

    # something went wrong, no image url to return
    return None

# fetches a random slackmoji image url
def get_slackmoji_url(query):
    cache_name = "slackmoji_url_" + query

    # return cached url if available
    if USE_CACHE:
        cached_url = cache.get(cache_name)
        if cached_url != None:
            return cached_url

    # no cache, fetch new url
    url = get_query_url(query) if len(query) > 0 else get_random_url()

    # set cached url
    if USE_CACHE and url != None:
        cache.set(cache_name, url, ttl_seconds = CACHE_SECONDS_URL)

    return url

# downloads an image from the provided url
def get_image(url):
    if url:
        cache_name = "slackmoji_image_" + url

        # return cached image if available
        if USE_CACHE:
            cached_image = cache.get(cache_name)
            if cached_image != None:
                return base64.decode(cached_image)

        # no cache, fetch new image
        response = http.get(url)
        if response and response.status_code == 200:
            file = response.body()
            if file:
                if USE_CACHE:
                    cache.set(cache_name, base64.encode(file), ttl_seconds = CACHE_SECONDS_IMAGE)
                return file

    # something went wrong, return the fail image
    return base64.decode(FAIL_IMAGE)

def main(config):
    # get the slackmoji image url
    query = config.get(SCHEMA_QUERY_ID, "")
    url = get_slackmoji_url(query)

    # if no image url was returned and we have a query, show error message
    if (url == None and len(query) > 0):
        return render.Root(
            render.Box(
                child = render.WrappedText(
                    content = "No results for: " + query,
                ),
            ),
        )

    # download the image
    image = get_image(url)

    return render.Root(
        render.Box(
            child = render.Image(
                src = image,
                height = 32,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = SCHEMA_QUERY_ID,
                name = "Search Query",
                desc = "Optional search to narrow down the image results.",
                icon = "magnifyingGlass",
                default = "",
            ),
        ],
    )
