"""
Applet: NowShowing
Summary: Current movies in theaters
Description: Displays current movies in theaters.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

MOVIE_DATASET_URL = "https://www.moviefone.com/feeds/movie-reviews.rss"
MOVIE_DATASET_CACHE_NAME = "NowShowing_MovieDataSetCache"
SINGLE_MOVIE_CACHE_NAME = "NowShowing_SingleMovieDataCache"
MOVIE_REVIEW_SUBSTRING = "Movie Review: "
JSON_PROPERTY_DATA_DOWNLOADED_DATE = "Date_Downloaded"
SINGLE_MOVIE_CACHE = 1200  #20 Minutes
MOVIE_DATASET_CACHE = 172800  # 48 Hours

def get_movie_data():
    display_movie = cache.get(SINGLE_MOVIE_CACHE_NAME)

    if display_movie != None:
        #print("Got Movie from Single Movie Cache: %s" % display_movie)
        return json.decode(display_movie)

    movie_data = cache.get(MOVIE_DATASET_CACHE_NAME)

    if movie_data != None:
        movie_data = json.decode(movie_data)

        #If the Date of the original download it too old, we'll throw it away
        if time.now().unix - movie_data[JSON_PROPERTY_DATA_DOWNLOADED_DATE] > MOVIE_DATASET_CACHE - 20:
            movie_data = None

    if movie_data == None:
        #print("Movie Dataset Not cached -- fetching new.")
        # since we will cache the data we need out of here after manipulating it, we don't need to cache this URL
        resp = http.get(MOVIE_DATASET_URL, headers = {
            "accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
        })

        if resp.status_code == 200:
            movie_info_xml_body = resp.body()
        else:
            movie_info_xml_body = None

        if movie_info_xml_body != None:
            number_of_listings = movie_info_xml_body.count("<item>")
        else:
            number_of_listings = 0

        # set up the dataset we'll cache and use for displaying
        movie_data = {
            "movies": {},
            JSON_PROPERTY_DATA_DOWNLOADED_DATE: time.now().unix,
        }

        for i in range(1, number_of_listings + 1):
            current_query = "//item[" + str(i) + "]/description"
            current_description = xpath.loads(movie_info_xml_body).query(current_query)
            current_query = "//item[" + str(i) + "]/title"
            current_title = xpath.loads(movie_info_xml_body).query(current_query)
            current_query = "//item[" + str(i) + "]/enclosure/@url"
            current_movie_image_path = xpath.loads(movie_info_xml_body).query(current_query)

            # let's only capture movie reviews (and hope they don't change their format down the road.)
            if current_title.find(MOVIE_REVIEW_SUBSTRING) != -1:
                current_title = current_title.replace(MOVIE_REVIEW_SUBSTRING, "")
                current_title = current_title.replace("'", "").replace("’", "").replace("‘", "").replace("\"", "")
                current_title = current_title.strip()
                movie_data["movies"][current_title.strip()] = {"title": current_title.strip(), "description": current_description, "image": current_movie_image_path, "display_count": 0}

    # Now we have movie_data by recent download or cache

    # Sorting the movies by display_count
    sorted_movies = dict(sorted(movie_data["movies"].items(), key = lambda item: item[1]["display_count"], reverse = False))

    # Updating the movie_data dictionary with the sorted movies
    movie_data["movies"] = sorted_movies

    # get the movie name of the top one on the list (the one displayed the fewest times since we downloaded the dataset)
    display_movie_name = list(movie_data["movies"].keys())[0]

    if display_movie_name in movie_data["movies"]:
        movie_data["movies"][display_movie_name]["display_count"] += 1

    cache.set(SINGLE_MOVIE_CACHE_NAME, json.encode(movie_data["movies"][display_movie_name]), ttl_seconds = SINGLE_MOVIE_CACHE)
    cache.set(MOVIE_DATASET_CACHE_NAME, json.encode(movie_data), ttl_seconds = MOVIE_DATASET_CACHE)

    # return the movie that has been displayed the fewest times so far since we downloaded this dataset
    return movie_data["movies"][display_movie_name]

def main(config):
    #get the movie data for a single movie that we will display
    movie_data = get_movie_data()

    #Fonts: 10x20 5x8 6x10-rounded 6x10 6x13 CG-pixel-3x5-mono CG-pixel-4x5-mono Dina_r400-6 tb-8 tom-thumb
    font = "5x8"

    # we will add items in display_items... these will be stacked on top of each other in the display
    display_items = []

    # do we display the movie image?
    if config.bool("artwork", True):
        movie_image_url = movie_data["image"]
        artwork = http.get(movie_image_url, ttl_seconds = MOVIE_DATASET_CACHE).body()
        artwork_image = render.Image(src = artwork, width = 64, height = 32)
        display_items.append(artwork_image)

    # do we append black overlay?
    if config.bool("cc", False):
        black_box = render.Box(width = 64, height = 7, color = "#000000")
        display_items.append(black_box)
        black_box = add_padding_to_child_element(black_box, 0, 25)
        display_items.append(black_box)

    # append title
    display_items.append(render.Marquee(
        width = 64,
        child = render.Text(content = movie_data["title"], color = config.get("color_1", "#ffffff"), font = font),
    ))

    # append description
    description = movie_data["description"]
    print(description)
    description = render.Marquee(
        width = 64,
        offset_start = 40,
        child = render.Text(content = description, color = config.get("color_2", "#ffffff"), font = font),
    )
    description = add_padding_to_child_element(description, 0, 24)
    display_items.append(description)

    # Secret Code to display "Display Count" -- Make the font color black for both title and description (a crazy combo nobody wants)
    # This should help me make sure the app works as expected on the devices like it does locally
    # This will simply tell me how often this particular movie was cached as the current movie since the dataset was downloaded
    if config.get("color_1") == "#000000" and config.get("color_2") == "#000000":
        display_count_text = str(movie_data["display_count"])
        display_count_text = render.Text(content = display_count_text, color = "#ffffff", font = font)
        display_count_text = add_padding_to_child_element(display_count_text, 30, 15)
        display_items.append(display_count_text)

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
        schema.Option(
            display = "Lightning",
            value = "15",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "artwork",
                name = "Display Movie Artwork?",
                desc = "Displays the movie artwork under the marquee information of the movie coming out.",
                icon = "photoFilm",
                default = True,
            ),
            schema.Toggle(
                id = "cc",
                name = "Closed Caption Style?",
                desc = "Add black overlay over image to make text easier to read.",
                icon = "glasses",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Color(
                id = "color_1",
                name = "Movie Title Color",
                desc = "Color of the text at the top displaying the movie title.",
                icon = "brush",
                default = "#f4a306",
            ),
            schema.Color(
                id = "color_2",
                name = "Movie Information Color",
                desc = "Color of the text at the bottom displaying the movie information.",
                icon = "brush",
                default = "#ffffff",
            ),
        ],
    )
