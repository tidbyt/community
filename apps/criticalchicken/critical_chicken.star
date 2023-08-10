"""
Applet: Critical Chicken
Summary: Gaming news
Description: Shows the latest post from CriticalChicken.com.
Author: Critical Chicken
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# IMAGES

# BRANDING

# CriticalChicken.com
imgDotCom = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAICAIAAADGAG6IAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAiklEQVQ4jdVTQQ6AIAzb+P+f54Gkwc6VSbzYi7K1XRUwM4sIu2NWUM+ER34lqfy/AWU9G7OaCMMD5y3GfLh7jlItdQiyquQVQW9XDjaIivGUBl0o8V6BCCTBLKoLVXYw7EAf9IXH8hzl7dBZHE0LoH+h+1131/9lM1Qc1u0dqAj9ri1HX6uEw49xAVdO+EzxX5uRAAAAAElFTkSuQmCC
""")

# PRIORITY 8 TITLETAGS - EXCLUSIVES

# Exclusive
imgExclusive = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeUlEQVQ4jWP8f0ecYSgDJgYGBkaVlxAEYcNJrAysajD1wkm4LI0AC4TCGg+MKi//3xGHkLj045fFZTIVARPcHXD70NxE0H34A5imwc8A9wDclfBQJ94FaOrRgoDWMQBNQhAXoFmG5hS4GmRxrBqRAUEFFALGoV4KAQDqW1Wdm7a45AAAAABJRU5ErkJggg==
""")

# PRIORITY 7 TITLETAGS - OTHER YELLOW TITLETAGS

# Breaking news
imgBreaking = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAhUlEQVQ4jdVUwQ0AIQgrt4QLsP9ELuAU+iAxDRKM3ss+CIgUsUbpteBlfABEm2izePU5ZMfZmc1D5mS7Vh0MAKDXMoudbxKJNl5fMbO20wkbcjLCqoMBrD70uYfrl/Amo4ap/HYS7BXgHv/7OR4mueMMFGBcvEs7R6IPc7LUW1Vjttd/oQGjH3RBa8DhfAAAAABJRU5ErkJggg==
""")

# News alert
imgNewsAlert = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAgElEQVQ4jdWUyw0AIQhEB5uwAfqvyAaswj2QEMLHE3vQg5EXgiNDpLMmXl4DAPEm3hLLWUK7uzQl7hArpJWbHwDgrKmlz5rRFuLtuJBUkM3UHCHtho+IKk2RV+10hvw6pckDXJstd4orZZZXLnWt3AE7ThZeehnHvVtqce/rv9AHW55VCeyZ+JUAAAAASUVORK5CYII=
""")

# Live (animated GIF)
imgLive = base64.decode("""
R0lGODlhQAAHAIAAAAAAAP/cFyH/C05FVFNDQVBFMi4wAwEAAAAh/wtYTVAgRGF0YVhNUDw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDkuMS1jMDAxIDc5LmE4ZDQ3NTM0OSwgMjAyMy8wMy8yMy0xMzowNTo0NSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI1LjAgKDIwMjMwODAxLm0uMjI2NSAzYTAwNjIzKSAgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkUxNkM3RUY1MzZDRTExRUU5QzQyRDk2RDA4NkQ5MTVDIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkUxNkM3RUY2MzZDRTExRUU5QzQyRDk2RDA4NkQ5MTVDIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RTE2QzdFRjMzNkNFMTFFRTlDNDJEOTZEMDg2RDkxNUMiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RTE2QzdFRjQzNkNFMTFFRTlDNDJEOTZEMDg2RDkxNUMiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4B//79/Pv6+fj39vX08/Lx8O/u7ezr6uno5+bl5OPi4eDf3t3c29rZ2NfW1dTT0tHQz87NzMvKycjHxsXEw8LBwL++vby7urm4t7a1tLOysbCvrq2sq6qpqKempaSjoqGgn56dnJuamZiXlpWUk5KRkI+OjYyLiomIh4aFhIOCgYB/fn18e3p5eHd2dXRzcnFwb25tbGtqaWhnZmVkY2JhYF9eXVxbWllYV1ZVVFNSUVBPTk1MS0pJSEdGRURDQkFAPz49PDs6OTg3NjU0MzIxMC8uLSwrKikoJyYlJCMiISAfHh0cGxoZGBcWFRQTEhEQDw4NDAsKCQgHBgUEAwIBAAAh+QQE9AEAACwAAAAAQAAHAAACJoyPqcvtDk6cAdiHs66S0w2GSGRQEymmCTp23KvG0EXWl4zneloAACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALDYAAgAHAAMAAAIGDIJ3ltwFACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALDQAAQALAAUAAAIMDIJpywx3nIlRVnUKACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALDYAAgAHAAMAAAIFjI+AGwUAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAIfkEBPQBAAAsAAAAAAEAAQAAAgJMAQAh+QQE9AEAACwAAAAAAQABAAACAkwBACH5BAT0AQAALAAAAAABAAEAAAICTAEAOw==
""")

# PRIORITY 6 TITLETAGS - MAJOR EVENTS (EXPOS, ETC.)

# E3's future
imgFuture = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAl0lEQVQ4jdWTwQ2AIAxFf41LuIIHN/DMzJ7dwAMruARJPZB8KyiiJ32Hpnzgk0IRVQUAQERiLiIAVJUJRQ653saCbq2s2yPWcYhJNy/BOwBtP+2mJCo25rP5yjy5iq9hASR41yQH8+IZyzXUQM8XexNYQ/AueFd6gSvlay/QwnR50u7IPkACG71SvzWsrOHwB/7OSYv/iw0My7H5bYtrZwAAAABJRU5ErkJggg==
""")

