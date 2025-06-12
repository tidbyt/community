load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COLOURS = {
    "line_positive": "#FFA500",
    "line_negative": "#344FEB",
    "fill_positive": "#FFCC66",
    "fill_negative": "#87CEFA",
}

ICONS = {
    "thermometer": base64.decode("""
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pg0KPCEtLSBVcGxvYWRlZCB0bzogU1ZHIFJlcG8sIHd3dy5zdmdyZXBvLmNvbSwgR2VuZXJhdG9yOiBTVkcgUmVwbyBNaXhlciBUb29scyAtLT4NCjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgDQoJIHZpZXdCb3g9IjAgMCA1MTIgNTEyIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwb2x5Z29uIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiBwb2ludHM9IjQxMS44MjYsMjc4LjI2IDM3OC40MSwyNzguMjYgMzc4LjQxLDI0NC44NyAzNDUuMDE5LDI0NC44NyAzNDUuMDE5LDMzLjM5MSAzMTEuNjI4LDMzLjM5MSANCgkzMTEuNjI4LDAgMjAwLjMyMywwIDIwMC4zMjMsMzMuMzkxIDE2Ni45MzIsMzMuMzkxIDE2Ni45MzIsMjQ0Ljg3IDEzMy41NDEsMjQ0Ljg3IDEzMy41NDEsMjc4LjI2IDEwMC4xNzQsMjc4LjI2IDEwMC4xNzQsNDQ1LjIxNiANCgkxMzMuNTQxLDQ0NS4yMTYgMTMzLjU0MSw0NDUuMjE3IDEzMy41NDEsNDc4LjYwOSAxNjYuOTMyLDQ3OC42MDkgMTY2LjkzMiw1MTIgMzQ1LjAxOSw1MTIgMzQ1LjAxOSw0NzguNjA5IDM3OC40MSw0NzguNjA5IA0KCTM3OC40MSw0NDUuMjE3IDQxMS44MDIsNDQ1LjIxNyA0MTEuODAyLDQ0NS4yMTYgNDExLjgyNiw0NDUuMjE2ICIvPg0KPHJlY3QgeD0iMTMzLjU2NSIgeT0iMjQ0Ljg3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSIvPg0KPHJlY3QgeD0iMTMzLjU2NSIgeT0iNDQ1LjIxNyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiLz4NCjxyZWN0IHg9IjE2Ni45NTciIHk9IjQ3OC42MDkiIHdpZHRoPSIxNzguMDg3IiBoZWlnaHQ9IjMzLjM5MSIvPg0KPHJlY3QgeD0iMTAwLjE3NCIgeT0iMjc4LjI2MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIxNjYuOTU3Ii8+DQo8cmVjdCB4PSIzNDUuMDQzIiB5PSIyNDQuODciIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIi8+DQo8cmVjdCB4PSIzNDUuMDQzIiB5PSI0NDUuMjE3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSIvPg0KPHJlY3QgeD0iMzc4LjQzNSIgeT0iMjc4LjI2MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIxNjYuOTU3Ii8+DQo8cmVjdCB4PSIyMDAuMzQ4IiB3aWR0aD0iMTExLjMwNCIgaGVpZ2h0PSIzMy4zOTEiLz4NCjxyZWN0IHg9IjE2Ni45NTciIHk9IjMzLjM5MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIyMTEuNDc4Ii8+DQo8cmVjdCB4PSIzMTEuNjUyIiB5PSIzMy4zOTEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMjExLjQ3OCIvPg0KPHBvbHlnb24gc3R5bGU9ImZpbGw6I0ZGMEMzODsiIHBvaW50cz0iMzExLjY1MiwzMTEuNjUyIDMxMS42NTIsMjc4LjI2MSAyNzguMjYxLDI3OC4yNjEgMjc4LjI2MSw2Ni43ODMgMjMzLjczOSw2Ni43ODMgDQoJMjMzLjczOSwyNzguMjYxIDIwMC4zNDgsMjc4LjI2MSAyMDAuMzQ4LDMxMS42NTIgMTY2Ljk1NywzMTEuNjUyIDE2Ni45NTcsNDExLjgyNiAyMDAuMzQ4LDQxMS44MjYgMjAwLjM0OCw0MTEuODI2IA0KCTIwMC4zNDgsNDQ1LjIxNyAzMTEuNjUyLDQ0NS4yMTcgMzExLjY1Miw0MTEuODI2IDMxMS42NTIsNDExLjgyNiAzNDUuMDQzLDQxMS44MjYgMzQ1LjA0MywzMTEuNjUyICIvPg0KPC9zdmc+
"""),
    "wind": base64.decode("""
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pg0KPCEtLSBVcGxvYWRlZCB0bzogU1ZHIFJlcG8sIHd3dy5zdmdyZXBvLmNvbSwgR2VuZXJhdG9yOiBTVkcgUmVwbyBNaXhlciBUb29scyAtLT4NCjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgDQoJIHZpZXdCb3g9IjAgMCA1MTIgNTEyIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwYXRoIGQ9Ik0wLDB2MjU2aDQxMS44MjZ2LTMzLjM5MWgzMy4zOTFWMjU2aC0zMy4zOTF2MzMuMzkxSDB2MzMuMzkxaDQ0NS4yMTd2MzMuMzkxSDB2NjYuNzgzaDI4OS4zOTENCgl2MzMuMzkxSDBWNTEyaDUxMlYwSDB6IE00MTEuODI2LDEwMC4xNzRWNjYuNzgzSDMxMS42NTJ2MzMuMzkxaC0zMy4zOTF2ODkuMDQzaDY2Ljc4M3YzMy4zOTFoLTY2Ljc4M3YtMzMuMzkxSDI0NC44N3YtODkuMDQzDQoJaDMzLjM5MVY2Ni43ODNoMzMuMzkxVjMzLjM5MWgxMDAuMTc0djMzLjM5MWgzMy4zOTF2MzMuMzkxSDQxMS44MjZ6IE0zNzguNDM1LDQ0NS4yMTdoLTMzLjM5MXYtNTUuNjUyaDMzLjM5MVY0NDUuMjE3eg0KCSBNNDc4LjYwOSw0NDUuMjE3aC0zMy4zOTF2MzMuMzkxaC02Ni43ODN2LTMzLjM5MWg2Ni43ODN2LTg5LjA0M2gzMy4zOTFWNDQ1LjIxN3ogTTQ3OC42MDksMjIyLjYwOWgtMzMuMzkxVjEwMC4xNzRoMzMuMzkxVjIyMi42MDkNCgl6Ii8+DQo8Zz4NCgk8cmVjdCB4PSIzNDUuMDQzIiB5PSIzODkuNTY1IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI1NS42NTIiLz4NCgk8cmVjdCB4PSIzNzguNDM1IiB5PSI0NDUuMjE3IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjY2Ljc4MyIgaGVpZ2h0PSIzMy4zOTEiLz4NCgk8cmVjdCB4PSI0NDUuMjE3IiB5PSIzNTYuMTc0IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI4OS4wNDMiLz4NCgk8cmVjdCB5PSIzMjIuNzgzIiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjQ0NS4yMTciIGhlaWdodD0iMzMuMzkxIi8+DQoJPHJlY3QgeT0iNDIyLjk1NyIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIzMjIuNzgzIiBoZWlnaHQ9IjMzLjM5MSIvPg0KCTxyZWN0IHg9IjQxMS44MjYiIHk9IjY2Ljc4MyIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIi8+DQoJPHJlY3QgeD0iMjc4LjI2MSIgeT0iNjYuNzgzIiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiLz4NCgk8cmVjdCB4PSIyNzguMjYxIiB5PSIxODkuMjE3IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjY2Ljc4MyIgaGVpZ2h0PSIzMy4zOTEiLz4NCgk8cmVjdCB4PSI0MTEuODI2IiB5PSIyMjIuNjA5IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiLz4NCgk8cmVjdCB4PSIyNDQuODciIHk9IjEwMC4xNzQiIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9Ijg5LjA0MyIvPg0KCTxyZWN0IHg9IjMxMS42NTIiIHk9IjMzLjM5MSIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIxMDAuMTc0IiBoZWlnaHQ9IjMzLjM5MSIvPg0KCTxyZWN0IHg9IjQ0NS4yMTciIHk9IjEwMC4xNzQiIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjEyMi40MzUiLz4NCgk8cmVjdCB5PSIyNTYiIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiB3aWR0aD0iNDExLjgyNiIgaGVpZ2h0PSIzMy4zOTEiLz4NCjwvZz4NCjwvc3ZnPg0K
"""),
    "ha": base64.decode("""
PHN2ZyB3aWR0aD0iMjQwIiBoZWlnaHQ9IjI0MCIgdmlld0JveD0iMCAwIDI0MCAyNDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGQ9Ik0yNDAgMjI0Ljc2MkMyNDAgMjMzLjAxMiAyMzMuMjUgMjM5Ljc2MiAyMjUgMjM5Ljc2MkgxNUM2Ljc1IDIzOS43NjIgMCAyMzMuMDEyIDAgMjI0Ljc2MlYxMzQuNzYyQzAgMTI2LjUxMiA0Ljc3IDExNC45OTMgMTAuNjEgMTA5LjE1M0wxMDkuMzkgMTAuMzcyNUMxMTUuMjIgNC41NDI1IDEyNC43NyA0LjU0MjUgMTMwLjYgMTAuMzcyNUwyMjkuMzkgMTA5LjE2MkMyMzUuMjIgMTE0Ljk5MiAyNDAgMTI2LjUyMiAyNDAgMTM0Ljc3MlYyMjQuNzcyVjIyNC43NjJaIiBmaWxsPSIjRjJGNEY5Ii8+CjxwYXRoIGQ9Ik0yMjkuMzkgMTA5LjE1M0wxMzAuNjEgMTAuMzcyNUMxMjQuNzggNC41NDI1IDExNS4yMyA0LjU0MjUgMTA5LjQgMTAuMzcyNUwxMC42MSAxMDkuMTUzQzQuNzggMTE0Ljk4MyAwIDEyNi41MTIgMCAxMzQuNzYyVjIyNC43NjJDMCAyMzMuMDEyIDYuNzUgMjM5Ljc2MiAxNSAyMzkuNzYySDEwNy4yN0w2Ni42NCAxOTkuMTMyQzY0LjU1IDE5OS44NTIgNjIuMzIgMjAwLjI2MiA2MCAyMDAuMjYyQzQ4LjcgMjAwLjI2MiAzOS41IDE5MS4wNjIgMzkuNSAxNzkuNzYyQzM5LjUgMTY4LjQ2MiA0OC43IDE1OS4yNjIgNjAgMTU5LjI2MkM3MS4zIDE1OS4yNjIgODAuNSAxNjguNDYyIDgwLjUgMTc5Ljc2MkM4MC41IDE4Mi4wOTIgODAuMDkgMTg0LjMyMiA3OS4zNyAxODYuNDEyTDExMSAyMTguMDQyVjEwMi4xNjJDMTA0LjIgOTguODIyNSA5OS41IDkxLjg0MjUgOTkuNSA4My43NzI1Qzk5LjUgNzIuNDcyNSAxMDguNyA2My4yNzI1IDEyMCA2My4yNzI1QzEzMS4zIDYzLjI3MjUgMTQwLjUgNzIuNDcyNSAxNDAuNSA4My43NzI1QzE0MC41IDkxLjg0MjUgMTM1LjggOTguODIyNSAxMjkgMTAyLjE2MlYxODMuNDMyTDE2MC40NiAxNTEuOTcyQzE1OS44NCAxNTAuMDEyIDE1OS41IDE0Ny45MzIgMTU5LjUgMTQ1Ljc3MkMxNTkuNSAxMzQuNDcyIDE2OC43IDEyNS4yNzIgMTgwIDEyNS4yNzJDMTkxLjMgMTI1LjI3MiAyMDAuNSAxMzQuNDcyIDIwMC41IDE0NS43NzJDMjAwLjUgMTU3LjA3MiAxOTEuMyAxNjYuMjcyIDE4MCAxNjYuMjcyQzE3Ny41IDE2Ni4yNzIgMTc1LjEyIDE2NS44MDIgMTcyLjkxIDE2NC45ODJMMTI5IDIwOC44OTJWMjM5Ljc3MkgyMjVDMjMzLjI1IDIzOS43NzIgMjQwIDIzMy4wMjIgMjQwIDIyNC43NzJWMTM0Ljc3MkMyNDAgMTI2LjUyMiAyMzUuMjMgMTE1LjAwMiAyMjkuMzkgMTA5LjE2MlYxMDkuMTUzWiIgZmlsbD0iIzE4QkNGMiIvPgo8L3N2Zz4K
"""),
    "drop": base64.decode("""
PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyLjAwNCA1MTIuMDA0IiB4bWw6c3BhY2U9InByZXNlcnZlIiBmaWxsPSIjMDAwMDAwIj48ZyBpZD0iU1ZHUmVwb19iZ0NhcnJpZXIiIHN0cm9rZS13aWR0aD0iMCI+PC9nPjxnIGlkPSJTVkdSZXBvX3RyYWNlckNhcnJpZXIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI+PC9nPjxnIGlkPSJTVkdSZXBvX2ljb25DYXJyaWVyIj4gPHBvbHlnb24gc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHBvaW50cz0iNDExLjgyNywyNjcuMTI3IDQxMS44MjcsMjAwLjM0NSA0MTEuODI3LDIwMC4zNDUgMzc4LjQzNiwyMDAuMzQ1IDM3OC40MzYsMTMzLjU2MyAzNzguNDM2LDEzMy41NjMgMzQ1LjA0NSwxMzMuNTYzIDM0NS4wNDUsNjYuNzgyIDM0NS4wNDUsNjYuNzgyIDMxMS42NTUsNjYuNzgyIDMxMS42NTUsMzMuMzkxIDMxMS42NTQsMzMuMzkxIDMxMS42NTQsMzMuMzkxIDI3OC4yNjQsMzMuMzkxIDI3OC4yNjQsMCAyNzguMjYzLDAgMjMzLjc0MywwIDIzMy43NDIsMCAyMzMuNzQyLDMzLjM5MSAyMDAuMzUyLDMzLjM5MSAyMDAuMzUyLDMzLjM5MSAyMDAuMzUxLDMzLjM5MSAyMDAuMzUxLDY2Ljc4MiAxNjYuOTYyLDY2Ljc4MiAxNjYuOTYsNjYuNzgyIDE2Ni45NiwxMzMuNTYzIDEzMy41NzEsMTMzLjU2MyAxMzMuNTcsMTMzLjU2MyAxMzMuNTcsMjAwLjM0NSAxMDAuMTgsMjAwLjM0NSAxMDAuMTc5LDIwMC4zNDUgMTAwLjE3OSwyNjcuMTI3IDY2Ljc4OCwyNjcuMTI3IDY2Ljc4OCwyNjcuMTI3IDY2Ljc4OCw0MTEuODIxIDY2Ljc4OCw0MTEuODIxIDEwMC4xNzksNDExLjgyMSAxMDAuMTc5LDQxMS44MjEgMTAwLjE3OSw0NDUuMjEyIDEwMC4xOCw0NDUuMjEyIDEzMy41NjYsNDQ1LjIxMiAxMzMuNTY2LDQ3OC42MDEgMTMzLjU3LDQ3OC42MDEgMTMzLjU3LDQ3OC42MDIgMTY2Ljk2LDQ3OC42MDIgMTY2Ljk2LDQ3OC42MDEgMTY2Ljk3Nyw0NzguNjAxIDE2Ni45NzcsNTEyIDIwMC4zNSw1MTIgMzExLjY1NSw1MTIgMzQ1LjAyOCw1MTIgMzQ1LjAyOCw0NzguNjAxIDM0NS4wNDUsNDc4LjYwMSAzNDUuMDQ1LDQ3OC42MDIgMzc4LjQzNiw0NzguNjAyIDM3OC40MzYsNDc4LjYwMSAzNzguNDM5LDQ3OC42MDEgMzc4LjQzOSw0NDUuMjEyIDQxMS44MjcsNDQ1LjIxMiA0MTEuODI3LDQ0NS4yMTIgNDExLjgyNyw0MTEuODIxIDQxMS44MjgsNDExLjgyMSA0NDUuMjE4LDQxMS44MjEgNDQ1LjIxOCw0MTEuODIxIDQ0NS4yMTgsMjY3LjEyNyA0NDUuMjE4LDI2Ny4xMjcgIj48L3BvbHlnb24+IDxyZWN0IHg9IjEwMC4xNzUiIHk9IjIwMC4zNDUiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjY2Ljc4MiI+PC9yZWN0PiA8cGF0aCBzdHlsZT0iZmlsbDojNTdBNEZGOyIgZD0iTTY2Ljc4OCw0MTEuODIxaDMzLjM5MWwwLDBsMCwwdjMzLjM5MWgzMy4zOTFoMC4wMDNoLTAuMDAzdjMzLjM5MWgzMy4zOTF2LTAuMDAxaDAuMDAxVjUxMmgxNzguMDY4IHYtMzMuMzk5aDMzLjQxMXYtMzMuMzloMzMuMzg4di0zMy4zOTFoMzMuMzkyVjI2Ny4xMjdoLTMzLjM5MnYtNjYuNzgyaC0zMy4zOTF2LTY2Ljc4MmgtMzMuMzkxaC0wLjAxN2gwLjAxN1Y2Ni43ODJoLTMzLjM5MVYzMy4zOTEgaC0zMy4zOTFWMGgtNDQuNTIxdjMzLjM5MWgtMzMuMzkxdjMzLjM5MWgtMzMuMzkxdjY2Ljc4MmgzMy4zOTFWNjYuNzgyaDMzLjM5MXY2Ni43ODJoLTMzLjM5MXY2Ni43ODJoLTMzLjM5di02Ni43ODJoLTMzLjM5MSB2NjYuNzgyaDMzLjM5MXY2Ni43ODJoLTMzLjM5djQ0LjUyMWgtMzMuMzkxdi00NC41MjFINjYuNzkxdjE0NC42OTRINjYuNzg4eiBNMTAwLjE3OSwzNzguNDN2LTMzLjM5MWgzMy4zOTF2MzMuMzkxSDEwMC4xNzl6Ij48L3BhdGg+IDxyZWN0IHg9IjEwMC4xNzUiIHk9IjIwMC4zNTYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgyIj48L3JlY3Q+IDxyZWN0IHg9IjEzMy41NjYiIHk9IjEzMy41NzUiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgyIj48L3JlY3Q+IDxyZWN0IHg9IjE2Ni45NTciIHk9IjY2Ljc5MyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI2Ni43ODIiPjwvcmVjdD4gPHJlY3QgeD0iMjAwLjM0OCIgeT0iMzMuNDAyIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIyMzMuNzM5IiB5PSIwLjAwNyIgd2lkdGg9IjQ0LjUyMSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzc4LjQzMyIgeT0iMjAwLjM1NiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI2Ni43ODIiPjwvcmVjdD4gPHJlY3QgeD0iMzQ1LjA0MiIgeT0iMTMzLjU3NSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI2Ni43ODIiPjwvcmVjdD4gPHJlY3QgeD0iMzExLjY1MSIgeT0iNjYuNzkzIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjY2Ljc4MiI+PC9yZWN0PiA8cmVjdCB4PSIyNzguMjYiIHk9IjMzLjQwMiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzQ1LjA0MiIgeT0iNDQ1LjIyMyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzc4LjQzMyIgeT0iNDExLjgzMiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTY2Ljk1NyIgeT0iNDc4LjYxNCIgd2lkdGg9IjE3OC4wODUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQxMS44MjMiIHk9IjI2Ny4xMzgiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMTQ0LjY5NCI+PC9yZWN0PiA8cmVjdCB4PSIxMzMuNTY2IiB5PSI0NDUuMjIzIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxMDAuMTc1IiB5PSI0MTEuODMyIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI2Ni43ODUiIHk9IjI2Ny4xMzgiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMTQ0LjY5NCI+PC9yZWN0PiA8L2c+PC9zdmc+Cg==
"""),
    "car": """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" fill="#ffffff"><!--!Font Awesome Free 6.6.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--><path d="M135.2 117.4L109.1 192l293.8 0-26.1-74.6C372.3 104.6 360.2 96 346.6 96L165.4 96c-13.6 0-25.7 8.6-30.2 21.4zM39.6 196.8L74.8 96.3C88.3 57.8 124.6 32 165.4 32l181.2 0c40.8 0 77.1 25.8 90.6 64.3l35.2 100.5c23.2 9.6 39.6 32.5 39.6 59.2l0 144 0 48c0 17.7-14.3 32-32 32l-32 0c-17.7 0-32-14.3-32-32l0-48L96 400l0 48c0 17.7-14.3 32-32 32l-32 0c-17.7 0-32-14.3-32-32l0-48L0 256c0-26.7 16.4-49.6 39.6-59.2zM128 288a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zm288 32a32 32 0 1 0 0-64 32 32 0 1 0 0 64z"/></svg>
""",
}

