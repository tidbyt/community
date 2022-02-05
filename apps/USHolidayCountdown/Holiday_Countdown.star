"""
Applet: US Holiday Countdown
Summary: Countdown to Nearest USA Holiday
Description: Counts down days to nearest holiday for USA.
Author: Alex Miller
"""

load("render.star", "render")
load("time.star", "time")
load("encoding/base64.star", "base64")

def main(config):


    #Encode Images
    CTree1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAX1JREFUSEvFljFOBDEMRe0DQDccAo4w9FCAtFNQb4e4AeIEiBsguq0pZiW2gJ49AhyC6eAARg7rkSdKYgdYSJOVZsb/+dvxBqFiEREhIvInNLSEzRplrwgzeTUEk6UFPAF/Ks4aE4CcaAqMxU+fG3g4HICdCK4QUQi6ccmThAsgFeiknwWxVbfMxvAAYa3tLCriAlaCEGdiV0S3SJ+yUsRvuiVc9rPRHAsiV47qEsTZ68DfgRgBPKUoiVv9YDqQ7HR17nXtY/trXdBa7hLkst/r7uCtP58kWFOKIoAmteyvdUHedzmgxXnw8AAqrdiBUn+ZAN7MYzBvGcYRWjrznpGaescDUXRAsk81mhaMn8spiQFeAML4PgBA+Z0FsKz39EI8G1hUxGXHnaMFvXdz2O0XIamPpzla4rUl0U4wxP7QwmuzBt6TAJbA1dlxsFKv6/tHs6HDH9PQTr5Fuv2qy3guL+w7wq8CpErwtw5sbjGW6LaehwvJtoJ74v47wCccbO9E0vBuoAAAAABJRU5ErkJggg==")
    CTree2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAW1JREFUSEvlVjFywkAMlB4AnYt8AZ4AfVLEM3aRMkObL+QFfCEtkzKFPeMU0IcnwBdSuCMPuIzMiBEXne6MSZpcc4zFaVe70tkIynLOOURELcbPXDtzmG2Rd+u/VswEoYMWmaHglL8jYIIE1CDw/CODZt4CKRHLE1IhqkDo4H1VOIq9l7WaQytKe3YRAQZnciESKX2RzJ6T+eBDSSR5J6WTBHafrzC9eTwV2kcJztnLglD1MRWsJrdn3ZuAGAGrKQdPgQRvigryugz2WB8rki1IqV6zIjaOPwhoBxh8UjSwr/NT5VIJGbuqAn0ql56kkjgbQ7/6S8FjUyGJmj1gEfDtkEnZGl+FHUB3fU8BkH8HCVgXjtb+/qWkqUCgDM47jm5X7lAuYFytujNfmwUOld4nKJUgEpN2BvtsC7SrBGIvkeeHu05KuZZv66SRptf4WQ+4l6MvvPDp+I1grasS0Cz4UwI0ejHA34zjvyfwDalo90Q3Q145AAAAAElFTkSuQmCC")
    HPUMP1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAR5JREFUSEvVlrENwkAMRXMSjMA0WQDRU7MEDRNQwBLULECPMg0jgBRkJCPHsX3fAQmRMvH5P3/fOVea5NPf2r4suiKX7dbLfn++DN6haVOLSJwTM0QkbsFqsBQALZZJSZzeWdVbsJYrIwCEmoVlQg9Ctyt0oEZ9PzbvFng9nm+blKuQA4iwBkJBQtopwlkQF0CLzzbtK/fj1IUnzIqL3DABrMo/ASBiD2IEEIlz6Z4LDOnFWRADAK/ntcQsiMRpCAgAHatI3H8BaEtlb+U3uSdqbUg74EEgdlvHNgSgBcgp+JY45YHngBRFXNFHFZ4DLISOYW8vSOD0JMxCRC2p/ZSgXyfqBlq1jIMAMo7UKh5dSA7XVfWSge76KXHl1wBPawGZRixYGQ8AAAAASUVORK5CYII=")
    HPUMP2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAARtJREFUSEvVlr0NwkAMhXNFRmAaFkD0bJKGCSjIJixAj5iGEVIEHXCR4/jn+YKEoOQcvy/PZzupAX/jYzumzT1J4cfDbjxdruKZlx56KIuXRBxijXjOCQHkQMmBLJ7Pom9Pc8EA1MoiTP9DIbibLwCrvlRk6JupFFpt2853deaAVd8igghzIARkugOaAzXCURD1DnDxtnunHnq7saQ4yw0RQHrzNQAZWYNYAFji5E6INhRILU6CmAFoNfcSF0EkjkNAAN44jZz/FwC3lNaWntHO8MoQdkCDQG3nbWsCfPp8MW5rITxxdRt6ExABQsTNdexBSK2nTcnwJFyzhL62C6JrOCpc4kMfJEhZ0DU8AZxve/cjA225mrj0a4An1KaKRqV6EnYAAAAASUVORK5CYII=")
    FourJ1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAOFJREFUSEtjZBhgwEgN+98KC/8HmSP89i3J5pGsAdnB/19b/3+ncQMuRJEDEmq7/689JYYRICd2xmMNJG0GBrDjYY4g1nL00IKHAC4HfNoRh9UBjIyMcL0gRzCKHiUqNGEOABkqdEMD4gsQIDcEyElDIEeALRc9ivAFJSFAqiOQQ2xAQgDZwSgOmN9UQrRnkNMA0ZqwKERxQGlzKdFmwXIBugZSywQUByxoLiUqJWNzJbllAtUcQE6ZANJDVQfAHEFsmUATBxCdiKAKqR4Cow4YDYHREBh6IdB92AvcoBwoAACp8pPTED4QrgAAAABJRU5ErkJggg==")
    FourJ2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAZNJREFUSEvtlrFKA0EQhncVFAQtrbTRTp8hL2AeQKtooW/glSKaMq8Q0DJNSkHrNGKtdql8gxRCBBmZxX9vdrKX7N2mTKrM3Gz+b/+ZOWJNzQ+dHlBwZDD2obXW+ueDseH4w0xd/RFtuBjFyPtEKgcRlQBnh+UxBkH8DwVBiGkQztcGkKAORkLwQyXOKa77tD/+KLvBsXMF2YubHg3fdmeMeH05j5pzbExgdwCi2lIFwQ4tBJg8d+LdEXa73qM1wpGrzru5bW2a/Z11pyOdwEwsBJjrABGx+Nfk180FhPg75+5GUw+gxZNbUOWAdO/y6dsB4LYQlzm9DTNb0GQG0JuYIEMx0N72WjlwouVwJGjBw/116jYGO60tZ+txe/mDnO+3t4LNCwCKbpEMwFugi9EKzrOQjFE7F+CxWzR+L2AQcfsqQQ0dONAUQM4ArJdtkNuxdIDYAMqZkJsQ62+WA1Xise3QvUdNFoDe/9gNYy8pWZcNIF+1ySskCrMAmggufQhzIVYOrBywvdFJ+C83d6pqnv8D0cov6k2tTNMAAAAASUVORK5CYII=")
    Jan1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAOZJREFUSEvNltENhCAMhstsvtwC7nAruIC3wu1wC7gdlxJrEEsF2ib6ImlN/4+fAgaoPxEAwp6mMb7zB/M9MaqHNVLNPFCi1ApzUC2xQ5TEMXAHYOkATTB3dghAmi0rUljbDCC0h11KWgI7FaHSswHiF2J4i32idkl0AAHSVnGEqAKQ+OnUcQDpAvBwoxuAHLFaFhaAs5/rNgsIFYDFkqgBtBDPA2hdf+3Mj2a+/ATsh490xFk03xCApTALULPfQ7gJwFOYBVjmV1ynLV0+OM774PPbTjsG82Vs5Gq8FOVESxj6xgLgD6OGWxhGeMP6AAAAAElFTkSuQmCC")
    Jan2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAfhJREFUSEutVjFuwzAMpJA1a+f+IkvGLP1A0a1zXlAg6NwWyAs6dwv6gSwZu+QXnbN6NVRQEYXjWXZiN15sWaR4Io8nBRGJIhLk/Ni3vvHRebRLts1qIfPD0XzlJc7iNrRljAvE0zKGu59gb5uzhXWMQVywZrWI88PRbMy3CsAma0AYhALmoAikgCQAmKWQ59yuZ7smtk/z9O/1/iu+/T6nb/1vi+q8A5DRcSZcFvOAs+ZqZUFqAKisaZgWi6elaH3GckD9SprO/qOfKU4dMgJ/mLhGbOQPEjwUAFortbJ6IVsprUMA0nrKC30TcR13MtJEQvdo4ARXW+ZTYlhLQFKZIzhhC5eKVOyQX8VusAQKIHmti04wKdGfM2Ppr2lM4VtpD2OtRbDgrqgeSAqoraQ229ByMlm8hkvA7VMDMJCN0eznWnUW6ANQHHM2EHhNiiFDHWHC1vBEzLW/tC3mRt9ZgCC42+oHx5UAsCS8U5boPnAJADtfSn+HbdQloAOuS2a7RpjsBQCeXrcAkI9pd9QjABO6rhBNSH8PV5zk4n0CxW4SgB5hquGoXXac3SgA1wTG3bHKw82rTDkAU8UHLx14iBkZNRpe3Zy6OnGn+l+zYwx+STdw3vxcBjaPD/F9tU+Hj36jw8f3vmPL/24CoBaUwZjNfwDYGn+PuEoT4q/hKAAAAABJRU5ErkJggg==")
    Easter1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAVpJREFUSEvFljFuwkAQRWcipUTiBhHp6GipUBqqFEiJJV8BCkpqKiTS0MEVIhEpPU3OkDZNSlokDmA0FjMaD95lQWt7Gq9Xsv/bP3/Xxs76mEHF9TUcOhUwFoAVed/tRLQWAJ+JjQCQKLtQOwAL1g6gV6ozQO1xuRAthCxSFj6fE1EBbBB1DlwhrQzAirtyUSuAbQ/dewH+Jy3orI/A13sPTLt6nRcnAIlmH3PA2VyuBBOjdHsaAdCLaB4AAORrqC3OW5AVP5SImGciZiEBsBAJcFlxnr8VIv1J5J2fL9sL9gKA87BAFDduASBxLWrvSS8IoBCawDY89vbwtprmAMm4DdvNAQhg8fAHz4NfeWUewrJ++9y4lgMS5xr1uzJepk8yZggnACKihOP8WKj9uu+uhXBrZBtaF2wgQ8VZ0Aehc1E4BwiCi20umwvdhmUQdifg6/eo8r9iH/AJSZrpqOAnWicAAAAASUVORK5CYII=")
    Easter2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAWBJREFUSEtjVJz2+T8DjcEaNzecNjBS0wHoFoXs2gW2mG4OwOXNAXMAyGJQKAyIA2CWDogDkC2HRQuuUKBqIkROcLAECBPDFRJUdwB6QsQWGshqaOoAWCJEthA5YYJCha4OQHcQiI/XAfezeBkUp31mgNGUFpgkOQBk6f+uBgbGsgY4DXIMJWDQOQDkGZxRQIsQwBZ6jAwMDPDaEDmIwQ74j1pRMjIygtMENQHYATCLQBbAALrlMHFSHRGxPxRu5grH1RhuR3EALp+BLEV2JLGhALIc2VJ0PjgNIIcAMUFLbAjc2xPPUMX8DewAzbqZDNeb0hlADmjL2c+gdPUN3CpwIsQW3/hCg1AIgCyHAe9DVnD21rXVcDbMETgdwMjIyAhPHFBtxPoeOd5xeQQWNfBsiB4K6AmSWMthFuJzBHK6QCkHQI6AAVgwYxMjJq2A1GBzBHpOYPRZH0DzVjE+BwMAcR/xGL02ZuEAAAAASUVORK5CYII=")
    Thanks1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAeFJREFUSEtjZICA/1CaEUpjE4OpAcnB1OESQzYH2SyY8XB5EANkCDYNyJagq4PpQdaLTQxmITY7wHLIBiOHAi6D0X1ATgigeJZcn1E1BGiRBpCSEjyU0cXgUYAsQXc2euIbUg5AToAY2YtYn1ASAgPjgMpQD7DFzzWcwZ6cn7eBIXFSAJgteWMvmG5fvYNojxGtEGQwzPL21TtwhnBlqAdJjiDaATDLzxzYBbd8wut/DHorv4D5Tjl8cHETBzeiHUGUA7BZDrIB5ABtBgYG5pVfUBwAkiPWEUQ7ANnnMK8ih8CfdXpgYbd9D1BCglB6oKoDkC2HhQJNHAAL3hikxLgEmviQQwqkjuoOgFkOskhC25Sh4sBJcJAXiDLB4x3EB8ljc8DZO5bgbGyschwc+kRFAXIWhBkOokEOAAGQI0AOgAFsCdBnfcD/LYEbGJEdABJDcQAoteMLMldRJnjpB7NcRlSQ4cnr92C7X1w9DXfE7tf/MDwHsrBR9yVYTf1lcQaQg+CKCFkOMxnkCGTLYeLIjsBmOUgdyAGbbV6DtfgeEUU44P8MeJuQgTEDf7T87mH4z1rCwIgcGjBHgCyGycODAolBsQNAhsPMAzkC3RJC8rBQANGg4AcnQpCrsLmWXmIAYKfyrMUe/3IAAAAASUVORK5CYII=")
    Thanks2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAfRJREFUSEvVlL9LQzEQxy8VV8HhgYJ/QKHSSZ1FsXRwqEM3l3YWcRCxf0FBHMQ/oF1cSkE7OBRF6eqP0UJHB0Ghg0s3pZEL7+K9JK+m2lLMkpe75L6fu1yegAkPEerLcKY1Lk0brdFnnjNtPA6PRelqP35gYNcBLmLuozP8rMtGgi4N5eOBecZxgc0M4qoyqAIR328zG2kFXPf91x7grU1JmjZ9BRN9B+ZdDQPD79/qbt9A/w+glM+qzF+T6yrJ6m4DCqc59T3fuVFzud70Tsx7IwYm8XK9GVvhUj47FIQ3AIk/tq60+Em3D+laT63Xdma0fWk14w3hBeASRwUESAHAVK0XAUCfL4Q3AM+cUuUV+DxPK3Pm9jlSiZ/6YaQAXJyqMBYAKu82a8azsPl4pXAfAUgppRBCJ0zrSAVYl1t2CkziuJ5LLcNh606VfC9I6HvHNfo5ANpIlMNYQnElIzgKjjMC4EAIBKBhNqCZPYdRAJsXOeu3ernVsPpjI0jofSS+EMzCS/ddab+1HzTEdbcfOc8hrAq0ASQ+pzaAelbh7GxQhODipMghLPH7pJWgWOmo+FrEgIh9HR/HIKf3QfBqEAQKk59slUpFFhaPdGXoo/p0AMVi8bsr0RFCDBSnAAhhRkVx048AlnpoUACu+487MA77F6E3AXGamYnSAAAAAElFTkSuQmCC")
    VDAY1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAJZJREFUSEvtlEEOwCAIBPE9/f9T+p42HEgNKbogxjbRMzLjqhRavMpiPm2BncA/EjiJLuu3HPQ8ZLSu7tVNoNVUGrEEWqcP0hRAmnrnSJ0Y7/22ABtmpqBP300gU+ANDglkSFhwWGBEogV3CUQkevCpAgjcLeBJYZoAIoHCQwnI5LPmgweeLuCFDwnoq4jAhwVEIgrn/TeEqiQYJ8YpqQAAAABJRU5ErkJggg==")
    VDAY2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAYAAABqBU3hAAAAAXNSR0IArs4c6QAAAKBJREFUSEvtlTcSwCAMBOGLPJQv4lEBY2yUCQ306HYU7mI4/OJh/YAClJQKBhdznvavK0SJUjDWf1CzAViKeMcHnbwAtwPuK/AsYreEtdCua6he8jOUHQBvIxs62kqIr4uaLNU695GFk2E0sxNYfrBpOAOCCi8WANrthXADeCAo8S4NJYul7QQnvhRAIq4GkI5CKm4C4CA04mYADEIrDnUeUatcGGDtNAEAAAAASUVORK5CYII=")


    #Find todays date for holiday countdowns
    Today = time.now().in_location("America/Chicago")

    Xmas = time.time(year = time.now().year, month = 12, day = 26).in_location("America/Chicago") 
    XDAYS = int((Xmas - Today).hours // 24)
    HWEEN = time.time(year = time.now().year, month = 11, day = 1).in_location("America/Chicago")
    HDAYS = int((HWEEN - Today).hours // 24)
    NEWYEAR = time.time(year = time.now().year, month = 1, day = 2).in_location("America/Chicago")
    NDAYS = int((NEWYEAR - Today).hours // 24)
    Fourth = time.time(year = time.now().year, month = 7, day = 5).in_location("America/Chicago")
    FDAYS = int((Fourth - Today).hours // 24)
    Valentine = time.time(year = time.now().year, month = 2, day = 15).in_location("America/Chicago")
    VDAYS = int((Valentine - Today).hours // 24)

    #Find out what weekday the month starts on to tell when holiday is
    First_of_Nov = time.time(year = time.now().year, month = 11, day = 1).in_location("America/Chicago")
    Day_Of_Week_Nov = First_of_Nov.format('Monday')
    
    First_of_Apr = time.time(year = time.now().year, month = 4, day = 1).in_location("America/Chicago")
    Day_of_Week_Apr = First_of_Apr.format('Monday')

    if Day_Of_Week_Nov == 'Sunday' :
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 26)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 23)
        TGIVE = time.time(year = time.now().year, month = 11, day = 26).in_location("America/Chicago")
        Easter = time.time(year = time.now().year, month = 4, day = 23).in_location("America/Chicago")

    elif Day_Of_Week_Nov == 'Monday' :
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 25)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 22)
        TGIVE = time.time(year = time.now().year, month = 11, day = 25).in_location("America/Chicago")
        Easter = time.time(year = time.now().year, month = 4, day = 22).in_location("America/Chicago")

    elif Day_Of_Week_Nov == 'Tuesday' :
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 24)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 21)
        TGIVE = time.time(year = time.now().year, month = 11, day = 24).in_location("America/Chicago")
        Easter = time.time(year = time.now().year, month = 4, day = 21).in_location("America/Chicago")

    elif Day_Of_Week_Nov == 'Wednesday' :
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 23)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 20)
        TGIVE = time.time(year = time.now().year, month = 11, day = 23).in_location("America/Chicago")
        Easter = time.time(year = time.now().year, month = 4, day = 20).in_location("America/Chicago")

    elif Day_Of_Week_Nov == 'Thursday' :
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 22)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 19)
        TGIVE = time.time(year = time.now().year, month = 11, day = 22).in_location("America/Chicago")
        Easter = time.time(year = time.now().year, month = 4, day = 19).in_location("America/Chicago")

    elif Day_Of_Week_Nov == 'Friday' :
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 21)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 18)
        TGIVE = time.time(year = time.now().year, month = 11, day = 21).in_location("America/Chicago")
        Easter = time.time(year = time.now().year, month = 4, day = 18).in_location("America/Chicago")

    else:  
        TDAYS = int(((First_of_Nov - Today).hours // 24) + 20)
        EDAYS = int(((First_of_Apr - Today).hours // 24) + 17)
        TGIVE = time.time(year = time.now().year, month = 11, day = 20).in_location("America/Chicago")   
        Easter = time.time(year = time.now().year, month = 4, day = 17).in_location("America/Chicago")


        #Determine What Holiday It is
    if Today <= Valentine and Today >= NEWYEAR :
        DAY_TEXT = "VALENTINES"
        DAYS_UNTIL = VDAYS
        IMAGE1 = VDAY1 
        IMAGE2 = VDAY2   
    
    elif Today <= Easter and Today >= Valentine :
        DAY_TEXT = "EASTER"
        DAYS_UNTIL = EDAYS
        IMAGE1 = Easter1 
        IMAGE2 = Easter2    
    
    elif Today <= Fourth and Today >= Easter :
        DAY_TEXT = "4TH OF JULY"
        DAYS_UNTIL = FDAYS
        IMAGE1 = FourJ1 
        IMAGE2 = FourJ2

    elif Today <= HWEEN and Today >= Fourth :
        DAY_TEXT = "HALLOWEEN"
        DAYS_UNTIL = HDAYS
        IMAGE1 = HPUMP1 
        IMAGE2 = HPUMP2

    elif Today <= TGIVE and Today >= HWEEN :
        DAY_TEXT = "THANKSGIVING"
        IMAGE1 = Thanks1 
        IMAGE2 = Thanks2
        DAYS_UNTIL = TDAYS        

    elif Today <= Xmas and Today >= TGIVE :
        DAY_TEXT = "CHRISTMAS"
        DAYS_UNTIL = XDAYS
        IMAGE1 = CTree1 
        IMAGE2 = CTree2   

    else:
        DAY_TEXT = "NEW YEARS"
        DAYS_UNTIL = NDAYS
        IMAGE1 = Jan1 
        IMAGE2 = Jan2 

    return render.Root(
        delay = 1000,
        child = render.Column(
            children=[
                render.Row(
                    cross_align= "center",
                    children=[
                        render.Text(DAY_TEXT),
                    ],
                ),
                render.Box(width=64, height=1, color="#a00"),
                render.Row(
                    children=[
                        render.Animation(
                            children=[
                                #32x23
                                render.Image(src=IMAGE1),
                                render.Image(src=IMAGE2),
                            ],
                        ),
                        render.Column(
                            children=[
                                render.Box(width=1, height=3),
                                render.Text(" " + str(DAYS_UNTIL), font ="Dina_r400-6"),
                                render.Text("    Days"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )