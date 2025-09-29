"""
Applet: WowCharacterStats
Summary: Show stats for a WoW toon
Description: Show statistics for a World of Warcraft character. Stats shown include name, class, item level, Mythic+ rating, and raid progress.
Author: KDubs
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

WARRIOR_ICON = base64.decode("""
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
""")
SHAMAN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAcITNaAAAFM0lEQVQ4EZVVbUyVZRi+nvfjvOdwQL4CHBZxRBilojVFlhwBZZq12frlELO2/FyZ5MKPiaQ5HVNzTcfMrVr8yGZtTTP7WsUPmps6HTpyshkyFFFCDyAg5+M9V/d7ODjHaq3n7DnP+z4f13Pf13Xf96s06MT/aEoRpPrPE9rjOxRs6FDQ5Dc2KlDmCrw2uq6U4bODhTi1ZQoKDRsOdlRW/7XFLaYSjGIdLAC43ACDXZXkQ/DuH8VcLGsV0l916UyVPeH+fOZp4FRdUdd1OhgTu2Mbt/myuSJTPAzu5FBfGV+Gl365YKaWyJtVc8maUnJbGfNljm+Xc4aMUdvkPLiYY8bM/idgxYW+FL4INwssg1Vui21eD9/0ORe9x2oB6V4/m9enpTBLrOyYnMRjbpPP6Ukcvl/KlS4vIR4CxgRwsXlu5CE8KoIjviyUpxK9tYlo8ZhIyziCHn8Wkndp+LhjCHXeFHzTF4Y9auOT5hx8kPs7jl3Lw3LdjSkqCmWYQnk0RrtGmQjIZjICdt6G4U7G85VDGOgGtj8Twa0LAwi0XoOJCLrNEWy8U4zq7grMKW9Hz2QLpVOv4NPLCpVi7ywVElh9TE8l8bNShKmGxf0iDOvL+I64v2C64kinn0tLpsWE8xiKNbLeuL/ICQXq8PDWT+lcnaCxPEPjg99SeHJXES1ZGxPSMZ4GQgjjuHOXlYYiU8Oy/kTMz23B7i06ZklQ1keIkLhcmvUX7N4SVGshNLwUQNPDKE5XzcecJf3IqbiCunXpDgqEYcVXoHH4UgVrc70MdJXy3p8L2bzVz2htBTdJSO01tdhzjYi7VWmsFw+PipBNhskqsfCcW+cJ3eQi8frHhkKxWFE4Fj2VgaYD5zHQOYzdOWeRmtOJMx+2oC/RwhvJXhwJRxF2dA/bcjSKBEMhTXfhQCSMfU+l4ysRs0MP4+fRd9G04zqEXmiCjVYjhJYvbTTrCr1C/w8fWRgUoN7pJvqHbdRNMhFoH8SQ5kKiaLP2xmLM+96AV+k4ejsAGdDu1jB4/wKm2Q4LEhkO0atdLmouD93iFkM5vNM2j1e/LWZPWxE3KYOjmxfxjGSdT2jY7gUfdPm5s8jHX/c+wRXuBK4XqsiDbBAK3k/WRTGJawe4xJTgVi42Lk1m3+UZPO5yc98CnaG7L/B12TS6MZezlM5ocA8LJZG+3pPKXyQparOzuGqSxYBEz8DNEiapZCrXWFQoB3iZS8PJkI0dpo6nVRjnxJOiCLDujh+vZV/EctFgaW8+vqu9Aa9LlJuUhr37O3FeTm/IT8GUhLvwtmrYJLxrdjgWFGI1YEYjyBJ+08Nh1MDCqORogxpGz8V+eRrBF17As28QJz6/j9QEINt3D5fEV4oO7bf6kRe2sATBGKATDFJZ5U8SZLO461ImT/lnU+4UWsA6cenwGjcHzj7LgUtlXOMBfUIZkl28lgThUVFpRkyXTNmv6VY8MeKVzkF3ZSYhJLXiybPtkrhSyCUtZ4aA5lMRdIWuovGtVhSmZqDT1mAORlAQciOqW1BRp1qbyBRLYAt3jzXJKQ0pljtmfrFTgOOuBGXMNCIIt3pwus1GsDfgmCmBZOBwUHiMc0nJ2A6Hk4nNEa8+K50Si49ckcsYPLSWGyZlcIXQJBqxUUZdqJDQJw/VyIdhzGXn3dTdj846eE6PhVuecDS+0Zl0+PMneLjQa3GVFYtJVjrATt2VlNrq8BsH1jTRxOlxwPExFm4TvRh/9+hRjNiUr2C8FMYWxuqtQ+FYc97Hn+NTMvwNzolwttobi8AAAAAASUVORK5CYII=
""")
DK_ICON = base64.decode("""
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
""")
DH_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAcITNaAAAFB0lEQVQ4Ea2Va2wUZRSGn7nu7G7bbctCL5QCBYLlUgXFtoKgGKMSFA0aE0k0JBAIRCIxMd4x/vKfUSP+AIM/5AcQAwkYTSAEkEpCgYBAW2zLrdy6hV53u7OzOzOe6dKISmJiPMlkv3z7zXve8573O6MAvjz/e6j/FVFTdFRLh2gERVHQUVDlkeVIyD//Hpqlokc1CmrKyEZdQhVj0apjYIRwDZVQuU+yPU3/5iawBdn3JcV9pFA0Fd/18hkNKK6vwKoeg6n6aIpPWs1imhZ+PIwhj+JHWVcv+zNCfFi+B7II+7+Fqt4DKmlj04tJXegj2XSJaNKk+0AHzrkBsqU5eneeZ+hEN8nuPtJVfTz4ex3mjEJJrv4VONDKlzKCCNbR8gJSl5LgeNiDOW4cacFzfXKJJPZ3V4loFgUPO0QH+okU6rQdDzO1XsUTP/xDY0VKvYvN8J0kiqmjiTQlc8ooapiIp+bwNI9k8w10eVtvMfCKFCoVizuhCM8urqVt6/E8sBYwlFM5N4dVFCbdnyY+ZwKRmAWlBm6BT+p0D9e3/oqhGYxbPZv48llkuhPohknD2hAFB98gXG4xGKlAVbw8sF5g4aSyKCGFdMoeUb7/coKUCzmpICydNxuLqaqbStf+y1z59gSxJ6upXFLO6y9W0HhlIXZ0LJ6UunffsYAmemCLTNomHLFQC0PYPVK+6DXl+TqSvQnMyUX4ms6i96uZczVKdnMlipuhKlZOFJtY8xqKp2RwRYrh2F6aN9zKAwet0kzx1KQxpNq7RyQxhjN07jqNq+cwj0k1EzNYFdOIv51jXe1vvLNnHn375uObJZjjbIoHIqilA0TGiO4pi4zvoKsCqpcWYojZ/ZIi7GQKx5WueA7rn5hF0XSL2+0+X706ni29F1mxcx7m4cfAUrA1G3soQ1JknDhpP1MXHsAfyI44S/VcF7WsElwN586A8HfZeHsVr22qoffjEiqUj7je2cZbG39mxXWF0p9mI6bArz9Hj3dSjtvcqd7BjOU/4N5wcDKigWgtDfSJ1g2hSuO8QgurfBxdr+wlfmYZT89tJRFpZ/5TS2g6083Kz4WEdKVgUQsfrN5D3yNduMu20zqokOsU9/baeNn8jVWVqEq61kEN6xhhi1BdFaWqwcXEBWYoJazY9A2d1w4RnTaZ0pK4uMfhodoKslqO9ktDLH/hJJ+9dIhsIkUuI3dZIuibrhsW9vew+IsGzm5pwUyEocihh2v0MZ5tHWIfJ44nRG72n0V9Dr5+bza7Dj/DspmS0HEZHBqUlog3PfHY3RGjhIoL/TWty9i9oFUYi1+jIQxf4YF3L9Dc0cPMRhPl0xDbPlnC6qsnObStn0kLwlw82Idz3pNLZaN6Blk7g+oquKNSZFJJvly6G0+u45Q3Y7SFm3BIUtgVo+TSZE6t8YmrlTSs3E3lhMdlksGFHSnS4hRH/O+l/RFQuR24oxNRpFDFBEQ6LK6nf6Gsbjw1oXnkXu5izNEwGxbWsHRaDUdaE6w4+iiz5qboT2fJ3EySvT0sjXJFIqldJAjYjsoQ6BxcPD+Yv4GfkQauP7WK9OVbTG2E1h/D7Fq7nVRG3BCKCg2hm87h23mvBl+NwK74MtGCBPdEHlhG5MjIlASKamLKbtYSkJHy5EU3iyZjxZPyfGGnyeiUNgiYfClkMTpq78HNMx7dGAEXERUZ1IGW+QiY/Pk9CEDuBzR6evT3D3QPG11SpETDAAAAAElFTkSuQmCC
""")
DRUID_ICON = base64.decode("""
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
""")
HUNTER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAcITNaAAAEY0lEQVQ4EY2VW2xURRzGfzOz994plEBRIlSCRZSbiASEIIjgkyASCYmJifHyYCIJ4KPRGDE8IAaiD5iIF4REEg1RBDVBJNQELCBXKQUKtLW0pbbb3e7u2XPG/zltoVWo/LPn7Fz+880333wzRwFWnn9FnBAO6xeUM21YkitNaTwHYlGNdTWOE+FSU4aWpOZU3nC6Rzq1B/LrDyWFAFgphbFSDEe5+EGCsp5OUjfiXL6cY2x1jA2fZTjX5FAZjRAu8ihNa4Y5hrNujtacS2FZMbtauggJeF5AA2AdvBWesqTOQMLv9EKEIiF2v5FhxwGoGhFhS4NLRmhZJcyti3BhXnkBxakeiqS9Mxrju2ROVuXJiiW8gLOluyZMx+ceeoYMiud5fUWesmiIH9J5cg2OMOlTTUD9UFZxINPDwlEjoK2dUC5HXCZ1ZELtJ4SlMn8qNG532LPTxWuSyVoKcDG83yGgknMT1B8gYXzWssJIynDwyYW0F8SpLi9kQbnhlcWTZCS8FRFFjq2xnDuhCMcqqHpcsfqFFN9nIS0kB+xJAOq/IsIqL31GGXJXWogvnU1XWNrPN3Gp8XovY1+3troEp5vjjB2XxDSmiEtSqn/pN+FuFZw+VfI2j2pvoay2lvEiUaFo4BLuBQ4Y5AyvPif2+dMhnCoOGDmBULfABpZkC4OqJznW85gwdjj5iEv1/aOIOm4vsG+14+1JTp6JUX/ZIx0KM0l227O+UkOFJiSWunD4Y+pu/MX2A9f5cOZMWidP7nWF7AKF+Qh1F7PMm1VCVwd0i4VUYKshgJXH/n2b+bktw8gxD0HNj3Ru+5ZOWUVgNxmPo8M8s6ycvfuv8veNQo7JYcLzrT5EWLFnV5aXl69DeeFAHN9B/m73+ViRFIbnjzdTWVFKp9Md2KtUcoT8bUMZTePJdxhdvS7ot3IFDAwd0kaOsktaPF9UZPipJkXIzVKfsjxQXDIwd1B5ZKnHPQ++OahtYEWHPBcrUmw67HK1zeFUq0NHNso4yWoYXSI6++f9v5HOyHIjMvAOoYkaKoT103OrqKnT6BhkkgY5UAwbNVLuhD7D9gEoMdLvB9fQlTZkM7c7Or2JOiEXzR8XDpEqKuZgvUM0bjjVoEiJNLZAZhkUmpmzhjN9/lbp7L0vBnUPqOjKQvGrePHFt9ey8cgeWrvzOMbQKke1fcL4m6m+ILFYjBO1nQIqZ/1/Qn/0yXsseWwORmuuna/jifWvcTSRwN5bQfPWr4Lhvs6+JXcc2UnWEUMNVue2U+ja2hN8uvtLVkxZycTJUzhaf5aSR+fQtda30a2N2/vLLp6fsRwtBO4m9LRpD3Pt6kW2fLOB2dPnM33eEvaVVlJ5vRmVzwXQi1YvZfETK8lmHVx3aG37J9Vf7P6aiIny62+HSFRNZPOmbTjLnuL0uxuDL4ExisikKpT4/07W6wcb9F+W0HbVs3Nsidzb982dascseiT48sh+WqWMXfXSYosK+6re9SME7D8YMLoVftbAQwAAAABJRU5ErkJggg==
""")
MAGE_ICON = base64.decode("""
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
""")
MONK_ICON = base64.decode("""
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
""")
PALADIN_ICON = base64.decode("""
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
""")
PRIEST_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAcITNaAAAE7klEQVQ4EZVVCWxUVRQ9f5mZtkwHZtoOnelQaEMFWewS0pYlLMFQKGDBCiqDsoWoLNGAmggiqVRlaVT2paSoKWsBFxQoSKFaqMgSLS1tLUxZptCNUmawywzzr+99aW2M0fH9/P/+v3n33PPuu/d8QRRF0ioK/Bl8lSQIEIjwd4+Ob89jINFfUL5eZLdPALyCiHYWgA+Bzdwuqhcgq9a/5sef/z15FIKzrBD3HjTB2MMArSzgxJlzWPBaBjw+jwrMwXkwvwZn5pUEhDGPa1XlsFl7wVl9G5IcjDXr94DggdQFSQgAs/3L4ICP2JIQownT651Y1liLh3erEWo1Yeq4VLQJJug0WjQ2/Y4qR5Wafw6nMubOXaN1jZN9tgivZqzAF/uzEXClDq88k45wSwhmhcShaWUuiivq0N1ogF4vdoKq/t3+ZEx5OVmcObEgBEGmYEmmi3lZVEbtNMb+LI1/eiilWIIoNTGWokNDKMlup7OVBTR99RrSSayymC/ffcctczRmxPXfqnD6eC6+/q4Itj69YJ+YgHXrtmPm6BlYmbsbrWzVSZaSquoaNMbFwswgNm48CF/KeIisVNrYrnWsDDuHhkWpKfuWzhzbQdRGFFlcQhNcrTTp/Uw6fDqfJipEQatzyLT2MxpS7qC0ZhdFm60Ur5cpvm8o3a74ge45LlCg2aayFQX1zEi8UnwI7jYfkkeMQP/CQkSeL0BNfByk4nwcuV4NjU+B3hAMLSvb8JJf8KvNgqjhSShVRHh0YRg2/yPYj16F0NyA2rpyPGx2wH3nCoRRLGdyUBDqnA04dHgTzGFWbFm/CZYICw7u3A26XIHKrV9Bt34Z+o0bCRsLcOD7EoiLVyBpwSRUrNuGxrUZeGfJbERY9UgZOxEvvrQQsiG4G4zGHmh01qHOpaAF97Fh7Q4I2kAsXToPGZKMRQvt8I1OQKhBRu6+UzCzmi1dbkeQLhMPHDex6o3n0NbShBemzcWUybMQ378PoGM5Zp1CAbJEOXu3UNzAGIqOH0T7d66hwzszaXNeDg3u25usYUZSvPVU8uNBanZephPFR+i95W/SE4OSqeLSMbpwfC+lJD5FH69cpOZaCGSg/Cy5iPSLjMK8snLsU3y4M3AAWgQNorVezC04CV1lJaYlDYTP246ZYyawc3GhVdDDETIcsfcLkZI+BZIk4e0PNkH2EdRy4yXCO+X6rVs47qyBkp6G3FvVuFlahFWRw/CN4kbt66nIdtUg0mpBd0MAzCYdfr7phuunA0he/DLOXSzF0MTB0DCGnGiHGEFg0ZKnpWN232jYPs1EaqgWsYMTcS8qEW6TCeEtrRjQvx/alUe4dLUGN+rdkEUN6zYfVm/YhT1bP8T2Xfse75+pHu8U3tLEEhIzZBBTmGtwBYRDd6wAtcMSEL1wPjRGC1qzN8Bx4wbTjX9WLm5nPaGyZRPAgbWiQBJE2pb1LuWf+pLmjE8knQx6sqCIYsZOJkmE2uId7erPLPCKeKveBQcrIa8pBK1JvRFj643zmhg49QY0fL4ZsuCD4udfRmXLH4EsCyOjIuiB20EztFrqmXeK0qaOI5O5J2k0uk5R8Ydl1zXCUZbcPUy4fd30UNJG4aHHi4Yln+DSnOehUTWl42/WycWvF3GOOQL2hjYUJyQjf+lWWMLCcZdphkQc8P+B8iLwgCkd8/wDLuQkzXeeproAAAAASUVORK5CYII=
""")
ROGUE_ICON = base64.decode("""
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
""")
WARLOCK_ICON = base64.decode("""
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
""")
EVOKER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAcITNaAAAEn0lEQVQ4Ea2Ue2xTVRzHP7ePbV3bdZ2lY3QvpBtbJ6sTxxDGS6MwESLEIDIBY4JINAZFefwnUYL+gSFqNJEoJD6AAAEhEQmD8XC4kcGAKdN0oxsbY8DGHrA+dtceT8sYj0VMDCc595x7T36f8z2/870/BRCyP/SmeejEAeD/A2sUNmdbEIURikQoQzFaufJhZPm/2tmseL5eNYcM93uc8I3goGoiP9zDCetINmp8GH0qtXdBhm5112JkmoAV8cnHLJr1K3k7E2lK0BGn15HhLGb6FEhrPE+2UaX+vqt6IFg3fTtKwVsczUomJUFLINnFCzVraLY7uNGfiFedzNv2ME81BjiJco+kfwEriMlWEix6RrlcLN7vRBujIdTdwpHUUnIDvZgdVkr+SGKNfRF2+4uEn4+g7sCHgI/HRM7vhvFuTBYT5+o9WK0xHPp+IzHtjXzX6UJYHfiu1NMZVOjV6TCmmUluKCbBNnZQ9X1ghalpi0kdmQVhE+kGwb4vlxPqaMGWmEJlxQ6GO0ehEUEC19uw6GOJ05kIx9m4kmbgZ+N1RHFBFK4b3EJO3pEXsG/MBDTXallSm4q2KIltbXpMGTnYxuSwxdOJaGtC03yM0+m/caCqk3neDmpMDooCPZySjPquPFKkBe9RvOuVbeTmOIjr9XLINRdjtoMZbgOxmWlYbMOoa/LT4vdRW7WBGo9KeVBDR1Ex42TOa4llPXZmdzdymTD3KPb5rhIIxGDrbeNMQxmWSYupb/UTb9ZTvm41hhHjebzqK1KKTnP5TDtTO+oZl7WULv1YktTTrKWLXvqGpmJB+VaOaOZRuPYIsUJDqVuw+miITBN0Z01i7oJiTvr+wqqqOGd8ikHtp8c9kbxQgGBdO0r7hagvIsUn4o9oEVLQsnNtCVkTdVTv2sPTj8GiFIHwhWj76GUCo4swXW9F6etiieYSPxUspK8nSP15D0mx3YSCvVTGeEmvqogqHszxgpJstMPsOJ/5jNf161i118Cs4Q3EHP4KQ/5MEjq8lLb+wp8HNuGsq+DkF6WsP/A+Qv6JN4P9+H1d5LalR6G3HxHF4vPlCcK+cppwzZ4ihAchmhNFz2GjePXJaaKweKnYvmKl8D7hFD9aLEKaUfzwSKLIlqNbmu817CJwbK9oeXNdlBXhRVNRuKICR/lMwqE+kpODTM0JsfuUjR1b4OAbveR2DyNsdrL16HHyraks7fTKChJLocxio0xhjjaeZ0MGXqKF/gG5mtHzv2HWDBc35h6mTJ2H54KG3dVGUuP9zJkf4LmmZZR74jlVd5N9MmxTdzslEuZBlQgtldIFm0M96Lk2CI2wNWazmbL9v6NoVWwj8zlrXkLA38+jbgfTxyYhcsux6TWUd7bJmzZRGfbjIiSxgm/xkym/auX7TIJRJwwIRne1uZFYvUCt6eZixR6SMvMwmlXqPDe4eAlWVJ+Vdg+TIY/ukIjIUd+VXfolyjg/oPNO+bmFVtIKFoqeYCfZo0ZzobmDZZe2UGbWsUHpZ2KDIlXcRkQCBt15K/oBTyV1wgdC9bUyvP1vzrVUR0O1Mj4kBd3SdGd8AGfI0j/+xrpK/EArbgAAAABJRU5ErkJggg==
""")
WOW_ICON = base64.decode("""
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
""")