PLACEHOLDER_DATA = [
    {
        "attributes": {
            "unit_of_measurement": "°C",
        },
        "state": "23",
        "last_changed": "2024-01-06T12:00:00Z",
    },
    {
        "state": "18",
        "last_changed": "2024-01-06T13:00:00Z",
    },
    {
        "state": "22",
        "last_changed": "2024-01-06T14:00:00Z",
    },
    {
        "state": "24",
        "last_changed": "2024-01-06T15:00:00Z",
    },
    {
        "state": "12",
        "last_changed": "2024-01-06T16:00:00Z",
    },
]

MAX_TIME_PERIOD = 24

TIME_FORMAT = "2006-01-02T15:04:05Z"

def main(config):
    timezone = None
    location = config.get("location")
    if location:
        loc = json.decode(location)
        timezone = loc["timezone"]

    if not config.str("ha_instance") or not config.str("ha_entity") or not config.str("ha_token"):
        print("Using placeholder data, please configure the app")
        data = PLACEHOLDER_DATA
        error = None
    else:
        time_period = get_time_period(config.str("time_period"))
        if time_period == None:
            return render_error_message("Invalid time period")

        start_time = time.now() - time.hour * time_period
        data, error = get_entity_data(config, start_time)

    if data == None:
        return render_error_message("Error: received status " + str(error))
    elif len(data) < 1:
        return render_error_message("No data available")

    unit = data[0]["attributes"]["unit_of_measurement"]
    points = calculate_hourly_average(data)
    current_value = data[-1]["state"]
    stats = calc_stats(timezone, data)

    return render_app(config, current_value, points, stats, unit)

