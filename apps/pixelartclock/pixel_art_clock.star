"""
Applet: Pixel Art Clock
Summary: Clock & pixel-art weather
Description: Displays a clock, today's max and min temperatures, with a pixel-art illustration by @abipixel matching today's forecast from AccuWeather. To request an AccuWeather API key, see https://developer.accuweather.com/getting-started. To determine AccuWeather location key, search https://www.accuweather.com for a location and extract trailing number, e.g. 2191987 for https://www.accuweather.com/en/us/lavallette/08735/weather-forecast/2191987.
Author: JavierM42
"""

# Based on the AccuWeather Forecast app by sudeepban

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ACCUWEATHER_FORECAST_URL = "http://dataservice.accuweather.com/forecasts/v1/daily/1day/{location_key}?apikey={api_key}&details=true"

max_temp_color = "#fcc"
min_temp_color = "#ccf"

clock_colors = {
    "sunny": "#fff",
    "sunnyish": "#000",
    "rainy": "#000",
    "thunderstorm": "#fff",
    "cloudy": "#000",
    "clear_night": "#fff",
    "cloudy_night": "#fff",
    "windy": "#000",
    "snowy": "#fff",
}

# iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAbElEQVRoge3Suw2AMBCDYQch6JmAEVkAmkxJxwQMkCZUQRQ8KnIo/F95usKWLAHAjznrAG+I8xAlSX2331w7nXat8kQykMo34+1bnSGKjYfiSZkLOExfwUvLevla7gKCt04AAAAAAAAAAPicDbuDCkAllnRiAAAAAElFTkSuQmCC
sun = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAa0lEQVRoge3Suw2AMBCDYQcxAT0SHesxSgZimEj0WSGpgih4VORQ+L/ydIUtWQKAH3PWAd6QViVJ0rjsNzf7065dnUgGSvlpuH3rK0Sx8VC8aHMBh+krRGnzl6/tLiBE6wQAAAAAAAAAgM/JbwkKm5dCasUAAAAASUVORK5CYII=
""")

# iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAf0lEQVRoge3VOw6AIBBFUTVGe1fgEt0AFrhKl4LNWBhJjEBiIZPAPeWE4j3Cp2kAlEqcFe0M2cVKx+btv3F0yL5cZefJz9pxDXbt8kRScJcfTHJZURvwOOaDeZWv5k0QZ8VzVvyVCOhzBsvq2LQT6Pj6CxStytIAAAAAAAAAkk6mYDU7lBZnXQAAAABJRU5ErkJggg==
sun_with_rays = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAiUlEQVRoge3WsQ2AIBCF4cM4Ab2JnYs4EKM4kIvQmdi7AhZGCyVi45HA/5WE4r0jlyACFCt4F3JnUJUqXN1AvjC5A/whzHK8dOeuMzNM0a6NTqQMzvK9fb1WzAAe+93baPn7vTJXwLtwlV82kXUSM8a7tprBVC1b7gRQxz/gprrCAAAAAAAAQNoOkwsoNJ9QT3EAAAAASUVORK5CYII=
""")
sunny = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAm0lEQVRoge2UwQ1AQBQFkT24uStDQ/pQgLKUoAx3J2608JN9Mvnx5izP7CS77bxdT/NjOlqApoxDLxk6zluyoyRytqISV4WMEvGOfFMUMtGffUVNfNkVyMrvH0EHoAVoHIAWoHEAWoDGAWgBGgegBWgcgBagcQBagMYBaIEa1ql+I3UABakDLHv9RuoAChyAFqBxAFqAxgFoAZoX7I4UW3hu5CgAAAAASUVORK5CYII=
""")),
    "foreground": render.Stack(children = [
        render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAFU0lEQVRoge1WX0hbVxz+0qtNF01qGqlJtHXqKrMVsybsQd1YC4VarB0M1q4DSx90RQqCo1PcRmGj2ywUHI5RZC+jha6WsQfTUIVS6YMTZhOnZNVVq1WiSYeaNqna1Ibs4XpOzj33RuPEtrJ8cDj3/Lm/833f+Z1zL5BAAgkkkMCrjVsTC5FbEwuRl83jheN/KzyBF4QNm11rPRob9mhtWOIJvKIo+TAnolrPBY6cvxZXurY3HF1XHgTlNZaI8PoXAIDpOw0AANWR89ci7Q1HVSzZtRCKV3QskLVjxfmv3Ei88INvJP2qeAjHs+haha8FSvyU+EzfaYA+XSfpU+2rbZJN1GXmKi4Sj8jA5OhKU2KusVqQtZRi8TxSFn+BfzoAABITFA1YiWgskcHbzdC+V7cC7fXHlZr9AICPL3YBEMUDoAaw2LRSsMDkqKwEbzcDgKx+mWi1jtLy2UWjZGwu+TgAcedJIUj6O3XPqhczL9XGMg3mFuTjq82E/N423Hv7WFxzWb6molIAgHegG/vuRfudNT7YLv8DMHOtfuV4NANMRaWSshyMZRrFNt8fb2YU7NBgov1XvO+zI7+3LeY8Ip5w9A50wzvQLZnjrNwuiufg0p+jz+xRUJk+tyveAbwJ7ELWcC3u3nyE3QfSZLV3rxOmPhtcQgvMjipEGgcl79ePNMnWehxIkrRbrWeUKKGi6yzs+79WHGO5/XTyqqjhu0WYs8Stn/LoUW2rh3doDkDUhE2xdpy46x3ohqnPRvu3dJ5YlgBr1GzSM5j6bGKMolKccl2ggtmiBLOjStZXsEOD1658hfqRJlR0nZXNnfLopVwak+Gs3E7bjoeNuD73I4Dol0BV3pATAQC1W5C8HCoMwyW0wBquBTseKgzH3H2leq/RgFBhGIvDAkrmM2H3DqHC9Catpx6LO2HeqoPdO0TXz87S0ud3UzKocSxarWdgdlTBWKbBde9llC5UisJ0AZoFAFD980fwjwL6XIh1ui6aAbxwIpJHj6UZfb4ZWT+Puzcf0Xr3gTSMe4JQuwUk7wrT1O61TAAAFc+DFV8Uzlw2UwDAJbTgcMrp6O0e0OGdQ6dR3fIJnaPP5WqSAR+UvxEJFYYlGcC2iRlqtyAzINaus2Pbnm+mgnhj1W4BPRbxojzlugC7dwjZWVr0WJpR3F+H9FktzFt1ErP4TDGWSD95BIM3klFwaBEu/TmaxQiIsdQTcwjtTAGw9BXgs4C0CTmX0KK4CG8GWxMj+LiLwwLUbrGMe4LIGa6F2VGFAWEShjxRvKmoFOOeoORdYgQRb8jTUmPVE3O0kHbWp99j8EYyrP4vReEBHR0P7Uyh85f9ESrur4OvYx5mRxUlxAplRfKpTzCb9AxP1MC4J4hxTxCpIbGfxAvdmwcA+DRhpIbENclFOnT8ByrY7h2Cc35Kwu+JGvD97qO7ScQDQHrnyZjmkGdg6QjwwskFWNwv/Znp883I0pw3gDdnV7ZBEmPmvnRnAUCdL/1/IKawdwEBnxksjCVGMb2XjtpgmwFv7YnyIu9mZ2nxm2NEZbNkRGQG9FiaYQ3Xyo4FANkd8PTgJWzpPCFJeyKejAHAtuebFQkTgYSYIU+LmftBifDlBEvEMz9hareAP/9KQ8GxGdomsfjYKuvVWWoA+70nL/KXIBH29OAleL+tUOXY9BFAfiTY8TGnXwUANktGhBXOi8zO0koEG/Kk80j28GJ5k0gmEIQKw/B1zMsMB5j/AADwdcxHg5RpqAFqt4AHlX9Qk1ihY04/NYFvjzn9ikeMFx4LSoRjzWFBLjnyrrP/oQoA+H+ecU8Q/wI13OQen1IltAAAAABJRU5ErkJggg==
""")),
        render.Animation(
            children = [
                render.Image(src = sun),
                render.Image(src = sun),
                render.Image(src = sun_with_rays),
                render.Image(src = sun_with_rays),
            ],
        ),
    ]),
}

