"""
Applet: Overwatch Meta
Summary: Overatch 2 Meta Statistics
Description: This app polls the Overwatch 2 Meta information from Overbuff.
Author: GeoffBarrett
"""

load("bsoup.star", "bsoup")
load("html.star", "html")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

FONT = "Dina_r400-6"
LIGHT_BLUE = "#699dff"
WHITE = "#FFFFFF"
LEFT_PAD_1PX = (1, 0, 0, 0)  # left pad by 1

# request constants
CACHE_TIMEOUT_DEFAULT = 120
DAY_IN_SECONDS = 86400
BASE_URL = "https://www.overbuff.com"
USER_AGENT = "Tidbyt"

# content regex patterns
PCT_PATTERN = "(\\d+\\.\\d+)$"
ALPHA_ALPHA_NUM_PATTERN = "([a-zA-Z]+\\d+\\.\\d+)"
CHAR_TYPE_PATTERN = "(Support|Damage|Tank)$"

PICK_RATE_START = "Pick Rate"
PICK_RATE_STOP = "Highest Win Rate"

HIGHEST_WIN_RATE_START = "Win Rate"
HIGHEST_WIN_RATE_STOP = "Highest KDA Ratio"

# the statistics types to render.
STATISTICS_TYPES = struct(win_rate = "win_rate", pick_rate = "pick_rate")

# A map of titles to render
STATISTICS_TITLE = {
    STATISTICS_TYPES.win_rate: "Win Rate",
    STATISTICS_TYPES.pick_rate: "Pick Rate",
}

# platform types
PLATFORM_TYPES = struct(console = "console", pc = "pc")

# game modes
GAME_MODES = struct(quickplay = "quickplay", competitive = "competitive")

# hero roles
ROLES = struct(
    all = "all",
    damage = "damage",
    tank = "tank",
    support = "support",
)

# time modes
TIME_WINDOWS = struct(
    all_time = "all_time",
    this_week = "week",
    this_month = "month",
    last_three_months = "3months",
    last_six_months = "6months",
    last_year = "year",
)

# skill tiers
SKILL_TIERS = struct(
    all = "all",
    bronze = "bronze",
    silver = "silver",
    gold = "gold",
    platinum = "platinum",
    diamond = "diamond",
    master = "master",
    grandmaster = "grandmaster",
)

#: The app prefers having a maximum text length of seven characters, this map is of full character
#: names to their respective shortened values.
SHORT_HERO_NAME_MAP = {
    "Wrecking Ball": "Ball",
    "Widowmaker": "Widow",
    "Reinhard": "Rein",
    "Soldier: 76": "Soldier",
    "Zenyatta": "Zen",
    "Baptiste": "Bap",
    "Doomfist": "Doom",
    "Lifeweaver": "LWeaver",
    "Brigitte": "Brig",
    "Junker Queen": "J Queen",
    "Ramattra": "Ram",
    "Torbjörn": "Torb",
    "Symmetra": "Sym",
}

def get_shortend_hero_name(hero_name):
    """Retreives the shortened hero name to minimize pixel space.

    Args:
        hero_name (str): the hero name to shorten.

    Returns:
        str: the shortend hero name
    """
    if hero_name in SHORT_HERO_NAME_MAP:
        return SHORT_HERO_NAME_MAP[hero_name]
    return hero_name

def get_cachable_data(url, timeout, params = {}, headers = {}):
    """Retreive HTML data response.

    Args:
        url (str): URL to make a get request to.
        timeout (int): the timeout duration.
        params (Dict[str, str]): parameters.
        headers (Dict[str, str]): headers.

    Returns:
        str: the HTML response as a string.
    """
    res = http.get(url = url, ttl_seconds = timeout, params = params, headers = headers)

    if res.status_code != 200:
        return ""

    return res.body()

def get_split_string_cleaned(input_text, split_pattern):
    """A helper function that splits a string and filters empty strings.

    Args:
        input_text (str): the input text to split.
        split_pattern (str): the pattern to use when splitting.

    Returns:
        List[str]: the list of split text values.
    """
    text_list = []
    for text_value in re.split(split_pattern, input_text):
        if len(text_value) > 0:
            text_list.append(text_value)
    return text_list

