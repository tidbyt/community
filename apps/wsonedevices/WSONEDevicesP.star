#Shows total number and status of Workspace ONE UEM devices in all OGs.
#
#by Craig J. Johnston
#email: ibanyan@gmail.com

# Import the required libraries
load("render.star", "render")
load("http.star", "http")
load("humanize.star", "humanize")
load("encoding/base64.star", "base64")
load("schema.star", "schema")

#Set the fonts
FONT = "tom-thumb"
HFONT = "5x8"

#Define the items that make up the query to the WS1 tenant.
#Set the root OG ID.
#Look at the number at the end of the URL after navigating to OG Details page.
# og = ""


#Set your tenant code.
#AirWatchAPI Key in the REST API screen.
# tenantcode = ""

#Set the API admin user's username and password.  Today this app only supports Basic authentication.
#It will be encoded into Base64 for you.
# adminuser = ""
# adminpassword = ""
# authotmp = base64.encode(adminuser + ":" + adminpassword)
# autho = "Basic " + authotmp

#Set your tenant's API url.
#This is your tenant URL but changing cn to as.
# tenanturl = ""

#The actual API query.  Don't change this.
query = "/API/system/groups/devicecounts?organizationgroupid="

#Set the API URL by adding the tenanturl, query, and og vsariables together.
# AWDEVICES_API_URL = tenanturl + query + og

#Create the WS1 icon.  This icon is a PNG file that was encoded with base64 by using:
# base64 -i logofilename.png |pbcopy
#in Terminal on a Mac.  Piping it to pbcopy puts it directly into the clipboard so it can be pasted into the app.
#We then ask to have the base64 decoded back into the icon image.
WSICON = base64.decode("""
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1FjrnvyFwby2ssx1mqNIYhFLECFARg1lVGAhSqtGiok07Sc8/COOXySXTK4yGDkWUIUKyfGD/8Hvbs3C9JSbFEwA3S+2/TEG9OwCzbptfx/bdvMECDwDV1rbX20As5+k19ta5AgY3AYurtuavAdc7gDDT7pkSI4UoOkvFID3M/qmHDB0C/Svub219nH6AGSoq9QNcHAIjBcpe93j3b2dvf17ptXfD+TCctTxlbYAAAANemlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAtRXhpdjIiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIgogICAgeG1sbnM6R0lNUD0iaHR0cDovL3d3dy5naW1wLm9yZy94bXAvIgogICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgIHhtcE1NOkRvY3VtZW50SUQ9ImdpbXA6ZG9jaWQ6Z2ltcDo3YjVmMjE2Yi0wNzg4LTQ2ZGQtYTExNi0xM2VmNTJjYjU4MjciCiAgIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDdmNzQ3ZDktODhiNi00NDc5LWEyODYtODg5NjVkMDkwYWY3IgogICB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6ZjhkZGVmNzEtYTI2Yy00MjY3LWFhZmItMDcwYWU3NGMwMjJlIgogICBHSU1QOkFQST0iMi4wIgogICBHSU1QOlBsYXRmb3JtPSJNYWMgT1MiCiAgIEdJTVA6VGltZVN0YW1wPSIxNjk5NTQxNzI0MjI1NzI1IgogICBHSU1QOlZlcnNpb249IjIuMTAuMzQiCiAgIGRjOkZvcm1hdD0iaW1hZ2UvcG5nIgogICB0aWZmOk9yaWVudGF0aW9uPSIxIgogICB4bXA6Q3JlYXRvclRvb2w9IkdJTVAgMi4xMCIKICAgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMzoxMTowOVQwOTo1NToyMS0wNTowMCIKICAgeG1wOk1vZGlmeURhdGU9IjIwMjM6MTE6MDlUMDk6NTU6MjEtMDU6MDAiPgogICA8eG1wTU06SGlzdG9yeT4KICAgIDxyZGY6U2VxPgogICAgIDxyZGY6bGkKICAgICAgc3RFdnQ6YWN0aW9uPSJzYXZlZCIKICAgICAgc3RFdnQ6Y2hhbmdlZD0iLyIKICAgICAgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoxY2E4NzYxOS05N2NkLTQ2ZjMtOWZlYy0wYTlkNjJjZTFkMTEiCiAgICAgIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkdpbXAgMi4xMCAoTWFjIE9TKSIKICAgICAgc3RFdnQ6d2hlbj0iMjAyMy0xMS0wOVQwOTo1NToyNC0wNTowMCIvPgogICAgPC9yZGY6U2VxPgogICA8L3htcE1NOkhpc3Rvcnk+CiAgPC9yZGY6RGVzY3JpcHRpb24+CiA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgCjw/eHBhY2tldCBlbmQ9InciPz4EbCFvAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5wsJDjcYRLjqaQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAEzSURBVBgZASgB1/4AAAAAAACU0gUAAAAAAJXT/wAAAAAAldP/AAAAAACU0QMAAAAAAAAAAAAAldMBAJXT/wAAAAAAAAAAAAAAAACV0/8AldMBAAAAAAAAAAAAAJXT/wAAAAAAAAAAAAAAAAAAAAAAAAAAAJXT/wAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJXTBAAAAAAAAAAAAAAAAACV0wUBAQEEAAAAAAIAAAAAAIzKAQDr7P8AldP/AAAAAACV0+oA8/P9/////AAAAAAAAAAAAAAAAAAAAAAAAHm4BgCV0/8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAbCKlTpNjogAAAAAElFTkSuQmCC
""")


# Main function to render the Tidbyt app

