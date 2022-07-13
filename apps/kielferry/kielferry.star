load("render.star", "render")
load("time.star", "time")
load("math.star", "math")
load("encoding/base64.star", "base64")

FERRY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABUAAAARCAYAAAAyhueAAAAESElEQVQ4T11Ue0yVdRh+ft/lXDk
HucgBooNHFBnQRRiQUitjpDNbNOcfzsq5UNZMlmSLP5q6trZqloPJCk27zf7IzWSgbhybmVp/AC
kq2ykjOGd4DsgQKjiX7/br/b5Dtnr3/b7r+3u+53lvDP+zl44EOWMMgsisL4wvOogcrwhH8KujE
SlNx0CyEpynP372akPaedHuP2zvusAh0MEEWuZrDutiIQPPlj+I/l9i6Cw9hd2hzdbPTFBzGaYD
2fGWp60b67Tj4yAXBAIT0i9MpuYSCdg0W7YD2pwCg+uoFkK4rK3CCpuKqGInZ8EC1smXGwxHd61
Lc2np7k9LJlSRlukkCCYog+LR4FwwUPVALupK85HhdkHXdSiqalLFR/0jECBB44a1r6u5gbHdBJ
hmacpOMzMIUDIAyWVAVxm4omJ05CcM/XABst2J6fEwbLKCwMYXsa6uwdKj6+m9Ou1jrcfSLEVKj
E0QLRmMwOt4EkOCCwYjBsS57PoZ9BTVYGrgOzjUJGLRuygIlKDYH4CvrBYGgRl0MkPAXv/0vMVU
FEVs6mzDudZDJHcGdl8R1s6EMbe6FonZeXikJNbU14AlF6BpmhVzzRAwOjGNvpuRdNII0LyyfSf
Oc1O1KApoD5zBh7EtqMhxouPAXrz19kEsKw5AVXVcvnIJJdMxPN72BmmkjFPSlJSOmT9mcWowTP
KJqRUIYrrv2FkuLmb7sTvvYDBwAE+W5KJv8CZ2Na3HU9taYNwZw8Xe01heXIg4xbd9/348VFuHk
kI/wlMTWFVahf6xGOT5lJk7Au3u5WbGd1ZlwfdXJ3rG6hEcGIV3aRZe3rwFjCjIdhtJ1uF0Z6Iw
10NcOKLTs5AkEbJgoKtnAA7HEqhMgUp+rK2rh1NoUO/3oKggDzLF9p/yMgN/9Isv8dqenXAyGxT
NgMsuQVEUuFwuyLIIm0SbyW61vodv69ZajcC6vzrJr8278Xx5ATwuD073fgO7x4vD3cfRUFONlQ
8/iovBPsg2Jz7v6IDb5YTNRkBiBlWLRjUqQ5Y0iruGrv6fMTkXB/M3vclVLY6TB/eiIEtC6HYIF
WXlCI1HkeN14933P8CNsIZE4h7mIgMwlCQk2UGZ1uErLMLdyRg0KjEqcqzY2EoxJ6Ym9fz1O7j0
5xQWknG4qT4XUgoEchRECQU5Xvw2Nm6VipZMwNCoXZOpdO/LEjEmEJ1KzOmEv34rxvo+SbdpZfN
hHjp7CHb6h6YacGS4kbkkGylVsdpW0VLw+XIw8uNVanVKE7WNtdNuh8ubhfi9aRQ+sRXt21/Anm
1N9+cQKp5r4ZsaKzE4fBuJmVkIWTI83jw8UrYMl65cRfjWMJYu9yNyfZhqUsOamnrciI5jITKOz
EAAcZoPM9eG/p1SVvoWLX9DM+fJJKpXryTJDJHfI3BICeRlZ2AiOokNzzTCQZNJoQFyLhhETmYe
vv/62H/m6d9sgNcoHPJZ/AAAAABJRU5ErkJggg==
""")

FERRY_SCHEDULE = {
  "validity" : "2022-09-04",
  "weekday_schedule" : [
    "08:47",
    "09:37",
    "11:07",
    "13:07",
    "14:17",
    "16:07",
    "17:07",
    "18:42",
  ],
  "weekend_schedule" : [
    "09:02",
    "09:47",
    "10:47",
    "12:12",
    "13:37",
    "14:47",
    "15:22",
    "16:37",
    "17:07",
    "18:41",
  ],
  "holidays" : [
    "2022-05-26",
    "2022-06-06",
  ]
}

DAYOFWEEK_TO_WEEKDAY = {
    "Monday": True,
    "Tuesday": True,
    "Wednesday": True,
    "Thursday": True,
    "Friday": True,
    "Saturday": False,
    "Sunday": False,
}

def nextFerry(earliest):
  weekday = DAYOFWEEK_TO_WEEKDAY[earliest.format("Monday")]
  if weekday:
    schedule = FERRY_SCHEDULE["weekday_schedule"]
  else:
    schedule = FERRY_SCHEDULE["weekend_schedule"]
  for departure_str in schedule:
    departure = time.parse_time(
      earliest.format("2006-01-02") + " " + departure_str,
      "2006-01-02 15:04",
      "Europe/Berlin"
    )
    wait = departure - earliest
    if wait.minutes >= 0.0:
      return (departure, wait, True)
  return (None, None, False)

def nextFerryData():
  ret = (
    "-:-",
    "No data"
  )
  now = time.now().in_location("Europe/Berlin")
  departure, wait, found = nextFerry(now)
  if found:
    wait_min = math.floor(wait.minutes)
    wait_str = "now"
    if wait_min > 0:
      wait_str = str(math.floor(wait.minutes)) + " min"
    ret = (
      departure.format("15:04"),
      wait_str
    )
  return ret

def main():
  ferry_time, ferry_wait = nextFerryData()
  return render.Root(
    child = render.Row(
      children = [
        render.Column(
          children = [
            render.Image(src=FERRY_ICON),
          ],
          expanded = True,
          main_align = "center",
        ),
        render.Column(
          children = [
            render.Text(
                content = "Laboe",
                color = "#3399ff",
            ),
            render.Text(
              content = ferry_time,
              font = "6x13",
            ),
            render.Text(
              content = ferry_wait,
              color = "#ff6600",
            ),
          ],
          expanded = True,
          main_align = "space_evenly",
          cross_align = "center",
        ),
      ],
      expanded = True,
      main_align = "space_evenly",
    )
  )