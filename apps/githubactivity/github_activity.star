"""
Applet: GitHub Activity
Summary: See your GitHub activity
Description: Display the last 13 weeks of your GitHub contribution graph in addition to other metrics on your GitHub profile.
Author: rs7q5
"""

#github_activity.star
#Created 20221117 RIS
#Last Modified 20230308 RIS

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

############
FONT = "tom-thumb"  #set font
BASE_URL = "https://api.github.com/graphql"

############
#CONTRIBUTION COLORS (DOES NOT INCLUDE THE ZERO)
CONTRIBUTION_LEVELS = ["NONE", "FIRST_QUARTILE", "SECOND_QUARTILE", "THIRD_QUARTILE", "FOURTH_QUARTILE"]

CONTRIBUTION_THEMES = {
    #THEMES DO NOT INCLUDE THE NONE VECTOR!!!!
    "GitHub": ["#9be9a8", "#40c463", "#30a14e", "#216e39"],
    "GitHub dark": ["#0e4429", "#006d32", "#26a641", "#39d353"],
    "Halloween": ["#ffee4a", "#ffc501", "#fe9600", "#03001c"],
    "Halloween dark": ["#631c03", "#bd561d", "#fa7a18", "#fddf68"],
    "Winter": ["#b6e3ff", "#54aeff", "0969da", "#0a3069"],
    "Winter dark": ["#0a3069", "#0969da", "#54aeff", "#b6e3ff"],
}

HALLOWEEN_DARK_THEMES = ["GitHub dark", "Halloween dark", "Winter dark"]  #themes that get the dark halloween theme

BACKGROUND_THEMES = {
    #THEMES DO NOT INCLUDE THE NONE VECTOR!!!!
    "Light": {"empty": "#ebedf0", "background": "#f6f8fa"},
    "Dark dimmed": {"empty": "#2d333b", "background": "#1c2128"},
    "Dark": {"empty": "#000000", "background": "#000000"},
}

#GREEN = "#57ab5a" #used for open issues and pull requests
GREEN = "#40c463"
GREEN_FILL = "#40c463"
GREEN_FILL2 = "#40c46380"  #GREEN FILL WITH OPACITY (alpha is 50%)

