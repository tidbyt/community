"""
Applet: Cuneiform
Summary: Random cuneiform signs
Description: Shows a cuneiform sign and its Sumerian transliterations.
Author: dinosaursrarr
"""

load("encoding/base64.star", "base64")
load("hash.star", "hash")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FONT = "tb-8"

# To match the Maya Glyphs app
GOLD = "#e79223"
TEAL = "#56a0a0"

def printable(s):
    # These characters aren't in any of pixlet's fonts, so replace
    # with similar ones that are.
    return s.replace(r"ḫ", r"ħ").replace(r"ṣ", r"ş").replace(r"ṭ", r"ţ")

def printable_list(l):
    return [printable(s) for s in l]

def main():
    # Pick a new pseudorandom sign every 15 seconds
    timestamp = time.now().unix // 15
    h = hash.md5(str(timestamp))
    index = int(h, 16) % len(SIGNS)
    sign = SIGNS[index]

    img = render.Image(base64.decode(sign["src"]))
    width, _ = img.size()

    return render.Root(
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Stack(
                children = [
                    render.Row(
                        main_align = "end",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Column(
                                main_align = "space_around",
                                cross_align = "center",
                                expanded = True,
                                children = [img],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "space_between",
                        cross_align = "start",
                        expanded = True,
                        children = [
                            # Sign name (from unicode)
                            render.Text(
                                sign["name"],
                                font = FONT,
                                color = TEAL,
                            ),
                            # How to pronounce in Sumerian, one per line.
                            # Akkadian may be better understood but this is
                            # the source I took it from.
                            render.Marquee(
                                scroll_direction = "vertical",
                                width = max(30, 62 - width),
                                height = 22,
                                align = "end",
                                child = render.WrappedText(
                                    "\n".join(printable_list(sign["sumerian_transliterations"])),
                                    width = max(30, 62 - width),
                                    font = FONT,
                                    color = GOLD,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

# Many thanks to the Electronic Text Corpus of Sumerian Literature (ETCSL).
# https://etcsl.orinst.ox.ac.uk/edition2/signlist.php
# Black, J.A., Cunningham, G., Ebeling, J., Flückiger-Hawker, E., Robson, E., Taylor, J., and Zólyomi, G., The Electronic Text Corpus of Sumerian Literature (http://etcsl.orinst.ox.ac.uk/), Oxford 1998–2006
# The source page says that "the signs in this list were kindly supplied by Steve Tinney of the Pennsylvania Sumerian Dictionary Project (PSD)".
# The PSD's website states that "All materials will be made freely available".
SIGNS = [
    {
        "name": r"A",
        "sumerian_transliterations": [r"a", r"dur5", r"duru5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAXCAAAAADIX/s7AAAAp0lEQVR4nL2OWxUCMQxEL3swEAu1UAtFAkhgrayFWlgksBK2EloJqYThYx8HDDBfk5tkkosoC6S4JMpCTPCUXK7VsrxWV4ZJyWo1bPUQlQHWOikC5vldDSBp65ClOwBUBQCCKjAALxoArTXgyq6QS2mkmAAmAcElSfLhmGm33sex99tJKA8LZmM5t4DZfd7cQaIUv24BpVF2shzp7B/+6p/kCvSj6AAffXZUjJiRaU4AAAAASUVORK5CYII=",
    },
    {
        "name": r"A×HA",
        "sumerian_transliterations": [r"saḫ7"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAXCAAAAAA9oXCLAAABLUlEQVR4nHWRbXHEIBiEn3bOABaoBCxQCT0JOQmJBE5CTgKVQCSABJBAJGx/JLmPdrp/XmafeWF3eBNlwXpznTjkMmXBeRikrqpseCio59o1Q5A39YXBLG97BMg1yPOqmuZueAOXWW/NuDb1UrDuAxhmLjcAsrpy1cComhV2zxzvmx7qCMw5xc2L+R6OL1UAIxkgVR+SD2mH1O22mAC6JEn9fd9uT2M2jculcT7gQcFEV87Y1U7LaSvdjAlMqVjC0KaxXMe2XPdAVZICVblqTjlhpK8jrVPIiSGnGLJhliHqUWVUN657K3kgBsJTT6M4qkOqADYREnACWFkX7ycPZUv+uW29w2Z9r/Y43nXv+X12v//tASnndfgX0qbwC572OTW4Na5/4HoEWVhf4A9sIrTOODqfDwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"A2",
        "sumerian_transliterations": [r"a2", r"ed", r"et", r"id", r"it", r"iṭ", r"te8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABuUlEQVR4nIWSUXHrMBBFTzshsBREQRQUCA4EBYINQYEQQ7AhrCFIEGwIEoR9H7GbtNP07YfHMz7W3T0rLAvvy1WzXM0S2dbwB+jrmiZTToWmy7y9fhO/4DbcBjDHOW0XSCt3+7NWC3CSNnXtViD0m8hQILlLFy8hXh8hod8WYLWcLAkwrXUCmUyT5d7y0YYlAMsSjoQqoGuyNdra6zfudLu1wDw3IG0NLho3uq117eCW4yVVB4AmACZzubpsh1dNwAlokkcAVwC4unjWeNZ+eHH1CQgSvPd+P6DNri2h3eJP5/fqX3O9BW9BagSQ7DXt5zXpXnYctKClaBsBkv+ah1R3L1kg1WmtU675DhAtPedAdi9er4VGA78UgD4xP5N0fcSqmaUuWU6Ws2kId5tsb/sDSP02A3Rs4r9NOBT9QMuw5zYXGiDi2jhDCEMIQ5Rbn8bXvzTvXmwX5MEjEe5mgacXt2sp58dGChTaCNeR47KvkWRWVVVr+rkByFUeXuSOsIwN+AXjvPfEZGY7oL+Bx33ZytD33dIAR9rGX9HdC+KezzecOF0uj+VoGd5zQYbb+2O+6tP9H2vAP5PII5ZcckDXAAAAAElFTkSuQmCC",
    },
    {
        "name": r"AB",
        "sumerian_transliterations": [r"ab", r"aba", r"ap", r"eš3", r"iri12", r"is3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAACQElEQVR4nGNkIAj4Epi2PfrP42hGWCkD27J////+/v//BWGlTFwWN/9Prn76wogFv0JGLl7rMCeGr7e+8iafQ5dkReZwiznPe/jpSD5f8f1XO9gZGERQ1fo5S0GVs4mZd5/9enuCPgMDg/b9/xHMDAybzJiR1S7+fyJTT0ZcTEo/Z/ebJ+sDoW7c+VWEgYHh57dQTiS1Sif/v723aeHqg59fHM6VgwtPOyzMwMCw5v/zah1BhBe93xfFdhz8/2KWMbJ1M48LMzCw3Pvenx2798EdmCjLF7MI4cWXazZhBgoL469FOrHCH38zQgX+/vDVb1GLPomplIFFgGux7KK19z/A1eqv6LAJwqaUgeHO/8O2qLof/W/CUDXzuDADA8P/HWpo4i+fC2NXy1K89Raa+P4T77G6gIFl+XN0oRMfGbGpZGBgWpGOLqRWwIlNJQMDk1lXDTuqkLyePw6D9///u8EDReT6r4tM6Kogfrtmmpk/+eaHW/BYZlLP6+wqwWYsy+df65OMVS79hyXcz4HnFwvUXZ2PTa0K31HOkpNvvkOd+N85runjSoM2mY7fmIo//d+gg+Q5tj3f156+9en/r50BmO7lXZ3zCkmw05lB+tGHS1IqNksOT9vyH9UNwQffInF5JFbNvv7jzw9Wdn7znCWP1y2+jawYJQcxMAkLwCXEHJd8fbnIHuEGfICRR7vy6tedoZxEqGVgYGATTzr85Wm9wAwi1DIwMHM4L3v/+s0pISLUMjAwsojXPd8jwMAAAGMk0m+LaPJHAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ABgunu",
        "sumerian_transliterations": [r"ab4", r"aba4", r"gun4", r"iri11", r"unu", r"unug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAADBklEQVR4nI3TbUhTURgH8P/dvW3Nl5remGi+gJkVLi3N2YtQtiIjNBU0Q6SsT71piEGhpEmF1gcjexU1fGmlpg3FUjJMVLYZFmlmmWiKy2maTreWEz19cJubQXY+Pc85v3vvec5zLoVlx6rjnBeDxC5EvDwFVzpP5mYJUS9POTbbv5DcVJXan/k3pGzsd8Xsha5HZ3/y3dLFFZaJrVBSODDVcs7+Qv9oHQ9YY23DJS5GzhUG3WzXfb3lBz4dpCJHaKBaTFvaEqI45evqJHTxO/tqbOh5JAN43A1Cq44FMPMrmm9hPZVkvK+6qKJpWt18zh0AEDuYveJ2MwvgGRlOFTkslnhoIjk+q4mo8wKMExvfdwydLpezANOnzzkT//pbr8kyWnEsW9KZVm3MuTHUqDrWbZQADGUoFsWzmlnKuDb3O8zvqnec0vSs+7bcArgUOgBgBDaPXfJr+ifN1u9pVnCUmWLHZkPDwPe+rRSAXlK7y+rUmEGSuZiJO1UG2QHqjpwFKFIX99P6iEfmRePmbqSJ5Ywb3SOhD42DSa5dQtGomDDH7jtlOUDwfnaKAExN7xIKhca0d/DDN6G7Di0trj4UwJEmLbXe583NkVzUO9xKdwcMBAAjyuDcm7GyHr6HpQQA4BT8tP6XW0D2QCk1DwCNRC8LtbLdhg+chSjgcyIA54hrVao2R4D5FHg6MffLZI+5y5wNidk3UgCAPeEc0V+DYVljoMCWAphpQ1VCgFcHMV1cbeT7EsHlrkcAfTBBqc3YU9QBTUOkPwDGa1UrP0U5pjfWTrbHZWrKtlx3zZqdfxM6MifccmWsUI6FeztFZCLe4ma5dfrKtz1TxFAfsTBhIzpWUbknr5UFQMqFloXlEKKoLEjKrhzRvgxb+BZvXXj+ZLsjgCjWkto9Kdu3ll3Ns2M9j7ZqPmauBwDQzuUKFoDVHwQOKzCFtDCkVDdSvBsAcF9u9cq/B2Xnc6lLVx/NBx4uZwFwnU40a1Xpggf/YQF6pUQ68WOszfE/LEAxTpeHGwTAH45AGvfCl6PmAAAAAElFTkSuQmCC",
    },
    {
        "name": r"AB×GAL",
        "sumerian_transliterations": [r"irigal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAADL0lEQVR4nI3Ta2yLURgH8P/79n2rqmtrW2s1l1FGQzO3dCOW1TUbYWQhQeqSIO5xZ4IIZkGCCZFgzOiyEGTGLOLOMtvispa51XTMbt3aVbu26+31oRctH7rz6ZycX87J/znPIRBxRKl639MzfdJS8iNbUPlexuNiGMOIyJbkKjTMuewGezqoCLQPb+LC6aTtWxt/x4P/7wxdcMXKi3pL5TZBtr7tMQ9AbDieMz2e7ZvRonHHaqxfzycDSPzCbGQDuKNgheLLTPX6pAH9xP3l6x526kuyaFIkECRQT2wSAES3Z9ld+1+cUDTRZH5v5IqSzRavqhqYtKGpO0O1RjGvGaBKs04nlvyyuP1Yf1Cd2zIqRdlZdshWs1zcRMTIU2mD1UEAAFVvP7le9UivCxzNsiYviC74cPwKhnxJm/uCcHY0DT/R4MtBEc7CUUtjzC7Cjz3O2WP2p2RWAvyh5cXfXAyVZ3wO3y4l5KolF+/WdwaxvDh32upKANzfOXUAUMMxBOo6hXasqgitR7MxPa8AAIzEyjKdjfA4Y3m//VharjKGVdrLMecAAGy1ysUl79h2+WTHPgfjBkBtvRdugfv1Jt85Al1VrZ7laSPXUCPZ/VkEqFLdPxav/GG5g84XAcDgsZYlwvZNVhJUkTrvH5yUdtsMAB5ivFYLwM3hNVrcr00EqNEHyHOOMDxwdOZVBoBFm6FsaWnsTpF1bZ4qU5sBskp4pDg9DEtdO2kAIGP7Nle8fFvbqtl8zcTiAqDqFGs3nvlk/hzsTVK25ciWowAEkj2PGwAMM5SC9kW2OG+tmCDVemm/tWZqC7nZ7fkAGUM2AAAR7DNqWFRF7x2v2u3+F2QUiw91Xh+fI9vjNGm2z3hthkv5Pohnsr7v1f1NyF5OLNnNj+NvSzr7/Id05k/WYHv8RyaAo25saAtJlzsL8T9NGok09dpn4c1jVnC8XR4ygLOedYRYXtyNC3UOt4PuxVdsGjrfUPQV6OIFmgxhnwpktDC4IUq9ZG1VT0WinI3T1RJEGDzZLo3t0aIo9AQDtHjpU0vT4ehTVT3AAIuTVtjR3vEmricYIChRduMzMYA/OFQ2vcGK3RAAAAAASUVORK5CYII=",
    },
    {
        "name": r"AB×HA",
        "sumerian_transliterations": [r"agarinx", r"nanše", r"niĝin6", r"sirara"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAADFklEQVR4nI3Ta0hTYRgH8P85O7rUTQ8dmWVBsJxRVkuimSmFDcqCigq7gRYRhmj6oQtEVpQWah+Kgi50I1crM2ZlSZLmtXJBWEnmdV7XxXZoOc9uZ9vpgzo3P6Tvt+d9frw87/u8D4EpV+g+sqJfkCSppqYI1HoENy8IQ1NTMnhlu3DlxKB1G/V/SARLE3asBdfBSbN1k5MBvkGITH2nb7gxJ/Rwz1CFGAj3t5vVkWM8UBZ34SPXeUkJIKZX2EgCz1UiX6sRmjKWzo2QRSqzKocGnmwhRrcrLQwAhzUlyMfK9QJreH6vtNZiajs6nwpmJDQTAFxtZACqfPvl6GdGi2vMGs7eP/c7Jn41+0CncmxgOmMddN9dE0QiAJTBdjEztbq3a/xgakS1iyluKdDO2JjHNtXuXs9d5MZThLN40V7mLz9WGNz2Tcr8JSl62G+v+aSro8M/a22RvAgAKDpYs/CersfstcpHBYmpegCGd6vS0Wi3GnDgDQQA1NqA2YfKfF/ilzk57ykAWOtlPNiWQU9CgsZGACDlr9P9KFzi3ksAAKGlG0Bb3+x8KztaQ8abjkmtq6kxA0BIgkIRL6EXK3aGP+MIAKDKjZMomkbvKd6dRGTWZzulwyYJCQAgtQcn2+icIACwVIiNfQOke/BM3WKJBwBIVVGu2N/OW7qFAMBX1Qw3J5c4uquv2hQiAQDZFHqmJNnPyvljBAAMf1Akx95q7uKGHrEUAYBqXZGRc6Xd3OH9yOSC7MKiIwDcrXJOZ2kfAao8HgCgLM6y/cujvgjjH9eytVlDn/p6FwD7lp3n4XnADQEAqKjQt0FH9CbbWN8EddrZvyXLzs8t4EHqX6TLPYS3OGqdqCe30+GNA/d40nLDZklPJl576qIa4hKdE1NGSUuzfAe0UI05/eYvkVGJ92tfvnJV0kafc7fXsT5UMuvxzW92lz1AHBaXdeF7/MMakBNZvwkCydDehCxJw/0sXg0AuPGewX8XIYk5/pWrTAmahgUQGLG/YcR4mr4+DQuIZqi1f36bPsychgUIKuLUjyoa+Af+ajBUT0c2JgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AB2",
        "sumerian_transliterations": [r"ab2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAdCAAAAAD516GSAAABGUlEQVR4nI2TYZFDIQyEdzpnAAtY4CRgAQucBCxgIRawQCVQCamEVMLej+tcX1seffnFhG+G3ZAFNlUTjhbNHUZZj4FZaAxHyEijN4ufSadKiUKWj6iY8q+0+rVQkloigCDGnvdHEcnwcJQbTXZEJ2N7aviicyGZ0t/cRDG2/NKszODkPZc7TTaTdt0i3AwF4KtSy11Ise6AyLmJJyHGiCV6F9Lq6fvcKwAsdup2u1xdAIDC5sKOVgBJjFrv5oINx+lWu9zIUTZD8ENV3jhfGtnLyz+4QX3lBtlmq+CU9dEPVWmSdpwGI61GD6SqVFkFMpH/+/opNY0MyTiOJMZYhe+DmModh8ONzr66Pm3OV/ys0K/N+YzrCv0FyFiwHgSmwlwAAAAASUVORK5CYII=",
    },
    {
        "name": r"AB2×GAN2tenu",
        "sumerian_transliterations": [r"šem5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAdCAAAAAD516GSAAABaklEQVR4nI2TYZUbMQyE590rAVHYQnAhqBBMwYWwFHQQRMEUHAgKBAeCAmH645pkk25ymV/y82dLI8vARlbxrjjfR7m+BzZnZnmHVJJLxvI9KTPp6sz2Leo5+aW5vr65kZyrAiie7O25PyXLzVHrTH9isCbHdm3JuV9Io49bRrdgz6pO9qZyRxobqLdzZtY5gCDJvilERirkihrDASzhkPT0TSFrDgGUl+xkUJaiEo7GAagnewOApGKDAmXNrpyQcGQFAGmD2e3j12EYAFzLP37+XOrxoOV38eMZAM7n40kKAKzsUm62AEhkZIMEFVI9Oe2fuZIhvJtqiZljFJnWyVg3TVhiTr/vX8TItZPx+A4SDx/ACpOMqfhPMmnt6qzYZM5JHTsoSpJpugDVJtPrUBK7KCov+rJb1abvo+hkqcm47KqN4D4qSXNuGzHEn/yHErwj0fc5ABj38/2oj018wp9X6I9NfMDpFfoXv+T9DBYBJlQAAAAASUVORK5CYII=",
    },
    {
        "name": r"AB2×ŠA3",
        "sumerian_transliterations": [r"lipiš", r"ub3", r"šem3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAdCAAAAAD516GSAAABYklEQVR4nI2TYZFkIQyEu7bOQCxgAQtYwEJOwrMQC7GABVYCFrISYqH3x9zMvmFe7U3/ouADQncATrKOd8V4H+XxHqjOzPoO2UiWXOX/pETSmzP1PlMNgF2gnsGbwm4ndzZ0vlakJONoAKonpwpgK4+IF/8aWX/262B6iyAzfCN7cj5NlCPIWdB8q0Dpc3fUlyeHosaZNSrYNtKBqpPp+sPKzAbZUHegTaCQ5D0XzSlA4xNpDmiGQJPDk94AINmwo0oDqrrX1W/2MNxQJg1olAcoRrtZZCkAoJFkGoCDQ9qp1jInWQDUeTjQPbnunVxzCZ9SEVuCOkXGIjlOLVRW7KnokmWDnDafV2TtH6DMJIcKfE9WgqaPl1UL5sjyz+BNNcm0VoBuwfQO6BKZryTQyUe/3tNZ64oEBll7cp0S1rwkIUlzPh/TrlHURV5f+Kq59femj9P4C39/Q/+cxp/4+g39BnYB8+POogwoAAAAAElFTkSuQmCC",
    },
    {
        "name": r"AD",
        "sumerian_transliterations": [r"ad", r"at"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAcCAAAAADQV2lOAAABvElEQVR4nJWSUXUjMQxFb/aEgArBC8GF4EJwIbgQJhAcCBMIDgQPBBvCDAQbgvZj0nSm6Z6Tvk/5Spb0dOAZKUyI5c9T9AeA4fIUDIMG08qTMOR5VPke9Mn8TFvVEYh2G3Ta/CPqXIiqFg6Nj+vmoQmXaQ2IxSFGLEAVeYFD8pzP/U4new3SK1gBqH3pvVI70b7BceE6hOul3ujFn5ZRzFJr7b3yXVHxTTdK2trD9BAzcIQQpV4/y0Trz4T8+kCvBYpq3qxl1mBbLHm3SBdzKRlAddg+pMA455jbeCthh1Sil7WTQzv97L4N5lqdNbVOy9riGxAF0pxSa3NOLQLBA4hPrcxfVsUM/AlZ+JAuy9/eWc7GYFLLuYzm/PL67nLY7Sdrc7imBqPNEJuVFsr4OaWEvE4Q87rvonloI5ASRC2SNewmGMsgd5qgO7V5BwMSyphu7riB3pcKYioMJ2+tm3Z0v1xsvPWtc5AYARdhUAlNVecco3ebCVfnHdP71wniKaZfFsRYK0DtldrrjThyPm3+NBbe7/duxd6zZAGOh72Du2OvTPcsv9beaXp9vOlblv3h4b9anf9Nxi/pf4AY/YRTUTH4AAAAAElFTkSuQmCC",
    },
    {
        "name": r"AK",
        "sumerian_transliterations": [r"ag", r"ak", r"ša5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAYCAAAAABG2FsfAAABh0lEQVR4nHWTYZWkMBCEv3sPA1kJWMhJyEpgJeQkZCVkJIAERgJIIBJAApFQ+4MQZuZm+1c/ujpd1V3AbxG19jEuim9qviuJO6pmkSTt9g22P19wWloAs49EuQvR1CxtvrunDGDW+wakrvO3+cL+qVk3Dp4ZwA2dmQEs5iM/SmgvLR4Aqz0aAILGJ5paju9MZ+KrHKvSVGLSVN49sW6velRfKqPVl4G7NwVxEtNSdnLsIZM93xkSQx8TALcQtg2A2bbr7Vb0NYmv6LvvAejykDLgOub7BuDgK4SQjs4G+Iy+98mQ/mWAFv6mi2SyxphDrZMDL0nnidxe9WjUor5e2cnhVmmtLmkv8Vp1LYUGthgYhmSXYIcMkO16EIc2fz7Qieq1OgAdTCT1a82eXNaf++6k6Zi3ayr+fHQZsJzsog47YC97v2C1l8OE8VR02fsVexaclpLuCm+xTTVwwizHtfIW/Z3/4/ovMql1CcBsm2k3C+lNQ+GwF3Gqtn3hWyNU9509MD2t9wdNQ+bcUk/BkwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AK×ERIN2",
        "sumerian_transliterations": [r"me3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAcCAAAAAA7YNJNAAABqElEQVR4nJVUXZncMAyc9lsCLgQfBFFwIYRCDkIWgig4EFwIWgg2BC8EB8L0IT9O9q7XVk+OMh6NJlKAc1gL+I8YSXVfAb5dnoIVWeZHT5QF8Hj+4bIwKM9RzTJTB9z2g38CcJjCMhfZ+EUdnJT3T4hJUzVSHaLtycgQm/9Mh7LVyhaAkQfctUb9XHdkiBS4xIkOcBsJr05xPJgyFRC1xgkhr8lznwDQmnQ5G9PYxsAIAMg6XeCJey9+QwCQGmNOHoClnt3U5Y00b125AGFlVQCmjanL//7EQ/IAAFj2pifIMv94uwMAyjLU6TAzMCi5Fl7Zp2ZyNFQ1mRiZzczMbgDuJQ7DUp4OAFySeUw/ywb3cPAeS1kOdmBcJ0QBiKZKhdRVMDU31gEnMVCyRh1s/4Bjld1IKi/WDPSZdUTXDkCqWjYPgPZqZGVcC3c4hHVlpV726+bh548TKsuveVuKx+VF7cXqwT4eRr4OJPPp5jZu3fYP8NMqK5lWpX0jXuC3ez8XvOtQrlox4H6Gn84OjxLkGB0Ar41edZHt69/MJTLt38FAi3+F/Ab3GAYy+4+A+wAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AL",
        "sumerian_transliterations": [r"al"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC8AAAAdCAAAAAAf/mrWAAABm0lEQVR4nH1TUbGDMBDc16mBWMiTkErAQixgIZUQJKQSQEKQkEgIEg4J+z7gUQK0N5OZzO3OsuxdfrAvPQEKOgMKcwWEnMfZNKaiGzIWRjIW9rWQkCQpVReeQZJy7EtSNWJE2lZY6wN9Eg30hc0BgGXr2B67hh6AZjwCQCxy0aUFAEY5IQ3P8sBihD3DCSoC4Lb68DWmpzboA3/K73vLqPb6JMnkqjhiBHBf7iO05N2EcjfANNZPQx6qj6x8BTWNALDm+ByBnDtlGzeP41DNuvG28ewb37797OK3oTA6vfoBYElSSLpLPgDjE4tP//EHKd6x9PjEB6A930MUUUhUX/i2ZypbPqOaMdYLXGm3Vg2PHLd8JgN8pFtrc7cldJOLpdjbLmF+PF6b2B1Bvz6xa+mFn7VzALGcs+uDxF3rqTPmCWueAPCf2YX0UvSAj8vBmqSmSDg+vXXffqetEfIwr9KvK+mtlAaURiQjEy+k3/rVH4p3iV5dslf+bdeYXnbWj+c3J3U1FPcZPfkBWL6o7d/jWuNwTQUAZAD4A6sn9J3G+oEIAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ALAN",
        "sumerian_transliterations": [r"alan"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAYCAAAAACpGjAhAAABuElEQVR4nHWTYZnzIBCE37vnDKwFPglY2ErAAhZSCVRCIiEWiAQiASSAhP1+JO21vbv9Bwy788zswGulIvxRn+8XvoTfwf7j9RzW5oB9jMY+xv6EzK9QqdKu66U5NNDEw0YbbDS3DsLJ0QOkGgVTgJwAVGNKOXczy9gqwGoJiKaATd9QADTbHHolm+WczbrgrYIPZklVS3oAexLwnWprVFWdS+h9Qmqyow5oLDUJgDdsPn9Xi9mzdrHq7wRirfGUptevFtkboHLZ0j6HZeCCgECcuC1no1l2slnJuVpxYHOtEyeB0nN4krXWQ4HQE6BWJCvWFVaz+GpW/xxeoQ3vAJzDgah6gUmfoU7I57we8DZZT3cCee7lu3G0Tu1JVVWnHjGirQcBckJi7cmdblp9iCXF5qJM5qxP7mHsbOvBY7KPrG0bgO5LltuVdZxTb9eDYwwsy0AqxWpKyayA7xXEWY/ysgMx91mLcRgY7VArAhae10U0prmbWfn61wCW0YDtmvytMU6MF48y9jaubczvKSh+LNMNcV7Y2NkeQZC3FODL7tna2Mc+Xl/4kbhk+a/I/kjscnlvd6//mkQrn3qV+oIAAAAASUVORK5CYII=",
    },
    {
        "name": r"AMAR",
        "sumerian_transliterations": [r"amar", r"mar2", r"zur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABLklEQVR4nI1TQXEDMQzczISAKLgQXAimYAoOBBeCC8EULhBcCDoIPggqhO3jkstMcr5mXxrPzlqrlYAVXjBGsXvlqGNiZr5VySaqG6mx3dWsZNLKnqRTMgInANLch2+XGPAzP9MkzUs8raWyIDCEzld05sKbsDIgU2nF75gwY1gtBAoaudse4JQVgJkEAmQajUUaPeDUIh2mIQ2AdgCoxnhAAiBr34n1mHdH5SiLJ11tR+09EN78udrRWm3ILO/QCv/zIQ6QZpVwg9QAAM4qnKlPinCw0KImkGYxK0D2sE/zfc2+sBJovXPayU+KkcAZ+Jor/Ly4z5wi5t9nNXwHB5wBXKWmi1ucF1yXF8Eg2DrP9GaDQ4qd3N5bJ6eBYdFHDJIPEpZm2+HIYCg3xekPoyivXYs+NNoAAAAASUVORK5CYII=",
    },
    {
        "name": r"AMAR×ŠE",
        "sumerian_transliterations": [r"sizkur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABy0lEQVR4nHVTUbHjMAzcvjkCOgh6EHQQXAg+CC4EF4IOQh4EB4ILwYbgQFAg6D6Spn29qyYfO7JmvdqNga2E8L7U7oi9vR/MnneUrHjjd2xe72ym2d30f5Tc3CNwAkCVP6VeYsCtv45R6ks8bbC5IngIw/+t4Vl9J24ekL25qQBTRhRkggJFgWzmYVshOKG6KwFIBhkUKrIij13gBMCMggPuaXNKxTRaVGc13XRVF5y48KV8LuX2BaDd1oiFsHJn6nO4bss0/vmx/JonCH5/AcBNaAE6eGaa+bDpfN5c9uneiaNQmbglsSDjaO81+ZFFcKJG3CAVMl6Mp1bTkZJCGJEQgPRKGB4309PZE/7YZK3Xg29BECRAAV2/02XXO0xGPChU6IRk3/WpH3tkU2kqFpNztnII4BOoyJxOnP6sQF16xApasTKWm+xquM0fPOjcOzhXAjrzSljBnanLwVZwBVWLuQHuIwBxTFSUWxITGdu9MvbsfXKgjuElIT77bAyQmm8/IKK5YBqk5u7e6mjVWrVabdRqlusAfgCYaUoXXlgI8wKgP31AIBz2ZBezNw8pDvejX4d7efOCqT1ioOyvmT8NVnt4FN6OAdTKX9jZIB6VzFSlAAAAAElFTkSuQmCC",
    },
    {
        "name": r"AN",
        "sumerian_transliterations": [r"am6", r"an", r"diĝir", r"il3", r"naggax"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAAAAACMIRMSAAABBklEQVR4nG3SUZHEIAwG4P921gAWOAldCa0ETkJPAhZSCVjoSWAlbCWAhFTCfw/QFnY2L23mI5mQATjCk5rIFR/ixSBUe+a3+nUWPzsypvxeMdADjklqOl4UKQDIoYi6A8yqSQDEVGU+xKkOsgKQ+CYDyRRpK808BTDjKImxUCOxDjMzQGJXk+hrXw0Su26RXF011Va+gl38uG8AYC3KT4k7zDggbwBgANMQEulNHUSTtoun1hGFInHQcJGUEruW4TuDGUUiGcqVO7NKlUBTF3XaDcjfi8nmb68nt8m1PT1VcGz+qCsPYHma5uA2OQ/gXrLf17O1By7Kj+655KthTfq4tcne0T/JjJDuH2R0xAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AN.AŠ.AN",
        "sumerian_transliterations": [r"tilla2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAZCAIAAADmCgqdAAAIp0lEQVR4nLVXaUxT2xbeZ2oBLdgaEKGAIkIFRZQfBkEFb0iMJaghQAhgDCQNEByjBkFBjASVlF9lEBCRAE4FwRhBCVEEwiCVMA9WkTJIgCItSEvbc877sS+HBr3v+vC5fjSn5+y9vrW+vaaNgB8EQRCapgEAGIYhCAIAoCiKoijjT39CIBZN0wiCYBgGn0mS/Cdc5KdacBw3MTExGAxwA4qiAACtVgv1/jnrAQBmZmYAAMZiHMc1Gg1Jkj/irpgOv0F3BQJBRUVFR0fH6Oioqampk5OTQqEQiUSQGCj/LwcgLoIgCIJQFFVaWmpra9vT06PRaDZv3uzm5hYSEiKXy+FX5mQAAOiq/SRJEgQxPDxcVlYWGBhoMBjs7OxcXV0LCgrAMv3MZmNP1ixQFU3TBEFgGCaRSJycnOzt7fV6/YkTJ8rLy8fGxqB5KIrSNM34iTAWwF9bW9vw8PBbt26ZmZllZ2dPTExYWFg0NzeXlJRgGAYPjs1mm5iYqFSq3yce2gDNiomJeffuXXd3t0gk2rdv3+TkJIfDSUhI0Gg0jJOWlpZKpRIm3ordKIpyOJz79+9rNBqYoO7u7jRNV1VVAQBQFIWUW1lZxcbGnjx5Er5cM/HMRhiiQqFwaWkpNDQU/m1oaCBJctu2bXABhPb29s7IyGCz2RAXZTLP2to6Ojp6//79/f395ubmNE1//fq1ubm5oaEB7qcoysrKKj4+3t/fv76+nvF5bdZDXAAAi8U6ePBgTEzM7OwsiqKM6XV1dSqVCsMwmqYpivLz8xOLxS0tLTCDGTZRDw+PvLy8jIyMlJQUtVq9a9cu+Hl4eHh+fh4AQFGUjY3N5cuXnZ2dRSLRyMgIzBuKopiw+XUfkGXh8Xjx8fG1tbV9fX21tbU7duwwNTUFAIyPj09MTED3KIo6duxYWlpaampqeXk5A4pSFEWSpJeXF4fDqampOXr0qKOjo0gkwnHcYDBQFAVpsLOzS0pK4vP5sbGxMzMz8BBQFOXxeJs2bQJGgfevDsBDhlza2dl5eHg0NjZaW1sLBILIyEhnZ2fIFI7jNE0bDIbw8PCkpKTk5OTq6mocx2GdQRAEBAcHm5ubQ6VcLvfw4cNXr17t7+9PTEzk8XiFhYVRUVF8Pv/x48fFxcXm5uYIghAEAU8Ww7CgoKCSkhLmlGDO/KsAALy9vT08PCAvBEG4ublFRES8efPm5cuXW7dujY6OLiws3LBhw9mzZ1tbW/38/OAyuB1GPzI9PV1VVZWVldXR0cEQ89dffyUkJFRXV+/cuXN0dBTDMC6Xe+7cOb1ev4rCwMDA8vLy7u7uzMzMmpqamZmZX4yZ9PR0X1/f/Pz8R48eLS4uwpfm5uZisXhubk6r1dra2spksoCAgOvXr7e2tv7k9Jqbm9lsdmNjY3d3t0Kh0Gq1AAC9Xu/q6nrlyhW4aGho6ObNm8xcwIher7e0tIyLi2Oz2SqVan5+vrOzc3p6GsYiDAy9Xg9LKtwC6+DS0pKnp2dAQMCXL1/a2tqGhoaUSiUMIYqikpKSBAIB1JCWljYwMIDj+Cq7aZrGp6amqqur9+7dm5eX9/btW4VCAYN4dnZ2YWHB3d2doqiWlhahULhx40a9Xs/0MxRF1Wr14uKiUqlsa2tzdHQ8ffq0t7d3V1eX8TKdTvd3GV4WHMeVSiWbzX79+vXU1BQ8TJlMtrCwQBCEUqlUq9UODg4oinZ1dTk6Onp6eho3EOiSwWBABgcHv3//LpPJBgYGhoeH5+bmSJI0GAwuLi7Jyck6nQ7DsMHBweTkZKaKM61Xp9Nt37799u3bGo3mw4cP7e3tDOsMzT9mLYqiWq02IiIiKChILpf39PQMDQ1NTk5qtVqKovR6fUpKipOTE8zUGzdu9Pb2wvQwns8oisL5fP7Dhw/z8/Pb2toY7b6+vmFhYbm5udbW1vPz8xwORyQSxcbGMjWVEU9PTwcHh7t37xYUFLS3t/8kqP9BuFyuRqN5/vz506dPVSoVfLl+/fqMjAy5XN7Q0MDn8z9//nzq1KlLly79NNZBSEiIhYUFfOZwOL6+vteuXRscHExPT+dyuWKxOCoqasuWLS9evCgrKzMzM4PTHMx0giD8/f0vXrzI4/HAr5UXpjX6+Pjs2bOHGYpcXFwiIyPr6urq6+sFAkFwcHBubi6Xy01MTOzs7Dxw4ACMNGOIvx2IiYmpq6urrKwsLS1VKBRSqdTU1NTCwiI7OzsuLg4AIBAInjx5IpVKORwOWO7eKIqyWCwWiwWWh4Jf6UrGa3bv3l1UVFRbW1tcXNza2qpQKHx8fAAAERERRUVFPB4Pw7AzZ8709vbC+ghxIRAK5/r3799PTU0dOXKksrLy06dPOTk5Go0GRVHmkvHx48fExES1Wl1UVLRu3TqSJOFXnU4HkxIu+5WBjBn9UBQdHR2VyWReXl4KhaKvr6+kpKSnpwcsXzLgsqysLLFYLJFIDh06BHFhR1vRaGVldf78+f7+/ra2NhhCXC5XIpHExMQAAAiCAADY29tLJJKKigobGxuIveYZhhE2m+3t7f3q1avx8fHQ0FB4huHh4ffu3YOsQ5Tg4OCuri6hUMi8WcGemZkpLCwcGBgQCAQqlWqVQZAqhUKRkZHR29srFAqZ+Wltoy8zxpAk2dTU9ODBA2tr68XFRZ1Ot2olBJJKpampqcePH4cxAwDAjS8NarX6woULYWFhYLkCMtMVUxDHxsbu3LlDEAREXYPRjEFQLaykUqnUyspKLpfDOFwVEvD52bNnTU1NcLICAKx0KahieHg4MzOTYYXNZsNQYRRRFLWwsGDsz5qth2qZFpGTk2MwGKDpBEGYmJgYF3IINDk5CZaJXrmwMbzCtIOJMj4+bjyWMGT8TqisEgYX0gl1fvv2bWRkhCRJ5vrHLDY24ye6mAcWi/Xj/PCHxDi7cBxns9lrLACrOvlvlpH/Ffe/zBGM/AcUx83V6WxBFwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AN/AN",
        "sumerian_transliterations": [r"part of compound"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABvUlEQVR4nD3RQUhTcQDH8e//v7e3p0tHWbPCFwYbCKODhRFkMoL0preibq0WidCtokJTpAgSI1ggWCG5ImcR1siL8YJaZjFzqSQLqZBalgTx1G268Tos/d1+v9uHnwBAb0uZO+/EARQALW33p2xzrEV9UF80lNBh6xGBhNLL1aXpqcQc7muKhaT8YePEAZK/2dH18j4ovm+3Smrr/dmctyfcBwhjtC1HTdAqMyPDACKyPTOWzPrOqb2GHUDJC4qdqpZHL7EJQNn49lKGgw3dZVtSzwCE909Nxf7a5pXqoc7oAADO/k9Pr3PoLOX9xwDJ0ononhgC5s83HQUFVjoq06zm4McZn7AEAJU+b1X03a91Hbu+GBPj7vUqg5saY6/3gmNbYTg5X0U8BLaLAVBwXamLeWeMaYpbMhGQuHOj6mn1o+W4SvciiIHWpNAvLHyXm80bAGL282AiWxT0O573SAGrygcz9GY8u+QhfdgOwmT5ye4NeO6+GBvUVU3THKIl/NfVdPymU3XVnVoAYN9k3AgRCBDscwOS9+1flx8hJb0jXRUgyT++7SmwwiMNhSuHF38WDPfE/29frTEt+AebLJWjXwWsDwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AN+NAGA(inverted)AN+NAGA",
        "sumerian_transliterations": [r"dalḫamun5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAUCAAAAADwndHIAAADFUlEQVR4nKWTfUzMcRzH37/v73cPnSu3e2rumLg7F0e10IOo1LmaHHlaNqeIPwptR/QH89SRNY8bM1mmFv7wUC7EWB4aa5yHU1GWVjlhSUl36fzc5Z9GW6HN+6/v5/P+vD7ff94fYMTSFJMhvaGdP8or4vwPHhAuGx4nFKH+uYcY3679VVCRgt9O9KPDlWoAEGgROg68mOHwjc7iL2kITgIA8PbL+NKB3+ObbDNLmyHhYkto+NE85daDa2CYNRjl0IqJ/G29B34EBqdF0KligGXlZ5QAAeYc5p/0Pe8JWuezw9BmAv+I7kfUioUZkwbhxuVkmy7MFRCcb68+Gtu1R8zCI/I9NB0Ey051zGmq6Io3XdyuvmO7Q7MFjt4XH5nWnXlhAzBtzEiVlImaHtgjbghf3M51WHfK+wRZ3W1KLmO0mcIXt35Jis919nlJUOT3/pVuEtCRAaFhQ9qVKjfkcVHtFg6JUMj8/DlRdfPi8uxgc3wsrVl9QRVU/bmyD6E5kvr8T5Q3detuZqXraqi6+lgzAIRnyouEusbrDkA9P6anBVE2V6at3Idy61MaDwln+HOZWr3e3iULcS/n9bOi/imOrgaZY0zntGYA43XdTF7L5hoAaGM17qoYmezhG/X3Ooqf1M66Hr/SpzBay7W+ZPlLqvI+DKufFKb0a2tU9MSbOucEvfhB/nulwdxd/qgXIkUtPc3Z4ZLsXpXw2r6r/OvtRd+e258ziePNOkH2Cms277657umnKvXbhva5d30SZ9WXVnuBtjNnoxemP/aQp7GkRKsh9+Qam3tfbcncCpj9Ck6QDyRSWdghaMgxxqePiiGGnrGTQ94tdVpbtjz0AgDYyk2WCSZnYGePSeerWhDdvW9JbQlXqb0nPn4aABTPpvrl8iDOFnGL1muS9xaaLdNnM4NCCTAWoeaSdYrJvldaqKRUgOHmAUXGQM7HCaT7eQBFQ5WAuM8XHAVDDoAAqjAgdhRfCQCKW5drkn+7QgP9651VbR09XOYHi6fgSKTDW1JH5r/ov4kuCRz58NAz93R6Ro7/BAgKE8xpLtWWAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ANŠE",
        "sumerian_transliterations": [r"anše"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAeCAAAAACgDakjAAAD5UlEQVR4nIWTe0yTVxjGn34tNxEoKfZiHYLOCQgEdCF24GAaJiFsEZnzLgQXYEEXTQDHNMviJWOToEPGXVpmppAQRpzRroxwxwHiAEFatg7WWqDFAOU26O3sj34UjBeef857+533nJz3ALQYh1SHsSzO21hFzI/V5JsV/qUqxmsqKevicFwy+yRkvS3MWBe563UIAMAtgyhCj45fcFwK+OvO6nevfbHIgbVsrxdPD+nmdZMLl7kAf6OA7906XD02Iw5xpQvsWWCwMwNtgHfZPyJ8lhJ8vs0kE7HKSWOPoTCWu+lg+1TpTjcATM+EiM1Rxc9D6RN7bG9s2sHJnL4BuBSZtCffenCx/5Q1d6zjeZFI6B9b//Bcl7mulL5mYOFf9S5I+rP1rhd4qflt5vIzXfKl0yC+c7iZaJuzPXdVtUv41ljiZIcfKCf38PzroVcuOTumDbYaSpwBuHMAd2cqqVEzobvJASWW+1mJKH2t1WCXLGQBwB4VEa8BGAdKTiTmJgDU/tvPlElCcJWn7QAAHQOl68AUbAtKKrh2LQR2YWVyY5lXuB1CVdrRoUgAwKF/TdWfelxt4AEAPsntKBQi+pfGnn1Iyt2bMdR3XCN+X3kmMCD5kfgofZ3skY4nd7JmImk3QnrHh/fdSB7g9pN+UrINA7cECnVjQYZOsfTsHzUfjqnpIbVBAFhAgyo/N+3L+TnPgOhodXGhARRhE9mzTqcmNqGJP+Y+SP09Ju5gTqVUDQDw6e79KkdaqTRVhQGAQhLTtx3A9XLbI6f0iwD7WjORllAAoDj995WUp2ZBQWoLAIAaYB4IF252YNqIX+d3uwYd4RomNvJYAECaFco4YnmYpaXnQMk/ceweK1BuI2ZV8e9uMqg3/JY3SM+j7uJYhku6hs4TL1ZTm8aeQ7u+YcH+/C3GW4+UX29ts20Cxxvj4iNWU17+Xu8OwK7/NuC059zdgb7aq/trKtwAP0MUwzbzC99XR/wQ/PMEE/85YNA19WarcVhUxeTxRkbyBlTqRXOOSIqnslN1y79ErQbPp5JJwSR002u3VHRpBNB9XvBAPaoFgPrxD1tncIFnWfGv4BWhvdcyD0jaTXxNcZNZsJUbW6+nk9MJlgWgGy/oPMl2BIDB+DUKHwdQRaZMvKyVPR6XbWjQjDEo4c4K1snLixZDy4+rEOD46jT7LPctU4t93r098wGd06sQvkFpDYbFZAGF4BDXGtkM8eDqXoGs0N44FvBtuowYZwkxzE4vGh+vfblqZY86YgbYyX2JU0wLGAy7WO7ZuTcTJgB45366zjrkTqHGbvJmAgDwxegEbZn17FcA+B+f4o+Nm2RCOQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"APIN",
        "sumerian_transliterations": [r"absin3", r"apin", r"engar", r"ur11", r"uš8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAXCAAAAACkWak+AAABGklEQVR4nHWSYZGFIBhFjzsUsIIV2AgYASNoBI0AESSCRnhEkAjviyAR2B86s/NW9v4+czn3GxqA95CoRW8x02oA3qetMqzlOMrWAGxdl3apQS5iegUgklZTb9L0+ao8z2IBXea/zPEGBWCkP7ckAg/3CCidYPewR4FHzZVz5PeV8rByDlRcWw8J52K9BFQUvS2i8RGoj1Ni+/kVM0j1QACYFzCXO0dX8fkiYzbj89Q0TYM+KtMaqzFLNK89iFCYVj7cu31BmTF8A1gtADaHDzELKBMmgDxEoCBD/tQFVPAwBtpZJ8Avte0ecDpmjQGqd1QAabRxykCpITeTmC9lJ8M/TNu2sl9L8xO5/08XegB0qgkpgG4KVZE7P4WvgLOULm81AAAAAElFTkSuQmCC",
    },
    {
        "name": r"ARAD",
        "sumerian_transliterations": [r"arad", r"er3", r"nitaḫ2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAaCAAAAADgJ0EXAAABLUlEQVR4nH2TYZXDIBCEp301gAVOAha2ErCAhZyEVAKVkEoACVQCkUAkzP1I2kBDb/7tvI8d2H2c8JYsT3RkERdoUznJ9zgkkmTZDU3qHqhLFk+3G2NOU7elpS1jfdAZjl3SM++FWq8y9dIdR+C8FWbG7wk3lf0BFYNmHBRQIIEfqC4j5QjigIaiKHv0rni96uoCXu4LAJyD+hf1FnF1c5E2entBoNdQUxkIUIDLrEPs7DhGGfLdPn9eS74gGpF4JBG1cXgsmLe6MEgnGi6XUbniZYsGh4/x7BgAUxLV6r/nUIEvDIApdOgPvMYAmBL6YIsBcDQ1qBwFlAMGwE81aMkUyCMGQDXRA/3I1P0M62Zexc0A83Xpgq0s28d9dKyU07ceTTTw7P5/AHjMwB/QVbaaKf4KNwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ARAD×KUR",
        "sumerian_transliterations": [r"arad2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAaCAAAAADgJ0EXAAABXUlEQVR4nHWTW5XkMAxE7+wZAqHghWAKaggZCF4IWQhuCB4IaQgOhDQEB4IDoeYj3XltVn+Sr6tk6fiDNWx+chEtw4zzu8qYrjhGSVLdCk5yV6CrxZLCVohl7C8lW7U17i8Gr3hJJpUtaZZW+iv3oAi/Xomf+PvBvSnpH9Q8h3HIkBGkE+pqlG2Kq83w5Y6qiTucwaZ3PG63PZrsewYgNztrFRuBWPK7gVSXlqBU28CUqxydMpaVHE1fO4EMPieXh/VRj8HFhPuKDIN15bt9/n4v+ZPBmw1rl9Of1BCdfzI4H3jMTK+Tqmy78dBnsDERSo1NqMle1qjbz7HpawYWDPB1VLOA6xxkKNbq64YBvios4GEzIaaiuGGAr/kCNAjaY0CQ34NNkCEL+YQBqd+DrTRmndVeIgfrTilqvPwMy2beyd3DdJsvwWO0Oj7upLiLMv5P42ANz8v/D/CY4Aff2NTWv0yYXQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AŠ",
        "sumerian_transliterations": [r"aš", r"dil", r"dili", r"rum", r"til4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAICAAAAAA3wTsyAAAATElEQVR4nGP4f9eYARtY9f9dKBZhpnsM91bdTRNEF2dMm8nYARXegyTOosTgYiz4fvV7dA27//+/m4bFgv//Z2IYzsDAwPB/JlZnAgCGARbn5p/XpwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"AŠ2",
        "sumerian_transliterations": [r"aš2", r"ziz2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAdCAAAAAB+5kiUAAAA7UlEQVR4nH2QUZnEIAyEp/fVABZiAQusBCzUQiuBlVALRQJIAAmshCIh+9A9Cnew80T4A5nJhCJD0UehJDb8k+FLpty4tRx33o3h/e5OHFTpO0VKov7JcTJKAIDkwOpG0Cw19wXDjsNKv41r9QwnO1kKar7EaeqqZQcbMWIL87lQl02UNqEpx6tUMd9sFhCCss0dBsPs9GCeO5eRzzlmj4F+oEMdotYkgyey/vWZsMWKgZ/2IHxCtD41p3vXf7xo5MfAzZz9Y+xTHTRiHirsussm8PO1yP6uCUQy23gFVLbKh/XLro9UD2tZq4a9AfT6lv20b7MtAAAAAElFTkSuQmCC",
    },
    {
        "name": r"AŠGAB",
        "sumerian_transliterations": [r"ašgab"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAXCAAAAACkWak+AAABKklEQVR4nIWRUXXkMAxF7/aUgCiYgim4EFIIphAKLoQshAwEB4IDwYUgQ3j7MdNpJtM91afOlfT0HpwreDx1Xp6YbOk3xjL2NHdCVm/93PRlyrXckaacFU5MlaQvBbHJS1Y9McFzu68pqlWS5vMfvT+KDHNXeWTs3ABm1ce5Nj0xJO/fTr7AGM/M9jbqdGCAYBBTgJQCNpVo8WNbDxpqYlbranJ5k9RcUqZotQPDurZibVGOPntIXlYge7uKKt4TmHeIqjArwyIDiO4TwHR1bCm3D01Aujlt7WqnpJoo6XaVIwOLFvtDv5BtjG3ANAakDSzsX1C0z1fgEpNZHGADYAezO7OzE9TlS/zfLYDXRNjeBz/k8Z1F4OPthzAe9vy93E9fk/sExn5k/gFvCKBqnDVHOAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BA",
        "sumerian_transliterations": [r"ba", r"be4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAZCAAAAAD/S+oMAAAA40lEQVR4nG2PUXHDMBBEXzshoEIQBQWCCkGB4EBQISgQzhAcCA6ECIINQYZw+ZDdOLb3RzNvV3t3X2wk0zgat6XQqKpqszdSb4oc5Ht99ltoUxli0riLigevFsBX6FIZogHwCpzoaBmtd+3l8fE7qvRaksGaCrzWt4tSHJAG98FjUVcvKmHVz2jaDJC5SXpMGMKdE4TpBsBIzj5kDBaAUpZ5Km7p+SaQU+X8XfN7z2eypQFwbr2nqKpqZ9/B2mOuvz/nixlk5azkO12c5a5ZVmZnw/+dHZ+dAw5WdDjiYOWYgwIvLSxw0eoPU+gAAAAASUVORK5CYII=",
    },
    {
        "name": r"BAD",
        "sumerian_transliterations": [r"ba9", r"bad", r"be"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAQCAAAAAAgpEAzAAAAkElEQVR4nKXPQREDIQwF0M9MDWBhLaCFSogFLGABC1QClcBKwEJWwu+htGW77PTQnELehPkxOKslnxK8VodgpxaZLMDmJl8WFQAoVP8FMbO6vt9YZVRRr08zMZgoFuv2UYf7FQBwAZyz220wrOH1KmSTXWKvqfWWTPtjFmrWHoLpeIkvlOP0XekPlR86STPoA3ozPVw/Npx5AAAAAElFTkSuQmCC",
    },
    {
        "name": r"BAHAR2",
        "sumerian_transliterations": [r"baḫar2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAYCAAAAACHXxGzAAADv0lEQVR4nJWTf1CTdRzH38/2bGzDMc1tAaYLTbBUUjkh1ELOxp16FlxRVxxKnh1FKmAIHmDkNQMLulzAyeEp5+WFp5e/TslDzASc6WxMG0Nk0piCgBAb+8X2bE9/PAu2EX/0/u/7vtf78/ne5/P9AtP0UW2wc/gUfzo2g4iGUXGQtZ/eNwPMgqA+PcBZGy9YH0x1ZihEM3W7TO8PnzrG3vv6RBMvgOA2FZTQmqJdiXOmPDKSCQOfZ5upU1oWAIASf7n0Kj9xX6V/fMPPA2MjktV9FtOT7u7uHjcASBp11/RUJAlYHil/+u52PwugySUS0cULC8yFwq+oyfSKb8KcOTd5uxNqbfEJG8VW4/0O7ahFvyvZKwwlgJr0/pYzKgbNTuVlGcF+o2K8rN2XzsodFM66cc3OLstTgcWdHRf30iLR2EPbh59EKg4QwJWEuw0eNsPO3lNXAQBhJVuOVzsATmhJsuJcwU7bBYp+UV/+77xfXrwoap1LWl5Hnjcv40oyfGm4hF14M0oboy66WpmUz38rJaQ3vRent/E4EyATQyYYyqvTAamnzxwHeS7DQRv0bmZymIj2YCzHTm5F83rFSV0m+0rOKDCoTXu1iaVf+orGb6APTVUusBqfyobsbHgZcWgCaoWo/AHwd+FQVo/3x1EAzlbKvCoudvUKAJifGQYAiBpRA6Sj0xEivTVOMCWpCQLQzDUBWKJMVhUfeQYA0FoWNpjQuYzn5Mqqx88CABYMEjRI0Oa+0JgR3+U9fBqgKALs7QWsnvAKqfwXAPjDKFsz7BVHiJybDjx6zLMCwLw+GiDhDXfdttMe3xP0AiDglpbHftHqfeF1+Y47jQBcv338fH0HWRkzeAk/pP55FAA7+h4AEiDnLO+30zQzOg8FUG7524/fNQJP1cc+ODjSDODyZk6hE9G97e/ltbXma+4CArGBicP4bOXFvyxMe0uKlVwXVVpaw5QzH/HUfNoC3BJEHLpBRRavnH/4hIelTB3GvAidL97V9n3MfRsBAG5ZfO6DYWtZ9eR+6p9T5jXD86v8HZlg+cKT2f1AbWzlZ9YwsxUAUETbO/MXz+JwuVwul310b0dV1SWu335ZBQY5kKZJKnqiTmQWFKHKw5brEl+8ZdUUTCKlx7ENAdo9ULxh+02VYefkP07QvrbjuhAAUNomCYD5Zx2ywDgOuofVA6a1fk7mnfPHmIe+NzcIfr89yAD7266thjR/h1B69viuSwbBRDiCNVc9VBfoiOqSplEz65Bt4/+gp2nN79L/9P8BEnRxZUblr6UAAAAASUVORK5CYII=",
    },
    {
        "name": r"BAL",
        "sumerian_transliterations": [r"bal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAaCAAAAAALEPoUAAABM0lEQVR4nJWSUXHEMAxEt2VgCqZgCqJgCqYQCqLgQggFB4ILwQdBhbD9ODtOZi7pdb8szRvJWukDl1JsGxDitl0zQ5VPLX+jcJWqlfkNFAjM3upbKFBY6GefO1RpXA9fukGFmhn3cG3XqDO6xFmV6fMSLe7r5zGi2B74BrWH5eSjq6SHjLqlBXq0YWA7OukrrWCyUKNAyZoAQMkio6Ux2QoILfRUYoYyNjZVXbkYm4qIKFsAFRA2W7rDkUhE7IsPwTie6GxJbeQKlIWmHlioZBYASGazbokiIiIL0cYhFTL7OVpqGRAy9VQwBa0PNNMAkGkNEO6jGR10RKsAJ5hh98xlyzcrRqburK81lRvWVfrDLsgbFoFlskj7MbyUMh2KLXbHQuTYOF1yT/j0ycv7faH/sL9/Xtub5O0h2AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BALAG",
        "sumerian_transliterations": [r"balaĝ", r"buluĝ5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAeCAAAAACk+HkeAAACJUlEQVR4nHVUUXXkMAyce68ETMGFYAoqBBeCD4ILwRS8EFIIKgQHgheCFsLch+NsNs3pK0+RNKORLOBk3p09T4tWrtzu2g0gJCUFAN5Of+o1jDMA3/fHz9NVwvygLZdJqbOgDw5/AADE7QEAQe738P7Yai9fa11ve918S5/fzyokOxu7aiMn0EKfmQ5QWzubWQa0dwfAFVYAQGZN7ON/LIN4PDGOzLNec3AL2Sdm6GwecFs/KFMovyNHa65wIbuWgWgkVdU2WNoMfbIN1nwlR29uYREam2pjAIC3Neh6UB0AsH6ofq71/qWCWB8fPxnr5wOAxRUA1EhVVdWjKsEsVPpE5eKAwtFJ7QDwJvgaswGPSO+qH3Arwt8bgBVZfgA4H78BsE8RXtSHa5YymwcACI3DCgB09iwiIvKaA9e2iKFc9kgsg5zOCjzlROO+BYUCwBnJKA5GjeGCW+Hi6hxzJIuILCydJNhm1ItujdktYe7R3o9P7AnGGn7lZGth7OhIimQVEWHl4i77cQuLQ2FN7GmbTwQAt+vGkl50k25x7mhBsuaQ2CMA2fZ8jmDnVqgeyKykagGCNSckqdq2kLgfAAoA37ahFLKNboJZJnsppe96HXOi9XkaEjWM5feNzADclH6aT8xxbOQ+ofm23XgEkf41J5Hk8fkDi0eJm5ImQP1FLXGxenbuVm1cjbObDBfRm8lvagBg9v8UHKgdb+/tos7R5nn8Bzn4oc/E0dMvAAAAAElFTkSuQmCC",
    },
    {
        "name": r"BAR",
        "sumerian_transliterations": [r"bar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAbCAAAAACyg0sHAAAAl0lEQVR4nNWRUQ0DIRBEB1IDWDgLWMBCLWCBSsAClQASrhLuJIAETsL0o9cmB2ug87PZl0l2M6MAINj9tcM5PHBR4EcRgxJTjNzMyJG7qX3GWLjRzxjI7Jddn7PgKdlh6ET/Mfg0ZP09D0K6APBtY8yn2OoEu25oa75PXPmkoj9vtPbjtwXOmqOMOSOTVWq2M4mfMonvvwETBTZSvwRiSgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BARA2",
        "sumerian_transliterations": [r"barag", r"šara"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAADKElEQVR4nFWTbUxTdxTGf//be7mFliKj6wgVFUH34maCUWBxuswMpmhCDFncPkxMzMw+mG1Ktuk+uSWLYfNlJCZYgbBMsiiO6OZGdGMze9ER1412iOm4YBHaSW0psrbQlnLZhyK659M5z5OTk3PyPHAfpVpb90TrlPdG8ITzyAIrL1S9jqrJidhfycBM5r+NSBlxMMympZpsgMy+ljfu1F5t2RveBvKBt3YcrAQJoM6xAZi+GG2d6r6cap7ogdTt+s07QyAA3qnINSWg0Hir1G0za6U3EiBWu1pOz++3FXl+iwpRY+ksObf+sTMlnUGJ2SV7fk9vtyx1flokAYdOLtLy32vL/nsJQM7wSkCCsl/06kYTIMuSLGRFyCI9KNJ69zFfaF8ECIUTfj0wmvKTv3A1uzLJGWwCoHCVVK7alooy2/l1YPQWAfK7mz4YmvYDMLqj+hPuwnVT3uHBXiWrdkIgX36kW1+8bxdT273rj3+pzGD+qL3Xa9lSkjRviQnQetpf1OqffW6tumpwoGM5BY6Dcnbyp6fylo+UW61W2TJ4UVGyckH0l67d/frnb/5xCumWfro/I2d/QiB7Uk2a9ZUqMaTFI1eufNHRfAowjl0NGCpvjoG80fv22evvd0lzc0C17s5TZiCrwHnTmPAEBOJssFgtGwoT3hu9EF12/MJ+8eGMuVmt8MxVOOMCXL+e3z1y7LW6WrOhfrTDhqnhgGSZvFRhf3J0o91ulwt8jqHp/h705OzRRZZxYg1Pm3Ut+7BbMb06LRCN1pqAfTwqIjU+LGow/dQzuhLQ6zrDINwDP37/dcMPUrJozViu/ighs2Fk2c4j7boy8PwI8PEKcFUB6zxfjfmcyW8C/i7fBiBn+HGADNgergR4YfRk6+09npamOy+xoEtJ2GpZbDQajf3/uK7d/W6871rEpSiKokj3PXBo5SYVQNVixX3FU/dWuBMC1MJtWtp/+c+0DQjm1Jf9/syuzcFh07cRAWIyMJ+P8RMOAKX8Z+/qz574s29Na+R/+TkaBkCVFEVSJVmR1Ae6BIR5CEI83KXzM49UPH5PD4UMMf0B9x9PlTl+G+nafQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BI",
        "sumerian_transliterations": [r"be2", r"bi", r"biz", r"kaš", r"pe2", r"pi2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAABaklEQVR4nG2TbZnEIAyEZ++pASxwElgJnIRaYCVQCawEKqGVABKohFZCKmHuR793yz+Gl2SSAHC76vpevy4l5fOeusEC+SFT7Bdl2TFcpUSGj5uOEVH0WXoE/3YqD/lkwwEDzPA3H1oFNHOw1p60voUFTGn6c9JR4l35pmO3J34Q+TUdhzrOE6BzC8BG1TarPvprkEgpFLNsgozffVhdSGKwxroagO7Y3TUW0EIhybVzdhR/yyWqjh3jtvdS7jIHQgnTIajCCoDT02yArMywdmpu/fuggukBwJNc/Lg1GmrulJdxbaujdKrIQiEQsBtmyzLyoAAUGtSb6ROmItMyCRnNcoLt7RzYke8n6/T5kPZ8oX2uNVUTGu8nBABmCbcMytU2/+7DroBeez0bAOt7MCizQkTzPoVOlNHFdPKmE4sNvI6IDEA4Y0AUM6YLVQ1t+2X+ZQqaK/a8K7JJ6K8YAGAAgPb4NjnPFwr/LY3F7n+sspAAAAAASUVORK5CYII=",
    },
    {
        "name": r"BU",
        "sumerian_transliterations": [r"bu", r"bur12", r"dur7", r"gid2", r"kim3", r"pu", r"sir2", r"su13", r"sud4", r"tur8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAYCAAAAACkBEBmAAABJklEQVR4nIWTUXnEIBCEp3WAhVigEqgELGAhFrAQC1igEqgETsJWwt+H5HK9S0jnaXeZb5llB+kVzuqhtuH9UJndiLtiKo84wLCzJKmyh9Gs9StugnC/AvOZ6YJrdSMnIIdIHlF9ZZGtx7kb0BnqMLClty2bmecOWVM+exTvw9xhliQtJEmpkzxtpDxUkqTFoiTJNZJhYaRmwbtifstcwzCKfya97ex4mz6/75mrXh9z1O3r56y1M+KfrIGfGk+wfc7ell3FKiNDTWdvkqw57ezQSAb1MOE0+ZA73UkbO1RInrM9VsD6um+PlQqQFUhngxWKyurRCFCz9bGlE/neJjTM+22d58i7RaWFcmlRqT/Mr4Jdml/RHrGzf77Vi6ih949wbei2Xz9wyOzx6XKfAAAAAElFTkSuQmCC",
    },
    {
        "name": r"BU/BU.AB",
        "sumerian_transliterations": [r"sirsir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAADf0lEQVR4nJWTf0zUdRjHX9/7wZ2e4im/kugkT+ukgkabwUGWSKM5WdkKufIyZFFrBWyIkNhkoygnTu0H1SrksI0JEqiEUhzErMaPNFjswrABk7MTTDwZEBx31x93h3fQFN//fJ7n+35e+3y+z+f5gJdy66TcveLWulbt1Qt3i0tAW5ndB9yr07VEhwwtkFt/+I+rouBIUUhmQb8GUB0vsnXJXlnotn22nY9o9Q1C0RsjAys3Xcc/ZVf7ja2iLaLI6vE7scK6l+LFykr1v1koleq3fzqu5JnT20XCsgPtn9mMWr//QYJV7kAekdvSXfm8csPg3w8gACjy7xtWHewE0OVHtEotv1y0A86AgOZeD77jnZoG06g4Svu0xmRs7ANF81giEoBxQ014eicAl5bYmqJSIxpsAthX6c+kjrnxb/W7N9lnApZYat/tnQYYv2ABiVwqqOJTCiZ2OWsgPHl7U0beifg2BwBrYsOqKgeuAeCoVemDyqfyqxye81yfBElOokW6Ob0eUU2c5aEoTfqU+pO62RaN7Ntj+NMkAGD3Twy7+WK/VwMFQP1l1xe1MlAcHftn78VyQa64VbCmf6BFH3qPW0WWttXezSzOAyDbmQ1AQk+LWePT7WedH3mNYYIjxcd147JDCa48ZnRI5lMQmeZ9hdFtwfNwCUwZhl2502b28THfmPbKhmttzJUIHj8ZDaDM+rRtscjHfKoxzitTFkTNx4N0R4aDAe13+yfOrXjOxxzUVOeEzP5P4NJ0YS4ueT+5x5p6zIa5PvDKBnFR83J144zHtHZ+81ruefcjnIkqC8/82DEHLykNW78150M0j31wTByZ8bkp56viK25zBvXErz2XpgAc6lU7F5+1lvviAsDKwpuDSSWtgCQzI7x36uezI3aAB6v+Smv3dK/siZOr44JPFf7mQYut+10464zKje2u6PTyPS8kDpyaFMARtra0wlOcXdJx/vI11cMRHXXfT8ziSKWLgrb9+Kr+TAyg2NFtmL5s2KxaJJfL5fIVIeLZY25MCgLwe7Sw61xBGLjHZm/D4R/Gt8C2obd0pd3W5Jc7fGdrvpal1feWJSl4Lw94stp4osIPQludo/uGDhAYegcakMYe+r0pq2I3gPSg/U2ApWl9R02q23O3FPK60ZwJgP/XMa5PyZNG8W2IORJi73cFMvfDEJUWLpx26T9wKjHSExhRXgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BULUG",
        "sumerian_transliterations": [r"bulug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAABKklEQVR4nIWTbZWDMBBF79lTA2MBC1jISsACK6EWshKohFhIJaQSqIRBwtsfFMpHWd6fJHMu896ZENioxG2Fr2lTAWCp2iFcXmvI3B9YY7/1HprUySVXdrXHUHGrlbBOx50qxdwb0Pkx1ElXANIKqpaHWjIArCyh0i0b9fm1sVJsKkY3mvlETt5uoVZXcG9mJkqvKZuPUCsZdNI02xyzlMdWtSew5J3DZeCn6Yf7E6ge3G+xiw+AIWTq4buu4AL3erA51AADAE/gEcJoIPVXe3n1s9eo4EXAHBPyPMX3AItqiO9x5azERpWvS9m1/3uCwopR3iEQl3fRav3JJ17S/0SVFfMnq4VcDUfM9C5uXI3nSZzgJZ14gZWzzCPUnEN9OWUI2j/2neLH1H8ln5sVmB7moQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BUR",
        "sumerian_transliterations": [r"bur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAbCAAAAACov6uJAAABIUlEQVR4nHWR0ZWDIBBFL3tsgBZogS1BS7AFU0K2BFKCKcGUgCVICVAClDD7gUY9JvPDnLnwznsDnEqPfC0nX9EQo7lOrQZGmfwHUZHFuSiS5X5VE4kSZdGD7C9HXc+79DpmDQcYl7Y2U3TSAtg81fvK0ZMAjGHuqi+fugI0BvMsAKE3r6oQOu+7AkRpr7n1Ei0ojw11YIw6QN2FxoTCBvdIJbW+Y5Hhqgk+Sq+mtPo8aRJvfm4s+lUums6Mj4TkDz6HulXvoqyVd+So2XnMAPSbZj8+/wCQvI2cr6fN67KbOS1bvGrX+tdtZalQ0iGY9eG29RJPmiYvekPNbN2aTwN6qt9TWQjttPYz2rMjfsww/yqllFIPMOWA4L1q7p5z/QP3xZSV/dWUkwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"BUR2",
        "sumerian_transliterations": [r"bu8", r"bur2", r"du9", r"dun5", r"sun5", r"ušum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABWElEQVR4nI2T0XEkIQxEu1yXgFIgBS4EUiAFHMKkoBRIAYfAhKANQROCHELfx553Gdvjcv+1eJREA8CqmfFrVdZfsy2m/rCcfTHKqS6XrPh87ps0knZJd6bFxHDbLunOjpeHe70dAtnz93Rv2FdfOWOMCEtf0GTsPMdKLT5rjvicdgrPhcAL+1Ld3/Pb7e8xM1qskR9y7+YcH0NSMScAsSiVbAutVBZASStnGGLcSI5l+BLcNlSOoLe0wkBn2CBHfUTT6ERhSca7nrAEAyV40viTkGrGbQewPZrmgeO9quBtP/6XpEuCkuzpPHMLSyRjOaIYvcP5iPUD7uxS+EwJQHF3Bfi8sDucjA3QU/7KKabA9txPxZwlPAOQsrAwNnBbK6BiBud3D0nZTD/ByXnxV2pwrLbTGZefMAeXlmLU2K5YoJ2aik2/RAForC6d4voisZPtP0wBAP8AlOzx5f6utH4AAAAASUVORK5CYII=",
    },
    {
        "name": r"DA",
        "sumerian_transliterations": [r"da", r"ta2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABWUlEQVR4nH2SUZWDMBBF79mDgViIBSykElgJRQJIGCQsEkBCkJBIIBISCbMfsG3ZQucDOHAzw30JGgzXZbNqyKpC0Ow+gHVeZVJPFUl+mdMlOHazpG+QFdGPtaqDypSpKUME1yVj+vjW0HVpAVYNomKAac3TyWCjAqDBuL8J+VRdBaiGoTjmuQCSyhm3AFQ9UPoEUK6tqQBMGAHsu8SRw7gCfNqYCjDlFgH8yXfjWwC+gGKay1ZSP90k77m8H4m7Cl4eHnsutW+PKp1sqWxcndoCUKjDEF8ybO5z88JFF2YAm5LtDv362Lz4UuyWi7GM82Hs+LrKh3q7a66PGj+q9ebxBRS7e8bbvx1pR/4Gr3dENXvvfZb/sUDIdsvF/GBYxgKcYNyC3R4mVd0Bfwbur6sU+65rlgJYJI2n6OO82Of1gjPWL99baD7215wz/XDd5snZ9uqXHlWAXwquzqby6n+vAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DAG",
        "sumerian_transliterations": [r"barag2", r"dag", r"par3", r"para3", r"tag2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAACYElEQVR4nHWSXUhTYRjH/+/Z0fIjEtdaF5kU2oKwWJrrQ0JFCSOolCCMsILUILspMISgK+vSgc1SxCzpwoIGNdJACGvOItKkzI9GHly6D9oqXefsHM95u9DNc5Z7rt6H9/c+7/95nj+QMIi+1pT4FgB06SdH3uwCALCJmCOPw+9fe1fzpNT/Gbak12/dtJpbrJlrVGJsb5f1sDkLsi77anrLbyVeMp6UF0wrAMh4YHT3Nl42uwM6omGkSGTP14scALapY2bnoxO+0c3UJakhxj9HHNeLe2SAtRectbvOtATb5JfuJUZFMQzkyoYBD0Bg/tC1lZsp1GdlBzwRkaq/kzP2VT9dAovZ8OjBXN5H+IdF/mdBrSah7lLfL7DQyYNzdz8PH/3YYkzxjPzUFILYmedUCIxTFmnAH9rwybBXTB/3Mdrmal6clhgADOsfdKeWYDLIHdi4IIiqUBxl+WR5X8lcf5a+u2ZdZz3XNqkpdOd446mVnaZMB/fXFbkqMstzOCF6/3c+gnP8MUt07wSTSWOHpicM5fPhWFcBURaclbdWGMpkuDuumK5dNjUN8bGNMURoz7MNx/yjpL1r+D421d+lkWMyvmr2qjymhDzJNq8GwQ1vsxfqcRjSmDiktLT1BzTMep12yMi46exXtEwcAVRvvx+ClomPHfU9QxQAAykhUyv2SgDA2p/LsgJFphQUGk/nl3V/AQCwi62R4mBK9mG9VKiXzKGYfyht/OOQl8+371FJpIpAqUBpRIgFv+itWnnA5lZYH3wDCAWhULkwq322L9roxHndmoK3XLBEj/8A7EMGYeQjda0AAAAASUVORK5CYII=",
    },
    {
        "name": r"DAG.KISIM5×GA",
        "sumerian_transliterations": [r"akan", r"ubur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAAD0klEQVR4nJ2Ue0zbVRTHv79HC608SlusrcJgj9A5KZSwYTTrQthD3PhjmZgMtdHo2JTOZVs0cSCgqJkPcI/4GEsmmdNhHG4QIma8BgsbdWyywQCZPErpAGmlpbSl/a2/6x/7bUiiqHz/uufc8znn3JtzL7CgjtYyCwcsrHMB4/8kJPTcmql239YtFEzPNylN3ro5l+i1R09ePP1i2H8u/UjZzDNz1gsekvcO4c7sSgv/h3gKUKXVzHWe/Mb3lUQwEr5LwujYpEQcVE5dbbt5829wdocrOTvFIqLumvzsRNp5h9B6QRKqz/ziApEueVxbGDHSfKXeNx/eSx1KUEqYiW6fcGLCZeTXAwBCS/aU1l8XUjFhcu0rWZPcjYbGHnIfLzBRmvbLwdGM0QGvUD+4ymdyApAW73NsuAGojjRUBAkIYmr50pmn0+UTbc3NU1wQwFPflLKea125HofK2uIWUv6Uv6KDQJafZWmyAvBzB9fXOIGw/Bhb+pvnkGpY+5G0+3J9jyv2PeYUS9vPvuq+7d4YdZawFABwQ7t2EG1xXM7eKQ8AzunRhQx7yXMSo3PrkS8vdXSUhWxKXbt9uv1J7SfjNOhAS9tq2bXV2XEsz/M8z/xm0GV+FfFy37L+ACA2GiKuWkPlilsDA+HV3HGTGvDXFKZv6nqJ4X4MsAAz06ZVz/YtCdQHAABxXEXUsU99Sr8XALstcTzyQQDhy76V8PaG1DX7xwGoNq/8ovfACFgANGPl1VNjnUQCAPCMyx8e8QEEALwHzDI9DUB0a2WxoZVZzgUBwPBx3e4twxxYAKCdjoGmoevC3R3+oSHnff3bgVAGAOzwO0IIIOW81kn1+s+qpgHA/MG2fX9oRHdx0DxnHhPoTFmlvaSlLL7AGQ0ADMTDfSKaRCaKV2XV7TbzAICR/K7CwegIsMIQ0MF7s2A85QDX+GzpYcVD4gBAkck1IW5L1PJEj7F9vwsA6Hh9ij4hViPd0MWGEp4QQsi9Wcq2XiEAfs07lG5XW3mAXCyyER6RW3Ppz2cjFPoUnS6c6++tPS//ens5WxSqkIZJ74iVPACKfyCr4ncAgGWPOOPdziqbt/J5ABBxdbGmdTsfU87aOltau30A8FZ5LmXWNC4dVfC0xU8BgK7mqF/oI/l4KvpPtGpag0pFbNKKGLVruqev8+eZuSdT/Dp14UI3YXiAAQCiiD/ZfX93y4noCRflHPOrVZx1sHeoYxzzJS/CxnkOWvbXr/FgsE/fRGzHdmYuxSIUXUVKBk8/sRgUAJDju/OhctE0TP5yyeJpbL70L7/sn1j1kZK7++ZbAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DAG.KISIM5×GIR2",
        "sumerian_transliterations": [r"kiši8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAADwElEQVR4nJ2Ua0xbZRjH/+fSrqeUBWgJ0iEbcwtMlMKCoFuEaDOyyYhGnckIbhqziQOczOzDLGMw1Hjr2MIyM4w62QwMdyVokNvoFIGJyMZtF6GUlksFLF3blfbQvn7gsNpEUXk+nec9/9/7/N/nvQCLRlkts7hg8bjk3vE/CY72fTOXbWNxi4lp/5RS5qT6hkR7Hq74ofIV2X8uHXHE/qIve9lBcooJfy47OfAf9BQQllzjcx6//5sqIiTRZ1UwjU9yYo/C8ktrX9/f4Owua/y29QYRNZ96Z83J9dOC9QIVLp/71QoiXfl4TOFy49W2Bqc/nE8djVZwjLnXKayY8GpNAwBAUrJX23BdmIqRhcSkxiY5bzQ29ZP7eEEupWxv85jUpsF7Qn1PrDN3BoC0aN/0pht+tZIOVqSo5ebWK1csvAfA5q+1rKOrZ7djOsyoswmqOs3aToIgTYah2ehjRZR7WdaaiOK82KdTPpL2tjX0WyPfZc6w9NTFN2xjtrTgi4SlAIDXZ+8iMUWrMvMtjvnuSmaJeKe1mpi6MhKadaWl4s2JT26/274x5pMJFrRbZ36uq+sx9toEDwDMbzlx4YWW1/QP6dzzu5FJf5Wcba5lZQEHmPTUuh8NNTVYV/jqIP+dmwUYe2tM+OzNle6Gefkq/lTwyVKnwnVP6MajWREht1RFkiTz2ePVz+RlXai2hqWv+3TgnRHQAGjGaAnix7sJx3EcxzkmsGLECSx02GUIzJZ8W7V/T2O/ddkTw5fS3pYi5eOxvJFhHiwA0DPTg83664L82IXGzPcSDrolwmXjHhl9S6xQF9k36toqh5/fqq2eRMf7L+z7Qymax0F7+Y5xgd4SVDVVojsSVTATKpg//XmraietnTUc7lTkBxe324ARTU/hUOhysIJF2rOwRTvOTINvekl7TP6A2A0A7haCvrI1DjI4/GzECd0k6KiE9QnRkUrpph5WQryEEEIWVrrN+DMBcCvn6FNT4UYvABBg7vt6Aqj0GtOGRFVcIH97oLY+5PT2cvaQRC6VSefECi8AyhuQcep3AIBhr1h9uPv8qOBKFBAgi74TdWLF7Gi37mqvEwAOlO+mOpRNq01yL21wUQAQV1PmEnzEf5aI21/W2e56FPJI1doHI+3j/Xe6r9l9R7HoTaqlpZcwXoABACKPqui9/3frF6FmK2U3usLDeOPQgL5zAv4RcghpfgN00F+fxg88NxOayejJ17esxhIi9DwpGarcsBQUAJDpnPtQsWQaua5ybuk00n/6l1f2Ty37iZL/8z4lAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DAG.KISIM5×LU",
        "sumerian_transliterations": [r"ubur2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAADmElEQVR4nJ2Ue0xTZxjGn3MpaQsKlDJdBQTUtBlOqYtDtsVlYyzDjP0lctlGZhYjGS5eyBIzdHZhJm6ZTmO2xZjMujHiHC5KiJdhh8wMqqATYQPZSlvLrUoLpQV6ek7Ptz96WD1ua5jvX+c95/l97/OcN/mAmHW0mYktiF1nQ5X/k1DR0Wfm3NTIylhiWt5Suurno68U7zzx3dWGsoR5j047FNgY7Tb6Sc2HRGisylvwH3oKWJTXFHWe+973p4jU6L9ZC9fYfVVcWDtxo73n93/B2S2+3JI1TgUVacWgO+9Hj2R9z1qca/zVB6Jeus6wd6G9vaNlFgAUtU5WsPYB7E42R6/lSt29s1JiMlmwpgUAoKwrPdDSHTnqj9YEjWH96q2+TssvvxHe/7HD0Qhg9zZKZ7UKQy/1u3hpfjhndtskALVpl6fwtsxovsWWGQyDYRTKjs13gFe+PchO37KXT3uyh64FJP5i7YougqTaYudPLllOcTlpOO7OLswvUHpTH/P7Mj5i6ln63sk3/CP+1zMawQIAeHvVFqI3ZVXsnJiW4YlvtdaBVd00k2eKK83BjmcNn47RoPk267rEq0+VLBZFURRF5s/1q4pOat/uXzYQkuGzZ38GmAOXDFzrYfPTPZsZ/nyIBRi/NUc3dXOp1x2RZfLm5ONfeLXcjHxJ4ohKkTf6ib4bUKaVGL7se/8uWACMYEtLHh8ZVUVk02OaJQ4vACLHwYCtUV1SlIUs4oulF9591cFH8jKTnvjWwW5JdeSHyxX7jXtDitSHcFCh5lBQ4+BCVHvnm7u8OoX0u2iRt45KmqKkU+N1bYey9kxkxMnC8yITrudWLrkeBmz7bR8Mpi4EKzmkw3OqynoPeMumg0eSJ9UP4srPhC5wcI2DyiwobHoyXacu7GGVRCSEEDIXtMTVSQDcqT78Aq+dEqN4iCkT+gYXGI25Rg3tHG5rEU5XHGP3KVPUCWohTisCoMT4YvM9AIBzO7vBdOPMsORKEZ8cN7xjBzcTGLJdRvzdGgA19eXUNZ0leyhFpJ0cBQCrmo5y0jj9iXwMnLjonwprUzJWr0hf7L/fP3D7egBAevVuADBtp65c6SWMCDAAQFKyvu79227xV1q3jwq4uMcX8a7BPnvX2NyXhOW3AECzDy/LVkMnPXg1mvh+o4UMH9talP3wDudTiWdInb35uUdBAQCvzQif6x6ZRlWwYf735D+r3JoWW/AXbK52byMLFmUAAAAASUVORK5CYII=",
    },
    {
        "name": r"DAG.KISIM5×LU+MAŠ2",
        "sumerian_transliterations": [r"amaš", r"utua2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAAD5UlEQVR4nJ2Ue1DUVRTHv7/fb3djd+URLBKrLEIyYDAE6MyWmUmUxoBOM8JMgEM1DCUpmWiTBawUTWmp4TDZWFOKbaQjaOJjGEEhKFh8ILoISPJcWJfXLuyyvH4/7u0PVomZouL71z3nns+cc+499wLzKv8CN3/A/PplKvl/ElJ2ds2dsxpD5gtm55qMctsLsy7xO0+dqi58bdF/Tr300GjcrBVno7s+pkLRVrXzP8QzgJe6ZLbysPdPn6QOI1C7CgbTgFQyrbDcrNE3/Q0uSh0Ji4/oEjMzJpnoU18ecpSeFY5zRbdGiCDzXbMi26WjprZsfC68k8kLVEi5vsZxR8eUj8osAwA45b53+etaC7D4Vc561e4etC5EbW9oqPxNeIRnbWeUOp3Q81KLgXfknw4e3z4MQJaToV9SfJaAOL8V9cNXsfdCD0jcV6dGTXT+XlFh4acBvPLTQZG9oSPBPuTfUzfq4EszA25QuGVu7LwzoebaBI7Ri4v+WLP7rCCMtXbfFl9R7pc31pY1jag+5bQitr9gi81oS1IVQQQA4Du2ptLAHL/EtDDXTS1yn8FBzy0WfFCu4STBGZdSNofs649Z9XyCVfdc0AETC5b/VfeMa/XK+CcIIYQQ7v7a0OgCRUpLgP6iRbLsiBrwXor7VWYvTXapFsVN6T4lmsgN+jc5/tKUCOBsumCltd7X3DdT/TL++OPfHTEr+B6rkNbaiWcHluxZPhSY4p1+/QSA07Z3vzB5xaz4pvmjbrAAOKFt2JU3PpDOyG6CssMMUJajkcvHJkHFKhkATj4zEO0qYO2XxvTuTn6mX254SF7RfttxHYfPlCflRWRPOZFp7kPLG+VQdJ//ERu+l5vXJxYCEcn7TKj7bHOGWSl2HBdLeN0DBx3tdnIw95bGL2sgpmqqGRcBxngHkDjZ8+uSDNURrxfUA92Zek27pwtEjgllpx/OQrJ2CFNn7h48LPUO2TnBMLFU7lEB3CXAtcmEVP/d9axfeER4oEope1kvcqKEUkrpw0GPN1ynAO5ty4skxps2jgFZvBLAJwTgWs9/LsTtCXPmW5svlIlPJR4V7XXykC2SCRIFAcAQ+cbj/QCArh1sDPtkcS8BxG29EMvlLkHhQcGK8ccaqqsaxwFglzaBqVNe8e/xIGzXJAMAoSX5k446VMdeROuxUptVcPf0fTrARzXa39TScG109snk7GAqKxspRwAOAKiH34nGR7vrCr37RphRw6S3F29ob+64YcJcue/F+jkO1u2vX2M23xJ+lfYefTvaHwuQazHNbf959UJQAMCmMWG/YsE00ia+lS6cRmzNv/yyfwJKb5z4+OEeygAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DAG.KISIM5×SI",
        "sumerian_transliterations": [r"kisim2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAADnUlEQVR4nJWVe0xTZxjGn9Nz2tMWytU6MsFh0cULEMfQbdy8bCFpVDLYDG5jJipmNzUZLGO3bMmybNkcyUaCIsskilmMIQhCtkUNbrpaitaWsqatQCcwLnKp1Cqtp+359sc5BZq5s/j89b3f+/y+8573/U4OIKm6b2TSBmm1PSiRzP/7cIpaHPG16x4F17yYuwjfu7bN2bxZusDFSjs8WbYQ7fCRN6sfTH9f/uR/+RkgaZVpPrxzvlBDETFYWhOLqnCfNydP2W+yXvY/DN9j3vJWu10pVhwODD3b4RHWyk/y4Tj5m8erSFpXtKlq0mYwWqJheTnVlBqfwCmuTkaaEHr+YLewqv6y8VLPeHj5MiOg0iRuys/Rjv1x6aJvAd97mMq83EY7X+u9RYvPDz7nrvIBkO2rlRdeB7Ct6WAHIYSX7zg1rBsNavq6uizBEAGQ/XMnFXf6pj7BmWgbCItHBndWWgDNe/ol3YemAeSdGVS5ZABh18TcfGd0W0Fhqv9C75WxWXVndhZDj/5Q5pruf+qeUSbUH/zzFStJq3757VLPXQBUnMbebAQArOxsGUBLC3T6DQc+dF7YXFA7wYDmTD69vb9Yd018K19FY8rX6oob75/hAFChd49TW5VcwtlwoNUOAHDXg8099NV4sJNjAHrGuBwx3UpZSMCX3Kl/zFDrToYHAPiLgHJXsdZ0LiwL3I40TaVLOWmtHoEMAOMfiNsQo9XECgqEstf+4gYwf/38n/a693MAFRkPpT8xt989HAQDALTXYO8YMou5z0fPVR7JqA+BnZ/QhKlnOGrilp827gnGMwIOOjBjHBczuekfjzjMVRnfBVYquIh9yhtFE+cbpTVDqTQY4YZSdGRuqOwYwd3G3mNaOkku4KtiLRQhAIFoZnKydFvWrGa2DjIKEtkV9FLYAIA3VtTls9r7AID0L1rlfg1H1IxcxaY/syIrj79v/vUzRd32ZqZGrZIraEIrWQoAH1/cPgYAsO1ueGG3wTYFwDPz0Zx7V4xKrXyCyYv1OW60XrMBAHuihOrTHn3amUzoHp8MIHzhRJ34xWB903r8/qPZM7vxOG9BUmrKvZkJi8tlXKi0oYw63/2Xj+EBhgJAlmY2XJ/P7jyaPM1PuQczi6wq7pbD8bdtNqqBSPwWpVEb7DLFougIsRZ1kfDpD8oL0vDo0rXPveq6up39f+fDVTLnOZshZWAk8cdp+z6PlEH6L+Cdel2Sxj9KuGSM8GQQnAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DAG.KISIM5×U2+GIR2",
        "sumerian_transliterations": [r"kisim", r"ḫarub"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAAD/UlEQVR4nJ2Ue0yTVxjGn+/7+jHKpdyrVAsic21xIS0oGBY1ikPZ2DI3JYiObCHLdGCILlu2lduCbiYLTnQZIySA4hhmjg00G6HKRdwoiAgKBRm3WrkUoVBaWtqv7bc/qDKSjWw8f53nPe/vnPfkvOcAK+rCdWrlhJX1izXlfxJccmlMVc+NvbhSMrncEoK0nUsh+oOwK80VSR7/eev1Z40HltwBA/vh56zt6tFoz3/JJ4A10TVLlUs/+rGSdRpR+VZoJp5wXez+M3d/7+n5B5zznl56MEJNE4vWsaCNrpt2lp65FdVXO+bAugVvE2fzNE1KhXk5fII4J/LnUtpus/PELBMrVwAAXPMy8hUDj2gGAAgPP/HuaInpvqJexT7DM9MJgVJpe7ynT8M497dvNqfPAnDLPanbe6+Nz9ONhU6sHRUmNnNcfGNSt89rWxoaZhg7gH3f5xNe5b2H5qc5t5qNTn5BntvOwlv+GnVvoCQutU4oUCcUxU2/aQbN0F9uKfXfFu3R3aJQ6YPKnw8nycmLlGGs5/BhP18+n8/n8wOHjxIQFW5P/qM/vlIguq12KB4qjR2ha4PTIJz3OWLLDUtuiCqpK6iKLJ7ggGSapt5oa44kmicBANRAWnhgjiF1eFO1NDjJGBPIjdHHuR6KOB+7u0KtrbsfmHGnsRaS7HcHmV+tHIAyKDcL5jqCddrF6jcwZT7F3+r8zT7P3S79VC5J/GJHfdZxzQs7UKQS8xM+GU56pbV2l6Sw97NH4ACgbIPrfabGxrmL+PyE77oRHeDw5ba3mUCRHJpDWqNCykXHom7MGCSTTSfEHvLfjieMMOAAADU77d4w1OW8joKqG8mnZVlWtyHbO6+K3w6VpQiFUsHYxajIvLspT36o2R976Wcz8dZJnYBexEE6GOW4k473rpzKazobkqn3IMUWk4mx22k7fUrVQe0vGzF+RcXYv241Q/4geyiAB46zCUj7015IuTwN5mZifgEv3vXja9/VjHpee6lJVvGnQ92lhrfXzhyFLiQyQiYKEri9/IDjyjpYlmXZp710UHOHBfAw7dwuw5FBu4FZMFnMFpPVhoVOykU1qglLknky/b3XFfSV5CKikPdNeoPM5nJ+EgDhcD9dVr+4TlBhbGXXT7NzJE/PNflYaXeeWCYJ8zePdw7c6jYDwN7LWUSr4ObGx34OUm0hACC85oLFWYe0eAv6S2sNenuAn1C6SRhknFT1dbYZl55MbgbR2NjNUg6AAgDWL+RS97PZhJIArZ4waiyBaxjNUO9w+wSWyzcHccsCpPffv8Yz9j5ZPTta9H78RqxCAVXsqYGSmNWgAIDXTbYzXqumcWyhiLt6Ggkt61ZO+As+jadvEejyXgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DAM",
        "sumerian_transliterations": [r"dam"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADKElEQVR4nH2Ua0iUWRjHf+/rcfR1y3Js8kKtOWR0kZK2MlZms3Zh3awQy+hDEF2MBElSl2qDpb1FbK1FtbWhmUvQhTIiC7p4S8oGuklFUk7ZuLkiu16yNcepmbMfZkbf14nOp+f8/z8ezvOc5xwAbJs0PrQUoYLQKyqgZq2JHlZMEUOhtjYnfsFGMQJflK1NGFbSfp4b4g/fTth/uzpW6nARJlJ/a3bNu+8OKF1fzTrh8PriG190/vuLR4/vCF0f2TzN2nFpwK90P5iyJ1CKdyA9262jUVonyZ5IQdOyvwAUbXD6PnNFm9+VY0tsTwzVf/6ie8thWXVhTzyAkrnvWEeDZciNf5lioNXGrX2RrnubCpMOJgKyLyP1v1fDdphioGdCWOWgMxesx+vnACyvOj1t2E906rOn3VV5V27qs8OLb1/+kQE0RnU6+PCK3usG4prOhwFEF7XkwJhrW3SEPnvEMWlTwdP1ZhCg6+CB7ZtRVDcQcjYnKHn+6st3gJgrHYW+IQhd2rLdfC0fUK93FozIXtgrMwFiLsoB+3xfn75uOt2YByg/ydcVKTDJOcsHjy9znu2fjABEV6vl3K2G2hZJTd6R5FJANvWWrs2qrZLh86MEvI8riMuNsboQgOLuLkkqzmx9LvGYE/zz9f6M4+jiL5VP9noAlIjSupWvPQjAO3rK0Y4DJ54CkUUTfRkStR8X1JVVWm4teQQQ/l1hT9uYEP/Ze07FA2A9WWerygfUc7I501DqcsfFvpkIwNRefEYCzNjv2tCuASgJd/LuGdpY+c+R0RmPgZj6P32KraZcI6o6H1DSE4KuadGrmlEqIEMBRNbvN9cFhl7WO4OuqXbnwlVDD9FU9E1JRRBiWGVzfw3g5p2zd18CUD7C/+D7Frx8ustSbAcx492zj+B/F6jQ6xqXXaputgPeqeVLGNAB/V4D7xLhu+Ylmz57+L0DwNuurUhVktSALcfGegy8cF+1OY4vO+R/Eh7N6miLHTq/FIo04t6rbduK7tp9OzXFvO32oK7aiemGPw8AW/9hPyHSloYYLEvr7CB8VNnuQKiO6KMSG2rY/w8UaQ7ocPx15AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DAR",
        "sumerian_transliterations": [r"dar", r"gun3", r"tar2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAABaklEQVR4nHWTYZXkIBCE6+6dASxgoU9CW8hJYCUwElgJrARGQiIhSAgSQELdD7IzkLytf+n3pbq6O/kFIEjeslhpDwwKknODSAEAz64wEnBn1UMNEBk1MGJWZNTICHAXYK227uaCIFVbdwArq0J5UK8E7FkNPJjcyv1GAL36B/jr3QKYA+Vmg2dHjBg8lyab5seMSMgAkMgaDFjdfjDZGekBK5MBFnJl5crkZGA6cq6DahP52uK3FADkxQt5MDl7cxkeKnnZH7VP9JIpmzu+ynX2AbGbPJr3Lf+MQNuBT/hhO7x0NSSjwjGaoTq5mIIPv7ZcnE5xBqQUYw1KzlB9dmi6PhUga7AAYFJ170a/35QApqdo/77i+ys9GymAsumHO3JuAJC9/Q50ujgIWsaWIf0A26f6eT2ODFjJ3b0GtnuV8UaGKw/W6UWT6nxGrzvv8u+4BlgEecNFQ2EhGewVmBRY7//RrLT/bPEfiAD5k/ASB+8AAAAASUVORK5CYII=",
    },
    {
        "name": r"DARA3",
        "sumerian_transliterations": [r"dar3", r"dara3", r"taraḫ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADkUlEQVR4nI2SfUxTZxjFz729CEiBtkLVjQVpB5MFUYhjrRONbBAyME7CxgQcOAJhZi6pH4kSthhK2JzEVXECm6IWMDVuGSJ0VMd0TOZSUIcwLBUoK60fyK0lYOmk7d0fZZbSknj+eZPz/PJ85LzArF5u/wxztAheRc6+mU3CCcJls7Yv984DALjb6b422RzDV1e+cPeQM4f61JfStrpssT46faHe+devnW/qE346tBpsPkAtA/9mD01/G+kN9sl7Mt7YsKxVHnS83Tf2D/WFgWyIy98Svt1mlK0g5sFEULXwzrRv+o4R+cUHO7sl24qGrZ/YSIYBqJR9UfLTgw433v+9kqv3BAe6luba9XHaQrQMR7iKGVcHpKvcugMIrZ/eUeUzlXs/+Z2iU9wtCQAAtuCRdcWoOTufr1L+bnObINSWCm4xjc0tnPOGo3Knt1zRfLJLBAR+oDI0JLlfkHi32sBkvdRxsVeyt37l8TAARM6Fm18EAAAvTfXg3DrXMgBRU4Qxw7txPw9sTn2zTDFzzUTCnrFEPO6EgmOKk36V3XbMxrS4rIDGVz01u2zN9xaBoVl8AnCY1ZbZ4ROd+Zl+TSfWBBAUQMbuyfjuyg+sBrlV0w/SwQnMGgIA2xry+bb2G++LKq6r2kn4FyrFxTvt5EeVSomZBohJ69aokNBQLmfudWGposnx8EgK4HEnR8BglTlj5qkJIM2Wrzf3E3gmHvg/oRjR+lgbra7tH6EwffR2maIkEPV+Z+oClwJMAO+UYgpgEEwA8EvYlBg+/resV08DoABL21+f185AHSyNMnMAxn/0m34A2B3CI1OTNiz5s0NpMFudcygAoPhmil1uTNlYGn/aTj7mKr5XzgD317a8arxxuPXJnEwpysZ7o2I4prDCr9j44Z3EaBtYprCNQsCRMDHaevCZe57Ufh9Oyo/S3PRf4j9eqdt1ZLfezvbfdwkAiqs7SzBPpCk1XnFStr+mYDDfuHfd00i+w2Z/hQQA8rey+TSoE4SUnWnJGqn0HYuoWWs8FLH6oeFg3r8AwjqmPHG0brubIJlotuRskRqz93xJW5LjyJ5ehrCmkSwPHIBA9fjIw8MhhfpSFqeqXqsb1Om0Go1GM9a42BuOgqHa7ugqbR7wendL8nNbcpbtZRmgTpDbdywopwuYrv7J5Ko5PGinXrt8S7Hew40S+SzAh3fWeT3LQ84v/U+lyf5C+H8EvlyWfoD90QAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DARA4",
        "sumerian_transliterations": [r"dara4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAACn0lEQVR4nHXSW0iTYRwG8Of99n6bc02Itc1Pk8QQT4EzotRFagR2JdqlkRqZIOVFBdWFYBd128GKvInVVZqmuakjm5lNRSVSozy0tIPOw3TqPGwu931vF9OirOf2x3Pz/z/A9ux9ySYszSPiLKdUb8Mx07yaeqP851Bg3r+9WzyXd95ziSCTTR0P+xtD6u1OqxJEOSt6G2rGPOw3SVpV9g1VThOjZPDbYHmJ1SHxctkmbsTrl6RPbxkotGPOaZ0xB3MdMySIMlXsV9bvB6gqTpHPW2bzXq14HPMMAJEkhX5J4AlAyxDt7XYlOPsKE/v7PAAYOZRlG9jDAYCDMfZlUlyavHckVqtWq9WhGZ9rk3hbswbgbmH5ySjHqZCWGqsRBEFnqHBX+cKVEgBq0l5p0xk+JK7/uBzybh4Sd1A1UML7E14DoL4HmRXTlul9MUL7NVeAqG6v5DhlQIQcAMWc6fGy7YRUl5BeNgwpLKvzGAf4o94DoGCd7gl70cLI1Kl8Z31GTCXbCWCd37yYpsWK+yxgTS9eaHJdl1FKKZW1NmsACoAByvXu5If25wXu/lzGAVgRxhFEEOJ2P911ulD+htSN9wQ4IBDu2EJJHhtZNVx1cvmoeNdorgEAS8gWgluc79IXx1Xlie0Z1YYOOY+o70EMMOobzrYbY1ojzoCNjhZcdQwpIseDLYOtSd7A2OrZzY8Z20zRaGzRABShpUndATdco/FFTgkAE80XDpTrXQAoOG14pHYo0Bp2cdHsJwCYryu5UtcMgMLbnru7UckldRSOTYkAALIhS7nJA6AI9HjupOaRlPBkH92aGJMJIwSgwI7lj4fJTO8Gz4m/BsheWNYACkWa8Git1Loq/bFc4vUDgPoZq42n+Hc0vdWK/9BPrlsS+JtqmYUAAAAASUVORK5CYII=",
    },
    {
        "name": r"DI",
        "sumerian_transliterations": [r"de", r"di", r"sa2", r"silim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACKklEQVR4nH2RX0hTYRjGn7Od5jb3bdpQhwxrZCgjDWZqaUloNxZddKElRIzUkbSCQhYUFmWbJUVJRER/vAgkrKiLSE2YwyEFlRtzrKZDUKSCdOdAWMud7XSxrTP3p/fqfZ7f873vx/cBQsksZgCQ3diCzKUYmdcDMIcOZwmo3Nwzgm1f+NYkU5TUb1S9brDtG/T/KKYyTzj18+ooz3NtjnFaMJOyZKJqafU7RYhOVP8uw3lp369BY3WRpuLYgwWnNp1LbGznhnjfPPcqLUFbmQ5B7Q28LF7PRVcYE3IvH0zoxsBzTTKnLga7xCBvvloSzh7fUEFsNADAcrbnYQR/nKU1zulAhALA+dpC3cF4QNl9svd+GAC1HN79O0xTAPj5e03XzwVj4/aH7kgAIHeYG23KUxBCCCGKoqdrLTFeYucvAADyJ/vlwr2UT3h7CSASl93SubUUAKzNbpYJAU35i/zHehpn2NWuHl85ANCno293qUl8RStz6RG/bKKNbE6vhOz08wA3veSdck1FRACiXF3e+ZW5b2p6u1pX3Vxr9n4EKK284INrNkoBPBprXUPDi/F14hbPZAUgvRu8XRi3jrwfUCc/ZeUnhx45J44ntIm1pnyWwe0oE1QHY6VTAqjyOLb+46xNksoBg2eiNNa1M33SdA4YZuw6ADAy1+SZOLDDO74JOBrsV2TmQM3nkcJDKzeV2ThQ7/UvDqiyc6BhYabyfxzUgbG69c5fhCitwtpn17YAAAAASUVORK5CYII=",
    },
    {
        "name": r"DIB",
        "sumerian_transliterations": [r"dab", r"dib"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABJklEQVR4nHWSW5XDMAwFxz0hYAqhYAouBBdCFkIWggshhdBCcCDEEGIIMQTtRx5tHa++dDyRdKVcQMukKWIRCWERuUCOJrQFvmZiyvwAeJkXX3xgxLcysGLt5RRLmKEBwDrSmL/re3tfk0Ek2FIcQdpdZn+C4AW4YLyOr00PUO7gZBC3pk8Jk5jPasDPfnvR8zs/sBULTB1gZS5nbxGHp2FMj+/JB853M4m0231OWPfpptR4VUoppfbXZk/s/bey/FH9elXoGzPVTnc0T8l2Y27devxHKjCYlKJNcd2jrDb6NkKOY312vH6DDfebDR8RIBaeYAlOzl5gu3kTranBvXkk07uT0T96dGeb7v+lAdcTK6qNhdWmpb/e0pirNj2wdP+I6hfgDx40r+QGiDzLAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DIM",
        "sumerian_transliterations": [r"dim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABW0lEQVR4nI2T0XHEIAxEN5lrgBZICbTglEBKICW4BVICKYErgStBKQGXIJew+fANBtsfpy9m9UZohQD6KA4vh+f0Mhu0xJPozhIARJa5mqMq5QJ1hZWkjLTJpV4VTppF5pG2lbFe+shRJQqHTiav1Dai9z1xn/9gl9WUnk74Wi4HyuiqBKd7JzPFwEirzdTBkAo4Ffd0xwigoyvbtYwoBYBTdQCcaNgSjY6kTCMMJ+oQtLZeTdloz6yswfUwjGhiHoyqAzBxssItGgzLzkujbwZ2dvh7AJhbxpV18Y97D3+jfCKSTHbseaZYIwxD6cAA2V/oCZu0tZAGOukEdMuwwfvEOtrkzeDumRGl+G5ijTYidvQLRhRlvxppe8J+A3bYVo4fIzIBk6Yj6xMr1R/UxDkeRw7ACKOGoyostbFvXSIb+3EqEVd/EgHA8uInG83tfOv05Wc9w+vvLv4DXR3fqRfmQ4kAAAAASUVORK5CYII=",
    },
    {
        "name": r"DIM×ŠE",
        "sumerian_transliterations": [r"mun"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABj0lEQVR4nI2TXZ3jMAzE5/a3BEzBB0EUUgg+CKEQCi4ELwQXggpBgeBCUCDMPSTNZx9Wbx7/Lcn2CNiHCn4did2v2d41X0S5SgCQqUMLZ9X0AyrKRtKOdKjaPiUuXs2GIx0bc+s/0TW7ZeOhky45XRAjAOBr23gMI+JrCrqnC/49tavXV2KWZr341slAD0ClvYmyg2ENEDdZbkdmQJxc3q9xLcsMVQDiLgDE6DUjtmJlTvn1QKenjsbbSwW9huf4QqhR8LglCwASq7P1sssMBPPCGlBorK1nD3GLQMcuGudYYUTOhQu9NAwtIJjLd0QcBOMTwLA2Ijq90viDIHhIxF36+3SzikyyxMMFMdBiMPadV4vB5ySZGY3+NvECh/JuQT0r0Pm86oGdGWZYzBc3FGZ3ABEI5h2AbvtcZqgmb+u4FC4Ho/l5hpihzr01CpsD2Dtgg2PjcTAyDUiuZzYVNno6qYVD3tnnHcGY/WJ0o7aV/bPbqCH+veQoU7qKAOKHegi+Tez3Tn/dpys8/Wzif+ziBsGLISppAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DIM2",
        "sumerian_transliterations": [r"dim2", r"ge18", r"gen7", r"gim", r"gin7", r"šidim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAZCAAAAACXuGg0AAABAUlEQVR4nL2SQXXDMBBEf/xCQBREYSmoEBwIKgQXgigoEBwIMoQEggRBhrA9uKnT1HJz6h6lr93R7BwglDPNsvF2mxEBkg5tzlxVVbUeIHhTShuU6S0Mpw5gNu2G8+T88HHB2VGTtDmIWoGqqur3uF4jIDVp3MMw2gMEzTvyANQteNjHUAcd8x/UUt1L1P9w9jXOXzds/8kFCxQTo9toufoXF0d1ydJaDo4rb4YeAIdM50dXE3DkvjRJ5mItYHnfCrhoctb5seYQagbS8x4XNaScVUdvAcmBXp8/8XXgcx6/h9dY6xbXQbHT6S674KfSiJnUhwvpo6btub/ePce7CnwCU5J8z+SIL24AAAAASUVORK5CYII=",
    },
    {
        "name": r"DIN",
        "sumerian_transliterations": [r"din", r"kurun2", r"tin"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAABsklEQVR4nGNggIDcfQxogAlCKfgzcWGTYZQs5ztTyIIqw8LAwMDAERX5i0PkzZKv6CYyMHIHPlja9mqqJCOGlOmdY8IMgXf2WLGiirNan3/vz8DAoLjterIAsoRU6us/uxgYGBgY+LoeT1GHi/ParLo//1oLlBdycZ8zzMSm36ccBe5nwxTqbr2RCTGRSf3pjdeiQn9hMpdD1xV36EHYwWsO1F2dgGRv2JVTPhAWc+nd7/s4kKQ0l98s5oMwvfe8ClNGkmMtuzXHAKpq++UOXmSfOJ8/DAnGW3c93n9Dlvny7zUDAwMDA2Pek+MRyBLJt5YrMDAwMLDkv3/ljSTO0vK4Q4yBgYHBYePzB8eQ7JdfcTWDg4GBQabh7q6043MRErYnTzgzMTAwMCz9OVtE9HQfXCL+/lJ9iJkLBH2ezfv3HybRlLxw8nMoWzb5ysmL6yFsxbU3U3kQBjPrr/t/3YCBgYHB/ORFNzZk1zPIL/lfxsDAEPFovQ4TAyqQXf44xHnh8z4xBgygduDdvpsd6ImRgYGBgVF55pkOFRQhqLn/7y6R5riLIgNPslcnf/6PIgMALU2J2B8QgJIAAAAASUVORK5CYII=",
    },
    {
        "name": r"DIŠ",
        "sumerian_transliterations": [r"diš", r"eš4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAXCAAAAAAT5FEZAAAAR0lEQVR4nK3MQQFAQAAF0UcDFVRQYbPIsp2IQIStsCJ8Bxowp3eaIfaTsliTnp6DmjK1PmNrNQVKsgEt64MajN4+YP/nc8ENPMQZyDrDamIAAAAASUVORK5CYII=",
    },
    {
        "name": r"DU",
        "sumerian_transliterations": [r"de6", r"du", r"gub", r"im4", r"kub", r"kurx", r"kux", r"laḫ6", r"ra2", r"re6", r"tu3", r"tum2", r"ĝen", r"ša4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAVCAAAAAACprM2AAABCklEQVR4nJWSXZWDMBCFv+6pgbEQC1kJWGglpBJYCamEVAKVECQkEkDCIGH2ASj0Zx/2voQz8x3mzk0OkKczbzqFsY6I90Cy9rUtJaqZmVkBoll4AeIgXofmZCpALJ1F2feDBWgtJPUAJZNMY7PrK0AeLAE4y90yL8VGIFrJM2cODqTAdBtr9d55L4zIueEHEK3fAKo7A+4UtUiOACxHePIHkkvKe+Bd0YYN+PoA/FzdLphGPnznYRuhugVgxS9etX0AySwtZTqz6GZCVuA4cWnDeJ8X4NK2tX/sXIEj9C64ZqneXetlXBdefzusUXSmuszYTNruNejzrc4ervf6qPS3nv/ozyRXTQC/htuOMXqdD8UAAAAASUVORK5CYII=",
    },
    {
        "name": r"DUgunu",
        "sumerian_transliterations": [r"suḫuš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAVCAAAAAACprM2AAABN0lEQVR4nH2RQXXEMBBDf/tCwBRMwRRMIQvBheBC8ELIQvBCSCDYEGwIDgT1kG02r4fqOKMnaTQfsO43rvD+G+bQa8c4ByxK170dEXBDkqQCJClcCGtZHOBG87OGAVLJSua1Nlkhj2ggKizDAZSVRS15AFMkk5YiSWpaAJzWfPi1nEaZB7mN5L2PkoWJgN/vvVbnrIv7zVas3TrQqR1A4wyAa2VupDUdksd14VwDJg+ZpDIDrAmYeFxL2G8petvN7ABbgYk/+HbxYbe4AYe0vzh4A5jR1OxpwRj+JKh5YM7lGnKRFvciZCkZ8G3k4L0vCZh2vmLoz+MGvmKs1dpnt/aVYYLNBuu3Q+NpozN9M44zZJbabxVZYyT7/msCkOI5Ge+vvou6P+s52R7b31r+xZqAz38IO8AP0nm7CV4IfCsAAAAASUVORK5CYII=",
    },
    {
        "name": r"DU/DU",
        "sumerian_transliterations": [r"laḫ4", r"re7", r"su8", r"sub2", r"sug2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAACYUlEQVR4nFWSW0iTARiGn3/+00meQu3kIc1kFuWSBM3QkuyiItMKShREXVQXZUVQDUQRohMmgiJkRzDKTkaFZeRWulIXSeZZp2sxMwvN1MSl29+Fk9Z39fA+Ny8vn8CGQ5pBnG5hctqjFpeN8RD99e4CJ+F7K/+7NPBFqof15plrfv9MQZ2n+lt2ZUc4JPbsNzRlewtzImt8J+I9Q18ayPL7rpgnB/u1V4/HBfnmWTqCIFF664MYlBGwsrh1yF8VtT1n1iad3iSBzmgYQ1QYL1ROQ3cDLI9IiFxkF4D2McDV37lyarMlDHhSALI/P5xNde5MkgNl2YEOWqsCaCpUL3WYwofJc6R+dcILuFG3GiRAfJOgyXnZPuwy26/I3Pas5zMPiMBDAtFVX1MRZxiR2QN/a/LOj05hdRdnFutkcnRTv4oD5XK5XG3tf37ATyFXnn1f2qcta6BNN1rvA3DZuA8gQJvbJdV2S9eJ3dJorlYCqigAj5u3SRlKr6r1hF3N8R8s56JdAXArmo1BXtpl3gouRUM1w5be/s6nFemRoeXG10GQIL1wQQxLt5mKDBOhq5Sqg14h3UeSrdDYWW9DdNeXNAAmUw2KFZuTkzwFmPloAtw8nXeL1VtCgaoMkFknnE3T0ekd84ueXOeg3akALWcOhzmCAZPaG4BLtovBAMdi4E4GiE2qlCx9myjZ3SbD77e+szOijCBYAlHe1lgY8nhUZvMbLyvPVA0KEoKwTAI+WXV7FAJwSuotWyMTBEEQhKoMEO0FJVMALNFqmp1rinuNDir/+d9HIM4Lep3S3wL8Bcwr5eNieftFAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DUšešig",
        "sumerian_transliterations": [r"gir5", r"im2", r"kaš4", r"rim4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAZCAAAAAB1ZHNNAAABWklEQVR4nHWSWZXjMBBF78kJgaIgCqKghuCGoIagQJAhqCE4ENwQZAgyBAXCmw/FWWZ66qcW3VOr4CklDxX4XaIcQGpv0TOsfADEMu9AzF+ATXHfNpz3QFEGSmsJrDQFsJq7JEkVyFLEaqkBfE8yKA3fW4i9GpBrUTEbiXxTIGqCSXHpHqCtFPUclgpgvUR1gLUrA3itVfeCeXJ4qa5jqjFWkVoODjflpUm9NZ8zgGkFQD0/p7aQW7V1RO4q2Pu+bOnL+gr8K0ntCZx+AeaLiw/nlF4qHNXm6xOg9+lhq90PaT0+eijSciCLVDwAzg7gfOMjLbfrDcD4SnG/HgndBpxh3zG3ARF+XHRp3++FxixSjQZQ+iq1mPrR9uhBSgMvyl2JpMIrcJ6v2/D27fZ93Vab35dyuox3foLZZePHub+Aw7h8OgPmz+dtbu8osTuAIM9/ZHwDUnkN/gHLD8ZfawwrMQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DUB",
        "sumerian_transliterations": [r"dab4", r"dub", r"kišib3", r"zamug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAcCAAAAAA2fqIKAAABeElEQVR4nI2U0ZGrMAxFD0waUAvaEpwSTAlpgZSASyAlQAlQgikBl4BKwCV4P/a93WQzMHt/PJLuXEmWZXiCLwN/w16iHISqF2vyksfRnjytLAnUc3khGte+65YnjxNyUmWsf2XIBt4jKqBAMjKJFF6JjrUFQBQ8qCdjjeYm1/vwXb7gxT6sMZtZLC86azJLfnAhw1A2/7+VvZTi2tLf9ijrLv02yLbLVjaAtqxl6xyArP3WIsVTOqaIK54p0pUeuBiBqf+nqTaSARLmSPB1LEDt6CKPpqqqqqp4vplX1A6/XENuBZykQx4Xv4S4Cnkw4XrMox5DanJI13S3u50R29imuX/YPdp8wqOeZYiwkPKZHlwyH13HBNwc7ribC6hCArWEnig64ngfArgUcCc1emu+uxU9Tl2H6880VNujTaB+5B8jZR+Psr8+3MV0PVtEX4DYQ79JX94BfC1XCkCaQczf+D0had+lt1K2N7dObzwtf/wqfOkOY5/pXcC0eQGrHAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DUB2",
        "sumerian_transliterations": [r"dub2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADUAAAAeCAAAAACp5glZAAADpklEQVR4nH2Uf0xTVxTHv/f1tSkUBIpaHCtKQckSh0RBp0vsgGTLFNiMDKPogqNuTuem4saqTBNki4lgliU6dDhMgGX6h4gzYv1B60QyRBNZtYoQGCH8soL0h0Vf+3r3x3ul3Xxy/nnnfM/9nHfvuScXkLT5B5TSiWnts8kV06UZSVX5vvKj6SgiqW4z2uau6n1ZTzGizalanCxZaeXI0eUTRyUy4b9Q92MXrZeiUvo8z+1uR3F4UIoQv5o/r89raY4RAlVq6Pnm/9DUb9j0q60hdUqqTROd5HvnuhaK50qsM1c6glj2ycbdFOn7kuurRbWju3t4kgDgSxZVl3hYAIDzRdnys38MiJBhF22jwO2i/JLs8lYAwD/aTAslAOhIwgUPBMrRxXWU7bMOyABQdcoJ/QQAOE62fFt/ptwNhC2rz/cI29KZXBApZawm3XuruZsF4CtIdsp8wl/7tr576O2DLdykQxVOBEpFmAClTlee/7xf3OCNzaUxkaJPTdadtU2VPXfSbJ0sANAIHwK3HF/adC2kiUsbzNu9U1HOV7FHdjy8P8QAAH1t9zqLmCD/G5E1tqUhkXp/L18cCOLs7wAEYOR+P0P8hOEh46hQ5ZBiDx/CLbzhabX6CED52YUFrQwLJB139uaNWN6Luqh7VuwRqMhxGgLpjNHs6z4v8auzImwTCYY0GLVYdf23YzW/Xzncck0vLivqfCPIkDXtPc+2AgAUJ7xPrA56Hh7zYtTdCtvoeit+YL9cWJc3WhGcsOgjD0pTh6py9ZmZmfrCYevajvZE9uLahmp76uTNx4+4oTEvADCGr0db/QFoZYVix1WMZ2zq5AnADcZ/OLO4j+0xnz4wgzulUtf4kjZnyACqDTv4wQuRkW0ps+yyI0vT+MUYBQC+/NNTFjBRHCcHwBDA7QYAOMM1cvEmtDXGbz62A5C5notl/uIu+4GrtP+7n+8hrlujbswVMusejuYBAJNz25whSF1Xnl6+ZDKZTJduDuoBNvvO9nZDHPgHhA6I03f6UV1usxexezfU/GQHAKwg5uN2YTYSDhMAexcAMTrIdHJGqxZbHbn+7pIUQ9vfOYGWbBnPD7gacTZeMnVj0swxflbnJ7aAsqyCJgr9JQpFoUWc+f/a0+9/VNTGrv5yCoJ2bk9Vn49Q+YIZswokCMEW3S9pqwqJiyoDzw10rqxXYtvGHUtCwqigqz335iup6MG70u8r2DlySJ4LwETtbCqd8Q0D+BfXv1VN9CuyTQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DUG",
        "sumerian_transliterations": [r"dug", r"epir", r"gurun7", r"kurin", r"kurun3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAAByElEQVR4nI2S0ZHjIBBE37qUABcCDoEUcAhsCHIIcgg4BCkEKQQUAoQAIUAIcx/2qiSffbXzQ1VP09U9M/CpZvnYeiktYo7I6QNTzQX3K00VxYWqfqFqs0kmqeFdb8gHYzWHkEWkf0N1InuJKjHK7Gbx6l+uVIn9hvcyx2rA1Ww3ytfzzesyWNYtVrLTHVCju9+eWPd8NdaQ0g91DW3BqJaupbfXDQYwItXrHZCriMwiEnUQf5iAxONuZh/DzDBnBUPdN938EtV7KwayB9Chvh3xD5WMdmP/GK2XoP9DDZhaa3yGifXTuQCQ7qVdng7N0gG9LWjVCkanoo1e0cuDcO+nBmBH9b0AqBhytHWuYy+zuCGPUXlPALwFlJcttalV4WoALx6CGHZUm6sDOIUe0jI1ljLBxB2mdbce5UM6LwCdGvWNtgKtQaFB2yXbXMJpZYjvzvIhqYenJNAlLsOIsaCdBTwo7QEuOL9JAh20ZJQyoEwDDCg1sBZrnFmuezNeavWjBYIFBLC5ioiIjAc3J0c639oBo5xXrl+l3A5op+5HAIB2mUetv48K3Z/32a92aMsRepxLKsBSgBuQJmgTy+v3T6Xy67T/AtCU7VsOOqBbAAAAAElFTkSuQmCC",
    },
    {
        "name": r"DUGUD",
        "sumerian_transliterations": [r"dugud", r"ĝi25"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAbCAAAAAABy2MdAAADTElEQVR4nJ2USUwTYRTHX9uBAgq0HYuUGijSQkDbi6KoBFQMJR6IRsUlGhLSGESOuKEnloMaIy4xgghiAj0AkShqpBJFDLXIJrIrhSqLYqYttDC0HToeaGemEpb4Tt/3f//fvDfvm/kAmBGcdxj+P/hFxDUPgeW7jrNm2jeH7Er2Yypo9a/TAWt9wD58sopUR65n+M/bFxpOhvMC6Ajkspjt0cst9eK8Mj3L0NT4ed4tx+f0rjti1wzTLq+Xb230DqFWMSWSnruCAZNJpZpsZS9qxKbNXToxyjGa2W4bx8GsTuGK4ji8fiZKhphbtDqDqzyRHZumufV6dtX33tFGkqPbWCqiWcVQ/csmVcsiAACupo5UKr47m9rZZlu5mpG1DPVjolVL89NxY36+LQtAOmWtSJT4U5lDloXaVJnAwy1lnAwCAHHpmX23n5Y5MABrS2KIunvkh8WVDsUG4So+0j9HE77KmlKCxsXHzkXW3f7AE+GdACQ5OxAv8xPNu9JBgne6LGmgAKdx664EtHzCvTtYTXZeQgEE3eM8ANkQ2XoxYSPlTTGONdw5Gu3R/PMZ4vkpCYqiKIoipSJLYQ0AgNNhBuDJSgp+Mqxya+Wz1n8mNTWsVha1WxBYYLGRBxnhx6c1AEByuDZwOHkxTNyP3fovDWDqjBUq5wzOMHwKKdCeUMXeK7YCy1usB2NbmkL7aRCbWTxQB+5/Y0e91ulBy6TFlscay29nsM2EQGNHS+ZN+c2heUSoB1wvrrt8ZnxgwoVHcAlpnrlj1EZ9tGCPFjYWdmPuyYOpvO1sdvT9XnmEDnzC+ElfGzpNro+WlIS0N1/Yn6gxUTjptUGd3+/eLdr4mVdn/0SVngOF1lDxZthClYorDdH3vB/B7PR/whH1U8fmDt/USdLZJ4Dt5HUvpn7B8SI1dMnslgYrVksa0yDSMF53gCHnDsWvjFGrrZVyjTL40d4mBdb3xdWsPTll+OFD+1pwSKzhqBrKEmqzoPeja3ROn6Qg/LfmnQ5bvX/vDLJ95zdyLDdGGOi+2SSvqvfUEHPTGB31wmV49Amhs1eEezMkeTM2pq9IlwXRwWcvg0PEoDmL66Gkz05dEXHXelXHfbvjKRyv2r0i+xcTMlhUuQqebAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DUN",
        "sumerian_transliterations": [r"dun", r"dur9", r"sul", r"zu7", r"šaḫ2", r"šul"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAdCAAAAADj60EcAAABZ0lEQVR4nI3SbXnDIBDA8f/2zMBNAhawQCVkEjIJiQQqIZVAJYAEkJBIAAm3D0nXdU3X3RfCwy93xwsAnecfIXN8Rl7BxGSesTdMloXhuLvqbUngbAGQLmi/y3pdo3/Z5tNxxBaCFFxKVpLY0oxhOKa+O47X/ybiJLaGXOeoGqvWqD1xNhrgdWOnsZ+Ky10y9iyttCYnaYvxi8mM8HJJZ2baybpi2mJMwi2L2AQYc/742e5cVb0QPU5B1wEG7bgWpWtn2tjuNltoN8xyeN89lQa8bd9Dd0i7CMo1m/PjIwXfzITz/m3dMAkCEPdvjEtv3i4WKJNNTcRZHGwD9psOqn124H3WndhUpxpzrZZJc3dXzm3M1giYUPtYq33EJOv6xL3G2lcvv5is+5o013Wpq3UO/sF7DxritOXN9zUvB7J8iun5BLw5lEdsbbNmg1f3JwJMroMOzxRI0Om5Qub8D8Uw/z6v2/gC6XrEs/kCEhYAAAAASUVORK5CYII=",
    },
    {
        "name": r"DUN3",
        "sumerian_transliterations": [r"du5", r"tun3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAcCAAAAADZvMk0AAAA+ElEQVR4nLWTS3XDMBBFb3JKQBRcCKIgQ0ghuBBMQYUgQ0ggyBBsCDIEGcJ0kbgfa5xq07ccXWneO5o5gUlvI8e6XMd5aRoHkKV/QppJUpxkOgHRmuW2LIdomNurewWIIchzBXEAJMm+ud8PIpLN/tUgCYBGpHO9v3dKIrYMtQUJWUSmrehLp+7RHKykraWRixLqiyRIVxZ35BmAkdsPV6VR2MiV9bvURxV9KUuLnYa1jlxNp/yYQlrzMexA0Uneh0qfrcZt2WtUR7az7rPU+A/dAc65+xt6vBlCJTmuXfL69Ozko9vvlzahQMw5+4Oz38ra4qiS2uyfogSRaORt7JEAAAAASUVORK5CYII=",
    },
    {
        "name": r"DUN3gunu",
        "sumerian_transliterations": [r"aga3", r"giĝ4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAcCAAAAADZvMk0AAABKklEQVR4nLWTbZHDIBCGn3ZqYC1wErBAJKQSrhYigUogEhoJwQISshKCBO5HmjZp07v8uXdmhx149guGA8hwjizVJywJayNOothO1Rh3AEZprisS04mVDicdDiOqYtMB6K1op/ogjecsYTJuXEKqbu4LoA+h/K5QHABDGb2Z0oVSyijegXfg/bSGMsARjKGJtQegUagyL4q0cAJt6wAJgNzcrukVJJPgCFwqNFdz+DtIhIkktabJc/iy9tI/3oO655azD3eZ//SeyZv1k63IldTWOKw87SOZpVY1kpntE2mluyYMikERMpRtkksL6N0eA2yQ1dY88y3t0T6yStt9viv+Q3WA4/i9O2cIO8mYvwdv/wbB9+71f7ltsh/HwX84W2ssfl+flL2z/wBV1KR5rpItvgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DUN3gunugunu",
        "sumerian_transliterations": [r"aga", r"mir", r"niĝir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC8AAAAcCAAAAADUorlzAAABb0lEQVR4nJWT4Y2jMBCF30VuwFuCr4TZEtgSbksgJdglmBJCCUkJdgmZEpgSPCV4fwAJlzV73JNGgPzx9A0Sv7CkhBHbJAZBlJxI51g7zuJcl5/nNf7FxyklX9K1L+n6Z0pTnVKqhcx6zuT7UeTBc+8GUQqidFbQ2dtPTx/87Eux/pxYtgaplkjLq7XWQl0EthNrAXBaecKYKToACDdFYLxkxA3A6WqXR/Hp0s/3Z8vjKw6BAjjRvZ9L31XxMe+rkr/hS4zIhXUuoGGVkD0chvT3ctqlTSvt8CcdmmU+dTs+acyNSrGeI6x7zsKr+AW0W16h5NhaYB0oAzBOPh/+G96BhwxLGdYxrBUgKQCDtr8OAYDmuVb16X8fWv6huS1gJDf992JI3rTh30gQAAaj/ow9wgBguO2/64Pbf/rrm+Kew7/9Zz4wAPXufGwNwwDAXXfPR/cGECuVl7/b7/Qv14Qx3w73p3o99HXWTJej5Bc3WOBezQ4hOwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"DUN3gunugunušešig",
        "sumerian_transliterations": [r"dul4", r"šudul4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAeCAAAAACUdGg/AAADAElEQVR4nIWSa0iTURzGn/fd2ftueWkr09m8lEomaUWWKVJIkJZ9kaIItYQI7ALlhxBDsk9FKEGiWJbdRRO7IUURIWXqh7y3Mi+pXdaWuXS46dzm3tOH93XONPx/OZzn/M7z5/yfAyxciTUxCHke6KGwC4PBBT91flc+Gf/jM3s9rvLD1rDbEzFzxIVI7lxCg18ZZ/64KOksak+wVy+RM54iERdFRVGXh2fScPLJepf6cYsy4efw+q73rtAteuka10pOvJklb0Qp1plb1HEDQx2JJNy7w7g5OEvydDVk1b2r/+YEMA3QLwdfVu+Pvzy0p7s+dlPhSV1t2fFKyZMUh5EYM1hAqWUAPRGsvPcofF0TvNcfMj45eGpspl/3dM1OrQxA0AsHbQ5JT0VkPpCVjKh88FXO3QCbILEWS1rNDgD6s322XIOCh0LOKTkeCjlnbzD8AEjpvUd6wJGRfgaNgwDQ2fOriZ87tQmXABDbgcwmG2DztphyBwAA30ysMJdkAIBonz8doQBkfkQn6lNekdOu+XGQ8YpOAAA7ppKcGJoX86qRZRiWZRiWYViWBQBirrn7iQCUjzS4wzNtXBOd5BuudoTRbepwlT3WKgBkfGmyVgZQEvTD3ciO0ejodoFEEZOSn+LItM4EEP/CKvG4zN9Nruwq3KA8Lw8oyvtoh7cVSWkugLWsXuuv0WgCQtXuB7PVh5V7346pyvvb7IAV4BkAZDAnrZUAVB7fNEPS5tP7vrSlZIflS4KMYwCy/MEzMwNQbgVxd/dPnupz5Nhbx6V9j3MSIOS6NMbMZe5B64+WxntlF8f5SMLQVwEgxiclPQyVUT5ixO0p9J66llp8rDbjnZgApQCI8D1Dp4FRRiIMHul9vpQSaDx0c9WAR0gVR4ALr6KBqw+9ROViOQ+AlYFRef4UkjsK6HPrCnpVtglRmnLYAQgANcOTHAUwbHlRMqKx3nICALYr5febMK/E0dBwuf7OkFIMvoFyI/NBkQzxUe3q/00XOP63Sl5rF4f+AqloEdkLdYnVAAAAAElFTkSuQmCC",
    },
    {
        "name": r"E",
        "sumerian_transliterations": [r"e", r"eg2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAbCAAAAABHfcC3AAABI0lEQVR4nH2SbXHDMAyGn+5CQINgCqLgQTCFDEIHIYWQQnAhOBBiCAkEG4L3Q05vae+mP77TK+v9sOG95Lo1YDg3ZwE83N8vxNa2dC3FAUQ5Yb4UDW0CYNvGE6ZbSc0BXCZxfjnxKfUTYHCi94p6yFWU/UEesw21WQBZm9UIbKtBV6ICshbV2EaAybiAtYwOtKTQJggxdIUXmFD/Ym//RvMFopNHrhDlXgEXdhHgBrTZRmejkJLQVgLApgZN7ThD6b1YJvkL+daKAgPsD1dyBUeyOOAnG4QaP66noPvxJusqJy7pwQ9xuS31nD0W98c++xfDHls8LFrj0ewbd9syqOrNFoTxy8x0NaR0/IAu41AB+uQQ3x2/hv2swwMfb9Bh/D/oF6Cvh4zH/QMGAAAAAElFTkSuQmCC",
    },
    {
        "name": r"E2",
        "sumerian_transliterations": [r"e2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABGUlEQVR4nOWSUY3DMBBEJ6cQMAUfBBfCHgQXggvBheBASCAkEGwINYQshC6EvY+0VXK1SuDmx7L0PJrZdYcPyq5wsdYzAMDMpkm5u6qqatiuml0T85ps0oTuXth4qSTcdDM/czmjC+MQL0GcmHoEtmfB4JsBjGs2OpuksWU2agbQwd0WthMZElvfKWsvE9CjokYZ7QQjeMc4PPIq+TWnpNE8K+9ESgB6AFgiiblKRArLH7ttQv3Wp4gHTaWG1KqAr8d5YearC1M9dXudrgcKQ2CPc0UO+23VVwAl5AyjN1XVPK961Cv9FnOIxQ+OMOwTmXDwIiXSFet4/B509AJQsGCYPnV8qgm9UW39B6oHIBABs+x2+5KwAPgFm/KTu3Jt9TkAAAAASUVORK5CYII=",
    },
    {
        "name": r"EDIN",
        "sumerian_transliterations": [r"bir4", r"edimx", r"edin", r"ru6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADUAAAAaCAAAAAAyd0tPAAAB+UlEQVR4nJ2U4XHzIAyGn+t1AVagI5AR8AjuCPYI7ghkBDICHkEZAY8AI8AI+n64TeOk1959+mULPZKOVwgOZgv/YUmffcH9AcVSnkKcjr8yRjRIfISahN+gKWtW1engHDWHZp6D3VdPJuekMeqhmvVBNT9jU/NfEW1RCU3T4VjFtwdsBJtTkd2aRg2lqNyCfNQMXvP9JS36ijUOv1aAOn10Y97GIEPfm462X6B2m9/qrenlwhLyGFMuIiJZsRrBtV0Al5toBJZSbk2arPbFTz05C27btg0qHbYBceDFDFuliYz2xGfbRtylQo4xRRtTEckKGvaEbZw0G4K2CVBMzmavpA6YtGnRJiWEeKMwohqBUGITEQWTs8OVFhVeqMzX6wbr9WM9atJ3wT7O5zPQByTkPvQOr8Dqfa/48724yb67xcxQ69cY9jkv/b2O207R63s27/0bctKHba3RzBhzvYIHxritS5qx8PKZ51q3u3nI9bTBZfaC6XjvgZDW4XxC7ijuChHiZVf5MtgF7H470zx36mldcIBXghBk/0RD0u+n4YouANpuMxU1/EDtAt2aLW2CoPF7fqXZR2rUdnzNtukkh0S2JcBiDMZCSJqP0w241sJDouWwXMbWpud3a1t63Ar+8PfzjvB/rBsW9T945Y/VZpr9PeDT/gHlUjtjrTUDwgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"EGIR",
        "sumerian_transliterations": [r"eĝer"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD0AAAAbCAAAAADq/NgeAAACDUlEQVR4nI1U0ZHrIAzcvEkDakFXgq4EXAJXAinBKYGUgEuwS8AlQAm4BChB9+Ekl9zZnqfRB7CsALESsGGU7Nby0/gQ9eUQFj1CnbpDuKTnuN8g1wOuLdX8XK2Gd5S8pnjAJuuLmvvkFMFze0ENf9l2pdLl/QARn+vo3BaWVzbn3Ge0Fod5lz4Ef13PrrRMIhNjshiEb8tIS7sgTp4O7o9ujT2aaov6qr6qLwGA10KuVi/bPBNq4LEQAJwA1y+ZaQFnlg8A8P2Szc67neXp1kBpvtyToD2pZ3Wkfl2Juq0m6ktykhiA0Ycc1fw4ADjVLaWyr8EAKCnGGGsl4Byu7dcuF3CZAbe8Jd1YO3wuAITy1EBsxw5nTtf323l36wcA4rqfuM7y8PGYkgDkGtl88iSSm3k4mDvEE4DU8LXuJ+eWaXgEknHJAKSRGf4RMXJ+ep7a+mbD2dTREdgXvnRPMohanud5Ju4uqCO9Z01SUQZi8caNqlHH9w+gEkfvfdAegAOKoApUUA0AUFAH3AvBhqqpfxWO0R4A+r0eQOkNMb5oeVFeLKqqGv7w7sb1V9WLT1rCmhBZwU1JrObSnxLhPmkNlsACAFYPisj/pQPkRtXREQCECACnbbYNbf6tQQCAEWDOUy7DbZ9t/NznTToACGX53O898HrYHCSuv3LewS/DDgAAyNhvW/9hq67wDbVIGuaGcdX6AAAAAElFTkSuQmCC",
    },
    {
        "name": r"EL",
        "sumerian_transliterations": [r"el", r"il5", r"sikil"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAACt0lEQVR4nG2Ra0jTURjGf9v+6j+NvLRS0awZ6RwURJaV3SO6oZFGEFQQJBarqEaFYEolCZFldKcwukhlltLFiii1zFjl8vKlUNwkKxVvaLnp2k4f5nIyny/nvOf98Twv7wEgcfc4AKIMgXhIqXIdAIqjxkgAloviYA8m0RCvDlbPSQOY96l+AQCBFlG3JOQ/o7eKpgqzsEt+UnxuZ39CjV2Aw2Qdelh+t0O4GMunxd8bNNaTHM/tGLptrNvsD/hfuxVbKxz9v13qa+u6t8ZyHoV5mugJVFGf3ALjS336E6rLfqqGwxyzdkoDK36wsLn74EXxtDQvAqZaxccdAR5TBz8X2b7AJkt2Xk2kpuTRdJJEQSyjdKh9PoBf8WBLOmgKKhOi0tTA1KURAHN1QOq7WADlWmGKASYWmFYBsLXu7Z3M86WmPcDG11oAwmqLJYCQA41bACIrRF1NlTBFAylvtKAEZ+fAX4DuC/kZWUDrwcb+7fb2tGaPuULLfhnUAPisa8kPAHZ15fbuB7cPEPpYWI2uz1AsM173B7l+8JvvCKMEVF0N6gdF+jhJpazau2Af2G5ROjQSJAGKoe5z0YfXm5sEziCtDFRayxnNOCfEXOorufoemGCY5Nn1YAImvshsBNCcnJbSNCbj05p11wagy7Ou6/FCUAJy+Q0bwKL85m2OOUFjMsIHQLXhrFH/J+ZyTuhYWS4Zkk7fh7YefXhe9QB216NdeDDBGfNPPQE6G3Qzr96zSdpBAKdOEsOMk6ic8CMfAGyt5mOGHJuc5QRwyn0un17bpPXpA3u/AuAbFpSia6xKvPkTgLh5TkA+U9VrbXs1YzhzyrNB8/HZIbMUrlKOHQcoV3+u0b9Mdk8+t+NHquy9Im2hpWiyu4g5sVLljcDiP1cU7rtKVnj1JeBLYZ9w1w6Ht8c/5/YKM/3Y378AAAAASUVORK5CYII=",
    },
    {
        "name": r"EN",
        "sumerian_transliterations": [r"en", r"in4", r"ru12", r"uru16"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACJElEQVR4nG3RXUiTURgH8P95d+Y0nalF4VYmtQ+82AodQzK78AtvIugm9MLbLlq7KKiIqOiDqNhdRUEjMjIqqyELR+FNRRtLmGaGLEbmYh+VbjO26fa+7+liK7Z373Nz/vDjOZznPASlVWPv8frSjf0NntEvvlCtpRfldWKd/Ukydq91kqUjWfZOwsobvG0w6lPAvOjcML7ULmG0+Cbu/jIAGAq9XD4oVeDYaj6wV28wDMwx/2ZQKbtHLA2vHiuQ/o1HqUr+Nt3x1feRgMWN3nwlY1WMngOAlcE8ZJhjpsuf1sD2UEGOQdS2yRThNSomy4jZv/Ng3SNEnpUeBkDLyzPTvZ6NcaKuTpTvruoIhjN52ibfTWaGfwoMpJ8AXCWL6npGlVRBIDv3j1a3OwehpVZEE6epkb6sKb+tLxyNJcScwUNdrttJiXvNDifQq2s8u0A3XdFcXyrjYD7jBKAg59s76ez2Q8aH0xGBFJGvslhPAQBp0z6J0HD06MUHgRBf5Fyqb6rLC3CmoSACIgVLZ1ayiUSumgBAZ9cLh+sz0HzNeODWskB3ap3h0WcfYPUDAPRjinqyDmTf7uiuE4Bsyt4z4Xn6xr+xcLv5/vu13QBUh6eyl5SYH+aqbyb9/IV/H7TlqmADAJiCCyrs4gD9+MxY8//B1M8D9QCA/ckjhSWc5AdKBt86d7wQzixSAGDzvngJx0/vKwSHonBa7xjLtqIqBvoXkHDP78BY/30AAAAASUVORK5CYII=",
    },
    {
        "name": r"EN×GAN2tenu",
        "sumerian_transliterations": [r"buru14", r"enkar", r"ešgiri2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAADJUlEQVR4nFWRW0ybdRjGf//v+wpkpbSObhTUiVvLQbO5ZKDuUCPeMBQzTVx0roqboBkoE5YsEmIg83zhNk0WMwbiYUHMJDHpWDYTDVow2xgBmSiUQySycWy39WBLab/PC9ox36snz/PLe/E8gv/ftjr/+Z6c3E3XbM92XhYm+5ZEIG1IAiCvS4vcCmiel0uDmncmFjmSAAp9W5eFfdT1+Af+g4i35p+y/d0kx3Nzu/aiWJZl/v1/dQBrO7sujmYDyNm2h9sGvZUCIQFprrB2LNdiTH0prB3UIWDdybm0koGsmScClop+v96avd84Pt7l0fTl6fYxFNIrd55udm7aUVhxLKXK2FOoOZ40uoZGFabnrvuB4u9Hus/IYD08XsFzI4N/Vsh/LJYBcKI7E5Q3i6Jk5qvWQPNCfeSrbTXH22JC7F49JojmLwHKx59Ytu+tddbcX/yFfDzifKYvCLrH8i4ohO6bABQXOLsbPDcX7nqo1Xb0y95FgNY2r0C91wwoQKA9eMQU/EwraJBqxr4DmLkEMJ8RB6BTOnmxdGhnSkNymQZi7vmNvRKRwpu3AdVpacTd5PqhJVcHLJms/8iE9TduA6jhs3uuJQ1kPBAUoGVVt8SAezYAUnwM5dz5atkxvisMoBpW9o9/4HJgT+1H12MtVYDU99o+p0b40SktWa+INNkLXGWxbff2K6MC0GzTOasHpUhQqIfyFWXfjsMTAD/iq60/AIB3SGmchI3r7W84kMq1/iIdgHJqlXN2YhcMfzh1AKCpd6gjSVF/j5qbTneN+ZF/ynD9XOIzxKS3ZzoApALqlgTrL51IOXTrygJaKN0ybIr4lp6+MVsMqaXVoQcfmVRQpVWL3vmYISKb1Nk10TUvRCvNNsD+9efN7wsUsowO74Vfvo0U+dyApn+1PIYAJs9aNxsB5R3t14LGnjPtV8uXG0l9pXvgN4DMoyP/boGk+k4rJZ5+jzsnUd5Wt9cAYKgNVUkIcxbo3m2dKlmpt8BXB0DypyNr41Ze3znjCsDr03kApPW/F9/CHXIF7gC+WXf3MIDPsTlhteyV7gDQJUZU/gMG5jhiZtiRWgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"EREN",
        "sumerian_transliterations": [r"erin", r"še22", r"šeš4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADQAAAAeCAAAAABGJGJnAAACCUlEQVR4nIWUXZXjMAyFv+0pAVEwBS8EFUIGQgZCBoIDIYHQQLAhxBBiCDEEzUOSbXf6M/fFx5FupKtrGxCbhRsaszXOZuv9x0fMNru7bWvLEGz1bzkEW2zQ+70G09f5exKt/Ye4Du8I562jjjpV1wA9IC3js2SrqWTvGoDBLK4WhCEMAUBsflph2PpY/wCrfI4R8bmo9AB06fKUFfWSZnc54QfJCZBaSi1bcF+8R1RQj1Pwjo/Stf4rQ2ODNWIWBGLc/xj3CZnZHI/xNNCZLXBm6pt+8vWZlV9SNfkk8jnk4tMEY7cLUFMIy7JewzKrqqrOe0Vnkbj6xgLrss9CjpEDNbeaBe16QOquLWeS5kIibzor9UZSXy+JSGUs4EGkABUy1C39H0776hgT4NtpPz/N/PrwHZXG9ppSFikSCkglEaeKIwgKHhEFOOalptAtwcxsiXG1Oa4R1s6e4o4UbQ1CDODmWWJE7eohBtTAlBh26+40KVO/SS0XFgd+/Mi/aepbXUZcUaAfXKF/OYY7n0pu2yxOAcbm/bU9SI2rfzMxfwHg378Pp7DF5bB8Q32efVTqtN86atpUHNuMXHlLOk1+ew5qEv9LV7dKheI7l9RzSTdNRzhnaoKpkO8NeHyKfgFwhjaQfvjYML3ozCvAYHZ1P0PHtX+EOIDF2sfQaxIAZ/f55F18bxPfrSJrsa0BoLgAAAAASUVORK5CYII=",
    },
    {
        "name": r"ERIN2",
        "sumerian_transliterations": [r"erim", r"erin2", r"pir2", r"rin2", r"zalag2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAdCAAAAABtMQhgAAAAyElEQVR4nI3PS3XEMAyF4TtlYAqmYAqhEAqmYAqiYAqm4EJQIISCKPyzaOfUzqpafkePK0lSCtNSX5LUkp5VYTyo4cM3KRNPjW36BmJikpKXX0zH2SGyJNYVycKTBFumEp4KTntgI09m3pD7NPi0WpF0AsxhP8cPTNLgrn8xHZOMvmzqRFddKU9avzcy8KOyDY4ZALckxZL4HHBKgi2wR5Fgrq8lj5IZeNrRKJWoGxJtAvZad0rfl65r6+vrWUma1Ieo/4vyGuENsR+Jj9ODu3AAAAAASUVORK5CYII=",
    },
    {
        "name": r"EŠ2",
        "sumerian_transliterations": [r"egir2", r"eš2", r"eše2", r"gir15", r"sumunx", r"ub2", r"še3", r"ḫuĝ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAABGklEQVR4nG2QUXXEIBBF79kTA1jAApVAJVAJVEJWApGQSCgSgoQgoUgIEqYfkOxmt+9rzh1482YAJZuiy4ns6yayA2yy6aPhZZtn2Q1AkF8JpjeC6NAwQRjloXUPMLTfnrr0D9rRy1lk3SX04Vo22nvHfVqxYyoVgAQMGK9yBFSl4XJEnsUpkXBEXQNwI052irpy1QBpTOTFOx9rAlCdN5XsXTa1vHBr+IqtNAC3Yxum+Ox/8KX+rKM973r61JJGSymAyRd/PS1to/Uyl3h/yQ/A5J2LJf+b3xZLfuFO85Gf8/ezK1K5+Hs7AbzdJ7n54a/qyQvFjDpac/UnCF6uCi2PH8npaaQDGBRz/LxEMQCD5XvhXTf9hivAH4Zvneg4tXzrAAAAAElFTkSuQmCC",
    },
    {
        "name": r"EZEN",
        "sumerian_transliterations": [r"asilx", r"ezem", r"ezen", r"gublagax", r"šer3", r"šir3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABUElEQVR4nI2UYZmDMAyGv9uDgVo4CzkJRUInoRY4CZkEJmFIaCUUCUNCKyH3owxKD9jyK01e8iTNV4DKbFB16MhIgn0Pk+uZnZgoItITYHSZbgp/nMygATt5ADoAuB6WVU+OnXSzr1130oKV3piXH+MrrBWgCAC7ZQwtZv1OpJ+9ICEIA9DrzFqKQSSIywkV+PHIMSOLlahzdk184wsgN6lhnsu2fkVHhXHKvkk/gKFOelp6LatKXE7OAQgisgyzRR2hRC/t1Prf4f+9ARjHzbFJv4902yVru2BQ/j2WUfj0MfqpnaGVbC/Iatgz29fojQ50n2ydoJh1f6qBADSASux93jXxplfFw5zgBDSAVtf9m6XUvvaVcq++PdiBbzebbYAF5GrBhQbu2L5Yo+/75YGhQj0xdHEFxGMpuRKFJ61XQXgQ9tUJPIU//V9FOk3/ATwtt5vwl/26AAAAAElFTkSuQmCC",
    },
    {
        "name": r"EZEN×A",
        "sumerian_transliterations": [r"asil3", r"asila3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABg0lEQVR4nI1UXZnDIBCc6xcDWIiFPQkbCVQCFnISOAmphEYCSAAJQUKQsPdAmlDS3t0+bWYGvv0ZAjRhgmqhd0ESzN9icpO1TvQqIjIRoLmmuyqPSc8MmOQBcABwfXutWuw6yrjl7MZfSjAyaf3I1/UBswIUAbBub4NFH+dEpi0LEoJYAHz0zFI1IkFcIVSw93vBtOzBfQ8QAwRxzhxEjw+AXFLz1pcZyGYVe5XxuUSFmAqh8yegaZSJcBRwn1all0VDZN3LcQ5AEJG9GRZGL2OhxD1uKN+XIQ3+a64GlnxUNiXbI8anSXb5656/2/lyj3QCL5iVb8E8IF9zi3aAP4HIN5VO4OWEbOIz9E4KAI1tLyhueBVmaqXf9Mb32bQErcX3xQOAUcUFTx4IwAfAE6IvDZMdjslJVMpvhM0DOoDV9TTZcjAPj33lUqsfXivhh6fNdsAutM0uKw/c8PxiNd9eXw/MjdSTBVcvhmysLVdL4Yn52KgHoZbWsYj97/9qpV/pH7iJ1C2Wca7QAAAAAElFTkSuQmCC",
    },
    {
        "name": r"EZEN×BAD",
        "sumerian_transliterations": [r"bad3", r"u9", r"ug5", r"un3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABc0lEQVR4nI1UbXXDMAy8txcCpjAKGgQFggvBg5BBUCGkEBoINgQHQg3BgaD9cJY4brpNv/RxlnXWPQONuWja1Csjje5vMPlRxKvNqqojAZbrclf5c7ITAy4FABwBXF62NQ/Jgw6rz374ZQSno7Wrzzn/pNkAhgCI32iw2v2c6rh6UWNUAcA7Z9aKiI/qS8FEud/Lcaub1VDv3V54RwfQMqRp5eUOLM0wpeLaJQGWBh1pm7XuqnmLvAe6gQAX5rP3mEOow7c+9eFrOkOCUpOw+bH5rHmdxbBkqSkCHaZ73dP427wAIEmtaDogLIcBVyopvT9DjxauZSymtvLWxJ8FienjAvMM5Sq3kw5wYwu90gvdz64tUC66bzWgtQYi0AFmkRDKxSR1D2NkWguyAB3A5nJY4H7d0v8sfCmzhv4cidAfpNEBG1CuDa0decNxBZZv5+2BqYEGEnD1BCRzLY/DYgMx74IIIJyrE3io/Pe/yk8KOdg3c9/ClmGtpaEAAAAASUVORK5CYII=",
    },
    {
        "name": r"EZEN×KASKAL",
        "sumerian_transliterations": [r"ubara", r"un4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABv0lEQVR4nI2UXZXcMAyFvzNnCLgQUghaCA6ELAQXQgaCF4IXwgSCAsGBMIHgQFAfkk086U5bPd1jXeno58pwspDd+emVieXwb7JoilGtK2ZmSaDztfta4WnuBg9hHgGfgfeXad0jlt76FWev/V9KCJa6bsO+lK9n78AJEHVvw1t3xBVLG8qWs0XAHz178wDiADSbrg6X4/0OgHW2mwdc8QCqGg5HwxVk6edh6ysAcl8aIMjs+mFeHd0yQye9JeEoQMweCn3OVva5qgLZzPZmvHk00j1iUqf6lWGlXtq5HW/DMdokMLyFpl2YpHmeZVceO/ZWTB+4e8oBzYdyVOHC4MYq8P3HQNL5VxuCW9rlOSsaq6wevCXAFYsVR+FyipMQ9SYBdx/4056yZsuKy33uMQtPWQHNlQZ8tABiCczyuYAPqXV/m53v9SYBFjkfhJRV95sGpFhOuBys1kCGK7gljuO6a4kw/dTmxtJGnIvD5ojr2OKx6lWEjQmAWdk3u9U6tvUOgPltAmBsp/r5CjsxfmxgY0wH85Pni+38Jy9sOFFHifjq9CVO9cpqKqN4fyhkRPhuuwAPi//7Xx2z+dZ+A0iPDEcZ46DgAAAAAElFTkSuQmCC",
    },
    {
        "name": r"EZEN×KU3",
        "sumerian_transliterations": [r"kisiga"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABt0lEQVR4nI2UXbXbMBCEv/aEgCiIwlJQIKgQVAi+EDYQHAgOBAmCDMGGIEPYPjixndyk7TxJs+M9+zMyvCBV90p9glhN/xZLHlSzxWZm1gvEcAyfDudxjrcAabkCoQK/PqZ1k7bONHrA1ZC7v5SQTGN0rQMIbXrQwYHzgOatjWARNE8JoFl/p6vVagqEvedgAZBWewe5Wl4DruowAGDRNgSgmuok5JzTHnCcQJZuvt37SoB60rnUL5zryrgG4rxAlM56YS8gNJu0DlnN2jbXnIFqZhZ3qWvNtGoTLD8y3KWuhqz7BMJgNk2dKdhGr9LTchmW885FzhJLLF9v5374Olpz4K15vmf9CfPOCIsjDvN44DY8Sws+IeK9B30jfULpUpwXXxOB77bN9eCB4Kc8ZTMbzDYPbLVepHZ+I93ocReu8ps5vT4Iaavv7x4Imqcm2mNHD1T4AaFnLGtvoucCiuDOi43OlXtA19nrvurVhHSuCZi1bbM5r/F91XcpvcI3D5ygPO56eZzGK8A4btLry9SmmuzwnO1lCcfHXUQJB63oePsgpUgIy35DOEqfCjD93//VPpu3+ANnnBWAjcKonAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"EZEN×LA",
        "sumerian_transliterations": [r"gublaga"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABvklEQVR4nI2UXZXrMAyEvz2nBEQhFExBgeBCyELIQtBCaCG0EBwINoQYQgxB9yFpk/2/86RYY0UjTQKfMGT5fPQTgufhb3JIN7PkcXF3vwSIekyfDnGp8a4wtCugGTj/WFZmW0a3LdY0/tLC4BbjFusyP45VQDrA0lOGetzvuV+2KHvOboDumtUPQlL2tCYk2+22Xo/+xIOqg+aUhj0hvEBIlQlgpMlbWanBmhShbo+x9pxiVSnXAjA26CRskwuEdp62l4S1ZfdVjC42+hhCh6yqUtj7ToBkTeskzZfZb4tHZlNV3wb8pJ7a+631ALzFV7ldS3dH5MNGD/MzgGQY6qqe8qLA16pQVxlDrCZEmr7FS/2m5JMqUpgClXt4H/oK/g11Rfd6tQkK0qi5AMhXqkqDHhpAqwHOEzgDr58Kq89j9wgVEimZmfu8myMlAMKy+n71QLBMXud69ECGF9ALZVq1BevLwlkqkCgi05aw1nMCleeqgUYdG8CkofXlebo2uK9aXcPycPcXDxxgoq7SPR6P24rx4xcb9Qqt8Q3ufKROwdCDUYKV+yF9pDIF1b3oROBIPWJ2+9//1RJ+Tf8DF3UO1YCRGmYAAAAASUVORK5CYII=",
    },
    {
        "name": r"EZEN×LAL×LAL",
        "sumerian_transliterations": [r"asil", r"asila"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAABiUlEQVR4nI2UXZWEMAyFvzOnBmoBC7UQJHQlYIGR0JEAEkACSKASBglUQvaBf5bZ3fuU3Ny2SUiAC4rBXqlPcDoUf4td14TQqZ9UVSsHXo5hc7Dj6FuBItWADMDXx2vtO0ylhsWWrvwlhUKD94st03ulxYLNgNBtZYj6/ZxqtViDDoMGQPaaRQ+FdIN2c8AOoWnm4143HKVdV+wBiwGXyrFd6iqAKj0Xz5Z9nE0/JowfxcZ6YaTwYMX3Cciy9NUvL7g5ZdWtGNHpPen0nkoRGTp3SAZM3j3L2G7cq7CpRcoI2frWApNeTcp3P0ZLJvR1i3KGoW3qIzHW4p5jy08YGC9U7V83Qnj8lI7xVsnjngbgMrYP5mm4Q1FdpS83lNmddCxOC2EgpWcVbqVjW60XRzBgU+j7uTZ3OmJtaJdASGBA7PapgRdpbYlL+dqMNOfa5wclKW3d6/NT2wxswnBpfdyVNeeN9VLzAe1F2ruAHNbAhXichaOU3omk3cNxNzYAbw3//V9N7tfwN45zxOeVwM/YAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GA",
        "sumerian_transliterations": [r"ga", r"gur11", r"ka3", r"qa2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAABcElEQVR4nHWTUZnrIBBGz+4XA1iIBVYClUAkZCXkSqASshISCUQCSAAJIGHuQ9stod3/jZ8zzAww8IfW7a+dk5L0jnlDWZHONrK+UCqFF7eIVx0VxKzSmJ/AUU1yY0t5HU3FPZ0PwNnJGY6nOd5j9u96dwYAagbio1YN9SuPxtjxOz6DQymlSaqCTfoWUMryxETSqQVbHk2qTTYFMJg8kms5Wk49VnWaXZoO+Ai6KvJ+uo+lxmjUjo5gs7le6+clTzW3TD0OsqpqxLIw/1yui9cwS/GrnGVCmp1PavUe0EVASbjX+ezJLIISh5YZdCjzQEXtKpzyQoQKRDKzy5c4AFmN8YQ1f0Nt9udfZQA0NcYWa+50Zdq5PZbKu+OtFvL0yCMicsbEGAFZt19/AIh1sXv7DhqMZq6XxhTxOHknfUohwUtyjSdegrF9JSLtfwG2cRHrEx0WulEAfOoO42VgAExXGfQDeVPox9mP7zDr29V/Mifk522pma0AAAAASUVORK5CYII=",
    },
    {
        "name": r"GA2",
        "sumerian_transliterations": [r"ba4", r"ma3", r"pisaĝ", r"ĝa2", r"ĝe26"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABAElEQVR4nM2SUXHDMBBEXzImIAqioEC4QkggKBBcCAoEB4ILQYZgQ3AgyBC2H3U79VRu+tn93Tfa094d2vtCVdmmAYINqIQ6EqSiohLoVWKdiUr0OkOrUXN0NSaVsxJg8rFoT8VB43FnR33mYG8L0EklVXMgygBmjTsAmABQtwd8Is1hn1h1fEr8K6TB8jRMi1m4Dbhg1+kn5MbNUvw3a60uR1dmH0oeS7R5ezxrdb7jkmPg4saAr8XQSf1YlCBpnrfe+srCrQUmY8LfbIOsqVHY7kWts5DahccJSPa6DQrp40dScjkDpFyvzrjeq86XjsPpCUHz8gT44xoBlscvyDt4+a3xX6k2mAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GA2×AN",
        "sumerian_transliterations": [r"ama", r"daĝal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABW0lEQVR4nIWSUXXkMAxF7/SEgChkIbgQNBBCwYWQQPBASCDMQHAgOBAcCDYE9SPT2dONu9Wnfc/T05Mu41JpVtRtBacrVlwbUbNixYrjbsW3GW+Buw0wWrLspcWEMlgA1Hpf7KcqAl2PDELbs9NHBWazEv7tM6p6wJsCZEtnI3POM6AGgM3ncaPkBOIPpLucHcy1PkDu0yH/diL6hHMg8bHRRnx/+XO7Q1yW50t3EpmXxyojy664NsI2yF6hKjQzhzALmlJK8jV0h8Zt3XBebivi9KOGXidhj9dX4pK+LaUn5EwI+CRPlfi45nqVuEk/7bNcd6bD5rKP6yGSzauFWETK7O04HUcI8FrAbHZPxQKMlvNX92H4i3SV2whsyk5/0ydSUXjmgjf0x4s6VHrCWNnfgaDT94xcACCaBYkRIMRmmJ3ysTR/XvW2vv9C0F1/AVondVYBoO7/QT4BjcLivZ+3ZFYAAAAASUVORK5CYII=",
    },
    {
        "name": r"GA2×GAN2tenu",
        "sumerian_transliterations": [r"dan4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABaElEQVR4nIWSXXnEIBBFz/aLASykElgJEwmxQCSkElgJWQlZCUQCSAgSQML0odn/tJ0nPjjcYe7lMJ4ruxUkLWBloRS7j4hq0aLFMmtx+4xTz6w9jBp1dWaP8aVXD4i2ruhvVQw0LaY3PL3ZnbeFlUsFJtXin/r0eh3AqQCsGh8Ba32J/W0oAHR6VDDrFKLOtOs0l3ZDnqqN0YPEiSmunj0k6FpM39s4scZro8Orzmiy+ySkyhcSDsDHC5KHapn7zt4tf0VgyEla1+XbRvP+oKEkm+vygEhIS8I6c1owVobEWaxIynckJfvj5jgCtcIZ0y/3RD5C39X8eaxLqkOXa5chc8mPjq/qRH0oxpTJ6TaHSCn+FsCkOseiHkZd1+2eMd67K9JUTiOQhEx7kqu4uSBsiTtFfv1RPyotfqzkI+Dl69kh6wEIqt6EAODDu49AIwzn3ZO7L8vxH4Km+wfYS/pdBYCa/0C+AcPP5xRWrojvAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GA2×GAR",
        "sumerian_transliterations": [r"ĝalga"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABPUlEQVR4nIXSYZHDIBCG4fc6MYAFLFAJWwmpBCohJ4FKSCX0JBAJICGRQCTs/SjXTi5Ju7+Y4QE+WL6628xmRckDOBnQ4raJqBYtWhx3LX7beA3ctYVOk47ebJlQWg2AqPVF96oYaCymNWxndvIzA71qCZvngFcBGDUtgRPBilhAFADt/y29a0JU2xdZlSkWQuRJDisy57aPyOux1gSGdp6u3r8jOd/sdGqj7BOgtYlsH+NmU3SW4wxSicQ8ZJw31wHj5JIBd8yLS6ZFUyzRpPo/6rtEb8poXYmpeBmLg5hqzkoa23OO3nFmdNhLBm7DMlmvek9FA3Q6jgD2OVd3mbl2QBYm7FUWpkbyiuz+qJqF0M1MRyDI9zKEC48bqQYTI/y1d1WNcLltzjzrMBw/CJrTB7Db6cUuAMzTG/ILocfO3rVT30AAAAAASUVORK5CYII=",
    },
    {
        "name": r"GA2×ME+EN",
        "sumerian_transliterations": [r"dan2", r"men"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABaElEQVR4nIWSUXHrMBBFTzsmIAqioELYQkggqBAUCAoEG0ICQYZgQ5AhrCBsP+zk1Rn3dX+kkc6s7t6rtzQ0DqvIPEKQEdNwjIiZmpoGbqbxmImWudkJkk1Woztisp4sA2I+qv1W6qDzuJNjaBBk9u4KcPI0HHOTewN6M80OwE1FewBCrSFM1UUTgGrTQ0iw6aHCStGEGADW/7AiPwbWQJYN6d5+jDAnd1mNdGkJ43ba7ecMdQbOtHF5+vCKDHdgH8keaeetu5PF49f9+w65yxO+zEkOu5zCuARwDHg5hw2RMo8zIbrr6EAW3yDeZwnLU5Kb9rFMgKhH1G/Wlei0+qBl0ihVQw0A0kNKG1ItiuWizmkfLbIZ7IFHAL3ZbVLLkKyWvUtbAI1rAmZhwf8bejVyXaIhv/6otYsnp8byAWS57B8Kq7Bill0pAPlFylad8DUc3jzrffz4g6D7/AN4Tfq4CwBt+Q/yDf8W7Vxzj4deAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GA2×MI",
        "sumerian_transliterations": [r"itima"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABZklEQVR4nIWSUXHsMAxFTzshYAqm4ELQQshC8ELIg+BAyEJIICQQbAgOBBuC+hFvp/uadvUpn7m619LbcK+c1ippAycbpbhzxKkWLVocsxZ/zngNzNrDoFGzN2dMKL0GQNT6or9VMdBZTG94ePZ3APrlsCNLhc4R6zg2Iuz9uANetqOxAJ2QLo/YYbjOsgMmbQD7Qer0cGemPEvsAXIwAKIA3duDkGlZSG5wgPF2B/7PGWcTgmQL0L6zqXwhl2FNNdl8r1CnVE9UoC9Zsjm82DMVWPaIyQmwxlpqOtrfEdJtTuMGRKFCbxoia9pSFXHjRt1tBViWHUDagk18Wor9pnp4YfWmZOvKGouX/Hw8za6duK7ecTXRYW/pR06YVOdYNEDQnJ/fmkplHIAkJOwoT0ib6hX59aKaF8JQ2T+AIP+eB7lwJFINZl0BwnriFTrhdj99+ar37eMFQXd5AcD7S6Jtuu5/IJ8V1eln8Mhu0AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GA2×NUN",
        "sumerian_transliterations": [r"ĝanun"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABRElEQVR4nIWSUZXCMBBF73JqIBZiIUgYJNRCkNCVkEoACUVCKqGR0EhIJMx+UDhbCIf3O3cybzLvZ7hWmoqSZnAyo8W1EVEtWrQ4Ji2+zXgNTNrDoIuu3rSYUHoNgKj1RT+pGOgspje0PTu5VegcSx3HdyImDNwAVl2aRrzGpVeAzl7Pu9LF2mxM5Sj9sdkLpsR1mkqPLIgCHPaAmJpOOed0g4e/7mWHy80GCzbwnPLyCjXXueZcPxwOsIZIDCGCxM3Ly6DcaOuQmOaE82acMU7ODSQld4/DMAC1JlLaM9GbslpX4lK8rP/C46bNC6t60RCLMeXidR+dDbmoTkvRAIOuKw2kq4wDkISMHWWHbFO9Ih8TtV2aMFTyEQjyux/kwn0j1WBiBAix8XHQCedrs/LUYT5+IehOX4D3MLReAaC2LvzQH7JD0GzRg8wMAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GA2×NUN/NUN",
        "sumerian_transliterations": [r"ur3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABZklEQVR4nIWSUXXrMAxAb3pCwBQ8CC4EBUILIYWQQnAgZBASCDaEGEIMwYagfaR9Z2uzN33K1/KV5Gb4rBxGkBTBSaQUd4yIatGixTFr6Y+ZXj2zXmDQVbfeHDG+XNQDorYv+lsUA63FXAzHzk6WCkyqxR+843TTogI0m03djxJ2t88MdZwbAJ1e789Bt1WFrRcFaJsXYBgzZnQukvOeaV9rSA9mMASeI31D0ii4UYar89YcI3cEADPXKb03une0rtu6qXc677qnNyTHZMksKS1PFwkpJlxvxohxku/UOIok6mNcDSZ8/w21morJxkbcldAAp3Dpav4415jqrcu1ix/Lku4LXfeUbe3ENfSOK5vD3tKN+rqxSXVei3oYdNv23M5czGMBlXEAkpCxo3zXcg/JXpFff9RexeKHSj4DXu4/JZwHIKh6EwKAD4fjboXb5+HJvzjF8x8EbfcHcLTG9yoA1Pwf5Aux293qd1JcuwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GA2×PA",
        "sumerian_transliterations": [r"gazi", r"sila4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABQklEQVR4nIWSXXXrMBCEv/SYgCiIggphC8EUVAguBBmCAyGBIEGwIdgQZAjTh+Tcxj+93TdpvzO7I82lu66cVrapQLCCajhHTKqqqoGbajxnohI3tdBp1BzdGZNqqwSYfKz6raqDxuNax3bnMOEXINh9BQappt2cUVIAogxg1rgBQgt+HtPDFAAa9l6TI1V+kMvehsvOF+cngJIObYCgMWLpRaU5qPT97kfeDjKt310ch2m5l+DvAH64nA2CpcV5+zk3WJ7KRIiuL7hgV0qP2ReAdc/9xs2nhABbR+To6uxDzWONNj/D48IrMiuaUq7O1SFqG50nMki3sSpBp3nmBGlW+g6YjAXf2wZ5RjYK+zVRDxVP6laWdyA9rL6oPIxlKbmcAVI+viPQGJ/X086/eivvfxA0H38AZ2E4qgCwLv9BvgHF9dPQcSCzFwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GA2×SAL",
        "sumerian_transliterations": [r"ama5", r"arḫuš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABR0lEQVR4nIWSW3XDMBAFpzkmoEIwBRXCBkIKQYbgQFAgOBBcCDIEGYICYQ1h+2E3jVulvT+Sjkb7uKuX/rpQVZJ5Ai8Tpr6OiJmamnpG01BngkVGO0Fv2UpwNSbqySIg1ga1Z1IHTYs7OfY1nz7W1cvHAgxmGvd5gt03AlAs7wGJVoavpgCw4UeRXoupPCK/1ZfscvgToQQY4h05VJAb0PGzgJ2SjR5C2qI0VajNE85vw6slgun1+E43r4cGSfM044O7TDgv3QzdFT+cp/sLl3dDaSEJkv130yk4La3XlDVIUQ8kCavjG1IsiMWkzukQLAChlHFNsCGD2ZjVIvRWCoCoukekWbj0wCzcaC8CcJWt3W0Jhjz9UWuUltgv3N6AKOe9PT5ublt0KQHEVPWxEbpr9eauw/T2D0Fz/Ad4NsZ9FACW2x/IJ3UX3Y1Kr/QPAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GA2×ŠE",
        "sumerian_transliterations": [r"esaĝ2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABZklEQVR4nIWSUZHjMBBEX1IhMBSGggJBB0GBoIXgQBhDiCE4EBQIWgg2BAnC3EdyV+tb53Z+5kOvRt1dfRimzu6U+PmAEB+0FvaR6N68eQvM3vI+k92YPcHg1Zcse4y15AZE19z83TSBkyJJ2GhOd12l6xpV7h1OgdrH8Ssxj7DqyiOPdgdYvG6EaGmDm5tbm6MDHHz62GpU0S50kYlHObzxGutQU0mlPq8cvyHTGD/0Ei7hQtwPDFheOxZ/Q2RTE9Ob1PwGyR5qqqnmWl6O/iVMVbt06dxfjo5Er5aSNbcYk9WHyFVHnXRKr7wOSPnahn7uZUK7rGGar/MBoGRpi4ZWastxaQG0EIkow/yUu3iObqWJtFv2bXWecrm5z7W5weDLwg5y6owD8BlZ0XGbZ/gTA/Fto55XFBs66xmweN1+FAyA4m5SCoCV3bhPkY9p9+XvHB/nHwhOv34A9ir1/QoAff0P8htvA+nMGzE1dwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GA2×TAK4",
        "sumerian_transliterations": [r"dan3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAdCAAAAADqAOFmAAABUklEQVR4nIWSW3XrMBBFd7JMQBREQYGgQjAFFYILQYHgQLAhyBAsCDKEEYTph7Pc61S5nT9p9ppz5nEZHpVmJJ8XcH5BxLURryoqKo5JJbSZoJFJexh01RJMi4nSawS82iD6LsRAZzG94Zdnu5mK83MFRlWJPzpOSlFRKRIhqAcoup6MjGsqmkavBrwCXO3jdhKZa55zrsty/HaXRisVcP38fF1fsi7YHsCYY6KvSMZkwK7ZHkKvIrPZgJ6tt1u7ShwAuF++lsm8EXJuNzF/5Gn/uuBTXjIumPuCcX3F5We/Brf3a9bzWsbDJ0EBSMFIsU7SKsEXif9exj5digavMYkxMgY9n84TGVWnVTTCoCXRQLrKfQCyZ8PO/oS4w5J/e1F7FUscKtsNiP7rLOTi3pFqNCkBxBcrz+g8n49m5ojrcvuDoPv4A/i9xlYVAOr2H+Qbv0Ph6Cq9WFwAAAAASUVORK5CYII=",
    },
    {
        "name": r"GABA",
        "sumerian_transliterations": [r"du8", r"duḫ", r"gab", r"gaba"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAXCAAAAACkWak+AAABY0lEQVR4nG2RS5EjQQxE30YMAVEoCloIbQhNoQZCG0IZggZCD4QyhDKEMgQZQu5h57e91kGnF8pUJjyZHrAIbG7Q+jOkpWHZIAYsWlAckaqGjTSqVjw7DO12QFRsKKiaeKpCSLN+U9YU6WOMbc/ea4YKLw9OEe398cEs5eSMt3OWx2mty+Va77zA9RJWr1+XivEAfixCQ7P+tLNPH2O2yL2v2bXAVG7/ePZUsVBQJStDGyj98LsroKtQ1Sg5oRnHqVqxuRttFlztWc7MHaoKRQ1iclQCNhVsxt9SXJU5jmJVgY0PP54Tdk0/IFpsqNMk81SDpswoX4SFQj7HaHv2WTO08KvGq1dunzmvdrLO23lfbq/rxvmi37eXO3d7WPnUuy/1nZsXHu7czQ2gHbrw2VUiZ6u5jzKGFujKHwRgQ5WqgacKofasC5sdmhzPBmMa/n8Xrgp7/wzzeRdbh5IL7A1W/QFI3uwD8Tp1UwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GAD",
        "sumerian_transliterations": [r"gada"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAXCAAAAAAjaEA4AAAAtUlEQVR4nGXOURWEIBAF0KfHAmMEKlBhjEAFK2gEjIAR3AgYASNgBIgw++G6is4P51zgzatwDnusG4gVrnGSRJIsKEyrFOhOlLwXexdwkFKMFy9yC++jOMYSAYAA0BDFKQDWA2jivpLBPOXrh5Ze3LnY+qNNcP976wHU2PRYVEENWvOLmJ+kx2UoiZlhkzM3MvPUtqNeLq1+pzJG5w9RV2SoIUiRcFSNQVRT2t5Rrh/vkPEi4Au2TEtwDY8rngAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GAD/GAD.GAR/GAR",
        "sumerian_transliterations": [r"garadinx", r"kinda"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACbklEQVR4nGXRbUhTURgH8P/uzu1aS2MqojnU0BgSqSHOppShiUVJShmCkhIqpETZ24dwFVLNDymZQmRFFEpZZhBZYuFauBLzJdEgM/Mlt6nbdObmmne768PU7vL5dODH85znnD8AAJB9cVics8VWl1aOjCXubTh4lfM+63suLtoKAXLdlMonJkzlbPUFbRIFisXZ46eFAEAAwCsiJZVdrJwFzW25rZvW9J0YaeEAstXIbduVuKCYuTsDgBu3HL038+1nsfCNHaRU5xtiLO9GhJkFQC1cktZ6E2VsetTrPtJ5efJ8FwBQAgCArXcq3iC0iouTy8nLspJB/lYuW7gsOMA+dm7OTtiNTngYl5yp6tGMAyARlqq6V+w/Y6UxDTcmAADUyV59RnNtEiwutzn92hRugkBq+yMK2p4gmQgq/IUNoxKlU2n2uGRd8A6F/muOcP186QsfrClpU4GMop3NfmvkcOfznofdFSaXMRMZZr0mmmfeD4bqDIOh5WPPgE013HGPxvhPj6eiwYzuEdFMtvYYtZoD6M3+yK4YBrp+VA1T2oGysQ/LRkmT0uefBDQuQgBrTJG6WmUocnwEyH4DHbPXpeyQxC0BEM5deFo5se9qYmF4u5YoWFF/lQbwIu4cptRDUXP6lshH7VdI3p36m/yliEMgCzsSyd0ShZJJcb3nU9m4NGtIx2cdQLz80hr45AzKm76mdudwkKm+n+UPrKRok9hL1MvjA8+YJDtzja06BwvAhQOGUyMrM/yFEATH5tcM6PIBpkneL///r0lASkfrWYZWvdu9JgcgrDHBR8C0FfAbVg8u82/YDy3x7C/ziO6muErWDAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GAL",
        "sumerian_transliterations": [r"gal", r"kal2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAcCAAAAAAlqeL+AAABJ0lEQVR4nH1SUZXDIBCc9sUAFrBAJRAJWEgkpBKoBE5CkAASgoQigUiY+2iSg/Rd5muXGXZ3Fm46Z2wYTEoZUsseFUqZ9lAVkiTnmocj35P8xJpBD1xEzd/M3OtBbH2U6Cf1yLWgk1BapJjWTz0nXw0PLKSVRzaRouXBIKtM0p34u0d9JWM9C7Je7Llq40ItLyNj2oZE8OKZGhcZ6+i03gVYTRh9rRhYOA9HE9rS2EKnkcbGeRJpmn7ScRZaX7QhwPIPcO0iaN/vwFI1MSzFmWoGsgy1C49XtgMOFwprX/vsFKSRKcYt16sf22Va0ql6BrToVHpGXOC+Xj0EgHuUYVYXgs47L5bsc/5PAOQk1LTPcf4O+6KONHy5+HqssyBGf0ED3TUN/AKQBaNO9oITGwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GAL.GAD/GAD.GAR/GAR",
        "sumerian_transliterations": [r"kindagal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAeCAAAAACk+HkeAAAEGUlEQVR4nIVSeVCUdRh+vt3fsrDLnYAQBAJBbEAZlgWUDDEyg3RAhxlNyACCQ8x4LE6oU0TKUGA32QRmlwEbFomhoHKkgZztOrEcOrBstKiwswy7sAfft19/7FnO5PvX733e53l/70Xh/60w8IIiKW59Kn3uMMaVHrXf34UPADs0mnn2eLJsNgooMv0gAAByF01jbIg0v0x3iZ0XMGff0NIAQEJnrVESI1Qtsp4B7n3OmuBF8bNiHaYVOYF82cWX/qhnAPLFxRaLivtCkfQ25X6/Kt2hCNu6yfVMRAPAZbzFmsG5zufNXwK4yvbtCrIQetmO08xqloXulhYSX9bywXZh+ikAe7ZhqEL4ecYTJ96JAWmKuPJy7vRfNAXagA7j0+U/WzRM3mpkz9c9OhgJAFCYGvH07xLM7c85QgR6Vb4vq1hgwUq0uT4DtmGaGr/76JgOAMcKMEyab5Wo/U31MPqY62KRv5Dv4sIniXI2w96Lj5wPAEhtBrAnE99mySdzIz14ANkkOahkrLSBKcOoXWNe98hV1nmE5dpdfzIAwGkn7naU0SwZ7U72jfrSB7y4MAMAWLgupcssycnEgcfrmrV6mgVg5nCDLGsDkHV+LvbUdEf/PWYAYJ4KfWbJGqESW+teCxq5ogKAlSKzy8lvdI5ySNr2DVqvsvHlgvDI2kEbyuEKfAdUZr5fQEBAQJi7OvizqjCHhj6fl3opcue9kRH7rw1zk+I3hwMAeUWY8VNx/6qFExh0nfNifNtlpZECQNErdKbPirw7xfVVjpDH7osyHJkGQGJOvyuz5+VRqtWjH9Yq5k0UAEpVLY17ux3vdddsZSRGqkHS3A0ARBsS5tCA9fNO9r/Vc9UEANDdxPENDw8lVCh7xxbASofX8QAAB9iFtrwAq6ThlxmTujLO02krWTpFMbC7tPH3347uM9XwAVDho9Xh2frxmywAJkUdrS/scOwIaYeU9KMJaygR3qgzb9siXL9YbQIJZyNS2b5fNRwAK6HkXOWYrTczSSxx/7hrs+caAJczOydm8no/+VRSNUKyBU9Wtugty0ZOaOlt2xeyaV+m6gIN2noImi5vvxG/ob2d75MHOwtuOZVvtr9qMrsOAwBlA6gMUdFj1yoUSvL3xufa5u1jc1I3V+fhX+ZXSI0dBADSuuNQYs+EZpEBQLs6UQSGoGUnl2Vyp96aAgCQgeWvEk6q+ycZCtA/NOsgpZia6geHbT+z5vv0BdZLJNGuW+izskmGAsBKefbqkVjrERydP3ZZTwOAcbe63Ha8JMvFcGJ0xur5Jjk0DXLwRKKo4o101BQMr9Ml07YImRQ3quw8F6cG5MCaTOYRnFm498cu4lYmdYSEPCeeWOKP/1pya7AXRLF34DZz8+DcgaU2wWlJAPAPAIqk/cFeAhgAAAAASUVORK5CYII=",
    },
    {
        "name": r"GALAM",
        "sumerian_transliterations": [r"galam", r"sukud", r"sukux"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAACd0lEQVR4nGNgQID59YwMeAATgskn6KxMpFLrT8JRwky4lSKA8IYjC7/u9xdmIWgqY7L/qxcruJavi5LhxKGUGcpgE3jD6yMXGfJh0vYSVX6samOUoAZLztmxx5OBgcFq3tOns6yEsSj9dSdSAMLyedzJy8DAwMCg0nDz9RJfKVRHS2gzLPj/c5qFHDsDA4PE6RKYOG/x8Q8bMtSRHM2xbDvL618zLWMOH7vGwMDL8Q0m8bl3UqJvXdLWrTe+QEUSfcMZur64Zvz9/+TajWsP/6SgWBmw+N6NPgeI6yw/LmZgWPTn8L3tNTZSclK+z7LQ/GHeffnObD9pBgbHu/9dGRne/d8bBtX5BF0pA4Na1cm76yPyz199LMLAcu9g/xOIMDOGQgaGW21LfcIm/p7y3+EHA4M6XNgGi6kMDAwMvh9fy2Tt4mVgMWC/hFUBDMj4h796N+Wb8D8GhquH/fCYKp5z8OmyQMMFn76qMjCs/v9qgiUDAwMDg9EjdKVyxYeerwgVYmAQnfY/n4Fln986fdu7T16y/FcQ+YuiUCIpSOTw5AOvGRgYXteLJS1l+fF7mXOV0feDn/8Jsv5HUiicEia5c+mFNxDe6+qDmSxaHFP5Np8+9uYng5EBIrj4UmMldpZcegsXuFmuyHD5/8UQeQ4GBgYGi8cwt3IXXH611F4ExTls4gwXFiqhhQB7ztW3q+xEMUKDJfAz1DkMEJeyJBXynEq/8QZDJQPLfQTz328GKb9c4dXTXr7DVIgMFNf/O7Dw/psZmjz41TEwMLAknZpxf6cuN0GFDAwMrFNuzdbEI49Umvw+ybn1BnFKGZ5sfPAfp0IGBgBxud1H3wLKnQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GAM",
        "sumerian_transliterations": [r"gam", r"gur2", r"gurum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAWCAAAAAAK6IjkAAAAjUlEQVR4nH3QQRXEIAwE0Nl1EAuxgAUs1EIt1AIWsICFWhgLWIiF6WFPDbzN8b95ZAIAwNXwmi8AJPvpdcCyW9MYTHhM0S75W0OSmNcBXlsoPDNgZ3BZCKD8YWd+qAStq67pqVVxirpyjyb67Kl1SOMcYSna7imtRwK1K8qmtnPLxt2XwEj7bPjeZIESD1omREoJ/EPNAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GAN",
        "sumerian_transliterations": [r"gam4", r"gan", r"gana", r"kan", r"ḫe2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAeCAAAAAB7tgMBAAAC60lEQVR4nI2Te0iTURjGn22f3+Ztn/cLGqYLrSzNnEXZzTSLMHBiUBbmH9nFJiWFCRnUTFNDAq2ZgmCGkYaFMrsY2EVNLV1E6byQsVBHXr60ae6bzvXH3JzSqvev8zzndx7OeTkvYLkKRKy/7C6WbUuN3aJiW+Scs79vSuD+BxixeaxTnBNgaVvga7yXf6CN2+HGt8n8P3KEVMI11x4ZirodAOC3DIxqf+S51Akr7r3h4pD/fmkDovK/+VXmGZVIbeUiJ/juaYw9XbqEcyuU5Q1MFzkuyJS2B+NvevY7PZvUN69kA177jLGzfGGUTrKxMcJglMk3VPPriXb7mPCpLABhfSkOfIqiKIoSlnYPlOQyE5mGTkd3eGva+jMcAA5BACMNJ9L7DBmzAeqGkF+KMvG2y3IdMD5yiJxJbAWgAwHYeXZpO2fYADC3dUXhyaTY1vrce8Xlk2RAWHD/uY+mJwRWrzetRTJBQi8FcNL7irZn9ul31gQZOwyucNA+zpYZZrM1bSABq68AdPkd95PUpbEfpnUmEFaR1iHtjp5N8RKDxQGAQNFQz0qPmz9vDZpA5i6ZLpPwq4Nf1y929PzxT+mdIVeCftSZrNotWNOTApyhfQAclAmONfBCnytOuQPwyVHmUcZE75IKrdI5mNSQ3u5gAjh6vY0k4Wlqvx6A8mprdqS4DYDrGGRZg2qNepyenKdpmp5u8U2d7BXxDCkswLty9CyXnTh0AAPyXWufHCHJcNqOtI5u7Hinvm0agDjh7vjVUnV5yeh1LvFQqgycn9NiFlotlLwp6kKp3gjuidHzu2cKk13zshjiovn36RVLR+tNHE6vslZQEzFNqqM8KQGAxWEBLA4AyJtHVGYHX62rfDlcdY1+ccmaAMCMMsDcFABAyujMQAiSVWnVQG2nAABsQr0Ax7hlA0kALhXaz834V/kXV1XQTXs7FqTluVZ1hTsQgwNGgLAIqu84iR9zSaO0nIi5gi9dEyb1G8o1DeFKuX63AAAAAElFTkSuQmCC",
    },
    {
        "name": r"GAN2",
        "sumerian_transliterations": [r"ga3", r"gan2", r"gana2", r"iku", r"kan2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAaCAAAAAAcMmrdAAABLklEQVR4nHWRbXXEIBBF7/bEAJWABSqBSsBCKiErgUrISggSiASQQCQQCdMf2WQ/Ut6/OdzDvPfmQkPRMoNRoQVgqqRYpKgmgZORVE0bAC9e+n3Q/p/PtEh5LJVqz8go/jEUkfG00okBum2Y9Tz0eX4lFPlBQNC9YX0jnlSqlJNbKy+2PSdtxLZFrT/Ndi9AzLM1ZJQmY8watCMsZr3Fy50aJcmQahGXYkq2TtUPMop98pHShKppwNSq6WuEWPzu1BtwosFXBdMEFAdO1E7UaqAANgLeA9ECsmf5mFXyLOcIR7/dQhjcatf8RijL/VC94Ko0BNBpeq+WMGPcFRwBfMjgr5it50kk2nh2Gg+njt/vt6vv2rx16/XWukj+Aug+W+9H2sefK2zF5AU40v8BlWuuW3y78LoAAAAASUVORK5CYII=",
    },
    {
        "name": r"GAN2%GAN2",
        "sumerian_transliterations": [r"ulul2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACq0lEQVR4nG3SaUzScRgH8C/wZ3ghUiw0N13zyggrM9OGZYcty+yUJiPNlZXpWh7T1Hjhiw7LdVhuWWaRJrkZlkc6K506NUPnMVloHuUmLOeZORIwegGimM/L57Pnt+f5PQ+wLJw79y5PmSgEzMopzpIMAQBUnR4AiKzV9ItDSptlRY451gizwdbn3+b0MzFdkeZqIdZaWvXEJw7389vDk9rVeWbKFX/vhvDL1IPIovafPFjH9QQvUfHoYFRb+JvaH+MHsFtWAjC7lW4mJSVwXew21DwR2jsQgibH3Oq6hx+p/oKJxXq6tLszI7SgbaxuIxx72wSgFT6lGo0Mp9RSCWvLnuKOMU4a7eQfXSvmkjlXFh63PdvnPU0W5c2MzseyVINJwcIT49j2QiQ1VGteB6gIWmYyRebXzGi6MJLflWUBWWqap6EahOsplYajEkkbw6XPdABd3JoJFG0SeBVrAMCCG5PhdrWus9y4i3UtIZRbTdWK2Z3GBvxc70Tn/ZYujOLdUlq7nlGlLyOBDMCyI1Z3cNaHfc3Is4yAS4oZShpdZAMgqqq8WfuIAt7QEQDA4b6Uuy9JIWpJp74CwOYW2TmZA3g1v4Z9AEpKPx/UghL515yIMCEAMCt7b+LMgFLRUL/GLvezL4D4yVhLw2AA9lXwWfenRvOD1DQLdcIwLDOCEmthYiLTnUs0qst0l/3lwZNYm82O6l/4cwAsSuDfEW1hoO+uBkoIfN9NHDWq4daE+1X9mg/HGaejPWgxzhGPs3WmfQMA7AVeFbxA9nXGq3RvZtz7xWWTAJCtNPPn+e5KyYQt4bI9Ug5zZkh2KKw8uqRjLh2eDV1LDsXQ2nS6XH9DMaDwkLuK683UGE6fOgrY90Jvs2krIIBD2hR4Ra1aGQHa22Mg2ZH/y/8DU4L4qHJrGT8AAAAASUVORK5CYII=",
    },
    {
        "name": r"GAN2tenu",
        "sumerian_transliterations": [r"guru6", r"kar2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACKklEQVR4nHWSXUhTYRzGn/ecs7OvtpU0K2yUC+3CPr2IQZBRXkVJqNAEyQhGxCCjGE6SQNeNUBGzWWJ456KWxW5qF0UZpIhJG9FJLSrcVrYvXS324dlOF5O5ndVz9cKP//M+z/99gTVVuXtRLGrtSI42kf8wcsAsgJQxoqQgM9jXz+7WQizd4K7NvZEfJ3q4egCEZQAAUgYA3Wb6Iu1KRttVmj3eHOTG3Nu4INHvZwDUmROpl79yuoM7N56ZnIO84xB8SX0lD1D1EyEuH/7waPSmGjC8E1yOaNICvelroGN4fPVm40ebBmiKXmlM3AZGBWHC7PTvACUDWLR+uqYG7sXn55SApefR8yCfdcjU7ebzJxmYwjYVDIvCxdXmR67PRM/KbySCfQR095JNCc/y9kLDfU7/sbrH/ZsAEOtSn/TqpArI14T3kv2OlWvgMhUvZvvRlU7+Llo0tjzkht0ebroBINbw1LimeHFV91e6Te8HqqU1ctqSnlajePE6e82bdUwq9efWAjNUezxe/H5+V3ULecY0B2PgvRkUsgAAMiPylievt/kSClZGUOIJ44anD7RT6a0rioHaxuYST7Cq2N3vrf4MpfuWJij5L/A4KxYvj7V90I74BIhYKEBL5l2KU3tf8ZSYAYSmYf9MayFAlBMIzSzLwuccQ5F/zCUCWSJZGPs5WJktY4KAdJxnTsc6NYLYE4Cb5CQR84UcLwZ5dVYTli3LUvDOAMBfpdLF70GIxFMAAAAASUVORK5CYII=",
    },
    {
        "name": r"GAR",
        "sumerian_transliterations": [r"ni3", r"ninda", r"nindan", r"niĝ2", r"ĝar", r"ša2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAXCAAAAADBtFtBAAAA2ElEQVR4nG2QUXXEIBBF7+6pASykErBAJGQlUAlbCURCIiFIIBJAQpAQJMx+JNBs2/m63PN4Z87cQsloP8PCCQCTbLLrKwCwbHJw2KVJtEwHGAn8zGZP2KXSDcKohpy77jHZ0icAPgCyUTBTEuGznPFgsLJFCE7FqAHuAMxr9w2K0pf4bFmcAGIBJ0EfvUACgweVVhPXags8PdYMJa25VAva+Kj8w7fNALAM43ju1ayx6SvVR7VqSX1p/+61NV9kte/ybJj0mzyybugTvyZM7a5X+58kuD/qBTEOY2vyr9XaAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GAR3",
        "sumerian_transliterations": [r"gar3", r"gara3", r"qar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAbCAAAAADXbrl4AAABMklEQVR4nIVT0XWDMAw88rqAVnBHcEdwRnBGoCOQEcwIyghkBGcEMwKMIEZQP4Bihffa+zL35PNJOoATujNl4dWZ78tZYgl/S3DpJrKitiCpZC2mRK0x51tNUqp7Tfbzc6xKiMerZ3/vD9k0qIUDiHXYX2oKzc+58uEf3wAQeblt0pprG63u03BF03oqOsSqk+pC0kyrD648sPIhGEUCgGGSFEMIISTVDrt09ZLs4/GqHtCIGknzZXbbdOYeiQCzNgLw8XKMrdsl5BvqgXt29/4CzDs5vqgslUYquPZAkWoxNKj82syba7MloGi7HlqZ1pw0kekxHmMnXj4BEMfn97JSIbdvm+uAIHJ03cnUmg6zUNJcUYMNVMwsYlPlbSiJJYopaPCODPo6kQZe//2lso3/D6CttU4VCmeVAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GAgunu",
        "sumerian_transliterations": [r"gara2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAABh0lEQVR4nHVTYZHzIBTc7yYGsICFVMI7CakEKgELVEJOApXwIgEkEAkgYb8fybUJ7e3sTCabhWHDPuAPhPjXlxNK7RX54HLk2Lk4v7lMSQydVqmmkxJlrvasxcoajppJTMHzEOIfgDBdg2B5iXZf83P7VYbt0bYgK3ZDu6xWxNnbejhIJWtiKUyFqqlMZUsptU4vG1lsmVU1aPKl2qn+RjeRcUsnRlgSKxOppFaq8rWHr1UADGFssO1u3NJsxkaZXR7tA2NupjW939vX93pth3NuWNCsxQRv3HK5ex0BR+rMM6QUF7SYGBXASAKGidEIEXQnKJ4wDBjpAJvoBzTYh00Nas1OABloADJWuLBe8heAbEzOyGvbmY/3Ns+P74wBwIiWgcWYnfAv24zbz/PvvkUQAgzwTM9KkGToIggBzvHZuQEAcvMOYsxOYATEwrXr43ilisBPONWcTHruJROTuK7lJKs7tTzawEkLOlvphgiAln5k3gcGgLwNID/NKQr7/e0n26THt/+ZTDHvojCkIAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GEŠTIN",
        "sumerian_transliterations": [r"ĝeštin"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAeCAAAAAB7tgMBAAACgElEQVR4nIWTbUiTURTH/48+vky2OZsvq2XlF2UpkhWIksUmCMqkhkWDHCK4QEN7EyH6EIqaMpSxZph+yEKSIKQYY6M00sReSEvcVGqN+ULqsm1qNdHl+uDj9jxjtfPt/7+/e849594LBIuIyt5AiwwKcstBephWWDCO17E+URs8BSOIZsem2a6MCU0KpI7OVpeaHxI86nwDXFg0ZP2/fOSJ2bViAKmDtjKO3z4WyCXVOL2DAACe9rtqv89fLYyjY7xTPXP1mw2UKp035lFzIV5xX3za8IMFF0evjLkreyiZ3Zqo6l8FANIxrjjvJnyge8HsAbG5K9+dvdGYeccKgMzj3379ww96jl/t7t5K8+mVWlPd4aZhAE9zApqJb5ne0NMvLNc4fikW4CDlEAhRVhgEQmpsp63ekkwamdAypxERCD9TPsrJ+Gm35ry9595ZKW5kDSnpVUo6xkhsT8XK3ZZJxR/0bVG+rrDSzTjOL0wBIMS2ZwfYKlu1ryWF+eV1GhZxbVoTDQDxo4+Biul8yufeWl49EuXnkrUzNbHAXSG4XSqgSE+1L+mfdwzR8mUMTMjCAbI4VT0bTe4jkiOTkklsx52T2ZXt7/2ctH65ehgAnqsnLU7XF8vS+rzFav264O09iLWbPq5qpisVAEDujfloyv/diVzpIxMAskxS0eDcpjBek1R7f4XqXJ6U0N0GFBmyAQCCqhHj5yc7aylGa6nvQ6ST2PNQA8gGTlLDSHngXeIAQO7UiJjxxrl1tYC4PX1X83XeywDki30igs6BYLOBKK5/c6LeXiDptTfzECoEBofuQxOLkS04KWxj8aWukAkBpH1rYxr/+rlLWifT+Atp6s6F1eejzAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GI",
        "sumerian_transliterations": [r"ge", r"gen6", r"gi", r"ke2", r"ki2", r"sig17"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAABj0lEQVR4nIWTUbHkIBBFz8cYwAIWsICFWGAlsBKwwEjISGAksBIYCR0Jdz9CMpnZV7VdRRV0Ti7dF4BLBM9XuLV+p0JV+cykarYAcCPzeOUI3rPdP6iSt3vY5qJLZpJa+RALzapRlY61qZQmhSx3Qj5Zb6tgbUcqqjpr3Xo/C+9qtVAV8YpHtqoqONM6f8s20ugFWrvKeWmFPEvLstRwvUFUJF7lEjCmRb7YRGhtH9MfOaCM0wl5aCtEeaIO06MAlneno+4Ire6Dlg7MaXnLT+SUG0oTY7ztPeV63UeV1rRj9Sx2lxt1nyT528bvvJD/AFs8e39t6ckjP7fXVu6vLZPEYvpPDIqqTAEAu5x9temDswY0qSx7bazrSeXzajRzgCwenVLsbXA5ZxFgDZzYYXhsOqzOl0t4YCjhSx0a87bEpn2DG9d4elJm+3XXCx9CDBsP/lUrHULVSIp0aeT4PsALtrccTIr4YipxWvWJub2tYFoAV2TiB+w4/WX2l3R5RhdsmXvE+bX+rPYdbrr2F50pKLqMfVupAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GI4",
        "sumerian_transliterations": [r"ge4", r"gi4", r"qi4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADIAAAAcCAAAAAAG8rMrAAAB9UlEQVR4nIVUbZHlIBDsV3UGOAlYYCUQCVkJWOBJYCVwElgJRAKRQCRMJPT9APJx+17dVKUqmaGn56MD8MbsT4/89F3MFZqbQ4dS+eKgDrPSKecsZL5HsojNLyCGZCEpIVFf/KHWlEyRl/VQQhAWVdIlUWKsMcGIaw7vrphAOzMx0R9ZhCErVSoQaocwXButuWY4sg1HzZExVCpoOqhOY0vg3SyQOqQwBouZDoi1PQCc1GAvxgrAdAhskX5c00HTAUAs6jaBnAFAwvguuR2/0JR/Vtog6diBpR00FpoWQBY3aOakB8TLLYemBWJuD0IsZ+diOsSeerHj+KB5RG3+jKgHvuw+AQCfXwcNJug6LUhqQlLTL7t87iNodnhsbgOwmqPH1bsNmwc277bNW1wVmzMi/2f+UfRz2cZAoTTWzw3AnE5yFddpDOjzG0hOLimqbe1DcT7Ii/SZGokAHllv353F+nXaM1rGsjw7RzYfa3/DtAM4NQsTjlX2DQDKC+Oor/fNm/hPiCMwh0zWXqKrbCp6ZLOOwgAAoe0Fuk6LKCxPE3/vxuhZA73A7Op9iENdEgCXGQNhSGYXhojqqbFbYV2ZnkLARoo5InK/fE5IV6YnAUAXyqsb5gYxfT6pXV+q8C3k+LlCK1j1kSqpbyApvAnA9P38BQxEf28dZ7t6AAAAAElFTkSuQmCC",
    },
    {
        "name": r"GIDIM",
        "sumerian_transliterations": [r"gidim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADYAAAAeCAAAAABC0bJaAAAB7klEQVR4nJ2Ub5XrIBDFf+1ZA1jAAiuBlZBKYCVkJVAJREIiIUgIEooEkDDvQ5M02aZ95737aQbmDnf+HE5sYV2KCWPNhUO4JsWstNX740bumI5Z631/d71XsyGT91L0CxpORtvKNEf3In1jrdUE0aEYRveCF0SPa1ZVShER8WiZxEMQbw5pqtykXT0v2hbxQBDR4H0vr1AUfNxpXWsdnwm4uiEDLn3npQ/ua/OcDkN9eFOR5m6JB6bw6EIpaitTPHCenaq6YXNXzVKaC9A8lTiLJNnrmCtmlpZMX2ctURn/xFtoJuYhXF23FIRKqxlxVV8Xz+5oHZ3W6Wdx1efCMiGqquuasOVRm1YJuiaub/2sb6VsnK51P/8zaAWGBJm0HOfe28X+NvH0Fd1u/B8Q+MLUvD0ld/axC1gBpl80bDOYtGOhbF7HTZMToMJd+DifT1JU8QBimcd5C5scs955gcUCZ7TpGFVkh/rDE7ZlnHFcL/ttVwpGyzt8aJe9gXEY1uXq6yXq8MiubX2ieaVqrGD7Ogu1JqIgrrH7dt1l3MIsR7eTSO+UiIzc+t3WbyFP8nU7iUgZb7RHhFc0UEEm4+TlFwS0BzpGEZm8+Dc0AE6/ZDaKRlM/83H4O9iw/oT/BlPC34OOHpT/473vJn8AqKAQOTOhEJUAAAAASUVORK5CYII=",
    },
    {
        "name": r"GIG",
        "sumerian_transliterations": [r"gi17", r"gig", r"simx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAeCAAAAACk+HkeAAADmUlEQVR4nGNgIAGYejEwMDAwMBGvg8OgWopUPZbLWM140fXwSOHVo8P/UrmYB1WMZ3orCx4tTjsSGNTXtAog28OUlvHnD0KJbrsVgsMqopSXf/SKHONsnUlCSOZYvb6yskoEzlX+/2CyKowjOLHnSqTcjumb9FSXLeBlhAnznuIsyLM5vOn0Rwifcf71b6Z/b75jZmBgYOAwEL4d8Smsb3r3N7FGXpgPOBZodG2NOC/e8e0vROA/50NZ8e3nPzIxMDAw/DlR/fX3nwMXtn9jePUoGqpF4dS/V9qKx78drtEWgwD77/cKhNlZmJmZmZmZFTdu2iLNILNSlYE5+4g+VMvJ3//3MNjfaOOF+8f1kS7c3QxCVpEnVvFKrlJiaz8K0cJscvLtzM85DCqHDlsLwBwr8PxGsBgbUhjNWaSzTL92kwIDAyMDg2BM9e800cleR5m7Ul9cuHwGouRficrrV2evfoZpeXVlljTr2781NxkYWBiMi6J2tBxtZHzD8Pfrs58u6o6/IGGgevFAocaTHzA9p29M3P+FNeYeAwMDQ+qVuzXCDAxzPzIwiG5+tyRCBqbo8Pu12fpIbmOQyz9UC2Hd/L+GnYGBYcknBgbd87MR3pb4WiDIgAoibqczMDAwMDClLnefoQARe33Ppk0XpuDjR20ZVC3l9c+EGRgYGBhYDl3bU7qzdNMXJsX7r64bWgR8uwLxNhO7n8HZfQdeIfRo8i92v7eCgYGBheHN/AsTFta//Ctx/x+rkPCd6wcgCfU/P//UGVGPr/6AOJfpBpN8wrGL5T82QE3gnvTtwo9iBtWTz8N5OCAxz8yy/+39BUFyQoKCgoKCwqLiPSe1WJnY/M6kMkM1Mdd+/n+BWeNwEyIdiH3eogfPKPoz99zSqXp7/IKOzmm4Job8bx+cWWf93eyvLgcBsh8KkHKK6/YObpY5m0MYGIzOJ8OSykThyvi9994obPhwHirC2KW36t7rnxDv3GB7/+PvvDnrGRjunIqD5+Y2TS9fGbFPy/d/ggr4mD7f9mDzc2YGBob/DJZ236Z+efvjL4N4pVQKIhLVNvLeeLlwF5w/12+h1Oe7UHt+CAWvbdNYZiTSyl70DuFkxsj/mwSQovDdvXINJK7pzgqVE3LLZkgwIAP24izkkqvMFEWWQXP1llfzesRQBRlYUAovjNJyy/8Tc3kYGBgYkEu0P1+QlfxD15P7RH3LF3RBQkB2EsSDAMxRRcp7ZnWPAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GIR2",
        "sumerian_transliterations": [r"ĝir2", r"ĝiri2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAZCAAAAACTTbgJAAABNklEQVR4nIWSXZHDMAyE150joEIwBR8EU8hByEFIISgQdBBcCC4EB4ILQYWge0jcn6Sd7Esymm9WOysDW8mb2UbeuvXosKXird+3ohqL0B5VzMzqJzuq84cjBtNPHFv76y1TzC9cXCL0WkODBABithobZYUAQIxTeoZmLscWVgPgmUVtmKFBhSsDQF8Xjs2UPQCQ2DA7pcSlBamWPVyXxhhwniYAHC5xOgEkt7+pRep6jIgWqdiODgFdDdfTt3PO/eKC89E5N15c03HE9QdiVrtHBb0WAjjfu1NlAqolAhB8zCYAgha6UyFb8gCwtFOsSiUACFrDTBE/9bqcT4UXg6opL8s2dxRrd6Ni+bFspXJ3p2JpvazJL3VLycXeLHsVFek17ECA17znBABiq3f/9Y460+118A/QysfT+06pPQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GIR2gunu",
        "sumerian_transliterations": [r"kiši17", r"tab2", r"ul4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAZCAAAAACTTbgJAAABQ0lEQVR4nIWSUXEjQQxEe1JHQIYwFPYgiMIGwhwEHwQZgg7CBMIYgihMICgQ+j7Wm0psp7Z/pFK9aqkkAY/yJ7UHVa73pZdHSj/asZVMDZcjKkhy/mQncwumODM59Sll3LPGEB0cXzi9jdByrjvksi7QwVF3iiEA4LTuN4gku43qpNd92FyAaubJtjm1MEZyk8k2DtMqAIjT0OhAzmGZSu/WZpoAKy3IflZVDQ6Gqg42Rs+YXFWd2aBUCR7oZcE6l/e/v0sp5Q+ueDuVcrmW6+sJ5d+llNMF769w8ssK0DIENjAUhBlapgkw2QXAUnXQASwZ8kn1wV4BgH5byPQpALDk7Bsl/f5OYum2pcvkRmXawx2d+x9IpI7z3uxO8eku8fNT1NvdPUbwSbPvkvCWywEE1BxHTgDgvPv7X8+oN/n4XvgP7sfv4sa7fTAAAAAASUVORK5CYII=",
    },
    {
        "name": r"GIR3",
        "sumerian_transliterations": [r"er9", r"gir3", r"ĝir3", r"ĝiri3", r"šakkan2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADGklEQVR4nIWSa0iTYRTH/++7zXczrWnZpNCK5bDyGrlKRGKhphRFBt1QKsFEgy6k5BdBzDS7mUXeKqXUCkEzKLWyZaVLs7LlPS8lOnVN2tzCZpvrw7tN3RY7n87ld/6c85wHMBmRTs35BOyZSO1i9gU+dmDHgMb+aHOUVs2yjZEAALZv2sup5zGLTcnAwH3/GYcb5sX3y/j28Vpm02TuEjoXIb+qT/S0RROCuqHeUPJ+sQKsQ5k16WS4XMc7Qn31XjX4qH7ERsP+gXLxBtqN7inb29vaqDy7Adzggr76eHdrfFG1OBTAKh8Aou7qlIdfkumFthV0v4h3scRZqa8JAFHi3QCEdZKh/nWmUmh+d0PcsgWzg32AVQyA/7RTMUzohTvYJWeUIIJ07Q4bh+XB+0XKqrJRM84EFfkYAMZGVfGNY9pZHZS/AYSc6OeqUkdef/CPPR1z767C3JAkzweArT/viPg84Zsuaa7o0nKsKH9XmcwBgMWBaR2dp0wnie253HASwJ7zq4EtLU2Cm0W+rW0posPqhxwjQgnSBzri6ai2NKdVk8wGxQYOyqo8cP2Oe31by4Wcz7fmNqS8smWfjnMAOFKUU9x4ozfAyFBlUEBeYUjHKWeKV5o9/0mYglzFjzgv+nkCJBMJCR2aQwSAvMLQBiGTdC1ZgJNs7jmVVs0EAEN7RNalex6pFbRQJ6OmotnRddzMsjlu4VGbGF9fVTHpxFSSlteXbzyFesJp+3KHtVI6dFmyepdf0FRTaq0MYJoUrjRXGmhP5+/zIEu/qIIBOCzj+YX5ug+L8+pnjGcy2uiVrlmjuurb4FI5Z7N+B1Po6022F72VzvsElpbnfFTClzzRJHqyVrZK3r4fnV9kWuEAaRjXr9M4qVv6bv+yKNnAZ120FQU6UhBdfMNayaKbDRBaBosBQv/ivrWUhXrwscRpJ40iMqJTv/6Z0i7OiPm7ZpLvJpDKphWulNaaX2gbn5RodTKDQfV9UDl10a46KRy5/Eyl83InHHfOlNvFV44d6/sD9JLg+suldnGxdAgADHrM/FLbGPYfljMe/ANYeVcAAAAASUVORK5CYII=",
    },
    {
        "name": r"GIR3×A+IGI",
        "sumerian_transliterations": [r"alim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADoUlEQVR4nJWSX0yTZxTGn+9P268thVpAqotaBUoHQ6nCNpkO6RKQCYYF55KZeKGLGSYoW7Lo4gZpOhiyBTZNNtwMRiY6EydhGwNEHcS1rFKHSFuSVlk6oBLSMtdiW9t+7S4oVSwu2XPznpzze05yznmBBRFqPv6HCtxbovGK7GdAZOQVpB+ZTo5m9zdz/wtnsmt0Kdf3xi9k5akVxNK8oDA9df0n44Zmjdb5ZcJ8Ln+6kT24eimakHa5zFsF7Scd4Lxd21MXLHG4pe8KBzauGb/YO7mEoXTs+9+U82GJ5YfyeyM9rtoXCXF+i6X3gDQW57fqSgHIXgCgGus6etqopgAA21rG+t5ZGzNslYEHQHVlD4ANl7TDdzMXSq9+bRo6tshAgFMm/QpAovEGRohHOeWCa/ttILK4t7lKmyO/rIC+2DYVxWkId/cBgNPt3rf8foB6KCDDQDivxioOfnytfzCj/M09ba2OqOENxzcAkOlsLUyVZvZbzP2vNcmRfErXoYkHAK6ixmiqXjiJynTq6mEAOzUyIEs3pPziZq52+APVbvvlZRGEJ1ffGz08bzjf0aj31SeAYYAdkz89j88N6zqHxj5tvNP2eEJeesPURI0QAMPjCvdN92cApOZBnQho0hcZasW8lLPHn1wJLT/htL2fARHDxInytfcrDxr97wkANOm3d7/MISVnGhatm0k48o/fTdsNvnSvzUef6F7r3LWuCgBlSvq1vVsgmY6yDD+56PVcavT6ZbqywaJ21ROHlMtD5mUNAED4iVtKhpN2Z54Vi2VlOZtc2g+77QB9oWDNd/EmqqdDj82aKQBgFeHeelZ4gQK4SSnrSzJX/jXYfMUfOdOATFQcB5XW6mVVA3oWAdJt+zNxhlEGS8iXshXk3W9v6Z646twsZ8crZChvi3rn1uM3bNgUHBfV7fr5gTlXKbs5eO73xz8AAA2CM/tRnM+20aov882lrcZzTsozE1K4pXNXJ07/jcWiAWByytnJ7k2CpaUTqN/OJF5qCpDyt858hqdFAwB8oRGPoiJ4wEjTPiYcpvwECLbvbAwdwQkC1ur2FUbkVFV6CI+1uNjEZv0ysxROkABFAfbqkwCnIrAqkLoqy2j3OiRc/xK4ywGYvQBGhoBHXf5C+seV4KeFJJtxiH0aJ8Cn5iAMewBIZpHXOdE7zmPDJCEo9R+7HY7t7gXwEAAwCySQR3VBAIB4w8zws0aN6o+i0UhHvzsWBv4FvVtWZr2zn+8AAAAASUVORK5CYII=",
    },
    {
        "name": r"GIR3×GAN2tenu",
        "sumerian_transliterations": [r"gir16", r"giri16", r"girid2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADZ0lEQVR4nIWSa0iTYRTH/+9lbs2ZU8uZXc28lWYKWVloGaZFUGQQRhco2AczjKCLQoWIWMlKDJpRVmizIsgUWnahNTNdUWQrrdl0lbPV1LY5bU7f1/VhF7ss9v90nv/ze845nPMAbhHF3MmYgC9lWIM8cXS8D5i/RKnN8ZyO13O8YyQAgJdw/NHQg51T3WZS0tb/tCPMjIpcXPLx1dnSZ4MVgU4vy3iGzZvjjSaim3SaNLL24gA420sbisl1RkYkJtWxc3tu3td7ebCtW6ZY5AxzPlzbonmhNB9LgDC1quu+OOxf3L9ekQZgbjyAjPf1h2+8OeTse3XV+4fiICB16e84p/AJAWCDYhOAlKY2nTbOfZUm7ZDvTn55dBKmQRlkDgCaGbs2fCFYWzrvigEgljLtfsk9BWsqqnqjVKAFZnKaaRygwV1/BwAMfRax0mCfYGAeAbAqXyu0HNHPMt6dEb7j4+sjHIHitAUA9hmlALCivzojUpTS3KmuyCgPRbis5dbB4EKFISYgpsz6Ts+oNtIAyF37a6ILAIgulDzujjhHbW7m96fLD8fKE1lpIG8kbFvmpo6iRVMp3VMGAJ2rmggo9Ts3eq9pFLkSVUEvS/WbQnKEtPaHrfc0J0xC5a0Yp7dbtiy7KhkB+FyuYO83ZSxAlVhKuEDlhVXvDgRwRVdPAgCC7r79XMopMhwtG/y8N4r+Cdgvv5IqTyB/nvi6AwDI7622iXGHc3SmHUrBVuFF0eB5c9H5MRoAHO1ZZeU1swvrnLPtoBrqWvnB31x8QzpvYdy87GLu28e3aac3tM8u6pK6vpH1u2BtqN8CtfMY5K/PxcqfLXfkXwHavS9J6y1XeSYxvrac9a+jAL9posWZMfPVEW3dzTecW3WpT9I54cpu0XaGGKcsY7PplIRYsr3mS4ssPPAZ/sBR6fkXXaHVrY3DmqRLM1+0XVP1AQH1y0N+/IVPinQY2LhhgfV51yUTAMDaYGymvIAAUFkdosinQdbZ93u8KdPdlf9kaXoUhJ3iUAzBPqz12Dabdzx1T55NMDywPquDXSg3/1v6L5zaOR4xGDk9Wv3VNhDMtf+nX4+SG6/Yx3odDsunHvPQKZ/ZyRT9SR2PcZAEf+OYzCc+07BHwwAAhIlGtU9coda5ojGT1UuzvwDDY06/YQB5EgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GIR3×LU+IGI",
        "sumerian_transliterations": [r"lulim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADtUlEQVR4nJWUb0ybVRTGn/e9b/+PUlvYygyuE+gKFVgd6kZEVzRsDHAYXY1b3Acxhhl1Zgn+ySKMIAwQQbeMsUnAMVFnJssUZB1jQhwFBggrLRjG0I4NkLQBqSC88LZ+6Chiq4nPl3Ny7u8k9zn35gBe5YrwPxQ+9bg3D4n+F4i+F8URx+3B3mpGGf+/cGF0tmnt1f3S5ao67DnKPy/WR4TFfDDSXZbX5vgk0FOLnyjmXnvAH00pG2YGEsS1x+3g7c25lL+UbHcqMyWtD28YOWe846chdfCrazpPmjz0TfqtG5dmch6lZPEVQ8ZXlb64qMqUCkD1EIDEwYZ3Ky25BACwvWKw6ZWNPmbf6BYASLy8D0Ds+bbe4ajloydOWrsOr2qgwEtTlgNQWH7EDWphc7q4OcMGSsvv4+ts9vi0J5lzNXe9OAOJoQkAHE7ny2vHF8msmHYD7keyb8qW3m9uad+UvmdfTZXd2/Cs/TQARDmq9GHKqJahgZanStUIPmW6kCcFAL4m22J9a/lJEq2nrhwE8EyeCtCaunQfX49r681KNIzV3XcPEahzb/Uf9DR8caG4c74gEEIhkHLnu0iUdD94sWvwaLG5ZsWhIKLw7mi2BIBIKFiT8VurBiB50wUBQGlnUneOTLDuTNHfR8KojzlshzZ5xqNrHj2Q2T+bSQEo7dzZuJVHy6sLV41bGPjO76yTAQB3b3p+2WeytysAAMQa9ENto1g+4WWFouCkXXGk/2odQ/EXALBZ8yHjJ2mKA0CxVI9OyAs3e1iZTJW2ectM23uNYwAjer12mnLHJ/CS+vShHT8D4DRuYwEn+ZIH8IPWxSRHrb/dXnaZ9VggRyJaGS4khS3YWzeXAgCU0/aLYlKoo5Lpx6I19PCnPaYVx5qhPtrN2fqMX5OsEz8BABkJyH++fnogtlx1vf3zjpUfAIDRDJ8QGyxm/rVdu8cj400AS5G5SZfGqfzjymjlFFaLMQYJtBtmza79eku4YWOPmWydFyrOly7S6heqP8Q/RTuJ6sikKtq1h/mVpq23l6ZYyk1YChTXdMaHBsPRjou2wCnhRy9qFg/XSA4diNw9d3PHDiun/X7SDx7ntp+WicbR0V8uLlna9hIvlA0L1VrG/rTL+awvfrY+lubRQffz+0uOLmGhgdUz366HKNwl34Y3OR98Tdw0Abgt9ajfDpCE0cIRAeemKXEqW+nyvU2RQiqVSqUGFSABnp7QCwghhBBFdZEvDPA8gXi2ljxmeXsFHPOH/wXATlEYQCL5JAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GISAL",
        "sumerian_transliterations": [r"ĝisal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADgAAAAeCAAAAABcGILpAAABrElEQVR4nJ1UbZHrMBDTdErAFELBD8IeBBdCDoIfhC0EF4IDwYXgQEghbCDofuTay1envdOvdHdkrWVtgS2E7U51hcNOLcK/Ju6g5TD8hReZwjuzruAyTVsb3G+JiaUUkuXO9OsjfG6dV0XNbkm0Qga1QaZCNVkSGyPJiMRh7qGrQzYFXKYCAJTUpWig1gy0NOaZF95SBQC0Vj0AYaalICIi3wqpmgOE0hpZHjCG75kKFRCKN66QgKODF3frfiTHcJ0+bh8xyqlBCGPX3+bDln66Q128msxev6lWN3cEqgAoTMuqlPkv5U4YigCH/vNz05jh/6nXN2O0VASgjHuKrw8Kc+seeEV0Wrp/t53G8YVcak57esCB+fkiuFy6UZ9sdV5mdW5OsEGQyLg+ughw7APqtevGrVwK5/OIG86ql+ui7wBA6NplEMuP3NSXdVQpwNEjRFz7KZ/eAa4B0Gg4n0cAEGg7Xrp+Mep0R+bZqkqIVWLifY9Raev3h3oAtsyikqTRHn6wPnF17XZkdvG+kgDk7b+tljqs4/oelDPB38AZ3xhvJ6vjxW/jsMEXJ4AULP3dUisAAAAASUVORK5CYII=",
    },
    {
        "name": r"GIŠ",
        "sumerian_transliterations": [r"is", r"iz", r"iš6", r"ĝiš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAXCAAAAADMqisGAAAAuUlEQVR4nGWQUZGDQBAFGwoDGwmxsBbWwllYC5yEsUAkgARWQpCQkzBIePeRDQR4n10zb7qmYcuclgIxTTsiulwuj1+MHxmjEqSwQ/OsHtBznw2SB2CWpw2OMqBdWOc5V1YoQJOHW58D5b0cG6C7c4+B6a+yWiG3z+0kAFzP3aYyDV+Cb9b9lpVz3PN5jkHqT6xdmMzt8AuSYnJtoTpbWB/LChDt0/fKxz5eGi/ObodygO52Maa9Iv4BWlteJrZVgCwAAAAASUVORK5CYII=",
    },
    {
        "name": r"GIŠ%GIŠ",
        "sumerian_transliterations": [r"lirum3", r"ul3", r"šennur", r"ḫul3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAcCAAAAADKa4nAAAABQ0lEQVR4nHVSbW3EMAx9Oo2AKYRCKWQQMggZhAyCKYRCKJhCDoIPgg+C96Nt0lSbpaqx/Z6/gf+kpquW+O5P3bcF31d/MC96NWwmZYVsrBamSr03v0FQ/JI51Zyq67Wy0Fw9rJzQXM7aiF0TtJ2+8xG7VwKAbMYAoseD7CN8VmMaQMjRYZXZKrHZTBY8A3jk/Axt1kRvgI7368kEQJlZjWcBm/jOSOo2Oi5mGbH7DkzqTJt4szbHRuzmEi4M7xHdvOKBv4T27/3zymVwCqKMLMYUxKUbB6AIs05XwSZewzHBDOxr6+MUsqnLMUqIAMDH+1vo67lU8d5/KX6e0LGhqMYUzyxaT3vKx5BPV1ZjAt+3T3UWQGya7XJBoZXEtlwQVTe66M3Yb9e+73UytLUVANFVZ6fVMO5rxJRbiH433GW7dPoLr/XBEFm/+1QAAAAASUVORK5CYII=",
    },
    {
        "name": r"GI%GI",
        "sumerian_transliterations": [r"gel", r"gi16", r"gib", r"gil", r"gilim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAADAUlEQVR4nGWTWUyTCRSFv//vXy1oQUwpBWqq1DiKFrEzOC6xbsjiRsQNEx15kChG50UZ0AFiUIw4DiLiEKyDGoSiDrYWqAZBVBziRoNrBPfGGBQyAScSglJ8sBISztPNPcm9OefeAx6M2Sj/Vgyzr2cofvy44lsx62ZL1kzB0xW/06pPaSdHASzoWvfq1+rfDF4AEoBW8Zxlje5ETeoDFH7T42rK9Suz3t9raEEAMHfs0jZ21ke0/uDK6fq7UB/qddPWZsqrSkECKSHmqqrQcqjnWoCqqUOnlhX06ZbkdX0JtINASEbc6Zmu1nTm2w4e7uZ0V0C36/pVoaKPinJgdkXppf4SEXnlNhHUj+bJJiUeP2s9q9qSAiAKulpbfSTJpTIQdlprM41KH3OtisQLEhLugLzGzOgM/arUPqC9/EPo1i8+c5Z1oI2MPwdqe7YcIjtzBhxSnL9dNpuRl3ObTGJQ0cPfPwPtIeEeVp7uXtEbImyaofQr4dI+CQh2zIupmgKAbK89kGv1ow9lzpm1lCgJRqxOL4DFjjBAzK70QX/j352+A8tMHx06YHF1OPL9Nk24tuBJRX+u8rvnCcq7bwBH4NHtS8Ynt8WvNr6suyK5PUfb0P7WOQ6A5J6TCgh7XlhnOWjUCiCCocj7ujLfCEijbgfqQd+ccv+dxlyzO8FfFMb/ceepeXltfoqXmBEUbzdPJsLSO6Gw2VkWvVwg+PJ/p15lga7YVnZUAdsa5tqDok5QtHBjqRd4TzetKXaFgW9T68X8UNjeUsSJGG2N/J8ojzBZUt3EkWeOjU37/DpnUWhxc5xNlrRr4gW/AeVpt6qOe8Ofnf3uhlOH3x0QLD8l7fHolpIj/NVTY7uho9fZk9rIs1Vr/38/5aLnU/tcpg8Ox2YDaF4klLbBXyW5bwl+ODBbfb5n0ULrZKImcOPxlkm+6mLngT2DQmB8/TPRNgPwy4PqFw1Wi81lGhySBSMg1joNDM6ayrka3+FhsiFBiskWMHXvEIcQHvhD7JHB7FdLcQtm12uSqwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GU",
        "sumerian_transliterations": [r"gu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABLUlEQVR4nI2TW5HDMAxF7+yUgCmYQiiYggtBFEJBFFQIDgQHgim4EBQIdz/abpt0tvX5s3VGo4cNwAXjsI+7gdRhOVN9GpWtoI3ZBmF3kvZdnx2VJOmNdY4fXaFCvWslm5Ou/+tBvSdAGLuzFlZ1WgIA5HyUo2tNAHr16CqcAGlsAsBob3ZjBjCzQHu/DTsZXWMm67Gk0AqASEEkH8GozsLqLDnsbQcAJqC97lxIjY1vnO7x9TnnIALApm1Zt11me2TWer+ajDQlXfdFALUeZKnsc4CyHTcaGuX0co6S43peAMT1vO3d2Jbt+pRTlu1yuQIAzjiyLRMA18CEYGSXY5U7Zs4wklb/Fv0B7YgsxWmfX9yNAhTL4/9KmpdRF4n+sbEXfgBctq/agzCcGL/fNcnTa89j0QAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GU%GU",
        "sumerian_transliterations": [r"saḫ4", r"suḫ3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAB9klEQVR4nG2QXUhTcRiHn3Mc27LljmwsoY/NDDb0og+8cUJQy9RlZReBFy0zs26MlSVh7KY0yGVCkS0Ci5DUNmwK6U0xCfswxGVXpoOWw+iiiNrCUTHWxZngyf1u/n/eh/flxwOZWJ40oYhKfmxuY9FLsqUh/W7AlHVn/eg+XUpJRACMDca41iZPTK4VeF1Xs3Mk5lcDoA5szOxYjuS4p247zZ/N22Si794hAiqcp22RxzVWz7P6/VMAqpn8jmhrEoyPxkcp7ysEywNJPp7XM1YOordU1Plv3ovCQrxMrtMzPtAqwRm7nqrOgMcG1XcQwXC/kXOx4ElBPmCtrPgSCHsnCy/pb0z7KNBp/grLzXMPHUgads1XeGdvrTKkOfWr/3XveWEVIC+UfvV98D87AMRDf2a+maxZSEkq5oh2XN6qdI1YXZsTHnPEQ+LVto8y0f8ECo6WJoKTvx8e3sBzbfvFxSrX14SqTfs2taVuU80baFyIROCpcO1CqmjCz57ZwWQ6OrQTcvtlOxzsbvGAGOranpgPS8ehWHgPQNmPNc3DIDJX9Cky3Flci2NiCYAm79KJOQB1ib03qJGu149slo/1nV0uDBy7opYCdzP9fWtXmnF5pKG98lcwK6W5X0wblJOMnd0uPqjJlvxK36I9KwFte4ty8A8KGpU/ha1CawAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GU2",
        "sumerian_transliterations": [r"gu2", r"gun2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAAC+0lEQVR4nI2Ua0hTYRjH/+/Z5nbGVlZooYUzFbSm2VWyspIQ0Yp9y+hD9qErWua0GCqKCFFeyi6g1ZJKhfwStEpKM/tgUoMampLgLVPIS17mamtze/twjjtnldjz5X2e5/2d8/6f570Ai5m88PSijGBk38hDf2/ELEIz6/Ur/dj/xdmU+mBzVJAIly9fmPbPM0U6psO1RNC293kkWYBeWvLdWPZq1FkfKOBxdDxJ9W+62JYNYEP1V73Sm1RO2EcvbVqhYFmWlYrpJUU2Pecd7c/mq5UCbWzXmVOPe2UUzPSAg2fpHPboi8q54L40z1Pl4HDPmKpq865UqwcAkRAAHhelSg2cBaXzCxkZg6f6FwApSALToHzY0OPyFqwOV6hjkkOKr4CsChywyjTM0B0YaLUTAMKow7TDp8TQ1uGJHvqRASTpHZXni5rLA4ATfRkSAKlZ1LzTtyOqAosr35UPAElj7ncz9uMSAPrJTAJY2qe7E/5s4ZY2889EAFBcMF9suekPAGypNRMw2Oqa1X+1PJ7OcJsdVP/1WRSXk5cMF0Ld8WKriIsIAiKALDrFJ07Ty/NzWkej9MfL/WYRvjtplkzUHEl/lOI/DQDo7Bzkp8KuteQyMH8Wq3i7XZWmuZsXPCU/wCV+9Nt52oicLgY2uxjvrnWZjO1Xn2j9srlzwki5/VhrdJ3tBojuyz4xHz2SKVOpNXE5UzVKANj89BgAhLY2aQGA6GinToRLP8Vz46HJGtaLa143RYPH6cT1dQJfv4Z3dN/uKng85FVTDPcTAAMPspIt762cRteao2MEAKjkzTH3OQcArDYit8OLuys3HozY1ssd9rlwv5/ch5T2peGkw22Puu3MsfBSQaAyxZqqepy8hvIbfKMJpYlX1R9CKjy2DMu8VJJI6WDyMuG63gsV6pClz9gGW+yl3lsmBdB6eMwjIEQi+K660cvyoaVtc0JKXRYAsdWEiyNG2/irPVYIMWsY98F9XxFP160ZGcXCplH4xqSiVni4fgNI/AoYrIHMggAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GU2×KAK",
        "sumerian_transliterations": [r"dur", r"usanx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADLklEQVR4nIWUe0iTURjGn28XbWYiBlNDyqGrvDXDFKWI0m6mliVlWZmRQUZJJdIVSkojs5IuhlpGhVTYZXahMRPULM1L2dpmTjS1FpKXynTqLt/pj83tWFnvPx/P8/2+9zzn5XwH+F9JmoqdrYLzP9punUTPWBXv3zAjTInu9nL/Rjn/+IIJU5MbF1qXUdb0jU4T0qH12s5+I8mxdWRiyLUZE+Ah9cVczM1StMVyrZ77EKmRTP0bPa/hvgAABJdUkZaRMBBIZ/Z6S6UdhvEsYYVnOFcLAACcW2EpcmLB800nixZC0WebKWsCK3CbUl1xOLYeACC64p1SZsFlTOO2ruo6k412dOW4B4Q92J2eoDql/gIAngWeu54DAIQDpCtTQudwOPRA+oFoRX7NPYOaY0nzXQCIylojAEAcTlSrx8cWl5tIHluCuccV7eeSCi8f3BpiBw+5JgKA9BGpCvptJMJ96pyRzQD2vhUB4tTC82kx3j5lreGAtLtOM+ePGW4gA54Agi6Ypf8lRU2wl0y5gneooKVO8QfeYWA7APx8BwCTA0P6GoYMbWmNKbzm7tBUiov073QU5EVldArt9VyjHuCGBrsR0nrvPewTFdd4nCduOgqfclS+uGZ2HC/3aGhVxKKPM1P9R3vVyjcA7E4v2y/joeczneKxzKi9m9jJjxfsqDTEf/B6Wq9q0gEAP3tpmgxgYhsdaH6VOtPVxy98/4tvUfyS/nJni83LVa4EAGbNyA0fOo02HADge0ITt2dQtilo1vp0XysNJpaQ2kUUf19kfjpkaBKXvOxp13ypleCcMsq8CICvTPHrOyrLHznKenE5AGB6Jj6wO6Po8fed+ars5QefmZszqx+2Lcje8n2YNTclLsNGBgAIcXJo2eO/XducdmztkScma3ckxOhLlWPdk7O6LLFYJj6nRB/Ycnv53qdj55VZSwy9Z+Y529uZi3/T07YPl7M6HRkmpdNslpiM7JhMbfW6NyXcL5JXuR+TqdsooGI+HxPhcC0a7a60nVge1NFDhAbG32u6YSN/kpHCTYPj3kP+g1aMQD7oMUDhv9dtllb6H/15rp+s8hc7Djl0fNmKVgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GU2×NUN",
        "sumerian_transliterations": [r"sub3", r"usan"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADUUlEQVR4nI2Ua0xTZxjH/+/poe2pBcEaICoCQhdB2igacRojGiV4meGDOrxkmqgbGjRKS6JDHfGaaBAUNaAi8TIM+sFL4zIlMuasKOjWMa2SEKhRsFwEZoHSntLXD6f0nBoNPl/O83/f33nyf94bMFIoftkyIiMGWdh6OdSvmBFoZoohUs59Lc4tqRj/ZPI4Ca4Y82U6dI9J67JH6Yjobf5vk8kX6NEHe4p23W9zVYSLeArtTFN/nt7flwMguvitQeUfVHU5248ka5Qcx3GslA7J7zMI2frmHF+3LGDmXmzNutEURMH0tgz6WOpBqiG/QBAXPT97zg4KuLdDXTJ97tIPXgBERgB4eUpVMXDvPSbQCdqX/x5CqQsAAWdhnFzttUbe33BwvDJYnx6973AIPB7FgDzrYIezIbm41A0QxDUN3ik0S03Hlscr339jSVatSXD2jnUMVC/68fqhzLyiMx5g6Q5alxy4Iuq9Fn4Pnwe5sfOfN3WO6lj9k1Tgp5ZsAlhqe63zPl3CGeb6/jR9ZMTZVNPO61uhOTcXwObubWAr825F/P0p/jTX/H/DhlldepI4Sj1jU3j0EIBzE3eNYU41j93tEEHtOEALzITXHqkEE0QokQ3PVWpmsf33ltVL6s5Lc5Cu8rUbKhdrbtqGsktOPNbdrQjXsgDiiqpzGdS/ktp49K06M+Z83vge5ZIaW6gimFWwCqhkAOLKYHzBoM8pxa1XeFNZbeHtJHmOCozMJVcqvaAgmFTGb7cCJOP1Qimva90WpA6OSTH2lCvDc7OMcd9lTdNdTZlQU5UEACSD/pchwdnns4Xv991lIVvsDX+amwoT1i26V6WDD6ddJxNFviLKl2S8K51jbdv/rHslm/RXlV4oAqDl0o50S90H4czwUes7CABQ2YONOLDW1XrzRsRxV26DHx86MW25dmaTcNg98fIB4UdKm1eEtRn+KE087TZafFZBoDZNNZU0un0eCoptQkIoXXCUhMWemuPItgxbJQsotaWHidf1QqzYR9AP/dT2u/OY/5axAGpWd3hFRNx0gL/aXzjQbjV7hgcYWl+wyi6hA4NvfKrJdNv8moFjd2cAEfiKyN7+2iKnfskCfGDBfLtU9bU/HJz4xi8/Aow9MJa/ezxGAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GUD",
        "sumerian_transliterations": [r"eštub", r"gu4", r"gud"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAeCAAAAACOSIixAAABNklEQVR4nIWTUXXEIBBFb3PWABZigUpgJVAJqQQqgUjAApFAJGCBSGAlTD92T0PYnOb9zZw7j2EG4F1Gpi4znFAOfZLtNEkpl5CTYN+O7KSiVG9rUf9SQVJKIhIO2JBjV6bRfM8262NxaWOVS6weVBTfpCepEm1jVUN63qLudh8m3UevWHdMfS0AjMHMP8/cTaGN2tbHH/Wwr4rt7pz+3gDwIsm0jZpmpDpXB0A6dAmY1EZekgJ8P+Yjhc7V8q6OgiDu7E10VWZbrijl0/K53S6MAvcVBun32ButAPG4x7Z7W8prksMGOZ49OhXjywgwoiY56Olla9lXctNYx7Y0HiOggp3nfbdEkdjs0RiXjfWtEUAV14b+eWruLu67v+ckMsnR6UST+BKuIAhybQWjyDUEvn87/AIAdZ84ySixbwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GUD×A+KUR",
        "sumerian_transliterations": [r"ildag2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAACYUlEQVR4nGNgwAC8U6QwBVEBY/mPREJq+J/+mERACc+y90eucOG1SHHZv9KIX6WooiwoPPWzP+/sWPr3qiKKaLARExKv5d/JOfv+X3++w4AdSfT08zB+BC/s6fe3//dy+u25VyiKEK39/32CKYKferb7qgkDA1vXk3k6cEeGLJnjIbbhyGso/++ia8cms71h/2M47Vvrti9QJ//ew5LubfWbEaLm3xvLk32P/zBdX33CpMlszg0GBgYGxvrayxwnt179DFXz323miyXXpt7cxBvR8rnk+ZwtvxkYGDb/W2+F7E/rH7cYJJeev/z3fSOD6YuPdUoMDExvpiYdQ1bDevsCcyybPM/kF+Z2ji8+pE61Y2bQ40ENU4dt69mq/98IZvRdd/v/ozOR2y/5M136gqqGgZnx17wD+zf8P/7zVP0JNeG/8kwsDFjApzUsf3VrHeK3q0h0XUvfzCL9FFPNv9cSQY3cXyXkC3mnLTvHwDLv8AQ025gZGFj/vzzNYpWVyj1hzWcGBoZDn1cbobh550wG9oBoBi6nO/9nmkDC+aiV9Jqda+6wMDAwsNxkYGD4/LuL4fdhBgbLqk+p695B1Jz7kp+QFfCdkYGBgfHjLwZGnvt3Gf69ZeuL2FV28Q/EaBZ1ZqvA/7svsDIwMDAwMv76qybHwMDg3spWthMWzQws5jwNS+Y+/gxNaK5Kn2SyWR2M97Td/Ydw4/+P4XwIXuibT7/3nf+/QwDFp7GazEg8LtcP51Tn3UNNzmhpnoHR6fmc+1WYwYoCmBp/v9EgoIaB+8l1RjRtGGq+91z5jyoCAMeR6f6whe7wAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GUD×KUR",
        "sumerian_transliterations": [r"am", r"ildag3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAeCAAAAACOSIixAAABYElEQVR4nIWUUXXjMBBFb3tCQBRMQRSmELQQXAhaCAoELQQVggJBC0GFIEN4++G0sZ108/48586T3oxtuJdpPlReH1AR/6B60Kzen0JROdwdeZArGimM7v5LZdVaJeUd9trKoc3jeT+H5vfNffvsWi8jgStKm/KsoRI2ViPXNcW42b1YfZuS43LD3K8PcAtTtvPvtXZyeHPLx/JNLeECVl/4fIvRv38CkKS+m451sCGAybcRAajK+4xWXVYSkCokVQek45itTqVJM0kV8G0E7mUV8KU3pXadVfyBYuq5SxNgvU8/UK4JrCZcUnq0U6tgvekauBuAjnu0ipeKjI1R2e/x6/ZpFMLVCEjqKvORAhfK5kYmN2unlQrj2whOnhD5e7nAtAZ2E+ByOJ9vu6VI9daEWWwWszZGAGM/2bSe2g7B0+HbiyrM2js90KzU8zMIkp5bgVtfwa1O99Ty5+438Q+TUcuDlFrPWwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GUL",
        "sumerian_transliterations": [r"gul", r"isimu2", r"kul2", r"si23", r"sumun2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAeCAAAAACk+HkeAAABw0lEQVR4nJVUXZnjMAyc3e8ImIIPggvBheBC8EHIQXAh+CAkEBQIDgQHggth7qFNozTpt7t6ihSN/jwScCwmmTd/3otlcz8GFbbuG24xKyVVYU06l5MUrPFJlM0zaQzR8VDqx9PJFJxuKya7MZphmlQYk3ExGWcd2OtCK5ntS/GeMTGseqDoni1b3HcsrfWqwcbIsrTsJLOkPSZQFeMaKyq5DKqviXpm8ZG0VQC/HnFnN2Ceh66bBwCYg7uq9m13un9MAPAJAEHmP5gAzBPMvfHRX1eI6Qc1UQBAYoanRSP7ZSqeyqHnQj65P6gVRiAQnm1tUGGMlOfTiwD4jMWe/gEOmK+/x9dBAQh1/DttTY3xXt/WvOZpCf459nue85QfFt8CDuTkM3a7lCgGicaQ66LpGeRWNnkAwNfmPD2kVubgdhhk2lcMTGmRESLIK+V1KUv5CgNTyB61Vkq0+zwwy6KLXrhMelKe7A/bObrHy8mGuIVZH4COB7R+xZhWtepJObhWkvDgKADcLnYbefI1f3muer0xpvS2PzggCcCHcqvjZdXKiGimHQGHF+o5dQEMya9L20rgMfuAZbf34m7n6c0v/AdxPRVkz493+gAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GUM",
        "sumerian_transliterations": [r"gum", r"kum", r"naĝa4", r"qum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAACX0lEQVR4nI3UX0hTYRgG8Ods33ZEW1krd5RmKlq6/i4ULQoMKmYQCREVSKKVFKRddNNNhEiUiSSFpSXmhTehmQQ5xWGWttKKYuR0/hk5TGc0ph62qdvO6Saic3bO6L18vh8fHy88H4X/nTUjDcJAFaOQs6qnQ2phcmXwGC1t6RruslIYmb7ztakaVaRdd9e7qgElyJiXKwkb+yz9IZFlKrc921ewRAThIjfYdbvg0CovwhrN6WQfJwqz7c5588X0iFfkWDsfvo0ThSUL02cjHwwgttHlSQCS/83KfVeVkhio4s4BbUWJf4PMpldpMhZotzH44G08bEjaoNWu1594tHxNYm1/JmniAulbNhYPWmeUCGvLOj/NBGXxbAVNjIzZPuX0KAnnuhe/JUO9KqvNUOT6M9+3T+qoSa//cbfdtFnWAsCl7Cpnfa97rOXdk0Sk9F/XRLFk+Ktju0FRcTR/onUOWAlHvbm39WDedA1MPyuB/Ndd+miWeAtplmL1lIPabUplGtxRLEMcKf4Sn+GMTrU3WPhtbkF+dbgZUOQa4m5NjPYMsKMd5cNZO2Nlran0M9n0/P5C3g+bn3WNwMGc7LDK2D21A29I8fx8YiwNNU0DHt3Woi8BSbur2VAaIjYg0PYRi912gGKp87jjkrCnbkzFjIEAWGpahrslCPBDs32pFqtzSdSU4AHjg/i1YRAAHAuEWQDwB4e0R9It46IGcaEMmg8Bwg5mMdWOuuZfEfvjLdUjO4TdBnnB16dJLo/kjPP7RbrseIwUBQDjTI2ocUT29wJV7MukZE/Fo6jz/QbelNcYgomFywAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GUM×ŠE",
        "sumerian_transliterations": [r"gaz", r"naĝa3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAADLklEQVR4nI3Ua0hTYRgH8P85O2vqXLOm86xw6Sp0lprlBUW7SbGklR+sWRliSSJeSCoI/RAiFSZWdJHuJVhQRkqUlk6zWqO7KLnUapnJXGVpykzd5fSluZ1TQs/H//vjeV/el+cl8L/l3XmGHfA9yOks/1KPgJ3k6ZIF/7aCckcOjx2pepmKIBH/bys+MjQpAsHK6NsTUt8WbauNY+mS4Otx60YoVvjToas/vDZpzNmC+dNMJNLILQ5OhyiD8cs9TcRfp4jW11U+EnLCzOFPWwDePlIq9PCjaKzN+rPgdbbvuxSk3B1784/eAC8rRVo0b1tcombZbufdjGVXzVIBNemyKRty4a4Ckm0/CioaN3al3c5pbKddjW520MTT4Bs1puFxAg7vparM4hPWfWpvU6Jebps9+SLs/UYXnvOwjGoZj8zQ6ft5sEt21b3st8LSquZ1zulTNKz+9dH9hUwFAipSVm/4YPzOoxx9x3zmLZwxWaneUqWMatTUCl+GhAd8dukG4Ie+IVsZm7F+UcJyj5j7OgWA5Dp+mV/6KsVW4an97NvKDi01nm4yd115cl6GwNb9IgAdAuFMSCHGhsssS77oPtK2WJynSxipHgAm7AA0XfYCR6o8fIXfcj27c1N1YmzfCai+lgArH9QHAOnm7UVXdzYX3Mm9/tCXZamhFMEovgUQ3USEKog+Y8aesME0iScTR863CIcG3S1NdQeOZVoWpfnzl1pT3gwMWzHoP9m1uV32zhOmFb3u9sAvMjZUePDd2/uPR9/eyn+uDPPCtfLA5ovCU/ZDRsMTWuSyqh2v0Fa1bL42Cwtu5QOSUkM8gIwW3wpljjoqNeBq4ZRd0llNIdwfMn0uQu/uBXDOVukJUMWkn8iThg/iNU4b/pqJBQD4FMZgbn4SQFTYJyrlgGsinPO7qaPWIAYFYOTCOMxXrADzzNQSpNUbh6cmhSEBwJoQedJnph0UAMcoYB8FgDHrM8maBdoezgQ5bAsFjM19RwBQ0mXdxy8NWsEpRlvWuZg926BqmdMKL64EACq6h4nn6F1qj39RAIjsL+d8MtS0vxeIDEsIMe0qt8jjlt/vTxzGMVpXVgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GUR",
        "sumerian_transliterations": [r"gur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAXCAAAAACgrHkDAAAA8ElEQVR4nIXQW3HDMBBA0RuPCIiCKagQFAgOhFBQIDgQUgguBBuCDcELQQth++FnZzry/q10Zl839miTTEId/Q2gjzIJMQwHwGfLls2eAIRso42WA/bZScg9ydo1a+xDZw2MNvqNPC3l/uhqC2/N5rSZ2Syeu5oHp9xTmwYBQGqNB1H/reBgqKNvtpE1HKMrw9JttPm5Pe5zAkSLgIvUjx8K4YI8phKgen2VAe5d/ocq+CvR9eFCDOGCVBM6drEgnPAKqRFZ8+ZUcJnQAajXdeUop939olvLdnT57+oByjerwnRxVHcXLQLc3wJ65ooCv5l8ccloBqTpAAAAAElFTkSuQmCC",
    },
    {
        "name": r"GUR7",
        "sumerian_transliterations": [r"guru7"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAUCAAAAADwndHIAAADiElEQVR4nH2UbUzVdRTHP/8H7hMIhoIGXGCCIfIUijpxkEY0qGbLLGsyMQKbbuCykRIGyzIqrchRd+QosYgiJ8gLCl0XUSYOlJwoE+4kHmQiQoBA98Ll/v+94MKyOc67s+/57PzOd+f8YN4wXHp5Xl2cH9+x2jg/vgQ8dIKX1t9LFL1lgxvoNW7RTvXZAmnhvLhcrPaGi3+FDi2UbI5b7wd91jm6Om9DXDKA+MbhRjff+buX+rnoI66FTY4tr/X8cbStMTr0jleOESDUXNSRc2HdzOt90oKNO4L0qSv0CWsNq+JnYP9c5NzhhPTuop+bD7fmAwuuNuQ01be5g5h9a8w+1DX1JrIeAlrv9zv+vusY77XZuqfyANBUnILk25FL+586dOmJvlcA6VOr2pjcEwcQVmva1TDWHBj3jR+8ds5UVlZV3vR1yfkP670ByOpaBbHVK+kyvnvZyxIFsHfo1G+tikmETZa6iMDS5k7zXsUcAy2nvb/tNp5oCUlp3QZA6r2TWhlBAkESUAQJQNeRpUQlv5hRvLGwLvjQSHxpVXmGsqmi+Ica3UC7R2+tb/uDAjOgyd+inpuUZ0xQVXuaux5AsY8/6K87+8HG6K/MpWHtfZZrW8+IZdb8rPuW/eHa3OCl2TrdbgVli7ZgWx9O3EWnhKjr+20CnkgwVfP0O1+agqXb1x8TAKGvMsHPsCTSjVCDR7rqvh1wb+g2CE7cvuKFe52/px24qSXw+jQsSl//0fMpV/SPj7hMR/0yPrk9taVAnip5Sf41flcKbSsBY97HQYuQAQGHqy7AYazrsWl4xtXf9cnN/pn1zYVffN4zsXlnUGfpSc0nJmtSIC4yGgkEyQG9mfvyIk/LwOQxd+v5xc95GAYlFV/PMtUek1lPdWzO92t9wpddTUsczjgD0v8WznZk8c4TMqiKQbchzK3wD5sIvLovIn/K8B1Qszt3sPaiv6mv0tzzqIW1H4x4W0bVaJumN4Yo/mkA6oKa8vcmqq3AxZhjiWeXd15gdBRAFBFFBIlZu/ln/+syDr89usSB4xMzp6usMVSFHPwJQLVsLTk62GRxFk+MMiZjHYA7s/1bWmSk3uCkyRsBzsNXlw3KR9fcdRIHqiMqZmv/vMllgRtFkK3MDSBj82nd02Gb+zai3Cfsb404k64jx/tnhWEYgpERuPJfB2Ir1z3kiP6hpCjpUa7Nxb8KAFID+uxp6QAAAABJRU5ErkJggg==",
    },
    {
        "name": r"GURUN",
        "sumerian_transliterations": [r"gamx", r"gurun"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABV0lEQVR4nGNkQACZySxP5CWSzyMJMSGxn663/qi1BlkWDTRdWc6DW5ZB7n00qgATCu/98jv4pBm//cQnzcDCiFea4T8+6d8fWfFJ/5JPZMYjnfKHp5IDlzRvSTEra+4pLYSIHIM4gtO9zUFR0WbaCm6YgOU5hkuRMAMc7rkyMDAwyFyeIcXLx8fHJ5Z75xHLl26zVQ9+Mv5nsU+9fZWBgYHh9aMXO/f/ZfzPHMA9TZPl+hmfiD0fmP4zu86S+svAwMDA9lN++d6fjAyMu0NCfzBcfL7QVkpSUlJCdf4xBQYGBgbdJ9lQ29hznjPczoGFo9TGFW4K4trTbvPCHWvBoIZwufGjZ7smn1+qj+RXlCgQMc04K1X4nQEnSLuhjMJHi7Hjtz7gk2b6jy9KMABJyYHhP/N/fNJcRnL4pJ1+oyV0FOB1q/9RDLIASqhJbv90TZc7/CZCBADgA2SQLYxwIwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"HA",
        "sumerian_transliterations": [r"ku6", r"peš11", r"ḫa"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAAAAADFHGIkAAABBklEQVR4nG2RUXEEIRBEX13FABawsBb2JMQCJ4FIwAIrAQtEAiuBkzBI6Hwse5dUdr6oeVM90w0m1dqkSJRUm9QAIEi1mgpQVXOSLQcgKThrDnDNXNHZh2pFHoBVReloukOsnDOaI64BdK2cC/PU78eWl+xUCgo3LirksX1c9FPcB7+BfwL44u+r4ybLy0hFidR7xte+jAGQJUkyxyJ1dSlkKxVoWmm2QMuqREUIMsBZDfqE1F1UsDLPBZKsz7dpes0dcKZAlBykM3PXj/0+W26APzPE3YBBXe5jAM+Xp3FE8r28f2HW4fyxp93/BTPE7e68vwLsjxEuAftX9P/AANi2APt+gh8NsqMQBXeMSwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"HAgunu",
        "sumerian_transliterations": [r"biš", r"gir", r"peš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAYCAAAAAC+OKDoAAABYklEQVR4nG2SUZXjMAxF7/aUgCmYQgaCB0IGQih4IHghuBAyEBQILoQEggzh7Ufc9nR33499ZEl+vjKccsnMpEyWZE1y3jS5zHY1oKrVIp/GSRjrohK8BYDmoWh+lCqPzepFCYAoUx3l4VeL91sHiJXtc+TOfNwBaD/YKpmZmbmW0SypnZviAfdHOOvhB5XhK4MnnnW8JyxS4HKUif+r1G3rXLe5nSZfSO4AYZ2+pgmuofd4hwz0EtPtu+S+9Wmd6ccEsJ8msiRJPhFdLpeW4msD9mGyKmGawMwbiwrMrgCrD5RtX5SheJiV3QZ+KOvuZma2S/uI7RqjKB6o7jWllFJqKixShEX7eNGeMXvwK5qKqoAwSEIIV7YXhRo/icAr0rkcZX2i3EJ8/o+Hrn1L83EARL7v9fgHfFWbw/AAsWl+DguAS7x9/LzuPL768neLp4oAktJ7h1dC7wDb7xlOUwD8AQOs4D1Vt7zJAAAAAElFTkSuQmCC",
    },
    {
        "name": r"HAL",
        "sumerian_transliterations": [r"ḫal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAPCAAAAAAqxAuKAAAArklEQVR4nGWQURWDMAxFLzsz0EnAAkioBSzUQiehk9BJAAmdhFooEoqEtw9g9Jy9r+QmJy8J7DIaOEMH3I7EY0+cuBRU5gNnB0B10BeVqZoWUxTBh1Q1t5goJQvgamjwfePp07p8WF++t8t62jsxVf3p1jPPvMeu68bt+V4e3S6yFAxgggLEbI45qhP4mKQEEPJxdxiAJNm6O7r6ewgwFOVzkdIWrOLV03Dy1GZ8AcWPXfnAZSExAAAAAElFTkSuQmCC",
    },
    {
        "name": r"HI",
        "sumerian_transliterations": [r"da10", r"du10", r"dub3", r"dug3", r"šar2", r"ḫe", r"ḫi"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAABiUlEQVR4nGNgQAH+s/UZsAPBze9s4RwmJAlGziyX74zYtDAbLHy772EMFjlm79u/7694sUwUU8brzoHmtTffv3RDl2HyuLdNloFBIu70Nh1UGUaPu9vlGRgYGBgUD+9AlXO/s0MeylQ+skMbISHkf3OnApynfGQ7RE7Xyjp8+qtjCBkGBpUjO7QYGBgYprx+/OTTe28U41UOb9dkYGDw3PF9z7aLXKiuUrm4S4OBgUG4+dXtheh+sby9R4OBgYFp3+9SdCkG+3O7mRgY7GX/fMCQOnjFnoUhIffVGyEMqTzzbIal3//vP7MLXSb/YRoDQ9vE2bt/ffNHlSl4kMLAwMDBJ6oTce6OHbJM0YNkeBRb7LmBiHiGwgfJLAie/t7rNgjTklmRzdDff90Kbg8bqs0GB65aMjAw8NXdSWWHiMATCaP+JO5FvzQc1No7f6J7hdFw349nGx5eM4AJINLh/wupq8Q/vD94D10PAwMDAwNn9Yc/0VjTKAOD4Pr/EXAOC4rU+3nMT+EcAJ0qfyj2n86uAAAAAElFTkSuQmCC",
    },
    {
        "name": r"HI×AŠ",
        "sumerian_transliterations": [r"sur3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAABw0lEQVR4nGNgQAH+s/UZsAPBze9s4RwmJAlGziyX74zYtDAbLHy772EMFjlm79u/7694sUwUU8brzoHmtTffv3RDl2HyuLdNloFBIu70Nh1UGUaPu9vlGRgYGBgUD+9AlXO/s0MeylQ+skMbISHkf3OnApynfGQ7RE7Xyjp8+qtjCBkGBpUjO7QYGBgYprx+/OTTe28U41UOb9dkYGDw3PF9z7aLXMw8LMhyF3dpMDAwCDe/ur2QgTeuRBhJzvL2Hg1GBgamPbZV3RyZJeuvf2VkYGBgYD1+7S+Dff9bFgYGe9k/Hxj+vBf05HrLzMDAwMBxkYGB4eCVCBaGhNxXb4QYeDVO9F74zcjAwMDA9PIfA0OeeTbD0u//95/ZxcBhiORPBob8h2kMDG0TZ+/+9c0fNdwKHqQwMDBw8InqRJy7Y4csU/QgGR7FFntuICKeofBBMpIn9fdet0GYlsyKbIb+/utWcHvYUG02OHDVkoGBga/uTio7RASeSBj1J3Ev+qXhoNbe+ZMBDTAa7vvxbMPDawYwAUQ6/H8hdZX4h/cH76HrYWBgYGDgrP7wJxprGmVgEFz/PwLOYUGRej+P+SmcAwAwVI/Hx+N2ngAAAABJRU5ErkJggg==",
    },
    {
        "name": r"HI×AŠ2",
        "sumerian_transliterations": [r"ar3", r"kin2", r"kinkin", r"mar6", r"mur", r"ur5", r"ḫar", r"ḫur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACOUlEQVR4nGNgQAH+s/UZsAPBze9s4RwmJAlGziyX74zYtDAbLHy772EMFjlm79u/7694sUwUU8brzoHmtTffv3RDl2HyuLdNhoFBLOr0Nh00Gffb2+WZxUT5hTUO7oDKQS11m/Eg6oVolvBvzo6/y7+UXIM7XshvMvcFGTlmTp8MbravRXITtBgYGBgYdXkZZRyC3p+MuzX7PF+ayoSbHN9VMl4UX2NgYJwS/oOR73eVqtmmU89/pbMu/sHE8Itzxpei6wxMW8+K3Dh8cxXv453X3378dOvB29evP11NlJqowcCy/VRB+puN7x+06Wx99tvkGxMHAwPb/DsZi6bksDC8rbe2us3Nt3fvgw8Mb748YmJgYP3FcDylfzILA4O9LAMjq9z/VXcZGCTfbId69OCVCBaGhNxXbwQ/XnOZd/Uuo+03NSYGBvYZrxnyzLNZlgZxHOB1mcl7e9ubjwzaXx5ADMwvap3N8nAWl4Lej3BO5kXPGRh432xmYGBgYCjMb57DwMjBxi6uUyK83/npszuMpj8uMzMwfOYMbZv/j4Hlxw+G11ceNAR/PLH/PSPXpx2MDF+rbSoW/YOHvN6+zz4MDAyRngwMDJm3kliRY0V/9xUrBgYBPgaGggcpbKgxZnDgqiUDAwNf3Z1UdpT4YmBg1J/EveiXhoNae+dP9CTAaLjvx7MND68ZwGMeLvX/Quoq8Q/vD95D18PAwMDAwFn94U801jTKwCC4/n8EnMOCIvV+HvNTOAcA/RTPhL10oRoAAAAASUVORK5CYII=",
    },
    {
        "name": r"HI×BAD",
        "sumerian_transliterations": [r"kam", r"tu7", r"utul2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAAB00lEQVR4nGNgQAH+s/UZsAPBze9s4RwmJAlGziyX74zYtDAbLHy772EMFjlm79u/7694sUwUU8brzoHmtTffv3RDl2HyuLdNloFBIu70Nh1UGUaPu9vlGRgYGBgUD+9AlXO/s0MeylQ+skMbISHkf3OnApynfGg7RE7Xyjp8+qtjCBkGBs3jO7QYGBgYprx+/OTTey8kGfEI84PbNRkYGDx3fN+z7byokyBMhn/GDG6li7s0GBgYhJtf3Z4tfnC6HkRGuO+TLQOD5e09GowMDEx7bMsWLTA/cfPPfwYGRjUhptRbDAz2/W9ZGBjsZf98+PeZ2ZjvAzMDw1/eH4JMDAwMB69EsDAk5L56I8iucaf3xGcmBoZ/fL6NijcYGPLMsxmWfv+//8x20TwDuAsnzBdjyH+YxsDQNnH27l9fg5AcLxHGkf8ghYGBgYNPVCfi3G1bJDmG4gfJ8Ci22HMDSa7gQTILgqe/97oNkgwrshn6+69bwWRS2BhQgMGBq5YMDAx8dXdS2SEi8ETCqD+Je9EvDQe19s6fDGiA0XDfj2cbHl6DexCRDv9fSF0l/uH9wXvoehgYGBgYOKs//InGmkYZGATX/4+Ac1hQpN7PY34K5wAABA6YZTTQb0sAAAAASUVORK5CYII=",
    },
    {
        "name": r"HI×NUN",
        "sumerian_transliterations": [r"aḫ", r"a’", r"eḫ", r"iḫ", r"umun3", r"uḫ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACIklEQVR4nGNgQAH+s/UZsAPBze9s4RwmJAlGziyX74zYtDAbLHy772EMFjlm79u/7694sUwUU8brzoHmtTffv3RDl2HyuLdNloFBIu70Nh1UGUaPu9vlGRgYGBgUD+9AlXO/s0MeylQ4sFULISHkf3OnAoQpocxjd3OXFgMDAwOjLi+jjEPwnYhHEKnYiEvy1/zfFF9jYGCcEv6Dke9v5FGzt9w/GX/yClbpvUh4NfdL0XUGBs8d3/dsu8imfeTYgQOHjhzQ9bqfycagcnGXBgPT9ugePdXzv+7s4T/3+wHH5YeX75//xXAnQ3GKBhPD2/orcq9iZS5dOn/54MnLzHJvfjMwMBxPEZrMwsBgL/uLsfrBB10eIU0xZRVpmX8MDAwMB69EsDAk5L56yX30vLD4PZaHfx6ceyHKxMDAwJBnns2yNIjjAK9+4i1TyX1/zmqfWS9tzMTAwJBf1Dqb5eEsLgW9X8q3OFnYWdhY2Rk4mRgYGAoKmucwsDSxsYvrlE2O/cLNwsHGycbAwPCfoSiveT4spCz2XPXX1nFQ1FdgUFujnfMgmQURivp7r1swMDMwMDDwJE+7ncyKHPT6+69bQlj1z5LZUGPM4MBVSwYGBr66W6ns0DiER6b+JO5FvzQc1No7f6InAUbDfT+ebXh4zQAmgEiH/y+krhL/8P7gPXQ9DAwMDAyc1R/+RGNNowwMguv/R8A5LChS7+cxP4VzAGbCtZHCPtapAAAAAElFTkSuQmCC",
    },
    {
        "name": r"HI×ŠE",
        "sumerian_transliterations": [r"bir", r"dubur", r"giriš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACRUlEQVR4nGNgQAH+s/UZsAPBze9s4RwmJAlGziyX74zYtDAbLHy772EMFjlm79u/7694sUwUU8brzoHmtTffv3RDl2HyuLNZloFBIu70Nh1UGUaP24eMGBgYGBhkD201YkR2oduEx7uU+MV4JTj/p0kvhPiNkYGBgUHItu3xMY05an9/sH1T3FJmf6HiKgMDA6MuL6OMQ9CbhT6/97ieVbthdeJDUmX676JrDAyMU8J/MPL9nqv72E7w65vf7MJ8m4XyGBd9LbzOwLT1rMiNw0/m7xD/tvPT428H3p5/J89zP1FwggYD0/boHj21C9fnPni04Oy123eWHNrLpMd2J1VxigYDAwPTvt+lDAwCdXFGlkrmgi68vnNlGBgczu1mYmCwl/3zgYHh40vlK7ce3X5/6ccpLk4GhgNX7FkYEnJfvRFiYHBxWBz8TujHR9XTRRefMzDkmWczLg3iOMD7xten8sl+r8vKzwxOMST4HWXIL2qdxfJwFpeC7r/pEjecVIWEfimJqOy/8I6hoKB5DgMjBxu7uE6Z4eEXEi+U7vG/ct/BquPrU9I8/x8koBjMm0zv35iZdFn8ieyfy8W3jDsX/oGHvN7On2cirOx07SS8heb8SGFFjhW9vb/TGTiYOBkYSq7XcaPGmP6BGxYMDAx8tbdTeRgQkcLAwMDAqD+RZ9EvDQe1yY1f0ZMAo+G+H882PLxmBE8TcKn/F1JXiX94f/AOuh4GBgYGBs7qD3+isaZRBgbB9f8D4RwWFKn385jfwDkAU7TS2HUc5s0AAAAASUVORK5CYII=",
    },
    {
        "name": r"HU",
        "sumerian_transliterations": [r"mušen", r"pag", r"u11", r"ḫu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAZCAAAAADsnKr4AAABCElEQVR4nH2SUZXDIBBF7/bUABawkErISshKwMJWAhaohFQCkRAkpBKChLcfTSBJu52/O/cMzMB8ATibhoxtubGEtQOANQB4PaNfNb0UfZwUnxgUfa/RFG8mTXHU3Cw8TsQCAM0c8XIFNVYAwMnLV+w1m51nkiycFhq45b2/c39UMur2Gqtfan3mUM6DBJwU+BSn5IL55Afc6P7358y3Dz4luvbouvbKGYZbMC002wbblKHJJuM1anKgbbmfzZoZNTvYeydfMpqe37LxTjIl45fpijdBYS6Z8/XYdTSXNtX5XyZOtnn3YPX+bu7r+a/13C/WlFV643n85NcX93YDnRrY7eMhwrp6fygjgbEH9TwEAAAAAElFTkSuQmCC",
    },
    {
        "name": r"HUB2",
        "sumerian_transliterations": [r"tu11", r"ḫub2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAZCAAAAABmszO5AAABVUlEQVR4nH3TUZXkIBAF0Ld71gAjgZHASGAlZCSwEmgJ1RKwkEioSKAlFBKIhLcfSU9nk8y+v8ANRXHgB3qb8/KGkOcWccMhaXjMM2IMQOipm4mwjkxHh4FrKgAxinVVUzk5IFFTpjkAgbQEQOgvIIReewAAUN1aJcUracatFNf5SB0vVyQ98HM/Flw5d5PvmNoBtkfSQ+OutBsaDnB+3FrpsuvJqbu/vr72CABOjOPwdJUGUI4rAsBye//EaOIBBPXtsY2fIIDp831KVmJS9xttN/FP6WeSkqMD03el1/gcI5awa+sKBqmW8eftY9HQnvbXAbkYB9em+wRg+Sh1cV9Fdnv0eSRrDq//hN2tewQtrTAUkmM63KBC2aCQ1CLaaWXAObW7FTqromSXcKEA+F62W5bpE6u7ZgCSbDCwcPzeYTtwAKT+j+3h5Vt55XledvX4TvkLkZ3Ds/mJoNEAAAAASUVORK5CYII=",
    },
    {
        "name": r"HUB2×UD",
        "sumerian_transliterations": [r"tu10"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAbCAAAAAAre5KyAAABk0lEQVR4nI2T3XXcIBSEP/ukAVICLoGUQEqQSyAl4BJuSmBLkEvAJaASUAmohMmDtF6fjTYn8wZ83LnDDzxWtC+DZ4B8Qk211a/jJ8a2Rr5vwZY1bG+fCy5Hfi2kaVlW56KHMJLqKDZaGeFWwZcuIAxJkmbAuqy3WkdNh2uMU6mR5oGoGpOaA4LUPGByO5jVxwTkDGCKdXgAVB1AlMWdbHsPvgHQu4742tej6pHTDMDn4YAiyR3Hc1XYCgDrArBlNxtTeuOy3VVsVT07aN0B2DwsjMbV+QZajGWMktWq22O4pnQCArjUpNmaOay4ps4Ofru/uu1yCSltF9pHeO9Hu2cVAXC5q1aN5rsdFZ850/b75aeLvP9Y/XpMnYMEs8A2BXCPQTeV0abl9enlo6X1Ct6H8TFOLJf3Bdhec9n8p4m7hQnWpDn5274kueMcNWwHp1kaZbpzMOUDNEm91io1C/ytebjjZnpPRerZn1CAH+UAk3zR7M4xIOYDDKqyhxjw+Sj2n/M/4HjsC8B0tN/Tv7ldfwACrfeknT+8TgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"HUL2",
        "sumerian_transliterations": [r"bibra", r"gukkal", r"kuš8", r"ukuš2", r"ḫul2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAdCAAAAADnHpEhAAABOElEQVR4nI2TbXHDMBBE32RM4ChcIKgQFAguhASCA8GFYENoIEgQbAgWBAvC9YfjfNRq0v21o3067UgjUACkYZGuBq4RWvmQY0K8ulMGoNXzYrhFVRxdDVlgSEuW57iOkhqy9BWHoHsdomRJGcCTsixMVNnrMJ4AZ12YnXVLotY+lJq7MC/rnVmjV4/WPKi1dY83U6agbOXMFCogjjlxkSHlAhbTApEBgZS2jMIVAvB5XxrkniA9lJhFu9WM322p+TMUz36yrfzTca4e+0Lx9gFyzp/60kn5DkmXkyv3GW+Q4+Pop0uB0TtEP+aLb+IWktUczRxhPsqWIVzftzWbYSp3Ci1QSVd/OWBf7g1ANcnnJbwAAHY9TanLM3Q+aCjc9G9JMHs7DAY7/mPWPL2H8I//6E81w6v0BySmkEBBacUuAAAAAElFTkSuQmCC",
    },
    {
        "name": r"I",
        "sumerian_transliterations": [r"i"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAXCAAAAADbiLvPAAAA4klEQVR4nHWQS5nEIBCEK/ONASzEQiywElgJRAKRwEggEogEVkKQECTQEnoP4XXI9K26+vkjaHyJi79ZLnOQT8ab0mYCRQBAPOLgAGJGujNSr0e3AvdphtmKakyMda9Chl3REQkAEvKwXrDUXMIj+9YPyYEvXbXnc66O5axa2SsCl1N33ZJ+htskw9bZ7MZPF3I67eUfg42a5Tnr3s9XE1Om346EVyUpJgKQXrQOrEARAmXgmZfhGs4djx1YWT7725Pym8FfKvLTT3sTdmHUTfFobAuRbGc8ROAgnvJAds95/AMqkoDxsC9lsQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"I.A",
        "sumerian_transliterations": [r"ia"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAXCAAAAACpR9l5AAABXElEQVR4nH2SbZECMRBE311hIBZiISchSOAkLBIWCUHCIgEkzEpIJAQJWQl9PwJL8VE3v1KpN909U/Ol/YmXisZccNFfdsyFECFrfKWY1KSmiaxaszSQmmz3jgXXssPl5qISpBxMMjMzS+FGuWpT80BQqhk2LMFTSg803kIux4njFSinkS1g0nSXGKTku5jUH1EZQBrWOEGpadrFGGOut782AbT4CO0VB93KgGApWgqj0bJbqZ2yrEsnA3zrHZmz8qqWtCon6211GFrz34XFpiE6gFC289PeLgePd79XopjuWTSt7l0Lam0JSO2sOvaxR60h79TQV3JWW1cRpJbcE+WaAV8q+7Lm0G8cmAH8ddu/jC1srocHBMCyXHmr3B4XEaX64ogZ8D278zpZpPwclnclNoV9Gubu6o6HDwiwgUvcRbcAXN6O+04FKsfjJ5tn6vIxyjPlT/v/iQX4AyQ/1RjN9kxpAAAAAElFTkSuQmCC",
    },
    {
        "name": r"IB",
        "sumerian_transliterations": [r"dara2", r"eb", r"ib", r"ip", r"uraš", r"urta"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAbCAAAAADehRkCAAABMklEQVR4nI2TUXWDQBBF7+bEwFbCWqASJhJiIZVAJWwkEAkgYZEAEoiERcLrRwIlDaR5v++emTczu45E349Y0Vx4UqJvwQqodNPxGZo9oFK0WqcVCDpFSzevGwpVqxB+SKYIgCnLr1OclPPdG7ZKgc+qYA/QlA2AXa8h+P5qBS3maUP4Hi/lNLvpHlVKWVItKUd1uYOjeKRCLgdvOdaUqSup6uxnb6IMogwqBRg68Ir8pYK64DNgCYgRSDZRu4m8NmGI/daoc8eoY9aalrUIVE3/4dyhdc6dz8659uCcO7CkwrH//BrH9Wb7Odeh30CWFO2L4LsX3oIqt17DAxVTeANLyjZfwQBfACEAHqYLRQ3qtF7hlzqJuL7zxe73ASv82DSvc9XS8P+cWemNXWx/jIV+AAaJ0+g0kufzAAAAAElFTkSuQmCC",
    },
    {
        "name": r"IDIM",
        "sumerian_transliterations": [r"idim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAKCAAAAABp3trNAAAAhklEQVR4nH3PURECMQwE0C1zBoqEWCgSYgELOQlYOCS0EloJRQIngUhoJIQPfuBmyv6+2UwW+JM0+ukWpyzPuMNfaaLdh3PobGsDmH81MlnRfF521qr3RscrBNMIC5LDJp8fHl+8qkhSuiwETtGaHeqKUiSDUd3HNtlwHRXD+3whETxPFQDeLoYxTa/NmDgAAAAASUVORK5CYII=",
    },
    {
        "name": r"IG",
        "sumerian_transliterations": [r"eg", r"ek", r"ig", r"ik", r"iq", r"ĝal2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAeCAAAAACdn8hFAAACwElEQVR4nI2TW0gUURzGvzMzO7uz6/1SGGySrqhplheiCJUepB6CSM3CwLQsEy22p4qECMwXi0SMoIheyiAwHzI0bU2yi1oJuVpZZmupqQVe1lVnZ5zTgyvrrrvi93LO//DjO//zcf4AAIDhGMKWKc+3qTiHVCxhOAauIgAA/mj24+nkI8GjBovJygAAl9TVHrLPdN8TTbJqVZTYJPu0qWNCpCos8Nd2UjJWWueJhq4sZ0w9Yrh9VyxOfj2bNlaBrc0DhpYCeFZUo/XJ4TAAmaOyMp8HMIXT3/TuFOdYx79Hh1VXNswoL+sifTuaNgAd2s7f3uiZ9zFteVdKWv5RaY/Qfo6A6syvVnWwTGNqMDC0z/RuQkxIEBvmCKhfqMY7LSFypMgMwBwY3iUD0Bwi3mli+xmfQSYWFKpThdoIqB+7OgvOuetLKy8yDStyik+hBFAhqn8NGirlq2WWY6ifn4YFqE+Usga9GBFScQ8ASvWXAUC7w/2XAM4TsmgVNwIApQCA1c6++53e7Of0S9kWCUjxrZIAaLe483m5K26zzwUZgp2lPOKWYPqFeqe3HKe/2dpjB0r0FwEAldxKls26KtxZ4a3Rjn6wA2CXhoB3zbugZso8x9162rRUcr0JJ/Z+GaM0MSDfDlDt5sGVtPlThFVhzlTlL5XM3/HUzORgDa/IgiAIguD6yM7iH3Hx3JvUG9EPewFxIW5XTe2fSZmGbHpkA+AfseiCDxyvL+B6dvecPdD2lkmMGeoYijQwUGIDDtoBCOG6Yy6t2/sziLE8J/MkbCoeskxZAlAeEgDKcBCd7hzBvPSLC1YXpVmftX6klDiGlNKloBTinyQtw90zovFULh5Qe3VskAoepeYdUgOF4/0CRMXo4xl11fXhZhOPRiO/Hhjbh7pf8NB5acJdJMkyuT5fBz56evWkesfPZ/wHrQz6szKPBYsAAAAASUVORK5CYII=",
    },
    {
        "name": r"IGI",
        "sumerian_transliterations": [r"ge8", r"gi8", r"igi", r"lib4", r"lim", r"ši"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAXCAAAAAA0StDxAAAAxElEQVR4nHWPUZWDQAxFb3swgIVYwEIsUAmsBFbCVAIrgUoYJFAJVEKQ8PZjT9sFpu8nJ/clk3knALLfJ/DmdmErl0KhaNirUyLryGGMVn2BkxVR4kmzUoE3Sp2G44k6ZK4I3/NZA65R/8+foZmNCXgwpSXZO0LMrRxXL+v0UpX9+u1MQI31rD/3FYBqfa0a+fF1e/dJYyvDtWisN5/yWNTi0nCIsWjAVQoeURcNXKlskNTtjOqvXM2O08/Xtv350+BH4xeyG2lHUCqsCQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"IGIgunu",
        "sumerian_transliterations": [r"imma3", r"se12", r"sig7", r"ugur2", r"šex"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAXCAAAAADSYxu1AAABCUlEQVR4nH1SUZGEMBQLOxh4FnoSOAldCZwELICEIgEkUAkPCVQCldAn4d3HcoWyO5evTDPJpGkr/MGyrBFkzXfAByyaVJNOnzSAtkRWuXQ0mTbqeKdC3dSZg7ZJ1ZV57PSK0opd3ZG9JNr3/qbag0zqwEmnws2H3KkSeFLdzCnWARwjAAssaAKC2b335wbc2S5pv03Wbi4txLmiq80wonHyDFZWCCj2Fuv6GjPW0pCcRQx6zHMeunIteUEvcxsDWhgZ5ksrCJFgRA8KAMmzeKHluEGnasC3IR80RgDAPKDDG5wueUlz99bibZtXxe1bPKidv6oXfvx6C67xzEfe810d3qtckv8T8QsEHpO2NYRiyQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"IL",
        "sumerian_transliterations": [r"il"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAaCAAAAADKl7C4AAAD3klEQVR4nHWUe0wbdQDHv3e90gct9MUK3ejAsoFQlMeKyMYKijBhjG0xwoi4oIOY+Vp8LVviIBCVqds0bihuyRbNtmQ4pzhdyoIixCFQHKMI1HRDyktqC/KwhdZy/gFlPVq+/1zu+/t8fo/L3QG+IT+rFvmpGQi5dPE3tM+8m9kE+GA7C+V8Pl9Y4jsBmTl0Vspowk6qQPJZ3tW3NN3R/DNNIy+QaVPZv7uyGI3w5G9A0nvrvTupntZfMrpv4L+ajWLpSiTykoGBlkcgExEeUlI+WYrob84yV3nUfEnZ18mnGnNKdE6CXCSIRYJcdMek1MyoZ3Ao7NjoEif+KGOqPbomNY+pt71bI1Zl2ElxmyNhU5Q4UiGJDGGHhswZRqVBwFja/hgBAEC19YpYdf7hcdOqR3TZsuNWJ8iIAs73IaJWaq47yHbzb93e2udy13G4ea2HL7xdnPZACPT5WewnWFfd00w7Ut5I19Gg3jecWy+3qeNHyHjuZvpT1xf9xzOz8zW8H6xbnpq+62rvH3+9gj56hlaave2QM7fby5rdIIDnK673lg/3a/qs+V+eAvDQ53GDjVc6gM1xak0YNWkhc4pFb16r8rKJ6qJd7F8VUwAgc+cmOrP3WOPLRjQAgNP0Wyug+PEXP9F1tjQYBnMT7r8NxdZKdrJDAlDbWxac5vnZgYjZUbt1AgAKM8emeY5lcKqpCfxYZaJ1wxGn1XjXNDIEiJ6pCPzORQAAVVnfRDvn4VrAgtM5DcgOZqs+qHfAK3a9/mtExUZtSkt3ob93dKfaEGxbGqJse1JYJQvcUonwhVh5+aQgJfwrSdckfGIyAesUETF5pfPSIt6zy+86dS+0kNBwWFslAVolX+tmZzb/so/rawMALGJBmHDyjjRrlqCX9ccWK6vOuRNPhx87sb3w1JQr7uU3Nvh1A7elblEsDF/s6QsrK6I8uvHC7SPddHC/nW/YyDZYYLh3WBF/fW6VG6lNTpKZ/rxmNE0Aw+aZ11LNSxMowdLyA3MC5fmc6AIuAKh0HVEMN/XQ5YEx24knY4SeRnK1IzjRIWEu4fnIovUVK6Bg7zudQ309pe03Bd6ocvhoul0CUF7d8nlg/Ljs4iwARGkz0ritDa6X6hKkHzLOY37lHzcBpr6SelWdrkmcUBA9fqe666+kWpmGPdjLRBqIRKylz9fuitmt6rl1vHdm2v3qgeZt4cP2RSbiXtqrXx2Wdp5of9e/DhogrTJeW/V5BccH8vebXc6BiR2e0YCkwT+g1lWtRh78KWhNveCg6P5NcncZ0m+oVi/OI7BWSO+dsZ7+EexQoT/uf+14YcF69rzGAAAAAElFTkSuQmCC",
    },
    {
        "name": r"IL2",
        "sumerian_transliterations": [r"dusu", r"ga6", r"gur3", r"guru3", r"il2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAZCAAAAABMA8IWAAAEBklEQVR4nH2TbUxTVxjH//et0PIOowoaiAJjEqFMNodzmlq2YYaY+EbYfAM1jg8T55aROXTZcIoLzG0hGhMlOseGyYYYhoBOkGTKlIKDlMRCC4KwtWy1gC195d6zD20vFYzn07nP8/89z3n+51wKz1xlK7Y6ACC/qKNHHZexpjVz5JaOX75JXeMAgIAPdt3tmlqoeBkA6Hk0106iAQAqPXk89oSM5bYS3mwl1uIAjyBbT0wPbaQZoBSHoubi+UZS6NltGP9pVbNxA2I7dHsvTH8m8Sne/qfqrZ7OFwHmXXIx8Wk6Q/tDd4e3z0ej5ZNFALL6Tt+ui5zVnOxu+nslACx5RO7vi/GjV/dOFX/K7/F8RN4hvcEAAivI4Jt+ouRuUiUBCzh69MNlhR1PGACA4JZtTOM/t9PHzVcBwNySWW0D4GjcMz3mhw/0pta6wQK860Gt8vXkNisNgI9ctQA41hrziqo66Ts3gE5rqwAA47r0ysp2EScDOgMBC4Qogt7RlqgnBQAAs08RrqmwoaFy55fZX9wGRuwuj94V4D4WT0Q+1ACApUhoIn/6uE2gPFGhRRVVYwOc/51q/77u27OTbkLyVGpL6ogLme3XA1kv7VJGUAC7w6CEPlf1kPFVdaf2cnIJO80HDhUcKc85YgLVU5rJ6K8FTJ04w88Of3gbBbC5W7r4+Jt3AsWwMzwnsXlNyrnohCFjzOUXWhplRJfXOHB0Ouxilf/tUgDAFrCjyzRh61kxPJNw075wNCT4tSubNfwB7mBhqIAhraQv2aVI0vnhAgCwtkv1BvZPMzVble7Tl+01Vd8tlWaVmnB9mxygBmWAXXnmvHac9yrdoQDAooeY+CijRXz4vBB83z6oWXTJ1bLxnvTDgkE5DTAMQMFxONzss3hm8ZQAsCAwsBkREyLuWtxvcXKY4WCypxWlfaO+6k0RxLbcc4qHzEunABaglnPqXx6LztuiOdrTwb3knPa9znhfQjJ24oZldvaUVMrTXf4HfWpG7E5CLxAQQAh7H/VX/uXFurLaOn/nOc/sAL3aeOiGxXel5OsFDBgptawhdkvzedWuEeJ7aS7MWywA2zXmbF+bxdvGvjJoe/hOiSy/KesRNNt//pET4OJ5OAn/bJzq71+rCDL4srEJKxxrHYxmxwQwNGzcGrm737FUqoyPSFZSoP8y+6yQeqwDu9/Z1nRL/BsPvuHM/kqedGACADN1ct3HRyeGHUyJZDyuhAFX7MO7ZVaAQtwIhj/5zTl7oMSZ6RpnetdmANhdMRwzVt9hBxjCUwwBrbF5ZbTUwQOIJw2KuSNlGckmAODKyfj+xLnZp1aC+dX5jjSSKAAIufxg3XNhYNGv4fODOb9LAYB6KeX58P+OOqOWcQPX1AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"IM",
        "sumerian_transliterations": [r"did", r"em", r"enegir", r"im", r"iškur", r"karkara", r"ni2", r"tum9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAeCAAAAACUdGg/AAACFklEQVR4nI3RX0iTURjH8e+7vZabhNZMyvFCZmoUGCHlgsjAkkik2IWyYlAUJGSXY950uZiIiKGEZay1/hCFF0UUVEpSUv4pIgN1Gzb3J7ecodYQNnm7cEPKbe65Opzz4Xee5xxYLaHOqCaj2j8xUJj6VLG63N0kLcqZJNZOyu6R8gzgCf+nL0G5ZX1Y47Htrax/FL6wLvTeyQe2WkPn0sNqj30LAGrLrDGN01pD9vz4WnVt9mwK1vB0dC76RgJBKQhKgexWj07XvjOJPDK5PBFuAna8NJk6JFB3DJs9b8sVa2new+j0AUDzJBY2bwA2O3yBxe+XtNlivLJEAAFK+wJnXMC+vsFGP4Bkq76Zo/c9mxNWsoSY+xeIbDNovAKA98NXPwCRAEu9upJTC0LiXqUAYqm1dmF7gROIzK78uqalIlhVP9XVN/Nvr+9kOSK3ZgEqhwVgk73/ynS0edf/84gfi0bKPBfH7ImNjZ1H9XlTV+/H1oyuedx/Wdv2oyGeKdoCNeQWJX16o3sP6vafelQOC4qe0LGkCkSc0XkiZrE7+kJG2XXa8DqFhMpxLaDo9Bl6hgZ/n0zpEpKCMVmOxLpzUrrEk0nXs+7NuD13/6yXWTXw/iDnl3xlaSAV4xpFo+t2IeTeGC5OJ+ucx9u+mZQA0uHUbULJZ//zUX26qHgpgrf8POjNQIKy2XUoEyey/Kp4PhP5F7fdtDaXloW8AAAAAElFTkSuQmCC",
    },
    {
        "name": r"IM×TAK4",
        "sumerian_transliterations": [r"kid7"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAeCAAAAACUdGg/AAACpklEQVR4nI3Ta0iTURgH8P972dKZt2ZhjklpzSRbhaRGkZkpkggiZMwQDIOEjCIY+kXogjKRCsmYWaHLNAyVsKRAU5SQTK2sjOmmNudGk3euzVxjF98+7CJR6v6fnsP58ZxzOOcAqyFyCnnwKwcnB6PWniVXyz2lwiXWn47ZU+z0qNgPmKX7MG5gqzeGmZrGvcn5bcbiDaG2KQLAVtlC0fowXaPYAgDgVTKF6ziBbEER4akDq5iza7AzXWOLjjdCgKAIgiIQUKNJSbkT8x95bMo1aSwFsOO1VForBHi1I2WaATH5Lw176pg7BIDf7jSWcQGEN8/rl75fEATQnnBoACAAUZ++QA1gf99QiQ4AhI3pDUF58y8WCQAsAcI5bQJoREr4WgIAtO++6AAAVj1sncnRJywAyQYtB7MERQC0SJZt2b5NBcDKuG+dX51oSM3XKLUGLse0WcCMDLq3+ZZlrWwNB0BgcyUABCv6L805ykVp4zNm1jT88scBN6SHd47Gac5/VXgPuKnueF7YbEWLUz9E22LIZ0brJ4+sio64+/yqzNbmGddnFI2FFs0ChMWltIUbXLvEn90zxq5r/boKss7RCQBkfXZBL8xmgDy1j2d3UCRPlOSRUDnMsJbR9x2vWFD3ciW97uYryvip2QRXimQ0wLMaWACwXybkUntGmji/x7thY/dvwCkJ+3W6wQ6s/o6VGz9bixOSWga8kHs7h2JXuBf51a4rge6e7ghrOE9OMrzHy17pUmVmBXNC4k3fHl4n5BafTL1JFb4/J2cY33NgdUtMyIw6PBfODoFwAgASlXyyRP0oCgiVj8T6JLepPc5b01wAQI4q49aElAIA4dEgn6SOROLv7P6o6x7Lw8YhDQ90aO30QwJUufqwP46GqyfW7I/8A/n8+b3xgJAlAAAAAElFTkSuQmCC",
    },
    {
        "name": r"IMIN",
        "sumerian_transliterations": [r"imin"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAZCAAAAADsnKr4AAABDklEQVR4nL2RQZUEIQxE/66DWMACFrDQFtoCFmIBC22BkQASGAm0hNoDPfNm9jCnfZtLAlWBpOqr9t4tRrN+gxSh9zOZGb2fFiNNkiSfkqSW1zEfK0+stZS1s8lTnUZRCipY05aaEkTlUQBXVgJqrQMIs+7KAEUKgE0dALu0A7jmACCqsi52AIYAMK12GA5AUli8RafI4Bu4c8WzAODkXPin+A+8h82AgG8GMYYcgRj6g3RIrUpteaAhqUryB25T7mq2qWaXW1PxQ82ev0S5T4OsOAvEWRnDXsYoc702pgKQVbS9jhm0RPflkU2N9z1avXj7xcvv+99OAO6XBzf6L33evXnT51P8NX4/r+LKPxemtBryjjIzAAAAAElFTkSuQmCC",
    },
    {
        "name": r"IN",
        "sumerian_transliterations": [r"en6", r"in", r"isin2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAdCAAAAAAmmduNAAACEElEQVR4nH2U25EcIQxFT7mcgFIgBRwCDgGHQArtEOQQ2BDYEJgQcAhMCNoQrj+mp7yvWT5EVbeOuOiqAIC8E5AjAVUGRZmvlq0B2B5ADgeq5ldAXkpgSwlyhAEuHY+BEupQthwOyQHGnGqPFLlc1VyulmY0FSDJbT1ClgoqWwUVRUYFGBpT0jrSJ0SLaSp1T1PJa2cVKFJMd++fQzZCB+ahBh46wHez2782PoWadjZqrGI07bcJ1pa0zgqvEGUoUoameF8yHUsab6Acke6xSe/qASTfr6Ec0YwSUY1DO0OavZVUfLpXg3w0yP8hlzq4omMjwgFbkiTFuO03W6k9JPKKurysqMtbrBwNIIVq2SoMDR9ary7EVEV1qaE2ddwchCxvamB7s7fdmzaagcu34/Ll1Bj7nMCuvQGKpuppzP3meWlCXlpgXf38qnOuluKDj7ZUE7bUMnQd5cy087BPbLclv0eGjqMAPu/d8Tfp38/9LwAXyOV6Gen6fDGrpdr16cUv1w+GLtWbNsihTD5d2J6hnN17tWpoQ4nYcEQsoIfVOG37QJjLfVqX+8wrqk8gqc372/Ce+NaOp9/Q2tNvSPn5kl+A69XL3/da7sSfX3WS/vwsE55/pPliAFd7ujwgABuSYV0yOG7D3iP5A1UAdDlw6ACaHKiVLwm6MnBEAtr5gH5NMPr/6GdX6ym6v52QfwY5mb9pZSHjAAAAAElFTkSuQmCC",
    },
    {
        "name": r"IR",
        "sumerian_transliterations": [r"er", r"ir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAcCAAAAAC4pOt2AAABJ0lEQVR4nH2SUXHkMBAFO64Q0EEQBVFwIGgh6CD4ICgQtBBkCF4IMgQLwhjCu4/N1Tmb9c6XqvqpNNMjIJrjpAYILr+gkMZz6ta1hrPbzkowe44HJren3bXyjL+FBvsK3vd5Xh9xteIBCHnTlv3ju/+PsZja9BjgGJDadKoHl6pU06tAuwfeYAnzTnT7be3j2Ll1Rn/xMYZ9BkaZbUpNkmySJBUgLhJANrdUgqVRkbyF0tx9vLsgq+Zh2moFZ1nLJivxXxdZBXBSBN90RIDXBLCYn5pMh3UHB2gEfJVUE3bYtqlEp9GnRdqSA5YDjfqqmvIC3+kwX/vHH5h/Xa4/pQ1cvfN8XvZnSt9Ze/bcngsfoPsT9vVjf5/Rd7it/QX9hLkD7D86+wt0lqbta6RwIQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"IŠ",
        "sumerian_transliterations": [r"isiš", r"iš", r"iši", r"kukkuš", r"kuš7", r"saḫar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAZCAAAAACaphhzAAABIUlEQVR4nJWRXbmDMBBED3wxEAtUQiphK4FKoBJaCakEKgEkgAQioZHASkgfWig/tw93nshyhp0hGX/LDRAUQfMfRLiBYuH8AwDq5KlTBdfVuGm8H9z7+TmWqQbGerV+rJ/ToEpjKiDrrG0XiFDMmxvbnsFoKNaL6BZ5gbyo9JjNOij3+XAiAMZdHssCYdcpj24JyH1HmL6Ux2QsK8VamYsBkHlstfNNOvVgbKmXCCDXcPOh9WEu7zyAkf6iAERBVXvVfptUPlHjKXQ4djKBJn5cGiX6Aj+9s2+CoCX6QXopbcGaoEv+O6MeuvkTSBLY3q0d0pbI75W3X0KPve6SBjcu+xUy/9O3M7fEuLSsDgDGufawHU45OgDD6vb/KUkOeAFHM3LEOq124AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA",
        "sumerian_transliterations": [r"du11", r"dug4", r"ga14", r"giri17", r"gu3", r"inim", r"ka", r"kir4", r"pi4", r"su11", r"zu2", r"zuḫ", r"šudx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABY0lEQVR4nHWRUZHjMBBEX6VCQBS0ELwQbAheCDKELIQJBAWCA2EEQYIQQZAgzH3k7tZ2sv3nrlfj7hb8aLWm2UwOlpptHFw2EYt7q0k03Vp4C2veOQwW1ofbOvPDmo17CtlbbjXxdjgFg7XN16Xl5lBdhwO2CerVxDdBV2vznlKBs/MFdwnlgzWFTqWsPdVtpQLnIACpVCGlYShAddu/PgtGE2sPdVkHULV2aKkC4LJpVr+2RxvRVR2v1Il+436nz9ePaVZfp37cAjiB517K5Tq7sixviCflAo4hDD0Hav2N0l4DI8v06XMA/xbLZs1ii9mBk6btuL0KnO7LdE2BdI/i+nepLsux5T+JqSdkcSoW7SCBMwDJDXm53YL6wkwq2ws/zzoKYtFBVsuHYM9V/+p7GvNIr7ep8KL/FOmzqNCXd9s/c5UO9K85ujeHXuQfLRy9XS4Aaq0xvplrT9HTNF5eqT+IctQLZ44MvQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×A",
        "sumerian_transliterations": [r"enmen2", r"kab2", r"na8", r"naĝ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABoklEQVR4nHWRW7UjIRRE99wVA1jgSiASaAk9EmgJHQknEoiEjgSQABKCBJBw5iM3M53H1AcftfYqqgD+adOeUld5tVR3DqaoiMZnq0vUtLewGrby5OA0pJv5tXNmscNMGVLNWGdaHc7XYKa8C99UrBaApKoao/aum9O+C1p76YaUNgemxFgMJUkx7IrapGK7kDbtAbyqB6fqIQkcjK2YNdRvthwGjRolt4H3MPAeW+EQBCDXJuTsXAWacQOHZxBMNgBEFe1lMyU5SEm7B0SgqKreSAJfnOqa2zhFazcPI38/dk/1ch6/AfhiXLhex5jPx2VOtk3jsWicQjjXHwrLtbb1PJOX5endc+bCD2UCBhfcKIHWnrBax4NKowU8y3S0JYDlg76Ks2adx3Uz4zRZ54r/RF2X6ZwD+RrFjFNtJon5FAeIJksoYpJo1BcJHO5rvC/L5RKSrczkiqPC/Zz/ZnlxRaOBkrQ4wHsAP3P/7QcFojdPivG11f2HHjodWxLGMnjXvVcdQJ3W1dT/7NvL3np49Z5vBGitvRfjlWLkya/v1B/qEwQGz/GLTAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×BAD",
        "sumerian_transliterations": [r"uš11"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABgklEQVR4nG1SQXHEMAzc6RwBUXAhuBByEFIIDgQfBBWCA8GFIEOwIcQQbAjqI5k7J9d9yTs70q4s4IWoTbIqXyhRHRhQVmYNZ6pxUBkpGHUxnxhYdXGjkZk3bTqdVeAzRVHZ6KUVYLUNL99yI4hEe5ENRo0om8aQqG0+q4SBG5kC8q58IibXUVFiT3WMVICbYwBIpTJSsrYAqDRO3QMGZW2bUBYLiGg7R7LCwAcexadal2CMTEBPn/Raj82lHKVT54XUwwbZGIj5GMih2cM9YPBryf/Ma1mMAKiU094Jy9HpBnIgWFt6/llrBYDpd92HPB3eIL27NPWlks8rYKpd1sNV96nvZVZtGlrIBBA3aeMWXLYQBuDd5EXb7CMTIEGVhxOwm5HnvbGKgctMwhr0gj0jgEQ2L+vqxBTMSGUYite3TgzWQEAWzZej2Hd/4HGf8oRe13vBG54qpK8ijL70d9Hhq3QA/XsO9E+jN5ituSt38gUAqLWGQFfdVYWe7pN/V/0BVanryOcJB0wAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×BALAG",
        "sumerian_transliterations": [r"šeg11"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABoklEQVR4nG2SUZErIRBFT23FQFtgJfAkEAmzEoiEiQQigZEwkdBIAAkzEkBC70e2dpPJuz8Up051ddPAX1brqt3SEZk9EaRaSpZfUU/Z9BnhLK71heAt6ibPZNqsW3i1SK9IVkvODqXAW3+6zb12QXX1B+2pUaeWXE/oan16tTTBSVxD5tg+WUsc7LR1lP15pAanmABK2xOleN+AXR4n4Fx5DJgtWa+rVPWgaj3GMJsg3hM2RRN8cG1z2cc1O7cGGOWzuXXckqgi4etR8sRY8l38mK6Ln2Z3v2opYcFvMkJwggP4AMe97fNtolwugAyAdh67nId308OSiOCjHzWy70AIAtDkhtyJHjihY8QSxmWXuS7gcCIwOyHfhIIHqGbdcs9VQFLXngSVHF03p5tuogmYY5jV+jSvSUCzWXLb5iHEIGvI6O9/S6aOWJNosmyHJDgBUMTXy7JEdY2J0p73+LfWkEiWBapaPXyKx9v/5HoONTD25dx4y69F+dc0MS7jXfrpqw1gfE1Z/lPoLW7r8che+gJg3/ec5egdLUY5h/nd+gYQ/f73wG7HlgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×EŠ2",
        "sumerian_transliterations": [r"ma5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABrklEQVR4nG2SW7ErIRBFV6XGABY4EjgSiISJBCJhIoFIYCRMJDQSQEKQQEvgfuRx8rj7q2vVptl0A3/aRhfpI36iMV4IpowYR3pHPaYhrwg7wlbeCG4EuZpXMl9HHx6A7gDXRUZ8oHvzbUQ77q1kRO99Kj240V9MSy/dILI5ACnjKiK9wEiwuyeSuB5YQGcJgMvNaq01Q1aYjK2YJdQfthyURk0xW2MtxiguYitMIQLk2iI5O1eBZlSNGg80uD0wjTh62UwRByKje0C4yux9iiARJk5uyUZPyep2zGg+KADqHNh6i71DVy4X1fn8e5zFtr3eB6Oac7sPYALLxZnlPK85279dqHXm2WvCBAzOVS3ntd0OGwO2rlofi98h2gKe4/7XlgAWCAWaX+boHq7irFlmvWxGT3vrXPFQscm+bni6rM35oFVTO+vJNS/nswIrX4pDLKFEI3Gk8aEIEwDZunJc1yC2MpPr2396Vj6aOJKBIqO493skPv8EejrMxaNt3Ve+tHtWl58qET3qt+meqyqghxDNfxp9yV57+GSvuW5qraVkPn2fLjTv/fLt+gcbaQWSGFFDegAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×GA",
        "sumerian_transliterations": [r"sub"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABpElEQVR4nG2SW7XjMAxF93SVgCh4IPhCcCCkEFwICQQHQgIhgWBDsCHUECwIno/eR5s75097nSUdW4If7b3F2Ho4o95fCJJ7CH19Ry2sPb4iTPdrfiPY7uNDXsn46K27dxfhHcneg+mnVmB7e6mmlpsQ425PtpegJvZgWiDuvY0/1AIxwFVMQSZf/rInr1TKrql+TqOAKXD1ASCVGkiHtQVgLApgBFEEuCwbCypGnJZjLhYzLNU836PKbSifH9djjmZvj+aIexRCDw4ID8FnFwP8Ab/exd7bvFhvzDGzO0kAQhJl0m3mAoaj1GkZpdzvAJvoM7w6x/RRDVwQj2C91eypFUjwXEnRI5XRVrgQtXos9+HDZA8G+GoGRkjANVt0Eo590FkmSx4KSgHEGvwtReB6bNU6r6muddHZVhc3nmPtiLml18X3aPA5SAx97ScFuAKQxOb7tvloCiNH/b4ThZ+1ukDoq0COPZv3m4gBLl/FPLjs0LoMlV/6dpE+SgzorL9Nn7mKAnobVyn/8ZxlHs2f2VsuAGqt6ypn39mFpsFNv13/ADai8fSznmARAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KA×GAN2tenu",
        "sumerian_transliterations": [r"bu3", r"kana6", r"puzur5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABrElEQVR4nG2S4XXrIAyFv9PTBViBjkBHICP4jYBHcEdQR3BGcEYQI8AIYQQYQf3hxE2Td3+hywcSQvCrzbpqN3m2zB4cXDERW/dA4m51WU0fKbylrezLZAmAYEmv7hGartYtAiGJbQIRvOzWkW8z8VYAV1Sk9MDVzJL1B2jppTtUtxDLVoDUQ+hl4V4o4NXEd0E36yrFpkWm1MPaQQXena+4JdUPtpwGjRpDbmuevml6GYKv8J4EINcm5BxCBZqjxrG0VtMI7A9cTayXzRUNoGo9AoRr180tumd846suuY2v1fstwsgfGaBmmvfjVvYb48zlMsb0/TlP6tvptjPOk1N/UHgutS3fE3mefzvzxexaPiiXcIQURkm09ou1kV04KB0tEZlPn74kuCfhTMvLPShm3da+FgdOuvaHX5Mw7W9kSXFR69OyiQNdzeQYgQg3aj9k6klFnIqt9iSBdwCyC2U+n5P6ykSuf+bpWEVBbHVQ1Ergj/be3/tziiUy2vlUedFBkT+rCmMer9CtrjqA8W9a3X8uepG/9vTs/akLgNbaurpn7pli5FNcXqkfnT8QbyC0p9EAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×GAR",
        "sumerian_transliterations": [r"gu7", r"šaĝar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABkklEQVR4nG2RUXEjMRBEX6VMYCjoIMgQ1hA2EBQIexAmEGQIGwizECQIKwgShLmPOM7avv4adb2Selrwq9W7WXd9ttwPDlJc1fOj1TW7HS2Cp7U8OERPtsvRmXfvPj1S6KMlq2vwp6sgej+cll66YLZGIBIIBAAOQYO5hq7Y6j0RuivqPQCYwklCRZZU/7BuadCoWbc6oVATQKhwSgqw1aZsW4wVaMJYoE0ygO8Fs6v3skqxCGbeJ8AW15xLvL0IUtyKhbXv+4StJgCGU8K0q2AKb4wrX19jzJ/nj9lCu4yfhSSpxO+uThD4irJ8ztdtC4e/yGG8t9t8QhJCjHWUz2trv1Q41/v8ho2WiHxczqEkblUS2wGC4t4991wERLv1CLDv8QcwBZY0LeZ9XlYVsOxdBfwO3ZoAULdAKiqmnv1JCicANonl43pNFioz2zER832aFPUsUMxL5EHfrd709zKVidGul8qL7hTbuZoyPsYrdMtVBzDe5yz/uehFYe/p2XvIBUBrLWd55p4pxnaZllfqH2919f6sb91WAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KA×IM",
        "sumerian_transliterations": [r"bun2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABhElEQVR4nG2RYXHkMAxG39wsAVHwQXAheCHsQXAhZCFoIXghpBAUCA6EGIINQf3R6TZJT//05o2tT4Kfmr2bddczct8RpLqqlyPqWtz2iOB5rgdC9Gyb7Mlt8+7paKFHJLNr8NNTEL3vuqnXLpjN8aTtBg3mGrpis/fb0TKFi4QVmfL6l3nJg8Y6j6XtI61wyQqwrE1ZlhhXoEkMvMSvgMXVe52lWgQz7wly18OPINWtWpj7tiVsNoFcksWjRfY8zeKTpGKbQtICYjEcLHVJqloFwqagHtKWxXySV0YkI8S4jvp4tgYMWhtPWsvyyoiNkZc03ptM9QmBvJb3ga7cB0AELjUyJhkf83XcZYrU68cSClN77lc75TSZ99s0q4AV95rEfD5t4iuABXJVMfXip1K4ALBIrO/PZ7awcqN97D/7OWtS1ItANa9x+nXtP9/N/ZpqYrTH2/rgXC+L5W01Zdx/KXzPtQ5g/LsVWf8nnSpsPZ/ZYS4AWmulyNk7W4zlmqbf1ifVgfhzktxDxwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×LI",
        "sumerian_transliterations": [r"mu7", r"tu6", r"uš7", r"zug4", r"ĝili3", r"šegx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABqUlEQVR4nG2SUZHjMBAF+1IhMBR0ELQQZAgOBBtCAmEMwYZgQ5AgSBAiCB4I2p/bO9u59/e6uqZGpYF/Wdse4970ilo7ECQ31Taf0a5zi0eEa8OaTwTfhviWI+nfbW/hbKFnJGtT1y6jwLf90J573oUYV3/RDou62NTtSlzb3p+tqHAXV5DnUH6zpsGolNVSPT6p4u+DAqRSlZS8L4AFM2fmCohU6YPdpoUJEyfByjIWj3+URNmMyjRRu7Lw+IVEn8RGDcaYoskjqJiJSZUEobjiuxu2sG1m/fQ19tHVzraxpGljdE4gJY8AaJOgqlnAvRVgRkTQDCixNe7IgOB9sTwttQJ4GcyTeheheD/13IlmQwo2VnnmBVz1M1oEX2wxVCqVW/ZOnr1tq9irc95nX61CBQGU0YD7tlQfBkt1rpO9fA1xGefRfCrDyxiP/6UtOoasErXN7RL13AFI4vO4LEN0hZ5UTvfETw2Ktlkgx5YvRxEVbj/l1YUcsLp0hY/8tUhfJSo22qf0Z69igD36Wf4z6CPuvQ9XdtoLgFrrPMvVu1pY6sLz0/oG51ENhfk0G8kAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×ME",
        "sumerian_transliterations": [r"eme"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABhElEQVR4nG2RUZXjMAxF75lTAqLgheBCSCFkIaQQOhBcCAmEBIIMwYYQQ7AhaD/amXEy+/78zpX8JMGPVquq1cLZMuscJFkINh+tGmbT3sLZtKaDg7dJd+mdcbdqw5EiHC1ZLTg7tQJvtXs9aqqC6upPWBfUqQVXA7paHY+UBriIy8hjyn9Y49Qo5LXF0o+U4TIFgJhLIEbvM1DEO0fL77wAzBasplWSelC1OgBS06P7ESSZJnVr3fcBXfVVG/Y+1wdtYdtaG5/X+6iu3BoA0c3dLi/g2Lw8nuMSo+tuMQ5LhlJelEwI3ueWnkvphivOC8Q3pa1N0XMv8kgLuG/w2pUks2pznZOAhKr1tfshfcXSAB/b/faME3Gbg7TPXCQFAWiNs4KpY0pBNNhsJwW4vOYWn+7LMqnLjMQMMmxfs373GgLBZoGkljyAuONW3/q8DWmgleWWAVp/8B+KeM0aaPffqb9y5Qa0v+Ms+T/MWW6v09k75AKglDLPcubOFC3ehsdv6h8tgO1zdkdTqwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×MI",
        "sumerian_transliterations": [r"kana5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABpElEQVR4nG2SXZEkIRCEv7toA2WBk8BJYCX0SmAk9EhgJICEHgkgASQ0EkBC7cP+3EzP5ROV8UVFVpDwT7uOnIeGs6X64CBVQ9D4bI0QNT9aGPV7fXKw6vMhj8566FD3TBGeLdk1GD2tAqvjYdpGHULOuz1hD0FN1mBGIO86/DOVAyxiGrL59oe9+EmnxVDmfDipweIDQGk9UIq1DWCdNEAsBQRYbna9bVOMuNkaxmLet2acFBChgbE+gVTNNZt9HIcj79lUtccK4PefXMwU72Lnek123cy97MW2Fi0gLjcw+LSA4W5lu62pFJPX9YJFSgEcrYBriQXxCNa2WW+pdxHTgc8be+qfz4U4py9uXrpsNVHK1g1znYCY494xhitVdWgcsQpIGHnYqDZvAC6br/S/ttmtc/Pd2n6b5O65Gem+34EtlUloqX19vGaDr0Fy0KgnRcsCQBFbLyn5bBorpT31aX6PLhA0CtSs9VSKHOD393B9c9Uxe3prvOiHovwtOTAv8xX6ytUmMC8lyn8Wvcgc5w6ecgHQe49RztyZYpY3t71SH7H6BqwV87y0AAAAAElFTkSuQmCC",
    },
    {
        "name": r"KA×NE",
        "sumerian_transliterations": [r"urgu2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABm0lEQVR4nG2SYXHkMAxGXzsloIOQQvBB8ELIQfBCyEJQIWQhuBAUCDaEGIINQfene82mp39680b+NDJ8V/Zu1l3PyP1AkOKqvj6jrqvbETF5yuWJEDzZLkcy7949PlvoM5LsOvlpFATvh27ppQtmOZy0Q9DJXKeuWPY+P1um8CZTRZZU38lbGjRqHls7rlThLSnAVpuybSFUoMn3q4/kq6v3kqVYADN/5JgJwNJd4QWxsMm4ahxcNxsyglSA8G71o7HL/QaQPC1ZfJG42q7YKsDc+2ylmHVTeAFdfoUI8TKY7PM2NSDYnTg+72DUG69IQggpjJJoDQSYS5M2xmHTsu8avU+IlmQ65TzFvs5l97w/XqS4d1/7WgREu/W871b21BfbcwAzhZdltBDjuE6hfQysJeplSIoEtj985fo6vNtEKiqmvvqpFN4A2CSU6/2ebKrMbPV4x++zRkV9FSjm5fQpTOH10dwusURGu18qP+qfxfa7mjKu46f0lasOYPyZV/nPoB817T2d2VMuAFpr6ypn72wxtktcflp/AdSwDII9X5VXAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KA×NUN",
        "sumerian_transliterations": [r"nundum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABnElEQVR4nG2SUZHjMBBEX6VCYCjoICgQHAheCDKEBIICwYFgQ5AgSBAiCBoIcx+5JI5v+0+vukbdI8FHi/WUusU9MtsQpFiMNn+jHmdLW4SzsJQvgreQHrIl48O6Dd8u4jeSxaKz3Sjw1jenSy9dSGnxO9smqEsWXY+kxfr47UoRjuIqcgn1D0sOSqMumtu2UoVjiAC5tkjO3legyfNW8UB9FpwtWi+LlOQhJeufSvPjUSRFOHL1lyx6nZ0uU0bzj7KAijS9Fn4U4IDeWVfV8XaaxuTaWeE+indtvOn6L+EBHGttl9tIniYAT+aW8ypK1ufVRyQgeF+13O6tAUEao0MZeO3uQNIW8EznkysBHPps5RgG9+pRzLrNfS4CEnvqPgg2xDgYDPG51cM6nW85kNc5il5rk/IesFe05AglSoo2204RjgBk8WW630NylZFcRZ2qa4irfJ51iESbBUqysvkU71wvcD0PZUDb/Vw/rnx9beJNTjVFdNJfcj9zVQX0Z5yl/uLZyz162LOvXAC01uZZ9r69C83n4fK/6y88SfuhDbaFhwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KA×SA",
        "sumerian_transliterations": [r"sun4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABnUlEQVR4nIWSUZGsMBBFT21hIBayErISMhIYCVkJICFIAAmMhERCImEigZbQ+8HOG2A/Xn+eOtW5lwbes+qW0qbxilQPBFM0Rp3PaIuzrkeE1bCWE8FpSMUcSf/UTf3ZIp6RWTVavawCd0LDVjZDSqu7aJreiZJGu0XSqlt/tlKEztiKGUL9ZM1BaNRVcjtWqtCFCJBri+TsXAWadQfNAN1kwzSIFeOlVqzDTc2GetgFfDDWIbc2ztauHiR/PgZnfLh2DRqG1ehg/JyeEUi6bfqeCB1YHs4MU7/kbPfWY2zN5uX3swIdJmBwrkqZlranrojLvc3gXrmStIDn+/ZlS9ghTOKqs1BrFaArDhmMPNabjGZwlHsGpJlsawXwQPdYmvNBcpvbJKNrPk0GkJyX/Xn5VzNqsoQSTYo662X2jkA2rnwvS0i20iOPsPjWfpe8z+ojUWcDJWmxyatP8fVXpQgfL3G8+eKRNt2aSBORd57XiwD5a04TMsKdT+6n8+xWFUDu/Wwq/x/73P6c+ZQLgNbaPJurd7WQfPPDX+sHwBgFrDZxO3gAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×SAR",
        "sumerian_transliterations": [r"ma8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABkklEQVR4nG2SUa3jMBBFj6oQMAUvBBeCCyELwYXQQnAgJBASCGMINoQagg1h3kerfUm69y9HR6M748BvVm0iTeMZqe4IJmuMOh9Ri7PKHmE1rPlAcBrkZfZkfGlTf7SIR2RWjVZPo8Bp2309Wm4GkdWdtF1RKxpti8iqbTxaEmEwtmAeofxhTaFTKWtPdb9SgSFEgFRqJCXnCmCc76Z4EmAcwDDZMD267cb3UrAWV6Ha5Sm2ALjy3i2rZLFre708sopzEnKU8PpcQiJc6Avb1vs4Xe+j2HorJZWymG3bdRvAsjnzmMYlJStgZzeypr7f84IJGFxwPQdqhbrVRDk8Chek14DnfrvaHMCypFoWezxuVm06tzkbMLFJc2tbm8wt7toP21KdDz3VuU796aqXairFpfE9bdcvqlhCjkaiznpKhAGAZFy+L0sQWxhJZV/p91l9JOpsIIvm00/xvuonz5vPnl6nW+Er/yzStUikP/u39OlVOtD/jrP5z6Cv2FcLZ3boBUCtdZ7N2Ttb9HTzj2/rB2qf+kbCYTf0AAAAAElFTkSuQmCC",
    },
    {
        "name": r"KA×ŠE",
        "sumerian_transliterations": [r"tukur2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABsklEQVR4nG2SUZnjMAyE5/ZbAqKgheCF4EJIITgQshBUCA6EFIIMwYYQQ7Ag6F7aXpO9efP/jWVZI+CfNh+qw+WM3N8IqLqI5yMakl3fEdjTVg8EwZPu9E6m3YfHowtyRLS5sJ9KAcHH22kZdRBUNz7Z3hpldeEh0M1HBJCeXoEK8EncQEtqX9hKMnQ07a2nNZZY2GwCNwCLu7urQGpKeYir1+HVd999H151CABkFx91o6oBUPUR0y5j37ehQ5WgAnzgpy2l209m3iJg5ausJa5U+I47QgAAfMBW3O9m0+17npT7xYC54cKXcOX5/pqVOEURqQTw/gixckQgJujjRUoghBSsJvT+uGnWYSB6ZPMBtZ4QMV++uSaAASB33ihTNmmP2u7D88iVAJKhI4DyWEauW826R6gAfxbrIUabOfSbQXvCracyNTbuZLiatp/XB5SRqpCKZz9JgE8AQKFQ53VNyg0TSkNaY4mNzNI6vcKOAvFMQFWvAcASDmm/XIj7HqE5HxYTeMzrqfLdVGCznfcQz76aAbDrlKn9x3MW7yOd2fFFAOi9/24MZxesXOLy2/UXoQcl3mcxCJsAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×ŠID",
        "sumerian_transliterations": [r"sigx", r"šeg10"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABnUlEQVR4nIWRUZXjMAxF7+4pAS0ELwQPhAyEDIQUQgLBheBASCHIEGIIMQQbguYjbSfNfqz+fH2P/STBTy1WVauFMzI7EGS1ECy+oxqi6RHhbFjWN4K3QTc5kn6zat27RXhHslhwdnoKvNXDaaxrFVQXf9IOQZ1acDWgi9X+3dIAF3EZGYf8lyUNjUJeWirHljJchgCQcgmk5H0Girx+7YprAEQLVrdFVvWgarU7jHXcggb4hahP0q6ha1yTNvlqlfxq3P9Z8gQw2DAuYqN0UbcAVOltfGbf04Pj7mW89XNKTgGKNrrHKPeEF2RA8D639TaXAuC+kn6+3totbW1IXbsWGdcZXCHH4p8LfnS7mlWLNa4CEqpWz+ZQGDf5yXWfi++Glkostzb50ukta/EKpZ12FUwdwxpEg0U71d4jkMSv13ke1GV60j6u/g70956nRfsIyzzN8+op17zvf7+Z/I8FU4rrNbUyT3scabcG3B+TeFb6iHqjTY9j/jjk3q3cgPbVR8n8v9xWhzPTAL/fSCklRjl7Z4uWPrvxX+sb1xP/OC1ylk4AAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×ŠU",
        "sumerian_transliterations": [r"šudu3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABpklEQVR4nG2SW7HkIBRFV03FABYYCYwEWkKuBFoCLYFIIBISCQcJICFIAAnMR+f2pPvO/qJWbTbnAfzTNppIG+ETjXEhqDxCGPEdtRCHXBF6uJjfCGY4OdSVzMdow14ueWt9eEOobQQ93qLyMYIZ7UJ8y00hshnA6GfYkWFE+HWGS1i/8NBncWCyt9Za3VdIHSalC8q78pstuU6lxJA65zhMQBeYXABIpQbSbkwBqtKqFwBtOs8G4wij5U1lMSAymgU7moiIHBYknLOULHprR7PIJgrwx/PBcLom+hp3Zfr8WIzzen8AFH1UAJ2e7gk0u1F+mddy1+cudL0n4LsHJpRDYUzpeVlrBTC169kCmFeW9O6S4V6VzyvoymxTrwXge4FTNnSv2LdbfyhvyLdSjOvWAuj9dO1rNdb1VGNd+sNUmxfssnSudZ0dD9G4HJSEEceHAkwAJGXyfV2d6MJMKteE+XWygTCigiwjm7dnkPD6E/C42Wzpdb0VfujlIv0pEuj3/tN01lU60L/mqP4T9EP6aO6TvdUFQK01RvXp+3TR0836n66/tv/+BIKIWWsAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA×UD",
        "sumerian_transliterations": [r"enmen", r"si19"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABqUlEQVR4nG2SXbXjIBSFv7mrBo4FRgKVkErISKASUglEQiohlXCQABKCBJBw5iHNnbZ39hPrWxvY5wf+abWm2ix+IrMXgmSL0ZZ31OJi+opwFtb8RvAWdJNXMm7WbHh3Ed+RrBadvT0l0eGtvZCp5Saorv47ubYm8BLUqUXXIrpaG48AbY2ARjiJK8gUym/WFDqVsvZUAehjiuAKnEIESKVGUvK+ANWNQC+1e2AvcLFoLa+S1YOqtQFpm0VAtuePINk0q1vbtg3oqgKEtg8g+931Rb/zePQ+zufrqK5eOvDoN4CQnq06gePhZZrHe0rumEXaGx+qJIAvJCD44HsO1PpsQhgB5lqHuru014Dnejm7HMABMpVlBKrr5/1eNmu2tCULSGzaPLgYo+qANNnT/5p69cPQr87XuaM1MM8dwE2uyBW03I7BmzpCjqLRFvtQhNNekvh8vd+DusJIKscGzMAxVhgi0RaBrJa/l0IyHF196nYZ8kCv98vxEv18nL5dpHPRSL92fmrPVTrQ/4yLlP94PuW2Fj7ZWy4Aaq3LIp++Txc9XYbpp+svuYgFjrX669YAAAAASUVORK5CYII=",
    },
    {
        "name": r"KA2",
        "sumerian_transliterations": [r"kan4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAcCAAAAADDgCm6AAABeElEQVR4nI2TUZXkIBBFb+8ZA1hgJLASaAkZCUQCkQASEgkdCUQCkRAkpCQwH0n2dCYz0/v+gFuvqCqAq/oGvXyzf5JblcrhtPV2hfpIMneAZKYyad0UAPRD/YPCuvgl5y2gbnLb0ZrtDpk1pLy4tPvWoEMN3OpYtGG2stmitRStZN6D1P0xfXBzffTRipF5x7BqxI/7yineCxCWpGqv/LpnR68Gn4+u1ATcMHkserDKij7SFMFOxwXaAW5Qoy/owUKZL31R7r7x1fol+bA6dZT8JFvt0dXoraiIJ7jxi52Bg2JGGuwwze48mUPHhFpdSreYoRnOZiY8UwyPqeFDWT9E+dELQfUkxtL4nzMCnSuuM1ZF8IPoJgKoo+xqSQlbra6ZpVeovCqz5qdO/HnyLUzEVkzWU5PK9H3GrQhIZcSdoJPXrndx/J39C0ruY0MbnfqVgk4C3eRfUNIWaJ+GcP1DAPMMMr7wuuj/qDdAEKEUYb6+VSkCfAI6WriZwxPJtwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KAB",
        "sumerian_transliterations": [r"gab2", r"gabu2", r"kab"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABY0lEQVR4nI2SYZWrMBSEv92DgViIBVZCVgIroZVAJVwkFAkgIUgIEhIJiYT7fgCnpbB9Oz/COclwJzMZNBh+h82qIasKQbN7Q6xzlEE9H+KKm8a07c/lhdgMX2K/ChIRfaA9TIxRHSBh0Ng650Rj1stRudUIEDSIigGGmIczKyoAGozbRPOpdRWg6rriGMcCSHo1AcAEUN2AcksAJZ3RFlRAMqEHsPN7nsG4Arx7mAqw5XsG8Cfnxl8B+ASKaX4dJfXDm+Q1l2MlLip4WXUxU18Aqf11b6WVJZWFV6efAlCoQ/dchOYy10+82YURwKZk9z3ops1bBVDskoux9OOzbLu7sA/18tVc723cVd3i4xModv1t/n55kWvPVvZ4QVSz995neY0FfDZrLncMay5HGj/rnRhUtzn+jLhuV2m+tW0zFcCeTlxqVAFg7GM9YDF5z+qbP+g6c+tOj/eo7LX/H6cA/wBULcH/mSUhMgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KAD3",
        "sumerian_transliterations": [r"sedx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAdCAAAAACcOlPtAAABbUlEQVR4nG2SUZErIRRET6ZiAAtEAiuBSBgLsxKIBCKBkTCRQCQwEkACI6H3I/uS7OTdP+pUd/Xty4HHuEJbm3NmWzfj2Wbwjn8zSTl3SSUXSV1d9VcXIcrbnp0SuUcFSv9VZgGlpG4IigosPWh6WgKjFMF0VXB6mvYuA3Q5ICkCRQGAqOI1AqkDeHkgysLgauDWNg9s6zM7dxoMtq3EymT5nOF2/jqcrhD/BxWhXU7XMX3C4xrMZWO7tMT2QaNUp8eyNb/SegFHOKcUWtu4bftQR7hfFmsB1r3vAHlp1/PpcDjcPwJ5/Pf8ek8zwLgCuMFtX28sRgC3WMCX4Xp+K82Fb8Ck2x1Muv7ZqvYKXlUOrywzvFNrZgC7roCf38MHpe7xtcQFX0t5bzspIu+0mCWOSuSJl+28egNtHkdoq3P86cukrgmmXjIm9bo74qQEuC4Dk8qur9Qt4BSBIL+jZQEI3QLLXuoevzWPgO0/08jSONnx08IAAAAASUVORK5CYII=",
    },
    {
        "name": r"KAD4",
        "sumerian_transliterations": [r"kad4", r"kam3", r"peš5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAZCAAAAACAmvj9AAABc0lEQVR4nIVTXdHDIBDc6cQAFrBAJVAJWMgngUoACVQCkUAkgASQABLue0hDSDqd3tOyt9wfBzAYVwDAtQBTAr/MBADglYhI/RKzWhkAiMqj/iGVLDpvthw5/ggsKlEmmgFAkPmm6oB0CJE8A3BS8wFXx97IBGIwlMVJzQwdPUyp1NQ2XiwNz9VF+zyCKcPt61BzZdc3DgXAene6V8edTI/1uAuKai9lzz/XNzJUL5MMkrrt1QoiA8hMvafeZeyvdvRGmaKnKC9aTA34IIGFK7E+PuipLL6UD1pjgfJ/7cpT7NPfK+GesgQ05WvWqTRzCa01sKyAXV0YRw/gVtK5bxlNum8wPawO/OQlvyNGTipHWQ3TUbWOiz4lhLQfZgHxeo6tLcl5aztza22oZE2vPz2PqcvD6nD8Ojqc5KgyGDLstLEi9/ef7ungWyoNqYiK0ydu3KgGAG0axIDd7gh2epa2b+FpepIBgCHPr8v03YL77vsHlUrG5X/Ez98AAAAASUVORK5CYII=",
    },
    {
        "name": r"KAD5",
        "sumerian_transliterations": [r"kad5", r"peš6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAbCAAAAAAfAlOuAAACDUlEQVR4nIWU3XXjIBCFv5PjBmiBLYGUgEsgJeAScAmTEuQSUAmoBFQClIBKmH2wZDub5Ox9gtHc+bkzCP4LG8vL7fT6KfoPwOd5w8+fd5vzqW+/xSoVgGlIreYeXVprsRkgxm/+cTQPQJVhAUi11VCjiJUw/FdvV0SnPXDUDOBzrjVlW80Yqnsjbwehb6l754oDZjqQkrEzq7FrM4Zt2R2zOyg1tBDHSIAK4KfqmqtxqIpK2Ss62TyvdxWW3GfmLO6y35fs5rBNzIt7r5s5lEmj7FABEG3+fsK0qKqhmeonnXaCloPK7uaaHoSqo4iI+GrykAhw6ls52tmxvkv0tkNKZjvLMp3L7bZ9TOkC8LZ9H+N2wdXgiqx/LukzXdOZ7qd4vd3ryA/HvRBAp6o6AlD85C1Bm7RdpaXXH1bFWugduMoZmP9kPx+y0pd+Pz9mb/HL1eR6/WQ9A9A3v6XV2tDR+pjcoY2oToDJmh8KRr0jUsLQAwIQmk47NY3nxiUVKyrQanzNYItW/2jf1acQeTitwDiWBKOtVH3uEgCi1e6NqaoBStAnkgznzCuBMEbYU2gFaDUcnWlrzZOreSVgik4GIKgAp/XyHMMc+8Ia2g3z8rw+t+ivG1g6X6EyCfhX3f6B+/rXWPoMODvN2/rD9J1c1+9WyMP9ZAavnpc3/cxz/jHOgdM3y+135w34C+9xaPn741ckAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KAK",
        "sumerian_transliterations": [r"da3", r"du3", r"gag", r"ru2", r"ḫenbur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAbCAAAAAClodvOAAAA6ElEQVR4nH2QUZHEIBBEu7bOABZiAQtjAQs5CawETgInISeBSCASiISx0PeR7GYDJHwBbx7VNACZcLMCwxV6AMA43NAVN2+XSZjNhRuGVRZbxi4flKSmTE7twMObGfNzMT/fiBpd7VpMJGmBwWe2A0al+H3WF2qwJzxqOQ42FJbw0YCp2rJRmf17IEud1kVlGrd9aihgMvnVXgOAceKw/Pbohp5/K9qXXeQ7UuU6cWY9LAyH66KynKtgCQZJ9hLOLQGBpGpurFci9VGZ6vJfQSgjY58B0ER2utp/tMiy9iEApCtzczFf0X9XN3wfZj9RXQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KAL",
        "sumerian_transliterations": [r"alad2", r"esi", r"kal", r"kalag", r"lamma", r"rib", r"sun7", r"zi8", r"ĝuruš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAYCAAAAABVDxvrAAABAklEQVR4nH2SUZXDIBBF7/ZgAAtYyErAQiKBlZCVQCQECa0EIgEkpBKChNkPaE+2p5SvYeYy894Zvugfa8EtywcChiNdUw297kJ7Gmsk+9CDZjE1iHLYlhslxeN6UiSt4iVJci1OPp1HP5hR8NI7HlDxrolQbqXKHMJZUJXsZBfZ58cAH/+J9hFQYXBsU3nvS2sNKIILPz3vxuF1UWRuPYS8GOykunUAlp0pK8D0mZLLxgVYXR8yd7gArGt3rWYDBRCcC9tW/Wv7DhWx5uguQ7c+w6rzLQMwDr/n93YurY+k5w963UWiaQ7f+ZG8v2ylXa9zzxTEFVAw9ZHa5/IJgKEAf1VQku1/QaheAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KAL×BAD",
        "sumerian_transliterations": [r"alad"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAYCAAAAABVDxvrAAABKUlEQVR4nH2SUZHDMAxE33VCwAfBFFwILoQchBRCCsGB4EBoITgQHAgJhBiC+mH36txcqi/Js1qttP7iOKyFbhg+IMBs0S85deoQtMQuZ7KYI1AvpT/I1pa3VmLY7hWR2DJLorw4fXSxHi3tqxknR+GAJqyaAOmRMrsZa0GZppNFZOlfA1zYL5ZLLxLeElywb0i3xVi0+6rThc3nDu1CbEXc3TXMPHY3mc0yA2DXcxo09tLwN5QZJgClDAwLP3MD7L3Q50yjp+SuaV4nToDvasx3hrDeLnh0ghOg/IGt1xT1BA3A2HfjNOcjqmp3JordIlZvh2aowmO8mh9ZRmtu9TTbp8Ij8fcH7b3ARbJmxrIusKa97FL6/t+lAAgeaOB6DMk8p08AMAl4AroAruU/f0P4AAAAAElFTkSuQmCC",
    },
    {
        "name": r"KASKAL",
        "sumerian_transliterations": [r"eš8", r"ir7", r"kaskal", r"raš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACK0lEQVR4nHWSW0jTYRjGf9t0bYasjDyFscxZInoxRedMqJCkAx2uvMhMKlfpxTpQoBYhRdhJiMquqoUQKSYJ0cFZUWkFgtBh1uaRlefNLRc0Tfq6+HvYIp+rh+f3vfB87/fBrOSliSykzd4SRXAinzVhpZp05f9ZVEWSb9arNuoCTqizG6YOXWtbAkDokbH8ALbVLUbP1fw0AmjKuys18yi2vqmqttMvGmUQfnXMFDAVYvbsgJQDjcKM6vpIUWCfzD5/AUDMmfGK2/YglNIx2Vsila6e9mTLZuJNu+UhB+9NFnYnARCX7glNFxLadSuJJr8YvfioXQcYba2Gk75jAOwctsSSayqrt/+eNkNWt3UF6nKfGdjrskQCCmV4bFGPe/0257NoIOz0RClHPWeXzm1uea3HXx8l7ahy8MVQmWq+q2K/61fujNc+FpcXzU2posq8lpZvGQCEXxh2fswGYO2a1D1XnMKiWWx9pQWWVXkLYp5+yQLoF8LVNdGfA2m2N1pW3hkwgdbaaQCMzeM3Da/vqoG0zy8zG/ryAFY97zTKQXm+t66nEIDk7yPDOVKH+OZLSiCkRjikJPXroCN+pmBcghxAP/RBByQUf7Juf9+WPHcxGaA6nn/fpU7U6705jowbUyZb4CtFVP/x2d++E6eAzPbW5EBG5Ikf7g0WRxyAoeNhdBAM3dL1YKBOWuK6ln1BDFnxkDgs/WtZdEQwQ/lE5LKQ8myr/0n+Ao7Du1jWQZr1AAAAAElFTkSuQmCC",
    },
    {
        "name": r"KASKAL.LAGAB×U/LAGAB×U",
        "sumerian_transliterations": [r"šubtum6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAeCAAAAACOSIixAAADE0lEQVR4nG2Ta0jTaxzHP/+5tZVOt9llo3WxCNK8VARdoCyo6OpZecCKY0HR0YrqRXZ5Y4UZKUG1LHPmhchCT0lFBcduaHEsjKIyL8Nj2Y2yck3ndP7d9u/F36kv9rz6/b7Ph9+F5/tA0KO5cG28AIC5/WODWwhOsTX3dXU9ACnLxGJlQB7j8gynnD9iQ+NEgJ5voacDaoJtynBIV/Jhk3EgPpinUciRasvW0cOpqJS6ym+g2mcA13uvTKn2rBHV8tib1QCtNf+JQMZED0gKQQEQVZF94vYSAJM10Q/Q190nEZ66s7IHAAWgKYh+t21+0mgwlYbt6gcQBAEs6TVdDFLJBsvavEfmw8q40vb0YZs+vJ9okCMlTMiIaet7d21hUcT4t0dcsiwBfDlpXF7rkWvFlDs6zeCvydvcndEJoLfGan0A7kMNKrnj7mpjVutaYGV65aQNALqCSd5/5/UBOMtc4AelvjbqSsSofHH12ZOFSTn9FUy3/kwTJOPSZofcWTL1+JRZkJD6R1ZdtrWAm+qjYsvZtr2uiFeRC6aKAIQIepvclkUdH9MFgOSWF/k6MH0STw0sqj74z3WbEkCb6OjVSABtushzTvAcn5Xys6pdALSL54X/z9QZyw487lqzon4vkNS0b2O9BWB9g+uT3W632xs/936eqyyM73w2q/gOwjlPoeXYRatPfcJTJTF28t0rTeBX4E+b0cjk8hd/t8QAK+z5L1MB0hpmM625ehyAHkjbr4LQEufzkQDF0iV54L/iiWo8PQKYczkSdmSoFLhzu371wrTMhMOx2wAoe8OXN80ixJx/4gi8oz0nebdmZnT86qr3md6BcoqQEIQ/13U8lwIURVOsHWVxN+5x1ZTZVDfkiXZ9mDDkHPHIpu9qp03Cf+aSzTzoCenxoYi4QeeAu7zj1oc2oD/76VdZ9wG83m+55RykoLYiuhtAegBAmMUgAlQ5emVPyJT7/Gz30ECE55pqDH4BmkaO8moh+N/WFS0IafXJd94JJTnKoJSk9Zc8CySrvEJwSm/eft8bSIw64TdAkyPXXDMS/AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KEŠ2",
        "sumerian_transliterations": [r"gir11", r"keše2", r"kirid", r"ḫir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAAByElEQVR4nIWTbbnjIBSE3/aJASywElgJVEIqgZWQSqASEgmNBJAAEoqEIOHsj3yUdu/de37BmclhMgzwUS6pz9Z3ZSS5n8kmPLwP0i8iIqOB3rZw16xz6WcLrk6ATcC1pZ7bza1WNHoGiFzibW7R05sEN0Yb57LKGeqvrW1zRakz+HD8RiGXustRetyWfklpcR3EIUzzQdDKlu276vQ8V+ASoi43AOnlKCd+PyOE4F6A4gQmlJpXVLmrU+ZwRFE2oC8XsGZYnilIkFHSIk4eOzPIIg8Jy+OZnhLglAxQalboaIy6WnNMjTenilG1KkW9gEo2jMOoRQnByyB+Z4pHLySbrB9DgK7eH1ysKqwelGjCy+eSqVRWrGN+TM0lVJ13494CAHRwmA5glDZ8XWco7T7X+l0Eu8+GjtPm5aD+pdq2V1TYqDj+fFDvITVh0+X3pkiKM7xPNsuaexERsSkc6zYDCTpQ1ce4ZdRjpj3CYoufN8BX6MCqa2y06tcVqMsuu65a45xfTHTeBmHjrQXo4Bjp70DF6G2fX8yJd197O0HR+yFDA80f1Gg8Vk9qv3zjc/tk2xc7VmNzGwjyja/r+XpXP9XS/xf+C86WDE9NuWduAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KI",
        "sumerian_transliterations": [r"ge5", r"gi5", r"ke", r"ki", r"qi2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACRUlEQVR4nH2Sa0hTYRzGn3POtrbp2WwysyGyXNJFtmCzkFGx/GCIYRDRBcEygtLWMFjuQ7ESMZVGZEIQhi6QFmZfioRhpIwgGIpD18VBs/CCFY4tt1DP6vRhtzO29Xx6eX4P7//yvkBKoutGAoDIpkJ25Q3P7wFgXD+VIyD1MANiqD+zjRyT5Jxl0pcGy/GhuR+HOC6PEzgmm6StiHbTGlEkaRIpTo/r/MwKQdNKXs1Ylg6EXeGR3n2yYnVj/1dXSSYX3Ak27XptLAGAKvdwMpHogXer2Ty4XXju7EIU7Pq2/aRpOS1AWlssj0HwZe+nwwDeCdoeGFc49xPWQDMF7PXWFsadGv8zOSdgCV7lA9jpPpm0qn1PChMlJOYrHY8YACGftckdIQGA/fulIXIzEAscbOvv2wQAokD1fX6VAgBEl+iL488BAKVv2Ruxa5Uuk5Ai49o6xLrLAJLafa/cpxLGEtFgqq+i8lGRQ8PjtdpCph31Cj8ArAXslx0Lsck31IoXRdcmTYRHnE+IJRfsLAB5jz5v9mesSbJKtbkaXnYC0NQ/XZyqBADFmL04UaF20WMuTdY76nWpAShH6rbEN3ve0xfbWfy5NYNrLR9RcNfwyv2LBPu7ouNhfLLEf9AOBC/NSdsbNpxzFPvnTIXtdhTp0s1MlMneOAwUgNNLnQJkSDszUX1EDoDfGuoSZnJA652uBEB1Mt3ibBzQffDqgXa2Jz87Bw58mjrRy9joXBzQewPMfUluDuLwt1nNfzhA1Dn16c4/Zmq1e15dURQAAAAASUVORK5CYII=",
    },
    {
        "name": r"KI×U",
        "sumerian_transliterations": [r"ḫabrud"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACWUlEQVR4nGNgQADO0hxGBgYGzh5lBuyAe9V9TQYGhpwfYTgU8F/4PY+LQffG/zgkQSYkthD/Jody/yU3X9kiibIgKfAROsNbx/Cng1eP8ytckBEhz7vf+N7vF4y8vAosbruxuICj/cuaifpCErpxsx8cksGUZ2t7H6e6NUeGgYGBweLUKrgKmBtY6jNL18qzx0c+/sPw/4e4KVPeMxQFTHVZZfN7lrMIHT//hYGB4Qhb2aScF0jmM9a9y2Tom6Z7xVMYKuJ2b4UokoLyD7kMKZ/1lU6FwIWcbi0UhlnBV5LdPDmp7tJl4Vt1iae+MjEwMDD8/3c3+mvNO4gCm7KZk/o0l/37xyig/PL+W2YGBgYGhj9PeVP2r2ZgYGBgkNv3v27iTqmSFgaFQ3kczExQILjk/yklBgYmZo0+1VsSh+RcOBgYGP58QLhLTHUb53I9FpaCno95in5trtN/PGT4/G5BxvLHEJ//1JVaK1Z4Jo/xAhcPIxdf0nyGjQbqPF1W3JdfQxzJZKH86+2XZzsZGBj0/JY9OWvCIHW4QGL3AgmYDZ5PLpTIwe1zv3JIl0H7jPFqb3ZoyCZcmAwJM2h0683/nHXN50Gu05aTn5gY/n/Tbp5WzYCsgMFo3of0mzyt4d/33WT+/zdCu6fhD1p0G186oCyya44VCwMDQ/jTVjYGDGB0aa+BIz8DAwND8vt2Dkx5Bgajy3skGBgYGBLed3Bhk2dgMLmyW56BIeZdFw92eQYGs+vbxQLf9vLhkmdgsL5y89FEftzyDAx2Dy/r4ZNnYPTeaYUqAgA0AcObO4fKsAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KID",
        "sumerian_transliterations": [r"ge2", r"gi2", r"ke4", r"kid", r"lil2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAZCAAAAACaphhzAAABLklEQVR4nI2SQXHDQAxFXzwmsBSWgihsIDgQHAgxBAWCDaGG4IUQQfBCiCCoh8yklzrtP7/Rf9LoxO+RB5hT8O6AsAmcBJcDAJhDmWOE2yGyP4eYgZiPiDGekaGvsq9HTFob9M3zcZEBnYyYVxoNaIADOJfT6YwBvVyXtJtPj+t8nhediot5dn6q9xk0BjQUiS/SvsMeCShRgL4OZXG8GBTwglMwF0AAOClpPDQ9V+jT4HfXM2yTsS0raiuDTIAoQF/s4oUKWAWvuFeK1/ecrkk+LAGgN7bWUGAoIEpGkaxAehGYDwkBxCFDypCTvAm20FwCiAKhsCnoxvsenSxT++jR3UdNf5ia7I0NUIdBkCzktL09ukTzz+tq3Pho2nNdsAmoDVYDs9ef/CclBPgGOvSXsv/n6oQAAAAASUVORK5CYII=",
    },
    {
        "name": r"KIN",
        "sumerian_transliterations": [r"gur10", r"kin", r"kiĝ2", r"saga11"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC8AAAAdCAAAAAAf/mrWAAABvElEQVR4nJWU0ZXiMAxFL3towFuCWxAlhBJCCaGETAmmhFBCXIJdAiohLiEuwfPhhDME2GX0kxP5RnrPVgxLTHPHB7EDO3hvuo6MpiVr0zW39usNfzMACePzkm0E8Kc3PdoyzGGaO+h6sV0Hdg632dZF+/zBeCttYwBXSikO6FY7royvGoxlNABhHOr6PAMgpTQP6B7Ak6JMPkPquDqAnADMgI8P/B8ANJr6mlOqnpMCDJLPj1L2FUP8edmcuosOwLWs2cf6kNNmAXA96je5/fKMfeMVMFR/JjN02TwV2QEQLo21EgFLPWPr6fMxmL/PbYHQ3GZnAJxbtLgmlGkq26Fa9Zvz16ZSPB6T5R2fBme2XePxkMS99qu0fdUvq35AD6HnPqZWJK28bdLFK7if+w/5GPrmACJWxJCvKy+XV9MO+TTKIAJoVI13PbmxactaEREDrV6S6qP+2N5iAmRRIiY0QFZV/Vlo3+s6gEsDI9Vx8inq02nte3O9JGjySbEi1gKqSZ9RAHauh2h9zlbEQNSs8SW58HbS1FYLenf1rwiTCWV28n+yxlBuy8/7Wbh6I3wcoQy/wRmmX4jhG1fi1aP7JlWIAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KISAL",
        "sumerian_transliterations": [r"kisal", r"par4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAZCAAAAACaphhzAAAAyUlEQVR4nIWRQbXDIBBFb3MwgIVUwljAQiohldBKoBKIhUhIJBQJRQJImC7Sv8vwZzv33Dc8LpyPvCE3Am0wiPyEhoebAQBJI0lneJjIp06aAE0WMWvVEdwun9Vi/FrAlTbaQRngXZMY+6ABQGfTcBBDEW8iALh9Cks+3x3pri0+9h1+aq/dcEQAF/KtdR1DkfGfSzNbMVKORzpymzjP+dWwabRifp1W82//On3NsV+qy1lq99LBU0rfIbJerTs2AMd96Sq6E1SALzErSCxOnGiuAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KIŠ",
        "sumerian_transliterations": [r"kiš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAADuUlEQVR4nH2Ue0ybVRjGn+/jK5Qy7iswoNDZLWNFXKEMxrBumAUvAUHiBpnMaQIKbsKyoJlIKeIFIzODwP4YhGxZUMGBQ5igjrCgEdgFEAaT0ZZyaRkNd0odUNrjH/0YGqnPPydP3l/e87xvcg4AOCoehWNTYVz8j8IN0yf/YbuyGJuofUibqvs7zhPvqBrm22K9ChdVkXnGtI1uVH5VW/1eh39DHNp6tsyOzSxpFqde3wZ7f4GP7wtjt9unRxV+bHCaS4ETmOptdVJfbm5y1JfjS2X+kt9mb45MfRKNYPmkKm+XCwDHmLTgoGNDrQL2iqcurJ0F/OrJ/XhJ7fmOeACAR8HoZNkzggMZPY0Ff/XdT2djMaXjv37vClFufcey/IsJOY/tweT0a+6R/sZTTtk1qkQ2MzyDs+pOR5VnIqBcrSEpACB0A+0J53PdS8aBDCBMXeW+Oax3y50zAJAxT54HgLKSuPSLIYDnuc6VG+E85P6xj12VKGh/ZkVZngDOiT/rTDESMfCGoWul3gcAfC6uaz99bu9gjj0AUHbZCZbtCdp3OcqYowN9b8e9KP2mZ7TYGB5vAAAEVu/Uu12L5r2sBwBENEwUAoE/kulC99jFw8kPSUP2x+QrNiH9WcORD/tWSLojAIZzN7lqWLz72LO3LjTBAWS7ofJP7ahpnoUtrbH8ousJKfkhTV2rjMJvBMcTZG6VpSoAIC7q02sA2dgVekde/WVoqLPuvVd+H6BnxIWxg1yvz+Uq67yz/NRQ/4DNTS3Uifc5HYrkLTNCiin5KfHEquXr8gVrzU7rUtqpAb1Jz9Byg7+xO6qgfZzBUDFXoT45x5YIh3uj2Wh6y+ocwiL27+HvuVaiNDRSSjCAueLozoOCGgAwg/A78qcgIyuAX0S0dMeitvbRR3euAs1Z1Y8ZAPoTAZLioB9m7UwelGXy6eO1uim7VBkCOeqBS2PjOkRFCiZQeupgGwPA3NNjSRM1mGgL1ynk7uSZjFZi6RWJSu6N6Q0A0HxZPAFl0hCxPhDeLnfvygdGHPhA5xqqvDKMd2TquH4TO0d70kMA1zcm9qpZPgsAhxZkb17aDcC8EIr/ytp5rlEmvv3gMUTOvvPSl5SA+XKvTXid7JAs0HFaHTWnMb2fNkiomS1YFnaTDWaqeUUpvHWRl9DtZhN5zdVjbiscALYdkVKA4nwLWV0hZG1piRhLbHY23rIQ+AUlfZtspiygKLq6usgmTMwAhL45Fey27IhObyuFVR7CJz8iPZW1FfE32kx0VNFKTUUAAAAASUVORK5CYII=",
    },
    {
        "name": r"KU",
        "sumerian_transliterations": [r"bid3", r"bu7", r"dab5", r"dib2", r"dur2", r"duru2", r"durun", r"gu5", r"ku", r"nu10", r"suḫ5", r"tukul", r"tuš", r"ugu4", r"še10"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAAA8ElEQVR4nHWRXZXEIAxG7+mpASxgAQszEroSWAm1wEigEqYSQEKRUCRQCdmHtjt0y34vhPsl4SeAkkVxaBApYREpAIss+jSsLN5LMQBOVnHmMJxoJ+YIGeWjUBz0e7WFmPYCPTDvkRdZh/MAtKxHVMT/XggQB/QYq9Jrq3gE6NB2MoaGXHGXfXBAB1HFe3LX6lDxh2rzd/WCmk+8w1gV9ceacxwfpA0wqeLG6Ne8/1Co84f0lev+J3/m+is+PP1z/7/qnGpzG5pGF41v8kxmtPpmOMHKVfscsSOpnsAA0Cv8/Lw81QD0D76n1rn6hjeAHyHPc7EOw2NzAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KU3",
        "sumerian_transliterations": [r"ku3", r"kug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAAB0ElEQVR4nGNggAK2jZ4McMAEoyP4LBkZ0EHUs4s3UjFERYV5Zn6ZKo1mwuu3isZTJZZ6oClm27ZjKX/hrVIWZEHGlgtrb3oz2J9eroEk6n5p/f9dd4wZJPbf82FkgGqQrb8peXYL95QJZ7m2tHKuhto5f9vVD0fPGhnveTuHQVYaqjbW4K7YsQX8k+ceU1rM8BhqqPGthfcu7b1gYnjwN8RpjAwMDLyr3us+l+z+WHTA/HP6O5j9zdskLazKjhXov3gmB3ep3w1TBgYGBp3Nx68lc0PEWJJVvZeeZmBgYDDX+3FiLlQli4bV3U+K9xlUQ80+fTqP8JXW3heRDAx6D57t/z+PgYGBgZmZgYGJ4da5/w5sDJLXOfXOWSUwMTCorBZnYGBwOrzwxlTJWcf2X/h+7uY0WQbOFzODGRlEuP8pVct86Gg7bflc/+Pj0meHH/2HxJXmmWsfnqxoeaP6SezT9z+ptxgZGBgYWBfe4c9byPF8d/uHrbIBXpchzmB2ND4Qtvun99z5cpInYxDOc0rTPDD5xS1xhh0zmaGhw8DAwMAQxHl59rfHL+yCn6JEHOfUWNHVPyzRIpmBg0HscBG6IAMDY/8ybkxR44sqUBYA6PSjtW+BZXwAAAAASUVORK5CYII=",
    },
    {
        "name": r"KU4",
        "sumerian_transliterations": [r"ku4", r"kur9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC8AAAAcCAAAAADUorlzAAACJElEQVR4nG2T4ZHjIAyFv9xsA9oSSAlKCaQEpwRSAimBlEBKcEogJeAS7BKgBN0P527jZDWjATQP8YSeAMBFtib5LZCsjqnMtp5KBnE/TirvCarVMtuaJpqDEmF8ejDP+4U5S6sAqGWIM4Sna3tPD3gbTQC0mSdYIFgkWESbDYBrYXOhrGyGFkxCMzc009hmP7S00jFLsil5gN3oz73c/Kne/Kne9VTv/ny37w4UcUwvFeh35wsWQTrQO5OHLsIaECfT0l/wHSC2aMRmGpupn5v3LTcPiLVhW/C6ajOPtkRoCW0ZqZYAZ0U+8DtAy+1CiHtC2net312K7IEmy+2Fv6bdcxeagxLWnqUIagEoxbb2zA9lOSOyILKstaZhD02m+6/50Xd5SQFn4yf/PwAM+oYPCgv+PQxfABqPELkSuZK44OIVmFyZHi9v8uQvtR/Qcli0HBat+4Wi+w4V7Zv+rvylWkBqRmtGaoZsCcDaZoye/XK1mrpqXpt5nZuXWpsH1EY+8H9CnS64ekfKDV+ui9blKB2Y+lA+xoY2i7e5YHPByiw2mmIh8Xu/vvZjuXAYR4555BTLcl3KERfljHP9Nv3oU9O6pmqObAPZBoIFhrklszla/V1vIV+uZHckuyPJH9B6CyeNPKZXvITdUz/ZH7rU80Pq+UF5XAmZo0uyLBu8/tfPnED96qLAaK0lt/2Zf/MCDPXt1warH9p5wX9Y2pb6g/8Le+1Wmsyp9f8AAAAASUVORK5CYII=",
    },
    {
        "name": r"KU7",
        "sumerian_transliterations": [r"gurušta", r"ku7"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAACg0lEQVR4nI2Tb0iTURTGz/vu6uY2TZ1sMiVCSsiNBolaJAwTIpDCqNGHCCsCQZaaRBGKmWBIRWClZEGFf2akmZoV5sJqhG2RlmHhFImZOtfMqfunm54+NLb3fQX1fjvP8+Oe51zOpWDDE3WKfmVBcVb6xiiE61ZxxYdo3RilhXtG8G7p5Mxusj5ICSP3Hd+PHqtNdGGQaxKaUYik2Q8ti4MXxRUWW0s4QBybPZSbEBaIKc248cVlrk8HgBQL5tAAXek8JtuIvfmKRJlUrtL22n8/PxLI2O+SAMCSWxPBYJOMOP+ts7n1/aLVcG5rUK41SACgDafLlDGhEXP+ludVD6D1fiqzXX2/BICMe27ln9T/GgsO59pZKVGSsq61j0Ko5YZtBbHzPiogrHgPq6p2aYxccBWAxAib5TV9444gq3pSnXaWiZIUn9nvFyTFwzDqM9mdLHiJJYh0HypMEzUvRmH1dSKnm22a/eak0ImjA4gtUJLMTfa4mGYLVImzKm/2TRzpGuOyn+YotoB1aoXMXWoHUxGXrTVGciXN1NJ1CsA9d57PNox4gMvGfkclBdCHno6DLGPK17NmU1vMMQDkR1pB4Z0RhzloC2RF14pvcliHjQYgi8vtp1O3D2FgE8GZ+7WBd3X2EZuleQBAkqM+Cive2j2B2XHvicqFTnVV5G1uDACYxA6lKFTy25zPPpsX0P0yl0n93zN5q9bGEKuPQoLFMSTfkak21HUj61py7N0soxTHP33w0+v3hvG3ZGibJtobR5kw6wcBLYkOGtKsJtdMgzqUYb1DiRWXh109mohNsAAQLjtjcE5eib63CRaAJ8jWzf2xm2I3wQJQRFY+rY8G+Aeh7u/A55OaZQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KUL",
        "sumerian_transliterations": [r"kul", r"numun"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAUCAAAAAArJnvqAAAA7UlEQVR4nI2SUZHEIBBEu67WwFhgJWABC1kJWMACFjgJrAROApHASZhI6Pu4VAIbtmrnbx7NVPcA8EkF/UhmNU65aBjaqjLV5YGbyvk4P3CnhW7uph8XGUGLr7K8yop85xP+bgII0JgHk14bXWM8oK2Zi0OkarRHtMzoaBO1HVAqtd2Au48BP3s283g6rBvuIRxwgzxuQFjwXNc9XAj/h8Gf0Do4VGo0/Raqp23UzqAyK1gt+pKi9Czn1cBEI7iusDJ3MNEbXjR7vs6I1+TmOlgtfVcL7VzohweVxDDXIQ4DpLY3upcyb/7p1Uj7A277eXIE5u5FAAAAAElFTkSuQmCC",
    },
    {
        "name": r"KUN",
        "sumerian_transliterations": [r"kun"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAAC4UlEQVR4nI2UV0yTURTH/9/oQLaCUEHBFhtANmgU9UEelCg+uVCDyDBBWalW4yOJCFKKCeAiVogaJ1ExKkhigigqIyBLhowGKsMKEpaFQvl8AAodgP+3c+4v555z7jkXWF5B2f66DoLNZXM4pBGUzlYdWDAAwEIUWOM0ld5ggHJPRo4SWosEgOFC6+2CbwYoIZBeqRt00buPOj6RaxCU8Ps81ZPfXsLXyQGaxha5ARsgY5LdPdZY+skZHT//ySV91L+uwhWwPvaxJED3QJCvz/rWVLkDAHhFpf6LajMin1wqrAkA0Bc+kuKzKF99mXllsh/78E1W/1SxNMN5N7Jj6wHQfo1qXW6TDWG746g6bPeDNjdVP8PilvGKN0vF9QCd+zSvX4cNjWFmzKyjyhus1zKdLPN+h5nuy+p7UtF3kKYpEiGgWWDL3lsp3ihfu4wX7K81MddYdIYUdiiieJluIEuZIFmCtwWjmmdLwmOcvOvHMvx7Gj7IfxQPFte1A/IIx+tudMd4hDizUuluaz/fcUZFeV3jeMcN2mzj0SR/K2ffRoIYjbuaRTMzygnwJmEvZM+iMyqhPYamm9efGvCwNHE087UL8qSJscP1J2hP00erpEUTopZ01lzcoMQyrhW1pSB1zzu+abd7ScjDahKjosAEei/Vm1yp4rNHR+bQtNAN5epgyZes4YBuU04bTz5SWwFEJ6Tl0Krc1HZg6HbPfG29r9TCXVaHopWuFE1RNEmTbCBWnJYD+oi8H8BQkbZntzhYJzif1PVWO+QMzooldxjQX/XfV61Ga2tnkux0DYsiCBAExiMvpMs0S85Oy8VPNw9WKaZJavrviEiccXfKODcrp2cD0WyHDXZO7JTf8dzlSADO+V3BAFjnmhJNVkAB/stO0RlJ9VjGyiggeD75q7BZvnPeNj7rs+qIV8RNKvua/iMsAG7MnymRts9L7dusJmT3aY1245fLAcD0C+eFj+Mf22YI7emztwMAAAAASUVORK5CYII=",
    },
    {
        "name": r"KUR",
        "sumerian_transliterations": [r"gin3", r"kur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAVCAAAAACBYooNAAAAsklEQVR4nF2QW5XFIBAEeyVgAQusBCxgAQtYGAtYiAUscCVgYSzU/ViSbDJfc+rMo7slSVJZUa8KTn6zA15z4cBJD1QX067dcUh5gIVC/UONITmwrHBIkhIMKRXrDhAkFYexj5QBXbFDXfN6VNwNPGvwEAQs65RbES237rC/SYrbXV2cy2FyqrbN0uROIUpSMOj2SKY6mDLtH1sAs3GJ/ZGUQ0pZ0u/nmWHqt9O74li7+wL1wHT1moK0+gAAAABJRU5ErkJggg==",
    },
    {
        "name": r"KUŠU2",
        "sumerian_transliterations": [r"kušu2", r"uḫ3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAACN0lEQVR4nGXRf0hTURTA8e97Pd3atJYRlhKNlAzJyPpDiTIJs1b0V2VgEBUWGRRoGdIPMEFBhIyEMEPNfiCVQmCi/ZNWIJpgueYwMYZQ2mimrMVke+72x3vWUy9c7r18OIdzzwFgW7EV45Ik7VAA6dCx53+MmLrROTMnm7MAdo4O5yyIvChmOhvbA0I2WXbdnXiXFiUZsPXJSpt1x/IHlFdMqq397nybMTRloCHJ/dKCRwhfWAhP+oLEJyYHvWmQOeYvqRY9LfUpRozrEfdNyH2Xp1cFRgovRdemGfDX+9CzEKC0hMdLYW3NW4dBjzvtAPJe8TUTiKl2nZ6nDUUVnXZQiAz1zQ4BgVuuG7YarTVF9kEZUED45CBA4FHwamKJAA47ri3LBmSQwpnXEwBEa8H+5hjIqZvsjUgaMhd3s9MBEPmUF9thP9e4rveHCS0tst8dX+980z2s8qWwbshbdiAkmEcpPP1Urcj+PhqSRHS6Zdx1UC9aAYRl0+6fj9v6wmA6mlKe1Cy5/o1h9Qvhf7VZ61qVJwul+He7La/brkUqvtJmFSChKnnfGOrtqIKtAr1a04cGFSC91nxkDKDBfSpR1VEoAOy5M5U/AYCv0hsf0QvSWnb2ZEt9WH/0O/MzDGgtcdQ1/R9KMCjNY4Q1ZVvKO4zTlvR/zswm5p6xXhlgyVKiKzNSVzR9O/9xqSGrrxXvhc/3Fpti1pqU3DjStX5xUHxurHbZPtUmLUZkfY889IslGAH+AkZFyfkz2R6hAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LA",
        "sumerian_transliterations": [r"la", r"šika"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAAC4UlEQVR4nG2SW0hcVxSGv33mTKwzNSqDY1Nta6NOHtLQRBq8pJY+qNBKoYVARSjWICmWNhfI5SFgSh9MsSGYinlIesGSPlaKTRpTS0qC0dIomZLoOMKkVZmoE62XM87lXGb3YQxSj9/TXouPtdfe/AA0zrzlYAvya3e6Mt111QC8MZs8nC3sUv1ayt8/J68KgNKv98p7V/yJzZLj2JG7j+vnKlSAyPy1WEvN9N9yk5RyLiWzFhqfqAAeb77DPzJs2m40iz98+cv76fP+8MJ571abs61vrRJUIO+D7O9/KldmpdyZ80h7Ttz5113qT0t6oGQ2LRU0at7LoVeeRAq14qXRt/vuop7/8bIFQDiuggCyP2nKCZ4uuxBUPipqE5FDQcTDMWM8IUDWFL4bQgVWuore7xoa3v9O0+Dw7k8/D4JkT85KWIGEEwFqcQhW/yj8C3nV9yvW4Os3gMyM3y+F4wKszPcAtf/6KZ3E+CJo8wbM5ff/MtNwxepdf3gMQFVafccmpWUAQgIh78kF94O5b7pvqBLiLwlA7W/dNzigK1XLvJpbbRn7EqPW7i8C03ltzeNCOn0F/6SAr6aq1kw9GdW0mKFpWkyP62N7CIXqs1wulzvrrL8E1NwXrq3+4Eq2L1F56qBFxeHjH++aJ9HwYH0nCSg1xs8HTgyZlmla0jRNK5VaDMaJ9FR4PB6Px5MlANX6tjX9pRsImN41fEsApi8mQa0NAIoqQHECwikAsgt7BwDM+mJADQAsTBmwGpQQndQFUNl5Lj11e5EABYDbPVGYaJcw2Rl1AOFnfOu5k6RTAFEAPQIk0hm+01w3oANUb5NPpQ22F00YgIzn+eYB3AK7VNBxy2HCm+MdIwbA0SZhl1bkmcXvNE6MLqdrh0zZpeWJ8mdbdvy5XOcEwHjNu+MRm3F1/3YuJpOJdWJSnnbaJsl4eVnwel/0aZ2Si6Zt0os35cXnM2zt/1MW+Mxpa/4HEp85rAq/OIQAAAAASUVORK5CYII=",
    },
    {
        "name": r"LAGAB",
        "sumerian_transliterations": [r"ellag", r"girin", r"gur4", r"kilib", r"kir3", r"lagab", r"lugud2", r"ni10", r"niĝin2", r"rin", r"ḫab"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAAxElEQVR4nO2TURHCMBBE32QwUAu1cBaKhFoACUFCkFAsICGVQCRQCYmE5aPDB2lTBdxX5l5uZ2duD+j06qgqSzFmyUFJFvsKnwtpKVwBgt45VB9ModfEirugTeWY4QTAMLLM5XfeD/f1MUlxqM0RZV+bfgMhCDhhY5eeOxgAR+8fZi0MhHfYbQtwMPdzc9QdyP5xE/tNDH9xPOIu2XSIKfixqRDEZRtTSVrDxOhJOxu3AdaY1jfylQVn3M5L25suDeAz8AE2dHBAwkAOEQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LAGAB×A",
        "sumerian_transliterations": [r"ambar", r"as4", r"buniĝ", r"sug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABCElEQVR4nK2TQZHEIBBFX6ViAAtYYCUQCbEwK4GRQCRkJGwkgIRFQiIhSOg9pGaGkGRO+09Uve7m0/UBlPwqKq0iIawiDeRkgq5wl0lL5hvAy7z6qsCI1zKyYeXloDWs0AJge5aY9/3ODtthFAm2NkcQ87TpDhC8AC2mV2k6wQA0aPcw5gq3TEM/TACBrFVOmq7sJuoIwN1kOpS97wdYsU8zFi2+tNYUdY8lahVT+ca2OC8L5gebvs4xMA1GF85qzDDfy+U2Fc5p4QOu9I84Afu7ceq1tb22rblwiGk5PJnxIybj+ssJXrgdYyoisoWJ3pHisc9Y2GJa/5G3c+bTmL6w3C5MuRX4A/Hwk5RYIqVLAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×BAD",
        "sumerian_transliterations": [r"gigir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABC0lEQVR4nH2T0XWEIBBF7+HYACnBFkgJWoJbgpZASmBL0BI2JWAJoYS1BClh8mHYjaC+Lw7XeTyHAdDyo8m0ini/iiiIwfg6w20kLJEBwMlzddkHRlwtIxvWTgqtfoUKgKZjmeO+3jb3bTGK+CYPhxeTYtoCghOgwnQ6fB9gABS1nYw5w4B7usNtARTM9ZyR+tVFdVDX+ddhVbLSQyrtm3bJ8TLWUwSwJny+jRKOi7Fb2/REiY2+bQEfdP+6kKLN7V/820ccD3BIO3HgcfljQ+jzs3e6F+YnUrYYwz32V1wFM15iIrY7dXBCX46piMg2THSWkN84YBrYxjR/I8kWlOHrfb2lpD8BdgV+Abu2ifeKKKXcAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×GAR",
        "sumerian_transliterations": [r"buniĝ2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABDklEQVR4nH3T4Y2EIBCG4TdmG7AFWqAFLIEW2BK4EtgStITbEtgSpAQtQUqY+2HcAOrxi8kjkyF8Ar3MPc3aRGLcRDrISUfV8JBJa+YJEGTZQvOBlqBkZOc+yGltcYMHAMayfnJ93pvXvhlFommHI4o+xvQnhCDAA2379L5gADqUn7S+YyAsYd+4eXbMcS6aA0aOueJcVEGAruwzfZzpc3mJijMu6tW4G4ZX+lGD+VU3nLN922yXwx/tPbzK0/NbtWzSkIqy4T4N1cvUrGytDZthrbtVk6/PRMO+iOF6ernOx1NMS056/JfJeHvbIQjuHFMRkT1MWE/6nM9pA3tM23/kaAsslzH9srhrxW/AHwSNmMDHI2CGAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×GUD",
        "sumerian_transliterations": [r"šurum3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABO0lEQVR4nHWT3ZWDIBBG7/FsA7RAC6QEUoJbQiyBlAAlmBJiCViClKAlSAmzD+oG9GSehDs/3wwjoGRSnGwViXEVaSAnE/UJ3zNpyXQAXubVnxyMeC09G1ZeLrbGFX4AsC3LmOt4Z8P20YtEexZHFHPIdJ9bfXThBWgwXqWhCGrLFA3avYw5jirmCgN+9ih1FJyOSntyRj3STru2rH+t/wxxa4yF9zICi+2GwU/dWGN0GhKAecFz6MeQS6zDfs4A6eZjV+LXSW4w7d5YPYzN2ml8ltjOxVTV+3EPtfL8zguAgdaH/1o7VnoYBsBpb/Lt83YHfobdzebfQsRJ+RNXUhpXaw7l60HjYsXzrfJukun5bk0i49rLoh/mhcd1TUVEZFPeOtJ4jTMWtjU9/yNHWmAu1/SK5fFFlFuBP8z9rmcNjjOsAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×GUD+GUD",
        "sumerian_transliterations": [r"ganam4", r"u8", r"šurum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABWElEQVR4nHWTW5XDIBCGv9NTA6wEVgIrgUrAQiuBSiASUgmJBJAQJCQSQMLsA21z6e48cc43l38uAEomxcGKSIxF5AQ1m6gP+FLJS+UGEGQu4eBgJGjpaVgF+bASC5wBsI4l1X28t1179CLRAuiwwVHMS6YHQA3zpoUgTUSQyViAQZ5iVnxC+4exMVhrl3pJ0ewEnBk71z28AUiJ1OduL9GK1a7lA/CDWpO3xpbl7ez0sunw1BJM9kX7et/VBsg6JlWpOrh6HfMxWo9fd/3Idk6VW3BHaQCzTPMUJg9hUHtpgOEna5UtcLexG7e1gfwNL/3p3j8X9MbajO9ywVzqIboOj1TBZExIl31jAFUbwGLNbR0SXjXlbddqmuOrggCUyYldvVUxOxylbDHvd9t3puLdeiWJnQXh+nmmIiLPqTlPPsQAtAPrRT7+yEba/DzTf7Bc/6b4AvwCUiXQBiIxRRUAAAAASUVORK5CYII=",
    },
    {
        "name": r"LAGAB×HAL",
        "sumerian_transliterations": [r"engur", r"namma"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABE0lEQVR4nIWTXbHDIBBGz2RqAAtYWAtUAldCKwELVEIqoZFAJBQJjQSQsPchkw75afs9MRx22V0+AKNPw0ZFNaWi2kHNkuwGnyt5qlwBor5K3BwQjVZ7Zmyi7lRSgRMAzjONdR0f3G1e9KrJbYsjqSxlhh2EqMAJ8SYPBxiADhvuIp8wEF/xcFuBDkY7LlviAZoRdG2A7T0Q3BF2TxtELH29H+FRUj2Pj57JufcTnZrc1VOtyQ5q3mFhmMTfb48h08qpAzCCK08wD79qbEmdGa8T1L8mtL0bhgGgGfGq771+4bCz4Rqnb7zL0n/FVIL/mCEql71NVVVnM+EDedzHiYPZpts/sqQFXoc2fWO9fCgqFOAfPiyXif/PlVUAAAAASUVORK5CYII=",
    },
    {
        "name": r"LAGAB×IGIgunu",
        "sumerian_transliterations": [r"immax", r"šara2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABKUlEQVR4nH2TUZWDMBBF7+HUACshK2FWQiqBSqASUgmpBLBQCUFCI6FIIBJmPygphGXzw5xzeTNvJhOg1mdNcSbVECbVClKUYAp8TsQxcQXw+pp88YOoN9ox49rr7kxhghMAtmEc0lbv7H0OOtVgS3MElcWm20HwCpyQpo6PPzAAFcb1Iotfiy3L+Jf/JFT1OZ6/Vi3QOoDwyhN8186NuAhSXzb9VUtg4tf5Uj/oZI2zemhfozFQP/sE6V6oJd7kwQ/ERiS3ktXRtTR4GO6r6hmbsU/i4bIZUcajsYlo2Q7w0xhpYGg2vte1vxMwtAf47ee6xZXbrmFf4rBb0zWO0v2LSbjmMINX2v2aqqq+L7RxxGGvEwvzmpZvZEkLlXA7j8fetD0AbgJ+AQhvoM4xAxzrAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×KUL",
        "sumerian_transliterations": [r"esir2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABIUlEQVR4nH2T0ZWEIAxF7/FMA7RgC7TAlmALTglMCWwJWMJaApQwlCAlSAnZD9SdUWbzxfGGJLw8ASVPxSlWkRBWkQ5K0qE/4a9CyoU7gJNldacELa4XT8XKySXWsMINADOQY3m/b813PXiRYM7DEUTvY9oLBCfADT2oNDcwAB29nbT+hAG3uOZnATqIfWzQfiv+Hru8Xjdx0BudW9jnVGnkBS/bw/2of2p5VXtXUfMwzoBJMeslZgrj/IJVP0UAg9bzXFCmHBs0YvZ1mk38p3fHu4FHrjjeVQSIu4ynyacKHtPAS++/eGxpfeWdvdiwpm2y2NDmW++k/b+Ygh0+VnDCeLWpiEg1E4MlNTauDVSbnv+RvSywNG16YBk/DGVX4BenNp4h5K7mbwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LAGAB×SUM",
        "sumerian_transliterations": [r"zar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABU0lEQVR4nHWT4XWsIBCFv+zZBiYl8EqgBSyBLWFTAlsClqAlaAlYgpSgJUgJkx8+jasJf+DMx8xc4AKIjsJpLKopLao3KNkmc8JVIc+FL4Co0xJPG6xGow0rlqiXsaQF7gA4zzyU9/zg6nXRqCZ3FkdSu8kMFwhRgTvWS+5/wQDcMKG1FiAIOAsS36tMEcAtERlHaCa3FwecOkDGRm2TpmiXbpQN33ah2fTJlNl3rctpi97/z1KXyCs3fOHyj9QtuwwdjqeIlyCxnDGpNa9g5ixNbdpOzvhBbx8t9vWwfam29K03LsDsDbE4GM7F5Vl9/PN9+8B8flTd4VrWcwMQumk3zvu5AWKYS7LHyAFLcu1Q5+74tvfQ7rgegN68Pf0yer16Ye+dbfMb3HpnCsFfjH6o8bzaVFV1NRM+kIdrnnWw2vT8Rw7SLK9q/lubPv8AYQG+AW3QvsB7KwwRAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×U",
        "sumerian_transliterations": [r"bu4", r"dul2", r"gigir2", r"pu2", r"tul2", r"ub4", r"ḫab2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAA/UlEQVR4nH2T0ZGDIBRFzzhpgBbYEmjBlEBKMCXQApagJWRLwBJCCVqClPD2w0lWQH1fwOHdd5m5AEreiqJWkRBWkQZSNEEX+J6IS+IJ4GVefXHBiNcysGHlpao1zHADoLUsU8r7Xdtvi0EktKU5guiPTVdB8ALcMFbF3wMMQIN2ozH/B7pU8rPfj+z24g1MetrdZczFs+pcbuOW7ZxN51i9uM/pFA/6h5gP289+xqDMOU6P6a3UKYa+x144Z1T26t30uCvMI5/tihimPsevKqZ7a7E1F7iJLDh7quCFro6piMgWJqwjTnWfabduqf7IRxaYD2P6xdIdU9wK/AFC9ofc8DzkWgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LAGAB×U+A",
        "sumerian_transliterations": [r"umaḫ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABNUlEQVR4nH2TYZHDIBCFv8nUABY4CVggEnISUglUQk5CTkIjgUgoEoIEkLD3g6S0ZK7vF8Nb3r59swBKHooGScT7JNJBDsbrhu4zIWauAJNsaWoKjExaZgqtJjkh+QQXAOxAXPP7e2d/ymEW8bY1hxdz2HQnEiYBLphBhWW/0rGpuaDd72jK9TDqmLXKUdFXlW3ah0lmEP9Qj3syuzhgpfhS6Q6zKKy4o3f3FFFeLbCErGNcdtOVttsSViBjN70N1Z0VCy5ZBLAeZv+ogxUEzHrU39J3Haxg/brroEqu+ZlD7Z17zNGxpl+dc/19MXSmuanxE52vIzEA4bXiSK1BSc2d1vBN3PlPfBfM/JEm44Z/FSZhPK+piMie+eAI6/mdsVDWtP0jhyx0hlvfLuAL5BTkDpeAPyDYsGpuRaleAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGAB×U+U+U",
        "sumerian_transliterations": [r"bul", r"bur10", r"ninna2", r"tuku4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABRklEQVR4nH2TYXWsMBCFv8OpgbGQSggSggQqgUrISshKSCXsSggSFglEQiJh3g+yLYXtuz+Ak487uUMGQPQhHFRUUyqqHdTFJnPAQ2XJlU+AoGsJhxesBqORDUvQk0oq8AaAG8lz/e337ro9RNXkjuFIap8x/QlCUOANO8pyf4EB6DD+y7YyowNuBiTtqqyhNbMKxAjE0IoDTrdcpnjwaiAUOWF5qDDpDSaNP9GazI25humeCeNP1K7dx8f9uiT7npdk+/r9hZpb4tc1iL1Ui+sr+eCugwu59lNc8pAm7LH4Moi3uceb+X1y++N7NhZVIK4gj8S5b1JoFynuBZZiwBQBtzbc7XapHwZyD8yX55qXb/dvbW6fTmO6U7fY+F9MxY9/VgjKdB5TVdV2YqNnmc8+62Ab0+M/sktuuQz5Fd6k0x/AF+Af9yrExz+xncsAAAAASUVORK5CYII=",
    },
    {
        "name": r"LAGAR",
        "sumerian_transliterations": [r"lagar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAAAAACMIRMSAAABAElEQVR4nG2SW5mDMBCFf/rVwFgACVRCLGQlgAQqIZWQSmAlBAkgASQECbMPKb1M97z+OWduqbDq/LRM0rr6i+C1aDxbIrLL7yLD0hvQxpzDqHXKn3kyrDp6kDxr91Ej6jwIAFGzADE4ARfWNbTHK6cRIJV+kn9PKHmyJkKOOXof9YlcGVFjbiWrqo4GOVUPnbrwaviJAkAKa8Cgei65+VnphYpLNBl0AoYO2KfFLO2E4xY7AIvOMmyTxPq2sxt0bCOH2dla2/VSVVXVSz10Yn0PhXHU6E2HD20/zRbe9n96N263ppd0XO0DAVPf3H2m/QfBfr80V4CvH1WCTaAd+Q9ldYoo8IELNgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LAGARgunu",
        "sumerian_transliterations": [r"du6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAAAAACMIRMSAAABMklEQVR4nG2QXXkDIRBFz/aLASphI4FIoBKIhI2EjYSJBCqBSGAlgARWAith+kCSNmnu64H7MwOvmvxSFmPd+I/gtSvuXokxm7kWM5fTC7ChtRh0TO3Zz8xVoyfblnV6ygiaZwNjDaLNwC5sS9lwznM9FMDE4heuG5B6n+Tv3cW5ufuZmpAWWvA+KBACoK4/09CsaaqqEcYc3QM5VQ+TOmkj5JqqmAcSgCRVwAZgyjc05u7bFJA+9Y76L6MJbIvZ3NEHME/AthSQ72VJYvqMHY5L4BsojPa4gY/ldrhaXVAxJIdkue1x/F6jSXZes3a3nrWeD8MwDCczzvbrMKyPqD8SiRo8TFl+G960HPerVCmHNcEzgvWyP5KyOf5HQDl/XsaGfYOA6+nz3Ce/0XZ5Z/hHP7u2stDmVAZ2AAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAGARgunu/LAGARgunu.ŠE",
        "sumerian_transliterations": [r"part of compound"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAeCAAAAABlfzOyAAAD/UlEQVR4nHWUazDcBxTFz/+/a7GvstnFshn1HEFMEbXSsh4N0WFMUlKqMpWIjKpkWo2RVrQeSaq0QqMIDRrTmsoUIxsqVkUsSkQR6zVY6zHSXdKIxXpk+4HJ1Ex7vtw7d86337mHwEsZlGnkbNvEfgAgtNgj6suNZ/L0KOHcOg2A4vx0Yo/Lk9iZbEu+t+DFcyf5FRkAUcG5Fo7ek20OY4bcr1mAbSv10N8q8GxsjNbEsh8t3RtkAEyzelsoF/4qoOY0Vdmmli9w8x9RL7DueDLk3e29iFU+XHoEgPOVw1kEeyVvfCiMZye9kLAzfd5G8KqktfHOjftGOrcicN4PsK5fEiNgMptMUUbQylX+/LKZHn2qZFadcPjMG3+un9R4m7G0CElU1G3GhatXLjsxl8v43dZxqqYtEqwcIZhXx90gPWIRUuLx2kQ1J6NhLilfOeAw1TEofKCScC4X0kmYi7AyN6SIXknTNo/Qx68JI3WflQc5/tx3+pV46ZcLX3M/ZWwBhgMPIonQs7qVxmbnsnN8QHHvVjbSojbS6BfXjhlcn/Mzrx6qY+LiQrkiISY6tjeOTh4o9AbA65gyRPw9ByL3N4pByU0dnnjbnsjYUj6zDZid31pWNa8Fjd0DYFp7O5tWKc3Tk6S02Cb/0sj7VbFDIdCXuqxQ+CjYXW0AcDw1bNye1bdhbtYBO4zA48YOU4asjH480GjTcYEYXAKa3/IYlwGYngZGAHSKd5CGxjAAyLWdvd0OAFybfEA30QGTDwgEgHU7CQDQIdW04PSx3gnaT5OAXspaN2KPEUj3glmSPXTSdgPCCUrNunSqpGLmBwZAFqh84SMNRrjMXL+4lovMVX/Ehji4x1XmhroYuQxOqSIBFGmlpIfiJhE68zG+e3ICV1aH2VSRvfTdhas99o+3Ek6aRc/ColhdQfom6vefjjEb/170UFttdPv5Npllyi0YzG/PM+Qechxe3HAUL8fOW34rrvjs1AfTRRZn9hXST8yTWqp8dD4tQG5Xr0rvtPJgUkbvBh2mqYbfWbrLDWdFpcaNS8LeY2sBVsZ+EKVjr/L7hThwSwREjbbVIGn9Evv6uo9x7fybjm091XQwunJp+CSPeflaqZtfsTcAv8HZfdSsdhsUVJG830v1rFq0VnCb7PiCGxhxsI5OiUmp9AIAZ0UmOLXJurx+f7jViGDd9w1RZf2HZ53JqK5d21CH4+dF9wEgNiFsxFXQrBYaNhBOmhEcKSZC1tQawVE2v79LrcN0rWkFAPpH3a17/vT8bkJcBvjGNjLN64VtO/Coa3tsxG5C5sVMgdXB96nbO+fNzb3doN0tB4r+skzWUW+pxH+L+q99cfEx8T+2fwC5E5JVLMfhHAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LAGAR×ŠE",
        "sumerian_transliterations": [r"sur12"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAAAAACMIRMSAAABOklEQVR4nG2SXZHDMAyEt50joEJwIZiCD0IKwQchhaBAUCG4EBQIDgQXggpB9+Dkrn/7Zn+j1XrHO7wqD/MyU0zhjWDwrvL1SojudF1oXH5eQBQzFg9qz340Ni8DQFY9P+0QNyYAALsRAOFEQOJmnCspFRIyFwDQnkczonGVwpW1dD9qCnYxGV1drVlzYU/9iS4Wydzdi0odK1ddUXJPQPbEre8qVP8QA4Byy9xvkFYUavc1oxoYTLxO7RDadAZANtNMwJ1uA+L3DADBe1T1sRVrppZ7wj0SJskAcMlXutwnuuS1P2otiTNBU66kQWOJ1mOsbRjXhDEGBNCWUMYIgAYxzbRVvYbfxFxchge0/2fz6XjjxnE77x8Hb9PxBK0jvSMAy/kwBUP8gABcfw5nAHj7UQBwnz4ZPugXbO3CwWai8OwAAAAASUVORK5CYII=",
    },
    {
        "name": r"LAL",
        "sumerian_transliterations": [r"la2", r"lal", r"suru5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAaCAAAAAB535iiAAAAf0lEQVR4nM2OPRkCMRBEH3wYOAtnIRaCBCxg4SysBSwECYmFSAgSEglDcU2Abehuunn7MwO7cl7x9FDfZn9ZXwBUqm3PMnZax0mUCjFwJS3TwV3q6pKymoVpYIpL61k9fkXmZgrp4wkAUUpux6aby02/7OxuHpSXg/X5kw+HvwEz3i+MVDDBpgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LAL×LAL",
        "sumerian_transliterations": [r"part of compound"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAaCAAAAAB535iiAAAAwElEQVR4nK2QwW3DMAxFX4ouoBW8gldQR0hHcEdwR9AK7gjVCPQI1gjKCOIIv4cYgRwklyL/QvCRxCcJV5kNPNKiNvf5+3ABoFDSnFe/0uInsRaIIx/8hm5gkpqaJFOVdZWkGOpmqpGmOu30BDbk+fPs3x4XL5Nn33k0wAtjYP1KZ8puTlXVZqamJptC5xC2GpKSWuxvSGLUomU4LApJYNLhEW97/CFfHvHMAd/4vf7FV4DypN+f8Bf4vog73K/JHwH9XZa2PYV4AAAAAElFTkSuQmCC",
    },
    {
        "name": r"LAM",
        "sumerian_transliterations": [r"ešx", r"lam"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACsUlEQVR4nH2Qa0iTcRTGn717d3GmU1pTy0DTvJD3bpTgoChLchjOxCIoqbyUqYEFUaaRRYSGJZZKXkqSKMOkKNMWTdByXkttJoqao1E5b9vc7d3bh7bImT1fDn/O7/+c5xwA8E/A8mIAcCztYS7trAxz47LZ3NXbAJZI357MWEJET+rflRd+oJvA2KntKBkJJgAOn8dxdOWxuCt4JIfHL6eHxuVGVThJ919y3ONceVFqjMgaVWwJ6pIHemhkXuu9t8Iiis2/0PPbMuz5ZKYL8jtqR+8aWzSPpz5paWXvuLFiuuhPQoe8n1V+qP2cymusLEaBQvXgijTjPq3dCACEJwEAuxWdolOzQsRRcZubjFeRrIlLnnnoBACrXgQAALzqR569coZg4fbgUJcYCX1PB8xnOAABsSiVAICxA7ci/CJjkrjHaw+pSQh8Ixp+mC0A0qfeTOywpsmembPITdcR0JK0t3smcc1wNgsg4/uUvjePdgMA5hXKdSp9DUycwwLT4DeKCQCE5MijOqpMwgUApiZNuY8MwaYNfhW5as5fhw4vG76xFkCK1DW6gJJdHppOQ+TrXR6j2Swbws7sb4gEUqRCgKZpui8GUTaCAAAYi9PJ0nToqTlILG25MjdvmG2/SWuVTeTkeDi4X3MRG4rq2+uy9CqDHYGx890nfLgciUw0jvEvupMwL1gA2KYAwOy9zDaWUJYFEmxdzbm5YH82tcgDwPvm2PiPOgAgdc3cO/khfIsdgdb0oNCX0ANgYmpQEyUw2xP9A07CvMCDvUYAJFVNV5L2hBlq9em3Z32rDQCY2v55YlFSq75XJzpW+RgAEITdLjYZOo9V+2yHyf5if+trrrwwqHHB+lrqAUD7ZD+/OEBPL0/ALE8o8RS7U/9s2sSSDMt1Gaz/IYzQVjqJCfwCuHIH4dZStQ8AAAAASUVORK5CYII=",
    },
    {
        "name": r"LI",
        "sumerian_transliterations": [r"en3", r"gub2", r"le", r"li"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD0AAAAeCAAAAAC6MUmtAAACsElEQVR4nHWU0ZnbOAyE/7svDbAFXglMCXQJ2hKYErQlYEtgSuCVwJRAl0CXAJUweZAVy97NPIkQR4AGGAAAefIJyT/H7rflzaxP7cfgFUgBSEBcgDDbEyUuj+cq791Vj1OEpAg2gVGP2Am9nw7NYzrIRRXCqJC0gM0ARfWcjSydC/HaZwDApEgYiiTvsMpgldJ6fB0Iw5VOdJPKvewuwtAguVaqK4aqKpI07unT0OL1xI57KWn4Yj17t7q6zTLmojQ8rw7qLvXee5ckPSUfHfhH/HezJV6/txw+3rWFC30L36+WLsFv8Xa9HfdXtrdfDxG5ANlHsr54rWYqWqqvysOTDRZpPWVTabLXFoTudRKHN7KrUKby/t92F+ZgZ0wtvDawShGqwq75ogpFyvkld4bFR3phU7UC0yApQ1EEUw1yzWYHlO8iP1S70z1AVgTrQG9AVVJznZABQpNBaHqw9zlfAoQChAgwp9Tzc+UAppaHz9PglvMY3pFc5/n4w2ZxjdA78O8eeHT1CTF8FU1hi7t23/bK2xWI2wb5F4T8P4R2S3l+XF+5oeWPj9q3xwtThOQJ1gl046+qpekFsIdqJ4d6BvMAq3qU1CwfUAaKz73oP/0uUiRURZIPKDIo0lLkJ8lRBlO/S3GwTU2Eob471FwZUxXr06ihHPpj0HfNYy9vt2sa28d17T9/bb28sY1y2eCK1fN2yiP9eH+W0JWwqYG5DLlylithAzRcsx+Q/GTw3oFvb63+4PZe6/aT9cZbbu9car+QCISw3a4AJcDG5VP7CM1NxOGd7L6yuFKoqsqLZHeN4tDidqadHZqgKRB8QPJd89X8sVTDfF5MTw41CNMg7yaOUNTCk2R6tsJpvbeHQwcPhz5fH39jvzo0AZw9yGHbr9gsXzl0fumwO6wCvwED3gz7bMyoLgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LIL",
        "sumerian_transliterations": [r"lil", r"sukux"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAADI0lEQVR4nI2UfSzUcRzH37/73eWOqONqiOO0duLKKXFcHopVtJJEZZWlUcpS6zmptVUrrdZUV8pOqSFPIU//sLC6cLhOmZ4zGSJPJ3Q7fv2B3F1L3n99Hl77fD8P2xfQlv9DR0wjmo7H3OBF+wf4lxhpxbXrmTOrTAu3UrAyriw0nglstnZ0KDk3VCl1Y48H6Po0qWUbEnQH2B7+MFy4zpIB2Ij04R12WsXJkzfn29gYnfqhqo7kLX6wWx9WfwzjTNoGm5p95jyKZKcGxwx0KJ99NNFFHZBCqR+LuCwAMN6myHa5VrrkXLX9hfL9nQPvrq6cp8UKW4iE2CQ3h0p5kxrwmEuqTe0bDayV/I5eThud6WpSmfG6dXL8PDaRcCCIJ6G19ZOgcH+uz3e10ehP09HX4pFMfk7rzhCuvED2BgDM4mMDkaqp+pwf72nJ5VotPfriuN8z6Zq8TFF2AT+7fC/Ajir9Vn1MbABzCdUE9FBlIbMm2zpVz7dOWy6ocLEoFhlLs+gAjIIfNr2/FJTZ/EVCh/y69dQMBtJ4Q7EfVm3G4g3g5geMn8b9Yp/qua/sBAm+znZc7i0CiImlh16eDJdRieiJpdGcdc4kbu1cuIywdYf1RrBdFQAAmq9EUOl7VmVO4G1d2BTrL/ODdC2Z6j0vM8roVh4HAHySvirjlgRXDBaQyKJUEs+JCbfKE3lXSpwkTxfk1dgltxwE4JX0tTF+BQC3GpUpEX1Dymd/blaRGLPrNmMN8cbaOUSvxlk2yL5T57HLf/BJSS0AwL3wLhGRGLD6NEP1coDQCGV9HOGnbu9XGnGWwDyf6nMMHEovUmgmejwTR7di3p5TKH/Z9YugZotONpw4wIiNaA87Qu1KEJLdKflv1H8Gum2Pekq5xYY17ppE1wn4NUKnKgG3pmik99Uils5ezaFItdM+yjnm+gD4nc+hFHs8HwRATzyOtme1zwKET9FIQxSXDo9AfVjnHSZIiHL6ldELGABIll6e0HYOhb8d5rq2S3K71fiv2CUF6YNxFoz/kwCwPbcrxnBmKMCqqLWdJq37jwy31rZNA/8GyxgYBQx6GBMAAAAASUVORK5CYII=",
    },
    {
        "name": r"LIMMU2",
        "sumerian_transliterations": [r"limmu2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAARCAAAAADiEzPsAAAArUlEQVR4nE2QW5HFIBBEz1bFQCxgIRa4EnIlYAELWMhKSCQkErDASiASen94TH+dYgbobnTQtSoylZXXztVskaQS2+iUSmjnPzF9ouf6A9j8N7n3egEWeJxnfwAc13qs4WlPlXH/MExW3ft/xTAq27Q7GaphOZOjmomy2To182ZVbwLeKtENh7m78iJoiNRp2fCB9xcAt3tPS84hldC6uk1vVN2jXekcjG1aafI/PeBwqdFcLQAAAAAASUVORK5CYII=",
    },
    {
        "name": r"LIŠ",
        "sumerian_transliterations": [r"dilim2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAdCAAAAACGBrNjAAAAeklEQVR4nOWOQRHDMAwEr2EgCqJgCqZQCqZQCqZgCqGQQHAhyBBUCNePp7VCIfrdjnRaAEgFcRolZCXDinQ/9iWnzpKZ/sBIa26i8/6hCs1PvNPnHNA866U46XRn/b3qdMlc2qWxmgWhRr4ugh6NYTuAbQFjXABwO/AFrLIxXQdBulgAAAAASUVORK5CYII=",
    },
    {
        "name": r"LU",
        "sumerian_transliterations": [r"lu", r"lug", r"nu12", r"udu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABB0lEQVR4nJ2T0ZWDIBBF7/HYAC3YAluCKcGU4JZASiAlaAmxBCwhlKAlQAmzHyZRQfOx8zWHO/N4wAAoeSqSCCLOBZECoteuSvAl4ufIL4CVKdikQIutpGPBykoWwQUoAagb5jHu+019X5JOxNWpOZzot02TQbAClOhG+eEAA1BQmV6/ZKgqlE4q7GQ/dkTksRUHall9dY9JbXG5V7qF6+58xSdTGojjyDGungZgfzmruKdpZ7QD6IcMK9QwYu9LaYa1v84Q93uvePwhj+Jg7f+4T7DZj+GQYpeN6RZ73X3FRExzqmCFNh9TEZHXgzYGP+Z9uoZlTNM/8paFQnO7zOfepD0BJgB/cfeOUdMrMjIAAAAASUVORK5CYII=",
    },
    {
        "name": r"LU×BAD",
        "sumerian_transliterations": [r"ad3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABMklEQVR4nHWTXbGDMBBGD0wNxEIs5EoIEqgEKiGVkEpoJbQSgoRGAkhIJOx9AAqEdp925my+/Q2g5K0oLImEkERqyNEEXeAmE8fMBcDLkHwRYMRruTNh5eVgKSQ4AWBbxj7v3zt7m5y7SLBlcQQxS5nuAMELcMK0Kr6+YABqtHuYWQatUaaI8IP/lCMiz604YGWt6/4c1Baf9krXdN71V388ZYDc93zH+u0A9sNZxSNtN2ICwON1wAr16vG3KfSATTyPkH/l7v/GxbWDKbFfp+X9OZZYhXkvIenmmDuP3gMIXNfmajcPUetLVVVVVfVsd5/erdhtbtMOFpaVBElSnIp5dwuuIxnX7g49Nt2nDS90xzMVEZkX2jriflZTCgvTmZZ/ZJGF2nBtxm94Mul+AJeAfxxYqh+mh6EXAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LU2",
        "sumerian_transliterations": [r"lu2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAZCAAAAABvWJPDAAABdklEQVR4nI2S623sIBCFT6JtYFqgBVpgS3BKICU4JUxKYEtgS4AScAlQApRw8sNr6971WsmRkGD0MW/goGiPtjMZxr/DjjxzfUltwN7lNnYY0OsJ7amlWLrdULoynIVV7a5w2p4TA9IpbVhLmLeipFJDIdNJ3iRZ6NdHJMmSClm8vIIV8BvdqxoAEF/Y1+szbPoUNt+7XCDTs5GKSIdwrErm+uyeGkqYgflVD1wg4/QPTKbQDeAZX9Qkc2Xd3TM4pywWcL0IRC2mWZxa4x+jmiIZ3N4N2N4tYHsR6dy1xzdaWWfAUgFASreAKd1O1feksQd9TMo51ZhIvqHY7y8AkGSuCySZa2gtq3ykcYcYWUe5jDYaoGRc0w99AiT2wJAeedQUVd22ZW8wdQjubRlwXrJZ/2WThxlf+96uuqAt43t6DCrjjtaGXqE5O/fE4gIMLA645ZGPTT7AMMkun8tv5AqLwdqPX/UOWNz+xgJAP+yPBQTr+U8/x6zqJnuY+9EAAAAASUVORK5CYII=",
    },
    {
        "name": r"LU2(inverted)LU2",
        "sumerian_transliterations": [r"inbir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAXCAAAAAB2CaNmAAAD6ElEQVR4nI2Ua0zTZxTGn7f9t6XQG125l4JVSwRkBIkTIbJp3NRZCMiIE7ZMzIYhGJU5ojAQk0WMExSmMYx4YeDmUCFDN9xUNi0wl3CZlw7UlpvQC3cooReL/31ATIF+8Pl2nnN+ed/3nJwXeCOJhfAFJWE5emkXpG8GA7mfoxK+X8sdrA+t/y4DY0HdVnenOJeDF6Dt9GtDePDsS93EQlxc+olTnKYB0PTLV6Fb4pXcmmqTCZTQShi0Zc6XyzIuDzrB7QCDy+dKvP0VIqlLBIMv0rb6pXj1UpXm3ohaQdnobFks7f1VzgtHkMXhuXF5AauotbXuQQdcNXazYqBo0h4SWcSb8OmlKjJYE4JDN2dx/qb7FYWjx2cAQODJF0l8eAqxHwhfZl4qG1CFX3vveklfagGpALAt8934NqpGmnMv/GZ4OwBgR8x3DFuB5NRzYPVhH84Ugx7rbf9taDw4dsZLxTOeI3mHZr6pMhQp8sZwjVo7RYAE2mK42x4EAGt6aIOxudWkKY9mLLlM67IVHq5MAKwawxDdYzVpxzPXdVaJEaa66A5s71oBYFtXhKCgs3kFgO2dJ8IEXBfPXXf1Dcn+q092Nh2WsQFIiuP3V8VllyjT9+GdBw1+CKxT7ZLlq5cASNL4RXV/cOV+tEO/SGxZx5PSmJDdd3oqEwPnDyHg1j9RWKm+ZDS2yAEkqeNqmiI9zvdumle1dM+NruupYetPP2o7GjUv43+hez3O/HXsQIccQPykrqXqPNwKB1LmH8Nfc1StPrkxOOOO7pcUvkOC8+3gx1+0uX70RA4gQZ+lLJk6wmGk67Lh8mVoUOaqjfvDtijZAPFOq39elyyLruh7VBzCYbHdQkuqFQAro7/yfdbOTjmA5GfLQJL1Z1yQ1JMrbJ4w0vphum84CwDA9FTW24YK2bLs1uH2uhtPJ+lfPQAgfbDhnvahHMTtXMjmfiDqYuPeqZjyv6sPPhaNyEcFYz+Ni91FcnEobfdkdm2xw0WZt/LP+s9ck1oBgHOpLX5q+Y5G4vWHb1npIPD2MX1+v6J02IPze6p/42ad2Wqlqa7R/yyGEdNQHwAEnSUFP54unH3/3pwjiSx9JmFmHbdqa59qJrfmawZcA2VjPLXgmU14q2naZLZMWu0OLQv9+S0q+NVCbYhMsD1WXiVYV16yfB89YrUR9YjB0CENKP5Uq0p9qMJi7fy+ZW6GTIinaTYoWM12ju12RfcDGwAg3HPMYrfaWU5oXN39eplnMARMgwLEJ4x7frDM+QwCQghxRsOUu9CnIPLrTnO4KWGCyQBz4Sc2q9uLrbi+DY6hJBxSAfESO8UX6X+wc4GE2XNxoQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LU2šešig",
        "sumerian_transliterations": [r"ri9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAZCAAAAABvWJPDAAABv0lEQVR4nIWT0bHjIAxFb3ZeA7SgFtgSSAm8EpwSnBKUEnAJdglQApSAS4AS7n448Sb221l9MCCOxB1JACeb7dn3LxPO28bG/8OOtABgsgLDR8BXXDvsgqXvMKBXwER7hdX7R6KBmrOj2x2xKQNszRG21cOzqs1F+r8qAiJDqD6OLYcP9AKpay+r/d7OJsvDWIu0DqXY0j9lAJVk5rAdZpLMMZOkDDwVJCowvOhWVQDADJlNlXLMrDDNB+rB7wJ5Sk2F0iEwHC5gxsqm8glrCwEYGcwRhwtk9G8wmQMFGJjPNMxYWff0DM4pqwVcywKjFn40Tq0Mz1b5mZz9SzNgW7Pbahp38wBgAIhW1vECmx93ACbKbYHMcrXjQ0sRt3T5tiaFnuAgxgFAftbMZA7bWmd1uUqrqrXm7Y0cgw6AkmGTHzgCZmZgiE8dtTGqe03ZBVK7QSoJcIMpZotLkrrAmd4xPfbCXIDcH/45GQkF69r1Ck3JxcVIkWna4S+gozhgSj0dKlxcv1v/1sAvABJtuR9JACnN7mb8Y/9EvwAjdvr9Awukm5fbOuANtphuP6EAlsnje3n3tNO02a1tp0H5A/65F2fuOKfmAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LU2×BAD",
        "sumerian_transliterations": [r"ad6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAZCAAAAABvWJPDAAABlklEQVR4nI2T4Y3jIBCFvz2lAVqgBVpgS3ALpASnhNkSSAlOCbgEXAIuAZfw7ofjrC5RdHkSSKCP4c0wwIum8Lr3Tl7T53CU3oU+lXUj3LhtDxjs+w2dZLVGxcdG6ab87lqzHouGXxeZ8pb2ajWPR1KuyXKVyhvfTVJV2heTJNXSpJocbniGi0E66N7MA/hU1a29wM1wfciy3XO7G/AmqaQnWIYpkvesnHpOMcY4qvmxqe83AfAF+iHdODPa9bLh+rouAKTbGeKQmK+338hSzfKQVB2x30ueSg8AzpraI7xyjKYWIPbqXbDAMLpoYTjODZM0DYdnCL2HfXZdDx3J4q2pjRD2MrjaB/C1h9RSLzb1bFMwgBjNpiLpixp+LgCuhPMVV8J5XNbZ3Hfdbjjv9uDLtm4rmJR3+1kjuElZuRw+ymQWjy77wrfNMS8zxOQWt5+b/bz57fLo20ed6/Yz3B9qZmFdN/vG5jnGy9PznWBjiXCdt/m5EZ51AnwJy+W/5A47z/X8AQp/IHzKAvSXPxTAsY9/9BesafzHUU6ZpwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LU2×GAN2tenu",
        "sumerian_transliterations": [r"šaĝa", r"še29"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAZCAAAAABvWJPDAAABnUlEQVR4nI2TfZEjIRDF312tAU4CJwELvRLGAiuBSOiTQCQQCYyEjgQioUfC2z8mM/m6VO2rgirgx+umAeBFLb3OvVNk+zks5Dvrj35ZkE44LTsM6OcbOlPNhLJPdFfWd2FVXTqnWxYVfaflCY4cVst2qDCo1cieAKD0Z+tB0pjXQSNJ64O0HIr7M9wVyBvtQyMAhLJ6CCYVLTdnRfCpUh8sgnkn6SF528ICoEIpqA81SD5Mgw66qt8tUNVrBQpruKNFXdykkix3MGmVEci0OxpIozeNmeT1IABYRZQjAeIWETRhKkE0xUrzEDNLI9u05Qwk97T2wbmrsruiR0QdHAVIaxmC+QRE85RH9q7NqzYp7k1NVFsnCdi1ZsGY1340FRvRh9a+xbBeNQNK1jX9ygKExsodGsPZbHshvxDHEjCfZ0ByOId13xznJS6HBbHOZfm7w7Dl33S9ohlnXC6LfkLnWeQAIF+m6c8V/gAWnAU4zsv8/GoA4CinL9xgxJ7Oh/+SazTcwSHi+PUOfdBvIP2UBQB/+XEJCFjbg74BbGYkMTJZJvIAAAAASUVORK5CYII=",
    },
    {
        "name": r"LU2×NE",
        "sumerian_transliterations": [r"du14"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAZCAAAAACAmvj9AAABy0lEQVR4nJWS0ZUbIQxF7+a4AVqgBVICLmFSAi5hXIJcAi6BLUFTAlMCUwKUoHyMPZt4k7PJOwd9PF1ACMEnlfDZ+6u86X/Q0eyPh0fv4km3QXjnfRwuyJn59kqLd4NkUmu0eLjaxQRT/6xsYgZwvU4g0qPa9FFIRi1rtaqqqtoyvXhAKm/4to11Cz922FV/cyHAuL1vQBDcd3VhHbhxBpqZVUs7XczMqlazmhy41s1C7RIgKoAKpCfem3gAl6p1CaVPLpcW4Ek3wfUpm/zagQAxm5lmmvT5QZ/Aw+zGhdldPmi9X5c1hC3ifFhTXMHBNwBJ94nLNWV30OtUpTLO523Ce/yRMLOazUOyeuDaqkixopbFzMQ/67Yco1gLEHv1OAlMsxUJPqWs2ptpMSvTgxYg9B726LodmgBSs+ClWRcg7M1wtU/gaw+ppa5Sepby+N7apKiZOaiP1rlqaY+tSKzN9yaSte63VM2SADHL+5OzzeCKZcv6KKVpEYnHyL3h23As6wIxudXtGxe/DD+uxxgfNHXcpseULKxs25AzsiwxXl9gTjBYI9yXsbwmP+kEeA3r9Wt0p53nfvmaBPgG4Z9hgJ5fnQCOff2un7vcMSM1ihItAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LU3",
        "sumerian_transliterations": [r"gar5", r"gug2", r"lu3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAcCAAAAAC8UTtLAAABG0lEQVR4nH2SUZXDIBBFb3tigEpgJWAhlYCFrIREAha6EhIJQUJGQpAAEtiPtA2km30/HOYNdx4cAGB9UMvEZYkGaADwZp3qBoFBgAsAjtb4A4HbvpljdxiAmwG4Ar1V30ofG3j7akyuT+f+MHl1P/HRgM7l/awr5y8dhFCeTv24h2m8s1PQqoUkW8mnsAJkYLo8fG+2evja1q5PIWD0BAg5Ok1uC36fH/o9vwFlNIaCL+nN/7mMk3um8fcXH/HBmgEIf/Lnkp+MlYovQYr8To75rcP7tPETMTpV87s8q52vkrahzp8k/sfXM7K/z/KZPxp2vr4LtbwvKs0NUJVf9V8BVk7VAAT98T0r5tzF/KFl92N0J9/36ZtT6xfol6FfIX4L5wAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LUGAL",
        "sumerian_transliterations": [r"lillan", r"lugal", r"rab3", r"šarrum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAYCAAAAACHXxGzAAAEGklEQVR4nH2SfVBUVRjGn7t7F66wy8LyKUKJ5SKxw0dDYQY6VqNpNEiApIXTgA4DzpBoymZZKeYyWs5gVjqiMSAwohFiKASLhiW5CCTfLLDuskOsIqzLLst+cvuDiyOwdeb88dz3fX7nnvfeBxQHAAB2uDicooS73sPitem4yEEVAGD7OdAZAIi3TbR+iNblOvBk0wfZ/4GXWZXfRPkKPAVLvzZ9LjYVA2w+35XL57JYTz0S+k64Y5ocbiyU5IzcBclhaZLrFXuAwKPLWngreq+qBxkPJ8gcnarQO+QvjfQ2577OguurEZuNU2kAOB8O/lTZeLIvbs6ydqC44nHmEoe4rjVhTvLLBjwAgJOhuHDoQvtOpuzyg/Wjtd32Q4GO8NYvA+akU+a1WRGpnlTKKm96AACcdz4a++1PpZ5uTBQ6LZq94auV1T1PJgGAshtF3TQAXVeU3OgZ8qlECyDsE4GKN3pn8vmws+orNxWa+XjrTGf5YNt9AgAZ5P/9mcs2gMVrSiS3pmzlH1MBRPPV2iY7ALfY1Iy0tqquXsszOMkS/MLTkAQAlt3ifXZFqRLTNhJJmadqj/jtl0MmY6yTNTWvbXhLorsh7VE/5Uv6izZyGZ3cUDYgvSROzeqvCq3s3IZk+e2YBcP6JhTKFdd3RzKPRJN6h53RVNIHnT69+fjLKDKPUYN02sRGCWdv/cLPFRWzIWJcWteuAYDSB0XrXZhGUkOF4l51xtqUxp6S/CvGY1yE1w+lUVgeBkQsR2g0PN/kAfCOP9mhqju4GiBSiwuWcnonCABksDDCeqRKgcATqjxeUGJylWQ0+HBswfH4TO10mGFARHXzvbY/AAAER8eJzE23SKO9P0trsBAA7bTEKr1YARA+bIPBMHp/Yq+vuD9bvMen3MWVCpo2rXKXr88bBgAej1TKuLER28g32Jv2tQwbCYCmEtblqgD474ppBzBVoDlwan/f0Uc5LlKPNdnrnjsXOn5PF7eKjHT2cnFzH9N2GkhSWJTfz4zOMZhUADBl8tvBPv8PDOcf5pXn3MqXH5YJBS+ErH6RH0tGGR/adXSHdkSt15v1IB/H1s/hbBYBANDVpgd/lljXplE9uZvyY7N3gCiEINLN2tHft5yrM+tmdDN6yzQ9Gxvp++lZl2VGAjalgYkTreyznM7ZPTVjp7hs15e0fVWjm4cvun18uoVb2jb/J5Iq24FvT4x0sECbab++2eJ4l7D99iuuf1wbGjKa7Rar2RKg/9vfODYxaV6QATKU/PV6RY0FAEG9y4RpWhP/3ZoBSbXBQjM2muSQBBvMdM/g73TtazZZAQBOWqbrI3KPKfxCb1uYt8WL3ALj3CtYBIM7exFnxPPuSRDA7P6fo17ePitW3igh57eWuYMQOEPAWYD8C0zIqh60z+7JAAAAAElFTkSuQmCC",
    },
    {
        "name": r"LUGALšešig",
        "sumerian_transliterations": [r"dim3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAYCAAAAACHXxGzAAAEgUlEQVR4nG1Ua1CUVRh+vm+/vXDZ2XWRWwoiBkgwCzmYaCKjTSUiCsalCMuJ8taMQqag4ziKEmilQZo2yOiQRmLpgloyuAx3kGspcgdZmJ2VXFjW/dj78vVjd2mxzq/3vM/znPd9z3nmgMcGAIAVlh3G43rt3Ib/rpgzoTYS+TJk/s2HCwDERj0z3cVMZ/2PfD9zhAUArKw4LpeaB/1sGv0mwlPkJvLO1R89rLkAsAQCF1eBK/lvpUKmMQwAEkaj2QWxHAc1NVZ9OS9T/hAUm3yWVNlzDPA5taiN798jkQ/ZODwfQ+T2EQ13+an6ns+SSoyO1W/Ie5uz3iTh8kZ4jHYmHQA7bejKrZrTnZvtlOjBkjLlbvfPa80Ze2YuC+c1r+5IsIeCssEFAMDeNVJ88pfOnba0c7Fpx7onutuK87LKFvOnjr2DGqpos8fGdicVAJha2UmTz0d33FICADc1bjrVxcUS358m4BcFGWbnyR8cD6jomX4BADyVNvQJA0DdHTGodVt2KE8FQPylSMZXNKlDAjWCnrcFfvPejuqYfVw61PkXAYBa+sqFSzfNAMmve49KTkkWfCUDiOby+3UWAJ6R21briLTGBoe7oyhSdJv/jCIAkBaj+4/+10ehM1NI3FN4P8fr4ABaW23UifLy1e8oxOfvSnvG5+QxA55FjbR1k7Sr22mDuEvO954OSRZSF5W5xYcbHHttbvZcvTk+se9eU5c1QdSNf2SxgbzEDx979OajRRuqV/KGZtOn3s1jf1GFl1bE2i3BSmll1zMAuP706npnG5D4oGykvWLXuuTa4ZI8iTnXFWFVw5/w4CcGwv0Qsgpub/EB+MaffSSrPBIJENtLCrzZvVMEACooMNyUIxmBz1n5UX5A0lZJniLoRFTBma17VDoxPRjKeyJYmPoUABC0Ki7EUFdDaS39e1W0kQAYjpNJeq0MIDwZJU0rOiYyPbP792VneJQ6u/CW6vTLhQPrT44BcA18To1KndeFf0BtYMUcaBvTEgDDS4jOkgHwSIv6E8DMd4pDhQf7Tv2d6SxdsGZftG9RyGS7OjaA6xvgq+ML1ROPaYoKvJrfbxudTetlAKBRe31s+EEHunjiZGlmTf7AidZA0bLgyFcFUewwmi8TvyiblI8bJg0aUMqoKrucRRIAAG09HZiTIG0d004/TLnY7L44NJgg0g0qRW3COU3ODX9Un5jSMdZ3l76fvvdmq5aAeZS220neb7iQkUmbWVxXlstrqj6JYtPYNeH+wjbSuImzpapJMmGy20ZmPvTt1/JHJBgD49VnTSpaVnTWr+Q33Bke1hosRpPBuFjTrY+fmlqSkhVcEr1sCXtOHkLd/b3snhEAwYt73Zo0q5d/v2Ywr4I2MjYaQ3G0FhZG2lPdb/0qiZz7sKjY7gPNeuthHJV1dniIhWsvH9OYHb3GgMMA167UbzwdV76q2uZUKh5aewmSsMm5C4lL2QZHMUGY/UUMyNne3efudB4PatC9bGWAWpFqDQL++Gn+f4pFQhAiDkRskEdXssg59B+M5NhwZkTuHAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LUH",
        "sumerian_transliterations": [r"luḫ", r"sukkal", r"ḫuluḫ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAXCAAAAADbiLvPAAAA2klEQVR4nHWRYZXDIBCEhzwMxAIWOAmJBCxQCYmEIKFISC0g4ZDQlcBIoD/IvZZcOn/Yt9/O7gIKf/JLoh2jsSsdgrN46172WvZaa6ml1rt6k/HJ4MnsRHy084cHWzW+OjzLuFWP4RNBBETKTBAMxeEktkPLHh8AMs8FOifvz8lGJpNiasu7rmQwENpLz/du8PkhuOimLW8HwNR7gvtNB+rHaSFdarHpibVhPm65LR0hPHOLx96zLnG73HqY4NcfpZRSKvSeKc//HrN54hcALdd5dH9KgiRAkIIXRldg4et+jbIAAAAASUVORK5CYII=",
    },
    {
        "name": r"LUL",
        "sumerian_transliterations": [r"ka5", r"lib", r"lu5", r"lub", r"lul", r"nar", r"paḫ", r"šatam"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAeCAAAAACdn8hFAAAC5klEQVR4nI3Ua0hTcRgG8GfbUafOZDqnTl0LUyeWafugrpnYRVkWCmqMyEIlLKQb62JKkZYQFgZlGGZQ+UFtGkmSFwampJnlLS/zktrM2wznhZlO3dYHN9Oc5vvpOe/5wXkP//ccwFBB1wyJaoUNimwIjKu7CX0UPnfaXFP333WEp6HpkcgwrgkAIAdHCTSNB1Xi3wAAv/ZEXvGnNiOa5JY8oNnFZ0f10oNji5LV7CGta3nvNzt3Wt+H8u/rNOMZp8OnQ0jXAHH38u68YMyyq7N+aJy4wftsZNVVzWs1uA/oC0us66UwTWPyhl6Kq3zjhwDAlOkZFsDpLHnXt1rTsumlzuHKcCJVlcopHukJTS4w3DQx40YfcfhSVjSl1uo1EaWRwOISe16RoQE3K3DgRBPAXFJRaDNqAIS/6BCtvaZ0WKkDAFb+MQDuneXbAECg+2gPIOm9+L7ES/8IM2F2c5/kAo/DIiHyaUalE/u4dM4+c5yIvEKoI8YATq7jvDR9ZmVg89hTfnMyKUmUNGk+6KP9fNryIrVQFJMjux06BsD3TUXSlP7VdnrscWOrSIqBr0RId238ARU5DbMPUyTzN/L9l09X/lM5BQDeft5ezNHFjorB4VE1iFtzC6XRYrtFgB89fbYJ+mXRKk5S+kl+e63k8pImxcwvzarjD+xqTHk1nc0AIGhzAAB6oa4tT5Er4tpaktYtgHVZa2aVDf5qWrGmvfmm+T9Mv4PTYfUhr5Wr2jxWi5f8yRyFbkxDm6NtXdU2iZtoQL0Sto+Y6+YAAHO+JQBA0GINgOzsEpLbeBS2E5muRrm+/JXnqMvJIr0//nBjQ6dgE+2rq9uhj2Yx3V09Z8I3+uwAUC735vJXrgpHgkw3GyRhXNr2jLacSYmK0M0sANiIZTl2AICIsYT/YQAB7UUOALy7H5tsQcOn+q072DXFG/6F1ha7sk6YV7t9axhwKRhtCdgqBpInI7aOrZrOk420/wDvYQAtO7U0PwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"LUM",
        "sumerian_transliterations": [r"gum2", r"gun5", r"guz", r"lum", r"num2", r"ḫum", r"ḫuz"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAWCAAAAABIq/tzAAABjElEQVR4nHWTUcHbMAyEbxBEwRRCwYNgCqJgCqJgCqYgChoEDYIo3B7aNfnbVI+KP/nuHAGX6oLP2nfNs2LeNGlfz4ujl3/2Ner4xihHTdePUbE3V7sDpsRmePKn+jaTVSv5PqwB4VHGCYyqcQLBWgO50DfTrtO8a6arLnqDGL2la7dgWgdwRCjQrLhexhqjttcBHFET6FmbxrQDgOimJ30A0GDo0+Ss3dVpAIx+QIzcS4A2NytixnpK64slAIJeNYBZ2YEjaBgj8+UGQMZLWlMA6A19cwua0wSwis3KFyC6fS2B6Ft6j7hG5QCak1r7P0Ayg2ntIc3Op5LFLZDNLcCstGfW3DrW8mbF1R/pXf6KnjWAkTW62tWOqJcC6o/UxkUexLgFYkwyT2CT1TkFOH5Ke101gZ40jwGg6WatEXR/nBZL7v4TEqM3wCrkIk4bIDO5BwB19veroqyM83ycM1tnTgFuNsPI8A8AANBW1e1a4Ni11pd9Fk16/3Xzpf78vkcAoOvfu7a/u3yrf/igOVHMaaDGAAAAAElFTkSuQmCC",
    },
    {
        "name": r"MA",
        "sumerian_transliterations": [r"ma", r"peš3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAbCAAAAADehRkCAAABHklEQVR4nIWSUXXEIBBFb3vWABaoBCxgIRZYCakELCQSshKyEoKEIIGV8PqxTTYh2fZ9Xu4ZZgY+WOKbdM84b68riuGeknHeroRGz0wv5H5RxJuFtRpj1GxeFkGDC+pA04qHYsbi2CbKz5OBUeuB1aR2J2FKUQNEFQ3+yTrJ7C06zcAFvtrQPBKApX9UVh9uT8tYQ0oAqU2VRCIBDFLploXIY+xekwcomuwWxRJOLA1mh7wUj5arkFXRFCrrUveb6XPbxT3+rIcCcqZeW92qVVGJZovgUose019reLjR8n2QTm50B7SptbSSD4+0tdrRnRzX1s2N/q21zpjJ4/19td8EEYtOMmxrWbwzj1v9C2E3zSDN4aDUKer+deBP6QeG76WWBar2hAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MAgunu",
        "sumerian_transliterations": [r"ḫašḫur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAbCAAAAADehRkCAAABSklEQVR4nIWSXXmtMBBF1+2HgamEVEIsTCUcC6kEKiGVABJAwkECkUAkBAnTh8PfgbZ3P64sskMy/1ijtzRkvLqPDcUwpCRe3Ua42SPjjvyCIiorq+0eo02yWwTrfLAGbNxwV+RePMdE02kUuNu24Gy0+klCSrEbEK1Ypw/WmMmzRWMTUMFbHW5zAnC088lqQ/+wnBeGDJDqdJJIJIDOzMb1QkwR96yZApUyODcNG63DZ3veEKxRq2X/UM3iZS882skBOSs2hnNjIunY742ZNtdNfP6NCphnp0eWsztfG+i4vcrSWOJuPRohO3fYX5H2g1MqyBJj3oDj8+tSB2BTkL3RnxaXI7s7QJQD+sHCGrfM2W9WBcwaBrIv8+Wt17yASP/6/t6Trpd0jAcIRiz2Q7qlcZlA9TL35ylcVtd0ZlO4KOcUa/7rwJ/SNzv3v8bJaShCAAAAAElFTkSuQmCC",
    },
    {
        "name": r"MA2",
        "sumerian_transliterations": [r"ma2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAAByklEQVR4nGNgYGCw/LO+5/IGBmyAh4WBveJG6V0lrLL/azgZ+JefikMWY+Lj52RlZuUUYLnRrFj896zjCWRZkQ3y+0+/ljYIYDmoHqy2noGBj48RIft9WUu0729hhtMsb38m9Pf++1L+G0mW4TMjQ/bFFWyxLC/+nZ5f/YddB8UxjA9F4x7LB91kmPXv7vstSy6hO9bn29+NzAwMj/6fC2RIvcnAJKEry8/JJ6MnBJE++z+MmYGFeXP2Y1ZOFgbWkLLz975yKhoUr2dgYGBg2Ca/9S8DS+7Btwz/Xj5k+Hnjj9/Lh2oC5x9C9H44ywyzRdSZgYEh5M1Csy13HKFCpfv4GBhYGBgYGBhe72VgYNi1xJtNY+J+lEBDMD8t/xPxcBMDDlmGqxsZ9j7EKfvl/M2rDDhlGX7e/YBHlpGFCY8sBqBclknNHo8sq9P8KNyyv64pdpcxMPzDLvv/6W3RhhNx4j++wSV+/2NgYICmJpWVJzZMkvrH8fUnAwMDw/0n//5rCut/gMYRA8NvFn0Z7k/vTr5iZmBg+POX4e8H7v+wGGRgNzb8uqjvv/Sd9wxQA+Ul4LYwR/9/HMwGt4cBpgSqteCNK7IMDAAAUtWZg1N/ZKgAAAAASUVORK5CYII=",
    },
    {
        "name": r"MAH",
        "sumerian_transliterations": [r"maḫ", r"šutur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC8AAAAeCAAAAACZahh4AAABXElEQVR4nI2UUZWDMBBF7/bUwFjISshKoBJigUqgErISsMBKSCUECSAhkTD7AbSlTaHzlTO5mbxhHoGtMCkN6gBbb3K3sNF7gCF8xtMqgNcP+FoAH4BGo87Jw4aWUAFggr9csFPy+J7PY8toJAk4wfUAfL3nfZWvvbMXsMZJ/s5Pcp/54Bf9IPUQZb0dW1O6ZPkwEqOs9F8l9q+8GZduTiGc8gMvJhf4e8wHALAGib5EGXtfz5IAr6rtVvEpGl1qdk3cx2v1zHMz2uzirdZAChZAq108uemUerPPS0wW4JDz2Q2p2ykugVMPiz+v4yaNHWYcgqZG7nqsFPAqdbe0TsuF9/HFRaZ7mM3xydA5hydtFYznO7/ebOsrjy6yVb6M3S9lXoLp5Wf1X7jWSP576QitwA5RXvp1WnwbtKJJRct1WjKuxqGYB0mlvB3qd0+SKY0E+4FDVxF2HQrwD7bdlc8vkWmHAAAAAElFTkSuQmCC",
    },
    {
        "name": r"MAR",
        "sumerian_transliterations": [r"mar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAXCAAAAABGhbJHAAABBUlEQVR4nIWRYZXDIBCE5/piAAuxgAVOQi1wEqgEIoFIaCUQCYkEkLCRMPejCYE2fZ0/vH37LTMsPyiKJi9Za4VlAowebjiRFs4yM5FCoagzBjD0iNSWDlF03fHVhKenA+7i6JpxVjNKmAD0ZGo97hRbikAPAPPzKLpk5JDs5jlhAoAHVN9QlrA8tL1AmuBdD2Oxjluo3Xkx822oMzG5/YVmv8kzMvniKYzHEiqoDtGp8Q9nujrkx7I+C2+qTrkpkrFqJNoTSNpNBfL4mQLVkwAsAxnMC/QS0NBc5W2ZLdP16J3K4wIA0B6nCuRcAnyw6ww+LKqG8jh8Y9D9fkWAS1Ot6yn0D4JuqpV9cHO2AAAAAElFTkSuQmCC",
    },
    {
        "name": r"MAŠ",
        "sumerian_transliterations": [r"mas", r"maš", r"sa9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAAAAADFQYt8AAAAnElEQVR4nLXPQRHDIBQE0G0mBqgELBAJsRALWMACFmIhlZBIAAkgASRsD21DCFy7p88bBvY/8Ik18chQCk9UEY6BgdS4RaYdlubOgOaStpaBQM49N3TlMJTxheNyaxbnWD1DJ7u+M6mODx7Z7UtTYoyYjN6yBwCbi0sIJXBEALMvjpVMVrb/Brpf07rnei5w9XHyTZdvz773+e/+BoUyPX2Uhh4yAAAAAElFTkSuQmCC",
    },
    {
        "name": r"MAŠ2",
        "sumerian_transliterations": [r"maš2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAACfUlEQVR4nI2Ub0gTcRjHv3f3Gw6nadN0ERbZkGEas1YxETVqiEWzrN72xvCNGJW9if6CEkapYK6/VuYfkkKsoBqSFULCkOX+qgiazTBmzjDbpbbtejG33e5Met7cPd/n8zzP97i7H7BqUPrazSKRpoI1gZxlcmjCCQleYjUB+58As0bpnOWjScc1n4Tt2PiKm+yqN/r8Wp7I5PRMfzQdFHnQzXiHe12LF2QRiZROLQ499TZKRH4r5soLJlqSeVOPfTdefvFl3porGpzUPmoZUPGaS2fbpMCmKtv99SJY7+XO0eGMOuTpiAUA7BoUw2lv5vZFshLPk5B1reWuQgg3OLaFblOPTHfGhQt51tupAICMmJBUPaIGQGdqtWWtbE88b0q+3bAOAIxVoQU1I2oA5NaUy8Wy6qiVBY6mJADj/scZfBZHjdxDR5/AX+HozUSgmZvpK98eA+Di0BYAgKz6K3tF+DB6jyGBjHnLKgxWm5uj8hXn3RwAn0RBDQvZl2dqCOH8n1mSzsqZxRR/mpwBfL90jH9SyKL97B6SLeuIq38/9INeqs6snKYRkB/O6yzeIESlNxZOYYbrL5QCAK52xQNI7FjgWt3PBGiMwb4X5PejOmcwp2kCwDd+R65M2Z/bz0cl9fmnewFt+P3Vdq8FAFm8QnPSac/moaTJroves8wCALXTbM4KF5hGWxH+yQLqQfPWENpgLxb+SFEsciwDmcEddc4DtADFted8FjusJhWA1Gabnlm2HSkGENVuPvGg/R5RFaVXvvYLxyIhOXoVtdvCTryb/aAUkSsEpeqebzNdEpldOeTXl76V/B8KKN/OR84SsgoIYKzlZ+ST+wvUztM8u/QfPwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ME",
        "sumerian_transliterations": [r"ba13", r"išib", r"me", r"men2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAXCAAAAADMqisGAAAAkElEQVR4nL2PQRHCMBBFH0wNxEKQUAuxgIXUAhKChGIBCamEVkIiIZXwOTAwzXLn3fbN39n9J7FsuODvN74kqalpdRyYFVxp/qhwpSQFeqKUsTTFbj4DD7yzuSSto8lBHXOwbqt7LtF1u0kkfSgDAL7GK/W5ALC/c0XK/T9J0mzvVqbp4AaAevnpYfmX2417Aa5GQuAx/kIlAAAAAElFTkSuQmCC",
    },
    {
        "name": r"MES",
        "sumerian_transliterations": [r"kišib", r"meš3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAABbElEQVR4nI2TYXWsMBCFPzgYyJOAhVQCKyGVwJOwKwEkgASQwEhIJBAJiYTpj93tthRa7r85+c5N7kwGvsu1nFanw2nWqS71wVmxqU2aGyOj5C9XWQlirc1spV3tdVddtfWFwUYTe2tytFmcEVrbS3Mdbzvv1bQk9aumpCmp+jX5VCdvqMBlebGW8D6FejS11JFmtJGml3UxtwwwafcZY1jTYp1eWT0+MagleZjUA+XSRa6+NQDMTmIMQiBGJCAEgoAwAtXcjfRmGOYIEG19IQNEgGebIhEox2CJOXIfgNTzzzY+VdEvDHkc4yPbMUqFwPz/F+KlEri9n0IpgXCKvLOPhp1i3epOs4Rp7Zq/zUuA/s1cl6Sqqs1fbLswXv4VRVEU8gtbATR9/6wNcORdAvL2iWKc/XLa/GD7+KpjvRw2ZbtDEKa4wz30LbvTpk07i9ncfS+b7M5k2VrnvX/Qqabu5My9+pMkpOkY/QA6+dhL29q05AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MI",
        "sumerian_transliterations": [r"gig2", r"ku10", r"me2", r"mi", r"ĝi6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAcCAAAAADpMNgVAAABrklEQVR4nJVU0ZHjIBTT3qSB14KvBK4EtgRvCaQEpwRaICVACVACLgGXACXoPrI5g+PczL4vLJ4GniwBDLUY/LQM/U8pinUeEU0n/6VIpqefBqyyLtOh76NbO5M+q7SQQofpYGRNPSVcegpuWCUtBnvPhCRGtbZ11/noKekTBZi2sLYn6gUphIazEk/SQJFedbBm0af9ACSTLIDi+IOkzG8YmDLzQgugVjuIWxjVKWWujGJpATiy2HlX17LQmReaeNICnhqApSocSs11BCIw18eckepxDv0s3TmOxerRDJ58TBAJAM+vfZ4T4erTY98ce9i2L4zHNE4ARE4nOtWTYy7tSzujriuAaQPCMuU1bf+ssup47/0HABcg/VmWeLs3PAa5OqV2zoSr9i11dsN2AdBuyTu1QQVAI663sLcY11qT0wypzMoMgAezeDKaN7GTSFIB9GPDS3KHcqQFIqvtc3mmdZfTqNvvZpf7LOueHyPrLR04v/bl1yoLgAbInrEAxGzfZgiqUmVWO4ZO64NHx+fMMjOOr8zCwmLPI/Q90tFuyMzvLwYAkBoPiD/R7S+MjCIhgm44tAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MIN",
        "sumerian_transliterations": [r"min"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAXCAAAAADIX/s7AAAAeUlEQVR4nL2MQQ0CMRRE3+KgFmoBC98CFr4FLNQCWroSWgldCb8SZg89QOBEQpjLTF4ybxN7B7vC0Q+yJVwKhVpuCoXkUGRpRCZFw/UAqKPIANM9KgAmrVGlGwAMOQCusQBFq5MKcOGZCW+Ef5D91+b+QeYXnvl64gRN5jWijZHgpQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MU",
        "sumerian_transliterations": [r"mu", r"muḫaldim", r"ĝu10"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAaCAAAAAAYx7rgAAABQklEQVR4nH2SUY3EMAxER6cjYAqhEApZCKGQg5CF4IPQhZBCyEJIIXQhuBDmPrpVm6x0/nKsJ2tmYuAsFwHEgLG+Ln3xQCgfiF77VSDrNCLRzj4xQxrdgHg792TSSWP7QCjvVoqpRataRsTqobn52wtlueHVIbnNz+VgZhdluQdFJyfp40fOZ1gb4Vfr9ShTVaCmt6LG8OkrmBVg5dubswI4046BmAETWfb4AwMQx4C86feGe47LvAB4ZmBb0rOH5oRERON/ZVBO5OQBOAtAsvEz1FBJ3TOoFXCWByQwgXybnxjgm0mPeLP9aHZkhTcOp5EuE1etTMmm1sUjylyPibMmk1FROzmZiqr4BgBsi3fycGlGJ+d30+tbrVZkjl/hm10uKtEAb+tgXRrlCiUgMQ6Q71arCaDjIkR2axMgR14Xd39+asxwQgIBzwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MU/MU",
        "sumerian_transliterations": [r"daḫ", r"taḫ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAACOElEQVR4nEVSXUiTYRg93+v3uWlzbdH+xJ/8QedGYTWTlheiUSuLgXdRYUmBehGNERZbUBe7UwjMWJEuy0QLqfyjn6W0skwsC9OSEDFlydI5N5bY2uzie7/1XB3Ow3M4z3MegK+9BlTmQihGSsGO3sKCV/I4b7pKAAAZjsnllrchgc65/I4AgNGeGq3Nf/6X0jonN0oAZDSGps0xz2+eJZUXA91rBEDgWpbKJSnheH4D6avLMXSaABSN1WjeWBm+wRnHuyR44T2RzKJ8SLHToyKEEEIYxvi5gLm+W8o+mOYqfg1YPn2kE2tVSywT8mYqxZuLXh7SfdtFDf3RDuO9t1YK1LWS+lvxtfLcBtw7CODcwoHzkf3xbUeaxKzVhxS7/mdVZHCJ+j9tnp1aJz4g3fRkycj4b6Tw/ucgy94HAFz+I3+HY/2hiA7oPeHjBEBkxp0w5OW+0/vEvvaHZhkAsro9hZrObJUhCACQV9jC/SyALPNNydwi7vCHI9VlTyfcpBQYtxzRNCQd/UB1Jqd00R+YsQLIGaiX9F5hhfu7m0UYWeksA3RtanlPkrCY+pmBaYhuL16JQb0azFoUAouqWtlcbUKTK1hSW11+soYGHBPdH0WgWw2kdh1Tvj4jyIibH8tg2wLktXsPt09so3TmJV99AnH4UewcS7b5W6g6OWXu+BIlAGILivBAopaGtdE3XKrkcZpzPvvCvJAW0nrubuLRVpclsdHOCQ3FoJEifZtKfPv/f1ac/Qc14b0Ob4DWiwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MUG",
        "sumerian_transliterations": [r"mug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAaCAAAAABnFqgRAAAA80lEQVR4nG2RYbGEMAyEdxgM1EJPAk8CSOAk1AInIU8CFkBCkFAkFAmthL0fhZsr1/xpJ1+ys0mAK9ShiPb62P5APSbSVoGJLsxV4GMvdBWykEpSqoQcpxj6H7XgOfewnsvdR88gJCkaL0kx+Y0CH6IA7pKMvgMAqMAyGABGsqQyOpMJ9Jyo0yho9x0yb0C3A0iZ7IOTsUFOpFQYSgnw32qnLasU03b7UJbDTNP2OND838Hox+dwAM2rBFaX9W8FgKZskIDHWXvetEsAjJmO53pb20IGJa9VffvxUebq5WCi08rdAEDIX6ncxKVMfFyndSvJG7//fwj4rMAhAAAAAElFTkSuQmCC",
    },
    {
        "name": r"MUNSUB",
        "sumerian_transliterations": [r"sumur3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAeCAAAAACdn8hFAAADpklEQVR4nIWTf0zUdRjH39/Pfe+Ow/sFRwd4kyOgJpLpCKMwaevIVuaaijNMItGOwMycgTW3hgmkxaZt6ulUJoak0qVWmjYYp5ymE0rPCyR+yCV4/OaC23F8v/f9fvsDTnZXjvdfz/Pstefzfp49HwAVPfEAgLQOrvbyA7YYgZKKAtJ8pi1HBwAvtpz+YriUCoQ1u1TTCQ3Y+w5uMt7ziYRxaRTXtFMIgGeVSd0BtIyWxYhc3a3h8Y3PvfQaEwAnbl+2ggOo6RZ5TM82uSxB9wQt2XN3dgBMlVy6mAwY0/0F8TP14ysRE9t07RPgPZsu0LX2qsuAFfbIqZSI8vTOodziiR09lYA3aES8GWIyZu8/1QekigAQb3V/HfOumm/uGwCCYKpwiedcb76tGch6HwAI7IzdtsO1mH0Y1BbyVfVrNU/uPtywaBZe+fpnDgANwnORX7YUHZ033y6A5/xs2Mt56qpj3tiik998m0U2OpqmNghweqr/SI+1meM16l5AwXmUb+SqzlSMAF0FORv+pNa4R4ifJkO/cwciXRapx6crP9niSXnHNj+65kzn5COVtz7Xl4uK1Q6Q12kAIveFg7KB5H2bOoGhUoGTRSidm6/TqQvixmXMRMepjQUfH6pZbRMy82kAPOHOmpxnG/oBH/9qN8VrblRfh7BwncZFkbFauL9qKKFvCqk7CwGVZSuw5f6PLRf3aLNuqAEgZPVcKPIjji899un6SwCAqP11W1otYTQEAFCESX87IXGTLjcAeGsAyYbFUQmjWvLPGvGdu+j97FxB971Ret1lHkDFguSnEzB0G8S/QZqyuOV3Qj3dvHUEwPKkD6PncPShX7Qe4CF14QcJ5VqYNHk7Ge1tw2tXpbff1KscT12hKAHV+tL7HSL6j+XipIQBX5ETgC+RZQAgfNfeNraVTdcgWhz6Qt8DK4tn9aOxGiX998j35QYnyxMArE5h4gA+mmRaHaTzA13tbJWtvQaQFxjjMwZPr6Sq4uyG+q5Ju8zz88wsxc8N/StFWWYGwsaImAkZw1vb0kTXMrzZ22Gd2K2l/aMtyqEAiENkqs3tppip4hzTuMCx6wGShI7C4NubYqrsuQoA4TnNgjDY2JYCAEgl/08Db181p8VlnhcEwbusZNjwOMwvXdnt72yCIFhrEV55NPhb/UfUkp8GfV3nr5gpKH9NnIkGjGydBVsdekD+WMfTivjIfItG8d6ZyUkZGg1QzjjiI2WbJI/ifwHsy2j9gaJ7LgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MURGU2",
        "sumerian_transliterations": [r"murgu2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAWCAAAAABIq/tzAAABHElEQVR4nH1TXXlFIQzLJGABC8dCJwELWMBCLWABC1hgEjoJtZA93N2dv57ljfRL00IADigJd4yI3GEtIKn/ScTnnazLt2fJ5m3WK5nWGOz5SeNrGs/T52b02ozXZscmxb3sgkXvBQBk0PTYbZbDISlntllFF01lb6zO/rdYZj/Zivmg0vS6el1c9XfJZudqUnL06FWk0xOAxXnY4YXNLFAAQK4AIBkyLteFVkLFCeVmdWoeP2rqV6sDNIgHAEDswSrV6bd4vGsaWKU6SBfq0xBifgp2roPey+KcdH3IXFLOd2lPTs1AasbxcE2yXF1F9qj9oUxai0dUcs2b4GXd3eNvsQ3vYXIApGqc8hFU/OszlgCA1O+InhKxO34Azp+eqhClgCEAAAAASUVORK5CYII=",
    },
    {
        "name": r"MUŠ",
        "sumerian_transliterations": [r"muš", r"niraḫ", r"suḫx", r"šubax"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAVCAAAAADKylngAAABg0lEQVR4nJWTXXEjMRCEv3KFgA6CDoICQYagQFhDUCCMIexBkCHIEHYhyBC0EDoPu5v44sol1y/6qZnp1rQG/oYp8F/wXfGbkANA8NvJFfezypOta5iUZD9IyGuUMynTpu12SPgM0RECxJ3cgEFTBYiS1Nv+dNM9+ibcOqEqp76V7TZ2FXwGXA/NylhabtXqrlsDJmnSsOYHcKYxqjjI3Vxrrk7Rt7Yl9HUTrHcHY1/1DCrSFPGKjIUk2Chif++LGyc3tt27QWpNdeiQjVDBVg2ymt/7Nfbpw4pR1Y16hFEjTxtJuLNuGHA5MbsTwV+wV9JtBtIws3sdWvHTTmIySaOnQjSoYHGT241DiDGV6fZyO1IduNzy6cpyPN0erf7zTIQutUke8Gq1SSrEtWsPHDAoPf0u4WVYbsByjf568enM9ddj/Y3F22E5Xmq6ACzHV9w5zPNX4QDn+QCnxW2az8+h+Mu/ElheAJL2nmG6mygPzkMA/3ls/Me2fTuDn7F/46/xBo4H7BO5A+m9AAAAAElFTkSuQmCC",
    },
    {
        "name": r"MUŠ/MUŠ",
        "sumerian_transliterations": [r"ri8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAAC1UlEQVR4nIWSa2hTdxiHn5z8k3OSnjY1iZfart6qRWsVa1fRtV6wUaMwtAi1Uu8XEHTUDq3Xiim6WcGpICqoc5vImMvCWqkNCoo3vIuKN6KNGnBSTW1nTVNPmrNPrh+M+Hx8f7zvh9/zwkfGXCQxSSkAPfxha4JQgnnlEgyrDTcXAJICmP6PLYJvKk+Zozm+wb8bi86BeX0v+/N+zWrHh2vHgWqp6rdQPJmXP59/2TL36/LBnf+UDEobMGWIMiMElOYydc0fbxcy0TdednpOXb2VPfDXwvrpe8qW7zZCcWiN8PvF5Bpnvuc2nVs2eG413GiNh9+/cUafZetlQ9pOCoj5XeurbgPiVeRC2qS2kRk5SjSpYzZWX7oQquhVYq8qvH6HQWWFzfNOLDb4PbU5T3KfBlErcrPEPrVl3Jx7kZ/Op+XbVk57eFCebDMnW1WrCu075PnSn46xvzykLrC567W/8ceDKIbucrQfDKK+tSEUo/37R+70nbwCdOLo6DpAZAlQ7QaQ6todAKYk0kypFvsnZRfVf8bPR9REQ+kLS93k1X0mMEgAxjPvlMT3V66SEFmHlPBwwGA1KUaLEEKSAWTBhGWN4kPm4YIDWvENUCqkzAdDnxk17YVXR6oUSzxvU9WW8OPeTtss74BA8P3Gf0c6HE9bspfpMGMKpet2BRcw7uhUsmq8jy6Ntnndx2YeKV+0B3A9+M4AzqK1vry9l8GydsNVc1PXlTl/Z3aa5ZuxrzJcJQLe+PLX1VwGOoLmc3mlAUdft6Ip0Qy9f2NIIyW59yrfiotjEfbVZwPtewu+7bNroDu7ZJTJpG5smya29hTjXffbNnnTJ+QsndW0PbmnFtdisVhMQ9tmWiTd6dtnf5DT4cMjrL6G7bVIBro/oNYmjr6oPxThdUUgy/SX3gTxaJeOkIQRIFIJotoFIJ9sTQUwphj7y3aLs9umbAag+G4iOf8BO7X41nEHvEYAAAAASUVORK5CYII=",
    },
    {
        "name": r"MUŠ/MUŠ×A+NA",
        "sumerian_transliterations": [r"erina8"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAADaklEQVR4nHXRXUxbZQDG8ec95y1nK22hLbU4xpcYVwKmSPhQGCkwXKiwgVGZkSCRJUzFGmIJRmAJkQxJppkJzBFhbCoJMqcMQRaUEUfGnKDbgIEQtwIT2IAOVottOee0xytTL/R/+zx3P+CfjNfwP8lVAKDqcSn/a2WA4lIG2NPk/mMvACIHwAIEIAA4GcUzVT9w7icuGL7yZV4ESGWE6r7+T5Y+nOsQgLdmmOrOFVGF1Y6R5fVDaUVG3/zBeF10ViIxO7xAZuYSnWhNKr3VHpfWcEVe3sDqSy5931XcHH//Li768OTJod/o4CDNbAxK/WAMnqatjye/vOHkHU57EHcnUnh2n3NIpIA4tK+2bgwAY3eOBeQ54kLTqSBDLmTjfACoguqeD60y/fwrIl/av/Ly12XMcMU57YYa14E3X7zK0JOKjbSS646PfgxN1FsS1lqRo+AUgfyOmNVlwyfI/5yetxo6pzBgOtqxrtXu3HN0LcYjAhDiU2dMh9qMZtr38LtlAe73ZgsiFxuXul+RmOZ0SZL4VIeRS7hZTQDUHgQAdLljb51CoT0rPJuRc+ba4wU1HTqAAY59CwA4MbzYN/ao5OatrXnq5OCzmt22CUsYiJ8lUKyy/d7D2QeikpYmK/kzo+t8Pt/I+A8EhPulRjgxHj0VkqAjD9zjc55kk/8Q30Ug4fzSF1ELVfkfPgdNdql1q3yUAoT4ADDHchUS4Jv2nGr5C7ezC2YGDQ86XWCANyoZsNGtmntGH0Ao43HvkLFXxNUweZtLpqTIODIk2w5r29vm2b/GAymWWFu43aW8a15+GyjbpK81OFTK7Y25CE1QXvMuw+w31fxasG5lscz6E5DyQgV1NesLC9tjA9/pjyoxRZRY6h/rybiWOj9bNOBEYsulBdqNkMvvqpNbRrDQZDkwfdzmDX183ROjRfG2Jk5+Q6CAvTexpmkEgGCTj+4uWtBE7yRgiJaEzE/7AJVSX9F75KoJVP365Sl3e8qBiPqE7KeycmQy7vBmOWj9I6zJPGGvidmV9vThrP46NkfwiqIoSgJwmhT00slXyad3MGw+3avov3DznjeAEL/PmYwkenax77MtbFpvx4afk+YByS0ALMtSAPC+TwBalwsAsu5tPQAwShouD1YEq/2KHAcASJ/5l6y/vwHGUVJAHalxRAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MUŠ3",
        "sumerian_transliterations": [r"inana", r"muš3", r"sed6", r"suḫ10", r"šuba4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAYCAAAAABR+svWAAABNklEQVR4nHWRbZXDIBBF7/bUABawgAVWQioBC7FAJSQSGgmpBCIhkQAS3v4gCWnP2fnD1+XNmxlwHgDnsHOghTV1+WH2ZVmsN9P4Mo+pEWJ5g3fgstKcpFXKFwl6KWtVAjoNvaQU1uFKMKgza7YAUVFSRPGDYF2jqkkrrWZQUvgkgpROvR6CmoaxVeT808kDQaePLvc1PXADKACMY3cQU/Hrq1rgdkn+NOd+W0zZDsMa8Lvl12GMlN2Z5U2Ydz3GfQJYNy4HfC88Bk+3P/V7/RABR1wmguj0f7wgalbWXoXJsbaq9iMKICn3h1OIGSDtjamEsqMRVoF2rLU8f0/XwDb10C1vvqJp4OXt2cQo4P4Fv7ewlfF6803wHLYPoE7uGlOxjShNo1kr2zkyWA6ilGuaVlsB+AM4PcTHOqQM6AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MUŠ3gunu",
        "sumerian_transliterations": [r"muš2", r"susbu2", r"suḫ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAXCAAAAACgrHkDAAABOklEQVR4nIWRW3HkMBBFj1NDQBS0ELQQFAgKBC8EG4IGgg1hDEGGYEGwIEgQ7n7MK54klfujUtfp26+O5FmLdaYZVopzdAAg8orxFlzVljZVO6mmJPVXgEHatWsDgiZSdZit2l6RuyYFs1cLEBU1AFaXmnhq36M8AFaq5pr1qAHQS+nhd/V22vms/ZEQbmYcikAU8AbQ7qGc+aI3DV+DR6LE6Rdiod/8MebM598JPuJAuM1NBIb51pgj5oVeBP2sC0QlVYV68d77LcIke5j25HH/SiKb2MBiYp/LoauTa+/Zgz+PQLKJvL7Mcv6bgbY4SfKhvDdeiLEA2ND+dF234u0LwOn6tMWmAu5MKt8T+GXOkBjLZMZviWxDAJuZmfyj18bttrA8Fz3Pz0Plu0crtn00wBZgTHeTBvAfIOm5rfOpPEoAAAAASUVORK5CYII=",
    },
    {
        "name": r"MUŠ3×A",
        "sumerian_transliterations": [r"part of compound"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAaCAAAAAAcMmrdAAABXUlEQVR4nHWTW5HtIBBFV03FABYYCbHASGAkMBJyJRAJREIiASScSAAJIKHvB8k5yTz6q2k2uxdNAZfwhp8xEE3ai9Zm/1xNuezUkvamRwNOesQqoi6K0MsV8OJtFqkhr1d39RBrohiAtU4iYhF/A1A1OpkAGEWqfUgQd2f0UvORRvEQ5JsHqh4W4MQA4aWwj7HDnujm4Mmv0zV4jRfgLY5P11nbI2v7P2v1ORhxpwcxnuIoDroHQcTbQ+HkOKc6khdgaMwT9Fal+aWDUQygMKXgBCN/R2TQeAdz6u7rsoF2Y4JWRq0/CkSR4OR89pABlR91DTXnTiqXu8AoFrTUrMh17PNIn8tl0Hty4EraGnPZARg+7m+xBd3cQiI33Uf8dhewlMmqGfga9337TcFmp6UBaTFfv3owK93BttSuivRUtHQQnuXhuwdpv68HgPR+bXNJ9bPL9Z+8+tF24D9CuuMf7RpSTgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"MUŠ3×A+DI",
        "sumerian_transliterations": [r"sed"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAYCAAAAAC6zXDVAAABYUlEQVR4nHXRbZHkIBSF4XenxgAWYiEWWAlYYCTQEoiERAItIZEAEogEkHD2R+eje6r2/qKoB+498Ic4lq2b0ZZHDI+Jq1Lfyj5Y+4SoV6VVGm5BPvYdMCuGKqnW/CYYmnxY5QFMrkGSQ/GdMGq2ml9rp6bYmlf4IMzKzRzrqpkh6zcZdN8b5MDke8NGA5Du+a0sYHK+z1dvDVEARHMSnMbTrK7JnUR1PAl1vkibDSdJau4kQWeAluAiUVn1IKYdA/vXnAfxwuv/leB7wAZY+hF/M/TBmDJOjGCnDUhSjUcjWFevWnNrCXJrr0ZN85UInMZZtqkafDRRAfgy08/bmz93v5SRaSOyOxj8x+ueudcqSYGYV8Xk+eKzlh7s8HffKbAVHnt0v0l/OrbtuS8enCX6I+tbIwbJYSN+tiYqGc5G5SJ76U+ApbgOP/0i/W61HXwpydOBb4Dynns5v3s57v4H4tkD/XkUD5cAAAAASUVORK5CYII=",
    },
    {
        "name": r"NA",
        "sumerian_transliterations": [r"na"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAeCAAAAACKvViMAAACnklEQVR4nIWTXUiTURjH/++7160lalmZbWl+UDOQUsHoQxC1i/wIDBItRTM1PxJHWVRDvZhkZjeSGuhCofAiKQssIieG5o1ZJjnxKz+SlQu3dGvNOed7ung3P1jT/9Xh//zO85znPOcADjrRdAoAvGscQxsUu9ggBHhNBmZz7qzOnEwJkqym4HWm4x7eEf2obCWg8HWUt2qzdCJlb9U8IeOnZ2vXuZRj2Wb8MCwRLzfx3PFJ51yQwn3o/ZsV2jciIkqZp3NWNVCpCk9riQEApKge7VrtI934kqxhfvXi9L7gQ/fVRmCFFeWTknkbV8melFns2P5GUepnEDfDr8FlAJ1eUt7tBS6kJKzC395q91gYgNLWUFebk6au9eBWMnMfeXcQAODd0xUCANe6Dq8eJEdf7QEATD9pqbvX3VE1iNA6XY4GACZ+16hHrRQAEHo6f6bWAjCfaOPT/tKkuOedWX7nNQAA+oBIOzfHdbesKS7/0AfAg9QB/HM9piWWdedqFSjDBAyP5rT3LXm2B6Bp1gAId+wT0iYEcNzfJYoQ+2VJJI0hT4JoJtDyXRgpDwfaq5vjBwAAE/7KF+1mblLmOJcB1+TQDCr/gdynUKUVC1zNYo3EAAAx0qMzHSYKAKxeF3wXdZPTI2hYVpO2EMAnsvzL4l0aAFI+pq6Oq0TbdnknAAwRczWPMz3LpjJpAOmKMBu2Xa69bluSBdm2tVudyqaAmP7e4sT4hITYaLm2yJ64bPbx2jNQ4BavHpY/kuxXeorlZ+wue4j/68pILs50yYIB4MZPqRMKoHKHsw4cowFAri+inXJg8oYzAQAVxqs85xjALxi5BKBiInGL/ysoHLvoUvktenMKgED6dXB8awzgS603tyjKibnT6rnR+Qfide1LPAHBawAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NA2",
        "sumerian_transliterations": [r"na2", r"nu2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAZCAAAAACJcViHAAABqElEQVR4nH2TUXUkIRBFb3LWABawUJHASCASeiUQCYwERkJHAiOhkdBIAAkvH8n0ZLJn876Kcy5VRVEPDq2b4xc938NuW/w/65+OMK7dA73T4ErvD6DVg3S7m2/lbyfgYnMGtDk7vdMmvrqDzPH9PHW6AiGdAO8xh+E9TMf1Bi4KgCJAqA+Fl6o1qx7gDs5L6Qfp89iTg6Sv10gJ1qIhScd9lqoSPm/oK2OSschLJYaQ6kM6AL8NgKzFBkEb2u1W/Z4O8EMV3DoiocYxMhraat3q93QArqgSR3WQhpYakWqOq6Q18Kgixu6ArEwNaHgI0up/gLiBbSNA2kepGUm1VElal4cVcJue28ulZlo/WQDobbbL9emlp73EO7laA7BRTLh9oOGOyYcyRrHjZwYAthcZQYu055zLbfJx1Z4/WzYdbWTI5Tale39L1Zb8ncTGDqBxTP6QT5u2PMafz2M7bekMvLaHF5szDMOM9kXS3lI433bQBe+d9x6utNbObbpqd3dsxnu8TCNA77PPNr8VcHd3YHV6ro02f1joX2Wtv9n4m4u5vM5fyA9Q+w3OWiunlAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NAGA",
        "sumerian_transliterations": [r"ereš2", r"naĝa", r"nisaba2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAdCAAAAADj60EcAAABkklEQVR4nI2TW3FkMQxET4WBKJiCKZiCF4ID4VIQBVNwIHghaCCIggaC9mMyj2QyW+kvV/mU3N0uAcCYwFaA4pUXqtlBdwwQWyZAH0+U2AZNXdHFQsME1J+pHLJcbc1wV1eLitv8ShWLpBxS3UWVI5Wu6prr0eSI1R0orsuEESUGJafqzt1uWIS0DS0yM+3IzEy9XLWVfk0i246gxlFsFcteszfTq6GZoXI5a+ZQWNMOQUKjUu75NHKWK6cyc1tq9dgRXwqW4bkA8Cy+h60ROUeOGY/dyuFpADNTB4dF7QfbN/WOtZl+CCAzs3dGzh2VGRpTbu9Zrksp1ewI0FxzWlrstcNKG0KZ4XoNkyFtU1cR3+iWlh3VGpa5+t1hdesJsNUUahxRgW85QFakIPtSSHwWUq5fcdfMUXz11obnbK1pDHD5jrFdKrQuvUNvlP6EAEgosDJt7/ys/KveAM5/AN5PnBFO7z+OuqvEwuLlxtw0cubzqjzL82lTHrzd9MHHb7ATf3+DnV+5eXt18f9pL+b9A93sDWBlgEJxAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NAGA(inverted)",
        "sumerian_transliterations": [r"teme"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAdCAAAAADj60EcAAABiUlEQVR4nKWTUXGcMQyEt2WgQjAFUTCFvxBEwYEgCqbgQDAFFYICQYGwfbi7zp9cbi4z1ZtnPq+1Kxn4urZ/OP58gH2q/8REv3O7sb6jZpDjuZjUzniOTfZOf0Y5c++iAdDHsJK5N0kFWo2v2zLI0aAH+hA09bqPxjta5uh9FL337mVgyieqlQOyGMHRq3ZVB1ZW//hejACANWMAWpYKwLedTTcvVrmuLjnhGwcPcYdvTN6mcOzUlx+/fr//edv7rYVJ9tce/RV4n/ZyFcrydpM1riiVWV4hzVZdvB6LYf/cNINl6jEQEdIGL9TKmudkWqTH9KIbbdImOwB41WwnDDIZQdOqXaWtGHKJPblOyQjmDINojVI0XxVXGdvcdqW0XNM12Q/2Hg7fs2671yfzakOTJJeTJB3wDec53XL3HJCwOQErK7tModa5d689U2fTCjGH03EY5mXxTqWZXSZXzMXaTo9S5P0mjQIwOFepRHmGwHj/d8QBwKM6IDFDIPl4y/cAAKUCeun+L/baCMc7JwmHAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NAGAR",
        "sumerian_transliterations": [r"nagar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADIAAAAYCAAAAACdY/E9AAABdklEQVR4nI1UXZkjIRCs3S8GsMBKYCUQCVkJnISchF4JIGEioUcCkUAk9Eioe0gmNxP4bq+eoLoKumt+3oAcPvGKUDFf4aI/zl0NQGYakWZsrCMDUGm+Z5XRWXNDh+O5Wuhp08yeBgCIRaFJd56Q09gRSFKVJi/dOWMc6QWTTZaltonUvWSy0RhN4JyrrZIkJ7ZtdqKpnyXfEwkt10lU4LNt+hPVLv5MWRfJkw6Ak8YcACBkqpC7WFy2NcTECF2fWlJqisqqGlm3sYTaEh/rSGDS52GxkXaCaGSMjRv4SOCw6m7rqO588mVJOQIOIfrlsjwqy0m/sblF7rf4bCYOcKlRhfsMIc9ZnpaYN5qsyunlpUgUvG/3qv7ro6zbBShfy95SSnKH0/xgffPl87oTHNHhV5BDdmUG3DmhlFsv6T0RkUaSVvW1KB1zx/t8Wd4Kvj+GH+zYgtlLwu/lZ+lfywXn68+6DQ5YcDsGYP7/zoA6+MH8C38AQa7jBXXc70cAAAAASUVORK5CYII=",
    },
    {
        "name": r"NAM",
        "sumerian_transliterations": [r"bir5", r"nam", r"sim", r"sin2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAACKUlEQVR4nI2U3ZXjKBBG7/bpBEiBCYEJAYfAhEAKdAg4BByCHAIKAUJAIaAQvnmQbfn07M7ZekGndFU/n6qA/2HJAGUBwHoA491xfEfLMFCm/QTIYe/dWsfacZ5/AOreO8a52z3FXzspXjcATFNrTdJsVUoANEmSpsuqmEUyjyx2VrJ8m8arHC4zFP1QqlMpzFbGq6SoqIydZbx8TiVqzMVoUSXXs/4hGShSPFvSGHUG5LPyO5u0AE5nKqyUSDMr4upZL7gj4FjetFpkwDYtQFE6M8oD1PzG5vEUyUNR/ajuu/SnbQD7ZbcdYP9wLf43DGCK6cYs8Xr9uFOy+Rtaw3qxzXPrnzvXlG594xiG5zTs/ThT6r2XeF3rBkF4/cUSM81mveDTkRP3+16/OpD7/aEBXwT3ZXJY2X6UdsPsVGmxf2gW5Tn+a54jQ5iK8JwreW+g5hCBqMaDxc8BuFkTNRyRlGWhlhkhaeYXi5ujgJvzpY2UgaqGrTPUeLIUBYha3lgDNAWSMtWfbNRiyWovxZsKmCIBceaaXmyRjF2mIh9HSY2+45q7rsDt4r19BPEt3NfYzE+2gw1tvezdNi4H0C/7o+NY9x8b3tw2ONitO4PZfpnnRO4Xjsd1dQEuX6XwzGSWOTLYNp7CpGmOesMcA2x77iyQ1I4WnzdJerCYJgemTfuCixxg2tsOPjQ7fKa1802tAFbh5QmP8u3MgH1j7XQA8V/WxB3f/wbpx3Pqb0EDJQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NE",
        "sumerian_transliterations": [r"bar7", r"be7", r"bi2", r"bil", r"de3", r"du17", r"gibil4", r"izi", r"kum2", r"lam2", r"lem4", r"li9", r"ne", r"ni5", r"pel", r"pil", r"saḫarx", r"šeĝ6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAbCAAAAADNUln2AAABo0lEQVR4nI2U0ZXbIBBFb3LcAC2QEmiBLYGUQErQlsCWgErAJeASUAm4BFTCy4e8tqXdk3i+xOjyeMwAP3ghfOWy4Dwk+wJeNHobSozh/k+bNqxXhiJNX/9mAz48Ela5dgNJTX0yezrJQ1J6ZPImGkTU1/DgpHJX8RoGTg4/sc47H3E1BhaWEOZ5AeByva5AkXrcGQljuJGAnlx9rJaAk+f8Z30WLp6ZS3gHS3Asl5sGAM9bAYjqkqSIk5Tv3agHbpMeSpipa5hJz62oCfh5gCvA+vHr3SSzvi0HrdOODYm35AA8Z9YjvNM2LZuLW7wF58GmZo54ivfPSb3ealUlb6Tu974pyrexG6oQiuSjpECvXS3aZ3qS6uZ09DYAXBtSU6IWkw/dWZhDu5yvMSy/QzIrLHPm45rBnlNkXq6bYwC8vN36oZKVwCSpGqtmv+lOUBrq0fspNUnWj23RrqTx2OSNTlL7TPqsJkktBbJGe75VG12Vn6oaS61DkkbV2FX7pv3NabGxfFbhHuW7U3WfUKRX7vdn+H7w8u8wTeV1GjeOb8dfufg3dUsYNbYAAAAASUVORK5CYII=",
    },
    {
        "name": r"NEšešig",
        "sumerian_transliterations": [r"bil2", r"gibil", r"pel2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAbCAAAAAAfAlOuAAAB10lEQVR4nI2UUXEjMRBE312FgCjsQRCFCQRR2EDYQJhAUCDIEGQIMgRRmIXQ92EnZ8eu5OZLq+rWdE9P7S9+rJyOuRwGpyOLJXz5AZ+ipLHhijFDnYj8PX506gSaLMVINGm7R9UEVoBlyEc4kGavWsA1NLd0S3AZuJwctau7ny9VgSJW3ZdBllpa59xG1LMZGTxlbGN/vxG07inBiVMp72++PPfyAuyHcgSaNNcbRSUihwPTc79p24En4/CyXz/fjHeO5RUWSuZ0JO2kHTiPU37rd9WUJK1kSfU6Je+Pxh5y0jYVadOXiLwDv7/gO8D+9uc1edqfT/cvPt3Ai/PsGcA4sD/A33RIo6ZjPtkC2WDxmh4wfP08bppdkhy6ZEkaNybOppvq5TuHOpQm2SqpMPtUWy1PcvwjbFI/q445AiCPkIac3lK9Cw5TDfXVmsayKQGskq9yplepSSVkZmb1QrDlHJValUNyqadFY5FUS/Q5R7/yUOShuZptPiQtFpIDU64wPLaI7Zrg0rCLbasakjS8UBUjAyWmRVwRuq6nvbbeQ5KiK873WSVHuerwZfkAlrVd8gDYJusE8PYgx09O0+fu2cdmf182P0T9b6Wh7zQ8qBz3PyD+AqH/dhXVJIlYAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NI",
        "sumerian_transliterations": [r"be3", r"dig", r"i3", r"ia3", r"le2", r"li2", r"lid2", r"ne2", r"ni", r"suš2", r"zal", r"zar2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAdCAAAAABz+DjTAAABHklEQVR4nH3SW3XEIBSF4b+zxgAWsIAFKiGVgIVUApWQSshISCQECUTCiYTdh2ZumWR4Yq1vHy4HgNjzZmTlIzoBJP9GZ96sXfuowR3UZl9CiVPadW+SNExSvxPoNCUPuDRIXbOtDfdpO8leAo/ZXGVdOA6EXFXzNeDaCOBTDNetYmeq2cMHvsKI9yxuGWdiuHwBTWxcuQBJ1g9VOZgmTbJ1UT9IAFlNUA9BHb0igEu9NLUA1DqYA7Ja5Rtdnybp/xGdyVzTPRKAya+NM1N9IA/QVWC9yFMrVLMnD/9NWM90H60kq1ZlORC3ymBtZ5oa4EVP/Li5uPJ52ev5mXFJcVmWPeQEJZbfXVt/7PcBcoIyjkd63lQuWwXmm5Un/QP9zafKCtz+sQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NIM",
        "sumerian_transliterations": [r"deḫi3", r"elam", r"nim", r"tum4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAeCAAAAABPz8IdAAABcUlEQVR4nJWUW3nDMAyF1TIQhQxCKLgQPAgehFAQBRWCB8GFoEIwBQ3C2UPTxrl201Os7/zxkSWbqAlBR+/iPF8Ob4FZFCC805yab/Zr4Mt9U5f4difiOLNjCL17vwlkwEsF8pSKY8plC2FD1gzjKVMBmIpohSVeEZ0blXZ79SzjoUYFNC6JhILULqU1kAxVFk2p8GkRgIWLThbW2Jp/Jm/Lf0ZUuL4aU2xqUoKYrIGZNXF+AYJEuy3upKIkTtCnpjMPxEczERUOhBEYvDBRWNY8d5ZdQCPgCEQUcKCn6n14AueP7yJEREc34YukNZC8cH9QQy8VMHTjDkTXS19+aKeGqNXi7fN0p3ZW2Lxu9SGqo47Dq7U9SS7tnDxSKQM2vMaTXVrbbIhN2d2QARtmBxFnAPUOlDiqDcgbV2J+MAEAUDQbXDfUK4AyIGJAXl2dHYAdmc3TjnoNUKduO2/GI8pyGgTYtbMZEfovPfV/eIvpF0k16GFYlugLAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NIM×GAN2tenu",
        "sumerian_transliterations": [r"tum3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAeCAAAAABPz8IdAAABrklEQVR4nJWUW3UcMRBEy2bQFIaCAqENQYEgCkOhA0GGIEOQIfRAUCD0Qqh87Eszu46T+hr1qTunXxIwybjgO73uj+u3wE6d1O88L9O3xLvK2/bUV+RzAyTv0nFqikhPgUZGH2S7h/IlFPYMEWerjS4v98gCbNsJosv28X46Eov//tHTlHCNZpem5kq2fCQKO8t8tDmB4gw7MINxPygphxRs0NcpKD79s8RcPgAINKLPqXW/D6nQ3PZAN0YUsVvXLOQGGAsOI66xItVIMgaDvkphvXoWD4XsgGVEbwDSSBqOXElSL8AaXQDd16xqUUYgRfIVkBZGXICgAlDioDTMVy3RFBiR9AZIowH6eBNSONNSqIBGzzcAKNElPdnrHIMNpskG6VzOwCvw/pb6CfIAnH7JJjU1z58/XzbMcxePYQ9ASmSQ9by8dcydlD7vyTlUGhlhdnFJ2Jy2OPNU9rI20tdkOdrVlXcAUpA9X9xOtiIAsq5xd+0boyTJXpszarm2QGfPoZONNPPj1ZGvAQk28Sj4UsdZLTX8izfjrH7cBiMfbvJflVn/y4/0D28x/gDLbx/LjW/7twAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NINDA2",
        "sumerian_transliterations": [r"inda", r"ninda2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAaCAAAAAALEPoUAAAA6klEQVR4nI2UUbHEIAxF776pgVjAAhZ4ErDQlcBKwAIWqASQsEgACVRC9mNfO30fJdyvMDmTuYQE4NTKkTApYu5ODYDHJU4oK5V8h5bl3zFro1Q7TnrkoXMY5K9auU6SgO5eIPgA6F2laomTBQDb31LZpew5ouykf81tt/70iIqwZUC50l6S3+6m/fpzBijFMfrz2o9wbyMQAPpRmEKXxixyXQHA1BoEdGl586E10s/ROH5ZUq7lDMBD6i9qt9N+3Ql4Fnp2UeBuZlnLlYMRb/gVW1P5XvqybwZWqy3fvt414Zn97AeRpHX7ADCgeOafHlagAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NINDA2×GUD",
        "sumerian_transliterations": [r"indagara"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAaCAAAAAALEPoUAAABWElEQVR4nI2U0XGDMBBEX2Zo4FpQSlBKUEogJeAS5BLkEqAEXAIqAUpAJUglXD5iiPCMSfaL4/ZWO4sO2NHpKPwTopq9OSG8Vc8TSydLfEVdmkMZrTMmbZU985C1P+nX6HQ9MMeTOZvDcdQ/M3QjyLzW773O+TmUSacWoM1zAOgeaqo6zkdys5Q4shSxny4ClN4NBbh1w9VNw63ivo1GuEcwfklXwPWSCoB9L0gvl/RL1uwPfv3qHuYAaNfulxv2OyDTCJitnjaJPZ3muk+VJEB1JID4MuxF3oSlzwJ0m8wE4OYq5Cb69jYArudeALyNC4CABPNVndOkeA99SmIv5uHEFvnhdn641H4aMT7FCAQigC2fCSBL5uPJ/Jrbg9/tU8lcp/UDv2cWdKwbTk82qtfs6vrsKre6au/OFq6Ctm7V17DVvjlaa+4xvZKqG0E1/PcHMa1/LOY336evLm3cPKwAAAAASUVORK5CYII=",
    },
    {
        "name": r"NINDA2×NE",
        "sumerian_transliterations": [r"aĝ2", r"em3", r"eĝ3", r"iĝ3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAaCAAAAAALEPoUAAABe0lEQVR4nI2U3ZXjIAyFv9mTBmiBLYEWmBLcAinBWwJTAluCXQIuAUqQS4AStA92snZOkpP7wo8u4kpCwB1BJ8OHMKpttG8IX4d5pgZTl1fUejktF+etXW8r905D0/TGfkRQecq0Bh7DcC3uljNGLToBoPEmoQhALHfnfj84TWIALsvo/s7AkNYZYCXXujv8Cv5a4Y9cO8Cl9mWiduO+/QJgbF8qgB+7rUNeVugzABdrx3VewKbqF8DO183puJpQTa8VfN8u0jae9N4DzS62lAxA3vZ+/fz+2Wb9e53u1JhXt66m059lEUgTECcDTlPSKBq0DN77shNa3BNqUjPA0CSOLUecikaRknNuO3dSCQBeJG1jKzlrG6S4LM0f9BJzaCq5aIgRIIoHbGqqUtpWlxs3iZTovfelRDjVOJS9qGHfkDac9J4w6uk1jXdC1OmRe7A+pEy3SD7BoKLJv2u4A3Twoq/hDv3mGZydl/WVq6MhqsZPP4j8vN3+4x9+N+AzuH9zYwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NINDA2×ŠE",
        "sumerian_transliterations": [r"sa10", r"sam2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAaCAAAAAALEPoUAAABWUlEQVR4nI1UUXUtIQycnlMDsYCFWMACT0KehH0SYgELVAIrgSshSMiVkPfTu91e2m3nC07mhJmBAByQaIRfgiJ8SxeEl9O64yZ027+j3l4/bXfOKc3Hjq80eNSL+hkSxsCHvSuj7ApgMBEYBTQWn6GPNsMA1I7BqtzR6tKtRy8AUHwoqIaMLiEuLfLC1SYRo4/ImtFr9+bdXV37qrINM805izUFDVdvLYrp8LVv+HbSS0PZqIs0Grpw9YiGegPIUs60QZDsKrTaAOhxdF0y80djqk4AG22FK3XIaq6FCQBkswpkFzF2riohz9QX5TelOYn/JvyT7T7zpHTDnfBnPnFfKW1z3wEodmAS5iTcaTKeqYB5Oell32SwU1P+4t62IxmNBhSDFqnUIe2rrB4ZhWdAjxesF/NUwqLmq4E7IUq2+B58mreMwultX+2/41zQCP3tB9Hth8H8D0+Lzk9alTHyAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NISAG",
        "sumerian_transliterations": [r"nesaĝ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAbCAAAAADTm2lFAAABNUlEQVR4nIWRXZWDMBCFbzkxMBayErISBglUAisBJAQJIKFISCQQCUQCI2H2oS0NPVv2vuScm2/+L/gsL3MGqDlBsKquQVWrE+YqmCVhOssDVu90OUXA6xY2OiWCbqr+hGiD6rqpWgDub2JVDduyjAsAs/yUfY8cBaCGkMnNNkEAmOibmHYm2zbCUZbIA8/d3TTou2NbM3hw6LeJn45xrj8sae1scgkC2S1DwiIFkxpBwkFmAN+O1s+t54NRNW38vhT66uf9U561QFSGUbH7/GAmcHusFfGmyrapLmtN6ABY4JWvYsplIDXRAaDySObqnabX8ESDHd9uaIh4eiHspIP4nA+Mk7owQkxAInblfUwcyi3Xj7ftwHvTl/dBn2pankXg6k/AvbegYQynCAA76r8M4AOAX9tSg4wRsMWhAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NU",
        "sumerian_transliterations": [r"nu", r"sir5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAVCAAAAABwadGAAAAAzklEQVR4nHWSWxHCMBBFDx0MrIVaCBKChFqIBZAQC0VCkRAkJBJSCUXC8pE+IeRnM/fM7tyb7AkAJ0nMY6R6nMYpyo98KsXTXd71Rmi1r6hNUcd07OsEoEkuCnBkfrClqmYvBL8h6dUVQzd/8ZanGdMKrXmWVGdIyYilXb2140vMPF6zRreN7faBo04drNAdMmk2bLDXnTG4lSHBAzLMNr9O8CBxMgex2a4mck1/oA3vL7Y0EXL16UuekIdfef7PHnv9swhADBVxMXSv7cEHpyRSZgoeQPwAAAAASUVORK5CYII=",
    },
    {
        "name": r"NU11",
        "sumerian_transliterations": [r"nu11"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADIAAAAeCAAAAABLOhIgAAABmElEQVR4nJWTUZXbMBBF7+4pARWCC0GBMAvBheBCUCGIggLBhaBAUCAoEMYQXj+cPZucxo0zXzqSrt48zQxshSk/PnjfIkLZOtlCYguEzQweSkix+gvM0CRJW2YeJeU9MnbJ406J0TUCoXnbyWQ19WRmk4bZp11Erpq91lp9pOgpE2dNxKvxXCBrsz4Qx5y7lIDuRZLUgelfpl5/MrjkVRWgyCczsx6B0dt9fd5DqgPAcjhyOXEEOC2MZmYYsPwe1hs3drvm1WN0KQAE9dZqra0Cyad+99lvKR8sfSmfDwDVzj8vEPz7ghWWuBy/kG+BcQrH8wWImcsvAE7DZTVgf1iWU4JbmSpfRUJ2n9fEiFI1M8sFkvJ9YujqbehSK0rrbp97Gc2Sw5RbuyPePhchgUWWHwtAHs/jCYgf51gvHwubMWRfXxzXmlLy5OXJ2IRr96rNXmvt/r+G+WSqJmBWncysPW9LgKIEqQcIZVfzs3bv4GB7RwyYNJuXKu0mwCT1tsP5TQyz5vyKyJqc+msE5HXcXoo6P97/C2OA9UE1mVwMAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NUN",
        "sumerian_transliterations": [r"eridug", r"nun", r"sil2", r"zil"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAXCAAAAAA9oXCLAAAA30lEQVR4nMWQQXXDMBBEf/1MQBREYSksBRWCC8EUVAimkECQIFgQJAgShO3ByWvy6qbHzkEH/dHsrN74qaQtD0TzCUO6detmegYJdiHacjhXISyE4Pwq6ALRFrvcY+pu1s1qt1otgutm/hajNW5Va9xSrOsFYLP03c9c6JG+E00AxBZgBqD4kV2hQKEAFBowrQA0BgM4jrumdTvdBoC5SM1DfISgnuiID3CUoM07ARkOccjD074rxASmpITacW0KzPnjqcPzzPff+zC9YP8Cj4+/Nrg28qB9vnLfZPpX7BeXHWZwpwgAmgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NUNUZ",
        "sumerian_transliterations": [r"nida", r"nunuz", r"nus"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABfklEQVR4nGNgYGBgYGBwXaHAwMDAwMDCwMDAwBKUIMbFwMDAwMDEwMDA8NdF/X8eM5yrKz0vj3uqEEQfo/P1HGYGwVXrhBgYGEWVzbNmvPv80WT+pL9lTxkCjt1oZk+/fquDkX3ifi0GBs2HQQwsdftFGBjYlp9m4vL+9JHhz4cXnxgYNDn2MRV4soZxMzD//MfgMH9LDQMbm+6ueTw5C5hsz2QxMDAyMDAIzX3+VuZYav12iMUM4jtf3j7hAXfzqztiLBN2MMCBcNsjJYQX2KUNn31DcMUXK3zRR/hXknHrh2qGnVCdZkebWRnirnoyMDAwcAgkX0q1E5TXTzjpycDAMO/qlWK2GZduVDLYX0xhZGAuum7KIL+7U4CBweFqEhPTh1c/GJ69evOBgeHVXymW9VJf5C////2bgcG0ZekEBm29nrO2DAsLGJwvJEECM+Wq27xiiwspMCennzx38qAr3AeSxx+fD0V4iDd4/1RehJs/r+VU/s3AwMDAAAB+SXdJM3qKZwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"NUNUZ.AB2×AŠGAB",
        "sumerian_transliterations": [r"usan3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADQAAAAcCAAAAAAL7MNsAAACHklEQVR4nI2U0ZXjIAxF7+6ZBrQl0AItkBJICUwJTAmkBFKCUwJTglICLgGXoP1wEnuykzn7PrAkeMfSkwAASJ47fNvsHxF72Eg20n9xhk6b182K+/H8L4CUjpmPZY1In6+J83V+wZjXjaICVWUNNmsUe40Gb9HH5aPO7iO0wwLksDj118v1VW4z4CZ11FIgqQM/mtleln3pU/YQygRiICZAK4hasnuiAEM3WnwkGHtzYECtiFrzZcdhMtv8bFMppoIPVQVDpoqo2lOPipVhUwordLg21nYk9Saa8arOnjqUzcex004t33ZSN03EMUmwJ62KNdMsmzvudhxTlWIZQn8i9b2U4K3u7NS7B3J7Io0vsoAV4DeAy5/z1UVAvky4FP/nFLNDYhIkfeFnG5U0VMhfapJhZjbs/nG7P0n8+MN0OaD+yr2CMCLLkeN8OS3H+XSa3zntZthpAqqKtBEt3qNmGeo0BK1dZEztUROljpx7U5IK1dbgqptNwVuFZAXK2nYrwNupLie8P3KmHd5J6RxPAMzzNcUZKYAUBFe27GqD0AA/Iqi128C2Jt9dqwLQVIXQwPcAiI5uIwDah9XYAtC4L7eakKISGr77W5+tD2vRmWmAFyRIPbf0eLiKjW/zemBaH5aSl/mwPGRbLsnNl9WJnwvEC7cF4LoasU+78VGz/rhVz+nt4MZmi+0m+XvS29qTwxbxvJ83b1n4F38BUa+iI1mAOkMAAAAASUVORK5CYII=",
    },
    {
        "name": r"NUNUZ.AB2×LA",
        "sumerian_transliterations": [r"laḫtan"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADIAAAAdCAAAAADNrmCOAAACSUlEQVR4nIWU4ZXkKAyEv9s3CZACGwITgjoELgQ2BHcITAieEOwQcAhyCBAChKD7YXeP5968Xv0rUKGikAAAvOMSxfPXcCoXJLa8Sv4FELSFb6tRfky+hO+5xifKi/XqXqQDoSZCTSeazFSsvOK4VJMgXtNZUS2L2qXs/2Oykpwu6pxmgNK7HaHTtVLJeZ4esgy8BXAlw2xmmgSkm9kS5RGzLf3w6M2lBo0dvL+T0ninATBwm1+gHZAmf/aHPzWDQaqBZJafgjMQcjdNDiD2L5VeM0ZSx2zJzhfxtWgppWvRxWyOIOXq2TJbUufmHoM9eiXbHLp6rQ7pZrXolYL0ri6oBsSOGg66Z46kDKIx5G41XR3MJWabHaR6YPUUyIJYrYt6YOrWZwHeDjemdWqfA/xhz5509ZngxDXXPoru4PY/MaW2778Act7G+ygJOG8/kFNF21e3/77dbndG24YPA4CksSay5cddco8PYTlL6JOI5G6mkz+EZbmNtnBv2a2HtG3dLzcdJOdg3NcG8BZc8h+phffC514C8glswA57o20SonOs20gfxwlvYRo3ytjGrfj773pQAO6wgpPoB239NuqpnN66PhG6TV9dH+dqVidvWUSm51PGspzNMM9ANLOaBVycu9UcrYsLcG2YnOuElJMB2ew5LwGwxUoppRQ9e59/wJVtm/5d9vuxUv24hZn1fryq8bmep+/jKdktqvoYfYJZVHsMoPTvf89TXK/TFwrWLf2Y951zRf05Zy85V1D6X36xH/jTy+3/AGkjaT78MW+GAAAAAElFTkSuQmCC",
    },
    {
        "name": r"NUN.LAGAR×MAŠ",
        "sumerian_transliterations": [r"immal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAaCAAAAAA7nOs1AAAB1klEQVR4nIWU3XXjIBCFP+e4AbYEUgIpQS5BKQGVIJeASoASrBJQCVAClAAlzD7Y0dqJnb0vcJi5c+cHOPATWuW75Qbj8pb7YIYnBC7SovNJ4kOYJiIiUp4xdJNUkjTzcOil2Lk18/aEUU/0943zv6SUjYVFd6U+M8DghmG2WGcGZ81owYkVt/uPviWrIBbxt6JaSSIikoq0KBZUE9G3bFwp7rq3Il91m+ZdssX5ZIvzAE7KqMHMqfm9O0rSruuFURwl4cQAGLl1xioAfZlnr4keOALQMysbFTIZIFPV++iDNXRjP7due6/QAWYAF0EGYmSQq6rM4sUSRUSSQpWmIDrgbfbq2UzI2CUwcZ6YOn0N/WY4Zl1yV9rBOGicYu/qeoa6DLU/hjqStUIrA6YrjMLcESAUcgzbdkdpST+tY2jXVpbiopRYSoyxXYDjNn1T3WH8BKxG69OG4wyxAsfPF/5aLZYJyPUx5rObCIDrebFRA+ExieMrhuICQwmqfjO81Ainw+Fw+OhmnDW3af+usW4AOaN1yuu6/F9jR53e17H48ZGxBgiVsFDPPzk9nD6q+3olr7C/Hfd1a4xvcvktqx9zzdOfqfO68sO+u/tRAr9p7Frfxf4CzScF4i6qwOsAAAAASUVORK5CYII=",
    },
    {
        "name": r"NUN.LAGAR×SAL",
        "sumerian_transliterations": [r"arḫuš2", r"immal2", r"šilam"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAaCAAAAAA7nOs1AAAB1klEQVR4nI2TbZXjIBSGn/aMAUYCI4FKoBKoBFZCKoFISCVQCSAhSCASQMLdH02ynd12z7y/4H7wcN8DB34oPZWSu7Hm8CKZbMmgXDk/BVUyAPRXxxl5yH8LRmne1+/BXV4mggxPgKFKHCT4NaidwlqMRVmNNhDEtbjXu0naoCG0WldgExFJbb1MACUiep041DZFAdCyc+0cYjNtCinUIQJMUp0G7aNE75K0BDCL2t0R5VpQbSaIfR6+BQ26RakeCDNwBKAsPavSS6eQAQqZ06nnxTgbUnb3LzNt1hqAkEAsKWHlQRUnsQWCiIjo2UGYVEjAcX4y8Vm9uHJlXMZTH5du4FoSAB/Z+ztGB3BWd2uwW8tygT6G3kcY7NiXPGSANNSWaktJvstODoAmAySZawpBEkBt/uUcNjX18NlAagOYGhNwLOfb60FQESBTgMuIC5cF4Hgpb+rNTU8Ken7svV8rj28ADCqPbt5sYDLn9Z1/vOswRFApF2AyabxuibeM2/lwOBxO2Zpgbn3ZG94z7o/XUkogLUX9Sbxl7OrXz7HbuP+9R0cuUDr5znJ/xfv1mX2bzH9Pls0lm9aFDlVm9ZNbbVquX5fnef7WntoZm94x+j+LTb8BRFskrqGIPpUAAAAASUVORK5CYII=",
    },
    {
        "name": r"NUN/NUN",
        "sumerian_transliterations": [r"nir", r"ri5", r"tirx", r"šer7"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAbCAAAAACsSnu0AAABK0lEQVR4nHWRUXHEMAxEXzMhIAouBFNwIbQQchBCwYGQg5BCsCFEEGwINgT1I9frXdPu6EezI2nn6YXfinNW8OFk4JsVa7adHXzbXdvlBVidOpedqDh1cqnT2uW1AkiJ1jYraytrm4Bi620+WPS2eVu9JYBoHgaAjGqvWruq3noYNgHoKFToP0FGvy/1oX9QWu0PAZQyCRZIkRRJawghzAaMenna1bM4BfDjx+/189wryctwOryokJ1cD+ezUxVVVOlvKou7XgA2S8VSs1QsleYI1powABdV0S4Zyd29VbLKtd+5OYvOohxvmc3dueVaqUrPFUCpMDR/zD1DA8a6X3PHIxKOAvw3t5JsT+3Ere2BB27xSASMy/LnC2D4z+DM7VmTMHneHe/ufucLYvvJd3B9uXAAAAAASUVORK5CYII=",
    },
    {
        "name": r"NUNtenu",
        "sumerian_transliterations": [r"agargara", r"garx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAbCAAAAABOlmDNAAABJUlEQVR4nH2SUXEEIRAFu+IAC1gYC1hYC2sBC2OBSMACFrCAhYmEl4/dvbvcbeV9UdXQzMDAmTYTn/mCnAB+8thvcasAfNP6zfmsAbDkM7x+0LktgypjWMjf8FIodpOTFXvMcQg2e+ywrhjQw5BLFWDEk9O0bFdhVy9z9gJNz0aLvCucFI1tNQ1wxTobTavD0sx9JXo4gMuG1rGMRNU2pMKmDQAfuUkCijYsnCyNHO0wzlD0PUMKhzlgTJtaR0FJGhmAvhIeGZdRpZaOq8+6TIZpx+Tk8BKrQNHL66bVLz2kLk9rvLxrjUNfZQBbKPILTpmiil3Gejb3jJ96gBR3/+6XccTdWPXtUpcbeiXH+0T8yVh36kcFsn+ofQzbn8z5H7V4U/8CtoW1tyZLsrQAAAAASUVORK5CYII=",
    },
    {
        "name": r"PA",
        "sumerian_transliterations": [r"kumx", r"kun2", r"mu6", r"mudru", r"pa", r"sag3", r"sig3", r"ugula", r"ux", r"ĝidru", r"ḫendur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAAAAADFQYt8AAAAwklEQVR4nG2PW5HEIBREz6ZiAAtYwAIjYVZCLGQkYGEigUgACYmFkQASej6ytXnRP3T1vdw6/QMAPpFXjLePzElRRSqKXGSWYq0W8x8kt72uvFNx+2LRsJkghdNhBQPgpMN6/2EaxylXqBhPXf8Gg3gW3dRbwmDy/IHA63A/SclvLh3Bd4pT3ud5unYE6ObaiulcDM18ZYy2MbCK0tvfeNDTLo1eDju4OuVrr0Eqo7nze9ZHA7VjasX0v81adLs9ffsCnTl4zV1Jjf4AAAAASUVORK5CYII=",
    },
    {
        "name": r"PAD",
        "sumerian_transliterations": [r"kurum6", r"pad", r"pax", r"šukur2", r"šutug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAAAAAAnwHldAAABIUlEQVR4nH2SYZHDIBCFv6kDLGCBk0AlxAKR0JPASUglpBKIBCqBSthKePcjSdO0vXszDDt8+3aWBXgotBHvAO/m9SJTM52ApjoHO0WpqTogWNX4il2zLJurPoInVQ1OeclVe+WD5Cl5S16iw2wYEtMNSKqlieme0hN3JfVMAJdrwPdw7Ye0tVYtRkUoGW8aoQwkpcXfNb4muANwO/MD7s65z6MH3KjBwUlAydAJUAJCtexp86TyyqMgmcOnoUk6XOj86yxOl1Ba5vJ9PEJs1u39Uaax29oflUlL/0RRVOOuXtIYN356DG9LsKq88ncMwdTW+33AEEyRknG2f/nDsl+/6QBXbv0nOzAolFzq+79br9lqMQt/Yeik/zBk697OfgH9Fqr13/qa6AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"PAN",
        "sumerian_transliterations": [r"pan"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAATCAAAAADHKBDfAAAA3ElEQVR4nG2SURnDIAyE75uDWMACk1ALtYCFWsACk8AkMAlUApOQScgeWiiB5i2X6/X+fgVuxqU7FQhW76vcG4Moo01s82SyjyXRTkrbP8kug2/NiKkkP8iGi37WsgdgIg8lN2HVkvK5Jh2wyHZE1In1TqUPMBwAJ2sT/PXGPoByJgChXZ24K6VbAhsAwOHXIX38JuenIY5zLQDpCFhka33Ez6AAlVhBrj5rD9IDUS1W68YepAPKJ0gV2JfZB8+sAeFKbCSPS/7+XvtbGV9Pg9sJMh7s+L+ckyfENn//Nmim7Y2kEAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"PAP",
        "sumerian_transliterations": [r"kur2", r"pa4", r"pap"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAVCAAAAABjvpF0AAAApElEQVR4nF3QURHEMAhF0TvrAAu1EAu1EAu1UAuxEAtrIRawUAtYePuRTZuUzzMMPABgU2GuD8BKHc+MTZQcrKh+/bEclXzJ7dQ27FCFkCS/N52qAGx7CUVvrTqeQUe4vQ1SuFlbDVK4R3oFZpf2t6W4+ty5L9zSqrnJrW8DoLTWpH/OoUW6yrjj1s2VT40wQ83jer5094banK3HLXr/HrBYb/4Bbx9ephvhitUAAAAASUVORK5CYII=",
    },
    {
        "name": r"PEŠ2",
        "sumerian_transliterations": [r"kilim", r"peš2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAeCAAAAACUdGg/AAAC/0lEQVR4nI3SXUzTVxjH8e/584fSWSpteRGjAgLpxNmhiCYugagdK6RGheiS6RKDcRqzmMFivGicSxYTk00TUNkSo6IXZhTN3LTVKOBbjIkTIThSUUpBqDBtLWy+AJX+d9EalQ7j7+o55/nkuTjngdhEIlFV5SfptVBZLYiORLZ9lSZcj+ZcOeTcCCrruoRoKYvQSGWhawwAr0c8diIXnj1k/bXj/gQptNUztFm9AQEQzPvX4qbk8Kmn6TmjfzW77rw1c1yz6Kl/kxsAxdnmBuP3zn5MC81bDZ2Xz3e9ls+qP3zi8wyHTzMbgIQyzRO/s70+PWPFF9/cueRwv7LGzr2Ok4UAmHzLgMwum3+nBBA/vbT2rvfCV9MABPNqbOa8xYoCqGXDONCQ6dw9CqDW+mSDqdiS0NZ00gfm1sqeyxYZoKpZANTdBNDNKWi4avr6diqi9MyYclQWOf2Dz7r1VgGh4n4FENmnAT6pjW/XHdFeMGQZTS9vqwZlZV6vp+XjGQFAXbQLwJh9DuDsoy1GlyFo2mMYdzd3uAbkDWmOLI2tKQgkt1wDyJcWt4JubkbaklsP8vqOd3T8AyC6Yza1hAIAfPrLkr+B5fYYR3d67thD/6zU8vKla55H3rNnaP+wEguA3v8CkqsK7BuNYtmOVn+goFaqq5h/PSKVtAedMgDjZfdHQB00qB8mTq9wAvceW6vvWm+EwnSwPEYIhIhf0+I6ODUpP0OS1w+H9oSXwnaAL5vjI1+0GpAk0P3052/X9l7yrAW2BT4PN3Wz0Fli3liTKdssucaimr4Rb0UmEnDCPpWJEQBxp1SPcocGTms3b08xHeuKS//sh101E6UMMLb/24/s9e7ZZXn1U4JzRlJTEsVw1EwJgFsLUrwljosldckan37oaJvOVh8lI3E0/tG9r2hawj7lSFLcllazPBlkpqexQAb0v99b+F2feVIHH/RawsUib1tP6TsgsasjheZn5UfVu+TrrBwo+v+GNPFioH30PaUSfTWJnDTvL/8DfWAHYqmPfx8AAAAASUVORK5CYII=",
    },
    {
        "name": r"PI",
        "sumerian_transliterations": [r"be6", r"bi3", r"me8", r"pa12", r"pe", r"pi", r"tal2", r"wa", r"we", r"wi", r"ĝeštug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAYCAAAAAA0FzmpAAAA3ElEQVR4nG2QUXHDMBBEXz0hIAqhoEKQIZiCC8GFIAoKBBvCFYICwYZwgrD9amKl2c+3O7s3B0BYC0BIPHQBWCaud2Lig7Oiu/Zq0vKClaqHSaXDi1cRlfe9w6vPqUKR5jMeoNFgo21dnkVFwL73qxBdEcxl4cVQAVulGntj1hXLMledr91RBcvKYdWfLgAcE0AoE7ef9ownJcwkz11L9Arm8n42umYwr+fwwGwbB3D7PM7prAUFsNyVDEfrth78NkYj/ufcx4P0htO+71N4w2ljeP0xA0D7mqB1/BeC2HUYnxexxQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"PIRIG",
        "sumerian_transliterations": [r"ne3", r"niskum", r"piriĝ"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAeCAAAAACgDakjAAADhElEQVR4nI2RbUxTVxjHn1vuvaXc3raAdZ2zpdAXWXGoYWNT8aWazEQQQkK2JcuyF8OyJcsWtw/bsph9cW4x2bKZmGXxy4wGjaDGgvOlUVEZRORlTnm1vbWlUGjh9oW2t97b3rMPlKylNfr/cs55zvM7//M8D0CuJETFVwFNnov8wmUVn9+K88Jx8ikJWNaBJMsamtcv2ro2l68bPsDxz3hdVrrz0J3I9IkWObHG2/5PePKgnnq6ByanDE1Wy6z9T+KLuFOz3dM5AC0tRNdxT1hYiaxTF0kVuvo/hkMPj2zDAeDQxG/sx0umHw4FLrfqZCs8vHevEKZXq6ZutPemQ53U/W8T6b211Tp3vsMXzEQaFntR7Ggt8X+kWWgCAChaOhmPPHL83qjLrMOnCcT6zoojsdl0yHznYAcL8OloRFZ2awaA+ujtteNn7jnTvhjRZnxYo1IyDs85LwMAAJbL2u/uPik4obfVsm+NAAAQ1vd3+G3XRxeWiJ9HLWHdKqo49ZLNJjgjc1B5TZz2LSKsenDLZ93Lf6l5b3dqwN7vAsDIq11KAkWLtk2tVm8cHg/ZGWn7qqFTCwCWr9s/yChYt7fJ5OjsH8Qwzyj/rxhg3xzgy7dGq/3q28F3XQs+P0JEy+Fj2Y2t218/Z8OrFMwn6sS4L+rx090JB7/VXCwPiCwPIGGlWXMwaDUe4WUNftgduK0uLQ+Dut/ygO1747yVKRWoQgEhqV5cziZNxsqKV0gIXhh5jDtOjlES/AVUt+E1pSFhX9M3yQkFeG8SQ3QhBwBQbCjfYNQRpLtnkhmfAcCoWEEzscnD7bm3Vr85TFD3SybrryKJVwRZa8+5ifVGozrE+8YYt3N+eYKASUlDUmeOMJvMUyV6k5JWXaL+GkSguDj2996od/iRy+WLZs58SSqZKvRl0unYSFWr6i5qnkQByEbPg/mTLncqu2F4eg2FfHA68bpQ7I88rtHyHSwA3ajt+n4eVgrP2A8BG1PMmnXSRc7MA8iQ/YdcIIsAmIVu/pd3Ggoh4UaIFrtncoEVBAAH7oBIpaqMAIXJeB4ghwAACRZGzIiI6H1Y7mUuQZgmUiCWBBkRqfICOcSLv7YRyB2s34KATKLnIabRT3H5ruCVfoQUu0u1U3ltstW2vwchJHBcnEP8hecAyJvBHytpuZym6TL0jezZAFR0NhQsf7hWmS/jPzWfdavLzfu8AAAAAElFTkSuQmCC",
    },
    {
        "name": r"PIRIG(inverted)PIRIG",
        "sumerian_transliterations": [r"tidnim", r"tidnum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAUCAAAAADwndHIAAADmElEQVR4nHWUa0yTVxzGn7Zv31JLXwoFKlQFW2lpUQoy8IOkNMVFUFw2UTQhbAtbFojLzC6ZHxazywezZWYXF3HLLk226eIIInMbzslwVMdVOhDQ0GwUainFVigtvb3t232A2ILd/9PJ8z+/85yT/5MDxNXWw987nsH/lfLsHpUqf5v2Um1MIx6tMip1Evu/t4+Hr9KJ8edqZQtsKjttwBHTWAAAbm5ZudpMdk3XlJqlvss3rInwrG/HrMJC9YS/tSPmXtEbyq/SkY7rH1jqXqcvP+Umn9z/wq2Lo4/ji/S8lZIzps+T49zbM4OUseu2HQBObz4aBQB5466p8yb3OpzfPmVNyyxufS9OIwznWL8PWrwAgGGN2CnV2UWDb6UfeJXobLetwTcIwPFx6FzFdDCGLxrTBKfcs0bDoh8+/ek+Yf19dj+chh/L6ut6frgXieHNip8sXCmKmu56+u2BVTzdPUCaDriqX/pjzBhhbzbZO4822QAsd3cr6j+ZvXR9GQAgVh4sIQsyWLxgrjpIKq55Q1M0AIK1TzE5NHPv1iGVpCHs5UhzQJtW7Sbfzq//4k7DAlVcUCJ1ee9s5wtYLIaQy+m5OSqlQ+geBnGsV6kvTCX7un10WR4nvPyQT4cAALKcHRreRgvnJCXxTrT1O0OUwmQWVQruD7nyUht5ZPpc2am9xMemI6KkGkktzzH+N6lKdk9uiWYtZ+5S70x+YDW+SI06bKPmaQAAHZGCTzASSWhu4kZpafru1BM84grOaWhyfl5LFe1PigRS8gTkZyl+y0jLiCcAVXW0syu6+hZ29uISL8y3CbRevtA6eVP8/JYPCcDXiynxxoBoTl2xg0X72UgytK3m8sSZ2qbjv363MlYtl0BIJL7wlSpXv63ck/zwQYdnJfMu1z99clFQVuwJJhGsiy2PhmU78/XuZ+t6WseATS+bt/eNuWUcux2tJeWawqg0/yQrLhespleswz7hwSLP2rjtPKKxXLnKzZmVzSygxfvmiqp/Q+/7lIjbFnUwTCTIZbjr0jo8nF3VfKytwzMCUBkZ1BKQWlBdzD0b0cXhSgET8HqikWgE62v2G8O+pw/1/zIjbRYHGr/UVhYxQ+//FUZa3OV17zCbnHdDG/Y0/Pn4AQDUhyvY/pvXnqhKnh/vGl8CEP9dwOkWDQRDUYasHvQkwifezfpoq1KDn3vMTIJ2zQU1AKCBnQgGAOT/9lrhmu5/9eVto7BM/rkAAAAASUVORK5CYII=",
    },
    {
        "name": r"PIRIG×UD",
        "sumerian_transliterations": [r"piriĝ3", r"ug", r"uk", r"uq"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADd0lEQVR4nIWRbUxTZxiG73N6ju2hpVBGW6AdH0PbuFo6a1l0H4QRJREVjDGG1ZCZGbMlbEvIsmRxW2KyLW4af8GGW6bzDyDJQnQazVC6CbIwOyRaFQTko0I7S6GwU9vTnp6e/dhaK5R5/3nv53muPLnf9yWwUmuY2uzmNP10yiiqOd7L/fZC+inxVKXUr926JW+0z7ph4Otbz8AzXiyrMhZ4T1907/38ukXe2T0UWRXPMW+yGsSxft9Wf3Dd+nvXPRt3Mq4rjkfL+ToVoKj41HHzz9YGA0AdDZ/37gAATX3Hjb6PDcu2X2bcCxbNo/6B8bE4ACibdeda/p0pTHU1zOWOP1L5fYEe8bZd+6RxKPRc0kuMb18Ydeyjn0yzhzwT7p9aiiyJRiV7EID924YDJ+oAqCtP+m41qhJh5F/macKMMYY24hPEAbx2ZWp4EObazkLpHh8ASPPf26U4f/KuAIBQHf25KiaqTVSQcNFtE4HI5qse58OQWBCt2OlO7GTePGjsa74RFKm4KWOeW+OQTxontyv3DjtmWEJJ3Qth5Jgr+Ypi6NSpivd/GG13UPJivOrgwsLvgV/2tNQvvcvGiEvkbj/JP54WU5+kd7D2szOz1H7e+dYuv7rYRAhT1xTgOH1JId/DEZENKR+uyy01vqQVB7xU5aWH3bTemH/gb7Nq8wNxbPdQ+VyUYgmx8E4UALC2uMRcJmRyrt7hcTd1xJkrkU0P1Y9Ydes+8PAjTCzOq4IEECvdMqUyWEylRGSm7+7ojA8AKCfYdo1ubrHX1//9j8dRTq2nmYw8HxkmDXabKhiY/W56dppNpKKAiMfjoo8wQmDxakDupMNaTlD4JRIxS6n+4rZ/IZh6YQoAIAjj5H3VGcW8vKeEfUWT7RmhQ1xm6Y77WCbqvzNzo8dorW3KL1IuIUT6OP6xwH24gk7iuW2gDjdxOcc6Fg75/rIvEry+/eYKOolPnviosQsIS9ksqtx7zkeGXiZW0kkc3W90AdimrSHj/TrLHBGXi/+Hq1maBwSD2S8piHZTAJtuO5kw79iaJMCvg3ly0Rutttlsco5fHS97/tr2r14HX3B2QWbfxPN8TKw+vHoYf6NIGqqqH+T46a4JiTQTnGw+miZNqvTbTsc6rRqZTCaT0d80SJ+BA61n9QmblY6mnqq0XOtMwi+lW/cPKORdTCYKUNIAAAAASUVORK5CYII=",
    },
    {
        "name": r"PIRIG×ZA",
        "sumerian_transliterations": [r"az"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAeCAAAAACgDakjAAADuElEQVR4nIWRbUxTVxjHnwv33lL6Rq0tFdZKaUEsiiO6xqGolcwPgBASognLshfHMpNlZtmHzSy4LHF+YPHDlmzL4odhXLZloIbCBrPR8DJhVl62CYhYbtdSuUDf3+tte88+0EqByv5fznOe8/zO/zznAdisLKL4Q4c8w0Fm4dzi9wfDTOwK+ZwCbN2GJHfWN+0JGHpfVu2a/CDC/M/tXMmxi8P+J1eb+USBvfMv31xbEe/5Hhifp27Ua5eMHcS58Lz8iK1nDJqbid4rNl9sI7JLmssRKuu+m/ROtVfjAHDx0Zfud1ZN35xw9LUquRs87Pf6iZID5Qt3OkeSqR7e3+ejyVjfql++0UV70pH6wAgKfaUj1jJNsUYAgNzVnab9sfnbBmV6H7TcERr9hZ0OLSVTpcNtXW6AszN+7s7BRQDeW6dfmP35/nzSFyN+1EztzxNRZtt1OwUAANo+xSf3nmZfLTLo3KemAQAI/etHVwy3Z1yrxOUZrU+5nSdOFBoMsXn/MpTdYp/QAYRVjFe9N5B6y/7XahJjRpMFACN/7xURKJhbvSCTvjg56zVSnM7tEz+4ALQfdb6R1rCytrHE3GMaxzDbDPMP63CfGGNUh4IVK9Ihz6sWF72CENF86ev1H3v4TN2yAS8XUu9Ko7N00LYiGIiamUOlYr6DdTMAWW7OujmoFXJbbLccv2R1DEklKh9ITdoH7tGDN/SUJMbLiSHEKWJT1WSJpqx4Lwmem9P/4uZrD3lZeD46vO8lkTpqLBidi8Sy8ZE4hgQ5EQAAsVq1T6MkSOsfc9TsIgDeFsoeJSqHomAqVOm8Z/kqmZkT8J+0s8DNauE82qPRSL0MbaCs887UBAHjkOq4siJIHXjF6ZLXBphtv/J+G0cg7H54tzZon3xssdDB9JmvSiQ9U8MP+0N5grD3aLf8aRCAbLA9cF6zWBPrPwxPrj5fT3XhhfB51Rf5tE7BdLkBBA2K3k+dsFH4s+jPm5FuZ+XxvvoiTiBSygBwkfHzzUAawVqmliMTS2PmlrociFoRErADi5uBNSLv4AnyVK6Caf2eZnmJcg1ATjycAVgjYlXHQju8snzLTxjmQ9Q0iwQnsUxEVioId9zf1vFZrHCIxoAVeyiKsmYE1jwQNZi47bzrO02TyOqpq0JAxtGWBEBoygVm6lx7lH/c029CSFgjUSxsSUACAcu6v3lbpYHKOCAM/3hv0xZ9AAAGgGQ7Lg/vFgrEMll+GVxoydjJMxWoACRH+uuzU/Y6Uaay/wDNk49+YNR2KwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"RA",
        "sumerian_transliterations": [r"ra"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAdCAAAAAD9InGvAAABeElEQVR4nIWUUZWsMBBE7+zBQFuIhTwJGQmshKyEQUKQwEoACYMEIoFICBL6fQA7AWbP1leoFNWppgO80HfCr6iK9eLtfTnt93aMSaxLJelVsz+Zel3hbwVpp6a2y3A0dbYd3aNtSs6oM7NekG3uj2Vqfap29nRKyVlXTsxGBdXOcEGnz80obyZPfVxlUKsHbiA5xQRQLyMpAeOp9n2EG6BNSGWfXBxTMtYNW1S9r2867Y8nC3va7VkdUHVJlpTATGMy5h9AI/4zPeqveM6kfQ34OejuMc+uCKZuzdrNop3Acwr7ltecOQorvvtmiWZKcXHxR4m0pyZVDERIFiu8MiUzcIE60d6A06JDehAAH0Aw7WfiD1SA7VsHWNwPfZ6M1Vn9dbYupSuARxMBG+5Andb1O8dJigBztr+GacrhH2R6O2wfZyIyhvl8xTheVwAW2iF0sNZ+jd9FKEgtS3TFJ9y7FqQkgmoOIq541739gTz3JvyF3L/X/Qdmvt98IBl95gAAAABJRU5ErkJggg==",
    },
    {
        "name": r"RI",
        "sumerian_transliterations": [r"dal", r"de5", r"re", r"ri", r"rig5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAZCAAAAACeU8hOAAABLklEQVR4nIWS0XHDIBBEXzRqgBZICbgEVIJTAilBKQGXIJeglCBKgBLkEkQJlw9JRhoz8f7t3ZvjWPgA8DqFpO318RuwxnYAoHUA0AoAJ0fFFWEUmfw0y7RaL4P3Mkl0vSxmY1SUeYrFj4uao+rFerHsUsvEIG63WqJYiLMMFDnpxRc7yrwuZg4MUUQXdxUPqOfCq3oZgXZzgQDkkE7MWm22FTM1JR5AMw3V7lFNclG/YwI69v9TbebSe58yPkPW+HP/an9oIWdQ685KlYnKpAwmA4MsMlpY32AqY/yitmpr4XIOZZXrb3sejU6fVWTg9rxX11XiU4O/52e9CRVER9vlMr2pnMMj6OPztzWG7+RDSaE6B+6d0foNQ/rK7qXoFYArv9mJgdm8gCcNe+Z/d6CVFytPAggAAAAASUVORK5CYII=",
    },
    {
        "name": r"RU",
        "sumerian_transliterations": [r"ilar", r"ru", r"šub"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAABAUlEQVR4nG2SXXXEIBSEv/asASxQCbGAha0ELGCBSkglJBKohKwEIoFImD5kIWE385L7k5k79x7AyHOFD1js38rwUyvuMdcw+aIzcqMVaYoBADuVqGf5E7N+fVtvANgejwFznmbGUvPwYsiUWMOYOxJe9v2nHXlqpNKTnFwl5RdSSu/KO+xhKo+9vdSWvzdlAAap6secOlJOOe1HSlJ0t6MzY9f9zL/bFs6c2CzYUrpBS3Pkegf2SEM+N4hHuvRHKG2o1R0gmLpdO0koAKgMAEzt1qSxbuUBsytwCqOyUrBPBQCv9o39q5IkWW4WN5ht3uixwiTl6+dbNJrLBhqv6/wD5ROTOE+ScRwAAAAASUVORK5CYII=",
    },
    {
        "name": r"SA",
        "sumerian_transliterations": [r"sa"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAZCAAAAAB1ZHNNAAAA9ElEQVR4nMWSUY3DMBBEX6sQMAVTCAUXgg+CC6GBkEBoIDQQEgg1BC+ELIS9j/ROaeve782PLc3T7qw0ALib42/ZPXyyDusiLmoOKnXg2EVSpw7aV0tyzjnDtczObq63vhrkQJgn8WNwQX2uAA0L+aJXP4JSI8BCLHPfr8lZqq3ATkvxk1vUX1Sm1yENAFOrkTAuOfXvGTadg0hX2jGcdyO8f2Sgn0k2pzXEsqa3azfA2d3MbL4V22v9WYHSJYlDGxiqGQC6ImORL30Cjru/yMRwevafAIDxNeEGePZPBXDwqVO/K97q8CHDfwANoCiIKrnSqG/2M3abah9gogAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SAG",
        "sumerian_transliterations": [r"dul7", r"sa12", r"saĝ", r"šak"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABTElEQVR4nIWS0XGrQAxFz3jcgFrglUBKgBJICVAClLApAUpYSlhKWEqwSmBLUD6cOMvaydOfrs6MdO8IfsrbEcJhYymZZQoSzTmbT9LtcLPFSyald1T2gZMkira51NzssIZzubMk3lxlsYCo7ci6/ogNhODrAssOrYI5gODt6M5UcHAVUWTs938KgLL7tGlGVTtcewcwObdV3TrdScm3CgDenPV4M7OaEOwoXAYHINECyK2JIwQfhGfqQlpYIS1ePgBtU5kFcIGKFVhlfTF+UNIjgOr+FxWS9gB6X1W9pGJdydg/+jqW2QNctqFddH78lEpwpUu4TrBN41h/PUxiHcc991nvcAXgY5tv35OO7eTjdKizWSAEKw+7p/pV09bFGnRpXySSffSwR0cafsn+u9L70Jf//EzB8qZ9918KVfXzc1wZlQDS1jbjM/UJhTii4GgaCT8AAAAASUVORK5CYII=",
    },
    {
        "name": r"SAGgunu",
        "sumerian_transliterations": [r"dul3", r"kuš2", r"kušu4", r"sumur", r"sur2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABS0lEQVR4nH2S0XGDMBBE3zBuQC0oJcglmBJICVACLkEpwS4BShAloBK4EqQSLh8OjoSd7Bda3hy3YuFXk6YQko5HS7VwMKt6r7fK2pK/6doUVv5ETByoLCNIW1qXTZNeqOVry0y69roeIJym4hBSUt00TO6AFYvaoMnrtG2Tpq6mgoeTMXIR3yF2/OoEIU55kYKyEU69f4RZOjO76ADElF81AEzq1adt65XgQ9B0SBk8NAxxzP08G/mZ+bEcY0JDvnM1kfg4S5tfIRqwzMibVxVl+p8F/6VClr4w7FtqddYUXXHr8e4BmmVo78IzvZjgXxc4XWG5juOeMTOPYyxzuggnAL6Wm9vHdSyxnGPZKeLZjxjAIUMF4YBnV6+trBbk3tbQY/vn03KO1pCHP+5+V/4cumOf38puxw7unSglItPtzf+qKfLSXsZX6hsYVaGWv7CJmQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SAG×ŠID",
        "sumerian_transliterations": [r"dilib3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABiElEQVR4nIWSUZGsMBBFT21hIBayEjISWAmMBJAAEoIEkAASggQiYVoCLaH3A2YGZl/Vy0+qb066b+DCe022pbRZ+ymZnRTcajHacJEeWxxs/TpJekdcbrhITpCfs1Q+bLOS64pXyU0Wva0fEMG2U1VvawkpTeEDOxn1ySJAmmyrrlSKUDgnuLbO3wKAkCdd5ET5DEUdAboYF1/N3U6619SX8cmi1UxmZoGUbCtPztr1sUYoaHy7jDShiXMGXe6ayO8nNhVQoOMwg46T9oB04Hofl/4YOe8UnhmY4/i8r6WKHI6cAhS4Gqcg8h6TpZwv9guSat0BovvDBanVP4Ph920126wGUgmktAVSRYJgAUj7V11GKavBHWaRcu21rUMCfVsoOli6tg1HYJSxfZ4nIKSQoQCgX4aHHvcqlkwGrxnw2fOkyLfYVlkhIM3eyfaf2V0zkrZHIA2DO+r1OE7x1QugqdYe7Z7l7dThlHu9N/Vnnv9SMN6krv5LISLTy9g/KQXQ5ads/1K/O3PQyALPbHEAAAAASUVORK5CYII=",
    },
    {
        "name": r"SAG×U2",
        "sumerian_transliterations": [r"uzug3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABiklEQVR4nIWSUbHjMAxFz3RKQBS8ELIQHAh5EFIIKQQ9CAkEB4IDwYYQQ7AhaD/a7UvTmV39+c6xrStd+KlgNcZq01kyOyhIMlWb36S96mzpcpDaF0XyjTdJCqU/Sn63ap730ndJgqmzdILorB5OY00eYgzdCTs06qIpQAxWh3cqKlxFCjKN+VcBoJBD28qBchmuowLcVTc3rPcHKQO4zVH85poAEExtJJiZdcRo1cNYazUzq2YuKoAkiyC7TxPEEIVRiclVDdFXJSpcaAsrtCXIN1D6Rpt2imutNFrzAlzAsQKrrD8TFxFfRMQj/tGXVHMA+/C0jSbxiuKVyPPH2MoIUNrDOHAcBADX1NGmsrwWkvq8hT2jnYpTp02Ay3brlzK/MlUkTgLt9YwIcL3Ddp+m7hmYxqqQneAQQToEuALwvc373+sDW0ZoZHFZMu7YoNosEKOlUygeHp9134bUQVn6fHZ4oOCWk9Ju7RM6Uu3rNp7z/EnB8ruMw38pSilhln9RDaBtvZ8+qT/ng9kFrfEPQAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SAL",
        "sumerian_transliterations": [r"gal4", r"mi2", r"munus", r"sal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABcElEQVR4nFWRSyhEARSGvztzGcZ7wRQZbh4pj8VslLLRbJTksWAhpJQIhYTY2XhEKdkolGQzUmSk1MiEko0ZIo9islBcIaJxXYs7c2f8u/PVf87p/wWAGmFdISgREGsNO+86MQDVZZYEQsQUWz7oIk8MuYbMrYI3p1dxqUF0p/plRVUdgu5q8D0OO1iM74rSfY03PasbkSXuCWOQxG1/3tiheHs+JUCMDepuGpC/tiYFUM7tuAhgXdrI1D70v8k/APd9lwsFAEiHFy0mbeXovg1A2lM/VlIBMPVflQogLafLMZGbzssU8y8VdhEQvp6621obFXg5z8gFJPfTg3w9lg1QeDyr7XmeSgKIqLruBZCOPJVaDk2eZu366QAA5g53XSBV1QSQ1FY1shMgACSPWtpPCCNZk8KwV08eBdvce6dX7+L121o/7en2Bf3mmYPPZ3k+MVSPseLMObBVRJgEm8M3Ec0/1aodYZMBcDlfw8gfbBF0sdXb6csAAAAASUVORK5CYII=",
    },
    {
        "name": r"SAR",
        "sumerian_transliterations": [r"kiri6", r"mu2", r"nisig", r"sakar", r"sar", r"saḫar2", r"sigx", r"šar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADIAAAAeCAAAAABLOhIgAAAB5klEQVR4nI2U0XHbMBBEXzJu4FqAS0ALlxLQAlwCXQJSAlQCXQJUAlwCWAJYwuZDUmxLipX74nD4gN093gFAnBEoE6BUoM/IVa1Sb0MqAOTZgaoFqMpA0fQrxLrq2lQBWDQNW7WCradTkqbqFWSjMboB3qRCnlIkT8kAXJ6nbmpVgKfmx5fKsAOLDTs4++nM6LYft6/3pPS+wdN7tADHbGBb3PcAQKBsL4frBFhOr6xIldCk9CFsVbUbgKSLvTgVYVG72LcybwI7O7w8htENsuo55DDXWb5HiGsE0gpQCqTR7xBn5OfJjxvgEcACvIXjPeRTfUjC2oyA7un6JKxoGKGpQOinj79HfEjFypTcypR4hDw1PxxXG7yGxQa/PTwwAT/fdo/sB0vG/o7ZnQ7elBVpJTQpk4cUHnsBn4rnEOw8EI8QQp8B0ly5jNhDBGsO+DSg9AfIqfvJHUgWAAv/k0DWX0nWFVN8JMyKFIhdFXyoso74vbBlpO1I7bCH2uCNLbRvRVV1a22quIqUXI6ra+Q7v8FF2DLH6FbUVbzNKifKfdyuF0ly4AdYyTxvofr2TC52ePH26r4d95tbLP+6zFFWt/O2tK6YpXFv9L+0MqkAVRGsz/vr5QohBIBogOVW/xFVVAT+ANpWX5+zBD5fAAAAAElFTkSuQmCC",
    },
    {
        "name": r"SI",
        "sumerian_transliterations": [r"si", r"sig9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAdCAAAAACcOlPtAAAA9klEQVR4nKWSW5nDIBCFz/arASywElgJrAQsJBKwgIWshFRCIoFICBIGCWcf2jSEkr503mb+YThzgXic2teq//o6KGlesrIWAxldBQeSJOWa0Ycx3Q4wZ9WnzvXoCCd8sWjpgcCJEnRV2JICIJJBvQpdGQBQajkAgEANIJhmi46FYxiDs34Uu31apo4PlaoFVRRjVtlkWwK4Phv/Xbusf1JTARAo09M5lgU06U4houAILwWclyr7gjf2KWztZYPaT/VCd5gWE20D3sc36zzNtxMI9e29Be5jWTKgCpiNQwL2x2q/gYmMDro4CrVrIIdmLwCg2TXj/+43hhV9XL78AAAAAElFTkSuQmCC",
    },
    {
        "name": r"SIgunu",
        "sumerian_transliterations": [r"sa11", r"su4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAdCAAAAACcOlPtAAABJ0lEQVR4nHWSUZmEMAyE/7tvDdQCJ6EroScBC0UCFroSWAmLBJBQJIAEKmHuASgs7OUtmXQymZS55t/4GotndS7OUz8k4xyNFMsT2EiSNN8SVXhN7RuYkqkmX1Z4Uc66RHSqIajTHIoTsZNmIErBXIWOCoDmgxwXt76gAm6PdtjBwY6PLZ3ga230/TDgnP3tsgP5id1UjnWxKjoI8GqsV1ST5QK3NXkWdRuGe2TsE4B5YzZzMvep6/0iyNh9JtBoxGrb5Y0Wnr4lJROmAcCeTFEJnc0+n0CHy+c70QIkCpv4SOsgZjd22mAW0HxwqFA0y8x8lYN9UaND7jDDCfgGoE90Ly6xqjU/dc12rZ7V2xVMtmRaLF+79126y+c1uwApXCfmVfzH+h8FvLxpP6mgtAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SIG",
        "sumerian_transliterations": [r"si11", r"sig", r"sik", r"šex"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAABbElEQVR4nGNggAHlSVYM2ID649P62MSldv4/Ys4G4zHCxaWXMn2S3XTsyGcGBgYGBha4ONvffe8m6H10O4Umzikfw3P49NXHaMYzJf5/lKXCyIAOZK+u1sTiGqbp5yQZPH3Z0MVD3/gziO4/LoQmLHq/j4Eh6dM/BVRhjvVHuLj8Hi6+FYcqXvjCgqXs/5/kxacEkYV175YycJau2nbhyf8SJGHmKfv5GBgYGJjVMnc/dEGIW75YwgvzRemlWFYoW3jD/x0icEWZ92bLQZy4+MauszIID2b/r2ZgYGAIPP82zflJDCJgUv6/miLNwPD47+93t3+uZocJs7QvyfjysoNJScA69+qnILgzBBQYnf48fgfhKKx64wEVd/7/doERwq2zXkAk+PaedUf2Muvcxx4MDAwMdWcVUYOIa8FDdwaG8IdmDGhAYOoZX7tbMejCDAzcdccfNmEKMzCInd8tjE285JgONmHdxc4IDgCd7XT9Gn2ozgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SIG4",
        "sumerian_transliterations": [r"kulla", r"murgu", r"ĝar8", r"šeg12"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADMAAAAcCAAAAADpMNgVAAABcklEQVR4nJVUXZldIQycrYNYoBKwQCVggUo4FlgJsYCFWIgFLGQlTB/O3face2G/bl74CcNMEsgb1pZSaunnx8a7RHTStG+8P66LIgAAdS/vv3I+N1W+vN4bACCbjYIcJw93dCcN7TFTVkANAKrPvIdkrw8iYHagUgBx8+hpq2zaZD/V9wkgmjQje5/Ucj8rl/GIWQAgM0NskqMJgGac7ZoLu96RBlWmljBjaP17LisvEtNTYmqERmdofZJzTI5zT1zjXgFRUn1VlWqcAkBpjxj+WYm5KWTqANCKVPtM16f1tkTc7Hihuoldlye9UF1ZbeOoW6pqsZMqY0VVNRgljp2GGnGribRBjuaczrmTLoNDrgA2AXoCUg/q5n3XGc1bSidDjIurOX0dl3QynJws6HFPcrm9uZvHow+ZAxIvP3QvkY6DCSNWYTdb/nUrKXq2qUv1T33nYb+TI7u8f6O7CXmYSA//fwxQnRXI38IA/aum9gcAldV7kmCZTAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SIK2",
        "sumerian_transliterations": [r"siki"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAABXElEQVR4nG2SUXUsIRBE79szBtoCFogEVsJYIBI2EhgJICEjASSAhEXCIKHzweZkMi/1yeVUUU0DolX40ap65Kp6AFSt5sS8PmPQwwIEfWp0P+yhLqhlIrz+Uj4iLNPjwdiHWYENEE+aBlE1HxqEGGIAEK3AP+CQ95QR27qTbaaVOyxYL60AMnofffr07x5RV1ENAjnMs5yBG/vmtt0M/tMC5VFoaV196WbMejL4fjwwmndNrHtsV+TsuBdyG6QOFuD2QoZUAOd3d8oCIPnPUprYJqFfDMdIDwd9QG7DtFeMOsh6BCEHMLXKq9eLs2+zW7/zNOeszbtnwnQHbNH0c6/evG9iHEBa7QmtZrw1cvsAwApwC3NlhNZP8xvA4t02PVZfumGO3nTgVmyc94pYe146CFo1e1O1ust//bFOqqp5vtAH9v7LiRWAqPppuChnYHG8pyuZWsxfZAB8ATnR0itIFm+RAAAAAElFTkSuQmCC",
    },
    {
        "name": r"SILA3",
        "sumerian_transliterations": [r"qa", r"sal4", r"sila3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAYCAAAAAA9/JnTAAAA1klEQVR4nGXOUXXDMAyF4X89ISAKGQQPgg0hhZBCyCA4EEIhgeBCsCEkEGwI6oPdtc30pPNJOldfwPp7AIxDSQljBDA6AWCyqqpqABaNAGA12kGjgFWvpuKkY8g9DDn6PfcV96weyDGEoNG0RW1TEF9zRFdeZfMqQPDApdn9m922/mmU67z6k8HsbJSTkVwxZ2Myx8kkWHcyE4tLnxlj2K6ltl0jP96257ha7/t2B9CJESPj8VNeYZ1dJN2Z34jL5hKpbLwbycmSyqdRbpL4V8v093gPPACMnl0udUzmhwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SU",
        "sumerian_transliterations": [r"kuš", r"su", r"sug6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAZCAAAAAAHqxH7AAABG0lEQVR4nHWSfW3DQAxHX6YQMIUMgim4EFIIKYQWQgKhg5BAcCDsICQQYgjeH/3Q1qWWnnTys3Q/nw726jszM8ddhyxuyyJ1u5YXY6KCTXKI2tph+NVtVJhjHew6FCpzYgqkUaFEiVICwPw4UZEH7VmbMkMJlRJKEZ29AnDfvOGayzbe2ZYcNQHw9FHAt+5Oa9silsAHzTC03lmR9U5AUUUBFM0td0puK6S3mPPEDUugBmQ67j/UB4DZvqyBEJ9WaXoeNK0J/YWajkKoiChPNAQkoN+6PPMmkMj59PUukJ6ib98EUpVVx3WKPdnRTZdV1fDyOlDbZQAmMFNj/PMt6s/HaZ7BzAyf5d6q/l1kphZzdNWefAzsm1sl8AOLCqlBm/jR+AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"SUD",
        "sumerian_transliterations": [r"su3", r"sud", r"sug4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAVCAAAAAAYmlO4AAABYklEQVR4nI2T4ZXbIBCEv6d3DWxKICXQAi5BKgGVoCsBl0BKQCXgEnAJqAQoYfPjsOOLfZfMHx4wOwzLAJ8RlP+Gaeq+3p0ArBkzSfJPvRI+Rlt01u177qYRQIKqp6ax6mfMBrNgZ2QeR3otGcCpqraqw1PQRzQDYLNucxtlLUTVhNkAabaGFFPdago53AWKeoDQLEjQ6DQKbC1IrZKLM7XePdvQmkBsdtiKqsVh1BETXmEIj5bFIrHa29VUa9XsG2wBmyH4Tx2JrfxpcdQsUZ+Q34a0fSjcPLLN7HbFmp3wznxcgT5c1yT5Jh01qGo0ZHABMoSPDEzWOZ/KsfSFLCC++vVCP63H8+u9ZeHorNCXWg4c7L9cP12fqTD93PtyvRxAvxjHeefM5cdLLlNf9jzvAP303uVsr6+JABOshwx/55NNZv+SC4C7ZQeCPoTfgBiwYB5ifuci9buf8jduAXyJ328hz5B1kyTxAAAAAElFTkSuQmCC",
    },
    {
        "name": r"SUD2",
        "sumerian_transliterations": [r"sud2", r"šita3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAXCAAAAABGhbJHAAAA3UlEQVR4nN2PUXHDMBBEXzwhoEIwBVEwBVMwBRWCCiGFEEOQIVgQbAhnCNuPZhQ5UQl0f25u583d7oWiNOx5996RFxj81ycNedNqqzbJZDLXYmBQJMlPCiTzbQaiogLcLSj8xeBMG9BL28nv6uWYmYE9M5+hWD9fWABmXH+izMY6+mPYKXi3uHt4b5vdWkXvdua4xdfCmSVusfycxGgqeryLYnqa154puv07A+BjuTUG9jkfv8tdSiV6CZ6kNFTtdGu10/MmYBMNSLXL9eOtPsDltHVN5kX/BDqOJvQD00V9O66//RYAAAAASUVORK5CYII=",
    },
    {
        "name": r"SUHUR",
        "sumerian_transliterations": [r"sumur2", r"suḫur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAAC7klEQVR4nH3TfSzUARgH8O/v5RydheS65EJF8tqUS2OyWKeNq/4oL6WMWmytWqLW5G2zU1maVVsl1UjKlg3JJikiKTKR5rpDiI7u5O5w7tyvP2hZXM8/zx/PZ8/2PHseYD7CW7lYOkgAAGVO+Xhv/R+hzkebbVUcNTNiAJAZ771CJfGd+bQxsT5fIbLoHbw3zNy1WxJsOV1V2LYsR67XMqP90iwfapEgbsac6ksLEJiLBDOWb6I6dbLS6n8NP/JxUc8GwKktJqtR2aWc+Vqxb1Ejbqr6OBz4tSG8zwllVZoe3fd6kcWCOg3IMxVRXUfGpwxTfU38/ZlOs7XC0qaiV9I5QCWQAJBvIrSy38Zh9IZvypKgLuG0yuxW4XkPAEBoMgkAaZPtXhZscZlHCJ8Y+Z7T3t89rOaKn+a5AHapTwnALjs0lnGqzK2YPaPhcp7tSHZZWXupm3BusXZ8cT812Jd28I2jZS9UDEvb0xyWIUju9sswl7NYBemsAMPIppapahl9zT+Cd2wCoAmagp4ZzQq+GBQ8a3XOdtDmo2JVMSXXkFdzIkWcvzMSJuSEsjmxP7pFJw2NGoodHTHQ9fWescLAckbPzOoZA0NQBMdBcHKlWKDTa2Ruu+b20pE0GefOKTbluVrtdeIXOD9iqwV069qaknzhwTu9HSwagC7lgV2wv7cl1mk5qnL3FFeuuOaKl0q9IsFd7kwuJwHA07bmS+/Ew+Mt8bcVxWOyKYrFEKw9eWv8WuNOO/jSAHZnV1YkP7fukjDmpgSbJBiGbV0S2NuRIRnHB9d0GrwTsTMFusODISYsAjBoDbzV4YEq6eVONQAwedvppAOV4r1S9LAJANOTHJH9dfWT6irDny0M76O5479sNN6769r0Wg3C/DeeraxrHFl4K0rAI1XaFjE2UDNUdGNcUrTfcanrpfZIEi/8yG1lvh7imy4FAGBzw5FPSe8ajL0jAMDd7eXPt/z/CQCPlDuNlcj5PFD82hj5DQ/iLpamMqJiAAAAAElFTkSuQmCC",
    },
    {
        "name": r"SUM",
        "sumerian_transliterations": [r"si3", r"sig10", r"sum", r"šum2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAaCAAAAACBP2NVAAABa0lEQVR4nHWSXZEcMQyEv4MgCqbghaCDYAoOhAkEU/BCMAUfBC8ELwQNhM7DbFJ3yaVf1PordUkCoIYBQJ+XZf4msNUASJIDkEMOvAHNf47bE+j29BvAfFh6f5VlxgA8zOIAjsVFsBU7lg5S7NhbmawtRWSwqdXUto6l0dZQ1IjeV1dkZjhVlaaVaEppaBg9LM2gG+y9SaOSYnfSdJJWgwZQ92t8H64MMJtHeqk9vEaGEjm1ZVC2+1iXWknSshySpM4f8mYz3Sk/vD7N7vl8uH/k8+7nR/E7YyWmnKRtFmG4hpnCKEExSrQFtdDm7HA4ve8GGbBdL7Up8qXWw1wJ3qCXO9lvD5vng3K+nzbPB/V5Aw5JS4rUpb2lbksxt9SNppGAuhXNilkLhQO0WKheB3c1igYUlSuSF5+QYuvgP1jL2rXbf9Ejw4rvstY1xhxN32TTktbsc0nx99yqONKLbk370qf+ya/7emN+AZGsBT0zYQKDAAAAAElFTkSuQmCC",
    },
    {
        "name": r"SUR",
        "sumerian_transliterations": [r"sur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAXCAAAAADSYxu1AAAA+klEQVR4nHWRUZXDIBBF7/bEQCxgIRaIBCKBlZCVgAUqIZUAEoqEIAEkzH6kaUh6+r4ec8+ZeTP88FIgMTzu4NXLtJpllTIATtZSBi5aiuizaaUk7Gb9gPB0u5H55bqDVoY5Z6WmOLgUrxSq7iFCzMuYAG5OHTRPpDzR8/tYttSl2H1jB17sbhyAFwnmTY0AZQacPDVdZbRLTQlUggro/gF9VCbEDqhbdZdJ2WpDjDUTRIJ9d9aCkrAWvw1Dytyk0oIX8f3e59hoo4M0X9D9Xe7p05QPylVjk/B2RqZObfwzdWbM7fvU2c5T+pi0Z36K/cYgiPsOCf6j9A/L/H3wfqQh9AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ŠA",
        "sumerian_transliterations": [r"en8", r"ša"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAABYklEQVR4nH2SXXnEIBBFT/eLASykElgJVEIqISuBlcBKSCSkEkACkZBIAAnTh/yR3W3niRkOc+8AH/wVEyFnVev+qW6OZSsiIpL0EyEFY8UyJH06B16aMkuNWEA6VZwTVyC1pAgwyWR2ouumsmmUFqhG8HkEUJo2K3c/kKBnoAKYAcgBNDY/dmQmLEKxcOyjK8wZAUD8aSRPm2J9Qi7ZlEMA/ZeKp5uoRmObn3leU5VhvA7+/gBYFTs/SBGL7GLIJFlnF3f09auzNkVtZVrtnt5pQ9CTiFvtMvM2MvuOl+TqfWPr0qRknMRFyEX/atdKVNAuditdqxx2sQZAuba/AX0eAEgyHL8B76FeHpjtdis1fp99moHrWBYusy67gPXz54mgGjEp7KlWpr89jV9lRmMCQF0DvBAwSVrN0cngUqm6/Zd4FDtJHa9I+TXUtI1bIpdQlPLj3YtVp6wnvCL/xiL0C4VEzyJDUuT1AAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠA3",
        "sumerian_transliterations": [r"pešx", r"ša3", r"šag4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACK0lEQVR4nH2SXUiTYRiGr2+bH1M3V5alNsypkM0cOa2DBAmJwrKioEIQNUzD0COhoEhC2qyhgUh0IGIRgaGiRbDUNqUOikAc/tVIHAujItxGYllJXwebburWc3S/93W/f8/7QrCiL9cCRDenE75U1lk9ULt0LkJA41juVrPnvXQ2xJSF6HjNswLzoU7nt2Qh/Ap1CzefS9JyyciQImiGZNXDuXOLXwS1WifLfx1mvrLpR2fFvu2J2WXt7lfajVw0+6qiArroQ/+GhMLkvRAcHZzpS17LZY3e6hUdu1tO4UxPYigXGjw1cshpBih8mwaHZ7sSQgJXfHVRIOt9A1Dqe7oFitwP41dwXON8vQhJ96cGtUBrp9NRjHDc3b6SOLrUJoJq6s+0sxh2OL533T0Jmx7/PuPnKXbpGiBo91baxrJi+x9plaICEnokewogz+x1jd3zN1QQr74Y6AgczjDVPWbLUlD/d/HS9enMwG5ptvHsgCz51dAhfa0WHOpoeYzq/AMJYPON1IVPtz0A6rbynx6XaxrEnLK+udE8AE2LNUnz5I4GkJ3+bL+4dbUPRyZfZkO8ZTAVdIOWBOQVjhZVaCsNoyN6amzpAOnWE1T7TOs+jdExoi/eFbh3RpXXpGBd5Y4Prz5xudcsrudgHB/O8KtKb5NyIwfjhF0HUOG9FROOQ97k0E4o9VhU4Tnsf2fddmq+JS4Sh/xJ58dWTWQOBe4Jw/84wrGBA2udf3XSqnC/T9vxAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠA3×A",
        "sumerian_transliterations": [r"bir7", r"iškila", r"peš4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACP0lEQVR4nH3SXUiTYRTA8f8+fHFrc7EyUkQTFWuWlEn0ARZSmWVJgXbTh5gZgkIRlVAYCVtlGUREQUSRNCZaFgojxU0qwotsa86vFIcRdlHuNcRa2nq7WNp0s3N1OL/Dgec8B/6F6mw5gOp6EuFDYx02AOW+gws06Jy/GrSs7pcKg4ryoFyva8kybX8w8CVWFn5CxcSlZkmaLLC3KcO69q00+dsvSd98/k3hPNL0o9c/6HCNSp6vr+JCXTCJJbn9PUU73owWFA4+C+lQGsUSMHaquf8Itg01xc51ebVYCuQ3R1T1ddZpyB5qXB7ssipvmQJWOesVFz58l1Jg57AlOqjh3HhFBMgfS2a0d/1TTUsgd6ROP8NR1WOnBYh56JiwQKXf3O/MQ7Z35N5Mx27fLQE0PdMuyQxnfF7L7XxYXD9VEPB4m3QekMWtLba7DeqWloRIQQnRjZItHlCsfOJx3AksX5Y9bbb8PBUBQHpPg6M9TSk/2bvr2tOtqQBIYsOixKvvA4PTkrvfZduKlYc9qotqzcYBCWB4NGVI2TUNoM0RKr2vPXoQ1h1p+tSVCaCrtcbont/QAfIDn20nls7uIcf9cg3oa1pXQGJrTTSKImetJniV6V0dBsrakwCSrPsoHTfOO5oMZ4chL/Xvu5OPi8aQm1nvss9+8VHRJMx3yHDZkwPZMfFyZKhDRrctEaBIvKIO55DpbkuAQ94aTXiHDX3WZfvHaqMWctjiHvh4U7ewQ9ZId/r/HNmeF5vnVv4AESrHPPlKauYAAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠA3×NE",
        "sumerian_transliterations": [r"ninim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACXklEQVR4nH2Sa0hTYRzGn3ObHtmlTqWmImiBlinFvESChgSWA026jFGZRBorA6HIvqggbZYYZBcThy2CFkOlJZKWiKWGBd6oXHnJ4ZC58HIWXjA1Tx9sON3W8+l5n9/zvh/e/x9YF3sjDwDY8l3wLHHT6F4AeYtKLwVZ/0qtBPu+C6ddQtLFc7LGJO0R/eBkEOH5hauzt5oFYUX1roVeD126kjb5+LydkEjCyMQuD/d9Sxf02XEBgdFZurGOEHcu0jpymH/+2LDJrUFr+Ivrp8MjL4M2crKEz3V68R4KKSN1ga6cKJpRU8CBcgBI6AoHks2GHS6FAscVAGT9RwBQ8Q3yCwqDoOecWFoynR95Lzjg6cDbnaBRoR8cHjebzvzQORtpiw8Yqv3DyNLXsaoi7fFe3lChGUtjjUunANBA6HUf+zKoLY+G2ByldSFDKvjOyYaaOYpRf7ICVGS9pe8xEVKwjQB2twpCh+1FarLSiJiB2r7WKBrXVucvF5ojwQIIfmKfW26pDAX8a6D6XVQj/Mylz1nYYj9xgqXk+aisMGVxSrqazt2fCKTIVNHNmU4LR0AUFZ0Zb8t4HfbQP4mb+OMnZhyff0m2lj37Zqyfck7zqLYtdbqNVk/O+ptSuPeXZsl2prN4zuWn9nfaI5DVeDL/zitbQ6sCKpt209LEtldyGREAyPSmzPAch4bGJsV2V1NrLn57Nq8VbeaAvEfHrrnzfKmvOwfk3dU+AJDN3/bzxIG4nioGODtTJvbMgYO9VcyJ6btSbxxI7DdbK2TeOYhk65eY/3CAULw5tDH5C/3gzfvUxzkSAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠA3×TUR",
        "sumerian_transliterations": [r"peš13"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACVElEQVR4nH3Sa0hTYRgH8P/Z5eDkbDN1ZSpWZgxXDpxXHK2QaNkFc1Sy8LJqFYZGEaQQGJnOKAdZBIHBhAoVNUO6WbSJBe7Lam1zNFraQjCQ7awsWbY6fajldFvPp+d9fv/3/fDwAovFO1sPALyO9Yhe1ONJCYD6QGWMgNAa7Odj01vmQNiQFdYnCh8odNsMrtlUIvoLDXOtTxgmqB59xlkchmX5przpb58IPn8dSz4e5X5c+7xBU7AqJaemy/MiPdJJnf8o929f9u5+RILTRmsXT1vdQ6lLndVCHwv1VDYbpe6BlHAnmn11bCC3AwCKxjOB7ZO9orBAo7+BC7AGzQCgpoeTgDLP7cQQC1q8Z0hgdbdjTEYAnQaXdTeIPZ6uUGJn4DoJUBM/3ny1yiGe+NJ7oxxI6FvY/8czjMw5AERa0ch8YGBz/930OJIDiAYYYwZAsDe0yfzmEwwAzj7xZ1WCT+sGAEh7nFm+ky7WKeeOK/e2iAGA+C5RzHpXtOWKRMlcbMyyvyo1HuZUT/HOx1PFLgb4RZWkWL0SftMCe+7qByXZ5Hs5lQiQuTVD05Z8AKzK1++N3a6HIoJNcFUzxuPJ//agdIzlAEm3fpoLC0zBO4cOqpsteip8lVLLqAR17mENkvQ3zRf2DjOtyz6NzDqaXd5YC6m2RpC2pnrmIgfLKs9mXKu6VnG6GEAtrSOXOyCzmVR9g2IAR+j2uEgHZLbnVUoAGvpSfDQH8u1PM4Eq32UqugOFzkcrK7x6QSwH5A7Xx05hbAcUHrv0fw5i10jJ0slv4Mq/+/7P898AAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠA6",
        "sumerian_transliterations": [r"sa6", r"sag9", r"ĝišnimbar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADcAAAAaCAAAAAA2gptyAAACIklEQVR4nJWTW3HkMBBFT1IhIAoKBC0EDQQFggeCB4IGggPBhtCCYEGwILQg9H54MplHtmpzv1SlOq3u21cv/Ep5bKXjY/0dhttMTc2GX3IEVTfZwIuVytg/I76GXlz8PN03BvhCbITeCMcWpYbPIww2TWbzZGtWzdvqHuvParqZTmbZJkDMPECeJWeZRIdNsz5gMKjGbUurjlkFINm8j2rmUPOTjXvBbxM8gGZmZbDgLQNgGXill9apvVVq4c7fsCagQqs0aqN8370BDag06Pjrhc8fxeWxNU8OPjsypHjHXXXzmpsLsIw9OI93wREg9J+5G2V/JuDeG1JPORyiHLBTAbAnTr9fi6XTP5bHcj7WCi7ccy1cDls5A609tZEynWFkuXIuQGlpLAAu1f7EAJz90BeX+vH12kEG2sXpcvAXZ0V82lLYRjZhXP1x8Yvvhw6IgAhq82aSYowxRoLukQ+aN13FbFYVG8CbXfYvwqCCpMmuigy6u5R0c6pRrjmb7BJGEUZbWUXzEC8Ct80+AWhmUpJ5t/+6YPm6hyV3dXzyNRWtiz+4+XzuVOiVTtuDdQnHG+BonGbHzSfuyfUGTmsPPngnDoF8n5ewFuS03Dq/cRyB0Aq+VXx1oRL35XyFVLZR7UGj6EbUEZBMFqKB7cT3fIHlIRrlPA2+/nkOzE2fNS7vz+k4+vzxc2a+OH8+/XTzsf6b+h9FTxhwCdK+bxuBv0gyWufOaMGYAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠE",
        "sumerian_transliterations": [r"niga", r"še"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAABd0lEQVR4nG3TUZHkIBSF4b/awbWABSzQEhIJjARWApFAS4gFWgKRQCQQCWcfkszW7DQvUPcWRZ37FQBA6Pxafpy7jQJ4AzzgJsD6ejaLHHg5yB1o+a4BUQWsFfAKkIddNSBJDmsyfK8QlSBJHrCiKqyp4ocSaShYURE8fJ3m7R3asWypvvajxj8cdXruByA5cldjHcpoKAQNeXKFx/NYPfvsyvFaUuRrWT3zVj0OwOooHdfGShiKTP37zTOlHBQZflSYlCFK090tQM9Xzij3LycUBQhykCtQVyDL37OtwGRABMwB9Hpdjfqg0h/nYdt/N7Fr6yvgDAiAnWT1B5mH1IFaPpONeJGlK0q8huCw3i6yKAWArFVYVbvIpMBF5lqc9803lneqr/de0xPaNB8AQ/4kyx/I5qOcZLyWFPd5WY2vrXo8gK0jD1wblTBGJH4iqzLcqBB+kiVlsJ4hKED6j2zYTdZvsntC13eYHFgEzAO0m2z6RDb+AhowEKBAWL5OAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠE/ŠE.TAB/TAB.GAR/GAR",
        "sumerian_transliterations": [r"garadin3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAAECElEQVR4nGWSfVDTBRjHv7/ffmNbwmCwEW/JQF4EedMoQDkLLQUSo+yCwl0Y8qKkgcohhq7zJeGAQzA50ElBN2OBoUYgB5zhwZmZIC8Rk5eDiSAMEbYBx9hYf8jVb+v733P3ued5vt/nAeCQv4nPpJzgwsXZgwRMxIj23OwCr6D12wkAJFhH1ANi53CR4KDT+2F2MUwTnEzqr3JGYFtfNAMA+GnNe/JLPrsbLjkf03uqZuGYpQnv8VcagJoBDgAQMv0L70U9i/fQmxidaXLJmW+t6Byj40TB495lC8vyY1cAUN3+1nIbSmkl955ZcNb2PM+LlgwP0R2YWc4cd+87uhQ+dRMgz0kd26QaydiA7JFkOYyt0dnYqqdHaFIsdrW/9gO3+YwoAQAQX2qT6euTQKUInZsql1RVoTwzBk2Cizu3V9t98DV86+qDKUDq6JVH6uQ6ycrKt7XanLxlY6s6kIYp/ce/xIb5z8ZSgCtveu28xr173eTsrmeWBPe5MW4ACJ1PJG+kNBkgwc+cnCrgffiR+z6ByCObyJS9J7Rg08QxwMA++0deSicAal0aXyGeDj1woeBR0JHybmVOXF3n8AI9Gftbi28+SZ4AAFA5ut505VK85i3eTufb4/akOTX3tI8eJOdVKrD/sHL1CHt38DreUD7bnZs0MLit1jZdW3+1y2h76szaxfND/5Zb7iVubPQsiNtTGHDlfqMqlWvyBBxZVzC93n3D7VM/YRLiPTktDbGmL8ls0mpFSBz+vdYcAAmYsQw6AwwkU7fGfFMI2wRfLtLfvI4fx+3LNABIhGVKeRHLqfMiW843iuuHv/M06f9bRQthxvmeOfXSaqhAHqDQvXMh+m+mW422aG626jY9xyV9+gsOhLmddUcHAUKmHo+c0PJXejxsH6qrmcXHvwodV9MGzE+wrr0tKstuuxyc/RjUiaTNl/xf+XX/rX0dvVnyF/wIu46GSVp3wiJktMS30Km7eObkPQnALc/jV7jtPS04tyHuTrFuLMPdeHezwij7SuGXB9gpfbpGAB6l/k58jh8czXFa/STaNEnri1GCSr8HV+vFkT5eFDAqNxsn9HJMraBP5fBF/6DOCNcbQOhTXa5lqrQABXzC78ySWkYUiavmPz95SVjdUDlHn2DFNmgdglKqAAAUdsWXRb3eeqhBbOCWtPSPZO/PyGil92eSPzlYJctWjZ9Yz9a4qpVb73grZuxvLBbeDZlr6Fr4r73BYseDgPsSw8uK8mSMbVCRfNW80nruqTbQ8d3cxh6j3dlbE2ukqzTIQ38GlLYPXVY0Kzp+9tqyrTcm35gGm99eRDszS5zFKvaJyLU65erfHrcRpmIIrYxqu7xALovBwxomkhP+RxvrHzBonNFc0uH3AAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠEG9",
        "sumerian_transliterations": [r"kiši6", r"šeg9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADtElEQVR4nHXSe0xTVxwH8O+9vX2tFNraiStBLIMWoSGrtPIwk2liFjWZJmMkI8tGl2wrTLY42cxguoQ9XOYwC+gkOv/YjBqETEElAVydyeZwULth4RYslleBEUrX8ijcPu7+qNoA1/PXOd98zsnv/M4hwDGO4FiIKwcg5vMFwlVZ85D0KZpodzhfIE0rsk23bpMV82FOXzpf7y59spLJpRKFpee831qsFHCdjlqdywyB2BeHgDRUl2EljLhxc4PxvemGRg+z1huDe0AUHRN/Zcqtz3zrvwvOs3wA2HB82l6RzF+lSXaAmcQ282z5rsVDHqLEmuCqCgLA1Mf6zqrWd9XUqg3yha15A/QB35Xz9teaO3Y7T0kBiAAA6pPu7vI03kq+VGW1h3s7Zm037s8cz+o/xAPwypsFBaadgKZhrMusEz3BFFhKx95OH5qbo/Xzf49LxEiOjEJ5ig6mlAGD5qwPPznQ3GIPPu6MfHRHbrVkUBYR8xml5ffKGs/+czZ/tZptbYoSfdku5mLbvfDj2vV4n/319OLprp4LoQ7PBy+6hhuP1jDWWL3GMw/+ObI1WgwQScxbWNbMqGTT7OSwjqDmfPxQeNgR493d+uLioqaOv0CBJQ35mUgSiVOCMu2gfXdE7fvcAry0ouU228/7SvZfnacAImNv0xZyWNP/TMq41bZI+vyKeD/Yle1WxLmXDRvHKEkwfIsum7z6ts1Z0iNLFYLn0Hz9xgS5+U7MpmUbs9ezY82OMerHH1hXG0rp77ZfkZHWwo1h8Hhe7zQCj6hIv8WQRQXo632DUwBVkMYrIDs3Fx3Nyfup3KbYqwoljtR0BRJeZwCsy8/JVwWmrtsHHka3U/cntN/OeqTpqlQ5rc0QJSLsV6giWJYVfunXZAtGx36hXeOxV01e19KJXENnQoOdH+Sxz34m7PW/Y+5bIN3yw+2N/a5J34orByrSAd21yyejH0M1VCmlvZde3XlvovObTVgztglfvhyHyoHt0eXzDw8aWvatB34LV8ev1dQfcO64aFUu5ej5dgsDgAglh6YBlq73c3BAEicdZkacEv64/KNrTpbXL//CdJdU9XFoUCBldSf8xqQOEgzxXOtZ8SLDau/aeQuLHBoAkdcihOEEAODTOgu78C/LLnm9wcBNztPZkcLGtnCSUUxOOZSF/nN3liIgCOrwXC0nB7Oc0eumhCIekWQcPegOsgAgMM20c3JCPWh+kJP5J8DG19LOR3kYiDyleD6Q+310Ggu1qVz2fxUigmrjXc2qAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠEN",
        "sumerian_transliterations": [r"dur10", r"šen"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAADMElEQVR4nNXQa2iTVxzH8d85z+ktiSVpYxp60Wq8lLq2tGJtlblihzKqiC+kKJRBLF7GhuhoN91E0MFgUKUqQ1oG4nDCGGIZRkSJ1erStbrUWpPGNr3kedImab10bZo+T5Lz+EpbL2Xby/3encPnxZ8v6U/ef03lmLt91u3S3Pe2Y56O/uSiTQZyblmB896fAqeEE0EFjSNedqS3ajQ+iw3N29UYSYx+y6al0A7h479FS4rEKgJCpjccb4vn3Wq8oLzGkS+MSuPS70/8QMSUtg2jfSsz+4Y2OZR8nb0ku+mQp3XqoM/GyCsdzdnyzR7PVgXSmgT7FVg9pSXOz+iVszhzOw228+sdUy+CoiSJkiRKfr8UDPNCgDkrxSYT3K0dWRdd3H8Vj90RYcPIzslG21OPChYDiwFY2zLoA9jgiXw3Mxu5OT3ZlCHrzOkBY56SO9FCHfUm5+K8ronCy7cAr9wZBdgjR0aN3ZhlqdPmFK350FJW8Lx4xc+0eq2DB/ZWGFPWz4SaAYxPMwBMrxFd/MlUUk+q8NRt8bp0E4MPm4WPIgfwS9x671qtoakbAAgAsHWW7vrJO6YP7KxkVBwY8LfH+gA+Eo5AedBw1/ZJbudscCbVNwMI2RHrANoANwAQSgFwMY6hlc/m4ONjmG+EAgKlsx90fvvu6D+T/zneo/8P+MvLFf8aM3fm57WdIUq5SlUOgBAknOfz4OGpZaVL9dGh7NRBU1ZY0ASmU4JlB9T34yptJzF7lyznY6t6haS0rozFv/m/XqALv/fmtN31rf3Wc/qG7178viVwtaa9q+ES3VWqBSCrMcS4DABQAYC5Vtl+yhXbr18y/No73GMf6fEFp32PEzf/8cCVnV5urTDXRgmgLOQA2F9H873PIY/NKM8iCIUgu8JqX+hHU3k5p1i0WUADAKg0DoA96Z857CmWC+q0pdW+4o0jK5SaccvCltRG+31VJURVCQCQOwkAmE7WaCbHc5L12qg0bBkbNrjuGqo1F44FlTf6xQCArV7tqTWeKqo8aagaahvodn4q3tydeLZOfisEIQBw4zSjAogAUAJKQCkKv0p6p9r+Sga8BGJKWguQBIQMAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠEŠ",
        "sumerian_transliterations": [r"mun4", r"muš5", r"sis", r"šeš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABJklEQVR4nI2SUXHEMAxEt50SEAVTEAVTCAVTMAVRcCG4EFwIOgguBFHYfty0SS7tJfsn+cnSagQ8quoh9aACAJl2fNG6CTIz1OIPTrztOG9kt37gjGkbOaePGHGYZ9/CrJPLEqyPGHfWJtmXGlFim5bOzn1ZHeHsU0rIb1ZnZBvbulnQja1Ehbms1V12XDckjgzIULTV8xJuAYD31RQXtAIASEPgq0MZQQEmuwBpKpafZapDvKytBgtg5MzwAlmnKA0aeTP6BBa24HTF2GzDKnSusdKQmZPzTOMtIVXFx+2GJ+pfaCQtPYPudzA5zw6z0ACuu/8XowL5BBOjHy7tKPUoNoDXEy7r5/v5bwBKdJtXwOTBM6sAAHEul1qL+yUOyvpyCTT9BsDFwzm8pQW4AAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠEŠ2",
        "sumerian_transliterations": [r"še8", r"šeš2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAeCAAAAACdn8hFAAADY0lEQVR4nIWUa2ibVRjH/+c9J3mTJdFUWxZjTUPvzS5Ftqy2oLuwm0w3lrZWyrAirnj54IcxcVRFRacfinj74NiHoWNCaTeQ4TYQazRKbbtLV9bRji21W9LOkiZpmqTNm/Oe44eILprg/8MD5+HHn4fncgjyZfv4xSl/6v7tlh1jKCDVlv9uHufByQXtrUIs0H7alZ/YHX/FHRwwFab3y9+2srzMJ8FA0FYYhiWxcufQhgfMq/7Wlhn5nlIYZsq1P2Y+iJ2bp8xAFQCQ3Jz6WhShYR27uGg9YETs8lxCAQAWVCNFCmG2Wrsv0N+xaSIbHZmKAoA44KXF6FY1dbhfdE4Ndlc67ixZJMDdRBahSdg5+8vy6pZMuO9iiBuNAOTebW0LRbw//9BCPV7dWL1r+mY0AQCo21zEGuyzWt9AvXdp/rXu40s8BQCwhHmxSlDZZ6BD9+0PZ773X6cAoJ5ybxn+j2tv+XBpnYLb/Y3s0oP6uNPrabZYrVarPm0aeOPfNB9c3/DMSQKsGfrx/U/ru7c9HxsTACDcJX7f7FfTc3kDzRwpHT0MwPHTCXZO6mf2qYwQAOhK17RKoes8y7mu6TrXOdc1TTwNBkAC4Fc2ifK7AUYB2Pn5h8RKqHaSloTWBZrMNxpCK1U/YPcEcuunZOfefrKzJTFWUwbASeWZx2L+F67Z00OW20pl/6sT86bZBgHkFslkf+T85ndb6p/d4HK5XBeSh54YHdxzrPbmaNebDdaPur5IOM7uHYmwnDfJLiZGzOvUaQIAKJn8pufqeOtA463x9b+2T353NKBWn3oqnCBgAJfK8t3kyY59c1ENAGDOqJfljMIXDXqSppmmRY2ROFUIwEDdqjBWOE9823E1nmtW20sKAwUhIAQEBAqUXDcZbC/XXFH0+I1IHRMUAKQ3//LunSjI6tIqOlhxeuvB0EiEAOCVrNjGMiz9vL2uTy1vH379eigJALJtZ4pn0iLNM8t6KqslZVrLpmVGAAx8NNbb4jOtWeCrmhQAEBs9vRvLHn24p7m6ae3Rx+NlpUfWqpayVqcOAnS+03NwR3A4Rf+6L0mZZhDCkGVSZ5wJYdQodEZ8nlsMJk/Fsd+f86f/qU6CSBCZH0TVLgMA+1n5paPI/3GvlEYTAMel48b/Z3P6EzodYc/N6A7/AAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠID",
        "sumerian_transliterations": [r"kas7", r"kiri8", r"lag", r"nesaĝ2", r"pisaĝ2", r"saĝ5", r"saĝĝa", r"silaĝ", r"šid", r"šub6", r"šudum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACMUlEQVR4nHWSTUhUURiGn3PumTszok6Dlj+l9GtEUdhCI4ICAylxp5gQtalNtAgEJYIypIW1yVpIhRCWq6B2UYQttCgwBftBLQsanUrTHCdn9Dpz72nhWM2F+TaHD57vPe/38gky1I57E89fZ2/buzUTQNm4TizGHT2ckaBqbuBcy89wORlVxNlYY3usHgbr/RmQ/Mefone8KLt1+/sFraWwBTqNSISOWN0WasB78ddglohYRdpYk0bYWXroC6jK2etD4T0ncuLrO8bz0gid3TQ8D8TrTMi//XL0QaHbSFZfuwlyutwPMy0jSxd+uAlDSAGqt7ayf1zFdwWq9ol0QPsKbECFFw43vzCTxUZj0k2o0iSgKnZ3Pv0udHPh5Xk3kddlAqq856oFRLJDUbeP2KIAVO/JmZ4wKGkqAA2sapkSQH29u/+SA4oGDUjDkY69KmI+A1TuoeTNGZE46uldEtibayNFb/oTAkB7TpmAqvnYMAfkbrgWAxir7rsxkpIIVitAvvq2MeD1ebwyx+vz+cz+nbOjq58oAaAedpZ8npLWAaPJEmAHZMK00jZSfJiumpN2ifA5gDZyiv0u4mBF17GQsdwabIsCTvDWu0h6Kmqprd0GJhdDcYCF36YrN9UxqQEeyeWVXrqTVRMr71iq126AtBGj4YpKOH/bpF7Z5b9youdLNxVsSR2/vTZXuwk92T11vOx0Slcbgfu2i2Bd3ZOat/8GnPmky5TnTLffdUbwBxn/x2Dxim/IAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠID×A",
        "sumerian_transliterations": [r"alal", r"pisaĝ3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACd0lEQVR4nHWSTUiUURSGn3u/6zcz5i9Z/kdqGdEfFmhFUWAUFbZKzE1tQ1oEghJCGdLCIihcSEUhmqugqIUVYQvtDyrJfijLKTI101HHSUc/Z77vtlChGZizuefAc15e3nsEMWp926+nrxLWbl0TC6CwX4dmg47ujUlQOvn6dO3YUBExVcSpmcrGmXJ4W+6JgaR1fAvccKHs+nUfp7WWwhboCCI0cNBqtVCvXWcn3sYLv5WpjZQIwo7XPd9BlYxf6RnacjwxmH21f3kEoROqe6eA4FET0q4//3InI9pIfFejCXK0yAO+2s9zdSPRhCGkANVZVtLdr4Ibk0u3i0hAu9NtQA1N76t5ZoazjMpwNKFWhQFVvLn58W+hazLOT0UTy2+agCpqv2gB/oSBQLSPmVkBqM4TvvYhUNJUQERopgRQP1t2nnNAUaEBaThSS41Aox31BFBJe8NNPhE6FNc5J7Dzy/wZvXk5OjyWOz/84IgJqMNfKyaBpJxLMwB9B7oupzS7br9o896/tU0B8uXw6mSXO84lE11ut9vs3jDuffPJuvjhYfKt+AUfd5tzvX+ktcuotgTYyTJkWh0/3PuDavdIGEDxabR0Utq5wu0A2kjM8lg/N+i86kBVnQZQe4pvHhsw5utTGwKAk3rtgx9DWE07Ms964wDUXEOjDQzODgQBpv+aAMZs28l3KwBQVwc1wD05vzDLxbi8/YuN+rXw9i19xlKgIrjYLK0AYFRcUCEHbG1jQ3jB6f+EEzizKi+9wFW4bHMo31OQnRR52gCbWhq15RuftibGA/M+v65RURqsPPro8HvQWqK11M5UOEoirqrVE3VG8A/qwfnA6cs58gAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ŠIM",
        "sumerian_transliterations": [r"bappir2", r"lunga", r"mud5", r"šem", r"šembi2", r"šembizid", r"šim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAbCAAAAAAfAlOuAAAB7klEQVR4nHWUUZmkMBCE/91vDOQk5CRkJWQlMBI4CRkJQUKQABJAQpAAEhIJdQ/Mzc2wTF7CV92VrnQ1+eB0NYyvQAzzMuO9O883JR8QVyRJSjTmhBClI9xocl4DlPyzitegcASD/LoamFTi4bS2JFI5ljClqIWPGLqWsc5P+Q0suOW7HnSG+gsu0NXY4p+iY48z1efba6f60AMMKiWdNcsOmuyzpEYRuHiW69PpNtUN3NizXX3K/e0RSfd9PbQjqWSVe8lYVn/Hg6ziiRCYyqTkvW+bXddgAVol3hBs0e7qHva5BGil5h2BSQwaNOB9AxBKToriLSEKUzQVSXIARor+H+ECtHbbnGE2btusXYDah67m76FbAJPg1fagUlRUilSKYhQ0glTWXdHqbV5lnyS1JQ4mx9XHHFeiwAsaRfBZETBJ4U4IBshyNBowRe2D4BVNerg9rTvhM2QHMwsjG3VmedLqV3/93vbvq9kd/pztFM0jbXsiWFz/9Zi/ets9v2zcQtiIgIs4IvtYNK2n+z9J0Pdib+tog60OsGBxOHK1DPTtG1/LGtLE7ksU2Kzso4I7OisPfHrG393Lv7V99bY2Y7dwti7z2P8Aby7zB7r5jPB9AtbrWme4HeH7pYEZoJ9h3Lu+zYcHAIBfAH8B8Rsq9cK1t80AAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠIM×GAR",
        "sumerian_transliterations": [r"bappir", r"lunga3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAbCAAAAAAfAlOuAAACDElEQVR4nHWTUXXkMAxFb3uGgAvBC8GF4IGQQvBC8EBQICQQEggOBA8EB4IMQfuRaXc6nerL51k3kp6cF57GwPpdkLxdN2IMz/Od1gclqJmZ2cTgngBidpO1NXLVgcFKiLaA1p9Voi0mn8cAbQGyxdYcFFN5KJJ0YtKb2NKQRR04VUvwInlMrH27yx/gSrieO0BZZV8Hzh3J/Q1OMHZJxP6fWGeC67FeVoA5jWGkjvOcZ4DFVKdnZvnFiodCoUVpKsMxl1q5H8GXRURKAohNhUJJVgZYbka0/P3Dk2k1vZUUbYWiGcjmP517iKLFphhjGo6+lpaAZBO/AF7t2Opx3UwzJLPhN4BiLLbYQogD2CRaJxPjV0AMp1bUzCyQwJlJ/AROQPL7HhybC/vu/RXocx57PS/jlRk3wfe3kE3V1FTNVE3EYDCYtAFkbdHXZv6upaSyuCotSpWGGESDwQRiNQHcZPkGZAdUCwy24NTSFxBN3GTF36xoB/Caa4CNKys7feN612ts8eO8H+cPd2z4dfNF3Ffafgd4wvz+9af2SwTgtHPJeUeAIASE41kMKTJe7srNs3HYuvrsewA8eAKB2j0Lc/plr9ryVDj2Iga+Wo1iOTxu1iLwGln/jP1e399n34d1vPIsTts6/xAvofIXxu0ZcH4i9o/WN7g8yrehgQ1g3mA9XN+3zs94A/gHm1dR7DpUknsAAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠIM×IGIgunu",
        "sumerian_transliterations": [r"šembi"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAbCAAAAAAfAlOuAAACEElEQVR4nHWTUXXkMAxF7/aUgBeCF4IXggshhZCBkIGgQHAgJBASCB4IDgQFwtuPtN1pO9WXj46uJb1n/+JhdCyfEzZst42c0+P64PX9mH1ePZJckqRCFx4AJgUgAcxNBei0pqwZvH7vkjVrAFTMrKgBMCi3FmCV25cmvReKxxOYVT2dY7p6+GXD2LMc2119BzfS7XXXuAVj64/rBNhw/IZnGA/rycd/YpkI6cj1sqecbkeEUoALE8As9/JIrDjLe2+lFKkkCJ0MwLXerxDX2czW/txdbmpr6wDm+QTa8PniIq8610TNW3GzU6R4At9i9VUl59x3VK1VkgG9Cj8A0XW6aliE3FSgl7qfAFYxa9ZMyh2AeS0y8SNgIrhWl6TTMsnyO/AM9HHfU2ALad9jvAHHNIxHfZnHGxAKfH4Lg9zlcpfcZSboBMUbwOAtx9oU70bq3eZQrWWr1jBBFnQyyFUGhKLhDRgCUJXoNBNc/QeQZaFojW9StBN4GmqCjRsLO8fG7W7W3PLry36eX8Pp8NMWVwsfZfsdEEnT34+felwzAM8712HYMSAZCTv/GV2fGa937aZJnLIucYhHAiJEEol6RGam/gdfvQ1l5fTFBHFVzaYhfXVWGXjKLH/G4z6/v0zx6JbxxqN43pbpW/ISKxcYt0fAy6NrLu3Y4Pole7wtDWwA0wbLqfq+HXyP3wD/AM/SXDNJwUvDAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠIM×KUŠU2",
        "sumerian_transliterations": [r"šembulugx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADYAAAAeCAAAAABC0bJaAAAEiUlEQVR4nHWUa0yTZxTH/+/btxQKLwtYQaoFlAhTKQqi4GUa8bJgRDfd0KnZ2JQwEzI0KmxDI1E+6MZEnBeIM8YBOmdwqGhEZF5wcxJYgYpcK0iBUYvlTkvfy7MPVGkKng9Pnic5v+Sc//mfh8I7wv1s0W8EACQiAQBQ1NTLSyx/ablpqyaXgH4Hlsb/QQGgZ5wMAAAwi2PDzwwQbnhIJIYF2DiNmojy1wu9ToA0Jrd8rxwAsOlefV664Zp6SuPwGoBoljuPp9xuDJZyHwEKTXdb8xeuAICdbatwjGw4bk2ggCLSe8hH5kAp88hPfi/K3AHf0tPT4/craMBl/cEAqJ4/EzRygK4V6/Y82KWerrKLlQXbeOXa+qUZk9Bd1Nd2rmr/fGeXuJX1fdCXBNHZHMDQlsT5KZlo1o9pI4RS9dZ5EVJTvEdyZ++Oyppqa2I5v7oEbDduxLJXOYBxkoTPZXT6xy8lNkgUqFxz4Qgwa+nalXeOeCq+098nfQmGGtOMZjhVWapEAIxalt1w/lblWF+u3maOUsjYprq6c1t3nXntcSOjKZQvcVs/mRKx0Z01CACYFX230prs5Vh2ZKhfZmU9Y+uAS1e/3j2gdVq18N5TYBaGZxzN50fnVbzXQcVplwmpJANpNnW36LiOK0oAmJW6JN/gW5vLAmDWcQ5Ye7JTVFngq4rFtNRLnh24uNRfiEg//4+AQerb1T930BO6AwACq0nrEF9X1UseQX3tyQrZHm3dgQCo/yQDi9CYxwJgJsAa/w65aDrm0fTek+9DJFe2PyCZpQmJywsXsrUGoy1lIgz1gu7XsE99Kke+CpZLKgDUfHP70Kmu3SG+nB3mvsDcJk5V9BjMPp7tRn+PlyOclD68IeDjoKP3raFZBIDQ2Q++ytcfdtjMCz1dUPi8Mlk9vdqGp8hvvhZB62oj796Opvuv/wLAKyGu/8T8FLmHsx3Wkb9XYZhdvJwdnF4RflVYpnWlARjIMJVzybiZh2Tbl+qiHM3s1ChRbt+L7AfjvydVB7u06TMLiiuzZXGWHQyu8zS8ja1SROSaHnziCSComGxDQx4LAAUxAIK79BEIa2kIx64h7kPsfIOxVc048EKXHGCbTO1TZ+3oAD4Ii/ixr6d/oBqW7p4O3H/uZxwrgzcHlkT+nqOxCdiYcnHfJBEA6EL/1IIYmWi2gKNHBmEYFKywZYmY4+3s+lly+Vsj3clSsgQAmF7uxPunBvzo7dIp7mS7Re7lEhsWKbXw4BEdvV7VvrXVTgQ+yy16dC8zzJGh9wgRrZxAeCtnFUTeKpDSszmdpHPkeYvO0QqjktA8k3TT65JBMzdk0fXyqJA1GtOWuXH/RW32uFPmU7HONO4/tDlZS6zHlXN0jwHXC3c94f2wax4Y1SOyz6e1x9+lssURs1k5uDfurpkBBTA0xYChIAGv33QtyVt5rNWdYVV6RxAAmMMFz0SM2yHj59VJzGmYd490OBZJAQCdXiO+eYwdQEsm9dAA7uET0QHreMG/vbOJiYAsNl4OWWSECwBA1Zk64R5LJQDwP5Uq8o9TVXo5AAAAAElFTkSuQmCC",
    },
    {
        "name": r"ŠINIG",
        "sumerian_transliterations": [r"šinig"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAdCAAAAADJW7CzAAAB2UlEQVR4nJWU3XHcMAyEN540wJTAK4EpgS6BLoEuQS4BKQFXgq4EqAReCbgSoBI2Dz6PT4nkGe+boP2IP4k/8KFq63IDanm+jZcFwNR+40spSZKahnoCig8FAMlfEDnFyCPERy5hQgEw5BBIbsbZh4RYxKxDfE7FoxwB2UhpHRMV2jFYIW3oTEl79mocZAY6u3dA5xYFk4tIUP9rpButwhyYSJIyk2TU+1vnXDd2pxYAYphGK+yFXiRyj3Z3NOPoAICYRTzuKcUApJiiZHTXGQ/FF6VLAmoI9SMuBhQPi6idbpw33WaJkJ/LUi+vD9Gml6u+JVv/oL228XLdtLoWoPPzGDHUAhsjScsxBO1zB91oHQAmwyMAaEiMVMZQ9k01GQCekOpmk2m0S74ks7SmRRW9Am328vbr7XYHztYegLacLu12Ws+nW335hQob1PX0fP4wVM5Bl/JZUonuBehDBwDYFJtZqdaUp/HOiAElwiJapxstAZ27H987o4ZGqbUKQ2pt6gVF9/zvjDOkZaBX9ILc0+NYdyXhLECQZs7dWp62j9fT6Qq8YgVWnK87wD8Z7kuc2DPta+8GgLnF7m92pEoeDmdfzoPb5Wk/jOV2+x6wHvgPgUN9G/gLKgwtUtn3V+AAAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠIR",
        "sumerian_transliterations": [r"aš7", r"šir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADIAAAAeCAAAAABLOhIgAAABOklEQVR4nJWTa5XDIBCFp3tqAAusBCqBlRALrAQsjIVUAhZYCVQClTCRcPdHmjbhcUrnVw7Ml3vnAVEvLLh98dUj1Ny76SEmKVJdB00JwET5gNEJANArpmVKstHWJ4gZJCZJ6iE2yDjMWw0qiBsg+FDBjLeMCUUOozsfIjMxZ8DXPsvM+PChBJCIWP3q2Y1nJES9MizJY6oQ6yTpwmxGWP0bAeqBe3H50OyT54v1r8TbpVKZaTHL9XVwVjQ5db3dicgw3X8rlWX580R7mQhZRRSLhJYx8NEYbdXrDKS56jGR45QOxGn7UJ7IGlq+lwIx8f5Tnu1Cs6RiE53Mb56NKra3MfyaifstG1jLNW3rweDy02t77egTIyKHYJkzMEwQWQA5DVS+Cx0Q+BOR1RzyZwQRN57bu4ihff4PAKqjrncQ5VAAAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠITA",
        "sumerian_transliterations": [r"šita"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAcCAAAAAC4pOt2AAABFklEQVR4nHWSYZXDIBCE5/XVABY4CbGwFmKBSkglcBKoBCphKyEnASRsJMz9SNsQms4v2I9dmHkACOaxVyY1qzEDiNSOeuOsM20AEMmpw4MpMgUA0jzb0OHIyAgAzpKzvtsZ6QAgMeZCqnTNCQCE5JxjJjW0N3MEgGSRlpRRlGVyb0x5T1EzB/hEi76n0MnWtY/GNHRUtjzcVKjjjsJaQ0FZgmtoZ0cyjQLghAM9HnV9/AF1saR6aQrNZJ+MSZ6vOu/7ZAzL7VZf2x0No9TrbdkKp/AKx00l4fLzu7TnjRoGlWFLadXqd+CqLeGWIpmMxuiAI+oZ0sfH2nIuRpNjegaq3OvyQQE8/V7rMcQZuP99g99FAfAPXfCqeUmIGtEAAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠU",
        "sumerian_transliterations": [r"šu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAcCAAAAACxT0sMAAAA70lEQVR4nHWSUXHDMBBEXzMiIAqioEJQIJSCDaGBIENoIMQQZAg+CDUECYL6odg52+l+3czT3t3e6IODbC4izobpCKCrOc01+zMhZhffAkiPHJ/l42dHQq129dfZaVQTYAAEfqUoJCuxOIq8gGMlnqnXFg9waZ5BgyYDsDAPOrPdqlBT3SmunkDYeeLWzfGpNoOybbDQWY4y7c1XN+k88iLFWnVdq+bIdVGN0jbHl5sGTRcAsXN0J5T8f0l9ukogTKPq15JKmO+u9OMpqRHGb1fC7keseWRx7Oe3g6RcUzhuFQHj7G04LQxgXH9/C/gD1r10P/hrUX0AAAAASUVORK5CYII=",
    },
    {
        "name": r"ŠU2",
        "sumerian_transliterations": [r"šu2", r"šuš2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAcCAAAAACW4crkAAAAi0lEQVR4nJ3PWxGDUAyE4R8GA7GAhWPhIKEWsICFVsJBQi0ECbHQSggStg9cBPTtm83OzqSrvm9frI4QkpRqYJFWFABFzdMAaNITAKo0HiIc6AF2LvGHykwH4MY+DUfEdF3XDYBFKgDWpASG8V1eBYDUA3egX1ns3K4ZzQ9aSHZzPguWn7t7PQdL8AOKNjl30egcNgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ŠUBUR",
        "sumerian_transliterations": [r"šaḫ", r"šubur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAeCAAAAAB/Q9M8AAACsklEQVR4nI3TW0jTURwH8O/5//ef0+lsw1uprBQhmVrqzCZ2MRRCNImi8iECi0wrogJLiQoHJc685ZC0wt4sKMKHINJMqYcpjRaWObQp4mUXx7Q5/3O69eCFzTbz+3LgnM85/M4NWEtebTg2DWelofixct3SlmjkzdPqacqr4O1ijHYXE8hbpcxol+hQtNEbjVBmqSccokwbWe/KVGovzG6fAiCQMXp+2NCSaIoS/rFzD5SLVXSapdBtevrYDbxKAsBv0n/QsS2fjS/ax3ua3p84NZhTNHltrVYAUNWUqWXlKh1neXhMMCGKlMxLQSVywreZXbVRnY/dKayL9dN+db3zhEX8d5VsdCZloX9n4mA+bd7HPIUHjY2IYTXFw1bilJ5t63/3srsssDK9Qm4Amim104PSzReDSAsABFo1GtuYSitWB9j6DICJXfZYlRwlA/rOlbOjuCAcmkOBS/wAgEM86F1RQ4d11us1AHCnx0vlrXbfEFi/zOwqxTM7ACaK9x+aoPjatgAAAnk9nxAQAkIRQggIRRH3AiJqDLdMAACrpjJeHRJdkiPKTUwJl8cJrjsIK+kHQHK+2IDguoSiAQAge6cL8tn93+Yo4iTEBeJyUYDjaNclM8AqxMLQe5aTQpGQBnbosht+5BJsyCcFD+B8zCjsYTJ+Z+Vx7bf14mKrpO+55p8dDQ8tA5yQEQczosVScvJbZ1x1bHdersOfZ3F50issAIw2SgAgVandjcPlFe0TDwNi7ku9ntYZAEDWQO+40h8AXfLzwcGethAvcnUH0qTgPQWtdxYBHKu0zIWZmrtYrysDAHil5kc0AOQbJl+/Ocf3LQGcn6oHQC7rFSmhAd6/71qoI0ONICX6KsGmbCWyX0+umqqDtiCB1MEZxeZVrifNWOPrDW4I3VHL+Bz8CydQ54F62waSAAAAAElFTkSuQmCC",
    },
    {
        "name": r"TA",
        "sumerian_transliterations": [r"da2", r"ta"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAABMUlEQVR4nH2T3ZmDIBAA5/LZAC3YAi2QEmzBK8ErwZRASrAFKQFLICVACXsP+AOaZJ8EZ9lhV3/4FAGXkmr187RvjsdeREQk6hMhBTPIwBR1lQezdOUqdjIAYlWRJ2OBtBI9QJBgdsLaUB7qpQeaBea0AChNn9T4dyBOv4AG4AVAcqAZ0mNHXrhcyBfGsx8LOSMAyFRdaaaPvq2RTp0QdIimQuqYZ0DNMuT0jwhkIRO/IPTR60HCNwQdRMbscnvDAZC2duXWXaOz3I1d3r1aCw3iFfSfdZUVm8/KiL60rs0D5hiAPSEm7t/iigSZVIlkjRJpFkx0O6KVef6e/JrEYowDaFuACwFB4iqHlWmMpf2me5TGSqzkV6T8SVTYrlsiN1dspcc2l0q3Wj1xV+Rr5EL/9Jmlv/HsrvkAAAAASUVORK5CYII=",
    },
    {
        "name": r"TA×HI",
        "sumerian_transliterations": [r"alamuš", r"lal3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAABSUlEQVR4nH2TW5nDIBBGz/aLASzEAhawEAtUQlYClUAldCUkEogEImGQMPvQNCGX3Xnicmb+Hwa++CsyYymmtc/DutuGXlVVVeyB0IrptecldpcHg3b1TDrtAY2mytNQIa1KAsia3UrEmOuiST3QTDCUCcBYfDHhe0NGOwMNwAxAGcHSl8eKzIxvoVQ5HlKozDkFQF+7Iw10kto90pkDglVxNXL7KRyim83QA2COW0uVYPGq0YATvUIkd4AXSbbXfIlkAcDHrBoWLwemfRuwpXyu61Ql+QDEKOKCpkuhARtsTJoM+Gu7A3SiGgHo3l786fDTzP0OwHJlS8JWxcn6FpcGZH2ZGuk1HdrYTDgZV8Qa97wfhJvC5NwI0LYAJwKyil+GUV9Bavef97JJE1V25hek/iQmqz8jt7FaKo+rvjS72ZPxjPwbb6Ffg9O0QE0OkCEAAAAASUVORK5CYII=",
    },
    {
        "name": r"TAB",
        "sumerian_transliterations": [r"dab2", r"tab", r"tap"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAARCAAAAAATGGhhAAAAfUlEQVR4nHWQURGEMBBDA4OBaqkFkIAFLNTCnoS10JNwSOhJKBJaCbmv4wPCfu28zOwmAQ1yCnNQ3Mi63ZWpY3G3d79yYH952L5XwVjkocKW1F+2KH0+YLQHIbOtAo8Hjiz8DPNnSOnE+3+ZIuIc+i0vnKwmmqsssk+6tPkDPtAyuV8PNv4AAAAASUVORK5CYII=",
    },
    {
        "name": r"TAG",
        "sumerian_transliterations": [r"sub6", r"tag", r"tibir", r"tuku5", r"zil2", r"šum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAcCAAAAAACB2MWAAABr0lEQVR4nJVTYdUjIQycu1cDWMDCWqASWglUApWAhayEPQlUQiqBlQAS5n4su4X2e9d3+cGDMMlMQgC+WOA3xGgm0wyOX1/wYtZ6/4/8Sl2K7V2//x3xOM/W6PThD73O4PsrT80M7wFJX7SmxO4mUmAWLkfGEwDg6fTPc20pa6dA/HxDvcZgb8+eIS6eu+WJB51Qto0rZRAqJYcNJUnJdOAPdVbZK1XtqjaRagCYhX1W4Q6KS0iSJHjZM3uqgdEObwGEUly7zomJ2gE81bbjRM0sZCYzW39DjglxkU7kVNjSwakvUbIrOerSCsm8wBR2IzApy97dxEnV0y+cpPUjEkDKPUHxZY+4ECkaOk9l7GdpfeETzvN5TRcAQG2Lgb3egWh2hvTKv7W1le2IFMHEbX6K2jFginvDW4TbJFEMAJwekz4MImARAQSsK65103JeBPP2Drne5/ZsUTiYRnnVJRQ4QpmPiVSmyyBJh/EWiqN04w3KW9G2DN9FqBzmzuG9S757wFBSIR3e7K2tI4FLA+P24yqAan4KuCHa84fX2H35NFNG5hMA1Lovn1bn8fwXd8wkMJsjBkYAAAAASUVORK5CYII=",
    },
    {
        "name": r"TAG×ŠU",
        "sumerian_transliterations": [r"tibir2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAcCAAAAAACB2MWAAAB1klEQVR4nJVTW5HjMBDs2woBURAFHwQZQgJBC0GBMIEgQ/BCmECYQJAhSBD6PhwncnJ1qesPV3le3Rq1gA9I/FSxhyt0u8CvD/Uzlnb+j/lGm6vvQ1//7riOk3c2vMVTrzPFPhVphem1Qe1J66p0GWGGmzk/Jh4AALdgP7flPrJ1CjRg8MtJkv++9QwyR24oAx90mdUEAEKtO6G5lrRWZTVSAcweyBQpqxhv7JWadad2QnMg1VjV9Mm2FcmcNGtOMW/JSHOUygiENeYBpFrDPV2USjM+ZEYaK01EcqUVVrKQhUw4AJOLN4zi23XaGqabApd1gRe5yOTC99x+wiKrqsIjXGVngcFYjyGEkBTKwSwyzhwy9X47ALR09bWSLKpqikioOIZIo/ReWp71ihGXm5vG8XyPN8DBn86AuI1Bu/mz2+5REQgVUGkewFfUnXuBQWz5fTScx1PDeXsLDmEaFwCH62BXBwE8BEDCsuC0oF1dwDRIWy3kSzvfdyiSuYNJxnC/ImQaAmEsD0ca9bg7g1WB6+yXA3NnbzC/HNrX3XPJNO58F/C6pdhtIVWtZMALXta6Jwi6Y1xfXAPQ3N8aviF+fIs6v33e4eqe+QAArW2fd7Rp//8HBsI/bcIdsYkAAAAASUVORK5CYII=",
    },
    {
        "name": r"TAG×TUG2",
        "sumerian_transliterations": [r"uttu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAcCAAAAAACB2MWAAAB6UlEQVR4nIVTXdHjMAzcmykBUwgFU3AhpBBcCC4EfRAcCCkEF4ICwYEgQ9h7SNLG991M98ETS1pr9RPgCxK/RfRwla4z/PkSn93aHl+f9e8Ppc42fCWY7B+RlaT5k+8CAEhT+5hSW3x9bYYFwOL08fP2bjUUd1vfsuvk/XNdtlvBdHd5fN5PLwIQtRzDhrlWxsORmQFAqL4nzJEHqic9RrfF71MIZvFMyFbT1otcKqlAMRlDpuoeMSjlRFA9TccJ1c0mQorUz6M8gmROJZecYi67z6h1dMoI7KYBQDILAIDIWlio+q61RNKMKiLVUyuNrGQlEy7A5OKCqwztNR3pp3V27dYAhOUqPzK5cJ/bM6yyqaoc4Yz7CgRf4Os+3wIUetXIONNnbhKFAMpRXzT1ZtHMb4SRKOIYIpWyrwYA4Jj1ujrFOrahLIAHGgA0wGG4PXGRn37oADyWBwBImJ6f5qew3FYApsMuae+gL0fDnTJmIGySmB0AXF5eXw4CDBAACeuK25a0Xed83+dQ22PvoUhmB5X8UZeZEQhlfS+fsoydJLXz0mTmwMz5szrM6GsYLKFjKLu9C/iHgHj6h5MVI8O/fewJHTJD6TJug2sAmvsf4Q4Zrr+sbjiO33DWZ74AQGvH8Rtt6u9/AZpkR4/Zk0U7AAAAAElFTkSuQmCC",
    },
    {
        "name": r"TAK4",
        "sumerian_transliterations": [r"da13", r"kid2", r"tak4", r"taka4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAYCAAAAAAuK9knAAABFUlEQVR4nHWQ0ZGEIBBEey0TmBRMAUNgQ8AQuBAwBA2BDWENAUJwQoAQIIS5D0/X8tz3A9Sr6hn6YRCr7l4TZ1M5a5MzdfEFAIAVEZEgIklExMsUitpU+yIVLbiawdVZx7mSGhg7qRidipW1KwUgWfFhEiAFlAkpAFinXTTbkQEGMgBUXNwtN07vA9v/6ri1jgi2O7lKR2a0Onr6KEsVf8+Gh8rLz27Iex6x94II1+9KJeK+g477nhFHR0RQMsFuoY0+zQI/h3kxILdlBo6nHSMWdNY6XgA0rNzlg3ns2SsATQTg6GKfOSigZYxmcsiaSNNRyuzDk6FF0yo3FNUo6KTy2D8u9LXDWyQZ3FPkTV8UxH8z+AXXWJPXbt4QWAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"TAR",
        "sumerian_transliterations": [r"ku5", r"kud", r"kur5", r"sila", r"tar", r"ḫaš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAdCAAAAABgL3gnAAAAs0lEQVR4nL2RSxHDMBBDNWFgCqGwFFwIpWAKpbAUQsEUUgimEApbCK+H9OPGOVfHNxp5JUuSdDONyvgvmCTJj7ZJ0mKPdOTzii/bAXqwWmH+pXUDgmU4YS4N8tltLUySDkGphUlLaMQG39i97hzROlqJ6t7YwL+PWtBoQOTE7WM2VjkANbqSTqHmfPWgM6cg9n3KhnXmd+P0qrMnF53gboYO9+OkFpMGPS73E69evznov/QJWVFlfku9b+oAAAAASUVORK5CYII=",
    },
    {
        "name": r"TE",
        "sumerian_transliterations": [r"gal5", r"te", r"temen", r"ten", r"teĝ3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACO0lEQVR4nHXTXUiTYRTA8f/7bJpvgpQ0FbRAHV2YQoHStA9S6UaMBCvwotSCEAODtEIwlC6lCPzInJI3GVhUhMM+TEXULF2GpZYfCWtLsiQFdbNp79uF23xndK7Ow4/zfJzDA36RUnMIACEBSELvpyEF2S8BIjJn3rhUsTfGT+XLymwWQKZNdb3utKk/NNVid+mJPkOsUMASXun+qUQuX9LowUG3/eF02y4AqlxHSpYuaDTt89uKB2PzczkSQMBI32Kr5FMpbbwzBkJzurtNEkDhinJM+Dh1vCsWgLDWPpMERNsnZa0aCTcZo/eFRVp6kgHa73p5e8anLiNkfH3a/PEkkZYeE3CvWgbiUw6cqp21GoFtlUP99TsgytJrgvs1MtAwY7cvLGYBYGzriAeIsvSYaK6RQTzvNkwMOF4BYJ92zwA4Cv7cSkAFxKNzlfvj3i8B8PubXgeAoyiwOg5A4Czvjxjx3FHnfcmHAhICVBCQaFDm2RyDVp0E6Mk97xwK/YdPp39fk0A016WsiKPSJj1T0WRVAGFrbJSTkrP9Na/cXLcgAfrrgVt2Jp29Md+h0fwyc9WqbmOd+GwqHaCs3QDkf7my1dO19ZlZS6bM6b6dy+prnZ7cM9LR4klzGoBC3rX62mX8mdHiyYZU1laCL5aaN1QTe16MFj5xTixWBa+vNWcDjF2du3l4OGjusbZ2g9Xh3KYQh21ghP9FUNGv1RJvA1tuy5s98I7ruK8XcQL8/5i7JULx5u9Q4S8R88qEeQDYqAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"TEgunu",
        "sumerian_transliterations": [r"gur8", r"tenx", r"uru5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACsklEQVR4nG2SbUyNYRjHf89zntLRkWVFc6TFpKXMprwUerEMyzB9MI2akbA1azWNmdfZiKGiF5n5gLUim5qX5V051anJkpfIjtMsHZV0znmO6Hl8OJ10zP/Tde13/6/d93X/wU3RhUsBEAUAQZTcqE/GhvsAAUlfDLIqzpvhRrU5ytd1AEkmVa5/aFJ7xrjFkH3Jdf4zRQWqp5wcsih6W9YYuqRBNlV21kwHIF+Oy7buHkMT3hsyL73s698oAHi01Q3eFkapEN/WlLEsKLLA/GCRALDLoawRR3Hcp/boXMe7rltx5U8WCkCwuUMLIwfiz/N51qPrH+5VdBT4FiwAPr19BkgAvotPm0/tPP5aTmy2xQy9XnpyrwG+2gAp3EfQxyab01XN448Dfu31EsPXd+XlGEYWd/GL2fx9cB3zn6witCoFAH3100VcLdSCdFe3vm44sBbZvmLY33dOlIjY+yGj4ux2VEC6cacj6/tTK4MD2xZ+nBLj44mHsbdrT1HBxOeAhP3g4vg28J5Q8UAX3FKjQey207AjL6JBBQki/ZV+8PK6XRWysql2ZA9NxlgBkEhNt7dMAuuP1EBpcoxVg2Br7Gfz8u7fAohXi6IdYqLAT2XtzjB8/fV6fYAHWw5dNiqAZCrThkcNbaj09jxXrQswVmlA6U07UFoUJQDSEc9xgVFbT317M2CoDf1t6QNIO1Ca/0sDIDkcWFqaj5Ycs2TOHZyagIR9dkpJoey8oTMtxuy8M50RXq26oEiPgdjww8V294QSdle9MnP1/b3T/PZ/yx0PcK3w74fSnnUvzu+tbOpK2XQi/1+v0//q+ItnddZ8b2fv5oY3uX3ZoarectM2xvMXq61pZboec2PbfyY75ZXZ9yvbFc/yC9p/uWexvNZVR4aJrne7NFQeoLjqZlT4Az4VCJHqef5DAAAAAElFTkSuQmCC",
    },
    {
        "name": r"TI",
        "sumerian_transliterations": [r"de9", r"di3", r"ti", r"til3", r"tiĝ4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAXCAAAAAC6kJmNAAAA+UlEQVR4nJWSXXHEMAyE9zolIAqhYAouBFMwBReCCyEULhB8EFQIOQgyhO1D5qb5UWZy++RZfWNbK91wUC3PR8cQ5XasHSVKo5H5CgwEayis12AgsVi7CmMgGS/TjZwdW/KH45b4g8nx7wFV9mbmDK/HagJa2MPMHp1ZgUbbBFupjKDun8zksFTn/KpJY40UkJrWrNw5EkAlMleKiATIaNwoRAKfQEzoU3/lUX6Xwzg9+v/doeQJWLJdfTyaJg7H3oMqBTCOG1samZxMRJnh+MrRS1BUDx4AURNvOoN5k+9fcLf1+e1vWnlnBYHyFo0T2tvYc53Q3bf/ADFanA0GcwX5AAAAAElFTkSuQmCC",
    },
    {
        "name": r"TIL",
        "sumerian_transliterations": [r"sumun", r"til", r"šumun"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAANCAAAAACS8iExAAAAjElEQVR4nHWPYRXDMAiEb3s1gIVYYBJiYRZiIZOAhWhpJRAJqYREAvvTpfRtu18cHzwOwIt6PM39ggTBOSuzDKpJHVJTOsokpblJiFkTcnayZeAhOW/106iJdgAvYAFqZeK5NrZIdSDsgFiz8vQxuR/X1VrEVdw1AMAZ0H2unQHkbzLZT9Ha+fYPlvAGbok1GFfkj8IAAAAASUVORK5CYII=",
    },
    {
        "name": r"TIR",
        "sumerian_transliterations": [r"ezina3", r"ter", r"tir"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC8AAAAcCAAAAADUorlzAAACRklEQVR4nI2U3Y0rIQyFv0S3AbdAC6QEpgRSAlPCTAmkBKaESQlMCVAClAAlcB+S1Sb7I61lHiwfjmX7wIk/mfY9Z4zOf4MjaYwxxnDPUL7yfb/QlB+OEwDpfnvLenW1tiK1646unbqpkvU2P9JLAUmgA7gAZhgkpTRKaiW1FpNAGEM9iw8Pu4fkUE0hJQLShirNlKZK04Aa4QlvQ3BDCAVJAUnDAoSIT/iEbwAMD5yx8Z679wfB3VVUVceM0kB/nA4vUzz7cD2IZuuRm0pbVvE+I9F9ndjT/plancgdUZuqgEiHQ7kAjBf/4L8cqdeLckzOcHE6T95jTZ+nLX/6NE3TxxU3GoQmktJHv2MBfPz0l37ZZrHM1fVJmT5Z06d6vK8P9CgBvbf9sc4EuoGNYAPoYb7yh9FKGu2hEynunc7vwBLwO27H7UAYZm+aM0Bfv0zv1nFF96J70bWZnhxrD3Z7LkKafUhSgSggBggplpZK2UvZd8CP9sG6J9AF7A7egxsKpDRJQ+KQOBQgwz/hy3BIcuimsE3QLfDZb8KXt3kunk2i2iTkasPWdRT10n+H+qIfCW7NOpJ1IS+h1yWu5BCMETE/iKgkcaX5JQ3rY9OxNM0woYzv5oHzpi11M6reF45jkXv1gnHH5XQ7Pv10Oj1e7vl2WYysq1XXY5Fr1kw1Yqb5l5/jTL4orY5JqfVmud1snzeO42c0nKFP3ZE3z1o9a13YNvsbnDPQr06xdrgCc4WZBTju5Mxx/FAt+PfYxB+otQD/AaA4eDSAd9NYAAAAAElFTkSuQmCC",
    },
    {
        "name": r"TU",
        "sumerian_transliterations": [r"du2", r"tu", r"tud", r"tum12", r"tur5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADUAAAAcCAAAAADkLqhSAAACV0lEQVR4nJWU4Y3kNgyFvwuuAaYEpQSmBF0JTgm6ErQlMCUoJXhK0JQglyCXwCmB98Oe2dnMLpAQIARZfiL1+Mhv/B9z4YoovwGg9q9jWT9FvQEkLsduGkg6PGVg7Z8Hq1HEhwBgLjAK9HKsNdIXOXZfz7MSBtbB5uElxvoFLEesJygyJQolKiWMEm7hyysk5cUiMoBFDcwjmUe24bl6iTwjmp7M5FzNeo+IiDkDYEzN0YdEHxJjSHRXQszNw1vvMyIiRm9mOQtYAN+vRXe2kthK4h9bbpuWn4C87U2Wbdv2netrsovXQGdInpF0eNHRPFu08JDX3y2OVT0y6gX1gswVGVFbhJmPV1S7fxM3WKaQp6CRkDF7lOQ2uj4jtK5jPOq/RIK1Hm4GyWehzW593JnUuo62CNaBbwCst59n2NuZ/fLH/f6SLptq2rfrDmD641G+F7EOWAqAlNWHl3c2OpyaL89kCWApoc17H03+/v3PH9rrC5858vEeO9+lPl2Zy7scpYyWH7EA1DvkSGQXsidkzBpDepTnu7WNKg+Ueiyot4fLiJojfH4AnQHPzlNvkdRjUfdlcc86euQcdcSR0wfT3gEsag7zEjVKmOdpboSWSItHxOhmS35iwjrwPe+XRN4vbdkuTfY9CRvslZ72yyaSVAXYbhvXdxlL8yVow1MbnorPXKP4Es9tqfnRX32ebFQPPXu5oFFR9xbrJ3rP2eyOOuZGu8+MCeofVftsj3rRXGCe82mtUOI/oJgGSUH0mIm0L+bhBx3+JbBvcNvgtgNvt69QAPwCh/iUpQxn0U0AAAAASUVORK5CYII=",
    },
    {
        "name": r"TUG2",
        "sumerian_transliterations": [r"azlag2", r"dul5", r"mu4", r"mur10", r"nam2", r"taškarin", r"tubax", r"tug2", r"tuku2", r"umuš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABE0lEQVR4nH2T0ZWDIBBF7/GkAVtwS6AFtgS2BFICLZASTAlrCVBCKEFLkBJmPxQTRXe+4DxmuPMYgFZeLYeYRUKYRRrISYXuIH9n0pS5A3gZZ384oMR30rPIrZcq5jDCDQBtmGLe5zv9WBa9SNBHOIJ0BdNVIngBbijTpuFEBqChc0+lrmTAjx7AHq73AjQQuwiggq/MWxsDiNbYIU3bvt3LmUdvmTa92KhFAzjZO7s2VkKnezpprMQw5Ur9kLN5uQr9XXwgWh/f9dU+G2hTfXshNzLvfCuuldThK9ZoG87z54zc/dZOf5An/d9rNomMM5cVvGDrMRURWT03jlQzozQsY3r8I6UsMJ6O6SaLvYByM/AHogqYzQWsmDsAAAAASUVORK5CYII=",
    },
    {
        "name": r"TUK",
        "sumerian_transliterations": [r"du12", r"tuk", r"tuku"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAAAAAADXsHGAAAA7ElEQVR4nH3SUXHEIBDG8f91YoBKwAIWthI4CbHASaASqIQggUi4SAAJiYTtQ/qQ3IV+b8tvZpdluLG2OWyfuDA34cE5A19T27aa8bbJnffEqrGupdQSLhSn+hQgqrlitBgAr0EueT8VLdMrfRwLMek/bstYxj7n5d7SGm1nNoCJVSfpMuAnrcF0GWxcNbkuA2PRZ00Dl7EiAvnnip0XR37kBm/sReyWv+cNgMG2U0vPkvNy2KqO+9VcUtUpnN/kFgPMDevMlue/loeYWmJRXaN7lT1BzajP658AOE06dRVUSx9B1XZtgJZbl38BDBd5CVdb5Z0AAAAASUVORK5CYII=",
    },
    {
        "name": r"TUM",
        "sumerian_transliterations": [r"dum", r"eb2", r"ib2", r"tum"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADcAAAAaCAAAAAA2gptyAAABj0lEQVR4nJ1TbZHrMAzc3hwBPQgqBD8IpuAHwYWQg6BAcCE4EBwINgQHggNB96Mfl1yTtvN2NP6x4420WRnYQrCb9Ct0jf5HZtS/cemRae+0e/i2ay29ln2O4oZpQXj3RQCF0/xcmHzVFSKSAC27p7JD5alnHhnFYIQ9UxxpPiEVx/uq+c8n9R07JkOjIWOmfvobXIFhnob13enqhpwbBwAIMcdQk9QolQAgaMx7UbC021KwCqtY7Vjl6lntYzwAYEOTn/HVQt31BADTdHPPfKrdLdmPa4v55zSJ+hmw6/9CUt1w7O/p5ERqcS+ga1EJgCzT59B+7brEpjndK2XtrAJAauFuKy5tXebEPKMUlIKyGBhgc/JVDACfQzl+TWsdajbrOV1LSkBoUaRqDTVtRiKEtQ4mqwc8AYCRrDXsr5y5FQDw6kFwl7UF985LNrruwD6qRv9aKvk3Qz42Td2TXb8IwwbpQtPcXcwctnU+TOeywVtrMA1j2XvUNok+QQ0f2zpj+d9hF8fzns+w5W+Jb6go/fRxCBTTAAAAAElFTkSuQmCC",
    },
    {
        "name": r"TUR",
        "sumerian_transliterations": [r"ban3", r"banda3", r"di4", r"dumu", r"tur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACD0lEQVR4nHXSX0jTURQH8O/v7p/9yrJNgsA5x6olaEJIRLPS8EFEKDJ6KOghFkTQS7jqLYIVGuXE6skh5kMhSYwwGbK2h0n9zHTSRls5Y4VoFG66P25u6O1ha/78dbtP5/K5555zLhcqpVwmk+tcYxVgLHkyLgSUOpM6qJtnuTmddkzQtRczNp6VbVdYhRKtna89FxmMMQ4obDTWAaDF3WPgGG5MzOgBABZH045/edcrTyE67rmp22oEIEhhZzkAeNu0PQ1lUo77OPMNFQCkrn/23NkvYg7QdC8ND6Qu+QEA+2YzwuCnSJYUBgMoaW7i0ycDFEDZqXVnzP5zLJLhiqyqmh6vuRZ8C9Scb6TZsJ/siS+Rv5ern5Kr+noTP/S+0RSddMTnhlxTovKagfsAuLOjo64zsCx2HhA/KgBODoDmchvJJPjMy68SxioMFW2Vz52t7ccWqmx9r1fEg6kfG92lR1YtAlB/uq41GPv1zr+4TIqd07pDoYVuAcDH0JUGx/fe9rBvudi55uG26GVrVw4AsPdbIAmfL0pFrX15czicVxwt0fY6ZxPiwZ51qg7uzsfGCe8JhbRzshbK7y5c7PPMQcqFVfpA9mg8K1aQzbBlZP6ee6tuZivv6ru8CYDBWVQ2m6dv/9iQKgCoh9Phyd9PylkGgKvuX/nQX/sfBbjt1vVbrC+er01TI4YpyuQ/gEy7GDeDVjwAAAAASUVORK5CYII=",
    },
    {
        "name": r"U",
        "sumerian_transliterations": [r"bur3", r"buru3", r"u", r"šu4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAYCAAAAAAEmyiIAAAAjElEQVR4nFXQUREDIQwE0L3OGYgFLGCBSsBCLGABC1igEloJnAQsxML2g7mS8vdmFybhwO/IuDZQmTYSq+tNk61B3WikePT9NpUFwAlA3uEJfFaSbQQkrlZnE6AsTZY1CAA8XsjBjZfM8p2tmxXKeMfKntwCasNvEI0Tf4yOyuaE5j8CMocPM+vhu+EL6OI9z53h8HUAAAAASUVORK5CYII=",
    },
    {
        "name": r"U.GUD",
        "sumerian_transliterations": [r"du7", r"ul"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADAAAAAeCAAAAABPz8IdAAABhUlEQVR4nI1U3ZncIAyc5LsGaIEWuBKUEkgJpASuBG0J3hKcEtgS2BLYErQlzD3Yt2fjn2Re4EMzkhBCwDlq+wehg5D+xLyxudqYjvlD6R1UC+04p8y4PojGMSvzUT7WBfBspTTSZF9QmC2uBayVJRbqHl+pnmtTYqnmgGQ1bPiJ9GjGpotSjTql4xdBfsz8Afd3FPzRiMfjy+jC/X3a5fz4PR2/zfxrugHumQS3++Iat3lz+TvWy+V1PlADBY40datCLF5NWeZsfbEEoYOwv1xZVjRUSwAQrQUgEZDR4UQAKEeHgaMDoMQOOgHE7GfA47nH3YMTdwWU1f9fBGlNptUEebfvlwKn/CqhG5mEArV4LIiz+wkDlRmBfZu9BG7k+oWUrADbupdegmit7/FEehT1hSvIxv3bvF5DSh/yyILrosoRAOLw/HXDFtWEtPydqYtSs+TSZf+Cp7EuL+BtSutwbCiHzkVlcG084gO1HzOump4NMrf5uZ48CbCHYX9iHMNvhtInMpXqHjGMPBEAAAAASUVORK5CYII=",
    },
    {
        "name": r"U.U.U",
        "sumerian_transliterations": [r"es2", r"eš"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAAAAAADXsHGAAABMUlEQVR4nFWSUbUYIQxE76mDWMACFqgELGBhLWABC1QCFqgELMTC9AN4u90fwrmbSZgE3q+0E8S8z+AfGlV3YKvvYHzxXLaDqgjAo+elVUcyHZXg46VJ40pvFZtHBCC60qmhAkDX+NK1oyY/5/kNiD7VAKxLfdOp8NKovOs9KmDNc52HPt4sKYBNj0mRMFdk7NJh6IEsyD4DSWTvBqMCFPcEVFlXM6ga+92rAvh2o2rtTqtrRQBV4Nfvv32b9IcSAOw34+dJQNUwqiy5Z6jCmiq3NUhrxaSEdVUeRSia1n9Ms+lJBSjqSQlIPqvs5cesorn7jlN3gsdM+8/86Grwyd/tRp05Rrm9PPjxuNyscpdr939v7a5B++wD9DNBW0fHvttE8KOar07WBxPvYrablf8Bo/K/8Umjz5wAAAAASUVORK5CYII=",
    },
    {
        "name": r"U/U.PA/PA.GAR/GAR",
        "sumerian_transliterations": [r"garadin10"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAADZklEQVR4nF2Uf0zUZRzHX9/vfQk4PH54l0KCoGQgVIS1sI1AIURpmUIjLFKhQImxSE1KKwTJsRZp2lC0spaaFQFjUUYIY3LaiZTAcEAJHowbN/JQj+O4A+7bH4covf987bXP+7PnefaAM6IA0fUnSkt1b4Bi07TjtBdvjzjKPJnNsi3BQPXI772X1ID6VNcyEH+9EnRPefDMzRQJNN0lfWEAPN/o6qXyKB5IEu8qQqbp74FX54lsmyxzwnXarP7O4ztaB2IBCeDpwuaG94rW1nT0j3UtlQECRs9tfqpQUSVmjvbYJBAiKvxqDT+Rsc7mUJXIALg1D9ZbGnLMnyef/qoaXBO0pv7obdNtZYGgn+9sj2/itRzF15kPheyzXJD8Nu5uP/SSIbE5vwMQVSYAlDKKsdDA0Ccf0ReapU82HduzfWr0mr6DuZGlF8PsZ3MByX3EqGT6jlexWGkC2eYU7ALWFN8f3rUASCkFeWG93os6jTlB2nHcVhsBiLIjxRz9eAIASS79Z0fkA/5mrSov+bJVmWIWgalQo+8zxw9O3GsOa53YFdfd+cXLwb6GaP/FQUFBi7Zcfeeg95z1oq5f/OBqrjue3FB5uAJCsnx0KSpvpY/iriNl9JyNh0fL37ftPxMPYsz5icr5pH9ZsccHEAGm6vTB/WD231+7M/xfQA6wDAjcisu22mfLVvb3vQAs76joiAKQ3upZCJQbHp5VfOt7v9OlAQU3jzjJam1k1voNeTdOus/cu/qz50qvFWUnXjJZXS1pMmBfYdIUuNReaIrdWQISzCtPHTyn6rRtDmkfl31jBcAeYr3cmlTnatidfKhoVCLiSPhvAX1Jq7rydXemX/nGACAnbLh9frLldVP1xYzaSik735S8yut2ZPveKxMw2TsEQLCC8WGXx6rCt6bKqVLu8rTmGNtYg7YFQJBmTgxEe1zIAV1b+rAgvVn8kcOslBUFnJr7NhyeWYH7Go1WgIBj+qa/fJ7989aPa0UGFjqFNU1s7Otc7zIzdLCg67A+YrTljzVVumH1SYsAOIKHcLN8WDc9O1W5S94b1W2sSVigHnpCo9FoNJr0n5fUbJXur17wfdu349s9BBhc7CSJ1w8fcJm73+O69kQFwGCgEyTIJf9TENIbVwLwi58TrPj0vs/gP6caTKqHoccEAAAAAElFTkSuQmCC",
    },
    {
        "name": r"U/U.SUR/SUR",
        "sumerian_transliterations": [r"garadin9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACk0lEQVR4nF2RbUhTARSG33t3t+naHFttxZwmuGGpaShGSiRoqZCGKSYSZQYFWf4wtUItBxGBYWIIIeYkDVOppkGYRBEjdbrSbAv7mqQkztH8yE33cbfbj21avT/Pw4Fz3oeALyTDACW0M6JekB3CsvWvIJD4XDGAIre1Hpxa59oFaoOIXvRLAaBvDIBkcEAKABQAsE8nFVsAEE92hXNJ+0hxtCWAMmtfjQAAzMqisw7NnK3UrgdIAFk32JMZBwAwhK2Hw9aw2rQVaQAF8mRl0KTpynqncdorIWY7IsdLTM3WM8laKrT0lMYZPzrPqnY8WI+wwgKxaz5VLjuipDpSKrpUFo+MfjQzRbtFBLO277BscaXFvkTp98Rup3nhhvfdZoCbADoscuuw1uAFKNVYXdSXsLWaOQ9AUISXXagrGqYBgHQ8LV45EUTMevzfixeqtfRGF8rn7goAAJF1NUUXh78To5uIAQBkNA4cx785ar3JBRCfZ1eRbLlYErpZr2JoWAmghfa+hLjV5WoQBAjruiUHAITGr7uBxImx6AAhch3tfADApcfBQr5YPREdkJLW4H5mAwDCwC849Ovbh4JzqmWABCevSar/mSgAABbjzj8PW6eoSgaQOysbdQPLwru3k/lg1p29PaP3FMZyadV+kmpNL1PfEg/ReyMs372Kac8nBxeLjof3C/uoH7/lEsbL5qwGi7YxIQTLNRMTx48l2nk86uJoVdSSIIm0qd8u4WAyvOJjqXPGj1MMKFebqS7VRF7+vAAQWwiGzly91m32H//G1pzA1/h/9PLl5V0+CySAd2WGAqGPeETpDd1+PyQA6O9k5ft2hDXjTe5/mueoB8MBINvcy/tPCnYouACQ81q4OfsDKjL4K3vTaKQAAAAASUVORK5CYII=",
    },
    {
        "name": r"U2",
        "sumerian_transliterations": [r"kuš3", r"u2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAXCAAAAADSYxu1AAABB0lEQVR4nH2QQZHDMAxFXzMhYAqlYAqm4IWQhZBCUCFkIdgQUggxhBiCDeHvoelhD94/o6/Dm9GXdAMwcvGRkrnHmnHxngvRPwDAdOmUpEOSmnS+Ia4dduxRyZS0W9tNlhQAc8DSvDz7tjRnp1dwbdk2ADUPnGeCoMNwOhKsuzxAUlvBtABNHpJWuL9Tp0q1c628gNwLFDLU+gK4xXRbNv6oF/C9ArMnrPSf9Qm4kC8DyjtX5+oQQNg/hhnAHMjfnYEm9/waQqZehwymvq3/0IztfkTnyrcd5UUAvAuX4QgAUcSmgTAltc0P7vXE52OYG/rjZ7jz/MxlfNE8nAowXf39sX7Vp/0CViiupjYNLK4AAAAASUVORK5CYII=",
    },
    {
        "name": r"UB",
        "sumerian_transliterations": [r"ar2", r"ub", r"up"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB4UlEQVR4nGNgQAGMDe/cGXAAloB7/6OQuEhSTFJBOf+/izD9w6KN2eHi/0s9d/crYZFjcr9548iTd7/+hzJhyLH73Ngmx8CgN+HBBXt0WfaMTzN5GRgYGBgkVpy3Z0aR4019PZkVymabfzacFSHFqdFyp4wdzmWb+zER4gslPRO3uqNfC1HsmPosgZ2BgYGh987DB+//L0dzQtn9Kj4GBoaoXb/PrHzjgO74wq/dvAwMDFxN7+7dwfRa3tMpyowMDAyLYw46MDAwMIh48D0X+b3zOUTWv/8WCwODhgzDQwYGBgYGZgvvM5rH90K1bizSYuDz235qzzFGiP+nnO+XgsopT73gzrD7/f/r299aQkSiX2VC5ZT2nnNjYNm+T1bOUCjv1F8GBgaGx5ffQuR0pv7JPcrAwMAgoOjZdn2SCAMDA4Pd9lAGBgYGBscLe3UQ4Rdya60MAwOD3Y5QBgYGBserSzSRfMXoc3WnCkwy/eEEKQZkwGh38JQZg/2OUAaG9Du94uhBYnb8kq7OFm/dRY9y+DDCi1Fr1aUNT589/j8ZU46BgUFry///y87eNsUmx8AolPvixptFolglGRgsL/3/n80I56LGFcutMwyf/yO4qAZzTfx9iwGH5I/3H7cgcQGlqJxbdPa2XwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UD",
        "sumerian_transliterations": [r"a12", r"babbar", r"bir2", r"dag2", r"tam", r"u4", r"ud", r"ut", r"utu", r"zalag", r"šamaš", r"ḫad2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAABwklEQVR4nGNgQABGJmYW7dV/dRgYGBhYEMKq2jzKprZ8W18xoADG5t//f6+a9iWHDVWcQbDg3gWdphvqDBjA6t65+ztlGBgYGBiYEKJsCgZPVRS+/WVAsZdT3imWdf6SBqb/EHHZP+9//+XmknWP+DN56W8GS1lWiHiVxPFvb9RUDL9OXvKDgYFh60TZxwwMDAwMad//X3r0/20u1Di5h/lQo1teeLQ9ToLbvmGTKIQh/fn4nWSEq9JuaUAYHHv/L0Lyg/zrGGYGBgYmhr+Hb3fBRTW8Pl1242FgYGBh+LfzyhW4uGbDFWbLvwwMDCwMjIqSCFNOvI36xdZ1WfgEAwPn2s+mCImcH9OmfP/7P5GBgfne/60IcY1HYVU/b2QJMzBEf22528wKE2c9duHddlsGBgaTRy9SVv1uY4RJ7Pl/To+BgYHh2v/XO3e//L/ZGSp+4K0TAwMDA2Psh5e//zMqBBo+6jrIwMDAfOpSzlcGBgYGqAFiLr0n9wQxM+i+9kSKKgYGBgZ+w9obx7yKj2LGL7du0/kPKyQwxBkYuBye5kCMQTXsG9e3y/+wiDNYX4fEIpo4q+Xzd9jEFWX2foCwAOyQl3Hlmlz7AAAAAElFTkSuQmCC",
    },
    {
        "name": r"UD.KUŠU2",
        "sumerian_transliterations": [r"akšak", r"aḫ6", r"uḫ2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAeCAAAAAB2qHNGAAADiElEQVR4nGWSe1BUZRiHn7N7lgXlvmBkROCQjJlDVEAlkQ0zpYMpNV1GJ0Xjkk3TRSdGK8EioQaiIZxR6YLOKDmGBRbDRJotiSyFCiSbxi5r7CCF3AIhlr1w+uNw2F14//t+7/N97+X3gXdok1cA5JR7qYJGDaAWRbemRvTRZb2dfxU0L4144WHbHGcGBP/1Gjcubva9MzYxxqQHvx3+Eb42D1yd9KyrU0igyi2FdkrSr3mdJ0OXROU737icFeD5/Kru64VF/xqCPaSYD3oq1nRvX360WXJ2m8y5Xu2sG8w6cP1+7zlLJeNfT8T+JA33WCSXIcozpfnUYtutRuVWEt6N+yV6xm5+6/exvEbbfnPpKg/cUb944nuX+5xU0lCTfW9JbwpsupVr/IrgqvMPePAh+lMhwIbHb9OqY9dWNtdu1kF818vg1zBgj4XwEn26e298W+YLYsaaPmEqUNdcduEm0Gd+qJKp2rQmMwzu21W0qEamVa87RYcE3Gey7mqQKkJnF/xmVwyE9VcIAH45V16T9UevvFBdogVVx3u+AeEH82dddLU742HIPi0BTB0pf3WfAIQX36gTBAAi+ydPBs71GNVUBFhG6u+R95fyRxnc9fPwFr4u1YKK8bbJo+NzuNWw+g4gJP3HTAFwNG9/sP7JY0uMQ8rE9gvmRgUOe986ELzsBkJr/Omi4rP6HhHpcMVjn9ftHFZwV8PEjILbbB+OaeMuCeqOlb/pNqbNRIqS4Oc/cztaPwUJqj3r43Z2fKzX3jsoNUp/16cKAMnnPor9YvRyutw7hHaMvziH62qPJ7Q4W/67ad0qF083FoC21LlXwZMnTPpoBVftvlg9+lmg5ZMkABZlm3cABJ3QBxwv1QJLm64+/+f5OIV/RnIVarBuACA471KGLN9tyJVtKkn1X9uX8uX6xbO2cuyAAzQAEYWpO+tk2fSx3V8CRCqtk23nEvc+ffoHOxA4fGhwttDyPeEF7UrVb1inAsRMF4A2bVP2c/VnRsSE1q5Z4OGCgVf6cIcAoJK//HRDTnF/Zs2WlctaJgHsZBy6tseTVmxSHGptTXxqq07VjiZc8Hlk9cbDVbcW0N6hTvruYii+VV2matuR+cka+Yt5hMs4em2E6fLOcbM1bz4uqeYrRBu2AQSdMp9YkIsIE+a9zorIToCxg0stC/B/hqR5iuadNvm6an/cAhyA/wH0Q074j20eEAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UD×U+U+U",
        "sumerian_transliterations": [r"itid"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACdUlEQVR4nHXSa0hTYRgH8P/Zjm5jimerZassr/NGbpSpTZ20lkqfrEgtDAwxCzKzpAzsQ0YlSIVfiiAqSdCM6DKwBrqFt8pjEpn31DWH4XI6dZv3nT6cBZnr+fj+eB7eh+cPrC2CwyXlr11qACDXUlD45uBoNdXVg/V1Y4WZN1Q7LvA8mE+RsVtZMhrmgcDhpZt/jHQEAABIvmvpz7uPjyhmZ9S0v+STk7UsgWHavgpSJIqOCZcvttVq45/yCNZiz05ojQ6OX1iQkG4oHQJg0Mn47CT+wK9KEzOvv5wbAAQGAxFUmjXevezVWfmLgXxE6QoheXsdIe/VvO8l7A6cTMbWkQzqcctG4a2PsVSNLhT1egnbl8F0RkBYbj7uddF+BaUzmcCJyWjW9rYkY1M5Q4eem+nPKpiiIwHpZD4JgAA/pEeVF8IRPU9aoWwLstZSKop+6MybZb8jpmfUhcxcbjbzU3X/Hpna91I7JnbfYVG3qnJN0AqHaU4hNnt3jWcseVfSG4ZAyI+APKofbkt5Nv6hQjtZvRUFzgdVCytMGbjXRtOBhMYxRWiN5ZDiszUW28dO5thNxVJwbzJDKiCxrwqBTa8kcabbfsTXrpFGDQDOHfubvhTgVP9+pHUX4ZJZhQZmYDcACHofKRtGnyThsAbeOQchrtiD+uVUAMBpxjJoHTSON989JgS4gEiAzjohABAWZ73eZvWSxski/Ttbm74BkLUW17oAkBqHZQ5Ab7sfFZxw4LzjXbNOafviAgDi77T4+lLKXfJtvPYzE57C5EVtyZ4qE7CZ+MeWbbbpBcM8e9r1rYnD7okebN/g1P9sh7Tdbb8BgNLqOkYKBUoAAAAASUVORK5CYII=",
    },
    {
        "name": r"UD×U+U+Ugunu",
        "sumerian_transliterations": [r"murub4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAeCAAAAABlfzOyAAADBUlEQVR4nI2Ta0iTcRTGn3d757Tay9Y0tDWTyDEdWbPZDbUyyVKTVBIlKpOICpGKyi5EJRUGYTMt0VZBGGJQlFZombZcomne1kxWq2XavGy1Oa/MfPvwbn6I1M6n8+F3nuc8h/8fmLYIFpsUKSfT2ADIaSmf1QLJ4o3eH9/8nl4JQNwYTbfctVynZqSAWJ1uyx5T+CwUwZVpxjsagoC/duNwRlytB8X3VwTyzAGVVgYjJ6YweWTdZ5sD4PO81sjlHvU1R+cXu7EYbHeZ2YVRBy891fUTHImvX5s6twlA94PtcxnsZrDqJzMBXW2SKXIlPpY2dKpByXRYjJr90g4aAFklL2u3EwCACR/Wy0+Ch1nDBavUbpkBCV7ZrfmG9S/sAMgFLX3DBqecOfCO/XwR0lNDEbvjlPuhwPzht6FCOwCMGRdNZeBpLYlAoukeYjorkNyfw8Xm75sAgGzqTrIOMKb0otGsh5zEPH7h1gJhcdzlyapxvB8M1YwD5GvhRUMPY0rzSm4sTdleFxUR1ShbF9E71CUK1lWv5vcBxCuitNXdacputualH2l7RRRma7mHrXtSREU2a8SGDoD0Flh+/XBGYNlQv2aZfaLcN8w6KhaxyU/t+yfIrGq+gbjl6Sl07obfDVfNiozl/uHx8dxnVIz+gDbutsa4dx77HAmfd12uFyXb5zjXdOx0kO/ZsdP0GY8YqVbz7b1+Z6/yPqpHk6cOIv0yehwQlNVy3C8YpAurn4jxvFPfEQMQRUKbyOkJ95CKENU1m6Q8p1D8WJ8Srcy9ceWE8UAlQA4ovFo+sAGAdqTpldvSw3OfpEpgygxATX4/RsYzKwEQFSPZ3b8YOYVK9IPHsnMHGrWPesBxYB5hf8DbZQZAquq7XasliNQlX60OviIo+qRWXavBEHyXqX4CAMFxTCUQU5Y+GgApoHxC5StYdVXlwTlHagCAwL9rDkWtCJMt4bZkfJ6GcBWL8o425vEAzPSdMTk4ODD2dogZmVFQbjPS/4GttXRhdszLr9nEdH8AJUYi0JWGlrsAAAAASUVORK5CYII=",
    },
    {
        "name": r"UDUG",
        "sumerian_transliterations": [r"udug"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAbCAAAAADehRkCAAABSElEQVR4nI3QUZWkMBCF4X/7jIGsBFZCLKQlpCWwEtISGAlBAkgACUFCkJCSUPsAQ0M3M733qTjny00RrDPgLeA8YC27DMkBlaNRTapakqpqUm12qNFGdciaIBaXYuq8hphdjjsUNBKL75IBcizGakyQh2I2Y2LRAENUuxxpYNAaGt1V5WLVQa0JLjABTMwwIo+uFo+BnhEuHOKHjX1ePRYEXtRoc6jWebqKX8cnJfyts67JplJVgA+eYqtp3G3QEw6qArBUf+bdmTuEw40ewLa3PfrKo6sHuI0nZuuyNTNAjD+o7ZmmuqtO1AdAbe5hYTOSJ/lmL5nXLqF39gUtNxrp1k9L1/7+dcjWJVezLmblOp1v72jnqV1etT9FXEwMy+QBxlPEJfkbAiJ3EF5/DxGg0aDutOAQV7R+r7Al/YfCqX+PoBnegH8MGZyNOuTNNgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UM",
        "sumerian_transliterations": [r"deḫi2", r"um"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAcCAAAAAA2fqIKAAABV0lEQVR4nI2U3XHrIBBGjzRqgBY2JXBL4JbglEBKkEsgJaAS7BJQCVIJUAKUsPchdkaKrzL6HpjZ3cP+MABs5DRyTlWTOQh1O+vmTJumsvF4M68gjmEHFv6EcZw3HmtoqwhT/6NCK2AdOEEcCIXGynrdY6lWVVXNSbWqatYgNbFUAzV+t29QXaS6HGOI2eWQwg28RvVA1Oyeo6iqWq+BXM2lBpYqQNYM4HXRPFoAs4TsEXXEBHohZICgARgKV27hkVPKRAEaX0sBmMcZ6C1j4vNv13Vd17E9mb0Gi/2YntZ6yDG4+b0dhzfgdD/F0fs0ngPvJiR/dGW2pRtvY4yPae3xNAOIUMpXo/JLRkua3+8Py/4CuvbxxDAyHYL99e2bQ+R4rP5zc4xrc+mo+v6Gz0WWUw8xZBP0VcCPx2WKu1Du+93Gv2bMqvnFLbcXTvTkV+H0P1Ue+gfc2K71lbb/KAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UMUM",
        "sumerian_transliterations": [r"simug", r"umum", r"umun2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAeCAAAAACgDakjAAADXElEQVR4nJVTbWxLURh+zu3p1mrvvtpO1RrGqogRiREjsg0RH7PERyQWn5NYJsFiEv7wA8l8hJhvwg9+sBhDmPlhhk2TBkFtM2zGVuu0bHTt1vbeXT9u711nlvD+Oed57vOc877vPS/wL0GIQmE4yBVFA6D9LARxFQYZkiZpxxuXmrmqwADalJWsVau046eqBzlyfwiC/fj3K3EAAEail4X6nl4oeSiUDR+c1YLn33JXdmWLIFs6UlHY2+poDnyc9rdCdLd6H7tSxT2325yg1+sS4tVJ1+unbHWtZQbrGdOqG5+EhmSxzvsjNPYAGE2wyZma+3L0o+3df+qVpul5lrsVe43zmwCAqqvTjPXMMLMqleG+Z8E21ukPN0ut6vvVo45KzFqhL1/vQtJ+sXA6qj3fIZ02+5Ilw9LUEiQAQEyGYIMz0ZCmLS/xAKji017xAGiooFO+v7XFUsuak4iIjClw+GcIpw64AACfHEvKPABgOzPTrGVZlmVZbXKF8GCe7J/c9nPN7MZ9RMIFbeMAgBzNYL5+EfvTp8moy3PKDnpuQ0tnbSEvYatt800eoJp2GogJcyrV1X4DlD3u5I59sgGNjYsrvQDNrLlcLXFRD+Ij2yp4QifcEkiY1Vy5PNoL0M+7vsmSODrwFTqLy+R99B7fxxSrB6D2PSffSayPIxF6gY40K4MS6ni1KV1ZfIfz066MQhrodDIAwFqCEQ4wE/f3HJNA34kFDXU5h3CZkp8L3Uy3hwEgkDhuQFYgW+5+kPZvmt7YcvwXztC0UUVvCcMAgBCry3sip4jeYOh+1JEtbRJuyF7iW1fZTU07K2RNvCfn7B0nCAAInGqev2Z0QXdRe/ir18KvKgeoZkK/g1e43dtCbQIAxFihwfYvX1ePPV0qDithdt8DQO2LMuvIjw4CANHDdcMOO7wCAChjDRuF4i5en16Yf/GaDwBrLw0CoB2Jc1O8XEBsp/XZEVuvdGPUHO1DAM9uZ27aeq3Ehym1HgCgmcpsJ0/E1PWn71VH/MP6EQDgf/2uYum6NedfjDnsBwBcndQv0T3fEdlaVn4zqpSNVe5ma7g/ERqFMQZDhDLRfssAAGA6I2je9WsoR4jG1nSJjqEkf8YMxhb6P0f6Z3F4/92R+j48Kr8BoRs0/ZJWl2IAAAAASUVORK5CYII=",
    },
    {
        "name": r"UMUM×KASKAL",
        "sumerian_transliterations": [r"abzux", r"de2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAeCAAAAACgDakjAAADrElEQVR4nJWUbUxTVxjH//f2FFp6W176Yikwh6OpW+iMmYxNJ6FsynQpNSSOZA1jA7JsLhkaXTK+4Bfj3FiWzS1s6vQDLlMZMmImbkwBFWVrGJJUcC4iBelsaXnR0ktfbnv34doXZSTz+XLOefL/nfM8/3NygP8TFCUSqT/h9qQCIIkseGHklwC5hcxqbUUe1xN8KK0ry2ekEmb1WukSwjrL87YvZ45nAADoWLoyHL185OAFvn3F0qrKB6et2+fNwsIc21K0K3DHfjt4a91/NaLsDFx0GYU515iXpVIpszKluT+OrvnA9Sa9VE/rqk6P8zfyhT7PZctsQdCy0JjTaB16snfnwqN6onu+Xv9z117tpjEAINK+Iu0onZYnMdLcTBkGnnKyD8ySSqL3F6UpapNV1faWC7n7hMbJyrvv2mO7vXRMX6ofc4QoAKB06tANp0b53Prx6gEQuidaNBwBQMI75uLn33Hor8jzcilhpS2AnS2G/WZIAdmmiWvXX2v3AiAz+1un5gQNT3PIaD4f45/tkjePtzgYWlU2bN7YgvamLC8A6vNS+p9JwZ+orHSkzpno+NDbjmmHj/nIsjGweHgQWzuqOyIALbvrDioYhmEYRiGTnEgAEC9O5xvl1vDEocmqsUGUGFxb0gAQU39rX0yT8mtmsq28l2uLutV1Mv+O4u2+j0+fKk/1AfhNk5BoLjckAdKvut8ApPvY73LwaveQ7+JRdgMAYmv6+q+Yxs9RyUeQnFWF+Tm6Ieic6tnUcMkLKQfOcCyZL91FgnNOGgDk+lByVfQze7PllcPvFVZXZn2Rsn/D+ZuWT9FKqHtbPPSClwbAUxkcHgrR5h+meu3u17fV/47dR+02C3vkG1K0cs91iqYBgE9X1l2Kl4hAKHwOhpNrm9Z5Gl+02/64tM3ir/llgeg+7IprMr2Wb884QQEAz0leYfufqJWy5uDJjpp3/CM+faTqJ4DInk4QEZHH0xCe4gFAYYAMOyfvVUyJe3oD39tcoOjGswCIbatphJp1UwCQukKZ1mz38QAgTlfX8gfmI6ri9zeXH/dfA+S2UyEAxK15ucDHBQU7DVc/GwjE77OEuQDgaqepvqHtoB9rrngBgJjEZmeEEkpXtZztS/pJRrMBgB251V1RU334z1XNLADgRGFCohzcnWQtJY+/GUlBbY/ntuGBP8n2axVYJsQaW6caAEDPJaUjrvvLEWGS3j8vEMtJHo1ieiD8eMT6CRcejzD+7REm/wJSalk+sBCcGAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UN",
        "sumerian_transliterations": [r"kalam", r"un", r"uĝ3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD0AAAAZCAAAAACnNHkVAAAB6ElEQVR4nJ2U0bWkIBBE79ljAqRACmwITAhuCL4QmBCYEDQEDQFDkBAkBDoE9kN8w8wb92P7Qz3Q1V1VNMJ1DCFspf+4lfetbP+AAmoLfv68ZXa7GwCCuYZne7Flc22d83CuaaswTbGh6KvKczjeYyleVUK5lOKfKbrU3nnzcx7HPPs9+zFb8AHoQJjcMEWRCItZ7dqyrWVvIfWiBbMMiF1WSK5KKPTlKk4iwz7rbTfz7u2+HygFXRYowrQKAL39atWdkljGKSUTl36JagKImJXuFgTU13R6mdYWvZ4WCpGkECKxLijo4uSIq3Op+qRCi9aAVy90ajgxi+qY3F1rtciZH9sco4JWSj+ivKNFDQ6g2D2c8o6DaDqMLvTBfzTUZdMBJPXs+DpcjyK/jdH3SLjH3tyNv+HjAmD8I3aAjWYWOYUG4MleljSkmwBxtbLCikg1dqIDXExvop7DqoTp8UP0EYkOwJg/y6nb3V4yysp76bODwK+jiHefr4P6uHpsRY7eX8r777tR3uldoaloZTXxsMLYx0vKcInWZ+9RLY9qs7f3NsVdGFajA+DbtB/0vs+uKXN82gOz5eZvYpp/AzC2o6cOZ6uTxUIHU2pGO76M+evU14k6nqYyn/ifUKz1vK/DXFouCfgLrSEJ6xGCU0gAAAAASUVORK5CYII=",
    },
    {
        "name": r"UR",
        "sumerian_transliterations": [r"teš2", r"ur"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAbCAAAAADehRkCAAABF0lEQVR4nIWTXXXEIBBGb/fEABbWApVAJaQSqIS1QCUkEhIJREKQQCSAhOlDsvlhk+194gz3MHM+4ANPCBmj+9bW/aTrn8CKJwxgNDQyU6NFRKLapHUPaMSZTizgRiuGPaM448UCjFFLA6AkjgcJFb0RB4CRJHOfbqlsWElpmSHOR4GTurBUkgZuAD39XMvkwsot7WINDHMt8EIgLNY7MhwsnfSVurMm5c3/Vg7qgTq1qt16yMF2/XQUVGlx/8quDGzDCAA+jhKtOt3bViLJnp+w62iYvk9ihWMSv58XEjzUvvfFzDfn79fK2nHQ41XiG1Uw2V+Os2IFl+QdQHXHaJX74vVNxT11IvE1y5Ikzfk7OPD8GG/5A+rQpYEDZ08cAAAAAElFTkSuQmCC",
    },
    {
        "name": r"URšešig",
        "sumerian_transliterations": [r"dul9"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAdCAAAAAAI3PofAAABeUlEQVR4nH2TYbGkMBCEP7YwMBZYCbEQJORJwAInIScBJICEIIFI2EgACXM/YNkAe6+rUlAznZmepFMwrHFKlTWxd3YanfuTOPDOQacbHE5VdZEPibDngEHbdtAO8LNXm5GQWdt2UA/IK1TLAMBr7jjBLKHSLdborBUAXs2ZhddZdw0v3Uph9UJCFu2ODe6tY5+tha4FoDuU2ndRwrZrEZp9WHeU/zQKAK16GvVZ7pHNEwyABBenrk3Z4eas1QYDiEQqM6X1OytFCQKpxkiNzc+kzP4jsVn6lEbTxNG4adNxpHf1/oXXO84dqdahXfu6KIrnc1tFUdTXWouqzx3xyWW6jKw/05V0m5Gx/g8JLN8u+dLxEeablC8dJxOqW1QMSBZ+RKpXc2V1FgmZt8vE0zfM+a0hRqwY5wAEoKy2b8xIjUyxkXE3xQiUwszfPrfJHKO40fTZsZSWVJ/aMTVrGu15cr28LcAu3cere+hGArdUh+9/gffbeuMfj9jK2adgDeMAAAAASUVORK5CYII=",
    },
    {
        "name": r"UR2",
        "sumerian_transliterations": [r"ur2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABOUlEQVR4nI2TbXnEIBCEp/fUABZigUpIJFAJnIRUAieBk5BI2JMAEhIJi4Ttj3yRC0m7/5i8GWYXAAuRdPhX3ZoUE/pcsuYM/oA1OqkYM/j5c27OQoZlK/YXSUh4aKt5oUPQrK7gsH0diPmqXwp7J+2lO/UmeleshCL9WRKfydM95orTMWpddAY0s4bO14HYAyCxBTqwyXXNLQEAibhqk40DAKggLL5e5U7slDmqIabVYwqbGm8eVZ7wNTeYsLJ1mndJ31RX/bjoyo5zDL9MqgqseNl7CFmLtWCC3So5IpFh/nV3NAv8NrqWB41D1QLcjvKjUVSgUYQRv0YqjB4AYI42KogF2vcYJ6W8OLBXe7h4kYB0R6tepu7Xwyp3sVQr7Fz22s5jAIAVDna9NBeZAQC7l/sXvJ8GA79HPK2VcVa6VgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UR2×NUN",
        "sumerian_transliterations": [r"ušbar"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABbUlEQVR4nI2TYZXjMAyEZ/ctAR2EHARRcCHkILgQshBcCCmEFIICwYZgQ5AhaH8k17pp0rf6p8n3xmMphpqITfhVfZ5qqri1ku+P4A/4niul1MDX72NzNenVHqXjmyRimodubThGVnoHx8fXLKrv7ivx2YlHmw69RbaKt7hLf+2J1zrKObVK4JSYd50BVmV0bR9FRwBifoeO2rc66yAAIGahMekDAICiqY3uLk/ml8yJcqp3jyVsPY39pWsTzusFK+6sq+sp9Z+47lYAAL4SqCwwpz8r3E31b3bz2tBcCoFKKZ7Oy6bEwmNEImZ5HfJEk8WsoowYnC3wZnSDZv6fSYKPToDgnAGfr1O7nEgYAOLARJtVvi6li+oBSI6ao0YVyW6N0fMWBkXzgJKT4OQpxi29wPV0HQMQNhl2fySgnjHQ3PtSmZgc6PX0pxpMw9i8NgM+jmk/1nItAGYgzJA3KIDm5Xa0TuM4SNs4BX4AlcHS8da8oBMAAAAASUVORK5CYII=",
    },
    {
        "name": r"UR2×U2",
        "sumerian_transliterations": [r"ušbar7"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABUklEQVR4nI1T3XnDIAy85usCrOAV6AhkBDoCHcEdgY5ARnBGUEYQI5ARxAjqg/+IY6c9nnScpeMMECXSAf/C6VxzxbWlgj8SvyF4W03OjfjyfdxclLzoCkkvnJBK6bupsMxWzCsxr7uFRF6dl/ixk006HPYm2jJBeVf9vkdeaqKv3DLR5mztbmfAiljYtmaSBIA07KhZfMtb6QkASDV2K+0jAMCwiia30IOG0XM2Jdelx2i2npP/6VqHt+mAFYvW1WlK/STXXe8wFQAMwn2ykeakOhYj8+zCFk6LiogmpxjFcY2ISLVMnw4G3JNnL067WbyJrpeyhEZFI0WOHOO+eAx5BIeIcTkFTnhG/rjTHPH2t3u7VcOwBqCfbVCk2cYeTNIIIUMPNnYvElC/0JubK5fOuHE9j2/Rq8TYvLZjGwAQVDgsl8a9FuPh5f4l7tvCCfALIvzUep42d6cAAAAASUVORK5CYII=",
    },
    {
        "name": r"UR2×U2+AŠ",
        "sumerian_transliterations": [r"ušbar3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAaCAAAAADpzOFtAAABbUlEQVR4nI2TUXmFMAyFz903A7VQC7FQJHQSOgkXCUVCrwSQECS0EkBCKiF7gHG7fVy2vuXwc5I0KUSZdcS/zltXS8XUSsG/gm8InqoppYEf/WtzUfaizyPpohJWWe52DyhnEnMF5+fXhUWu+uX804mSji+9mX8rQfMp/X4mPmriz9IqkUohOnUGSIRg2zizJACs4YTO4lud5M4AwKqxMfERAGCyiiZ3yKOGreZillIPj63Y2iU/2LbCeW+w4mBd3bPUD3Z2Wr91E9a9jPR9UzaLkS13zKrKwvvwnWKD45EqMqsuBqBkZVyihP1XOAXeAMzPLeu77tabTCguYwVgq3t2eTKUYWbuqh1cjx49Zs/DDBDc6QRLl/gx9/tNzLQ6AAYON8Cv5TdumOpqJipUqLhpAOD4duK70aNKFvXJJWePBk8XCag9PE0+rTNgLQDQK18AQFQZY/Pa9JIOKjkcS+OuYfx4uX/B9zZwAnwBQjzSy7aYaL4AAAAASUVORK5CYII=",
    },
    {
        "name": r"UR4",
        "sumerian_transliterations": [r"ur4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAZCAAAAADsnKr4AAAA+0lEQVR4nH3SXa3EIBCG4e9saoCV0JVQC2OBSmgltBKoBFZCkQASQAIjASTMuTjN2U3/3jvyJJOQmR/LiRAItXacCDN2WfEiMUvMEk3p9vwYQ0ozq7miV+2S9g5oGVBWRA8j6qAPODASoyYkTHT0TxXddOcAwd468+CHG3euZ1tMe+VzcONz0XnV5w4AdXn1WLNRFw7A9S83FEtXDvD8HFufs23OHS0RoYb3qXeaOrgxMHBwRaQVh8X9PRt8r7TVnUZ6u88aG0RQ2qYib1O/MyJSvCki2WocU9lPXqSYw+1sTaKMxONp/P9GrNhrBkT8jQJS2ktrALDjS/8FIcp5VOHG9poAAAAASUVORK5CYII=",
    },
    {
        "name": r"URI",
        "sumerian_transliterations": [r"uri"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAACLklEQVR4nGWQXUiTcRSHn//2issV06R0s7SGy0DLBKlIiCyhL0GRGVGBeRFaWUEkBjYDUwwhA8MKsYtKDBIkDFppWhopiFnEyjTbEsuPtQmKX+3jfbsYyqDf3Xl+5+KcRwAQX6pa8pT/ST/3adurhzLLWXVDcZeEEmuds6cHSPV2ANHRqAaSXLcDVDLe+TEskH1fNpm+7njvyLG2AUizi79nAI/IvKk4s9qSr/g7AIaqQgAqr4lHY6fpMh99UaQDqT3p3TSwtUFpTm7eoB+wj1jMLU1SqvP6oAIWNXML82ab/2SaMWHzOol+ORZFrFFQeSOKPfW/3twd9CN9PLTbJkOMDUVbYqxttAUudJZGacO0YTUW9ni/H1/+T3qZYRpVQUo7W+z5PSt4rePniCxI9O29ULBCocwIQGVX5zGCogLAWO++Go6I12n02qDyzLzPdRjN40XXBxMAcXoA9b2/FRIYvzkOBvZyu7M0QGJ/EkDxTCYAYl/dRIQPpKnq/Dn19NOBvrwhgOzxbICN96Nv+VwnUnrPP88AJNWkLsMrFL3WW5nT2nR5tm6ieH+DXRqLK/y8KOTI1cLdaSexjxalKrtdSh09O6qgxF5S4fHo02rKd7mtPlkajK7oXRD+qHAZRVOWkPes0AFIEVNvZ5aEEiKDNy+y7MF4QJVm/XArYDCp0MVcfLJscNJdZJEh1Ll0YGdBy4qN3O4sAEPtkR5zkKSAEwyvO3L4P4aeU8HjP9QV0yk94SraAAAAAElFTkSuQmCC",
    },
    {
        "name": r"URI3",
        "sumerian_transliterations": [r"urin", r"uru3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAcCAAAAADHdfmHAAABDklEQVR4nI2SYXEEIQyFXzs1EAtYiAUsnAUsrIVY2EqgEqiEnIRUAhZe/1xnWfam3PtFwpfwMgSYtaVLalIGgEy73mgZMWao9SecRB2iG9tOVmsXzjh6MWd46y1kwgr3U5VV8pZsfriQOsZBLwlA6WNaKivPZdvfaXhZo+eTY4ljdvOhusqJq6Or/TCewy0APGbZHKP8qBLvFCC4C6Bx/i3xw4XsLICRnsf0w/8wtHgAhbUzXPEPqDRk5uRcqX0kpE3xdb/PDUe39oOdpC1WznpCMC7eJhUaQJ/X44pRgbzAxOh90QmAei/WgPcFl/X7c90NQOnV4hVQnVyNCgAQ5/z7z5W6ryEAyCxvL4Gmvwhlq0AdazYKAAAAAElFTkSuQmCC",
    },
    {
        "name": r"URU",
        "sumerian_transliterations": [r"eri", r"iri", r"re2", r"ri2", r"u19", r"uru"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAABzUlEQVR4nH2SPWiTURSGn3tyY0gKBYVIUSstFEGD0kFdolBbUMGlYutQBUEXdVOE4OKi2VwEpf4OTupSqIOImqGbQ1W0Wo2oNFJqxGArMZrk+7kuyfcTTN7pvPe55+ceLrSo6+JGCVjlh6vEcZA1c3Jp6qeLATAmwLPpF7P1/r2pB9t3fviSSIiCr4uBUhPfTLlsalbxWhp25015xdgngq0zywfGljOTAwCcXjkz/v2KqOCFnLX680TT3Orp+XGwFpr90F8z4pmhvBkVwpqf82PJ5ZOgQ3y2rO1m7M4XbAhX0NWAqYoCQfcGzlRrLHRfHgo9IixBhm8fjzWcMbaPXABN9cnoha1P3/wWcGKy1mliq0sBmtrL1I3skdcVAXvH5gEvvT743IDGSsQj9dJi0QW1qfLO9cbbYAB9cmlP37GruVdVgHVL5/3+2fUK9NHI4MK5mcZRNObvhxiAXO8v3JyhreRhoXi3PUb/meordeLmvd0BIyY63N2Jo0fuJDtxExt7tL/hXCfQzAHQKPexuff2WUWBk0pmvP1Z6QVAg3ya3rar96MGKvF9XrrRBRuUjN8vRfOT0/95hVUzIIfNr7PxSPsJt9RPtX7jgP4BXQqfU5LjkVAAAAAASUVORK5CYII=",
    },
    {
        "name": r"URU×A",
        "sumerian_transliterations": [r"uru18"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACMklEQVR4nH2TS0hUURiAv3vm3vHOpJhaCIGKFWWYIlGLoBZOSosGF5lualWbIKhFlAXRqjatCnoYVm6shTFBIZLiQnq50BBdOGqmltjDhrFxfMzMnbmnRXOdOxfrX53//B/n/84LHKHe2O5yzlnh1jUh1LyvkZbyTR6v1+PRdVWoupIhrh0dGoyV1e1/VnV4akJFydXcgcm9R2xrNM7JaFTGjV+PfAD6YxlfSspRe5sLi40N4attlem07EN3XWC6Osukq3cgYEtrQ/eXTmS7+iPSbxPjqQzmOrYzFNTtaUPkvIaaRQxHQdHX0HKWcZMYiw0aDkJ1g9YkFku9oR8VfSOqEgIV17a57FaVl+PjI836xFtAABR0+oRVbL+rw5Z3/YfU2+P1ULGwGwSitu205ScBwq36+5KVz2z9OyeI9RRfv+UvKSgqKsrXAcw3QZr8hS270m4kPlbfu3lyeEWAcaBLAlpSjjbv65i1CMPrdRnhb99ToOyUACi8rnLdmU8TZ+d9pWce9A2vARSa1pHODCxYJ3BK1Mxe7E9nbsPalZKU6ZFoLZ9rswB7rN+PePnlZ7ujKHIg87bU1Rc7Qg5isRtGfkctgnHT2SD8CianLCUhNV++gzBXIJlYN0X4nhRvYJqxgpzj3cfSWikzbi8aElBRzJ5UR7B3WYFkTeRKMgPIvM0mqCCmn1cfLAmqQEyrz+owpoEiGjtD2qeHgSQbxWoKRJOMXvL886sC7EmcE/+r/wGtxrzxPLauggAAAABJRU5ErkJggg==",
    },
    {
        "name": r"URU×BAR",
        "sumerian_transliterations": [r"unken"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACGklEQVR4nH2TTUhUURiGn3PumfHeUUuCaGWm1CKsyUUtWkQ4GS4SySyKaBG1KChqU1RQQVC0qWV/aK2qRTFQYIISST8UpKEVOVii/dDKqZgZm0bv3HtaOOK5V+pdfe/7vef7gwMhqPN1VlibRdSOSKkqv2ZO1JY7sZjj2LaSyhZzjtPNA/2Fmqa1d1dvGB1RiIpINPlx1SajRvs3ncvpKXeiMwFg39RT2aJ+Z7Y5+qu99eepjvoSrXnZ3ZQciwcm6ep9lTRoY/pqdntw1paMbjEG445OVYTWGUjZoMpAAdCaORIphbMYzIFY1jZQVXzkA8OFfhcZcKgoaOfAk+RGC0CJNEis6lCr93uHOs+5M7EEyYLLiWAhRlKvc3NMIhs79tklpgEQac/sTKFn69l479tJCUU7P/NMBBzTb+JXLuwezEtw13VpwlC4sZg1Pfnjsw9i+XwD6uD3xNL9154OZQEW+cISxZBjj2wYOdZXYlGX5tYzWc81HdcvjV/sM4Q/bfaXFXbRAtWPBuTD8YkHZtExubP+xYdyx3HKLQSg8o8X503HGv/w87QnAfG7dmaXwbrAYKldz7yAIDWJhaYw2hc0ILESt5YYwryLSCjb1r2ldGbPnzKTrgYUwu/xbqd6JwUUGzInjXvpyiofFMix+/H11SkFFCKbAx2GIyBk+7105NONZOjWJeQ9kDt07rjzz68KsHL6kPxf/i8lzbP6YmBRhwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"URU×GA",
        "sumerian_transliterations": [r"šakir3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAAChklEQVR4nH2TW0iTYRjH/++799vh0+W6CEMzURHSdJgmdKALlyGYjEi760aCCJK8KTSIriovOl9Ui0qCNKhYKIm0RRgEVmrYSZcp6+Qh2ZjOue2b3/ft7cI5vwn1XD2HH//3eR6eF1hj7Fy+bm1uxfRGgVJm/hVsyUsziaLJZDQyyoxklThTMzQo5VZvf1i6Z2KMgaQLeue3kr0ajfrfPBTiMdl31wYAxns8tqDwT9pnmufq7YHTd7Ymwtz+3mqn15rSSY/7jVMTVvlvLjSk9loX5HWaxtDJPelrxhnyGLWhPXhCAEshhkPyimvIDsyPSoMyaArBhC2GhFvUXg1G/ACFLkeDqK3NmQAAsbayRFBAAYZ1lx2v4klEd7TsNZ+Lpm2rfW/3vlMBMNCqirYOabnO1YDPiuj0fLnd+WJHXaEpBjBIrgNnre6PixRQDNnFpddcMR2RsgY/DNQ0ZhT+AIHQ1HjjAobDFJArzFTvDVNwnSj7JqOV5c8dPQyyKOoi/ukZFSAFfEN4Yh7ghowsPVu/JO96SdixKdvmIw73SAQALPmbMB0g4MapWfIztpFcfKCww7Rs7GRfYhI946IuTklcplAspRSds2COS9/b+jQbeVszE+BphYsRvcXtKhYA1t0kdWkAmu3pHuH6rKrd/PP1BYUALPK0IKIB5q52TcoA3A0tz74UEAAMX+Maiej9W8vL+/Mob1ylAEC5YMtYlZi8ktgufOf7EzlQW3tmEon5km4gvELAcLB3f+KyVK5oj0HmHGAgcZfa4XEvEkApC7ZqEG62mAEGUO8T684cDwMgCfu0GhiNAYTWP/YL47edKfJJi6gAPcRDp0z//KoAULR0nP6v/hf6YvEcPzEq5AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"URU×GAR",
        "sumerian_transliterations": [r"erim3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACN0lEQVR4nH2TTWhTQRSFz5vMi++liVEjFMEk1hRRqrFIXXQhmFixYihiFARdqQuxoAsRFYorBX+7a1VS60ZdKBGE0toimJUuWgkVabRqaQ2msYmRNDYmeT/jIkn7JmjP7sx8M/fcywxQI3p1o6l2rSqzJBJCbd+yFxvqZItFliWJEioJS0TXvrHRgrut5cm2XV8+UQhW0Rye3LrHcEcwznI5VlRSfX4AkB6w4rzK3hvLnPsV7MhcDjVVrPvNYFt4ysslGRh5GzZYX7p3/jCfNZBlAUMwPGYxa007YzHJaDuyZ0VQjojmODtRGFVqCGoG5M05JbVBX0hooEIaIDA5+Ur2W7d91s7edhMAEIBg5R0/MRLpiGdobtyTKlU8AfGFTlTzMQBq3+zuM+vGm+RFojBcf+VmwLna4XDYJQDQSu0966ddR+1gAEBReuftuXYsukAAZecAA0xz3bZwy+uu/f1JBoBCsVhMSiYxqwFCIwMAIZ9wBbIfGut0AKCnv/tdJ+++iv4BgDW6AADqju0zyZeZn5sEAPQ4aZ4+H6mkMisAoKtrh7rj5V4Bcq8hHqoCZen2g5Eb8UVLXsz8eMiPjLa6rycNNv/ck+YJTIamjQfwUa8BUqe+Gi1hot/OEwoHgID4++uxjAiw4tDggcrL0vQid1t5poI+rD2KjfwWALU5e0ldAphtlQ5QgEw987Y6YxRAQdzLVZgQAYEEn6bFz/fDKv6lvAaQIyx3Qf7vVwWALaVOstz+X2HcwiNHljKQAAAAAElFTkSuQmCC",
    },
    {
        "name": r"URU×GU",
        "sumerian_transliterations": [r"gur5", r"guru5", r"guruš3", r"šakir", r"šegx"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACTUlEQVR4nH2TX0hTcRTHv/e3393uXa5kjQRrLZdI4VwihfYg5FR6aEg0e6j20L+HIKiHkP4Q0kMLCnyrRWj50J+HYlEwJFcPvpSRyrIHpxUjlTW0ae6Pc/Pe7dfLbPeO8rydcz7nnO85/H5AidGbVk1pbM20Ak8INczEL1dtEPV6URQESqjAFYnrB0dHMpa2vc/qmr9PUXBlvNb31daq6OGaZckky0q/+hwAIDxk2YTMvijHXPzt6li82ltbcC0fBtp8YbtKiT8w7FO4LTFvolOt1RlnToUwPGWhspJ1RkOC0u2IX+BBVUQwCZIvuhOZEQlERVAtcypqKBcDCDRmJUPutKpqdEaCjT2OYiPWuPWWu6YI8MfNBKSl9/SaPoYd2YaeG6eaeKMFQE5uvDZDkRk83G0PjKcIIAtpf7tYnShvqmqw9k2mKzUVMQPF6pj9nudEcJkA0j5/PDR+tnve7OkUjW9WTPp8pJZC0us10uLPaA7gqpmEzMfUMetnwexdoFsydXum6bmIY/uZ+++CKwBglF22pWYxFRl6ZfoEWKW3B6LUTep/XBoqKNVmK20m3+zwAhAGoKXvb2+GOzrV9Xe5/rvblk8Wd901X6MzkNfTc/2KC815HysPxmWTNP1yZ0wR0nhyUBvFZF4VWCoBQBjv2FQaVBMgjkcV6xPQHRk4VHhZuXxWmZQYAAouP5h7EgqkOECuj1+RiwAzlOcBCpDwC/t+c4gCyPDtqgkTPMAR1/MY/+2BT8a/LJ0DyFGW7BL/+1UBYPfqebJe/g827cfS/smKMgAAAABJRU5ErkJggg==",
    },
    {
        "name": r"URU×IGI",
        "sumerian_transliterations": [r"asal", r"asar", r"asari", r"silig"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACKElEQVR4nH2TS2gTQRzGv/3vbLpJU18IeoklPgpFDT2o4EGhscWDJYjRk17Ui+CjBxEtSBFRCoLgxRfRCsUHKBHEENvgoSc9pDXooVFbmppiS2mMJtvEpLvZ8ZDUzC7a7/bN/Jjvmz8zgE3s2kbZvrYkh6oQsaZ07qK30elyOZ2qyoipUp24vH8kXmru2PF0+56JLwySW3GEv27bJ5wRnOaaxsv6/AM/AKgPeTlv8E9iTPfPYCDbE9pas83voh3hSZ+lSST2PizY9syd/GFr164c7xKK4QlPum3XGUmqog3kzilgFiKhAXCv/uGW5w0AY6W4biOYA5C29Hzwzt4wADApAxBkjzWJz/C+QLpYNQQQVtz0kwWZi5Vf99ctgdpDJ5b6cQDYdTa+tkVIRmnoYK8v9nGBAEMtAnu7U9njpcE05HHiABgWR323rx9NFAjQd0Z48Ex+tMXsbI38UrVC9Qzd5ZL17MxsBZA2c8CVhSy/eZbS5KxHAsBOffdvOHn3beI3AKwxpXDhqjw1cCX1txY7Rm1T54drrRw6MMj62EBKuMs973RoGKIit9Y3CJZefZt7ZB0ZoqlGcc7Fl5syNiLTq4kEPps2AHpSdMQV/0o7YhGB/P3rlifQcCh6oPayKmbZEledumQOVR4nYwsSYLTlLhl1gDetMgEG0OQL325PkgEoKZ2WhDEFkCj4PKOM3w8b+JeKFYCOcO2C879fFQBaF0/Tcvt/AECHwO7bfHGbAAAAAElFTkSuQmCC",
    },
    {
        "name": r"URU×MIN",
        "sumerian_transliterations": [r"u18", r"ulu3", r"uru17", r"ĝišgal"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAACMUlEQVR4nH2TW0hUURSGv7PPnjlnRmeyJnNCRjQwupn5GBaEIXShMqhe7MUiqJcCrbeMIEKCXoKim2JCoL0YRkloBEITkiQYZXlBdLLwlnnykuMZZ/cwas6Erae197f3Wv9ae21IsKRrAZG4t2iG2ylXD1ulgSSXyzRN0zSc2nJ+o7ixa6RilRnu7XMnaRqEBuPuF35X1i8VupQHuz+pyQkVOR2foMQ6tP/nAQCOfCs7PnxLaPEHqnIJXoi5lWn+0aPhBIX59mTmotupigQyngfbveuISJ/jx0zvVE8wmsh5k9vU8X5Ttj76Nn3bUxsSezE7fX6DJ7u8xAhkzdgaSOT6r8u4sB/nFbbVUX+mOiOigcB7c8/yIkT0ha8Gnk+0hiQgEAWVp4wlrBQ9rV0QahkBQDLbVHQlp/nDVEyJbqSkCr+F3+tL1gBJuH3r/evFHdMxnumr9m6usDT3xiz/OwUS2+3S58YGh6IArHV+SUnvHic5tU8ogLOHX4fbLu80F/JffUJabTp47uSUP1oD8qS+o/9iy5I+w4HH4QGvM9kAEPeyBh78xf+YeDYwVLMyRs7UZ479j6vPkcSQLh2EqccWylHgjecjt/tg+GGnA0Ag91alxnGr+TfMBcf1GFfGscZ9S3A+iooAzDMPINGiL1Xtx1fTsUfMyyhbGAk7vx+QIHobtu8KdMcmSVoHFyIpORABTRyvG3N03W1IrAKwwwrECWWVuvSVO7Bl7tyKHxL+AM1KuIYs4XU1AAAAAElFTkSuQmCC",
    },
    {
        "name": r"URU×TU",
        "sumerian_transliterations": [r"šeg5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAAC0klEQVR4nH2TbUhTURjH//fcc/Vu05pT8mVJaWGWtQwaaZqVJQVFYRZ90S9BERlEHyo/RC9QRFBEQlEZRlQahVAhlgqBQSmmGPailq3cuvvQ3rfcnfPunj7M2ZTq+fY/z+/8n+fhPAeYFfRcLj/7LBYJokAITbb6TuToNFqtRiOKlFCR+0Oc3NL3NrRg8+qmFetGRyi4JCGh5fPyTXEeVTYWCDB50nG7HADEW+qEX2GD8WWOeKp2eA41FExJsf355haLaUYnrR3dzXFyjXTdv3tmr9t9bMaVK2w4CXRK8EwFWkfSbdPpnHk+h3xtIib1RQs0Wk3Sg/aaaeJoYGicmYHotFzNyn7J+NW0f1K70RtDru7vWbvMAgo+y6atqPEYQkvfFvHm0bpGN58uJOlSxiPhh3kCQDHncr2nViyVec9eOQ0DB8y99nyXXs12+l57AYCCbCy83VHkSfSSdwWqISAVZ55//N3vBkpzaJQItVfu61rU6Qrn9nk3SSXv7U7mlvQb9PxiHYsS4X7T9TMGvSSiSC1oMh8/a6nc+THzu8XVvZxEiUmtlvjht1KdyxhM1Zsz5j9y6oMO2S6HAQD0oFSeXf2ypM2qS7OPp5UNnEptvjMB5C3Mz0mPAACtJqu+3SuXKnhBE+JTdF07M0wN1p+SY1T+VRKtcuOS5cKL4gyH0WNPdC9JrfCdHhODxrz1jDMaFQCgTw/LLfKFi8PvkNVTynhbfU8YMGgNmpQlW6MewScrZAw1lPZ+TbP1Xn6mvAIAt/sH8KE4ITrLJwDoHPT6OaJY3Xc5FnsXVz1PARAmlM0FQmM+pipQ6OA0APmNkwAgIOWN6bFDDkL8BjEAIEDirrZtUysfUSfiiUkGgIJT2yP3hzp+cYBS6KtT4iyS9SpAAWJ5bCrOHqIAQkJFvAc+CQBHqh45hS83WxT8LYIRgOxhgWOaf35VAFgariX/y/8G3E0XCwZs9F0AAAAASUVORK5CYII=",
    },
    {
        "name": r"URU×UD",
        "sumerian_transliterations": [r"erim6", r"uru2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACXElEQVR4nH2TW0iTYRjH/++795vf5rThRUFgtgq2MJdCXlh0cBlBiUQrI+rGgiiCIioqsAOU3UVXaWUHggw6bBTYxNVFNxUx17TCrRKzRg5rOLY5d/i27+3Cb7qt1f/mPTw//s/zvAegQOzSElXhXlZqUaCUlf0InzKUarRajUYUGWUimSPaNw+4ElVNqx7UrB35zEB0gtr2ZcXGHA+rn0ejPCn9vmUBAPE2T0bS/ENumqMha8vkme5qZVn5xtFkGzXnVdLrfGvLFlxerWsMdkZ25NfaHObNBACIqe2irxU93KsraGfAK844tAV+PTSiJXxEAM0jPH0zI3XfK4n4MZxwSWD5x6UGMehj8031vpsqAYwEAQbVQn8etfqsa7Hr8lhNq2EQoABF+RVLbiru4FUdx8bwiZiUjKCN3fvEbBhA5Oq7PgAr15uQAACGRP+2c2bn0BQF0uI0gJAPABqM8QteygGGlNt8rWOPJ0YBqb6Xgx9KPg8Abve60vEZD0mrVUmT44EMQJZxkF0bYl3nh+CnL04gQwB28Kdl0f6ul544AFTIBIn2iH73lqdysGfESACwvbR27PgrpVK1BG4HsKbuQN3gexAAoNcN/u4sMKvXnU/i0Qml22ffJ+4WAoD80e3jyjlP25cG/yZQ8c2TvQn45CIAAvaYMqNcsMwrQiRDqSwBarmzoJgLZgmUbHdsVZ58Rk7mBiUOgIHI/Zn7XucUAdK14dPpOYCX6WWAAXT0sbmh0ssAJIRNeRmGBYBQ66Og8PWGLY1ims4AdCePntT886sCwPLUYfq/+B9VKdWPpqWwGQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"URU×URUDA",
        "sumerian_transliterations": [r"banšur", r"silig5", r"urux"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACSklEQVR4nH2TS0iUURTHf9+d+80rnZFaSOEDs6BSBqk2RUg+okUlkrWpaNOioNciekEERdGqaFOaUm2shTJBEYqS4CJ04YtaaDUhophW49j4/Gbmm7ktRp1vpDy73zl/7vmfc++FVSHvbbatzi2H3akLITNHw9cL1rncbpfL6ZRCOrWU4tbB3h4jv3L36+LS718lWoZu938rrrCcUTOmZmdVJPbrUQWA87mKzJjqs7XN5emaqumbDUVLmN/VUukf9qU5ed/e3WTBsuDTmWPpXg+HVanFGK/UUMaqcXoDLitWhS/pyDRFv5aGg0ZPDJGW0g1lRakFQWDLteQ0wLZj2b+hBEg8D+s6E8sKZYJeVV0bSCCy5UZ3AiSibNeDRiMpSIicEVQ0b78ykSf2dUsFEqOt+rav/dOcANOx7U7rxKbT/osA4zPNRTaQRPt8T+6fHJgXENvp2ev56Im9A2C4Zx5AEnO7bbHQj4k4aIXTHXcns2yTyUnsAkCeGy/PO1P7YWARIGurY4sr4khbkjwlSkaudC6RXTsSbo3b56wKUVcw1tC5gnrD447+jLM5ABGR7PL2QvRlamHB+j5Co9fWdwnwTv3RALnwpjCYUvwMgNNb3xwWwO8NNkDyZWWhgGnAYu1UKEleAKH0cq/lXjQwAyHLLSEQ5S+yWSMEOI62HFp6F/FExFqMKUCiJdrijUPtcxqYJeEbZkqgMrMSIEEMN/v25A5JwNAPpHUY1EETNU1BPfDMb/KvWIiDOK5mr7r++1UBtkfPi7XqfwFDRseFVFkMDQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"URUDA",
        "sumerian_transliterations": [r"dab6", r"urud"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACsAAAAeCAAAAACQgbgCAAABO0lEQVR4nI2T3ZGEIBCEW8sEvBBMgRTYELgQuBBuQxhDwBA0BAkBQ5AQMIS5B2rXP9ij3xi/aodmBjhLaRSL2BSzinnuMt+qy7kNk2ztYLfDr4RdrBBiw1VMneOkqLn6Akb4aTmaKN1b+Ts8E/2GWxRz6IJrAUDJQ5k4Fk8SvHKERqY3aVaexY2FYwcAMxGz09FMBONS+WrWAJqJBvStMZMHAC+6R4L18ADqYRHwm0d8ANtN9xh3SWYO9HqrmdKMBNDAAtPPJ7O3agDP7yIUNYCliIysvqefZdWqilks40qyyJxZirBPXgqJmdUAoGcMj6+qqqrKfjBtAED2/ev8TyenBVvXxJgdeuj9XvWdy259fatY4/KB83EvFEsdEosZZwePy91Vu1l/LmFLzQExByp8c5fazYzCmEf/AEy9taJPb0kHAAAAAElFTkSuQmCC",
    },
    {
        "name": r"UŠ",
        "sumerian_transliterations": [r"nitaḫ", r"us2", r"uš", r"ĝiš3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAYCAAAAABR+svWAAABA0lEQVR4nK2SS7GEMBBFDxQGYiEjIRaCBJDASMBCkBAkgIREAkggEhIJeZsBhiqY1burdNXpTn9uEeuVW+U5eKTSxNjcE13e3LbkpXBCrmO6Q5rmlYyuMUbF/CCrsgK3ZduI239UnCywPfUBLFkBk3wEMBmo2mcAPFD+AuCfiAr64KVOHp3mB0Kaz3u4EOq8l1hc7u222EuqzpLeHcGCiPGyWBEn0A4oo8bjSd5/n084MeyzJNezJgjhAsi0t1GF0HegEegTsOu7O2YJabTCAHRnjdSeQSkbO651UQxDcejlt6996FSvjqtCa81ZY7518ntkt03Z3lv97fdOHi/Xqo+1/gBOr4KCYfoUNwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UŠ2",
        "sumerian_transliterations": [r"ug7", r"uš2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAMCAAAAABDkhIaAAAAfElEQVR4nG3PUQ3EIBCE4b9JDWChFrYSsICFs4AFLGCBs3ASQAKVgIXpS5O7I+zjN8nu7MZi6melaTiUZ30pQVV1k+qAJPX0DVxRHrDDmWJ8Xw8HTt9gh9bM+fbw5c0BZHWV8LN6lAF0df930roM5iJgI0OcFYL8tnozcwOnCi8Z7/DX0AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"UŠ×A",
        "sumerian_transliterations": [r"kaš3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAYCAAAAABR+svWAAABNUlEQVR4nHWSbdmDIBSGb71WgAosAhUwgkZwETQCRtAIMwJEkAgSASLw/pg6t/meX5zDzfniKWLlubQ8B4dUmhjra6LNq12XvBRWSD+lK6Su78noCmNUzP/YqLICu+axFpd1VHyOwHruIy82r9HG7uUuWQFPee4uLkZGu2yuyb+J7QptVjthgfKTmGdUQKhT6IsIUNtkz8Ttp1AvpZs+iS44qZNDp/mFrA2fhDTbeZi3SgFA+YPoVdK91Mn356fa3sPxGToviBgFoA0QARGfoC1QRo3DkZw7XngQVgz7tMl2+AQhAAQHzAgr0y6bWwhdCxqBfpWEUI/+0R6zhDSNwgAcMUjN2yllPU6+KophKA67u/W0D50qb7/WGprRvHPMl0p+TOyyKZtrqT/c3kl5eQ80apPWH4TNpBTX6I0NAAAAAElFTkSuQmCC",
    },
    {
        "name": r"UŠ×TAK4",
        "sumerian_transliterations": [r"dan6"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAYCAAAAABR+svWAAABUElEQVR4nHWSYZWDMBCEP3g1kJOQSshJWCRQCZwEKiGVABJAQpBAJBAJWQm5Hz1o+x43f5KdTDaTfVPlJnKKMqcF64Sc23NFV7awrWWtgrFx1DNJ217VS4P3Lpd/MLjiIGxlaA0ADmuN2FbEPus8DcD28uFzyaWUNeengrU4YLLHwyb3ZZ2KGfx+pQCX28uaxlkiqC47swD1h/30XKZ37l3hXbAA1ph/FDMxAcFGeWMv0KfFii5IiosDMLabPxR2t85ztA1t3z9w8VDcncrdiibjvEkg6GPQuF6TAlSAhPhtNvM1pe74pzXLDekbIAsUD9NEXt0xvLU4kADUGnqiQkqMR1RMsLrvLyn1HQgGWfYWptef7vhL0nEwHuDgQK+vorbtMMamqh6P6sA1bhxjvYg2MfCJ1Hj/6jGfJvk+ssemvp1H/SfuTurTc6Cxf9H6BUVEr2iioLasAAAAAElFTkSuQmCC",
    },
    {
        "name": r"UZ3",
        "sumerian_transliterations": [r"ud5", r"uz3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAZCAAAAACJcViHAAABRklEQVR4nI2TYY3EIBCFX5o1gAVWAieBSqASqIRWAiuBk3BIAAkgoUgACXM/trul3fZyLyGBzDcwbwDgLdL4pyJZya7Dt22aAvcX1D3vSM5Edoo5KPaYcqgqOACAMCnvE8nG4omWSMUX8ksRT7BEBgDdRs5jD5fHGr5rqi5hSAAgfO7rZz0TaURimgynuNvxKEkShsBJYjEHsDtLyOuAao6++TSfd4YbcJW2Gjs2RX6O6inkeTPTBfBo1XkJmoVtfQNGoXRNAIDW5jRz3YC4AYwx5JUU74CAybtM/BAV+wLWLoEkooGw5De2U3D3MX2WWYE0DmKRm6NhOLmsVe6evHmRvbvkANT+8eri6R21mnsW9YGcztHwFaxlO9LYp9GjvTrMKor2zQe+ZEgpmAGU5DBNSMVHk+u1p2stDVmK+eNrtiriz/AvkNevL0j9XSEAAAAASUVORK5CYII=",
    },
    {
        "name": r"UZU",
        "sumerian_transliterations": [r"uzu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAD4AAAAdCAAAAADXkoAAAAAEsUlEQVR4nIWUe0yTZxTGn35t19IiRSqFceuQilfwGsO0TBwy4wWcG2JEJriJk4x6YQpkuCAO5xiTDm1kCKjTwGCAKBamQJWUTFBaRQGxVYEJKJUVS6FDrt/+AMSWLjv/fCfn9zx5z3fyvgcYj4Ay/E8wGP9FqPYf1IcCDJopYK+jT6TMGD/AimXOHlLR8owB2xh3UyAc3jqRRssEoP8y34w78AVZfAP4un+VKfEmH84eO/uQPgG0+DqrKWbajvaaIwoFM0oxsMmURb5WymcDoCY3XQyzFPd/MfVsoao4mRf0t3zwZlMW2xgd6Kybe7t+OwH4yO6En7p6w2+qnb27Qc7jqLWS0p5+DyOyuo2UFfaR+rupARZzq06tL1OvM/PrlMDmzeXFS6iMlWUlNm/VLa+SIxppTJCv6MqzjqKce2tmKk4YGd+xHPse7S1gUABQTufavoGMFH2j2B5ehUJbuzkHstuHH2eKNcuYbw3tmBgAsKAkm+UUAAD4Kc95HDJjyfM0ACtU0hsSWfmPD2u7taMdVek7ltqPKwK7t1HcbB0WbVFGjORYrAXgxfB3im0FAHZCMCHKBxgRgQ6utWzDExZda8lPmLeYPzJw+8Hj+0PwyO9cC8mz+qc6T4F0tNYKWJW9gnn6Dz4ATnrj8cvLAQgUWeEJBnVXZ8L9sBO/Api5Ie5ytark6C456U9gWW6z8oKFS1RS/X7sLBICvN9LnCGUyeavvzwPwLQV9sCjmMieawPlt0+Odc2Zv+7bqn6ymgdg+s+DIgCsJZml55cBgF1BYVxLBg+b890mhtS0kX/P8fqfjTrZvvHKlu6zRRW2IKDT0A0A/mlsESoUAKA55JBQHfUSbrSuN0MmiOGX/c1tHGEYFQCQdE4S/qKpBzT7T/frOOA4WW5z3xusyQfA2q1WbUiJ1Q4KeHqAu/ROL4XizHQ94wX6zWT5CADglcGRNUoBcGbgboOUJfxrWOUFn4s+BNjfF7yHT1Rlgo/lCwB4tqfuS9KqW5/HKsPiJdSJdpbfzZD+Zg3apVtO3t5fioNPdtegEkHKocOC6FZcevLdBTlzOoCWc5v8G4iz1cd/eJ+gENQRAHC04/PbdkHJ0tGuAdYh4a/TEj0BVGqIRJfoFgAPQg9/pecB6K3fHX/myaP2aWCBHB3kuvIXzhIMDjHqIpfvWPx8rJWDXSLMAACkTt46MVnwGRdYL2Hi81lWodgamlhUcutxZWnmTj8PBwLcSunY+nKvym0WwfTO2xQN6VSHrBlsAO5bvrnS1FGXU24IcrO1GBd4tR2kABR+ipePQ9qxS+SaKE3Eq8knYVe4En36pgd6Fx/26L0GT+uILmlDyCRHlB2AOTW1J2cgor/uaV+f8XvfqCG3S3qHH6btXUUQH7WGeyvbQ40EFBqAp44scnVkzqJWbWOLEZVm7BdwB9OStABz+x5D855OndpIQAIAN+t+3DWNDT+PFFGMKKybtR1jq5Yrq85YaJVlCMbUsEoni9s58DUEmZLuoYnt5pb9/ENYpF6fZsb/7r68V4tAD3AyBRWiNyk3X2wJ63RfM3bApeSIubIzdTIXJM4CbGzMyYA5pa7mwWSw6VNK/wIl7Mjd7KYjTwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ZA",
        "sumerian_transliterations": [r"sa3", r"za"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAXCAAAAAAnnZAFAAAAtUlEQVR4nI3OQXHEMBBE0V9bS0AUTGEpiIIpyBBMQRRCwYEwgiBBGEMYQ+gcVE5tkkvm0lP/9AiFWSgOqVuXHhucJ2zb4OKiwa511Q7JLXlPgLsbwKoPvQCKVABwGfPxubsKPIB2zjBoM1zcd87w4551NCDnsXwCSyakcCmqFHKJrKg14sWho5oOKCq7CqTeU/QEmIcBZHUt85lL/5bGLV3hCbTllo4JS7+labxJ/9D/F6738AUnmWlm+UumFAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ZAtenu",
        "sumerian_transliterations": [r"ad4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAaCAAAAAB535iiAAAA1ElEQVR4nG2SUZXFIAxE56wDLGChFmoBC1hgJcQCKwELWMBCVkIqYfbjFZp2O19wITkzBMApU/CiTKZ/MJbOwe1JhdS0c4GvTwc9fo6Y4+N2IgOQjdw97eQAgNCcn0pq6v3cWJj9j19X+o0CyGl2n30ACGNlcYGmFSVdiGTySaHUeoUAxCKCdFKjeA6tYXDbxKzfeOKgAQjiw8XSqNpPE3VxkhUzXFnmsImxj5NjLQCg2Aq3354vXlNp6i2F0eYVZn9w1Zf7/NvAqx71l0TDKw82P9AfvE97j8uMk+oAAAAASUVORK5CYII=",
    },
    {
        "name": r"ZADIM",
        "sumerian_transliterations": [r"zadim"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAaCAAAAABnFqgRAAAA+ElEQVR4nG2RYXXEIBCEp3lnAAucBCqBk5BKoBJSCVsJsUAkcBKIBJCwkTD9kXCvybF/4PGx82ZngVYp4FS3drG+ol8TabvAaChzF2T1wtAhkUwkpUvIcdLi39RK5uxhM+PVh2cRkpSkTVLMfqogFxUgNEktDgCQBJbFADCySyZqMDtBOiZySQUfAgTzBNxW4baWkEfdc/O1oq6wdX05AjJVvDnUDls2UszNrY/tMtsU1nvF8HsFYx6/HxUYfs7Aprh8LgAwnBuk4H78PXbqNgDGTPVrucQWyZLIFtV/P1ll7m4ORkPq7A0AhHyX2psYzw8v19vyPJM/gX5/sW0jaTAAAAAASUVORK5CYII=",
    },
    {
        "name": r"ZAG",
        "sumerian_transliterations": [r"za3", r"zag", r"zak"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAdCAAAAAAI3PofAAABhklEQVR4nHWT0ZnjIAyE/8vnBmiBFmhBKYEtgS3BKYGUQEoIJZgSTAmmBLsE9iG7a5G705MEw0iDJBgsGv5llzF0i30DWIA/+sQkn91xDCi532A64yDSDkxtI5n3JSuUleyM/Tiq0CzVUawtxOZcGRP2xcSubIXUA7A6hVsWeIZtk23z2+ZXg9lngHUPp3rpgu0p9DnuIe4B4vb6obDqHE/You0i3Uq3mD0CTM63Wz0VJNsaDaBZGp47AD0NurfEEukiHemwRQCmGg4tNM93FQX7eKHKPc4DW9D+46VsciEX1ZOnCWeVzll7fdU1MsVl7c+funpaBYBLnYOelmLM8dvIh/luzlSOeVR5k1/38/ntTP5oj7MSvNxFvfCuAky2XfVApax5W/UvVGZtissOKHK4AUw0Z86xcPoFkKMUYJJ2VcO5jVS06gtwKRrk3hJC9gCXD127r/UdZTx602IC/05Fq4LeoZok20PAGMGBOASoXn8nsgyLcdquuUNf/Hu+vy2m/999AcoP3P9mQEMhAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ZE2",
        "sumerian_transliterations": [r"ze2", r"zi2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAcCAAAAADQV2lOAAABsElEQVR4nJWUbZXrIBCGn+6pgbkSsMBKYCVkJRAJiQQqoZWQSAAJQUIiASTM/kg3Sdt77ul9f8HwzDAfHE68oyIkcHy8RX9VwDK+BYNXL2WSN2liGdQ8G+3wYlrlVAcg2Adai39FrfOhqIPTLP3tcDAbxnGtRixWxOAAajUn4KoaDtmHEoqWGOOsqqqTDiEEJxAUIOig5eo2WmlUSwzBOwdMqjrdD4BOrSt60FXne+oWkNkXu9FnwQRZxnSP7Rt/6e/rTr5rvVwvecvzbBhyu9fZsW+yn8ZUWdxOO2593avM4+5Zk/MWmrVDCaCE1/5uFQcBvW8icL4kCD5VJ6Tq8vcRb29P/h9ddFwWpH4uIrTmOHnLswbVDlOKQbQ4QtkRr9E+ZkLQqHOYrsAwgdd5w10cDnOIAJ0arw8qbos9d/JYpWAaal0yiMnQ9U28vyuTvw69ZaXj0t4CPTjX40nLtWnINVN7nvQ8HctgGJcqxloBcq0h17TFvrUHZ2mQdvz1tmLF5A4gmQU4/3m4ysrY7jdl1qAOhwE4r/YqAIb8mXlVIv1tVP9QiPDm7/Or/6N/ACwt/IZ+5PVNAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ZI",
        "sumerian_transliterations": [r"se2", r"si2", r"ze", r"zi", r"zid", r"zig3", r"ṣi2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACcAAAAbCAAAAADacMk/AAABzUlEQVR4nG2SUXFcMQxFz3RCQBREwYXgQDAFF4ILQYXgQHAhOBD0ILyFoIWgfmw2zSbRjD80c+b6XknwXTV97GX8+A6rCxBA395UgN4AG12hjAr4hLZhTLABLRUgMn1nZnhmDpipSDQ0lBpCiXn7JnPtM9PMc8JMR9wRn5SYlMh289PTJDynhAvzXCYepp69RtQalvJmfMVKtdyp6i62zmk7+l7R9o5Owi3vi7SXyx/q6wU9KCoHcHC9yi33e3k2WNlA3c2Ku5WIVs5oLXpWqAJgCfQEkJkL8YXGRGJSPBuky52reRPfKWgoJZUSisaGnWf5xIkbjAU2wQxqVizPnO2Bo4ZCASn3va2nCz9H77BB2Pe9r+vjHRxPihbhogdIOe6CxyNXKzPz7I/+2BvUoBg0A41G5JJPOSw7bANvSFTwE3K+z++Na3mCBUxHfMNMuxv4wPX0Rc/JTBPPIcuz8sSnsvFLmeXluvT1uo8rfjzH8UWvpGGR1XbI9pAdUUi+6B2/7MLLdb0ex+avbH6X/fzht//+yumTGoueRk9jRNZvOCQCeggWwgihf5sXSnSY8zbDPcDifqxtAzrfunGCDNABWoHzXfCxvD72df8DJCc3alaQgb8AAAAASUVORK5CYII=",
    },
    {
        "name": r"ZI/ZI",
        "sumerian_transliterations": [r"part of compound"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAACzklEQVR4nD3QaUiTcQDH8d///zzPnjk3t3lkNLLDi9BUrCitFthhopWJVuJR0Y1EER1GWL6ww0oQzMIyKDKNDnVBqCRqWStD1JzOK03LpRNN5zY3t+l6U31ffl9+AE7GCaUiViQhLtejvD0RBIWHQEUQmtvIKbs06wdz9ybsyKnGtoq9d9I8KYanDoWv2x0Xr406V3/A3e3G12zLqhPlBAi4KWsJsmlGIgzuLoLvWzoYD3XYYQr0tvvnV6wvH3HQ6TkztXTb7KwcNAPQVI19qO98eWdFZ9mkSv+qT12zxI+eKRLOmjDTZ8GXqxtfjM5cii80D56KJY9Xj004ShdsK+KdfJK2x2lZPsDN2QpYQ+NS5aRN7J9CgbUeQcTiOSF1mDwxpklJuU19cgCsrJXsC1Qck1wIjC6hdUlPLQJewAKh+S1Rm30KO856KYpU7AErCAAgLtq8OM25aYNe6mrtf0+t+FtAWLtAZvAf8hV6SwfnKQDACaD4RtwPo7NEfHWi4WNMBgXhGLpSQDl5TfGuYptbYXSepC3/KAu/p972447u5MFkV0qnfjklEpMxkKXof6GrHP/+XH9re6IqQeF2TpPlFqO8RgDxo/CChQnFw2n3Tgu1i0T6X6llwkxKYKphSl4zVdpWpbZN9Flezat1IQp6Pxyf1HZd82TrA/l8gamhyaIeqLLupGtK983Y7DajFQOXvYxlzHnZE7UtWUnyRMsC2UY+tMVMnCGObpFRZuAZQwzLBnu1yyvF0jd6wou+dYhHl/b6zA0r6daprSeH39bpaqurZr2yFo5P+f4M/ujTREv3/+RACAgiLtYnrrJeqTvP+2U3sDl/2Sx7DlZHRjqOSFJn15FmNf3HSezTc9xvwTirtU6bpe7/v7AiN6Ln4dCzoXd96srFERQAYUBYgpY837YuWeaeuzpTeiwAiEM4RsYASM9wcYU7hDyy/wDlsyErcTY0FwAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ZI3",
        "sumerian_transliterations": [r"zid2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAACRklEQVR4nF2SW0iTYQCGn//ft6Vr8zR0KzFBLdtQPJBoUhGVEVhERCB1EQQhGdFFV1EXQQQREoZCeWGIUJSVUZFTK9LspIIjqCYeog3LLaez/m1Od/i7mBH4Xj4XDy8vL/yPVqdLSj8x020GIaUshRNUarCqGSUFPPCC0LeOXwskuKEu1dG1Q9MPkNwTa8pdsdRODB4YuZgQXl32DR0vTkvW6/XammnfzFEAEf3y60p9u/NjWAY1PrPF5QaQNWZ1YRprXlRVVeT39rkAgBCbTRemnabx4bGIgHjNKTOACOcIf8fenJqTb0NulZg+2doLiOeV2rQCi+1D42TMB6hJW9sUEF7tQ8ljsGzom0iU7Ktbp4A4N3XG3vmpRXtn6l1Mhlj5Rss4CH9bjWFh7I9SXJYd/ioRj+oL3wBw+BlVzsXOMlOG0Wg0Gp90pIAMTneK7rVv/yGNX1EURXGsTwcB/vnq3sGl3XXnXzkkiBQVp7uQwffNpmJa0M36FUVRFkc1uRIA+5sl80Dckb+yY09jEgLwhjLXPl7efqndHZJBdRXowwL4uVjW2zRntr10fA5IRLNLU+cF4PXlQb5l9ulo0C3DcLX1uwCioQIoVWz3b84CUL/thQAw7bk9eWv5+umiIfecTCxSrhUAoYrmyz14fuw7YndpiAWrDALAPbNzU+dAWaDF7lkCjP0VAsATvBtoOJaVdbBEIwFa0y4BQMCXlRnpiuhEDCD8qFsCqO3QBFvv+dR/r5N+A3BWHalcw+pobwwXrkJ/AcWv5tgJyrjFAAAAAElFTkSuQmCC",
    },
    {
        "name": r"ZIG",
        "sumerian_transliterations": [r"zib2", r"ḫaš2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAXCAAAAABGhbJHAAABVElEQVR4nIWTW5nkIBCF/2kHWMACIwELrARWQkZCWaAlJBKIBCKBSCASzj6k882tZ/Y8Fj/FqQvwrjg5/qusHp+ffAg7SSU9YV60/d0ejMV9yeFY9y/MfltCe9yuCfYD98SY1dilXktRlNSyg2yAmx1gCWDuvVuMoalkjQQQlIG5A0keYIwMxC6lNDsA1yqQFcGPcj7nwc8y01VjU4asBq6dic70SlyQaxJkaSI0tTNYDXIf6QHF0Up1pkkxjdrshGa1AJOaApBVndU+Imoy6gnd9n1rzdwSSMC6BQ+Li7Ae8erYjWPbvGd/27KH/fVeg3v7kwvrK/VqbFU/G+766TJLHt9kUNRPSOW9yPCgDNzoQNG3tVA7KRsewjCgta9Qk8wBrhfAhrsm9PIBmuye3LLueL8C+b4dxGP7nCkphqHv+uTLVNTthw2+1DXy7wSg+Yff8g8Si9pr19EdVQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ZU",
        "sumerian_transliterations": [r"su2", r"zu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAaCAAAAACBP2NVAAABGUlEQVR4nHWR4W3DIBBGX6IswAqscB2BjJCOQEeIRyAjuCM4I8AI3AhmBDPC9UcdJU3tT3oS4gk+HRzYSvQFvN90RDMzq9uStLhxEdLl77YP15Sr2WiBE9P9pgBOvPcu0LWpdrIWDn5uXjsEKL21pv33BrsNHJgHpl6kKaIgCr7hh/lcgFxthGh1SSvTMmcsAGSLAMniytXNi1tlTQCIPUmJVXpCdYA9ecgjjS5z3HkMwCbbSOQASKXcWz7DyoU7ebgBECxud564utuHbtcdcVe34zjimNyulEFr2JEiOJ/n928F4JS4lM8uEqnlvfvE1zdQQIJEaimv8vxYqYIEGanFt8fJ16iCDyIX0f8SoH2DD9J3xgMgB/gBJu6qhTNdIPUAAAAASUVORK5CYII=",
    },
    {
        "name": r"ZUM",
        "sumerian_transliterations": [r"rig2", r"sum2", r"zum", r"ḫaš4"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACaklEQVR4nGXTfUwMcBjA8e+9uLs6rU41LSTLpkiZXKXa2OiPRq22MH9QW1n9oVlllDLWsEOjzbQmklWkFxSVtKOXu82QosSpVE6JXrzsbEnu/NF1Xe7569k+v+f3e55n+wHge9gB25DLBAAIknu9bXBRaM85GQBKnS7SpvTQ2A13QGq/+XHr9VzzRXPhnjeSIwUROadGjNWawUSFtQbW9UcDy9MZMJkmpk0mffA8ivZ11q8Hwup6CO4zHFUZ20qLfOfU+cTA5aUgTuyrXAdRQ6qs936KQnXArK6p0h2Qgkde3+nFgKhs5uNxcD2rjcEvfufJ5uatwIa6zr0iAOEW01AoIE/tSF5d/6hmyAuIfV25yfyWQqu1BxDu7shUdqvTQZYzqHKfa8XpXpM526jJT/siw6dcnyS3zKGo+pa9Yjb1rlF/Lbgz2hIinh9TUW76/SLcfFOpcexiyS6LiQGRocvt2ru7GoGL0HhbHBH3qn0B82ey8sf5sGlgUO8v6nUyWS9YUTHV+/NzzQ4JII78ZWisTxFac7nJ0KgEwDF76q+2YvhthJUrqscPOgLgdnW0QXMGjypdlGiea81z+93qavuU8WEVzkW6/RIAhJb+CL0wlVJ7adlkwdqJlAe5SWJL9ROA+NY0OwD/ludKHLJ1qXZWbJf1LMncj3fT0yBI6M+Tm1nNkjxNjKUZzytd0RA/nC8FEFS0h5c1hFiN6lo8uge2dZesRJLbOj6jf6m0XhQuqjdxEKgrRLhdq0t4mMjCkB8ZzpQQEAR4FQ80ef7HyDK+H5v9JPiP3xf+z0hix3zMJ1U3bRQEDkL4B49b1nK44HY+AAAAAElFTkSuQmCC",
    },
    {
        "name": r"TWO.AŠ",
        "sumerian_transliterations": [r"min5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAICAAAAAAzNOsPAAAAa0lEQVR4nD2OQRGAMBAD88BALdRCLWChFmoBC7WABZAAEg4JtXCVsDxKySuTyWQjWtLQQdHUhefhCuzhSytGK0FSxPAav4aqA+BsqwHAErWm0M8uaes56X4GgzYomX9A/iMqNu+IfbrD5gO98s47WGY7O1AAAAAASUVORK5CYII=",
    },
    {
        "name": r"ONE.BURU",
        "sumerian_transliterations": [r"BUR3gunu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAAA3klEQVR4nFWQUXkEIQyE/9ZBLGwlxMJWAhaohLUQC1jYSuAkYIGTsCdh+gB825uXQBgmM4EBT6N+jmKn/7+n/gDMF7lGu4x6TnLPEDW0A5CvCCBUxn97pAS2c6MUiqIcd6NLRslrPhu/L348z2eFArA8zCm7rrTc9MvZtdVhL1QNDmEHQFMAxDXzPHEDsDU6X90hBFNwq8pkUcqihIqr3W7JKkP2bugEygxpNaTN2rS/N+dQ1AQQtWkHTqW56qgjRZ1iPcC7Z2X4AJI/PX29OO17qveSx5LW+sQbrK/TH0XkayLyxVmRAAAAAElFTkSuQmCC",
    },
    {
        "name": r"THREE.DIŠ",
        "sumerian_transliterations": [r"eš5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeBAMAAAC/JAEaAAAAGFBMVEVqamo3Nzfq6uqpqan9/f3+/v4AAAD///9j9gXpAAAA2UlEQVR4nNWRQUvEQAyF5+c/ErdzHphOr8NWPQ8d9dy6lr1aKHrtWtDzsOiYcRcUL54N5BE+8khIlAehRCjCIHX7AGzGnch+BJ7v1YXJ+WBdzunDvGXTq5CMMUdJM5uDax5V0OPcUHqfHYbjvJJCsKn3m2YQeR04KMTUyIzkOiC51iu0gyX4yTIw2SgdPNWE7qkWcGcjFLbXK+B1LXsVEaAXAv0ApBcGl5pOANXL9lTzGegF4vu2oPoN/k/HnxauVkKrywnP4LKPiDe7CLrqv4CnDm3gDhTk758Guiab3uDq1QAAAABJRU5ErkJggg==",
    },
    {
        "name": r"FOUR.DIŠ",
        "sumerian_transliterations": [r"limmu5"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeBAMAAADayfNlAAAAGFBMVEWQkJBRUVHT09P8/Pz9/f3+/v4AAAD///9sl20AAAAA50lEQVR4nH3PQUvDMBTA8ffx317S9GpGm1yDG54DG55rV+vVSqXXRkp6NbiJr9qBBzGQx48ckn9AVogoEZ08Qhb7xyHOff95hkzroI3m9Q7YxahfQ5wtwd6X3Shz2/kG5MmEl9rHIBvAQ7Ji55IRR0DsShRuYxHZ9+y9Kr+dFyiq/Mdq5Ff54Gr8xwLkRY3Z0OfFU89tcQ6aB7dliRNn3qYGvLsMxqfzMAkgud1M1Jbtcw3yEMyurpLBBuiUSqp8Z4n4/oels117blDcrp3qDcmr4mqk3z3qD28Xr3/8YGeTW+yIjTy+ABf71Z007579AAAAAElFTkSuQmCC",
    },
    {
        "name": r"FOUR.DIŠ.VAR",
        "sumerian_transliterations": [r"limmu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAVCAAAAACIiSp3AAAA1UlEQVR4nG2QQXHEMBAE+65CQBREQRQUCAoEUzAFURCFCwQLgheCDEGCMHnYV7ZT16+dntrH7kPb70ZIFq2aD2m4apA8RZKkuEqSWuySpAxLY9KM64WiQFJyfQW8pvYCJkVl4NWyPECRIkBTd0CQCgBRDYCszN5HADhyPHIW8ARsrzcO6uHH3RvAF2BprjZsqyMSfaz2XnT7UTs9ADz2oqTxExzbFOx7cKEoA7NWx51ViaD2XxN6d8v7oitZ7XjAHS8pfPAs6md4nqNhH/04P3Tz9er/APljg/dEoOzQAAAAAElFTkSuQmCC",
    },
    {
        "name": r"FIVE.DIŠ",
        "sumerian_transliterations": [r"ia2"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeBAMAAADN62OsAAAAGFBMVEUuLi7Dw8NmZmb8/Pz9/f3+/v4AAAD///86cXdWAAABA0lEQVR4nFXQMW+DMBQEYP/8i2OTNVYDrIhGnS3ID0CIpCtEuKxFSs0KEtA+oKBk49O94ySzDIBIAE4fImNX87BmsLfGN7a+M6mU8opOqUJ1/jfThS3y3dePJz07gr0LcxI3t9ondXXP2EWr/JIUnoilemRsr1XCdd3z0PHjlAG/NPPZ0owLECtaPuQRMMw0REnkw5bKPHhNsXKYuxsrRAGlwXpMQ7Kk7jiRXwdrq85Y480Una/cRvmqTKbjoBnrXvjWDWfCcXeJrg+9WIj67Zw5rkj1Qnmkh/JobyZ3jtFEYEkX8n9SegZO2NjGL8etfkqp+8r2+c/8ow2BcqXIUiKogD9ouQ78+mm3oQAAAABJRU5ErkJggg==",
    },
    {
        "name": r"EIGHT.DIŠ",
        "sumerian_transliterations": [r"ussu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAeBAMAAACs80HuAAAAGFBMVEU3NzdwcHC/v7/8/Pz9/f3+/v4AAAD///82wPFwAAABfklEQVR4nHWRQY/bIBCF+fkTwPi6VDZckddqrrTxtlfW2MkV1PXmatStc7VXaV2cuI2q7iLNE/PpaZgZEECjAABH0VYBLpQiqHUAbWeAdk8QJWaJRQfxY5iDHE6SD13I5fAcHNLH7niXTG1wh7wT8KnbZwTVm96/GJ8ISGZ6JumHw1igiuWz3bFjRnV4dvZBBFcg28qc2nLqy2bLSVPOEgOqiumMS8XNrmCc3GufAyCA0BMAGXtNFvHZBT66AkDEHH4BEPZ6gd6pFc4KVPq6OuHmBDauzj9wjpGO7zltdFIbIV2cWKUj+Yw+cs6FXyQG/xlD1qg4DaeM8WF6CWKQxg9DTpHZOD9CoNKwnOZk06d3FSo23+dv9WGfYz3tXcUy3wMiX4SgTRIXYvzJNJWcDSBdTmfaVNzUNeO0MkGsC9ld+1wWoh7P60TmCqm4TeQdvkH1tf939gvcjv9DSN9w3mr+hQqK7agjxG18HD/BVe4fbGweCFxO/JLlpjVV8Bu1fIzRboG3oAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"ONE.EŠE3",
        "sumerian_transliterations": [r"eše3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAMCAAAAABDkhIaAAAAfElEQVR4nG3PUQ3EIBCE4b9JDWChFrYSsICFs4AFLGCBs3ASQAKVgIXpS5O7I+zjN8nu7MZi6melaTiUZ30pQVV1k+qAJPX0DVxRHrDDmWJ8Xw8HTt9gh9bM+fbw5c0BZHWV8LN6lAF0df930roM5iJgI0OcFYL8tnozcwOnCi8Z7/DX0AAAAABJRU5ErkJggg==",
    },
    {
        "name": r"TWO.EŠE3",
        "sumerian_transliterations": [r"eše3/eše3"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAXCAAAAAAqg+BCAAAAxElEQVR4nG2QQXXDMBBEv98zgaUgCqKgQkggqBBMQYWwhZBCkCE4EBQIMoTpKYlje47/MLN/B05SH2d06obKniYVWHSzD5q7ArjU8oYWeYdx5cu9/L4awjXcYYT5x2164hXMAFdVm971k1zAIk1sk7oSqMfdgVEOJRx1lIYzzXY/o1mBVu1AHW5a4o4qQVHvm1krcsGQ/ZoT83Mkhe+1DowP1r9o6SVvcQYoah8vTH2RQd3L26ILtIO8tQr5KB91OZUv8R/GIWCjmg4KSAAAAABJRU5ErkJggg==",
    },
    {
        "name": r"FIVE.U",
        "sumerian_transliterations": [r"ninnu"],
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAdCAIAAAAo+qvVAAABxklEQVR4nK1UQbUjIRDsFwdYIBJAAiMBC1jAApFAJEwk9EgACT0SQELvof/yCZn9u4etW/Kq6KK6GID/Be+9MWb8VErlnBfCqnHOMfMsQ0REXAhvGqUUEc1nxxiZWWs9E/Z9f5Mh4kwyxjDzTMo5M7Nz7u0CM8l731pj5nETIZRSvjRa6/IbKSUASCkxs/AGgYiISAi3GGMp5TzPbdt672I1hLBt2+v16r1770spvXdr7XmewoHWWmtNomPmMUdCkyGDgIji+Xa/34/jQERjTK1VxopAKWWMsdYKQZKYdwMxRhkr1pVS+74T0Qh2EJbVQwiBmYloiTvGOLJl5tYaLBDlWItSSu62EC7KlXMmIqXUUA7ngpTSfND33pfz5FYz4XvjA1KO0S8AQMSFN7x8wRjzaemthJ+Qds9VlgDmV3OhKaWMfgwNM4cQPvk3AHDOEVHvvdYqlYsx5pwfjwcA1Fov5oh7uQ8RhRAQsbXmvb94yGOac673fhwHAGitpYfneco/f8LNWvt8PuWxiB9rLQAgomTzU4yyrrmpKSV53fM+LiBLmwuxfCZ+mrkknnNura21+IR4m3nLJ/Aasve5ymL+L7J/xC8Mz63FJegCAQAAAABJRU5ErkJggg==",
    },
]
