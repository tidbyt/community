load("render.star", "render")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("schema.star", "schema")
load("cache.star", "cache")
load("time.star", "time")
load("humanize.star", "humanize")

METRIC_OPTIONS = [
    schema.Option(
        display = "Pageviews",
        value = "pageviews",
    ),
    schema.Option(
        display = "Visitors",
        value = "visitors",
    ),
    schema.Option(
        display = "Bounce Rate",
        value = "bounce_rate",
    ),
    schema.Option(
        display = "Visit Duration",
        value = "visit_duration",
    ),
    schema.Option(
        display = "Visits/Session",
        value = "visits",
    ),
]

TIME_PERIOD_OPTIONS = [
    schema.Option(
        display = "Today",
        value = "day",
    ),
    schema.Option(
        display = "Last 7 days",
        value = "7d",
    ),
    schema.Option(
        display = "Last 30 days",
        value = "30d",
    ),
    schema.Option(
        display = "This Month",
        value = "month",
    ),
    schema.Option(
        display = "Last 6 months",
        value = "6mo",
    ),
    schema.Option(
        display = "Last 12 months",
        value = "12mo",
    ),
    schema.Option(
        display = "All Time",
        value = "custom",
    ),
]

CHART_TIME_PERIOD_OPTIONS = [
    schema.Option(
        display = "Last 7 days",
        value = "7d",
    ),
    schema.Option(
        display = "Last 30 days",
        value = "30d",
    ),
    schema.Option(
        display = "This Month",
        value = "month",
    ),
    schema.Option(
        display = "Last 6 months",
        value = "6mo",
    ),
    schema.Option(
        display = "Last 12 months",
        value = "12mo",
    ),
]

# API URL for Plausible
PLAUSIBLE_API_URL = "https://plausible.io/api/v1/stats/"

# Config/Schema Keys
DOMAIN_KEY = "domain"
PLAUSIBLE_API_KEY = "plausible_api_key"
METRIC_KEY = "metric"
TIME_PERIOD_KEY = "time_period"

SHOULD_SHOW_CHART_KEY = "should_show_chart"
CHART_TIME_PERIOD_KEY = "chart_time_period"
GENERATED_CHART_KEY = "generated_chart"

USE_CUSTOM_FAVICON_KEY = "use_custom_favicon"
FAVICON_PATH = "favicon_path"
GENERATED_FAVICON_KEY = "generated_favicon"
FAVICON_FILENAMES = ["/favicon.png", "/favicon-16x16.png", "/favicon-32x32.png"]

# Cache identifiers and TTL values
REQUEST_CACHE_ID = "request"
REQUEST_CACHE_TTL = 600  # 10 minutes
FAVICON_CACHE_ID = "favicon"
FAVICON_CACHE_TTL = 86400  # 1 day

