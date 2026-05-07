"""
Applet: 50 States Visited
Summary: Visited states map
Description: Toggle U.S. states by abbreviation and render a recognizable 64x32 LED map with Alaska and Hawaii insets.
Author: apollonyc
"""

load("render.star", "render")
load("schema.star", "schema")

GRID_WIDTH = 64
GRID_HEIGHT = 32
BACKGROUND = "#000000"
DEFAULT_COLOR_MODE = "multicolor"

# The mainland coordinate runs use the full 64x32 canvas but leave the lower
# left and bottom-center open for the Alaska and Hawaii insets. Each run is
# [y, x_start, x_end], inclusive, and expands to individual LED pixels.
# The mainland was rasterized as a real state silhouette, then simplified into
# readable runs so the continental U.S. reads as a map before it reads as data.
STATE_RUNS = {
    "AL": [
        [18, 42, 44],
        [19, 42, 44],
        [20, 42, 44],
        [21, 42, 45],
        [22, 42, 44],
        [23, 42, 42],
    ],
    "AK": [
        [23, 8, 10],
        [24, 6, 11],
        [25, 5, 12],
        [26, 3, 12],
        [27, 2, 12],
        [28, 4, 12],
        [29, 5, 12],
        [30, 4, 7],
        [30, 10, 12],
        [31, 2, 4],
        [31, 11, 12],
    ],
    "AZ": [
        [15, 13, 16],
        [16, 12, 17],
        [17, 12, 17],
        [18, 12, 17],
        [19, 11, 17],
        [20, 11, 17],
        [21, 13, 17],
    ],
    "AR": [
        [17, 34, 39],
        [18, 34, 38],
        [19, 34, 38],
        [20, 35, 37],
    ],
    "CA": [
        [7, 3, 3],
        [8, 3, 7],
        [9, 3, 7],
        [10, 3, 7],
        [11, 3, 7],
        [12, 3, 7],
        [13, 4, 8],
        [14, 4, 9],
        [15, 4, 10],
        [16, 4, 11],
        [17, 6, 11],
        [18, 7, 11],
        [19, 8, 10],
    ],
    "CO": [
        [11, 19, 22],
        [11, 24, 24],
        [12, 19, 25],
        [13, 19, 25],
        [14, 19, 25],
        [15, 19, 25],
    ],
    "CT": [
        [8, 56, 56],
        [9, 56, 57],
    ],
    "DE": [
        [12, 54, 55],
    ],
    "FL": [
        [22, 45, 45],
        [22, 49, 50],
        [23, 43, 51],
        [24, 48, 51],
        [25, 48, 52],
        [26, 49, 52],
        [27, 50, 53],
        [28, 51, 52],
    ],
    "GA": [
        [18, 45, 47],
        [19, 45, 48],
        [20, 45, 49],
        [21, 46, 50],
        [22, 46, 48],
    ],
    "HI": [
        [25, 15, 15],
        [27, 17, 17],
        [28, 19, 19],
        [29, 21, 21],
    ],
    "ID": [
        [1, 13, 13],
        [2, 13, 13],
        [3, 13, 14],
        [4, 13, 14],
        [5, 13, 14],
        [6, 12, 15],
        [7, 12, 17],
        [8, 12, 17],
        [9, 14, 16],
    ],
    "IL": [
        [10, 39, 41],
        [11, 38, 41],
        [12, 38, 41],
        [13, 38, 41],
        [14, 39, 41],
        [15, 40, 40],
    ],
    "IN": [
        [10, 42, 42],
        [11, 42, 43],
        [12, 42, 44],
        [13, 42, 44],
        [14, 42, 43],
    ],
    "IA": [
        [9, 32, 37],
        [10, 32, 38],
        [11, 33, 37],
        [12, 37, 37],
    ],
    "KS": [
        [13, 26, 33],
        [14, 26, 33],
        [15, 26, 33],
    ],
    "KY": [
        [14, 44, 47],
        [15, 41, 47],
        [16, 40, 41],
    ],
    "LA": [
        [21, 35, 38],
        [22, 36, 37],
        [23, 36, 39],
        [24, 36, 41],
        [25, 39, 40],
    ],
    "ME": [
        [1, 57, 59],
        [2, 57, 59],
        [3, 56, 60],
        [4, 57, 60],
        [5, 57, 60],
        [6, 58, 58],
    ],
    "MD": [
        [12, 53, 53],
        [13, 54, 55],
        [14, 55, 55],
    ],
    "MA": [
        [7, 57, 59],
        [8, 57, 59],
    ],
    "MI": [
        [4, 39, 40],
        [4, 42, 43],
        [5, 39, 44],
        [6, 40, 45],
        [7, 42, 45],
        [8, 42, 46],
        [9, 42, 46],
        [10, 43, 44],
    ],
    "MN": [
        [2, 32, 34],
        [3, 32, 38],
        [4, 32, 38],
        [5, 32, 36],
        [6, 32, 35],
        [7, 32, 35],
        [8, 32, 36],
    ],
    "MS": [
        [18, 39, 40],
        [19, 39, 41],
        [20, 38, 41],
        [21, 39, 41],
        [22, 38, 41],
        [23, 40, 41],
    ],
    "MO": [
        [12, 33, 36],
        [13, 34, 37],
        [14, 34, 38],
        [15, 34, 39],
        [16, 34, 39],
    ],
    "MT": [
        [1, 14, 19],
        [2, 14, 24],
        [3, 15, 24],
        [4, 15, 24],
        [5, 15, 24],
        [6, 16, 24],
    ],
    "NE": [
        [9, 25, 25],
        [10, 25, 31],
        [11, 25, 32],
        [12, 26, 32],
    ],
    "NV": [
        [9, 8, 13],
        [10, 8, 13],
        [11, 8, 13],
        [12, 8, 13],
        [13, 9, 12],
        [14, 10, 12],
        [15, 11, 12],
    ],
    "NH": [
        [4, 56, 56],
        [6, 56, 57],
        [7, 56, 56],
    ],
    "NJ": [
        [10, 55, 55],
        [11, 54, 55],
    ],
    "NM": [
        [16, 18, 24],
        [17, 18, 24],
        [18, 18, 24],
        [19, 18, 24],
        [20, 18, 24],
        [21, 18, 23],
        [22, 17, 18],
    ],
    "NY": [
        [5, 52, 54],
        [6, 52, 54],
        [7, 50, 55],
        [8, 49, 55],
        [9, 50, 50],
        [9, 54, 55],
        [10, 56, 56],
    ],
    "NC": [
        [15, 52, 55],
        [16, 48, 55],
        [17, 46, 47],
        [17, 50, 54],
        [18, 52, 53],
    ],
    "ND": [
        [2, 25, 31],
        [3, 25, 31],
        [4, 25, 31],
        [5, 25, 31],
        [6, 31, 31],
    ],
    "OH": [
        [9, 47, 47],
        [10, 45, 48],
        [11, 44, 48],
        [12, 45, 47],
        [13, 45, 47],
    ],
    "OK": [
        [16, 25, 33],
        [17, 28, 33],
        [18, 28, 33],
        [19, 30, 33],
    ],
    "OR": [
        [3, 5, 6],
        [4, 5, 10],
        [5, 4, 12],
        [6, 3, 11],
        [7, 4, 11],
        [8, 8, 11],
    ],
    "PA": [
        [9, 48, 49],
        [9, 51, 53],
        [10, 49, 54],
        [11, 49, 53],
    ],
    "RI": [
        [9, 58, 58],
    ],
    "SC": [
        [17, 48, 49],
        [18, 48, 51],
        [19, 49, 52],
        [20, 50, 51],
    ],
    "SD": [
        [6, 25, 30],
        [7, 25, 31],
        [8, 25, 31],
        [9, 26, 31],
    ],
    "TN": [
        [16, 42, 47],
        [17, 40, 45],
        [18, 41, 41],
    ],
    "TX": [
        [17, 25, 27],
        [18, 25, 27],
        [19, 25, 29],
        [20, 25, 34],
        [21, 24, 34],
        [22, 20, 35],
        [23, 21, 35],
        [24, 22, 35],
        [25, 26, 34],
        [26, 27, 32],
        [27, 28, 31],
        [28, 28, 31],
    ],
    "UT": [
        [10, 14, 16],
        [11, 14, 18],
        [12, 14, 18],
        [13, 13, 18],
        [14, 13, 18],
        [15, 17, 18],
    ],
    "VT": [
        [5, 55, 56],
        [6, 55, 55],
    ],
    "VA": [
        [12, 52, 52],
        [13, 51, 53],
        [14, 50, 54],
        [15, 48, 51],
    ],
    "WA": [
        [0, 6, 12],
        [1, 6, 12],
        [2, 6, 12],
        [3, 7, 12],
        [4, 11, 12],
    ],
    "WV": [
        [12, 48, 51],
        [13, 48, 50],
        [14, 48, 49],
    ],
    "WI": [
        [5, 37, 38],
        [6, 36, 39],
        [7, 36, 41],
        [8, 37, 41],
        [9, 38, 41],
    ],
    "WY": [
        [7, 18, 24],
        [8, 18, 24],
        [9, 17, 24],
        [10, 17, 24],
        [11, 23, 23],
    ],
}