RAID_COLORS = {
    "Raid Finder": "#1eff00",
    "Normal": "#0070dd",
    "Heroic": "#a335ee",
    "Mythic": "#ff8000",
}

DEFAULT_CHARACTER = "chinpokodin"
DEFAULT_REALM = "firetree"
DEFAULT_REGION = "us"
DEFAULT_AUTH_TTL = 86399

CURRENT_EXPANSION = "The War Within"
CURRENT_INSTANCE = "Manaforge Omega"

def main(config):
    client_id = secret.decrypt(
        "AV6+xWcEK3ttMwoBOdFBvpJ6mhRkE1fvDYW+JYmxMY1sTmyaTz1RuNYFkZN9IsfvyolFeknXQLmYkZOuSfCtLII7XHU7tSmT8pVrmS9Am025jZ4QUs25fSLknwMqwAecue4iBMUubsI4CbYrNVDJFrSABxXJljtSueQxsM+/QMtNO3pumZg=",
    ) or config.get(
        "client_id",
    )
    client_secret = secret.decrypt(
        "AV6+xWcEghHB4IYtF4KGd4dBFfKi4eiY9kyAQp9NHc/Lpe+IF6YkwIOyT/09XYEmZJZnUFmcgbIeot1x6JZgzIp9gEwvfHboAIN3L0r7iTrjQTylskTkGB2oQ/0Unkmii//7khorLAJ6CW3UxN6BnRuK9prp6gfHynAFwOykcPMArz5TMQ8=",
    ) or config.get(
        "client_secret",
    )
    character_name = config.get("character", DEFAULT_CHARACTER).lower()
    realm_name = config.get("realm", DEFAULT_REALM).replace(" ", "-").lower()
    region = config.get("region", DEFAULT_REGION)

    blizzard_auth_url = "https://oauth.battle.net/token?grant_type=client_credentials"
    blizzard_profile_url = "https://%s.api.blizzard.com/profile/wow/character/%s/%s?namespace=profile-%s&locale=en_US" % (region, realm_name, character_name, region)
    blizzard_mythic_url = "https://%s.api.blizzard.com/profile/wow/character/%s/%s/mythic-keystone-profile?namespace=profile-%s&locale=en_US" % (region, realm_name, character_name, region)
    blizzard_raid_url = "https://%s.api.blizzard.com/profile/wow/character/%s/%s/encounters/raids?namespace=profile-%s&locale=en_US" % (region, realm_name, character_name, region)

    access_token = get_auth_token(blizzard_auth_url, client_id, client_secret)

    if access_token == None:
        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.WrappedText(
                        content = "Auth failure!",
                        align = "center",
                    ),
                ],
            ),
        )

    player_profile = fetch_data(blizzard_profile_url, access_token)
    player_mythic = fetch_data(blizzard_mythic_url, access_token)
    player_raids = fetch_data(blizzard_raid_url, access_token)

    if player_profile == None:
        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.WrappedText(
                        content = "%s - %s (%s) not found." % (character_name, realm_name, region),
                        align = "center",
                    ),
                ],
            ),
        )

    faction_color = "#f00"
    if player_profile["faction"]["name"] == "Alliance":
        faction_color = "#00f"

    return render.Root(
        delay = 3750,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(
                        content = player_profile["name"],
                        color = determine_class_color(player_profile),
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 1),
                            child = render.Image(src = determine_icon(player_profile)),
                        ),
                        render.Box(
                            height = 24,
                            width = 40,
                            padding = 1,
                            child = render.Animation(
                                children = [
                                    render.Column(
                                        cross_align = "center",
                                        main_align = "space_evenly",
                                        expanded = True,
                                        children = [
                                            render.Text(
                                                content = "lvl %d" % player_profile["level"],
                                                font = "tom-thumb",
                                            ),
                                            render.Text(
                                                content = "%s" % player_profile["faction"]["name"],
                                                font = "tom-thumb",
                                                color = faction_color,
                                            ),
                                            render.Text(
                                                content = "ilvl %d" % player_profile["equipped_item_level"],
                                                font = "tom-thumb",
                                            ),
                                        ],
                                    ),
                                    render.Column(
                                        cross_align = "center",
                                        main_align = "space_evenly",
                                        expanded = True,
                                        children = [
                                            get_mythic_plus_io(player_mythic),
                                            get_raid_progress(player_raids),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "North America",
            value = "us",
        ),
        schema.Option(
            display = "Europe",
            value = "eu",
        ),
        schema.Option(
            display = "Korea",
            value = "kr",
        ),
        schema.Option(
            display = "Taiwan",
            value = "tw",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "character",
                name = "Character Name",
                desc = "The name of the WoW character to display",
                icon = "user",
            ),
            schema.Text(
                id = "realm",
                name = "Realm Name",
                desc = "The name of the realm where the character resides",
                icon = "earthAmericas",
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Region the realm is located in.",
                icon = "globe",
                default = options[0].value,
                options = options,
            ),
        ],
    )

def get_auth_token(url, id, secret):
    token = cache.get("access_token")
    if token != None:
        print("Valid Auth token found!")
    else:
        print("Auth Token is not valid. Calling API to fetch new token...")
        headers = {
            "Authorization": "Basic %s" % base64.encode("%s:%s" % (id, secret)),
        }
        response = http.post(url, headers = headers)
        if response.status_code != 200:
            print("Blizzard request failed with status %d" % response.status_code)
            return None

        # cache call is needed because ttl is dynamic based on the response body values
        cache.set(
            "access_token",
            json.decode(response.body())["access_token"],
            ttl_seconds = json.decode(response.body())["expires_in"],
        )
        token = json.decode(response.body())["access_token"]

    return token

def fetch_data(url, token):
    headers = {
        "Authorization": "Bearer %s" % token,
    }
    response = http.get(url, headers = headers, ttl_seconds = 300)
    if response.status_code != 200:
        print("Blizzard request failed with status %d" % response.status_code)
        return None

    return response.json()

def determine_icon(profile):
    player_class = profile["character_class"]["name"]

    if player_class == "Warrior":
        return WARRIOR_ICON
    elif player_class == "Shaman":
        return SHAMAN_ICON
    elif player_class == "Death Knight":
        return DK_ICON
    elif player_class == "Demon Hunter":
        return DH_ICON
    elif player_class == "Druid":
        return DRUID_ICON
    elif player_class == "Hunter":
        return HUNTER_ICON
    elif player_class == "Evoker":
        return EVOKER_ICON
    elif player_class == "Mage":
        return MAGE_ICON
    elif player_class == "Monk":
        return MONK_ICON
    elif player_class == "Paladin":
        return PALADIN_ICON
    elif player_class == "Priest":
        return PRIEST_ICON
    elif player_class == "Warlock":
        return WARLOCK_ICON
    elif player_class == "Rogue":
        return ROGUE_ICON

    return WOW_ICON

def determine_class_color(profile):
    player_class = profile["character_class"]["name"]

    if player_class == "Death Knight":
        return "#C41E3A"
    elif player_class == "Demon Hunter":
        return "#A330C9"
    elif player_class == "Druid":
        return "#FF7C0A"
    elif player_class == "Evoker":
        return "#33937F"
    elif player_class == "Hunter":
        return "#AAD372"
    elif player_class == "Mage":
        return "#3FC7EB"
    elif player_class == "Monk":
        return "#00FF98"
    elif player_class == "Paladin":
        return "#F48CBA"
    elif player_class == "Priest":
        return "#FFFFFF"
    elif player_class == "Rogue":
        return "#FFF468"
    elif player_class == "Shaman":
        return "#0070DD"
    elif player_class == "Warlock":
        return "#8788EE"
    elif player_class == "Warrior":
        return "#C69B6D"

    return "#FFF"

def rgb_to_hex(r, g, b):
    r = "%x" % r
    g = "%x" % g
    b = "%x" % b
    return "#%s%s%s" % (pad_hex(r), pad_hex(g), pad_hex(b))

def pad_hex(i):
    if len(i) == 1:
        return "0%s" % i
    else:
        return i

def get_raid_progress(progress):
    status = "N/A raid"
    raid_level = "none"

    if "expansions" in progress:
        for expansion in progress["expansions"]:
            if expansion["expansion"]["name"] == CURRENT_EXPANSION:
                for instance in expansion["instances"]:
                    if instance["instance"]["name"] == CURRENT_INSTANCE:
                        for mode in instance["modes"]:
                            status = "%d/%d %s" % (
                                mode["progress"]["completed_count"],
                                mode["progress"]["total_count"],
                                mode["difficulty"]["type"][:1],
                            )
                            raid_level = mode["difficulty"]["name"]

    if raid_level != "none":
        return render.Text(
            content = status,
            font = "tom-thumb",
            color = RAID_COLORS[raid_level],
        )
    else:
        return render.Text(
            content = status,
            font = "tom-thumb",
        )

def get_mythic_plus_io(mythic):
    if "current_mythic_rating" in mythic:
        return render.Text(
            content = "%d io" % mythic["current_mythic_rating"]["rating"],
            font = "tom-thumb",
            color = rgb_to_hex(
                mythic["current_mythic_rating"]["color"]["r"],
                mythic["current_mythic_rating"]["color"]["g"],
                mythic["current_mythic_rating"]["color"]["b"],
            ),
        )
    else:
        return render.Text(
            content = "N/A io",
            font = "tom-thumb",
        )