# Fallback Images
GLOBE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgBAMAAACBVGfHAAAAG1BMVEUAAQD//v/+/v/+///+//7///////7+/v7//v5gSunGAAAAAXRSTlMAQObYZgAAASRJREFUeAEFwTFz0mAAANAXwpdmhGKqI5yyJ7ZQR9RCHVNCYsdwEi4jnrrXO6N/2/cAAACu75Z3AIi7abMqbnMAT0W1GWVFA3DTjE68ztfPQNKUVxOiNl6UINuYvRAqcQcyeqhYQjTwFwoOJRYTXkFFOkVF/BGeL+zxdr/dDZ+O2fr3avXuO2H3uTov6v2XrspWHxal5IUoh1FLmotL0jkkG8JcuBC1MHohzKUl4QLjlpBLW8YXSEuSVrQhymHcElrJe5ISxiXnOcW6zh6ezj+afZNN/+BYz5rT46HrpqfDQ49dSQ8/ie8RFwww8G0CawY4sgTDxCpn3Av/wFW/iSfEeRhaoO/ClqrMfgHM7uvL6M3sBkDY1sXt4esGANf14xQAAPAf0R82TFufV44AAAAASUVORK5CYII=
""")

PLAUSIBLE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAS8AAABQCAIAAADHv2QvAAAbBElEQVR4AeyZA5AzyxaAe83ftm2ubWaj9W4mk7WCfTZKzyw+28bVbwUzk2RVtq7L1zzdnfRvLVPJ+eqrrrPmVyeZIXMnc/m241mjVcZfmW0XukY9slO1ubSecars0iS70jHsNsovVBp/cyzLnpa5gcwvCIJs3pFfZfpl18it3k9oT2Vz342cyu9nrthJEASZC0nJaafznO2DV6Grudjj0mrbn9u6u5E8LQiCxMcnnCv6lOxUoKV5VGe5un5bFUEQ5AnZtquofeAy72fe7XH5S/R/T0nfTB4BgiDxCUlluh9AMwtt56i2bZ+ZPBAEQVLTVpis/4JUFkfbuP9syXfIPSAIsnrt3q6RaxDJIlvT9p/4+GSCIAhn49azstMHbSyJjZaricmrCIIgy1dtl+weqGIJ1UlXEhJSSCyDICmpyzqGrkAPS26F6a8khkHwpmKiWf43lBAhnsz/OolNECS/4iuRkyJoG9e27tGTWANBNmw+1TOuRlSNYNuQmpi8gsQOCBIXF9fa/wINIPLMrfkliR0Q5EzeaGSmCFqd/lUbskiMgCBdIzcitkaw3PQfEgsgyJHT3ZGcIijZ/enLD5KoB0Fa+56P8BrBc2U/JdENgqzfdDLyUwT1sj8+IY1EMQhSXPtNdmNDpScbIrPG1sHg6i0NJIpBkPb+Cz0uNRyk0juuhWcwgso09EzsOf19Eq0gSEraSptLsY2rNhe1h6UIp42drEwoISKyrGibOlXphvuiJCpBkGNnJIiQqbAs4VR5nLxJG+sTXNomZac/q2HmbN1M+gq8sopEKVX6H7MUhQrrkM18YPKdKVbl4tdY3TFxrm7mfP3Mum16giBRiVn+Ny3QqchO5c4g75LHKfZkqMnFs8kWPFc3fb4enNp+yEEQJCrpHr5mc/lskKLTx4JUZBanKJOnCIqhB4QgF6VJ2eWv7pyEDsGshqms+qkD535AECQqsYzelJ18N9IahdCklZ02NtyzJ6FDOHsfEqTk0FoH/HfaMhhoGQD9Lf2B5gFmf7C5n57mvoC5P2DuC5r6AiY4e4OGHqpODla1T+Q0TkGHEGFWAziZ3TB5NP83BEGiEsvYLavDZ3WCIkUQClTBO+LU5Nt7UuNZwpK852mkZNfqurT8JtCfp/PnNQVydcGcRmp2I6RFc+JCYLwxiC0svOb2zJchl74/Ez7DyZK/k0glMzNz5X1kZGQQZP5Y+SCSk5Oj4e8o2d2ywwtByk56CkMROiBLfqoy6IJX8iCF4gKP2jGslRiVgia1UK/yIMFcHRikQo3QZMMElzbZSDPjTYZPiHBSRMgK5PXCx4JQY/BMxTMkUrl86cKHH753j//61z/I40AqKypaW5rvsbSkhNxNWlraPb9e7uBAfzT8HS1joRqFcjhF3iSsTahRSLNkEdIswfBtye5RpdjkKzIohXpQK9CrBXdsSDhzG/mepFmCUBdvjMVGs+Rm8VMUyMwNDVA11Ph/8jQcP36sxyY/lbJVajabqyorc3Kyd+3aiTUuAorivf9Xd+nShdiqsXv0hpXXaPfK9IQgFa7sZLOTz6qVSgcq1AizeNTqVCtavMVGqNHLgywyqAVsQ/ImRZbQJJdnCSfIwoP8RJ+iPXqC8P48Zvgkp0r/Qp6GT3/6k/CrnIuvvfbS888/84XPf27z5k1YI9a4gHSNXLXaPZI9FKRYjxJVlAkD69ABwsA3JKjILMXmfqXE6CkxQoreYoPYkKAGsiBFkwGQP58EeWMiSxigQDhZirdl25XrP1H4y0WuUfjuu2/++c9/3LZtK9aINS4IHYMXYDdCkJCiRAevBQZ+sjglO2SphE8FgqQpCtnNyboOT6nRzYME+YYMN6kWhPQX6LV8HQQZej7Js+SNseoC4Th5seKtPGPaM3ySQ+e/uVQ1cl9//WV9kw5rxBrnnxbbfyBFUBpj0gi5oQ55ilb6okLlQbInkCC/1lrb6SkzeUpNoSCLqT6wSE8tNKiQJVzdYWpUPU2LZ8YV4YlXwsALZBHyD4FT3XV4eGlrBN97762yslKsEWucZwyWP1kdtEYrS9Ey5rGM+egQbtLCm6SvVKxQI3TooFtRgpM1CXNdh7vMdKvM7GZBQpYeGqSBBWlQmKrYk+KiK38EKwZ2+kWucIp3KAx9FAzKhu11S14jfzK5YcN6rBFrnE/qW38mjbklqBEKFOtxjM3hILk8yHs2pAxCjZ23ys03oUYeJOxJaLLY4OVNigeudE/qP2bvLKAbN7YGvOVHZWZmZggzM5Pt5UKozLTMjGVm2PdelymcMjMzM3P7SVeZ+I9kRStrnfx90blnjk4iyWONPl2csUGmmK8Aplp4o1U7/FHtcLzAzEX+sfle/YFGZMyYUQM0erUNHTL44osu7CHV1ZX/WzSm5E0L1HcAJKkOUBQgBUVaUZWKSVGSgwVIOOyqEIDGlNL25BLUYztKEiB1eUiUpO5JKlWJaFgKkwozoVRsWqVIZUeOF55PzpT0hgc0nnH6aVmZmZaSl5szfPhQgqi33nrzTz9+b+NAbrLJJgM0Rm7769OYP6XqtJWDGzr9dR1IDyxhjx1BEYWpYjkCpNKQ2TXQ2CZAImjIICYxXJUziTwsWCrAhE/LfYQdOV54PuSEUV7RePjhhzk5fdddd7n//ntDAXnCCcd7O4obbbTRMcccXVVZ2dhQj+5duHDBjTdeP2/enEmTJlx04QX5ebn77bevox/etNo23HDDXia7braZ+ayNN96414/DaE9JTm6or5s4cfzcuXNuuOG6BQvmXX75pbzUeLsdffRRO+20o/2nU0xj/mhedutKIzfwkEMORqleccVl06ZNueaaq66//lp6dfZZZxYW5G+++eaRofEf//gH9Qz0inf69OlTuSFz5sy+9JKLR4wYxg0JWdaTlD0B1xH1iPgRONSwpBUlqVmt0gqQfiETFGl19QiNOTXtqaWtqaVt2KswiYZMRoKYxHAVESylFcYUaQKq7CPqj+p42u13jY8wjVKK9e67b1lepL6+1pNR3HPPPS684PxlyxZ/9eVnvVrIr736ymWXXbLtttvaFDxYniihYJvt+eeeMZ81atSVoY6HltNPO7W9reW333524mnffvutAb9vyy23dA2ADY3bbbcd/L//3js2ffjh+2/++99Fp5xysuc0qncKNtfq1Sv5IJtufPvtV3feeXt2tikCkpg1LrNknr+uzV/fDo2gCJCiIUU9KhTZoUWUhpQWIHN9bRqNZRqQoiQRHcgOie7oEVcELGXnISEzWIKpU4LzqY6PyV2x4YabRJ5GNvSS5UWmTJkc5ihCyMqVy9TT7FzeeefNmJjoPqTxuOOOffGF513427xx0Frbb7+9hzSiit984zWHHeBuz549E93rLY2U8vGiXKdbcdNNN1AT232JhKwxaQUzyof911+n02gIhivyoN4qw1XjUMGpi1G1k+tvTytrSdNoFOlmMkkx2Y1lZ5cYCtO8gyhu1fEHHn0OHe4TGimUs7wIhpDrUUS5dbS3qcPcPdb77rtPn9B47LHHfPH5p657jq2B0Rg+jeEIhRwYz17ROHbsaHfdeO7ZZ7bYYgvjKnEZV6QWTMsqXRjAaQTIOo1GCNR3DBR9oiEbugOtqiQAoUIgt6Y1vbwFSSujFSVpMImGVP4k+8KktMIYfIbYkX3lhbb9/V+79hWNxx9/nOVFML3CGcVFi+4L85FCr0aeRnyzJx5/LJxul5QUhW+phi+jR4/yhMYJE8aF0w082y4a0y9PypmYkjelbNhincZ2n84k4qvtVpK+HiYrZCogNd3YklHRnF7eJEAiACkiTOpA0oqqNOBkX0gLRlR2VKuOP+yEy+htX9EYHxfnuW5kI7bxyScfhjOQGF177bVnhGmk8iGcPi9d+gAX6Q804t3tttuuYdLI1AJxNMIRYmDatWLTLk3MHo9kFM+DRgFSQ7FrR4xVPboDjYiqENBFr2vN9zVnaCg2ZZQ3a0qyrBmrVelJBCCR1DLDfBU4FZbGDm1pR/BfEOPg4qZ//Gu3PqSRiR2WF5k61b3faG8DI7/++tN3333Fjr3UnnF6hGk868xGm/6QEyJgQ/rH8r/ff/c11nU/oREh1BkmjTZmwo8/fPfSSy8sX74U/5Br4urDrZ2RFZN6cWLW2ISssbRFgXuY0qGpx9ouk5W2tlOZrEasFRSVvUoLjf7mzIq1mRVNGRUGkwCp267N4k8CpPIqDTKRMqUzVWvsiMiRyH6HD6erfUjj1VcvtLwIMf3wvf877rhNKbqmptUEV6Ojo3bYYQcMQnn+iLhWlJc9/HCnZR/IKESYxuuuu9YSwjMbG4JVDZ4hN5nIIXn8Z595Wg4jys+/1h+Nn3/2MYCRH+JzTzrpRIoKZs2aARKhjv/wg3fDoRHFGIpDInzbbLNNj+NJ9jzzzJPm43ntao50VNL5CZmj4zNGxWeOSsqZVH362gBAIspkFRH1GFQYgJIUIKGxINCcVbkGILMq1wIkWAIkorCEySCBzDbxLWlFZwqfiOwIhKJXY7Lu2GjjzfqQRu44asryIvwrfBoJ5xAP5KFBadgnvl955UXz9Xn1RpjGhx7qMB92zz132V+cPCo5QFKa64/Ge++9e+edd7acy7948X9DnXXiiSe4pnHGjOmW15TsheVGsvHjjz8wn5KcnDTolMTzYtMuI5YTl34FWKYVzPLVtmgasjbYh+w0RGU+JAnZYAg0ZleuBsWsCo3JLj0Jk2sBUpmv0gZjSStYwictoijVDihvTS5avvlW8oz2AY3k08hfh0o2fvPNlzwc4dMoH+Tku1x55eXm6xOYjTCNnR3t5sOam9e4H6TwaZSi1tAbNQyWLxGEjLxrGh979GHzkRRs2H9Z3krms+rqzhh0cuI5MamXRKdeDJOCZXb5NQGNRk1DKpPVRyscIrIjKOox1cJAU07VquyqNTqTaxBhEj7BEhHztZtMJAhRwVIXYrPsI3JM0467SkrNexoxPseNG2MplG5wQ1etWm6fSp4/f67nNRzq9cmaAxhamRkZIIRvSXHJ4ICfXpmv/+QTj0eYxvvuu8fy+mS009PSKJboExrj4mLtP2LkiOGWJ1JK4XocMXTNR7JqhH1PiNlYe7AnJZwVnXxhdMqFMIkAJEqy0He7v65VgAyIhlSpSPzGOsNeVVI0GBpXAmRO1WqAVEwiSlWKKMdSWiKxsi98Kv0p/9r3kCq67j2NHk2qOvTQQ7yiEd2Yk509efIkXgGEQNapJyAUYRopebHv0nvvvkXqZebM6aeOHBEbG0OVzPqmEWes14/YeuutGTVLDNx1hsobXH1z7A1r+V+225FHHmG+/m233TLohNj6qOQL8B5hMir5QgESN1KrB6htDegOZAAxUNQkEFTICopM/ige0pRXvRIgc3UgRU8aqrIiGEtMWXEsEWjsRjRIhRp/OfJkeWP1UxqpzvEka0zmF3ff5Ej0axr333+/de0kISgqRVk2wRMaXRsgH7z/rqXH664zRNf4u4fVCIOOj6k9OeHsU5LOBcio5PN1JXkx9ipR1rKh/5FwDkwi/u5a1k41CUukZMiavOoVAJkrTFZDo2Cp6UkhU5g02bGG9PjL0VGXbLTRpv2WRm6cJ1lj9Ia5nqv/08hGotVddhTlD8ye06gCy/abZTyztaXJXWeod/XwocL+H3RczBknxjWeBJCJ556SJDQa9mp85ugi/x2Bes1YFSUJjYhCkZ3B7DRC42qNxpoV+TUakGCJegyyXWnhEw4NOBWW2QR+2JHW0KKr9ztEzWrrdzRih1CV70l944EHHvDlF1Ij/v+PRuYotLQ0uesw0a+oqFO8pVElTuw3yz6DqLvO4Fx4+Gj95z/3Dzr2lJEnxjUApK4hBciLKAmIz7iSnAdVrDnl1wXwIVGP9e0INDL9Cg5pWTQALAGyZMiqfA3F5YhgKUwioippRVWKzgQ5sWMVn9JmlC3eaTcZp35HI/k0gig86F7V/j8qs91tF+B54/VXeVY4knggsdOXX37BCY2HHXao5QWZUmR/r154/lnzWQQAQ0UpcSAljLGuQniMvI6HNI4fP87UQaf3nGCsu3EkzOYZjVKidMzJwzFWAVI0JMaqUo/QSEkAZTpUsfrOWKtrSFGMoKi17AMkurF06Or8mmUFvmUCJGQKk8p8pRVVCZm0CktxMqVNyrt5i6325kv2Hxopy6bSAiuopqZKJbI8oZHkm+UnPvXU40wOAieUj/ksv8/nhEbylpYXr6wot++/pdnMDbTPHDBhjwIGKRtyLpQKeEijKvW0395663XzucwpdzeOe+yxu2c0Ssnx0ScNOS76dGI5oh6J6ER3xXJIP6Ibk7LHU8jKPI+SIfdhtRoa0lCPoKhJ6dCVBb6lhdCoMbmcVpgUVSmSW2UoTFpEyBTNmVWx5KAjB0uKP2I05uZkH3TQgZayzz57U0VBKYznYXr7kn/yePaJR4panNBI+avlV6a+z77/H334nmUezOE86QMO2B9jGEue8CB5F3s+UfUe0sjUUCc9pC4v1LQ4F51hsCxjqkWFBRix6ypUknTrxpPiz0Q3iqWq03ip0o0peZNT86elFUzPLr+6YsSSQAPGKihKizxYNmxFoW9JoV8DUhdhUloRpSrFvRQ4icEuPybq/H9t7mJyRkQr4zynkefVfCSw2V+fckcnNBJDd2HOYTpalhwxP9j1DTn44IMo9GNyrfmyhDc9pJGCuF7n9Wekp1uee87ZZ3mbbyQ45/J+HRs1EhpFNxLIUbpRojjoxsTscczwSMmfinpML5rF1OTcyhsqhi9BQw5pfBBBN5YNXV7kX4IU+hB2loqqRAwLVmlLn+FeZpbee8QJtf/cXJl/f1kaiSI6PNLeksR2ff21V81nUYTpMJRPsajN9bHGLW9UqDnN5LgdlhBRzWsZD/M2+3/B+efZd4PiBMsTWffE9Tg+/tgj5iNJtLp8gI6LPk1zGuPPxEw9GRqTzgdFKcqRKE5y7kR0o0Zj4YyMojnQmF22ECWZV3kDtmv16avAsmzo0uLAYgQgiwOC5VKYhEwNS7+hLQtqlmWW3HZ8zAW77BG14UZqIP86NC5Z8l/LmbU4V07Gm8I3m4uTpLb8IpiXDmlH0FShAryWISKE+vVQ6PLVYICsuv1t4XG3XLvAWxqZm5YQH3KhFma6WKb+EcqeXI8jixhYvmiYdOZkxS0mRgZ7rWT/6yjHERQJ4egFABdDIzFV5TQm52qWKooxoxga52eVLsituDa38vr86pvyq28mC7Lt9gfsvX/K4ccFTkm8NDFrWmrevIziG5CUvHkJmdNOjL/40GP8e+ybtPmWu0eGwL6ikWBGqFRSWWkJI6SK+ok6WIb+KR22DPncffedNj4YXigPYnDgh7KeUAez6BarXeHjgRlxCCZSn3vO2Vh6lgcT9jD3h7PUxH/pNgtbYAcSPTI72xTKkVew9/Q8nMPB/BIMRcoMZF4/631QhsZiX6GOR7m5G0f7sCq5KwLOoYoEiU2QN8LK7RnQwl3EQNVQVB5juq4YM0ZpNOaMRzem6ooxvRAa50IjijGni8ZC320gGhmu+j+NFLjaPytYd70Wl6GjSD1de+01zHnjOXa+1ArZF/NiBWEKVPf4jjzlpARsZvSxtATA80DDEiU4oZbARKt4S6M5I+WkwgkrOpxxtM9Uff3156zaDMNM0CEyjxrk55WofDT/vgtz6LRrSVYDAUVdK14aly4ojgXFpFxDMaYWTBenEcWYo9OIpZpffUtBzW1o1wEa1dRhh6MoEQVvpUcu9Omnnwi/1MGcX6XAzZPe+mqq+3y28auvvkStaTjjyMYqnhL9Ckeo7NWWrkcxCoeIlOCgGPXcBtHUbsUoZqqiEcWYV3VjQc0t6MZ9D0odoFGtR0q+3uEokl9arzQybU88JZdiWtmAjZsmaxOGKUSewKBvaUQjseRp+OMolo43+UaCqECIiK+IVpTgjaAoijEtSDFmdylGaARFnMYtt959gEa1ERd1OIqk+F3QwjRC7B8nNLKRKuS17frh4NE3r2KMxcVzHOZPmLD6o4eVcSgWF2qf5RQ8GUfZiGaFc09wX1mGT1sXR6YaA6EkGJWNSihVJTZUNBXFCIpKMcKq6tAAjbIR4AYzJ6PIDHEeTecl15Tm8dpmmpJDGiUPQTBwXWsAcRdtlhin7JtgibsiW5YaYS1wD6vGcQ6JqZDBBzDnlb0EvTwcRzVr0b7aMVScjHWGjLtNzEZxKLl+EoyGVlQ2apGEUhdml11tRFOrboLGosCd+x+aNUCjeePizPMgv0e8MXiFMh4Cc86d1ypH2qw7xiLCrN4b/BBT7dHW2qyeFUGIA0IVr+EIsRSFfVSDAAwhB4wuSnkcmuW8TZjMQfEg5/a6PjoZGvU7/q5p5EOp8iGZEfx7KvIvfhMBfii1DXUnuf/cBBZzwEj2fBzVRjEwL81e34AcQJycEpz/E4XGOhUIFYeoRNL9ykAljqq0ogqlgmKB77b8mps33ayXAoiBjXQcL2/56QX7iY7k2RlL5vhTqspkf4aKv3CuzVmsok8Qn0i6wzo+Qv8E6MlwEERh0X4WcQJUQkpHHXWkw1R+KOCZe40bVlxcSP8hhCtjCvIV0NjUBq0PF508IaFIPtp8T5gjwkeT58SO4JuyIgFZIroRgXEMTuFyYxlHfh6CdxyFVjgOVBpT1hvyJ+uFQOTPds4pu7ooCML7R2zbtm3bdh4zjNi2zVmmz66Vi+c4qW+dKXyrurr3vRhNq/V0iiUqNjcIRjTG1oFz2IjGmJI1qAghb0V166IMpchDeCjTqdEVOw0Vm3oPTI9vWvoxoxoXf7FR/PxvY6/eCkKIhGFtxzq2NeIhIrGucwsDqihn3qMOXerHN7cIxpCIQvWGEEJERWxNJQyRh3j+plU0uqLe3Jyb3sFBRXlrrt4WQojJwIYuKw9Nb26wRDWdNDrHHqtbl//9t1WEkLcFBup+eAAJm/oQiceYTtEVoaKcNOo7N+0d3BUh5M1pepFQJlKREHmISwau/DKd4p4hA6qo6+DkqQgh70Fz77HUQkyk8FAkREs0RSK6YlnDlJ29qyKEvBNtgxe6Fl6awtDIQ90STTsb6YrpueN///5T7wchRDIQBiIJ8YmEGE27xp7k+OHlG6veG0IIaqFpIpXfK2JxKirWdW6Ex5R/UCQSQowAHH+Cfvjahi7kf6sCQjL//PmjPhJC2Bsbu3crmmaziyaiExu8/eI/JQwJIc9ASKHlB9a76QAAAABJRU5ErkJggg==
""")

