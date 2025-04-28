load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_PRESS1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhxJREFUOE9dVUFyI0EIE/T//xBnz+t9m3PvJiUJxuOdSo2remiQhCCBiIoqVAT4iwBQwb/PpwoRgEP8PYoh77vKwWMG8sM+xVDwff3q0jyFyEUMOrjVZxbliODNvl67kIswAMO55QrgnINUdV0aiEJqRhfCUrUircwufUsYxAycfRBrdUFVFSpnM6+QhqTJ99mIlQ5sPvoqYUoI+d0K8VAKWktdaYQGC+zaWJHNeBBSdFM/p5DJcydTEz+eRii4BWxqREoEcI5RkgSTUDcxWEP0hqy7oC6LsvWT6KIU2LzMJAVkpnq098bK9bZU28YumabYH+pqUfS0tKf2aOIzdbnc5Qic1zC3zVj5z/NhJdQpBgmBm0I9hT2oGzvfkgjtQCqcF5tmyR7Pr/GhnUBbrOWmEK2UCVLmFBE1GWRPlL1YLw8FY53Q9pZWpLliOXltq0Ir0ErS+G58O4MIOxCPv189Yy2pECYRsqNE6OqZS7c9KWbQOFz8x8J9/3uYsuegUBI9ry7a8G+jkXKGbSX0l7Htyz7TrlFm2oJolMhrQ6U9ATMpTPiejo95lwvHNrRKG3cMfdsePcseTQ1Ye9fu6/cMkAd7bNHr6b4TNdfjU9rK8Tq7Erau7Qx1nqK74xZOdutBlvsjsPhdI9Z7s5fNOFN72lvjWm/Xir22SVtNm7jR9kYcrLfFrH8BvYYGUZczUjfGE99rygL+t4Qd+wuWw2uVegtaNgAAAABJRU5ErkJggg==
""")
ICON_PRESS2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhZJREFUOE9NVEGSIzEIE/b/37CpmXv2bTu1V8OUkGgnOXS3bbAQEhERVShEAQigCgg++VlAhZ7c7Ide7x5XeQiFigD/Osf1Sn04kpt9iXIwBHstne1QrYUR3HPcDCDzIGIbUoDYO8qXnEyspX2hd1KeM3RmKtaphKmEH78ugJsonJNCOHU3PsMnKObpk11ZQAi4MYeGS8HM4oVLQUTJZwmTqGwOg3sKcEIdvc1pkABOEWF0EkNRsulBp1NN3d6ThbWFMJNdawhYe3c5TQk5VFHPjV1QpzDqqTvruIvRaPouXuckXcFWyU+JT+ME6iI06WsxgHyeJpLB4UZUJuq/1lSUoHz/fT00CCnJZJl1JAvyeZhQTRmp1CnEsjb/WcABfL9f1qrUIlYjkEclcYnvShhec9NCsqmf8UPg6/1HyrKejZBNSey9+oZiQlUE0sAP8qr3Qv5YXih8vV+Pl+RKm5aktyzYenPYdgtdkkXrSVJEnkRZoZKbiSnZ9srhyM0YNpr75rWE0HKSgZhGicY00iGtR2u55DszLHKqgDptDp8QD4qHHU8bQ2gdtpcv4Z9zjdOoEV4Dy822bhPhEah5x4C2zh0xz2y0NenliRpDqFyb4DFjz8NjB3yU0ByNIoG9t1CNnyeRPEynjLsVpEnNTptkT1x2XnnvSO92eE5oU0qsHqRTJsfjjGnrX5r17OukHvQWs0Cojl9ZCGSNJDwwIgAAAABJRU5ErkJggg==
""")
ICON_PRESS3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhNJREFUOE9NVFtyI0EIE9P3P0PWyXeSs+3rsyElCXrG5bLHbRrQAwJARQS/UACi+AQEwt8BVPGJr+g3YwPBc17lRz9HBI9LiXYyzKlVREFMPCX4UxmcmMWDpfnqIoyfNLkLa126zo/gjQnn5dyI63Lb7vF0r2cWYR/qooCsjYsXOqEvOrlQbSc0yruvG3IQgZjwvUxD8rt5uonNTBUUooYs3M3BgGan6oIXYrnDiasgv+5mKyG7mMYtjAs4ztAFvpBZuOISF0m+VDxwrUlYWPp/OHB3kuUhdPdcqEqTXqGErQeuWKfgEiVtqVGWXTZNFqXr7GpIgs9jGwb/LISQ+wMf3y8J2VdbuPFLB4r0ZV8xYadzh/z1Z8wCvH+/OWF3Jhna581pINkh4UQgaRHxEhYCgf1XTpY/X1+/7NV21UAYd1jlIuk8Iocp8sm/vBnA/n3sh/fPl+mQnj1RGhEbXNLLuLJNyJMz3FReCXcC//3/x+ebhXDTrd/YRgQEJEpQgMFiNT0YpVk3/DPmPaYNnHMta3aEIffonQkwSYxh1/bpI2lPgQXq89kguTkpPQYzcYLjJSDjz6QMzvbOrDpLphZslcWEpfE568kM3JB7peiM3XozeW8K8gzvMfO9WW9Da7Za8cd+lD8FtdMcDrVke6eJ9FP2KHi2+vFeb+3ZNkSl9TUz9CB7XPtYpU9/3Eu453km+Af6OmuMfKEtMwAAAABJRU5ErkJggg==
""")

LOCALIZED_STRINGS = {
    "ding": {
        "de": "Ding",
        "en": "Ding",
    },
    "dong": {
        "de": "Dong",
        "en": "Dong",
    },
}

def main(config):
    lang = config.get("lang", "en")

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
                            render.Image(src = ICON_PRESS1),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_PRESS2),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_PRESS3),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["ding"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(" "),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_PRESS3),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["ding"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["dong"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
