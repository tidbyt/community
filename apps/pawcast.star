# Pawcast - safe dog-walk time from temp + humidity

load("render.star", "render")
load("math.star", "math")

def clamp(x, lo, hi):
    if x < lo: return lo
    if x > hi: return hi
    return x

def heat_index_f(temp_f, rh):
    T = float(temp_f)
    R = float(rh)
    HI = (-42.379
          + 2.04901523*T + 10.14333127*R
          - 0.22475541*T*R - 0.00683783*T*T - 0.05481717*R*R
          + 0.00122874*T*T*R + 0.00085282*T*R*R - 0.00000199*T*T*R*R)
    return clamp(HI, -40, 140)

def risk_and_minutes(hi_f):
    if hi_f < 80:   return ("Low Risk",     "45-60 min")
    if hi_f < 90:   return ("Med Risk",     "30-45 min")
    if hi_f < 100:  return ("High Risk",    "15-20 min")
    if hi_f < 110:  return ("Very High Risk",  "5-10 min")
    return ("Dangerous", "Skip")

def risk_color(risk):
    if risk == "Low Risk":     return "#61e827ff"  # green
    if risk == "Med Risk":     return "#ffd900ff"  # yellow
    if risk == "High Risk":    return "#ffa600ff"  # orange
    if risk == "Very High Risk":  return "#fe0000ff"  # red
    return "#000000ff"                       # black

def fmt_int(x):
    return str(int(math.round(float(x))))

# White text with 1px black outline (layered copies)
def outlined_text(content, font=None, fill="#FFFFFF", stroke="#000000"):
    base_args = {"content": content, "color": stroke}
    if font != None:
        base_args["font"] = font
    fill_args = {"content": content, "color": fill}
    if font != None:
        fill_args["font"] = font

    return render.Stack(children = [
        render.Padding(pad=(1,0,0,0), child=render.Text(**base_args)),   # down 1
        render.Padding(pad=(0,1,0,0), child=render.Text(**base_args)),   # left 1
        render.Padding(pad=(0,0,1,0), child=render.Text(**base_args)),   # up 1
        render.Padding(pad=(0,0,0,1), child=render.Text(**base_args)),   # right 1
        render.Text(**fill_args),                                        # center (white)
    ])

 

def main(config):
    # Inputs & defaults
    if "temp_f" in config:
        temp_f = float(config.get("temp_f"))
    elif "temp_c" in config:
        temp_f = float(config.get("temp_c")) * 9.0/5.0 + 32.0
    else:
        temp_f =50.0
    rh = float(config.get("humidity", 20))

    hi = heat_index_f(temp_f, rh)
    (risk, minutes) = risk_and_minutes(hi)

    bg = risk_color(risk)
    raw = fmt_int(temp_f) + " F  " + fmt_int(rh) + "%"

    return render.Root(
        child = render.Box(
            width = 64, height = 32, color = bg,   # background = risk color
            child = render.Padding(
                pad = (1, 1, 1, 1),
                child = render.Column(
                    children = [
                        # Top line: length of walk (only)
                        outlined_text(minutes, font="6x13"),
                        # Middle line: temp + humidity
                        outlined_text(raw),
                        # Bottom line: risk description
                        outlined_text(risk),
                    ],
                    main_align = "start",
                    cross_align = "start",
                ),
            ),
        )
    )