STATE_ENTRIES = [
    {"code": "AL", "name": "Alabama"},
    {"code": "AK", "name": "Alaska"},
    {"code": "AZ", "name": "Arizona"},
    {"code": "AR", "name": "Arkansas"},
    {"code": "CA", "name": "California"},
    {"code": "CO", "name": "Colorado"},
    {"code": "CT", "name": "Connecticut"},
    {"code": "DE", "name": "Delaware"},
    {"code": "FL", "name": "Florida"},
    {"code": "GA", "name": "Georgia"},
    {"code": "HI", "name": "Hawaii"},
    {"code": "ID", "name": "Idaho"},
    {"code": "IL", "name": "Illinois"},
    {"code": "IN", "name": "Indiana"},
    {"code": "IA", "name": "Iowa"},
    {"code": "KS", "name": "Kansas"},
    {"code": "KY", "name": "Kentucky"},
    {"code": "LA", "name": "Louisiana"},
    {"code": "ME", "name": "Maine"},
    {"code": "MD", "name": "Maryland"},
    {"code": "MA", "name": "Massachusetts"},
    {"code": "MI", "name": "Michigan"},
    {"code": "MN", "name": "Minnesota"},
    {"code": "MS", "name": "Mississippi"},
    {"code": "MO", "name": "Missouri"},
    {"code": "MT", "name": "Montana"},
    {"code": "NE", "name": "Nebraska"},
    {"code": "NV", "name": "Nevada"},
    {"code": "NH", "name": "New Hampshire"},
    {"code": "NJ", "name": "New Jersey"},
    {"code": "NM", "name": "New Mexico"},
    {"code": "NY", "name": "New York"},
    {"code": "NC", "name": "North Carolina"},
    {"code": "ND", "name": "North Dakota"},
    {"code": "OH", "name": "Ohio"},
    {"code": "OK", "name": "Oklahoma"},
    {"code": "OR", "name": "Oregon"},
    {"code": "PA", "name": "Pennsylvania"},
    {"code": "RI", "name": "Rhode Island"},
    {"code": "SC", "name": "South Carolina"},
    {"code": "SD", "name": "South Dakota"},
    {"code": "TN", "name": "Tennessee"},
    {"code": "TX", "name": "Texas"},
    {"code": "UT", "name": "Utah"},
    {"code": "VT", "name": "Vermont"},
    {"code": "VA", "name": "Virginia"},
    {"code": "WA", "name": "Washington"},
    {"code": "WV", "name": "West Virginia"},
    {"code": "WI", "name": "Wisconsin"},
    {"code": "WY", "name": "Wyoming"},
]

