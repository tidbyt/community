"""
Applet: Guardian News
Summary: Latest news
Description: Show the latest Guardian top story from your preferred Edition.
Author: meejle
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NEWS_ICON = base64.decode("""
R0lGODlhQAAgAMQAAN7e3llZWR4eHg8PD5SUlM/Pz4WFhaOjo0pKSsDAwGhoaC0tLTs7O7Kysnd3d+3t7QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjAyMiBXaW5kb3dzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjQ1QzlBMzk3OURBQjExRURCMTkwQUFDMDVBREIzQzVGIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjQ1QzlBMzk4OURBQjExRURCMTkwQUFDMDVBREIzQzVGIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6NDVDOUEzOTU5REFCMTFFREIxOTBBQUMwNUFEQjNDNUYiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6NDVDOUEzOTY5REFCMTFFREIxOTBBQUMwNUFEQjNDNUYiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4B//79/Pv6+fj39vX08/Lx8O/u7ezr6uno5+bl5OPi4eDf3t3c29rZ2NfW1dTT0tHQz87NzMvKycjHxsXEw8LBwL++vby7urm4t7a1tLOysbCvrq2sq6qpqKempaSjoqGgn56dnJuamZiXlpWUk5KRkI+OjYyLiomIh4aFhIOCgYB/fn18e3p5eHd2dXRzcnFwb25tbGtqaWhnZmVkY2JhYF9eXVxbWllYV1ZVVFNSUVBPTk1MS0pJSEdGRURDQkFAPz49PDs6OTg3NjU0MzIxMC8uLSwrKikoJyYlJCMiISAfHh0cGxoZGBcWFRQTEhEQDw4NDAsKCQgHBgUEAwIBAAAh+QQAAAAAACwAAAAAQAAgAAAF/yAkjmRpnmiqrmzrvnAsz3Rt33gOMw3wMDocw0EsEgOGxy94czwMzkcDIY0CmTVHAhJtQAwNa4AoEAkUDgR2FSh3RURlISH/Pg7OxGC9esOVQAVKVD8DSgp8Kn5cgBANSgdKIpCJKYtWjkqPUptelSeXjZ1KZYkLYw4KVyShS5tJDw4jAg49snl7MQKPAAgMgqsQA5EPBaUESgEDdA8LPg8EtQHIsRCCSzADz1cM2CJDRQEQtEXgDm1gDQdAUbJJejHUBSQEDAMMCuICQ0DmCrn4lDkAgoDIJlkLCgoQgGrgNyQBAhxogOiZJxEDBDBrIODaQGgDBAEYQK0BHQfUFtBQI7KtxwIFShx0VAJgUzMlT0x0k8Io1q89sNTg1ESpXaYfDcQZ4mmU2s6cARpIbVCyp8wFf6rh9EXsVsyjDNRMYvrVCk4vwyAR8mJUotSvOEUctApWAJiqRq1c89RuJ9uYsAYYjXvUa7VNAXwYgKCJrpUoALJ+JBtrE13CUQjQ3bSSMWXD9piJaydAjoCumxR09fzADE0EnV8pSbDWcSPBBQAYoEPbTrFODnwAIOCjgE3NEBI/AEBMHU7jmjg/AxAAZ+RP2LNr3869u/fv3kMAADs=
""")

def main(config):
    edition = config.get("edition", "uk")
    fontsize = config.get("fontsize", "tb-8")

    #For the sake of linting
    finalheadline = ""
    finalblurb = ""
    finalpillar = ""
    finalsection = ""
    blurbstripopst = ""
    blurbstripedst = ""
    blurbstripopem = ""
    blurbstripedem = ""
    blurbstripstbo = ""
    blurbstripedbo = ""
    blurbstripopit = ""
    blurbstripedit = ""

    if edition == "uk":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_UKHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_UKBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_UKPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_UKSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_UKHEADLINE)
        finalblurb = str(GET_UKBLURB)
        finalpillar = str(GET_UKPILLAR)
        finalsection = str(GET_UKSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")
    if edition == "us":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_USHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_USBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_USPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_USSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_USHEADLINE)
        finalblurb = str(GET_USBLURB)
        finalpillar = str(GET_USPILLAR)
        finalsection = str(GET_USSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")
    if edition == "au":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_AUHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_AUBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_AUPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_AUSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_AUHEADLINE)
        finalblurb = str(GET_AUBLURB)
        finalpillar = str(GET_AUPILLAR)
        finalsection = str(GET_AUSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")
    if edition == "international":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_INTLHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_INTLBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_INTLPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_INTLSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_INTLHEADLINE)
        finalblurb = str(GET_INTLBLURB)
        finalpillar = str(GET_INTLPILLAR)
        finalsection = str(GET_INTLSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")

    #fallback
    pillarcol = "#ff5944"

    if finalpillar == "Opinion":
        pillarcol = "#ff7f0f"
    if finalpillar == "Sport":
        pillarcol = "#00b2ff"
    if finalpillar == "Arts":
        pillarcol = "#eacca0"
    if finalpillar == "Lifestyle":
        pillarcol = "#ffabdb"

    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 27,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = finalsection, width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 1, color = pillarcol),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = finalheadline, width = 64, color = pillarcol, font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = blurbstripedit, width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 27,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = "Error", width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 0, align = "left"),
                    render.Box(width = 64, height = 1),
                    render.Box(width = 64, height = 1, color = "#ff5944"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = "Couldn’t get the top story", width = 64, color = "#ff5944", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = "For the latest headlines, visit theguardian .com", width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "UK",
            value = "uk",
        ),
        schema.Option(
            display = "US",
            value = "us",
        ),
        schema.Option(
            display = "Australia",
            value = "au",
        ),
        schema.Option(
            display = "International",
            value = "international",
        ),
    ]

    fsoptions = [
        schema.Option(
            display = "Larger",
            value = "tb-8",
        ),
        schema.Option(
            display = "Smaller",
            value = "tom-thumb",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "edition",
                name = "Choose your Edition",
                desc = "Get news that’s relevant to you.",
                icon = "newspaper",
                default = options[0].value,
                options = options,
            ),
            schema.Dropdown(
                id = "fontsize",
                name = "Change the text size",
                desc = "To prevent long words falling off the edge.",
                icon = "textHeight",
                default = fsoptions[0].value,
                options = fsoptions,
            ),
        ],
    )
