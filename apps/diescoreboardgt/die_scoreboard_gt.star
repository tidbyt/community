"""
Applet: Die Scoreboard GT
Summary: Beer Die Scoreboard for GT
Description: Beer Die scoreboard with dropdown menus to keep track of score. Customized with logos for Bizz (5) and Buzz (7) with a red solo cup and Georgia Tech's mascot Buzz.
Author: zachtempel3
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

NUMBER_IMGS = [
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAqSURBVHgBY7B/wDD/BMP5GQwPLPChAxIMDRwMYABkALn41QMNBBoLNBwAHrcge26o7fIAAAAASUVORK5CYII=""",  # 0
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAZSURBVHgBYwABDgYGCQYGC7xIAqyMgVT1AOfwBOG2xNZsAAAAAElFTkSuQmCC""",  # 1
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBY7B/wCB/goF/BgODBV4kAVQGVAxC8w8wHGBgeIAXnW8AKgMqBgBzoBbH0MZ6/gAAAABJRU5ErkJggg==""",  # 2
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAlSURBVHgBY7B/wCB/goF/BgODBV4kAVQGVAxRD+TiVw80EKIeAJk5DfdkeUVkAAAAAElFTkSuQmCC""",  # 3
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBYwCCBg6GAxIMDyzwIJCC+ScY7B+AkPwJBgYJBgYLPAisgANoNgDVyhQd//DRbQAAAABJRU5ErkJggg==""",  # 4
    """iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAADKSURBVFhH7Y5BDsIwEMTyEI78/2e8AZRqqgStU9p0p3DAki/VZN3yuN2f36K2lx9YvYq+WSr9Bzd9a4lX+o+r2VBDef6BK1T+/wM/8AMVGjhVtkEjp8o2aORU2QaNnCrboJFTZd+hoUPlIjR2qFyExg6Vi9DYoXIRGjtULkJjh8pFaOxQuQiNHSoXobFD5Rh6kKkyY+hRpsqMoUeZKrMNPcxQ5z9DjzPU+X3QgTPq7H7oyBl19hh0aEadOw4dm1Hn5qCDR9SZAaW8ALn9t6JfOjeAAAAAAElFTkSuQmCC""",  # bizz
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBY7RfyDhfkfH8RsYHCvjQAQegMqBisHpNxgMRjA/wovMngcqAigEwiCIRDKuGtwAAAABJRU5ErkJggg==""",  # 6
    """iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAG9SURBVFhHxZXNUsMwDIQT7vD+Nx6Fdyp3ilddmY0i/6UDfDNpHcvaXTuhbMrXbfvAxdv/49kg9wKHY+63sr5cvD2AEKithIG5w6kDLBmcetALAkqIdw6bUPcAS2kNsPyDB9EwfhJ+tU6EmpVsLmKNGWrIKRPj0EJxaJiakM1FsGbHh6Nm+1uosQHsBXz7eqyNdb1vgXXVBGJqGu8BRGMPh9v2+hiiPmuO7xd8zJgDb8pADayYAwugHHbVwUMegou5pRE4beg6CwARCK6aqxCgl+F6DqdPJ3g6Ad9RFsZFM3NQTbNewhw1yMHMTwLjFmoOoWEvX06g6wF6TifQw80hBNRcvx3cA96eQP94B0TF4y44NGIoJdMfBnChWMsMItqT6WOuG6A1x+EUMQSHlZeWoJpj7JcVLxI3A6pgL2nWCEaBYh/WY077+gL4c/vcT6dhxUIrWCT2TAUwc1ACAG3KcOEYKvbFANO/Ayu71YvTTZoB4g/IjBhC9oJmtaHoDC1TDe1r4kZ+NUBGDLD0v6AHhEePaVS/zMwJrJzSJXoGf2KembTmlaeeyVB84plfDtAyX33RLgXIzK+94dv2Dew3EB1psnP6AAAAAElFTkSuQmCC""",  # buzz
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAmSURBVHgBY7B/wDD/BMP5GQwPLPChAxJAZUDFEPVALn71QAMh6gHctSR33GtExAAAAABJRU5ErkJggg==""",  # 8
    """iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAuSURBVHgBY7B/wDD/BMP5GQwPLPChAxJAZUDFICR/goFBgoHBAh/in8EgD1IPAMkGGTcArQUNAAAAAElFTkSuQmCC""",  # 9
]