COLOR_OPTIONS = [
    ("Red", "red"),
    ("Blue", "blue"),
    ("Green", "green"),
    ("Cyan", "cyan"),
    ("Pink", "pink"),
    ("Yellow", "yellow"),
    ("White", "white"),
    ("Multicolor", "multicolor"),
]

MULTICOLOR_PALETTE = [
    "#ff4b4b",
    "#ffcc33",
    "#41e36e",
    "#35d7ff",
    "#5f7cff",
    "#ff63c8",
    "#f2f2f2",
]

MULTICOLOR_INDEX = {
    "AL": 5,
    "AK": 0,
    "AZ": 2,
    "AR": 0,
    "CA": 1,
    "CO": 5,
    "CT": 1,
    "DE": 6,
    "FL": 1,
    "GA": 6,
    "HI": 4,
    "ID": 2,
    "IL": 0,
    "IN": 4,
    "IA": 3,
    "KS": 0,
    "KY": 6,
    "LA": 3,
    "ME": 6,
    "MD": 2,
    "MA": 2,
    "MI": 6,
    "MN": 2,
    "MS": 4,
    "MO": 4,
    "MT": 0,
    "NE": 1,
    "NV": 5,
    "NH": 4,
    "NJ": 0,
    "NM": 3,
    "NY": 5,
    "NC": 4,
    "ND": 3,
    "OH": 1,
    "OK": 6,
    "OR": 3,
    "PA": 3,
    "RI": 5,
    "SC": 0,
    "SD": 5,
    "TN": 2,
    "TX": 1,
    "UT": 0,
    "VT": 2,
    "VA": 1,
    "WA": 6,
    "WV": 4,
    "WI": 5,
    "WY": 3,
}