def split_by_percentage(input_text):
    """Splits the input text by the "%" sign.

    Args:
        input_text (str): the text to split.

    Returns:
        List[str]: the split text.
    """
    return get_split_string_cleaned(input_text, "%")

def split_by_number(input_text):
    """Splits the input text by the "%" sign.

    Args:
        input_text (str): the text to split.

    Returns:
        List[str]: the split text.
    """
    return get_split_string_cleaned(input_text, ALPHA_ALPHA_NUM_PATTERN)

def get_pick_rate_raw_list(input_text):
    """Retrieves a list of un-processed strings containing the pick-rates.

    The strings are in the following format: "{Character}{CharacterType}{PickPercentage}"

    i.e. "AnaSupport5.00"

    Args:
        input_text (str): the input text to extract the pick rates from.

    Returns:
        List[str]: the extracted pick-rates.
    """

    start_idx = input_text.rfind(PICK_RATE_START)
    if start_idx == -1:
        return []

    stop_idx = input_text.find(PICK_RATE_STOP)
    if stop_idx == -1:
        return []

    pick_rates = input_text[start_idx + len(PICK_RATE_START):stop_idx]

    return split_by_percentage(pick_rates)

def get_win_rate_raw_list(input_text):
    """Retrieves a list of un-processed strings containing the win-rates.

    The win-rates are in the following format: "{Character}{CharacterType}{WinRate}"

    i.e. "AnaSupport5.00"

    Args:
        input_text (str): the input text to extract the win rates from.

    Returns:
        List[str]: the extracted win-rates.
    """

    start_idx = input_text.rfind(HIGHEST_WIN_RATE_START)
    if start_idx == -1:
        return []

    stop_idx = input_text.find(HIGHEST_WIN_RATE_STOP)
    if stop_idx == -1:
        return []

    win_rates = input_text[start_idx + len(HIGHEST_WIN_RATE_START):stop_idx]

    return split_by_percentage(win_rates)

def parse_char_type_percentage(input_text):
    """Extract the Character - Character Type - Percentage value from text.

    This text contains the statistics in the following format:
    "{Character}{CharacterType}{PickPercentage}".

    Args:
        input_text (str): HTML text from Overbuff containing the statistics content.

    Returns:
        Optional[Tuple[str, str, str]]: an optional
            (character, character_type, statistic_value) tuple containing the statistic
            details.
    """

    # extract statistic value
    statistic_value = re.findall(PCT_PATTERN, input_text)
    if len(statistic_value) == 0:
        return None

    statistic_value = statistic_value[0]

    # extract character type
    input_text = re.split(statistic_value, input_text)[0]
    character_type = re.findall(CHAR_TYPE_PATTERN, input_text)
    if len(character_type) == 0:
        return None

    character_type = character_type[0]

    # extract the character's name
    character = re.split(character_type, input_text)[0]
    return (character, character_type, statistic_value)