#Here we are calling the API and including all the headers.  We check to make sure it returns a HTTP 200.
#If not, we fail the app which makes it stop.

#When the JSON data comes back from this API call, it has a value at the bottom called "Total".
#This is actually the total number of OGs (or as it appears in the JSON file "LocationGroups"),
#and so we put the number we find there into the variable totalog.
#We also look for the root OG name at LocationGroup 0 and put its value in rootog.
#We then set the rest of the variables to 0.

#After this we use the totalog variable to create a FOR loop.  The loop starts at 0 and counts to the value
#stored in totalog.
#Inside this loop we grab the info we need from each LocationGroup.
#Because the returned JSON doesn't include a key if the value is 0, we have to first check to seee if its there
#before we try and get the value, otherwise the app stops with an error.

DEFAULT_OGI = "11536"
DEFAULT_TENNANTCODEI = "W2+l8YG+rrWWFUI6v9E+6lE+Tef8fQZYt4VMj7ATEzY="
DEFAULT_TENANTURLI = "https://as1506.awmdm.com"
DEFAULT_ADMINUSERI = "apiguy3"
DEFAULT_ADMINPASSWORDI = "VMware2!"

def main(config):
    og = config.get("ogi", DEFAULT_OGI)
    tenantcode = config.get("tenantcodei", DEFAULT_TENNANTCODEI)
    tenanturl = config.get("tenanturli", DEFAULT_TENANTURLI)
    adminuser = config.get("adminuseri", DEFAULT_ADMINUSERI)
    adminpassword = config.get("adminpasswordi", DEFAULT_ADMINPASSWORDI)

    authotmp = base64.encode(adminuser + ":" + adminpassword)
    autho = "Basic " + authotmp
    #Set the API URL by adding the tenanturl, query, and og vsariables together.
    AWDEVICES_API_URL = tenanturl + query + og

    rep = http.get(AWDEVICES_API_URL, headers = {"Authorization": autho, "Accept": "application/json", "aw-tenant-code": tenantcode})
    if rep.status_code != 200:
        print("URL %s" %AWDEVICES_API_URL)
        fail("The request failed with status %d", rep.status_code)
        
    totalog = rep.json()["Total"]
    rootog = rep.json()["LocationGroups"][0]["LocationGroupName"]
    totaldevices = 0.0
    totalunenrolled = 0.0
    totalenrolled = 0.0
    totalenrollp = 0.0
    
    for i in range(int(totalog)):
        if (rep.json()["LocationGroups"][i].get("TotalDevices")) == None:
            devicecount = 0
        else:
            devicecount = rep.json()["LocationGroups"][i]["TotalDevices"]
            totaldevices += devicecount

        if (rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"].get("EnrollmentInProgress")) == None:
            enrollp = 0
        else:
            enrollp = rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"]["EnrollmentInProgress"]
            totalenrollp += enrollp
        
        if (rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"].get("Enrolled")) == None:
            enrolled = 0
        else:
            enrolled = rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"]["Enrolled"]
            totalenrolled += enrolled

        if (rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"].get("Unenrolled")) == None:
            unenrolled = 0
        else:
            unenrolled = rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"]["Unenrolled"]
            totalunenrolled += unenrolled

#Now that we have the values we need, we can put them on the screen.
#We render a column so that all items (or children as they are called) are vertically laid out.
#The children of the column are then listed between the [ and ].
#For the first child we render a row because we want to put the WS1 icon next to the root OG name.
#Further when rendering the root OG name we do it as a Marquee so it scrolls.
#This is because we don't know how long this name will be.
#The rest of the children are the the name of the value and the value itself.
#We also use the humanize.ftoa function to remove the .0 from each number.
#We use the Height value to make the height of the row 1 pixel higher than the top of the text.
#This provides a nice 1 pixel space between each row.
        
    return render.Root(
        child = render.Column( # Column is a vertical children layout
                children = [
                    render.Row(
                        children = [
                            render.Image(src=WSICON),
                            render.Marquee(
                             width=64,
                             child=render.Text("%s" % rootog,font = HFONT,color = "#1270cd"),
                            ),
                        ],
                    ),
                    render.Text(
                        content = "Total:     %s" % humanize.ftoa(totaldevices,0),
                        height = 6,
                        font = FONT,
                    ),
                    render.Text(
                        content = "Pending:   %s" % humanize.ftoa(totalenrollp,0),
                        height = 6,
                        font = FONT,
                    ),
                    render.Text(
                        content = "Enrolled:  %s" % humanize.ftoa(totalenrolled,0),
                        height = 6,
                        font = FONT,
                    ),
                    render.Text(
                        content = "Unenrolled:%s" % humanize.ftoa(totalunenrolled,0),
                        height = 6,
                        font = FONT,
                    ),
                ],
        )
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ogi",
                name = "Root Organization Group ID",
                desc = "The number at the end of the URL after navigating to OG Details page.",
                icon = "number",
            ),
            schema.Text(
                id = "tenantcodei",
                name = "Tenant Code",
                desc = "AirWatchAPI Key in the REST API screen.",
                icon = "number",
            ),
            schema.Text(
                id = "tenanturli",
                name = "Tenant URL",
                desc = "This is your tenant URL but changing cn to as.",
                icon = "url",
            ),
            schema.Text(
                id = "adminuseri",
                name = "API Admin's Username",
                desc = "Username for the API admin user.",
                icon = "user",
            ),
            schema.Text(
                id = "adminpasswordi",
                name = "API Admin's Password",
                desc = "Password for the API admin user.",
                icon = "key",
            ),
        ],
    )
