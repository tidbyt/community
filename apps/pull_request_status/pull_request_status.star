load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64

CLOSED_ICON = "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAHESURBVHgB1VTRbcJADLUvtKr60wzQoPBLhYSAAcIGbABMgJgANqBMAIzABNB/hFAl4BMEHSBVEf0od67vkhSQCP2AfvRJEMd3fn52fAdwZWBkzAuuRyRrbNpE0Hsar7txQbN8sgZIbnq0ri881/78kB0gfEmPV8+JiEyRHByk8Wa5pK03nKakEif1pnnH3m52WQ7IcgJfrwj9pwJlnETVgaAKwUo5TiFKq4qASzYrHMRkOLmXVl2vJY7yws3EuoWl+pJwDnc2+NuN8pksDKRJarLcK2SmvnnhsplsoW2m7McRboOeGWWR0mkh2fwhNB+ASyVAPyo9M1o14wgJ4B0Rhvc7UUQpippYndrITV7wj+ACCLgAs7wzmBWc1tUIuRSeXShdjfAU/hGhOZ8ArrbnuWTjt8Bwv4Y9zTmVyG9G3TgQOocBSFiPO8vz3GNDITaPnDzHep6NQh7ScuQU0koZE6kGMVBCmC+r9yqkYijN+BIBD/iBD232uNqBGJyac1BCehaJB4L9WTCEnKUtCEusqsV3YiBWUTuOiBT0uKqsblNExr3rhs8Ar3mnZEWlK+ifu2A1dN+RrzhdnQJqZ0ZvQ/gLfAM46sKcL21hmAAAAABJRU5ErkJggg=="
MERGED_ICON = "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAHRSURBVHgBxVRLTuNAEK2qzkcajQSraLIac4OZHZ8FyQ1yAxLx2QInIJwA2CKQ4QSEExAWfHYJJ8A7RDawASTH7qIqxsEGAjIg8WSr3eXu5+p69QzwzcDkxJ28cqyhNQZ0wEJr4ay0BRmBKTKiIwZwhi8R9+ZPSg3IAIofAsRaREYtC/hf6G6Zue5WLschA+hlABG8fOHOQ+Bb+ASGhDnmVpSVXQn9XzdPR2812hOZiIeEjfOyZwGqUlQvjpnCfab6DRJLTpZOS92dqetjkcrRufV/L8uw/tZGFTHAXG1AUgzkJGUvleFbYLDN3Zme61aunGR8e7r3LyTTQbQbeoc+HcVrciPJmFcJcVmVlg31nZleW4Tynl5WpMaiPkuf4l+J1GzfrMnYGEkIxnQpCKohUlOUn+WIJL2k8NDs+3mHIF+L+3c0IURCyVCPj4kUDnoSQ6pLneekGzoEqJkCW3v4IWESKlj87FZuuqHvj+lRlUyu/cWzP5uDjyU3aRYG+CDuQW2b9/owdlFyTcrLqpx87tlqiO2Fk1IVMiDlZSVDpE1j7YS6RtX8spcVfTLjX/dysbintlMvE3AnqiNvZfXyqx+s9p1Ex8QlF4un5Sb8NB4BxW7HDI3uX3UAAAAASUVORK5CYII="
OPEN_ICON = "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAHPSURBVHgB5VQ9UsJQEN59CTN2xlrFWCszOQKcQCzRQjyBegL1BOoJgAYYG7kB3MDMiLVR7KWUIS/r7gtIkADDjFZ+zfv73vd2k/0WYEW4Dc9ddG4nF9nG/iUheEDYt8C6Dkp+kDzfbuQqEYSvPL2aJ6i+xZq5GxIiQRGAyhp0233wnKSY7MMSoEmj4jl6LfxAwEBb0SGGWEaEMyS6eDt6vp0SQ+zzo31eB7yo9UpP1dQIBYTkZHSmjwppvCePsbA3IRFHTS7P8jxWtuu54oxgcOrzi9Dhlx0N4QtfOkeORGGmJWdqYBf4CX+U0nWv1OUBT+OI6Sw1QuvTPmR2K76EgdJWYfxTfooKJqmimyool4jgLuZEneDY95PEsaiK7BYsgA0rYPRp/EUcBb+M/ywoNuNyOZE5kcpv3u95iy5mm/tx/bEZ2EnlGUE9CBNeJVdF2J7XWbakiRDcxlRwjGNGokZQ7CVNQQraWrM3TD0yMaJhMTUt00DYDGDvskcL8W5k9qbqULwMw6GLSu1w3rAM3JHyCmE9SZ14mbBmvKzxkcVMtOLldClVG4VQmaSuqjJgkpat752TwgPk1qQoM9NgkzDfDEl+orHse6nbgb/AFylE0zzTO3DzAAAAAElFTkSuQmCC"