def main(config):
    # For the "add" screen, show only the logo.
    if config.get(DOMAIN_KEY) == None and config.get(PLAUSIBLE_API_KEY) == None:
        return render_error_screen(None)

    time_period = config.get(TIME_PERIOD_KEY) or TIME_PERIOD_OPTIONS[0].value
    metric = config.get(METRIC_KEY) or METRIC_OPTIONS[0].value
    token = config.get(PLAUSIBLE_API_KEY)
    use_custom_favicon = config.bool(USE_CUSTOM_FAVICON_KEY)
    favicon_path = config.get(FAVICON_PATH)
    should_show_chart = config.bool(SHOULD_SHOW_CHART_KEY)
    chart_time_period = config.get(CHART_TIME_PERIOD_KEY) or CHART_TIME_PERIOD_OPTIONS[0].value
    domain = sanitize_domain(config.get(DOMAIN_KEY))

    # Alert the user that the domain is bad
    if domain == None:
        print("The domain that was passed in was bad, showing error screen")
        return render_error_screen("Invalid domain was used!")

    # Alert the user if the Plausible API Token is missing
    if token == None:
        print("Plausible API Token is missing, showing error screen")
        return render_error_screen("Plausible API Key is missing!")

    # Get the favicon based on if the user wants to set a custom favicon or not
    if use_custom_favicon:
        favicon = get_favicon(domain, favicon_path)
    else:
        favicon = get_favicon(domain, None)

    # Fetch the stat for the given metric from Plausible.io, grab the int value
    stats_results = get_plausible_data("aggregate", token, domain, time_period, metric)
    stat = "%d" % stats_results[metric]["value"]

    # Bounce rate and visit duration need special suffixes, otherwise run the compact_number
    # method on the value to get a string that fits into 6 digits.
    formatted_stat = ""
    if metric == "bounce_rate":
        formatted_stat = stat + "%"
    elif metric == "visit_duration":
        formatted_stat = stat + "s"
    else:
        formatted_stat = compact_number(stat)

    # Determine if the user wants to show the historical chart or not.
    # If yes, fetch the data from Plausible.io's API and convert it to the format render.Plot needs
    # If no, do nothing
    # Either way, the end result is a list of children that will be rendered later
    data_children = []
    if should_show_chart == True:
        results = get_plausible_data("timeseries", token, domain, chart_time_period, metric)
        plot_data = convert_result_for_plot(results, metric)
        number_of_data_points = len(plot_data[0]) - 1
        largest_value = plot_data[1]
        data_children = [
            render.Text(formatted_stat, font = "6x13"),
            render.Plot(
                data = plot_data[0],
                width = 35,
                height = 10,
                color = "#0F0",
                x_lim = (0, number_of_data_points),
                y_lim = (0, largest_value),
                fill = True,
            ),
        ]
    else:
        data_children = [
            render.Padding(
                pad = (0, 3, 0, 0),
                child = render.Marquee(
                    width = 37,
                    align = "center",
                    child = render.Text(formatted_stat, font = "10x20"),
                ),
            ),
        ]

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Image(favicon, width = 20, height = 20),
                        ),
                        render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = data_children,
                        ),
                    ],
                ),
                render.Box(
                    width = 1,
                    height = 3,
                ),
                render.Marquee(
                    width = 64,
                    height = 6,
                    align = "center",
                    child = render.Text(
                        metric.replace("_", " ") + " " + make_description_text(time_period),
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = DOMAIN_KEY,
                name = "Domain",
                desc = "Your domain to get metrics for. ",
                icon = "gear",
                default = "",
            ),
            schema.Toggle(
                id = USE_CUSTOM_FAVICON_KEY,
                name = "Custom Favicon Path",
                desc = "Toggle if your favicon image isn't at the root of your site",
                icon = "image",
                default = False,
            ),
            schema.Generated(
                id = GENERATED_FAVICON_KEY,
                source = USE_CUSTOM_FAVICON_KEY,
                handler = custom_favicon_options,
            ),
            schema.Text(
                id = PLAUSIBLE_API_KEY,
                name = "Plausible API Key",
                desc = "Get it at plausible.io/settings",
                icon = "key",
                default = "",
            ),
            schema.Dropdown(
                id = METRIC_KEY,
                name = "Metric",
                desc = "Choose the site metric you'd like to display",
                icon = "chartSimple",
                default = METRIC_OPTIONS[0].value,
                options = METRIC_OPTIONS,
            ),
            schema.Dropdown(
                id = TIME_PERIOD_KEY,
                name = "Time Period",
                desc = "Choose the time period for the counter display",
                icon = "calendar",
                default = TIME_PERIOD_OPTIONS[0].value,
                options = TIME_PERIOD_OPTIONS,
            ),
            schema.Toggle(
                id = SHOULD_SHOW_CHART_KEY,
                name = "Show Chart?",
                desc = "Toggles the display of the historical chart under the count",
                icon = "chartLine",
                default = True,
            ),
            schema.Generated(
                id = GENERATED_CHART_KEY,
                source = SHOULD_SHOW_CHART_KEY,
                handler = chart_period_options,
            ),
        ],
    )

