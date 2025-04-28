load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAoRJREFUOE9lVEtWG0EMLPWYba4SWJMF4BMEjpH483wQ7MHkGDgniCEPZ41zlWzxtPKqpBkH4sV4plutLpWqZDBzg0M/N8Acrk/jVu4YNxVi/NOnKZzB/OOim8MM5nrJhHxnpC6xPpHpYJzjTsQwuy7gaYbEdiR8GwBUJkg0ThRKHoiYqyklto/1CQTj3IkowVTvshzH4v6nEKiCqI9HcPv1IikwlIbV5OEoaqgXXVe1ufv1jIeXA65PT/B9f8Dn0xE2e36PsPl9wM3HER72B9xOLnShlShZqXt2vFal3+2eVWpQlKhU7bvGJG/nn86VqFjpqTRnNyvRlUY8uK4RYVED1/iqTmanB1E4Oq9orAlqJBsHOu/QlGZoxKzdphwCLTeioxGymo4DNBy11jjbN4U7tXYoeQszzNc/sPxyGYiSg1ADsPj2hNVkHMiZprK6ktrNLnORHWNp8/VW/KmbKV7SYNKiYXH/pLqXmbRWR2lKiNzSDpRLKQ3md9vgq6dR6N5pvBeKO9rpWHTx7P8JrWB2t0U7u4pS/gD2YZCcwNZc4/usfcRqeolAKAGmU0isO0oxzNttMJ8tuT5rpEHecHN2gs3La/g2jd1OrtBVR0O6wnqgUVC74IHL6rBBwg656CGXEMVm/6r31fRKcZRcYVPCI/FUU+hPd8zvHoVvOb3MeRDNSgyYraOKNvfpMJ7lmRwOgHd18OoguL74Xs1ZUwyeHGeaPkDRMAjz5QAcLH6cWqmzMN3RelFXfqd5Q/xE2KtzmH3JVeLVbBzGYphcAs/RFRMomsi40OGwGAaNWfDPtA4Cs6Sj/yT2fpL09GgeZmjOzxRMDNIQtex0jOrHX7roeBnwFyJ6fy+gno16AAAAAElFTkSuQmCC
""")
ICON_CLOSED = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAktJREFUOE9lVNF1IjEMlHZJPSQVwJVwXBnAR6CObD5IyuBSAlwFIfWEte/NjOSFF+CZXVuWRiON3Myqu1u1/OST48g8XqvfvuMZp9W0rbNqjq9XXMKC17BkABrrZi7cxFVL23yCj7gDT/JeFQW/UsaIDB/V6l0Es57RhGzyDXz0xZWRaykN1P793x2azGRYL5kNsuq6XrRoiX26cBsD1e79TLRMNECESWLiwbBdEkjXdXQoBoP2sRY+7d7OjCzekD4Ko//K/0gUAd0MaPGBUxTX3cVcKdX2bydeWj3NkBBR4OzjciW3f55mrZYg9e/XSA5JQd+LThQNxuBuB4eqUMKYUKqJGIg2scLwZb20vu/ESrYgED4fTqzP6vGhFQkGx89v7c8fgnwV9/h1ZcBhs7Dee/IdId1KHW13OCdt0T6BJRDTmGlFW0fFXre/rCOyaBuogCkfTpCNreb91Lhu9nH55vvvx9nU5O7cR6xXcIj2QQHBGDZLhcOz1JIVzY5E9cBdVJ6NHsnBZNjAYcciBoduZSz2jP4za0iYmZsdL+Cq2mo+mygBws8rgw8bpcwmVNtIantwGKpNJWQ/EuGNuLM3WZT1gimH6NKh2ibrJH2iCFJMov0xk6rby3YhtbTb6OG4eDdZqFdkFfMlCW8BNPZwjsZWnSGsJHkaitMUuRFza+wfqUdlNWecEk0doJTgqg2HzLeNr6CAyoyRp8ZQwaSUzEUjKQ8l53BOjcbsS9ThKEcz6RHC2NI8oMMc7znq5IMDftK7pkEoWxPqP1goXzJ7NgxkAAAAAElFTkSuQmCC
""")
ICON_CLOSING_1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhlJREFUOE9VVNtx20AMBO6cflyCanAbSX6UPuwfuw23YKeD9OPhIbMPkGeNRiKPILCLXSAzsvCt4FX0dfiTURGVUXzIx1GZgePkQURVBY4Ql5lZCmVKP2QUo5EI57jXCd/UG6l73jne965IpEJxrHVWJTpWryj/Zw4hbpjNSKmuz1HLSCP+vH00DEYBES5eft7Ol+YYpo2CKADEDq4FBBX3t7+mJaqkcTEV6Yx4/nUjkpGDycgOUoDSWtQm7q+fTCY0/EHEKRHb2Qg6aVWMMRl9Jqyj4v76QWmeHh+cC0Uy3v99scDT4w+hQ4HUOZ4//74RJQ2DXzSbCJHeekt1WUR2spB9Luz8XeuIOSeRUzpQWvSSEyrubMp5I2BK2XaIVMIxth6SxooBhegt3PuC/TIaPXBWMUD0qiNGzrYR8EndbwltYUoA71koW1IWZ/KI41gx5rgmBQhYZXQfGoimQCrbX+Ss9mhA1P85qbF8CPC1joD7v41Wj4JF6RkgSrWfR5iqMUFZM82EaOwYMCgrkAqboamX0j2/XBatWsQ61qUylwMpr5imodBrdlXZlNtYm2iyXPuwl8USfMVdS0IO6XW17yXPtoWZp8pE6BW1Wa/bRrN2z/YtwoV4rTktSCqASbFP289emF3msl6/ZDa9DXcWao0Xaf/3WPU04NwLyxqpDVb5FNILWIJts3ltEy9Wz+G+wsxNM75tpP9XPWgyHdvS5AAAAABJRU5ErkJggg==
""")
ICON_CLOSING_2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAihJREFUOE9VVN1Z5DAMlBL64ToASuAog9sXtg7gZSkDroTb6wDq2S8W3/woCXmIHceWZkZjZUZWZERVYIjCy08WvvniSkZFYfRGfnHeZzMyM6p4oPSBcTuqWf9nVGTHuFvnEqE5BjaW83f2MXiukWmC7Ao258yRRxmsSEQIjRv/l9FfEce3M+Az0Ma84uXxzpkc2GFBnFs7zxiaHU//TBzZjRPZCaE1rXg+3JLZNE0SUiS4w8gqnt7+GxXzaRtFt7rQrilGxuvhln8oAQMmd8QYi4JFxcOvKwYpF+Dv14U1vr+Gbk6QGe+fF6J+OdzElEAJCLRNxVgqnk5nWWIth4slEut2FtAFwerr403kNJOFapooxojj6cwsv4mQ5WTlPj6F8OH6ioF4qDI+vi6cP/+5i5mWc1GAaamhRetuv4j65vXN/PYmrbSMmOaJIFaEoDxNDmgEEmTzmhxHsEQI+fGMMUx5rTIoL8wiuXqzKvDzpqwGkQcqyY7W0U1JerfGwiyOKBgSa8++L/LOUkhohKC82QZZ7Lv1yqmaMrSCd/j2JdZBeaa5dVco71iQBbOf7caO2XWVrYFIy4rCdZ3hwe42SD4A3eHk9faw/Cc1iVZ3RV3NfYoIdQYIWQiHoM9cDLckcbF/eHs2j6rQnULK2wsedpTdaHS3Ow1Rdddsg25ddEXIPPaVGkrj3LmalLtlm9WuxcOXu67fOglBC7jDJh3V/1cBu4St7zd1ulwygKPQgAAAAABJRU5ErkJggg==
""")
ICON_CLOSING_3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAkFJREFUOE9VVN15IjEMlGxST44KQlogZRw8hNQB9xBSRmghXAWhn8PWfZqR7M2+rNer35mRVFXNxB8TNcVbNN7+Q0UM93zU/+MQNnTNn6KwcAf4GOPxg8HSGvd5p6I0Dct5YkB6LlJ5VZ1BTcXcO5wtbGspP+7TW9EyumQt1vxt6Oj1fEWYLJ7ti5z2T4RHTYpW2kdKVJgItc4+3s5XtoO+iBrPA0ocT/sN7kqpCO7BNNFo5qSIvH5coyJCO+CIMklFQKQmf3bPqBoQIDF6NfGAb+cv/HxZPwSedLzc/ompyvZxRQ4DiM/bHdAcdxspBfXhGwl7Nzm8f4UwyBO4gDxSARHO+1ogd/r9JLVUikXDppsHdBJMtusVsAsNyeX7jqq2v1aDJK/zcmsIfNw9Sy1+AoFAU6w3Obz/DSFnhaFPczwd7eAzyKK3yclbrjXQhcxUeu9y+HAMVbZr/+nG1ODluyHRy6Pfz2Yvtzu+j/sNKvSuxqR061JKmfKHOJPlGMe4gnqiOj+4r4YvSPF2rHdRLWQix3XMzmKWKYpAiwbdmqi6FpMUEWmtBw7BLnvmeC9GfQ5oTK37dpNaNRI5UuoBm9RKcQILlJ6K86ufkzJXiEFypXoXVCJi9N5GKWQzcQpBgqDEgLPOanlwYQ9SRvLFimM8BuPyyOGJjeij6thHF1DfmIfEKNSfMuOuzQWxYMpT5T5EoqnTub4IXciGQcbQRfZcS9TnnMi54AEAcw1hjKBzVZFpVpWG7DSqBokOjcp/9wlXL048qUQAAAAASUVORK5CYII=
""")
ICON_CLOSING_4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAlJJREFUOE9VVdtBIkEQ7J7FeA4jkAtBDEP8OIhD+QDDkAtBiACNR2fmrqq6B9wfdmf6WV3VuLl349MNb93cXAfWHV943Pq46da7m/NCrvimp8MSAXl+7cwYl8DX94qEKOGhoBGSbl35L4e0bzUqw8/l1lCNdys+qcLrxDB18y7zTttemwp2s/XuyDZg4HzR+cvjIspHmwrMuhGNZuHVeqMHAslioDH6B8KBgL2sFLh4CUyjQrTQqrBY799jJK7uBl4EnIPiBdt12z4umHaaJutdI+1AsfZmm92R2ZdztHGZ5OFc6bS8nQUTBMHh/GUdQVcLQYKWyQ43q7XZZn8SPTzHpKryCX4RVGEmymyf7qyUEkU4MbfWum1278xyjwqjXziqErOHXzeccBLl8PHFIMBSOEbLOGy12fr1yJkzf1CFLWjMwbXUgSiMTM9PdzZh2ggYZLDauq33R4K9nN8M5iP43/M3q3q4nXEWSStUiDSo0EthDUyDl9ar/dmffqiDIkpv6TJ5MbDG4TNaRkBeB/61Ndu8noj//Xw2tI2cb5/fZB/PqWO1+vYJDM22q9/mJVUfRGitWZkwqdR8UDi0K46lJlILwjV9Y4FEy62aT8JBvM3BBHUwrB/KZ/eEhMkwZbUsHgDDoS/CJeFSaJEgBaKFcLUwzKwUiOFaTTkOjB77J9bk2JHBv7GmNC2tFXFL+1Bkj0qiXQRMKHMArDh34dBOSvrST/DwIi82q80rQg+SC1chpKU37Ljtc6sPucfOQ8AoJh2p2fwzyN0VM9ddwPz/5R9sz1gzWfrEdgAAAABJRU5ErkJggg==
""")

