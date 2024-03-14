"""
Applet: Defector
Summary: Display a Defector headline
Description: Displays a recent headline from Defector.com.
Author: Rory Sawyer
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("xpath.star", "xpath")

DEFECTOR_RSS_URL = "https://defector.com/feed"

# base64-encoded contents of the image in the rss feed
DEFECTOR_LOGO = base64.decode(
    ("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAABU1BMVEVHcEwAAAAAAAAAAAAA" +
     "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
     "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
     "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///+BgYF4eHiKioq5ubns7Owc" +
     "HBz4+PgCAgIRERHV1dX+/v4mJiYBAQG7u7tBQUHCwsIkJCQFBQUICAhlZWVhYWGTk5N3d3cW" +
     "Fhbh4eEoKCgaGhri4uJbW1sxMTGnp6dgYGDLy8vExMR9fX1YWFh2dnZvb2+FhYX39/cdHR37" +
     "+/uwsLCpqalPT08GBgbq6up1dXWlpaVAQEA+Pj6Li4tycnKBgoEfHx+fn595eXn09PS4uLiz" +
     "s7Pm7tc+AAAAM3RSTlMA3OoX/Kj97BbAiPIkMwnS9iflOWepLXCU1zz62+AMsbb+H+0KIgNQ" +
     "+d+RlkaJdLsGIUl2vsCNAAABcElEQVQ4y3WT1WLCQBBFl0CAoKW4e3Fou1MqFKu7u7vb/z81" +
     "7JIEyHKfJnNP1mYGIVnjxVJFY0jmhHwmhdTSmjgsy1xID9hjZTPuU9Zk6/WNAlbJblH8CQ1m" +
     "iLPK/zN9jA2O7v4CHiJ/hABl8rE43dXlxcuDRPjI/ej5p0DRY3WFAjqPCJiwCgBYqtMsL74f" +
     "JwNvc6KuW/e3IrEwT7JBLSpiGahKW681AdZp6EIlBoA3ABptErlRhQXs3gDskCiENCwAHwPs" +
     "03sgAxM4BHiiEUoygWeA8y6QYwInAEck0COBBdRrAAckCqM8CzgF2KMvFUUZBvB6BbBJQy9K" +
     "mWXgmwTtzw9xg8YqPUICoYIM1GY7+ukUa3uZZmNiNdNZVTWbd1vUjweQXO+zGarfv6/3lnQY" +
     "nnSUzT6s5UaNtCktHNsfcUptbTUw/UllMBx+xvrO3tGK+HT9dpw3Dkynhw8qtj4WYM23yx0S" +
     "19GHo96Ekv0HzKmlbLKQ7JEAAAAASUVORK5CYII="),
)

def get_item_from_rss(rss_xml):
    root = xpath.loads(rss_xml)
    titles = root.query_all("/rss/channel/item/title")
    idx = random.number(0, len(titles) - 1)
    return titles[idx]

def main():
    # refresh the rss feed every 15 minutes
    resp = http.get(DEFECTOR_RSS_URL, ttl_seconds = 900)
    if resp.status_code != 200:
        fail("unable to get defector rss feed")

    body = resp.body()
    title = get_item_from_rss(body)

    logo = render.Image(src = DEFECTOR_LOGO, height = 16)
    header_text = render.Padding(child = render.WrappedText("Defector Media"), pad = (4, 0, 0, 0))
    row = render.Row(
        children = [logo, header_text],
        cross_align = "center,",
    )

    marq = render.Padding(
        child = render.Marquee(width = 64, child = render.Text(title)),
        pad = (0, 2, 0, 0),
    )

    column = render.Column(children = [row, marq], main_align = "space_evenly")

    return render.Root(child = column)