############
#stuff for open issues/prs
ISSUE_PR_COLOR = "#57ab5a"
PEOPLE_COLOR = "#768390"
ISSUE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAnZJREFUOE+NU0tIlGEUPefO+MAHpGZGkSatggqJViZp7hQsWoz/zJTmVFAEqYsCd+quRQsziIJqfKTO6CJC0F0mmKsIqcBVmElQmc0iFdOZe2MGfjFB7Nt9j3O433kQ21ZNd01GXkHe/vgGSsRQokSeGGJKzHvTMB9bin0bbx7/48K4Fe/0OEdMvNWAnYSiEGAmaWlm3ABsDYJFgO+o8VfRpuinJHaTwB/2V6nwKozHACzQbFpF5iCJZagnR1RLjSwHcAi0j6L2NBKKvE4RXOhr2Jdu2g5YLYCXTOjwysbKzOj10VV3wrrHdVnZadll5pF6AOcBjq1TOlk1UeUtWjhwDoZrBrwX1UeRUOTzdm3cvT/sP6wiNwicAPGEvl5fsVjaHQjyNIF7I6HBmZ3A7rkvHCwTD25DEWOgL1CtylYj3vwuLOgar32wqXBgMLBX41ooXlkcCg79dAlqxm5l5C4utdJwmk5PIEQwoJDwcNPzIfdRCrxOH4hKGCYl3Ua2ktT3XAoINESnN9gCQ52Z3R8ODY26BE6fcxTmaQfgAIiCic5oY3TWva8PB+pIttAfDjYo6RjRP3J5IPq/E/h6Lzo0NLC+J3gGQDPN3q6uL3dvtW4nDZKWZqXnNBt5isGBYEk8gTYoDorq3ciVyPRuLvif+ctVpA2Cr0xmP3dPfiPUbpKYpGrXbjkwkVYzVEL4MJXEVAcoHQQrDIiaIrJcVDC71dKkdTnfl45S4CfgGGyKph3/dMHE4wOsFMQvM3yAyRdDfIXwZoNaTOI4DPkA56iJkc0uuH9OdQKJCijOAighkGmEl4a4AWsA5iGYWIdn6kVj/48k7i+RCic+VLxoAAAAAABJRU5ErkJggg==
""")
PR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAbpJREFUOE/Nk7FPFEEUxr9vji1MoMBKO2JiB9hB0AIuMdECEiDssbtCdq81JobYWqCJiSbERhuIsCzk9nb3TowhWBIa/wUbC40NUQs7aWCe2bnc5SB7CaVTzvzm9973Zpe4xFoInalmNTkqQtnezCGl1CTIn6c8+bi3vHecnzk7zrhovkyDermnwAmdISFDA5D9BA4SP151I3f0TPCK5P0zrcu0Sr8aS7Uv3SLTQSV0Z6n4IYdKJfUYIjdTvz5c2XafkFwzF0SOQP7WWn9qVJPttsQI7E13QvWxKcAGgBkKvqZB7FYi7y4hawBvCbBKwRAoU9RSTqrJd9OwEby2r6ir1jKI9bySQD3NgtpncxY5cwp8nvr1ERNVqW9a62q7i84Qc3gx8iSvlPnxs+6cduQsNPykWcRcStAtu1jkPxLYmX1NnVjHRTNoRyhiTIT5Le+GVcIKgEetV8DbLKi/787eizGCxdCzoVAT4AWAe/le5se3zw2vB9MSRA+mAdmHRkUUVggw9eOJ89MvZloRdpeuW1q/E8EgKQMQvkmDOP8qO6sX03lGO/LGKLgDyI++vzyMH8Z/Lv59Rcw/79j7ERrrQ4EAAAAASUVORK5CYII=
""")
PEOPLE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAd5JREFUOE+tk79rFFEQx7/z9q7QFEYhjb1NtIkIQasTLA3amMZKjlyTH3cbcnuc567P7HJedkN298QiQfIPpEiMnRFsAyEQFBVEREQ8sLJMsftGdnUvlxgDIb7qwZv5zHe+M49wwkMnzMdfgJoTXmPFl1mgI5T6OGdNvz2qyD5AzQ4nGdzuSfjKUGOeOf3yX5AuYMbz+sRu/hsBG0ITkiM+FRPPE1DICT7fbOgdww4fslDPvYa+kwG7AMP2bwO0KnL5C636+KckYMb2CwL0moGRvODtSNH334kkXbP8KL1lpOpsWCLixcMAWYIuF87lNJIEmgRwyzUr63st2P4NAdogYOVACwOuWbmUFao32wNxrH6AWXctPdhnYtIjwLLXMCaMeg8qK12ltt9OFAimKy2rvL3ngeMvgqnEoFdE6jMURSBcBTBEoIk5s/y0x5M3ffHPYSnlbgownOAJGBPMXPQsfTmrVpLydL92tpqoEkIUW42p5ZoTrjPzCIDNOI7uURJ0RuvvEGghc/bgzNPxgQueWbmevFXt4CYBLwCskWEHRQDPNE1cfHx/6v1hC1NvtgfjWL0DeNA19Q+p6j9+pS0kI/Ss8tJRK1t1gjtaxFstqX/J4gzHv/v/P9Nxf+cvOtjHXAVbbF4AAAAASUVORK5CYII=
""")

############
#oauth variables
CLIENT_ID_DEFAULT = "123456"
CLIENT_SECRET_DEFAULT = "78910"

CLIENT_ID = "AV6+xWcE/KQvC81B6WzgwzvD4ZoupLfN8TC/SJsH+HM9BJvI6pGrRJweJGMO34ZFLehdFzch8C8F/EJNbu6yMCVShWY85jU+m3OFI6mTNQ9WMFUvJtyazmNiGRkFhydP1nCm2SRMp5ih+NMu0j1CVy+R3GJ8LfMVmLc="
CLIENT_SECRET = "AV6+xWcEctKRED4FFQz/BS/u5MlGScY7F3x1xZ5Tg+8spZX/+Y/dfMnd+6RPagWOYzh63Xea4bP8qnHf5kGuplixKHx3dfeQoxmsORFbMW2Da98T716B/8EcWuQhw2hb4gbQr0oKPwZr6RANKywUWBUt3/0LAhoG9EziqBUGJFAeLuDnFeGdAvjYz/w1lg=="

############
#debug stuff
AUTH_TOKEN = None  #can get by using pixlet serve and login with DEBUG_OAUTH ON

DEBUG_OAUTH = False
DEBUG = False

############
def main(config):
    #get user data
    auth_token = config.get("auth", AUTH_TOKEN)
    if auth_token == None:
        data = None  #creates empty stat information
    else:
        data = get_contributions(auth_token)
        # print(data["contributionsCollection"]["hasAnyRestrictedContributions"])

    #create parts of the final frame (error handling done in each of these)
    chart = contribution_chart(data, config)
    activity_overview = contribution_activity(data)  #get the activity overview

    #get stats like total contributions (in last year), open issues/pulls, and followers/following
    other_stats = contribution_stats(data)

    ##################
    #create final frame
    frame = render.Row(
        main_align = "space_between",
        expanded = True,
        children = [
            chart,
            activity_overview,
        ],
    )
    frame_final = render.Column(
        main_align = "space_between",
        expanded = True,
        children = [
            frame,
            other_stats,
        ],
    )

    return render.Root(
        delay = 100,  #speed up scroll text
        show_full_animation = True,
        child = frame_final,
    )

def get_schema():
    background_theme_opts = [
        schema.Option(display = color, value = color)
        for color in BACKGROUND_THEMES.keys()
    ]
    theme_opts = [
        schema.Option(display = color, value = color)
        for color in CONTRIBUTION_THEMES.keys()
    ]

    return [
        schema.OAuth2(
            id = "auth",
            name = "GitHub",
            desc = "Connect your GitHub account.",
            icon = "github",
            handler = oauth_handler,
            client_id = secret.decrypt(CLIENT_ID) or CLIENT_ID_DEFAULT,
            authorization_endpoint = "https://github.com/login/oauth/authorize",
            scopes = [
                "read:user",
            ],
        ),
        schema.Dropdown(
            id = "background_theme",
            name = "Background theme",
            desc = "Select the background theme of the contribution graph.",
            icon = "fillDrip",
            options = background_theme_opts,
            default = background_theme_opts[1].value,
        ),
        schema.Dropdown(
            id = "theme",
            name = "Theme",
            desc = "Select the color theme of the contribution graph.",
            icon = "fillDrip",
            options = theme_opts,
            default = theme_opts[0].value,
        ),
    ]

######################################################
#functions for getting data
def oauth_handler(params):
    params = json.decode(params)
    if DEBUG_OAUTH:
        print(params)

    # handle oauth2 flow (see Example App)
    auth_params = {
        "client_id": params["client_id"],
        "client_secret": secret.decrypt(CLIENT_SECRET) or CLIENT_SECRET_DEFAULT,
        "code": params["code"],
        "redirect_uri": params["redirect_uri"],
    }
    auth_resp = http.post(
        url = "https://github.com/login/oauth/access_token",
        params = auth_params,
        headers = {
            "Accept": "application/json",
        },
    )

    if auth_resp.status_code != 200:
        access_token = "%s Error, could not get authorization token!!!!" % auth_resp.status_code
        return None
    else:
        access_token = auth_resp.json()["access_token"]
        if DEBUG_OAUTH:
            print(access_token)
    return access_token

def get_contributions(auth_token):
    #get the contribution data for a user
    dataQuery = {
        "query": """query {
                  viewer {
                    login
                    followers {
                      totalCount
                    }
                    following {
                      totalCount
                    }
                    issues(states: OPEN) {
                      totalCount
                    }
                    pullRequests(states: OPEN){
                      totalCount
                    }
                    contributionsCollection {
                      hasAnyRestrictedContributions
                      totalCommitContributions
                      totalPullRequestReviewContributions
                      totalPullRequestContributions
                      totalIssueContributions
                      user {
                        issues(states:OPEN) {
                          totalCount
                        }
                      }
                      contributionCalendar {
                        totalContributions
                        colors
                        isHalloween
                        weeks {
                          contributionDays{
                            color
                            contributionCount
                            contributionLevel
                            date
                            weekday
                          }
                          firstDay
                        }
                      }
                      
                    }
              }
              }
              """,
    }

    #get data
    data_cached = cache.get(auth_token)
    if data_cached != None:
        data = json.decode(data_cached)
    else:
        rep = http.post(
            BASE_URL,
            headers = {
                "Authorization": "Bearer " + auth_token,
            },
            json_body = dataQuery,
        )
        if DEBUG_OAUTH:
            for key in ["X-Oauth-Scopes", "X-Accepted-Oauth-Scopes"]:
                print("%s: %s" % (key, rep.headers[key]))

        if rep.status_code != 200:
            print("%s Error, could not get authorization token!!!!" % rep.status_code)
            return None
        else:
            data = rep.json()["data"]["viewer"]

            # user = data["login"]
            cache.set(auth_token, json.encode(data), ttl_seconds = 600)  #store data every 10 minutes
            #print(data["contributionsCollection"]["restrictedContributionsCount"])

    return data

######################################################
#functions to create displayed information
def contribution_square(fill, background):
    #make github square for contribution
    #size of squares
    x1 = 2  #size of inner square
    pad = 1
    x2 = x1 + pad  #size of outer square

    #return render.Padding(child=render.Box(width=x1,height=x1,color=color),pad=1,color=BACKGROUND_COLOR)
    return render.Box(
        width = x2,
        height = x2,
        color = background,
        child = render.Box(width = x1, height = x1, color = fill),
    )  #don't use padding otherwise have to distinguish between inner and outer edges

def contribution_chart(data, config):
    #replicate the contributions chart that is seen on GitHub for the last 13 weeks
    ###########
    #figure out color scheme
    background_name = config.str("background_theme", "Dark dimmed")
    empty_color, background_color = BACKGROUND_THEMES[background_name].values()
    fill_name = config.str("theme", "GitHub")

    if data == None:
        cdata = range(0, 13)  #only need to iterate through 13 weeks
        halloween_logic = False  #this does not matter since everything will be empty or background color
    else:
        cdata = data["contributionsCollection"]["contributionCalendar"]["weeks"][-13:]
        halloween_logic = data["contributionsCollection"]["contributionCalendar"]["isHalloween"]

    #change theme if it is Halloween
    if halloween_logic:
        if fill_name in HALLOWEEN_DARK_THEMES:
            fill_name = "Halloween dark"
        else:
            fill_name = "Halloween"

    #get fill_vec used to determine the colors
    fill_vec = [BACKGROUND_THEMES[background_name]["empty"]]
    fill_vec.extend(CONTRIBUTION_THEMES[fill_name])

    ##############
    #create contribution squares
    cdata2 = []
    for (i, week) in enumerate(cdata):
        weekdata = range(0, 7) if data == None else week["contributionDays"]
        left = 1 if i == 0 else 0  #padding for squares along the left edge

        w = []
        for (j, day) in enumerate(weekdata):
            if data == None:
                ctmp = empty_color
            else:
                ctmp = fill_vec[CONTRIBUTION_LEVELS.index(day["contributionLevel"])]

            #add extra padding around the top and left border squares
            top = 1 if j == 0 else 0  #padding to squares along the top edge
            w.append(render.Padding(
                child = contribution_square(ctmp, background_color),
                pad = (left, top, 0, 0),
                color = background_color,
            ))

        #add empty squares for days that have not occurred yet
        w.extend([contribution_square(background_color, background_color)] * (7 - len(w)))  #should only ever be the last row, so no extra padding necessary on left or top edge

        cdata2.append(render.Column(children = w))

    cdata3 = render.Row(children = cdata2)  #height=22 and width = 40 (with outer border)

    return cdata3

def contribution_activity(data):
    #create the graph of the contribution activity in last year
    if data == None:
        #empty plot
        plotdata = []
    else:
        #percentages may be slightly different than in GitHub due to rounding
        total = data["contributionsCollection"]["contributionCalendar"]["totalContributions"]
        codeReview = data["contributionsCollection"]["totalPullRequestReviewContributions"]
        commits = data["contributionsCollection"]["totalCommitContributions"]
        pulls = data["contributionsCollection"]["totalPullRequestContributions"]
        issues = data["contributionsCollection"]["totalIssueContributions"]

        if DEBUG:
            print("Total contributions: %d" % total)
            print("   Code review: %d - %f %%" % (codeReview, codeReview / total * 100))
            print("   Commits: %d - %f %%" % (commits, commits / total * 100))
            print("   Pull requests: %d - %f %%" % (pulls, pulls / total * 100))
            print("   Issues: %d - %f %%" % (issues, issues / total * 100))

        ########
        #plot activity overview
        plotdata = [
            (0, codeReview / total),
            (-1 * commits / total, 0),
            (0, -1 * pulls / total),
            (issues / total, 0),
            (0, codeReview / total),
        ]

    p1 = render.Plot(
        data = plotdata,
        width = 22,
        height = 22,
        color = GREEN_FILL,
        fill_color = GREEN_FILL2,
        fill_color_inverted = GREEN_FILL2,
        fill = True,
        #color_inverted="#f00",
        x_lim = (-1, 1),
        y_lim = (-1, 1),
    )

    #########
    pfinal = render.Stack(
        children = [
            render.Box(width = 22, height = 22, child = render.Box(width = 22, height = 1, color = "#fff")),
            render.Box(width = 22, height = 22, child = render.Box(width = 1, height = 22, color = "#fff")),
            render.Box(width = 22, height = 22, child = p1),
        ],
    )
    return pfinal

def contribution_stats(data):
    #get stats like total contributions (in last year), open issues/pulls, and followers/following
    if data == None:
        final_text = render.Text("Sign in to GitHub!!!!", height = 9, offset = 1, font = FONT)
    else:
        #get data
        total = int(data["contributionsCollection"]["contributionCalendar"]["totalContributions"])  #total contributions in last year
        issues = int(data["issues"]["totalCount"])
        pulls = int(data["pullRequests"]["totalCount"])
        followers = int(data["followers"]["totalCount"])
        following = int(data["following"]["totalCount"])

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
        people_img = render.Image(src = PEOPLE_ICON, width = 8, height = 8)

        #final text
        final_text = render.Row(
            #expanded=True,
            children = [
                #total contributions in last year
                render.Text(str(total), height = 9, offset = 1, font = FONT),
                render.Padding(child = render.Text("contributions", height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
                render.Padding(child = render.Text("in", height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
                render.Padding(child = render.Text("last", height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
                render.Padding(child = render.Text("year", height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
                #render.Text("in last year",height=9,offset=1,font=FONT),
                ######
                #issues open
                render.Padding(child = issue_img, pad = (4, 0, 1, 0)),
                render.Text(content = str(issues), height = 9, offset = 1, font = FONT),
                ######
                #pulls open
                render.Padding(child = pr_img, pad = (4, 0, 1, 0)),
                render.Text(content = str(pulls), height = 9, offset = 1, font = FONT),
                ######
                #followers • following
                render.Padding(child = people_img, pad = (4, 0, 1, 0)),
                render.Text(content = str(followers), height = 9, offset = 1, font = FONT),
                render.Text("•", height = 9, offset = 1, font = FONT),
                render.Text(content = str(following), height = 9, offset = 1, font = FONT),
            ],
        )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")