LOCALIZED_STRINGS = {
    "open": {
        "de": "Offen",
        "en": "Open",
    },
    "closed": {
        "de": "Zu",
        "en": "Closed",
    },
    "closing": {
        "de": "Schliesst",
        "en": "Closing",
    },
    "opening": {
        "de": "Öffnet",
        "en": "Opening",
    },
}

def main(config):
    lang = config.get("lang", "en")
    status = "opening"

    if status == "open":
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        render.Image(src = ICON_OPEN),
                        render.Text(LOCALIZED_STRINGS[status][lang]),
                    ],
                ),
            ),
        )
    elif status == "closed":
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        render.Image(src = ICON_CLOSED),
                        render.Text(LOCALIZED_STRINGS[status][lang]),
                    ],
                ),
            ),
        )
    elif status == "closing":
        return render.Root(
            delay = 500,
            child = render.Box(
                child = render.Animation(
                    children = [
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_1),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_2),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_3),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_4),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSED),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                    ],
                ),
            ),
        )
    elif status == "opening":
        return render.Root(
            delay = 500,
            child = render.Box(
                child = render.Animation(
                    children = [
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSED),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_4),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_3),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_2),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                        render.Row(
                            expanded = True,  # Use as much horizontal space as possible
                            main_align = "space_evenly",  # Controls horizontal alignment
                            cross_align = "center",  # Controls vertical alignment
                            children = [
                                render.Image(src = ICON_CLOSING_1),
                                render.Text(LOCALIZED_STRINGS[status][lang]),
                            ],
                        ),
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            child = render.Text("Invalid status: " + status),
        )
