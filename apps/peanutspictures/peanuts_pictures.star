"""
Applet: Peanuts Pictures
Summary: Peanuts Pixel Art
Description: Shows a specific or random pixel art piece of characters from the Peanuts comics series.
Author: michaelalbinson
"""

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_SPEED = 500
OPT_RANDOM = "random"
OPT_FANCY_SNOOPY = "Fancy Snoopy"
OPT_LUCY_CLASSIC = "Lucy Classic"
OPT_LUCY_COOL = "Lucy Cool"
OPT_RED_BARRON = "Red Barron"
OPT_SNOOPY_AND_WOODSTOCK = "Snoopy and Woodstock"
OPT_SNOOPY_AND_WOODSTOCK_WALKING = "Snoopy and Woodstock Walking"
all_opts = [
    OPT_FANCY_SNOOPY,
    OPT_LUCY_CLASSIC,
    OPT_LUCY_COOL,
    OPT_RED_BARRON,
    OPT_SNOOPY_AND_WOODSTOCK,
    OPT_SNOOPY_AND_WOODSTOCK_WALKING,
]

def main(config):
    image_opt = config.get("image")
    if image_opt == OPT_RANDOM or image_opt == None:
        image_opt = all_opts[random.number(0, len(all_opts) - 1)]

    if OPT_FANCY_SNOOPY == image_opt:
        img_to_display = fancy_snoopy()
    elif OPT_LUCY_CLASSIC == image_opt:
        img_to_display = lucy_classic()
    elif OPT_LUCY_COOL == image_opt:
        img_to_display = lucy_cool()
    elif OPT_RED_BARRON == image_opt:
        img_to_display = red_barron()
    elif OPT_SNOOPY_AND_WOODSTOCK == image_opt:
        img_to_display = snoopy_and_woodstock()
    elif OPT_SNOOPY_AND_WOODSTOCK_WALKING == image_opt:
        img_to_display = snoopy_and_woodstock_walking()
    else:
        fail("Couldn't find an image to render")

    return render.Root(
        delay = int(DEFAULT_SPEED),
        child = render.Image(base64.decode(img_to_display)),
    )

def fancy_snoopy():
    return """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABlUlEQVRoQ+2YsUoDQRCGdysbxULsIjaBgF3IQ/gCPoMpfR3xGfIC
yTsErARBC0kaCRaS9BfmYGDYzO7N2Dhzt9cEdq+4/5t//5lsfJo+N4F5vn7fuOV2bbN/z+7998bNxYT9hNvLO3Y9VgDVAfUI1Ayo
IWigC6x3y5OvmF3fq5uK6S5ARVJxsN40pycxxhi0EEwCQOFUJIjDhxOPe1oI5gDkqqvxtgaCKQAS8SCu5AAA5RIAZ3uu6hIAGggm
HICVl4qTHAepC8wAkAScRLg2DHsFgDrIlQOgapIALDkAxWO7hKCUQDDhABQmDcIURCoe9l0C0IBI7Y6CaZa4c0Ba2dJEiLMAV333
DsiBQGF0fxAASiE5GAAIgbqAJj5Of/RoSP4ZmuoCpTb3uPsOD6NDuNp+hJ/RuP1Nc0A7BMH7bgCszj7DYnse5uG1BYAPgIBK5+4O
uqZHNwDSjvASp602ACKxeg6ECwClKVHS60suMA+ga0QePABM/78eA/cO6DWA0u1vemHaSwd0hZ926OHC0PQRsAjgCGhw+xCQEG5w
AAAAAElFTkSuQmCC
"""

def lucy_classic():
    return """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAB4ElEQVRoQ+2XwVHDQAxFvQVw5UIBVMOVFjjRAAXQACda4JpqKIAL
VwowiBlllD/SyhtLikPwJbHX4+Q//a+V2+v75zxd8NH+ARQ64OH2eu+1H/AHvpNrcgHvizZriQOkuHmep9barw4SZ62h0CwQ6QBY
IAmng8VLgb21bDekAEA7y6qvtXC0E8IByIpr1b4IAFrFP96eppv75wP92jUP0Fk6gIT2DgnGg7J5ACSUY8Bd3gOAcNApmY0wvAeg
GIIxCoCeYUE4CwdIFxwjvgeA5wevVyxdT3GA3AYlAMw6CkVYFVEIBYD7P4rvnTMM7Z7MOIQB0GZ5y/4k6JhoIIiIfhACYES8Vuml
eZUAeNZYC+EkAGT2R5ygReHkAKzX2BFh3pDUG442AcAafaWwJbnX7untBBFbYlgEPAjRADbVA+TgI6tu7euj1zEiUeLpuSEOsDJs
jcHaW6H1PsAZx16zNvv8e6kA2BmjDZEARQn0tth0ABiPHgx2RpX49Aho9K1tM6Kje9XW1ksc4L0iV1oe/0spgF71/7QDWPjd49e+
ALuXq4nO+ZMW6Htl/kt6AIln4Shanmv5rICRGgEpngXKikvR2vUKR6QBQPFa9RmA5ZCKWKQA8MRb2xX2A+4RmVH4BhmJppAr/Fyu
AAAAAElFTkSuQmCC
"""