sunnyish = {
    "background": render.Image(src = base64.decode("""
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
""")),
    "foreground": None,
}

rain_for_animation = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAHwAAAA/AgMAAABfvETvAAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAxQTFRF7f/5AAAA////////5apNygAAAAR0Uk5T/wABBHPglTMAAAFrSURBVHicnVTLdcIwEJSCC/CFOyVQAAddUkDeS/pVCZRACS7AwZFWq/1IK+PAAXgaz87serT+HNbJjT/+Zwe08es9fW3euRhaPGaxfOzSb35E4+lkmT+e7+nbbQAOSss8xHcm4L+mARPxz7k0pC0QJdVP6mAAT+EhovT9abWC18KLELP4MaDSAIdKqtvD8+XCyiD5G8yw4IliDDEf7elTfjouiHF+9EyUWMb5BdSyTEB9w32h9P4qd50438IgK4l8C4M8Kvix+pftvnH/1DR6XCek4Kdf1O3mkPMfcUWkwt2bSPlPBS+Pf/g7gpOgdT9gTbjSifV+ZBMv9c8B/7U3R/LzSF/tl0H9b7+3Xvr9wrUoHyqwHH2g2f2xYsGlwVUJmvtHJKjBoZC8Tw3e54dwKFqV6TnyN5jhsf0ivFs4ceONq4j7zTThr5DqfsGR1MnQjkH9UQKi/X6qzOb1fidaUP7bvnhc2yjfteIf/Ymd6j3uqogAAAAASUVORK5CYII=
""")
rainy = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAMAAACVQ462AAAAAXNSR0IB2cksfwAAAAlwSFlzAAAWJQAAFiUBSVIk8AAAANVQTFRFxNzvxd3vyd/wd/93lcr+WrFaKYcpAAAA/ue9frrtlMn9GXWgAWSOfLnrlMr+JHypjsX5icL1aKzGAX2ZM5e7dLnnD4OjFYalkcf7DIKhjMT3AXmXAXqYswBWBn+ci8X3DoSij8b6v9rtw9zvwtvukcj8k8n8dgA4An2Zaq3Ha67IvNjskMf4j8b3jMTzDYWeAH+Y7dm1AWWOAmSOicT2C4SdEoegd/54BVCRBYGajMX4XLFlAWaPnc79crPSAmCPAWKODoSfkf98AmGOAoCZEF6PDISeD2WaJQAAAkZJREFUeJzFlEFv00AQhd/YSW1cQkRoExUUCYHSFilFkeDQv98jiANSfGl9gSJES0WkpFUUx47NzOzabdImrYIqVs7srHfft2/Hdgj/2OixAETZf3bwuACXf7P1Aa7tZ+sB3Bv5bA2AOzealYBKKj+J9+kd8PN1iKWSzUAViBYFQLMVAIdD5oDyTDMFQGQSFgF6d65Vi4RymyQlgFtqulJ1JyCBx0meS8bD/F6AqU5JSACPt88zSmSY6xGqycZ0BWCxuD7vm5KsFgEFZNrls7Q6XAmwJ6pU5gHPndhXwtTj5Ow2QJzNAdwmft8AvNC1m3RVu4z5fBi2R3+M/s1pUZ5gmzc4qSAY8WDv2zzgKbSs2L7gEDOgjmbEwndExxawLwZ5NhQHe2NZvdUvKiYAePHuiWJijq+P2zoT2YP0UlRJixxKeKuAlyMz3WFANzQLd/FdHPA5BHA+svpuUXn5l/rMADAh2BqYDQSAgsBGumHvK4Rw3io8fCwf37A+qdEFrhDAMRY75gjdkPf9QF90u3Bj2vX7TSOJOnVVotxBonxM128FHwGhGle3kWZeE3c2C3CyBUBkqtcpbEXvzxalO8CvpYDQK6XspcO4vLWoHwfj4RLAod3VGuAuQrO0a603sNzBITDxpV7Fnc1PbGOIVz+vKTuDxhE/Zg9aIQHohBdzRz2f9RM/QpuTCSQXWo1+GL0n5Wng6MDmcmVPCr0XU0/fEoXwJQG+nGdy2mJlrK85GoP+QWwE5U07EsBDWmy+mNvtoYCl7S/lxvpnzK2b8gAAAABJRU5ErkJggg==
""")),
    "foreground": render.Stack(children = [
        render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgBAMAAABQs2O3AAAAAXNSR0IB2cksfwAAAAlwSFlzAAAWJQAAFiUBSVIk8AAAABJQTFRFAAAAd/93WrFaKYcpd/93WrFac29x5wAAAAZ0Uk5TAP////3ltS17BgAAAHdJREFUeJzt0MEJgDAMBdAfJ0hcwOIE4gSO4KiO4CS1G6QTWEvxmooI4sEP+bk8CIRwEfo2EGgVSB6tACmtJiAuK0ULiCh1QVQt0HIiDpw2AzQuF0dgN4EHxuh7C8AFYIihMQHOE9VXvwBKamBaL8C8PD3xgzvgAE6wHWHgiaYvAAAAAElFTkSuQmCC
""")),
        animation.Transformation(
            child = render.Image(src = rain_for_animation, width = 124, height = 63),
            duration = 8,
            delay = 0,
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(15, -15)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(-15, 15)],
                ),
            ],
        ),
    ]),
}

small_lightning = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAApUlEQVRoge3WwQmAMAwF0OgYbuQsnaez5OAuHusSQjyIUITW9FBr438XsSLkBxMkAgAAAAB4XWAvrWsYWxeQ8oXmVBXYy1NIs024guUCmg+fuk+dmaENbLIJqVDxuWY3dCk395qx6FZpGM2C7I42jKnQsrPE16fZvu+B+hWeqv4JBvayLSsREU2zG7TvTLMbzC/D3DOTwUv9tglmP32N3wYHAIBGDvtJkY85fOPnAAAAAElFTkSuQmCC
""")
large_lightning = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAA3klEQVRoge2XUQ6EIBBDJ3v/3z0LN9pTmOAXiUtWaRcYxtj3Y6KjtMUBNRNCCDGOT3rn1RoYXiMfFs38UY+LtmgBmC3QFCkEVy316xYlCFctbM+NEIaO4xoCOthV3dm1cr41zrEO0dINmzJS3wqB1cfeM20AZHb+DaeuCbf91bW/7vVaP4aC9hxqOFR/I/TMGrOFhjJdQFbmq1lD2oK57kptjDXTel6rLhS921ZIUyzFRN7S15Hp7ZkfUm7kLeXaNLOy33IxRLjd9raKx4YQ6VfanccaF5PRm2UKQYgTdpDCUKuAFssKAAAAAElFTkSuQmCC
""")
thunderstorm = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAADu0lEQVRoge1ZzWsTQRx9227Jri3NB42hBT0UFEmwCA0kIFIPvSa3XDx4bA4FT4UcvPgHeCp4iAcP9WZu6Z/gRSGHUmwoerD40RIjiRiTbD9sPKSznUxmdmc2sUHqg8DO7Mz83nv7m4/daPM37nZwiTE2agKjhi7b0DBCwnuWVVPuozLO34S0ATxyRCBPqGXVlAWpGibipRJLi95OKa0Bo3hKPHjJSB64GRCORFGtlJUDixCORB3vi2LRYEU5iRRx5PURTgGatBvBVDqDzWJBeN+tv5tBg4COTRtDHrLjFAhHokgmYnjzdgcAeq7dgvHGknnSFw1taTlnG+Ak0E38MPqw7b3EVIV9DnAL9q+ITyZiSu1tA7w6LQrIG8+JHNueNUOWi6wOMib3JCgKyNarBvT6RGX7PX/2qKefzJja0nKu47TQkfJFzMdBsF3KYyGeBaBmmpZ7vNEZVBhZ3entbNiGyYy3XcpjZXVdKe647rv5BOiKaDWrfb/JqbDdmLSZnAojmYjhy9cqAKDVrCKVztjlZCKGzWKBO4YXyIpfiGdtDiJUK+UePq5vg9VKuW//JgJJPXsQGvZUkRmPpD8Nsg6wGpKJmF2WfhegDzKWVRMeN8k0oAOqnvSqlbJyn+1S3r5eiGd7sobmkkpnUHiVt/n3ZUAqnXEN5vQ+wMsYVQwinoAnHgA2i4Ue/j3vAmwqu5V5IG0OPr+26+hrGqZhAACCwSACfv85qaklxxg0umme5ZogA+XXYSfQBolEs6BNAICA34/y7u6wKDlC00PQgoGA0IDZa/e49bRQUVYQA+ZmZ1Gv19G2LCERNhPYDJA5JpO6Dzsbdl1gJm5zMU2zL25gJt5dA1ZW14XkeHATT2P/4MDx/sM7J2hbFjK3fqFer+Pj3h6A3rnLOyazc9vrztOXASur6/aRUpQBMpCdAsvzR5ib7q7FG1s6TMNwzBY3mKaJdrvNrWcRmInLTwGZp023kzXg26ebWEuX8bQYxdXr7wF0tzHeVsjb2lheP76XlAzo2QZFU8FJPLtt8tqZR0cI6g0E9Qbm/U1EQ00sRlpYjLTw4P477P88xVr6PKVZ8eRAQ1JfJN4LPC2CBE4E6AxoNxoI+XwwrhwCAIKTYzDGAXNCOyvrmJsew8aWLhXXic/LFznvGaAKFfdrh4ewWj4AQL15Cus30D7unJVPAHQXREB+/RiED4FjBmi6+hdggs7JYJ/PvcY2JtrSGWAdm/J/jKhCJIA2hm1D7g1ivCou/X+D/w0YNYFR4w8KxxvyMME3xwAAAABJRU5ErkJggg==
""")),
    "foreground": render.Stack(children = [
        render.Animation(
            children = [
                render.Box(width = 1, height = 1),
                render.Box(width = 1, height = 1),
                render.Image(src = small_lightning),
                render.Box(width = 1, height = 1),
                render.Box(width = 1, height = 1),
                render.Box(width = 1, height = 1),
                render.Image(src = small_lightning),
                render.Image(src = large_lightning),
            ],
        ),
        render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhUlEQVRoge2XP07DMBSHv5Z/NqhKMpaBGSGGHoETdGNh6Cl6DE7BwAE4AQtSFzbUgYVOjVhwQIDdUlqG0qhVaZWQxhHU3xb7Rf69X957csDhcDgcDofD4XD8dQLfHxWtoTDWOvkJa23CWiefhVLRAlbFdAWoKEqcVzkfOXbJUv65VUASUVKIcWwQ4HtevH7TaqXW9dsK2Ex70CrRxiCFQCkVr/mel3mgJX1fRVEpdwP2q1WUUmhjftyfNiEIglhYhvPi5LthWIKxIVLKuVgVRfnPgG4YLt1v1AZoYzg9fEUpxUOnk7ekGay0wKKvD9B9GdKoDeI4KUTmFtBaA8laodAZAHB5fUyz3ub86oiLg3u0MZlaQEqZyjwrBsh+H7HbAyDYKyM2QG6Nczw7uQOgWW/bkjODlXvAU6+Hed8BQL0NMZ+gP0bfzwMbEhZi7SKUxITJLLB5r7fTApUKABrQg20A1PNszO2jDSXz5GbAokG27MY22csyBNPyL/4FsuAMKFpA0XwBwISYNHm0gXIAAAAASUVORK5CYII=
""")),
    ]),
}

cloudy = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAEsElEQVRogd1YX2gURxj/HUQstbEXWg+8IyxsraBXKJrqgymmDfcgJAcGrFSi0j54kQNJI21SH65NyYPmoNG8pBhfxAaEIKRwJ1QaSoMmD2p6lJqIWo4GyQln5c6mtg0V0oft7M7Ozuzs7O299Pdyu/Pnm/n95vu++fZCn5y7sYYaUVpacLRFtbjrHF3brLRGsk0HAMSalKZxsVwx7CxXgFB333klAaJanEuYh7f3JnxtUAQiAgEh4YbcTNG1v4E8yE6MgCVPz2P7yIZlm/AK2k6yTReSjzUB01dHAABb1gG//LOfO+74fh0hEgKLt3LSDYQjukmYJuv1pJNtOnIzRfPXD0IbdXTusLfRhHlkt6z7xtGW6Dhp2OvoHvCdA7bvSrr2kzhnXZfAjwihjYYtWgQ3O/kr4wCAjw5FbO3nLpcNe2wOqJblm9q+KylMYiKyQSJfAHrarXdeKPSc+NTVBhGkgW6ManFEtbhyhgbqSzxfcLad/956Xvu9aJ60G1gvSHSctHJAUOg92lrT/Os/V/D0udpd99pfI8I+UQIk8JQDwhH56fan38OzagkAMDVbdfTr2uaavCRfMOKedn/iBS83VPD+3iYsV+Suz8LmAV5uAhYycehrkoRWcemRw1NGL82azzwvImFAkl++YBB/+rwJPe38PJCbcQ+N/MQZ74UQIdLVGra1bwhHbe/PqiVsCEcxcXVRSEaEgSFrs1EtLhSCFkFE3g2jl2aR7W01KkFeCMiuNxWUlhZciyW6smTHDWdSGBgax3AmpbQm7U0AkO01hOwfnTXfybNDgCDIs4Ro0mzFSQsk8hbaMwiGMykHURVke1uR/uxruwBekp0IpH4IR3RPtYTqWN5c3vo06MNcvJVDfuIMAKDzsJUolSpBelHZxnliVstFJZFl4/2KR6OmUvj/gIY7P80HZkz1dIO2KUK6qxEAMDa14ugLaW8kfHmAyMVVsXWHty/J8rK77UiMLxRvHj3W/BZgCdGD7hembX1kLLsobxOyjcv6g7JNvMDAYwCGR4TebE+tAd5PL6gTE0GFaPb0oNTerze/BABcubnJ1n5gtyGCKYBf0Bv266Y0eDZ4RH8rl2zvr0aiJlkAOJX5FgBwemif63o1CyACTfaDg3yvyZ41Cpz+vpT5LLIhs0XbTHc1mgK0JI+Yp81D3QSQob/PKm955Am8eA2NA7sfY2xqBQ9/tKrEy9e+M9Y8NegY70sAsnl24zSpeoBdL1O9LRybKq5iXF8v7H/y4bsAmH+ERBARqxfhi5P2W4e4PZ0LeKfpBzWFQJACZM+Oe7JHe0EkpqNz7oJw7BdPXsDnr/ztaM/vOWYmW08CeC0yyDhRomJPlgdZkiMgQrz0QBwGd1dWsa3RGQaDX3Xj45F7AP6rBEXlJiEUxPUGGORU88bFyWmhKGNp/x74x+tvIRLTrVLYb81d78QHiD3nzx8mXeeJPADgCCCCV2F4XtCs+RN1fs4iLBOY9ig6HO6urAIAtjWux4vvHBTO9/wxJCqBmzUd83PTaNmTwMOloqNPBDKWDi9WRNmHjNtYug5o3mn/p4m+TVyToOj7QOYVqsWLF6h+WxABWpJHXO38C5ja/3w4KyB5AAAAAElFTkSuQmCC
""")),
    "foreground": None,
}