SINGLE_MODE_PALETTES = {
    "red": ["#ff7b72", "#ff4b4b", "#d92f2f"],
    "blue": ["#86d1ff", "#4ea8ff", "#2867d8"],
    "green": ["#86f59e", "#42d96b", "#1f9d46"],
    "cyan": ["#8ef5ff", "#35d7ff", "#0fb7c6"],
    "pink": ["#ffa0df", "#ff63c8", "#d9329f"],
    "yellow": ["#fff06a", "#ffcc33", "#d99a00"],
    "white": ["#ffffff", "#e7edf7", "#cfd8e3"],
}

# Dark off-state tones are intentionally close to black but not identical; the
# slight variation keeps state borders legible when few states are selected.
OFF_PALETTE = [
    "#090909",
    "#0b0a0a",
    "#0a0b0a",
    "#090a0b",
    "#0b090b",
]

def _expand_runs(runs):
    pixels = []
    seen = {}

    for run in runs:
        if len(run) != 3:
            continue

        y = run[0]
        x_start = run[1]
        x_end = run[2]

        for x in range(x_start, x_end + 1):
            point = (x, y)
            if point not in seen:
                pixels.append(point)
                seen[point] = True

    return pixels

def _build_state_pixels():
    pixels = {}
    errors = []

    for entry in STATE_ENTRIES:
        code = entry["code"]
        if code not in STATE_RUNS:
            errors.append("missing coordinate runs for %s" % code)
            pixels[code] = []
        else:
            pixels[code] = _expand_runs(STATE_RUNS[code])

    return {
        "pixels": pixels,
        "errors": errors,
    }

_LAYOUT = _build_state_pixels()
STATE_PIXELS = _LAYOUT["pixels"]
BUILD_ERRORS = _LAYOUT["errors"]

def _validate_layout():
    errors = []
    seen_codes = {}
    occupied = {}

    if len(STATE_ENTRIES) != 50:
        errors.append("expected 50 states, got %d" % len(STATE_ENTRIES))

    for entry in STATE_ENTRIES:
        code = entry["code"]

        if code in seen_codes:
            errors.append("duplicate state code %s" % code)
        seen_codes[code] = True

        if code not in STATE_PIXELS:
            errors.append("missing pixels for %s" % code)
            continue

        if len(STATE_PIXELS[code]) == 0:
            errors.append("state %s has no pixels" % code)

        for point in STATE_PIXELS[code]:
            x, y = point
            if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
                errors.append("%s pixel %s is outside 64x32" % (code, point))
            if point in occupied and occupied[point] != code:
                errors.append("pixel %s overlaps %s and %s" % (point, occupied[point], code))
            occupied[point] = code

    for code in STATE_RUNS:
        if code not in seen_codes:
            errors.append("coordinate runs for unknown state code %s" % code)

    return errors

def _validate_multicolor_indices():
    errors = []
    occupied = {}
    checked_pairs = {}

    for entry in STATE_ENTRIES:
        code = entry["code"]
        if code not in MULTICOLOR_INDEX:
            errors.append("missing multicolor index for %s" % code)
            continue

        color_index = MULTICOLOR_INDEX[code]
        if color_index < 0 or color_index >= len(MULTICOLOR_PALETTE):
            errors.append("multicolor index for %s is outside the palette" % code)

        for point in STATE_PIXELS[code]:
            occupied[point] = code

    for entry in STATE_ENTRIES:
        code = entry["code"]
        if code not in MULTICOLOR_INDEX:
            continue

        for point in STATE_PIXELS[code]:
            x, y = point
            for y_delta in [-1, 0, 1]:
                for x_delta in [-1, 0, 1]:
                    if x_delta == 0 and y_delta == 0:
                        continue

                    nearby = (x + x_delta, y + y_delta)
                    if nearby not in occupied:
                        continue

                    other_code = occupied[nearby]
                    if other_code == code or other_code not in MULTICOLOR_INDEX:
                        continue

                    pair = "%s-%s" % (code, other_code)
                    reverse_pair = "%s-%s" % (other_code, code)
                    if pair in checked_pairs or reverse_pair in checked_pairs:
                        continue

                    checked_pairs[pair] = True
                    if MULTICOLOR_INDEX[code] == MULTICOLOR_INDEX[other_code]:
                        errors.append("adjacent states %s and %s share a multicolor index" % (code, other_code))

    return errors

