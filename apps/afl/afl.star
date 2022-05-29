"""
Applet: AFL
Summary: AFL standings
Description: Display the current Australian Football League standings and the next game time/date for a selected team.
Author: andymcrae
"""

#some code borrowed or inspired by nhlnextgame by AKKanman

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("humanize.star", "humanize")
load("time.star", "time")

#URLs for AFL API data
AFL_STANDINGS_URL = "https://api.squiggle.com.au/?q=standings"
AFL_GAMES_URL = "https://api.squiggle.com.au/?q=games;year="

#set default team to the Sydney Swans
DEFAULT_TEAM = "16"

#team icons in base64
def getTeamIconFromID(teamID):
    if teamID == 1:  #ADE
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAPUlEQVQ4EWOUUq77z0AFwEQFM8BGUM0gxqsMDMPVa/9fWw9Tr7FIWzhTJSlRLR1RzaDRBEk4YqkW2FQzCAD9vAxi/8qeMQAAAABJRU5ErkJggg==")
    elif teamID == 2:  #BRI
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAiUlEQVQ4EWNUnPb5PwMVABMVzAAbMWoQ4ZBk7ODzH0mxVr55BwMIowNsYjA1GGGErrjT1wOmFkzD5NHFMRIkugIUU6AcbGowXATTCLMZxken0Q3DcBFMA7pCmDgumgWXBMxFyAbCxLDpweoikAZkA5A1wsTRDcVqEEwxsgHIhmOTxxnYyIYQwwYAn2wsec27ZnIAAAAASUVORK5CYII=")
    elif teamID == 3:  #CAR
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAw0lEQVQ4Ea2SQQ7CMAwEKeIVcIR3gvhnr30H1VaayrE3aQ/k4ni9Hidpp/vz/bsM1jJ/S/Xx+hTtVpSB4ADYT4FGAEBTvpq7CmaiAzcgIM4IpOfZQdlADkCRAdTIVWveiIIzyixdHnzSWFdtaERUxBxr0mIe/RsoCkyNmvYAGJDrBZQNEeJqaKdAvVMAUSyg3jscwTaQM7k3QYsnYf+3/2gHicxEd0Im9zwNKMJodNENKqDcqBO4xuwrXy0blHMdV0NbAV9ZXi1TCVCeAAAAAElFTkSuQmCC")
    elif teamID == 4:  #COL
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAP0lEQVQ4EWP8DwQMVAAsIDMYGRnhRiGbiywOUoBLDiTOBDeBQsaoQYQDcDSMRsOIcAgQVjH40hEjsCyhSsEGAACPER2NwKWiAAAAAElFTkSuQmCC")
    elif teamID == 5:  #ESS
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAdklEQVQ4Ea3UwQ3AIAgF0NI4Tbv/KJ2nSlINRioflNPXhCcHld5Sx4ZKbBCRm3pEx1VmOcUajhKpTW5IQxhzQRpyfyPB0AyBJ7IQCEIQE0KRKeRBfiEvokIRZICiSAetIA1aRRrEQVa99nLPysMTiSB8CO362DL1HBgdOCEVjwAAAABJRU5ErkJggg==")
    elif teamID == 6:  #FRE
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAtUlEQVQ4Ee2S4RXCIBCDhbHqAm5iR3KTuoBzqR/vxZciwQ7g/egduSQFjvJ8x3q+n4jb49KyPsK19r73wAtGEPuGxMJnJnA/RiwkonYha0Xi1NRw/JcJ3ArJRb4Tx70eccp12dodYTgigHskTk0Nx2XkWL/DdrQZ4YgJnP/UdFN5su2yResnIVw5DYX+zgggmc1M0O0eJIDChcLI/iPHv3ak5kgwwsSPRhBc6LXEnuPRnHSkfgFLoo1BPuVWJAAAAABJRU5ErkJggg==")
    elif teamID == 7:  #GEE
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAN0lEQVQ4EWP8DwQMVACMUsp1VDGIiQqOARsx+AxipFZgU81ro7FGOLWNxhrhMKJagqSaQVSLNQCrGBU8OjaC0wAAAABJRU5ErkJggg==")
    elif teamID == 8:  #GCS
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAApklEQVQ4Ec2RwQ2AMAwDC0JiFR7MxjBsxA482KbIj1SOlQih8qCftol9dduhHnM9t6X0jHW/ytgDYO9noImpvEbcaGTP4EBszgyZpoEgyMycjDXsaSAW86mowxzV2BOCzMzCrGYa92t6KvZaM6PODsT3f0qgoPRqURKrRW8WgjRZlE5hDaSNCAagpVJ4A2mDDejZyA5wIBNjzgys4bX7NW68Xf8PdANMSEAQ9TcZggAAAABJRU5ErkJggg==")
    elif teamID == 9:  #GWS
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAbUlEQVQ4Ea3Uyw3AIAwDUFJ1ABbtNF20G1AiVAlUPnGM73lycoiknLAhpxrPJRQV7xQOSsjDimgo6EMoqEbcUI2IlPvCq/UQuNEIgaAZYoZWiAmyIEvIikwhBBlCKNKFPMgP8iINxCAKya7H9gJ03yO/6E9S7gAAAABJRU5ErkJggg==")
    elif teamID == 10:  #HAW
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAOklEQVQ4EWP8f5D9f9UURwYYaMvZD2MyIIuDBHHJgcSZ4LooZIwaRDgAR8NoNIwIhwBhFaPpiHAYAQBvDQvqUURIwAAAAABJRU5ErkJggg==")
    elif teamID == 11:  #MEL
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAZklEQVQ4EWO8ysDwn4EKgMlVuY5iY0BmMIFMocQwmF6wQeQaBjMEpB9uEKmGIRuCYRCxhqEbgtUgQoZhMwSnQbgMw2UIXoPQDcNnCEgto5RyHXUSJMg0agCU6KfEwFGDCIfe4AsjAHY9EhFcE9FpAAAAAElFTkSuQmCC")
    elif teamID == 12:  #NOR
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAPklEQVQ4EWP8DwR8HosYYODTjjgYkwFZHCSISw4kzgTXRSFj1CDCATgaRqNhRDgECKsYTUeoYcQIBKgiDAwAleENJA7mL7gAAAAASUVORK5CYII=")
    elif teamID == 13:  #POR
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAsUlEQVQ4Ea2UwQ6CQAxErXL0//xG/T44GtzZZJrKTgtEe+mmnXl0C8HWFpc/xJQxzEy2sudeoZ5ey2BSBlWjt4OOwCoI/A6qYHuQAZTBUI/B68Ta10RsKOFer4Pejzt1nhVM1ej1iVhwUjtEYzxTEz3WFrnGb+b2nKkrc4TgZfhEdEUBa9usNAMIJiUkLOtJUAbLINCnoC2sgkA7LBvFsyGXfRZCfXk1io7k/j/CaL/GB31XVG9zjPcNAAAAAElFTkSuQmCC")
    elif teamID == 14:  #RIC
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAe0lEQVQ4Ea3U2w2AIAwFUK5xBJ3G9XUah0BrlEdA+oB+XUh66AcAf5cbUDMZANSUP7fYs+xuiit5ypC3TQ3VELJUUA3BejwziaEWIp6IQ0SQBGEhKdKENMgvpEWqkAUpICuSQT1IgHqRAFFI67v26R6XiydiQegQjPrYLo+aMh01CRmxAAAAAElFTkSuQmCC")
    elif teamID == 15:  #STK
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAQUlEQVQ4EWP8DwQMVAAsIDOuGBhgGKVz4QKGGEiAkZERQxzkFiYMUTIFRg0iHHCjYTQaRoRDgLCKwZeOGKlVsAEA/oIOHbOdgRUAAAAASUVORK5CYII=")
    elif teamID == 16:  #SYD
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAYUlEQVQ4Ee3RwQ3AIAgFUHAc91/FeajfxKZVEVs8Nf0nDvBCgBOR0IaEKH4HRsAyHqzOFugtVhHMn9BT7Ip00CrWIkPIwkaICmmYhkyhFpsh6GXJQeHN7Wse7Ifs6334RgfdHyhzzeI3qgAAAABJRU5ErkJggg==")
    elif teamID == 17:  #WCE
        return ("iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAANElEQVQ4EWP8f5D9PwM2YPcDmyiDtEo9VnEmrKJkCI4aRDjQRsNoNIwIhwBhFaPpiHAYAQBZHATebqrONQAAAABJRU5ErkJggg==")
    elif teamID == 18:  #WBD
        return "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAOElEQVQ4EWPkdV/4n4EKgIkKZoCNGDWIcEgOvjBivKyvP0zTEeOgyyKM/4GAcCohrGIQpqNBF9gALe0MKAvt8SYAAAAASUVORK5CYII="

