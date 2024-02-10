"""
Applet: BtcDifficulty
Summary: BTC difficulty adjustment
Description: Displays Bitcoin's difficulty adjustment progress.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

BLOCKS_DIFFICULTY_ADJUSTMENT = 2016
BLOCKS_PER_PIXEL = 4
PROGRESS_BAR_HEIGHT = 8
PROGRESS_BAR_WIDTH = 63

COLOR_BEHIND = "#B74242"
COLOR_AHEAD = "#42B747"

def get_progress_color(progress_status):
    return COLOR_BEHIND if progress_status == "behind" else COLOR_AHEAD

def render_progress_bar(data):
    expected_blocks = data["expectedBlocks"]
    remaining_blocks = data["remainingBlocks"]
    expected_blocks_rounded = math.round(float(expected_blocks))
    progress_block_amount = BLOCKS_DIFFICULTY_ADJUSTMENT - remaining_blocks - expected_blocks_rounded
    progress_status = "behind" if (progress_block_amount) <= 0 else "ahead"

    expected_blocks_pixels_amount = math.round(expected_blocks_rounded / BLOCKS_PER_PIXEL)
    progress_blocks_pixels_amount = math.round(progress_block_amount / BLOCKS_PER_PIXEL)
    current_block_pixel_amount = 1
    remaining_blocks_pixels_amount = math.round(remaining_blocks / BLOCKS_PER_PIXEL) - current_block_pixel_amount

    column_pixels = []
    for _ in range(PROGRESS_BAR_WIDTH):
        row_pixels = []
        for _ in range(PROGRESS_BAR_HEIGHT):
            color = ""

            if expected_blocks_pixels_amount > 0:
                color = "#115fb1"
                expected_blocks_pixels_amount = expected_blocks_pixels_amount - 1
            elif progress_blocks_pixels_amount > 0:
                color = get_progress_color(progress_status)
                progress_blocks_pixels_amount = progress_blocks_pixels_amount - 1
            elif current_block_pixel_amount > 0:
                color = "#fff"
                current_block_pixel_amount = 0
            elif remaining_blocks_pixels_amount > 0:
                color = "#2d3348"
                remaining_blocks_pixels_amount = remaining_blocks_pixels_amount - 1

            if color == "#fff":
                opacity_frames = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
                animation = []
                for f in opacity_frames:
                    animation.append(render.Box(width = 1, height = 1, color = color + f))
                for f in reversed(opacity_frames):
                    animation.append(render.Box(width = 1, height = 1, color = color + f))
                for _ in range(10):
                    animation.append(render.Box(width = 1, height = 1, color = "#fff0"))
                row_pixels.append(render.Animation(children = animation))
            else:
                row_pixels.append(
                    render.Box(
                        width = 1,
                        height = 1,
                        color = color,
                    ),
                )
        column_pixels.append(render.Column(children = row_pixels))

    return render.Row(children = column_pixels)

def convert_float_to_two_digits(num):
    return int(num * 100) / 100

def render_stats_row(data):
    difficulty_change = data["difficultyChange"]
    previous_retarget_date = data["previousRetarget"]
    remaining_blocks = data["remainingBlocks"]
    expected_blocks = data["expectedBlocks"]
    expected_blocks_rounded = math.round(float(expected_blocks))
    progress_block_amount = BLOCKS_DIFFICULTY_ADJUSTMENT - remaining_blocks - expected_blocks_rounded

    estimated_retarget_date = data["estimatedRetargetDate"]
    remaining_time = humanize.relative_time(time.now(), time.from_timestamp(int(int(estimated_retarget_date) / 1000)), "", "")

    progress_status = "behind" if (progress_block_amount) <= 0 else "ahead"
    current_difficulty_change_direction = "▼" if progress_status == "behind" else "▲"

    return render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(
                        content = current_difficulty_change_direction + str(convert_float_to_two_digits(difficulty_change)) + "%",
                        font = "tb-8",
                        color = get_progress_color(progress_status),
                        offset = 1,
                    ),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Row(
                        children = [
                            render.Text(
                                content = "Prev:(",
                                font = "CG-pixel-3x5-mono",
                                color = "#fff6",
                            ),
                            render.Text(
                                content = str(convert_float_to_two_digits(previous_retarget_date)) + "%",
                                font = "CG-pixel-3x5-mono",
                                color = COLOR_BEHIND if previous_retarget_date < 0 else COLOR_AHEAD,
                            ),
                            render.Text(
                                content = ")",
                                font = "CG-pixel-3x5-mono",
                                color = "#fff6",
                            ),
                        ],
                    ),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("In ± " + remaining_time),
                ],
            ),
        ],
    )

def get_data(ttl_seconds = 60 * 60 * 6):
    url = "https://mempool.space/api/v1/difficulty-adjustment"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Mempool.space request failed with status %d", response.status_code)
    return response.json()

def main():
    data = get_data()
    progress_bar = render_progress_bar(data)
    stats_row = render_stats_row(data)

    return render.Root(
        child = render.Stack(
            children = [
                progress_bar,
                render.Padding(
                    pad = (0, 10, 0, 0),
                    child = stats_row,
                ),
            ],
        ),
    )