def calculate_hourly_average(data):
    hourly_averages = {}
    current_hour = None
    hour_total = 0
    hour_count = 0
    index = 0

    for entry in data:
        if entry["state"] == "unavailable" or entry["state"] == "unknown":
            continue

        timestamp = entry["last_changed"]
        hour = int(timestamp.split("T")[1].split(":")[0])
        value = float(entry["state"])

        if hour != current_hour:
            if current_hour != None:
                hourly_averages[index] = hour_total / hour_count if hour_count != 0 else 0
                index += 1
            current_hour = hour
            hour_total = 0
            hour_count = 0

        hour_total += value
        hour_count += 1

    if current_hour != None:
        hourly_averages[index] = hour_total / hour_count if hour_count != 0 else 0

    return list(hourly_averages.items())

def localize_timestamp(timezone, timestamp):
    return time.parse_time(timestamp).in_location(timezone).format(TIME_FORMAT)

def calc_stats(timezone, data):
    highest_value = float("-inf")
    highest_timestamp = None
    lowest_value = float("inf")
    lowest_timestamp = None
    total_value = 0
    count = 0

    for entry in data:
        if entry["state"] == "unavailable" or entry["state"] == "unknown":
            continue

        value = float(entry["state"])
        total_value += value
        count += 1
        if value < lowest_value:
            lowest_value = value
            lowest_timestamp = entry["last_changed"]
        if value > highest_value:
            highest_value = value
            highest_timestamp = entry["last_changed"]

    average_value = total_value / count if count else 0
    average_value = (average_value * 10) // 1 / 10

    if timezone:
        lowest_timestamp = localize_timestamp(timezone, lowest_timestamp)
        highest_timestamp = localize_timestamp(timezone, highest_timestamp)

    return {
        "lowest_value": str(lowest_value),
        "lowest_time": lowest_timestamp.split("T")[1][:5] if lowest_value != float("inf") else "N/A",
        "highest_value": str(highest_value),
        "highest_time": highest_timestamp.split("T")[1][:5] if highest_value != float("-inf") else "N/A",
        "average": str(average_value),
    }

