"""
Applet: CycleCast
Summary: Weather Data for Cyclists
Description: Displays weather data important for cyclists.
Author: Robert Ison
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

SAMPLE_DATA = """{"latitude":28.375,"longitude":81.25,"generationtime_ms":0.091552734375,"utc_offset_seconds":-14400,"timezone":"America/New_York","timezone_abbreviation":"GMT-4","elevation":167.0,"hourly_units":{"time":"iso8601","temperature_2m":"°F","wind_speed_10m":"mp/h","rain":"mm","wind_gusts_10m":"mp/h","uv_index":"","showers":"mm","apparent_temperature":"°F","precipitation_probability":"%","relative_humidity_2m":"%","cloud_cover":"%"},"hourly":{"time":["2025-04-14T00:00","2025-04-14T01:00","2025-04-14T02:00","2025-04-14T03:00","2025-04-14T04:00","2025-04-14T05:00","2025-04-14T06:00","2025-04-14T07:00","2025-04-14T08:00","2025-04-14T09:00","2025-04-14T10:00","2025-04-14T11:00","2025-04-14T12:00","2025-04-14T13:00","2025-04-14T14:00","2025-04-14T15:00","2025-04-14T16:00","2025-04-14T17:00","2025-04-14T18:00","2025-04-14T19:00","2025-04-14T20:00","2025-04-14T21:00","2025-04-14T22:00","2025-04-14T23:00"],"temperature_2m":[84.8,87.9,90.7,93.1,94.6,95.1,94.7,93.4,91.5,87.2,83.9,82.0,79.0,77.8,76.9,76.2,75.6,75.0,74.4,74.2,73.8,74.4,78.6,83.2],"wind_speed_10m":[3.8,5.9,6.0,6.2,6.0,6.4,6.1,5.8,5.4,3.8,2.2,2.4,3.5,3.8,3.3,3.0,2.5,2.2,2.1,1.8,1.3,0.9,0.4,0.3],"rain":[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00],"wind_gusts_10m":[9.2,12.8,13.2,13.6,13.2,13.6,13.6,12.8,12.1,10.7,6.9,3.8,6.0,6.9,6.7,5.8,5.1,4.0,3.8,3.6,2.7,1.8,1.6,2.0],"uv_index":[4.55,6.15,7.30,7.75,7.45,6.40,4.85,3.00,1.35,0.25,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.10,1.00,2.70],"showers":[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00],"apparent_temperature":[88.4,92.0,95.6,97.3,97.9,97.4,95.4,93.7,92.0,89.2,86.9,85.2,81.9,80.5,80.0,79.7,79.2,78.8,78.3,78.3,78.4,79.5,84.5,88.3],"precipitation_probability":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"relative_humidity_2m":[47,41,37,32,29,28,29,31,33,41,47,51,57,59,62,64,65,67,68,70,72,72,66,53],"cloud_cover":[0,0,0,0,5,2,9,31,20,0,9,54,51,38,0,50,44,56,65,84,81,71,54,52]},"daily_units":{"time":"iso8601","sunrise":"iso8601","sunset":"iso8601"},"daily":{"time":["2025-04-14"],"sunrise":["2025-04-13T20:10"],"sunset":["2025-04-14T08:59"]}}"""
DEFAULT_LOCATION = """{"lat": "28.53933",	"lng": "-81.38325",	"description": "Orlando, FL, USA",	"locality": "Orlando",	"place_id": "???",	"timezone": "America/New_York"}"""
API_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&daily=sunrise,sunset&hourly=wind_direction_10m,temperature_2m,wind_speed_10m,rain,wind_gusts_10m,uv_index,showers,apparent_temperature,precipitation_probability,relative_humidity_2m,cloud_cover&timezone=%s&forecast_days=1&wind_speed_unit=mph&temperature_unit=fahrenheit"
CACHE_NAME = "%s_%s_CycleCast_Cache_%s"

#Weather Icons
SUN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAASElEQVR4Aa1SQQoAIAgb0gf7/7GHGB08xdqKBBGc21AESOToybDAQ4SjfMQLWLXSEdwGrgms36SSELSd5IBNsK+nHKzdv7/RBFeDVlFpPWcXAAAAAElFTkSuQmCC""")
CLOUD_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAq0lEQVR42mJgoBJgxCa4atUqByAVD8QKQPwAiBeGhYUdIMkgoCHzgVQCFrWJQMMWEGUQ1CX7ifDJBSB2BBr8ASbAhKYgnsggMQDifmQBJiTXgMLDgYTwVcAwCGgIyIbz6JKEXAXU14DuovVALEBijIPU1wMN60c2SIGCJFSALbDJAqDwhRn0gAJzPgCTwQOYQYEgATINKkRJkNDorychvD5As84GBmoCgAADACo0LGmMFE1wAAAAAElFTkSuQmCC""")
RAIN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAARCAYAAADdRIy+AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPBBMhevOvbAAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAH0SURBVDjLrVRNSFRhFD33fm9mejPjGyMQnSgh2lToznYthIRo1R8UxDjVKqII3Ri5CWoT7YZpU4tMjCDcCONGoUXtpIUbhRY2mEWBVvrG0Zn3vu/dFor9zbOp8SzvPfdw7vk+LqFOOL35LhD6IBIH0Yj79PpoLR7VKsbP93Pq4sAZYtUDwBajy9U3U1m98MHeIgXmijt848lfBdOFxXaAxkF05Pee+bokldevIJ5PEHkHovui/enSyM2pmoKto/PNbCenAbSHrR4sf5O1yYlfZ0Umg/XSudUXt1z+mcwxe3A7MQDg5t0U7ewQ1doCikVlwxb1sJ0c/sNhurD4HsT76n0oGAPv7az2ZmatTaf7LQBoG/t0lJR1+Z/EAEApRA93WEFlXfRckUDUYrWNfT5BljUOEOM/ETlwEHquCKmWP1K6sPQSRN1oFEGwJsY/ZYHIwU6AOU6IPGYxegI7B2IYfReBGQIgDUmJuKK9q1vfJpm5rWKdx+KcTBElHOZEioiZTWlZSaWs4FcVREhECBIQiIWiu7RK7fHMyhd/5d4F11sohptysvmzTjZ/EgDs49fg9Oae/+g9HAqNcpsl+kR78wAQSR/qBikbAJoyuS4Q9oYNWeGRyKPSs/6ZzagvAbJxWSRYFYPBhvJuyuQeJE7fUfVwvwMdyrmmoIoMHgAAAABJRU5ErkJggg==""")