# Summer Game Fest
imgFest = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAlElEQVQ4jdVUwQ2AIAwE4jKygyzDWrIMQzCPj5p64Qoh8cU99NJej9Ya/HXebmcEedWWa8tCVp6oF4LAYEfYAUvM7CguOCSRYjHn685QjvoUCzow18jIwfRkt+4gQdCEOYBpyoNxN7yBiYPpiU2bvX0DrOg68AZWlPP46GPN/d9fSGvMNTGwhPv46YDZucw553e/hR6qoZ+YW8wptAAAAABJRU5ErkJggg==
""")

# PRIORITY 5 TITLETAGS - MINOR EVENTS (NINTENDO DIRECT, ETC.)

# Nintendo Direct
imgDirect = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAkklEQVQ4jdVUQQ6AIAwr6ivkAfL/1/gBfyGJB5LZ0EmAmzstzVbabSHc+4E/xwZgvU4AOaaS55gqpJQazjnXlNxI7I1+fu6tcEYYXFScK9EackycqyWWqGwuYpxqjwehQ3kN9EelYzp4S+rtq0s9DBtosI/y6JGwMjf0imY24D5gEy3KVFPDuXG6vQ31AMLff6EHc2GFic6yYRUAAAAASUVORK5CYII=
""")

# Pokémon Presents
imgPresents = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeklEQVQ4jdVSQQ7AIAiTZf//MjvoCGsB2dEeTIO1FHWoqqqOF8YnsTWsA/E+fAo4b/l6R/9JXK8cq6PvazIeXhPkuWZVRAbB6jB0KA7hnYGbVTZDCNCvAbJAXt0PDQ5bt79dYIab97LX4AaFvoa5gW3YZRvjbOCXOg4PfETmbvEnwXAAAAAASUVORK5CYII=
""")

# State of Play
imgPlay = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAo0lEQVQ4jWNgYGD4////////4QwIG8KFM3CpwaMSWQRNGaYuTFliAZGG4nIEmkriZTHFyfMAEyMjIy6dpIrjkv3//z8jIyMelRA3IKvRujMVzv6qYwhhZHedgJO3+w5DELpZNIoBXGysxkJcDyEhrkfzA8QDEJIJkkaxhhAugJbKMcOPeL24ADwGuK+c/6pjyH3lPMT1U8ss0Pww5AHODDBUAACy1e5eFlKsHAAAAABJRU5ErkJggg==
""")

