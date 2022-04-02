"""
Applet: NHL Scores
Summary: Displays NHL scores
Description: Displays live and upcoming NHL scores from a data feed.
Author: cmarkham20
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 120
DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""
SHOW_CLOCK = "show"
SPORT = "hockey"
LEAGUE = "nhl"


def main(config):
    leagues = { 
    	LEAGUE : "https://site.api.espn.com/apis/site/v2/sports/"+SPORT+"/"+LEAGUE+"/scoreboard" }
    scores = get_scores(leagues)
    renderCategory = []
    mainspeed = 15 / len(scores);
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]

    now = time.now().in_location(timezone)
    now_date = now.format("2 JAN 2006")
    day = now.format("MONDAY")
    
    for i, s in enumerate(scores):
    	
    	oddscheck = s["competitions"][0].get("odds", 'NO')
    	if oddscheck == "NO":
    		showodds = "no"
    	else:
    		showodds = "yes"

    	game = s["name"]
    	gamestatus = s["status"]["type"]["state"]
    	
    	home = s["competitions"][0]["competitors"][0]["team"]["abbreviation"]
    	homeid = s["competitions"][0]["competitors"][0]["team"]["id"]
    	homeColor = "#" + s["competitions"][0]["competitors"][0]["team"]["color"]
    	if homeColor == "#000000" or homeColor == "#ffffff":
    		homeColor = "#222"
    	homeLogo_url = s["competitions"][0]["competitors"][0]["team"]["logo"]
        homeLogo_url_dark = homeLogo_url.replace("500/scoreboard","500-dark/scoreboard")
        homeLogo_url_dark = homeLogo_url_dark.replace("https://a.espncdn.com/","https://a1.espncdn.com/combiner/i?img=")
    	homelogo = get_cachable_data(homeLogo_url_dark + "&h=36&w=36")
    	homescore = ""
    	homescorefont = "Dina_r400-6"
    	homepossesionbox = ""

    	away = s["competitions"][0]["competitors"][1]["team"]["abbreviation"]
    	awayid = s["competitions"][0]["competitors"][1]["team"]["id"]
        awayColor = "#" + s["competitions"][0]["competitors"][1]["team"]["color"]
        if awayColor == "#000000" or awayColor == "#ffffff":
    		awayColor = "#222"
        awayLogo_url = s["competitions"][0]["competitors"][1]["team"]["logo"]
    	awayLogo_url_dark = awayLogo_url.replace("500/scoreboard","500-dark/scoreboard")
    	awayLogo_url_dark = awayLogo_url_dark.replace("https://a.espncdn.com/","https://a1.espncdn.com/combiner/i?img=")
    	awaylogo = get_cachable_data(awayLogo_url_dark + "&h=36&w=36")
    	awayscore = ""
    	awayscorefont = "Dina_r400-6"
    	awaypossesionbox = ""
    	
    	if gamestatus == "pre":
            gamedatetime = s["status"]["type"]["shortDetail"]
            theodds = ""
            homeodds = ""
            awayodds = ""
            gametimearray = ""

            if showodds == "yes" and config.bool("show_odds"):
            	theodds = s["competitions"][0]["odds"][0]["details"]
            	theou = s["competitions"][0]["odds"][0]["overUnder"]
            	homescorefont = "CG-pixel-3x5-mono"
            	awayscorefont="CG-pixel-3x5-mono"
            	homeodds = get_odds(theodds, str(theou), home)
            	awayodds = get_odds(theodds, str(theou), away)
            	homescore = homeodds
            	awayscore = awayodds
            
            gametime = get_detail(gamedatetime)
            homescorecolor = "#fff"
            awayscorecolor = "#fff"
        
        if gamestatus == "in":
            gametime = s["status"]["type"]["shortDetail"]
            homescore = s["competitions"][0]["competitors"][0]["score"]
            homescorecolor = "#fff"
            awayscore = s["competitions"][0]["competitors"][1]["score"]
            awayscorecolor = "#fff"
            
        if gamestatus == "post":
            gametime = s["status"]["type"]["shortDetail"]
            homescore = s["competitions"][0]["competitors"][0]["score"]
            awayscore = s["competitions"][0]["competitors"][1]["score"]
            if(int(homescore) > int(awayscore)):
            	homescorecolor = "#ff0"
            	awayscorecolor = "#fff"
            elif(int(awayscore) > int(homescore)):
            	homescorecolor = "#fff"
            	awayscorecolor = "#ff0"
            else:
            	homescorecolor = "#fff"
            	awayscorecolor = "#fff"
            	

        if config.bool("show_time"):
        	
        	renderCategory.extend(
	            [
		            render.Column(
			            expanded=True,
						main_align="space_between",
						cross_align="start",
			            children = [
				            render.Column(
					            children = [
						            render.Box(width=64, height=1, color="#000"),
						            render.Stack(
							            children = [
								            render.Stack(
											     children=[
													render.Box(width=64, height=6, color="#000", child=render.Row(expanded=True,main_align="start",cross_align="start",children = [ 
														render.Box(width=1, height=6, color="#000"),
														render.Box(width=62, height=6, color="#000", child=render.Text(content = now.format("3:04 PM"), font="tb-8")),
														render.Box(width=1, height=6, color="#000"),
													])),
					                            ]
					                         )
							            ]
						            ),
						            render.Column(
									     children=[
										    render.Box(width=64, height=1, color="#000"),
											render.Box(width=64, height=12, color=awayColor, child=render.Row(expanded=True,main_align="start",cross_align="center",children = [ 
												render.Image(awaylogo, width=16, height=16), 
												render.Box(width=28, height=12, child = render.Text(content=away[:3], font="Dina_r400-6")),
												render.Box(width=20, height=12, child = render.Text(content=awayscore, color=awayscorecolor, font=awayscorefont))
											])),
											render.Box(width=64, height=12, color=homeColor, child=render.Row(expanded=True,main_align="start",cross_align="center",children = [ 
												render.Image(homelogo, width=16, height=16), 
												render.Box(width=28, height=12, child = render.Text(content=home[:3], font="Dina_r400-6")),
												render.Box(width=20, height=12, child = render.Text(content=homescore, color=homescorecolor, font=homescorefont))
											])),
			                            ]
			                         ),
					            ]
				            ),
			            ]
			            
		            )
	            ],
	        )
        
        else:
        
	        renderCategory.extend(
	            [
		            render.Column(
			            expanded=True,
						main_align="space_between",
						cross_align="start",
			            children = [
				            render.Column(
					            children = [
						            render.Stack(
									     children=[
											render.Box(width=64, height=12, color=awayColor, child=render.Row(expanded=True,main_align="start",cross_align="center",children = [ 
												render.Image(awaylogo, width=18, height=18), 
												render.Box(width=23, height=12, child = render.Text(content=away[:3], font="Dina_r400-6")),
												render.Box(width=23, height=12, child = render.Text(content=awayscore, color=awayscorecolor, font=awayscorefont))
											])),
			                            ]
			                         ),
						            render.Stack(
									     children=[
											render.Box(width=64, height=12, color=homeColor, child=render.Row(expanded=True,main_align="start",cross_align="center",children = [ 
												render.Image(homelogo, width=18, height=18), 
												render.Box(width=23, height=12, child = render.Text(content=home[:3], font="Dina_r400-6")),
												render.Box(width=23, height=12,  child = render.Text(content=homescore, color=homescorecolor, font=homescorefont))
											])),
			                            ]
			                         )
					            ]
				            ),
							render.Stack(
					            children = [
						            render.Stack(
									     children=[
											render.Box(width=64, height=7, color="#000", child=render.Column(expanded=True,main_align="center",cross_align="center",children = [ render.Text(content = gametime, font="CG-pixel-3x5-mono") ]))
			                            ]
			                         )
					            ]
				            ),
			            ]
			            
		            )
	            ],
	        )


    return render.Root(
        delay = int(mainspeed * 1000),
        child = render.Column(
            children = [
                render.Animation(
                    children = renderCategory,
                ),
            ],
        ),
    )


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
	        schema.Location(
			    id = "location",
			    name = "Location",
			    desc = "Location for which to display time.",
			    icon = "place",
			),
            schema.Toggle(
			    id = "show_time",
			    name = "Current Time",
			    desc = "A toggle to display the current time.",
			    icon = "clock",
			    default = False,
			),
			schema.Toggle(
			    id = "show_odds",
			    name = "Gambling Odds",
			    desc = "A toggle to display gambling odds for games that haven't started.",
			    icon = "dice",
			    default = True,
			)
        ],
    )


def get_scores(urls):
    allscores = []  
    for i, s in urls.items():
    	data = get_cachable_data(s)
    	decodedata = json.decode(data)
    	allscores.extend(decodedata["events"])
    	all([i, allscores])
    	print(all)
    	
    return allscores
    

def get_odds(theodds, theou, team):
	theoddsarray = theodds.split(" ")
	if(theoddsarray[0] == team):
		theoddsscore = theoddsarray[1]
	else:
		theoddsscore = theou
	return theoddsscore
	
	
def get_detail(gamedate):
	finddash = gamedate.find("-")
	if finddash > 0:
		gametimearray = gamedate.split(" - ")
		gametimeval = gametimearray[1]
	else:
		gametimeval = gamedate
	return gametimeval


    
def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()