def get_entity_data(config, start_time):
    start_time_str = start_time.format(TIME_FORMAT)
    url = config.str("ha_instance") + "/api/history/period/" + start_time_str + "?filter_entity_id=" + config.str("ha_entity")
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 240, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    data = rep.json()
    return (data[0], None) if data else ([], None)

def get_icon(config):
    icon = config.str("icon")
    return ICONS[icon] if icon in ICONS else ICONS["thermometer"]

def get_time_period(input_str):
    if not input_str.isdigit():
        return None
    time_period = int(input_str)
    if time_period < 2 or time_period > MAX_TIME_PERIOD:
        return None

    return time_period

def render_app(config, current_value, points, stats, unit):
    if config.bool("show_history"):
        return render.Root(
            child = animation.Transformation(
                child = render.Row(
                    children = [
                        render_graph_column(config, current_value, points, unit),
                        render_stats_column(stats, unit),
                    ],
                ),
                width = 107,
                duration = 100,
                delay = 100,
                keyframes = [
                    animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
                    animation.Keyframe(curve = "ease_in", percentage = 0.2, transforms = [animation.Translate(-43, 0)]),
                    animation.Keyframe(curve = "ease_in", percentage = 1.0, transforms = [animation.Translate(-43, 0)]),
                ],
            ),
        )
    else:
        return render.Root(
            child = render_graph_column(config, current_value, points, unit),
        )

