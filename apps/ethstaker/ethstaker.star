"""
Applet: Ethstaker
Summary: Ethereum validator status
Description: Shows the recent status of provided validators on the Ethereum beacon chain.
Author: ColinCampbell
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

API_VALIDATOR_LIMIT = 10
FULL_ROW_LIMIT = 30
FULL_COLUMN_LIMIT = 11

CHECKMARK = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAFCAYAAACJmvbYAAAAAXNSR0IArs4c6QAAAERlW
ElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAA
AAB6ADAAQAAAABAAAABQAAAACrlow2AAAAIklEQVQIHWNgwAHknoX9xyoFl4AzoMrQ+Qw
wARiNYRw2CQBc5RBwfuwjGAAAAABJRU5ErkJggg==
""")

def main(config):
    statuses = validator_statuses(config)

    if statuses != None:
        status_rows = chunk_list(statuses, FULL_ROW_LIMIT)

        return render.Root(
            child = render.Padding(
                child = render.Column(
                    children = [
                        render.Padding(
                            child = render.Row(
                                expanded = True,
                                main_align = "space_between",
                                children = [
                                    render.Text("ethstaker", font = "CG-pixel-4x5-mono"),
                                    header_status(statuses),
                                ],
                            ),
                            pad = (0, 0, 0, 1),
                        ),
                        render.Column(
                            children = map(
                                status_rows,
                                lambda status_row: render.Row(
                                    children = map(status_row, lambda status: status_circle(status)),
                                ),
                            ),
                        ),
                    ],
                ),
                pad = 2,
            ),
        )
    else:
        return render.Root(
            child = render.Padding(
                child = render.Column(
                    children = [
                        render.Padding(
                            child = render.Text("ethstaker", font = "CG-pixel-4x5-mono"),
                            pad = (0, 0, 0, 1),
                        ),
                        render.WrappedText("Missing settings"),
                    ],
                ),
                pad = 2,
            ),
        )

def header_status(statuses):
    status_counts = count_list_by(statuses, lambda statuses: statuses)
    sorted_status_keys = sorted(status_counts.keys(), reverse = True, key = status_score)
    status = sorted_status_keys[0]

    if status == "missed_attestation":
        return render.Text(
            str(status_counts.get("missed_attestation")),
            font = "CG-pixel-4x5-mono",
            color = "#f00",
        )
    elif status == "attested" or status == "unknown":
        return render.Image(src = CHECKMARK)
    else:
        return render.Text("?", font = "CG-pixel-4x5-mono")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Beaconcha.in API Key",
                desc = "The API key from your Beaconcha.in account used to load your validator data",
                icon = "server",
            ),
            schema.Text(
                id = "validators",
                name = "Validators",
                desc = "The indices of the validators you'd like status updates for",
                icon = "checkToSlot",
            ),
        ],
    )

def validator_statuses(config):
    api_key = config.str("api_key")
    raw_validator_indices = config.str("validators")

    if api_key == None or raw_validator_indices == None:
        return None

    validator_indices = raw_validator_indices.replace(", ", ",").split(",")
    loaded_slot_statuses = combined_validator_statuses(api_key, validator_indices)

    cache_key = slot_statuses_cache_key(raw_validator_indices)
    oldest_loaded_slot = loaded_slot_statuses[0][0]
    cached_slot_statuses = load_cached_slot_statuses(oldest_loaded_slot, cache_key)

    all_slot_statuses = combine_lists(cached_slot_statuses, loaded_slot_statuses)

    status_limit = FULL_ROW_LIMIT * FULL_COLUMN_LIMIT
    slot_status_count = len(all_slot_statuses)
    slot_status_drop_count = slot_status_count - status_limit

    slot_statuses = all_slot_statuses[slot_status_drop_count:] if slot_status_drop_count > 0 else all_slot_statuses
    cache.set(cache_key, json.encode(slot_statuses), ttl_seconds = 600)

    empty_status_length = status_limit - len(slot_statuses)
    return combine_lists(
        fill_list(empty_status_length, "empty"),
        map(slot_statuses, lambda slot_status: slot_status[1]),
    )

def load_cached_slot_statuses(older_than_slot, cache_key):
    encoded = cache.get(cache_key)
    decoded = json.decode(encoded) if encoded != None else []
    tuples = map(decoded, lambda slot_status: (slot_status[0], slot_status[1]))
    return filter(tuples, lambda slot_status: slot_status[0] < older_than_slot)