clear_night = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAD6klEQVRoge1YT0gUURj/7cyOD0lK+ifZWrq5kZRdFCMiKqNDREgdxJOK1V46dfNQIOQh6NDJi4WsEkEdAokIgqiQrCQPUmCpWKKtyaZZBPGYdeuwvbdvZt7Mju7srv35wTBvvu+b773ve7/vmz8+/+ayn/iHobCBPlWb1tiNTab36R87VzSH1Nf0OX7IdADgKyir9IQBdKwaZOdrL1x5AjrRzMeksg90ohmkss9i53NTAvpULbTtr7xdYRYh7rhWdt3R1q8QktYh2fkabuxWI9KtW3HUZgl08lI+ppUi6wmgY9UWGQleTn9fm3/Fc4q1znqB2BNEeNYEVyPMjVAGCwNkO2Y7QQ6onCkT2GGHv5oBbpCXJpgpMmGFGasiAcspJdrmB+mJezbX/xLI9wKcQBXdeO0h9RlWdQJIQgOQCjwT6tvhjygBqug8GWZoZVOu/ejT2y0y7zmVBdgFX1Q/Azr+2yakuvA0ZUmCJyWQiMa8cJMXeNoDspEIc+NjjVGkPgmpoONLSf34kuVgchJSLSXjWAKJaAxK6SZXejfBn5g7DgBoqGoBAIQXmqR2Ys2bGx+X21B+ufK0DEgXGNMrpZsck8XQUNWC1pFatI7U8oSYYe7+IqiiSxufyALLPQIbSEhFUf0M19kyQAzMDubdd2KMGOy7SBgA0B6WLNZh9xncNTzwhDjZ2zLAzW6K7FhJ/bNSMKC1kA9lDCjaGuXj+SclBp3IglhkCCSk4tuzYencjEU8AXYBmOV216wE7PzcL3nAx+1hgvYwQXihyWof+ZEKSGAAoz7bzfknJdhweE46FwAoHY38bG6IBjvZgkVZuhJIxxSz//7RXj4294BENAaS0HinD6jFfMzKYnj9Nsf5SEhFLDIEAJgvL0ei446UBeyJ4POr63LyJnhSTf6daahq4UloqGrB2TdHpfZ6oBjazCL0i1ugdc5CDxTjw2mC8rsUGw7PcQawxmbGrodrMBB9DABYe6DGdl15eRNkSegf7cWNPY8AwDYRIsrvUgDAt5sECCTLQJtZBH1ptR1CsnyUjkZ8P7YDWues1GfOP4bE3WfYf6FbaqsHipPni1vkzloLuY0MB0uPpHzZ+Mjr1+CVbor+0V7sPnPbIP8S/x2U8ET4/iF15sFEfnC5GU9PfsXVffMYHHnLZbIk5DQBbNcZC55fs74ItNUFAaQC7r71CQBQ1FGI7oKvBltz8F1BH2h8ADQ+YJAPjrw1JEJEzpogkGyE5iQAwL0l41/brqDPcD28sQI1n99jeGMFAKDm83uuOz8pXz6ND+DFqb0G2aF76yx2OU3ActFWFzQE3jM0yXVdQZ9t8MvBL84ArvdqEjk6AAAAAElFTkSuQmCC
""")),
    "foreground": None,
}

cloudy_night = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAADlklEQVRogc1YTUsbQRh+JlkTbGVDIEQP6qEg9NBT+xtE6B/opV8evBQhHqrgST2UQNNDLGIRD9Lqwf6Bgg20/QPtyUPBYiH1ICJWF6UkmkwPcdbZ2Zndmd0k5IElu/Pxzvu87/PO7IYkbmcoDEFSadB6TXtsp5G4c8/X1tzfDZzD/LdEB3WI0XotlBhzqrm/qx0sHsm7D3xtPKmrw2n33hpa8fkXBuY/kSlARk7HKO904+d3/2KCXTI8JrXDzw0CSaVBUmlcVqfQN7oe6KcqYSSZzdMoGdJdQIRMrkC4ZE3Aqy8MJJnNa+0BOnXfjXpn2W6eO22xR6zBEWUATJURVUmyegcAerAXapuk0oHB2Hq3hqezs8p+bQUoDQRkXVbjcaTO1rqsTrlt1tAKrg6n0Te67gvS5vJb7P/6DQBYXFv1+UQP9m4C0I59IMhpXYh7BK8CHpfVKc/uL67zoVRyyQPA6cUJylvbPrVIS4DWax0JSGLA1h6rOiFUAWH+klTaQ/704sQzrry17Xm2TI+NOBDXClpDdozq2KL1Gr5++4JMNoOzv2e+XxHKAMgMR4WKaJBNfo7uy5kOxBKwTGTZLoSpy0Qpcde2ZEdIWPR13gniBFaHcFRFivOkCmBBYa+aUaA6m9uZzc+vFjE+Ox/LhgWondWNctRs8/ZNA7Oz0CJeKRUxVyhoz6uUiphYKrrPCaNVOSQGbPfi0Tx3tC9ar4E44V+WIhj5NzMzAIDXy8vac+cKBXc+cB0AnoxuNhkB8WJlwy7RduBax07rMiAfJQjM/+a5I/8cNpV0lA8T9xPZuSkDagdvrpVSS7qMNI+X5TKAVobvP5lUvgf82NwA0ArYxFIRidCsaEBmI0wJvg02Z7vjZCUhkj+iFJ+cFzii1NNuogRar7U2wU5A9U+Tp/3YAXK2T/ay00eWdRFszPDj51pjSXYw+iZoCpcUI8vI8wipfx55QvDQXkWekFh+dUwBSrCMM/IGpBmY7HlEDUTXFOCCV4CqP0JQoqL7AWCZV8k/Z3v6dhbmPed2u9H9ElCB2wxFwnOFgrbEK41+4P3HgBG3bm6PHRArmaG+uuQGeNpkY/h2VX/QOD7zilPBFJPPHoW+B+QJQSU7eB2AHsN48p/n+YhSjwKCNsFKo99orZ4MQFxoK6DR30N7AIc4CjBFzypgdGQM1T97vnuxX9Zngu4fgxroFnmgRwPAyIn3Yr+szxT/AcOBDQKzgLaPAAAAAElFTkSuQmCC
""")),
    "foreground": None,
}