def lucy_cool():
    return """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAB60lEQVRoQ+2ZQXKDMAxF8Tl6Hzaw7mF6gByma9hwn56DVpn5GUWV
bcCSSpKySYhIwn/6+nYmqe/7tXvhI/0DCHTAsiw3r/2Av/Mdr/GCvM7arCEO4OLWde1SSlcdJC5Xk0K9QLgDgEASTgfEc4Glmrcb
XABIO/Out1rY2gnmAHjHtW6/BACt41+fH93b++VOv/ZaDdBDOoCElg4Opgbl9ABIKMYAKV8DIOFIp3gGoXkGSDEEYy8A+owchIdw
AHfBEfElANg/1LJia93FAXwZBAA55/wGc7WIUTAFoG1nc6GmgQEU/p5SKFqMgxmAPeK32lOOj3TEaQDkxEOoZuWaAzRI/HOw12iF
YOKAGgAZaqXOlkJTA/nnAHI/Y4+mv7Yn8MyBZgcQgNzWd+usy1Hh8EorgcWS2AwAa34rBAitBR9gnSoD+MaHd10bg1JHo8XTvZo4
IGf1o9tgHpoIOZk1reGHe3YFAGfsDURyiZXAWg65A5DjsWWZixLvPgIa/dyyaZHotW5r9RAHyC+W2RBpeXkvoQBK3X9qB0D4NE23
Bozj2NE5HqlAzyPnPyQDSDyES9H8XJvPCBiuI4Bt8jzPvzovBXMnUG0YhuufKN4Q3ABI8ZrlcxBwbQQEFwDc9phtOe+a5WUe4D2e
LvgGIrZvUJOQ/RYAAAAASUVORK5CYII=
"""

def red_barron():
    return """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABuklEQVRoQ+WZMXLCMBBFpT4dLWX6pOIIPkHuwJm4Q07gI6RKekpa
uvROvmf+zGpHEpBoV2DTwIxnbP+nv1+7Ir7sDlNY8Sd6Avj62Ceof5/dHb0bAIgfhiERPI5j6A3BBYAWD+GE0RuCOwAIxicHQJcI
7WLpki4AZCkQCMROUz6PY4wzCwsQ5gCwqofwGvbhM5sBJdG5dASI1hBMAUD8efs8a9mcjontayte2xpaQzADQPHvp6dk9WF5CQUO
gKheTjABIFceq0kI+E3xdMUtwumMlpngAkBaGqUACPj+i3jca9UAHiIDdPhp2//HAasG0Fr8XE4Ww5CFAyzEuwCQO4DcBW4JQSvx
ZgBwY3aA3AHett9Jf1MDwJR/+FmAELT4Ug/QcnurdZPymkkGyAdwwsM8UHOBpc2rrbVFCOYemAPBMugl3jQDStR7zPx34QC+hAbA
URnXW4+61+SAeQboPNBZgDLwSPsSDHcAui3mi3Es9naBGwC9Jeb6gB5h6AIg1w+sCgA7w0uHIYt1wLUAeNjhmQN3VQKLBiDtX5oF
FglA/i+gT4Nze7N3DpiWAA9GkPjs+C4dh3kD+AEmdITQ7XIM8gAAAABJRU5ErkJggg==
"""

def snoopy_and_woodstock():
    return """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAACHklEQVRoQ+WXYW7DIAyF4QLTep5dYFPOG2232rQLUJxi5CSG2GAk
qvZPEqUB3oefbbz7/g3uhX9eCyB8vp9w+Z+/p0UoBsAJL6keBWQEfBEAjXiEYg1BsoaWOasAJJPWYr9lQcfxtGvQzlkEoJ2YA6Fd
TK/44/eS+VkAVPy6rnncZVkcPOMVXsD9jOJhTc0A4OPWCJBMKikZOD9uQAl0rwVFSVCy4BH/4SKRRqFFFZoaABUoiciW6HsaACMi
bMsT2k6wupCvm4vjOYfXUas2HNcOQBQdQnDe+3zdYEz+swGQxJ/qcIQxO4R+AAXxuSVGCJPaow8AiIKeIYZ+tR4TW6BNZomMdgAF
8ZgDtgybhLOd4iT2aAOQxHO7//IAJFY45YfaR1xJNSyz+ggguy/x/05sesCcAdFSzAVUZOneoMR2A9BCoAmzCgAGhgrzH3PJ20Np
vjfsL0wAUAi1xEc37FI8AXDqLwCIEQRzAFfZH9+LBGCliVGQrRTF06gQjVOxih5A2hluzGN4H1tjVQ+Qwp/bfQBAgfRAaAPAQUiH
INbjrV1gAcLOSp12aAdAIaAfD21xy/k8i7sQj4mxZ/c3O1ofh1VZvlbGCAAQi2FvJTxbaCQAVcJjYISP26MEor2wJBpVANsIGHEk
PjRAc/QBXNhKj8S1kFfYodf3uyRqYoGRAJhkmG3RCpR8Z5MECQCuExR1faXISjX/lAiN8sAd2tGA0BuRJAsAAAAASUVORK5CYII=

"""

