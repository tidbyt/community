load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_SHOW_CENTIBEATS = True

def time_in_beats(now):
    # The time zone to use is Biel Mean Time (BMT) - UTC+1, ignore daylight savings
    time_in_milliseconds = (math.round(now.nanosecond / 1000000)) + ((now.second + (now.minute * 60 + (now.hour + 1) * 3600)) * 1000)
    time_in_beats = math.round(time_in_milliseconds / 86400 * 100000) / 100000
    time_in_beats_integral, time_in_beats_fractional = str("%f" % time_in_beats).split(".")

    # format integral to be zero-padded to three digits
    time_in_beats_integral = int(time_in_beats_integral)
    if time_in_beats_integral < 10:
        time_in_beats_integral = "00%d" % time_in_beats_integral
    elif time_in_beats_integral < 100:
        time_in_beats_integral = "0%d" % time_in_beats_integral
    else:
        time_in_beats_integral = "%d" % time_in_beats_integral

    # format fractional to be two digits long
    time_in_beats_fractional = time_in_beats_fractional[0:2]

    return time_in_beats_integral, time_in_beats_fractional

def generate_frame(beats_integral, beats_fractional, show_centibeats):
    if show_centibeats:
        beats_time_string = "@%s.%s" % (beats_integral, beats_fractional)
    else:
        beats_time_string = "@%s" % beats_integral

    return render.Text(
        content = beats_time_string,
        font = "6x13",
    )

def main(config):
    show_centibeats = config.bool("show_centibeats", DEFAULT_SHOW_CENTIBEATS)
    now = time.now().in_location("UTC")
    frames = []

    for _ in range(30):
        beats_integral, beats_fractional = time_in_beats(now)
        frames.append(
            generate_frame(beats_integral, beats_fractional, show_centibeats),
        )
        now = now + time.parse_duration("864000000ns")

    return render.Root(
        delay = 864,  # the length of one centibeat
        max_age = 120,
        child = render.Box(
            child = render.Animation(
                children = frames,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_centibeats",
                name = "Show Centibeats",
                desc = "Show the centibeats after the decimal place",
                icon = "clock",
                default = True,
            ),
        ],
    )
