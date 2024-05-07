"""
Applet: ISS
Summary: Show next ISS pass
Description: Displays the time, starting direction and magnitude of the next International Space Station visible pass.
Author: Diogo Ribeiro Machado @ diogodh
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

ISS_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAALCAYAAAB24g05AAAACXBIWXMAAAsTAAALEwEAmpwYAAAGlmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4wLWMwMDEgNzkuMTRlY2I0MiwgMjAyMi8xMi8wMi0xOToxMjo0NCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIiB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI0LjIgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyNC0wNC0zMFQxNjozMjo1MSswMTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyNC0wNS0wMlQyMjo0Mzo1NCswMTowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjQtMDUtMDJUMjI6NDM6NTQrMDE6MDAiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjI2YjI0NTk3LTc3ZWQtYjY0NS04Mjk2LWY0YjZiNDc5NmU5ZiIgeG1wTU06RG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjQyNzQyYjUwLTExZWQtNWQ0Mi1iNzlkLWZjZjU1YmY1ZTYzNCIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjAxZmE5NzY1LTZmYmQtMTU0NS1iZmU4LTdlMTY5YTRkMzgwZSIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyI+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MDFmYTk3NjUtNmZiZC0xNTQ1LWJmZTgtN2UxNjlhNGQzODBlIiBzdEV2dDp3aGVuPSIyMDI0LTA0LTMwVDE2OjMyOjUxKzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjQuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmFmN2ZhN2Y0LTFkYWMtODA0NS1hYmQwLWU3MDQyZDRiMWE2YiIgc3RFdnQ6d2hlbj0iMjAyNC0wNC0zMFQxNjozMzoxOSswMTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDI0LjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoyNmIyNDU5Ny03N2VkLWI2NDUtODI5Ni1mNGI2YjQ3OTZlOWYiIHN0RXZ0OndoZW49IjIwMjQtMDUtMDJUMjI6NDM6NTQrMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyNC4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4nxZmYAAAChklEQVQozwXBTUiTYQAH8P/zvM/7Nec2m9v8ojkMZJnpyJJElJSECirq2rmgDh2jQx07RMeKrnoIuymR0UWwQ0kLQ1K0VVL5ve11c3Pv1/M+7/r9SCGfBwuE8Hth9tVB7vMdzwNaMhMPUkNjT82SAUVRIFEKPXIMuYUPD7ey75+omoSG5MDLtsGL95gQAr5lgyqKHmxLwLUECKWq4By+EPA8D0zTUPfroIypgVgUWoMCWVd1Wgeo47qgigrfteBVinArRQjXgayoAKU4Mk04jgOZEQjXBq8W4ZT2AMHreiQCJswqhC8Qinc+q/zd7JdVZacj3fuCyhTuYRlWsQApFkMwHkfLifRz4+eP86FQQISaWmc2sosjZHLqzVzZOOhLd3asCiJ3QXhWQ7jhXb1s7Prx1pteIJiRjMLXetmYYdF4O685V3YK5bzeEuuUCptJVtrPD+uZgUZlcKDNXFmGrKpYXsz21NZWceraVei93UAyNfrl8aPRxv4Mzo4M4dO/pXSnFsZwklTJ/PT0R7k7namHY2vlbLaNycwKNOrzkmPuVg3jOlcDfcF4/Jt8eDDrN0bauemMb+6Xi1oimtKM7WaSW12F5HngleKZ7ZWlSULZdu/lG7eaOo4XNtbX6FHR0BRFtrvODfqVfxuJ73Mzr5tCuhNKnZwq2qhRLRxGONWNWmX/vizv93Drz8Ter/XbFEA42uwHEgkz2NLq26aLrfWVu/C2xiqHuUuWVRo/fWH0LVMYg+fYIIpK5FAUvsThU4ojxwOTJARUFZxzmEdV1KkEJRyFJBP4RCLC5GCUEDBVhbC5Xd3Jw+NAsMN1HNeFY9sAIQAAUArBPaeWPwClPrSIa0Gi+A8uuyvbv22EoAAAAABJRU5ErkJggg==
""")

