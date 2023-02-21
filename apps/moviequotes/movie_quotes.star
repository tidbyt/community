"""
Applet: Movie Quotes
Summary: Random Movie Quotes
Description: Random movie quote from AFI top 100 movie quotes.
Author: Austin Fonacier
"""

load("cache.star", "cache")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

def main():
    quote = get_random_quote()
    quote_body = quote[1]
    movie = quote[2]
    year = quote[3]
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    height = 10,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(quote_body, color = "#FF5733"),
                    ),
                ),
                render.Box(
                    height = 2,
                ),
                render.Box(
                    height = 1,
                    color = "#FFF",
                ),
                render.Box(
                    height = 2,
                ),
                render.Box(
                    height = 8,
                    width = 64,
                    child = render.Marquee(width = 64, align = "center", child = render.Text(movie, height = 8, font = "tom-thumb", color = "#FF5733")),
                ),
                render.Box(
                    height = 2,
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(
                            height = 6,
                            width = 6,
                            color = "#FFF",
                        ),
                        render.Box(
                            height = 6,
                            width = 30,
                            child = render.Text(year, height = 6, font = "tom-thumb", color = "#FFC300"),
                        ),
                        render.Box(
                            height = 6,
                            width = 6,
                            color = "#FFF",
                        ),
                    ],
                ),
            ],
        ),
    )

def get_random_quote():
    quotes = get_all_quotes()
    random_num = random.number(0, 99)
    return quotes[random_num]

def get_all_quotes():
    movie_csv_str = cache.get("movie_csv_str")

    if movie_csv_str == None:
        movie_csv_raw = http.get("https://raw.githubusercontent.com/wcmbishop/time-travel-movie-club/master/data-raw/afi-top-100-quotes.csv")
        movie_csv_str = movie_csv_raw.body()
        cache.set("movie_csv_str", movie_csv_str, ttl_seconds = 604800)
    quotes = csv.read_all(movie_csv_str, skip = 1)
    return quotes

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
