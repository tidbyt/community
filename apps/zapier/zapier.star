"""
Applet: Zapier
Summary: Integrate with Zapier
Description: The Zapier app allows you to trigger information on your Tidbyt from a Zap.
Author: Tidbyt
"""

load("render.star", "render")
load("schema.star", "schema")
load("encoding/base64.star", "base64")

def main(config):
    primary = config.str("primary", "")
    secondary = config.str("secondary", "")
    alternate = config.str("alternate", "")

    notification_type = config.str("type", DEFAULT_TYPE)
    icon = MESSAGE_TYPES[notification_type]["icon"]
    alt_color = MESSAGE_TYPES[notification_type]["color"]

    # Return if there is no primary text
    if primary == "":
        return []

    # Center core notification if there is no alt text.
    if alternate == "":
        return render.Root(
            child = render.Box(
                padding = 2,
                child = render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        render.Box(
                            height = 5,
                        ),
                        render_core(primary, secondary, icon),
                        render.Box(
                            height = 5,
                        ),
                    ],
                ),
            ),
        )

    # Render the full view if there is an alt text.
    return render.Root(
        child = render.Box(
            padding = 2,
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    render_core(primary, secondary, icon),
                    render.Box(
                        height = 1,
                    ),
                    render.Marquee(
                        width = 60,
                        child = render.Text(
                            content = alternate.upper(),
                            color = alt_color,
                        ),
                    ),
                ],
            ),
        ),
    )

