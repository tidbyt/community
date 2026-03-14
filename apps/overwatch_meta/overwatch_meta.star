"""
Applet: Overwatch Meta
Summary: Overatch 2 Meta Statistics
Description: This app polls the Overwatch 2 Meta information from Blizzard.
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
BASE_URL = "https://overwatch.blizzard.com"
USER_AGENT = "Tidbyt"

# content regex patterns
PCT_PATTERN = "((100(?:\\.0+)?)|([0-9]?[0-9](?:\\.[0-9]+)?))$"

ALPHA_ALPHA_NUM_PATTERN = "([a-zA-Z]+\\d+\\.\\d+)"

RATES_START = "Pick RateWin Rate"
RATES_STOP = "Frequently"

# the statistics types to render.
STATISTICS_TYPES = struct(win_rate = "win_rate", pick_rate = "pick_rate")

# A map of titles to render
STATISTICS_TITLE = {
    STATISTICS_TYPES.win_rate: "Win Rate",
    STATISTICS_TYPES.pick_rate: "Pick Rate",
}

#: The endpoint for blizzard.com to extract the pick / win rates from.
RATES_ENDPONT = "en-us/rates/"

#: the endpoint for blizzard.com to extract hero information from.
HEROES_ENDPOINT = "en-us/heroes/"

#: text used to extract the list of heroes.
HEROES = "/heroes/"

# platform types
PLATFORM_TYPES = struct(console = "Console", pc = "PC")

# game modes
GAME_MODES = struct(quickplay = "0", competitive = "1")

# regions
REGION = struct(americas = "Americas", asia = "Asia", europe = "Europe")

# hero roles
ROLES = struct(
    all = "all",
    damage = "damage",
    tank = "tank",
    support = "support",
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
    "Reinhardt": "Rein",
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

def get_rates_list(input_text, statistic):
    """Retreives a list of un-processed strings containing the pick and win rates.

    The strings are following format: "{Character}{WinRate}{PickRate}"

    i.e. "Ana50.0%50.0%"

    Args:
        input_text (str): the input text to extract the rates from.
        statistic (str): the statistic value to extract (win rate or pick rate).

    Returns:
        List[Tuple[str, str]]: a list of tuples in the following format:
            ("character_name", "statistic_value")
    """
    start_idx = input_text.rfind(RATES_START)
    if start_idx == -1:
        return []

    stop_idx = input_text.find(RATES_STOP)
    if stop_idx == -1:
        return []

    rates = input_text[start_idx + len(RATES_START):stop_idx]

    # If there's not enough data, the rate will be "--"
    # replace these with "0.0%"
    rates = rates.replace("--", "0.0%")
    rates_split = split_by_percentage(rates)

    # `rates_split` is structured in the following format:
    # ["{Char1}{WinRateChar1}", "{PickRateChar1}", "{Char2}{WinRateChar2}", ...]
    # Lets join every other list item together.
    result_rates = []
    for idx in range(0, len(rates_split) - 1):
        if idx % 2 == 1:
            continue

        parse_results = parse_char_type_percentage(rates_split[idx])
        if parse_results == None:
            continue

        (character_name, win_rate) = parse_results
        pick_rate = rates_split[idx + 1]

        if statistic == STATISTICS_TYPES.pick_rate:
            result_rates.append((character_name, pick_rate))
        elif statistic == STATISTICS_TYPES.win_rate:
            result_rates.append((character_name, win_rate))
        else:
            return render_error("Received unsupported statistic: '{}'.".format(statistic))

    # the values are not sorted... sort them.
    sorted_rates = sorted(result_rates, key = lambda x: float(x[1]), reverse = True)

    return sorted_rates

def parse_char_type_percentage(input_text):
    """Extract the Character - Percentage value from text.

    This text contains the statistics in the following format:
    "{Character}{WinRate}".

    Args:
        input_text (str): HTML text from Overbuff containing the statistics content.

    Returns:
        Optional[Tuple[str, str]]: an optional
            (character, win_rate) tuple containing the statistic
            details.
    """

    # extract statistic value
    statistic_values = re.findall(PCT_PATTERN, input_text)
    if len(statistic_values) != 1:
        return None

    win_rate = statistic_values[0]

    # extract the character's name
    character = input_text[:len(input_text) - len(win_rate)]
    return (character, win_rate)

def make_blizzard_get_request(
        parameters = {},
        endpoint = RATES_ENDPONT,
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieve a BeautifulSoup object instance ingesting the response from blizzard.com.

    Args:
        parameters (Optional[Dict[str, str]]): the request parameters. Defaults to None.
        endpoint (str, optional): the blizzard endpoint. Defaults to "en-us/rates/".
        timeout (int): the timeout to cache the response.

    Returns:
        str: request body text.
    """
    headers = {"User-Agent": USER_AGENT}  # Will receive a 429 without a user-agent specified
    url = "{}/{}".format(BASE_URL, endpoint)
    response_html = get_cachable_data(url, timeout, params = parameters, headers = headers)

    return response_html