# Generates the options to choose the time period to chart.
def chart_period_options(should_show_chart):
    if should_show_chart:
        return [
            schema.Dropdown(
                id = CHART_TIME_PERIOD_KEY,
                name = "Chart Time Period",
                desc = "Customize the time period for the chart",
                icon = "calendar-days",
                default = CHART_TIME_PERIOD_OPTIONS[0].value,
                options = CHART_TIME_PERIOD_OPTIONS,
            ),
        ]
    else:
        return []

# Generates a text input for the user to add the URL to their favicon.
def custom_favicon_options(use_custom_favicon):
    if use_custom_favicon:
        return [
            schema.Text(
                id = FAVICON_PATH,
                name = "Relative Path",
                desc = "Relative path from your site root to a .png favicon eg. /favicons/favicon.png",
                icon = "link",
                default = "",
            ),
        ]
    else:
        return []

# These values are unfortunately duplicated from the options constants defined for the schema
def make_description_text(time_period):
    if time_period == "day":
        return "Today"

    if time_period == "7d":
        return "Last 7 days"

    if time_period == "30d":
        return "Last 30 days"

    if time_period == "month":
        return "This month"

    if time_period == "6mo":
        return "Last 6 months"

    if time_period == "12mo":
        return "Last 12 months"

    return "Total"

