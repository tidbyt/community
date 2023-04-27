"""
Applet: GitHub Repo
Summary: Display GitHub repo stats
Description: Display various statistics of a public GitHub repo.
Author: rs7q5
"""

#github_repo.star
#Created 20221223 RIS
#Last Modified 20230308 RIS

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

############
FONT = "tom-thumb"  #set font
BASE_URL = "https://api.github.com/graphql"

############
#stuff for open issues/prs
ISSUE_PR_COLOR = "#57ab5a"
STAT_COLOR = "#768390"
STAR_COLOR = "#daaa3f"
PENDING_COLOR = "#966600"
FAIL_COLOR = "#e5534b"

#images of icons
ISSUE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAnZJREFUOE+NU0tIlGEUPefO+MAHpGZGkSatggqJViZp7hQsWoz/zJTmVFAEqYsCd+quRQsziIJqfKTO6CJC0F0mmKsIqcBVmElQmc0iFdOZe2MGfjFB7Nt9j3O433kQ21ZNd01GXkHe/vgGSsRQokSeGGJKzHvTMB9bin0bbx7/48K4Fe/0OEdMvNWAnYSiEGAmaWlm3ABsDYJFgO+o8VfRpuinJHaTwB/2V6nwKozHACzQbFpF5iCJZagnR1RLjSwHcAi0j6L2NBKKvE4RXOhr2Jdu2g5YLYCXTOjwysbKzOj10VV3wrrHdVnZadll5pF6AOcBjq1TOlk1UeUtWjhwDoZrBrwX1UeRUOTzdm3cvT/sP6wiNwicAPGEvl5fsVjaHQjyNIF7I6HBmZ3A7rkvHCwTD25DEWOgL1CtylYj3vwuLOgar32wqXBgMLBX41ooXlkcCg79dAlqxm5l5C4utdJwmk5PIEQwoJDwcNPzIfdRCrxOH4hKGCYl3Ua2ktT3XAoINESnN9gCQ52Z3R8ODY26BE6fcxTmaQfgAIiCic5oY3TWva8PB+pIttAfDjYo6RjRP3J5IPq/E/h6Lzo0NLC+J3gGQDPN3q6uL3dvtW4nDZKWZqXnNBt5isGBYEk8gTYoDorq3ciVyPRuLvif+ctVpA2Cr0xmP3dPfiPUbpKYpGrXbjkwkVYzVEL4MJXEVAcoHQQrDIiaIrJcVDC71dKkdTnfl45S4CfgGGyKph3/dMHE4wOsFMQvM3yAyRdDfIXwZoNaTOI4DPkA56iJkc0uuH9OdQKJCijOAighkGmEl4a4AWsA5iGYWIdn6kVj/48k7i+RCic+VLxoAAAAAABJRU5ErkJggg==
""")
PR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAbpJREFUOE/Nk7FPFEEUxr9vji1MoMBKO2JiB9hB0AIuMdECEiDssbtCdq81JobYWqCJiSbERhuIsCzk9nb3TowhWBIa/wUbC40NUQs7aWCe2bnc5SB7CaVTzvzm9973Zpe4xFoInalmNTkqQtnezCGl1CTIn6c8+bi3vHecnzk7zrhovkyDermnwAmdISFDA5D9BA4SP151I3f0TPCK5P0zrcu0Sr8aS7Uv3SLTQSV0Z6n4IYdKJfUYIjdTvz5c2XafkFwzF0SOQP7WWn9qVJPttsQI7E13QvWxKcAGgBkKvqZB7FYi7y4hawBvCbBKwRAoU9RSTqrJd9OwEby2r6ir1jKI9bySQD3NgtpncxY5cwp8nvr1ERNVqW9a62q7i84Qc3gx8iSvlPnxs+6cduQsNPykWcRcStAtu1jkPxLYmX1NnVjHRTNoRyhiTIT5Le+GVcIKgEetV8DbLKi/787eizGCxdCzoVAT4AWAe/le5se3zw2vB9MSRA+mAdmHRkUUVggw9eOJ89MvZloRdpeuW1q/E8EgKQMQvkmDOP8qO6sX03lGO/LGKLgDyI++vzyMH8Z/Lv59Rcw/79j7ERrrQ4EAAAAASUVORK5CYII=
""")
WATCH_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAVFJREFUOE+lkztLQ0EQhc/ZGxMECxs7G3sLO7WLFoKPQoQI9kIaH4m4Pq6EhNxoIERv0mpvYWEKKxEfhYg/wKj4A7SwsRGLwI4kZCW+Cr3b7TDz7ZnZM0TAw4D1+BWQyPidYQdRkN2OUmd5d+H2p8e+AZazpX5C1kmOAgi3FFWF2JdIrVzU+tXGPwFWvHIaEJfAswC+EVx2GHX3RjMoigOAZAS4ISRdSCUP65APwGrWXxJym0RFKcfNu/P3XyVrrzxGSBFADwwnCunF0wZAZ/1ZknsgTl662sd34/FaI57zZ2AQCYXarvLu3EMjtun30fCIgCM0k9TezgihjgFeh5SZ2tpIPtUTm+1kmiqqhVSi1ypa8/xhAStG8MhmYsxx1HTrpLVXOicQtUUGMlRMJS/sXedKMQoOgisIPAMrKdAvWEggH1hIICe2Guffu/DX7XwHbabC0TZBFV4AAAAASUVORK5CYII=
""")
TAG_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAXlJREFUOE+Nkr1LQlEYxp/naklaoiIO0SC0NUTQ0nintsAiKZMQh/IvaLb+CQcJRIqCWgy3llyaIgjamiKoIQKF0kK9541rCLf7IZ7pfLznd87zPC8BIH2cjmmBQNLo98Pmejj8fnTRx1u4G34tF8o969lwzuxpNmwo2VDCdYr6BxCgB41PYsjVT3zmtr5W7tghzFQziwosghITYcNaQDAkxAIEbVCq39Hphh3Czcq27iOLQjYucmdHVsBafT841fzSIcwN9l0gDkCqkopMIJg063voPBvxRHcUxAFIV3aWNMrgRSWsXubPHkb9ZCyACfOCcKuSXRGiSOKxEwsd+j7eJ60Savlaa+iLDWIIVMmMca7XlwNonAek5Oa0w9iPz1UQBZB31G90f+JlVge45+X0SMAoffbMXSV46HNk7mniOI1j1nj1Au297XhJqfNBjaZl3DxyAKyeENiFIPp3EU0BTuwpuQKGkFCrswxDrQ4APu26HQne2439BfPHF7zZOgrYAAAAAElFTkSuQmCC
""")
FORK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAlBJREFUOE+Nkk9IVFEUxr/v3TdqCWHYxqKsaBFki5KiVdmuFkYEtgtqYW1MZxw1/4x5J8c/jY4zmptyUdBOISI3QYusVRTWogIXUVmUmyQJLHPefSfuyxENA+/i/jnfOT/Ovd8llobWusBTxSWL8AoWDWYyOjKX0+wa1umiPIWSPLgLrpmd0Vov2DjtpLV251XRCQiqSBYI/RdKyf3elvp3Vm/uGdhjDE9TnEMisgBirNDMPdRaewGgWad3G8UOADsImQG5C8Jbyfa621Zv6hy8AMpFiHwQsATAJ2Uk3qsj7wNAo04fZACQeYBfSZwUX0aSVyOZAHAtHabDaog8ArhVgHwxEu/TkZcBIKpvbnHUr3MEzgDYTMEUHAxdj4WfWv1KInMUPmqFKAPwXYBR32y4m9KXvgUAO+oTqe2uKHuNA0KnX/J/P+hvbJy3WkNfXyF/55+i+A0AXnk08YFY9PPyI+YgTYlMjQjOExz3jf9kpQuOco4JpJLEnWQsPJzTljuwgdauwTLPSLVAykFmVwIgEiI46SqOdLfVvVkTsGxZlhV0uA+CiiCRmBBf3qqQTOSs/S8gJ4R1emfIDaxF1pN4Rkc+rupo6bDqCrmEqqpRVbr/y2GHjNmYL5KYfr3t+djYWfMvZE1AVPfvVU6oGpQjQYHwmfGzIyndMLUuQFNn2v6HNoCTfwukHEBXsj1yb32AeOq4OE4rSQnKRUjf7052RB+vC9DSPVzsedlKkpVLgHHXDY33tNbMrgtgky7roU0bHZba/U9fpm/o2h9rufAHeH7yEUh8GVgAAAAASUVORK5CYII=
""")
STAR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAf5JREFUOE+Vkk9Ik3EYxz/P7303nEFmuUNhMpApOkIMusS0QUJdIsg2ygg6dwgPXTw5zx06FEaXOoljHo0IKnojgpK6JGJuGBZBJf0ndbq97xNbGurcyt/1eb6f5/l9v49Q5c2me+osa7nW71/8se/Ey8WtWqWSfird7vfTcBwxB3G5Fz7jPNsWYDYVbXGNNYBwTOD2isq1SML5uBmy5QbF6TbBCwIDQEiEF4oMtcSdO1UBj5Ixu6nd3uF5hTY13mWQ3lXBL1W9KQVvOO+z56cILiUSY26xJm9HovVLPtNpIa2qskeM7lalWeGQwN51E1+LMqFG5wX5qiLfPNedlMnU4eYaY/eDxBXqgJpqyQAK5BD9gMeN0gY5nxU3wiVVIv8Qr5UXQB0VvVoyMZvuCiImDlz8D0hJbCnDgdoF528K24A4luqVorh4XBtizI52d2IxqMjJSl8R9HrA9iUbTz38UkphfePMWNdR1CQFohW9EG7ltTAUSTx9VwbIpLv7QJJA+A9AfwLfQXYCu1ahdxVvqDXxZKIMkE119asxgyL4UaYRfeB6ZCxMkwox0A7QN2IkGT79eLwckD5yHvScqmQE7ufc3MSBvuefXo1E6wN+u0PV61FlvxgztnbWGzyYHo2FjEWjsZgL9zrvN/swMx5rsJcJreT53HbWmSvWfwPWVcUZq6YKzAAAAABJRU5ErkJggg==
""")

