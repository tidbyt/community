"""
Applet: Marketstack
Summary: Track stock price
Description: Allows you to track the value of a stock that you currently own historical (week or months) or intraday price as a plot, this app include Stocks of various countries.
Author: kanroot
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

ERROR_404 = "404"
ERROR_401 = "401"
ERROR_429 = "429"
ERROR_422 = "422"
ERROR_UNKNOWN = "Unknown"

marketstack_data = """
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAEVAZADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD5kooor2z58KKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKQgGlooAYQRRT6QgGgBtFBBFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAU5elNpy9KAFooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKQgGlooAYQRRT6QgGgBtFBBFFABRRRQAUUUUAFFFFABRRRQAUUUUAFOXpTacvSgBaKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKQgGlooAYQRRT6QgUANooIIooAKKKKACiiigAooooAKcvSm05elAC0UUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRX6geG/CHhS10Cwgt/DOjRxrbx4VbKP+6Pbk+9aH/CMeGv+he0n/wAAo/8ACuP64ux3rAvuflfRX6of8Ix4a/6F7Sf/AACj/wAKP+EY8Nf9C9pP/gFH/hS+uLsH1F/zH5X0V+qH/CMeGv8AoXtJ/wDAKP8Awo/4Rjw1/wBC9pP/AIBR/wCFH1xdg+ov+Y/K+kIr9Uf+EY8Nf9C9pP8A4BR/4VzfxR8K+GH+G3ibd4d0nK6TdOpFnGCrCFiGBxkEHkEcimsWm7WE8C0r3PzQIIop9IRXYcI2iggiigAooooAKcvSm05elAC0UUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAH6t6N/yB7L/AK94/wD0EVbqpo3/ACB7L/r3j/8AQRVuvEZ762CiiigYUUUUAFc98Tv+SbeKP+wPd/8Aol66Gue+J3/JNvFH/YHu/wD0S9OO6FLZn5dUUUV7R4AUhFLRQAwgiin0hWgBtOXpTSMU5elAC0UUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAH6taGyvotiysGU20ZBByCNoq5X5WW/iHX7eBILfXNThijUKiJduqqB2AB4FP/AOEn8S/9DDq3/gbJ/jXD9Tfc9FY5fyn6oUV+V/8Awk/iX/oYdW/8DZP8a1/BfifxL/wmGi/8VDq3OoQD/j9k/wCei+9J4N9wWOT6H6c0UUVxneFc98Tv+SbeKP8AsD3f/ol66Gue+J3/ACTbxR/2B7v/ANEvTjuhS2Z+XVFFFe0eAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQBo2mg67d26XFroupTwuMpJFauyt9CBg1L/wAIx4l/6F7Vv/AKT/Cv0s+FkaQ/DHwrFEoRE0a0CqOgHkpXSVwvGNPY9BYFNXuflf8A8Ix4l/6F7Vv/AACk/wAKP+EY8S/9C9q3/gFJ/hX6oUUfXH2H9RX8x+V//CMeJf8AoXtW/wDAKT/Cj/hGPEv/AEL2rf8AgFJ/hX6oUUfXH2D6iv5j8r/+EY8S/wDQvat/4BSf4UHwz4kAyfD+rAD/AKc5P8K/VCij64+wfUV/MfkzWt4L/wCRx0X/ALCEH/oxaya1vBf/ACOOi/8AYQg/9GLXa9jz1ufqhRRRXinvhXPfE7/km3ij/sD3f/ol66Gue+J3/JNvFH/YHu//AES9OO6FLZn5dUUUV7R4AUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAH6i/DH/km3hf/ALA9p/6JSuhrnvhj/wAk28L/APYHtP8A0SldDXiy3Z70fhQUUUUigooooAKKKKAPyZrW8F/8jjov/YQg/wDRi1k1reC/+Rx0X/sIQf8Aoxa9p7HgLc/VCiiivFPfCue+J3/JNvFH/YHu/wD0S9dDXPfE7/km3ij/ALA93/6JenHdClsz8uqKKK9o8AKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9Ifhb498Ev8NPDO7xbocLrpNsjxy6hEjxusSqyspbIIIII9q6T/AITrwR/0OPh3/wAGcP8A8VX5dUVyPCJvc7ljWlax+ov/AAnXgj/ocfDv/gzh/wDiqF8c+CWYKvjDw8STgAalDz/49X5dUUvqa7h9efY/WYEEZHIorJ8GEnwfopJyf7Pg/wDRa1rVwM9FahRRRQM/JmtbwX/yOOi/9hCD/wBGLWTWt4L/AORx0X/sIQf+jFr2nseAtz9UKKKK8U98K574nf8AJNvFH/YHu/8A0S9dDXPfE7/km3ij/sD3f/ol6cd0KWzPy6ooor2jwAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAOw8M/C/4g+JtHi1jQvCepX+nzFhHcRINjlSVOCTzggj6g1p/8KQ+LH/Qi6t/3wv+NfZX7IH/ACbr4X/7e/8A0rmr1muGeKlGTVj0YYOMop33Pzc/4Uh8WP8AoRdW/wC+F/xo/wCFIfFj/oRdW/74X/Gv0joqfrkuxX1GHdn5uf8ACkPix/0Iurf98L/jR/wpD4sf9CLq3/fC/wCNfpHRR9cl2D6jDuz83P8AhSHxY/6EXVv++F/xoPwR+LAGf+EF1f8A74X/ABr9I6KPrkuwfUYd2fk7d289pdS2t1DJBPC5jlikUqyMDgqQeQQRjFR11vxo/wCSxeNf+xgv/wD0oeuSrvTurnmyVnY/VDwX/wAidov/AGD4P/Ra1rVk+C/+RO0X/sHwf+i1rWrxnue8tgooopDPyZrW8F/8jjov/YQg/wDRi1k1reC/+Rx0X/sIQf8Aoxa9p7HgLc/VCiiivFPfCue+J3/JNvFH/YHu/wD0S9dDXPfE7/km3ij/ALA93/6JenHdClsz8uqKKK9o8AKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9Df2QP+TdfC/wD29/8ApXNXrNeTfsgf8m6+F/8At7/9K5q9Zrx6vxv1Pco/w4+iCiiioNAooooAKKKKAPzG+NH/ACWLxr/2MF//AOlD1yVdb8aP+SxeNf8AsYL/AP8ASh65KvZh8KPBn8TP1Q8F/wDInaL/ANg+D/0Wta1ZPgv/AJE7Rf8AsHwf+i1rWrx3ue6tgooopDPyZrW8F/8AI46L/wBhCD/0YtZTKyMVZSrA4IIwQa1fBf8AyOOi/wDYQg/9GLXtPY8Bbn6oUUUV4p74Vz3xO/5Jt4o/7A93/wCiXroa574nf8k28Uf9ge7/APRL047oUtmfl1RRRXtHgBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAfob+yB/ybr4X/wC3v/0rmr1mvJv2QP8Ak3Xwv/29/wDpXNXrNePV+N+p7lH+HH0QUUUVBoFFFFABRRRQB+Y3xo/5LF41/wCxgv8A/wBKHrkq6340f8li8a/9jBf/APpQ9clXsw+FHgz+Jn6oeC/+RO0X/sHwf+i1rWrJ8F/8idov/YPg/wDRa1rV473PdWwUUUUhn5Sa1/yGL3/r4k/9CNW/Bf8AyOOi/wDYQg/9GLVTWv8AkMXv/XxJ/wChGrfgv/kcdF/7CEH/AKMWvaex4C3P1QooorxT3wrnvid/yTbxR/2B7v8A9EvXQ1z3xO/5Jt4o/wCwPd/+iXpx3QpbM/LqiiivaPACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA+5P2OviB4Rb4TaN4Rn1yytdaspLhGtLiURvJvneRSm7G7iQDAyeDX0FX5M13fgT4vfEXwUY00TxPefZU4Fnct58GPQI+Qv1XB9646mF5m3FndSxnKlGSP0ror5W8Bfte2Uojt/HHhuS2fGGu9LbehPvE5yo+jN9K988D/ErwL41Rf+Eb8TWF7Mwz9mL+XOPrE+H/HGK5J0pw3R2wrQnszraKKKzNQooooA/Mb40f8AJYvGv/YwX/8A6UPXJV1vxo/5LF41/wCxgv8A/wBKHrkq9mHwo8GfxM/VDwX/AMidov8A2D4P/Ra1rVxnwd8X+G/FfgfSZNB1e1vHgsYEuIEkHmwMEAKyJ1U5BHPB7ZFdnXjyVnqe5FppNBRRRSKPyk1r/kMXv/XxJ/6Eat+C/wDkcdF/7CEH/oxaqa1/yGL3/r4k/wDQjUnhy7isPEOm30+7ybe7ilk2jJ2q4Jx+Ar2uh4C3P1XoqhoGs6Tr+lxapompWuo2Uwyk9vKHQ+2R0I7jqKv14p7+4Vz3xO/5Jt4o/wCwPd/+iXroa574nf8AJNvFH/YHu/8A0S9OO6FLZn5dUUUV7R4AUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUqsyMGVirA5BBwQaSigD0/wL8e/if4REcNr4ik1KzTpa6mv2hMem4neB7BhXvvgX9rrw7emO38YaBd6TIcBrqzb7RD9Spw6j2G818Z0VlOhCW6NoYipDZn6ieDfHXg/xjB5vhnxFp+pnbuaOKUeag9WjOHX8QK6Kvydtp57W4S4tppIJo23JJGxVlPqCOQa9Z8B/tF/FDwrshk1hddtFx+51VTMce0mQ/wCbEe1cs8I/ss64Y1P4kcf8aP8AksXjX/sYL/8A9KHrkq0/FusS+IvFWr+IJ4Uhl1O+mvHjQkqjSOXKjPYFsVmV3RVkkefJ3bZa0rUdQ0m/iv8AS765sbuI5jnt5WjkQ+zKQRX0F8L/ANqzxXonl2PjSzXxFZDA+0pthukHvgbZOOxAJ7tXznRUzpxn8SKhUlB3iz9K/hv8XfAPj9I00DXYRfMuTYXX7m5X1Gw/ex6oWHvXd1+TSMyOroxVlOVYHBB9a9n+Gn7SfxD8IIlpqFyniTTlAAh1BiZUH+zMPm9Pvbh6AVyVMI94s7qeNW00eRa1/wAhi9/6+JP/AEI1UqfUrp77Ubm9kVVe4meVlUYALEkge3NQV3HnM2vCHizxL4Q1Iaj4Z1q90u5yNxgkwsgHQOv3XHswIr6S+Gf7XFzF5Vj8QdFFwvA/tDTgFf6vETg+5Uj2WvlOis50oz3RpTrTp/Cz9RPA/jfwn42sPtvhfXbPUowAXSN8SR5/vocMv4gUvxO/5Jt4o/7A93/6JevzE0nUtQ0nUItQ0q+ubG8hOYp7aVo5EPqGUgivW9O/aQ+Iy+F9T8Pa1dWutW19YTWYmuIgs8O+MoGDLgMRnPzA5x1rllhGneLO2ONTVpI8aoooruPOCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA//9k=
"""
MARKETSTACK_ICON_IMAGE = base64.decode(marketstack_data)
MARKETSTACK_PRICE_URL = "http://api.marketstack.com/v1/"
MARKETSTACK_PRICE_URL_KEY = "access_key="

def main(config):
    api_token = config.get("api_token")
    company_name = config.get("company_name")
    select_period = config.get("select_period")
    missing_parameter = check_inputs(api_token, company_name)
    color_profit = get_preferences(config)
    query_timer = config.get("time_query")
    type_query_to_make = config.get("type_query_option")
    if missing_parameter:
        data_raw = None
        return error_view(missing_parameter)
    data_raw = cache.get("marketstack_rate")
    if data_raw != None:
        data_raw = json.decode(data_raw)
    else:
        data_raw = make_marketstack_request(type_query_to_make, api_token, company_name)
        is_error = is_response_error(data_raw)
        cache.set("marketstack_rate", json.encode(data_raw), ttl_seconds = int(query_timer))
        if is_error == True:
            return error_view(data_raw)
    return get_data_select_period(data_raw, color_profit, select_period, company_name)

def check_inputs(api_token, company_name):
    missing_parameter = None
    if not api_token:
        missing_parameter = "Missing API Token"
        return missing_parameter
    elif not company_name:
        missing_parameter = "Missing Company Name"
        return missing_parameter
    return missing_parameter

def error_view(message):
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = MARKETSTACK_ICON_IMAGE, width = 27, height = 24),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            font = "tb-8",
                            align = "center",
                            content = message.upper(),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_percentage_with_two_decimals(last_price, previus_last_price):
    minus = last_price - previus_last_price
    difference_percentage = (minus / previus_last_price) * 100
    v = str(int(math.round(difference_percentage * 100)))
    v = v[0:-2] + "." + v[-2:]
    return v

def get_color_percentage_change(price):
    if float(price) > 0:
        return "#00ff00"
    else:
        return "#ff0000"

def get_data_select_period(request, colors, select_period, company_name):
    list_data = []
    i = 0
    for entry in request["data"]:
        i += 1
        list_data.append(entry["close"])

    data_filter = list_data[0:int(select_period)]
    min_period = data_filter[int(select_period) - 1]

    data_reconvert = []
    for entry in data_filter:
        value = entry - min_period
        data_reconvert.append(value)

    min_yield = min(data_reconvert)
    max_yield = max(data_reconvert)
    last_price = list_data[0]
    int_select_period = int(select_period) - 1
    previus_last_price = list_data[int_select_period]

    select_period_data = []
    k = 0
    for i in range(int(select_period), 0, -1):
        object = (i, data_reconvert[k])
        select_period_data.append(object)
        k += 1

    price_change = get_percentage_with_two_decimals(last_price, previus_last_price)
    color_price_change = get_color_percentage_change(price_change)
    pattern_company_name = r"[^.]*"
    company_name = re.findall(pattern_company_name, company_name)
    company_name = company_name[0]

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Column(
                            cross_align = "space_around",
                            children = [
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    content = company_name,
                                ),
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    content = "$" + str(last_price),
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = False,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    content = str(price_change) + "%",
                                    color = color_price_change,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Plot(
                    data = select_period_data,
                    width = 64,
                    height = 22,
                    chart_type = "line",
                    color = colors[0],
                    fill_color = colors[0],
                    color_inverted = colors[1],
                    fill_color_inverted = colors[1],
                    y_lim = (min_yield, max_yield),
                    fill = True,
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(display = "White", value = "#ffffff"),
        schema.Option(display = "Silver", value = "#c0c0c0"),
        schema.Option(display = "Gray", value = "#808080"),
        schema.Option(display = "Red", value = "#ff0000"),
        schema.Option(display = "Maroon", value = "#800000"),
        schema.Option(display = "Yellow", value = "#ffff00"),
        schema.Option(display = "Olive", value = "#808000"),
        schema.Option(display = "Lime", value = "#00ff00"),
        schema.Option(display = "Green", value = "#008000"),
        schema.Option(display = "Aqua", value = "#00ffff"),
        schema.Option(display = "Teal", value = "#008080"),
        schema.Option(display = "Blue", value = "#0000ff"),
        schema.Option(display = "Navy", value = "#000080"),
        schema.Option(display = "Fuchsia", value = "#ff00ff"),
        schema.Option(display = "Purple", value = "#800080"),
    ]
    days = [
        schema.Option(
            display = "7",
            value = "7",
        ),
        schema.Option(
            display = "15",
            value = "15",
        ),
        schema.Option(
            display = "30",
            value = "30",
        ),
        schema.Option(
            display = "45",
            value = "45",
        ),
        schema.Option(
            display = "60",
            value = "60",
        ),
        schema.Option(
            display = "100",
            value = "100",
        ),
    ]
    type_query = [
        schema.Option(
            display = "Intraday (short as one minute, US ONLY)",
            value = "intraday?",
        ),
        schema.Option(
            display = "Historical Data (end-of-day price)",
            value = "eod?",
        ),
    ]
    query = [
        schema.Option(
            display = "1 minute",
            value = "60",
        ),
        schema.Option(
            display = "15 minutes",
            value = "900",
        ),
        schema.Option(
            display = "30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "2 hours",
            value = "3600",
        ),
        schema.Option(
            display = "1 day",
            value = "86400",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "company_name",
                name = "Company Name",
                desc = "The company name to display",
                icon = "sackDollar",
            ),
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "The API Token for your MarketStack",
                icon = "key",
            ),
            schema.Dropdown(
                id = "select_period",
                name = "Time lapse",
                desc = "Period of time to show",
                icon = "calendarDays",
                default = days[0].value,
                options = days,
            ),
            schema.Dropdown(
                id = "time_query",
                name = "Time to refresh ",
                desc = "Time to refresh data",
                icon = "clock",
                default = query[5].value,
                options = query,
            ),
            schema.Dropdown(
                id = "type_query_option",
                name = "Type data",
                desc = "Query to intraday or historical ",
                icon = "clipboardQuestion",
                default = type_query[1].value,
                options = type_query,
            ),
            schema.Dropdown(
                id = "color_profit",
                name = "Profit's Color",
                desc = "The color of graph to be displayed profits.",
                icon = "brush",
                default = options[7].value,
                options = options,
            ),
            schema.Dropdown(
                id = "color_looses",
                name = "Loss color",
                desc = "The color of the loss graph",
                icon = "brush",
                default = options[3].value,
                options = options,
            ),
        ],
    )

def get_preferences(config):
    colors = []
    color_regex = r"#[a-zA-Z0-9]{6}"
    chart_color_profit = re.findall(color_regex, config.get("color_profit") or "")
    chart_color_loss = re.findall(color_regex, config.get("color_looses") or "")
    chart_color_profit = chart_color_profit[0] if chart_color_profit else "#008000"
    chart_color_loss = chart_color_loss[0] if chart_color_loss else "#ff0000"
    colors.append(chart_color_profit)
    colors.append(chart_color_loss)
    return colors

def make_marketstack_request(type_query, api_token, company):
    url = MARKETSTACK_PRICE_URL + type_query + MARKETSTACK_PRICE_URL_KEY + api_token + "&symbols=" + company
    response = http.get(url)
    if response.status_code == 404:
        return ERROR_404
    elif response.status_code == 429:
        return ERROR_429
    elif response.status_code == 401:
        return ERROR_401
    elif response.status_code == 422:
        return ERROR_422
    elif response.status_code != 200:
        return ERROR_UNKNOWN

    return response.json()

def is_response_error(response):
    if (
        response == ERROR_404 or
        response == ERROR_429 or
        response == ERROR_401 or
        response == ERROR_422 or
        response == ERROR_UNKNOWN
    ):
        return True
    else:
        return False
