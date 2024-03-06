"""
Applet: Virtual Pets
Summary: Virtual pets
Description: Choose and name your own pet while watching the environment change with the seasons and time of day!
Author: frame-shift
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default values
DEFAULT_PET = "cat"
DEFAULT_NAME = "Fluffy"
DEFAULT_SHOW = True
DEFAULT_LOCATION = """
    {
	"lat": "40.69754",
	"lng": "-74.3093231",
	"description": "New York, NY, USA",
	"locality": "New York City",
	"timezone": "America/New_York"
    }
    """

# Backgrounds
INSIDE = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAAsTAAALEwEAmpwYAAADaElEQVRoge2XX0hTcRTHP4VJzWrT/Dt1UYoViBRmNUjKEaMG9aBB2ENY1Ev1YK89m/RWRL5W9NAI0gcDCykVDNRMjCEka5O66tJa+1OtwiB7uN3b5r3OtnvLxfq+3MO555zf75zf+fP7rXh89tS8azJCv2+Gc7vLAGgb8lJrLiQe1OSrSrNoG/IyV2OPq6sVmcPdZBvW6WIrQxcry4BKU5YudhYNQL9vJq5irbkQ12SEqlJ9NpIoxkIRXeyoBkBK7cXgmozQfLIIgKs33+iykUQwV2Mn+LMMyszqB+D1RRT/1HhJlUC/b4ZmimR6uVC3v0LBE9zTWCqKAekrwjY4wC2zhaaAQM8eq8xXDUDbkHfJxRsujQJitvyO/N/AL+dhy3gAa0CI+b9lPAD5YjAkLJoBiUyBP4Fg3lOy3+2KK9Pb545Jacl52+AA1wL5DAcMCp2FvJScAsG8pwDcb/0OwOGLK1XlpBLo7XNTt79CPtlr4/nU5HxWyFvzPwEw8HatzPsjAcgc7tZmwGHiyYWdhAd6ALjfamPvlWdsrQoBELysVOntc7Pmw1qGA4ZFnS86MCfSjz7JQUh6DMaDltK4U+flzLZcBV9y/nhvGeyO7VNl5iyaAgKsVqa4dOqS8xJtfSTykxqDS8E1mdyMHjshBv3eCw8AB602AB76XjHuMlHQFcJljsiHE90DevZYY5obQOi0DTo7AbhhOErDZjEz2yfsHELkp1QPqLxdSL9vhlmHiRaXH46J/HsvPDSPhXFijJGXeoDgno7hh07bZPrBkSMy3T5hV/Azok9L6ziTbGm9G1z/6uH86nJa7vrl1C8v/waCum2vL4Il6krwofs5AOvt25ekV9RX75uXFOsd1UltuKNrRKaTtRFtq9ESFh2OgsezCqdgpN5RTUfXCNmGdQQ/f9S0FkCG1g2DdqcXwikYQYgvU2nKAh0eRBkL62e5YSwwEp4N02gJx/CdghFjgVGud90eQ9H35VTA+yk/OQUmnK7XMfxNVRsBsJTkYqkopqNrhJ3l8W+rv4OUmgIAO0pyGZ3yyw4v/BeNZx7tD7GUCwAoHVVDvaOa0Sm/5rVSrgckgg3Ay49fNNlIuR6QKCwa9dWfWWmEtA/AP90D9MA/3wO0Iu1LIO0D8L8H/O8BaY60D0Da94Af/z5EEFOhcoYAAAAASUVORK5CYII="
WINTER = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAAsTAAALEwEAmpwYAAAD5UlEQVRoge1YPUhbURT+0ggVBNsK/rTgFKg/hVDI4NBUi4qUjhbbYLdISUtcujg7ZymUvEHE0A6KrbRjKWnikMQhQ8BaMJXiUISQKoS2VIhDSIfkXM+97ybmVcpT6wfiu/ee8+79vnt+njrKiVfl+88iuH2tCwCQzOW1z4Ra68lcHm+f+wEA9D53d4vwM9LbuPPytRhHjQUAgNPrwchos5iPx4oAYJorpTIme2471dkr7Be+fwEAMaeOaS4eK+ICTfDDWoUV36ixgKixAKfXIw5PiMeKGBltxshosyDHbZxeD0qpDOKxokSe2xIxTnaqsxfxWFEIwfdqqk+oS0PucC6Za5i3BCIPANHZNa0YnBjdPvmWUhmMzd6SbCcX103jpUc3AQCTi+vifXGsS3tpBagFI70NoEI8OOCy4iowFpzC8vQM2vp6JEIAEE1BEIvOrgkfsuFCEHSRQs8Pn1bSjN7JU4f8GhbASG9j/N7hzRnvzYdpFL5wCMvTM2h/PAngkKDT6xHE+ZxuzAUCIEUEUCFJcxTuhJHRZuF/ARbx7hjEOXzhEPbml0w36/R6pBSh9b35Jcmf26jko7NrNQmrPpYF4FFwXPjCIRSyW+KHC1FKZaQ1XziEseCUsOFdgZPjKaGCr1HtaTgFggMuKeyDAy5RE/4Wm4lVuB/cBQDsRuaQzwJt1bVCdgtdv7+hwx8Qtv2DwwBk8vRbrRkqKIWiKdnGUhEMDriwsbN/rJZJ2EysAqgQ5+9eyW4BACZaD+C+4YJRXe/wB7CZWBVFFKiIxcnSMxFVCypfJ9QVIJnLw93tOnKOY/HjJ2msE4zIE3hHmWg9MK3xSNtMrMIXDgFApZtU59Vb1xVUvkbjJvXAAKQNdWFeK/R15HXoHxwWInT4A+KW+dfjxs6+2IfSgHwJ1E3a+npEh1A7h0qaky9kt+AY9wyVaXOgcsPtVy4BAL7++KklQLhclv04dJ/Q/FOYwKNhNzInosFIb9ckrkKkRPXbgghz8AgoVNPMFw7B8cRYKlMe6sAPoUL1K3mHcPV6r3atwx8wkVBTgfvp9j3Kf+PNB2lMghBhAhVeABUBpNVyGXA46m5c7xA6f8vvaMC3ls9uZE5E38qviwAO60oylzcJ63jxOS8LYCNUUrVEqxc51E10cHe3mOqKpTb4r1EvSlQ7nQjq3ye8oHIbXsRPVARYhSoCrztqR+FFmqfBiYoAK9BFACeWjMyJ7xVd7hNOdQQA9QtovY5COPUCEI7qJCqo3pzaFFBBhKy21DMjAKHRTkKw/P+As4ZzAew+gN04F8DuA9iNcwHsPoDdOBfA7gPYjf9egD/pbypokf5iEQAAAABJRU5ErkJggg=="
SPRING = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAAsTAAALEwEAmpwYAAAFX0lEQVRoge2YX2hTVxzHP5UwBcOS2dtaBGm1mtVtBIuF4nCb2A5kgqAW+6It86W4ToovOqdv6zbqi2xapAiF6vYQqSsMHIXaIrZQC+3cgm71dol1QuZsMhKIYEe27OF6Ts65uSnJdGbd/MKl95zz+917vt/z+3ObkvS1vvSew728saoCgNHIfcd7gVzro5H7XDp1AADxPP/q5dKveyJE3bkqOQ50JQFw+1LU+ONyfjroBciaS5quLHvVtmnDOmnf/+NPAHLOPhZz00EvS8SEutlCUYhvoCtJoCuJ25eSmxeYDnqp8cep8cclOdXG7UuRNF1M9hsaedVWEFPJNm1Yx3TQK4VQ3+VamFCFA7nM3Ggkb94aBHmAyX7DUQyVmDh94Zs0XVm2nQEx8srxiWYDgM5AVD6vMxjV3uUoQC50T4QAi3h7fXUhrhLNR92cb7vL0rWlGiGASdOgrsna4GS/IX2ETdJ0MR+OSV/AMVLE/QcfWc+ta4pr69NBr/TLW4DuiRC739mUGX8zla9rFlp6KjnfdpfS7R4gQ9DtS0ni6pwYxwYTj31SmkCAFE5gOuiVcyLcBWr8cem/hALx1RMQV9HSU0lsMCFPVsDtS2kpItZjgwnt5FUbO/nJfiMnYbtPwQKoUfCkaOmpZD4ck5cqhAh3cbX0VNJ81C1t1K6gklNTwg51TdSevFOgvb5aC/v2+mpZE/4uZsaSbN5vnWqiL8oP4RhgjefDMV75M42n1ZC267e4AZ28+GuvGXbIDmIamk1BRbC9vprgvYdP1DIFZsas74BEX1R7dk/4VwDaKlbiX72c7j5LZE+rwcxYUhZRC6UaWXEviNoLqrousGAKjEbu5zWn4suh77Vx8N7DLBtBXkDtKG0VK2mrWOm4Jnxbeipl+ogaYT91ERVqm1XXhJ/LvmFAC22nMM8V+vmQB6jdewiAGxdP42k15CmrX4/Bew/le0QaADININNNlq4tlSLYO4edtNp258MxSnZveistXg7WCZe9ZLWnmXjCkYCAN637qXD6hP7j8DEaGpcxfOURgLxf8ds5wEoHceLdEyFJvPeq9VX36Qnn6BMpkatLgB728+EYYAlY8u7ne9IiD52gqm+H3W/+dTfl65c5rnlaDcy5FMbLB2lotGyGrzwievssvrLM5oSfp9WQxO0QQthTafxCTBsLQQRhAVF44XERVEmm01BSor9QDTsNW9xZmxD+duHWb3FjDsSJ3j7LMAcBiN4+K9d7920kMT6CZ6iRA198B8BUyMWmav0kp0KWWPb3CmKJvqiMPrWgghWF9n2VfPJta9qZ3T+DywNxbbxjlxeAY1WZ0xYCmHMpPvv6Nc2+Y+dNGTFnDnXz/ul2zhzqZn9dM5DpJk7wr16eVVcKaoNPA4KwissDcWqbZ+XYnEuxY5cXcyBOx86bUoSOnTcBK5o6arswjzRwams55pEGLkwOc739Q+25akEVsH+/PPMIyAU1MlSRckUMwHu//Mydqw9Ys7Wcw6EVWt2xdxS1SF8aarTSbfO2f48A+aL2BSto33z1Y8wjDazZWs6dqw/wnRzm2q3jAFwciZPoi3JpqBGAPW9f0XK/d99GeV/w/wLFxo3fU3QGoly7dRzfyWF2XH9Rku8MRLk4Egcyp5wYH5FCgJVeg5FZeS26CIBMWogfPMD60QPAV+Zi7zYv21dVkRgfAcCzeRuDkVkpjjmX6SyLUgDIrg1g1YeZsSTmXIoTzQbbV1UBMBiZpTMQxVfmymrpi1aAhWCPEBEdTh3oPykALNw9VDzz74BnhVyE7Vh0XeBp47kAxd5AsfFcgGJvoNh4LkCxN1Bs/O8F+AsPUtYCTHfEkAAAAABJRU5ErkJggg=="
SUMMER = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAAsTAAALEwEAmpwYAAAEL0lEQVRoge2YQWhjRRjHf6kh7ZLoZjeRBDEK21q6C76LxR6ieF2CJy1410MPPXkJe1AQ7Gkve+phL4IHD4vRk4SCN8seClHwHWzIbiNssdtAHpu6CTUx7fPw+k1mXl6yyRZJq/3DkDcz3/dm/v/55vuShNyfvnY//PQr3n0lDcDm3n7gs2DQ/ObePt/d+RgAeZ+ViSq/9a0drtzqvadUSAIQm++yYDXUeNmOA/SNNSvhPnvddvn6nLIvbD8EUGP+voyV7ThTMqBvdlyM41sqJCkVksTmu2rzgrIdZ8FqsGA1FDndJjbfpVkJUyokDfK6rRDTyS5fn6Nsx5UQ+lrh4YTSAeR6Y5t7I/M2IOSBgWLoxOT0xbdZCffZrt2TXlz1P/vIi7K1e3X1vjW7bqwVKMAgrG/tAB7x1aXZcVwVFpfr3L8dYvpawiAEUKokWVz2NihXRLdpVsK0q47yBQIjRZ5vfRk+WbNhzJftuPIbWYD1rR0+yL3V6xd/HtW1D9m8y/3bDombl4Eewdh818gNMiZ9Z+PgxKdrCAQo4QRlO67GJNwFC1ZD+U8xJr4/BXEd2byLs3GgTlYQm+8aV0TmnY0D4+R1Gz/5UiE5kLDfZ2wB9Cg4LbJ5l3bVUU0XQsJdWjbvsrhcVzZ6VdDJ6VfCD31Ocs/IV2B1adYI+9WlWZUTnhc1G+ZuugBEivBb1QG8U25XHW4cu3RyPduU5T3r5OXTnzP8UBWkkjRsxkqCq0uz2LutU5VMQc32PiNF8913qzUAVtIprEyU9aIncifn+UgS9ZAwyMqzEPUnVH1eMPQKbO7tjzSm45sffzX69m6rz0bIC/SKspJOsZJOBc6JbzbvqusjOcJ/6hIVepnV58Qv7N8wYIR2UJgPCv1RyIMXyiJCJ4c6Zf3bo73bUuvINRBfgVST6WsJJYK/cvhJ62W3XXV4gVbkC4AZdxqAR0+bvHzlMtFLM+y12/wVYmCbAV5/MUbtz7959LTJ9oPHbD94DCfjApm/9E5v87GU11o1OHrDa3/80uTtV68CUCjv0sl540I81gsMhdey8PsPhxw9OeT42Fuz40wRSRwbdkK640zRrjocPTkkm3cJvf/5e67cwyDo6vvh96u/GeKljBs418mZpwf9V0H3C1r3Wf4PN0JGX8pmu+oY45J4AU8AfdJ1IWS+p2/hYZsI8h/3HaP4DvKJFFE/0O7u9xIqePnLL2zok29NASYJP6lBog2LHKkmQbAy0b68MvYXoX8TKctsw+yC4K8YVibaV7L9NmN9DzhL0CsJmNUECPwfQ3696tfg3AoQdA10YpvFfayMd9pBd19wpnLA82BYAh1WUQTnNgIEkg+eFRGD/M69AIJhQgTZCf4zAgiGVY8gnKkyOAlcCDDpDUwaFwJMegOTxoUAk97ApHEhwKQ3MGn87wX4B5vtN3kWXoa3AAAAAElFTkSuQmCC"
AUTUMN = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAAsTAAALEwEAmpwYAAAD3UlEQVRoge2YP2hbVxTGf45DA5bSP4K+OKWe7FKHwMNghDGlyEOmbHESMC10aIcOhkK71aBJkLVgqqVDoYEY07rW1qUZ4ngQxhRSgZGg9mRwbQ2ipbagAUcdXs7VufddKXo1RXbqD4R07z3nvvt99/x5aKD1+LvW7c+/5f23hgFY39v3/hZ0Wl/f2+fHrz4GQPYLR1LGr7ixw8qn75nxQmELgGymyXRwaObL9TRAbG6zMRSz17ZXbzw19r8/fAXAzLljmSvX01yQCX3YpEjiu1DYYqGwRTbTNIcXlOtppoNDpoNDQ07bZDNNNhtDlOtpi7y2FWKa7NUbTynX00YI/ayL3QkNe8i159b3euZtQcgDLNYCrxiamNy++G42hvhsvG7Zri5lYuPZDxoArC5l2vsttW0AvwCdUNzYASLi81OjSVwN7uWvc6tQ4RqDFiHAIrZYC4yP2GghBL5Ikd9ffv02gNlTp4749SxAcWOH2ZuT7fFPv/TqGkMpH3KrUOGjzN9Am2A20zTE9ZxvrAUCrIiAiKTMSbgLpoND43+BhFg9AXGNUj7kfuNS7GazmaaVIrJ+v3HJ8tc2LvnFWtCRsOuTWAAdBSdFKR9S5dh8tBCbjSFrrZQPuZe/bqULYEUN2CnhQq9J7ek5BeanRq2wn58aNTXh32KldsCHd68AsLy2TbV+GZ4Tq3LMYPAXc7kxY3tnPLLV5OXbrRku3DoiNomK4PzUKJXdoxO1TMFK7QCIiOu9Hz05AmBmIkU4ElB8vj6XG2OldmCKKACqJkCblBB1C6peF3RNgfW9/Z7mNB78/Ks1ruwexWyEvEB3lJmJFDMTKe+a+JbyoUkfIeveukSFbrN6TfwuugcGrND2hXmn0O+FPMCd8StGhLncmLll/fZY2T0yz5E0EF+BdJNrDBoR3M7hktZtt8oxA7OTuZY8HKIbfvON1wD47Y8/vQQEr7dsPw3fK7R+FRboaFhe2zY3XtzY6UjchaSEvFsIYQ0d9lWOgUjAge+/+KQleeiDPoQL1++ddwMmh1/1rs3lxmIk3FTQfr7nvsj/wQ/2WAQRwgIpvEAkgF58RrwwdFPfPYTPP+kevfh28lle2zbRpwsqRFHoCjvw7JuFFqcELqlOonWLHOkmPoQjqVhdSdQG/2t0ixLXzieC2zF0QdU2uoifqghIClcEXXfcjqKLtE6DUxUBSeCLAE1seW2bcCSKCF/uC850BED3AtqtowjOvACCF3USF1JvzmwKuBBCSVvqSyOAoNdOIkj8f8DLhnMB+n2AfuNcgH4foN84F6DfB+g3zgXo9wH6jf+9AP8AuZYlhhKiFa4AAAAASUVORK5CYII="

# HTTP cache
TTL_TIME = 86400  # 24 hours is 86400

def main(config):
    # Run and display the app based on choices
    pet = config.str("choice_pet", DEFAULT_PET)
    name = config.str("choice_name", DEFAULT_NAME)
    show = config.bool("choice_show", DEFAULT_SHOW)

    # Determine hemisphere for correct season rendering
    location = config.get("choice_loc", DEFAULT_LOCATION)
    loc = json.decode(location)
    lat = float(loc["lat"])

    if lat >= 0:
        hemi = "north"
    else:
        hemi = "south"

    # Determine current season and time of day (period)
    timezone = loc.get("timezone")
    now = time.now().in_location(timezone)
    season, period = read_time(now, hemi)

    # Set animation delays and actions
    ani_action, ani_delay = render_action(pet)

    # Set filter for time of day
    filter = render_filter(period)

    # Render name row if 'Show name' toggled On
    if show == True:
        name_shadow, name_name = render_name(name)
    else:
        name_shadow, name_name = [None, None]

    # Render for display
    return render.Root(
        delay = ani_delay,
        child = render.Stack(
            children = [
                # Background
                render_bg(season, period),
                # Filter for scene
                filter,
                # Pet action
                ani_action,
                # Filter for pet
                filter,
                # Row for name shadow
                name_shadow,
                # Row for name
                name_name,
            ],
        ),
    )

def get_img(pet, action):
    # Fetch pet action images from common URL
    url = "https://raw.githubusercontent.com/frame-shift/images/main/Tidbyt/pets/%s-%s.gif" % (pet, action)

    # Fetch images from web
    res = http.get(url, ttl_seconds = TTL_TIME)

    # An error occured
    if res.status_code != 200:
        # In the event of a failure, return empty string
        return None

    # Grab and return responses body
    data = res.body()
    return data

def read_time(right_now, hemi):
    # Parse current time
    date_m = int(humanize.time_format("M", right_now))
    date_h = int(humanize.time_format("HH", right_now))

    # Determine season by hemisphere and month
    if hemi == "north":
        if 3 <= date_m and date_m <= 5:
            season = "spring"
        elif 6 <= date_m and date_m <= 8:
            season = "summer"
        elif 9 <= date_m and date_m <= 11:
            season = "autumn"
        else:
            season = "winter"
    elif 3 <= date_m and date_m <= 5:
        season = "autumn"
    elif 6 <= date_m and date_m <= 8:
        season = "winter"
    elif 9 <= date_m and date_m <= 11:
        season = "spring"
    else:
        season = "summer"

    # Determine time of day
    if 6 <= date_h and date_h <= 11:
        period = "morning"
    elif 12 <= date_h and date_h <= 17:
        period = "afternoon"
    elif 18 <= date_h and date_h <= 21:
        period = "evening"
    else:
        period = "night"

    # Return season and period
    return season, period

def render_filter(period):
    # Determine filter color by time of day
    if period == "morning":
        color_f = "#eea93320"
    elif period == "afternoon":
        color_f = "#00000000"
    elif period == "evening":
        color_f = "#582c5050"
    else:
        color_f = "#610c0420"

    return render.Box(
        color = color_f,
        width = 64,
        height = 32,
    )

def render_bg(season, period):
    # Determine background based on season + time of day
    if season == "spring":
        bg = SPRING
    elif season == "summer":
        bg = SUMMER
    elif season == "autumn":
        bg = AUTUMN
    else:
        bg = WINTER

    # Force background to night if time of day is night
    if period == "night":
        bg = INSIDE

    return render.Image(src = base64.decode(bg))

def render_action(pet):
    # Determine pet actions based on random numbers
    q = random.number(0, 3)  # For random action
    p = random.number(0, 36)  # For random pet location

    # Idle
    if q == 0:
        axn = render.Padding(
            child = render.Image(src = get_img(pet, "idle")),
            pad = (p, 0, 0, 0),
        )
        delay = 200

        # Play
    elif q == 1:
        axn = render.Padding(
            child = render.Image(src = get_img(pet, "play")),
            pad = (p, 0, 0, 0),
        )
        delay = 200

        # Sleep
    elif q == 2:
        axn = render.Padding(
            child = render.Image(src = get_img(pet, "sleep")),
            pad = (p, 0, 0, 0),
        )
        delay = 1250

        # Walk
    else:
        axn = animation.Transformation(
            child = render.Image(src = get_img(pet, "walk")),
            duration = 240,  # 240 is full 15 secs for Tidbyt display
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(-30, 0)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(70, 0)],
                ),
            ],
        )
        delay = 0

    return axn, delay

def render_name(name):
    # Render the name and shadow rows if toggled
    name_n = name.upper()
    font_n = "CG-pixel-3x5-mono"
    cir_d = 3
    shadow_c = "#000000"
    pad_name = (2, 2, 0, 0)
    pad_name_s = (pad_name[0], pad_name[1] + 1, pad_name[2], pad_name[3])
    pad_cir_s = (pad_name_s[0] + 1, pad_name_s[1], pad_name_s[2], pad_name_s[3])

    shadow_row = render.Row(
        main_align = "start",
        expanded = True,
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Circle(color = shadow_c, diameter = cir_d),
                pad = pad_cir_s,
            ),
            render.Padding(
                child = render.Text(content = name_n, font = font_n, color = shadow_c),
                pad = pad_name_s,
            ),
        ],
    )

    name_row = render.Row(
        main_align = "start",
        expanded = True,
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Circle(color = "#ff0000", diameter = cir_d),
                pad = pad_name,
            ),
            render.Padding(
                child = render.Text(content = name_n, font = font_n, color = "#ffffff"),
                pad = pad_name,
            ),
        ],
    )

    return shadow_row, name_row

def get_schema():
    # Options menu
    return schema.Schema(
        version = "1",
        fields = [
            # Select pet
            schema.Dropdown(
                id = "choice_pet",
                name = "Pet",
                desc = "Choose your favorite pet",
                icon = "paw",
                options = [
                    schema.Option(display = "Cat", value = "cat"),
                    schema.Option(display = "Dog", value = "dog"),
                    schema.Option(display = "Fox", value = "fox"),
                    schema.Option(display = "Hedgehog", value = "hedgehog"),
                    schema.Option(display = "Lizard", value = "lizard"),
                    schema.Option(display = "Parrot", value = "parrot"),
                    schema.Option(display = "Penguin", value = "penguin"),
                    schema.Option(display = "Raccoon", value = "raccoon"),
                    schema.Option(display = "Skunk", value = "skunk"),
                    schema.Option(display = "Turtle", value = "turtle"),
                ],
                default = DEFAULT_PET,
            ),

            # Select name
            schema.Text(
                id = "choice_name",
                name = "Pet name",
                desc = "Name your pet",
                icon = "pencil",
                default = DEFAULT_NAME,
            ),

            # Select show name toggle
            schema.Toggle(
                id = "choice_show",
                name = "Show name",
                desc = "A toggle to display or hide the pet name",
                icon = "eye",
                default = DEFAULT_SHOW,
            ),

            # Select location
            schema.Location(
                id = "choice_loc",
                name = "Location",
                icon = "locationDot",
                desc = "Your location changes which environments are displayed",
            ),
        ],
    )
