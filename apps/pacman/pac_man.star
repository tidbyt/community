"""
Applet: Pac-Man
Summary: Animated Pac-Man & friends
Description: Pac-Man, Ms. Pac-Man, and the ghosts chase each other.
Author: Steve Otteson
"""

load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

Red_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZ0lEQVR42mJkQAX/kdiMqFKMWBVhVcGIXx2yIhZkdffvgZiKSgirICL/lRiBQkxoongYLGh2OTuDyHsYIkDAhN+VyJ5mRFaKy60QEUYiTWVA9tbAKmVEjRtGbBHLBOcw4o5SCAkQYAClNyHYKAGFjAAAAABJRU5ErkJggg=="""
Red_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAYUlEQVR42mJkQAX/kdiMqFKMWBVhVcGIXx2yIhZkdffvgZiKSgirICL/lRiBQkxoongYLGh2OTuDyHsYIkDAhN+VyJ5mRFaKy60QEUYiTWVA9tZgUIoz0pED4j8RXIAAAwAqjCfKmzaHIQAAAABJRU5ErkJggg=="""
Red_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAYklEQVR42mJkQAX/kdiMqFKMWBVhVcGIXx2yIkaIuvv3QIoVlRCWoIkAKSa4KH4GA0SpszMIIQNMEZBS/K5E9jTjf2wuwyrCSKSpULcOBqWMqHHDiC1imVDiDU+UMjAABBgAABYhI/KsN1kAAAAASUVORK5CYII="""
Red_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAW0lEQVR42mJkQAX/kdiMqFKMWBVhVcGIXx2yIkaIuvv3QIoVlRCWoIkAKSa4KH4GA0SpszMIIQNMEZBS/K5E9jTjf2wuwyrCSKSpULcOHqU4Ix05IP4TwQUIMACFXCcVNRT5FQAAAABJRU5ErkJggg=="""
Pink_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAbklEQVR42mJkQAX/t/+Hsxk9GZGlGLEqQlEB08CIXx2yakZkdffVQaTiTYQiuAhQNROaKB4GC5pdzs4g8t40dBEgYMLvSmRPMyIrxeNWkLeINBXkAAaiAU2VIkc3kI3GRSiFxhtq4kCJUjAJEGAAKCwn3ZOFumYAAAAASUVORK5CYII="""
Pink_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAaElEQVR42mJkQAX/t/+Hsxk9GZGlGLEqQlEB08CIXx2yakZkdffVQaTiTYQiuAhQNROaKB4GC5pdzs4g8t40dBEgYMLvSmRPMyIrxeNWkLeINBXkAAaiAR2Uokc6KhcaEMiew8UFCDAARh02V5LWH9sAAAAASUVORK5CYII="""
Pink_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAa0lEQVR42mJkQAX/t/+Hsxk9GZGlGLEqQlEB08CIXx2yakaIuvvqICHFmwhpNBGgaia4KH4GEICUOjuDEDLAFAEpxe9KZE8zQpQSdCvIuUSaCnXrYFCKHN1ANhoXoRQab6iJAyVKwSRAgAEA7Ecnc313zkMAAAAASUVORK5CYII="""
Pink_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZElEQVR42mJkQAX/t/+Hsxk9GZGlGLEqQlEB08CIXx2yakaIuvvqICHFmwhpNBGgaia4KH4GEICUOjuDEDLAFAEpxe9KZE8zQpQSdCvIuUSaCnXr4FGKHumoXGhAIHsOFxcgwAAKRzXt/Z+p2AAAAABJRU5ErkJggg=="""
Cyan_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAbElEQVR42mJkQAP//yPYjIzIMozYFaEoYURViksdkmoWZHX37oNIJUWEGqgIUAEjIxOaKB4GC5pVzs4QSQwRBgYmAq5E8jQjslKcblWEhACRpoIcQDSgrVLk6Aay0bgIpRAOauJAUQcmAQIMADWWIt9gASEJAAAAAElFTkSuQmCC"""
Cyan_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZ0lEQVR42mJkQAP//yPYjIzIMozYFaEoYURViksdkmoWZHX37oNIJUWEGqgIUAEjIxOaKB4GC5pVzs4QSQwRBgYmAq5E8jQjslKcblWEhACRpoIcQDSgh1LUSEfnQmML2XM4uAABBgAuqy7FKWj4UgAAAABJRU5ErkJggg=="""
Cyan_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZ0lEQVR42mJkQAP//yPYjIzIMozYFaEoYURViksdkmpGiLp790G0kiJCFl2EkZEJLoqfAQQgpc7OIIQMMEXASvG7EsnTjBClhN0K8haRpkLcOiiUIkc3kI3GRSiFcFATB4o6MAkQYACxziEr7ViBvwAAAABJRU5ErkJggg=="""
Cyan_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAYklEQVR42mJkQAP//yPYjIzIMozYFaEoYURViksdkmpGiLp790G0kiJCFl2EkZEJLoqfAQQgpc7OIIQMMEXASvG7EsnTjBClhN0K8haRpkLcOoiUokY6Ohcaq8iew8EFCDAAquMtEaMaO1QAAAAASUVORK5CYII="""
Peach_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAcElEQVR42mJkQAX/twfC2Yye65GlGLEqQlEB08CIXx2yakZkdffV1wFJxZtBcEVwEaBqJjRRPAwWNLucnUHkvWnoIkDAhN+VyJ5mRFaKx60gbxFpKsgBDEQDmipFjm4gG42LUAqNN9TEgRKlYBIgwACKxTFN5s4QAwAAAABJRU5ErkJggg=="""
Peach_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAaklEQVR42mJkQAX/twfC2Yye65GlGLEqQlEB08CIXx2yakZkdffV1wFJxZtBcEVwEaBqJjRRPAwWNLucnUHkvWnoIkDAhN+VyJ5mRFaKx60gbxFpKsgBDEQDOihFj3RULjQgkD2HiwsQYADG/zefW11t3QAAAABJRU5ErkJggg=="""
Peach_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAbUlEQVR42mJkQAX/twfC2Yye65GlGLEqQlEB08CIXx2yakaIuvvq64AMxZtBcGk0EaBqJrgofgYQgJQ6O4MQMsAUASnF70pkTzNClBJ0K8i5RJoKdetgUIoc3UA2GhehFBpvqIkDJUrBJECAAQB3PzDjbS2xbQAAAABJRU5ErkJggg=="""
Peach_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZklEQVR42mJkQAX/twfC2Yye65GlGLEqQlEB08CIXx2yakaIuvvq64AMxZtBcGk0EaBqJrgofgYQgJQ6O4MQMsAUASnF70pkTzNClBJ0K8i5RJoKdevgUYoe6ahcaEAgew4XFyDAALN5NzW64nz3AAAAAElFTkSuQmCC"""
PM_1 = """iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAN0lEQVR42mJkQAL//yPzGBgZkdhYVWCqZsSvCK6UiYE4wEjQMAgg1ryBUkf1cCEhPoiJX4AAAwDqQA4Si0u90AAAAABJRU5ErkJggg=="""
PM_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAQUlEQVR42mJkQAL//yPzGBgZkdhYVWCqZsSvCK6UiYE4wIjfMLgTWfBLwwELfmkC9mJqINZ9VA8XEuKDmPgFCDAAXgcSGtpg8gUAAAAASUVORK5CYII="""
PM_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAATklEQVR42oyRwQ4AIAhCpfX/v2zdYoIuTuWeYIYgZfItgHfellChg9jsavluSEXNFDJ+FqpcB1VueHXN7VC/Fx3A78V0DnHsis//PQIMAOn8FBVaC87kAAAAAElFTkSuQmCC"""
PM_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAQUlEQVR42mJkQAL//yPzGBgZkdhYVWCqZsSvCK6UiYE4wIjLcTjV4dfAiMcMZA0sRJrHQoL7aBAuRMUHMfELEGAAVl4WDFURo9cAAAAASUVORK5CYII="""
PM_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAASUlEQVR42pSRSQ4AMAgCxfT/X7ZXIthYT0rGHUFWxVEA5D84ptHUCU2bbVCratX02dhxio5ca53L+bCC9C72fh//ODEbr3wFGAAhERIXQwReQQAAAABJRU5ErkJggg=="""
Blue_1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAaElEQVR42mJkQAWKiv/h7Pv3GZGlGLEqQgZwDYz41SGrZiSoDq6aiYFogKL03rT1QITJhiolxnaIIxmJVIruAKKU4nIliouBDvi/fR2QhDBwsclyK3J0A9loXIRSCActcSCrg5AAAQYA8+9Mz7UBEeUAAAAASUVORK5CYII="""
Blue_2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAYklEQVR42mJkQAWKiv/h7Pv3GZGlGLEqQgZwDYz41SGrZiSoDq6aiYFogKL03rT1QITJhiolxnaIIxmJVIruAKKU4nIliouBDvi/fR2QhDBwsSlwK1qko3GhbkA2GxcXIMAAE4lJ2S951wwAAAAASUVORK5CYII="""
White_1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZ0lEQVR42pySUQ6AIAxDqfEi7P5ngqOIcTrKArrYD9LCW2gCSKNKOcyLgI8whVg2gHeOaXxyRm8prAHNgvw0Y3+jkdu1JIKoLxBCVy3Z75rrVUN3p77+6crPfXoXO6rBfQ7mdG0CDAAkbSfVbUPwiAAAAABJRU5ErkJggg=="""
White_2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAYklEQVR42pyRUQrAIAxDzdhF7P3PpEdRWF2JRWdZvhJ91qBIs0pp5kXAW1hCLDuAb45pHDmjrxTWhGZBfpuxH2jkdi2JIOoLhNBdS/a35vrU0NWlr/+7uk93cTwEz97FLsAASOI2l+NAp0cAAAAASUVORK5CYII="""
MsPM_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAaElEQVR42oxSQQ7AIAhrjR9x//8j2zQzIgxpOEGBNgCEkB4TdS+vRe7NZeUp6oermfSg+gG03iBzmTvVSqoulXScPDkKtO1gAYdLIomC9OyXzdN2x63IWbS6Tsqof/MfPYz+xOi+BRgADbUvf8YXEK8AAAAASUVORK5CYII="""
MsPM_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAbUlEQVR42oxRAQoAIQjbjj7S/f+PFkZdmtgNIcht2gJSiNZC8e29SS9+dp6hTrz1uB7UuICqAlnDxBwg7VZMXqaW3e+bOX2YaBz6QF4SFMMu/71NgmGUtLPjTE4MWcGNh/Bz5WYcJOg0bu8mwADQCUCuMV1YSgAAAABJRU5ErkJggg=="""
MsPM_L3 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAaklEQVR42oxSWwrAIAxrZBdx979jFKsDaxcsfhTyaFM0k8XxvnoCtoGI4mIBPRhvJdV0muPe9LYOAROrJQBmk66UCLrlnLDiQAu2VNhThoK+ifZWbKcGe1y6uqzcUH83oYwL9U+OvZsAAwAhmCrEUB1tYAAAAABJRU5ErkJggg=="""
MsPM_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAa0lEQVR42oyR0RHAIAhDg5vQ/XdMz7a2CrHK8eHJA0MEWvDK/7CeTieYDXR5gcPFaLImggD3ennXZD5PSQFCsTXdbHSvkhQNJgszRwqwi36erIOJDu7m6TbbSXqyrST+PBeDB1r2hE1OAQYAIrgve2BhAl4AAAAASUVORK5CYII="""
MsPM_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAbUlEQVR42pxSQQ6AMAijix/B//8Rg9PJKC7GhsMySluyidyws9ZAZNNJgIndBmHXQtrMS1IAVb/svbIuKw7Q3R9JUGILpu6TAsRBbqTlBraPvD/arSStcpfyiQLWrhG+BOKzvaqD2OVMWvcQYAD3TD+u+Dql5QAAAABJRU5ErkJggg=="""
MsPM_R3 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAbUlEQVR42oxSQQ7AIAiz/sT9/49dkI04QCbhgFJLG2ztDc6sAys6VNLHcuoGuAYjFdyNChiDUlCyLYV/7gQADxrYaFd6JZMhLF269pbVXJ5AEzR5jDaLP9uJiFRS39GkE3rBxOKf5JTf5d8CDABWTyrDZeekXQAAAABJRU5ErkJggg=="""

MSPACMAN_RIGHT = [
    MsPM_R1,
    MsPM_R2,
    MsPM_R3,
    MsPM_R2,
]

MSPACMAN_LEFT = [
    MsPM_L1,
    MsPM_L2,
    MsPM_L3,
    MsPM_L2,
]

MSPACMAN = [
    MSPACMAN_RIGHT,
    MSPACMAN_LEFT,
]

PACMAN_RIGHT = [
    PM_1,
    PM_R1,
    PM_R2,
    PM_R1,
]

PACMAN_LEFT = [
    PM_1,
    PM_L1,
    PM_L2,
    PM_L1,
]

PACMAN = [
    PACMAN_RIGHT,
    PACMAN_LEFT,
]

PACMANS = [
    PACMAN,
    MSPACMAN,
]

RED_GHOST_LEFT = [
    Red_L1,
    Red_L2,
]

RED_GHOST_RIGHT = [
    Red_R1,
    Red_R2,
]

RED_GHOST = [
    RED_GHOST_RIGHT,
    RED_GHOST_LEFT,
]

PINK_GHOST_LEFT = [
    Pink_L1,
    Pink_L2,
]

PINK_GHOST_RIGHT = [
    Pink_R1,
    Pink_R2,
]

PINK_GHOST = [
    PINK_GHOST_RIGHT,
    PINK_GHOST_LEFT,
]

CYAN_GHOST_LEFT = [
    Cyan_L1,
    Cyan_L2,
]

CYAN_GHOST_RIGHT = [
    Cyan_R1,
    Cyan_R2,
]

CYAN_GHOST = [
    CYAN_GHOST_RIGHT,
    CYAN_GHOST_LEFT,
]

PEACH_GHOST_LEFT = [
    Peach_L1,
    Peach_L2,
]

PEACH_GHOST_RIGHT = [
    Peach_R1,
    Peach_R2,
]

PEACH_GHOST = [
    PEACH_GHOST_RIGHT,
    PEACH_GHOST_LEFT,
]

GHOST_CHASERS = [
    RED_GHOST,
    PINK_GHOST,
    CYAN_GHOST,
    PEACH_GHOST,
]

GHOST_CHASED_BLUE = [
    Blue_1,
    Blue_2,
]

GHOST_CHASED_BLINKING = [
    Blue_1,
    Blue_2,
    White_1,
    White_2,
]

FRAME_WIDTH = 64
FRAME_HEIGHT = 32

SPRITE_WIDTH = 15

NUM_X_POSITIONS = FRAME_WIDTH + SPRITE_WIDTH * 2
NUM_Y_POSITIONS = FRAME_HEIGHT - SPRITE_WIDTH

DIST_BETWEEN_SPRITES = 10

MOVE_SPEED = 1

MIN_X = -(SPRITE_WIDTH + DIST_BETWEEN_SPRITES + SPRITE_WIDTH)
MAX_X = FRAME_WIDTH
FRAMES_PER_CALL = (MAX_X - MIN_X) // MOVE_SPEED

MS_PER_FRAME = 50

# the amount of time before a new sequence is generated
SEED_GRANULARITY = 60 * 1  # 1 minute

# Make the odds of chasing a ghost a little higher
CHANCE_FOR_CHASED_GHOST = 2
CHASING_GHOST_COUNT = 4

MAX_SPEED = 10
MIN_SPEED = 50
DEFAULT_SPEED = "30"

#this list contains the currently supported fiat currencies
SPEED_LIST = {
    "Snail": "50",
    "Slow": "40",
    "Medium": "30",
    "Fast": "20",
    "Turbo": "10",
    "Random": "-1",
}

def get_schema():
    speed_options = [
        schema.Option(display = key, value = value)
        for key, value in SPEED_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Change the speed of the animation.",
                icon = "cog",
                default = DEFAULT_SPEED,
                options = speed_options,
            ),
        ],
    )

def main(config):
    seed = int(time.now().unix) // SEED_GRANULARITY
    seed = [seed]

    speed = int(config.str("speed", DEFAULT_SPEED))
    if speed < 0:
        speed = rand(seed, MIN_SPEED + MAX_SPEED + 1) + MAX_SPEED
    delay = speed * time.millisecond

    app_cycle_speed = 15 * time.second
    num_frames = math.ceil(app_cycle_speed / delay)

    allFrames = []
    for i in range(1, math.ceil(num_frames / FRAMES_PER_CALL)):
        allFrames.extend(get_frames(seed))

    return render.Root(
        delay = delay.milliseconds,
        child = render.Animation(allFrames),
    )

def get_frames(seed):
    yPos = rand(seed, NUM_Y_POSITIONS)
    mspacman = rand(seed, 2) == 1
    reverse = rand(seed, 2) == 1
    whichGhost = rand(seed, CHASING_GHOST_COUNT + CHANCE_FOR_CHASED_GHOST)

    if reverse:
        beginX = MAX_X
        endX = MIN_X
        step = -MOVE_SPEED
    else:
        beginX = MIN_X
        endX = MAX_X
        step = MOVE_SPEED

    frames = [
        get_frame(xPos, yPos, mspacman, reverse, whichGhost)
        for xPos in range(beginX, endX, step)
    ]
    return frames

# How many app frames before we increase the sprite frame
PACMAN_FRAMES_PER_FRAME = 1
GHOST_FRAMES_PER_FRAME = 3

def get_frame(xPos, yPos, mspacman, reverse, whichGhost):
    frameIndex = xPos // MOVE_SPEED
    pacManFrameIndex = (frameIndex // PACMAN_FRAMES_PER_FRAME) % 4
    ghostFrameIndex = (frameIndex // GHOST_FRAMES_PER_FRAME) % 2

    whichPacman = 1 if mspacman else 0
    whichDir = 1 if reverse else 0
    pacmanChasing = whichGhost >= CHASING_GHOST_COUNT

    pacmanImage = PACMANS[whichPacman][whichDir][pacManFrameIndex]
    ghostImage = GHOST_CHASED_BLUE[ghostFrameIndex] if pacmanChasing else GHOST_CHASERS[whichGhost][whichDir][ghostFrameIndex]

    if (pacmanChasing and not reverse) or (not pacmanChasing and reverse):
        firstImage = pacmanImage
        secondImage = ghostImage
    else:
        firstImage = ghostImage
        secondImage = pacmanImage

    return render.Padding(
        pad = (xPos, yPos, 0, 0),
        child =
            render.Row(
                children = [
                    render.Image(base64.decode(firstImage)),
                    render.Box(width = DIST_BETWEEN_SPRITES, height = 1, color = "#000"),
                    render.Image(base64.decode(secondImage)),
                ],
            ),
    )

# Gets a pseudo-random number whose value is between 0 and max - 1
# seed - the random number seed container
# max - the (exclusive) max value desired
def rand(seed, max):
    seed[0] = (seed[0] * 1103515245 + 12345) & 0xffffffff
    return (seed[0] >> 16) % max
