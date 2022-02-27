"""
Applet: Nixel Clock
Summary: Pixel Nixie Clock
Description: It's a Nixie Clock made from Pixels!
Author: Olly Stedall @saltedlolly
Thanks: Joey Hoer, whose "Big Number Clock" code this is based on.
Notes: Numbers are 15 pixels wide. Seperator is 4 pixels wide. This is the widest you can effectively make a digital clock to fill all 64 pixels while maintaining numbers of equal width with space for a seperator.
"""

print(" ---------------------------------- NIXEL CLOCK ----------------------------------------")

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time") 
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

DEFAULT_TIMEZONE = "Europe/London"
DEFAULT_IS_24_HOUR_FORMAT = False
DEFAULT_HAS_LEADING_ZERO = True
DEFAULT_HAS_FLASHING_SEPERATOR = False
DEFAULT_CLOCK_STYLE = "round_darker"

# Constants
NUMBER_IMGS_ROUND_BRIGHTER = [
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACj0lEQVQokVWTO2iddQDFf//H98h9N7e5ITVeIkmKLUmK0UFQRBwVxLGTi9RFKIiLHTp3cXQQBGeHYgWLSEFwUAQHl5bS1lIqaNI0bXOf33189/8dB41tfsOZzuEs5xhAPENqDTVvaduEg3HGnwZi55jOAjOOYg7D1hiakacfzTEbD1mZS2k+v8r44Am3BjllMyWMe/Ty8H+bB7AYFqsxo15g3k+4sBrR3Mvolh3tlQUmDLm067l+J6JlHrM3DU+bW9UEkxVUU/j6dMLpYsTs7BKsO3Rln9GNjE6txvkbjmu9iFJ4TDYLEDmrtVpDbZyubpU02US9yysKD19XuHpCxeg13Xq7qvvL6PdXnDaPNRT7VM4gfBKpYVKdrXk9OoWGH5Q16mxr/JHVZAuFmysa/3BSv1XR3TPoi82K4mRe1jnZd2PDssasR44wBXduEX+vT/ZrwX7D0vlsF7/Rp/Uy3O96unGTbZ9TtwF78YTlrcjy1xAeBjDzHmU5hYVhgAfXJ9hpTvpSQm8HftwZ0k4LlgPY25OAx5DF0OtA/qSCqTYIA2hEhudWLfRjurdF4me8afoMckMPh/3078BXWPanM9opjL7ZQe2CY1uWub1A+mELs7TE/s9TmgsJp+qeX3oDdk0BGCtXjhXj9eVxr/Eayr5rK9xZly7Fkra1e6Gpn0B3X63pjcWKwMiYf7eimneqR7FeNE5XjsfKNqzybxfU+X5Djz6e1701pwefvKdzq3WBUeScAJlDqSQJpVBQDwXvVwzvpOLy8klanQEvuC6fx3Wu3TygZCeMihw9u20MlKzFGE88yzljLXHV0514/hiPOKCgbCOG/wWPHOMQi6WIDLVQMFeILobcWgoVSEes/AN+GTO8WTDhkgAAAABJRU5ErkJggg==
""",  # 0
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACaElEQVQokVWTv24cVRyFv/u7987MznjZ9Tq2EwmMQhSEogglipCgACQaiqTIa6ThzxukoeUZkKgiIaVLl7xAKgpAio2wAwmbWNmN17vjmblz7y8FMphTneKc7vsMoJxJ6YQqs6iBsApI7lCFpk80KZ2dIqfFirBdeLz1NLWlMgPOvX+Zqtqiw6HWsJnnOGP+PRtALYadYcXsRBlL4JsLsIbh+fmPuVQdoOT8MBUe7u6xbpWjticpWODuTjXkdRLOact3FzNu9ImrN4Qvbq145/cp9uUJ18YZL5Ly67xj7B1NjIh3ghGPbxu+2hLKVw1/auDdTwcMv/6ErZuOv6dLZj/v8+2g59qoYB4TuQiS5Y6DuODLQtnoEr9p4uKaErwHNlBreW8MT73j1XHLzfWcEosag7wdE5s95IXwIgS2x44sGLrjltTuE3aVwhm2h8Ify455WTGs1qg04q6L8iwI+5qxkSuTBE0GhQGNjiRCWMKg70lGOJwdE7sTRsYgiyS0AsugSAIXhPXeYIaKLT1uQ3GZUovFR7iqNdb2NFjkcUj8QsTIiutdYn4UeLlSTOkBj7c9xcQxnScmPjEqPUcnkYUm5DBBq54nbca0MFwIhr3nSlwq8Axs4MluhC5yZTLi/gwa4wkoFvRuhhCi8DQlPhzDB7kwer0iLRsOH0F9EPjo9mf82Obc2/uLynma2P9DmAEGViii53yp3Nk0XFq0/DS5wudVx85sn++Z8OCwZqAdddeRTvE8pbwUw1bvqUmUPqMuHAMM87pmEQNvkbE0gaT6H9tnTcmNoAaMWlQDAbDWQlJ6/b9VbwDGohaC0uHb4wAAAABJRU5ErkJggg==
""",  # 1
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACjElEQVQokV2Tu28cVRyFv/uaO55dr9f2Im1sb2xHdoQlIAVYoqChQNAE0SFRgOiAliiiQuIPgAqalAhRICo6UiAhUaIUkRVpCQqQbB62Yzmz8Tx2Zu78KIJF4BRfdY5Oc44ChKfUMYbEGGrXYrKGExNhrIamIg/t01bUadhoTd8oUpPQNAWb1rO1MSIrT7h2WNCGmr7MOK4qannSZ59A0YstR1ozMi0fDw3nDzN+m9dsri2hdgo+n1h+vnGbgYHjMCPIP80DH5GKYxA1fLvRsjvUqItr2FVHfTfF//iQ48eLvD8pufpHoOdKjuqAdlZTmpguDV+uwPBeTf6Kw79zBnEzOq8lVJf7dNQBX51puLBgSGvBG4PqxVZmleLtJccH84q/yoyz24ZVCQw01CksfH+OfK/m8Yd3+Lq7wCe3CiLVYneMxVlNIjPGdcB6y/Rey1xHo+IWl0KvF+F04DCDeNhhORbIp9h15ZjXLXui2MCy6RQDI6waIbngCCONyjOKbw552Df8/ugEWxU8o8Hep6YQg0eznSiSoubslrB85XnYSlA/jJm+e4ebtyMKD91ZgW9hTjvsOG/I9IzXa8X2XExxd8bi5XXMKKK4tEd5LWd/opikFWsL4G2XNEwJSmMPBKyFXzO48WfJxZc94dUB+ovr+F9qwqomsvDsUZdSYr4bpzwyjlICAOKtliXn5E2c3Nw1Ivu7IuOX5OCzZZH9F0Umz0nz0Qvy1nBFAEliL4CoU3ivWAmWNxrDpZ2S4/N9rhbneG/9PvrBCZ/+VHAla+hGmrwSWuTfbaNBG8dIFDuNIqFlMVH4XHOdklvA1HqKtiK08t9jnMpqRas0iy2sSeABhgPbokUR/veqvwFrJxmvGzVx2AAAAABJRU5ErkJggg==
""",  # 2
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACgklEQVQokU2TzWucVRTGf+fe+35kPjLJYEyso5EGta2IASuIoIuIIGKFLgR3hS7dKbgU/BMEF65cuejKhbarggiCpepKEEVqS6y0lHSImU4yM+87772PiyTaZ3FW53c4h+c5BoiH1AqO0jtyPItVhULGPyGjairGTXy4FTuGvXMseiPLAmFSMcDorwxY3HvArfmEXSC1YGeWmKTDIeGwGJ0QGFnG2WnNJ1sdXjjhmW6cZGl4iz9/83xxu8Pl7Tv08oymTtTpcGF1Q1Dmcg3KUt+umHTttKR3pPq8NHtVqs5r9/2nteVL4ZwGeRAgy7xJllPkkc/XPKdSTXvD8dRzJUWsmF8YEF7aZPzyZX64W/DBfeN2PWXBO1zpjCZF3iwDy9OGn0awexd2rhwwGjbkzy8TvvqOP7YjS77i3GpGLUfbBVyBsWqJR9Sw23haZUYK4Dx0PjyDK9eJl0YUPjC1xKDboeWNx5VwJPEExo5f4IbBahHJC2iWoLm6jcb30Geb9Bca4tzYm+yRC1ZNuOiMkSA2NY+2HTNBnMGEjNnXE+qPrhMeW6b13jorw8SgmSA17JvHzZO4oYTVczZm4sE+rBHpj+dY7rHroJ0D8vU2bQdDl3OQHH9HESbJgMCPc+O1cc0pDye+PEv5+5DJ93dw756EXgt35VfqtRaX7s2JznM/NYc+FxaEy/RiXupa30ufrkv7b0vakvbfkC72dPDWaV145kmBqZcVOk6mDBS8V+kKvd4t9Y2hm88G/fLxpv56pa2roHP9nnBB/RDkMR1xR4/hoGWeJhmLipzB6FqbriI/+yk3o+i6korqv2j+Dx/JO8M5T9aIRCQCyQU8UB/deax/AT5oKTnBEMfCAAAAAElFTkSuQmCC
""",  # 3
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACf0lEQVQokVWTO4ucZRzFf8//ubzvOzPZmV0ymR012YguQkLYpFBIiBCwEUQt/ATqF1AkkC9gZWetFlb2SR0shCDYbLEJIUFzWTbi3rJze+/P32Ijiac41Tlwit8xgPKKUmsILsNrpK4KnDGYkFG3BZMmvhrF/Fe2IgyMJXcJSVXyZmbpDE4jzQEP8xmzhdLzhqO6Yd62ALhjM2QdT154Rs7z5ajifKWM323QRcbm5BS/LAx37j6h66ElUrTHg3UQrAY70LVeqr+es/rgXNDJNVQfXdL65ro+fqenv71/Rq+dXlWs6MnEKqDirVDFjBWZ8eMYzjiws4oT3wyJax9jx32SbIa7/4Svujnr/R5HZWQpeKRjgKbis5HjwkqkfNoy+jQhfvAWzfwWZnePEGA3MYSDKR8tQSsZURR33gWGRrhIDUVDf1UI321Qb21hq5SYW8oS8IZ8oaz2+vQ6z+nnLbKWpnzSDezPlf0dZfjDOpJXyPUpxitxUGIm4AoolyzPF1PacsbYWuSvWPFQa44OleGNMe7KmOrWn5jLJ+DCWexoCb8MLhhs2eDmU9rWEMXi7s5ytiN87oWTCcRHh7j3xvChhfAGurmLGjioWrSEw56nji3bGnFTNRRO+F0MW9/u8fZPz5iuCFkZ6d60sOHZfwzapOgw5fZOjjPCtG0Q1UgkslkLX/8Dt/9OmN8XDraBB3PinT0Oj2B8dYOfZZl784rUw7xpj/E0QHCOoI7lJPKFhY2QsnPpdV7besp0UfO9WP6YFHStUNYtjepLthHw1mFrS20r1jJLWga6wDNp2C4rOl5oolK9QPNl+YVEBGcsMdY4FSJClIhTQ6Ht/171Lx9pIkpIaNRnAAAAAElFTkSuQmCC
""",  # 4
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACfklEQVQokVWTTWtdVRiFn/fd+5z7lZjbfBKtTWyljVK04EDBIoJjceCgIxGE4sCBYysI/glFUHTYiToVFDqXUqWltolYlaSpaNO0N8n9OOfsvRyUartGa7DWYMGzDBAPqYhOKzoLCVYa2G05fzqkpmaveiSKPzDRnUMtY4HAU2NjpYbeyjILuUs5zFSNs9ArmI7xv7IBihjtVgey8XpR8dFzic7iNN/H47za3mS41+XjDfh2fZPHSlHnzLDJAKhbBuFBL5dd7ZxuSz8fk64sa/TBtPTdnHTrBW2fWdLzRVfgmm0FAbIYTAYseeT8UefUoii+OUnz1Q38wl1G7cggGdV6zaU0xfu3jJ3RAVPRcTeokzgzZyylxOWfKvzqPdrvrKJ5xzcadn+suTIxns4j3pwLNBboILwjZzUE+rni96HxTz9y59xvUDXYJ6/Q+/IwJ04bT07Etoz5rtNS4FnAPTtrBK5XBVeVqHqJre3A7TfW0blLpN0x7c9WOfpMi/YoM97fp5NqnmiBV57ZVkOIRrcduLcrNvfF3b1Mc3HA5K3b5BuJ1tlFlqvMiSQMGOB4TeJyFnUFx3PBuHZmZgpmlTjYd1IfQr9ENcwW8OvEGJK5OBGYmcxdc1bo0/mgC7gGX/elm0eUzpbSL4+rGZ/UnRe7unakrbXCNW1R3eBySQRgxzJfDIx6MdI6P0J/OfW7h0mhA29fI5TH+NAPsVVDEQLDlO8TZkAMzlQqONUX72WwKrP50hqvXf+DrYMJn/d6/PD3AAvGfpNpdH+7HlAeLdJWZjnDTHTK2GG1SGzs1dxEjELDEKNK+p/th59ibpRETDWlwAySO02GsfIjr/oXZDwq6SomrP0AAAAASUVORK5CYII=
""",  # 5
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACfUlEQVQokVWTT6tVVRiHn/dda++zzz735NXr6W4tPdlNOxVIiVQgSQ2iL9CgDxBJsxw6cZIDJw6aGEIT8SsE0USIJkFFaUESohFkngzvPf/PPmvt9TqQUn/j55k9PwGMx5Y7JXPgGqVoEkEgZgpiTOrmcRT5T3aqlE6o8awCbEhi8+AmcRm5NbxHwniqcFhjjEJ8JHuE3OfMG6ic8UmlPEPNTxuvcojEqr3g8r+R6zdvsytzNBjT0OABvFMWTeJwqVzazKn8ku3aeOvITVh3DK8mqm6H83tLfrm/oOccUxrUqRKAva3IxSqnM6/54V7kxQNC/8qAg+8UjIdj/O2/eb/j6ZVdJiGwu8hQw9E0yke9Fr1JzbVp4Nga7D67D1gQPr9LbyNjJxNensx4rxCWXtEUUbGG1zXgF4FfZ8aWefpv5ti7x1iNA/pxyeAkvKHgM6Pak5Nbm0MIapJ4STKuzRN/ENhaa+ic3o+MhugX/xC2wZ3aw5ETOW0nhPGMtWbJSc1RZ55vzeh32rzWcmQnHLZvSjrzPcsvt5lcmBP+jLhT6/TryGacA8bMG5rEuJUiXoTjpWflQMyR5o7FAloOXNkmrBdUCe4mzwjP1zGAqFhXsAPq7JtB13a2sOGlntlvldlptfhZaavxwOzT/Xb9udJe8M66TqzlxB5GIkrbPEc7wsXDwiurwPTtDpPjBc8OFL5aMPu5zwc//sXVO/fJMscoxIeFCULpwJKjnzvObQRuhKcZPV/x4fAGd0ZLztU5380DPvNMYySaPWobhRaKS0JCWW8ZR4uC1jTye+PYoWaaRVZJCI09eYz/nyKKqGCS2BWNIErIFGLDKj2B8gDhqBrpBld5swAAAABJRU5ErkJggg==
""",  # 6
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACcUlEQVQokVWTT2sddRSGn3N+M3Ond+bepA1JDCLEWirUtpQsdFm34kZ3LoXSleAH0I0IfgU3Ct0q3SkILkVKobS0lFAKWkOt2qRpTHr/zGTm9+e4CGp7Fmd1Xt6zeB4BjOcmc8qxTFkDVmLkQJRtUQ4lMuvS86fIv2GnyijLWULIeuNMBpwYM2hatmYtDyWnHyrR9zzrw1HR0RLKHDIpWI+eT1Y6Xl5x3Fhe4q3lhvjkT766t8C3z+akAqI5Zj4CYOOssLqsrVJnP53C7P6G2dOL1tw5aeHJGbPmHYtfvG4fgDlxdqLMDbBMnWCDIa4NfL4Kp5zw99UtqtWSgfUE/wg+Oo4btXy8XHBtXrDrWxYHOa5Q+azxkYujnvcr4fYUwp0WuzFjcKslWxuTvTngj09/QRqlP6b8vA+lGPqSyzgNlArbLUxF2a0Vv1YRMnAf1vD7lP1NmETP6miBYlgwxNBxrmyUyqxTNjMHJBajIvOO/Kwir5V03+/gG/grh98mc4a+5RVRdBoSj2LARCgTSAJnieNNYHhpEXE10x87dsaO1CpLYY4GqMShj0Pkujd6jHPe8A3EJFRDkI2KeHOH9p6x7RMLKUfyAROFB2Jon4yUKfcPjU2EJeewg0j53jKM38Bd2WUrgfcOyozv9hxBhG3vUTMjT8aeE75ujYNCqSYOW63h18c8/CGwF+DCu2/zpRtzt5lRIXQpHeEpCJoLUR3rGJdz5eTYmJxfx92c0B7u8k054tr+ITWBLiW82f9si0IhAzqBmp7FkNMXNa+Wngddx9OuZyhCUOijvSjGf6aIA2dYOHoLB5XleCJdetGqfwAyLSEmweXYhgAAAABJRU5ErkJggg==
""",  # 7
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACiklEQVQokVWTTWtcZQCFn/fr3ul4ZyaZTIepBFKalohWQcGibop0oXajIi5FaBFc+i/cdOnGhRvFTUT/QBE3gkJAEWu0arSBaU1q06bNzHjv3Pu+x0X9aM7irM45q/MYQDygzFsK7xg5obJh1wcShpqaaXUoivm37K1lKWTMnbDzxBMxJy0NIM3YLitu4yjilGlquFtHAPx9MwxbGfsRjlvxtok8e6ykerNPbxPGV3Pe8wtc/v03ulVDERyTfwY0bGdq5ZlOeqPPh7n0RlvaflJp94x052lN3ir0/YmOXhotCd9RL+QChPNWR3sd9YLTR8uFxiNU/rKquPm47r3oVX82ULW/pqur6IuTmU53e7IuaDFksh1g7+Avns8tp0PFTgCzFNDGFvlXDdWnt3C9NvdGD7GwX3NxJHCGJgp/vgU/l9Cx4FKDq8F+8ie68Cj0b5GfMejyNcLWjLsLhio/wikSf5gJ9pmu49WOxcwN37UMRRfMXgl+gDk3wg0XiZsVdk9E6/jx5oR2rBgYi70yNYzrxM0MVuYW+gbeWcGufwuvf0368CfchQJ/tsWR64a1rObAJspksOvThvVp5E41Z9U47NEOWEf18S7phqe8NMPTpvNYRjGfU7Q8201iYgFjrIo8U9d4vbtotTPM1fzwsMpfl1VeDKo2+tJsTdceybWxEvRUkQvnlFsjAIXMqZu1NMic3vdBk+eM9M0xNTdOKW4d1+TlQuNXzun8yqLAqhWcAJn7ZihcAGdYMInXqshZk5i/sEb3yh4749t8sNzny/GMwlZUStTS/982Fto4aixKhhM2MTQ5BzRcjxX7QGY9tYnMow6D8R8pxuKtJUZhiQgIziElqnSYqr8BOGQyY0M+wDoAAAAASUVORK5CYII=
""",  # 8
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAACk0lEQVQokVWTu4vcVRzFP/cx9/f7zWN33J1lXRMS3VViHqCSBbWxShTsxcIqKgGxEJs0/gGxstDC3kK0UFEQK0lAEIIW0cLdwBpWQ2Z3x0yc9/we996vxRqSnOJU55zicI4ChAdQs4amM7SjZrP0dGuBG6aGj5FB7h+Uou6ZndYs1TKiEkzu2bCa8UqHapbz73DMxEA7q5iWirtlAMAekmaxqYlFybpxvPNI4KQu2XrpUTZu99ndh09J+eXmkNUs4CkY/R8gy6mTdj2VZxMtW08pkXdrItvPy/zHUxJurYt8vCa9UwtybnVZIJGjiRVA0EZJp6FkQ6fyw7qT6rwWyU9Kvrsp+fup+K/WJEzOiL/YkN9OWFlvOFnASSdxolvAYG443xFOT0tGL64isUn1xq+EbmB6aQ+1NWXy3nHW9j1vr2SMbCREjz6RZbxsE9p5xYFXzPrlYesvGORWQNWBIxF2RuwDy+1FUm04Ihq9oBXnHMxD5HpbMf62DzenmMtnsa93yD7soJYd/pN9potwY9xnqSo4bg161+dczXNyo2kBe1rRu7CNunqAeS2FVx8nfDOhf92TGzhazDHKMhJBdwv4zmtuW8eTpaE7Mvw5sVRv/kX8uosNU/LP/+H3CMkcSBx3RbHjI7qIkUQZro0iP1eaLCp2ep7JExZ34Rh832P7igfboP5Yhy/vaKbAUAI6iCCmYODh8sBwUHcsjIWhU8hPM7Y+6NOzis1XnuOj+jGuDec0jWIW5XCeCkViNJXAilO8lUYy5Wiffppn9v7mj/GAL8Rx5Y6nZQ25L6lE7m9baWigmKAhJiyZwNlWyhlT8Fk/0KeibhVeFGWIDx/jHowyiIYYoSWBGYamrRFCwUQekvIfk1A8AQ/Pu/YAAAAASUVORK5CYII=
""",  # 9
]

