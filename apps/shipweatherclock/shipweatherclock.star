"""
Applet: ShipWeatherClock
Summary: Ship scene w time/weather
Description: Clock with ship on the ocean scene that changes with weather.
Author: Peter Uth
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")

TTL_SECONDS = 20 * 60 # 20 minutes API pull interval
DEFAULT_LOCATION = {
    "lat": "47.60",
    "lng": "-122.33",
    "locality": "Seattle",
    "timezone": "America/Los_Angeles",
}

# define custom pixel art
SHIP_DAY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9Ti1IqDhYRdchQneyiIuJUq1CECqVWaNXB5NIvaNKQpLg4Cq4FBz8Wqw4uzro6uAqC4AeIs4OToouU+L+k0CLGg+N+vLv3uHsHCI0KU82uGKBqlpFOxMVsblXsfkUQwxhAALMSM/W5VCoJz/F1Dx9f76I8y/vcn6NXyZsM8InEMaYbFvEG8fSmpXPeJw6zkqQQnxOPG3RB4keuyy6/cS46LPDMsJFJzxOHicViB8sdzEqGSjxFHFFUjfKFrMsK5y3OaqXGWvfkLwzltZVlrtMcQQKLWEIKImTUUEYFFqK0aqSYSNN+3MM/5PhT5JLJVQYjxwKqUCE5fvA/+N2tWZiccJNCcSDwYtsfo0D3LtCs2/b3sW03TwD/M3Cltf3VBjDzSXq9rUWOgL5t4OK6rcl7wOUOMPikS4bkSH6aQqEAvJ/RN+WA/lsguOb21trH6QOQoa6SN8DBITBWpOx1j3f3dPb275lWfz/OkXLLpp+1fwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gKGxYTBfJFka8AAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAoklEQVQoz52QTRHEIAyFXzq991oPRQAOqgIZVbEyULEOEJB42OsqYA8M3cAA7fSdwiNf/gAlZo610NGMgUQEGiYiyvEEAFfVb3UUkVsgMXPRadu2YRFjTBpXH6I+zuhYEx7qMXjq2BFbcevtLCI5W5o+gI4d8fUG5aS6iQ8gchZxXZLx+ban0f8+pIJzNtbln9CShgCU4/TAGjrB3i56p9r7AUivfni8gP/RAAAAAElFTkSuQmCC")
SHIP_NIGHT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAABgmlDQ1BJQ0MgcHJvZmlsZQAAKJF9kTtIA0EURY9RiWjEwhQiIltEK9OoiKVGIQgKISr4K9zdmChk17CbYGMp2AYs/DRGLWystbWwFQTBD4i1hZWijcj6JgkkiHFgmMOduY/37oCvkDYtt2EELDvrxKMRbW5+QfO/0IIP6Mavm25mNBabpOb6vKNOnbdhVav2uz9Xa2LFNaFOEx4xM05WeFl4aCObUbwnHDRX9YTwmXCfIw0KPyjdKPGr4lSRVdMEnZn4mHBQWEtVsVHF5qpjCQ8KhxKWLfV9cyVOKN5UbKVzZrlPNWFgxZ6dVrrsLqJMMEUMDYMca6TJEpbTFsUlLveRGv7Ooj8mLkNca5jiGGcdC73oR/3B72zd5EB/qVIgAo3PnvfeA/4d+M573teR530fQ/0TXNoV/3oBhj9Ez1e00CG0bcH5VUUzduFiGzoeM7qjF6V62b5kEt5O5Zvmof0GmhdLuZXvObmHGclq8hr2D6A3JbWXaszdVJ3bv2/K+f0AGrVyg8UeX9UAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQfoCwIAKB5MSFkcAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAK1JREFUKM+dkCESwjAQRd8yEQh0VXFUVyARvU9OkVP0RkhEPY6qagSiM4soLSEstNOnNn/3708iRHjvNcuyWCKEIBg4/tB1HSEEtZa4l6Dj4FKclbIE8d5rLMRvtJbUdS0Abm4w/ayRDStZbZw4HVCrTs+9omWOSpl/Dl1uUBVwviK9osf9d0jTItIrWhWDcH/Yt9lt3/2mRQCmxLH5i9gEDMWcOTVNxthskZoAnlZrRXVS7ZEKAAAAAElFTkSuQmCC")
STARS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAIAAAAt/+nTAAABg2lDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9TpWIrDnYQcchQneyiIo61CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx6uDirKuDqyAIfoA4OzgpukiJ/0sKLWI8OO7Hu3uPu3eA0KwyzepJAJpum5lUUszlV8XQK8IQEEIcYZlZxpwkpeE7vu4R4OtdnGf5n/tzDKgFiwEBkTjBDNMm3iCe2bQNzvvEUVaWVeJz4gmTLkj8yHXF4zfOJZcFnhk1s5l54iixWOpipYtZ2dSIp4ljqqZTvpDzWOW8xVmr1ln7nvyFkYK+ssx1mqNIYRFLkCBCQR0VVGFTXxXopFjI0H7Sxz/i+iVyKeSqgJFjATVokF0/+B/87tYqTk16SZEk0PviOB9jQGgXaDUc5/vYcVonQPAZuNI7/loTmP0kvdHRYkfA4DZwcd3RlD3gcgcYfjJkU3alIE2hWATez+ib8sDQLdC/5vXW3sfpA5ClrtI3wMEhMF6i7HWfd/d19/bvmXZ/P1uhcp059wCBAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6AsCCAch5iEd9AAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAAySURBVFjD7dZBEQBACAJAq1OVJJa4l7cbgXHAmZ8lGTijrbsH4Olo4IEFXSdFKQLAYQu39A8iAmA7lwAAAABJRU5ErkJggg==")
MOON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAABg2lDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9TpWIrDnYQcchQneyiIo61CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx6uDirKuDqyAIfoA4OzgpukiJ/0sKLWI8OO7Hu3uPu3eA0KwyzepJAJpum5lUUszlV8XQK8IQEEIcYZlZxpwkpeE7vu4R4OtdnGf5n/tzDKgFiwEBkTjBDNMm3iCe2bQNzvvEUVaWVeJz4gmTLkj8yHXF4zfOJZcFnhk1s5l54iixWOpipYtZ2dSIp4ljqqZTvpDzWOW8xVmr1ln7nvyFkYK+ssx1mqNIYRFLkCBCQR0VVGFTXxXopFjI0H7Sxz/i+iVyKeSqgJFjATVokF0/+B/87tYqTk16SZEk0PviOB9jQGgXaDUc5/vYcVonQPAZuNI7/loTmP0kvdHRYkfA4DZwcd3RlD3gcgcYfjJkU3alIE2hWATez+ib8sDQLdC/5vXW3sfpA5ClrtI3wMEhMF6i7HWfd/d19/bvmXZ/P1uhcp059wCBAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6AsCCAU3IMPKJwAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAA8SURBVBjThY/JDQAwCMNM9x8GJkw/VK3o5SexRAILStxd42YUJM3QzDZhlSKCpwDQ+PAUji9qyXYtlwM67DslQxOP4PMAAAAASUVORK5CYII=")
MOON_CLOUDS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxMXMG6cBKMAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAARElEQVQY04XOsQ3AMAwDwZfHUs+5NJh6rpVUAQIHkb8+EAxedfcFYJuqCoBg60EAkuID9qXFUGbOAJiB7fPJ9XdOUgDcvrYd4Q73XgoAAAAASUVORK5CYII=")
CLOUDS_LIGHT_DAY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVKXYQcchQnSyIijjWKhShQqgVWnUwufQLmjQkKS6OgmvBwY/FqoOLs64OroIg+AHi7OCk6CIl/i8ptIjx4Lgf7+497t4B/kaFqWZXHFA1y0gnE0I2tyoEX9GHAMKYQFhipj4niil4jq97+Ph6F+NZ3uf+HP1K3mSATyCOM92wiDeIZzYtnfM+cYSVJIX4nHjcoAsSP3JddvmNc9FhP8+MGJn0PHGEWCh2sNzBrGSoxNPEUUXVKN+fdVnhvMVZrdRY6578haG8trLMdZojSGIRSxAhQEYNZVRgIUarRoqJNO0nPPzDjl8kl0yuMhg5FlCFCsnxg//B727NwtSkmxRKAN0vtv0xCgR3gWbdtr+Pbbt5AgSegSut7a82gNlP0uttLXoEDGwDF9dtTd4DLneAoSddMiRHCtD0FwrA+xl9Uw4YvAV619zeWvs4fQAy1FXqBjg4BMaKlL3u8e6ezt7+PdPq7weNmXKxByfkgQAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxIWNHEom8wAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAABg0lEQVRo3u3UsYoqMRQG4D/jYiHIFnrFRnAbG1nwBW5rdfE57H2CfYfb37dQsBvFYSwGLMRCrtWMNhaiO0Yyk+RstYuiC2vnwPm65JwEzg8J6IwxhlarFS0WC9Jan5doOp3SvZRS1vO8f3hgzvlCCAEpJQqFAhznooTT6QSt9V2X5/N5UavV2pkIgIigtUYul0McxxBCXDQ2m034vg8iujeEXw8dQJqmMMZgv98jDEOEYfh+OByuGsvlMqrVKsbjMYwxP7qciCClTB85ALiuu1+v12a5XB4/90ajESmlbr5rKSVNJhNSSpG19maPtZaMMRRFESGL+v1+EkURpWl6c0CtNQ0GAwqCgI7H49Xws9mMgiAwWZhVfFcYDoe6Xq/nisUiKpXK16dorcVut4PneXBd96XVav1tNBq/S6WScBwn2Ww2/+fz+Vu32x1kIYCnW5u9Xu+53W4/AYDv+7PtdvsqpXSSJIHWGnEcm06n83n2DxhjjDHGGGOMMcYYY4wxxjLgA2EDX+Re5XcdAAAAAElFTkSuQmCC")
CLOUDS_LIGHT_NIGHT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVKXYQcchQnSyIijjWKhShQqgVWnUwufQLmjQkKS6OgmvBwY/FqoOLs64OroIg+AHi7OCk6CIl/i8ptIjx4Lgf7+497t4B/kaFqWZXHFA1y0gnE0I2tyoEX9GHAMKYQFhipj4niil4jq97+Ph6F+NZ3uf+HP1K3mSATyCOM92wiDeIZzYtnfM+cYSVJIX4nHjcoAsSP3JddvmNc9FhP8+MGJn0PHGEWCh2sNzBrGSoxNPEUUXVKN+fdVnhvMVZrdRY6578haG8trLMdZojSGIRSxAhQEYNZVRgIUarRoqJNO0nPPzDjl8kl0yuMhg5FlCFCsnxg//B727NwtSkmxRKAN0vtv0xCgR3gWbdtr+Pbbt5AgSegSut7a82gNlP0uttLXoEDGwDF9dtTd4DLneAoSddMiRHCtD0FwrA+xl9Uw4YvAV619zeWvs4fQAy1FXqBjg4BMaKlL3u8e6ezt7+PdPq7weNmXKxByfkgQAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxMHKtk874gAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAABiUlEQVRo3u3UsaoaQRQG4H/WTKNLBDV60eqCKfMCPkBeQlIEJG9xQcgLaGlhESz2Tawv2FlYyK4iNps1G2Z3ds5JkxuuVy/Ebi+crzwzDDP/HI4aj8eMv5gZcRyjKAo0m014nve0hCiK0Ov1cAvnHO92ux/z+fwrSsp7WbDWQmsNpdRFnYhuOrxSqah6vf4ZJeY9/30iglIKeZ5fBNButxGGIZj51hA+lDoA5xyICFmWIUkSJElyyrLsYmO1WoXv+9hut//dCcwMa60tdQBhGCZpmlKapr+n06laLBbviQjOuYvNjUYD3W4XURTBOfdqNzAzmBmn0wmTyaRW5gDUteJwOMw7nY72ff9sED4hImw2G9RqNbRaLWitzx5/OBzAzDSbzSoouasXXK1W3/v9/gMAj4jOhiIzwxiDOI6xXq/vjTEfi6K4K4oiN8b8Oh6Pq/1+/y0Igi94A652wGAwqC+Xy58AMBqNHrXWn6y1/+ZFnucuCIJ3EEIIIYQQQgghhBBCCCGEeEP+AB90ynum2FsSAAAAAElFTkSuQmCC")
CLOUDS_HEAVY_DAY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVKXYQcchQnSyIijjWKhShQqgVWnUwufQLmjQkKS6OgmvBwY/FqoOLs64OroIg+AHi7OCk6CIl/i8ptIjx4Lgf7+497t4B/kaFqWZXHFA1y0gnE0I2tyoEX9GHAMKYQFhipj4niil4jq97+Ph6F+NZ3uf+HP1K3mSATyCOM92wiDeIZzYtnfM+cYSVJIX4nHjcoAsSP3JddvmNc9FhP8+MGJn0PHGEWCh2sNzBrGSoxNPEUUXVKN+fdVnhvMVZrdRY6578haG8trLMdZojSGIRSxAhQEYNZVRgIUarRoqJNO0nPPzDjl8kl0yuMhg5FlCFCsnxg//B727NwtSkmxRKAN0vtv0xCgR3gWbdtr+Pbbt5AgSegSut7a82gNlP0uttLXoEDGwDF9dtTd4DLneAoSddMiRHCtD0FwrA+xl9Uw4YvAV619zeWvs4fQAy1FXqBjg4BMaKlL3u8e6ezt7+PdPq7weNmXKxByfkgQAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxIFGswR15EAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAB8UlEQVRo3u3VMavaUBQH8P9NTDWm1kal4CBtJsElL2IXJ6GTDqVDeZt+ibt26ejg4OYn6FRwLHQTBYdWVAQVQTpZH0iQqKjXNKZLfWuftpFS7m+5S845OQfuuQQeopQ+TqVSZrFYfCQIAkRR9KxWt9sFABiGcVacAG+FhsPh19lsBkHwrhRjDIQQ3NzcnB3r9QAAYGDbtqcFTNNEIpEAIeSfG8AaQGe/31/0cw+x3W7R6XQQCAQuivd0AJVKZQPg82g0+uY4zl/Pv9ls0Gg0sFwuwRi7KIfvCldg3u/3bzVNa6bT6cCfLkLXdcEYw3w+R6vVQqlUIr+WoKsoCvx+/1n5RK+7b7fbTrPZ/B6NRr+sVqtXmqaFJEk6q+Hj8QjGGMbjMabTqdvr9X5ks1lfvV5/f/pO1/XnlmU9cxznSTgcfvCLQ3Bl1Wr1g67rbw3DkBRFgSiKcF33vtkT27axXq8xmUzc3W53sG37Lp/Pv/hd/nK5/DGZTL7JZDJiLBaDJEn3++d0noZqWdb1B0ApfQrgNpfLvVNVNe7z+QRCCFmtVjgcDhBFEbIs28Fg8G6xWPQLhcLrS+rUarVPqqq+lGU55DiOKAiCoCgKIpEIIYTANE13MBgc8b+jlMYppXFwHMdxHMdxHMdxHMdxHMdxHH4CyQy8JI6Oae8AAAAASUVORK5CYII=")
CLOUDS_HEAVY_NIGHT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVKXYQcchQnSyIijjWKhShQqgVWnUwufQLmjQkKS6OgmvBwY/FqoOLs64OroIg+AHi7OCk6CIl/i8ptIjx4Lgf7+497t4B/kaFqWZXHFA1y0gnE0I2tyoEX9GHAMKYQFhipj4niil4jq97+Ph6F+NZ3uf+HP1K3mSATyCOM92wiDeIZzYtnfM+cYSVJIX4nHjcoAsSP3JddvmNc9FhP8+MGJn0PHGEWCh2sNzBrGSoxNPEUUXVKN+fdVnhvMVZrdRY6578haG8trLMdZojSGIRSxAhQEYNZVRgIUarRoqJNO0nPPzDjl8kl0yuMhg5FlCFCsnxg//B727NwtSkmxRKAN0vtv0xCgR3gWbdtr+Pbbt5AgSegSut7a82gNlP0uttLXoEDGwDF9dtTd4DLneAoSddMiRHCtD0FwrA+xl9Uw4YvAV619zeWvs4fQAy1FXqBjg4BMaKlL3u8e6ezt7+PdPq7weNmXKxByfkgQAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxMIFwbMv1YAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAABxklEQVRo3u3VvcoaQRQG4PfM7kR3iSKIWdcmXoFdmmmDhSAhRfiuJk0uxM5NFbAM5AJskhQhhXYRBXfRlUWMP7N/k2ohkCJRvrUI89RzzuG8sz+EEgkhnrZarV2v13tCRGCMlTbL930AgOu6V9UxlKu23W6/HA4HEFFpQ9I0BRGh3W5fXVt2AADwPcuyUgecz2fU6/WbQi47gAOAr8UNlSFJEqzXa5imeVN9qQFMp9OfAD6FYfgjz/NH7x/HMRaLBS6XC259yu7xCvhBEDz4vn95jBCUUkjTFFEUYTabwfM8mkwmtN/vkabp1f2MsrdfrVbZcrlc27b9WUr5stFo1AzDuGrhYukwDBFFkQqCIB2NRuZ8Pn9XnHMc57mU8lme5/VKpfLPfxzCnQ0Gg/eO47xxXZdzzsEYg1Lqj3NZliGOY+x2O5UkSZzneTAej7t/69/v9z80m83XnU7HsG0bv4ddfIeKUKWU9w9ACNEA8NDtdt9Wq1WXMcaIiKSUyLIMRATOecI5D47H4zfP817dMmc4HH60LOuFaZo1pZRBRIxzDsuyiIhwOp3UZrPJ8b8TQrhCCBeapmmapmmapmmapmmapmmahl8T0MMoSBWbjQAAAABJRU5ErkJggg==")
RAIN_LIGHT_DAY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxQKJxds+/0AAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAYklEQVRo3u3XwQ0AIAxCUfdfWkcwerDSPO5G+NQmjlGqORve9TIUVTapadDzgRLSwOwNp4VoMY2eFFmOQjzzmxQkwqsNDjqjBLoWG5n+LdSNnxbfcgIwhOLJOU0ZeaCotp0FMhpJt5CNKToAAAAASUVORK5CYII=")
RAIN_LIGHT_NIGHT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxQrCt4ssmsAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAaUlEQVRo3u3XwQ3AIAxDUXbg0vm6/w50hIoeSB093xH2d4jEGIWa173a3XUyFFU2qWnQ84ES0sC8G04L0WIaPSmyHIU45jcpSIRXGxx0Rgl0LTYy/bdQX/y0+JYTgCEUd85pysgDRdXtPEblOT33lCsJAAAAAElFTkSuQmCC")
RAIN_HEAVY_DAY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxQKFzG1y1EAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAhElEQVRo3u2ZUQ7AIAhDvf+l9QImKhHQ8vrpop3YdjO0VhK9rwYOn5uJnXjyK/o5Dyjhe1W5p9lkRuzxMq48hBkg+AA/ScLhiCVQBoir+u78mzym6zYyBqDkF4A8UFYFgauqnPCTf0VqIX0JfFMguVP2kGUjGUXf3sjWeq9XT775EVesAUCGeYembslzAAAAAElFTkSuQmCC")
RAIN_HEAVY_NIGHT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxQrF70q3rIAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAiklEQVRo3u2Zyw3AIAxD2aEX5uv+O9AFUItQPtR5PiKBIdgGRGsFcfV7vDd8dbAiduLJr+jPeUAJ36vKPc0mM2KPybjyEGaA4ANckoTDEUugDBBX9dX+ljxbz21kDEDJE4A8UFYFgauqnPCdP0VqIf8S+KZAcqesIctGMoq2XsjSeKdXT/7zI7JYD/ImXl1oA3nQAAAAAElFTkSuQmCC")
SNOW_DAY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxQsKqoDBGQAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAZElEQVRo3u3XwQ0AIQwDQfpvOpRwOh4ER+M/wl6HSKzVqKqqcXfdDEWdTWoa9HyghDQw34bTQoyYRk+KLEchrvlNChLh1QYHnVECXYuDTL8W6sTPiG85ARhC8c85TRl5oKi7nQ3XgJNt4HaPtwAAAABJRU5ErkJggg==")
SNOW_NIGHT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVh1YQcchQO9lFRRxrFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8Af7PKVLMnAaiaZWRSSSGXXxWCrxhAAGEMIyYxU58TxTQ8x9c9fHy9i/Ms73N/jkGlYDLAJxAnmG5YxBvEM5uWznmfOMLKkkJ8Tjxh0AWJH7kuu/zGueSwn2dGjGxmnjhCLJS6WO5iVjZU4mniqKJqlO/Puaxw3uKsVuusfU/+wlBBW1nmOs0xpLCIJYgQIKOOCqqwEKdVI8VEhvaTHv5Rxy+SSyZXBYwcC6hBheT4wf/gd7dmcWrSTQolgd4X2/4YB4K7QKth29/Htt06AQLPwJXW8deawOwn6Y2OFj0ChraBi+uOJu8BlzvAyJMuGZIjBWj6i0Xg/Yy+KQ+Eb4H+Nbe39j5OH4AsdZW+AQ4OgViJstc93t3X3du/Z9r9/QCDd3KtmFmoAgAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxQtH+Wr8QYAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAZklEQVRo3u3XwQ3AIAxDUfYfJiu2IyB6IHX0fEfY3yESazWqqp5xd90MRZ1Nahr0fKCENDB7w2khRkyjJ0WWoxDX/CYFifBqg4POKIGuxUGm/xbqi58R33ICMITiyTlNGXmgqLudF2iScE5Btz32AAAAAElFTkSuQmCC")
LIGHTNING = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9TpaIVByuIOASpThZBRRxrFYpQIdQKrTqYXPoFTRqSFhdHwbXg4Mdi1cHFWVcHV0EQ/ABxdnBSdJES/5cUWsR4cNyPd/ced+8AoV5imtURBTS9YibjMTGdWRUDr+iBHwOYwIjMLGNOkhLwHF/38PH1LsKzvM/9OXrVrMUAn0gcZYZZId4gntmsGJz3iUOsIKvE58TjJl2Q+JHristvnPMOCzwzZKaS88QhYjHfxkobs4KpEU8Th1VNp3wh7bLKeYuzVqqy5j35C4NZfWWZ6zSHEcciliBBhIIqiiihggitOikWkrQf8/APOX6JXAq5imDkWEAZGmTHD/4Hv7u1clOTblIwBnS+2PbHKBDYBRo12/4+tu3GCeB/Bq70lr9cB2Y/Sa+1tPAR0LcNXFy3NGUPuNwBBp8M2ZQdyU9TyOWA9zP6pgzQfwt0r7m9Nfdx+gCkqKvEDXBwCIzlKXvd491d7b39e6bZ3w+/a3LFYPmf5QAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gLAxcHNCQ6ejcAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAdklEQVRo3u2YsRHAIAwDbfbfWWlSpEiRJuC7f20g+YWBqsFKkqJql/lVSvTR5q2A6MPNW4FJ08dW4GkcF8KbYUwIuYXcCF96vyOEdcp8d/eEQYxeg1NC8tD7+7aHDwD/DjAE/wPUMQokgE6BBNApwBNgBZRi6wJ5G3elOccUgAAAAABJRU5ErkJggg==")


def main(config):
    # get coordinates and current time
    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    lat = loc["lat"]
    lng = loc["lng"]
    now = time.now().in_location(timezone)
    now_unix = time.now().unix

    # get 24 vs. 12 hour clock selection
    clock24_bool = config.bool("24hour", False)
    if clock24_bool:
        clock_format = "15:04"
    else:
        clock_format = "3:04 PM"

    # get Celsius vs. Fahrenheait selection
    celsius_bool = config.bool("celsius", False)
    if celsius_bool:
        unit_temp = "C"
    else:
        unit_temp = "F"

    # wind thresholds for wave animations
    wind_medium_threshold_mps = 3 * 0.44704 # [mph] to [m/s]
    wind_heavy_threshold_mps = 10 * 0.44704 # [mph] to [m/s]
    
    # pull weather data from API or cache
    weather_url = "https://api.open-meteo.com/v1/forecast?latitude=" + str(lat) + "&longitude=" + str(lng) + "&current=temperature_2m,weather_code,cloud_cover,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset"
    res = http.get(url=weather_url, ttl_seconds=TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (weather_url, res.status_code, res.body()))
    
    # DEVELOPMENT: check if result was served from API pull or cache
    if res.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Displaying cached data.")
    else:
        print("Calling Open Meteo API.")
 
    # get data values of interest from pulled data
    sunrise = res.json()["daily"]["sunrise"][0]
    sunset = res.json()["daily"]["sunset"][0]
    low_temp_C = res.json()["daily"]["temperature_2m_min"][0]
    now_temp_C = res.json()["current"]["temperature_2m"]
    high_temp_C = res.json()["daily"]["temperature_2m_max"][0]
    windspeed_kmph = res.json()["current"]["wind_speed_10m"]
    weather_code = res.json()["current"]["weather_code"]
 
    # convert times to unix and windspeed to m/s
    sunrise = time.parse_time(sunrise + ":00Z")
    sunrise_unix = sunrise.unix
    sunset = time.parse_time(sunset + ":00Z")
    sunset_unix = sunset.unix
    windspeed_mps = windspeed_kmph * 1000 / 60 / 60
    
    # convert temperature units
    if unit_temp == "C":
        low_temp = low_temp_C
        now_temp = now_temp_C
        high_temp = high_temp_C
    elif unit_temp == "F":
        low_temp = low_temp_C * 9 / 5 + 32
        now_temp = now_temp_C * 9 / 5 + 32
        high_temp = high_temp_C * 9 / 5 + 32
    low_temp = int(low_temp)
    now_temp = int(now_temp)
    high_temp = int(high_temp)

    # set wind animation strength
    if windspeed_mps > wind_heavy_threshold_mps:
        wind = 2
    elif windspeed_mps > wind_medium_threshold_mps:
        wind = 1
    else:
        wind = 0

    # determine day/night and ratios for sun/moon heights
    min_height = 22
    max_height = 1
    if sunrise_unix <= now_unix and now_unix <= sunset_unix:
        day = True
        day_ratio = (now_unix - sunrise_unix) / (sunset_unix - sunrise_unix)
        night_ratio = 1
    else:
        day = False
        day_ratio = 1
        if now_unix > sunset_unix:
            # assume next sunrise is the same
            sunrise_unix = sunrise_unix + 24 * 60 * 60
        else:
            # assume previous sunset is the same
            sunset_unix = sunset_unix - 24 * 60 * 60
        night_ratio = (now_unix - sunset_unix) / (sunrise_unix - sunset_unix)
    sun_height = int(min_height * abs(0.5 - day_ratio) / 0.5) + max_height
    moon_height = int(min_height * abs(0.5 - night_ratio) / 0.5) + max_height

    # determine weather conditions
    weather_table = [
        # code, clouds, rain, snow, lightning,   # description
        [    0,      0,    0,    0,        0],   # Clear sky
        [    1,      1,    0,    0,        0],   # Mainly clear
        [    2,      2,    0,    0,        0],   # Partly cloudy
        [    3,      3,    0,    0,        0],   # Overcast
        [   45,      3,    0,    0,        0],   # Fog 
        [   48,      3,    0,    0,        0],   # Depositing rime fog
        [   51,      3,    1,    0,        0],   # Drizzle: light
        [   53,      3,    1,    0,        0],   # Drizzle: moderate
        [   55,      3,    2,    0,        0],   # Drizzle: dense
        [   56,      3,    1,    0,        0],   # Freezing drizzle: light
        [   57,      3,    2,    0,        0],   # Freezing drizzle: dense
        [   61,      3,    1,    0,        0],   # Rain: slight
        [   63,      3,    2,    0,        0],   # Rain: moderate
        [   65,      3,    2,    0,        0],   # Rain: heavy
        [   66,      3,    1,    0,        0],   # Freezing rain: light
        [   67,      3,    2,    0,        0],   # Freezing rain: heavy
        [   71,      3,    0,    1,        0],   # Snow fall: slight
        [   73,      3,    0,    1,        0],   # Snow fall: moderate
        [   75,      3,    0,    1,        0],   # Snow fall: heavy
        [   77,      3,    0,    1,        0],   # Snow grains
        [   80,      3,    1,    0,        0],   # Rain showers: slight
        [   81,      3,    2,    0,        0],   # Rain showers: moderate
        [   82,      3,    2,    0,        0],   # Rain showers: violent
        [   85,      3,    0,    1,        0],   # Snow showers: slight
        [   86,      3,    0,    1,        0],   # Snow showers: heavy
        [   95,      3,    2,    0,        1],   # Thunderstorm: Slight or moderate
        [   96,      3,    1,    0,        1],   # Thunderstorm with slight hail
        [   99,      3,    2,    0,        1],   # Thunderstorm with heavy hail
    ]

    for w in weather_table:
        if w[0] == weather_code:
            break
    cloud_scale = w[1]
    rain_scale = w[2]
    snow_scale = w[3]
    lightning_scale = w[4]
    
    # animation timing
    t_end = 15
    t_delay_ms = int(5000/24) # 24 is slowest for seemless repeat
    t_delay = t_delay_ms / 1000
    pps = 1 / t_delay # pixels per second
    offset = int(t_end * pps) # offset number of pixels for seemless repeat

    # individual render components
    sky = draw_sky(day, day_ratio, sun_height, cloud_scale)
    sun = draw_sun(sun_height, cloud_scale)
    moon = draw_moon(moon_height, cloud_scale)
    ship = draw_ship(day, wind)
    ocean = draw_ocean(day)
    wave1 = draw_wave(day, wind, 0, 64, 20, 0, 21, [1, 1, 0, 0, 0, 0, 0, 0])
    wave2 = draw_wave(day, wind, 0, 64, 28, 0, 22, [1, 1, 1, 1, 0, 0, 1, 1])
    wave3 = draw_wave(day, wind, 50, 32, 22, 21, 21, [0, 0, 0, 0, 1, 1, 0, 0])
    wave4 = draw_wave(day, wind, 42, 32, 22, 22, 22, [0, 0, 1, 1, 1, 1, 1, 1])
    stream1_1 = draw_stream(day, wind, 50, 24, 20, 0)
    stream1_2 = draw_stream(day, wind, 50, 24, 20, offset)
    stream2_1 = draw_stream(day, wind, 10, 26, 20, 0)
    stream2_2 = draw_stream(day, wind, 10, 26, 20, offset)
    stream3_1 = draw_stream(day, wind, 35, 28, 20, 0)
    stream3_2 = draw_stream(day, wind, 35, 28, 20, offset)
    stream4_1 = draw_stream(day, wind, 1, 30, 20, 0)
    stream4_2 = draw_stream(day, wind, 1, 30, 20, offset)
    text_time = print_time(day, now, clock_format)
    text_low_temp = print_temp(day, str(low_temp), 50, 6)
    text_high_temp = print_temp(day, str(high_temp), 64, 6)
    text_now_temp = print_temp(day, str(now_temp) + unit_temp, 64, 12)
    stars = draw_stars(day, cloud_scale)
    clouds_heavy = draw_clouds(day, cloud_scale, 1, CLOUDS_HEAVY_DAY, CLOUDS_HEAVY_NIGHT)
    clouds_light = draw_clouds(day, cloud_scale, 0, CLOUDS_LIGHT_DAY, CLOUDS_LIGHT_NIGHT)
    rain_heavy = draw_rain_heavy(day, rain_scale)
    rain_light = draw_rain_light(day, rain_scale)
    snow = draw_snow(day, snow_scale)
    lightning = draw_lightning(lightning_scale)
    
    # top-level render
    return render.Root(delay = t_delay_ms, child = render.Stack(children=[
            sky,
            stars,
            sun,
            moon,
            ship,
            snow,
            rain_heavy, rain_light,
            lightning, 
            ocean,
            wave1, wave2, wave3, wave4,
            stream1_1, stream1_2, stream2_1, stream2_2, 
            stream3_1, stream3_2, stream4_1, stream4_2,
            clouds_heavy, clouds_light,
            text_time, 
            text_low_temp, text_high_temp, 
            text_now_temp]))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Determines location for time and weather.",
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 Hour Time",
                icon = "clock",
                desc = "Display 12-hour time (off) or 24-hour time (on).",
                default = False,
            ),
            schema.Toggle(
                id = "celsius",
                name = "Celsius Temperature",
                icon = "thermometer",
                desc = "Display temperature in Fahrenheit (off) or Celsius (on).",
                default = False,
            ),
        ],
    )

def draw_sun(sun_height, cloud_scale):
    if cloud_scale > 2:
        sun_color = "#ffffc5"
    else:
        sun_color = "#FFFF00"
    sun = render.Column(children=[
            render.Box(height=sun_height),
            render.Row(children=[
                render.Box(width=22),
                render.Circle(color=sun_color, diameter=8)])])
    return sun

def draw_moon(moon_height, cloud_scale):
    if cloud_scale > 2:
        img = MOON_CLOUDS
    else:
        img = MOON
    moon = render.Column(children=[
            render.Box(height=moon_height),
            render.Row(children=[
                render.Box(width=22),
                render.Image(src=img)])])
    return moon

def draw_sky(day, day_ratio, sun_height, cloud_scale):
    if day:
        if cloud_scale > 2:
            sky = render.Box(width=64, height=32, color="#aaaaaa")
        else:
            if sun_height > 20:
                if day_ratio < 0.5:
                    sky = render.Column(children=[
                        render.Box(width=64, height=5, color="#87CEEB"),
                        render.Box(width=64, height=8, color="#FFFF8c"),
                        render.Box(width=64, height=6, color="#ff724c"),
                        render.Box(width=64, height=4, color="#AA336A")])
                else:
                    sky = render.Column(children=[
                        render.Box(width=64, height=5, color="#87CEEB"),
                        render.Box(width=64, height=8, color="#FFFF00"),
                        render.Box(width=64, height=6, color="#FFA500"),
                        render.Box(width=64, height=4, color="#ff0000")])
            else:
                sky = render.Box(width=64, height=32, color="#87CEEB")
    else:
        if cloud_scale > 2:
            sky = render.Box(width=64, height=32, color="#202020")
        else:
            sky = render.Box(width=64, height=32, color="#000000")
    return sky

def draw_ship(day, wind):
    height1 = 8
    height2 = 9
    height3 = 10
    left_space = 4
    if day:
        ship = SHIP_DAY
    else:
        ship = SHIP_NIGHT
    if wind == 2:
        ship = render.Column(children=[
                render.Animation(children=[
                        render.Box(height=height1),
                        render.Box(height=height1),
                        render.Box(height=height2),
                        render.Box(height=height2),
                        render.Box(height=height3),
                        render.Box(height=height3),
                        render.Box(height=height2),
                        render.Box(height=height2)]),
                render.Row(children=[
                        render.Box(width=left_space),
                        render.Image(src=ship)])])
    else:
        ship = render.Column(children=[
                render.Box(height=height3),
                render.Row(children=[
                        render.Box(width=left_space),
                        render.Image(src=ship)])])
    return ship

def draw_ocean(day):
    if day:
        ocean_color = "#0000FF"
    else:
        ocean_color = "#131862"
    ocean = render.Column(children=[
                render.Box(width=64, height=23),
                render.Box(width=64, height=9, color=ocean_color)])
    return ocean

def draw_wave(day, wind, w1, w2, w3, h1, h2, seq):
    if day: 
        ocean_color = "#0000FF"
    else:
        ocean_color = "#131862"
    colors = []
    for s in seq:
        if s == 0:
            colors.append("")
        else:
            colors.append(ocean_color)
    if wind == 2:
        if w1 == 0:
            wave = render.Column(children=[
                        render.Box(width=w2, height=h2),
                        render.Animation(children=[
                            render.Box(width=w3, height=1, color=colors[0]),
                            render.Box(width=w3, height=1, color=colors[1]),
                            render.Box(width=w3, height=1, color=colors[2]),
                            render.Box(width=w3, height=1, color=colors[3]),
                            render.Box(width=w3, height=1, color=colors[4]),
                            render.Box(width=w3, height=1, color=colors[5]),
                            render.Box(width=w3, height=1, color=colors[6]),
                            render.Box(width=w3, height=1, color=colors[7])])])
        else:
            wave = render.Row(children=[
                        render.Box(width=w1, height=h1),
                        render.Column(children=[
                            render.Box(width=w2, height=h2),
                            render.Animation(children=[
                                render.Box(width=w3, height=1, color=colors[0]),
                                render.Box(width=w3, height=1, color=colors[1]),
                                render.Box(width=w3, height=1, color=colors[2]),
                                render.Box(width=w3, height=1, color=colors[3]),
                                render.Box(width=w3, height=1, color=colors[4]),
                                render.Box(width=w3, height=1, color=colors[5]),
                                render.Box(width=w3, height=1, color=colors[6]),
                                render.Box(width=w3, height=1, color=colors[7])])])])
    else:
        wave = render.Box()
    return wave

def draw_stream(day, wind, start_width, start_height, width, offset):
    if day: 
        stream_color = "#00008B"
    else:
        stream_color = "#00094b"
    if wind > 0:
        stream = render.Column(children=[
                    render.Box(height=start_height),
                    render.Marquee(width=64, offset_start=offset, offset_end=0,
                        child=render.Row(children=[
                            render.Box(width=start_width,height=1),
                            render.Box(width=width, height=1, color=stream_color),
                            render.Box(width=65-start_width-width, height=1)]))])
    else:
        stream = render.Box()
    return stream

def print_time(day, now, clock_format):
    if day:
        text_color = "#000000"
    else:
        text_color = "#ffffff"
    text = render.WrappedText(
                align="right",
                width=64,
                color=text_color,
                content = now.format(clock_format),
                font = "CG-pixel-3x5-mono")
    return text

def print_temp(day, temperature, x, y):
    if day:
        text_color = "#000000"
    else:
        text_color = "#ffffff"
    text = render.Column(children=[
            render.Box(height=y),
            render.WrappedText(
                    align="right",
                    width=x,
                    color=text_color,
                    content = temperature,
                    font = "CG-pixel-3x5-mono")])
    return text

def draw_stars(day, cloud_scale):
    if day or cloud_scale > 2:
        star = render.Box()
    else:
        star = render.Image(src=STARS)
    return star

def draw_clouds(day, cloud_scale, threshold, img_day, img_night):
    if day:
        img = img_day
    else:
        img = img_night
    if cloud_scale > threshold:
        clouds = render.Image(src=img)
    else:
        clouds = render.Box()
    return clouds

def draw_rain_light(day, rain_scale):
    if day:
        img = RAIN_LIGHT_DAY
    else:
        img = RAIN_LIGHT_NIGHT
    if rain_scale > 0:
        rain = render.Column(children=[
                render.Animation(children=[
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=5),
                        render.Box(height=5),
                        render.Box(height=5),
                        render.Box(height=5)]),
                render.Image(src=img)])
    else:
        rain = render.Box()
    return rain

def draw_rain_heavy(day, rain_scale):
    if day:
        img = RAIN_HEAVY_DAY
    else:
        img = RAIN_HEAVY_NIGHT
    if rain_scale > 1:
        rain = render.Column(children=[
                render.Animation(children=[
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=5),
                        render.Box(height=5)]),
                render.Image(src=img)])
    else:
        rain = render.Box()
    return rain

def draw_snow(day, snow_scale):
    if day:
        img = SNOW_DAY
    else:
        img = SNOW_NIGHT
    if snow_scale > 0:
        snow = render.Column(children=[
                render.Animation(children=[
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=1),
                        render.Box(height=5),
                        render.Box(height=5),
                        render.Box(height=5),
                        render.Box(height=5)]),
                render.Image(src=img)])
    else:
        snow = render.Box()
    return snow

def draw_lightning(lightning_scale):
    if lightning_scale > 0:
        lightning = render.Animation(children=[
            render.Box(),
            render.Box(),
            render.Image(src=LIGHTNING),
            render.Image(src=LIGHTNING),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box()])
    else:
        lightning = render.Box()
    return lightning
