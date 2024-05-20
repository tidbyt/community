load("icons/cloudy.png", _cloudy = "file")
load("icons/foggy.png", _foggy = "file")
load("icons/moony.png", _moony = "file")
load("icons/moonyish.png", _moonyish = "file")
load("icons/rainy.png", _rainy = "file")
load("icons/sleety.png", _sleety = "file")
load("icons/snowy.png", _snowy = "file")
load("icons/sunny.png", _sunny = "file")
load("icons/sunnyish.png", _sunnyish = "file")
load("icons/thundery.png", _thundery = "file")
load("icons/windy.png", _windy = "file")
load("sample_forecast_response.json", _sample_forecast_response = "file")
load("sample_station_response.json", _sample_station_response = "file")

resources = struct(
    # sample responses from Tempest API
    sample_station_response = _sample_station_response.readall(),
    sample_forecast_response = _sample_forecast_response.readall(),

    # weather icons, keyed by condition name from the Tempest API
    icons = {
        "clear-day": _sunny.readall(),
        "clear-night": _moony.readall(),
        "cloudy": _cloudy.readall(),
        "foggy": _foggy.readall(),
        "partly-cloudy-day": _sunnyish.readall(),
        "partly-cloudy-night": _moonyish.readall(),
        "possibly-rainy-day": _rainy.readall(),
        "possibly-rainy-night": _rainy.readall(),
        "rainy": _rainy.readall(),
        "sleet": _sleety.readall(),
        "snow": _snowy.readall(),
        "thunderstorm": _thundery.readall(),
        "windy": _windy.readall(),
    },
)