# PRIORITY 4 TITLETAGS - INDIVIDUAL GAMES, TOPICS

# Ace Attorney
imgAttorney = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAb0lEQVQ4jd2RSw7AIAhEB+5/5+mikRA+Rty1b2EIwjAKAJDEwmIu4ChvQ2Wo6WLrDQbGZKFONOS7Zx+epeYFmvtFJFvsMntImlqpIyJdzSEK5zirh+rppNdfmR/pbNA8z29g+uWHP3qh/FvqFX+IB49wpIoUTsX3AAAAAElFTkSuQmCC
""")

# #ForTheGaymers
imgGaymers = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAgElEQVQ4jdVSywrAIAxL9///3B2EUPsIjp3MoWhJ0wQFAHdnXYcFXmO/clKttKoz1ahJfr1u8B1xk1imDSXCuWnBn/CYGYBYxYy7k5P67bkNbGZRJwomHboSGZ42a+tSaEW+mJ1MTDopcx+gfYGkcrKb4Jf4M1ubn3RugvpeV+AFe2XyYPlLGH4AAAAASUVORK5CYII=
""")

# PRIORITY 3 TITLETAGS - UPDATED NEWS ARTICLES

# Updated
imgUpdated = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAaUlEQVQ4jdVUQQrAIAyr7Xv8/z/mewoeiqG4yNilYA4llCpJirZHVW6Gikh3zzXIxjGAfp5/ny0DiX+YQQd4dwcfZqhBMi/2QAyEVtqnV9SnnsE3QEf/9mugsvZ+Sv1T3/Zsiv2023+hCSUNS43exBvSAAAAAElFTkSuQmCC
""")

# PRIORITY 2 TITLETAGS - SUBCATEGORIES

# Link
imgLink = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAT0lEQVQ4jWO8xMTEMJQBEwMDg+7fv3A+hK379y9cEC4yEM4jDHAG/2Vm5kHraGRAVPrR/fv3MjMzrZ1CHiDKA4M5NqAeQE70QwswDvVSCACWyhvxvQC7jQAAAABJRU5ErkJggg==
""")

# Live updates
imgLiveUpdates = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAgElEQVQ4jdVUQQ7AIAhD2Xf8/z/me0h2IGlMp2jmLjZGUaBSNaY7ZzkZWUSKGeZuU+9tFANXN4wYiI1SPgqYoqpW1cCLImAXM9ieCwaweUzA/JuA+JC8jvWst9od9AU4dXtmAcXIu7K+r+Hyob3rN8hL8ihy+iTAFm+6iHT6L/QAAhhutuMPegwAAAAASUVORK5CYII=
""")

# Rumour
imgRumour = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAXklEQVQ4jWO8xMTEMJQBEwMDg+7fv7p//0L4EAYmicmAk3DxAQHQ4L/MzIzVHciOxqUGlzh9ANQDEPdhSmMVRAO49NIHEIgBYsCgiAE4gLgGM0SRxXGpGRDAONRLIQDRcT8YI2tvaQAAAABJRU5ErkJggg==
""")

# Site update
imgSite = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAfklEQVQ4jdVUQQ7AIAhD2Xf8/z/me0h2YGsMU4jGiz11wGpLjOnOmU7G676IFBEl+PxzDJtJI9KOhWobAhSRylyZUVWOiukaVGYYAldN5VNqKwFaB12E3a6h0V8b10+4Qn4Gf2Gj7mx9DRd9K3F0zYCmHW099BceN4V0+iv0AF9HaY+06XuTAAAAAElFTkSuQmCC
""")

# Update
imgUpdate = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAZklEQVQ4jWO8xMTEMJQBEwMDg+7fv8gkhIHGhiuAiyOrR1ZGZ4Al+C8zM8MdBGfr/v0LZ19mZoaTEAacTX+AxQMQt2IVx2rEAAY/A64YwKqUVHH6ACYGWDrBFeoE3TeweYBxqJdCABHkQT+CLnxQAAAAAElFTkSuQmCC
""")