# Converts a large number into a compact string that is 6 characters or less.
# Values under 1,000 will be returned as-is eg. 120 stays 120
# Values over 1,000 will have the suffix "K" eg. 1,234 becomes 1.234K
# Values over 1,000,000 will have the suffix "M" eg. 1,234,567 becomes 1.23M
# Values over 1,000,000,000 will have the suffix "B" eg, 1,234,456,789 becomes 1.23B
# Values over a billion will return the string "A LOT!" (What are you? Google?)
def compact_number(number):
    value_string = str(number)

    # Get length of string
    character_count = len(value_string)

    # Return the string if it's less than 4
    if character_count <= 3:
        return value_string

    # Thousands
    if character_count <= 6:
        return decorate_value(value_string, character_count - 3, "K")

    # Millions
    if character_count <= 9:
        return decorate_value(value_string, character_count - 6, "M")

    # Billions
    if character_count <= 12:
        return decorate_value(value_string, character_count - 9, "B")

    # Yikes, that's a lot
    return "A LOT!"

# Takes a string, grabs the first 4 characters,  and decorates it with the decimal separator
# and the correct suffix eg. "1234" becomes "1.234K".
# It will also remove any trailing "0" eg. 1010 becomes "1.01K" and 1000 becomes "1K".
# characters
#    value: Any string to decorate
#    decimal_index: The index in the string where to place the decimal separator (1, 2, or 3)
#    suffix: The character to place at the end of the string ("K", "M", or "B")
def decorate_value(value, decimal_index, suffix):
    # Convert the string to a list
    value_list = list(value.elems())

    # Take the first 4 characters
    cropped_list = value_list[:4]

    # Insert the "." character at the decimal_index
    cropped_list.insert(decimal_index, ".")

    # Smash it back into a string
    joined = "".join(cropped_list)

    # Loop through and remove any and all trailing "0" characters
    for i in range(len(joined)):
        joined = joined.removesuffix("0")

    # Remove a trailing decimal separator if present
    joined = joined.removesuffix(".")

    # Return the joined string, with the suffix added
    return joined + suffix