WINDSOCKS = {
    "1": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPATI4lMzQpAAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAPySURBVEjHbZU9bBxFFMd/87G7d2f7/EEMwsISIQV0oSIpkCggBRQUUZp0FKBEQqJACrSgSBSREB9CSkHBR4fSJBJIhDY1EnShQWBhK7FDwtm+24/ZN0NxN+u9daa5mZvd92be/v7/p+q6xhiDiACgtUYpRQgB7z3GmGYe9+Kz7feMMQDH9nTciH967wGa4O153GsHfNw8ro0xWBGZe2B046vw4Ntrzbp//rLqX3iXZPZiWk3Qw7W5gO0Y8QZx2PbiYJKH27/9wbnUstRLqOqKkFlMNqCuSwrn2Lv+Ee7OLQKgRBh8+DXZ6bNYa0nTDLV1l2zzFGZxGRHBxsyHkzx89t0PvJEGlPIgglEKmySkCz2gB8DSyhBZSNHGIFVF+uQ6yfo6o9GISmoeXX2b+tF9CLMbfHL9m7D3cETlKq5ceovV23uUv2swBsTTHUrRlEIpRZIkACwvLwPQW+oTyhRjDP+MK+zewxGV92xt77CyuIDznlyEpAp470gKhyqFKlQkJmFcOLxzTYlCWZGWgsMxyHqUpSDOoUWonMOWVcH2vV1OrA0ZTXL6IVA5R6ks3gtVVVLnBd47ysRT1SVe5CjBeEKZF4DgxFBQQxAMgUIEffniBU6srXHmxdN8f+sX/vxri2RWDq2n5ET+p78apTVGa7QxBMC5gv3DQ/59cJ/dw4KdibAzdmjAOqnBKlaHS1x883VufnyHp7TGGIOrhbqukTynnBzgvCLfP0AmDq3BO+H5tVWyvmWnKFgYDFi98jnZxkmyjWfRWmNDCAFBiUhY7GX63AubYfdXCfu1KPEENTpgWIzppSlL/R75K+fJ3rvWYHnvnZcbanLguR//ntOE1Vo3FqG1RmrhmRt3SYwJxhj2vvgAd+ksh8BYhJOf3pzD8ukONVrrRvHGGGwIobGDEALLmQ0mG6gorI0O910s/+tQo5RCRZbhKIHWmhACvY6wqg734w6WXWrafhVCwMZs0S2lI6xj3Hew3D0sqCeC0YKeHTSO+A3UrF5KKUVxJKyQmISyw30ywzIvS7zfZ3NGzWDz1DHVW2ux7SvVdc34SFiqTHzDfTzXQhfLM6815Yi9ot0njpXIGKO01iGEqbDud7iftMwsB9Z/3j528naSJkFUazUVlorCWutwr98/N4dlPHm8RYzzWExFhL3RQZgJSy31e2E4nrdj1cFy3mmnrXbuO7QxNcawIoWaCSuMRdQTX/40x/29Dpbdbqa1ni9RzOS9x3vPxsowyEKqorC63HextNbOJWmLDJhaRXRMYwyiUG1hTTrcb7bMrN3LHzemTb8WyrLEOYeIMC5c8M6pRlgd7k++9GpDXLssscztpi8i/A8ffNzRfqUoXQAAAABJRU5ErkJggg==",
    "2": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPATIXPx3t/QAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAJFSURBVEjH1VW/axRBFP7em929XC53lxw5RUVs7bTTThBsrCSkERvBIgEhnY3WNoGAVcogFlpbxr9CyzRBAgnR05C78253ZvbNs7gkEr0tdrVxmt1ZZuf78d58A/zvg37/8P3dK/32ev1sXl9aRX35qcbGwBiDZrPJZQDOLR6Mxrr9cQedJMK1Vh2XZg3atUjrtVkCQJn3VFZBdPpyPBjqxtZb3E8URAEQgSFCFMdIGjMAZipZFL3c3NLeUR/PNzbxbOUxFrZ7sJ8YMAaQ8Nc1iHpHfbgQsLd/gPm5BnwISEUQO0UIHnHmQVbg1Gls4vIA1mXYP/yKxU4L/XGKuiqc97AUIQSBcxZ5miEETzYur4hXHy5jsdPBrZs38Ob9B+x+3sMpT2YDYwwxsxKRMrOWBvCSAxFhodXE2qMH2LEMZYYxBkEVLs+RpikNj4+pd9gr3UWsqgoBRETn5xp07/pV9J3owSjDYRq01x/qOBtpnCToLDRLK4iY+cSOyfPKkxfnWO7ezdSv3MYPQEci5c+B6oRUCNMLeHm+pdJIiI2BOIcqFp1T8EeW0CRORAREVL5NT38qUjDKvAbvSQGQCKrUgADAGDOVns0tBRFUBihi/ssiVmIGT0nef2LRl8GQZOzBDAQv1QGKity5s4Ta2jqiKEKS1IC5RrUuKlJw8UIX3W4XzAwnOSqfgyIFcTxJpna7XSmuz3YtbFPr4K1gbLNq9wGfBFuRgnQ0hk0zAAIvpjyA5AJrLbz3UxcoAO8zpNYihEFpgJ99lxZhpYb1AgAAAABJRU5ErkJggg==",
    "3": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPATEF54nPdgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAOuSURBVEjHfZU9bB1FEMd/s3v33rMd27EVByWSJSAFdKEiFEgUkAIKiihNOkAgIiHRRQgqUCSKNFAgpaDgo0M0RKIgtKmRoIMGQYQtxw4Jzx/vPvZmhyJvL/fOTqbZ2ZvZmZ25/85fmqbBe4+qAuCcQ0QwM2KMeO9bPdmSb/ec9x7gkM0lQ/oYYwRog3f1ZOsGPEpPe+89marOOIy//8Lufn2t3c9duMzcxfcsnx4c1BPc0qrrBuzGSBUkybqbvUlhN3/9g/ODjMVRTt3U2DAzP5yXpqkoQ2Dn+seEWzfMwERV5j/4UoZnXyDLMgaDIXL7d4brZ/DHllFVspR5f1LYZ998x2sDQySCKl6ELM8ZLIyAEQCLx5dMFwbivEfrmsHJNfK1NcbjMbU23L/6Ns39O2DTCj69/pXt3BtTh5or777Bys0dqt8ceA8a6YsIklohIuR5DsDy8jIAo8U5rBrgveefg5ps596YOkZub2xy/NgCIUYKVfLaiDGQlwGplNpqy33OQRmIIYgBoopVNYNKCQTmhyOqStEQcKrUIZBVdcnG1jYnVpcYTwrmzKhDoJKMGJW6rmiKkhiDVHmkbiqiKm2CgwlVUQJKUE9JA6Z4jFIVd/nSRU6srnLuubN8e+Nn/vzrNvm0Hc55vPfinDMRsQerM3HOvHPivMeAEEp29/f59+4dtvdLNifK5kHAAVnQBjJhZWmRS6+/yg+f3OIJ5/DeExqlaRq0KKSa7BGiUOzuoZOAcxCD8szqCsO5jM2yZGF+npUrnzM8/RTD00/inCMzM0MRVbVjo6E7/+y6bf+ittuoaMRkvMdSecBoMJDFuZEVL12Q4fvXWlhuvfNii5oCePrHv2feROaca0eEc47Tb30kp978sB0XItIiyMxoTq5ZF5aneqhxzrUv3ntPZmbtOEj646QPy/96qBGRmUu1CZxzh258lBz0YNlHTXdemRlZCtidlt1Kkp78ih4st/dLmonineKmF02S/oFM+yUpSH99+IqlhWVRVcS4y/oUNfPrZw5Vm2UZWbekxA3dgH1Z6MPy3CttpYkrujxxZIseJ1udYVYAaz9tHPLpJmkTdIN3+95HVh+WXWCY2Uwc7z2uC9NU1lG9T2tVKUUITOqaOoQj/briujBN/GtmqOoMOyW9pCGY0qCUU58UI/l015bRYowzPCwiR/7wPiyzLJuhzH4VWbp5Wh/FtUnWHw4z6dv68oD0G6WqKkIIjyTvrn78+ZclIS7ZuvOsf+5/krB53+r86LcAAAAASUVORK5CYII=",
    "4": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAS81FRHABQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAOJSURBVEjHpZW7jxxFEIe/6u7Z1/nufCcb5JNOAhxAZkRi/gAcQECAnJgIEJItEVsIBwiEREACgSUHBDwyRIIlEpM6RoIMEgssfMJ3xtbeY3dmeqqLwNvD3N7ysKikq6aqflOvrpamafDeo6oAOOcQEcyMlBLe+5bPumzb9fPeAxzRuazIH1NKAC14l8+6LuAiPsvee4KqHjIYf33V7n3+USsPX7nE8PxbVswce/UEt7LuuoBdjJxBptAV9iZTu/HDz5zrBZYHBXVTY/1gvj+SpqkoY2Tn2nvEm9fNwERVRm9/Sv/M84QQ6PX6yO2fpL95Gn9sFVUl5D/vT6b28Rdf8VLPEEmgihchFAW9pQEwAGD5+IrpUk+c92hd03vsJMXJk4zHY2ptePDBmzQP7oLNMvjw2me2c39MHWsuX3yNtRs7VD868B40MU8iSC6FiFAUBQCrq6sADJaHWNXDe89vBzVh5/6YOiVu39ni+LElYkpMVSlqI6VIUUakUmqrrfAFB2UkxSgGiCpW1fQqJRIZ9QdUlaIx4lSpYyRUdcmd37c5sb7CeDJlaEYdI5UEUlLquqKZlqQUpSoSdVORVGl/cDChmpaAEtVT0oApHqNUxV26cJ4T6+ucffYMX17/jlu/3KaYlcM5j/denHMmIvbwdCbOmXdOnPcYEGPJ7v4+f9y7y/Z+ydZE2TqIOCBEbSAIayvLXHj5Rb55/yaPO4f3ntgoTdOg06lUkz1iEqa7e+gk4hykqDy9vkZ/GNgqS5ZGI9Yuf0J/40n6G0/gnCOYmaGIqtqxQd+de2bTtr9X221UNGEy3mOlPGDQ68nycGD9i+8yvHIVNxg5EeHWq89Znpop8NS3vx66E8E5164I5xwbb1yRU6+/064LEWknyMyQ9bWWBzg1NzXOufbGe+8J2TCl1Do9Cs1PjYgcCqr9gXPuSMT/heanpruvzIyQAbvbsptJ5rPdfJbb+yXNRPFOcbNAM+UeyKxekkHmz79u8dHsNmdTM9o8fUQZQiB0U8pvwz8BHmq4CGtnX5CunDdr+74sKtF8ox6Vuuu77UEGn6/7oslaZJflLo73Htcd05zW39X+33qyKGvXHdP8/poZqnrodcp81nXtMka26Z7tTKWUSCkd6oH3/kj0ZtYGIiKEEFq/RVm4HHk+59/a/0Pee5w2SlVVxBgXlmSed849TH12obp81nX9/gRO8UFjXyhwYgAAAABJRU5ErkJggg==",
    "5": "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",
}