# Video
imgVideo = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAX0lEQVQ4jWO8xMTEMJQBEwMDg+7fv5gkhAFnI3MHxqU4AM7gv8zMDHfrZWbmy8zMDAwMun//IosPBkBU+hlULkYDTAywwIaEMVaAR2rAAc4YQPYSPA8Q9Cr9AeNQL4UA6pcw8e6EjGcAAAAASUVORK5CYII=
""")

# Guest blog
imgGuest = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAfklEQVQ4jWMUTbnDMJQBE4R6NVv51WxlCAOZhIujqUEWR5aC60WWwqqMWoAFYq5Y6l2s0nBxZDViqXcxtWAVhIggk9R1PQM8BhgwQg5NEOICPAYR6T6qxwATfmlkN+H3A0Ef0ggwQjIxcvjB2ZjBjzVFwVVi6sJlMvU9MHQBANRzaDVZv5IOAAAAAElFTkSuQmCC
""")

# Guide
imgGuide = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAWUlEQVQ4jWMUTbnDMJQBE4R6NVv51WxlCAOThDDgbDh3MAAWBgaGV7OVxVLv4lEklnoXrga/SvoDJjiLyHAdVMHPgOwBIsFgjAG0FIKZopBFBlseYBzqpRAARIwvoYLHC90AAAAASUVORK5CYII=
""")

# Interview
imgInterview = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAa0lEQVQ4jWMUTbnDMJQBEwMDw6vZyhASwoCzkcWxqsEkkVXCSZp7AA7EUu9CrBRLvQsnIQxkNh5nIaukD2AirAQ1IF/NVsbjRDoEORogygPILkaOJUzPIHPp4xliY4BI1yCrpE9aYhzqpRAAbcdKNyBePcUAAAAASUVORK5CYII=
""")

# Opinion
imgOpinion = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAUElEQVQ4jWMUTbnDMJQBE4R6NVsZzkBmYxXBpX5AABPEEWKpd+HuQGZjFSGonp6ACVMI4j76O4U8gMUDQ8j1DBAPQNIA8e4mVT1NAeNQL4UAwGIyn4uKz8AAAAAASUVORK5CYII=
""")

# First impressions
imgFirst = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAlElEQVQ4jdWUsQqAMAxEU3Fztb9qv8FvdbW7Q+Aac6FVnAxSjubykqCYzm2VP8ckIst+6KMaNzDZLKf4hIF1JwWCE+EktwVEpJZcS7aJWjKgyNrTheWilrXWWqbVQIUEdrYF3Fpwuwk6wROEur/hsAU72xvouJ/3YJrjfOSzcx7WaEH42bwNoCyT+WrgjuEk6e9/oQtj2aH3JX/ovQAAAABJRU5ErkJggg==
""")

# Hands on
imgHands = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAZElEQVQ4jWP8UibCMJQBEwMDA3fnaziJxsDKxuTi0kUHwITG5+58/bVcFO4CrGyImq/losToojVggrsA2TX49dDTfQQB1APIwYnMxgUGjx9YiFcKSScMsChC8zNcls6AcaiXQgDLbEH/hv0EJAAAAABJRU5ErkJggg==
""")

# Preview
imgPreview = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAaUlEQVQ4jWP8UibCMJQBEwMDA3fna+7O1xA+JhvCxUpilR0ADzAwMHwtF4Vbj8b+Wi6KSzN+WfoAqAe4O1/DnYLGxqN5QIIcDSBiAC6EFgPIgmjhjcwdKM8w4ZdGzhL4ZQcqLTEO9VIIAECZQ3zUBQYwAAAAAElFTkSuQmCC
""")

