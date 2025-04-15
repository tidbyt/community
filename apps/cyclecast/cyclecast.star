"""
Applet: CycleCast
Summary: Weather Data for Cyclists
Description: Displays weather data important for cyclists.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")  #to encode/decode json data going to and from cache
load("encoding/json.star", "json")  #Used to figure out timezone
load("http.star", "http")  #for calling to astronomyapi.com
load("humanize.star", "humanize")  #for easy reading numbers and times
load("math.star", "math")  #for calculating distance to planets
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")  #to calcuate day/night and when planets will be visible
load("time.star", "time")  #Used to display time and calcuate lenght of TTL cache
load("animation.star", "animation")

#Note: Windsock is a conical textile tube  

SAMPLE_DATA = """{"latitude":28.375,"longitude":81.25,"generationtime_ms":0.091552734375,"utc_offset_seconds":-14400,"timezone":"America/New_York","timezone_abbreviation":"GMT-4","elevation":167.0,"hourly_units":{"time":"iso8601","temperature_2m":"°F","wind_speed_10m":"mp/h","rain":"mm","wind_gusts_10m":"mp/h","uv_index":"","showers":"mm","apparent_temperature":"°F","precipitation_probability":"%","relative_humidity_2m":"%","cloud_cover":"%"},"hourly":{"time":["2025-04-14T00:00","2025-04-14T01:00","2025-04-14T02:00","2025-04-14T03:00","2025-04-14T04:00","2025-04-14T05:00","2025-04-14T06:00","2025-04-14T07:00","2025-04-14T08:00","2025-04-14T09:00","2025-04-14T10:00","2025-04-14T11:00","2025-04-14T12:00","2025-04-14T13:00","2025-04-14T14:00","2025-04-14T15:00","2025-04-14T16:00","2025-04-14T17:00","2025-04-14T18:00","2025-04-14T19:00","2025-04-14T20:00","2025-04-14T21:00","2025-04-14T22:00","2025-04-14T23:00"],"temperature_2m":[84.8,87.9,90.7,93.1,94.6,95.1,94.7,93.4,91.5,87.2,83.9,82.0,79.0,77.8,76.9,76.2,75.6,75.0,74.4,74.2,73.8,74.4,78.6,83.2],"wind_speed_10m":[3.8,5.9,6.0,6.2,6.0,6.4,6.1,5.8,5.4,3.8,2.2,2.4,3.5,3.8,3.3,3.0,2.5,2.2,2.1,1.8,1.3,0.9,0.4,0.3],"rain":[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00],"wind_gusts_10m":[9.2,12.8,13.2,13.6,13.2,13.6,13.6,12.8,12.1,10.7,6.9,3.8,6.0,6.9,6.7,5.8,5.1,4.0,3.8,3.6,2.7,1.8,1.6,2.0],"uv_index":[4.55,6.15,7.30,7.75,7.45,6.40,4.85,3.00,1.35,0.25,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.10,1.00,2.70],"showers":[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00],"apparent_temperature":[88.4,92.0,95.6,97.3,97.9,97.4,95.4,93.7,92.0,89.2,86.9,85.2,81.9,80.5,80.0,79.7,79.2,78.8,78.3,78.3,78.4,79.5,84.5,88.3],"precipitation_probability":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"relative_humidity_2m":[47,41,37,32,29,28,29,31,33,41,47,51,57,59,62,64,65,67,68,70,72,72,66,53],"cloud_cover":[0,0,0,0,5,2,9,31,20,0,9,54,51,38,0,50,44,56,65,84,81,71,54,52]},"daily_units":{"time":"iso8601","sunrise":"iso8601","sunset":"iso8601"},"daily":{"time":["2025-04-14"],"sunrise":["2025-04-13T20:10"],"sunset":["2025-04-14T08:59"]}}"""
DEFAULT_LOCATION = """{"lat": "28.53933",	"lng": "-81.38325",	"description": "Orlando, FL, USA",	"locality": "Orlando",	"place_id": "???",	"timezone": "America/New_York"}"""
API_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&daily=sunrise,sunset&hourly=wind_direction_10m,temperature_2m,wind_speed_10m,rain,wind_gusts_10m,uv_index,showers,apparent_temperature,precipitation_probability,relative_humidity_2m,cloud_cover&timezone=%s&forecast_days=1&wind_speed_unit=mph&temperature_unit=fahrenheit"
CACHE_NAME = "%s_%s_CycleCast_CacheXXXX_%s"

#Weather Elements
SUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAASElEQVR4Aa1SQQoAIAgb0gf7/7GHGB08xdqKBBGc21AESOToybDAQ4SjfMQLWLXSEdwGrgms36SSELSd5IBNsK+nHKzdv7/RBFeDVlFpPWcXAAAAAElFTkSuQmCC
""")

