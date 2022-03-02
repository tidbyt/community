"""
Applet: Arcade Classics
Summary: Classic arcade animations
Description: Animations from classic arcade video games.
Author: Steve Otteson
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")

FRAME_WIDTH = 64
FRAME_HEIGHT = 32

MAX_SPEED = 10
MIN_SPEED = 50

PACMAN_ANIMATION = "pacman"
SPACE_INVADERS_ANIMATION = "spaceinvaders"
RANDOM_ANIMATION = "random"

SECONDS_TO_RENDER = 15

SPEED_ADJUST = {
    PACMAN_ANIMATION: 1,
    SPACE_INVADERS_ANIMATION: 10,
}

def main(config):
    seed = int(time.now().unix)
    seed = [seed]

    animation = config.str("animation", PACMAN_ANIMATION)
    if animation == RANDOM_ANIMATION:
        animation = ANIMATION_LIST.values()[rand(seed, len(ANIMATION_LIST) - 1)]

    speed = int(config.str("speed", DEFAULT_SPEED))
    if speed < 0:
        speed = rand(seed, MIN_SPEED + MAX_SPEED + 1) + MAX_SPEED

    speed = speed * SPEED_ADJUST[animation]
    delay = speed * time.millisecond

    app_cycle_speed = SECONDS_TO_RENDER * time.second
    num_frames = math.ceil(app_cycle_speed / delay)

    allFrames = []
    for i in range(1, 1000):
        if animation == PACMAN_ANIMATION:
            frames = pacman_get_frames(seed)
        else:
            frames = spaceinvaders_get_frames()

        allFrames.extend(frames)
        if len(allFrames) >= num_frames:
            break

    return render.Root(
        delay = delay.milliseconds,
        child = render.Animation(allFrames),
    )

def rand(seed, max):
    seed[0] = (seed[0] * 1103515245 + 12345) & 0xffffffff
    return (seed[0] >> 16) % max

DEFAULT_SPEED = "30"

SPEED_LIST = {
    "Snail": "50",
    "Slow": "40",
    "Medium": "30",
    "Fast": "20",
    "Turbo": "10",
    "Random": "-1",
}

DEFAULT_ANIMATION = PACMAN_ANIMATION

ANIMATION_LIST = {
    "Pac-Man": PACMAN_ANIMATION,
    "Space Invaders": SPACE_INVADERS_ANIMATION,
    "Random": RANDOM_ANIMATION,
}

def get_schema():
    speed_options = [
        schema.Option(display = key, value = value)
        for key, value in SPEED_LIST.items()
    ]

    animation_options = [
        schema.Option(display = key, value = value)
        for key, value in ANIMATION_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "animation",
                name = "Animation",
                desc = "Which game animation to show.",
                icon = "cog",
                default = DEFAULT_ANIMATION,
                options = animation_options,
            ),
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

"""
Pac-Man
"""

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

#White_1 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAZ0lEQVR42pySUQ6AIAxDqfEi7P5ngqOIcTrKArrYD9LCW2gCSKNKOcyLgI8whVg2gHeOaXxyRm8prAHNgvw0Y3+jkdu1JIKoLxBCVy3Z75rrVUN3p77+6crPfXoXO6rBfQ7mdG0CDAAkbSfVbUPwiAAAAABJRU5ErkJggg=="""
#White_2 = """iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAIAAACQKrqGAAAAYklEQVR42pyRUQrAIAxDzdhF7P3PpEdRWF2JRWdZvhJ91qBIs0pp5kXAW1hCLDuAb45pHDmjrxTWhGZBfpuxH2jkdi2JIOoLhNBdS/a35vrU0NWlr/+7uk93cTwEz97FLsAASOI2l+NAp0cAAAAASUVORK5CYII="""
MsPM_L1 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAaElEQVR42oxSQQ7AIAhrjR9x//8j2zQzIgxpOEGBNgCEkB4TdS+vRe7NZeUp6oermfSg+gG03iBzmTvVSqoulXScPDkKtO1gAYdLIomC9OyXzdN2x63IWbS6Tsqof/MfPYz+xOi+BRgADbUvf8YXEK8AAAAASUVORK5CYII="""
MsPM_L2 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAbUlEQVR42oxRAQoAIQjbjj7S/f+PFkZdmtgNIcht2gJSiNZC8e29SS9+dp6hTrz1uB7UuICqAlnDxBwg7VZMXqaW3e+bOX2YaBz6QF4SFMMu/71NgmGUtLPjTE4MWcGNh/Bz5WYcJOg0bu8mwADQCUCuMV1YSgAAAABJRU5ErkJggg=="""
MsPM_L3 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAaklEQVR42oxSWwrAIAxrZBdx979jFKsDaxcsfhTyaFM0k8XxvnoCtoGI4mIBPRhvJdV0muPe9LYOAROrJQBmk66UCLrlnLDiQAu2VNhThoK+ifZWbKcGe1y6uqzcUH83oYwL9U+OvZsAAwAhmCrEUB1tYAAAAABJRU5ErkJggg=="""
MsPM_R1 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAa0lEQVR42oyR0RHAIAhDg5vQ/XdMz7a2CrHK8eHJA0MEWvDK/7CeTieYDXR5gcPFaLImggD3ennXZD5PSQFCsTXdbHSvkhQNJgszRwqwi36erIOJDu7m6TbbSXqyrST+PBeDB1r2hE1OAQYAIrgve2BhAl4AAAAASUVORK5CYII="""
MsPM_R2 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAbUlEQVR42pxSQQ6AMAijix/B//8Rg9PJKC7GhsMySluyidyws9ZAZNNJgIndBmHXQtrMS1IAVb/svbIuKw7Q3R9JUGILpu6TAsRBbqTlBraPvD/arSStcpfyiQLWrhG+BOKzvaqD2OVMWvcQYAD3TD+u+Dql5QAAAABJRU5ErkJggg=="""
MsPM_R3 = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAAbUlEQVR42oxSQQ7AIAiz/sT9/49dkI04QCbhgFJLG2ztDc6sAys6VNLHcuoGuAYjFdyNChiDUlCyLYV/7gQADxrYaFd6JZMhLF269pbVXJ5AEzR5jDaLP9uJiFRS39GkE3rBxOKf5JTf5d8CDABWTyrDZeekXQAAAABJRU5ErkJggg=="""

PACMANS = [
    [[PM_1, PM_R1, PM_R2, PM_R1], [PM_1, PM_L1, PM_L2, PM_L1]],
    [[MsPM_R1, MsPM_R2, MsPM_R3, MsPM_R2], [MsPM_L1, MsPM_L2, MsPM_L3, MsPM_L2]],
]

GHOSTS = [
    [[Red_R1, Red_R2], [Red_L1, Red_L2]],
    [[Pink_R1, Pink_R2], [Pink_L1, Pink_L2]],
    [[Cyan_R1, Cyan_R2], [Cyan_L1, Cyan_L2]],
    [[Peach_R1, Peach_R2], [Peach_L1, Peach_L2]],
    [[Blue_1, Blue_2], [Blue_1, Blue_2]],
]

"""
Not yet using a blinking ghost
GHOST_CHASED_BLINKING = [
    Blue_1,
    Blue_2,
    White_1,
    White_2,
]
"""

SPRITE_WIDTH = 15

PM_NUM_X_POSITIONS = FRAME_WIDTH + SPRITE_WIDTH * 2
PM_NUM_Y_POSITIONS = FRAME_HEIGHT - SPRITE_WIDTH

DIST_BETWEEN_SPRITES = 10

PM_MOVE_SPEED = 1

MIN_X = -(SPRITE_WIDTH + DIST_BETWEEN_SPRITES + SPRITE_WIDTH)
MAX_X = FRAME_WIDTH
FRAMES_PER_CALL = (MAX_X - MIN_X) // PM_MOVE_SPEED

CHASING_GHOST_COUNT = 4
CHASED_GHOST = 4

# Make the odds of chasing a ghost a little higher
CHANCE_FOR_CHASED_GHOST = 2

def pacman_get_frames(seed):
    yPos = rand(seed, PM_NUM_Y_POSITIONS)
    mspacman = rand(seed, 2) == 1
    reverse = rand(seed, 2) == 1
    whichGhost = rand(seed, CHASING_GHOST_COUNT + CHANCE_FOR_CHASED_GHOST)
    if whichGhost >= CHASING_GHOST_COUNT:
        whichGhost = CHASED_GHOST

    if reverse:
        beginX = MAX_X
        endX = MIN_X
        step = -PM_MOVE_SPEED
    else:
        beginX = MIN_X
        endX = MAX_X
        step = PM_MOVE_SPEED

    frames = [
        pacman_get_frame(xPos, yPos, mspacman, reverse, whichGhost)
        for xPos in range(beginX, endX, step)
    ]
    return frames

# How many app frames before we increase the sprite frame
PACMAN_FRAMES_PER_FRAME = 1
GHOST_FRAMES_PER_FRAME = 3

def pacman_get_frame(xPos, yPos, mspacman, reverse, whichGhost):
    frameIndex = xPos // PM_MOVE_SPEED
    pacManFrameIndex = (frameIndex // PACMAN_FRAMES_PER_FRAME) % 4
    ghostFrameIndex = (frameIndex // GHOST_FRAMES_PER_FRAME) % 2

    whichPacman = 1 if mspacman else 0
    whichDir = 1 if reverse else 0
    pacmanChasing = whichGhost >= CHASING_GHOST_COUNT

    pacmanImage = PACMANS[whichPacman][whichDir][pacManFrameIndex]
    ghostImage = GHOSTS[whichGhost][whichDir][ghostFrameIndex]

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

"""
Space Invaders
"""

BIG_ALIEN_WIDTH = 12
ALIENS_PER_ROW = 3
SPACE_BETWEEN_ALIENS = 4
INVADER_ROW_WIDTH = (BIG_ALIEN_WIDTH * ALIENS_PER_ROW) + (SPACE_BETWEEN_ALIENS * (ALIENS_PER_ROW - 1))

alien1_A = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAPElEQVR42mL8yXGFAQn8h9KMMAEmLJIobCYskiiKmLAZi8T+T9AKFmTV2NhMaAL/0dhgE5AF0E34DxBgAJjmFOHenXrNAAAAAElFTkSuQmCC"""
alien1_B = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAPUlEQVR42mL8yXGFAQn8h9KMMAEmLJIobCYskiiKmLAZi8T+T9AKFmTV2NhMWCRhVvxHVsCIxQqwBoAAAwAbERDiEXss2wAAAABJRU5ErkJggg=="""
alien2_A = """iVBORw0KGgoAAAANSUhEUgAAAAsAAAAICAYAAAAvOAWIAAAASklEQVR42nxPCQoAMAjS6OH7+Q7YRriaEESaFtFw0GcRL+7cwpCbSIULLgR+CyYCPYORN3HKXG9vhSOyBC9iU3cPAsrt+geHAAMA8jsQlUAQEDcAAAAASUVORK5CYII="""
alien2_B = """iVBORw0KGgoAAAANSUhEUgAAAAsAAAAICAYAAAAvOAWIAAAASklEQVR42oRQgQkAIAibo8P73AosyrQEQbc5RUHFDO0puGPhtAYGaCYcdXEEXgN0An+G7DydIHJdg0wcEW0oydrQnZ+3HV9qAgwA+98Qkq04gCQAAAAASUVORK5CYII="""
alien3_A = """iVBORw0KGgoAAAANSUhEUgAAAAwAAAAICAYAAADN5B7xAAAARUlEQVR42oRQQQoAMAjK6P9fdpcxhuUWdDBMLTBa6Qg3KENyAsgPuS3nYI8HPpFc/uZeokA5VHGkIXO3LgY4qLy+tQQYAHVUERDg61VsAAAAAElFTkSuQmCC"""
alien3_B = """iVBORw0KGgoAAAANSUhEUgAAAAwAAAAICAYAAADN5B7xAAAARklEQVR42oRPQQoAMAia0f+/3NgOIzJb0EExNcSiqRQycCFSBrCPmI6ticeAXyXVn9I9OUTzKHH1aQz4LBAcD1Hr8luAAQBuTxEUquo0cAAAAABJRU5ErkJggg=="""

SPACEINVADERS_IMAGES = [
    [base64.decode(alien1_A), base64.decode(alien1_B)],
    [base64.decode(alien2_A), base64.decode(alien2_B)],
    [base64.decode(alien3_A), base64.decode(alien3_B)],
]

SI_NUM_X_POSITIONS = FRAME_WIDTH - INVADER_ROW_WIDTH + 1

# -2 because we don't want to duplicate the first and last X
NUM_STATES = (SI_NUM_X_POSITIONS * 2) - 2

def spaceinvaders_get_frames():
    frames = [
        spaceinvaders_get_frame(i)
        for i in range(0, NUM_STATES)
    ]

    return frames

def spaceinvaders_get_frame(state):
    whichFrame = state % 2

    currentState = state % NUM_STATES
    pos_x = currentState % SI_NUM_X_POSITIONS
    pos_y = 2

    if currentState >= SI_NUM_X_POSITIONS:
        pos_x = SI_NUM_X_POSITIONS - pos_x - 2

    col1Image = SPACEINVADERS_IMAGES[0][whichFrame]
    col2Image = SPACEINVADERS_IMAGES[1][whichFrame]
    col3Image = SPACEINVADERS_IMAGES[2][whichFrame]

    return render.Padding(
        pad = (pos_x, pos_y, 0, 0),
        child =
            render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(width = 1, height = 8, color = "#000"),
                            render.Image(col1Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 3, height = 8, color = "#000"),
                            render.Box(width = 1, height = 8, color = "#000"),
                            render.Image(col1Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 3, height = 8, color = "#000"),
                            render.Box(width = 1, height = 8, color = "#000"),
                            render.Image(col1Image),
                        ],
                    ),
                    render.Box(width = 1, height = 2, color = "#000"),
                    render.Row(
                        children = [
                            render.Image(col2Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 1, height = 8, color = "#000"),
                            render.Image(col2Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 1, height = 8, color = "#000"),
                            render.Image(col2Image),
                        ],
                    ),
                    render.Box(width = 1, height = 2, color = "#000"),
                    render.Row(
                        children = [
                            render.Image(col3Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS, height = 8, color = "#000"),
                            render.Image(col3Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS, height = 8, color = "#000"),
                            render.Image(col3Image),
                        ],
                    ),
                ],
            ),
    )