# Second look
imgSecond = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAf0lEQVQ4jdVUsQ3AIAwD1I21vFpu4FbWsncwtVCCkFpY8IJjhTgBhL2v0+wMh8Wn7FMmAUfI1Fbscr1lUEFn/h/Ap1xiKDFAIodOM3LkdLnAoMIqON2B8OBga4F55uvUJyROVDjN22isuo3DvC2yb4bwgN5yAa1/rTADu/sv9ACud2p++XPSeAAAAABJRU5ErkJggg==
""")

# PRIORITY 1 TITLETAGS - PARENT CATEGORIES

# News
imgNews = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAYElEQVQ4jWO8xMTEMJQBEwMDg+7fv7p//0L4EDaEi0yiKRs8gAVCXWZm1v379zIzM4SNqQ4uO9gAlvSDNZghPqS9e0gGWDyAHNLIjh6cfsAeA3CHwj0DERyEqYhxqJdCAPtWMkGheN8eAAAAAElFTkSuQmCC
""")

# Feature
imgFeature = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAbUlEQVQ4jWMUTbnDMJQBCwMDw6vZyhCOWOpdZDZECs5AVoNMIitG1ksfwAS3Em4rnI3pRKwuQ/M2PV3PAPcA3AV42LgAPJaIVE9dgIgBuBAuNi6AmfDoCZgwhV7NVsYfkPAMQIZeqgPGoV4KAQC/IEoZwsoIUAAAAABJRU5ErkJggg==
""")

# Review
imgReview = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAZUlEQVQ4jWP8UibCMJQBEwMDA3fna+7O1xA+hA3hYiWxyg4gYIFQX8tFuTtffy0XhbDxaMAvS3/ABKHgrmcgFKgDHuRoAOoBSAzA2ciCaEGOzB0MnmHCFELOEvhlB0NyYhzqpRAAjPg3fsFfT3QAAAAASUVORK5CYII=
""")

# FALLBACK - IF NO RELEVANT CATEGORY IS FOUND

# Our latest post
imgLatest = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeElEQVQ4jd1Syw6AMAgrxv//ZTwQCQHWoSdjDwuPUmgyAFBVAB746/XYraneSHEUSfWq37bqVIN0dPu2O6pzwl+lfGNNKw7uTURIl9dFhK9v9bdTCcwA11p5i/XXCnMPp7FNK8YtTJcQImdCjhcbcz71Ezz7cB/EBe+wuYw/ht85AAAAAElFTkSuQmCC
""")

# ERROR MESSAGE

# Sorry...
imgSorry = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAIAAAA3VtxdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAZklEQVQ4jdVUOQ7AIAwLeTHmIeTLHVxZEaIdOkDxgmNZwglHQa12MpxLj+gR4lNxMKjcBQZwsgY0QFzhnvhGaHwM7PaaTL7M6Ze+GMO+LnXaw29PQLiv0Ofp5vewpr2c08zK6b/QBeMeUr9B6cGnAAAAAElFTkSuQmCC
""")

# MAIN