MOON_ICONS = {
    "0": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAioWyEf7awAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAALSURBVAjXY2AAAgAABQAB4iYFmwAAAABJRU5ErkJggg==",
    "1": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAh4Z49IVDQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAKOSURBVDjLxZRLSFRRHMb/59w7d/Q+nHEmMS2yWlS20cBEE6IoopVFiwotjaIWmcse2hMzLJEyJDMCCdHMhdAi6AEJZg9TzIgiaCGENurojDOOc+fc1zltMlLMamagb3XgO+fHx/c/53DwQ3c7OjanpqV53/X1mbCIGpqb5X3FRZczN+VHXj59NgLx1NlrV9fUtbeOnLx5vQgAUFzhj7qet3e97Q3ebrm3dSEfRwv2TUw8lERRZqLYvGXP7tS4gQf6+/vH/T5jdMqflr99W/n8SqIGgyyNfRn1RJKcTkFWlINHzpyS4wJmPG8FgtMmACAhIWEFLwg5CCEUM3jc45EAYzEQCBhqOGwmKHIuY4zN+nw0UIwxMgxjlSiJNkYptihlTpcrI+YqKKUsc0N2HkII2QQBIwCKEZoTko+yCRSamdnBMLYQQjTZ5bKRcHgy5sQ7Sw5kJLvdBS63226z2ZCmadT7zTPw6/D+OXGiIqOs3I0luq4ruq6bhBBGLSsYCgZfxTS8wkOlSxWHo4zjOC5CCDicTk4n5ElLbZ03liq4ddlZV+x2ewplDCRJQiQSCY8ND9dRABo1uLTy9C7DNPerqmrxPI8AADRVrWm6WDU4f+9fV3Hswrn1KcvSGyljWNd1ixBi2QWh9UNv341Ff7c7bW2Zv4PuLS9b6UhZ8gBznEtJSuIBwAj4/TWXDh89/rjtvrbQmZ+J3/T0sNrGxkJCyAtd09TqigoDAOBEddVaLjGxk+P51ZIsWzohvdOTvsrOW02vYV6vcy767EJSFBQOhbjq+vqMr0NDQk5envvzp4+KtDy9eEZVmanp7zGw7obK84MAYP3xBS1m5hYUcL7AFPKNe61pvx8opQz+t74DJwYPByH5rTgAAAAASUVORK5CYII=",
    "2": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAiMiODG0lwAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAOlSURBVDjLtZRLaFxVGMf/3zln7k1m5t6ZadLaaGsa4gNDHz4aaEAKSRFS7MaCrdK14qtF6qrYatEgtW6KwbpQUWg3RbcKVuqmgTYVlGpi0ldiMpOGTJp5z9w7c+85n4saMfWBI/iDA4ePj9/iexF+46MzZzA6MoKPh4cRiUSgtYYxBn3bt7c/3t/fNjE2Jnbs3Olu2rJlwHHd+evj45f27d496SaTXCoUGHeglj/P7d0LIQQAIAiC3xMGBgfXxOLxX8YvX64/9fSeRGdX15cacINYq/fNpdHvKsXS28ePHBm5cPGi/qOY0ARfnD2berS3dyqbz8e///knrE8kuT2Z4quZ9HB+Zvbwqy+86C/nCjSJYeb1HR1iU2cXr04klQCsmN3ySvfGjZ+8eeyY9Z/FREQ1rxY6rVFBRKS15nXt7daaROKZR/r6Xl92Ni1mY5hI0K1CPmBmNrcfipWKvj6XPvDB6dMPNS2WQiBXKBjP8wy0FrPZbGApJQBg4mYm1FIkYqtSrzUtFkTw6j6iliXcaDQS6tAwwNoYrvm+EEJQAzz4RP9AUjUjDrRGWzKFsSuTQbVa4VWOIwFQIwh0pVqFFYZh2AiS+w7s725KzMxQUmKtm7DZcWgmu2AyuVzIzByNxaQxBiQo4qSS65oSCyFQKRQIYElEyJZLvFQoGKUUSAjYti1Z6xBEkaZqvJDJcLmQ54rnhcYYfmDt3UYpxdVqleu+b0rFYmDbLUIJsdiU2OiQmFm02rYwzDy9uEBCShmxLOG4rsXMsCOR8ui5b6ebm2NmLBaLWhDRtfmbpuT7EgCHQWDyuVydhGCh9Q/vHD2aVk1uHdricXFlLhNmyyVFRKSUkslUSgJgSykTVZH3AfC/FpNSyJVKPDk/xzVmFYahBiCklDDGsJSS4sr6evbqta9WXDchBIwxfyt+/o3DYOZU5/333QCRUy6XNREBDNgttui+tzMT8Rs7nt21a3rF5n146tSKsVrGjsewZ//LSKxuR93zOAzDoFQqhUSEaDQqpJK4K5Gc4ErtyWXpikN/4fx5HD95Er7vo1GvY+jQIQDAY1t7Wzo2bPClUqhVKqjVag2SEo7rqrZEwnNaWj9N/zj21ksHD976y0MfcxxUy2UMnTiBmakpbN22DRPjY/Br3sP1eh0P9vTA97zWxD0dQ0KIRsp1zy2kM59/9u576fGpG3+qId3ZdaLboWgshp7Nm7FUyGNpIYtSLgdmBhH9Yy/+d34F1Ma9296AqCMAAAAASUVORK5CYII=",
    "3": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAiUDIgIDTwAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAARsSURBVDjLvZVdiJRVGMef5znn/ZqZd3ZmZ2Z32goxvUhFvBECIYldRXG3MBPCm8AgCCXowpvoJgIj8qoukqAyMvowNcI0u7CLTFLoYhPdtljanXV3PnRmdmbnfef9Oh/dFHQxWgT1vz7nd/78HngOwH8U/KcHnz18eE95bMzcMbnn6bH7xtbUq9Wbv8zOXHj/zbe+uXb1Wv9fvf7KsWPuj3Nzry71++16HKtFzxOfX/k+PP7l2fjbqz/c/OjM6d1bd0zQX++wewG5YeAHZ84Ut09MfGo6zjOWZTqcc5JK6Wa7rQPfpwdKpRHJ6Cl7pGRc/ur8FQBQdwUfOHjQvjE9LV4+etTZNTX1sR/H4yOFAqs2GiKXzTLOOQ27WZ0CYESEKdvmeTe77cn9+xW3jMs3pn8CGgT+5MSJEABgat++I4VicRIRkTEGCAhaa0iSRIVhqBARAQD8MJSj+bw5XCi8VN64cdc9VZy6ePHhDZs3v8cYs1OOA43mHVnID3PbsiiMIlWt1xLf98g2TeKcIQDAr7cWRTcMtkS+f3Jg48d27sQNmza9CACuFEJZpsnGRsuG1+/rOI5ls92WWds2+mGo/DCUhIRd35ftKKRCqbRl++NT4wPBj46Pl4ZyuQOWaTKlNfj9voriWLY6KxjFseacaZUklLYdSoQADQBJkqg4SRgiUjafe4IPAk/u3TtpWpYrpVS1Rl24mQxKqWDDuvUMEfF2804yv1gRAIBrR8sGAUAvDKC3uqpUJiM9z9s6EJxKpycQEZRSYHAD0k6Kmitt8eewXNM01o6WKRaJnq7MS9e0ZKPXM7JDQ0opBelM5v6BKphpbK4sLwvGOaZSDrU6K3K0OGIAAAiRSL/bJSIiLwh1LwzZTKUCQkkgIjQMA5GIBjb2/H6hF/RRSalz2SGezbj6j7LQaTaVUoqHcSwL2SwbXnFi3/Ows9JJEAFtxyatVGsgeKRQdB+0LWKMEQCA0loTIiZRLL1ulyEREhF4QSC7UWQIIZJcPmcQIrZardhxnOmB4CAMABBUKp2mKIpUs92WhAjS93QQhgwRJQDAzeVblCRC27bNOisdgYRgGAY2643zAx23u52EMYZaKV273UjKpRLjoNXswry2TZMSkajriwsQS0kaNFiOw4ZyQ8x1XWbbdn1h5uevB4KFlD0iQqmUNg0TkyhS/U7HAEQMokjOLC/Tqt/XAKA554wQMY5jBQB6aX7htXMfnmwOVFEulqqMsTVEhFEUqtmlWzpOYu0FgbzuVXgsJQkphNfqxVprzTlnbjbL/NXVz1q1+rsAAIMd+75wHEcYnDPheaiVxEqjkQRa2WEYSq2UCoK+0EojIqIQQjaqtXPLc3PPn3r7uLzrEprYvfu7/HB+7Z1qbf1Sva6v/zanK/W6zRATx3H4arebgAYoFIuWaVp+r9s5eunsF0cunT7b/9uv6blDh4zyuoceATfzAhBu6/V6+UKhQIwxaLfaPa1VzTLNC7XK4jsnXn9jEQA0/B/5HUyQULZnC3XcAAAAAElFTkSuQmCC",
    "4": "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",
    "5": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAicGYF6VQgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAASkSURBVDjLvZRLbFR1FMbP/3Ffc6dT2kKfFEqTijwslkQM4KIsCEiQlbo1ceUKXOlCQ1wYN8QFxhgIVkmECDFigjxUFuALE0ETaJEItKUv5tG5M3fmzsx9/B/HDYnGAWWjZ32+X75zcs4H8B8VeZQmi5vsyKfH+4ceW73btKytnLH+336/iUqIQovr/jIxPn5KST25//XXxCODj544uerpLVvectPpFwzDsOMkUUop/PnGONRLJVgzOMjLlUrt+sTE+7fHJw59fPjwHAAg+6dpTn719c4nN248TTnblE65NiGEcM4pZ4xKpSXTClzH4Y5tW8v7+jZnWlqyz4yOwoXz5xce6vi7K1d3rRwcPOFVK07vsk6W9zwZiwSWLmmjKdtmiKgX5mZ1ksRcKaWFlBoQy2fPnttONBL6IOjxU1+s6h8YGJNKOSY3UEqphRB6RXcPXyyXJAGAMI41YVRprZExRm3L4rEQbenuZS939/YETeBn9+yhG0ZG3jRNs7NQLqm2TIZxzqlQEnLForAMkyIARHEEflCTuWJRNMJQ3pcjs+0Xj4x9mOd/B28d3ba8GkXP1wsF2bN0GY+SWLtOig/09plxkmhKKZFK6aDekMu7exybEVjIF4SbSnHbsmgjipY8PjIy0uR4x84dzw3297csSaepVApcJ8WrtZoghBDbsthCoaBzXlEbBqd+tZL41UC7jkOFEDqMY8y0ZsyhJ9au5c23QDbHcSync1lqMI7rBgextaXFqNZqKmg0VFd7O7UtixJK2eTkndgwDEIAyM2701Cp1yVwaiBiR5Njx3b6LNPkA909uLKriwAAUUqhV6morvYOvuiXFaWUUkKIY1k8nUoxvP8S5SAAv+xLKZXmzYYJlVqjwTlxHYcBABBKQaPGcrWiDc4JAIDWGkWSgNJap1Mp1t3RkRQagRGFkWIA95rASRzn8p4nhRRASQcwRolSGgd6es1YJHqp1WYAAEgptdaKhWEoHduGxaBCOedUCJHcvHL1WtMqEPBKeybDHMsmjmXRmVxO3Zqb1YxS4lg2i+JYISJGYQMBANKua8RCoFevsSSOhW2Zs7euj99oAn9/8dKXBueqs72dAyFkoKeXrV6xkuKfqyKlSkUWPU8JKTGo18VUPqsRgFi2bSZR9NHkxA3VBJ6dmblT8ctnojhWAACmYdBECE0AIEmEznlFZZsm5Ap5VEphoiTxagETiZC1IJien5o+KoXAB2bFuYuXhtcPD38bCZEuBwFyRrGvs8v0fF86tk2SsKFzuSz1fF/M+SUjEgn1vFKUnZ176diBdz8DgPQDs2LXttHrC/Pzr1ZqNdHf1cUQgSAitrguKZQ8WSwuYsn31XzZg2qjjmEYinq1emDi8uXPX9m7zwSAGn1Yum3eMPzJYiG/d2p+vmqbJiAiGpxT1zBJ2a+QXKmkqlFoUEJUrRq888Eb+98eWrGq9dB7B5NHCXpy+sKFkTXr1h80bfspxpgxdfuWmMln9U/j4yYg3lVxtK8+d+/isbGxxl+F/F/AuGf79l8BYNs3P/y41batXZNzM5vuZBc6k2pwvi/TeqYchFEIMAQA1+D/qD8AdWmNN4gcE6UAAAAASUVORK5CYII=",
    "6": "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",
    "7": "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",
}