CLOUD_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAq0lEQVR42mJgoBJgxCa4atUqByAVD8QKQPwAiBeGhYUdIMkgoCHzgVQCFrWJQMMWEGUQ1CX7ifDJBSB2BBr8ASbAhKYgnsggMQDifmQBJiTXgMLDgYTwVcAwCGgIyIbz6JKEXAXU14DuovVALEBijIPU1wMN60c2SIGCJFSALbDJAqDwhRn0gAJzPgCTwQOYQYEgATINKkRJkNDorychvD5As84GBmoCgAADACo0LGmMFE1wAAAAAElFTkSuQmCC
""")

RAIN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAARCAYAAADdRIy+AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPBBMhevOvbAAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAH0SURBVDjLrVRNSFRhFD33fm9mejPjGyMQnSgh2lToznYthIRo1R8UxDjVKqII3Ri5CWoT7YZpU4tMjCDcCONGoUXtpIUbhRY2mEWBVvrG0Zn3vu/dFor9zbOp8SzvPfdw7vk+LqFOOL35LhD6IBIH0Yj79PpoLR7VKsbP93Pq4sAZYtUDwBajy9U3U1m98MHeIgXmijt848lfBdOFxXaAxkF05Pee+bokldevIJ5PEHkHovui/enSyM2pmoKto/PNbCenAbSHrR4sf5O1yYlfZ0Umg/XSudUXt1z+mcwxe3A7MQDg5t0U7ewQ1doCikVlwxb1sJ0c/sNhurD4HsT76n0oGAPv7az2ZmatTaf7LQBoG/t0lJR1+Z/EAEApRA93WEFlXfRckUDUYrWNfT5BljUOEOM/ETlwEHquCKmWP1K6sPQSRN1oFEGwJsY/ZYHIwU6AOU6IPGYxegI7B2IYfReBGQIgDUmJuKK9q1vfJpm5rWKdx+KcTBElHOZEioiZTWlZSaWs4FcVREhECBIQiIWiu7RK7fHMyhd/5d4F11sohptysvmzTjZ/EgDs49fg9Oae/+g9HAqNcpsl+kR78wAQSR/qBikbAJoyuS4Q9oYNWeGRyKPSs/6ZzagvAbJxWSRYFYPBhvJuyuQeJE7fUfVwvwMdyrmmoIoMHgAAAABJRU5ErkJggg==""")

