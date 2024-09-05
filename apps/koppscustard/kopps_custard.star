"""
Applet: Kopp's Custard
Summary: Today's Kopp's flavors
Description: Get today's flavors at Kopp's Frozen Custard.
Author: Josiah Winslow
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("time.star", "time")

WIDTH = 64
HEIGHT = 32

TIMEZONE = "America/Chicago"  # Kopp's is a local chain in Wisconsin
DELAY = 100
ERROR_DELAY = 45
TTL_SECONDS = 60 * 30  # 30 minutes

KOPPS_ICON_WIDTH = 62
KOPPS_ICON_HEIGHT = 21
KOPPS_ICON = base64.decode("""
UklGRmIDAABXRUJQVlA4WAoAAAAQAAAAPQAAFAAAQUxQSB0DAAABoEVt2/G4etLUdpvUdlCb/9S2bdu
2bY3Kr9jmv23btj2q74N8+bfPI2ICphtjzLnSnYwx+yS1v7Rr3YODfFJNY4yZP+7QkiqSY4wxg5fvn1
VKGmHOSBr4wIm5F/qk5o58D+zLEXyM7yZIO7nWoFYayT7lN8DlVt9zfagCzwLrB1/lt+Zaw0/Sdj5pW
jEVAnoe6CIt/iwgTYE3pKdhoTQ+Rkchs6R2xOhp+MQ/jbdV5yZ7JSV7KPVlVMrxA7wiPQ6/5o+zH+gT
51Ggen8e0Xz4qYNU6VYc313Xg1Ib4tHd0whP0Vac0Qbg1oMJGp3NNg0WSlO9LI5zFKgT5ynIyJt/QEg
DsboBWfqnwbvSUi+bbAXehJOylfkd5ik258sW3shp6ZkBNNdML4ttu75+dro/zv1fPDxA9mKXbsUw1N
LFAMfUyUs/m+wWeRzWRw3ui9lk6wek5c/3a7zMwn/P9icldfwRZtly/waM0hJ4S3oONuhvoqekRK5Vq
vYNsL7Qe8AbRbKdJatMyT+4PYdyHgfer2kp/DDwSNBT2rAcbb5jvha7ruve2/1B13XdnvKNeiZl2xPD
fVLIjV1n6eHGjvcwfsuOLxJ+e6CT/ufrOJEOlZxoXZ9KNK6gZmGnRuv29aO1nWCtsKQ6jcMVnUillgo
3qFo94kQqKdRUFZ1oPV9pJ1JemsDoJ9qxJGte+R8a/Nr09kVMuZTV8nTja4/1GC31+7jmuy1ZXHtTn6
dqujuWs2yFTHqOlqxIX1SB3e/302BGDmvAhD+WrCSQllr00V/yJWb1r17tIkuaSc+9pM4hpvrHrrx5v
ntoIB3C5VNoHGLqLyuKsPHpZzSYNaMbsO/HdjsIpN0ZYYsSszYF6ib8+GlA+uglyVLpOT7UQDpoaBPm
hjjwkxPztgbTLncDJvxs+hJMn5V4vebExKxci6NNJ9NMSnlZQ8ozvXzf9aWmf2OZMDPtUoip310uzcb
ndmiY6a8OZsaKxFzjhiz2J63aOnrb6cnrhoz1H6suFdk6OEFTtozP1W/hlGYaawZW2pc/ObGrmb00uZ
GZuSy3AABWUDggHgAAAJABAJ0BKj4AFQAAAAAlpAADyWiYeAD+/97c8AAAAA==
""")
KOPPS_FLAVOR_URL = "https://kopps.com/wp-json/kopps/todays-flavors"
TEXT_COLOR = "#fff"

def normalize_flavor_name(name):
    name = name.strip().upper()

    # Replace special apostrophes
    name = re.sub(r"[‘’]", "'", name)

    # Replace accented characters
    name = re.sub(r"[ÁÀÂÄÃÅ]", "A", name)
    name = re.sub(r"[Ç]", "C", name)
    name = re.sub(r"[ÉÈÊË]", "E", name)
    name = re.sub(r"[ÍÌÎÏ]", "I", name)
    name = re.sub(r"[Ñ]", "N", name)
    name = re.sub(r"[ÓÒÔÖÕØ]", "O", name)
    name = re.sub(r"[ÚÙÛÜ]", "U", name)

    # Remove special characters
    name = re.sub(r"[^\w '&]", "", name)

    return name

def get_best_wrapped_text(text):
    word_lengths = [len(word) for word in text.split()]

    def count_lines(max_line_length):
        # We always start with 1 line
        lines = 1

        # The -1 counteracts the +1 we have to add for spaces
        line_length = -1

        for word_length in word_lengths:
            if line_length + word_length + 1 > max_line_length:
                lines += 1
                line_length = -1
            line_length += word_length + 1

        return lines

    # The font should be as big as possible while fitting all the text.
    # I'm basically eyeballing this.
    if count_lines(6) <= 1:
        font = "10x20"
    elif count_lines(10) <= 2:
        font = "6x13"
    elif count_lines(13) <= 4:
        font = "tb-8"
    else:
        font = "tom-thumb"

    return render.WrappedText(
        color = TEXT_COLOR,
        font = font,
        align = "center",
        content = text,
    )

def get_flavors():
    # Request Kopp's flavor JSON
    rep = http.get(KOPPS_FLAVOR_URL, ttl_seconds = TTL_SECONDS)
    if rep.status_code != 200:
        return None

    return rep.json()

# HACK This function wouldn't exist if list unpacking worked like Python
def render_static_screen_frames(child, duration):
    return [child for _ in range(duration)]

def render_failure(text):
    return render.Root(
        # HACK This is the only way I know how to change the marquee
        # speed. But it also changes the speed of everything else.
        # Therefore, the obvious solution is to include nothing else.
        delay = ERROR_DELAY,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    height = HEIGHT - KOPPS_ICON_HEIGHT,
                    child = render.Marquee(
                        width = WIDTH,
                        offset_start = WIDTH,
                        offset_end = WIDTH,
                        align = "center",
                        child = render.Text(color = "#f00", content = text),
                    ),
                ),
                render.Image(src = KOPPS_ICON),
            ],
        ),
    )

def main():
    # Get the current month name
    current_time = time.now().in_location(TIMEZONE)
    current_month_name = current_time.format("January").upper()

    # Get this month's flavors of the day
    flavors = get_flavors()

    # If failed to retrieve flavors
    if flavors == None:
        failure_reason = "Could not get flavors"
        return render_failure(failure_reason)

    # Output will be rendered as a series of frames
    frames = []

    # "TODAY AT KOPP'S"
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    height = HEIGHT - KOPPS_ICON_HEIGHT,
                    child = render.Text(
                        color = TEXT_COLOR,
                        content = "TODAY AT",
                    ),
                ),
                render.Image(src = KOPPS_ICON),
            ],
        ),
    ))

    # Flavors of the day
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Box(get_best_wrapped_text(
            normalize_flavor_name(flavors["flavor_1"]["name"]),
        )),
    ))
    frames.extend(render_static_screen_frames(
        duration = 9,
        child = render.Box(get_best_wrapped_text("AND")),
    ))
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Box(get_best_wrapped_text(
            normalize_flavor_name(flavors["flavor_2"]["name"]),
        )),
    ))

    blank_screen = render_static_screen_frames(
        duration = 5,
        child = render.Box(),
    )
    frames.extend(blank_screen)

    # "THE ___ SHAKE OF THE MONTH"
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Box(
            get_best_wrapped_text(
                "THE {} SHAKE OF THE MONTH".format(current_month_name),
            ),
        ),
    ))
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Box(get_best_wrapped_text(
            normalize_flavor_name(flavors["featured_shake"]["name"]),
        )),
    ))

    frames.extend(blank_screen)

    # "THE ___ SUNDAE"
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Box(
            get_best_wrapped_text("THE {} SUNDAE".format(current_month_name)),
        ),
    ))
    frames.extend(render_static_screen_frames(
        duration = 18,
        child = render.Box(get_best_wrapped_text(
            normalize_flavor_name(flavors["featured_sundae"]["name"]),
        )),
    ))

    frames.extend(blank_screen)

    return render.Root(
        delay = DELAY,
        child = render.Animation(children = frames),
    )