def render_seperator():
    return render.Box(
        width = 2,
        height = 100,
        color = "#d30",
        child = render.Image(src = base64.decode(
            """iVBORw0KGgoAAAANSUhEUgAAAAQAAAAOAQAAAAAgEYC1AAAAAnRSTlMAAQGU/a4AAAAPSURBVHgBY0gAQzQAEQUAH5wCQbfIiwYAAAAASUVORK5CYII=""",
        )),
    )

def get_num_image(num):
    specialNum = int(num)
    if specialNum == 5 or specialNum == 7:
        return render.Box(
            width = 32,
            height = 32,
            color = "000",
            child = render.Image(src = base64.decode(NUMBER_IMGS[specialNum])),
        )
    else:
        return render.Box(
            width = 13,
            height = 32,
            color = "fff",
            child = render.Image(src = base64.decode(NUMBER_IMGS[specialNum])),
        )

def main(config):
    firstTeamScore = "%s" % config.str("team1", "00")
    secondTeamScore = "%s" % config.str("team2", "00")

    if int(firstTeamScore) == 5 or int(firstTeamScore) == 7:
        if int(secondTeamScore) == 5 or int(secondTeamScore) == 7:
            return render.Root(
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "space_evenly",
                    children = [
                        get_num_image(firstTeamScore),
                        get_num_image(secondTeamScore),
                    ],
                ),
            )
        else:
            return render.Root(
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "space_evenly",
                    children = [
                        get_num_image(firstTeamScore),
                        render_seperator(),
                        get_num_image(secondTeamScore[0]),
                        get_num_image(secondTeamScore[-1]),
                    ],
                ),
            )

    if int(secondTeamScore) == 5 or int(secondTeamScore) == 7:
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "space_evenly",
                children = [
                    get_num_image(firstTeamScore[0]),
                    get_num_image(firstTeamScore[-1]),
                    render_seperator(),
                    get_num_image(secondTeamScore),
                ],
            ),
        )

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "space_evenly",
            children = [
                get_num_image(firstTeamScore[0]),
                get_num_image(firstTeamScore[-1]),
                render_seperator(),
                get_num_image(secondTeamScore[0]),
                get_num_image(secondTeamScore[-1]),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "0",
            value = "00",
        ),
        schema.Option(
            display = "1",
            value = "01",
        ),
        schema.Option(
            display = "2",
            value = "02",
        ),
        schema.Option(
            display = "3",
            value = "03",
        ),
        schema.Option(
            display = "4",
            value = "04",
        ),
        schema.Option(
            display = "5",
            value = "05",
        ),
        schema.Option(
            display = "6",
            value = "06",
        ),
        schema.Option(
            display = "7",
            value = "07",
        ),
        schema.Option(
            display = "8",
            value = "08",
        ),
        schema.Option(
            display = "9",
            value = "09",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "11",
            value = "11",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team1",
                name = "Team 1 Score",
                desc = "Input Team 1 Score",
                icon = "1",
                default = "00",
                options = options,
            ),
            schema.Dropdown(
                id = "team2",
                name = "Team 2 Score",
                desc = "Input Team 2 Score",
                icon = "2",
                default = "00",
                options = options,
            ),
        ],
    )

OLD_NUMS = [
    """
    iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAuSURBVHgBY7B
    /wDD/AMP5BoYHDPjQAQagMqBiEJI/wcAgwcBggQ/xzwAqAyoGABq+Fsfy3SMpAAAAAElFTkSuQmCC
    """,  # 5
    """
    iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAhSURBVHgBY7B
    /wCB/goF/BgODBV4kwcDAwQAFHEAukeoB0jsHbnVM+9YAAAAASUVORK5CYII=
    """,  # 7
]