def get_blizzard_soup_object(
        parameters = {},
        endpoint = RATES_ENDPONT,
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieve a BeautifulSoup object instance ingesting the response from blizzard.com.

    Args:
        parameters (Optional[Dict[str, str]]): the request parameters. Defaults to None.
        endpoint (str, optional): the blizzard endpoint. Defaults to "en-us/rates/".
        timeout (int): the timeout to cache the response.

    Returns:
        SoupNode: the SoupNode instance.
    """

    response = make_blizzard_get_request(
        parameters = parameters,
        endpoint = endpoint,
        timeout = timeout,
    )
    soup = bsoup.parseHtml(response)
    return soup

def get_blizzard_text(
        platform = PLATFORM_TYPES.pc,
        game_mode = GAME_MODES.quickplay,
        skill_tier = SKILL_TIERS.all,
        region = REGION.americas,
        endpoint = RATES_ENDPONT,
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieves the text contents from Blizzard's end-point.

    Args:
        platform (str, optional): the platform to extract the data for. Defaults to "pc".
        game_mode (str, optional): the game-mode to extract the data for. Defaults to None.
        skill_tier (str, optional): the skill tier to filter the data by. Defaults to None.
        region (str, optional): the region to filter the data by. Defaults to None.
        endpoint (str, optional): the blizzard endpoint to retrieve text from. Defaults to "en-us/rates/".
        timeout (int): the timeout to cache the response.

    Returns:
        str: the text content in the "https://overwatch.blizzard.com/{endpoint}" page.
    """

    # initialize the query parameters (platform is not optional)
    # note: changing the `role` parameter still returns the full list of statistics. This
    # is a UI filter.
    params = {"input": platform, "map": "all-maps", "role": "All"}

    if region:
        params["region"] = region.title()

    # add the game mode if there is one
    if game_mode:
        params["rq"] = game_mode

        if game_mode == GAME_MODES.quickplay:
            skill_tier = SKILL_TIERS.all

    # add a skill tier if there is one (and it isn't all)
    if skill_tier:
        params["tier"] = skill_tier.title()

    response = make_blizzard_get_request(
        parameters = params,
        endpoint = endpoint,
        timeout = timeout,
    )

    return html(response).text()

def get_hero_name_from_blz_card(hero_card):
    """Retrieve the hero name from the blz-card.

    Args:
        hero_card (SoupNode): the soup node
            for the ("blz-card") type.

    Returns:
        Optional[str]: The Overwatch hero name.
    """
    hero_name_text = hero_card.find("h2")
    hero_name = None
    if hero_name_text != None:
        hero_name = hero_name_text.get_text()
    return hero_name

def get_hero_role_from_blz_card(hero_card):
    """Retrieve the hero role from the blz-card.

    Args:
        hero_card (SoupNode): the soup node
            for the ("blz-card") type.

    Returns:
        Optional[str]: The Overwatch hero role.
    """
    blz_icon = hero_card.find("blz-icon")
    blz_icon_text = str(blz_icon)

    role = None
    if ROLES.support in blz_icon_text:
        role = ROLES.support
    elif ROLES.damage in blz_icon_text:
        role = ROLES.damage
    elif ROLES.tank in blz_icon_text:
        role = ROLES.tank
    return role

def get_heroes():
    """Retrieve a map of heroe names to roles.

    Returns:
        Dict[str, str]: The Overwatch heroes mapped to their roles.
    """
    heroes = {}
    soup = get_blizzard_soup_object(
        parameters = {},
        endpoint = HEROES_ENDPOINT,
        timeout = DAY_IN_SECONDS,
    )
    for hero_card in soup.find_all("blz-card"):
        hero_name = get_hero_name_from_blz_card(hero_card)
        hero_role = get_hero_role_from_blz_card(hero_card)
        if hero_name == None or hero_role == None:
            continue

        heroes[hero_name] = hero_role
    return heroes

def get_hero_image_map(heroes = None):
    """Retrieve a dictionary mapping the hero names to their respective images.

    Args:
        heroes (Optional[List[str]], optional): an optional list of hero names. Defaults to None.
            If None, the list of hero names will be retrieved.

    Returns:
        Dict[str, str]: a map of hero name to image.
    """

    hero_image_map = {}
    if heroes == None:
        # retrieve the list of heroes
        heroes = get_heroes()

    soup = get_blizzard_soup_object(
        parameters = {},
        endpoint = HEROES_ENDPOINT,
    )

    for hero_card in soup.find_all("blz-card"):
        image = hero_card.find("blz-image")
        if image == None:
            continue

        hero_name = get_hero_name_from_blz_card(hero_card)
        if hero_name == None:
            continue

        if hero_name not in heroes:
            continue

        image_attrs = image.attrs()
        hero_image_map[hero_name] = image_attrs.get("src")

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
        skill_tier = SKILL_TIERS.all,
        region = REGION.americas,
        max_length = 5):
    """Renders the hero statistics.

    Args:
        statistic (str, optional): an optional statistic to render. Defaults to "win_rate".
        platform (str, optional): an optional platform to query statistics from. Defaults to "pc".
        game_mode (str, optional): an optional game mode to query statistics from. Defaults to
            "quickplay".
        role (str, optional): the hero role to extract the data for. Defaults to "all".
        skill_tier (str, optional): an optional skill tier to query statistics from. Defaults to
            "all".
        region (str, optional): an optional region to filter the statistics by. Defaults to "Americas".
        max_length (int): the integer for the max number of hero statistics to show.

    Returns:
        Root: a root render instance.
    """

    # retreive the HTML text
    meta_text = get_blizzard_text(
        platform = platform,
        game_mode = game_mode,
        skill_tier = skill_tier,
        region = region,
        endpoint = RATES_ENDPONT,
    )

    # retrieve the heroes
    heroes = get_heroes()

    # retrieve a map of hero name to hero icon
    hero_image_map = get_hero_image_map(heroes)

    statistics_list = get_rates_list(meta_text, statistic)

    if len(statistics_list) == 0:
        return render_error("Unable to retrieve the '{}' statistic.".format(statistic))

    title = STATISTICS_TITLE[statistic]
    sections = []

    # add child contents (Hero Image - Hero Name - Statistic %)
    for stat_details in statistics_list:
        if len(sections) >= max_length:
            break

        if stat_details == None or len(stat_details) != 2:
            continue

        (hero_name, stat_value) = stat_details
        if hero_name not in hero_image_map:
            continue

        if hero_name not in heroes:
            continue

        # filter by hero role
        if role != ROLES.all:
            hero_role = heroes[hero_name]
            if role != hero_role:
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
        region = config.get("regions", REGION.americas),
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
                id = "regions",
                name = "Regions",
                desc = "The region filter statistics by.",
                icon = "globe",
                options = [
                    schema.Option(display = "Americas", value = REGION.americas),
                    schema.Option(display = "Asia", value = REGION.asia),
                    schema.Option(display = "Europe", value = REGION.europe),
                ],
                default = REGION.americas,
            ),
        ],
    )
