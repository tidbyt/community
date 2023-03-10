"""
Applet: Guardian News
Summary: Latest news
Description: Show the latest Guardian top story from your preferred Edition.
Author: meejle
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NEWS_ICON = base64.decode("""
R0lGODlhQAAgAMQAAN7e3llZWR4eHg8PD5SUlM/Pz4WFhaOjo0pKSsDAwGhoaC0tLTs7O7Kysnd3d+3t7QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjAyMiBXaW5kb3dzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjQ1QzlBMzk3OURBQjExRURCMTkwQUFDMDVBREIzQzVGIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjQ1QzlBMzk4OURBQjExRURCMTkwQUFDMDVBREIzQzVGIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6NDVDOUEzOTU5REFCMTFFREIxOTBBQUMwNUFEQjNDNUYiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6NDVDOUEzOTY5REFCMTFFREIxOTBBQUMwNUFEQjNDNUYiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4B//79/Pv6+fj39vX08/Lx8O/u7ezr6uno5+bl5OPi4eDf3t3c29rZ2NfW1dTT0tHQz87NzMvKycjHxsXEw8LBwL++vby7urm4t7a1tLOysbCvrq2sq6qpqKempaSjoqGgn56dnJuamZiXlpWUk5KRkI+OjYyLiomIh4aFhIOCgYB/fn18e3p5eHd2dXRzcnFwb25tbGtqaWhnZmVkY2JhYF9eXVxbWllYV1ZVVFNSUVBPTk1MS0pJSEdGRURDQkFAPz49PDs6OTg3NjU0MzIxMC8uLSwrKikoJyYlJCMiISAfHh0cGxoZGBcWFRQTEhEQDw4NDAsKCQgHBgUEAwIBAAAh+QQAAAAAACwAAAAAQAAgAAAF/yAkjmRpnmiqrmzrvnAsz3Rt33gOMw3wMDocw0EsEgOGxy94czwMzkcDIY0CmTVHAhJtQAwNa4AoEAkUDgR2FSh3RURlISH/Pg7OxGC9esOVQAVKVD8DSgp8Kn5cgBANSgdKIpCJKYtWjkqPUptelSeXjZ1KZYkLYw4KVyShS5tJDw4jAg49snl7MQKPAAgMgqsQA5EPBaUESgEDdA8LPg8EtQHIsRCCSzADz1cM2CJDRQEQtEXgDm1gDQdAUbJJejHUBSQEDAMMCuICQ0DmCrn4lDkAgoDIJlkLCgoQgGrgNyQBAhxogOiZJxEDBDBrIODaQGgDBAEYQK0BHQfUFtBQI7KtxwIFShx0VAJgUzMlT0x0k8Io1q89sNTg1ESpXaYfDcQZ4mmU2s6cARpIbVCyp8wFf6rh9EXsVsyjDNRMYvrVCk4vwyAR8mJUotSvOEUctApWAJiqRq1c89RuJ9uYsAYYjXvUa7VNAXwYgKCJrpUoALJ+JBtrE13CUQjQ3bSSMWXD9piJaydAjoCumxR09fzADE0EnV8pSbDWcSPBBQAYoEPbTrFODnwAIOCjgE3NEBI/AEBMHU7jmjg/AxAAZ+RP2LNr3869u/fv3kMAADs=
""")

def main(config):
    edition = config.get("edition", "uk")

    #For the sake of linting
    finalheadline = ""
    finalblurb = ""
    finalpillar = ""
    finalsection = ""

    if edition == "uk":
        ukHeadline_cached = cache.get("cached_ukHeadline")
        ukBlurb_cached = cache.get("cached_ukBlurb")
        ukPillar_cached = cache.get("cached_ukPillar")
        ukSection_cached = cache.get("cached_ukSection")
        if ukHeadline_cached != None and ukBlurb_cached != None and ukPillar_cached != None and ukSection_cached != None:
            finalheadline = str(ukHeadline_cached)
            finalblurb = str(ukBlurb_cached)
            finalpillar = str(ukPillar_cached)
            finalsection = str(ukSection_cached)
        else:
            GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText")
            if GET_GUARDIAN.status_code != 200:
                return connectionError()
            GET_UKHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
            GET_UKBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
            GET_UKPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
            GET_UKSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
            finalheadline = str(GET_UKHEADLINE)
            cache.set("cached_ukHeadline", finalheadline, ttl_seconds = 900)
            finalblurb = str(GET_UKBLURB)
            cache.set("cached_ukBlurb", finalblurb, ttl_seconds = 900)
            finalpillar = str(GET_UKPILLAR)
            cache.set("cached_ukPillar", finalpillar, ttl_seconds = 900)
            finalsection = str(GET_UKSECTION)
            cache.set("cached_ukSection", finalsection, ttl_seconds = 900)
    if edition == "us":
        usHeadline_cached = cache.get("cached_usHeadline")
        usBlurb_cached = cache.get("cached_usBlurb")
        usPillar_cached = cache.get("cached_usPillar")
        usSection_cached = cache.get("cached_usSection")
        if usHeadline_cached != None and usBlurb_cached != None and usPillar_cached != None and usSection_cached != None:
            finalheadline = str(usHeadline_cached)
            finalblurb = str(usBlurb_cached)
            finalpillar = str(usPillar_cached)
            finalsection = str(usSection_cached)
        else:
            GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText")
            if GET_GUARDIAN.status_code != 200:
                return connectionError()
            GET_USHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
            GET_USBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
            GET_USPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
            GET_USSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
            finalheadline = str(GET_USHEADLINE)
            cache.set("cached_usHeadline", finalheadline, ttl_seconds = 900)
            finalblurb = str(GET_USBLURB)
            cache.set("cached_usBlurb", finalblurb, ttl_seconds = 900)
            finalpillar = str(GET_USPILLAR)
            cache.set("cached_usPillar", finalpillar, ttl_seconds = 900)
            finalsection = str(GET_USSECTION)
            cache.set("cached_usSection", finalsection, ttl_seconds = 900)
    if edition == "au":
        auHeadline_cached = cache.get("cached_auHeadline")
        auBlurb_cached = cache.get("cached_auBlurb")
        auPillar_cached = cache.get("cached_auPillar")
        auSection_cached = cache.get("cached_auSection")
        if auHeadline_cached != None and auBlurb_cached != None and auPillar_cached != None and auSection_cached != None:
            finalheadline = str(auHeadline_cached)
            finalblurb = str(auBlurb_cached)
            finalpillar = str(auPillar_cached)
            finalsection = str(auSection_cached)
        else:
            GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText")
            if GET_GUARDIAN.status_code != 200:
                return connectionError()
            GET_AUHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
            GET_AUBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
            GET_AUPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
            GET_AUSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
            finalheadline = str(GET_AUHEADLINE)
            cache.set("cached_auHeadline", finalheadline, ttl_seconds = 900)
            finalblurb = str(GET_AUBLURB)
            cache.set("cached_auBlurb", finalblurb, ttl_seconds = 900)
            finalpillar = str(GET_AUPILLAR)
            cache.set("cached_auPillar", finalpillar, ttl_seconds = 900)
            finalsection = str(GET_AUSECTION)
            cache.set("cached_auSection", finalsection, ttl_seconds = 900)
    if edition == "international":
        intlHeadline_cached = cache.get("cached_intlHeadline")
        intlBlurb_cached = cache.get("cached_intlBlurb")
        intlPillar_cached = cache.get("cached_intlPillar")
        intlSection_cached = cache.get("cached_intlSection")
        if intlHeadline_cached != None and intlBlurb_cached != None and intlPillar_cached != None and intlSection_cached != None:
            finalheadline = str(intlHeadline_cached)
            finalblurb = str(intlBlurb_cached)
            finalpillar = str(intlPillar_cached)
            finalsection = str(intlSection_cached)
        else:
            GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText")
            if GET_GUARDIAN.status_code != 200:
                return connectionError()
            GET_INTLHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
            GET_INTLBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
            GET_INTLPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
            GET_INTLSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
            finalheadline = str(GET_INTLHEADLINE)
            cache.set("cached_intlHeadline", finalheadline, ttl_seconds = 900)
            finalblurb = str(GET_INTLBLURB)
            cache.set("cached_intlBlurb", finalblurb, ttl_seconds = 900)
            finalpillar = str(GET_INTLPILLAR)
            cache.set("cached_intlPillar", finalpillar, ttl_seconds = 900)
            finalsection = str(GET_INTLSECTION)
            cache.set("cached_intlSection", finalsection, ttl_seconds = 900)

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
            offset_start = 24,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = finalsection, width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 1, color = pillarcol),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = finalheadline, width = 64, color = pillarcol, font = "tb-8", linespacing = 0, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = finalblurb, width = 64, color = "#fff", font = "tb-8", linespacing = 0, align = "left"),
                ],
            ),
        ),
    )

def connectionError():
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 24,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = "Error", width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 0, align = "left"),
                    render.Box(width = 64, height = 1),
                    render.Box(width = 64, height = 1, color = "#ff5944"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = "Couldn’t get the top story", width = 64, color = "#ff5944", font = "tb-8", linespacing = 0, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = "For the latest headlines, visit theguardian .com", width = 64, color = "#fff", font = "tb-8", linespacing = 0, align = "left"),
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
        ],
    )