# Removes the chance for human error. Does its best to remove
# the scheme and "www" subdomain if present.
def sanitize_domain(domain):
    # Check for empty at first
    if domain == "" or domain == None:
        return None

    # Remove whitespace
    stripped_domain = domain.lstrip()

    # Strip out "http://" or "https://"
    prefix_free_domain = stripped_domain.split("://").pop()

    # Remove "www."
    final_url = prefix_free_domain.removeprefix("www.")

    # Don't bother

    return final_url

# Makes a request to the domain, and will attempt to return the site's favicon
# icon by assuming the three most common favicon filenames.
# Defaults to GLOBE_IMAGE if it fails.
def get_favicon(domain, favicon_path):
    cache_id = FAVICON_CACHE_ID + "_" + domain

    cached_favicon = cache.get(cache_id)

    if cached_favicon != None:
        print("Returning cached favicon")
        return cached_favicon

    base_url = "http://" + domain

    if favicon_path != None:
        print("Using custom favicon path")
        favicon_url = base_url + favicon_path
        response = http.get(favicon_url)
        if response.status_code != 200:
            print("Failed to get favicon: %d" % response.status_code)
            return None
        favicon = response.body()
        cache.set(cache_id, favicon, ttl_seconds = FAVICON_CACHE_TTL)
        print("Got custom favicon")
        return favicon

    for f in FAVICON_FILENAMES:
        response = http.get(base_url + f)
        if response.status_code != 200:
            continue
        favicon = response.body()
        cache.set(cache_id, favicon, ttl_seconds = FAVICON_CACHE_TTL)
        return favicon

    return GLOBE_IMAGE

