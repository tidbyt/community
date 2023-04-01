"""
Applet: Roc Bindicator
Summary: Show refuse in Rochester NY
Description: Use address located in Rochester, NY to query the City website and then display what trash bins to but at the curb for collection.
Author: Nolan Lynch
"""
load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/json.star", "json")

DEFAULT_LOCATION = """
{
	"lat": "43.1529219",
	"lng": "-77.6212444",
	"description": "Rochester, NY, USA",
	"locality": "Rochester",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

def main(config):

#Get User Input Data from config
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    Title_Texts = config.get("User_title_text", "Bindicator")
    Bar_Color = config.get("bar_color", "#de00cb")
    Positive_Color = config.get("Positive_Color", "#2f7000")
    Negative_Color = config.get("negative_color", "#700000")

#Convert config Location to Float from String
    LatAsString = loc["lat"]
    LatAsFloat = str(LatAsString)
    LongAsString = loc["lng"]
    LongAsFloat = str(LongAsString)

#Set conversion URL. The Location needs to change from reference type 4326 to 2262 (This is what the City GIS system needs the Location data formatted in.)
    Conversion_URL = "https://epsg.io/trans?x="+LongAsFloat+"&y="+LatAsFloat+"&s_srs=4326&t_srs=2262"

#Get Contents of Conversion URL and if failure, tell us what the code is. Also set lat & long variables for use in next step
    GIS = http.get(Conversion_URL)
    if GIS.status_code != 200:
        fail("GIS Conversion request failed with status %d", GIS.status_code)
    Lat2262 = GIS.json()["y"]
    Lng2262 = GIS.json()["x"]

#Set Refuse URL
    Trash_Schedule_URL = "https://maps.cityofrochester.gov/arcgis/rest/services/App_CityServices/City_Services/MapServer/9/query?where=&text=&objectIds=&time=&geometry="+Lng2262+"%2C"+Lat2262+"&geometryType=esriGeometryPoint&inSR=2262&spatialRel=esriSpatialRelIntersects&distance=1&units=esriSRUnit_Foot&relationParam=&outFields=NEXTPICKUP%2CTRASHPICKUPIS%2CDOW&returnGeometry=false&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=2262&havingClause=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&featureEncoding=esriDefault&f=pjson"
    rep = http.get(Trash_Schedule_URL)
    if rep.status_code != 200:
        fail("Trash request failed with status %d", rep.status_code)

#Define the JSON fields we want to use from Refuse URL call
    TrashPickupIs = rep.json()["features"][0]["attributes"]["TRASHPICKUPIS"]
    RecyclingPickupIs = rep.json()["features"][0]["attributes"]["NEXTPICKUP"]
    PickUpDayName = rep.json()["features"][0]["attributes"]["DOW"]

#Set Text to look for 
    This_Text = 'THIS'
    Next_Text = 'NEXT'
    two_week_text = 'two weeks'

#Lets find out what refuse is coming this week or not
    if (two_week_text in RecyclingPickupIs) and (Next_Text in TrashPickupIs):
	isRecycle = 'No'
	RecycleColor = Negative_Color
	isTrash = 'Yes'
	TrashColor = Positive_Color
	PrePickupText = "Next"
    if (Next_Text in RecyclingPickupIs) and (This_Text in TrashPickupIs):
	isRecycle = 'No'
	RecycleColor = Negative_Color
	isTrash = 'Yes'
	TrashColor = Positive_Color
	PrePickupText = "This"
    if (This_Text in RecyclingPickupIs) and (This_Text in TrashPickupIs):
	isRecycle = 'Yes'
	RecycleColor = Positive_Color
	isTrash = 'Yes'
	TrashColor = Positive_Color
	PrePickupText = "This"
    if (Next_Text in RecyclingPickupIs) and (Next_Text in TrashPickupIs):
	isRecycle = 'Yes'
	RecycleColor = Positive_Color
	isTrash = 'Yes'
	TrashColor = Positive_Color
	PrePickupText = "Next"

#Make Day Names Smaller
    if ("Monday" in PickUpDayName):
	PickupDayName = 'Mon'
    if ("Tuesday" in PickUpDayName):
	PickupDayName = 'Tues'
    if ("Wednesday" in PickUpDayName):
	PickupDayName = 'Wed'
    if ("Thursday" in PickUpDayName):
	PickupDayName = 'Thurs'
    if ("Friday" in PickUpDayName):
	PickupDayName = 'Fri'
    if ("Saturday" in PickUpDayName):
	PickupDayName = 'Sat'
    if ("Sunday" in PickUpDayName):
	PickupDayName = 'Sun'

#Let's display the data
    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                render.Box(
                    height = 8,
                    child = render.Text(Title_Texts, font = "tb-8"),
                ),render.Box(
        height = 1,
        color = Bar_Color,
    ),
                render.Box(
                    height = 8,
                    child = render.Text("Trash: " + isTrash, color = TrashColor)
                ),
                render.Box(
                    height = 8,
                    child = render.Text("Recycle: " + isRecycle, color = RecycleColor),
                ),
render.Row(
     expanded=True,
     main_align="space_between",
     cross_align="end",
     children=[
          render.Text("When: "),
          render.Marquee(
     width=40,
     child=render.Text(PrePickupText+" "+PickupDayName),
),
     ],
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
                icon = "locationDot",
                desc = "Refuse pickup address",
            ),
			schema.Text(
                id = "User_title_text",
                name = "Title",
                desc = "Set Title Text",
                icon = "heading",
                default = "Bindicator",
            ),
			schema.Color(
                id = "bar_color",
                name = "Color",
                desc = "Color of the divider bar",
                icon = "brush",
                default = "#de00cb",
                palette = [
                    "#7AB0FF",
                    "#BFEDC4",
                    "#78DECC",
                    "#DBB5FF",
                ],
            ),
			schema.Color(
                id = "Positive_Color",
                name = "Positive Color",
                desc = "Text Color when bin is going to be picked up",
                icon = "brush",
                default = "#2f7000",
                palette = [
                    "#6bff00",
                    "#1aad00",
                    "#95ff82",
                    "#497341",
                ],
            ),
			schema.Color(
                id = "negative_color",
                name = "Negative Color",
                desc = "Text Color when bin is not going to be picked up",
                icon = "brush",
                default = "#700000",
                palette = [
                    "#ff0000",
                    "#ff6969",
                    "#a60000",
                    "#ff4d4d",
                ],
            ),
        ],
    )