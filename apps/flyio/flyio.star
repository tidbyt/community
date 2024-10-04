"""
Applet: Fly.io
Summary: Monitor Fly.io Apps
Description: View current status of your Fly.io App's machines.
Author: Cavallando
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

PREVIEW_APP_NAME="Welcome!"
PREVIEW_API_KEY="preview-api-key"

FLY_API_BASE_URL = "https://api.machines.dev"
FLY_LOGO = "iVBORw0KGgoAAAANSUhEUgAAAKcAAACXCAYAAABwbEtBAAAACXBIWXMAAAsSAAALEgHS3X78AAAgAElEQVR4nO19e3xU1bn2syYhZgJkkiGQQAiJLUEiIKkWEVoxXvjEY0Ub8ILQgtZLxXJpi7XW+iueo35F6SnanrZaP8VTlGI/Uz7tqahYI1hR6yWoCIoXbpGEjhMSJJNyyf7+mNkz6/KutdeemQBG398v2Xut9a533Z71rMteszdzHAdfiLdUl82qA1ALoCpxLQIw1iLq84lrI4C9AJq2tqxozHoGe6GwL8BJS3XZrFoAdQAuAnBGDyTxPIDVABq3tqxo6gH7n3n5ApycVJfNKgIwB8BCAJVHMOntAJYBWL21ZcW2I5juMS1fgBNAddmsKgCLAcw+ujkBADwEYPEXIP2cg/MYA6Usn3uQfm7BWV02azGAnx3tfFjIrQCWbW1ZsfdoZ+RIy+cOnImFznLYrbStpDBUgP6FfdG885/ZMinLRgBzPm8Lp8DRzsCRlOqyWXMQ39LJGJjlFQPx0//4FhpfXYbX3r0P0y493TPO/EX1+O3y76P+0kkorxjoJ7mxABoT+f/cSO7RzsCRkmwN44WhAsxfNA2zrz7Xd9x7ljag/tJJWHL3NQCALZt24LFV69Cwah062ju9oocAPFhdNqtua8uKOb4T/wzK54I5q8tmLUcWgFkzuhKPP3tHWsB0pWHVOty44D4AwMhRw3Dzv8/Ca+/ehyX3XGvLprMT5en10uvBmWjIjFfjNaMr8XDDzSgfWpJxnniAulJ/yelo/McvMX9RPQpDBV4mPhcA7dXgrC6btQxZBGb/Qk/QWEvDqnVoeHS94j9vUT0ef/YOjJ9Y42Wi1wO014IzsXhYkKmdwlAB7rz72qwC05Xbb/kDmndFFP/yoSVY0XAz5i+q9zIxuzcvknolOBPbRcuyYWvO1VMwctSwbJhSpKO9E7ff8gdt+LxF9Vhyz7VeZpYlytvrpFeCE/F9zFCmRsorBmKeN3tlJM88+Rpe2bBZG15/yen47fLvm0yEEC9vr5NeB87qslkLkaUN9vk39CwwXVl+3xpj+DlTTvFi0LGJrbJeJb0KnIlTRYuzYau8YiDqL/HeWM+GPPPka+Tck5f6S073moMuTJS/10ivAifi88yMh3MAuOKaKdkwYy1e7AnE56CGVXwIWZpnHyvSa8CZYI2snS6qt3gcmU155snXrPSW3HOtaR90dm9iz14DTsQPCGdFJp93So9sHZmkeec/sWXTDk+98qElmHO1kdWzVg9HW47Ys/UfXtZaxxgAoI4BSNzDvU84E/eMu48rMcg6qfv4lf0gWyesxk88MSt2/MozT75qtW01b1E9Hlu1njwFFWCBq37+nbi/Wx1urahuJ+l2Eje8LnHf6DjA7SsGNdqXKn3pEXAuvLSlCMBFDKyOMdQxoNIMRiQAyEABl7rnAbtzz9vI5tE/i6czPSIvv7gZ8yx1r7hmCm4j9ki7ne7yHS1v/ayybEyqkoE4uljq3gHA3Ap1644hhUj6/mdgwM2z9sABtgNOo+Og0QFW//zh0qyfN83qsL7gkpY5Cy9tWQ2gjYE9yBhm2wCTScBkoIHJyHuGrTs37MxWGQpDBT226e4lL7+o3++UxTQn3rJzw06hjkDUn9AOTKxzRtc/78+ASgY2mzE8yIC2H89sXf3jma1z/JXYLBkz57yLW4oYw0IWn+uEgATQNAWkgAkJmNDd88M7Y8nwjz95L/PTGAmpGXUkf9emypZNO6w6R//CAtRfOgkNq9YpYa3Rj/q59QVAZEDZnbzXsKgUx2EAS/g7TqLlmAM4uBDAhT+e2brMcbDMAZbd+UhmbJoRc867uGUhY9iG+HG0UJIBOWABPoHJxHCRXVNs6d7v74qiu/twMJNy8HK0hnRX3tm03Vp38nmnkP4HDnUVR/c1G5iSruN4GFPbSXefjMt4Egoxhp8xYNuPLm/NaHGWFnN+7+KWWgYsZ4knMcLQrB22VT8SmODDqXsm+O+OvBcDkDVwlg/zdUI969K8w/6nHqaOtHPPlrYBheXFACyZEzSLJhkypeO4KsJ9nEE53RAc/PJHl7fOcRzMuWtlqe+fmPhmzu9d3LKYAW8AGCvNQZJlguRHg5Upcc29lKUYk+vtrW0fRv2WwSRDK7I2Q0hLNvtgzv6FBVqA7v20tZMlallgShD3fPtRIxTvT9hB8p4ppMKAsYzhjRtmtC72WxfWzHn99JYiAMsZw4WpzPCZFRnNBFa3SMZ5qVRJyVhS5exp++iQ30Kb5GjPOS1+riFIzehKciHVEv3oULL+HZZgOG4viWNRngkBSAzJyHmonk1TDAreLsPPbpjRWusAc5autJuLWjHn3DgwGxnDhRTbuYihgKn6qYwp6+mASa3kP421DbIpg60c6c13WfwwJwAM1fy049NY2yCVHekdER2LpliRmIdS7QYuHcUPSOCncdGMVqunWJ7gnDu9pYjFgTnWLYQoTClQjwKTr0Agq4uhY0H8Mye9sj/cfThID+fEUJ9QUAAr6LBUe5DhZoAiZXusLUCN4JSB6aYgFFQCmpSRFPVnAZh8OBhw8FDMq3yfa9nXGZ+OKyBibmvQLCr7y+2i1VXASOPDFqBacM6dFgcmuLOR1OKFF6XXJQumrsplfRKYRM/k7z/paDaVzbcc7W2kdOTUCfo8fxqLmofwhMvMgESbEwCFrMexmca2J0D1zMmwDPGVljZREGFKLyGAqfRUQ8/k7Slpyb3jC1FEZEuIQzjHolTdmsAqA1TbRq4vYQ9x4tMe8yPBOXd6yxwGzJZ7RqrA+nmmUilyAaUwCpgygGV7qfAv0GkSes6pu2epOJDqmSMCG4BC8uPbisDF7EUz6MeeCjivm9ZSBQnNFBBp0Mo6ohY95KeACcVPZzfV278QvShE4N4z8V5sL0YDFHqACn48NjwIjIu3bNGM1io5TAEnY1jGko8iKSAyXpcGbeqfEdgyMG2G8rgfIwuaqXR0+FspHwti+nmHMsIpbEkwpBtTo0sBVAvGlHdq+kDjijzFL4Bz7rSWOob4JrtSUI1xsjeAmMOQ9jhg8n9aYDIhD+UDh1NZTVs2v709q/aOhJjebDeoqDzeEgYmVO6TINbsVYLwc4d33r4WH4zUYcCFi2a01vGaASneYqiRlJ5AJOfBonJhCGAq7EgB0wz43iA+3z6HzW/Tp+dzAjmx4/KCiXZLPPpVAJi6ByC2swmgfN1TANXoy/NPzoQbtpj3T4IzwZpnJJWV4moRr4BISVjRSd2kC0xXL9S3ZLuS1QzE5qcSPSl+n+2/o2H7UN+SqAJE+J1PqgBVMAAkA6k9UOjiyXiIyxk8ewa4yIvBK1sBUc2BKU6yEPxfBsBkDBgSPj6rp/k7OvZn05xvqRnt79n+2jWvkv5VpSccooHIHaAR/O0AKoJRbMu4n/5Ajyj0FJFx7BkAgLnTWqoYcIbOkG5dbANERV8qADhdO7CKbPCl8pPKycylKS//3f40ek+I7lk5JVs27dA+7qwcNKIyWXdy2wAZAzRlR7XNN54RIxRkGc64IbFyDyR0LhI1eCPMOxECjRQzusDk88UI3VQYcaJeqrThg8coBcxE/B68yLbonpVT8hhxCh6Izzery8ekAASpHbi2oBhOV9cU27kJKDbAhfPiCVgA8W8/xcHJgDkya+rpmErPbjgX5pnQ6bhhmp96cJXl3g8OV2XtN0TvaBYYR0pMjyNloX6iAQClxRURvo4St5r5JiPBSPolLJFDNp8Q4Gt4JwA7BwACieNwYyVdU0Q7IIrJk4BU5rfJP6bYk9NI2WIYN+KcCjXV9KR55z89Xw3TU+Jnvtnw6HrtkH7S8aeVAGpdARkClMcGAToRxLwBD+yoRRh7w4zWogAD6mxYUwCTIExx0RlhojqT9JO6TNCR7cnAZACGl49BTiAna0eU/PwKMpvi5+CJ7vU1OYGc2MihtcljhMkOzlcro+qT0WRBAlRahWhArIBViiPYU4FbF0D8I6NCBN4hg9LYA+QextcG1AzLcdwIlI5aaeJz+OPLTuyg6iAdOVqLIltwvrJhs/aBwZcGn9iRn9zfjEvynkl+GoAqJAAuUjIevUBSyMfP8C5KbQDuGzgkNcUtxxXQR4sZiERBDDqiHfWAyFlj60uNmfEhxzpz3nNXgzbs9FH/VpqsP6a2Y1oA1YJQs6BSdFONSKZJX+sCjKFKjug6ZFCSmTAnYDecS5Wim//I9viwUN8whmRpYWT73qJsyviJNVY/EXllw2Zt5xkYGtxaVlQOt5JlMFJ+WoByugC0IASn46XL5wOEW/KpCoD4Oq5ihLSqmtYJ1aOU4dwEXoswBmDSSRdkbWF0pNlz8nlftdK77ZYV2rBzT55emqpKnwCV/IW3gAgRZfCJejrAWi+OUtfKABWg0C+kiLJbe2VKYaiMm8ArVoj+RD0YMGzgcAwMDW5FFkS3h9hTco7mBQm8NDy6XjvXHBga3Fo5qFphQPe/J0C5tuXbR2l3sg29h3cFvFpJaRCHjb2j2+nQmmpmid+ZyJXj6mnCeJCe85XpWZl7bn57+xHbUqoZXen5faN9HeaPG0w5OVVupeOmAdAkrMm20ACOamw+L7rFkeYasGdBv1fNKWmOCcWa0VVQypbck6l6qBw4HMMGDc8KqtZavtA1U5l26SRPnXuWNhgeVVZHKkurBaCkC1CVLdX5p9JWTNQzLo6sJK4dEGPZmPCXjBxTrkBtT5QqQu654PRk9zfGzczKazuO1NDuNaS/smGzdl8zEMjpnDp+ZglPAH4BCs5PrnuBaKC2gSIkCfFuDdEQbmFYl3tUNllTvlKsSQNRqhi+sglgMsRX7qeNPKddV3+2svnt7T2+arcZ0k2LoAknnHmwuG846U4HoDLQrEiCvNKLIwrQVJqyW1gQ8Qn3tFA9Uflj6jwzeSF6P+PuJtZMDuXnFWQM0J5mT68h/VdLG7SLoPy8gvavnzg58drJlMh7nNYA5d1Mbg/1MDFNLirqKfaEpCrYSTgCmhBVuBIKhVWAzcTCSXrafVTdFXTP02QNbsXn5wVx/rjL+pgL5S26wxXZEuNLYDftwD1L9RvuU0+9rE9+XlABI6AfWbiLJ0BVtpRGRMs/GNyg7CXcSXAqivKViygbh+Fe55b11T/9IWN9hYqMMHJobUHloOqMFkcd7Z1Yu6ZnFkb1l07Sbrzv6+jEd+f8Uhu3alB15MSK2mRkBViQ6ojTEX31QpKCF5mQDURdvdMPyMxnzqpHkDTh4VkxLdaUrlbAlHJ68devKskJ5HYZi+YhPcWe0y7Ts+Ztt6zQ/ngtN5DbNWPSVSXJekz4kwA1sqWP4T2ZFr04SvtPR4YsyZx64PG9zZNVpT9I9ya3+Kd56qDLn8aDIT68f3PCt7sNJjzF5gtrfqW8YqD27ObaNa8ZO8T0r83udg93CB0XqfbyBGjy6g1QW/LQXmU7luIeNo7HJcDnhvu0q8loqsTZYk3XZargmoragqoMh3ebL6z5Ed0X4pp3RXDjgnu18Y4vjQ/n7jght1PyKgHUCyheBOBFHkYdmcSSGEhlnEo/QBaEzJ7GV0rIdrJMF9qONcU867dG+OslGQ7vDavWYV+WXrpQGCogF0L7Ojpx3ZxfajfbcwO5XZdPurok1aap2jGzo75zM14rm+zpITIG3DLwYA54WuOYjklXxbhdvnwX1K4DSUlIyvnHBTHrzOvyfZgQpKO9E89kaWF0zpSvkguh225ZYXyxw+yz5ubn58XPEZsAKruzgSvf7JloNO0IaSHU62iSVxN7GYXLiJxRM6NmiTUZrV81qBpfPzH9zXnTOUo/Qn0qu+HR9cZ55qRRk9uPlx9REgBVOrEMULlSZWq0YU+dWxOsBy+MQ7vybN0iTSV105CuLYeuoGmwph9mOGfs1FBZcXla88/mnf/EKxsyO0o3fmKN8kRoy6YduHG+fp45uLg8cu5XpoZ4YOkASpadqGsagLofgad0eX0mNBJxlTOr8ZY7nJtGwJgbzoSQKYJVtWYMGeUrLhPWtE0Pibxfcfb8kmCaT48yZU+ZNZt3RTCz/jatfm5ObtfVkxeUUMynBagHZmyaXMueUO+1f0xsVz/sx2B4eawMRkubNPOBHtIh3cs2MmZNopKB+PbSFWfPS+u77C+/uDlt9qwZXSlsH3ktgADgirO5eWbCj9y/1gBUDufd6bCn9TCliSq0v7FA8sEPJl1NmVQi0b2HtJN2lzazpv0CgKGseCjOPfmitFbv6W4rzZG2j25ccK9xAfRvp1zU9aXSag+2FK+CSwag4aoIEde9F//ohx+2bakybaps8X1OTUZMRikw2kUUb/kCKrY0zEfZMKUFgBz6vl5zdv6oYbW+P7KVzqZ8ecVA1F+S2j66ccF9eMZwXnTMsNropBPPzqfIRQtQr85pYFNypJF0GXSBcnuKgAOIVbuHMLj7nEYVMXP+h3imBbIJVFSYCahyPNu6+Ob4y8NFfcO+Aep37snPNR/6/VPGlXlx33B0Vt13wiZweQFUW5FWRKQyr0nNq5Jl4Ir51Ivnd4j4uaKncLmwZlWLAopgpBVNQ4ppwZCfF8S8838c9rtAali1zpo9edZseHQ9+Z10V3JzcrsWXnBT2M2gHnxm0bInoWiDMb4NFHb0yQwCWA0FI8EpU7w+x2IPSxeMVM/ySt/Eon6YmbE4QK+aPC/k960htuzpsuYrGzYbt4xyAjmxeectyg/mBWF8+mPt1g9D6YJVxxHGkdGCWZPxuPRTR+aYdDXbE3R8saoUT96f09lLF4y6fUBZBhcPxRVnX+/ra3A27Omy5pZNO3Cd4QgcAMycdIUzZMBQ+umPfPXBqDZgUb0sgaCpfJVwbNhOLI948MM7roJubRxOwdirqDhaf0Z7E55WrCvpfrmsGvUTZmSVPeffUI8tm3ZgZv1txi2jiydeHjupsrbAD/tRooJVjW8CqycxGPS88sWzo42RgL7HEX3JN6v63DOzyoXkp+mxvEO790fIqcMnBscNn2C9FG9YtU6771leMRDjJ9Z4AnN89YTIaSMmii/fAoxzZZObFxscmIZ2SllmRX4E9NOmXs3hvSCSMmSTojZxIkClf316vod0U3YNDTttwuUlYyrtt5h07HnFNVM8N9lPqqyNXvq1+K9FydW4x5USq+Hbivo8yEVj20QepK6md+VMHL1oMUv4i1fuZxJKmKrj7kkFBB3pTRBS/ACfBndVeifPINqwVDySebRhKTd/f1LVycHWvbuje9pbPOehzTsj6OjoRGSPuOD/4P3d+PD9j7XxhpdVR66ePHeAnA9XxM4oZVhTDiEseVWV/LKlL/+EuJ91d8xqWl2aOd2yWFKPZ282MIK9MIPLZJN56uvKOX3CzHCx5R4o9aTH9I2gcL9w9MqzrymhHoDoj77pyyLrkmFZ9vMKpNnRXtf8bD3LYsxfOr3TIoysaMNwx7NNMC+I70+9KVzcz/8mvUnC/cLRGy68KVzA/dRCTV+8Upm1qhrL+ksHpBT7mpOyRxUDdZ7T0oQVA3KVmA7Ys93TrfIgKQXzgvjBBdkDaLhfOPqji+LANGbOz/BtxZbUnUEyAHW6ZmUd8uCHrXU/w7hWx7J0nmBLk2GNLJq4yRZAw/3C0RtdYFqwJV1F3tOUbIsNg5JtIXcw/mrR/p6rdUrsKsFfVRmHCx8mM2lIE8sU5AUxd8qCcFHf4rQOKhccV9D+44t+Eg7mFSA5e5QB6sGeVJjfaYv/odzPUJzd7pE8lWSXuD/pqZ6cbbGdn4X7DcANF/6kxC+D5gRyY/PPWxAKHse/q51Gl4lQerz+j2CD2SSlvPHjSCWs1dc0VrbyYdsRdfaCeUHcMPWmcG6O/S85b5h6Q3DogKEKO5LDt6n8ac47tfYMfulKNm35HtYzTjyDybSl2awYNplY9eLD0UOHD1n/knNN05NRGYD6CccxKrqsZlgEU/S05pyZJnq0rWUiy5+7P7pxW1PYWzMlTduawr//2+/1U4E059I9KZmmkI0c9hg4e5O4Fb38ufujb273B0xXmj5qCt//rArQY6fbHXvSY+C0eWT1WREHQOPbz3alC0xXmrY1hZ99a60wVz1W6+lYyNeRZ860Su0dqScr8+PoLjzx6p/TflsIL39+5c/5uz7ZJXpaZN4xuI6qaLKSjRz6BqftQ/wjbSvzSHoTj6z/b8/PxxSGCjB/UT0KQ94fuvrv5x9qdZRUMsu2k0Fkq6g91B9MZgM2Sn500hFH68iiXdeP8DQl+fLWF2Mtez82fj6mMFSAhxt+inmL6vFww089Abq77ePSDe/9Peamayo/FZYRiDOIm037NnoBILNel2kGejZNnzkg1Ne/02j84KsLzJGjhgEARo4aZgXQxk0Juxowkh3LaDFzfTjH1IRBHNZtQWqn5q+YjuZe8DOZNITZNnQKGPG7tn2fwIs1l9x9bRKYrowcNQxL7r7WFA272z4uje77RASjnCkTUxrCjKODQ/gZhdai2suRdW3mo4ZMkHNOY6a5StHqcTWuZQITRViKdVQTcA1hzW3NRrOTzzsF50yhvyF0zpRTUO/xpYxd0WYhe7or73AB4LfD0Xd2om07nVeGoHRFAWdPDB3p4tB/A/j3U8I4pfd3v7vdEMUTfKZ3vgPA1o/f3Z6sGw1rapxiWJojSjphHtn0NOcHL9rVuqcRrkb8gE7LuDojpkpKc/HgmMKSV+9SeX0fXffOdyUteaiVRxy551gsjNLunJb6ZLgnoL3rlC83DU638D5gbjXMm73sEvKtqR8Gkxpp0oHXZ69t3kanANPHVbBD2JPDbNvBN1ANoFTS9qHruc9pBJ1G3zOQmz+59mmmIGz6CKMUbdjDvX558IhKg7rxs3+A99vohg8+IWlfBy6HqyvRTesLcQ13FOv5IRedv9yeNqLTNYBT7NLew7yo6zeDUorZGZZ8DO0Uew4pHmpIMf4DthsX3Kd8yKB5VwS/WtpgfIscAJSHy1P15NDDux9Ryuu3wgglr3bgp0GkSQ+mFMopNUKu49ifBXQcGM8UUllwuMNhXPRUDskASUUKF6KZwiRft6yG5IT4xf3CKOpbHNm7v0375dSGVeuwds2rqBkVJ8GOjk7jOzddKepbHCnuN6DETVRpcEdseEDfoYzDvKRr0uEDtDblDiTH9zN8e0iukCizBJ0DOF7nMiWUyKAhAeIFUiOsaBtGIEpgpdxnnzSl72MbVhqT7Gjv9Jx/yvK/xp7XlwRl4kYHTD7vfBw9a/ob0n0B1WhU1BVAaREHoLaSHMmQSRI1wutr42l6HLVvZxrSqDCFJYhAW/aR3eOGTwym+7shnRT1LY6cWj0xSA6PBDCpujOJsT6s7XmkZAnGVHtpUK6L55jmnE5KyVPkBoYhH0SN6eKZAC+EyQpEfjKRb9ddU5ITyMnKF7JyAjmdV551bXKaIHRsoU5ShVDA5pc1KRu6DPpgUb4TKexoTERUIVkVlqeSyIR1itzVZUZfYNUpJitGZRPP6Bmy55DwUMw4fQ78vr+Tkm+edikbHB6qgNLhWofPpy0wIetJV0WBc9uAUQYlGceCDWhWBcmCATM7qvTGD/s2vVCIq/kjUqMZkTZLZkLXSNqrB0BHD6stuP68RWkP8cG8gvbvnrsA46vjb5NzASmDkmZROk+8pMOaeuB6PIKwpmETGE0JxIV9/9IWhwH2L+OSr9LLuNKzodEBhEWaG5b8hbQUpnMn/ZI7DUxycxUi+ckv1oodiKHx7WfaX9j8t7zD3YetXjZ76vAJkfO/Wl8SlN/yAUABgiO2mwmY+g5lHiG27dkKABg2sFrECjc68W4xLG6nm/PrdhKjo6vPX51Et6PChKuTtNmd8BPAqQNNgAoTrvo30rlffnXfVGtlg7vqASgCVAWgl5sGKPUaQkovdiCGl997oe2dXW9+uqe9tV/XgVixq5ufF2wbFCr7dFTFmH6njTi9WASlfj9QO4r4AiaXBmfz9Q82xJ5/e83+jk5xW6x8QNXOM0+6oGLYwGohd8qUgh8xBWA5HAh1Vxqc3YJb1TGDEzTwVLDSwBKvzON1ionPyUkMnC32pN3pAVT25237FeP+IzG08/4yeOIXkTVjB2JY/uw9kda9zdq9WgAYObQ2+s2JV4YpYLuAce3KjGdixO6EsW4q3MNGQO6x+qriKkBOiPvzFEdzdW8JlqBN0JWoRNTYF7JAsJCOrXh/men4eaQjV0ziT9GBaC+bwHQA/G7NkqgXMAFgy66mcMOL/yfqRqTty38OVUSBYZFgTTXTenHjB4QGsYtLWEvl3phZKQPCvQZUVgCko5INLbrVBYgOCJQ/H0ZlyVR+WYe3TaVLdRgvYK7d+Hh7+/6o9S9G3921Mdz04Qb9joQOZD7B56o40n0K0HFHQLakp2/rdDWZdVLgpSofdE80J6FnT8/64wAKyc8LiK6/if1s/0y2dHngyxm/OEpY14EYXtryXB58ynNvPn7AVJcyqVBhVuVO4kwPLMtfX3KFl0FLJSzE8jTredUBUFWiwg2A5RpX9VPBw9uTwUMBTCcmfa90k3mkgMmVcduerbDdTeCl60BnaM9e9RcAPKM5XLp8mrKekSUM4qrkJhuSxa++X3SVjJuI7CD+3N11uuHJkjCPhYMQAVBcRNLS1ZWWtmb89dVVO1vadpb0zS/cP7ZqXP8zx37jOCFOsszxQyqun7tw4m26Fe/WEV/PfLo2AJXLIbgJwFJhOmACwEet720HUOkvJ3Fp3x/FwKJyDohqh5TT8wKdFas6YllySSO61k7hz//ClLBFIktzdQAwDtuiOwEsLvyNDzfE/ucfK4MAKgCgo7MtuP6dpxHZtyd6wakzwsG8oAagiVV8ooLc8gJ6kCbrTRK5jrwwawQl5+Hw/x1C12fnkCWyr7VtuDOmOGmGYE1HcIvgoraPhHwJQwC0FRMwhgqZU3updtVO9Dh/f45iR8mOmK3UjQO8tOVvXQlgKrJ5Z1P43jVLom37o3wsaUGYSlFeKMogMK110cAAAA4ISURBVA3nWtbR2JDj8Tqp4qUcJmAGWE7abygZMqAquWdL5Z+vEyUDGQifjuMAAd3CJz3rmq4vo4n0J66Q8iaFUck0vPhA9NmNq40N074/Gv6vv/xHbHeb+OtHMWvcTNQBCVKl0zj+/+RyUOBPhaUIwmt3YUzVqcafNJukNFSu9PkUITmiW/5zOHJJuuVwwi2lAxh+GkyBVmccIDIplitt9pQBS+LbAWIHY3i48Z7Ill12L9s63H04eN+aJXj9g/jWCQ9+eV4ngFcJ14PVJMa6IkGZACanLMfh/cqKyzEwNNjzNTqyVA8Z03pcn6Amj8QhHql9FH+t27u2OHDaVK2jv01mUqwldZ6R+Ef6p4KUHijnkDPRdTCGB5+6M7pjz/uem82yPPHKyuCjLzyQfDUhXwxxP1R87OjFfl5/ShzXlg6UUIkgmV8JmG7+ppw83Rd75gRyYmeNrS/liYciCLGN5KuBNeU/ox3uVBJ1NVWKXBlK5WjcVC9UGs6rMji7e/Y244Gnfx5p77TfbJZl886m8O+eXBKJHYgpeadBqgdq8k9TNofQFzu6yE/J+qcACNWfb69hg6px/ji7D83mBHJi3zrrh8HCvmHFoKm9SNEBg69UT3GQM36U/HnB1HNycP7gwsG5+QfXvNu1A8kO+bydSw/kVX12DwD/3NuMP/ztF7GuA7GQRWmNsr9rX8Fb21+LVJWOKOgfLBTCdM/XeY00HqsD4CFI+Duynhrm5V9aXNFnYGhw50et73YeOnyQnIv3LyiKXDZpXmhgUXkyrkIkBGEABGsSRKIlIUlPdrN503c7/GEL9zuR5pNIHkfgkAKxp57BFnRpAnhr24bYM2/8yenuPuz9zkEfkhPIidVPmO3UDEt9XtoVxZ0uIjViAqRXuBumB6uDjR9uiL3b/GYkum9PNwCUDzg+t7p8bHn1kDFJfWHkTAJN3T2hF9J2R+PM4SmQs+9N3+2kAzxzuL0eTOkRtsCAtz/aEHv69T/6fvrhRybXXtQ1YeRZ+fwpJl40BGrNoI5yQ4Tx7jRZlGdmGcB8HnjQATwQVcBBchtZ05HdqYVuN+fv2uxO2IJDbMInCFX19qHDhxJ1n1JwAKbsrCcqSDbvOABj+MtLD0S3Nm/M6PXXNvJM0+r8XZ9si178tSvDDqAAjy8X4zzJ8nqILo4fJs0UmLwnBUw+IglMQPijM+wINvgM8+zruo0LonSv/HAgZFLKbKow6tMEpTIAPPHykQGmK5t3NoXvfmJxtOtALJ4PjgV4kRvG7x9piwuU9fhwPkz29wNMlfXECF75lo17zj0d2g7vZtdP393EgLHpDd0280VGDNG0Lcj+ifsDB2N45Lm7ovsyWJFnIjmB3K4rJ/8wv6y4XB0vGHkrSNeBGJ5uWh1586NX+h7uPhzMzyton3rqZX1qKmoLtCxDePEM5h2WBjCRIgfdPFPQd1RiUcCns0deBVsbc8bVLLoMDFUAUrXLo0vx569MG+4F9KQIcdTVe0csij+tW3bUgAkAjtOd2/TRS53980OHysIVfVx/m/ll14EY7n1qSXRb69YBjuP0AYBDhw/mb9rxRp+Ozr2RE8rHJBd0BD5T/mmCko/jBUzIQAIVJoGJyrfCohpgSlEkO+/mjDtxURVjqEt/4cMEtkyKB5CVOIyLmLj/pKMZq567M9Z1oFPc2zkK4jhOn/c+frvPvs69kREcoGThq6ClrRn/9dfbumIH9vendFvadhVs2/N+5ITykwpyc/oIYTwgpFvRbcGWsj0dMOPAcQQ/CGHEsK4bxh01z4oI7OrI6TyUM+7ERUUALgMJFn/saQYyMf4Rum7ghy0bO5946XeHutM4k9iT0tK2q2D7nvcjIxKA0rHnGx9siK1c97s+jtNNLDpT0r4/WrBpx+vREUNPCubnBZUWTQeUcrx0gWkGJD2cy2I3nJNx72bXTdtdxIC2dLeDksOxQcdrg1/W3bLj5djzG3t2qyhTCfUNR7915vxwUV9utpEo119eWRlp+nCDr0epOYGc2OVnzA0OG1RNhptAmbwzANMh3H6AKfo5Imi17GmwqbOXuhYzx3Fw/fSWRgBnxH8BCYnRbPY9zXoQQEjPP133+jdXRbbseMn3M/KjITmBnNiMM+YGKxOA+tfBGP70wv2R7Xu2pp3/88fNiNV+aUL8xQuuJ4c2X6BM3OiAqSxWtOESkLRhqatg14s1JT0Az9/5SGldIJGf1UQ9aH1cXz9bS0I8SccNWPva8uhnBZhA/GTTiud+haYPN8Ra9zbjvjU/zwiYAPA//1gZfOzvD0STW0k8WLgBMFl3xLCYrHMJmEK7pAnMVAIis/J/gl0ZE0qJCR8njkfmOA7mTmspYgxtgH9WNC2OqCGbn3+67oMHY/jry7+ORDs+/swAs6dlUFF5ZOaZ80vy+wRhw5SC28CWqXtH469nRVDDLx9Xz4R+hnM4QPHSlaV7mbtRPnd6y3IGzPYz9wTsgAyDvQOHYnj8hbuin8bajtpW0ZGQwlBB8gWzgPf75AEgP6+g/fK674UGJQ5k2ICSd/sGpgFMFDApPR6cKmhlXYfSeeiulaVzAP7xpYNlYJjtOIijx+IqH3wQKonTZaSOg+i+j/HXDcu6Dncf6vXAfPzZO6LlQ0uS5dyyaUdkZv1tJR3t+jcrdh3oDD209hexqeNnOycMHZvasE+IDSgBCUxwFGbU3acDzJRxFZBK7mnQLnM1kswJAHOntzSyxMKIZM8E0myHd0Cv0xp9H2tfvTd2rG0VZVtqRlfi//51cVdeXh/luNrujz+JXPvt/yyxeU33aSPPaT9jzAUhQA9K997h/QUwqfNLwAcwedskWA3zTMFPC/bn71pZWueWRf684BxPGiZE1XWEnuJIOlt3vhR7+pXfoLcD85KZdbHHnrw1RgETAAYPGVDy2JO3xiaePmq/l62XtqwN/XnDA8nn/MKwDK5+HeIejnHho9zbApNPn5hnJsWTRZNhC3k/AZy/faxsG4C7vQybEiILyfXkdz56ruulTY/2alACwFVzz++6/RdXBfv0yTWWtU+f3OBDf7qp7yUz6zxPrL+3a2P4wWfujHYdjBlBmQJfApQkYDVAdlwSsgBm0s9RsKDDC/9fCrt76crSJr68wrAOANfFV+5NDKjMZHinNuf//uby6M7WN3v1/BIAfn3/gui53xjnu5xP/eUf0e9ddbdnvJxAbtfMM3+Q755cBziguG5u9OLZ0tXV3zuCPznkc/ZsNtp525qw7Q5Qu3Rl6V6+nAo4AWDutJY6xvAcYJpbisDT6zIcPBTD3zc+GNnT5v8HaJ8lKQwVYPXTt7VXVA5K+2cj723Z1Trjwn8vNS2UXJl88mWxMVXihr1uJQ7JTd/Tq2xw99bAVPyMi6ozl64sbZTLR/40+DePlTU6wK2Cp6ZXyHMMOezAoU489dLSaG8HZs3oSjz70n/uywSYADBi5NDSJ59f0lozutJT95nX/xh8+vWVkcQgrAzhPPi0Q7/DgQdQ2hncffrATDE7L4mwWylgAhrmdMVr7xOmR5YA2j9txvrXf9t+4FDmP0A7lmX8xBo8uOrGmNf80o8cPHgodtXld3W/uH5TXy/doSXDI9847Tslx/UJkmxpHt4d7h7ae1tgCnGScR1FL3F9aGliT5MSIzgB4PrpLU0gDyOb55/v72jseuv9J9J+JcpnRS6ZWRe7/RdX9dgC7+Yf3h979OFGT/v9g0WRb5x2dUlJKPULShmIrn/qXgSmADb+XrCTHWAC2HjXytJaU5k8wTl3eksRAxoZw1j3caTpYEhk7wd4/Z1HIrF/7e3VwziQ/sLHr9gvlHJiUydeFywfMJycZwI8kBwFsFScTIDppkHobXSAOnkBJIsnOIEkQJcxhtnUo8tDh7rQEnkz9uGudR379rek/Y6ez4oUhgrwmwe/Hxk/seaIdUA/C6WJo6Z21Q4/K59mTrthXL23B6abjgaYDznAQi9gApbgdOXUEbf88V8H953G+x04+GnhoUNdxbo4vU3KKwbi4T/fLDyKPFKyr6OzbWb97cU2T5S+NHhs9NxxV4QpUMbdelZV/TMDZjI9B3fftbJU2Gg3iS9wAkB12ayLACwH0KsXOZTUjK7EY0/emtWFj185dPBw58Lrfo2n/vIPz5dJ9A+GoxdMvD7cvyBsGN5181EXjA4FMr/AbHcczLlrZWnyaKaN+AYnAFSXzSpCHKAX+o78GZWeXvj4laW3r2q791dPeI5YgUBO56knnB8Y8+Uz8wERZK7bNIzrdGQWjTtJYP6/BDA9h3FZ0gKnK9Vls+oALAZwRtpGPgNy0+KZrVd+97xjbi5tu1ACgL7Bokjd2JklZQOGA/Aa3s0HROjhXQHm8w6w+M5H6D1MG8kInK4khvqF6GUgLQwV4I5fXH1EVuTpSvOuSHTq2T8J2yyUAKC4/+DWUVWTCqsrTkt9gzMRZhrGdfcEMJ8HsGzJI/6GcEqyAk5Xqstm1QKYA+AipPmy/GNFqDOYx6q0t+9v/9a0O0I2CyVXAoGc2JABIyLVFRMqhpWOUYZxgJ5fyv6JfcztDrDacbB8ySPi4Y1MJKvg5CUB1LrEXy0+I2AtrxiIy2ef1X7FteflHc2FTzqyds1rrfcsbSj1A1JXQn0HNQ8ZWJM7dOCo0qLCcuTlBk1bTNsdoMmB0wgHjf/74ewBkpceAyclCcAWHbEEfchJX/lyvwunf214KNT30wunf+39o52fdOWFxrfKPvxgd9lbTR+2rP7TCy3p2Bgx7PTaAYUVLVVDvtoizS/33r5iUI8AkZL/DzlQO/8zap2bAAAAAElFTkSuQmCC"

DOT_DIAMETER = 4
IMG_PAD = 1
TEXT_HEIGHT = 8
SCREEN_HEIGHT = 32
SCREEN_WIDTH = 64
LOGO_WIDTH = 12
LOGO_HEIGHT = 12

CHUNK_SCROLL_ANIMATION_FRAME_LEN = 150
CHUNK_SCROLL_ANIMATION_PAUSE_FRAME = 0.75

def get_machines(app_name, api_key):
    """
      Gets the machines from the fly.io endpoint
      Errors are returned via a "machine" object for easier rendering
    """
    machines = []

    # Config Validation/Error Handling
    if not app_name:
        machines.append({"name": "Missing App Name", "state": "error"})
    if not api_key:
        machines.append({"name": "Missing API Key", "state": "error"})
    if not api_key or not app_name:
        return machines

    # Render a preview of the app
    if app_name == PREVIEW_APP_NAME and api_key == PREVIEW_API_KEY:
      return [{ "name": "Monitor your Fly.io App machines", "state": "preview" }]

    machines_url = "{}/v1/apps/{}/machines".format(FLY_API_BASE_URL, app_name)
    response = http.get(machines_url, headers = {"Authorization": "Bearer {}".format(api_key)}, ttl_seconds = 220)

    if (response.status_code != 200):
        return [{"name": "Error fetching machines", "state": "error"}]

    machines = response.json()
    if len(machines) == 0:
        return [{"name": "No machines", "state": "error"}]

    return machines

def get_status_img(machine):
    """
      Gets the status indicator based on the machine state
    """
    if machine["state"] == "started":
        status_img = render.Circle(color = "#34D399", diameter = DOT_DIAMETER)
    elif machine["state"] == "stopped" or machine["state"] == "suspended":
        status_img = render.Circle(color = "#94A3B8", diameter = DOT_DIAMETER)
    elif machine["state"] == "starting" or machine["state"] == "replacing" or machine["state"] == "suspending" or machine["state"] == "stopping":
        status_img = render.Circle(color = "#FFD700", diameter = DOT_DIAMETER)
    elif machine["state"] == "preview":
        status_img = render.Circle(color = "#0057B7", diameter = DOT_DIAMETER)
    else:
        status_img = render.Circle(color = "#FF0000", diameter = DOT_DIAMETER)

    return render.Padding(child = status_img, pad = IMG_PAD)

def render_header(app_name):
    """
      Render the header in a row with the Fly.io logo and app name, app_name scrolls left in a marquee
    """
    return render.Row(
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Image(src = base64.decode(FLY_LOGO), width = LOGO_WIDTH, height = LOGO_HEIGHT),
                pad = IMG_PAD,
            ),
            render.Marquee(child = render.Text(app_name), width = SCREEN_WIDTH - LOGO_WIDTH - IMG_PAD),
        ],
    )

def render_machine_name(machine):
    """
      Render a machine name with a horizontal marquee animation if the length is greater than the screen width
    """
    name_text = render.Text(machine["name"])
    name_len = len(machine["name"]) * 5

    # Delay based on when the chunk animation is paused, additional 30 subtracted for fine tuning
    name_delay = math.floor((100 * CHUNK_SCROLL_ANIMATION_PAUSE_FRAME)) - 30

    # Create a horizontal marquee for each machine name
    name_animation = animation.Transformation(
        child = name_text,
        duration = 100,
        delay = name_delay,
        direction = "normal",
        origin = animation.Origin(0, 0),
        height = TEXT_HEIGHT,
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(x = 0, y = 0)],
                curve = "linear",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(x = -(name_len + IMG_PAD + DOT_DIAMETER), y = 0)],
                curve = "linear",
            ),
        ],
    )

    name_available_width = SCREEN_WIDTH - DOT_DIAMETER - IMG_PAD

    return render.Row(
        cross_align = "center",
        children = [
            get_status_img(machine),
            name_text if name_len < name_available_width else name_animation,
        ],
    )

def render_body(machines):
    """
        Renders the body content for the app
        Chunks the machines into groups of two, and slides each chunk in from right to left
        Keeps paging through all chunks. If there is text overflow then that is also animated across.
    """
    available_height = SCREEN_HEIGHT - LOGO_HEIGHT - (IMG_PAD * 2)
    visible_rows = math.floor(available_height / TEXT_HEIGHT)

    animated_widgets = []

    # Create a horizontal scrolling animation for each chunk of machines
    # Chunks should be made up of at most 2 machines
    # Each chunk animates horizontally in from the right, and pauses for a moment to let any names finish scrolling in
    # and then scrolls back out to the left
    for i in range(0, len(machines), visible_rows):
        chunk = machines[i:i + visible_rows]
        chunk_rows = []

        for machine in chunk:
            chunk_rows.append(render_machine_name(machine))

        chunk_column = render.Column(children = chunk_rows)

        # Create a horizontal scrolling animation for this chunk
        animated_widgets.append(animation.Transformation(
            child = chunk_column,
            duration = CHUNK_SCROLL_ANIMATION_FRAME_LEN,
            delay = 0,
            keyframes = [
                animation.Keyframe(
                    percentage = 0,
                    transforms = [animation.Translate(y = 0, x = SCREEN_WIDTH)],
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(y = 0, x = 0)],
                ),
                animation.Keyframe(
                    percentage = 0.75,
                    transforms = [animation.Translate(y = 0, x = 0)],
                ),
                animation.Keyframe(
                    percentage = 1,
                    transforms = [animation.Translate(y = 0, x = -SCREEN_WIDTH)],
                ),
            ],
        ))

    return render.Sequence(children = animated_widgets)

def main(config):
    app_name = config.str("app_name", PREVIEW_APP_NAME)
    api_key = config.str("api_key", PREVIEW_API_KEY)

    machines = get_machines(app_name, api_key)

    return render.Root(
        child = render.Column(
            children = [
                render_header(app_name),
                render_body(machines),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "app_name",
                name = "App Name",
                desc = "The name of the Fly.io app to monitor.",
                icon = "server",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "The API key to use to authenticate with the Fly.io API.",
                icon = "key",
            ),
        ],
    )