MAG_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAKCAYAAABrGwT5AAAACXBIWXMAAAsTAAALEwEAmpwYAAAGlmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4wLWMwMDEgNzkuMTRlY2I0MiwgMjAyMi8xMi8wMi0xOToxMjo0NCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIiB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI0LjIgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyNC0wNS0wMlQyMjoyODoxNyswMTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyNC0wNS0wMlQyMjozMDozNSswMTowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjQtMDUtMDJUMjI6MzA6MzUrMDE6MDAiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOmEwYWQyMzM3LTE1MmYtMjA0Ny1iMGU4LTQ3MWYyZTIyMGU0ZSIgeG1wTU06RG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjMyNWZkMzY3LTMzNTktNWE0YS1iZjk1LTI5NTA5OWVhYTNkYiIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmUzYjM1ZWM3LTZjMjQtZjE0Zi1hOWMxLWY3MDZkOTRkM2M2NCIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyI+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZTNiMzVlYzctNmMyNC1mMTRmLWE5YzEtZjcwNmQ5NGQzYzY0IiBzdEV2dDp3aGVuPSIyMDI0LTA1LTAyVDIyOjI4OjE3KzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjQuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjhkODQwNWQ3LTRlMmMtZWE0YS1hMzBhLWNhYzUyM2QyYTJlZSIgc3RFdnQ6d2hlbj0iMjAyNC0wNS0wMlQyMjozMDozNSswMTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDI0LjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDphMGFkMjMzNy0xNTJmLTIwNDctYjBlOC00NzFmMmUyMjBlNGUiIHN0RXZ0OndoZW49IjIwMjQtMDUtMDJUMjI6MzA6MzUrMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyNC4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz63pun/AAAB1klEQVQokV2SQUhTARjH/3sbTAWDZBhIQVm7iBcrGQXKZPPpDqvQQ6eBJWLkQaTAhDoEHTxYQnmQ1SDwEImIlbGGOKxNHE2DytKpbYavyZzLuWerfL39u4xR7wf/y8fv+1++DyTxTwyvY+r9RsedLZI1+ZnN3nwzuZhgv8aFjiTyiGL7lCe3MX+Ygh57dY7oMXN5KLoct5bO+Sp0ag7F1ba1F/csLgAhAIXl06J4PSwIO1B4AnvlVVCNRlhaziD8dAaCShTtbqJImQdZAp/vQRWAJZCsONv9JjsalOlPkB3Pk2xquswuv0ySbHav0y72sWcqTb9EPvamaWl7+Z1kmf6gs3fk276+ejG7j7qjB9B1qgTvSy34dHcQQ9MZGMIBmK90IK3koI9so7P1ECprzMWDCzsm9Ieyv/wSOfuVBeJ/SOeNt9MxmVfbxhPBixPbDMT5H7bhWAKND9dz1BDZJZ9ElV6S8Hz8ObCS0RrkuREpI6Sl5Co09E1uotZkWAOA42XG1UdhWatgKykvI6XyQv15d6HRE/jB2tvvIiR1+XsaT14LSt4PvwtOvdNNhbSDJDZkdlovTX5pcI2lWgY+PyNp0jzEEcethVcNrtGUtd27lFLpIom/OpFuxE5sGJkAAAAASUVORK5CYII=
""")

EYE_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAICAYAAADJEc7MAAAACXBIWXMAAA0SAAANEgG1gDd0AAAGlmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4wLWMwMDEgNzkuMTRlY2I0MiwgMjAyMi8xMi8wMi0xOToxMjo0NCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI0LjIgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyNC0wNC0zMFQxNjozNzoxMCswMTowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjQtMDUtMDJUMjI6MjM6NTcrMDE6MDAiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjQtMDUtMDJUMjI6MjM6NTcrMDE6MDAiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjhkYTFiODcyLWM0OTktNjk0MS1hZWQzLThhNDRhN2NmZWNiMSIgeG1wTU06RG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOmQxNGMxYzYyLThiN2UtMmE0OS1hMmRlLWNmYjE0ZjQyZjZmZCIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjkxNjJiMTkzLTQzODMtZWM0Ny1iYzhiLTNjNTQ1NTNkNGIyMCI+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6OTE2MmIxOTMtNDM4My1lYzQ3LWJjOGItM2M1NDU1M2Q0YjIwIiBzdEV2dDp3aGVuPSIyMDI0LTA0LTMwVDE2OjM3OjEwKzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjQuMiAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjc3OTMwZDkxLWU0NzgtNWE0My1hMzcyLWViZWI2ZTA3MDM2YiIgc3RFdnQ6d2hlbj0iMjAyNC0wNC0zMFQxNjozNzo1MiswMTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDI0LjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo4ZGExYjg3Mi1jNDk5LTY5NDEtYWVkMy04YTQ0YTdjZmVjYjEiIHN0RXZ0OndoZW49IjIwMjQtMDUtMDJUMjI6MjM6NTcrMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyNC4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5+4e5wAAAB0UlEQVQY0wXBX0gTcQAH8O/vd7u7tenuNndpc45iNouU1Ia51CLKJFxGy4JeEgJBgiAMeuu9hyAiMhJ86iV6KEFlUESCLWIGmYxa/wbprDna1m472915d30+JBqbQFVRQSyDbfexfXldOKP7uyK64G/iORtQ+LlJ1z68a+LKcz9KSOT/VFSpQQCzu/Ug5Mo/77mTnbdFKfDg856LEbbneEutrLntgsfNdA/4S3ywt6t+a6w9KElLy1+TDgenML7AAWk0NvTsxtXzo8/XvUi59mJfOY2YuYjUk/tQWS/ktjDqKI9bY73hLZ32p9OZeTo0eHRh8trlgWQyjXhGhkQ0GC8fQqcmsIOF9WoKO00VL9aqSCQ+4ebklchI9ESc2hiGAoBpWTANA06BQ+6vint3p0E0Bc4GH0AJLAOwYAIAQEEY1aifzeWLRy5dOBb4vqHjC7sLnpYQ+N8Z2OwiyPB1/LI3op8rYWI4iDtTT9/PL7yOMq1t3crS25U5qIrLIW+Es1UR9v0h8B2nYHUMwvI1w/yWwaHKIlY/pmYePY6Piy5njpweGUe+KEPyuPiQx+zb3Haf3W7uPEwkvxcgQCFbsGVXlrXS+mzRcLzRampNFOrwH2wZs6XH+aY5AAAAAElFTkSuQmCC
""")

