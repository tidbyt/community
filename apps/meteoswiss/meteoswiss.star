"""
Applet: MeteoSwiss
Summary: MeteoSwiss Weather Forecast
Description: Weather forecasts from MeteoSwiss for Swiss locations.
Author: richardgaren

Originally written by LukiLeu.  Modified for compatibility with original Tidbyt.  Extended day abbreviation support for EN, DE, FR, & IT.
Data Source: MeteoSwiss https://www.meteoschweiz.admin.ch
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Weather symbol images
IMG_001 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAIVBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQDa2gA/PwC/vwA/PGVYAAAAaUlEQVR4AWMAA0EIhcZRhnKMQByTAAYGJQYGZmEQhzUdrMDQAExVQFVDwSzBlXCzmAUFBQ1gnIlAjiSMsxDIkYLYJ8QgCAIMikIoHIQyTAMQRmNaaoTkHGZhqEMhJNQLaJ7DCAOQMgIAANyxDQsL904QAAAAAElFTkSuQmCC")
IMG_002 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAIVBMVEUAAADl5eXr66v4+Dn//wDIyMjf3wC/vwB/fwA/PwAcHBwsAMD2AAAAcElEQVR42n3PUQ6FIAxE0eG9cSjsf8EaIRZp4/mjFwjAkQjyIHsHEwbjKJIvl5IvFC52rZK1ITDeDJvGaT9TOdXlWxTAByBSSZiTwcP/Vy5w8vGlY1E2mHoajCUY8zwYG9IgQx6Aj3AkITy4Y/PeewIReQNMCzpfOwAAAABJRU5ErkJggg==")
IMG_003 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAoElEQVR4Ae2UAQYEMQxFc5BcpGDu1AvMgXqIHiUgYIABw6DbwtddIxspYPcJMD/PF6Zk09qYOHGRCO27XzTCfeX5Q2sPLpE+RtjnMmK1fguJuK62beSlR2sdOxidIODpP899s04ws9dyXek4ipqUUlJK1hXOM6sT6FAeZ9YQb4foMLOGQItV0GIVdPmLfkmEX0TXyDkTYOZwF/pAQ8xvyAv+ZO+v6lyATgAAAABJRU5ErkJggg==")
IMG_004 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAALVBMVEUAAAD//wDf3wB/fwC/vwA/PwCUlJTx8RISEhLk5CWurm9vb28lJSXJyUpKSkqCih/+AAAAaElEQVR42tXPQQ6AIAxE0ZmiFQW9/3G10Ugb0b1/NzwSAlokXF8gKUKSCxJPEWnTSRuDG+JfGhEaBx7pEUKJ1mSQ4/m86F2pN3BVyxNJAfSRAZE74G9HyC+g+h8otQ8b0P1gAawnVAA7VVQI7LvpAbQAAAAASUVORK5CYII=")
IMG_005 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAAAAADFHGIkAAAARElEQVR42tWMMQ0AMQzEjOE5hEzIhIwBv1SpS5MCqEf7dLxAVMWoVSsGqWfKZXpKT/ZN46L1ohV9J1TMIQG+Yc+ihwB++ADFgfXZ2iIAAAAASUVORK5CYII=")
IMG_006 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAQlBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJTx8RISEhLk5CWurm9vb28lJSXJyUovKrshG8FKSko0o4jwAAAAd0lEQVR4Ab3PBQ6AQAxE0ZkWd73/UXGa4BvjReF3DQYkjh6D6DGoYKWevw7I+knFxg9CGGUEE8YwZIKDJOIkneBAOcvmkB//F2VqqtoCm9RsiaQA6QU4QX4TDtOHkD+ENP0ztO1D6DqHUNX3W/XA7QMrLK6hBjACFEsQP3zKVL0AAAAASUVORK5CYII=")
IMG_007 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAASFBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJTx8RISEhLk5CWurm9vb28lJSXJyUovKrshG8GXt8eb2vpKSkqNMOQlAAAAg0lEQVR4AXXQxQGAQBBD0QR3l/47xYe1ecd8dPEj4QmHKLZDHL0hTlJcomeIGeOVZjlEzAIiLyHICpaq4Kk+wRLz0lyhtfeur8UwSuB0DVYiGQG15wpEGwhytRdaJfjTPCthWZywruGwbttqP0r2q4hw8B/1H4n/8ssOBH9wwM0P16kfqS0RPRZsAy4AAAAASUVORK5CYII=")
IMG_008 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAQlBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJTx8RISEhLk5CWurm9vb28lJSXJyUqXt8eb2vpKSkoQXH/SAAAAfUlEQVR4AZXPBRKAMAxE0d0Gd73/UXHCZPA/nhdoiyMSF12BEwviNhDPXxfWgVCw5QchNGEELYyhkQlMScSpdAom4Vw2Q27nRZlqVa3AZh4YIumA9NQMRH4BZttAfg12/ye07TW0Xdda0LmRd7C/qurrw3vg8oEVls5QAxgBXd8Qx4ZHzEkAAAAASUVORK5CYII=")
IMG_009 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAQlBMVEWUlJT//wAAAAB/fwDf3wAvKrtvb28lJSUSEhIhG8E/PwB9fQB+fgC/vwDx8RKurm/9/QD7+wDJyUrk5CXa2gBKSkreCU1+AAAAfElEQVR4Xq3PWwrDMAxEUc1ItvPue/9brQzBdYgoFHp+r9FgYQOw8y2YHoPaHvS6sDJjpdA9cLnNbBTrZ2N+9kvTcXxa4cTxEBTVJm7og+JxkSaXFnAX1ycBYN7P4DgEgZRY+DqWksTG8deQ0l9v5xKfepHhBzNr4DkUkm/2RQNNXuWyrQAAAABJRU5ErkJggg==")
IMG_010 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAASFBMVEWUlJQAAAD//wB/fwCXt8ff3wCb2vovKrshG8Fvb28lJSUSEhK/vwA/PwB+fgB9fQD7+wDx8RKurm/JyUrk5CXa2gD9/QBKSkoZceH9AAAAjklEQVR4XoWQWQ7CMAxEYzvpvrBz/5vi0tG0JAXeVzTP8igOQlRlxy+R7FNYgrDH9BYprbkahEynWYjpsHXM933TCAHGQZ3goJwbFs6L6CGQ3y6BtB2FXpFRBVVN7kvUkf5AYLqE0/+p6y+iabKJGDOBR6yqiEEK5DBZGUQBV/EkAOXgKXL4wXY9eyk6Fy+dJgOGtbuqOAAAAABJRU5ErkJggg==")
IMG_011 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAASFBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJTx8RISEhLk5CWurm9vb28lJSXJyUqXt8eVpa2ZyOCb2vpKSkq0ipM+AAAAhklEQVR4AW3PBQ7EUAgA0aFs3f3+N90qCSkvznzFIEIgCon6oAk3/aX3gnugojzSLMeoFJi8xIhUOFUhh/qAo3Jq6kPr511fm2G0IFPtHElEEqg/kANtEKAOQRsH6nqew7Cs2xYVtsNd5jkOs+30R822018ehZs/ahgtuMt3CD84cPmGEfgDImoR4UQPVqIAAAAASUVORK5CYII=")
IMG_012 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAVFBMVEWUlJQAAAD//wCUlZV/fwD6iQDf3wDgiyWUlpclJSUSEhLHjkqtkW/tihJ9fQB+fgA/PwC/vwBvb2/7+wCgkoH9/QD6lwDa2gCtknGUl5jgjCZKSkqJKFbgAAAAnUlEQVR4Xn3P5xICIQyF0dxQtldref/3NGAWF0W/n/cMk4GQYsauf+BtDtYr2NMUwfvXzlYB02FEyvKCDTBe9pdmBW1eWCIJGVjmDVoF3c8uRLG1ScDsFDYiZvbilIPEElrqIgw7AAL3sh4pC22ASoBKyV79gr4EffGBMaYqPTB1fS0/qG/38gVjnOsob20iDZ/7A9AP5q0IgG9oBJ7PcASpsLbM4AAAAABJRU5ErkJggg==")
IMG_013 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAWlBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJQSEhL6lwD6iQBvb28lJSXHjkrtihKtkW+gkoHgiyUvKrshG8GUlZWUlpetknGUl5jgjCZKSkqS2e+ZAAAAqElEQVR4AXXNVWLFQAxDUYXBeWGG/W+z6jjkwvnUHcDD82D9G/zAhsCHCsJID+gQeAGgojjBhXuKW5K9f8ph5KlHQjACjzQUdv+U38Sp6tfL5RM08b4PiJhA8AiFNG5vXwEQ6rj28gaepoFBDIjDfbimcbShu8I0PaG7Lpgwz/OgF+xT87KsvHANSsO2uwt84qFPlWUjNlQ1hFru5qkDVMgvFRz5peb6BX4MEkovA7VUAAAAAElFTkSuQmCC")
IMG_014 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAGFBMVEUAAACUlJQSEhIlJSVvb29KSkohG8EcF6g6Lo1mAAAASUlEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggFktiCIjeAI0orjjMQRRXaAA7LTDBgQII0BG6cczoEyyvGpBwBkNhE1Fm8K4wAAAABJRU5ErkJggg==")
IMG_015 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAJFBMVEUAAACUlJQSEhIlJSVvb29KSkqb2vohG8FNbX0cF6h0o7smNj4a1fKAAAAAWUlEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggFktiCIjeAI0orjjMQRRXaAA7LTDKAeSgPiciibI60BwWlLy0DjzIRyuNIWIMKGO20DmAYAHfAWDrmaKVoAAAAASUVORK5CYII=")
IMG_016 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAKlBMVEWUlJQAAACb2vpNbX1vb28lJSVKSkp0o7smNj4SEhKXt8cTGx+ZyOCVpa3PJ7ilAAAAZklEQVR42tWQyQ0AIQgAAe89+m93gaiEYAM7DyUzkYeADmBQ8WFIGD6UDJtcLFRQLMHygbkmMnWE9f/J5eyrfiJd0Uu4iZ7Xr0EJpMiop2Ih8ZT0stDb9q4Aq4THsOCXDU+hE3U0Pr2uAd6hbLa9AAAAAElFTkSuQmCC")
IMG_017 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAG1BMVEUAAACUlJQSEhIlJSVvb29KSkovKrshG8EcF6jb1TbEAAAAVUlEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggFktiCIjeDAWWnInHJ0DqayNGQDyjE5zkjKRJEd4IDsNAMGBChnwMbpgHOgjA586gE7rhSpvuaWJAAAAABJRU5ErkJggg==")
IMG_018 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAJFBMVEUAAACUlJQSEhIlJSVvb29KSkqXt8eVpa2ZyOCb2vohG8EcF6iYb9TVAAAAaElEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggGQOByAxBEcwTQkTsXMRARn5sxpgkBZBEcMKAtXlgkUgBmA4AAxTJkziAM1QBTZMQ7ITjNgQIBVDNg4u+EcKGM3PvUA/bce8hRara0AAAAASUVORK5CYII=")
IMG_019 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAKlBMVEUAAACb2vqZyOCXt8eVpa10o7uUlJRvb29NbX1KSkomNj4lJSUTGx8SEhJIWhePAAAAeUlEQVR42m2QUQ7DIAxD7aYECuv9r7uVIaxGeT+AX2Sk4I3/QML9iBsvRvVNHcovF1LKhWoCmg5oOgB3s1ScB5kZkFzGLBe2vKp2LqPPMzGJVXXAZZRfeNiDIf+Qx5lslpP/DQuJBqDNQ/Sy82DQGiQSClmQ0cmuF77wjwhM5rpeSAAAAABJRU5ErkJggg==")
IMG_020 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAG1BMVEWUlJQAAAAhG8EvKrtvb28lJSUcF6hKSkoSEhLcXT31AAAAYElEQVR4Xm2KsQ2AQAzE3FFfxddZgQkoGACJGahZgc1R+OQVJNzEjg51cIlocEccONsbM/TyuEh8NKhO8cJSw/IzwurMUggxkhFb2U+ikaxCJLuQqWP6izMixS8xcb7xAA5yDrNgRtvtAAAAAElFTkSuQmCC")
IMG_021 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAM1BMVEUAAACUlJQSEhIlJSVvb29KSkqXt8cvKruVpa2ZyOCb2vohG8ETGx9NbX0mNj50o7scF6hrERocAAAAeklEQVR4AW3OhQ3FUAxD0Txm2H/ZDy5ayhX7pCCc+SVK9g+WN+fNnXdyF+6ViXbEr2Gg6zu6JjAmRp5SAuRSK0trgPoPEqMO8XR+FfZL6OMKXMX37t0N9NtB/uGQ8th7rSUzONwjedWa3DAUmOva934AjUEDDigAp8EXA4gFFRTAr+AAAAAASUVORK5CYII=")
IMG_022 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAKlBMVEUAAACb2vqZyOCXt8eVpa10o7uUlJRvb29NbX1KSkomNj4lJSUTGx8SEhJIWhePAAAAhElEQVR42m2QQRaEIAxDGyvYwfH+11WyaAT5G9okL4I2Uh9swdWNywbOoybHKf1XhSzpQjUTi7Q7jU/aAe8GE6NOx/aN59cAh+zOKhkUMpBVWUH08YUxXVO/ZHiY5A58fqGRP7DtkvtlgnnCCbnHe4g8wKEVCQqQCEtDuyhAsRUNaNrsBmxbCBOAthDKAAAAAElFTkSuQmCC")
IMG_023 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAALVBMVEUAAACUlJQSEhLadwD6iQBvb28lJSVKSkrHjkrtihKtkW+gkoHgiyUhG8EcF6g3n4cTAAAAdUlEQVR42p2P7QrAIAgAc8u+Vnv/x50VYmWDsfsT3KWRmQFiURKOWZ22Ag10Q7Ac5uRhCvySQwjNRwldQyJ7wUjVROY1EvpBPr+FtAupD+iQZUACD6ggAzpYGxaNroW4et//rUDy2+TMllLMx3DfKrDgC/92P1wNA8EqsB98AAAAAElFTkSuQmCC")
IMG_024 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAALVBMVEUAAAD6iQDtihLgiyXHjkqtkW+gkoGUlJTadwBvb29KSkohG8EcF6glJSUSEhINHyPiAAAAhUlEQVR42p2QQQ7DIBADHTbUJQn9/3NL11ItRA9V5gQevAgwwwHEKl6YeG4fmLQOs0kIq4MWIuPeuGdeLBSzjvRBUfJAxmR4DDUS301QVK0tKkVoLVGXAiViKUi44NvgwnwbtNlpEfklKYpzZuHQuxMLsmFgZdHxk/PEn+K6FuFAB+7NfgOhBwiEQaiU9wAAAABJRU5ErkJggg==")
IMG_025 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAMFBMVEWUlJQAAAD6iQAhG8GtkW/giyVvb28lJSUcF6jtihIvKrvHjkpKSkoSEhLadwCgkoFa5pV5AAAAi0lEQVR42o2QWQ6EMAxDDW1ayjJz/9vOZJFwhED4y/HLIgVTEgCEu4Ijg8+sgql1AjMBRQF2ZBCnesNm+SBgMeo//cI1vEFjQGiNraRCwlb1DGpYIY96NyCPA+tK13iglHTNiw0nEH+Jamgeq2xg1yceICkAmr/9CrqDUiaS1S/BsiTAATcgrQg9gh/jwgNWKmC5agAAAABJRU5ErkJggg==")
IMG_026 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAbUlEQVR4AeWQAQYAMQwE+7M+bZ+Wp+w/Crkch4PtWQJ1Y6FSY5OxJ/NOA4Yom+gTvVmr0rCsITrjRqK8ioEh+u2NAGmpkQfgWxRzjohHEVFPswg59pBf1QDR3/qmxmTFcanCmRX7CFrkI1Y7kgsQoFOL69V6CAAAAABJRU5ErkJggg==")
IMG_027 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAkElEQVR4AayQAQoEIQhFvVknq47mPQLwIBHuX1gENhMEH59hZtKXSDGq3xSQFonQnAkRitHiH5xDYzgXIHcx7Hj6wLI39U4RscWAZa38EmJaI+bfjvCCzyw2/38Sg9gsqn5yczE/RTh6YkUi9ieKrdy6qkU3seimWqRF1Ik+IyKvE6WGPIOGXhjRv8weEmEEAMrnmEkW5+NIAAAAAElFTkSuQmCC")
IMG_028 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYAQAAAADIDABVAAAAEElEQVR4AWOAAsb/EExtPgAcigwBIDUqQQAAAABJRU5ErkJggg==")
IMG_029 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAxElEQVR4AazRAQbEMBAF0DnIXCQgd1oA2h4oh+g9CgUDChSUqO6vsM3aGF/sMwpN/oyJ+K7rrn79Qesq08QH3Ydxpf3jPGUcGw1Qv4eRjm8bUnKWYRBfSZln8SBlWaitxSisGNEWd56yipDK/HXlrFZRVTblOMK2JXOllEII3hb2/WW0EvcM/3lm6/K1CFBV68JNQeCmIIj9yXsj1yBLk6NARAWDFKUPAhEdDEJkEUq9VlRUBEnS5CVIhFvghlCURZDLEACOcuLRqa1OMwAAAABJRU5ErkJggg==")
IMG_030 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAx0lEQVR4AdWUsQ2DMBBFbxAv4oqd3AODZAQPQeagobqKIhIVioXIr76cCDknu4jy9EXD+fl8AFLmPAWpoFm0LDKOYhehGEuubxyHDMPFBghhMey4XgNLStL3UoCWaZISsMyzaWpdJ1ZQim2xhtEMscD+86TkNMM5Z7Xsu1/XqEVijN770hS2LagR6tg8H7NW8TYIgMNrFeyiFXbRiij5D9F9eSCtIihu8xOxuOSrha7fiuxH4yfSOOwQgpDqFxK9yAdaRf4PeQGwVusB+8tNpgAAAABJRU5ErkJggg==")
IMG_031 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAA1klEQVR4AayTsQ2DMBRE/x5xkx3SuGIn98AgGcFDkBRZgobKFUUkKhQLkatOJCDLfHg6pYn9fP6ApJlnQfToRV0ndb1DhMXYsv3HNElVbRyArBfDjt9tYIlRylIS0NI0kgKWts2aWlFILliKY7GHCQskB/ZfJkYTFhhjci3jaPvehyTee2ttagrD4EIm1LE8H3NQ8TMIgMsHFWxxFLY4irKLvb2QE0TXyxPZIXp0b0QvouXefhC6NFejZe0ip4mUV0t/IsphE+ecEPULiS7yR1Bhv0MqQwCojt5FrXeZygAAAABJRU5ErkJggg==")
IMG_032 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAyElEQVR4AcWUgQbDMBCG7z0W2DsMAvpOAaDtA+UhathLFAoOFCgoUd3PONlWcbts9vkVmny5u7alMvuOkB27aJqo7z8QYTG2HN/YNuq69wOQg8Ww43oMLClR21IBsQwDlYBlHFVTaxrSgqU4FnsknEGCpv48KTnOcM5pLevq5zlykRij9740hWUJrER0Urw8ZjbxNAiA5o2iB1yNVFELsQl/uSFfEJ1PV+T/InNrskEB6Vv4sUg+kcrWQggkmF9I1EIvsIn8H3IHhqrWFT1Ua/QAAAAASUVORK5CYII=")
IMG_033 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAQlBMVEWUlJT//wAAAAB/fwDf3wBvb28lJSUvKrshG8ESEhI/PwB9fQB+fgC/vwDx8RKurm/9/QD7+wDJyUrk5CXa2gBKSkr2HOLTAAAAg0lEQVR4XoXPWQ4DIRBDQewGZs+e+181ICFrUJPkfVKWgEAF8NQviNaDxQZ221mLkTWDNeB+36gMh+7g9qIC1v7y9UAplNiBoXapsJzB8LwGlbIAj3YmCgBicR9KXAbQ1j6t/zdNX2CetfDQLzQU6MAvNOjzkPL4mW9y+MHECvSQSX4AHdgDjbYGv6kAAAAASUVORK5CYII=")
IMG_034 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAASFBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJTx8RISEhLk5CWurm9vb28lJSXJyUqXt8eb2vqVpa2ZyOBKSkqL4/vxAAAAjklEQVR4AW2QBQ7AMAwDnWbMvP+/dBTNUuHEPhcSEIggIi2c+kIdDM1yK1igooCRFyWISgVS1iAiDTyaSh7aB3iovHSv6P18GFsyzRSyMP2ViDigjXiFoE+IuL2uJvow37bXwBpe/hnshzUisb2svJtXUVjAAq/iFT98PBb+N7kSCu/bJ+ANyD4+YjEDuAGzEBJ9fQLyhAAAAABJRU5ErkJggg==")
IMG_035 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAAAAADFHGIkAAAARElEQVR42tWMMQ0AMQzEDOSJhFZoBZd5vFSpS5MCqEf7dLxAVMWoVSsGqWfKZXpKT/ZN46L1ohV9J1TMIQG+Yc+ihwB+hnAxmkvajrkAAAAASUVORK5CYII=")
IMG_036 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAVFBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwDl5eUcHBz6lwD6iQCrq6s5OTnvt3L3lBzqzqvn2cj0oDnk5eXpzqw5NMXj5eUhG8FycnKrqndxAAAAoUlEQVR4AXXNURaCMAxE0SkVQYIFQBBx//t0SD3aWLyf80jBl3M4loXC2+ALRP5Uxg/i4J3HW3muoOJe46O6pH9qYDS1IyEY3imh1u7XsBPV9cnLIQmaeF8AIiYQHKGVQfcxCYDQxPUmKfBrmhnEgCju878wHYVpP8jCsiwzD7LA/a4H6/obHvFg27KnQhjEhq6H0MjdPPUEtZLpoCTTc30BLb4R3d+D7kwAAAAASUVORK5CYII=")
IMG_037 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAWlBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwDl5eUcHBz6lwD6iQCrq6s5OTnvt3L3lBzqzqvn2cj0oDnA3+/k5eWb2vrpzqzj5eXS4uqt3PRycnLMvH6jAAAApklEQVR4AXWQVQKDQAwFHy6hLe7c/5p9+AaZz5nV4MSycOM52I4Ojr0Fx/XWBatwLAcbnh9ghz7EQRCZN8VQxKFFhEDh0G4h0f7znZGFX2qc/DXCkrjfBkRUILAIEskWnxsBEFLQlmICriYVg+ggC/TVWyieAq/IpK4voWkaXiF129Yq0Hc8qSUsKvTVY2Dhk4phND1HIiTPhBiXTyCJ3Phh4R5S2j+WjhKqaohubwAAAABJRU5ErkJggg==")
IMG_038 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAS1BMVEWUlJT//wAAAAB/fwDf3wASEhKtkW/HjkovKrv6iQDgiyUlJSVvb28hG8F9fQDtihI/PwC/vwCgkoF+fgD7+wD6lwDa2gD9/QBKSkpy1++IAAAAo0lEQVR4Xn3NVxLDMAgEUEDFvafd/6QBBRkznsl+afYhADqDSJf8gxg8hKgQ3keBGH89BgU6HnMR7Te7Mb8MEFd/fN2QAxxyEBArJAXtn50ESsbhBMROoRIgYmQHBQtyKEFTYLkAkXDmdgcXSgK9rfHhvq/Qth5yhWm6TMgHA3vs9sFWMcgFK2xCINsKd7oBD+NQYOHerfoQASW4ZSQBusPA8AWwRAY774QNMAAAAABJRU5ErkJggg==")
IMG_039 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAUVBMVEUAAAD//wDf3wB/fwD9/QB+fgD7+wB9fQC/vwDa2gA/PwCUlJQSEhL6lwD6iQBvb28lJSXHjkrtihKtkW+gkoGXt8fgiyWb2vqVpa2ZyOBKSkoror5HAAAApUlEQVR4AX2OBRbEMAgFf93de/+DLgFeSdbm+UwCwIgi+PwJcRKGJNaQpJk8EJFECZQsLyCwL/FQVP6mGgF1GRENgYCErIY29F3vaJhh9Cb3FjiRimKgaSwIiAi0zcR+9gLQEAvZVdW2SWgbYrcx23G4goYhvz+ei4XlM/CKSWfbKF0hwpY/Nx0yQtGw/wp00nJevh9GDvNks5kbRNt8MID5DCPZFyD2Ewpb/g7vAAAAAElFTkSuQmCC")
IMG_040 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAKlBMVEUAAACBgYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoHgiyUSEhKfGc9yAAAAaklEQVR4AWOgCRAyQeIoKcF4YWlpSnBeGpAD4xVBOUpAtrNGWlomlOOstCxtkxIYANlKx9KUoBwgTstB5mQhOFpphxAcnbRFCM6yHCUE51gWEietCco2AXJmQNnqDAy8SjBgAPIJDDgwAABh/CPPaVmdCAAAAABJRU5ErkJggg==")
IMG_041 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAARVBMVEWUlJQAAAD//wDf3wB/fwCtkW/giyX6iQASEhIlJSXHjkp9fQDtihK/vwA/PwB+fgBvb2/9/QD6lwD7+wCgkoHa2gBKSkpl3N4lAAAAkUlEQVR4XqWQxxbDIAzAvCB7dP7/p9aB2IW06aU6Shg/AHSIsOBXYKmD8B7ksiTBnD2JXbXcBnSEpveO4VFumuvl80QKKFgFIbLQlkHo2mxAYu08EDUecgIiYu1gwSEFW+iTH4uACEpQe4cKPa1EW3xEfTwL4ZsPZwPx/wFf3bvwL9kYj/6JmB54ZM3f/hk6DS91GQQnny4d5AAAAABJRU5ErkJggg==")
IMG_042 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAACUlJT6iQCXt8fgiyUlJSVvb2+tkW+b2vrHjkpKSkrtihKBgYGgkoHadwCVpa2ZyOASEhIoyMN5AAAAeUlEQVR42tWN2RGFMAwDLeeGd/bfLMFoMEOgAPZzdyzLE3ghp8sA4Jw+ugIMSRlOaQLDjumU0czPHjaN0u2bKgR0TAPRZ0KtaxEY3cfdW/FQxmAvGrd9ii8o/DkPtG4ThCHeBdVYvr+jz8nC3HzbmKTzx0AWAwNJRBbDwQN9k0/ciQAAAABJRU5ErkJggg==")
IMG_101 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAFVBMVEUAAAD//wD/603f3wC/vwB/fwA/PwDhOJ4OAAAATklEQVR42r3PMQrAMAxDUf/Y1v2P3KGUDrGgUIhGv0Fy/ElSGgGgJygnwkk5EU64IwflgM8gB2WgGctVMMxNANbaHuSFnoZu98inV3EwFzx6AQpjOm8MAAAAAElFTkSuQmCC")
IMG_102 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAlUlEQVR42t3SsQ0DMQhAUSaIIkVKxSKu2MkL3EAMQestrqK67qrrSJlEWIpjaO6eqL+xBJzNuoIZiAARhJi9Z1kCIZGkFhGYJbVEfCu4VLxl1hmipJAIfHne4XGbCZmlhWa/dhxl21g/zIT2vaqDiPBTKYWZdRh01Vr1T/1d1JkJMXNOSJ3LhFproZCHiOq4Uxwz/v4LVwFD7jPabaAAAAAASUVORK5CYII=")
IMG_103 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAhUlEQVR42u3TuQ2AMAyF4TdIFnGVnbxABsoQGYUqFR0VnUHiCFdBbBoEnyKl+3NIxts0DUSQEryHiUhZIUAvpYda3kNkt/RCmBN9T20bR0Sk/6mu47xRkSOiGGM+qcsx786/kzNWiqvnqBgTxZIww7T9oU+FyohkG2bGyjmnvgsOssp26Ad9oMECTOcm5AAAAABJRU5ErkJggg==")
IMG_104 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAhklEQVR4Ae3TsQ3DQAiF4TfD7XBz0LNMRmAJ5vAK1J7CjfdwKNDplKQ5SBPFnyjRL/sk8GuOA9cFMxChxCtjRJBn9qUWUSTG5IlE4jz7tj1c7z3/UvvOOlnI+Z5v65u1HDPrLJGLyrrPv5NQT4R6IkDDHfqvUJyI1jAzhtZa+lvwQlPmo38Ce0J9SYpri2EAAAAASUVORK5CYII=")
IMG_105 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAAAAADFHGIkAAAARElEQVR42tWMMQ0AMQzEjOE5hEzIhIwBv1SpS5MCqEf7dLxAVMWoVSsGqWfKZXpKT/ZN46L1ohV9J1TMIQG+Yc+ihwB++ADFgfXZ2iIAAAAASUVORK5CYII=")
IMG_106 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAMFBMVEUAAAD//wDk5CXf3wDJyUq/vwCurm+UlJR/fwBvb29KSkovKrs/PwAhG8ElJSUSEhLnxSAvAAAAWElEQVR42mMgAAxjkDiCgg0ITqCgBIJzUFAQweEQVJuH4ImUl8N4L8uBAMrjArLgvOXlUABWBAPI7HIQG8EpJ5ezG5lzF5MzD0lZFQMDP1z7BKDT4JwHDACIqFldC7Nl9gAAAABJRU5ErkJggg==")
IMG_107 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAABvb2+UlJSXt8eb2vrk5CWurm/f3wDJyUp/fwD//wC/vwA/PwBKSkovKrshG8ESEhIlJSWW/H9oAAAAaUlEQVR42qXNyw6AIAxE0aH4rKLy/z8rNumGKSvPsjeZ4o9VjxMRbXYEjlE59YPArjovqYLpJk2XahLTpyKGUpGezxA/Ez8TCLmuQbjvLuQchzxNmafsbsXFgadcqvTcFDSPkAQjpAJ4ATnUBRFhsuBcAAAAAElFTkSuQmCC")
IMG_108 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAMFBMVEUAAADf3wD//wC/vwA/PwB/fwDk5CWurm9vb28lJSXJyUqUlJRKSkqXt8eb2voSEhLBlhnEAAAAYklEQVR4AWMgAIRMkDhKSgEIjpGSKoLjpKSE4LAqpXcieFq7d8N4M3YDAZTHA2TBead3QwFYEQwgs3eD2AjObvycu0icve9uIzj33r1F4WAo60QyYA8DAz/c4Aag0+CcCQwAPPeDYKoih4YAAAAASUVORK5CYII=")
IMG_109 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAMFBMVEUAAADf3wD//wC/vwA/PwB/fwDk5CWurm9vb28lJSXJyUqUlJRKSkovKrshG8ESEhLlae7mAAAAYElEQVR4AWMgAIRMkDhKSgEIjpGSKoLjpKSE4LAqpXcieFq7d8N4M3YDAZTHA2TBead3QwFYEQwgs3eD2AgOnHUXmfMOnYOp7C6yAe8wOZ1IyvYwMPDDTWgAOg3OmcAAACBugrbEFx4eAAAAAElFTkSuQmCC")
IMG_110 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAADf3wD//wC/vwA/PwB/fwDk5CWurm9vb28lJSXJyUqUlJRKSkovKrshG8GXt8eb2voSEhLxeAt0AAAAcUlEQVR4AWKgBDAC6iALIwZAAIj1cJf9l+1XH80pCS6kOgYB9CnIW1HiBcdEC2Gs86dTQgRL8i5+WFKiZto9WLYhiyarZthVzpdQyid8ZoBal1DKx7dWuRUD/K9EbnUOgFvxSyILfXqAHjfc5wP34GGfYUAP42H3VNwAAAAASUVORK5CYII=")
IMG_111 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAAD//wDk5CWb2vrf3wCZyODJyUqXt8e/vwCurm+Vpa2UlJR/fwBvb29KSko/PwAlJSUSEhLkw/CEAAAAbklEQVR42qXNSw6AMAhFUbAqKv25/83akiYm9DnyTg950J9WPgoEbkUEx5cU7hEoMi9nqkB415ajmtTylLUFKKvvnXHZNcquIaiKQLi2EARB6JmIYJDhfkrswD+HYPmpVAe455lat04lsmaoRPQAJgoOvLSHOlMAAAAASUVORK5CYII=")
IMG_112 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAOVBMVEUAAAD//wDf3wC/vwChoYH6iQDtihLgiyXHjkqtkW+gkoGUlJTadwB/fwBvb29KSko/PwAlJSUSEhLGfwlwAAAAd0lEQVR42qXNMRKAIAxE0URFxFUU739YcasMhMpf7puA/GnS+XZBa6cH80hu/RKnU3VBLu4vAFo6whfQUTBg6IIBxrlkbNxXA5yR6rrDxhmIfMYmYHWPI0geJB44EHnQgH9A4IELIWzNnAthbfdLag+6srAeioi8hPEOp39BgvEAAAAASUVORK5CYII=")
IMG_113 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAP1BMVEUAAADf3wD//wC/vwA/PwB/fwChoYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoHgiyUvKrshG8ESEhKYBP87AAAAg0lEQVR4AWKgBDAC6hoLHIpiEIA9n/vuf9Y/ICF/1niLXPezDFfjXYV7V54LWK281/UJqZZfRGNI2gDNj8lw6JIVXWigVlI49L4LTYvQbBT/gG4kPsNBIM2nXQirEIYFDqlf4NAv5MyhXyiFgzGOJjlIhcE7EnzKHo3anwDkgcxBNfsDgc0MHfbzBRwAAAAASUVORK5CYII=")
IMG_114 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAGFBMVEUAAACUlJQSEhIlJSVvb29KSkohG8EcF6g6Lo1mAAAASUlEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggFktiCIjeAI0orjjMQRRXaAA7LTDBgQII0BG6cczoEyyvGpBwBkNhE1Fm8K4wAAAABJRU5ErkJggg==")
IMG_115 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAJFBMVEUAAACUlJQSEhIlJSVvb29KSkqb2vohG8FNbX0cF6h0o7smNj4a1fKAAAAAWUlEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggFktiCIjeAI0orjjMQRRXaAA7LTDKAeSgPiciibI60BwWlLy0DjzIRyuNIWIMKGO20DmAYAHfAWDrmaKVoAAAAASUVORK5CYII=")
IMG_116 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAKlBMVEUAAACUlJQSEhIlJSVvb29KSkqb2vqXt8cTGx+ZyOCVpa1NbX0mNj50o7v1VamPAAAAYklEQVR42tWQWwrAIAwE11dsq97/uo2VbgnmAh0QZYbkQ1iCAoc4Q7Qu5UByAim0TPQWrtkDtYV6C3p+E3LyQ8FEqu8PkfNyflYe1gsvDA1AWxfpg94WVQ1eIDo54NFFOj5u1eIDMF5WtewAAAAASUVORK5CYII=")
IMG_117 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAG1BMVEUAAACUlJQSEhIlJSVvb29KSkovKrshG8EcF6jb1TbEAAAAVUlEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggFktiCIjeDAWWnInHJ0DqayNGQDyjE5zkjKRJEd4IDsNAMGBChnwMbpgHOgjA586gE7rhSpvuaWJAAAAABJRU5ErkJggg==")
IMG_118 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAJFBMVEUAAACUlJQSEhIlJSVvb29KSkqXt8eVpa2ZyOCb2vohG8EcF6iYb9TVAAAAaElEQVR4AWOAAkFBBjhgEhRUgDJNBEHAGcxmBbLgvEBBKAArggGQOByAxBEcwTQkTsXMRARn5sxpgkBZBEcMKAtXlgkUgBmA4AAxTJkziAM1QBTZMQ7ITjNgQIBVDNg4u+EcKGM3PvUA/bce8hRara0AAAAASUVORK5CYII=")
IMG_119 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAKlBMVEUAAACb2vqZyOCXt8eVpa10o7uUlJRvb29NbX1KSkomNj4lJSUTGx8SEhJIWhePAAAAeUlEQVR42m2QUQ7DIAxD7aYECuv9r7uVIaxGeT+AX2Sk4I3/QML9iBsvRvVNHcovF1LKhWoCmg5oOgB3s1ScB5kZkFzGLBe2vKp2LqPPMzGJVXXAZZRfeNiDIf+Qx5lslpP/DQuJBqDNQ/Sy82DQGiQSClmQ0cmuF77wjwhM5rpeSAAAAABJRU5ErkJggg==")
IMG_120 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAG1BMVEWUlJQAAAAhG8EvKrtvb28lJSUcF6hKSkoSEhLcXT31AAAAX0lEQVR4Xm2KsQ2AQBDD3FGn4utbgQkoGACJGahZgc3hyUmcEK7sKMjQJaPBmbHRWZ4YwdXjIMGnpDr2L1ON8FIi6i0s7xIUHEv5D6KRMAuRsAqFTOgv9gyLB6QMfeICDnIOs5yjvSIAAAAASUVORK5CYII=")
IMG_121 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAM1BMVEUAAACUlJQSEhIlJSVvb29KSkqXt8cvKruVpa2ZyOCb2vohG8ETGx9NbX0mNj50o7scF6hrERocAAAAeklEQVR4AW3OhQ3FUAxD0Txm2H/ZDy5ayhX7pCCc+SVK9g+WN+fNnXdyF+6ViXbEr2Gg6zu6JjAmRp5SAuRSK0trgPoPEqMO8XR+FfZL6OMKXMX37t0N9NtB/uGQ8th7rSUzONwjedWa3DAUmOva934AjUEDDigAp8EXA4gFFRTAr+AAAAAASUVORK5CYII=")
IMG_122 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAKlBMVEUAAACb2vqZyOCXt8eVpa10o7uUlJRvb29NbX1KSkomNj4lJSUTGx8SEhJIWhePAAAAhElEQVR42m2QQRaEIAxDGyvYwfH+11WyaAT5G9okL4I2Uh9swdWNywbOoybHKf1XhSzpQjUTi7Q7jU/aAe8GE6NOx/aN59cAh+zOKhkUMpBVWUH08YUxXVO/ZHiY5A58fqGRP7DtkvtlgnnCCbnHe4g8wKEVCQqQCEtDuyhAsRUNaNrsBmxbCBOAthDKAAAAAElFTkSuQmCC")
IMG_123 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAALVBMVEUAAACUlJQSEhLadwD6iQBvb28lJSVKSkrHjkrtihKtkW+gkoHgiyUhG8EcF6g3n4cTAAAAdUlEQVR42p2P7QrAIAgAc8u+Vnv/x50VYmWDsfsT3KWRmQFiURKOWZ22Ag10Q7Ac5uRhCvySQwjNRwldQyJ7wUjVROY1EvpBPr+FtAupD+iQZUACD6ggAzpYGxaNroW4et//rUDy2+TMllLMx3DfKrDgC/92P1wNA8EqsB98AAAAAElFTkSuQmCC")
IMG_124 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAALVBMVEWUlJQAAAD6iQDgiyWtkW8hG8ElJSVvb2/tihIcF6jHjkpKSkoSEhLadwCgkoHHPPXTAAAAhElEQVR42o2Q6w6FIAyDi0NAPcf3f1xlW2LJ4qW/Sr9dwpAGAYC7CH4j+E9dUNVCYCLQkYMNI/BVpWLVvBHQGPlMd5iaFfQYEBqjI+khbrN6AtmtkEe+a5D3BoSGsM0eK3mxk3S1K4c2bCn5BxkA1c5uiEFREDTP6SNYlgAo0IIIXI/gAIYpAwxIydLUAAAAAElFTkSuQmCC")
IMG_125 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAMFBMVEWUlJQAAAD6iQAhG8GtkW/giyVvb28lJSUcF6jtihIvKrvHjkpKSkoSEhLadwCgkoFa5pV5AAAAi0lEQVR42o2QWQ6EMAxDDW1ayjJz/9vOZJFwhED4y/HLIgVTEgCEu4Ijg8+sgql1AjMBRQF2ZBCnesNm+SBgMeo//cI1vEFjQGiNraRCwlb1DGpYIY96NyCPA+tK13iglHTNiw0nEH+Jamgeq2xg1yceICkAmr/9CrqDUiaS1S/BsiTAATcgrQg9gh/jwgNWKmC5agAAAABJRU5ErkJggg==")
IMG_126 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAYElEQVR4AWMYfOA/lQDVDCLoXnREHsA0aBiEEaYHCXqTcoNGw6i+Hq9BlJuyfz9xRtjbA5XCtWEikAIC4P59DG2vfYEIWaS+nqygRRiEMIUsg0h0C8JruEIXFC7kg1EAAKvGhPFGDQKpAAAAAElFTkSuQmCC")
IMG_127 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAXElEQVR4AeXQwQmAQBADwHSWNuzmSksp97aK6O8+gsIGZLmQ97AbdMucsCGBRCn26hgFSApZJOyQJYWsdVTdsh9KhiApBNnbQA4lBn175DzuvqxTgBps9GNabHQBVuR7XYp2aIsAAAAASUVORK5CYII=")
IMG_128 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYAQAAAADIDABVAAAAEElEQVR4AWOAAsb/EExtPgAcigwBIDUqQQAAAABJRU5ErkJggg==")
IMG_129 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAlElEQVR4Ae3TAQYDMRCF4XePBnqHwoDcaS6QA/UQUfQcCwYssGCB7WBEtIXMRCn7eYD4bZbg3ywLjgO1ImeEaKWtFPjVOqmVsyXa/EqxxL7Tut4VEfn/1LaxdAZyek5Py4exHDNLz5Gzyrjv13GIJ0w8YSBBZ4huT92E0PXy0P0oZE8keDVmRpNSEhf9FrwRl/7RvwDLa7RGqeadBgAAAABJRU5ErkJggg==")
IMG_130 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAnElEQVR4AdXTAQYDMRCF4XeQXCQgd5oL5CA9Qg+RnqMQMGBRFqzCdrCeVTRppkp+A4hPEgazVSv2HaUgJbgyhZOzAyrlR1ZKB8EZL+eD2La4LFcrxjj+U+sqeuoLzs7Zaf1YmxMR7Y6cS2GN5/TnJRgJb1A2B3SrDxsvZMTl/rTpsdBUaP0VcjyNK+L8bBEBCyHoUHYXvKVDnZf+Be1PvHag4BpXAAAAAElFTkSuQmCC")
IMG_131 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAACrq6vl5eXA3++b2vry8nLr66v4+Dnf3wBycnJ/fwD//wC/vwA/PwAcHBwhG8E5NMU5OTmHx6s/AAAAaUlEQVR42qXNOQ7AIAxE0cFkI87G/S8bYskNY6q80l8a449NjxMRbXYEjlE59YPArrouqYLpLE2XahLTpyKGUpGezxA/Ez8TCHmeQbjvLuQchzxNmafsbsXFgadcqvTcFDSXkAQjpAJ4AWF+BSOeHxMXAAAAAElFTkSuQmCC")
IMG_132 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAMFBMVEUAAADl5eXr66vy8nL4+Dn//wDf3wCrq6u/vwBycnJ/fwA5NMU5OTk/PwAhG8EcHBweEDWiAAAAX0lEQVR42mMgAFJ7kTihoQsQnNbQKATnamgogsMV6lSD4AULCsJ4xwWBAMrjBLLgvImCUABWBAPIbEEQG8GBs3Yjc96hczCV7UY24B0mpwZJmSQDAz/chAKg0+CcAwwA7pYeTasMOf0AAAAASUVORK5CYII=")
IMG_133 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAMFBMVEUAAADf3wD//wC/vwA/PwB/fwDk5CWurm9vb28lJSXJyUqUlJRKSkovKrshG8ESEhLlae7mAAAAZUlEQVR4AWIgAIRMkDhKSgEIjpGSKoLjpKSE4LAqpXcieFqAJuWYBmIgiqGgAZx0lNOmSxkuEwbBsBQWQypL35VHelQ3qh9UL0AjML/5RbcmNrEmdrNiQbNdUJyh2ZP8dUcS3ZUPVzeDYK5xoVYAAAAASUVORK5CYII=")
IMG_134 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAADf3wD//wC/vwA/PwB/fwDk5CWurm9vb28lJSXJyUqUlJRKSkqXt8eb2vqVpa2ZyOASEhL3qxSgAAAAeElEQVR4AaWQsRICMQhEkUs0kRD1/3/WQLEFYOVrboa3s1ygf7jx1UrBh16J65dpbFBBZ74/xqQMP+UQ1BziRLXEyApzEGtAkVZ1kdK6txmyRJi7odfbv1lsQ9GNKggfYDmqUAGwPIn4mzhJfJiz6PCRxCAnCzvtF57tEBkNw5AlAAAAAElFTkSuQmCC")
IMG_135 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAAAAADFHGIkAAAARElEQVR42tWMMQ0AMQzEDOSJhFZoBZd5vFSpS5MCqEf7dLxAVMWoVSsGqWfKZXpKT/ZN46L1ohV9J1TMIQG+Yc+ihwB+hnAxmkvajrkAAAAASUVORK5CYII=")
IMG_136 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAP1BMVEUAAADf3wD//wC/vwA/PwB/fwChoYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoHgiyUvKrshG8ESEhKYBP87AAAAf0lEQVR4AWKgBADqmosECEIYCqLTWtBu9z/rkGSD/mU9pOuHsQp92FSDoSVjL6tdmfp+xvnqL0BOyyqDgtYIItpIATR7x679iEAzZ6gX8TTDHYAU0IV+t+CswWkXSrj1Qgl24XkKsAvvW8C67qTgvMIRevLU9gv7KOZ+uhJ8qH9yPgu/vPFBVAAAAABJRU5ErkJggg==")
IMG_137 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAARVBMVEUAAADf3wD//wC/vwA/PwB/fwChoYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoHgiyWXt8eb2vqVpa2ZyOASEhKR7nG+AAAAhElEQVR4AaXONwLEIAxEUecB58j9j7ojVSRV+8t5NtD8U9v1QxU6Ntagt2TopKbS2HUTnK/eApbRvEhAQUsEEa2IQdLZO2y67zHIjIPriTiZ2UVACtC4XxYcNeAVG+67BF6B+3nuHORNj3RncFnAJx3vF+/OK+wbWHT52rCAItdoJXiuP9PYDIHt2aF9AAAAAElFTkSuQmCC")
IMG_138 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAP1BMVEUAAADf3wD//wC/vwA/PwB/fwChoYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoHgiyUvKrshG8ESEhKYBP87AAAAiklEQVR4AWKgBADqmgskiGEYhqLln5Tp/mddR0t1QUMZvdjOi7K6hcJS30H5JFWRcjdSF0VDiLdXgDO1XQpcSL3AUY8HUB0Dg/rRgdVM1s4coxoWAzygWL98q3X1MH1h2xDohwY86DFrwK0S6IIKd3xNMGnSgU4PeAhRMFrvVvWZZeeSkClXiNa+AOVqDGUQLhWrAAAAAElFTkSuQmCC")
IMG_139 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAARVBMVEUAAADf3wD//wC/vwA/PwB/fwChoYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoGXt8fgiyWb2vqVpa2ZyOASEhIl5SN5AAAAjElEQVR4AWKgBADqHKsEgEEYis0Lc+X+R93DPZ8JtG27fiiGDoyl0NfK0EmaAmPXTcR4cQuBJM2LhChLiwtRWikKQGnOaFN+jwI0HbCnUdelAjS4/ZjreS4ZSAF/O6+KD0ce1IoNs/NRWGGEX24+LA8whVy4awEnHe8XesZV2Dc/W7E2QFAGaxR54LA/s6QNhTk4yl8AAAAASUVORK5CYII=")
IMG_140 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYBAMAAAASWSDLAAAAKlBMVEUAAACBgYGUlJRvb28lJSXadwD6iQBKSkrHjkrtihKtkW+gkoHgiyUSEhKfGc9yAAAAaklEQVR4AWOgCRAyQeIoKcF4YWlpSnBeGpAD4xVBOUpAtrNGWlomlOOstCxtkxIYANlKx9KUoBwgTstB5mQhOFpphxAcnbRFCM6yHCUE51gWEietCco2AXJmQNnqDAy8SjBgAPIJDDgwAABh/CPPaVmdCAAAAABJRU5ErkJggg==")
IMG_141 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAOVBMVEUAAAD//wDf3wC/vwChoYH6iQDtihLgiyXHjkqtkW+gkoGUlJTadwB/fwBvb29KSko/PwAlJSUSEhLGfwlwAAAAd0lEQVR42qXNMRKAIAxE0URFxFUU739YcasMhMpf7puA/GnS+XZBa6cH80hu/RKnU3VBLu4vAFo6whfQUTBg6IIBxrlkbNxXA5yR6rrDxhmIfMYmYHWPI0geJB44EHnQgH9A4IELIWzNnAthbfdLag+6srAeioi8hPEOp39BgvEAAAAASUVORK5CYII=")
IMG_142 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAANlBMVEUAAACUlJT6iQCb2vqXt8clJSVvb2+tkW/giyXHjkpKSkrtihKBgYGgkoHadwCVpa2ZyOASEhJHLcueAAAAeUlEQVR42tWN2RGFMAwDLeeGd/bfLMFoMEOgAPZzdyzLE3ghp8sA4Jw+ugIMSRlOaQLDjumU0czPHjaN0u2bKkZ0TAPVZ2IIaxEY3dfdW/FQxmAvGrd9ii8o/DkPNGwThKHeBdVavr+jz8nC3HzbmKTzx0AWAwNJRBaKyQMkjARQhAAAAABJRU5ErkJggg==")
IMG_ERROR = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAM1BMVEUAAAA/Og6/sCr/6zj/6zj/6zgfHQf/6zj/6zj/6zi/sCp/dRx/dRz/6zj/AAD/HQf/7Digpp2EAAAADXRSTlMAP7/+vX8f/b++IUB/27QMVwAAAJNJREFUeF690NEOgjAQBVF3VxHUW/j/r5WaJo2DW+OL95FMTxtO75MkfPotsBrYIPAa+BeABAESBEgQGBIPaUjcl5C0bSlxOV9DaylrQtxeQdmXEPMcoRZ8JCrcgyNhCETCGTgBBCQcAQkTg0YQaD+qEwAwI8A5AF4hGYH2SBImBCScAQnlgWowSXxk39TPZ/tD8AQZkxyWe0kTBQAAAABJRU5ErkJggg==")

# Weather symbol images mapping
WEATHER_IMAGES = {
    1: IMG_001,
    2: IMG_002,
    3: IMG_003,
    4: IMG_004,
    5: IMG_005,
    6: IMG_006,
    7: IMG_007,
    8: IMG_008,
    9: IMG_009,
    10: IMG_010,
    11: IMG_011,
    12: IMG_012,
    13: IMG_013,
    14: IMG_014,
    15: IMG_015,
    16: IMG_016,
    17: IMG_017,
    18: IMG_018,
    19: IMG_019,
    20: IMG_020,
    21: IMG_021,
    22: IMG_022,
    23: IMG_023,
    24: IMG_024,
    25: IMG_025,
    26: IMG_026,
    27: IMG_027,
    28: IMG_028,
    29: IMG_029,
    30: IMG_030,
    31: IMG_031,
    32: IMG_032,
    33: IMG_033,
    34: IMG_034,
    35: IMG_035,
    36: IMG_036,
    37: IMG_037,
    38: IMG_038,
    39: IMG_039,
    40: IMG_040,
    41: IMG_041,
    42: IMG_042,
    101: IMG_101,
    102: IMG_102,
    103: IMG_103,
    104: IMG_104,
    105: IMG_105,
    106: IMG_106,
    107: IMG_107,
    108: IMG_108,
    109: IMG_109,
    110: IMG_110,
    111: IMG_111,
    112: IMG_112,
    113: IMG_113,
    114: IMG_114,
    115: IMG_115,
    116: IMG_116,
    117: IMG_117,
    118: IMG_118,
    119: IMG_119,
    120: IMG_120,
    121: IMG_121,
    122: IMG_122,
    123: IMG_123,
    124: IMG_124,
    125: IMG_125,
    126: IMG_126,
    127: IMG_127,
    128: IMG_128,
    129: IMG_129,
    130: IMG_130,
    131: IMG_131,
    132: IMG_132,
    133: IMG_133,
    134: IMG_134,
    135: IMG_135,
    136: IMG_136,
    137: IMG_137,
    138: IMG_138,
    139: IMG_139,
    140: IMG_140,
    141: IMG_141,
    142: IMG_142,
}

# Day abbreviation language setting EN (default), DE, FR, IT
DAY_ABBREVIATIONS = {
    "MON": ("MON", "MON", "LUN", "LUN"),
    "TUE": ("TUE", "DIE", "MAR", "MAR"),
    "WED": ("WED", "MIT", "MER", "MER"),
    "THU": ("THU", "DON", "JEU", "GIO"),
    "FRI": ("FRI", "FRE", "VEN", "VEN"),
    "SAT": ("SAT", "SAM", "SAM", "SAB"),
    "SUN": ("SUN", "SON", "DIM", "DOM"),
}

# Default station (first alphabetically sorted station from MeteoSwiss)
DEFAULT_STATION = """
{
    "value": "0",
    "text": "Invalid Station"
}
"""

# CSV delimiter used by MeteoSwiss data files
CSV_DELIMITER = ";"

HEIGHT = 32
WIDTH = 64

def main(config):
    """Fetch and display MeteoSwiss weather forecast.

    Args:
        config: Configuration object.

    Returns:
        Rendered display widget.
    """

    # Get configuration
    station_config = config.get("station", DEFAULT_STATION)
    station = json.decode(station_config)
    forecast_type = config.get("forecast_type", "daily")
    language_type = config.get("lang_type", "0")
    language = {"0": 0, "1": 1, "2": 2, "3": 3}.get(language_type, 0)  #default to English

    # Check for valid station
    if station.get("value", "0") == "0":
        return error_display("No Station selected")

    # Fetch and process data based on forecast type
    if forecast_type == "3hour":
        # Fetch 3-hour forecast data
        weather_data = fetch_3hour_data()
        if not weather_data:
            return error_display("3hr API Error")

        # Process 3-hour forecast
        forecast_data = process_3hour_forecast(weather_data, station)
        if not forecast_data:
            return error_display("3hr No Forecasts")
    else:
        # Fetch daily weather data
        weather_data = fetch_weather_data()
        if not weather_data:
            return error_display("Weather API Error")

        # Process daily forecast
        forecast_data = process_forecast(weather_data, station)

    # Render the display
    return render_weather(forecast_data, forecast_type, language)

def get_stations_list():
    """Get MeteoSwiss stations list.

    Returns:
        List of station dictionaries sorted alphabetically. Each entry contains
        "point_id", "point_name", "point_type_id", and "postal_code".
    """
    cache_key = "meteoschweiz_stations_list"
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    # Fetch stations CSV from MeteoSwiss OGD
    url = "https://data.geo.admin.ch/ch.meteoschweiz.ogd-local-forecasting/ogd-local-forcasting_meta_point.csv"

    # Cache the raw CSV response for 24 hours to avoid frequent rebuilds
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return []

    # Parse CSV and return stations
    lines = resp.body().split("\n")
    stations = []

    # Skip header and parse stations
    # CSV format: point_id;point_type_id;station_abbr;postal_code;point_name;...
    for line in lines[1:]:
        if not line:
            continue

        # Parse CSV line (semicolon-delimited)
        parts = line.split(CSV_DELIMITER)

        if len(parts) >= 5:
            point_id = parts[0]
            point_type_id = parts[1]
            postal_code = parts[3]
            point_name = parts[4]
            point_name = point_name.replace("�", "").replace("?", "")

            # Only use stations of type 2 or 3
            if point_type_id == "2" or point_type_id == "3":
                # For type 2, append postal code to name
                display_name = point_name
                if point_type_id == "2" and postal_code:
                    display_name = "%s / %s" % (point_name, postal_code)

                if point_id and display_name:
                    stations.append({
                        "point_id": point_id,
                        "point_name": display_name,
                        "point_type_id": point_type_id,
                        "postal_code": postal_code,
                    })

    # Sort stations alphabetically by point_name
    stations = sorted(stations, key = lambda s: s["point_name"])

    # Store parsed list for 24 hours in Pixlet cache
    cache.set(cache_key, json.encode(stations), ttl_seconds = 86400)

    return stations

def fetch_weather_data():
    """Fetch weather data from MeteoSwiss STAC API.

    Returns:
        Dictionary with temperature and symbol data for all stations, or None on error.
    """

    # Check cache first
    cache_key = "meteoschweiz_weather_all"
    cached = cache.get(cache_key)

    if cached:
        cached_data = json.decode(cached)
        cached_date = cached_data.get("date", "")

        # Get current date in YYYYMMDD format
        current_date = time.now().in_location("Europe/Zurich").format("20060102")

        # Return cached data if date matches
        if cached_date == current_date:
            return cached_data

    # First, get the list of available data
    stac_url = "https://data.geo.admin.ch/api/stac/v1/collections/ch.meteoschweiz.ogd-local-forecasting/items"

    resp = http.get(stac_url, ttl_seconds = 3600)
    if resp.status_code != 200:
        return None

    data = json.decode(resp.body())
    items = data.get("features", [])

    if not items:
        return None

    # Get the most recent item
    latest_item = items[0]
    date_str = latest_item.get("properties", {}).get("datetime", "")

    # Extract date in format YYYYMMDD
    if "T" in date_str:
        date_part = date_str.split("T")[0].replace("-", "")
    else:
        date_part = date_str.replace("-", "")

    # Construct base URL for data files
    base_url = "https://data.geo.admin.ch/ch.meteoschweiz.ogd-local-forecasting/{}-ch/".format(date_part)

    # Fetch temperature and weather symbol data for all stations
    tre_min_url = base_url + "vnut12.lssw.{}0000.tre200pn.csv".format(date_part)
    tre_max_url = base_url + "vnut12.lssw.{}0000.tre200px.csv".format(date_part)
    symbol_url = base_url + "vnut12.lssw.{}0000.jp2000d0.csv".format(date_part)

    tre_min_data = fetch_csv_data(tre_min_url, ttl_seconds = 3600)
    tre_max_data = fetch_csv_data(tre_max_url, ttl_seconds = 3600)
    symbols_data = fetch_csv_data(symbol_url, ttl_seconds = 3600)

    # Ensure we have data and extract values
    if not tre_min_data or not tre_max_data or not symbols_data:
        return None

    # Extract unique timestamps from any station data (all should have same timestamps)
    timestamps = []
    for station_id in tre_max_data:
        timestamps = sorted(list(tre_max_data[station_id].keys()))
        break

    weather_data = {
        "tre_min": tre_min_data,
        "tre_max": tre_max_data,
        "symbols": symbols_data,
        "timestamps": timestamps,
        "date": date_part,
    }

    # Cache for 6 hours (21600 seconds)
    cache.set(cache_key, json.encode(weather_data), ttl_seconds = 21600)

    return weather_data

def fetch_3hour_data():
    """Fetch 3-hour forecast data from MeteoSwiss STAC API.

    Returns:
        Dictionary with temperature, symbol, and precipitation data for all stations, or None on error.
    """

    # Check cache first
    cache_key = "meteoschweiz_3hour_all"
    cached = cache.get(cache_key)

    if cached:
        cached_data = json.decode(cached)
        cached_date = cached_data.get("date", "")

        # Get current date in YYYYMMDD format
        current_date = time.now().in_location("Europe/Zurich").format("20060102")

        # Return cached data if date matches
        if cached_date == current_date:
            return cached_data

    # First, get the list of available data
    stac_url = "https://data.geo.admin.ch/api/stac/v1/collections/ch.meteoschweiz.ogd-local-forecasting/items"

    resp = http.get(stac_url, ttl_seconds = 3600)
    if resp.status_code != 200:
        return None

    data = json.decode(resp.body())
    items = data.get("features", [])

    if not items:
        return None

    # Get the most recent item
    latest_item = items[0]
    date_str = latest_item.get("properties", {}).get("datetime", "")

    # Extract date in format YYYYMMDD
    if "T" in date_str:
        date_part = date_str.split("T")[0].replace("-", "")
    else:
        date_part = date_str.replace("-", "")

    # Construct base URL for data files
    base_url = "https://data.geo.admin.ch/ch.meteoschweiz.ogd-local-forecasting/{}-ch/".format(date_part)

    # Fetch 3-hour data: temperature, weather symbol, and precipitation
    tre_url = base_url + "vnut12.lssw.{}0000.tre200h0.csv".format(date_part)
    symbol_url = base_url + "vnut12.lssw.{}0000.jww003i0.csv".format(date_part)
    precip_url = base_url + "vnut12.lssw.{}0000.rre003i0.csv".format(date_part)

    temperature_data = fetch_csv_data(tre_url, ttl_seconds = 600)
    symbols_data = fetch_csv_data(symbol_url, ttl_seconds = 600)
    precipitation_data = fetch_csv_data(precip_url, ttl_seconds = 600)

    # Ensure we have data with proper structure
    if not temperature_data or not symbols_data or not precipitation_data:
        return None

    # Extract unique timestamps from any station data (all should have same timestamps)
    timestamps = []
    for station_id in temperature_data:
        timestamps = sorted(list(temperature_data[station_id].keys()))
        break

    weather_data = {
        "temperature": temperature_data,
        "symbols": symbols_data,
        "precipitation": precipitation_data,
        "timestamps": timestamps,
        "date": date_part,
    }

    # Cache for 1 hour (3600 seconds) since 3-hour data updates more frequently
    cache.set(cache_key, json.encode(weather_data), ttl_seconds = 3600)

    return weather_data

def fetch_csv_data(url, ttl_seconds = 21600):
    """Fetch large CSV data in chunks to avoid caching issues.

    Downloads the file in 1MB chunks using HTTP Range requests, processing each
    chunk immediately to extract station data without loading the entire file.

    Args:
        url: URL to CSV file.
        ttl_seconds: Cache time-to-live in seconds (default 6 hours).

    Returns:
        A dictionary mapping point_id to a dictionary of {timestamp: value} pairs.
    """

    # Check cache first
    cache_key = "meteoschweiz_csv_{}".format(url)
    cached = cache.get(cache_key)
    if cached:
        print("Using cached CSV data for URL: {}".format(url))
        return json.decode(cached)

    print("Fetching CSV data from URL: {}".format(url))

    CHUNK_SIZE = 1024 * 1024  # 1MB chunks
    MAX_CHUNKS = 40  # Support files up to ~40MB
    station_data = {}
    leftover = ""

    # Download and process in chunks
    for chunk_num in range(MAX_CHUNKS):
        chunk_start = chunk_num * CHUNK_SIZE
        chunk_end = chunk_start + CHUNK_SIZE - 1

        # Request this chunk with Range header
        headers = {"Range": "bytes={}-{}".format(chunk_start, chunk_end)}
        resp = http.get(url, headers = headers, ttl_seconds = 600)

        # Check response - 206 is Partial Content
        if resp.status_code == 206:
            # Partial content received - process it
            chunk_data = resp.body()

            # Combine with leftover from previous chunk
            data = leftover + chunk_data

            # Split into lines
            lines = data.split("\n")

            # Save the last incomplete line for next chunk
            leftover = lines[-1]
            lines = lines[:-1]

            # On first chunk, extract and skip header
            if chunk_num == 0 and len(lines) > 0:
                # Skip header line
                lines = lines[1:]

            # Process lines in this chunk
            for line in lines:
                if not line:
                    continue

                parts = line.split(CSV_DELIMITER)
                if len(parts) >= 4:
                    point_id = parts[0]
                    timestamp = parts[2]  # Date column in YYYYMMDDHHMM format
                    val = parts[3]

                    if point_id:
                        # Store data for this station with timestamp as key
                        if point_id not in station_data:
                            station_data[point_id] = {}
                        station_data[point_id][timestamp] = float(val) if val and val != "-" else 0

            # Check if we got less than requested (end of file)
            if len(chunk_data) < CHUNK_SIZE:
                # Process any remaining leftover
                if leftover.strip():
                    parts = leftover.split(CSV_DELIMITER)
                    if len(parts) >= 4:
                        point_id = parts[0]
                        timestamp = parts[2]
                        val = parts[3]
                        if point_id:
                            if point_id not in station_data:
                                station_data[point_id] = {}
                            station_data[point_id][timestamp] = float(val) if val and val != "-" else 0
                break
        elif resp.status_code == 416:
            # Range not satisfiable - we've read past the end
            break
        else:
            # Some other error
            if chunk_num == 0:
                return {}

    # Cache the result
    cache.set(cache_key, json.encode(station_data), ttl_seconds = ttl_seconds)
    return station_data

def process_forecast(weather_data, station):
    """Process MeteoSwiss forecast data into daily forecasts.

    Args:
        weather_data: Dictionary with temperature and symbol data for all stations.
        station: Station dictionary with metadata.

    Returns:
        List of daily forecast dictionaries.
    """
    daily_data = []

    # Get station point_id
    station_point_id = station.get("value", "")
    if not station_point_id:
        return daily_data

    # Extract data for all stations
    tre_min_all = weather_data.get("tre_min", {})
    tre_max_all = weather_data.get("tre_max", {})
    symbols_all = weather_data.get("symbols", {})
    timestamps = weather_data.get("timestamps", [])

    # Filter for the specific station
    tre_min = tre_min_all.get(station_point_id, {})
    tre_max = tre_max_all.get(station_point_id, {})
    symbols = symbols_all.get(station_point_id, {})

    # Process up to 3 days using timestamps
    for i in range(min(3, len(timestamps))):
        timestamp_key = timestamps[i]

        # Get values for this timestamp
        high_val = tre_max.get(timestamp_key, 0)
        low_val = tre_min.get(timestamp_key, 0)
        symbol_code = int(symbols.get(timestamp_key, 1))

        # Parse timestamp to create date
        if len(timestamp_key) >= 8:
            year = int(timestamp_key[0:4])
            month = int(timestamp_key[4:6])
            day = int(timestamp_key[6:8])
            day_time = time.time(year = year, month = month, day = day, location = "Europe/Zurich")
        else:
            day_time = time.now().in_location("Europe/Zurich")

        daily_data.append({
            "high": high_val,
            "low": low_val,
            "symbol": symbol_code,
            "date": day_time,
        })

    return daily_data

def process_3hour_forecast(weather_data, station):
    """Process MeteoSwiss 3-hour forecast data.

    Args:
        weather_data: Dictionary with temperature, symbol, and precipitation data for all stations.
        station: Station dictionary with metadata.

    Returns:
        List of 3-hour forecast dictionaries (3 intervals).
    """
    forecast_data = []

    # Get station point_id
    station_point_id = station.get("value", "")
    if not station_point_id:
        return forecast_data

    # Extract data for all stations
    temperature_all = weather_data.get("temperature", {})
    symbols_all = weather_data.get("symbols", {})
    precipitation_all = weather_data.get("precipitation", {})
    timestamps = weather_data.get("timestamps", [])

    # Filter for the specific station
    temperatures = temperature_all.get(station_point_id, {})
    symbols = symbols_all.get(station_point_id, {})
    precipitation = precipitation_all.get(station_point_id, {})

    # Filter timestamps to 3-hour intervals (00, 03, 06, 09, 12, 15, 18, 21)
    # The data is hourly, so we need to select only 3-hour intervals
    three_hour_timestamps = []
    for ts in timestamps:
        if len(ts) >= 12:
            hour = int(ts[8:10])

            # Include timestamps at 3-hour intervals
            if hour % 3 == 0:
                three_hour_timestamps.append(ts)

    # Show next 3 forecast intervals at/after current local time
    now_str = time.now().in_location("Europe/Zurich").format("200601021504")

    # Find the first timestamp that is at or after now
    start_pos = 0
    for pos, ts in enumerate(three_hour_timestamps):
        if len(ts) >= 12 and ts >= now_str:
            start_pos = pos
            break

    # Collect up to 3 intervals starting from start_pos
    selected_timestamps = three_hour_timestamps[start_pos:start_pos + 3]
    for timestamp_str in selected_timestamps:
        # Parse timestamp from CSV (format: YYYYMMDDHHMM)
        if len(timestamp_str) >= 12:
            year = int(timestamp_str[0:4])
            month = int(timestamp_str[4:6])
            day = int(timestamp_str[6:8])
            hour = int(timestamp_str[8:10])
            minute = int(timestamp_str[10:12])

            # Create time object from CSV timestamp
            forecast_time = time.time(year = year, month = month, day = day, hour = hour, minute = minute, location = "Europe/Zurich")

            symbol_code = int(symbols.get(timestamp_str, 1))
            temp = temperatures.get(timestamp_str, 0)
            precip = precipitation.get(timestamp_str, 0)

            forecast_data.append({
                "temperature": temp,
                "symbol": symbol_code,
                "precipitation": precip,
                "time": forecast_time,
                "is_3hour": True,
            })

    return forecast_data

def render_weather(daily_data, forecast_type, language):
    """Render weather forecast display (3-day or 3-hour view).

    Args:
        daily_data: List of forecast dictionaries (daily or 3-hour).
        forecast_type: Type of forecast ("daily" or "3hour").
        language: Translate day abbreviations to EN, DE, FR, or IT.

    Returns:
        Rendered display root widget.
    """
    if not daily_data:
        return error_display("No Data")

    FONT = "CG-pixel-3x5-mono"
    DIVIDER_WIDTH = 1

    columns = []
    is_3hour = forecast_type == "3hour"

    for i, day in enumerate(daily_data):
        # Get weather icon using symbol code directly
        symbol_code = day.get("symbol", 1)
        weather_icon_src = WEATHER_IMAGES.get(symbol_code, IMG_ERROR)

        # Build column children based on forecast type
        if is_3hour:
            # 3-hour forecast: show time and temperature
            time_str = day["time"].format("15:04")
            temp = int(day.get("temperature", 0))
            precip = day.get("precipitation", 0)

            # Format precipitation as accumulation/intensity in mm over the interval
            # Starlark's % formatting does not support precision like %.1f.
            # Use %s and show a space with unit.
            precip_str = "%smm" % precip

            children = [
                # Weather icon
                render.Image(
                    src = weather_icon_src,
                    width = 12,
                    height = 12,
                ),
                # Time
                render.Text(
                    time_str,
                    font = FONT,
                    color = "#FFF",
                ),
                # Temperature with custom degree symbol
                render.Row(
                    children = [
                        render.Text(
                            "%d" % temp,
                            font = FONT,
                            color = "#FFF",
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Circle(
                                diameter = 2,
                                color = "#FFF",
                            ),
                        ),
                    ],
                ),
                # Precipitation percentage
                render.Text(
                    precip_str,
                    font = FONT,
                    color = "#08F",
                ),
            ]
        else:
            # Daily forecast: show day abbreviation and high/low temps
            day_abbr = day["date"].format("Mon")[:3].upper()
            day_abbrs = DAY_ABBREVIATIONS.get(day_abbr)

            children = [
                # Weather icon
                render.Image(
                    src = weather_icon_src,
                    width = 12,
                    height = 12,
                ),
                # Day abbreviation
                render.Text(
                    day_abbrs[language],
                    font = FONT,
                    color = "#08F",
                ),
                render.Row(
                    children = [
                        # High temp
                        render.Text(
                            "%d" % int(day["high"]),
                            font = FONT,
                            color = "#FFF",
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Circle(
                                diameter = 2,
                                color = "#FFF",
                            ),
                        ),
                    ],
                ),
                # Low temp
                render.Row(
                    children = [
                        render.Text(
                            "%d" % int(day["low"]),
                            font = FONT,
                            color = "#888",
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Circle(
                                diameter = 2,
                                color = "#FFF",
                            ),
                        ),
                    ],
                ),
            ]

        # Create column
        day_column = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = children,
        )

        columns.append(day_column)

        # Add divider if not last column
        if i < 2:
            columns.append(
                render.Box(
                    width = DIVIDER_WIDTH,
                    height = HEIGHT,
                    color = "#444",
                ),
            )

    # Create display
    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    width = WIDTH,
                    height = HEIGHT,
                    color = "#000",
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = columns,
                ),
            ],
        ),
    )

def error_display(message):
    """Display error message on screen.

    Args:
        message: Error message to display.

    Returns:
        Rendered error display widget.
    """

    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    width = 20,
                    height = HEIGHT,
                    color = "#000",
                    child = render.Image(
                        src = IMG_ERROR,
                        width = 16,
                        height = 16,
                    ),
                ),
                render.Box(
                    padding = 0,
                    width = WIDTH - 20,
                    height = HEIGHT,
                    child =
                        render.WrappedText(
                            content = message,
                            color = "#FFF",
                            font = "CG-pixel-4x5-mono",
                        ),
                ),
            ],
        ),
    )

def search_station(pattern):
    """Search stations matching a pattern.

    Args:
        pattern: Case-insensitive substring to match against station display name.

    Returns:
        List of `schema.Option` entries for the typeahead handler. If none are
        found, returns a single option indicating no stations were found.
    """
    stations_list = get_stations_list()
    pattern_l = pattern.lower()

    options = []
    for s in stations_list:
        name = s.get("point_name", "")
        pid = s.get("point_id", "")
        if not name or not pid:
            continue
        if pattern_l in name.lower():
            options.append(schema.Option(
                display = "%s (%s)" % (name, pid),
                value = pid,
            ))

    if not options:
        return [
            schema.Option(
                display = "No stations found",
                value = "0",
            ),
        ]

    return options

def get_schema():
    """Define the app configuration schema.

    Returns:
        Schema object with configuration fields.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station",
                name = "Location",
                desc = "MeteoSwiss location for which to display the weather forecast",
                icon = "locationDot",
                handler = search_station,
            ),
            schema.Dropdown(
                id = "lang_type",
                name = "Language",
                desc = "Choose your preferred day abbreviation language",
                icon = "language",
                default = "0",
                options = [
                    schema.Option(
                        display = "🇬🇧 EN",
                        value = "0",
                    ),
                    schema.Option(
                        display = "🇩🇪 DE",
                        value = "1",
                    ),
                    schema.Option(
                        display = "🇫🇷 FR",
                        value = "2",
                    ),
                    schema.Option(
                        display = "🇮🇹 IT",
                        value = "3",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "forecast_type",
                name = "Forecast Type",
                desc = "Choose between daily forecast (3 days) or 3-hour intervals (9 hours)",
                icon = "clock",
                default = "daily",
                options = [
                    schema.Option(
                        display = "Daily (3 days)",
                        value = "daily",
                    ),
                    schema.Option(
                        display = "3-Hour Intervals (9 hours)",
                        value = "3hour",
                    ),
                ],
            ),
        ],
    )