# Makes a call to the plausible.io stats endpoint.
#    endpoint: the path to the API to call eg. "/aggregate" or "/timeseries"
#    toke: The Auth token
#    domain: The domain to check
#    time_period: The time period to check (doesn't support custom date ranges)
#    metric: The metric value to return
def get_plausible_data(endpoint, token, domain, time_period, metric):
    print("Getting data from Plausible API")

    cache_id = "_".join([REQUEST_CACHE_ID, endpoint, domain, time_period, metric])

    print("Checking cache")

    cached_request = cache.get(cache_id)
    if cached_request != None:
        print("Returning cached data")
        return cached_request

    print("Building new request")
    site_id_param = "?site_id=" + domain
    time_period_param = "&period=" + time_period
    metrics_param = "&metrics=" + metric
    request_url = PLAUSIBLE_API_URL + endpoint + site_id_param + time_period_param + metrics_param

    # If the user selected "all", we have to add an additional "date" query parameter
    if time_period == "custom":
        past = "2000-01-01"
        now = humanize.time_format("yyyy-MM-dd", time.now())
        request_url = request_url + "&date=" + past + "," + now
        print(past, now)

    print("Final URL:" + request_url)
    print("Making request")
    response = http.get(
        request_url,
        headers = {
            "Authorization": "Bearer " + token,
        },
    )

    if response.status_code != 200:
        print("Request failed with %d" % response.status_code)
        return None

    results = response.json()["results"]
    cache.set(REQUEST_CACHE_ID, str(results), ttl_seconds = REQUEST_CACHE_TTL)
    print(results)
    return results

# Takes the API result from Plausible and converts it to the
# list required by the render.Plot method.
# Could probably be optimized by the zip method.
def convert_result_for_plot(results, metric):
    final_data = []
    largest_value = 0
    for i, r in enumerate(results):
        safe_value = 0
        if r[metric] != None:
            safe_value = r[metric]
        final_data.append((i, safe_value))
        if safe_value > largest_value:
            largest_value = safe_value
    return (final_data, largest_value)

def render_error_screen(message):
    if message == None:
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = 2,
                            child = render.Image(PLAUSIBLE_LOGO, width = 60),
                        ),
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    render.Padding(
                        pad = 2,
                        child = render.Image(
                            PLAUSIBLE_LOGO,
                            width = 60,
                        ),
                    ),
                    render.Padding(
                        pad = (0, 2, 2, 0),
                        child = render.Marquee(
                            width = 64,
                            height = 10,
                            align = "center",
                            child = render.Text(message),
                        ),
                    ),
                ],
            ),
        )