def read_repo_pr_label_setup(config):
    repo_pr_label_setup = []
    for i in range(3):
        pr = config.get("pr_" + str(i))
        if pr:
            entry = pr.split(" ")
            if len(entry) >= 3:
                repo_pr_label_setup.append(entry[:3])
    return repo_pr_label_setup

# returns "merged" or "closed" or "open"
def get_pr_status(repo, pr):
    
    api_url = "https://api.github.com/repos/" + repo + "/pulls/" + str(pr)

    response = http.get(api_url, ttl_seconds = 180)

    # Parse the response JSON
    if response.status_code == 200:
        pr_data = response.json()
        if pr_data["merged_at"] != None:
            return "merged"
        elif pr_data["state"] == "closed":
            return "closed"
        else:
            return "open"
    else:
        return None

def get_status_icon(status):
    if not status:
        return None
    if status == "merged":
        return MERGED_ICON
    elif status == "closed":
        return CLOSED_ICON
    else:
        return OPEN_ICON

def main(config):
    repo_pr_setup = read_repo_pr_label_setup(config)

    repo_pr_status_list = [[repo, pr, label, get_pr_status(repo, pr)] for repo, pr, label in repo_pr_setup]

    elements_to_display = [[label, get_status_icon(status)] for repo, pr, label, status in repo_pr_status_list]

    if len(elements_to_display) == 0:
        return []

    # hide_after = config.str("hide_after")

    # displaying_prs = []
    # for repo, pr, status in repo_pr_status_list:
    #     # check in cache if in cache
    #     # if yes: get update time and status
    #     # if changed: update value and time
    #     if (hide_after == "never"):
    #         continue
    #     hide_after_hours = int(hide_after)

    image_height = min(int(24/len(elements_to_display)),15)
    return render.Root(
        render.Padding(
            render.Column(
                [
                    render.Text(
                        "PR-Overview",
                        font = "tom-thumb",
                    ),
                    render.Box(
                        width = TIDBYT_WIDTH,
                        height = 1,
                        color = "#ffffff",
                    ),
                ] +
                [
                    render.Row(
                        [
                            render.Marquee(
                                render.WrappedText(
                                    label,
                                    font = "tom-thumb",
                                ),
                                width = 62-image_height,
                            ),
                            (render.Image(
                                src = base64.decode(status_icon),
                                height = image_height,
                            ) if status_icon else render.Text(
                                "?",
                            )),
                        ],
                        main_align = "space_between",
                        expanded = True,
                        cross_align = "center",
                    )
                    for label, status_icon in elements_to_display
                ],
                expanded = True,
                main_align = "space_evenly",
            ),
            pad = (1, 0, 1, 0),
        ),
    )

# HIDE_AFTER_OPTIONS = [
#     "never",
#     "1",
#     "2",
#     "10",
#     "24",
#     "48",
# ]

def get_schema():
    # hide_after_schema_options = [
    #     schema.Option(
    #         display = "Never" if option == "never" else (option + " hours"),
    #         value = option,
    #     )
    #     for option in HIDE_AFTER_OPTIONS
    # ]

    return schema.Schema(
        version = "1",
        fields = [
            # schema.Dropdown(
            #     id = "hide_after",
            #     name = "Hide merged PRs after",
            #     desc = "Hide a merged pull request after a certain amount of time",
            #     icon = "clock",
            #     default = HIDE_AFTER_OPTIONS[0],
            #     options = hide_after_schema_options,
            # ),
            schema.Text(
                id = "pr_0",
                name = "Repository and Pull Request 1",
                desc = "First Repository and Pull Request (seperate repo id, pr and labelwith space)",
                icon = "git",
            ),
            schema.Text(
                id = "pr_1",
                name = "Repository and Pull Request 2",
                desc = "Second Repository and Pull Request (seperate repo id, pr and label with space)",
                icon = "git",
            ),
            schema.Text(
                id = "pr_2",
                name = "Repository and Pull Request 3",
                desc = "Third Repository and Pull Request (seperate repo id, pr and label with space)",
                icon = "git",
            ),
        ],
    )
