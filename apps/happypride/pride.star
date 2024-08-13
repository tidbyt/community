#######################################################################
# happypride: a simple "happy pride" application for the Tidbyt
# display device.
#
#
# Copyright (c) 2024 Robin Knauerhase. Distributed under MIT license,
# see LICENSE
#

# Would love to be informed if you find this useful or make
# improvements: robincode@knauerhase.com

# This work is my own (produced on equipment I own and not on "work
# time") for my current/past/future employer(s)
#######################################################################

load("render.star", "render")
#load("time.star", "time")

def main():
    #timezone = config.get("timezone") or "America/New_York"
    #now = time.now().in_location(timezone)

    pridew = 64
    prideh = 5  # 32 div 6
    transh = 6  # 32 div 5

    # wow I'd like cpp and #define in StarLark...
    # Pride colors
    rp = "#FF0000"
    op = "#FFA500"
    yp = "#FFFF00"
    gp = "#008000"
    bp = "#0000ff"
    vp = "#9400d3"

    # trans colors
    bt = "#0096ff"
    pt = "#ff69b4"
    wt = "#ffffff"

    # border colors
    gray = "#7f7f7f"
    purewhite = "#ffffff"

    # border for both flags
    edge = render.Box(width = 64, height = 1, color = gray)

    # Pride stripes
    prstripe = render.Box(width = pridew, height = prideh, color = rp)
    postripe = render.Box(width = pridew, height = prideh, color = op)
    pystripe = render.Box(width = pridew, height = prideh, color = yp)
    pgstripe = render.Box(width = pridew, height = prideh, color = gp)
    pbstripe = render.Box(width = pridew, height = prideh, color = bp)
    pvstripe = render.Box(width = pridew, height = prideh, color = vp)

    # trans colors
    #bt = render.Box(width=pridew, height=transh, color="#add8e6")
    tbstripe = render.Box(width = pridew, height = transh, color = bt)
    tpstripe = render.Box(width = pridew, height = transh, color = pt)
    twstripe = render.Box(width = 64, height = transh, color = wt)

    pflag = render.Column(
        children = [
            edge,
            prstripe,
            postripe,
            pystripe,
            pgstripe,
            pbstripe,
            pvstripe,
            edge,
        ],
    )
    tflag = render.Column(
        children = [edge, tbstripe, tpstripe, twstripe, tpstripe, tbstripe, edge],
    )

    #painfully construct the message
    happy = render.Text(content = "HAPPY ", font = "6x13", color = purewhite)
    pp = render.Text(content = "P", font = "6x13", color = rp)
    pr = render.Text(content = "R", font = "6x13", color = op)
    pi = render.Text(content = "I", font = "6x13", color = yp)
    pd = render.Text(content = "D", font = "6x13", color = gp)
    pe = render.Text(content = "E", font = "6x13", color = bp)
    pbangs = render.Text(content = "!!!", font = "6x13", color = purewhite)
    pride = render.Row(children = [pp, pr, pi, pd, pe, pbangs])
    tmpmessage = render.Column(children = [happy, pride])
    message = render.Box(height = 32, width = 64, child = tmpmessage)

    flip = render.Animation(
        children = [message, pflag, tflag],
    )

    return render.Root(
        delay = 1000,
        child = flip,
    )

#make it go
main()