def render_core(primary, secondary, icon):
    if secondary == "":
        return render.Box(
            height = 20,
            child = render.Row(
                children = [
                    render.Image(
                        src = base64.decode(icon),
                        width = 16,
                        height = 18,
                    ),
                    render.Box(width = 2),
                    render.Column(
                        children = [
                            render.Box(height = 4),
                            render.Marquee(
                                width = 42,
                                child = render.Text(
                                    content = primary,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        )

    return render.Box(
        height = 20,
        child = render.Row(
            children = [
                render.Image(
                    src = base64.decode(icon),
                    width = 16,
                    height = 18,
                ),
                render.Box(width = 2),
                render.Column(
                    children = [
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = primary,
                            ),
                        ),
                        render.Box(height = 2),
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = secondary,
                                color = "#8C8C8C",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = v["name"],
            value = k,
        )
        for k, v in MESSAGE_TYPES.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "primary",
                name = "Primary Text",
                desc = "Primary message text.",
                icon = "heading",
            ),
            schema.Text(
                id = "secondary",
                name = "Secondary Text",
                desc = "Secondary message text.",
                icon = "font",
            ),
            schema.Text(
                id = "alternate",
                name = "Alternate Text",
                desc = "Secondary message text.",
                icon = "font",
            ),
            schema.Dropdown(
                id = "type",
                name = "Notification Type",
                desc = "The type of notification to display.",
                icon = "gear",
                default = DEFAULT_TYPE,
                options = options,
            ),
        ],
    )

DEFAULT_TYPE = "generic"

# To add an icon, create a 16x18 pixel png file and run the following and paste
# the results: cat icon.png | base64 | fold | pbcopy

GENERIC_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAACXBIWXMAAC4jAAAuIwF4pT92AAABFklE
QVQ4jZXTzU7CQBQF4K+kLBCRRCNCqkRf06fyPfxjQ2JcGk1cqRElYaF10ZlQYGjwJE2nt+eeOXPn3uzy
qtSAz/A+2EbIt8Q76KMXvgu8Y75ObCWSj/AQnogpHjFoEshwjAnGwUFEP7iY4CRwNwRK3OA04SpihNvA
XRHIgvK4ITmiCEJZXaCD67pyA8rA7bK8hRbOdkiObou4eXRQ4mNHAar+KOsC33azH1FiVhc4lu6JbWhh
GBcD3Gto1wT2cYdhjme0/5FMVcgRnnL8YIHf8LPEm82aZDi07MIM7Vx1/myN3EvEWE5nRJnjK0GcBkfR
RaY6ZrFOTI1zVzWRe2vxharQKy5SVzfHBV5Udz3DK87DegV/vJUy/l4a2gQAAAAASUVORK5CYII=
"""

SLACK_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAACXBIWXMAAC4jAAAuIwF4pT92AAACQklE
QVQ4jaWUQWgTQRSGv5ndJLubNG2JtlpiPPSi1lsPCiJexN70VAQVVBAvHvRSKEJB1JNeiqeKiHfBg/Qi
QgUVCx70ZNWDoVrSojZRk2yS3e3ujIdsq7ZBCn3weG9mfn7mzf/mCa01WzHzwGx1/d5h4IEQdlOr6hGv
ftfTqvpSCLsXuAjM/EPQgXQKGIzzk0ATGI7Xd4Chv8GyA8F0O2jAKIBMt3MAwg0ldCAYBx4jjC6tG/No
75zA+C/BQWAMcAAFeMBnMIta/XqKagiktYpvxXEiLmvSBJ4DyQ330CtIo9/H6FnSqoYQNkAZOARcj1En
zHpXpgwMKClI+QGWF9BI26hEAsKs23TteXQLRJKaSL1J6bDfISRCAFTMvu/lPcBoYiXMVXK9O0v5bHL3
lx+fHE8UQ+lO+8olFN6oCd3H1ML9b6RZEJkxi+gn8MicunS1DrQsz/cWdg2MFwfzwfDb92ec5UBHfRp7
4h3kwq/SlT15XbtZE5ZRxiolUD5QF5Xe43PAPiUNbK91Ot3wnGo2cy9oJTH7gpHMZFEYufBJ5Bo0SZAk
IkWEapdQMutdmb2r79ZI26VyjlMA2jSQ6eT+iFRdItGxlCEmzT/q503gKHADmANeAJcBhKOIFq1C9DFz
xRhZ3qZdYwgoABbtBmwBt03gWeyrlgXQgUB2r2i53S9oX76O5Z5dr3anVm5bIBA94bzY4Z/FN2aAV8Ct
zRA4ayehCAnkEnLtL1zYDME1YBEoAg9j/wAsAefXg8VWB8pv0SnWrEYYD8cAAAAASUVORK5CYII=
"""

SHOPIFY_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAACXBIWXMAAC4jAAAuIwF4pT92AAAFG2lU
WHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhp
SHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0
az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuZGFiYWNiYiwgMjAyMS8wNC8xNC0wMDozOTo0NCAg
ICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJk
Zi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRw
Oi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1l
bnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4w
LyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0
PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVh
dG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIyLjQgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIy
MDIyLTA2LTI4VDE3OjA2OjQ5LTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wNi0yOFQxNzoxMTo0
Mi0wNDowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMi0wNi0yOFQxNzoxMTo0Mi0wNDowMCIgZGM6Zm9y
bWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxl
PSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpkZmEwYmQ1Ni0xNjM4
LTQ2OTYtYWRiYS1iNDE3YzQwYTQxNTQiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6ZGZhMGJkNTYt
MTYzOC00Njk2LWFkYmEtYjQxN2M0MGE0MTU0IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5k
aWQ6ZGZhMGJkNTYtMTYzOC00Njk2LWFkYmEtYjQxN2M0MGE0MTU0Ij4gPHhtcE1NOkhpc3Rvcnk+IDxy
ZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1w
LmlpZDpkZmEwYmQ1Ni0xNjM4LTQ2OTYtYWRiYS1iNDE3YzQwYTQxNTQiIHN0RXZ0OndoZW49IjIwMjIt
MDYtMjhUMTc6MDY6NDktMDQ6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAy
Mi40IChNYWNpbnRvc2gpIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8L3JkZjpEZXNjcmlw
dGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PtFJmLwAAAKvSURB
VDiNbZJLbIxhFIaf8/2XubSdMuNa1SoxqohbSUNiQaRYYCEiLCQSiYTEUmJjR2LDAgkLK0sbrCSkDREi
Eg0STRpFXKrRRjsz+nfm///vWHSMaHuS8y2+nPdJ3vccud7TzSx1BDgIrAY+eZ6cKxRt/4dPZQCMEerS
BlUws4j3ACeBZ0AArACuAi1GZg7PBjgFXALmVUG3rWWe5/HZGLljLeI4YGSq3WnibmAQSFZtbAd2oeA6
Qrmix4JAtzmGvrLR01YZ+gvwgR0g50XYEVTGzgThuGetzdcnc9Qns8RxCEAl0rbib9r8hF5M+lIDXBbk
rMUyPvGd+fUrvY0th6lPzOfjyHOGi28xpKsBAgKCrBdjXv0FtAMUgiE2NB9i77oLNU9BOM7gaC8Nfqr2
J0AwaVfFVmsZLCtVRmjJdtbEX3/14Rqfz6MvSbqZqmzqjWLFGLMg0+DgAg1ArhJN0JLtBOD90ENuPtnP
gkyeOaklpP25hJH9tzojRJFuKRYtBmitrgxFAVi9uJujW28hGMphEeT/AxAgirROzNQdNAHU+TnefbvP
z+IAAFvbjnNo0xViDYltZea1iLQmPFlrgKUgpLxGfhT6udazm4HhXgBWLtxJ89xNBJWxaVqIY6VQss0G
yKvGhHaSfWsvsCzXRf/wo9qw5ySwamcCLHiutLpAUyUOqPOzrFtygK7lJ2qDo6VBvo+9I+llqMbzfw6x
bjZAm+ckmYwKPB24wUhpkHJU4uuvPh68Oc9kOI7vpJhe1irWaqMLtDriYsTh9Ze7vP12j7Sf5Xd5BMd4
NCQXocQzAIoQx2xzgd2K5oE1janF7VajjljDfDqRyxhxsRrhIIiAtVPeHQXPBYUJF+iv9n0AIy5G3ASw
CrQd6AA6VFmf8CVnVV4kfHnsedIL9P0BV+sCDO50NAcAAAAASUVORK5CYII=
"""

GITHUB_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAACXBIWXMAAC4jAAAuIwF4pT92AAABQ0lE
QVQ4jaWUvUoDURCFz65JZ5EUEkJUsNHGSrESthAsfAIfwiaYyk60FsEivaXvIBZa+FsoAcE2FmkSESKo
IH4WmSuTzQ8LGRju3JlzDjvD3I0ATWK5IbmCpG1JiaQNy11IupR0Jum9Dw143wE6jLaOYf45nlwfQ0xb
PS1Qs8IzcAJ8OPCvnZ9We7J7LQhUHPjIBMtAAsybJ8Cc1Q4cvpKTVHUjKdnZMg/WdHHZxVUBDae4Tv9Q
h/kK8GP4hoCuXZoZyMFfjNONJeXH7MQoC5x8LKntelvMQK5IWrC4HUt6cMXzDAKnLr4XsGX9HAI3wBdw
DCy7npeAvdTAATYD4NEGEwG3VlxzAqsM2hVuEwuWvAOKQCk19SngzZFbxul7C7PAqwG+TSjUph35mt6m
Djym4Pv03sSMyxXtk3fT+IgJfyh/04ByjCE9lZ0AAAAASUVORK5CYII=
"""

MESSAGE_TYPES = {
    "generic": {
        "name": "Generic",
        "icon": GENERIC_ICON,
        "color": "#7AB0FF",
    },
    "slack": {
        "name": "Slack",
        "icon": SLACK_ICON,
        "color": "#2EB67D",
    },
    "shopify": {
        "name": "Shopify",
        "icon": SHOPIFY_ICON,
        "color": "#95BF47",
    },
    "github": {
        "name": "GitHub",
        "icon": GITHUB_ICON,
        "color": "#FFFFFF",
    },
}