WINDROSE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPFygTkPYM/QAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAF7SURBVCjPxVM9SwNBEH2rkTN6BMFYiOSihaARBFExhZ1WyiFEzC8IxDMWWqgJNoqCFlaCQVtrSSAEP7CwiIUSG/NhIRYJiEUuouLpFae3FiGHm3g2Fi4My/Lem3kzw4JSCrOQRYH+htfgD8dULIWyAIDg9LmpmFBKjYdnJgVbvY7Xd2DvYcIAQq5D0vyk4JmzYHe73+Bbvmfq7rBiPjFKKyts3IxRAAj1HBNT29m7FzsAbLrjhI/kSGNwn/CRHPG3xQkA2Kw6m7U8Od/iNWRRoLIoUFXTUSi+4Ww9CrmgQNV0A5OWMoaGyKJQZZOP5MhFUoZ70I7LqyKGBlqgeNqreDX2WJ7YY3my0nvC9OPqasLq1i2cDp4RrPWdkrKGWbo3ULI+NZuGqumIHt1D1XR4pTRkUaCT/iTDZ6b98Vm6w/lxqniAYQBKGNgpr6aWY1wwYq4OCDjjpFOwYi4xYvQYcBwQZ2sDuEf687Qrw7eQgiwKVFrOmHLwbx/jC1N2GlOFpgbIAAAAAElFTkSuQmCC""")
DIRECTIONAL_ARROW = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQQAhEq0+AvHQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAABWSURBVCjPY2DAA6S2vv2PT56JgQJAfc17Ypo5iNHMSIx/n3kLMxKtGVtAYTMAr59x2Yg3etBtxiaG12aYYnxxTZGfcYKD0S2yUlvf/t8W2S3CMArgAACZwSg5iYpbGwAAAABJRU5ErkJggg==""")
FLAG_BASE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAMAAAAICAYAAAA870V8AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQQDzcLVI8vNAAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAABJSURBVAjXRcmxDYAwDAXR8/dMVPSMyAaUbEKJxCxWiE0BKNc9nR3nVeu2s8wTMjMAMnNAEqqqcX5IQnxlJpKEu7+n352IoLXGA+FUHgXhxXywAAAAAElFTkSuQmCC""")

# Parameters for Setting Options
scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def seconds_remaining_in_day(timezone):
    # Get the current time
    current_time = time.now().in_location(timezone)

    # Extract the hour, minute, and second components of the current time
    hour = current_time.hour
    minute = current_time.minute
    second = current_time.second

    # Calculate the seconds elapsed today
    elapsed_seconds = hour * 3600 + minute * 60 + second

    # Total seconds in a day (24 hours)
    total_seconds_in_day = 86400

    # Calculate the remaining seconds in the day
    remaining_seconds = total_seconds_in_day - elapsed_seconds

    return remaining_seconds

def get_weather_data(latitude, longitude, timezone):
    local_cache_name = CACHE_NAME % (latitude, longitude, timezone)
    local_api_url = API_URL % (latitude, longitude, timezone)

    local_weather_data = cache.get(local_cache_name)

    # We need to make sure we don't keep this dataset past the end of the day, but we also want to clear it a little more often to
    # get updated data. So we'll set a max cache in seconds
    max_cache_in_seconds = 10800  #3 Hours

    seconds_xml_valid_for = seconds_remaining_in_day(timezone)

    if seconds_xml_valid_for > max_cache_in_seconds:
        seconds_xml_valid_for = max_cache_in_seconds

    if local_weather_data == None:
        # print("New Data")
        response = http.get(local_api_url, ttl_seconds = seconds_xml_valid_for)

        if response.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (local_api_url, response.status_code, response.body()))
        else:
            local_weather_data = response.json()
            cache.set(local_cache_name, json.encode(local_weather_data), ttl_seconds = seconds_xml_valid_for)
    else:
        # print("From Cache")
        local_weather_data = json.decode(local_weather_data)

    return local_weather_data

def get_two_digit_string(number):
    if (number >= 10):
        return number
    else:
        return "0%s" % number

def get_current_condition(data, element, item_name, add_units = True):
    if add_units:
        units = data["hourly_units"][item_name]
        display_tempate = "%s%s" if units == "mm" or units == "%" or units == "°F" else "%s %s"

        return display_tempate % (data["hourly"][item_name][element], units)
    else:
        return data["hourly"][item_name][element]

def to_hex(n):
    """Converts an integer (0-255) to a two-character hex string."""
    hex_chars = "0123456789ABCDEF"
    return hex_chars[n // 16] + hex_chars[n % 16]

def most_contrasting_color(hex_color):
    """Returns the most contrasting color by inverting the input color."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Invert colors
    inverted_r = 255 - r
    inverted_g = 255 - g
    inverted_b = 255 - b

    # Convert back to hex
    return "#" + to_hex(inverted_r) + to_hex(inverted_g) + to_hex(inverted_b)