def make_overbuff_get_request(
        parameters = {},
        endpoint = "meta",
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieve a BeautifulSoup object instance ingesting the response from overbuff.com.

    Args:
        parameters (Optional[Dict[str, str]]): the request parameters. Defaults to None.
        endpoint (str, optional): the overbuff endpoint. Defaults to "meta".
        timeout (int): the timeout to cache the response.

    Returns:
        str: request body text.
    """
    headers = {"User-Agent": USER_AGENT}  # Will receive a 429 without a user-agent specified
    url = "{}/{}".format(BASE_URL, endpoint)
    response_html = get_cachable_data(url, timeout, params = parameters, headers = headers)

    return response_html

def get_overbuff_soup_object(
        parameters = {},
        endpoint = "meta",
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieve a BeautifulSoup object instance ingesting the response from overbuff.com.

    Args:
        parameters (Optional[Dict[str, str]]): the request parameters. Defaults to None.
        endpoint (str, optional): the overbuff endpoint. Defaults to "meta".
        timeout (int): the timeout to cache the response.

    Returns:
        SoupNode: the SoupNode instance.
    """

    response = make_overbuff_get_request(
        parameters = parameters,
        endpoint = endpoint,
        timeout = timeout,
    )
    soup = bsoup.parseHtml(response)
    return soup

def get_overbuff_text(
        platform = PLATFORM_TYPES.pc,
        game_mode = None,
        role = None,
        time_window = None,
        skill_tier = None,
        endpoint = "meta",
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieves the text contents from Overbuff's end-point.

    Args:
        platform (str, optional): the platform to extract the data for. Defaults to "pc".
        game_mode (str, optional): the game-mode to extract the data for. Defaults to None.
        role (str, optional): the hero role to extract the data for. Defaults to None.
        time_window (str, optional): the time-window to filter the data by. Defaults to None.
        skill_tier (str, optional): the skill tier to filter the data by. Defaults to None.
        endpoint (str, optional): the overbuff endpoint to retrieve text from. Defaults to "meta".
        timeout (int): the timeout to cache the response.

    Returns:
        str: the text content in the "https://www.overbuff.com/{endpoint}" page.
    """

    # initialize the query parameters (platform is not optional)
    params = {"platform": platform}

    # add the game mode if there is one
    if game_mode:
        params["gameMode"] = game_mode

    # add the hero role
    if role != None and role != ROLES.all:
        params["role"] = role

    # add a time window if there is one (and it isn't all time)
    if time_window != None and time_window != TIME_WINDOWS.all_time:
        params["timeWindow"] = time_window

    # add a skill tier if there is one (and it isn't all)
    if skill_tier != None and skill_tier != SKILL_TIERS.all:
        params["skillTier"] = skill_tier

    response = make_overbuff_get_request(
        parameters = params,
        endpoint = endpoint,
        timeout = timeout,
    )

    return html(response).text()

def get_heroes():
    """Retrieve a list of heroes.

    Returns:
        List[str]: The Overwatch heroes.
    """
    heroes = []
    soup = get_overbuff_soup_object(
        parameters = {},
        endpoint = "heroes",
        timeout = DAY_IN_SECONDS,
    )
    for link in soup.find_all("a"):
        if "/heroes/" in str(link):
            hero = link.get_text()
            if not hero:
                continue
            heroes.append(hero)
    return heroes

def find_image_with_size(image_sources, max_width = 50):
    """Retrieves the image source that does not exceed the `max_width` value.

    Args:
        image_sources (str): a string containing comma separated image sources.
        max_width (float, optional): the maximum width (in pixels). Defaults to 50.

    Returns:
        Optional[str]: the image source.
    """
    image_source = None
    image_width = 0

    images = get_split_string_cleaned(image_sources, ",")
    for image in images:
        image_components = get_split_string_cleaned(image, " ")
        if len(image_components) != 2:
            continue
        (image_src, image_size) = image_components
        width = float(get_split_string_cleaned(image_size, "w")[0])
        if width <= max_width:
            if width > image_width:
                image_width = width
                image_source = image_src
    return image_source

def get_hero_image_map(
        heroes = None,
        max_width = 200):
    """Retrieve a dictionary mapping the hero names to their respective images.

    Args:
        heroes (Optional[List[str]], optional): an optional list of hero names. Defaults to None.
            If None, the list of hero names will be retrieved.
        max_width (int, optional): the maximum image width. Defaults to 50.

    Returns:
        Dict[str, str]: a map of hero name to image.
    """

    hero_image_map = {}
    if heroes == None:
        # retrieve the list of heroes
        heroes = get_heroes()

    soup = get_overbuff_soup_object(
        parameters = {},
        endpoint = "heroes",
    )

    for image in soup.find_all("img"):
        image_attrs = image.attrs()
        hero_name = image_attrs.get("alt")

        if not hero_name:
            continue

        if hero_name not in heroes:
            continue

        hero_image = find_image_with_size(image_attrs.get("srcset"), max_width = max_width)
        hero_image_map[hero_name] = "{}{}".format(BASE_URL, hero_image)

    return hero_image_map

def render_error(error_message, width = 64):
    return render.Root(child = render.WrappedText(error_message, width = width))

def render_hero_sections(title, sections_data, image_size = 18):
    """Render the hero statistics sections.

    Args:
        title (str): the title of the statistics being rendered.
        sections_data (List[struct]): a list of section structs containing the statistics
            to render.
        image_size (int, optional): the image size of the hero.

    Returns:
        Root: a root render instance.
    """

    if len(sections_data) == 0:
        return render_error("Unable to retrieve the '{}' statistics.".format(title))

    title_text = render.Padding(
        pad = LEFT_PAD_1PX,  # left pad by 1
        child = render.Text(content = title, color = LIGHT_BLUE, font = FONT),
    )

    # build the sections
    sections = []
    for section_data in sections_data:
        hero_text = render.Column(
            children = [
                render.Text(
                    content = get_shortend_hero_name(section_data.hero),
                    color = WHITE,
                    font = FONT,
                ),
                render.Text(
                    content = "{}%".format(section_data.statistic),
                    color = WHITE,
                    font = FONT,
                ),
            ],
        )

        hero_image = render.Padding(
            pad = LEFT_PAD_1PX,  # left pad by 1
            child = render.Image(
                src = section_data.hero_image,
                width = image_size,
                height = image_size,
            ),
        )

        # the hero contents
        hero_row = render.Row(
            children = [hero_image, hero_text],
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
        )

        # add the title to the hero section to be rendered
        hero_row_with_title = render.Column(
            children = [
                title_text,
                hero_row,
            ],
        )

        sections.append(hero_row_with_title)

    # render the sections
    seq = render.Sequence(children = sections)

    return render.Root(
        child = seq,
        delay = 2000,  # ms between frames
        show_full_animation = True,
    )

def render_statistics(
        statistic = STATISTICS_TYPES.win_rate,
        platform = PLATFORM_TYPES.pc,
        game_mode = GAME_MODES.quickplay,
        role = ROLES.all,
        time_window = TIME_WINDOWS.last_three_months,
        skill_tier = SKILL_TIERS.all):
    """Renders the hero statistics.

    Args:
        statistic (str, optional): an optional statistic to render. Defaults to "win_rate".
        platform (str, optional): an optional platform to query statistics from. Defaults to "pc".
        game_mode (str, optional): an optional game mode to query statistics from. Defaults to
            "quickplay".
        role (str, optional): the hero role to extract the data for. Defaults to "all".
        time_window (str, optional): an optional time window to query statistics from. Defaults to
            "3months".
        skill_tier (str, optional): an optional skill tier to query statistics from. Defaults to
            "all".

    Returns:
        Root: a root render instance.
    """

    # retreive the HTML text
    meta_text = get_overbuff_text(
        platform = platform,
        game_mode = game_mode,
        role = role,
        time_window = time_window,
        skill_tier = skill_tier,
        endpoint = "meta",
    )

    # retrieve a map of hero name to hero icon
    hero_image_map = get_hero_image_map()

    if statistic == STATISTICS_TYPES.pick_rate:
        # list of pick rates (hero_name, hero_class, pick_rate)
        statistics_list = get_pick_rate_raw_list(meta_text)
    elif statistic == STATISTICS_TYPES.win_rate:
        # list of win rates (hero_name, hero_class, win_rate)
        statistics_list = get_win_rate_raw_list(meta_text)
    else:
        return render_error("Received unsupported statistic: '{}'.".format(statistic))

    if len(statistics_list) == 0:
        return render_error("Unable to retrieve the '{}' statistic.".format(statistic))

    title = STATISTICS_TITLE[statistic]
    sections = []

    # add child contents (Hero Image - Hero Name - Statistic %)
    for stat in statistics_list:
        if len(stat) == 3:
            continue

        stat_details = parse_char_type_percentage(stat)
        if stat_details == None or len(stat_details) != 3:
            continue

        (hero_name, _, stat_value) = stat_details
        if hero_name not in hero_image_map:
            continue

        image_url = hero_image_map[hero_name]
        image_rep = http.get(image_url, ttl_seconds = DAY_IN_SECONDS)

        if image_rep.status_code != 200:
            continue

        section_data = struct(
            hero = hero_name,
            hero_image = image_rep.body(),
            statistic = stat_value,
        )

        sections.append(section_data)

    return render_hero_sections(title, sections)

def main(config):
    """The app entry point.

    Args:
        config (AppletConfig): the user configured settings for the app.
    """
    return render_statistics(
        statistic = config.get("statistic", STATISTICS_TYPES.win_rate),
        platform = config.get("platform", PLATFORM_TYPES.pc),
        game_mode = config.get("game_mode", GAME_MODES.quickplay),
        role = config.get("role", ROLES.all),
        skill_tier = config.get("skill_tier", SKILL_TIERS.all),
        time_window = config.get("time_window", TIME_WINDOWS.last_three_months),
    )

def get_schema():
    """Retrieve the app schema.

    Returns:
        Schema: the app schema.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "statistic",
                name = "Hero Statistic",
                desc = "The hero statistics to display.",
                icon = "percent",
                options = [
                    schema.Option(display = "Win Rate", value = STATISTICS_TYPES.win_rate),
                    schema.Option(display = "Pick Rate", value = STATISTICS_TYPES.pick_rate),
                ],
                default = STATISTICS_TYPES.win_rate,
            ),
            schema.Dropdown(
                id = "platform",
                name = "Platform",
                desc = "The platform to filter statistics by.",
                icon = "desktop",
                options = [
                    schema.Option(display = "PC", value = PLATFORM_TYPES.pc),
                    schema.Option(display = "Console", value = PLATFORM_TYPES.console),
                ],
                default = PLATFORM_TYPES.pc,
            ),
            schema.Dropdown(
                id = "game_mode",
                name = "Game Mode",
                desc = "The game mode to filter statistics by.",
                icon = "gamepad",
                options = [
                    schema.Option(display = "Quickplay", value = GAME_MODES.quickplay),
                    schema.Option(display = "Competitive", value = GAME_MODES.competitive),
                ],
                default = GAME_MODES.quickplay,
            ),
            schema.Dropdown(
                id = "role",
                name = "Role",
                desc = "The hero role to filter statistics by.",
                icon = "userShield",
                options = [
                    schema.Option(display = "All", value = ROLES.all),
                    schema.Option(display = "Damage", value = ROLES.damage),
                    schema.Option(display = "Tank", value = ROLES.tank),
                    schema.Option(display = "Support", value = ROLES.support),
                ],
                default = ROLES.all,
            ),
            schema.Dropdown(
                id = "skill_tier",
                name = "Skill Tier",
                desc = "The skill tier to filter statistics by.",
                icon = "rankingStar",
                options = [
                    schema.Option(display = "All", value = SKILL_TIERS.all),
                    schema.Option(display = "Bronze", value = SKILL_TIERS.bronze),
                    schema.Option(display = "Silver", value = SKILL_TIERS.silver),
                    schema.Option(display = "Gold", value = SKILL_TIERS.gold),
                    schema.Option(display = "Platinum", value = SKILL_TIERS.platinum),
                    schema.Option(display = "Diamond", value = SKILL_TIERS.diamond),
                    schema.Option(display = "Master", value = SKILL_TIERS.master),
                    schema.Option(display = "Grandmaster", value = SKILL_TIERS.grandmaster),
                ],
                default = SKILL_TIERS.all,
            ),
            schema.Dropdown(
                id = "time_window",
                name = "Time Window",
                desc = "The time window to filter statistics by.",
                icon = "clock",
                options = [
                    schema.Option(display = "All Time", value = TIME_WINDOWS.all_time),
                    schema.Option(display = "This Week", value = TIME_WINDOWS.this_week),
                    schema.Option(display = "This Month", value = TIME_WINDOWS.this_month),
                    schema.Option(display = "Last 3 Months", value = TIME_WINDOWS.last_three_months),
                    schema.Option(display = "Last 6 Months", value = TIME_WINDOWS.last_six_months),
                    schema.Option(display = "Last Year", value = TIME_WINDOWS.last_year),
                ],
                default = TIME_WINDOWS.last_three_months,
            ),
        ],
    )
