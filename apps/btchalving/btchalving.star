"""
Applet: BtcHalving
Summary: Bitcoin halving progress
Description: Shows the Bitcoin halving- and the difficulty adjustment progress.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")

BLOCKS_PER_HALVING = 210000
BLOCKS_DIFFICULTY_ADJUSTMENT = 2016
PROGRESS_WIDTH = 64
URL_BLOCK_TIP_HEIGHT = "https://mempool.space/api/blocks/tip/height"
URL_DIFFICULTY_ADJUSTMENT = "https://mempool.space/api/v1/difficulty-adjustment"

ACTIVE_PROGRESS_COLOR = "#6d4626"
BACKGROUND_COLOR = "#000"
BORDER_COLOR_DARK = "#494542"
BORDER_COLOR_LIGHT = "#848280"
TEXT_COLOR = "#fff"

def render_progress_bar(width, height, progress, text_stack):
    return render.Box(
        width = width,
        height = height,
        child = render.Stack(
            children = [
                render.Padding(
                    # Top top
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_DARK,
                        width = width,
                        height = 1,
                    ),
                ),
                render.Padding(
                    # Top bottom
                    pad = (0, 1, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_DARK,
                        width = width - 1,
                        height = 1,
                    ),
                ),
                render.Padding(
                    # Left left
                    pad = (0, 2, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_DARK,
                        width = 1,
                        height = height - 2,
                    ),
                ),
                render.Padding(
                    # Left right
                    pad = (1, 2, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_DARK,
                        width = 1,
                        height = height - 2 - 1,
                    ),
                ),
                render.Padding(
                    # Right left
                    pad = (width - 2, 2, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_LIGHT,
                        width = 1,
                        height = height - 2 - 2,
                    ),
                ),
                render.Padding(
                    # Right right
                    pad = (width - 1, 1, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_LIGHT,
                        width = 1,
                        height = height - 2 - 1,
                    ),
                ),
                render.Padding(
                    # Bottom top
                    pad = (2, height - 2, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_LIGHT,
                        width = width,
                        height = 1,
                    ),
                ),
                render.Padding(
                    # Bottom bottom
                    pad = (1, height - 1, 0, 0),
                    child = render.Box(
                        color = BORDER_COLOR_LIGHT,
                        width = width - 1,
                        height = 1,
                    ),
                ),
                render.Padding(
                    # Inset
                    pad = (2, 2, 2, 2),
                    child = render.Stack(
                        children = [
                            render.Box(
                                width = PROGRESS_WIDTH - progress,
                                height = height,
                                color = ACTIVE_PROGRESS_COLOR,
                            ),
                            render.Column(
                                children = text_stack or [],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def main():
    response_block_tip_height = http.get(url = URL_BLOCK_TIP_HEIGHT, ttl_seconds = 30)
    response_difficulty_adjustment = http.get(url = URL_DIFFICULTY_ADJUSTMENT, ttl_seconds = 60)
    if response_block_tip_height.status_code != 200 and response_difficulty_adjustment.status_code != 200:
        fail("Mempool.space request failed with status %d/%d", response_block_tip_height.status_code, response_difficulty_adjustment.status_code)

    block_tip_height = int(response_block_tip_height.json())
    difficulty_adjustment = response_difficulty_adjustment.json()
    difficulty_adjustment_remaining = int(difficulty_adjustment["remainingBlocks"])
    difficulty_change = int(difficulty_adjustment["difficultyChange"] * 10) / 10

    curr_epoch = math.ceil(block_tip_height / BLOCKS_PER_HALVING)
    blocks_left_to_next_epoch = (curr_epoch * BLOCKS_PER_HALVING) - block_tip_height

    halving_progress = int(math.round((blocks_left_to_next_epoch / BLOCKS_PER_HALVING) * PROGRESS_WIDTH))
    difficulty_adjustment_progress = int(math.round((difficulty_adjustment_remaining / BLOCKS_DIFFICULTY_ADJUSTMENT) * PROGRESS_WIDTH))

    difficulty_change_text_color = TEXT_COLOR
    if difficulty_change > 0.1:
        difficulty_change_text_color = "#0f0"
    if difficulty_change < -0.1:
        difficulty_change_text_color = "#f00"

    return render.Root(
        max_age = 30,
        child = render.Box(
            width = 64,
            height = 32,
            color = BACKGROUND_COLOR,
            child = render.Column(
                expanded = True,
                children = [
                    render_progress_bar(64, 16, halving_progress, [
                        render.Text(
                            content = "HALVING:",
                            font = "tom-thumb",
                            color = TEXT_COLOR,
                            height = 6,
                        ),
                        render.Text(
                            content = "{} left".format(blocks_left_to_next_epoch),
                            font = "tb-8",
                            color = TEXT_COLOR,
                            height = 7,
                        ),
                    ]),
                    render_progress_bar(64, 16, difficulty_adjustment_progress, [
                        render.Text(
                            content = "DIFF.ADJ.:",
                            font = "tom-thumb",
                            color = TEXT_COLOR,
                            height = 6,
                        ),
                        render.Row(
                            children = [
                                render.Text(
                                    content = str(difficulty_adjustment_remaining),
                                    font = "tb-8",
                                    color = TEXT_COLOR,
                                    height = 7,
                                ),
                                render.Padding(
                                    pad = (4, 0, 0, 0),
                                    child = render.Text(
                                        content = "{}%".format(difficulty_change),
                                        font = "tb-8",
                                        color = difficulty_change_text_color,
                                        height = 7,
                                    ),
                                ),
                            ],
                        ),
                    ]),
                ],
            ),
        ),
    )