def render_graph_column(config, current_value, points, unit):
    return render.Column(
        children = [
            render.Box(
                child = render.Row(
                    children = [
                        render.Box(
                            child = render.Image(src = get_icon(config), width = 10, height = 10),
                            width = 12,
                            height = 12,
                        ),
                        render.Text(content = current_value + unit, font = "6x13"),
                    ],
                    expanded = True,
                    cross_align = "center",
                    main_align = "end",
                ),
                width = 64,
                height = 13,
            ),
            render.Plot(
                data = points,
                width = 64,
                height = 18,
                color = config.str("line_positive", DEFAULT_COLOURS["line_positive"]),
                color_inverted = config.str("line_negative", DEFAULT_COLOURS["line_negative"]),
                fill_color = config.str("fill_positive", DEFAULT_COLOURS["fill_positive"]),
                fill_color_inverted = config.str("fill_negative", DEFAULT_COLOURS["fill_negative"]),
                fill = True,
            ),
        ],
    )

def render_stats_column(stats, unit):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 1),
                    render.Box(color = "#525252", width = 1),
                    render.Box(width = 1),
                    render.Column(
                        children = [
                            render.Text(content = "Low " + stats["lowest_time"], font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["lowest_value"] + unit, font = "tom-thumb", color = "#b5a962"),
                            render.Text(content = "High " + stats["highest_time"], font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["highest_value"] + unit, font = "tom-thumb", color = "#b5a962"),
                            render.Text(content = "Average", font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["average"] + unit, font = "tom-thumb", color = "#b5a962"),
                        ],
                    ),
                ],
            ),
        ],
        expanded = True,
    )

