load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

CORPORATE_BS = "https://corporatebs-generator.sameerkumar.website/"
CORP_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAfcAAAHXCAYAAACh2RMRAAANg0lEQVR42u3Xwa2CUABEURqwERc0QcLWJuiEXmjFsjQuXLkiUcYwZ5JbgHx45/1hMDMzMzMzs917BDMzMzO4m5mZGdzNzMzgDnczMzO4w93MzAzuHr2ZmRnczczMDO5mZmZwh7uZmRnc4W5mZgZ3uJuZmcHdzMzM4G5mZgZ3uJuZmcEd7mZmZnCHu5mZGdzNzMwM7mZmZnCHu5mZGdzhbmZmBne4m5mZwd3MzMzgbmZmBne4m5mZwR3uZmZmcIe7mZkZ3M3MzAzuZmZmcIe7mZkZ3OFuZmYGd7ibmRlcf999GWOlf7tXz8zM4A53MzMzuMPdzMzgDne4m5kZ3OEOdzMzgzvc4W5mZnCHu5mZGdzhbmZmcIc73M3MDO5wh7uZmcEd7nA3MzO4w93MzAzucDczM7jDHe5mZgZ3uMPdzMzgDne4m5kZ3OFuZmYGd7ibmRnc4Q53MzODO9zhbmZmcIc73M3MDO5wNzMzgzvczcwM7nCHu5mZwR3ucDczM7jDHe5mZgZ3uJuZmcEd7mZmZnCHu5mZwR3ucDczM7jDHe5mZgZ3uJvZeQ47VVb7vm/TJVbyYvEHlwszuEtwhzvczeAuwR3ucDeDu+AOd7jD3Qzugjvc4Q53M7gL7nCHu2Pe4C7BHe5wN4O7BHe4w90M7oI73OEOdzO4C+5whzvczeAuuMMd7nA3uEtwhzvczeAuwR3ucDeDu+AOd7jD3Qzugjvc4Q53M7gL7nCHO9wN7hLc4Q53M7hLcIc73M3gLsEd7nA3g7vgDne4w90M7oI73OEOd4O7BHe4w90M7hLc4Q53M7hLcIc73M3gLrjDHe5wN4O74A53uMPd4C7BHe5wN4O7BHe4w90M7hLc4Q53M7gL7nCHO9zN4C64wx3ucLd2YNMfvPpyuen81uFucIe74C64w93gDnfBXXCHu8Ed7oI73OFuBncJ7nCHuxncJbjDHe4Gd7gL7oI73A3ucBfcBXe4G9zhLrjDHe5mcJfgDne4m8Fdgjvc4W5wh7vgLrjD3eAOd8FdcIe7wR3ugjvc4W4GdwnucIe7GdwluMMd7gZ3uAvugjvcDe5wF9wFd7gb3OEuuMMd7mZwl+AOd7ibwV2CO9zhbnCHu+AuuMPd4A53wV1wh7vBHe6CO9zhbgZ3Ce5wh7sZ3CW4wx3uZnAX3AV3uBvc4S64C+5wN7jDXXCHO9zN4C7BHe5wN4O7BHe4w90M7qHW6xBrmy7RWv/m6efeHNwN7nCHO9zhDne4G9zhDne4wx3ucDe4wx3ucBfczeAOd7jDXXA3gzvc4Q53wd3gDne4wx3ucIe7wR3ucIc73OEOd4M73OEOd8HdDO5whzvcBXczuMMd7nAX3A3ucIc73OEOd7gb3OEOd7jDHe5wN7jDHe5wF9zN4A53uMNdcDeDO9zhDnfB3eAOd7jDHe5wh7vBHe5whzvc4Q53gzvc4Q53wd0M7nCHO9wFdzO4wx3ucBfcDe5whzvc4Q53uBvc4Q53uMMd7nA3uMMd7nAX3M3gDne4w11wN4M73OEOd8HdDO5whzvc4Q53gzvc4Q53uMMd7gZ3uMMd7pCFuxnc4Q53uAvuZnCHO9zhLribwR3ucIc73OFucP9eDptMyYuFOi91YVzhbnCHO9wFd7jD3eAOd7gL7nCHu8Ed7nAX3OFuBne4w11wh7sZ3OEOd8Ed7gZ3uMNdcIc73A3ucIe74A53uBvc4Q53wR3uZnCHO9wFd7ibwR3ucBfc4W5whzvcBXe4w93gDne4C+5wh7vBHe5wF9zhbgZ3uMNdcIe7GdzhDnfBHe4Gd7jDXXCHO9wN7nCHu+AOd7gb3OEOd8Ed7mZwhzvcBXe4m8Ed7nAX3OFucIc73AV3uMPd4A53uAvucIe7wR3ucBfc4W4Gd7jDXXCHuxnc4Q53wR3uZnCHu+AOd7gb3OEOd8Ed7nA3uMMd7oI73M3gDne4C+5wN4M73OEuuMPd2nF9dV/GWHCXBHeDO9zhLgnuBne4w10S3A3ucIe7JLgb3OEOd0lwN7jDXRLcDe5wh7skuBvc4Q53SXA3uMMd7pLgbnCHO9wlwd3gDncHngR3gzvc4S4J7gZ3uMNdEtwN7nCHuyS4G9zhDndJcDe4wx3uEtwN7nCHuyS4G9zhDndJcDe4wx3ukuBucIc73CXB3eAOd7hLcDe4wx3ukuBucIc73CXB3eAOd7hLgrvBHe5wlwR3gzvc4S7B3eAOd7hLgrvBHe5wlwR3gzvc4S4J7gZ3uMNdEtwN7nCHuwR3gzvc4S4J7gb3/a3XXM24q6/kRbq94ou8wR3uEtzhDneDO9wluMMd7gZ3uAvugjvc4Q53Ce6CO9zhDncJ7oI7XuEOdwnucIe7wR3uEtzhDneDO9wFd8Ed7nCHuwR3wR3ucIe7BHfBHe5wh7sEd7jD3eAOdwnucIe7wR3ugrvgDne4w12Cu+AOd7jDXYK74A53uMNdgjvc4W5wh7sEd7jD3eAOd8EdsnCHO9zhLsFdcIc73OEuwV1whzvc4S7BHe5wN7jDXYI73OFucIe7BHe4wx3ucJfgLrjDHe5wl+AuuMMd7nCX4A53uBvc4S7BHe5wN7jDXYI73OEOd7hLcBfc4Q53uEtwF9zhDvd3yZc+ebGQjg6unWcN3OEOdwnucIc73OEOdwnucIc73OEOdwnucIe7wR3uEtzhDneDO9wluMMd7nCHuwR3uMMd7nCHuwR3uMMd7nCHuwR3uMPd4A53Ce5wh7vBHe4S3OEOd7jDXYI73OEOd7jDXYI73OEOd7jDXYI73OFucIe7BHe4w93gDncJ7nCHu8Fdgjvc4Q53uMNdgjvc4Q53uMNdgjvc4W5wh7sEd7jD3eAOdwnucIe7wV2CO9zhDne4w12CO9zhDne4w12CO9zhbnCHuwR3uMPd4A53Ce5wh7vB3YEvuMMd7nCHO9wluMMd7nCHO9wluMMd7gZ3uEtwhzvcDe5wl+AOd7gDVlJVcO/EPfm7XSwcPJLgDne4w12S4A53uMNdEtzhDne4w10S3OEOd7jDXRLc4Q53uMNdEtzhDne4SxLc4Q53uEuCO9zhDne4S4I73OEOd7hLgjvc4Q53uEuCO9zhDndJgjvc4Q53SXCHO9zhDndJcIc73OEOd0lwhzvc4Q53SXCHO9zhLklwhzvc4S5JcIc73OEuCe5whzvc4S4J7nCHO9zhLgnucIc73CUJ7nCHO9wlCe5whzvcJcEd7nCHO9wlwR3ucIc73CXBHe5wh7skwR3ucIe7JMEd7nCHuyS4wx3ucIe7JLjDHe5wh7skuMMd7gfgXvvRpV/65gNH0jHN8y1a68UC7nCXJLjDHe5wlyS4wx3ucJcEd7jDHe5wlwR3uMMd7nCXBHe4wx3ukgR3uMMd7pIEd7jDHe6S4A53uMMd7pLgDne4wx3ukuAOd7jD3cEjCe5whzvcJQnucIc73CXBHe5whzvcJcEd7nCHO9wlwR3ucIc73CXBHe5wh7skwR3ucIe7JLjDHe5wh7skuMMd7nCHuyS4wx3ucIe7JLjDHe5wlyS4wx3ucJcEd7jDHe5wlwR3uMMd7nCXBHe4wx3ucJcEd7jDHe6SBHe4wx3ukgR3uMMd7pLgDne4wx3ukuAOd7h/lHz4cJek8/4TBXe4w12S4A53uMNdkuAOd7jDXRLc4Q53uEsS3OEOd7hLEtzhDne4SxLc4Q53uEsS3OEOd7hLgjvc4Q53SYI73OEOd0mCO9zhDndJgjvc4Q53SYI73OEOd0lwhzvc4S5JcIc73OEuSXCHO9zhLklwhzvc4S5JcIc73OEuCe5whzvcJQnucIc73CUJ7nCHO9wlCe5whzvcJQnucIc73CXBHe5wh7skwR3ucIe7JMEd7nCHuyTBHe5wh7skwR3ucIe7JLjDHe5wlyS4wx3ucJckuMMd7nCXJLjDHe46T/N8i+X5S3CHO9wFd0lwhzvcBXdJcIe74A53Ce5wh7vgDncJ7nCHu+AOdwnucIe74C4J7nCHu+AuCe5wF9zhLsEd7nAX3OEuwR3ucBfc4S7BHe5wF9wlwR3ucBfcJcEd7l5+uMNdgjvc4S64w12CO9zhLrjDXYI73OEuuEuCO9zhLrhLgjvc4Q53uEtwhzvcBXe4S3CHO9wFd7hLcIc73AV3SXCHO9wFd0lwhzvc4Q53Ce5wh7vgDncJ7nCHu+AOdwnucIe74C4J7nCHu+AuCe5whzvc4S7BHe5wF9zhLsEd7nAX3OEuwR3ukiSdIrh7CSRJcIe7JElwh7skSXCHuyRJcIe7JElw9wJIkuAOd0mS4A53SZLgDndJkuAOd0mS4A53SRLc4S5JEtzhLkkS3OEuSRLc4S5JEtzhLkmCO9wlSYI73CVJgjvcJUmCO9wlSYI73CVJcIe7JElwh7skSXCHuyRJcIe7JElwh7skCe5wlyQJ7nCXJAnucJckCe5wlyQJ7pIkCe6SJAnukiTBXZIkwV2SJMFdkiTBXZIkwV2SJLh7EJIkwV2SJMFdkiTBXZIkwV2SJLh7CJIkwV2SJMFdkiTBXZIkwV2SJMFdkiS4S5IkuEuSJLhLkiS4S5IkuEuSBHdJkgR3SZIEd0mSBHdJkgR3SZLgLkmS4C5Jkg7tCfZB5aS5poMyAAAAAElFTkSuQmCC
""")

def main():
    phrase = cache.get("corporate_bs")
    if phrase != None:
        print("Cache Hit!")
    else:
        print("Cache Miss!")
        rep = http.get(CORPORATE_BS)
        if rep.status_code != 200:
            fail("Corporate BS request failed with status %d", rep.status_code)
        phrase = rep.json()["phrase"]
        cache.set("corporate_bs", phrase, ttl_seconds = 43200)

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    children = [
                        render.Box(
                            height = 12,
                            color = "000",
                            child = render.Image(src = CORP_ICON, width = 14),
                        ),
                        render.Box(
                            height = 10,
                            color = "000",
                            child = render.Text("CORPORATE BS", height = 10, color = "B74830"),
                        ),
                        render.Marquee(
                            child = render.Text("%s" % phrase, color = "DAF7A6"),
                            width = 64,
                            offset_start = 5,
                            offset_end = 32,
                        ),
                    ],
                ),
            ],
        ),
    )