SEP_ROUND_BRIGHTER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAPCAIAAABMVPnqAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeklEQVQImWNgIA4IMDJUBTAsTuNU5WBmODqR4///mf//Bz/cyMH4840qm7A5A8OjP1dvMaiIsa1JYNiTLWAgyI5qADsDw8Qiua3zjCXZGRgWN0n//x/x/7/+/eNCTJZa/AwMfxkYWAT5JBlkORkPdEju7lbX52cl0mkAeiEh30PI8swAAAAASUVORK5CYII=
""")

# Constants
NUMBER_IMGS_ROUND_DARKER = [
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAAB00lEQVQokXXTTUuUURQH8N888+hYarPQwUm0skJdhCBBRLtWQQuJCBfSpjbRwiBoEa3rG0TSy7Z9gZ8gqEULI4wgwRahRWaWlePL6JwW86RT0oHDvefe///cc849J4fQKDkk2bqZnSWo2SXJX1YeTRkwQQ+KSFHYhZZu71qwVgecLVP+xuIeBrup4O4XzGURbe0EGQrYqL86cYiRGpURHCUmWZxhrpXR91jNIquRyG27cGM/o+tUxum9RW9K32PmOih+4EEZzY055+vhtrQwtkVliPbz/LjK6h3SeU5fYaZCV5VzpZ2CJmm+7mUgT7VK4TJdC3ye4tU+pm/SeYL+AaZWWGpqIE90cDDhwzrvavxcYXmWasK3LaZniBXaj/F1iWeLNDfV00xeVuslX01Z+EVTK8UjVCv0pAz3svWdT7PsTTiVYyOrdvLwK7NY22S4mS9PWO5koJ/OJUqXSPt4/5ruIsdbsy/NJDQLxIU2sVAW8/dFvBFxTUSI55fEbeLpoLCvjs1USDIlxtvExwPi5z3x9pGYGhOTZfHiYneUujJSrpFMSHccnCyIh+1i6LA4UxLXy0LvLmLkNA7Gn4apZWtBfTg2G+4bxugfc7t1GrL6L8pviIKwhVKRtO0AAAAASUVORK5CYII=
""",  # 0
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABrklEQVQokX3TzWoTURQH8N/MZPJhmoZipVWqqLiQLqpuSl0ILvyA4lP4DG4Fd4pv4NbHENzpRhDpRkTtorXaSom1SZu26STjYqaZ2IoHLpx77v9/vm+A1KiEiBCgh1KOGJxACodakANDHOa2s6gcex+RYOivkpMC7k7QxMppZmsZ4GUL33PnSUbOfJXztAIeTjHf49IsV27y8zXvNpke53kXv/Ky+oTCPH7C/XHG2nxMubfA5WczFu6wvMXGVx5VUCsChUrZpREz3ed9yvVTbMdwThJxo86XEut7zI2NNmyQkcsx3xLOj1FLaHc4aC/5vUyzxEyNT3u0qkUTw2qQkVv4ERMO2ImYDEh7ZYch3S71fpbtZqdoWLifFjUHKaWEC33CBtXJqvoElZgdxAOupcWAQ/1iaLcO2ezyeZ9yDWqaEY1xVneZKjFxNFKEw61JWClnUT9ssbsLq0S8Xcve5xu86hQNi/CEbFWWB1ysMx9xZouDNZbe0FrnwW2eHrC9kaedjm7YkRaz2GSuy4sGi1WutnkMnRzTP76eQX4GwyES53rPiU/xN/l/1n+j/AHRo4j4aidAOgAAAABJRU5ErkJggg==
""",  # 1
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABzklEQVQokW3STUvUURQG8N//ZXSmaRwMoaSsiAhGLSJy4yJauS5qFUTbaNEHiHZ9gHZBXyBw1SYI2hS9bTQhkuyFWjSF2iRmvqDj5G3x/5uTeeBw7z2c5+Hc5zwRgvaIECNBM38n+P1fp+hvKWoDbuTn3pxgIa9BaydwYQs8UuHUAhOH6d9NlHJ7Fl/yno12cJpTJNzax5UeohF29bI8Tfdj3i0zNItG23RiQUGQCNd6hdGyMHZVWPkohPks6/eE+nHhYU1QFBBEQirO/tFV5miLRwVqL/jxnIGYxUX6J6j/pOsGZ7p5OpPNnIED5cB4i7TAXIN6kaST0hJrDSoxH1Yp7cn1aZJ2oBIxnevRn9IXczKhp0bxLJ1rfB6lXubtYq54RNrEXC79iSLVNU73MXgHw5QmmbrEkxmWOuhq5uJGpNbzS4uhThbnOHad0iDTl/n0hslZppaplSkmW+BYyKRvNXk5w/kBVi+wepOeMcpVyn0M91Ko8Gr+H3cI4jwJ948J4b0QngnhgRCmhPBaWLkoxNV8TWl2bnGk2eL3b3D3AF8PUfnFwSMkDc6N873Z5vMdvS0jSVEtUFzn26aZ87Vujtw2fZvbbatuA23GH0H1rEYfhg45AAAAAElFTkSuQmCC
""",  # 2
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABw0lEQVQokX3TO2tVURAF4O+c+9C8JInBEE1CCGjjAwvBTrBVEQRL/4GVlVaSQlsFwcJfYKXYioIgYhpBIYUi6YxJzFvjzcPcc8fi7puX4MAUA2vWXjNrdoawO/KUUN9VN1LugzYjS1UpNdXRRbVF0kAl4VKU99Bk2OLOWS71szzC0BJvv3J/lvm5RF7s6A25kAllMdYl4pmI6I/4PRjxU8SvwZi4njCZUBKIksyYrKnhRi/Hy0x+oudNTeXFL0uHiDOdft5d1d5gfCuNkJPLmhLKVfr/8LLG1DwTb5hcpPcCXY+mvZ7hSInR7iQ537Www8FsQWeVokS5xKmHVLqPWn9OR4lVjLSn/QR5a/CFnImM4QptVTa6+P6EmJlWPGaoSlFncSO9nLVkoyg4doDfQX2TFSy9YvEmnSfpu8LwKqPFbp+jyZTVOb3FyjonMFIjL5N/JL7QMURvxmySrEF526+CD2ucy7k6Tjxl6j3Vaxig8opaD+PL6R62fbbj34MOEbdFzPVFRB7xoy3iivh2XnQPJGzSu8PROrsqtza5eJSFywy+4+1n7nVgLeEaOxe9t3nvN3EQGy3UPkz2Dzzby/4/4r8FU7Qqc6XUHwAAAABJRU5ErkJggg==
""",  # 3
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABzUlEQVQokWXTP0jVURQH8M/v+nvPfP7NaMgUsoYWKcsCcW0ImiVaWluC5oagpS2oqaGgzcGttqCtIRocJKjBwRKNUEtFTX3v+d67De+mT7twOYfD+Z5z7vd8b4ao9WRoS9F6iuVopNty8iMgCVhDAT2pQCXZPNl4CGm6xQTKGe/meo0LI8QyH/7wtozFVLylQNQmykRF8cmQ+GZInL8kxhlx66X4fkB8OiLqT3m5iBgOemc8PsVooLDL+fvsX7uja4CudgqLPOhAKU3YRhPcYLCXWz1s/+LyDSqT7KxOy1bpLrCUU9pmuJQemxEEssC4JjGD/fS9YusT+RyVXbaqTS626pztSGTWCR0FbrezXGF+jdHntG9SfNQkZP8k2Q7Ffcol1spp7EDYi3yJbOxy8R5dk6xPE8ZoG6XzDJ095Dl5jUL5kKOgwtcyeeDqCSozdE6QPUT3gOos9YyVGrHKevFwTU3SA58DUy+4Oc1SL6erDL37yRW+LxPrNPr4sZbE1CAcKKzO3U2erfN7gbkVzFL5yNIuw6O8zlBNQmm0KiwkL2csMJGzcJFz39goMxWwl/Lqx+WZdqeRbCGx+q9wraXBf9o+/kHisdjRLPAXy9+izfOkj3UAAAAASUVORK5CYII=
""",  # 4
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAAByUlEQVQokXXTTWtTURAG4Ofmpon9pLSWCAUVWxUUFfoT/AGKbrVLBUEQ/4EguOnOjQvBrRsRdKUgbsSFCAopVZAWq1Qt9NPSNk1zc4+LexNTPwaGmQPvO2fmzHsiBJ1WyD3NvYgoz5v+gmYW5UBIcvBIXrqRn0t7GKL2zcUM0B3zYIyhYd4knBpgbYur8yTfEeeMNCsQxIIoi9WTQngmfJsRlh5mMcwIr84KCgKCYhaL7XkipioMRqyPkd6j+ZrVMtUmtXmuVLi/ko9RpNBq/Gg/4ymPPlF8S+U66RDxPAszvNhlImV0IB82n+CWiPESPSlLJQ68o3KR+iX2n+bgZ5Z/MFtgqcziRvZwbfJ6gUJMfw82iZ7Q/54wyvBNys+ZW6GasFxjoNRqG3FMXxerm3yosbDNTpW1GyTTDE5yrMGZXBWb7a0FGgkTgVrCSC+HA4vb1PtYPUKzwaEi1d2MnCatVUXZ05/rE24T5u4KoSrsnBfCS6H2U5g+Ljwc7lhXJOxR2NMa9QEGHxO+snKHWhfhAuUuJluyLWTd/lZYK+vmWiBKmD3B5S983GFqH8lGh879SW5Z0P4gvTFb9Q4xazM6yP4N+A8K/AK/2boAr+nBDgAAAABJRU5ErkJggg==
""",  # 5
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABz0lEQVQokWXTz29MURQH8M978zoZU9NOpU1DQxskRRgTIY0QCxsW2FixEEuaWEgsbEQiwsZOWNK/wFLEQlKJDRsbFStBquhPQqfTNnMt3pvpqJPc3Hu/55z7/eaecyIE7RYhRqPNk8vwVf+FhtYpytBGtvdiGb+ye5L5GuuTm2wxR7vZjlfdDGOpwIsFfMviMoKk9UQDeW6V2Znj6wp3L1OqMnaBbUXGNuLPmsK4JTXhRg/lOk9/cryfLZd4c4/pefJTHCqgIyNKmiIClS6GaozXOFFgz7UUr04x1MV0woEapXwmPRALqYxkmZdL7MORCuFir7kfFB9y+iCnYvI5NpfWqhCLKONtnQ8YKbD1CrkvMzruM/ec0gNO7qcrR30xTd4RkQgsRAwWONags8pqlZWrzEwwPUtUZtMYeysMRHzC77j5YYF8xNl8CiYzrNSYrVPKsaGYyqwEJjPJ3xtpmQKCSLgzIEz0C69vCkvjQjgvLF4XFiaFMCo87hPEaaxIWGsSaZ0fDXBulY8j7D6DTjzj8zsG32O+raGy5NBSkAijPcLhkrBrWHjSJ9wuCjoyf5zt2pmbzdLUkWSr3obFLap1vd1uzSFpDkjOv1OW2V8O4Jw17eaE3gAAAABJRU5ErkJggg==
""",  # 6
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABuUlEQVQokWXTPU9UQRgF4Ofevesu4CISwFUbCzWRRDujhsIYE639AxbWVtYWFob/YGujNSTGyqiFhXRakIAhGwoKBUyAZdmvOxY7l13wbebN5Jz348yZBMFoJCjFPB+5S9A7gZT+R0oHoFJO6SzVDP1IPDNSGNlxNtLt1STzUyyd58k07R1eNtg4jLgwnCpIBZkgERbrQvgqhF/Cnz2htSaEncnQeS5UB7QBlpBJYv8uj8+xkPLzPfU5JgPNHl7vqdZYrPHiKK6RFWN3UeFuxpsDbr3jRpWbZaYfUt3i0zIXKlwrs75bCFZIltLo8Beb4xzO0Cox/gyrbG7wu8+lCZQLSikq2uV7FG0up9Sidp3kNttLtDusZ6wdxLGRyjkKg6caz0kCWeDKERefklXY/ExjjH6H2TwqnZDqDyvd6dFu08upV8nu01pmt0Gjx2yIT5UU5BCN0WUF9ZTQZOYRLteMvWUlp90f7PpjP5L7hcNigZUO2xlTLXpz+Lbv4xe2+jxYqFiMTQpOovB2OjTrvZT5CXavkq3S7PDhDJpDYuHocJyNnnncr2zg657TjNF0JFInf1QRp5D/ALlym/tLcsmtAAAAAElFTkSuQmCC
""",  # 7
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAABwklEQVQokW3Sv2uTcRAG8M/75jVpbdrQRK0gDi7ij8XFoajdBIWKiqv4L7iKIAoOHVyETk6Kg5OTgm46uHTpZEErCm1BtC01aFtr0zTnkLdtUj04vtzd89wd3+cShE5LO3wDhY5aswsp2SYnOTDBJloo59VGjo4832qH2XabLC8mXMSlQVavMPSJDzOMFfA9J6Y7DcIeIRNScW9AxAURk6I1LWJWzF0WTw8IlTZGKhCpNF+3xY0KIwmLd1j/yZfrLL+gf5y+hPu9KOYbpu0FWCfNOJcxXaBwiJig+p76S0qHma9xcIXzg/naQdaXsdqknJIF2SbFxzRvkdaojrD5hNJX5susFTuEGeljuKctw9si+/eS/SB6+iXX6DnG2kfSZZoJU/X8sxLSyTVmmvzKOLGBCnGXnofLjLIxRu9NSqfoX+JEtiNwutDgW6M9eTihUG3LtvicxgKLjygHQ0epNamUOiZr5Ro3ub1CZYpkkuIDkpMMjKNE4x0rVV4vdZ2WUNjxq6mYPS7ilfg9Jf5MiLkz4s3ZYtjX1ndL5+7zTNvvkSajWD9N7TOzdZ4Not49tZu8ZfGfuBPzD7nTdmd3kbbsL10FpcHoOOuuAAAAAElFTkSuQmCC
""",  # 8
    """
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAACXBIWXMAAAsTAAALEwEAmpwYAAAByklEQVQokV3SO2tUURQF4O/eO5OnMYkEJYr4qhVJGgnY6A/QxkYllZUgqJ29Ym8lCIJVEBFBEUGMhYUEDAQkVRSjGNE8fMU8hslMtsXceSQbNufsfdZZ67DPShBaI0VW67ZVKWdIclRlC7LRru2yvFvJSXailGeCIqp5otCgaW9eutDFiYSJIY7PM/2TBzCfE2gShIJQrK0PB0WcE/FGLC6L8pSIG+LdfmGnaOAJEqFNSMSN3WJ5WMRfsTApFs+L9TuitCDWzor7e3NsTpCCDQZ7OFVidpjYYGWU0g++3iKb4PMVjv5ipDefxyapYq3oK/OhytJvqgk9Q8R3sg4cJpthGnt25MNDQcppfNzkdS99r8im6LhL3KT/CIUDrI7yp5v3a/mwCqSqjFcopfRjJmXiMtkjOi/iEqV7zM6wknKw3FROVWrvn88Y2uDTGm/XWL5OZYwdZRYf8zLoLqMtd0aVtOGvdZ5W6Q6mfvNtH31XcZ/nkzUD9Q4w/nerGRvTe7HKXDu7SswVqTxj7DZfMs6McK0jd1ta/+VWe6opHCvSlTBwiJNLTKzzJPCvKVSP2qcnLVmvO8Xh7rqbhLTlnGgqt8b27ja1evwHvw29kK3B2ZsAAAAASUVORK5CYII=
""",  # 9
]