def render_error_message(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(child = render.Image(src = ICONS["ha"], width = 15, height = 15), height = 15),
                render.WrappedText(
                    align = "center",
                    font = "tom-thumb",
                    content = message,
                    color = "#FF0000",
                    width = 64,
                ),
            ],
        ),
    )

def get_schema():
    icons = [
        schema.Option(
            display = "Raindrop",
            value = "drop",
        ),
        schema.Option(
            display = "Thermometer",
            value = "thermometer",
        ),
        schema.Option(
            display = "Wind",
            value = "wind",
        ),
        schema.Option(
            display = "Car",
            value = "car",
        ),
        schema.Option(
            display = "Home Assistant Icon",
            value = "ha",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_instance",
                desc = "Home Assistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "globe",
                name = "Home Assistant URL",
            ),
            schema.Text(
                id = "ha_token",
                desc = "Home Assistant token. Navigate to User Settings > Long-lived access tokens.",
                icon = "key",
                name = "Home Assistant Token",
            ),
            schema.Text(
                id = "ha_entity",
                desc = "Entity name of the sensor to display, e.g. 'sensor.temperature'.",
                icon = "ruler",
                name = "Entity name",
            ),
            schema.Text(
                id = "time_period",
                default = "24",
                desc = "In hours, how far back to look for data. Enter a number from 2 to %s." % str(MAX_TIME_PERIOD),
                icon = "timeline",
                name = "Time period",
            ),
            schema.Toggle(
                id = "show_history",
                name = "Display historical values",
                desc = "Show the highest, lowest and average values",
                icon = "list",
                default = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
            schema.Dropdown(
                id = "icon",
                default = icons[0].value,
                desc = "Icon to display for the entity.",
                icon = "icons",
                name = "Icon",
                options = icons,
            ),
            schema.Color(
                id = "line_positive",
                default = DEFAULT_COLOURS["line_positive"],
                desc = "Colour of the graph line for positive values.",
                icon = "chartLine",
                name = "Graph line for positive values",
            ),
            schema.Color(
                id = "line_negative",
                default = DEFAULT_COLOURS["line_negative"],
                desc = "Colour of the graph line for negative values.",
                icon = "chartLine",
                name = "Graph line for negative values",
            ),
            schema.Color(
                id = "fill_positive",
                default = DEFAULT_COLOURS["fill_positive"],
                desc = "Fill colour of the graph for positive values.",
                icon = "chartLine",
                name = "Fill colour for positive values",
            ),
            schema.Color(
                id = "fill_negative",
                default = DEFAULT_COLOURS["fill_negative"],
                desc = "Fill colour of the graph for negative values.",
                icon = "chartLine",
                name = "Fill colour for negative values",
            ),
        ],
    )
