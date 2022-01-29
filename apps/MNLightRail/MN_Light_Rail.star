"""
Applet: Minnesota Light Rail
Summary: Train Departure Times
Description: Shows Light Rail Departure Times from Selected Stop.
Author: Alex Miller
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("schema.star", "schema")

DEFAULT_STOP_CODE = "51408"
DEFAULT_STATION_NAME = "NICOLETTE MALL"

def main(config):

    stop_code = config.get("stop_code", DEFAULT_STOP_CODE)
    station_name = config.get("station_name", DEFAULT_STATION_NAME)

    url = "https://svc.metrotransit.org/NexTrip/" + stop_code + "?format=json"

    MTT = http.get(url).json()

     if MTT[0]["Route"] == "Blue":
          CB = "#00a"

          if MTT[0]["Description"] == "to Mpls-Target Field":
               DB = "MTF"
          else:      
               DB = "MOA"     

     else:
          CB = "#0a0"

          if MTT[0]["Description"] == "to Mpls-Target Field":
               DB = "MTF"
          else:      
               DB = "STP"



     if MTT[1]["Route"] == "Blue":
          CB2 = "#00a"

          if MTT[1]["Description"] == "to Mpls-Target Field":
               DB2 = "MTF"
          else:      
               DB2 = "MOA"     

     else:
          CB2 = "#0a0"

          if MTT[1]["Description"] == "to Mpls-Target Field":
               DB2 = "MTF"
          else:      
               DB2 = "STP"



     return render.Root(
        child = render.Column(
                children = [
                    render.Marquee(

                    width=64,
                         child = render.Text(station_name, font="tb-8"),
     
                    offset_start=5,
                    offset_end=5,
                    ),
                    render.Box(width=64, height=1),
                    render.Box(width=64, height=1, color="#a00"),
                    render.Row(     
                         children=[
                                render.Stack(
                                    children=[
                                        render.Box(width=12, height=10, color=CB),
                                        render.Text(DB, font="tom-thumb"),
                                    ],
                                ),
                                render.Box(width=6, height=10),
                                render.Text(MTT[0]["DepartureText"], font="Dina_r400-6"),
                         ],
                    ),
                    render.Box(width=64, height=1, color="#a00"),
                    render.Row(
                         children=[
                             render.Stack(
                                 children=[
                                    render.Box(width=12, height=10, color=CB2),
                                    render.Text(DB2, font="tom-thumb"),
                                 ],
                             ),
                              render.Box(width=6, height=10),
                              render.Text(MTT[1]["DepartureText"], font="Dina_r400-6"),
                         ],
                    ),
                    render.Box(width=64, height=1, color="#a00"),
               ],
          ),            
     )


def get_schema():

    return schema.Schema(

        version = "1",
        fields = [

            schema.Text(
                id = "stop_code",
                name = "Stop ID",
                desc = "Light Rail Station's Stop ID from (https://www.metrotransit.org/stops-stations)",
                icon = "subway",
            ),

           schema.Text(
                id = "station_name",
                name = "Station Name",
                desc = "Light Rail Station's Full Name from (https://www.metrotransit.org/stops-stations)",
                icon = "keyboard",
            ),
        ],
    )

