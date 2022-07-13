load("render.star", "render")
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

def main():
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
              content = "20:15",
              font = "6x13",
            ),
            render.Text(
              content = "234 min",
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