def luminance(r, g, b):
    """Calculates the relative luminance of an RGB color."""
    return (0.299 * r + 0.587 * g + 0.114 * b)

def best_contrast_color(hex_color):
    """Returns black (#000000) or white (#FFFFFF) based on the best contrast."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Determine luminance and choose contrast color
    if luminance(r, g, b) > 128:
        return "#000000"  # Dark text for light backgrounds
    else:
        return "#FFFFFF"  # Light text for dark backgrounds

def get_uv_index_category(index, color = False):
    index = float(index)

    # Define thresholds and corresponding values
    thresholds = [2, 5, 7, 10]
    colors = ["#8FC93A", "#FFD700", "#FF8C00", "#FF4500", "#800080"]
    labels = ["Low", "Moderate", "High", "Very High", "Extreme"]

    # Select appropriate category
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i] if color else labels[i]

    return colors[-1] if color else labels[-1]  # Highest category if above all thresholds

def get_temperature_color_code(index):
    index = float(index)

    # Define thresholds and corresponding color codes
    thresholds = [32, 50, 65, 75, 85, 95]
    colors = ["#00A8E8", "#66D3FA", "#5BC8AC", "#8FC93A", "#FFD700", "#FF8C00", "#D62828"]

    # Find the correct color
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i]

    return colors[-1]  # Return highest category if above all thresholds

def get_humidity_color_code(index):
    index = float(index)

    # Define thresholds and corresponding color codes
    thresholds = [20, 40, 60, 75, 85, 95]
    colors = ["#FF4500", "#FF8C00", "#FFD700", "#8FC93A", "#5BC8AC", "#66D3FA", "#00A8E8"]

    # Find the correct color
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i]

    return colors[-1]  # Return highest category if above all threshold

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_information_marquee(message):
    marquee = render.Marquee(
        width = 64,
        child = render.Text(message, color = "#ffff00", font = "CG-pixel-3x5-mono"),
    )

    return marquee

def moon_phase(year, month, day, show_description = True):
    # Constants for improved accuracy
    known_new_moon_julian = 2451550.1  # Julian date for January 6, 2000
    synodic_month = 29.53058867  # Average length of a lunar month in days

    # Convert the current date to Julian date
    julian_date = calculate_julian_date(year, month, day)

    # Calculate days since the known new moon
    days_since_new_moon = julian_date - known_new_moon_julian

    # Determine the phase of the moon as a fraction of the synodic month
    phase = days_since_new_moon % synodic_month
    phase = float(phase)

    # Define thresholds with corresponding descriptions and indexes
    phase_map = [
        (1.84566, "New Moon", 0),
        (5.53699, "Waxing Crescent", 1),
        (9.22831, "First Quarter", 2),
        (12.91963, "Waxing Gibbous", 3),
        (16.61096, "Full Moon", 4),
        (20.30228, "Waning Gibbous", 5),
        (23.99361, "Last Quarter", 6),
        (27.68493, "Waning Crescent", 7),
    ]

    # Iterate through the mapped phases
    for threshold, description, index in phase_map:
        if phase < threshold:
            return description if show_description else index

    return "New Moon" if show_description else 0  # Default to "New Moon" or index 0

def calculate_julian_date(year, month, day):
    # Convert Gregorian date to Julian date
    if month <= 2:
        year -= 1
        month += 12

    A = year // 100
    B = 2 - A + (A // 4)
    julian_date = (int(365.25 * (year + 4716)) + int(30.6001 * (month + 1)) + day + B - 1524.5)
    return julian_date

def get_wind_sock_category(wind_speed):
    thresholds = [6.91, 10.36, 13.81, 17.26]

    # Iterate through thresholds and return appropriate category
    for i in range(len(thresholds)):
        if wind_speed <= thresholds[i]:
            return i + 1

    return len(thresholds) + 1  # Highest category if above all thresholds

def get_wind_rose_display(direction):
    #Start and Stop at the correct spot on the windrose
    #Simulate a little variability in the breeze in the windrose by having it move about the correct direction just a little.

    keyframes = []

    keyframes.append(animation.Keyframe(
        percentage = 0.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))

    for i in range(0, 100, 5):
        rotation = direction + ((100 - i) / 100 * 10 * (1 if i % 2 == 0 else -1))
        rotation = 360 if rotation > 360 else rotation

        keyframes.append(
            animation.Keyframe(
                percentage = i / 100,
                transforms = [animation.Rotate(rotation)],
                curve = "ease_in_out",
            ),
        )

    keyframes.append(animation.Keyframe(
        percentage = 1.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))

    return animation.Transformation(
        child = render.Image(src = DIRECTIONAL_ARROW),
        duration = 250,
        delay = 5,
        origin = animation.Origin(0.5, 0.5),
        keyframes = keyframes,
    )

def get_cardinal_position_from_degrees(bearing):
    """ Returns the cardinal position for a given bearing

    Args:
        bearing: in degrees
    Returns:
        The Cardinal position (N, NW, NE, S, SW, SE, E, W)
    """

    if bearing < 0:
        bearing = 360 + bearing

    # have bearning in degrees, now convert to cardinal point
    compass_brackets = ["North", "NNE", "NE", "ENE", "East", "ESE", "SE", "SSE", "South", "SSW", "SW", "WSW", "West", "WNW", "NW", "NNW", "North"]
    display_cardinal_point = compass_brackets[int(math.round(bearing // 22.5))]
    return display_cardinal_point

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    title = "CycleCast by Robert Ison"

    instructions_1 = "CycleCast uses Open Meteo data (open-meteo.com/) to show current conditions for cyclists and outdoor enthusiasts. "
    instructions_2 = "It features a wind rose for direction, a windsock for speed (fluctuating between wind speed and gusts), and sun/moon phases with cloud and rain icons. "
    instructions_3 = "Color-coded boxes indicate UV index, temperature, and humidity—more green means better riding conditions!"

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(title, color = "#FF7300", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(instructions_1, color = "#E3D8C5"),
                    offset_start = len(title) * 5,
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#8F9779"),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#FF7300"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_animated_windsock(wind, gusts):
    children = []

    for _ in range(1, 3):
        for _ in range(0, 10):
            children.append(render.Image(src = base64.decode(WINDSOCKS[str(get_wind_sock_category(float(wind)))])))

        for j in range(get_wind_sock_category(float(wind)), get_wind_sock_category(float(gusts)) + 1):
            for _ in range(0, 2):
                children.append(render.Image(src = base64.decode(WINDSOCKS[str(j)])))

        for k in range(get_wind_sock_category(float(gusts)), get_wind_sock_category(float(wind)) - 1, -1):
            for _ in range(0, 6):
                children.append(render.Image(src = base64.decode(WINDSOCKS[str(k)])))

    return render.Animation(
        children = children,
    )

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    # Get location needed for local weather
    location = json.decode(config.get("location", DEFAULT_LOCATION))

    # Round lat and lng to 1 decimal to make data available to more people (within about 11km x 11km area) and to not give away our users position exactly
    latitude = round(float(location["lat"]), 1)
    longitude = round(float(location["lng"]), 1)
    timezone = location["timezone"]
    current_time = time.now().in_location(timezone)

    # use the real lat and long to get a more accurate sunrise/sunet time. This info isn't shared with anyone but the user
    sunrise_time = sunrise.sunrise(float(location["lat"]), float(location["lng"]), current_time).in_location(location["timezone"])
    sunset_time = sunrise.sunset(float(location["lat"]), float(location["lng"]), current_time).in_location(location["timezone"])

    #Dumb Down the current Time to work with the simpler time format of the API
    simple_current_time = time.parse_time("%s-%s-%sT%s:%s" % (current_time.year, get_two_digit_string(current_time.month), get_two_digit_string(current_time.day), get_two_digit_string(current_time.hour), get_two_digit_string(current_time.minute)), format = "2006-01-02T15:04")
    local_data = get_weather_data(latitude, longitude, timezone)

    # Let's look for the closest entry in 'time' to pull out current conditions
    hour_periods = local_data["hourly"]
    closest_element_to_now = 0
    smallest_difference = 24  #Just need to seed this with a high number (only 24 hours in a day)

    # in the stored data, let's find the closest time period to now
    for i in range(0, len(hour_periods["time"])):
        time_difference = simple_current_time - time.parse_time(hour_periods["time"][i], format = "2006-01-02T15:04")
        if abs(time_difference.hours) < smallest_difference:
            smallest_difference = abs(time_difference.hours)
            closest_element_to_now = i

    # based on the time period, pull out the current conditions
    current_cloud_cover = get_current_condition(local_data, closest_element_to_now, "cloud_cover")
    current_humidity = get_current_condition(local_data, closest_element_to_now, "relative_humidity_2m")
    current_humidity_value = get_current_condition(local_data, closest_element_to_now, "relative_humidity_2m", False)
    current_probability_precipitation = get_current_condition(local_data, closest_element_to_now, "precipitation_probability")
    current_temperature = get_current_condition(local_data, closest_element_to_now, "temperature_2m")
    current_temperature_value = get_current_condition(local_data, closest_element_to_now, "temperature_2m", False)
    current_apparent_temperature = get_current_condition(local_data, closest_element_to_now, "apparent_temperature")
    current_showers = get_current_condition(local_data, closest_element_to_now, "showers")
    current_uv_index = get_current_condition(local_data, closest_element_to_now, "uv_index", False)
    current_wind_gusts = get_current_condition(local_data, closest_element_to_now, "wind_gusts_10m")
    current_wind_gusts_value = get_current_condition(local_data, closest_element_to_now, "wind_gusts_10m", False)
    current_wind = get_current_condition(local_data, closest_element_to_now, "wind_speed_10m")
    current_wind_value = get_current_condition(local_data, closest_element_to_now, "wind_speed_10m", False)

    # current_rain = get_current_condition(local_data, closest_element_to_now, "rain")
    current_wind_direction = get_current_condition(local_data, closest_element_to_now, "wind_direction_10m", False)

    message = "It is %s but feels like %s with cloud cover of %s and humidity of %s. The probability of precipitation is %s, expect %s of rain. The UV index is %s (%s) with winds from the %s at %s gusting to %s." % (current_temperature, current_apparent_temperature, current_cloud_cover, current_humidity, current_probability_precipitation, current_showers, current_uv_index, get_uv_index_category(current_uv_index), get_cardinal_position_from_degrees(current_wind_direction), current_wind, current_wind_gusts)

    display_items = []
    show_info_bar = config.bool("show_info_bar", False)

    if current_time > sunrise_time and current_time < sunset_time:
        # print("Daytime")
        display_items.append(render.Box(width = 64, height = 26 if show_info_bar else 32, color = "#004764"))
        display_items.append(add_padding_to_child_element(render.Image(src = SUN_ICON), 48))
    else:
        # print("NightTime")
        display_items.append(add_padding_to_child_element(render.Image(src = base64.decode(MOON_ICONS[str(moon_phase(current_time.year, current_time.month, current_time.day, False))])), 43, -2))

    #Display Rain if Raining
    if get_current_condition(local_data, closest_element_to_now, "rain", False) > 0:
        display_items.append(add_padding_to_child_element(render.Image(src = RAIN_ICON), 40, 6))
    elif get_current_condition(local_data, closest_element_to_now, "cloud_cover", False) > 15:
        display_items.append(add_padding_to_child_element(render.Image(src = CLOUD_ICON), 40, 6))

    # Display The Windsock
    display_items.append(add_padding_to_child_element(get_animated_windsock(current_wind_value, current_wind_gusts_value), 0))

    # To make room for an info bar if requested, need an offset of height of 5 pixels
    height_offset = 0 if show_info_bar else 5

    # Marquee
    if show_info_bar:
        display_items.append(add_padding_to_child_element(get_information_marquee(message), 0, 27))
    else:
        display_items.append(add_padding_to_child_element(render.Image(src = FLAG_BASE), 0, 24))

    # Wind Direction
    if (get_current_condition(local_data, closest_element_to_now, "wind_speed_10m", False) > 0):
        display_items.append(add_padding_to_child_element(render.Image(src = WINDROSE_ICON), 16, 6 + height_offset))
        display_items.append(add_padding_to_child_element(get_wind_rose_display(current_wind_direction), 16, 6 + height_offset))

    # Initialize Info Box Settings
    info_box_height = 9
    info_box_width = 14

    # UV Index Warning
    display_items.append(add_padding_to_child_element(render.Box(color = get_uv_index_category(current_uv_index, True), height = info_box_height, width = info_box_width), 29, 1))
    display_uv_score = str(int(current_uv_index))
    centering_additional_offet = int((info_box_width - (3 * len(display_uv_score)) - len(display_uv_score)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 31, 3))
    display_items.append(add_padding_to_child_element(render.Text(str(int(display_uv_score)), font = "CG-pixel-3x5-mono", color = "#fff"), 29 + centering_additional_offet, 3))

    # Current Temperature
    display_items.append(add_padding_to_child_element(render.Box(color = get_temperature_color_code(current_temperature_value), height = info_box_height, width = info_box_width), 29, 17 + height_offset))
    display_temp = str(int(current_temperature_value))

    # To center the numbers, we need to have an offset based on the number of characters to display
    centering_additional_offet = int((info_box_width - (3 * len(display_temp)) - len(display_temp)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 31, 19 + height_offset))
    display_items.append(add_padding_to_child_element(render.Text(str(int(current_temperature_value)), font = "CG-pixel-3x5-mono", color = "#fff"), 29 + centering_additional_offet, 19 + height_offset))

    # Humidity Box
    display_items.append(add_padding_to_child_element(render.Box(color = get_humidity_color_code(current_humidity_value), height = info_box_height, width = info_box_width), 49, 17 + height_offset))
    display_humidity = str(int(current_humidity_value))
    centering_additional_offet = int((info_box_width - (3 * len(display_humidity)) - len(display_humidity)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 51, 19 + height_offset))
    display_items.append(add_padding_to_child_element(render.Text(display_humidity, font = "CG-pixel-3x5-mono", color = "#fff"), 49 + centering_additional_offet, 19 + height_offset))

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show instructions on this app when first installing.",
                icon = "book",  #"info",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The location used for gathering weather data.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_info_bar",
                name = "Information Bar",
                desc = "Add an information bar at the bottom that provides more weather info.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