#get abbreviated team name from the teamID. Teams are in alphabetical order
def getTeamAbbFromID(teamID):
    if teamID == 1:  #ADE
        return ("ADE")
    elif teamID == 2:  #BRI
        return ("BRI")
    elif teamID == 3:  #CAR
        return ("CAR")
    elif teamID == 4:  #COL
        return ("COL")
    elif teamID == 5:  #ESS
        return ("ESS")
    elif teamID == 6:  #FRE
        return ("FRE")
    elif teamID == 7:  #GEE
        return ("GEE")
    elif teamID == 8:  #GCS
        return ("GCS")
    elif teamID == 9:  #GWS
        return ("GWS")
    elif teamID == 10:  #HAW
        return ("HAW")
    elif teamID == 11:  #MEL
        return ("MEL")
    elif teamID == 12:  #NOR
        return ("NOR")
    elif teamID == 13:  #POR
        return ("POR")
    elif teamID == 14:  #RIC
        return ("RIC")
    elif teamID == 15:  #STK
        return ("STK")
    elif teamID == 16:  #SYD
        return ("SYD")
    elif teamID == 17:  #WCE
        return ("WCE")
    elif teamID == 18:  #WBD
        return "WBD"


def main(config):
    teamID = config.get("main_team") or DEFAULT_TEAM
		
    todaysDate= time.now()
    todaysDateFormatted = humanize.time_format("yyyy-MM-dd", todaysDate)

    standings_cached = cache.get("afl_standings")
	#only make the request from the API if we need to
    if standings_cached != None:
        print("Hit! Displaying cached standings data.")
        stand_data = json.decode(standings_cached)
    else:
        print("Miss! Calling Squiggle API for standings data.")
        rep = http.get(AFL_STANDINGS_URL)
        if rep.status_code !=200:
            fail("Squiggle request failed with status %d", rep.status_code)
        stand_data = rep.json()
        cache.set("afl_standings",json.encode(stand_data),ttl_seconds=3600)
	
    standings = []
	#could tidy this up a little
	#get the team identifier in standings order
    for i in range(len(stand_data["standings"])):
        standings.append(stand_data["standings"][i]["id"])
   		
    #build the output message    
    message = " "
    for i, x in enumerate(standings):
        message = message + str(i+1)+ ": " + getTeamAbbFromID(standings[i]) + "  "
	
    games_cached = cache.get("afl_games")
  	
	#call the Squiggle API and retreive list of unfinished games for the year  
    if games_cached != None :
        print("Hit! Displaying cached game data.")
        game_data = json.decode(games_cached)
    else:
        print("Miss! Calling Squiggle API for game data")
        rep2 = http.get(AFL_GAMES_URL+todaysDateFormatted[0:4]+";complete=!100")
        if rep2.status_code !=200:
            fail("Squiggle request failed with status %d", rep2.status_code)
        game_data = rep2.json()	
        cache.set("afl_games",json.encode(game_data),ttl_seconds=3600)
  	
    hgames = []
  	#find the home games for this team - finals data is null until populated at end of primary rounds
    for i in range(len(game_data["games"])):
        if game_data["games"][i]["hteamid"]:
            hometeam = int(game_data["games"][i]["hteamid"]) #convert to int as this field is decimal
        if  str(hometeam) == str(teamID): #compare the two as strings
            hgames.append(game_data["games"][i]["id"]) #add this game to the list of games
  			
    agames = []
  	#find the away games for this team
    for i in range(len(game_data["games"])):
        if game_data["games"][i]["ateamid"]:
            awayteam = int(game_data["games"][i]["ateamid"])	
		if str(awayteam) == str(teamID):
  			agames.append(game_data["games"][i]["id"])
    
    if agames[0] > hgames[0]:
        nextgameID = int(hgames[0])
    else:
  		nextgameID = int(agames[0])
  	
    homeTeamID = ""
    awayTeamID = ""
    nextgamedate = ""
    round_number = ""
    venue = ""
  	
  	#get the data for the next game
    for i in range(len(game_data["games"])):
  		if game_data["games"][i]["id"] == nextgameID:
  			homeTeamID = game_data["games"][i]["hteamid"]
  			awayTeamID = game_data["games"][i]["ateamid"]
  			nextgamedate = game_data["games"][i]["date"]
  			round_number = int(game_data["games"][i]["round"])
  			venue = game_data["games"][i]["venue"]

    displayDate = ""
    date_key = nextgamedate[0:10]

    if date_key == todaysDateFormatted:
		displayDate = "Today"
    else:
		displayDate = nextgamedate[8:10] + "-" + nextgamedate[5:7]
	
    displayTime = nextgamedate[11:16]

	#get icon data
    homeTeamIcon = base64.decode(getTeamIconFromID(homeTeamID))
    awayTeamIcon = base64.decode(getTeamIconFromID(awayTeamID))
  	#get abbreviated team name
    homeTeamAbb = getTeamAbbFromID(homeTeamID)
    awayTeamAbb = getTeamAbbFromID(awayTeamID)
  	  	 	
    return render.Root(
   		child = render.Column(
   			expanded = True,
   			main_align = "space_around",
   			children = [
   				render.Row(
   					expanded = True,
   					main_align = "space_between",
   					cross_align = "center",
     				children=[
          				render.Box(
          					width=24,
          					height=26,
          					child = render.WrappedText("RD:" + str(round_number) + " " + displayDate + " " + displayTime, font = "tom-thumb")
          				),
          				render.Box(
          					width=20,
          					height=26,
          					padding=1,
          					child=render.Column(
          						cross_align="center",
          						children=[
          							render.Image(homeTeamIcon),
									render.Text(homeTeamAbb, font = "tom-thumb"),
          						],
          					)
          				),
          				render.Box(
          					width=20,
          					height=26,
          					padding=1,
          					child=render.Column(
          						cross_align="center",
          						children=[
          							render.Image(awayTeamIcon),
									render.Text(awayTeamAbb, font = "tom-thumb"),
          						],
          					)
          				),
     				],
				),
   				render.Marquee(
 					width=64,
            		child = render.Text(message, font = "tom-thumb"),
            		offset_start=5,
            		offset_end=32,
            	),
       		],
   		),
	)

TEAM_LIST = [
    schema.Option(display = "Adelaide", value = "1"),
    schema.Option(display = "Brisbane", value = "2"),
    schema.Option(display = "Carlton", value = "3"),
    schema.Option(display = "Collingwood", value = "4"),
    schema.Option(display = "Essendon", value = "5"),
    schema.Option(display = "Freemantle", value = "6"),
    schema.Option(display = "Geelong", value = "7"),
    schema.Option(display = "Gold Coast", value = "8"),
    schema.Option(display = "Greater Western Sydney", value = "9"),
    schema.Option(display = "Hawthorn", value = "10"),
    schema.Option(display = "Melbourne", value = "11"),
    schema.Option(display = "North Melbourne", value = "12"),
    schema.Option(display = "Port Adelaide", value = "13"),
    schema.Option(display = "Richmond", value = "14"),
    schema.Option(display = "St Kilda", value = "15"),
    schema.Option(display = "Sydney", value = "16"),
    schema.Option(display = "West Coast", value = "17"),
    schema.Option(display = "Western Bulldogs", value = "18"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "main_team",
                name = "Team",
                desc = "Pick a team to follow",
                icon = "",
                default = TEAM_LIST[0].value,
                options = TEAM_LIST,
            ),
		],
	)
