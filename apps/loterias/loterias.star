"""
Applet: Loterias
Summary: Loterias do Brasil
Description: Veja os premios das principais modalidades da loteria.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# default values
DEFAULT_MODALITY = "megasena"
DEFAULT_PRIZE = "estimated"
DEFAULT_LOCATION = json.encode({
    "lat": "-23.6139915",
    "lng": "-46.7066243",
    "description": "São Paulo, SP, Brasil",
    "locality": "São Paulo",
    "place_id": "ChIJ0WGkg4FEzpQRrlsz_whLqZs",
    "timezone": "America/Sao_Paulo",
})

CACHE_TTL = 3600

# modalities configuration
MODALITIES = {
    "megasena": {
        "name": "MEGASENA",
        "color": "#4b966d",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAI3SURBVDiNZZI7aBRRFIb/c+exszuzs49oVk3EQhAxviKKIpJYWNkIigqiBNSIwSZFRNDtYizcImARgp0EtBAsLGwiKFHQxi4qiGChmIhs1sw+MrMze4+Nu87enOqe/3zn5/BzCUpdfntjvNaolIi0lpt0xntzfYtE/JBBSQAjU7uKC3FeVw0aa9WpsBXpQKSv1MOZQn5LFYBLYAAoATgc54VqwJAdUyklAXDbPTG7Kr/OwDKSC6rWMYSYUzUqfp48DkaJwCkGPS6X6zOV4OePIPRTADCwbU+b/eCH1rBl+OMEvsBEdQLf1CExB0I/gwDgbk+Pfdqobzi7XFl+HrYi7d/yd5I8Zhn+GwCDDAIYYNAjQeCactUB187N9uUKZywzWQXwjkHnmOgZgEGFrenQcBUSL+JhAdhq2/lbTw5NuwBQ/DT5HoR+Zdljomv60sqv/ZVqOS2l7A7TTO5uv78ufRkImkHXXAiRztu5vXR+/mLQjJpmfGhoeiudylxvBLXp7Zt3LHrV3/eXVstPo1aoxTlTTwSCWXaJCd1qZFOZK17Dm/WbgQPgiOtsfLDJzp9KGFYjzkpITTs6eqwiwUNCaOxYzisn0TP8x195GUahCQC92QJAcK2kvdM0s/u41TzIQJ+h6346lZkgJRiMvB6d99ZWT7T72D8AM92ZGije68pCNfDDtSFV+w/LS+s1pUhQ2BkKwQC8zgVEnsqvM3As+7ahGVHCSPjZdH6MBJ8E8BHAN2KeUPm/3Z7K0pDc1OEAAAAASUVORK5CYII=",
    },
    "diaDeSorte": {
        "name": "DIA DE SORTE",
        "color": "#c1893f",
        "font": "CG-pixel-3x5-mono",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SCTR6vhJbAAAERklEQVRIx5VVbUxTVxh+z72ltKUfjAtIB6MuQ9hAPsOi1FlIQBlsjIUILAhjOmYg0UEcbEy2yJKhzppiAWESQwwYkTE0zgx1uJnApEwHyFKVkU2EQgrIh225tbTce/bHuo3m2vj8fO77Pu9zznnOuQjcYBi3vlmkLSuz/r2onhpVq4kCdIU0MYz4M+oDubasjPox5FRsiV5PdLFidri5GY8AH1mEQsiGJtAUFsoHlLf35vf2cukjdwZ0dQ2FGVk0bY+mw80LIpGTJ26QGo80jENESnVmsMUCuRACC1Lp08ZpmIHwmzfl8cqsfcmbNnHpE+4M4DGmhe3h8dby7BZmv+MyQi6DnSvbDa+B0ZV/bgOe85Jh707uLeTENVSNVW1t7sp4RqzD9TgpCYkgCY6p1XgeyyBNJAJvdBBMZ8/av1kw3j2Tk2O/SN+SUlNT9mjr6/89CpeVJ8FBVD04CHWiKJtMqzV66Abrb1RVwSP8Fcjy8oCGDoikabiEQnBqRQWaebe/qr7HYMBN8BaMBgW5CL4POtANDVnC5toniOrqufZxgf7XCxdWz9szHitIMjR069YdOwDQO1AO5w0GtMjmYs+cHJxIJKOTjY24BszwQ2ysi9MA8IWxiQkC7kM+zC4vc2agFRIgIS5O8ps/XzF94oTf7HptJJWb6/mGV61MYLHAYZQNIzodG0NkEFReHo4k5tAnnZ2cg534ExXB1PIymrbqmuprtmwhmrEXvNzdzRWqp3gyUF6XML3vlFLppI1d/R/Vxw0MgBJ2wS7u1EMH/AWU2UwUwCqL0tJ4C/X3vxx5HBNjYozkg0mJhB1j9jsuPyOUtV6MTLBxI9T9n588OrThp76ICNtRus+czt1PWEmNR5pE4t0XoF//YVQU6t+rZdI9VlYc2bZjtJLP50xrFv+ScIJhJJ/6jwbll5ZaTy8Wz35+5IiiKH5mu12vX0w1pk3WaDSm5InaP861tzu+s2fYXiFJLj1+pYAQB66sELidTWQDn1E44nVXSlmt4nu+zYHdxcXLmrlXDae12pVvrRJzulgMeXg3nNm8mfoiYCg4VaPxqQnujujNyuKPiG5JKauVM1vn2GRGRpJkKbNzSdWwtISBbWNVKhXZTt72MGAson1eWjd3/bqnyc/TtyIx0ap46DejvHrVkWkT0rH/7hRFKRTh4QDwNoTCvFQq/Fpy8YXWsDBBA1WLO6KjmUq7gCePj4cudoIdDwzkfc83CzpsNi+eb+mLg+Xlbp/iwfdaft95padnueThz1OHU1LWfndew7VAJNLizKqqAP+Ejo+DDx3izIQ7Ayu+lthH2SqVuzoXpOBq1FtQ4K7MrQGSR5iIRofDpfHJz8h5rVzOuAXugdyVf24DolyfjHWlBw7wAvnbRNGrq57bhSfFJTab97UAc9CekhJ2D6JhPD0dTKgSfrlzBx7AceCPj2MePo43lJe70/8HZw/LOmG/QGsAAAAASUVORK5CYII=",
    },
    "duplasena": {
        "name": "DUPLA SENA",
        "color": "#98262a",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SCjkvIj0lAAAEPklEQVRIx5VVa0xTZxh+T8+h2EILtQORMsdAGAxSKnGUwrgYWAS2OGFBtMhQLgmwSIrCLBIDXhBHY+USmOGyS4hExhzTCMbxw4zEHWCDMYeGi0C5DRwUkMKB0p5++zHLDOyk8fn5fO/7vM95v/f9DgYW0HwqLurYXoVCd2v0+5G/VSqYIH5k3adpfsJbtq4DCoWLTOYiO9Pfj0KRN0tYUwN6zAn1cDjoNMSbKpOTg/pyv1Kc7+hg0scsGfjmeUB8sHp1db1l6Y/FOi7XzOP1VhJ2AEK+50/0pQTodOAA6WDk8zcTxdg1mO7ultnkzmZ/IZUy6bMsGTBl0TuNFEFs5elUQ99GN4ZtK2z+MiGSAr2df20DXL7DOw4ezC1kAvoYiSG7ocFSHEYiFapE4eEQDgYUrVJBBCjgKJcLH4I1sm9sNFKj6wMPqqufOfeuPfaYmtK3L/7y6lX4+aWnZ2S8ovgQHkJ4Tw9XC0f1fWFhlBx+Z/MVCmgFPbYkl2M/AY2dXF1FY+hndDAvDyNrVU8raicnwRdaYc3FZZtFNsTC1d7eRd6z/cN1RUUztV13yTdbWgzuVBqVgOObBqqgE65NTrJIVip4HzmClkxKSKyuRvcgCRb37dumGwgT0DY+zsJOQT4Mrqww9mgDWkDp7y+4uDfCI7Oqyunye2ypa0IC54BQL5TodNjXsAtKSBLzwfLRC7ncpDS5wifNzYyFzQjDbkL/ygpGflk6UFkcHAwi7BAStLUxDdXmnb0sGFiT92n2TFCQmSdvqy5X+nd2gjNYoxPMUw9zUAvE8jKaZ+1CguhoYsaOLHoEEon20pBkoJvHo1MNtRvdzEPDOSPUCw/4+kINADT+xw9duJ383ayPz1rWQoT2BnP+v+vL4wl2e8m9QsRi1ot7E3Yatlq9uVYMsBrh1nGbaJrX4yQT+eTnfysOnAxx1unItNKFikaSFBaLL/rFpqQQg9w6zk2aZtIx11luGl/ReJWVsUwiOtEYheNMCTti7f0EaRTFt3vb2z0gI2Ph17Gs4Zjy8rWshQitva0tpGL1MB8YKJz1yPGUqNWiY7JIWWFcnPUHgiBBGkUxtmKP8bApGscJPu2W4/ogJ2dVO50301BSYjpNc+h1grCJE2odf+joEFQ5FttdPX78rzeG3h89qNEYEyi0lvg/hl9ukT3u9tTzt8LCHW5sd/yOSPS8a/D6iKi5maqed5x3CQnBpUSYVbzBwCvfnSY6q1RafIpvnYxSf9TU3r4kHb0xeiEycuv5tnfAjDK0DIcLCmRNn1/K3nPlCpO+xZeQWp4bnBsODbUUtxXYHewxVCQlWYqzaIDlT+wnog2Grbz5Z2Req63nSIt1Ab6df20DfCvnQdGhc+eslDZ/2k4ZjdY4v9Ves76+85H3u571mZkwje5iizExcBYrgdInT+A+GEEzNsYqMKXDZ7m5lvT/ATVmyLftgLwfAAAAAElFTkSuQmCC",
    },
    "maisMilionaria": {
        "name": "MILIONÁRIA",
        "color": "#1c3176",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SCzKh69XsAAAES0lEQVRIx5VVa0yTVxh+z/eV3vxaVmjouImiDgMEKBe5RcAEmCgzG0tgKxACjAGaCQuFKYWMhMjEMhLmYCiXLYhNFraQzckCOMg6NphyyRRZIhv3ESFClV4o0O87+2MxoX5pfH4+532f9znnvO85COzg2HTidM2j4uIn959FGGrVarIC/YhUNC1hHNuo6uJinx73QafwyUkcCyZi9fp13AcdqE0gwICyYDgrS+Pb9vgDN62WTR/ZM/DGt5GfVKQZjaYSc9+2l1Bo5UlvIoxQYXzcLzD30GG9HvRwDWrE4t3ENuiGP+7e7eS16/K+Dg9n0yfsGcDvMyLM53D28vQMc4+5hJBNYSuWQQvXXsK/qgFRp1DOp9iPkBVKGIXkGzfshXHScS5uwXFxyBFngqdaDZUgh3WhEPNxPBJrNE9vrpZv+6WmGps3o7dHl5aMBVu/b0lfXIUNqvCnAGNjKMoSxutoaEi/mv1Xa5BKhczoDt5QKMAMyTBlNKIN/B2uLS1FGRdzPFq+WVyERUiEHQ8PG0EK4lHl+PhK4dph3ZWqqn97l0W6pO7u7S8sCouaJOPi5PIjRwCgBnzh6uIiVhMOEJuaCpeZFlhpakL5cAwS5HIb3TBYhvvz8wR8CD+DwmBg3ZEB7uDq4GCZxFn7Wl1j48G33RXOxrQ0ykVA887p9bgI5kA9PIx2oJE5q1AgilFDSFcXa+HnwKH4M3jPYEDp+3PvtYZER6PTmMELPT2sTWVNfF7wZlj7QN6jqCgrn3E0p7716MgIhMIkLmHvehBBPpRvbMCb+B2cl5TEmXlroWllOCho+cG6g35TJKJnmAnmEnvTUFMCmtfv7w8AAF4v+NG5v3Pnw/z8DAZz3NY0ez7pTbQR/4hEsgHpScfigABSMOaSHrkwNLRtsfTS47bjZgX3PEfDKaVpqUg8K5QqldQD2a/RcwMDJ1sSkjMvnjkD66iE4V24oM/YbN0qSEmh/2S68AhhM2VYh5fxbwhZ+JYKuiQhgaAv08m4jiTZCgs/5ydy500ml2GnKZG2oGDF61m5Ya2hwSA1x225UhT8gtrBEBHhFiGdkMjq671zPOTSyJSUfc28aN4Tk4lNl6llkuAKSZI+r/sLT2t1Oksjk01Xx8RwbpHvEuEYS86KG4Uug4OOX/LrKVls7NoJfeVGQG+v+attjaWZy7UKHTjg6ursDAAbcAgYsZga4hfx+318xB8TZaQ2MJB2RZ7oh9BQZgSn4PPu7vxlhzKHW2azVCxeEDQrlXaf4mDNidvV5/r7V8ueVuj3xcfvXd8dw73YhOPQpVJ1ft+enddXU8Omb/cl1GeYJsyGmBh7cTaog1D4KTPTXphdA2iCCELlOzt7eetntDtWe+EGMZD/Ev5VDUgElKfwYHk5t4G7wFmzWAQh/AnuY7NZVuQkFycUFuLbiED7T53Chfgj8H34EJagAySzs6BglPCfUmlP/3/QCca8oJbQ1wAAAABJRU5ErkJggg==",
    },
    "lotofacil": {
        "name": "LOTOFÁCIL",
        "color": "#871985",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SDCQafvZ6AAAETElEQVRIx5VUbUxTZxQ+b3tXS1MulMtgGWAh42tBKx8WgQ1akSwZTJ2MobIYQiUo2RK6AQ6BoRNwaLGhWSBZFRzD0UTdOrIEJCQ2kPChBIwEFgU2PgpoUWhGS0fb2/vuz5QNd+32/Dzvc57z5Mk5LwI3uIrfmWruVCpX+3+bXiVUKk4XcZHzk8vlXSMO8WlUKoMheS4YxsfhBBMMJ7RaOAgVcNDDg0nkpDKJubn7fCpn9/n09bHpE+4MrKUs0GvK2lpH+rrCkUsQIASAAIJ46vfAtezT1BQieaswJNZiwZUwhStJEgCuAQBwFa4hrkKlAoDXAPbsYdPnuDPguu5Kcv1MvGCU/swxRZcg9LfB/wA+jkT4+Iv1/21AeNfvgudp9gjZgGUgxrK2Nnc8woCrsQHL5aBnFkCvUqEWThBqEQiwBLZjSXv7knXp3lJUdvYfnSu3bV8uLNjSzam2XIGAVVEOAPKREVricZGWaDSG8upKQ3lFBRqDeTSWk4NFuA6L1tdxC5zBLaWlyNB17r6hy2gEPnQAPzBwqx5qQFdQw+ioSTa5YZKdPbvQPlA236LXOz6wqRxHudyEhMLCpCQA0EMv6I1G0HAOgCY7G/KYZchraoJc2Aa5MTH/YnQA5HNzHKAhEmirlTVKJc7HythYv9mwnX6zjY3imkR7SP3hw4ISKktwxGIBLVCgHRwEDQdAk5MDtxg53Lpxg3XwJkIArFYOjocYHJ+fj2ogDNWsrbHSD4EMDgUFUa3hJNVaXFz0yvjXn75Bknt1VR/v1SUlATAZAPX1bEk+T/SvOcwwB5jhggJiXtF/ZV4RHf1k7EGZadTTkx5yTNED7LYF31FZgpodO0AHALrN+pjiesf9rKgoW/jK5HrsS5ZujBdGjHp6+kojQ/2kEglSP4oQXZq12+3frvE3vufx2Bp5PwhKeTqXi/IPTXhVXFT0u9/iabOzrk6S8eGP0QXj4ybnw09MTrV68dIdqbFWp3u2I2x6fKtXJH/Rbufg/fQXzHvsREGn6Lag1WbzpULFlOrkyRXT9NCTOY3GFr4yaZMJhUChRqASEvy9I8v8vdXqoFNvXxVXZWY+62PTZd6lTzHvc7nco1qp5Eia2eyKct1h9qekEOO8ndy7GHtdC8zzOmAweHZt7/MqlsnM5K/eq33d3fYAyzl7xGZSgYFSaVAQABDwEAiSFF6mBoWXIyK2dXvU8vt37cKriMQNu3fjGddjBgcE8GaFPrx7GxuibnEGNVxSgsANtB3J2m8ye3pWfpk+8zQuLW3r+/Mz3AIcB004rqIilax6nEqeP8+m7/YntMYvf275KiXFHW8rUC/Mod5jx9zx3BrgzBEWrtHp3Fon1Lwwoh5jtvNFzdiMml9y1v/VAFn2+ohXTXk5L1nYxpPStMcF74/4ZRsbvs43J6jqwkKmHaqZ9vR0kMMjkE9MwE0YhpszM6gHRaOekhJ3+n8CMirL/a0oWy0AAAAASUVORK5CYII=",
    },
    "lotomania": {
        "name": "LOTOMANIA",
        "color": "#e88732",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SDRwrZ3+lAAAEJklEQVRIx5VVbUxTZxQ+73svOi5tQT5VKAySLQsSBkzFoPKhyEYNDiGpWQXddCPi4iyM7xpB5vg0DYVAJiHRRdIlksUsy1hcGYxuCAPB6cC4MWUFZI6Puva2hUJv3/0QakJzbbw/n3POc56c85z3InDxLXx3hUjH5XLukb5v5nB9PXRTPXiI4+h8b+NWtVzudlZcFzU7Okra8RA8aG1FNSgW9ri7w14Qgfr4ceFH8YaSHq2Wjx+5EjC3RbU3ccBs5u5YJMbTDOMonKWVdBwhzJmd8ZmtLEu+hU9IpUjkiKfDGHQPDgq7E06X/BAby8ePXQkgh7jr3D807YT72/JttxBa39gRb0fn4Stn/KUF4DOCQe/v+UfIO9oLZBGKr11zlUezpIdUk8REOEntQDH19eRDchDdYxjUBZ4gU6v1wmnT35RUykQvdv5XNz3N3bFI2KLnq3BqXAHlkDg8bM6whlFbVSo2sPeDWqtCQZLBAGqZDF2CHDJuNsM5/DqWFBYiY1HvUk3B1BScg1/BNyjIibABhqF5ZMRaN5c5wVZUcJd1mb+P37hB9i9nLr1NUQwTFyeVAkAhGFD11BTo7GngJ5WCB35IlC0tcAUew/3oaCfeMlRNinU6DHIUBKUmE68H5PAWfBwTs+Go390w0txMPwi5GGk8cgTrBZ955bMsCoFIdLG/Hw3Z00iJTAaR2ErSOzr4Gjt4JWQeFZhMyLj8c2LVhd270QG7D/V5ZyefqRzKVxsKnyZsKjbFxa3hbExvSo15YID8BApo4nc9SoNGdN5oJJVIR4ZTU+ll3UOPe3RUFNc0p32UIxQSi2277foLTNknSPX6IiICwgEg6zm+qPkt8ObRbdvsFsstw+QLzNlEa+kcodDNEPB+2GBkJLZf0rc9Dlcq186Kt/DHDV+/cpPjsJswyV9XWjq70Hg2KZ1l2VBtQk1Wfz9FAlLe2HziBO59lsc7+tU+NqVeNCNraMAknqRxeyiKr4CKZjpFLRYLnvD1EQefOmUfWfh3Mkelsq+YNxsmBQJyl1RCxK5dbnVbDocIlErcLi56MzAjg4pmOoV1FgvvKPbZU7goisJ0g98fQct5eUjknuT5p9mMc91tgj6rlcrzJeIvNRru6qYO8aHQUHvL02NP8hob7QnP3O9EuHpFG3cETIcElJfTM8HaqP2BgfS8T7h4e1fXGi9283jiGWwy4Xe8K8XH5HKXT/H8aOs37+ZoNDbfhftTt5OT18cdZ7h+ZYUggb8UCuHlBHNJW1UVr6dcCbA3mXbqU+PjXeU57bocuUNtdrarPJcCUBvW0dkrK0746s9o7ayc4lmkEt5zxl9aAM72uh1wsqwMqTfuY5ZtNiqLaRRwS0uUxL/kVVVuLtHgBU4hkcAv8CnMjY2hbLBC7cQEvAaFOLagwBX//yCh0dQnibWMAAAAAElFTkSuQmCC",
    },
    "timemania": {
        "name": "TIMEMANIA",
        "color": "#75fb4c",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SDhF++1DbAAAELElEQVRIx5VVf0xTVxQ+570HlEI7sBtjQGSUjGbKoDZkGAjgJtHBFiSMQdat0bgtkQ0FtkKgDCGC6GCCzAAOdMlWBzoW2dA5CUtUTIQQIDoKarLxwyqOMizSHxT63rv7Z3WG+tb4/fndc77z3XPPvRfBAxqJM//TNwoLF/bBfuOH9fVUHbJUIMfJtuJ3YZbCQrmDV8UWGQzED8/ilbY2vAUv4TZfX76EZCLs3Lmj2CvyvVv9/UL66MlAZZnzhvq+zWZnYcPSR2Kxi6c/ByeTTUhCNd5+22axQDK8AlKp9FHiCSyB3UNDGT10g8YZHy+kT3kywFsxmK9mmLU8VwNe7I+IboVdeIusQsgT+Kc1IJkgq+s0wi0UxBUsgy/1ek9hzDniJHqyZQvIKB08rK8HJCaoFouJCQ+ho6PDcpp6zng5J8dm4P5cbL97186S8MePwv3MsAoqR0ZELFVNrjU19XCc6dQn5eUYRMqISK0mJ1EGIpsNQvhSIi0uxp4Y9oT+oNEINbAL1oeFuQlOYzVYRkdN3SR6UlZVNXWWTxnr7O5ercVAB0vTSUmIubkAsA1OQpnRCJlkDItzcuAHKghKW1rgMtGRtk2b3HRboBmGZmYoyIfr0Ga1Cu7oRVIBEpUq6Fd4IP+suVmuoYhyR26u/9d4M+A3iwV6cS8eHRjABBJBvNRqmEUlsXZ1CRZ2YR/SOGy14s/3nKdPTScmYiMqyC8XLggOlQv/FsxoplvfH0lIcNHnVFyBfmJwkFSRIzAiPPXQD2OwtLTEB5Nr0JuWxkz7U0ujdqXyfgWvmPSTSLgaIOwZ4aHx10NewHh0NAC0Ps6PZPPvXryxcaPtKpCH/5NPV4CCyZZIXkijeiN3x8RgxV52LveDlRWHiKyzzXl7CyV664hZxHBcEEX/tL62oMDcTBJNk4cPq9KwdXuXwWAaJo2TEQ0Nk5nEYhjv7HTWgWR5maaF9HwP4Lxf0coKxR/gkVsQDhQzMCFtt9ufzQd7+J09e+ZW+WxjZVOTzUyiFo/7+4ORHIXUzZuDjsG3cq+GhshvcDBmKStLzOCMtN1uF9LlSwjDm2mazhref3PbMbOZ08PL3NXkZCYJaUZLSMA8LASXXLoku8goZPkpKX93k9nZ+N7elSoIsRn/61R4OGJ0NAC8Dkp4Rir1s2FHQIRC4aOjs/C12Fj4gp/1ksfFkXZcZuNCQ32u4z0/pcMhK6X6QqK0Wo9Pcd1Wp/Hjgb6+eRUE3zmYmrp2/dE1XIszOAei8vKM7+lQzTu1tUL6Hl9Cywb0fqBPTvYU54YUcgi0Go2nMI8GqK9gkf7D6VzLuz4j17VySzyP3jD7BP5pDQSm4+/P9+t0Pg4w++5iWV8W/5KMOxzBr0KA/HxeHikit/HN9HRg8Di2jI+DGI5A6NQUFcWroUOr9aT/D7rCysEPNJBfAAAAAElFTkSuQmCC",
    },
    "superSete": {
        "name": "SUPER SETE",
        "color": "#b1ce5b",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SDwl0jPnMAAAEPUlEQVRIx5VVa0xbZRh+v3N6o+uFjQKVlQka0imsXERZgAAyJnQKi4yB4TZ/sMiYjqrFjNU4NFmDEpmYQBQwxsBgDgxmKgNZYLLVMRCSMYaMOQuWcJusrC3tKeWczz+WGZpjs+fnc973eZ/znuf7DgIvuFZ352ndWxqNBVMPF/U1NcTz6DSZRNPS5m1r/n9pNAE6cWh49sQEMYmbcFdjI+wGA5b5+GAFE4ngyJGnhE8MFUwNDrLpI28Geulbvm+8vbZG/ejqty0LhW6evESMc0owjuiVw/55qxX3QwZgiWRTOAM9C+3DwyF3Ah8U/hQXx6ZPeDOAhUwHfZDD2crTaka10YzQ1sGbfRchE7ie/GMb8MHcGN9m9hWyrrYT1+CClhZvdRwjXsAtOCUFVRKZRGxNDfaDe1grFKIEeAjX2tosIspmUuTmOp5ksqzLc3POK+sX//spPHAaVcHA6KigAL+Kz9TVzfy6FNR6XKfDBpBCYn4+MgAP5GtreA9zgpiuqEAzx5c0rW0mE9bik8AoFB6C51EzxIyNmb90np2rrKpa/NkcPR3f1eX6nf7EOU6SKlVQkFoNgEpROTSaTLgHfoNDubnwPU6Gkw0NEAV6aIqO9tANQQmwMjtL4BNghgs2G+sbvYZLYCwmZoeSn6Yw19fLR3xNu1Pz8nze514VF1utMAo34ez163Q9yiaU+fnoTcgE/44O1sFuHIVlOG+zodmvlzNbZxIS8EfMITB0d7OFahP/DgzNkacXjsbHu2kjXrSd2zU0BDNgw3r21KNU6AFksSAKZeJv1WqO6TNz2VR1VNRqumPJlCcW0+PM/Ebz/4TyQ+6UWB8RAQAA6Y/46bL7I1f3hIdTGS6p9RJ7P5lOAKdELPZzipsUBpUK9fBv9pVccTqdF2g/RxOPx9bIfYZ8j6+iaclhwbtBxvJye8a64G9TdXVYsb88sXhiYtVpJU33amsXRPayu2R7uzsjbHp8GcewbdLpJJhb8DFzg71Q8Ao3VRRgt0v3CXLkeaWllg7q0/nQujpHvEtq9RWJQAjbwbV37/avJA3BIbW18mXJkvJgdjY/hZclCrDb2XSZEdDTgyRJlt3VmNV/mM1MHH6H/iYpifQjLnPrMZbkCI7KugcGZCsCzg51cvIDq+PP+wG9vetK+nOH7NGmAgPF4rAwAIiHRMASiU83b10iVyo5+1CXsDAyEqmAj7tiY3EZdOPJnTt5l0mpgEtRok7+y4E3tFqvV/EvvMkVbWFf32oHNbuA09K2PncfQ4+wtQGB+TpdiE4eUHRYr2fT93oTOpBrbLUkKclb3VbgHFSBzhUVeavzagB1Es+Ru1yurbz7Z+Q+Vh59WfADuDz5xzYgCuZPyCpPneIayZcEX2xs8Ic5DcIXKMp3VRgYrD92DH1AfAcJBw7AGRQG9bdvwyTw4EWjkdlP9+PXtVpv+v8AZmTNiD+v+uIAAAAASUVORK5CYII=",
    },
    "quina": {
        "name": "QUINA",
        "color": "#21027f",
        "icon": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfnBw4SEAG3DX9gAAAETklEQVRIx5VVa0xbZRh+v54DLQU67jBuRcaCyKWDMUuKchkkjIxgQFLmHCOim52RWTZgXFZKvRANgcK4OCAGFwz8gIk6M2UMiSwOtggOVqZcMgcdOAwwoJe0cE4/f5iySDlrfH4+532f93m/732/g8AKXsMvz7Tsk0ofLk4Xr8iqq8kuMot1haYDvg4yuE5IpQkPUvICulQq00UAorS1FTZQAxba2SEbnA8f5+ZKZQqU5DI0xKSPrBk4eNCD+mxZp1tdXbbVN3C5Zt4mlO1EVmF8xvtCUay/RgMhYMStPN524gkIBPbduwXulSeTXhEKmfRZ1gxQntQnpjskuZPfmjSuUWUIWRQ2dxYMOqix5P+3Aa8Fnx6HIOYjZILpCyzBn3Z0WIsjlViO+3FCAtxCV1gh1dWQBEa4yeVCM5KCorNzemwq/MmvYvHK5NJv+vzHj1fU/70KC8ixHAZHR+lGhw7Tt/X1yjaF3cCp8nJ4D9eB/PhxEODTKFqnwyTBAXVREVLGVCoHitRqyIZ1OOLrayHoAHxwGRubGblfsfR+ZeXPR2/yH8329urPa24bJQRx9mxFRVwcAKRhOVKq1aYZAHRNLCYKAPC+5mYsQQrcFhlpoSvFcjDOzZFoGjgwq9VigPVdO9LCHKxGRe0vCZv3cm5qMrHoKCjOzh6duPPWgnt7O9RhOcpQqViHAOie4mJ4EdWxiru7sQTWoW2Xhsy4BgAPtVqkFHz40k9LsbEgNOWA6Pp1pqF6ZgjLUcbwcIFMgQ5viERmWvmmHA98MDIC0UgB6cxTD78DG53e2GAl4hLclZpKDoX8kDhz6MCBycV71X//5ei41W9co54zcm4TnmqHxrAwkAHAyWd8Z25r6uil0NDld5du6JyY821C2U7kvKNjaIPAwys1IoL15+a03+rntbXba8UAbo2jiH2Zpn1PBXB4F0tLo3v2Hqneo9HUuVV+NeA9PBzZHcPx6cjL49Y4imwbaZpJx1znUeYsZyWiro61dYL6HucRBFOCi4vbJjdfrw+6GuLu4SyRTIsfjC/r6utXipZuaKUODrgcZqEjJibkviDea7y2Nu5Y0r3A9MxMV79/8xiNZFE9plyCIEQfCRaP6Z8+pQyUP/1qXBw7kd1I3sLYbybQyzl5cND9cJC/nSw+fr75j9fXgvv6NGlr5wwptrZmIaEwPp7PB4AwMEIQj+ea4fmGfUJwMK/BLYoKFAhwO32V9I6Opt+ha3GTj4+9mKfj9BoML1zaz3ceLiy0+hSnCMLDG6b6+6c3JieXO5OTd37fXsMdwAFYjn3Ly89lKFBycFUVk77Vl/CJz0KWdna3Es8H6210GZXk5FiNsxZA+tt+SYxsbe3kzT8j81pZnMAU2MN5S95C31qA74/8vj0+ZWWbvxguUJyaGmKcPMOKoKjA9ECNS4tUCqEsGdxWqSCNnoTulhZ8FAB9w+XCd8ReU1NhoTX9fwBXrc9iljt/WAAAAABJRU5ErkJggg==",
    },
}

def main(config):
    # get config options
    modality = config.str("modality", DEFAULT_MODALITY)
    prize = config.str("prize", DEFAULT_PRIZE)
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    timezone = location["timezone"]

    # call loterias API
    res = http.get("https://servicebus2.caixa.gov.br/portaldeloterias/api/%s/" % modality, ttl_seconds = CACHE_TTL)

    # handle API error
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(res.status_code)

    # get API data
    data = res.json()

    # calculate remaining time to the draw date considering the user's timezone
    draw_date = time.parse_time(("%s 19:00") % data["dataProximoConcurso"], "2/1/2006 15:04", "America/Sao_Paulo")
    draw_date_in_tz = draw_date.in_location(timezone)

    # humanize the draw date
    draw_date_human = "em " + humanize.time(draw_date_in_tz).replace("from now", "")
    draw_date_human = draw_date_human.replace("days", "dias")
    draw_date_human = draw_date_human.replace("day", "dia")
    draw_date_human = draw_date_human.replace("hours", "horas")
    draw_date_human = draw_date_human.replace("hour", "hora")
    draw_date_human = draw_date_human.replace("minutes", "minutos")
    draw_date_human = draw_date_human.replace("minute", "minuto")
    draw_date_human = draw_date_human.replace("seconds", "segundos")
    draw_date_human = draw_date_human.replace("second", "segundo")

    # obtain the estimated/accumulated prize value
    prize_value = "R$ "
    if prize == DEFAULT_PRIZE:
        # estimated: what the lottery estimates the prize will be until the closing time
        prize_value = prize_value + humanize.float("#.###,", data["valorEstimadoProximoConcurso"])
    else:
        # accumulated: the true current accumulated prize value based on people's bets
        prize_value = prize_value + humanize.float("#.###,", data["valorAcumuladoProximoConcurso"])

    # grab the modality display configuration
    modality_name = MODALITIES.get(modality)["name"]
    modality_color = MODALITIES.get(modality)["color"]
    modality_icon = MODALITIES.get(modality)["icon"]
    modality_font = MODALITIES.get(modality).get("font", "tb-8")

    # render the final display
    return render.Root(
        render.Box(
            render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Image(src = base64.decode(modality_icon), height = 10),
                            render.Text(modality_name, color = modality_color, font = modality_font),
                        ],
                    ),
                    render.Box(width = 64, height = 1, color = modality_color),
                    render.Text(prize_value),
                    render.Text(draw_date_human),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Localização",
                desc = "Localização para cálculo do tempo até o encerramento das apostas",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "modality",
                name = "Modalidade",
                desc = "Modalidade (tipo de jogo)",
                icon = "clover",
                default = DEFAULT_MODALITY,
                options = [
                    schema.Option(
                        display = "Megasena",
                        value = "megasena",
                    ),
                    schema.Option(
                        display = "Dia de Sorte",
                        value = "diaDeSorte",
                    ),
                    schema.Option(
                        display = "Dupla Sena",
                        value = "duplasena",
                    ),
                    schema.Option(
                        display = "Mais Milionária",
                        value = "maisMilionaria",
                    ),
                    schema.Option(
                        display = "Lotofácil",
                        value = "lotofacil",
                    ),
                    schema.Option(
                        display = "Lotomania",
                        value = "lotomania",
                    ),
                    schema.Option(
                        display = "Timemanina",
                        value = "timemania",
                    ),
                    schema.Option(
                        display = "Super Sete",
                        value = "superSete",
                    ),
                    schema.Option(
                        display = "Quina",
                        value = "quina",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "prize",
                name = "Prêmio",
                desc = "Exibir prêmio total estimado ou o valor real acumulado",
                icon = "sackDollar",
                default = DEFAULT_PRIZE,
                options = [
                    schema.Option(
                        display = "Estimado",
                        value = "estimated",
                    ),
                    schema.Option(
                        display = "Acumulado",
                        value = "accumulated",
                    ),
                ],
            ),
        ],
    )

def render_error(status_code):
    return render.Root(
        render.Box(
            render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = base64.decode(MODALITIES["megasena"]["icon"]), height = 10),
                            render.Text("  LOTERIAS", color = "#4b966d"),
                        ],
                    ),
                    render.Text("API ERROR", color = "#ff0"),
                    render.Text("code " + str(status_code), color = "#f00"),
                ],
            ),
        ),
    )