def _collect_validation_errors():
    errors = []

    for error in BUILD_ERRORS:
        errors.append(error)

    for error in _validate_layout():
        errors.append(error)

    for error in _validate_multicolor_indices():
        errors.append(error)

    return errors

VALIDATION_ERRORS = _collect_validation_errors()

def _normalize_color_mode(mode):
    for _, value in COLOR_OPTIONS:
        if value == mode:
            return mode
    return DEFAULT_COLOR_MODE

def _palette_for_mode(mode):
    if mode == "multicolor":
        return MULTICOLOR_PALETTE
    if mode in SINGLE_MODE_PALETTES:
        return SINGLE_MODE_PALETTES[mode]
    return MULTICOLOR_PALETTE

def _state_is_selected(config, code):
    # Schema fields use the abbreviation directly, such as CA=true. The
    # state_ca fallback makes command-line testing forgiving.
    if config.bool(code, False):
        return True
    return config.bool("state_%s" % code.lower(), False)

def _color_for_state(mode, code, state_index, is_selected):
    if not is_selected:
        return OFF_PALETTE[state_index % len(OFF_PALETTE)]

    if mode == "multicolor" and code in MULTICOLOR_INDEX:
        return MULTICOLOR_PALETTE[MULTICOLOR_INDEX[code]]

    palette = _palette_for_mode(mode)
    return palette[state_index % len(palette)]

def _new_matrix():
    matrix = []
    for _ in range(GRID_HEIGHT):
        row = []
        for _ in range(GRID_WIDTH):
            row.append(BACKGROUND)
        matrix.append(row)
    return matrix

def _paint_state(matrix, pixels, color):
    for point in pixels:
        x, y = point
        matrix[y][x] = color

def _compress_row(row):
    segments = []
    current = row[0]
    width = 1

    for x in range(1, len(row)):
        color = row[x]
        if color == current:
            width += 1
        else:
            segments.append((current, width))
            current = color
            width = 1

    segments.append((current, width))
    return segments

def _render_matrix(matrix):
    rows = []
    for row in matrix:
        boxes = []
        for color, width in _compress_row(row):
            boxes.append(render.Box(width = width, height = 1, color = color))
        rows.append(render.Row(children = boxes))
    return render.Column(children = rows)

def _render_error_screen():
    return render.Root(
        child = render.Box(
            width = GRID_WIDTH,
            height = GRID_HEIGHT,
            color = "#110000",
            child = render.Text(
                content = "MAP ERR",
                font = "5x8",
                color = "#ff7777",
            ),
        ),
    )

def main(config):
    if len(VALIDATION_ERRORS) > 0:
        return _render_error_screen()

    mode = _normalize_color_mode(config.str("color_mode", DEFAULT_COLOR_MODE))
    matrix = _new_matrix()

    state_index = 0
    for entry in STATE_ENTRIES:
        code = entry["code"]
        selected = _state_is_selected(config, code)
        color = _color_for_state(mode, code, state_index, selected)
        _paint_state(matrix, STATE_PIXELS[code], color)
        state_index += 1

    return render.Root(child = _render_matrix(matrix))

def get_schema():
    fields = [
        schema.Dropdown(
            id = "color_mode",
            name = "Color Mode",
            desc = "Choose the color used for visited states.",
            icon = "brush",
            default = DEFAULT_COLOR_MODE,
            options = [
                schema.Option(display = display, value = value)
                for display, value in COLOR_OPTIONS
            ],
        ),
    ]

    for entry in STATE_ENTRIES:
        code = entry["code"]
        fields.append(
            schema.Toggle(
                id = code,
                name = "%s - %s" % (code, entry["name"]),
                desc = "Mark %s as visited." % entry["name"],
                icon = "landmarkFlag",
                default = False,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = fields,
    )