windy = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAEXElEQVRogdWYX2hbVRzHP2vDOpgI7dIMmvRhBCyFgME+ONAO0tCH1ekGA7sXMzLcw9CXsSepCrqH7WFFEGUPDksrDKuOIdRNGLawbhDGphUrxUGg0BZdWpMXYaPQ6EN2bs8595x7b9ObdH4h5Hf+/M49v+/vzzn37spe++1f/ufIZVJMzMz7zsunY448NlcCYNdOEJDLpBw5yMbrXUs2GGpG632RbT09IMQmJ2bmlQ1vRc/Ur8NksDxmGm8KAcIAL+NFGJuM1jdOpWbYRrvW/xTlNwYAOAp8//HX5DIpNozPjDU3BVyGeEAY11opKf26V3UMnj3N7PKy0+5PJLj1yRfKmjKaEgFg3qxsjHu+fR2hZ9IfpGb07PIy/YkEk8UiHU/HWqXIEfKOFEEBW477QZCpF7W7ox9ZdR5mz7j0oYkRkMukaK2UjGEY9BgTczeoedMUVZ9evO/IkZZ7TN+O8t3Um8ocOXIaHgG2vNeJ8Kr0tiIq+uVnDHe+DmwaD/Bnz+/W/e1YCuTTMSUXvWCr9kJXeDTz65R1jZkXjziynHpNSwEdtfz1LoRQI0omSSZD111ZW7KuY6o3uUwqfAK8jrqxuZISxrWz2ftY02GLmBd+ukw82m0kIR7tpvD+OzzMnnGlUWgpsJUbHtgNkT3slR6myLk6PqK05fvA5ZFxRxYFGUI8BUxVXPeonPO6bIJ8zPmlSlDk0zHnJgkhEqC/aZnCWSVpc46JCL3AiQuQ0BFzdeIni0UAutrajPvTiQwlBfxyN4j3guS/TNCh8z3c/uAPJU0Gz55W5ttSQMaO3gS3ApmgVz7rV8ay15/nwOgYRz88Abi9D/Dk25vGdZt6DG7nO4ASRe/OAm4ihpNJpS1HgC0KG0ZAvd8AZH0bSc7L0KvXah3X886YqAE6GTa0bHlnATExM2813s/7Qqce4oaTSbra2hTve6FhBAgEMVb8RFsfF6gWhoyyDGH459lVpi9VnX99frUwRE/7W89WEQwSLdXCEC0Hbzhy7+F9/HgqwoHRMa6Oj3Ci5xd6D+9j4ebfrrVM/c8UAeD/jcDm+XrRcAKu3DnO26JYbRNexg88d8qRp//5ktSTYwCsPVohuj+u/As8Xq829hi8cud4qOu1HLzBuT2LlB79BcDS0mahK62ViUU7KK2VSXHM6Y/uj3uuGVmYngx1kwJ3d38DwIXCXhbWQ3zG0MuBpwpve5EQae/0v4JWVt2XiGS6T2kX5x448pGff+ACe5X21Euv+T7Ha32AxK2vgOAECMNN4S8Q0Y0zEWLqK69svnd3xLuVDS8YNi9fS2RdeQ0dMqkA753Mu+ZsF64aYPK2DGGovDldJ5nuc8ZN5JmeUVktubxuigJT/gNO/gfF4/UqUMdVuDj3gPbOmNEwgfLKkue4bUz3uIzegWFg0TpuMl6EvhfqOgX8oqQeJNN9xjQQOLdn0ZF174M5Amx5LyNQEbQhTCK8vA9Al734+YW+FxH/ASXAHAmpFbnyAAAAAElFTkSuQmCC
""")),
    "foreground": None,
}

snowy = {
    "background": render.Image(src = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAGSklEQVRogeWYcUhVVxzHP24P5BE92AJj4KNmaasxcmmaNlsogb69BCdbrskcbTN8yyGTUYKZqMONEELZi7UVi7lWMyeUM0G01luaM8URbaXVEoWhWw0cJftjuD9e53Tuffe+e6/+Nfb9x/PO+f3O/f2+v+/vnHuNyd316Tz/Y7jsGi55wut48/t/Ti54b7u+dvaKBtsELDQgFWbBWe3tNCl1vyO1eZTWnjO1dS2kstEe6MROPNuKmMWQn1WQwtr1DabrLrOgnEDvs1BC8n3Z+NNi6fzx74cziQByLhhIJxAclPbBQDrx/kYApjqr5FgfU74vm96BccMYYv5Lh6A+yanOKkmIPy0WX2qyZh3gl5+qAUxVEFNY2SUJyMlIlAvaSmDIoGpv5qfHma4+TeB2/NU5IxUEgoMR88IvqyCFvVX9Ec/5uDGTvVX9WgIWA7uyn+2tw5NTI3/rq6pf189NdVbRdWWU0tpzGl/9PqLyAKGOYc1BeKQ2j6yCFEIdw9oWyPdl20pCwKraEK642Le1civFTRcAbSWDgXQ8bjfFTRdordzKydAAXq+Xw+03pZ8np0buo6+6Kn81hzNdfRoi1q5v0PwGiAmeHo+qADtJChi1yY0vi2VlZnvruHRnis0r4wHw5NTIyokqT3VW4XG7ORkaAKAoKwNA+hU3XSAYSGdTiZ+a8nBf+1KTTeUvINpAnQ91DC+8BYwkb6agYCCdriujMhlAJgLIagJcnb7L5pXxnAwNUJSVgSenhiO1eTLReH+jbAMxB0QcfkBEtUMdwxpSAFziIHNS6TAiD8Bo8KUmS5mrCAQHKStcTTCgtS/KytCoYHZu7tGJXzuKLzVZkgDw4N4xWpvbqGuplsqAMHGi3wVUIixbwApOiBNK8HrDd7QqaTH/3PJleNxuAGbn5qRv15VR+ZyRwXouH+/U7P1kZrggSYlr6Okzf/NTk99b1W9MgNVVFA3R7ITMReVEZdU5MFcLhJMXqClvkLau5+NpbW4DoK4lLH2ViO7cr+Q4t/t1OV60AqygJ0SQIKqs3goqBAF6f39aLHUt1YyN3wDgXv+4JABgYvK2YRwVq5IoKS9hunsl8IiExxaZnyX0aggEBwkEB2XlWyu3AuGEPW53xGmu+o8M1svqJiWuMXzeCm8C27LzCHUMa/q+pLwEgOW5dzT2pgT402Kj5eXYzsxH3P1iHA015Q3KAYeUvIrW5jZ6+s6RVZAie71iVZLhfqGOYfPPYbsHm16edvz0NioJZhgZrGdEEcfY+A2K33slws5oDmDp+s+VMdAdvh0ct0C0ihslb2Z/dfqu5f5lhavl3Ib0/Rq7pMQ1EW0wMXmb1uY2jfTNcPP808DDf4hYVU5dd/auEGnvT4uV16AR1LXJyUnNHhvS98tbQByC4vp8sWATK7wJES86AIdujcHbSeQmHqDnYi//PPWDXHPZScpp0gL66pc1bsefdlYmdunOFBBOtPWhvX6tzIv8JlCvwO87Lmv2FueBeOnRE5GbeECOH//tBZoeHAMgxv9GvaNr8OjBUt764Ihm7vbPkZ+b0ZCwLtOR7/nvvoiYi4uLc/TM69U9APRc7AVgx+n3AXCpASSsy+Ts8epIb2BmZkaOjx4sXVAQRtheYvyPCrM41Hg+++QY77y7S/51AhG7S62GUUAiEKNkVVIWSoZVokZQn1tRXsazz2yUz1fXRFwtW/axbUuO4V4uiC7DZzf6HAdoBT3pegiFmSEuLo6dOwrl72vXh9i5o5ATp9odFyJmXWqe5gyIFpy+WqpaopFolbCR77WhLjnWV1WgoryMr7/5ltdefZkTp9o1a3qfl/LeBODevd8BuPXrEGDzELSSqVkfG8GMqD37mikrXG2arBF27yrGvWQpc/f/wr1kKQCHWg4DYXJUUjamhJUcQYATBQiYEWJGhC+/yHLPwiyPpY1e3h8e+IjpuxMsX7aCa9eH5PyJU+2yJQTMCIh4FbYjZbNEzXy7TOxUmYO51O2uO/ETc6YtoL/vo/W/Eazud1VpvvwiUwWYne6A5hpUFQCPWkHsYVsBAiL5owdLDU9WozZQSYn2spOwLtPypBeBG43two5PzPz8vKECjO5TJ1CvTyMy9uxr1thHOwMW+8K1O3ODHM/8Ef4I6xibAOBfSv848k4V8KgAAAAASUVORK5CYII=
""")),
    "foreground": None,
}