SEP_ROUND_DARKER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAPCAIAAABMVPnqAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAeklEQVQImWNgIA4IMDJUBTAsTuNU5WBmODqR4///mf//Bz/cyMH4840qm7A5A8OjP1dvMaiIsa1JYNiTLWAgyI5qADsDw8Qiua3zjCXZGRgWN0n//x/x/7/+/eNCTJZa/AwMfxkYWAT5JBlkORkPdEju7lbX52cl0mkAeiEh30PI8swAAAAASUVORK5CYII=
""")

DEGREE = 0.01745329251

def get_schema():

    styleoptions = [
        schema.Option(
            display = "Round (Darker)",
            value = "round_darker",
        ),
        schema.Option(
            display = "Round (Brighter)",
            value = "round_brighter",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                icon = "clock",
                desc = "Toggle between 12hr and 24hr clock.",
                default = DEFAULT_IS_24_HOUR_FORMAT,
            ),
            schema.Toggle(
                id = "has_leading_zero",
                name = "Toggle leading zero",
                icon = "creativeCommonsZero",
                desc = "Enable/disable displaying a leading zero.",
                default = DEFAULT_HAS_LEADING_ZERO,
            ),
            schema.Toggle(
                id = "has_flashing_seperator",
                name = "Toggle flashing separator",
                icon = "cog",
                desc = "Enable/disable the flashing number seperator.",
                default = DEFAULT_HAS_FLASHING_SEPERATOR,
            ),
            schema.Dropdown(
                id = "clock_style",
                name = "Clock style",
                icon = "cog",
                desc = "Switch to a diferent clock style.",
                default = styleoptions[0].value,
                options = styleoptions,
            ),
        ],
    )


def main(config):
    # Get the current time in 24 hour format
    timezone = config.get("$tz", DEFAULT_TIMEZONE)  # Utilize special timezone variable
    now = time.now()

    # Because the times returned by this API do not include the date, we need to
    # strip the date from "now" to get the current time in order to perform
    # acurate comparissons.
    # Local time must be localized with a timezone
    current_time = time.parse_time(now.in_location(timezone).format("3:04:05 PM"), format = "3:04:05 PM", location = timezone)

    # Get config values
    is_24_hour_format = config.bool("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    has_leading_zero = config.bool("has_leading_zero", DEFAULT_HAS_LEADING_ZERO)
    has_flashing_seperator = config.bool("has_flashing_seperator", DEFAULT_HAS_FLASHING_SEPERATOR)
    clock_style = config.get("clock_style", DEFAULT_CLOCK_STYLE)

    # Set Clock Style
    if clock_style == "round_darker":
        NUMBER_IMGS = NUMBER_IMGS_ROUND_DARKER
        SEP = SEP_ROUND_DARKER
    if clock_style == "round_brighter":
        NUMBER_IMGS = NUMBER_IMGS_ROUND_BRIGHTER
        SEP = SEP_ROUND_BRIGHTER

    # troubleshooting....
#    print("NUMBER_IMGS = " + NUMBER_IMGS)


    frames = []
    print_time = current_time

    # The API limit is ≈256kb (as reported by error messages).
    # However, sending a 256kb file doesn't seem to work.
    # Increase the duration to create an image containing multples minutes
    # of frames to smooth out potential network issues.
    # Currently this does not work, becasue app rotation prevents the animation
    # from progressing past a few seconds.
    duration = 1  # in minutes; 1440 = 24 hours
    for i in range(0, duration):
        frames.append(get_time_image(print_time, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = True))

        if has_flashing_seperator:
            # If the duration is greater than one minute,
            # generate one frame for each flash of the seperator for the whole minute
            number_of_frames = 1
            if duration > 1:
                # Two frames per second, minus one because first frame is created above
                number_of_frames = 60 * 2 - 1
            for j in range(0, number_of_frames):
                has_seperator = False
                if j % 2:
                    has_seperator = True
                frames.append(get_time_image(print_time, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = has_seperator))
        print_time = print_time + time.minute


    return render.Root(
        delay = 500,  # in milliseconds
        child = render.Box(
            child = render.Animation(
                children = frames,
            ),
        ),
    )


# It would be easier to use a custom font, but we can use images instead.
# The images have a black background and transparent foreground. This
# allows us to change the color dynamically.
def get_num_image(num):

    return render.Box(
        width = 15,
        height = 15,
        child = render.Image(src = base64.decode(NUMBER_IMGS[int(num)])),
    )

def get_time_image(t, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    hh = t.format("03")  # Formet for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")
    ss = t.format("05")

    seperator = render.Box(
        width = 4,
        height = 15,
        child = render.Image(src = SEP),
    )
    if not has_seperator:
        seperator = render.Box(
            width = 4,
            height = 15,
        )

    hh0 = get_num_image(int(hh[0]))
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = 15,
        )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            hh0,
            get_num_image(int(hh[1])),
            seperator,
            get_num_image(int(mm[0])),
            get_num_image(int(mm[1])),
        ],
    )
