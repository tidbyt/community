"""
Applet: LightningNode
Summary: Shows BTC Lightning stats
Description: Shows Bitcoin Lightning Network statistics, or statistics of your own Lightning node.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MEMPOOL_SPACE_API_URL_PREFIX = "https://mempool.space/api/v1"

DEFAULT_INTERVAL = "latest"
DEFAULT_NETWORK_DISPLAY = "alias"
DEFAULT_NODE_DISPLAY = "nodes"
DEFAULT_SECONDARY_DISPLAY = "empty"
DEFAULT_WILL_ANIMATE = True

SATS_IN_BITCOIN = 100000000

ROOT_DELAY = 1200
ROOT_MAX_AGE = 60 * 60 * 6

LABEL_COLOR = "#fff9"
LABEL_FONT = "tb-8"

def get_data(url, ttl_seconds = 60 * 60 * 6):
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Mempool.space request failed with status %d @ %s", response.status_code, url)
    return response

def get_network_data(interval = "latest"):
    url = "{}/lightning/statistics/{}".format(MEMPOOL_SPACE_API_URL_PREFIX, interval)
    return get_data(url).json()

def get_node_data(node_pubkey):
    if len(node_pubkey) == 66:
        url = "{}/lightning/nodes/{}".format(MEMPOOL_SPACE_API_URL_PREFIX, node_pubkey)
        return get_data(url).json()
    return {}

def validate_pubkey(node_pubkey):
    is_hex = len(re.findall(r"0[0-9a-fA-F]{65}", node_pubkey)) == 1
    return is_hex

def render_animation(values):
    frames = []
    for stat in values.values():
        frames.append(
            render.Column(
                children = [
                    render.Text(
                        content = stat[0],
                        font = LABEL_FONT,
                        color = LABEL_COLOR,
                    ),
                    render.Text(stat[1]),
                ],
            ),
        )
    return render.Column(
        children = [render.Animation(children = frames)],
        main_align = "space_around",
        expanded = True,
    )

def render_row(values, key):
    return render.Column(
        children = [
            render.Text(
                content = values[key][0],
                font = LABEL_FONT,
                color = LABEL_COLOR,
            ),
            render.Text(values[key][1]),
        ],
    )

def populate_with_network_stats(network_data_primary, network_data_secondary, interval = DEFAULT_INTERVAL, will_animate = DEFAULT_WILL_ANIMATE):
    has_single_row = network_data_secondary == "empty"
    data = get_network_data(interval)["latest"]
    values = {
        "nodes": ["nodes", humanize.comma(int(data["node_count"]))],
        "channels": ["channels", humanize.comma(int(data["channel_count"]))],
        "capacity": ["capacity", humanize.comma(int(int(data["total_capacity"]) / SATS_IN_BITCOIN)) + " BTC"],
        "average": ["average", "{} sats".format(humanize.comma(int(data["avg_capacity"])))],
        "median": ["median", "{} sats".format(humanize.comma(int(data["med_capacity"])))],
        "avg_fee_rate": ["avg fee rate", "{} ppm".format(humanize.comma(int(data["avg_fee_rate"])))],
        "avg_base_fee": ["avg base fee", "{} mSats".format(humanize.comma(int(data["avg_base_fee_mtokens"])))],
        "empty": ["", ""],
    }

    if will_animate:
        return render_animation(values)

    children = [
        render_row(values, network_data_primary)
    ]

    if not has_single_row:
        children.append(
            render_row(values, network_data_primary)
        )

    return render.Column(
        children = children,
        expanded = True,
        main_align = "center",
    )

def populate_with_node_stats(node_pubkey, node_data_primary, node_data_secondary, will_animate = DEFAULT_WILL_ANIMATE):
    has_single_row = node_data_secondary == "empty"
    data = get_node_data(node_pubkey)
    values = {
        "alias": ["alias", data["alias"]],
        "capacity": ["capacity", humanize.comma(int(int(data["capacity"]) / (SATS_IN_BITCOIN / 100)) / 100) + " BTC"],
        "channels": ["channels", humanize.comma(int(data["active_channel_count"]))],
        "sunrise": ["sunrise", humanize.time(time.from_timestamp(int(data["first_seen"])))],
        "updated": ["updated", humanize.time(time.from_timestamp(int(data["updated_at"])))],
        "empty": ["", ""],
    }

    if will_animate:
        return render_animation(values)

    children = [
        render_row(values, node_data_primary)
    ]

    if not has_single_row:
        children.append(
            render_row(values, node_data_secondary)
        )

    return render.Column(
        children = children,
        expanded = True,
        main_align = "center",
    )

def main(config):
    node_pubkey = config.str("node_pubkey", "")
    interval = config.str("interval", DEFAULT_INTERVAL)
    network_data_primary = config.str("network_data_primary", DEFAULT_NETWORK_DISPLAY)
    network_data_secondary = config.str("network_data_secondary", DEFAULT_SECONDARY_DISPLAY)
    node_data_primary = config.str("node_data_primary", DEFAULT_NODE_DISPLAY)
    node_data_secondary = config.str("node_data_secondary", DEFAULT_SECONDARY_DISPLAY)
    will_animate = config.bool("will_animate", DEFAULT_WILL_ANIMATE)

    has_pubkey_not_configured = len(node_pubkey) == 0
    is_valid_pubkey = validate_pubkey(node_pubkey)

    # Show lightning network stats
    if has_pubkey_not_configured:
        return render.Root(
            delay = ROOT_DELAY,
            show_full_animation = True,
            max_age = ROOT_MAX_AGE,
            child = populate_with_network_stats(network_data_primary, network_data_secondary, interval, will_animate),
        )

    # Show node specific stats
    if not has_pubkey_not_configured and is_valid_pubkey:
        return render.Root(
            delay = ROOT_DELAY,
            show_full_animation = True,
            max_age = ROOT_MAX_AGE,
            child = populate_with_node_stats(node_pubkey, node_data_primary, node_data_secondary, will_animate),
        )

    # Show error message to provide a valid node pubkey (or it should be empty)
    return render.Root(
        child = render.WrappedText("Error: invalid node pubkey provided")
    )

def schema_handler(node_pubkey):
    interval_options = [
        schema.Option(display = "Latest", value = "latest"),
        schema.Option(display = "1 day", value = "1d"),
        schema.Option(display = "3 days", value = "3d"),
        schema.Option(display = "1 week", value = "1w"),
        schema.Option(display = "1 month", value = "1m"),
        schema.Option(display = "6 month", value = "6m"),
        schema.Option(display = "1 year", value = "1y"),
        schema.Option(display = "2 year", value = "2y"),
        schema.Option(display = "3 year", value = "3y"),
    ]

    node_data_options = [
        schema.Option(display = "Alias", value = "alias"),
        schema.Option(display = "Capacity", value = "capacity"),
        schema.Option(display = "Channels", value = "channels"),
        schema.Option(display = "Sunrise", value = "sunrise"),
        schema.Option(display = "Updated", value = "updated"),
        schema.Option(display = "-empty-", value = "empty"),
    ]

    network_data_options = [
        schema.Option(display = "Nodes", value = "nodes"),
        schema.Option(display = "Channels", value = "channels"),
        schema.Option(display = "Capacity", value = "capacity"),
        schema.Option(display = "Average", value = "average"),
        schema.Option(display = "Median", value = "median"),
        schema.Option(display = "Avg Fee Rate", value = "avg_fee_rate"),
        schema.Option(display = "Avg Base Fee", value = "avg_base_fee"),
        schema.Option(display = "-empty-", value = "empty"),
    ]

    if node_pubkey:
        return [
            schema.Dropdown(
                id = "node_data_primary",
                name = "Top row",
                desc = "Choose what to display in the top row.",
                default = node_data_options[0].value,
                options = node_data_options,
                icon = "1",
            ),
            schema.Dropdown(
                id = "node_data_secondary",
                name = "Bottom row",
                desc = "Choose what to display in the bottom row.",
                default = node_data_options[1].value,
                options = node_data_options,
                icon = "2",
            ),
        ]

    return [
        schema.Dropdown(
            id = "interval",
            name = "Interval",
            desc = "Shows network-wide stats of this interval period.",
            default = interval_options[0].value,
            options = interval_options,
            icon = "clock",
        ),
        schema.Dropdown(
            id = "network_data_primary",
            name = "Top row",
            desc = "Choose what to display in the top row.",
            default = network_data_options[0].value,
            options = network_data_options,
            icon = "1",
        ),
        schema.Dropdown(
            id = "network_data_secondary",
            name = "Bottom row (optional)",
            desc = "Choose what to display in the bottom row. Set 'empty' to show only the top row.",
            default = network_data_options[1].value,
            options = network_data_options,
            icon = "2",
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "node_pubkey",
                name = "Node pubkey (optional)",
                desc = "Your own node's pubkey. Leave empty to get global lightning stats.",
                icon = "key",
            ),
            schema.Generated(
                id = "generated",
                source = "node_pubkey",
                handler = schema_handler,
            ),
            schema.Toggle(
                id = "will_animate",
                name = "Animating all stats?",
                desc = "Should it animate the statistics (will override top- and bottom row settings).",
                icon = "clapperboard",
                default = True,
            )
        ],
    )
