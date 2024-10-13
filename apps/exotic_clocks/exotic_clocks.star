"""
Applet: Exotic Clocks
Summary: Weird Clocks
Description: Weird but stylish way to tell the time.
Author: vzsky
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#############################
# THAI NUMBERS
TD_ZRO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAQElEQVQoFWNgGPqAEd0L/4EAWYwRCJD5KGx0xSBJbGJgTTgl0DQxgVWTQJCsAcVsbM5CF8MIAQwF+EIJxTocHAA6px/vs8WNiAAAAABJRU5ErkJggg==")
TD_ONE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAT0lEQVQoFdWPMQ4AIAgDwfj/LysdShqVgVEWIFzbYPZ/ub6wonTn7FGcs1cwAL3NVByHp2swQwWYK5BcCghqPKF2V5P7+7BTAO5MbydBsAHi6xwD+FkEXQAAAABJRU5ErkJggg==")
TD_TWO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAWElEQVQoFZ2PWw4AEAwES9z/yqhkGo8myv5s1E4XkR/VriiXo0Fyz0CBxOfnpa79PHIM1VUezPx40r4VGD8ANmlAYYL48gcvQBC3hnkzl55b5Q2ItHsF0gAKIC/8kAkwKgAAAABJRU5ErkJggg==")
TD_THR = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAATUlEQVQoFdWPOw4AIAhDxfvfWenwCBqMiZtdWlo+2tr/ML4wHGixObKnOnIFQhguTnWnadmAWXAMFFlpxcD+hLIbk2YYPzPZ24W86aYn0Hkr6srXUPkAAAAASUVORK5CYII=")
TD_FOU = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAXUlEQVQoFbWQ0Q5AEQxDuf//z2jkLLVELg/60um6MqW8QhtQ9nd7wdEA6UfhMguYKwXsTbQ6EDWFG91Af2GZBRensmrRz2Y10GDM21/SszDDGoplXCQt8+9ueUDnDrMGP9rLj+N6AAAAAElFTkSuQmCC")
TD_FIV = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAYklEQVQoFbWQQQ6AMAzDGP//M8wgT2mFhDiQS1Y3LWzb9peOKXbvXz9QBtzSlzxyoe4QNbIeHvBsJB9T1uuQ4QwYLE4YJbxJZavfwzRkuuHySkKc3zKsX9xQQln317v1AeoTJ51LzmRQuS0AAAAASUVORK5CYII=")
TD_SIX = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAXUlEQVQoFZ2QSw7AIAhEten9r2wZk5egaCOyAeYDaGkWJRGPtFlTN1yZTi6riNhQLajhhFEPWULFAFqzwmZN6DH1XwrsD/B6jinCtnevDN4o3vfh9Z5k2NE2xHP+AHlPP9uDhyGyAAAAAElFTkSuQmCC")
TD_SEV = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAVklEQVQoFbXPMQ6AMAwDwIL4/5ehHi7qwECE6sWJGzvpGLtwTyT77C5oGy4brEx/TOhTmyn2SFh7NW6f9MkgPReUIWLgLOwPuAyEDK41Iy7DW7qhX/wAhwsr/8Q/cI8AAAAASUVORK5CYII=")
TD_EGT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAV0lEQVQoFc2QSQ7AIAwDgf//mTKHQaaqBOoJXxLHzgKlXIM+wDHt5CLNeKsNWbSWsQ5MvjNP4+8kN2TOQDhw+PLoFDQQuV9taXiLn5yi3f6EHE2oyY/jA61NN+lglROsAAAAAElFTkSuQmCC")
TD_NNE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAW0lEQVQoFbVPQQ4AIAiq/v/nihrMlrY6xEVUwErpF2oHssvrgRwZmMh97iAfFQIAzWSTLyI2FN6Itz/wtA1hsGq09Oa64C2VaIgMeIpn8mbDjwVgwkSjuQQn0gBTU0fOkXQb9gAAAABJRU5ErkJggg==")

TD_BLANK = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAQAAAAMCAYAAABFohwTAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAADAAAAAD1HLXDAAAADElEQVQIHWNgGD4AAADMAAH30YzJAAAAAElFTkSuQmCC")
TD_COLON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAQAAAAMCAYAAABFohwTAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAADAAAAAD1HLXDAAAAGUlEQVQIHWNgIA/8hwKQbibyjCBCF2m2AADUkw/1AKlPfQAAAABJRU5ErkJggg==")

TD_DIGITS = [TD_ZRO, TD_ONE, TD_TWO, TD_THR, TD_FOU, TD_FIV, TD_SIX, TD_SEV, TD_EGT, TD_NNE]

#############################
# THAI WORDS
TW_A0 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACIAAAAOCAYAAABKKc6PAAAAmUlEQVR4nO2U4Q6AIAiEveb7v/L1BxohaJvO1db3qyCPC8VSEkgWkszyqzl2FfoMyBKyKwSQfjNCNaROV6smC6dxWtvO2jSQyUCRFgLQabl10saC50tP1wzijU4zNdaYakXGJK5FEGkora8WbyQsaMS84LK9r+49PNi+Iw/vOTUdTYrNkSS8kRAAcN1QUzbuf6JnPD2LP6/jBLPsgvujtkPoAAAAAElFTkSuQmCC")
TW_A1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABkAAAAOCAYAAADaOrdAAAAAiElEQVR4nO2SwQ7DIAxD/VD//5e9wyCC0NJ2laYd5gsocRIHLD2Ebdn2ilOeDvkZkAN1cwNT7ogrSSv+lslXcJf/FSCpuQO91cXmLQ5cunc10R9QyQNm3ihi5daaI/9PWBimXNR255kfdhVsO2ozhqewzVgSGx5OL7XDJ06hqwVoapz/6Y9beAEmmWEDeWE2yQAAAABJRU5ErkJggg==")
TW_A2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABkAAAAOCAYAAADaOrdAAAAAd0lEQVR4nO2ROw7AIAxD7Yr7X9kdSlAIoRItI29C+dkJwOEPkiBJO2cWGwxg6+DP6GG5j9Zc3wJAknDxrp7kNO7NdLkoEIXiJlnOx22+M8MSrUST2X1cLDNjZhtNxG00dT6cIdk246qVb785LGM9hhf0uRUjh8YNZ4Ri9M9C+gEAAAAASUVORK5CYII=")
TW_A3 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABkAAAAOCAYAAADaOrdAAAAAb0lEQVR4nO1QQQ7AIAyCxf9/mR2mCzbO6eZRTqZSoAAbfyAJkrRSMxVhAEuFP0MXpvdYlvNbAEgSNq/4JOO8xXceGQ2iUbwk/vnMaq9MUowTw8/0Y0YVbhO76DH5m6G34tQjK/SWh48xLTb73hjBCfwsYO+63gdgAAAAAElFTkSuQmCC")
TW_A4 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAW0lEQVR4nM2PwQ6AIAxDXwn//8v1IEYYI2Liwd54W7sCm7KNbQOUXdP36museL0AkC5mXC9bGJD6R0uVTpzVlCQUDdGYXapDxP2PuDiohqESw1S3NDKlPRz7sw4Qq0vmVMQHsQAAAABJRU5ErkJggg==")
TW_A5 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABMAAAAOCAYAAADNGCeJAAAAY0lEQVR4nO2QzQ6AIAyDW9//nesBh81kS0i8aS+M/XyDAp8Qc0ISAIgk/Q4AkWthPjALNrgDfE3xMl2xfHnkSa7ixyeYQQ7saiFfcji+sEN2tpZNmIaWVvDeVPUMWDSVHb+yTnDDPxWlK5YTAAAAAElFTkSuQmCC")
TW_A6 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAOCAYAAAA8E3wEAAAAgElEQVR4nO2SwQ7DMAhDn6v9/y/Tw0ByaaaIqcf6kihgGwjw4mHoH1JEAASApJHG2NDMpl4AHFNCmihNx/jEt2RJwu+FfDO/a1cWX2p0/tGI8hwjKxUan+p2icyVV1mGYefobza5t+rKcNfFb8XrZLbE8dJ0VJG00XlstRsvHsMJ/LhKGm7xcioAAAAASUVORK5CYII=")
TW_A7 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAOCAYAAAA45qw5AAAAhklEQVR4nO1SQQ6AMAhrl/3/y3hhykBxuuhpTXaiLRQGLChEBCIiX/nzrCEAAQCSof6W61GyobLEpimfNp3GzDmqCknSm3RBspqrW6+d5/XFCdlgua1m3lnQy3UrtztJ9RFuVtcGCNCUw7rqGYMDROdjK0PS7Ff7YVI3wwm/3Jyuu/vCL9gAjJplBxdP+PsAAAAASUVORK5CYII=")
TW_A8 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACEAAAAOCAYAAAChHnWMAAAAkElEQVR4nO1TQQ6AIAxrjf//cr0MnTCFGWM80IQQstF2GwATPwLfIpIEAAIAkineZYBcJjBigFkDoQlJ6InWMF2akTRWK7MQ+D1E1ZamcBcnyXLe86L73XEEAnQrGtVdAUX4lJMy4fmuAp0nEd5bH5q4VnHjHX1bTSesVdLxLfbuldgdoctp2u65kf/JE99gA62NUQ1RWpGFAAAAAElFTkSuQmCC")
TW_A9 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB0AAAAOCAYAAADT0Rc6AAAAeUlEQVR4nO2SOw7AIAxDbcT9r+wOhTYKoBIVNt5IHOcHcNgI/YMkABAAkGziUd1U0RlDE4/W+4ckqFSPkksiSXqTZ4rRu2lANmY9e/nJJbJitTS0HrdkNFXR0naaRuIIH3dtOswritYtob+FhlWTEu9vZi/m73zYxgXPXU0ZQdRDiAAAAABJRU5ErkJggg==")
TW_AA = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAOCAYAAAA8E3wEAAAAfUlEQVR4nO2SwQ6AMAhDi+H/fxkPsoUhBDE77p1moLV2AofN0B+RiACAAAARtTzIG8xBYmR2u++KkYdqB+VSAgfCmVxnr2cf0OoSzfRm34t+YacugrsO4+WDgIMULdQsG78a4aKCElPzJ+m16lY0hQwQ/JljR4+U6SPtYQs3H6tr9sSpZVcAAAAASUVORK5CYII=")
TW_AB = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACwAAAAOCAYAAABU4P48AAAAq0lEQVR4nO1Tyw7DIAxzJv7/l71L6NxAU2DrYRK+ocR2XgAbfwSSIMknPewXIl4jAcDMbjVn8xUlClTMClUaSWZc8Vq0aAWf3upXp2Md4tG5x5o3fEIIW0GYWtBWHQSumdmV3ymnxL34hIfWlXGlOQ1HSq9pbUq1AHxueGk9wkvPFhef24uZ4pWbNYxg+fPoiY3avs7cbiWsiMVl8RrLzCXHmlsR7ei7sSF4A4LunvrtM/TEAAAAAElFTkSuQmCC")
TW_P0 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAAcklEQVR4nOWS0Q6AIAhFOc3//+XbQ+gMsTZbW1vnSS9wganZBEkmSbP4FdtK0bd4sn6JRma2ZPQ6+IrYMSFAXRugJfZacm5+wPj6fZOanzVxvRqdAtE0LXZBTswfKOE+GGaT3n2KaJoCEKasDXo9HeiH7BvyVPu2X/LHAAAAAElFTkSuQmCC")
TW_P1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACIAAAAOCAYAAABKKc6PAAAAiElEQVR4nO2TOw7AMAhDH1Xuf2V3aFIh8q86dKi3EEwMOPDjo7AYkAQgM6vuZihcgF1+2n1sQcSTHt6FJJQV7SJl4t2FP4eio5xqCo5b5bXqDlfjq+uCsT7+khsFRnEAHLNqHXFZV38LA6FN0rZZG6sc5sGabcyR7lirm0XvgPv6PS9F//z4NE7nc3cAulfSLQAAAABJRU5ErkJggg==")
TW_P2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACUAAAAOCAYAAACo9dX2AAAAfklEQVR4nO2SwQ6AMAhDW+P//3I9OA1OxsZpxqy3wQqPALD0J0mCJM1k2GY2nyKdSvtYXCR5F7reVcXoj/cfvbiFt7k9JDbOMjUBqEr5nYwniKPwPOBDqBaoWcuLzNuXiXnDqK6ThnLWHeXc9ffEUXPi1oD+vbVuahh86bM6AA1chfR6r/clAAAAAElFTkSuQmCC")
TW_P3 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACUAAAAOCAYAAACo9dX2AAAAgUlEQVR4nO1RQQ7AIAgry/7/5e4wcA6R6MlssSeFUgoAG38CSZDkSg/HyuZLwBvTdaJVIiJFyP5OMeNEfAzqeJ6cqWOrRplaANClQn5dE+loyPReSE31jFZnaZzN3Eu308SnTQXnznKpQeN76qEK5DN+eBrDAH94Waalz37TjS/hAkM4hO/ahw55AAAAAElFTkSuQmCC")
TW_P4 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABYAAAAOCAYAAAArMezNAAAAgklEQVR4nO2TzQ6AMAiDW7P3f+V6EBbC0OlMPPmdFn5K2RRISIIk5fhTtrcCn8McsFsQSfoZAEgOtVPhKJByWtCs0YGflx+SRWN3WGxCkj4s1g01Le9pjnPYr2XANONAAEArJo5rHU1naaH4CNpkrRjjDQ8d/0EuG2yqG2CVywZ/OjuPzmL1mRPwvAAAAABJRU5ErkJggg==")
TW_P5 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABsAAAAOCAYAAADez2d9AAAAeUlEQVR4nO1RSQ6AIBBrif//cj0ISQVhQD3SCyTTZRZg4wewfCQBgACAJHuCWd4wbMbI6qs57yAJyqmrOLKQJOH/bOymzTRWn9KnSkjn0NBqL0pvisyld1jCZO/0PQJe01kJiyZ4drtvIxSliDBCaQ7VurxW33HjM04cUFQV8sAL0gAAAABJRU5ErkJggg==")
TW_P6 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAOCAYAAAA8E3wEAAAAgElEQVR4nO2SwQ7DMAhDn6v9/y/Tw0ByaaaIqcf6kihgGwjw4mHoH1JEAASApJHG2NDMpl4AHFNCmihNx/jEt2RJwu+FfDO/a1cWX2p0/tGI8hwjKxUan+p2icyVV1mGYefobza5t+rKcNfFb8XrZLbE8dJ0VJG00XlstRsvHsMJ/LhKGm7xcioAAAAASUVORK5CYII=")
TW_P7 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAOCAYAAADXJMcHAAAAkUlEQVR4nN1Uyw6AIAxrjf//y/UgIPKQkshBe4GwrXRjDDAhCZLk+jvY3iT7FOg4hWoLAEhOxTz57+6lvwNDB5Mk8j0AGLbEg7NCI9+bPXV7PKh5awQ7W+/Z4Wm+e7xc2er0VE9dM77Ht112xkzKzDVRlabwIj4ROEMmiYrkmUirUkW89VWXY4kKdyitnO3DxA67CmwP1t2EHwAAAABJRU5ErkJggg==")
TW_P8 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAOCAYAAABO3B6yAAAAh0lEQVR4nO1UMRKAMAhLvP7/y3GweIhUcaiDZ5ZykDYJQ4EfX4UkSNIdb3nDzCNow2t6TNRIcjdTnJGk9UZ1ymN05IejmVNNRQHEE1bHO22QNKaMhg5G4jUn5I2m5BYTX629iBPfbyY+vxw56UsyWMv3KwaN38tHaaZjipu+TQH365n5EZXCrfFVeASeu6IIAAAAAElFTkSuQmCC")
TW_P9 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAOCAYAAABO3B6yAAAAh0lEQVR4nO1Uyw7AIAwC4///Mjusmmp8bYkelnHSKoViIvDjq5AESZrdCyfMPIJuHNNjQ40ks5m67mp+v7JucmJWM1gCJAl/luoACGAYURKw5ZATXPOl7Cu/TX2g8D7kRB+Hc9/vXk7X8chlTijvzGHdk+lpHG85x7DFjaUpoPEeFXZ+REvDXcBwdPqVwh0dAAAAAElFTkSuQmCC")
TW_PA = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAOCAYAAAAvxDzwAAAAeklEQVR4nMWTQQ7AIAgEwfD/L28PFQMEKrWHzgmFxcUoUQAAAUDc7zJOhf9Rjdy9CtFiIjq+t0dwc6znRM3MvJrrOokpy8lSe4duWwUzZI0zh2IEFdaZ2qJKItZu0TwOER273PA1PeYJaoR39Z9odbfvdOfozV9uHX4BOXJn7ieB/0oAAAAASUVORK5CYII=")
TW_PB = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABkAAAAOCAYAAADaOrdAAAAAgElEQVR4nO1Tyw7AIAhr/f9/ZoeJYwo+osku60UirRSIwI8FUAMRAQABAJKMBDVU19OkUu3mMAtl1e3nYHZNkrAx0HTUcDr8V76MSy8slwZ1TY8Ps2MLLSLmnNm7y4t06cn7jgO4RqruyiOpYW5ATeZw+hucKb4jnv3AJ8Y1NHoB3fBRGhJojugAAAAASUVORK5CYII=")
TW_HOURS = [TW_A0, TW_A1, TW_A2, TW_A3, TW_A4, TW_A5, TW_A6, TW_A7, TW_A8, TW_A9, TW_AA, TW_AB, TW_P0, TW_P1, TW_P2, TW_P3, TW_P4, TW_P5, TW_P6, TW_P7, TW_P8, TW_P9, TW_PA, TW_PB]
TW_NEUNG = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAZ0lEQVR4nNVSQQ7AIAhrl/3/y90FCJsaezJZLxqopYCACUmQpFX+coWOgQ4pOhIAkJy+uV2BY2BsgiTR7+Folyud2loSR86IyLPPK4XUztU8X1rfQAoxMXEkx63zIatAum0F3Q7+jAeti0QHKenMNAAAAABJRU5ErkJggg==")
TW_1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAYAAADwikbvAAAAX0lEQVR4nM2QMQ7AIAwDz1X//2V3ARpSBEhduBFjxwkch21se/ZHIxNgAEkfPXLNgleTf1HTRakatdg6tZCk15zXi+9hQJMB3YPk2Z26kHyw1YE7mrm4XIlBVdtOPZsHwM00B4yzQLEAAAAASUVORK5CYII=")
TW_2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABMAAAAOCAYAAADNGCeJAAAATUlEQVR4nO2PSwoAIAgFHfD+V65FFCWW0SqiWarvo8jnLlLhSIujBGjGmzsAwWvWi7xd5zDc66SBTbfmg2lFbZPVaxHY9MDcm2+HPUIGrrtAAQwvPE4AAAAASUVORK5CYII=")
TW_3 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABMAAAAOCAYAAADNGCeJAAAAVUlEQVR4nO2QQQ6AMAgEGcP/v6yHphbppm08NdG9scBmwOzXXjqLXu0iNgHu4OwHL9YAhiKLgdmvpQpzQTA+pQTInmeSWXAg7EaP58wSGdbO7N70AV046j/7s0EWOwAAAABJRU5ErkJggg==")
TW_4 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAOCAYAAADjXQYbAAAAQ0lEQVR4nLWQQQoAIAzDUvH/X64XpyKKIpjTWNcWBhO2sW2ANIvvjLE5FoBvnGFEbepI0tkZncu+XIUWNR7GE3bmHxSwLzPmwlIBNwAAAABJRU5ErkJggg==")
TW_5 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAATklEQVR4nNWPMRKAQAgDd/3/n7EQ8EZPqys0DRRZSOBzspaIAAgA1Sdga/LwmHCsi5TXVBn3ySfVE8j8Pa81ylcdYphvnbu0pXuSOfBn7YilJBAvasTUAAAAAElFTkSuQmCC")
TW_6 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAQUlEQVR4nO2OMRLAMAjDpPz/z3SJ2+SaLB170WLgsAEO37GqClBlrEOf3fvqYwImXYWkbwkcdLq0IibD+6O96U9cQWkgDVXYX4YAAAAASUVORK5CYII=")
TW_7 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAYAAADwikbvAAAAXElEQVR4nM2QSQ6AMAwDx4j/f9kcKFWXqDlUIOaa2ukEfodtbHv1RlEIMICkad5yrIqzzVs87ZI0Ona/jmY1zO1ZA0Fp629A57gm8exKpoOpkPmG4YhS9t7lv+UC70QvDFDVqD4AAAAASUVORK5CYII=")
TW_8 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAU0lEQVR4nGNgGAUUg/8QQFAdExaNDMRoRAcsUOsYGRgY0GmcLkTiMjIyMmJ3ET6AZCkMw80lySBkM9EFyDUIA2AYBPX0//+I6IKHA0yOWpYPEQAApAYp+4uujuoAAAAASUVORK5CYII=")
TW_9 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAASklEQVR4nNWPOw4AIAxCH97/zjj4S1oHB2MiIwUK8A0UCdsABpCU7gMlJTWteohvNVwPeqokxQ+z6Y6fRtquKE4zB582nuK98SNUeV4hCfYrdTgAAAAASUVORK5CYII=")
TW_SIB = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAT0lEQVR4nN2QwQqAMAxDX6X//8vxYHHVubKdhL1bSUlCYD8MQBKAHoKZTbvook76+LhDQutuf9eIpLKdJ4dpfFCh5EitOjGcpLbO0qg/cQLqijb7m0H1GwAAAABJRU5ErkJggg==")
TW_HALF = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABMAAAAOCAYAAADNGCeJAAAAa0lEQVR4nN1SMRLAIAyCXv//ZTo0etHGmMmhbDkBwxGgCEmQpIxzVc2OgxWSpRMAkFxq7qrJcdA28L8PSYIGSTLW6MUgbvP85jiIOOlp2Ipy6H4RvxXQiJ+mfGYz3LbZNXPkhTfdptm1/BEPOJ9i12JxgCIAAAAASUVORK5CYII=")
TW_NATEE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAVUlEQVR4nO2PMQ6AMAwDz6j//7JZSFpQqkqIjd6Uwbk4sKmwjW0DtDfLgL8uleiqJkkUc+YkRaMyf0wvDPT9TkhinIoWZJMgRH5eWHCTjKJ8oQr9nBM1FjYLRY+cwwAAAABJRU5ErkJggg==")
TW_YEE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAOCAYAAADjXQYbAAAAQklEQVR4nK2NSQ4AIAgDp8b/f7lexAXjxdhTgU6BJNvYNkDJx3ettTUWgJ+qomnzpTtJOiBFeplHuGZy5k6S24uPart8M+zMIuisAAAAAElFTkSuQmCC")
TW_DIGITS = [TW_NEUNG, TW_1, TW_2, TW_3, TW_4, TW_5, TW_6, TW_7, TW_8, TW_9, TW_SIB]
TW_BLANK = TD_BLANK
#############################

DEFAULT_LOCATION = {
    "lat": 13.7563,
    "lng": 100.5018,
    "locality": "Bangkok",
}
DEFAULT_TIMEZONE = "Asia/Bangkok"

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))

    current_time = time.now().in_location(timezone)

    clock = render_thai_clock(current_time)
    if config.get("clocktype") == "roman":
        clock = render_roman_clock(current_time)
    if config.get("clocktype") == "thaiwords":
        clock = render_thaiwords_clock(current_time)

    return render.Root(
        delay = 500,
        child = clock,
    )

def render_thai_time(hh, mm, separator):
    return render.Box(
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Image(TD_DIGITS[int(hh[0])]),
                render.Image(TD_DIGITS[int(hh[1])]),
                render.Image(src = separator),
                render.Image(TD_DIGITS[int(mm[0])]),
                render.Image(TD_DIGITS[int(mm[1])]),
            ],
        ),
    )

def render_thai_clock(current_time):
    hh = current_time.format("15")
    mm = current_time.format("04")
    return render.Animation(
        children = [
            render_thai_time(hh, mm, TD_COLON),
            render_thai_time(hh, mm, TD_BLANK),
        ],
    )

def img_of_thaiwords_minutes(minutes):
    if minutes == 0:
        return [TW_BLANK]
    if minutes == 1:
        return [TW_DIGITS[0], TW_NATEE]
    if minutes <= 10:
        return [TW_DIGITS[minutes], TW_NATEE]
    if minutes < 20:
        return [TW_SIB, TW_DIGITS[minutes - 10]]
    if minutes == 20:
        return [TW_YEE, TW_SIB]
    if minutes < 30:
        return [TW_YEE, TW_SIB, TW_DIGITS[minutes - 20]]
    if minutes == 30:
        return [TW_HALF]
    if minutes % 10 == 0:
        return [TW_DIGITS[minutes // 10], TW_SIB]
    return [TW_DIGITS[minutes // 10], TW_SIB, TW_DIGITS[minutes % 10]]

def render_thaiwords_time(hours, minutes):
    def row(images):
        return render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [render.Image(img) for img in images],
        )

    if hours == 0 and minutes == 15:
        return [row([TW_HOURS[0]]), row(img_of_thaiwords_minutes(15) + [TW_NATEE])]

    onerow = (minutes == 0) or (minutes == 30 and hours != 11) or (hours == 12 and minutes <= 10)
    if onerow:
        return [row([TW_HOURS[hours]] + img_of_thaiwords_minutes(minutes))]
    return [row([TW_HOURS[hours]]), row(img_of_thaiwords_minutes(minutes))]

def render_thaiwords_clock(current_time):
    hh = current_time.format("15")
    mm = current_time.format("04")
    return render.Animation(
        children = [
            render.Box(
                render.Column(
                    cross_align = "center",
                    children = render_thaiwords_time(int(hh), int(mm)),
                ),
            ),
        ],
    )

def roman_numeral(num):
    numbers = [(50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    result = ""
    for val, str in numbers:
        for _ in range(10):
            if num >= val:
                result += str
                num -= val
    return result

def render_roman_clock(current_time):
    hh = int(current_time.format("15"))
    mm = int(current_time.format("04"))
    texts = [render.Text("H " + roman_numeral(hh), font = "6x13")]
    if mm != 0:
        texts.append(render.Text("M " + roman_numeral(mm), font = "6x13"))
    return render.Box(child = render.Column(children = texts))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the time",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "clocktype",
                name = "Clock Type",
                desc = "Type of the clock to display",
                icon = "language",
                default = "thai",
                options = [
                    schema.Option(
                        display = "Thai",
                        value = "thai",
                    ),
                    schema.Option(
                        display = "Roman",
                        value = "roman",
                    ),
                    schema.Option(
                        display = "Thai Words",
                        value = "thaiwords",
                    ),
                ],
            ),
        ],
    )
