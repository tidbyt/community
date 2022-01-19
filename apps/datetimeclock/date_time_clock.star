"""
Applet: Date Time Clock
Summary: Shows full time and date
Description: Displays the full date and current time for user.
Author: Alex Miller/AmillionAir
"""

load("render.star", "render")
load("time.star", "time")

def main(config):
    timezone = config.get("timezone") or "America/Chicago"
    now = time.now().in_location(timezone)
    now_date = now.format('2 JAN 2006')
    Day = now.format('MONDAY')

    return render.Root(
       delay = 500,
       child = render.Column(
          expanded=True,
          cross_align="center",
               children=[
               render.Box(width=64, height=1),
               render.Animation(  
                    children=[  
                         render.Text(
                              content = now.format("3:04 PM"),
                              font = "6x13",
                         ),
                         render.Text(
                              content = now.format("3 04 PM"),
                              font = "6x13",
                         ),
                    ],
               ),     
               render.Text(
                    content = Day,
                    ),
               render.Text(
                    content = now_date,
                    font = "5x8",
                    ),
               render.Box(width=64, height=1),
               render.Box(width=64, height=1),      
               ],
          )
  )