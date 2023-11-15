"""
Applet: Ten Commandments
Summary: Displays ten commandments
Description: Displays the ten commandments.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #to encode/decode json data going to and from cache
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"

commandments = {
    0: {
        "commandment": "I am the Lord thy God, thou shalt not have any gods before Me.",
        "commands": "faith, hope, love, and worship of God; reverence for holy things; prayer.",
        "forbids": "idolatry; superstition; spiritism; tempting God; sacrilege; attendance at false worship.",
    },
    1: {
        "commandment": "Thou shalt not take the name of the Lord thy God in vain.",
        "commands": "reverence in speaking about God and holy things; the keeping of oaths and vows.",
        "forbids": "blasphemy; the irreverent use of God's name; speaking disrespectfully of holy things; false oaths and the breaking of vows.",
    },
    2: {
        "commandment": "Remember to keep holy the Sabbath day.",
        "commands": "going to church on Sundays and holy days of obligation.",
        "forbids": "missing church through one's own fault; unnecessary servile work on Sunday and holy days of obligation.",
    },
    3: {
        "commandment": "Honor thy father and mother.",
        "commands": "love; respect; obedience on the part of children; care on the part of parents for the spiritual and temporal welfare of their children; obedience to civil and religious superiors.",
        "forbids": "hatred of parents and superiors; disrespect; disobedience.",
    },
    4: {
        "commandment": "Thou shalt not murder.",
        "commands": "safeguarding of one's own life and bodily welfare and that of others.",
        "forbids": "unjust killing; suicide; abortion; sterilization; dueling; endangering life and limb of self or others.",
    },
    5: {
        "commandment": "Thou shalt not commit adultery.",
        "commands": "chastity in word and deed.",
        "forbids": "obscene speech; impure actions alone or with others.",
    },
    6: {
        "commandment": "Thou shalt not steal.",
        "commands": "respect for the property of rights and others; the paying of just debts; paying just wages to employees; integrity in public office.",
        "forbids": "theft; damage to the property of others; not paying just debts; not returning found or borrowed articles; giving unjust measure or weight in selling; not paying just wages; bribery; graft; cheating; fraud; accepting stolen property; not giving an honest day's work for wages received; breach of contract.",
    },
    7: {
        "commandment": "Thou shalt not bear false witness against thy neighbor.",
        "commands": "truthfulness; respect for the good name of others; the observance of secrecy when required.",
        "forbids": "lying; injury to the good name of others; slander; talebearing; rash judgment; contemptuous speech and the violation of secrecy.",
    },
    8: {
        "commandment": "Thou shalt not covet thy neighbor's wife.",
        "commands": "purity in thought.",
        "forbids": "wilful impure thought and desires.",
    },
    9: {
        "commandment": "Thou shalt not covet thy neighbor's goods.",
        "commands": "respect for the rights of others.",
        "forbids": "the desire to take, to keep, or damage the property of others.",
    },
}

#Christian images
images = {
    0: {
        "image": "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",
    },
    1: {
        "image": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAgCAYAAAD9oDOIAAABVmlDQ1BJQ0MgcHJvZmlsZQAAKJFtkD9IQlEYxY9lGBrhEE0NL2io0BCVqC1ziKjhZf/brlfT4Pm8vPeimlvbgqKGsqU9CGysraklqGgPt5bApeT2XV+lVvfycX58nHs5HKDNy4QwvAAKpmOlpia1ldU1zVdBAH70YhRhxm2R0PVZsuBbW0/1AR6l92H119HMYedL5A7axbHfLE2c/vW3HH8ma3PSD5phLiwH8AwS61uOULxN3GNRKOI9xTmXS4rTLl/WPQupJPEtcZDnWYb4iTiUbtrnmrhgbPKvDCp9V9ZcnCftpumDjgSiiGMMc1iibv73xuveJIoQ2IGFDeSQhwONXgu6BrLE0zDBMYIQcRQRmpjq+Hd3jZ3YBcb3CV4bO2YAV9R98KSxG6hQ3H7g5kwwi/006ql67fVY1OVAGeg4kPJtGfANAbVHKd/LUtbOgfZn4Lr6CbshYgDdrg/bAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH5wsPBBYuL2GwGQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAYhSURBVEjHrVZtcFTVGX7ec+7u3c/sbrKbuNkEQiShQT5baaRWG0SFKogytNPY1jrVdqzOODVt6TDWFkamIzN+lI5VabH2Y7R2tOMHLSMRC8jH0FbSBoEQMJgSIGz2krsf2ezuvffc0x8320HcGKbT8+P+OO97nnPOc5/nfQ9w2SOozJoRD+H/NR77blui97XrDn7wVsfJxx5qa5gqn0+VcP+dLQ333BHfEwu75npcrLq12b+6Me5/s3t/Kv0/ga5Z3lT7w2827opF3C2MMRARPG4ebm70rSpa/KVDR0bHK62jSRGZX3n/9avfTtSoHVJKcM4ghO0sIsJ53Tg4e+XhpZAfB2aTYe7+7fyNiajaQURgjCGpl94/o5W6iZxz1Ec91+x9se3ZiuepNLll44KO2TMCayEBIiA7bp156vdDt9zZ1b86lTFPEBEggbbpgbte+OnCFVOCMh5xXbcgssXNiYgIhiXFnh79K8/9YeDM0VPJ/Bt7Up0FQxgAwAlonxf6ORBRPxH0d5ua76mvUVuJCETAyTP5zXet7dlfjq/ddKSn//T4xgkWEK9RZ2x7puXbnwg6vyXYVeZNz1taZ9eJDZfmLPvWsU0jaaO/TMPMab7v+QMhXhH0wa/NXBSPulsACSklBocLm08Pp7KXghqltHHoeHYjMYfzumr39PX3NdxUEfSOZbHbOBFsW2KsKEr3PTLw3GTq+PraD15JjpZ0KQFI4POLIqsqgoZ8rs+VuRzNmH/tH0xqk4GaRro0VhDdTj4h5FMWl2PKxYkKQ6tt2+Cc4ZxWGtz66PxVrc2BWSqnWrcLXkvAMmycHytYyZ0H9H4tbfQ1x70AALebtVZ01OHXr7/gVnk1JBDwcvhUBoJzEiEEyla1bRtcIQycLWJmgw+WKZDJm2i59VC1ZWZ1DgCKu5q2b5nXFY96bq2LeHjQp0BhBJqwJOBQAhCklCAiSAkUigKhgALTtCCEjbYWb277PnMfLZpTF9myvvXlxjr3zYzYhLedT8m0kR0z00LgLDgJhYhxRjHFxepCAQVapoRYlQrLEtDHLAS8HEnd2EW9f7r2SDyqXlX2uA1gNGsilTHfu/2BE2v0jHZaCCk/+puqPCuXhlvX3Ttt86xGb4eUEiO6idpqBdIGWH3McxVjDIwxaDnL0jIGYiE3ElHPnPSYpX0cEACyxW3vnD4c8vMmKR1NgwHCsiGlBJNSAgQMnCu88/JfhldHgwqIgEhQ8fxyQ9PqyST11I/mLY9HPU1yYs/evuyDI2mxf+LGDEPJ0t8+++VjK3/y9PFtqYw5KKWEtCU+/angQ0wJVqy5X1gY/jEBYIyg50y98wf//vX3H//w9lTa6GPjJTv/x+3DXwVGCwAwkja3Ao6r6mvcC59e19R5KeCLT3zm7ml16mIAkBIYShrPAKP5HfuGtDd2aSvw9q/aH754wcK2+siH3Uv01LtLpbb3Rnn0zeuHVW80XI5/afn0xlPdN6S1vTdK/cAyeWrHklQifkX4I1Xqiw8MPHnxxD/7zun9g+OPMubcujasXPHWszN/AQBuNcK67m54PuxXQo5WJfoGx9edHT6fnrJHMR5Wel6dtzdR47qGiCAB7OtNb6jyK7G5V/rvZxPyG0oVd1+9pucG0xqTU3ZTKYt2vNa3s+1K/zcUJr1EhPqY2mGDFgW8DIwIuaJIvfDa+RXvvncufdktevfftcyC2eGjDXWeTpfieC3oY7iQE0jnRWnngQu3PfyzY70VW/SO3yz+zr/68snUqJktFkShfUFgWm1UTdT4lXa/h65lCov7PRwqh1NIOIdh2RjRzWMFwz6YGxeHczlTT2Vl0q1IbyKu1pJ+4Ob/8nFx0bBtCSFsMEYwbMJ4SSDsZSDCxDyDonBI6WwGSDDGYVoWFCIn0QkQhLBh247dOOeQ0kYmY2hnNeNxl4u7ElFXVzjIIzSh5fLjwtkIUDiHomVLlsfFFa9KIGmjZAK5vGEYAseLxdI/ek/mt9/7yKk/Q2YN5y9Enty6fvryubMCS6r8SrvCaA7n5GWQIDJRsiRIcavcMnx1AI87ChM5rpgDwsqJy3kREgMRcTcQriKyi7alj/0HfqurMuo9+YoAAAAASUVORK5CYII=",
    },
    2: {
        "image": "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",
    },
    3: {
        "image": "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",
    },
    4: {
        "image": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAgCAYAAADEx4LTAAABVmlDQ1BJQ0MgcHJvZmlsZQAAKJFtkD9IQlEYxY9lGBrhEE0NL2io0BCVqC1ziKjhZf/brlfT4Pm8vPeimlvbgqKGsqU9CGysraklqGgPt5bApeT2XV+lVvfycX58nHs5HKDNy4QwvAAKpmOlpia1ldU1zVdBAH70YhRhxm2R0PVZsuBbW0/1AR6l92H119HMYedL5A7axbHfLE2c/vW3HH8ma3PSD5phLiwH8AwS61uOULxN3GNRKOI9xTmXS4rTLl/WPQupJPEtcZDnWYb4iTiUbtrnmrhgbPKvDCp9V9ZcnCftpumDjgSiiGMMc1iibv73xuveJIoQ2IGFDeSQhwONXgu6BrLE0zDBMYIQcRQRmpjq+Hd3jZ3YBcb3CV4bO2YAV9R98KSxG6hQ3H7g5kwwi/006ql67fVY1OVAGeg4kPJtGfANAbVHKd/LUtbOgfZn4Lr6CbshYgDdrg/bAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH5wsPBAooIHVIcQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAANzSURBVDjLbZRNqJVVFIafd+19zne83h+x5F5/wiIrkkCJMBFKiMqxTYSIaBAhDRpEg4LQGjTKRkHRLCgcORESCUUaBUYiVBRBUYESRGr3Xr3nnO9nvw2+e6FBa7x+nv2+ay/xP7Hr7qcfXJle/jUPh5FSUkgAkf6bNBwOY67ant99fembv/+a++rW2soNIUtCEjEcDlVVVaqqKksaLm1bfOzokRv3vvPG8POq2VWt9wlJDklDIAFhu7z56uwLWxfu8Pi+5b2vvLT5OIBtbBO2DQhIKbakhx+qj0otgzzm8IHyIjhAnW3yeqUleX543+Jd82WpzJ1E0TIafbh7Ou2iqqIACvWRbJeI6bjxQlnOh1jLh7hdz1xbG//TAJKkvP4AA9wc/7Ry9er8mf2DE8faKb5wqXwQDNTPBlVVNbLdgtPW4aO7dyzEIzt2VK+lUv5UW5/78Xq5drO5dSWq5elGcnn2wOG3ju+/ffKhJasuwSgZdy0/3644/f382xeufPt+tt1JSseOlZ0HnxxqdfIApZtDzdfMjeCpuVV+O7N5cP5yS5YkmzKIyWB+50nmZw9Slr8gli9CqYGguHPTNJF7dyCcjTLc+JRY+QhjQoEIJlOauq7JQAE0zDn71idE9x1WQRa2KRZd19p2l4HAtISzmqsggUEhoOBSaOu+YQAFkU0oUsY9AC5gB1LQNLkGRaxjkPM0utJgQ6gg9VbZwbguApeAnluK7CJE9J4KJCN11HXbSX1nNngiQCrYCZeNikwzTQ3gdTXMIBhgoUigjn5xRdeJ8bTBpgtAtoAmmYRLwUVEuGdWYTIdN0AOwBKpOCmFEAVkXKDYJERTjxqpR8XGuXIqpemFC2GDCIyYTFptmJIkOtvJElhQjNSzd12haetWkmIwGNg2pVMKgghjC7vr1bCo60EDOEajUQciJ2coFAcKkIQLqAwYT5oCOKR+tmnDAO4oXQEJRdCqoS60hpRTShqNRgIl4T5JopTC6toIpSFM3GIrbHvTpk1OoWRH/3MFdyYzvPfxdn75fTPjtkNSG5ICcDPdtNbbBnU9w4lTW7j2RxBWWWt0zXZJs7OzSZKm04Xr+/aOntuyMB1IDUcOtzzzROHiZU6dOf/DZ3U9KVpcXMzrR0bbZvbsOf7y4Pn7l7hnZZxWz57z2dPnL325cWX/BYhO2kugXsNZAAAAAElFTkSuQmCC",
    },
    5: {
        "image": "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",
    },
}

def day_of_year(date, timezone):
    """ day_of_year

    Args:
        date: the current time
        timezone: the current timezone

    Returns:
        The day of the year, and integer between 1 and 366
    """

    firstdayofyear = time.time(year = date.year, month = 1, day = 1, hour = 0, minute = 0, second = 0, location = timezone)
    day_of_year = math.ceil(time.parse_duration(date - firstdayofyear).seconds / 86400)
    return (day_of_year)

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The display inforamtion for the Tidbyt
    """

    #choose one commandment per day based on day of year. or always random
    if (config.get("display", "OncePerDay") == "OncePerDay"):
        now = config.get("time")
        now = (time.parse_time(now) if now else time.now())
        current_commandment = commandments[day_of_year(now, DEFAULT_TIMEZONE) % len(commandments)]
    else:
        #default is random element
        current_commandment = commandments[random.number(0, len(commandments) - 1)]

    #Always get a random image
    current_image = random.number(0, len(images) - 1)
    print(current_image)

    return render.Root(
        render.Row(
            children = [
                render.Stack(
                    children = [
                        render.Image(
                            src = base64.decode(images[current_image]["image"]),
                            width = 12,
                            height = 32,
                        ),
                        render.Padding(
                            pad = (12, 0, 0, 0),
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(current_commandment["commandment"], color = "#E0A42B", font = "6x13"),
                            ),
                        ),
                        render.Padding(
                            pad = (12, 20, 0, 0),
                            child = render.Marquee(
                                width = 64,
                                offset_start = len(current_commandment["commandment"]) * 6,
                                child = render.Text("Commands %s Forbids %s" % (current_commandment["commands"], current_commandment["forbids"]), color = "#F2C900", font = "Dina_r400-6"),
                            ),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    element_display_options = [
        schema.Option(
            display = "One Commandment Per Day",
            value = "OncePerDay",
        ),
        schema.Option(
            display = "Random Commandment Each Time",
            value = "Random",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "Display Choice",
                icon = "display",
                options = element_display_options,
                default = element_display_options[0].value,
            ),
        ],
    )
