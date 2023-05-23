"""
Applet: SlippiRank
Summary: Shows slippi rank
Description: Shows current rank from SSBM Slippi profile.
Author: noahpodgurski
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

RANKS = [
    {
        "name": "GM",
        "max": 9999,
        "min": 2350,
    },
    {
        "name": "Master 2",
        "max": 2349.99,
        "min": 2275,
    },
    {
        "name": "Master 1",
        "max": 2274.99,
        "min": 2191.75,
    },
    {
        "name": "Diamond 3",
        "max": 2191.74,
        "min": 2136.28,
    },
    {
        "name": "Diamond 2",
        "max": 2136.27,
        "min": 2073.67,
    },
    {
        "name": "Diamond 1",
        "max": 2073.66,
        "min": 2003.92,
    },
    {
        "name": "Platinum 3",
        "max": 2003.91,
        "min": 1927.03,
    },
    {
        "name": "Platinum 2",
        "max": 1927.02,
        "min": 1843,
    },
    {
        "name": "Platinum 1",
        "max": 1842.99,
        "min": 1751.83,
    },
    {
        "name": "Gold 3",
        "max": 1751.82,
        "min": 1653.52,
    },
    {
        "name": "Gold 2",
        "max": 1653.51,
        "min": 1548.07,
    },
    {
        "name": "Gold 1",
        "max": 1548.06,
        "min": 1435.48,
    },
    {
        "name": "Silver 3",
        "max": 1435.47,
        "min": 1315.75,
    },
    {
        "name": "Silver 2",
        "max": 1315.74,
        "min": 1188.88,
    },
    {
        "name": "Silver 1",
        "max": 1188.87,
        "min": 1054.87,
    },
    {
        "name": "Bronze 3",
        "max": 1054.86,
        "min": 913.72,
    },
    {
        "name": "Bronze 2",
        "max": 913.71,
        "min": 765.43,
    },
    {
        "name": "Bronze 1",
        "max": 765.42,
        "min": 0,
    },
]

RANK_IMGS = {
    "Unranked1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Unranked1.ac2623299b250689293cd4a5e68fcc5b.png",
    "Unranked2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Unranked2.4515c2502e417d483f3f571dd0ef66fb.png",
    "Unranked3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Unranked3.0f639e8b73090a7ba4a50f7bcc272f57.png",
    "Bronze 1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Bronze_I.90480ec5a08ee8d6048021f889933455.png",
    "Bronze 2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Bronze_II.9d7a7994dbf087e3aea44f5b1c1409a7.png",
    "Bronze 3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Bronze_III.b44c3a06f14234dec6f67e9b28088a6f.png",
    "Silver 1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Silver_I.b8069dd847a639127f6d3ff5363623f7.png",
    "Silver 2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Silver_II.7a97ee32770c36e78d9d7e9279c7ce38.png",
    "Silver 3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Silver_III.93588af0e9a6bc9406209d5ef3cc9dc7.png",
    "Gold 1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Gold_I.523b488f06ff22aaa013e94b6178f157.png",
    "Gold 2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Gold_II.951fc625063425ed048c864988e8d7b7.png",
    "Gold 3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Gold_III.38643ad9dbef534920fc2361fd736d7a.png",
    "Platinum 1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Platinum_I.7a22c1a7c7640af6b6bf2f7b5b439fc6.png",
    "Platinum 2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Platinum_II.ec1c571c896ed47ef2b14d8e2dd79fef.png",
    "Platinum 3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Platinum_III.cd9d7a413a1de2182caaae563b4e5023.png",
    "Diamond 1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Diamond_I.bcc6237a1e6be861f22f330bbff96964.png",
    "Diamond 2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Diamond_II.2f26cd8248bcf6c34ea1efe7f835b123.png",
    "Diamond 3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Diamond_III.ae3a5720a6ed48594efef54249095001.png",
    "Master 1": "https://melee-icons.s3.amazonaws.com/ranks/rank_Master_I.0ce2459fedf9e33ebee0cb3520a17e2f.png",
    "Master 2": "https://melee-icons.s3.amazonaws.com/ranks/rank_Master_II.c0b5472d49d391d2063d8e2a19c9ea17.png",
    "Master 3": "https://melee-icons.s3.amazonaws.com/ranks/rank_Master_III.5075fd077bf77bfa6c59985252e0cb04.png",
    "GM": "https://melee-icons.s3.amazonaws.com/ranks/rank_Grandmaster.0f3bc5674e8ec76f17514f197242c4fa.png",
}

def getRank(elo):
    for rank in RANKS:
        if rank["min"] < elo and rank["max"] > elo:
            return rank["name"]
    return "Unranked"

RANK_URL = "https://gql-gateway-dot-slippi.uc.r.appspot.com/graphql"

def getUserCodeDashIndex(userCode):
    for i in range(len(userCode)):
        if userCode[i] == "#" or userCode[i] == "-":
            return i
    return -1

def requestRank(userCode):
    body = json.encode({
        "operationName": "AccountManagementPageQuery",
        "variables": {
            "cc": userCode,
            "uid": userCode,
        },
        "query": "fragment userProfilePage on User {\n  fbUid\n  displayName\n  connectCode {\n    code\n    __typename\n  }\n  status\n  activeSubscription {\n    level\n    hasGiftSub\n    __typename\n  }\n  rankedNetplayProfile {\n    id\n    ratingOrdinal\n    ratingUpdateCount\n    wins\n    losses\n    dailyGlobalPlacement\n    dailyRegionalPlacement\n    continent\n    characters {\n      id\n      character\n      gameCount\n      __typename\n    }\n    __typename\n  }\n  __typename\n}\n\nquery AccountManagementPageQuery($cc: String!, $uid: String!) {\n  getUser(fbUid: $uid) {\n    ...userProfilePage\n    __typename\n  }\n  getConnectCode(code: $cc) {\n    user {\n      ...userProfilePage\n      __typename\n    }\n    __typename\n  }\n}\n",
    })
    res = http.post(
        RANK_URL,
        body = body,
        headers = {
            "Content-Type": "application/json",
        },
    )
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    res = res.json()
    return res

REFRESH_TIME = 43200  # twice a day
DEFAULT_USER_CODE = "hbox-305"

def main(config):
    userCode = config.str("userCode")
    showRankName = config.bool("showRankName", True)
    showElo = config.bool("showElo", True)
    if userCode == None or userCode == "":
        userCode = DEFAULT_USER_CODE
        # fail("No user code configured")

    userCode = userCode.upper()
    userCodeDashIndex = getUserCodeDashIndex(userCode)
    if userCodeDashIndex == -1:
        fail("Invalid user code")

    # print(userCode)

    userCodeHash = userCode[:userCodeDashIndex] + "#" + userCode[userCodeDashIndex + 1:]
    rankedData = cache.get("rankedData")
    if rankedData != None:
        # print("Cached - Displaying cached rankedData.")
        rankedData = json.decode(rankedData)

        # print(rankedData)
        if not rankedData["data"]["getUser"] or userCodeHash != rankedData["data"]["getConnectCode"]["user"]["connectCode"]["code"]:
            #new usercode, request data again
            rankedData = requestRank(userCodeHash)
            cache.set("rankedData", json.encode(rankedData), ttl_seconds = REFRESH_TIME)
    else:
        # print("No data available - Calling slippi API.")
        rankedData = requestRank(userCodeHash)
        cache.set("rankedData", json.encode(rankedData), ttl_seconds = REFRESH_TIME)

    if rankedData["data"]["getConnectCode"]["user"]["displayName"]:
        elo = rankedData["data"]["getConnectCode"]["user"]["rankedNetplayProfile"]["ratingOrdinal"]
        rank = getRank(elo)
        name = rankedData["data"]["getConnectCode"]["user"]["displayName"]
        rankedImg = http.get(RANK_IMGS[rank]).body()
    else:
        fail("Ranked data did not respond correctly")

    msg = "%s \n%s \n%d" % (name, rank, elo)
    if not showRankName:
        rank = ""
        msg = "%s \n%d" % (name, elo)
    if not showElo:
        msg = "%s \n%s" % (name, rank)

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = rankedImg, width = 18, height = 18),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.WrappedText(msg),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "userCode",
                name = "User Code",
                desc = "Ex: (HBOX-123 or HBOX#123)",
                icon = "user",
            ),
            schema.Toggle(
                id = "showRankName",
                name = "Show Rank Name",
                desc = "",
                icon = "question",
            ),
            schema.Toggle(
                id = "showElo",
                name = "Show Elo",
                desc = "",
                icon = "question",
            ),
        ],
    )