illustrations = {
    "sunny": sunny,
    "sunnyish": sunnyish,
    "rainy": rainy,
    "thunderstorm": thunderstorm,
    "cloudy": cloudy,
    "clear_night": clear_night,
    "cloudy_night": cloudy_night,
    "windy": windy,
    "snowy": snowy,
}

def get_temp(f_temp, display_celsius):
    if display_celsius:
        return int(math.round((f_temp - 32) / 1.8))
    return f_temp

def get_result_forecast(temp_min, temp_max, icon_num, display_celsius):
    return {
        "temp_min": get_temp(temp_min, display_celsius),
        "temp_max": get_temp(temp_max, display_celsius),
        "icon_num": icon_num,
    }

def main(config):
    api_key = config.get("apiKey", None)
    location_key = config.get("locationKey", None)
    temp_units = config.get("tempUnits", "F")

    # clock
    timezone = config.get("timezone", "America/New_York")
    now = time.now().in_location(timezone)

    # get weather info
    display_sample = not (api_key and location_key)
    display_celsius = (temp_units == "C")

    if display_sample:
        # sample data to display if user-specified API / location key are not available, also useful for testing
        result_forecast = get_result_forecast(65, 75, 1, display_celsius)
    else:
        resp = http.get(ACCUWEATHER_FORECAST_URL.format(location_key = location_key, api_key = api_key), ttl_seconds = 3600)
        if resp.status_code != 200:
            fail("AccuWeather forecast request failed with status", resp.status_code)

        resp_json = resp.json()

        raw_forecast = resp_json["DailyForecasts"][0]

        # day/night
        rise_epoch = int(raw_forecast["Sun"]["EpochRise"])
        set_epoch = int(raw_forecast["Sun"]["EpochSet"])
        now_epoch = now.unix
        is_day = (rise_epoch <= now_epoch) and (now_epoch <= set_epoch)
        day_or_night = "Day" if is_day else "Night"

        result_forecast = get_result_forecast(
            int(raw_forecast["Temperature"]["Minimum"]["Value"]),
            int(raw_forecast["Temperature"]["Maximum"]["Value"]),
            int(raw_forecast[day_or_night]["Icon"]),
            display_celsius,
        )

    # # weather icon, see https://developer.accuweather.com/weather-icons
    icon_num = result_forecast["icon_num"]

    if icon_num == 1:
        # sunny
        weather = "sunny"
    elif icon_num >= 2 and icon_num <= 5:
        # mostly sunny
        weather = "sunnyish"
    elif (icon_num >= 6 and icon_num <= 8) or icon_num == 11:
        # cloudy
        weather = "cloudy"
    elif (icon_num >= 12 and icon_num <= 14) or icon_num == 18 or icon_num == 39 or icon_num == 40:
        # rainy
        weather = "rainy"
    elif icon_num >= 15 and icon_num <= 17 or icon_num == 41 or icon_num == 42:
        # thunderstorm
        weather = "thunderstorm"
    elif (icon_num >= 19 and icon_num <= 26) or icon_num == 29 or icon_num == 43 or icon_num == 44:
        # snow
        weather = "snowy"
    elif icon_num == 32:
        # wind
        weather = "windy"
    elif (icon_num >= 33 and icon_num <= 34):
        # clear night
        weather = "clear_night"
    elif (icon_num >= 35 and icon_num <= 38):
        # cloudy night
        weather = "cloudy_night"
    else:
        # default to sunny, but should never happen
        weather = "sunny"

    # temperatures
    temperatures = render.Column(
        children = [
            render.Text(str(result_forecast["temp_max"]), font = "tom-thumb", color = max_temp_color, height = 7, offset = -1),
            render.Text(str(result_forecast["temp_min"]), font = "tom-thumb", color = min_temp_color, height = 7, offset = -1),
        ],
        main_align = "center",
        cross_align = "end",
    )

    clock_color = clock_colors[weather]
    clock = render.Box(
        width = 45,
        height = 15,
        child = render.Row(
            children = [
                render.Box(
                    child = render.Text(
                        content = now.format("15"),
                        font = "10x20",
                        color = clock_color,
                    ),
                    width = 18,
                    height = 14,
                ),
                render.Box(
                    width = 9,
                    height = 7,
                    child = render.Animation(
                        children = [
                            render.Column(
                                children = [
                                    render.Box(width = 3, height = 2, color = clock_color),
                                    render.Box(width = 3, height = 3),
                                    render.Box(width = 3, height = 2, color = clock_color),
                                ],
                            ),
                            render.Box(width = 3, height = 7),
                        ],
                    ),
                ),
                render.Box(
                    child = render.Text(
                        content = now.format("04"),
                        font = "10x20",
                        color = clock_color,
                    ),
                    width = 19,
                    height = 14,
                ),
            ],
            cross_align = "center",
        ),
    )

    # illustration
    illustration = illustrations[weather]

    # arrange elements
    return render.Root(
        delay = 500,
        child = render.Stack(
            children = [
                illustration["background"],
                render.Box(
                    padding = 2,
                    child = render.Row(children = [
                        render.Column(children = [clock], main_align = "start", cross_align = "start", expanded = True),
                    ], main_align = "start", cross_align = "start", expanded = True),
                ),
                illustration["foreground"],
                render.Box(
                    padding = 2,
                    child = render.Row(children = [
                        render.Column(children = [temperatures], main_align = "end", cross_align = "start", expanded = True),
                    ], main_align = "start", cross_align = "end", expanded = True),
                ),
                render.Row(
                    children = [render.Text("SAMPLE" if display_sample else "", font = "6x13", color = "#FF0000", height = 22)],
                    main_align = "center",
                    expanded = True,
                ),
            ],
        ),
    )

def get_schema():
    tempUnitsOptions = [
        schema.Option(
            display = "Fahrenheit",
            value = "F",
        ),
        schema.Option(
            display = "Celsius",
            value = "C",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "AccuWeather API Key",
                desc = "API key for AccuWeather data access",
                icon = "gear",
            ),
            schema.Text(
                id = "locationKey",
                name = "AccuWeather Location Key",
                desc = "Location key for AccuWeather data access",
                icon = "locationDot",
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone for clock",
                icon = "clock",
            ),
            schema.Dropdown(
                id = "tempUnits",
                name = "Temperature units",
                desc = "The units for temperature display",
                icon = "gear",
                default = tempUnitsOptions[0].value,
                options = tempUnitsOptions,
            ),
        ],
    )