DEFAULT_LOCATION = """
{
    "lat": 38.736946,
    "lng": -9.142685,
    "locality": "Lisbon, PT",
    "timezone": "GMT"
} """

DEFAULT_24_HOUR = True
MIN_ELEVATION = 10  # minimum elevation is 10º
MIN_MAGNITUDE = 1  # minimum magnitude is 1
ALTITUDE = 0  # location altitude
SAT_ID = "25544"  # ISS code
NUM_DAYS = "1"  # passes for the next 2 days
MIN_DURATION = "10"  # minimum time of visible pass
ENCRYPTED_API_KEY = "AV6+xWcEsXZATiO53Ve1JpH0NM3XZ4OGusmQXpCHReQk042dGY7VW2FiiNpxaSlIqAN8lxmEVlwbJVPWbObIdrjXdgUZypNzgnsUQzZy53qQdypQU2Dz9XdpBgVnqooGBjaG3vSX1PpGiXKiEjtspDpY2X9HYe3XQsyUpVDPdg=="

def main(config):
    api_key = secret.decrypt(ENCRYPTED_API_KEY)  # or config.get("dev_api_key")
    ttl_time = 5200
    display24hour = config.bool("24_hour", DEFAULT_24_HOUR)
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(location["lat"])
    lng = float(location["lng"])
    timezone = location["timezone"]

    url = "https://api.n2yo.com/rest/v1/satellite/visualpasses/%s/%s/%s/%s/%s/%s/&apiKey=%s" % (SAT_ID, lat, lng, ALTITUDE, NUM_DAYS, MIN_DURATION, api_key)

    data = get_data(url, ttl_time)

    if "error" in data:
        return render.Root(
            child = render.WrappedText("API error", align = "center", font = "tb-8", color = "#FF0000"),
        )

    else:
        filtered_passes = [pass_data for pass_data in data["passes"] if pass_data["maxEl"] > MIN_ELEVATION and pass_data["mag"] < MIN_MAGNITUDE]

    if filtered_passes:  # Check if there are any filtered passes
        # Take information only from the first pass
        first_pass_data = filtered_passes[0]
        utc_time_seconds = int(first_pass_data["startUTC"])  # Convert to integer
        ttl_time = utc_time_seconds - time.now().unix + 2
        start_compass = first_pass_data["startAzCompass"]
        magnitude = first_pass_data["mag"]

        # Convert UTC time to human-readable format
        utc_time = time.from_timestamp(utc_time_seconds)
        final_time = utc_time.in_location(timezone)

        if display24hour:
            time_human_readable = final_time.format("15:04")  # Adjust format string
        else:
            time_human_readable = final_time.format("3:04 PM")  # Adjust format string

        col1 = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Image(src = ISS_IMG),
                render.Image(src = MAG_IMG),
                render.Image(src = EYE_IMG),
            ],
        )

        col2 = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",  # Center align text vertically
            children = [
                render.Text("%s" % time_human_readable, color = "#FF0000", font = "tb-8"),
                render.Text("%s" % start_compass, color = "#FFFFFF", font = "tb-8"),
                render.Text("%s" % magnitude, color = "#FFFF00", font = "tb-8"),
            ],
        )

        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    col1,
                    render.Box(child = col2, width = 46),
                ],
            ),
        )
    else:
        # No filtered passes found
        ttl_time = 86400
        return render.Root(
            child = render.WrappedText("No passes found", align = "center", font = "tb-8", color = "#FF0000"),
        )

def get_data(url, ttl_time):
    res = http.get(url, ttl_seconds = ttl_time)  # cache for 1 hour
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the ISS passes.",
                icon = "locationDot",
            ),

            #schema.Text(
            #    id = "apiKey",
            #    name = "N2YO API Key",
            #    desc = "N2YO API Key",
            #    icon = "code",
            #),
            schema.Toggle(
                id = "24_hour",
                name = "24 hour clock",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
            ),
        ],
    )