def main():
    get_feeds = http.get("https://www.criticalchicken.com/wp-json/wp/v2/posts?_fields=title,categories&per_page=1", ttl_seconds = 900)
    if get_feeds.status_code != 200:
        return connectionError()
    get_headline = get_feeds.json()[0]["title"]["rendered"]
    get_category = get_feeds.json()[0]["categories"]
    finalheadline = str(get_headline)
    finalcategory = str(get_category)

    # DECIDE WHICH TITLETAG TO SHOW
    colour = "#ffffff"
    thetag = imgLatest
    if "[2.0" in finalcategory or " 2.0" in finalcategory:
        colour = "#d20202"
        thetag = imgNews
        if "[31.0" in finalcategory or " 31.0" in finalcategory:
            thetag = imgVideo
        if "[29.0" in finalcategory or " 29.0" in finalcategory:
            thetag = imgUpdate
        if "[27.0" in finalcategory or " 27.0" in finalcategory:
            thetag = imgSite
        if "[25.0" in finalcategory or " 25.0" in finalcategory:
            thetag = imgRumour
        if "[18.0" in finalcategory or " 18.0" in finalcategory:
            thetag = imgLiveUpdates
        if "[16.0" in finalcategory or " 16.0" in finalcategory:
            thetag = imgLink
    if "[10.0" in finalcategory or " 10.0" in finalcategory:
        colour = "#1564dc"
        thetag = imgFeature
        if "[21.0" in finalcategory or " 21.0" in finalcategory:
            thetag = imgOpinion
        if "[15.0" in finalcategory or " 15.0" in finalcategory:
            thetag = imgInterview
        if "[12.0" in finalcategory or " 12.0" in finalcategory:
            thetag = imgGuide
        if "[11.0" in finalcategory or " 11.0" in finalcategory:
            thetag = imgGuest
    if "[13.0" in finalcategory or " 13.0" in finalcategory:
        colour = "#f47614"
        thetag = imgReview
        if "[26.0" in finalcategory or " 26.0" in finalcategory:
            thetag = imgSecond
        if "[23.0" in finalcategory or " 23.0" in finalcategory:
            thetag = imgPreview
        if "[14.0" in finalcategory or " 14.0" in finalcategory:
            thetag = imgHands
        if "[24.0" in finalcategory or " 24.0" in finalcategory:
            thetag = imgFirst
    if "[30.0" in finalcategory or " 30.0" in finalcategory:
        colour = "#d20202"
        thetag = imgUpdated
    if "[34.0" in finalcategory or " 34.0" in finalcategory:
        thetag = imgGaymers
    if "[4.0" in finalcategory or " 4.0" in finalcategory:
        thetag = imgAttorney
    if "[28.0" in finalcategory or " 28.0" in finalcategory:
        thetag = imgPlay
    if "[22.0" in finalcategory or " 22.0" in finalcategory:
        thetag = imgPresents
    if "[20.0" in finalcategory or " 20.0" in finalcategory:
        colour = "#fc1a27"
        thetag = imgDirect
    if "[33.0" in finalcategory or " 33.0" in finalcategory:
        thetag = imgFest
    if "[8.0" in finalcategory or " 8.0" in finalcategory:
        thetag = imgFuture
    if "[17.0" in finalcategory or " 17.0" in finalcategory:
        colour = "#ffdc17"
        thetag = imgLive
    if "[19.0" in finalcategory or " 19.0" in finalcategory:
        colour = "#ffdc17"
        thetag = imgNewsAlert
    if "[5.0" in finalcategory or " 5.0" in finalcategory:
        colour = "#ffdc17"
        thetag = imgBreaking
    if "[9.0" in finalcategory or " 9.0" in finalcategory:
        colour = "#ffdc17"
        thetag = imgExclusive

    return render.Root(
        child = render.Box(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.Image(width = 64, height = 8, src = imgDotCom),
                        height = 9,
                    ),
                    render.Box(
                        child = render.Image(width = 64, height = 7, src = thetag),
                        height = 7,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Column(
                                children = [
                                    render.WrappedText(
                                        content = finalheadline,
                                        font = "tb-8",
                                        align = "left",
                                        width = 64,
                                        color = colour,
                                        linespacing = 1,
                                    ),
                                ],
                            ),
                            height = 16,
                            offset_start = 16,
                            offset_end = 16,
                            scroll_direction = "vertical",
                        ),
                    ),
                ],
            ),
        ),
        delay = 50,
    )

# ERROR MESSAGE

def connectionError():
    return render.Root(
        child = render.Box(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.Image(width = 64, height = 8, src = imgDotCom),
                        height = 9,
                    ),
                    render.Box(
                        child = render.Image(width = 64, height = 7, src = imgSorry),
                        height = 7,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Column(
                                children = [
                                    render.WrappedText(
                                        content = "We couldn't get the latest post. Visit www.critical chicken.com for updates.",
                                        font = "tb-8",
                                        align = "left",
                                        width = 64,
                                        color = "#717070",
                                        linespacing = 1,
                                    ),
                                ],
                            ),
                            height = 16,
                            offset_start = 16,
                            offset_end = 16,
                            scroll_direction = "vertical",
                        ),
                    ),
                ],
            ),
        ),
        delay = 50,
    )

# SCHEMA

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