def snoopy_and_woodstock_walking():
    return """
R0lGODlhQAAgAPIAAAAAAP/yAAC377S0tP///wAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQAMgD/ACwAAAAAQAAgAAAD
yyi63P4wyjmJtTTrva73nPOF0GdipHCi5LqG7tXGJkeP2TXsxND7OM0tSBkSZrxbahnR+YBEplT0mlqv2Ky2ARB0t2AAQfwFY8We
slmK/nTfaxKg7R6P45t52kLn4ylzdGh9d38SgTRtagxqi1eBhGl6hYwKX46PkDGKDwABc59mkJORfp0BqKiYU6OKJ6tenqqfsEut
F2R2sLKpvLUpkF64XsSHqcehW3OWMhq8x8t4nBmy1b9naRqhntePbs6WydKveaqGkd1e0CQJACH5BAAyAP8ALAAAAABAACAAAAPM
KLrc/jDKSau9mJG9s/8LJ4qgMpbaqBLg2n2um8WcR6/YfVbc4BMDYHBn0REpRtZMaEQ5Q5vf8PisxqoPgECL7ToABDDX6wWLxuSn
eaRtp0GANTscfmfi541cb7fE5WZ7dX0UfzdraAxoiVV/gmd4g4oKXIyNjjSIWQFxnG+OkY98mwGlnmSgiCuWlACmrnGooBxidKxb
pqWuurKxmm4Su7m8spQ1fsO6t1iaFbvPy12AFp6whAt70diUp4SP2tjE3qvIr9eBZ8664hcJACH5BAAyAP8ALAAAAABAACAAAAPI
KLrc/jDKGYm1NOu9rvec84XQZ2KkcKLkuobu1cYmR4/ZNezE0Ps4zS1IGRJmvFtqWbHwgESmVPSaWq/YrPYBEHS3YABB/AVjxZ6y
WYr+dN9rEqDtHo/jm3naQufjKXN0aH13fxKBNG1qDGqLV4GEaXqFjApfjo+QMYpcAXOeZpCTkX6dAaegW6KKJ5iWAKiwc6qiF2R2
rl6op7C8tLOccIe7u7lMs14yGr3EyHGcGb3SxlmCGqCyhslpy5apeJHUjL5/4cvFJAkAIfkEADIA/wAsAAAAAEAAIAAAA8woutz+
MMoZibU0672u95zzhdBnYqRwouS6hu7VxiZHj9k17MTQ+zjNLUgZEma8W2pZsfCARKZU9Jpar1aAQIvtOgAEMNfrBXvG5OxJy04v
AWaTOOwOwc+W+AVdl8D1Znp5fRl/NHF8C2iJWYYujolckm5/d497DwABcJuUlYGPEJoBpJ1kn4hrEZykmnCnn3ths4wKo6W3tUyV
W5htfqXBpmWSMhq3wa+EiMetrbplZxqdroSKH9AMksN9goPN3HXedIXJ1qCYFKPrJAkAOw==
"""

def get_schema():
    options = [
        schema.Option(
            display = "Random",
            value = OPT_RANDOM,
        ),
        schema.Option(
            display = "Fancy Snoopy",
            value = OPT_FANCY_SNOOPY,
        ),
        schema.Option(
            display = "Lucy Classic",
            value = OPT_LUCY_CLASSIC,
        ),
        schema.Option(
            display = "Lucy Cool",
            value = OPT_LUCY_COOL,
        ),
        schema.Option(
            display = "Red Barron",
            value = OPT_RED_BARRON,
        ),
        schema.Option(
            display = "Snoopy and Woodstock",
            value = OPT_SNOOPY_AND_WOODSTOCK,
        ),
        schema.Option(
            display = "Snoopy and Woodstock Walking",
            value = OPT_SNOOPY_AND_WOODSTOCK_WALKING,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "image",
                name = "Image",
                desc = "The image to display",
                icon = "bolt",
                default = options[0].value,
                options = options,
            ),
        ],
    )