#format for using these icons are from github_badge.star by Cavallando (changed colors to match GitHub dark dimmed theme)
GITHUB_LOADING_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAKNJREFUOE/Nk80JwkAQhb+xEPFsGdYQcxckcW3C2IRrguBdrcEychYLcULAhdEYIexB97zvm/fmR4h8EqnnjwGqiM9JBKYKtSu5iKDvkT9G8EtmjDgqjINA4M6DhTtwtZAOoK28z7lZsYWsSibWSQewy5gDpy/TSdcVZwN9/eozNgpFH0CgcBXbXkC0g+getNaiphCyhT14NjQdtAdD7uP3t9AA9HI6EU67BJgAAAAASUVORK5CYII=
""")
GITHUB_NEUTRAL_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAKlJREFUOE9jZKAQMFKon2EQG/D//3/GytaJIf/+M2oxMf6/1l6dv4aRkfE/upexeqGkud+JiYFxPgMDgxyShkf/GP4n9tQW7kM2BMMAkM3lLRMfoGmG6XnUWZOvgOwSDAMqWiaE/vvPsApX7DAxMoR11BSshsljGFDWPLGegeF/A+7oZWzoqs1vxGkAxS6gOAxATqMoFmB+Q6QDhlWggCMpHZCSPwY+LwAAIgFNEUoU0xgAAAAASUVORK5CYII=
""")
GITHUB_FAULT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAKxJREFUOE9jZKAQMFKon2EQG/CfgYHxRYh3yL9//7WYmBivSazZuoaRgeE/upexeuFJoKcTIxPTfAYGBjkkDY/+//uXKLN++z5kQzAMANn8LNj7AZpmmJ5HUmu3KiC7BMOA5yHeof/+M6zCFTtMjAxhkmu2robJYxjwNMirnoGRsQFn9P7/3yC9blsjTgModgHFYQByGkWxAPMbPB38Z1gFCjiS0gEp+WPg8wIAAa9IEXkNio8AAAAASUVORK5CYII=
""")
GITHUB_FAILED_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAJtJREFUOE9jZKAQMFKon4H6BjwL8YmWWrNlKTaXPQ3yTmZi/ndccvX2azB5FBeANP///38Jw///DdLrtjUiG/I0yKuegZGxgeE/Q4r0uq1zsRoAEkQoRBiCTQynAeiGgBWCbcZ0FVgKVyzAbQUpwKGZdgYg+5lkL1AUiI9DfByY/v/fT3Y0ggwAOVl2zZYDZCUkcvIF9fMCqa4AAId3cRFxqY90AAAAAElFTkSuQmCC
""")
GITHUB_SUCCESS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAK1JREFUOE9jZKAQMFKon2FgDAifH266MnHlaZDrSXZByPwIByZm5hLGv38aQYaQZABIMzMjYz043P7/KyPJAGTNf///b1yTuOIAihci5kcogARWJK54gB4zuDSjG+Dwn5Ep/u//fwthpoMU4NOM4YL/jIzzQYIwJxLSjBEL6BpgAYbsZ3TvYcQCSkgjuQZXisUajRBDMMMDmyE40wEoVrDFCEEvkJq5SEqJ2AwHAAphaBHnvjbVAAAAAElFTkSuQmCC
""")

############
#other settings
AUTH_TOKEN = "AV6+xWcEGJw/oqAqKSFYWNt3DfB/VggWkPfqIkWgXiECZ08wjiiSLO/WxFFkycjdHXryiuLQ5BQjZHMz96AkahedwGZ/mVCWQiCYYKRxJl7oCVL5y9Rwgj+tJpBpNzHfLEzO+0VV46uU5wLyPK2NgN9bWqlj6DRc9WyoNaoDk1LITXZYdnM1s783/w7V3Q=="
DEFAULT_AUTH_TOKEN = "1234"  #can get tis by creating a personal token (classic) in GitHub and having the scope be public_repo

DEFAULT_OWNER = "tidbyt"
DEFAULT_REPO = "community"
DEFAULT_BRANCH = "main"

############
def main(config):
    #get data
    data = get_repository(config)  #get data

    #create main header of text
    header_txt = config.str("organization", DEFAULT_OWNER) + "/" + config.str("repository", DEFAULT_REPO) + ":" + config.str("branch", DEFAULT_BRANCH)
    header_all = render.Text(header_txt, font = FONT)

    #format display data
    if data == None:
        #error getting data
        line1 = render.WrappedText("Error getting data!!!!", font = FONT)
        line2 = None
        line3 = None
    elif type(data) == "string":
        #error getting repository data
        line1 = render.Marquee(
            height = 26,
            scroll_direction = "vertical",
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(data, font = FONT),
        )
        line2 = None
        line3 = None
    else:
        #information on the repository exists
        if data["latestRelease"] != None:
            header_all = render.Row(
                children = [
                    render.Text(header_txt, font = FONT),
                    render.Padding(render.Image(src = TAG_ICON, height = 6, width = 6), pad = (2, 0, 2, 0)),
                    render.Text(data["latestRelease"]["name"], font = FONT),
                ],
            )
        else:
            header_all = render.Text(header_txt, font = FONT)
            #header_txt += "(%s)" % data["latestRelease"]["name"]

        line1 = repository_stats(data)
        line2 = issues_pullrequests(data)
        line3 = latest_commit(data)

    #create the final frame
    frame_final = render.Column(
        main_align = "space_between",
        children = [
            render.Marquee(header_all, width = 64, offset_start = 64, offset_end = 64),
            line1,  #watchers, forks, stargazers
            line2,  #issues/pull requests
            line3,  #latest commit and version
        ],
    )

    return render.Root(
        delay = 100,  #speed up scroll text
        show_full_animation = True,
        child = frame_final,
    )

def get_schema():
    return [
        schema.Text(
            id = "organization",
            name = "User/Organization",
            desc = "User/organization of the repository.",
            icon = "user",
            default = DEFAULT_OWNER,
        ),
        schema.Text(
            id = "repository",
            name = "Repository",
            desc = "Name of the repository.",
            icon = "user",
            default = DEFAULT_REPO,
        ),
        schema.Text(
            id = "branch",
            name = "Branch",
            desc = "Default branch",
            icon = "user",
            default = DEFAULT_BRANCH,
        ),
    ]

######################################################
#functions for getting data
def get_repository(config):
    #get repo statistics
    owner = config.str("organization", DEFAULT_OWNER)
    repo = config.str("repository", DEFAULT_REPO)
    branch = config.str("branch", DEFAULT_BRANCH)
    nameWithOwner = owner + "/" + repo
    dataQuery = {
        "query": """query {
                    repository(name: "%s", owner: "%s") {
                        id
                        nameWithOwner
                        watchers {
                        totalCount
                        }
                        stargazers {
                        totalCount
                        }
                        issues(states: OPEN) {
                        totalCount
                        }
                        forks {
                        totalCount
                        }
                        pullRequests(states: OPEN) {
                        totalCount
                        }
                        latestRelease {
                        id
                        name
                        publishedAt
                        updatedAt
                        createdAt
                        }
                        ref(qualifiedName: "%s") {
                        id
                        name
                        target {
                            ... on Commit {
                            id
                            abbreviatedOid
                            messageHeadline
                            committedDate
                            statusCheckRollup {
                                state
                            }
                            }
                        }
                        }
                    }
                    }
                """ % (repo, owner, branch),
    }

    #get data
    data_cached = cache.get(nameWithOwner + "_" + branch)
    if data_cached != None:
        print("Hit! Displaying data for %s!!!!" % nameWithOwner)
        data = json.decode(data_cached)
    else:
        print("Miss! Getting data for %s!!!!" % nameWithOwner)
        auth_key = secret.decrypt(AUTH_TOKEN) or DEFAULT_AUTH_TOKEN
        rep = http.post(
            BASE_URL,
            headers = {
                "Authorization": "Bearer " + auth_key,
            },
            json_body = dataQuery,
        )

        #print(rep.json()["errors"])
        if rep.status_code != 200:
            print("%s Error, could not get data for %s!!!!" % (rep.status_code, nameWithOwner))
            return None
        elif rep.json().get("errors", None) != None:
            #error message
            return rep.json()["errors"][0]["message"]  #gets only the first error
        else:
            data = rep.json()["data"]["repository"]
            cache.set(nameWithOwner + "_" + branch, json.encode(data), ttl_seconds = 1800)  #cache for 30 minutes

    return data

######################################################
#functions to create displayed information
def repository_stats(data):
    #get stats like watchers, forks, and stargazers
    #get data
    watchers = int(data["watchers"]["totalCount"])
    forks = int(data["forks"]["totalCount"])
    stargazers = int(data["stargazers"]["totalCount"])

    ##############
    #create images
    watch_img = render.Image(src = WATCH_ICON, width = 8, height = 8)
    fork_img = render.Image(src = FORK_ICON, width = 8, height = 8)
    star_img = render.Image(src = STAR_ICON, width = 8, height = 8)

    #final text
    final_text = render.Row(
        #expanded=True,
        children = [
            #watchers
            render.Padding(child = watch_img, pad = (0, 0, 1, 0)),
            render.Text(content = str(watchers), height = 9, offset = 1, font = FONT),
            ######
            #forks
            render.Padding(child = fork_img, pad = (4, 0, 1, 0)),
            render.Text(content = str(forks), height = 9, offset = 1, font = FONT),
            ######
            #stargazers
            #followers • following
            render.Padding(child = star_img, pad = (4, 0, 1, 0)),
            render.Text(content = str(stargazers), height = 9, offset = 1, font = FONT),
        ],
    )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")

def issues_pullrequests(data):
    #get stats like issues/pull requests
    #get data
    issues = int(data["issues"]["totalCount"])
    pulls = int(data["pullRequests"]["totalCount"])

    ##############
    #create images
    # issue_img = render.Circle(
    #     color = ISSUE_PR_COLOR,
    #     diameter = 8,
    #     child = render.Circle(
    #         color = "#000000",
    #         diameter = 6,
    #         child = render.Circle(color = ISSUE_PR_COLOR, diameter = 2),
    #     ),
    # )
    issue_img = render.Image(src = ISSUE_ICON, width = 8, height = 8)
    pr_img = render.Image(src = PR_ICON, width = 8, height = 8)

    #final text
    final_text = render.Row(
        #expanded=True,
        children = [
            ######
            #issues open
            render.Padding(child = issue_img, pad = (0, 0, 1, 0)),
            render.Text(content = str(issues), height = 9, offset = 1, font = FONT),
            ######
            #pulls open
            render.Padding(child = pr_img, pad = (4, 0, 1, 0)),
            render.Text(content = str(pulls), height = 9, offset = 1, font = FONT),
        ],
    )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")

def get_status_icon(status):
    #get the right commit status icon - from github_badge.star by Cavallando
    if status == "completed" or status == "success":
        return GITHUB_SUCCESS_ICON
    elif status == "failed" or status == "timed_out":
        return GITHUB_FAILED_ICON
    elif status == "cancelled" or status == "skipped" or status == "stale" or status == "neutral":
        return GITHUB_NEUTRAL_ICON
    elif status == "action_required":
        return GITHUB_FAULT_ICON
    else:
        return GITHUB_LOADING_ICON

def latest_commit(data):
    commit_data = data["ref"]
    if commit_data == None:
        final_text = render.Text("Cannot get latest commit for specified branch!!!")
    else:
        oid_short = commit_data["target"]["abbreviatedOid"]  #shortened commit id

        #get status id icon
        commit_status = commit_data["target"]["statusCheckRollup"]["state"].lower()
        status_icon = get_status_icon(commit_status)
        status_img = render.Image(src = status_icon, width = 8, height = 8)

        commit_time = time.parse_time(commit_data["target"]["committedDate"], "2006-01-02T15:04:05Z", "Zulu")

        #time_info = [render.Padding(render.Text(content=x,height=9,offset=1,font=FONT),pad=(2,0,0,0)) for x in humanize.time(commit_time).split(" ")] #condense spacing between relative time
        time_info = []
        for x in humanize.time(commit_time).split(" "):
            shift = 4 if time_info == [] else 2
            time_info.append(render.Padding(render.Text(content = x, height = 9, offset = 1, font = FONT), pad = (shift, 0, 0, 0)))

        final_frame_vec = [
            render.Text("Latest", height = 9, offset = 1, font = FONT),
            render.Padding(child = render.Text("commit:", height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
            #render.Padding(child = render.Text(oid_short, height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
            ######
            #commit info
            render.Padding(child = status_img, pad = (4, 0, 1, 0)),
            render.Text(content = oid_short, height = 9, offset = 1, font = FONT),
            ######
            #time info
            #render.Padding(child=render.Text(content = humanize.time(commit_time), height = 9, offset = 1, font = FONT),pad=(2,0,0,0)),
        ]

        final_frame_vec.extend(time_info)  #add time info

        #final text
        final_text = render.Row(
            children = final_frame_vec,
        )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")