def combined_validator_statuses(api_key, validator_indices):
    validator_chunks = chunk_list(validator_indices, API_VALIDATOR_LIMIT)
    slot_statuses = reduce(
        validator_chunks,
        [],
        lambda acc, chunk: combine_lists(
            acc,
            load_validator_slot_statuses(api_key, chunk),
        ),
    )
    merged_slot_lookup = dict_from_items_by(slot_statuses, choose_status)
    return sorted_items(merged_slot_lookup)

def load_validator_slot_statuses(api_key, validator_indices):
    indices_part = ",".join(validator_indices)
    url = "https://beaconcha.in/api/v1/validator/{0}/attestations?apikey={1}".format(indices_part, api_key)
    json = api_response(url)

    slot_attestations = []
    most_recent_slot_attestations_by_validator_index = {}

    for attestion_data in json["data"]:
        validator_index = str(int(attestion_data["validatorindex"]))
        attestation_slot = int(attestion_data["attesterslot"])
        raw_status = int(attestion_data["status"])

        most_recent_slot_attestation = most_recent_slot_attestations_by_validator_index.get(validator_index)
        if most_recent_slot_attestation == None or most_recent_slot_attestation["attestation_slot"] < attestation_slot:
            most_recent_slot_attestations_by_validator_index[validator_index] = {
                "attestation_slot": attestation_slot,
                "raw_status": raw_status,
            }

        slot_attestations.append({
            "validator_index": validator_index,
            "attestation_slot": attestation_slot,
            "raw_status": raw_status,
        })

    return map(
        slot_attestations,
        lambda slot_attestation: (
            slot_attestation["attestation_slot"],
            attestion_status(slot_attestation, most_recent_slot_attestations_by_validator_index.get(slot_attestation["validator_index"])),
        ),
    )

def attestion_status(slot_attestation, most_recent_slot_attestation):
    raw_status = slot_attestation["raw_status"]

    if raw_status == 1:
        return "attested"
    elif raw_status == 0 and most_recent_slot_attestation != None and slot_attestation["attestation_slot"] == most_recent_slot_attestation["attestation_slot"]:
        return "unknown"
    else:
        return "missed_attestation"

def choose_status(status, existing_status):
    if existing_status != None and status_score(status) < status_score(existing_status):
        return existing_status
    else:
        return status

def status_score(status):
    if status == "empty":
        return 0
    elif status == "attested":
        return 1
    elif status == "unknown":
        return 2
    else:
        return 3

def api_response(url):
    json_response = cache.get(url)
    if json_response == None:
        print("No response cached, reloading from API")
        response = http.get(url, headers = {
            "accept": "application/json",
        })
        json_response = response.json()
        cache.set(url, json.encode(json_response), ttl_seconds = 60)
    else:
        print("Found cached response, using that")
        json_response = json.decode(json_response)
    return json_response

def status_circle(status):
    return render.Padding(
        child = render.Box(
            color = status_color(status),
            width = 1,
            height = 1,
        ),
        pad = (0, 1, 1, 0),
    )

def status_color(status):
    if status == "attested":
        return "#0f0"
    elif status == "unknown":
        return "#bbb"
    elif status == "empty":
        return "#555"
    else:
        return "#f00"

# Caching

def slot_statuses_cache_key(uniquer):
    return "slot_statuses_" + uniquer

# Generic Utils

def combine_lists(*args):
    result = []
    for l in args:
        result.extend(l)
    return result

def chunk_list(items, max_items_per_chunk):
    chunks = []
    for i in range(len(items)):
        chunk_index = math.floor(i / max_items_per_chunk)

        if chunk_index == len(chunks):
            chunks.append([])

        chunks[-1].append(items[i])

    return chunks

def filter(l, f):
    return reduce(l, [], lambda acc, item: add_to_list_in_filter(acc, item, f))

def add_to_list_in_filter(acc, item, f):
    result = f(item)
    if result == True:
        acc.append(item)
    return acc

def sorted_items(d):
    items = d.items()
    return sorted(items, key = lambda item: item[0])

def dict_from_items_by(items, f):
    return reduce(items, {}, lambda lookup, item: choose_item(lookup, item, f))

def choose_item(lookup, item, f):
    key = item[0]
    existing_value = lookup.get(key)
    merged_value = f(item[1], existing_value)
    lookup[key] = merged_value
    return lookup

def count_list_by(l, f):
    result = {}
    for item in l:
        key = f(item)
        if result.get(key) == None:
            result[key] = 0
        result[key] += 1
    return result

def map(l, f):
    return [f(i) for i in l]

def reduce(list, acc, f):
    result = acc
    for i in range(len(list)):
        result = f(result, list[i])
    return result

def fill_list(n, item):
    result = []
    for _ in range(n):
        result.append(item)
    return result