WINDSOCKS = {
    "1": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPATI4lMzQpAAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAPySURBVEjHbZU9bBxFFMd/87G7d2f7/EEMwsISIQV0oSIpkCggBRQUUZp0FKBEQqJACrSgSBSREB9CSkHBR4fSJBJIhDY1EnShQWBhK7FDwtm+24/ZN0NxN+u9daa5mZvd92be/v7/p+q6xhiDiACgtUYpRQgB7z3GmGYe9+Kz7feMMQDH9nTciH967wGa4O153GsHfNw8ro0xWBGZe2B046vw4Ntrzbp//rLqX3iXZPZiWk3Qw7W5gO0Y8QZx2PbiYJKH27/9wbnUstRLqOqKkFlMNqCuSwrn2Lv+Ee7OLQKgRBh8+DXZ6bNYa0nTDLV1l2zzFGZxGRHBxsyHkzx89t0PvJEGlPIgglEKmySkCz2gB8DSyhBZSNHGIFVF+uQ6yfo6o9GISmoeXX2b+tF9CLMbfHL9m7D3cETlKq5ceovV23uUv2swBsTTHUrRlEIpRZIkACwvLwPQW+oTyhRjDP+MK+zewxGV92xt77CyuIDznlyEpAp470gKhyqFKlQkJmFcOLxzTYlCWZGWgsMxyHqUpSDOoUWonMOWVcH2vV1OrA0ZTXL6IVA5R6ks3gtVVVLnBd47ysRT1SVe5CjBeEKZF4DgxFBQQxAMgUIEffniBU6srXHmxdN8f+sX/vxri2RWDq2n5ET+p78apTVGa7QxBMC5gv3DQ/59cJ/dw4KdibAzdmjAOqnBKlaHS1x883VufnyHp7TGGIOrhbqukTynnBzgvCLfP0AmDq3BO+H5tVWyvmWnKFgYDFi98jnZxkmyjWfRWmNDCAFBiUhY7GX63AubYfdXCfu1KPEENTpgWIzppSlL/R75K+fJ3rvWYHnvnZcbanLguR//ntOE1Vo3FqG1RmrhmRt3SYwJxhj2vvgAd+ksh8BYhJOf3pzD8ukONVrrRvHGGGwIobGDEALLmQ0mG6gorI0O910s/+tQo5RCRZbhKIHWmhACvY6wqg734w6WXWrafhVCwMZs0S2lI6xj3Hew3D0sqCeC0YKeHTSO+A3UrF5KKUVxJKyQmISyw30ywzIvS7zfZ3NGzWDz1DHVW2ux7SvVdc34SFiqTHzDfTzXQhfLM6815Yi9ot0njpXIGKO01iGEqbDud7iftMwsB9Z/3j528naSJkFUazUVlorCWutwr98/N4dlPHm8RYzzWExFhL3RQZgJSy31e2E4nrdj1cFy3mmnrXbuO7QxNcawIoWaCSuMRdQTX/40x/29Dpbdbqa1ni9RzOS9x3vPxsowyEKqorC63HextNbOJWmLDJhaRXRMYwyiUG1hTTrcb7bMrN3LHzemTb8WyrLEOYeIMC5c8M6pRlgd7k++9GpDXLssscztpi8i/A8ffNzRfqUoXQAAAABJRU5ErkJggg==",
    "2": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPATIXPx3t/QAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAJFSURBVEjH1VW/axRBFP7em929XC53lxw5RUVs7bTTThBsrCSkERvBIgEhnY3WNoGAVcogFlpbxr9CyzRBAgnR05C78253ZvbNs7gkEr0tdrVxmt1ZZuf78d58A/zvg37/8P3dK/32ev1sXl9aRX35qcbGwBiDZrPJZQDOLR6Mxrr9cQedJMK1Vh2XZg3atUjrtVkCQJn3VFZBdPpyPBjqxtZb3E8URAEQgSFCFMdIGjMAZipZFL3c3NLeUR/PNzbxbOUxFrZ7sJ8YMAaQ8Nc1iHpHfbgQsLd/gPm5BnwISEUQO0UIHnHmQVbg1Gls4vIA1mXYP/yKxU4L/XGKuiqc97AUIQSBcxZ5miEETzYur4hXHy5jsdPBrZs38Ob9B+x+3sMpT2YDYwwxsxKRMrOWBvCSAxFhodXE2qMH2LEMZYYxBkEVLs+RpikNj4+pd9gr3UWsqgoBRETn5xp07/pV9J3owSjDYRq01x/qOBtpnCToLDRLK4iY+cSOyfPKkxfnWO7ezdSv3MYPQEci5c+B6oRUCNMLeHm+pdJIiI2BOIcqFp1T8EeW0CRORAREVL5NT38qUjDKvAbvSQGQCKrUgADAGDOVns0tBRFUBihi/ssiVmIGT0nef2LRl8GQZOzBDAQv1QGKity5s4Ta2jqiKEKS1IC5RrUuKlJw8UIX3W4XzAwnOSqfgyIFcTxJpna7XSmuz3YtbFPr4K1gbLNq9wGfBFuRgnQ0hk0zAAIvpjyA5AJrLbz3UxcoAO8zpNYihEFpgJ99lxZhpYb1AgAAAABJRU5ErkJggg==",
    "3": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPATEF54nPdgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAOuSURBVEjHfZU9bB1FEMd/s3v33rMd27EVByWSJSAFdKEiFEgUkAIKiihNOkAgIiHRRQgqUCSKNFAgpaDgo0M0RKIgtKmRoIMGQYQtxw4Jzx/vPvZmhyJvL/fOTqbZ2ZvZmZ25/85fmqbBe4+qAuCcQ0QwM2KMeO9bPdmSb/ec9x7gkM0lQ/oYYwRog3f1ZOsGPEpPe+89marOOIy//8Lufn2t3c9duMzcxfcsnx4c1BPc0qrrBuzGSBUkybqbvUlhN3/9g/ODjMVRTt3U2DAzP5yXpqkoQ2Dn+seEWzfMwERV5j/4UoZnXyDLMgaDIXL7d4brZ/DHllFVspR5f1LYZ998x2sDQySCKl6ELM8ZLIyAEQCLx5dMFwbivEfrmsHJNfK1NcbjMbU23L/6Ns39O2DTCj69/pXt3BtTh5or777Bys0dqt8ceA8a6YsIklohIuR5DsDy8jIAo8U5rBrgveefg5ps596YOkZub2xy/NgCIUYKVfLaiDGQlwGplNpqy33OQRmIIYgBoopVNYNKCQTmhyOqStEQcKrUIZBVdcnG1jYnVpcYTwrmzKhDoJKMGJW6rmiKkhiDVHmkbiqiKm2CgwlVUQJKUE9JA6Z4jFIVd/nSRU6srnLuubN8e+Nn/vzrNvm0Hc55vPfinDMRsQerM3HOvHPivMeAEEp29/f59+4dtvdLNifK5kHAAVnQBjJhZWmRS6+/yg+f3OIJ5/DeExqlaRq0KKSa7BGiUOzuoZOAcxCD8szqCsO5jM2yZGF+npUrnzM8/RTD00/inCMzM0MRVbVjo6E7/+y6bf+ittuoaMRkvMdSecBoMJDFuZEVL12Q4fvXWlhuvfNii5oCePrHv2feROaca0eEc47Tb30kp978sB0XItIiyMxoTq5ZF5aneqhxzrUv3ntPZmbtOEj646QPy/96qBGRmUu1CZxzh258lBz0YNlHTXdemRlZCtidlt1Kkp78ih4st/dLmonineKmF02S/oFM+yUpSH99+IqlhWVRVcS4y/oUNfPrZw5Vm2UZWbekxA3dgH1Z6MPy3CttpYkrujxxZIseJ1udYVYAaz9tHPLpJmkTdIN3+95HVh+WXWCY2Uwc7z2uC9NU1lG9T2tVKUUITOqaOoQj/briujBN/GtmqOoMOyW9pCGY0qCUU58UI/l015bRYowzPCwiR/7wPiyzLJuhzH4VWbp5Wh/FtUnWHw4z6dv68oD0G6WqKkIIjyTvrn78+ZclIS7ZuvOsf+5/krB53+r86LcAAAAASUVORK5CYII=",
    "4": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAS81FRHABQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAOJSURBVEjHpZW7jxxFEIe/6u7Z1/nufCcb5JNOAhxAZkRi/gAcQECAnJgIEJItEVsIBwiEREACgSUHBDwyRIIlEpM6RoIMEgssfMJ3xtbeY3dmeqqLwNvD3N7ysKikq6aqflOvrpamafDeo6oAOOcQEcyMlBLe+5bPumzb9fPeAxzRuazIH1NKAC14l8+6LuAiPsvee4KqHjIYf33V7n3+USsPX7nE8PxbVswce/UEt7LuuoBdjJxBptAV9iZTu/HDz5zrBZYHBXVTY/1gvj+SpqkoY2Tn2nvEm9fNwERVRm9/Sv/M84QQ6PX6yO2fpL95Gn9sFVUl5D/vT6b28Rdf8VLPEEmgihchFAW9pQEwAGD5+IrpUk+c92hd03vsJMXJk4zHY2ptePDBmzQP7oLNMvjw2me2c39MHWsuX3yNtRs7VD868B40MU8iSC6FiFAUBQCrq6sADJaHWNXDe89vBzVh5/6YOiVu39ni+LElYkpMVSlqI6VIUUakUmqrrfAFB2UkxSgGiCpW1fQqJRIZ9QdUlaIx4lSpYyRUdcmd37c5sb7CeDJlaEYdI5UEUlLquqKZlqQUpSoSdVORVGl/cDChmpaAEtVT0oApHqNUxV26cJ4T6+ucffYMX17/jlu/3KaYlcM5j/denHMmIvbwdCbOmXdOnPcYEGPJ7v4+f9y7y/Z+ydZE2TqIOCBEbSAIayvLXHj5Rb55/yaPO4f3ntgoTdOg06lUkz1iEqa7e+gk4hykqDy9vkZ/GNgqS5ZGI9Yuf0J/40n6G0/gnCOYmaGIqtqxQd+de2bTtr9X221UNGEy3mOlPGDQ68nycGD9i+8yvHIVNxg5EeHWq89Znpop8NS3vx66E8E5164I5xwbb1yRU6+/064LEWknyMyQ9bWWBzg1NzXOufbGe+8J2TCl1Do9Cs1PjYgcCqr9gXPuSMT/heanpruvzIyQAbvbsptJ5rPdfJbb+yXNRPFOcbNAM+UeyKxekkHmz79u8dHsNmdTM9o8fUQZQiB0U8pvwz8BHmq4CGtnX5CunDdr+74sKtF8ox6Vuuu77UEGn6/7oslaZJflLo73Htcd05zW39X+33qyKGvXHdP8/poZqnrodcp81nXtMka26Z7tTKWUSCkd6oH3/kj0ZtYGIiKEEFq/RVm4HHk+59/a/0Pee5w2SlVVxBgXlmSed849TH12obp81nX9/gRO8UFjXyhwYgAAAABJRU5ErkJggg==",
    "5": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQOFDkyNbzmjwAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAANtSURBVEjHpZU7jBxFEIa/6prZ3dt7n3xYnGQJREJmMghJHEBAgJw4A4RkS8QWwgECIRGQQGDJAQGPDJHg0KSOkSCDBKETPuE7Y2vvsbszPdVFcNfD3N7CCVHSqKumqqvr/7u7WpqmQVUxMwBCCIgI7k5KCVVt9ezLsd15qgpwxheyI/9MKQG0ybt69nUTztOzraoUZnYqYPTtbX/05SetvfD6DRauvuPlycRePSasbIRuwm6OjCBL0TUOxhO/9+MvXOkVLA9K6qbG+4VrfyhNUzGNkb07HxDv33UHFzMZvvs5/csvURQFvV4f2f6Z/qXn0KVVMTOKvPLheOKffvUNr/YckQRmqAhFWdJbHAADAJbXVtwWexJUsbqm99Qm5eYmo9GI2hqefPQ2zZOH4DhA8fGdL3zv8Yg61ty8/gbr9/aofgqgCpaYFREkUyEilGUJwOrqKgCD5QW86qGq/H5UU+w9HlGnxPaDHdaWFokpMTGjrJ2UIuU0IpVRe+2llhxNIylGcUDM8KqmVxmRyLA/oKoMi5FgRh0jRVVPefDHLhc2VhiNJyy4U8dIJQUpGXVd0UympBSlKhN1U5HMaBc4GlNNpoARTZnSgBuKMzUj3Lh2VS5sbPDiC5f5+u73/PrbNuUJHSEoqiohBBcRPx6DSwiuIUhQxYEYp+wfHvLno4fsHk7ZGRs7R5EAFNEaKIT1lWWuvfYK3314n4shoKrExmiaBptMpBofEJMw2T/AxpEQIEWj3N2lvDhi2O+zOByyfvMz+lvP0t96RkIIFO4OBmbmS4N+uPL8Jd/9wXy/MbGEy+iAlekRg15PlhcG3r/+Pgu3bhMGw5Bv/N8HQGjWXj51J4oQQtsiQghsvXVLnn7zvbZdiEibwN2RjfVW7ybOdgihvfGqeoLgpB10J50nZxY+sUXklK/orjxb8b/JbNJsd/uVu1PkoG637CLJeo47D2Wm/MweqKp0K5qlYZ49L/YUPUVB6EJqmgZ3b7/zKJpn525qZsfvwTyKZjfqv0q3fbd7kJPP8j4Pyby4bHfzqCqhe0wzvH/i/rw9mYc6dI9pfn/dveWwCztXaWan4ubxn8f2TKWUSCmd2gNVPVO9u7eFiAhFUbTz5qEIufI8zr61/0dUlWCNUVUVMca5lMzqIYRj6Cf3p6tnX3feX5iRM6+9RAk9AAAAAElFTkSuQmCC",
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

WINDROSE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAYAAADgKtSgAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6QQPAzozyENXSgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAUASURBVEjHrZV/TBNnGMffUsDaK6W09IfX0tYrFEK0CyCUmmibGWNgWXS4aLZFM/fHFn/sR0aWTc2SLSxxyfYX0Sw6N11mXIYZLLNua4AC6mZrW1xpHdgToV1pr17ver0WroX2bv9sBl1EsvhN3n/e930+efI83zwPD4ZhsBoplUrVlStXxjZt2lQPVqmS1X602+0t69atM548eVL31OEikWgrAABYLBbramN4K5VlYGBAqFQqD1ZVVT0vEAha+Hy+qFgs4gzDXJ+ZmRlramrqhWGYe1x86aMXN27c6IlGo39WVFQoNBrNOwRB/DoyMtJts9m+FIvFXDabLR8eHv7KarXuJAhiempq6k2RSLRx7dq1KZvNdnrFsmSz2bTZbP6mrq7u86GhoYNWq/Wg2WxW5HK5CR6Px3Ecl5PL5QGTyfR6MBg809zcbG9sbDyxtLR0+4mZr1mzJpPP50tRFD2/ffv2L3w+37lCoYAAABwAgA2FQsGp1WpfHB8f38hx3JZwOPx9TU3NHoqi+Cs2tKenRy2VSj/wer0vaTSalgMHDmxhWbaqurp6/+Dg4BAAAOA4PqhQKD5mGCZ48eLFDplMttXj8ew2Go1nWJZ9mA7D8IMTj8ePTU9PfwrDMCAI4nQoFOru6OjQYBgWhmEYcBznValUapIkQzqdThiLxb7GMOwQDMMAx/EBn8/3wnLeQ24JBAJ/OByOPXq9vkYul+9Xq9X7aJomIAiiEolEp8Fg+M7v93+4fv36CwzDlIhEospIJHKCJMkBvV6vFYvF1oaGhrcfAA0Gg9Dv97cSBHEsl8vN4zgeTSaTP8RisTdcLlctgiBlo6OjO1OpVHhpaSlJEER0fHy8AUEQ/ujoqCUajb5PkuQwQRBzDMNEY7HYWy6Xa4NerxfwMAwjlEqlFAAA4vH4YiqVwnk8XvHR5igUigqZTFY1NzdH0TRNP/rOsmypRqOprqysLAcAABRFQ6C2tpbn9Xrb/8k8k0qlUBzHf0omk6/6fD4EhmHgdrt3kCQ5l8vlsjRNo5OTk7UIgoBbt249Q5LkERzHr5Ek+Vc2m00kEolDTqezWaPR8B4UXyqVgkwmc72/v9/gdru3RiKRU/l8PpdOpycpiopcvnx5M8dxXofDsZ+m6SRFUXfn5+eLMzMzR/1+/4bZ2dm9CwsLny1v6ENuyWQyhxKJxFEYhkEikTiPouh77e3tbQRB3P7XLUqlUk4QxF21Wq2OxWLnwuHwuzqdDqRSqb579+49+1h4b2+v9v79+9jVq1f3kiTpOXz4sCQcDp8qFAoL/f39VRzHeQOBwA6GYag7d+4cR1FUnEwmo2NjY7sxDAstZ/3HigAA4PV6X5FIJBeCweAlBEE2MwxztlAo1LEsO4ggyBGSJAfj8fiiRCJBysvLmzEMm62vr7f5/f5tu3btcq04W/L5vLisrAyYTKbdbrf7ZbPZ/JFQKLygUqk2AgAABEEtJEmebWtr2xcMBvuMRmNHSUmJEIIg/hNnC03TzRMTE10CgUBusVi+9Xg8l5xO5y+dnZ22YrHIz2QyyOLiYsPU1NRxlmW33Lx58zmtVluTyWS2AQB+W/U87+7uFnd1db0mlUo7IAhqAQDIWJZNMAwzQlHUQGtr64+lpaWL/2tZLFcoFPoEgqDj6XR6b2NjY99TXXM0Tf8OAAA+n+/aU1lzy6VWqzV2u/3npqYm02rhfwMyRI4VD1oUSwAAAABJRU5ErkJggg==""")
DIRECTIONAL_ARROW = base64.decode("""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""")

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

    if local_weather_data == None:
        print("New Data")
        response = http.get(local_api_url, ttl_seconds = seconds_remaining_in_day(timezone))

        if response.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (local_api_url, response.status_code, response.body()))
        else:
            local_weather_data = response.json()
            cache.set(local_cache_name, json.encode(local_weather_data), ttl_seconds = seconds_remaining_in_day(timezone))
    else:
        print("From Cache")
        local_weather_data = json.decode(local_weather_data)

    return local_weather_data

def get_two_digit_string(number):
    if (number >= 10):
        return number
    else:
        return "0%s" % number 

def get_current_condition(data,  element, item_name, add_units = True):
    if add_units:
        units = data["hourly_units"][item_name]
        display_tempate = "%s%s" if units == "mm" or units == "%" or units == "°F" else "%s %s"

        return display_tempate % (data["hourly"][item_name][element], units)
    else:
        return data["hourly"][item_name][element]

def get_uv_index_category(index):
    category = ""
    index = float(index)
    if index > 10:
        category = "Extreme"
    elif index > 7:
        category = "Very High"
    elif index > 5:
        category = "High"
    elif index > 2:
        category = "Moderate"
    else:
        category = "Low"
    return category

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_information_marquee(message):
    
    marquee = render.Marquee(
        width = 64,
        child = render.Text(message, color = "#ffff00", font = "CG-pixel-3x5-mono")
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

    # Map the phase to a description
    if show_description:
        if phase < 1.84566:
            return "New Moon"
        elif phase < 5.53699:
            return "Waxing Crescent"
        elif phase < 9.22831:
            return "First Quarter"
        elif phase < 12.91963:
            return "Waxing Gibbous"
        elif phase < 16.61096:
            return "Full Moon"
        elif phase < 20.30228:
            return "Waning Gibbous"
        elif phase < 23.99361:
            return "Last Quarter"
        elif phase < 27.68493:
            return "Waning Crescent"
        else:
            return "New Moon"
    else:
        if phase < 1.84566:
            return 0
        elif phase < 5.53699:
            return 1
        elif phase < 9.22831:
            return 2
        elif phase < 12.91963:
            return 3
        elif phase < 16.61096:
            return 4
        elif phase < 20.30228:
            return 5
        elif phase < 23.99361:
            return 6
        elif phase < 27.68493:
            return 7
        else:
            return 0

def calculate_julian_date(year, month, day):
    # Convert Gregorian date to Julian date
    if month <= 2:
        year -= 1
        month += 12

    A = year // 100
    B = 2 - A + (A // 4)
    julian_date = (
        int(365.25 * (year + 4716))
        + int(30.6001 * (month + 1))
        + day
        + B
        - 1524.5
    )
    return julian_date

def get_wind_sock_category(wind_speed):
    if wind_speed > 17.26:
        return 5
    elif wind_speed > 13.81:
        return 4
    elif wind_speed > 10.36:
        return 3
    elif wind_speed > 6.91:
        return 2
    else:
        return 1

def get_wind_rose_display(direction):
    return animation.Transformation(
        child = render.Image(src = DIRECTIONAL_ARROW),
        duration = 25,
        delay = 10,
        origin = animation.Origin(0.5, 0.5),
        keyframes = [
            animation.Keyframe(
                percentage = 0.7,
                transforms = [animation.Rotate(direction+10 % 360)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 0.85,
                transforms = [animation.Rotate(direction-10 % 360)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Rotate(direction % 360)],
                curve = "ease_in_out",
            ),

        ],
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
    instructions_1 = "This was developed to display helpful information when planning a bike ride. However, it can certainly be used for any outdoor activity."
    instructions_2 = "The source for this app is Open Meteo, go to https://open-meteo.com/ for more information. The information is based on your location.  Displays a wind rose to indication the direction the wind is "
    instructions_3 = "coming from, then a wind sock to show the strength of the wind. There are also some weather icons to give you an idea of rain, clouds and the current moon phase if it is evening.  "
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

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    # Get location needed for local weather
    location = json.decode(config.get("location", DEFAULT_LOCATION))

    # Round lat and lng to 1 decimal to make data available to more people (within about 11km x 11km area) and to not give away our users position exactly
    latitude = round(float(location["lat"]),1)
    longitude = round(float(location["lng"]),1)
    timezone = location["timezone"]
    current_time = time.now().in_location(timezone)

    # use the real lat and long to get a more accurate sunrise/sunet time. This info isn't shared with anyone but the user
    sunrise_time = sunrise.sunrise(float(location["lat"]), float(location["lng"]), current_time).in_location(location["timezone"])
    sunset_time = sunrise.sunset(float(location["lat"]), float(location["lng"]), current_time).in_location(location["timezone"])

    #Dumb Down the current Time to work with the simpler time format of the API
    simple_current_time = time.parse_time("%s-%s-%sT%s:%s" % (current_time.year,get_two_digit_string(current_time.month),get_two_digit_string(current_time.day), get_two_digit_string(current_time.hour), get_two_digit_string(current_time.minute)), format = "2006-01-02T15:04")
    local_data = get_weather_data(latitude, longitude, timezone)

    # Let's look for the closest entry in 'time' to pull out current conditions
    hour_periods = local_data["hourly"]
    closest_element_to_now = 0
    smallest_difference = 24 #Just need to seed this with a high number (only 24 hours in a day) 

    # in the stored data, let's find the closest time period to now
    for i in range(0, len(hour_periods["time"])):
        time_difference = simple_current_time - time.parse_time(hour_periods["time"][i], format = "2006-01-02T15:04")
        if abs(time_difference.hours) < smallest_difference:
            smallest_difference = abs(time_difference.hours)
            closest_element_to_now = i

    # based on the time period, pull out the current conditions 
    current_cloud_cover = get_current_condition(local_data, closest_element_to_now, "cloud_cover")
    current_humidity = get_current_condition(local_data, closest_element_to_now, "relative_humidity_2m")
    current_probability_precipitation = get_current_condition(local_data, closest_element_to_now, "precipitation_probability")
    current_temperature = get_current_condition(local_data, closest_element_to_now, "temperature_2m")
    current_apparent_temperature = get_current_condition(local_data, closest_element_to_now, "apparent_temperature")
    current_showers = get_current_condition(local_data, closest_element_to_now, "showers")
    current_uv_index = get_current_condition(local_data, closest_element_to_now, "uv_index", False)
    current_wind_gusts = get_current_condition(local_data, closest_element_to_now, "wind_gusts_10m")
    current_wind = get_current_condition(local_data, closest_element_to_now, "wind_speed_10m")
    current_rain = get_current_condition(local_data, closest_element_to_now, "rain")
    current_wind_direction = get_current_condition(local_data, closest_element_to_now, "wind_direction_10m", False)

    print(current_wind_direction)
    print(get_cardinal_position_from_degrees(current_wind_direction))

    message = "It is %s but feels like %s with cloud cover of %s and humidity of %s. The probability of precipitation is %s, expect %s of rain. The UV index is %s (%s) with winds from the %s at %s gusting to %s." % (current_temperature, current_apparent_temperature, current_cloud_cover, current_humidity, current_probability_precipitation,current_showers, current_uv_index, get_uv_index_category(current_uv_index), get_cardinal_position_from_degrees(current_wind_direction), current_wind, current_wind_gusts)
    print(message)

    display_items = []

    if current_time > sunrise_time and current_time < sunset_time:
        # print("Daytime")
        display_items.append(render.Box(width=64, height = 26, color = "#004764"))
        display_items.append(add_padding_to_child_element(render.Image(src=SUN_ICON),48))
    else:
        # print("NightTime")
        display_items.append(add_padding_to_child_element(render.Image(src=base64.decode(MOON_ICONS[str( moon_phase(current_time.year, current_time.month, current_time.day, False))])),43, -2))

    #Display Rain if Raining 
    if get_current_condition(local_data, closest_element_to_now, "rain", False) > 0:
        display_items.append(add_padding_to_child_element(render.Image(src=RAIN_ICON),40,6))
    elif get_current_condition(local_data, closest_element_to_now, "cloud_cover", False) > 0:
        display_items.append(add_padding_to_child_element(render.Image(src=CLOUD_ICON),40,6))

    # Display The Windsock
    display_items.append(add_padding_to_child_element(render.Image(src=base64.decode(WINDSOCKS[str(get_wind_sock_category(float(get_current_condition(local_data, closest_element_to_now, "wind_speed_10m", False))))])),25))

    # Marquee
    display_items.append(add_padding_to_child_element(get_information_marquee(message),0,27))

    # Wind Direction
    if (get_current_condition(local_data, closest_element_to_now, "wind_speed_10m", False) > 0):
        display_items.append(add_padding_to_child_element(render.Image(src=WINDROSE_ICON),1,1))
        display_items.append(add_padding_to_child_element(get_wind_rose_display(current_wind_direction),9,1))

    return render.Root(
        render.Stack(
            children = display_items
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
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The location used for gathering weather data.",
                icon = "locationDot",
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
