"""
Applet: CPI Tracker
Summary: Track monthly CPI trends
Description: Track monthly CPI trends as well as the current CPI value today!
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

TIME_OUT_IN_SECONDS = 172800  # No need to get data more often than 2 days
ENCRYPTED_API_KEY = "AV6+xWcEltrtzaNkmlmzZpCnWcHPJjQCRZLSA7WUQuqvC3M+rirU8QioecfwYEsfm/1zAPE3BPDtuZEhdWIT+XNwTSBVZXN2oLRL7nbCfF5fNg3WSqGbVKi0Mg223QdZmycG/bE0fKls/QNY43mekfJhmVyzbrpC4bMEvptkWXnxAONJeA4="
SAMPLE_DATA = """
{"Results":{"series":[{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"319.799","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"319.082","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"317.671","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"315.605","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"315.493","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"315.664","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"315.301","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"314.796","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"314.540","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"314.175","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"314.069","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"313.548","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"312.332","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"310.326","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"308.417","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"306.746","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"307.051","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"307.671","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"307.789","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"307.026","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"305.691","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"305.109","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"304.127","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"303.363","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"301.836","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"300.840","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"299.170","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"296.797","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"297.711","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"298.012","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"296.808","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"296.171","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"296.276","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"296.311","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"292.296","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"289.109","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"287.504","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"283.716","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"281.148","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"278.802","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"277.948","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"276.589","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"274.310","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"273.567","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"273.003","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"271.696","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"269.195","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"267.054","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"264.877","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"263.014","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"261.582","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"260.474","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"260.229","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"260.388","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"260.280","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"259.918","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"259.101","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"257.797","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"256.394","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"256.389","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"258.115","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"258.678","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"257.971","year":"2020"}],"seriesID":"CUUR0000SA0"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"275.734","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"275.867","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"273.045","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"267.963","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"268.213","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"272.807","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"275.740","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"282.614","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"287.868","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"286.675","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"290.139","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"290.760","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"285.002","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"276.331","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"270.420","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"269.375","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"277.029","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"286.754","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"296.004","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"294.328","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"284.828","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"283.854","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"279.816","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"283.352","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"279.084","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"281.673","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"283.330","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"274.937","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"292.953","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"300.359","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"297.343","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"305.372","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"325.407","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"340.917","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"316.761","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"298.469","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"298.246","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"267.771","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"260.653","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"256.207","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"259.100","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"255.338","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"248.228","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"246.639","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"244.800","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"240.720","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"235.339","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"229.116","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"225.861","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"213.277","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"205.273","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"198.155","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"194.388","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"196.458","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"198.858","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"197.362","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"197.665","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"193.379","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"183.076","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"183.081","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"199.573","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"208.354","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"213.043","year":"2020"}],"seriesID":"CUUR0000SA0E"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"223.871","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"223.591","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"222.490","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"220.949","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"221.466","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"222.483","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"223.014","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"223.363","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"223.899","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"223.956","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"224.786","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"224.926","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"223.766","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"222.289","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"220.683","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"220.324","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"222.008","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"224.696","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"225.866","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"226.161","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"224.698","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"224.764","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"224.515","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"224.216","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"222.457","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"221.731","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"220.468","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"218.607","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"222.112","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"223.747","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"222.678","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"223.891","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"226.110","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"227.423","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"223.076","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"219.647","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"219.057","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"213.960","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"210.918","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"208.602","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"207.708","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"206.134","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"203.313","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"202.496","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"201.615","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"200.209","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"197.117","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"194.456","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"191.877","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"189.402","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"187.790","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"186.063","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"185.594","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"186.502","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"186.434","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"185.830","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"184.590","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"183.619","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"182.064","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"182.141","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"184.364","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"185.331","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"185.055","year":"2020"}],"seriesID":"CUUR0000SAC"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"122.428","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"122.327","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"122.260","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"121.747","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"122.061","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"122.180","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"122.204","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"122.201","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"122.734","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"123.098","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"123.167","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"123.372","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"123.613","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"123.847","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"123.752","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"124.061","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"124.570","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"125.259","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"125.849","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"127.556","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"128.029","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"128.392","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"128.059","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"127.406","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"126.227","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"125.825","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"125.749","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"125.624","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"126.596","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"127.903","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"128.688","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"130.123","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"129.856","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"129.464","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"128.122","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"127.622","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"127.471","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"128.109","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"127.345","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"125.747","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"123.678","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"122.097","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"120.107","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"120.666","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"120.310","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"119.434","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"115.051","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"111.983","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"108.597","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"107.893","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"107.517","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"107.691","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"107.612","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"107.819","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"107.474","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"106.970","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"105.252","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"104.188","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"104.309","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"104.336","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"104.703","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"104.421","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"103.896","year":"2020"}],"seriesID":"CUUR0000SAD"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"337.751","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"336.274","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"335.517","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"333.566","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"332.904","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"332.678","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"332.083","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"330.750","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"330.561","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"329.710","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"329.120","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"328.678","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"328.043","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"327.731","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"327.327","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"325.409","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"325.172","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"325.731","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"324.704","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"324.100","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"323.523","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"322.556","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"322.249","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"321.566","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"320.863","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"320.569","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"319.136","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"316.839","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"315.857","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"315.323","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"313.142","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"310.875","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"308.532","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"305.041","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"302.038","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"298.711","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"295.728","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"292.794","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"289.772","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"286.966","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"285.507","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"284.205","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"281.506","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"279.135","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"278.127","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"276.206","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"274.212","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"273.090","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"271.812","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"271.363","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"270.938","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"270.023","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"269.069","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"269.828","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"269.163","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"269.079","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"268.863","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"269.770","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"268.439","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"266.757","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"262.708","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"261.876","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"261.057","year":"2020"}],"seriesID":"CUUR0000SAF1"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"343.512","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"342.398","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"340.875","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"338.883","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"338.048","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"337.470","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"336.776","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"335.931","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"335.056","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"334.087","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"332.777","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"331.688","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"331.247","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"329.704","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"328.222","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"325.640","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"324.735","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"323.964","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"323.563","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"321.894","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"321.087","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"320.002","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"318.205","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"317.278","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"316.514","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"315.431","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"313.747","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"310.725","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"308.720","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"307.816","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"306.521","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"304.506","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"302.327","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"300.927","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"297.868","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"295.259","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"293.577","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"291.504","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"289.889","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"287.511","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"286.308","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"285.310","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"283.744","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"282.391","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"281.604","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"280.366","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"278.648","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"277.258","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"276.028","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"275.137","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"274.336","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"273.684","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"273.290","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"273.014","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"273.116","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"272.866","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"272.445","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"271.831","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"270.823","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"270.184","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"270.273","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"270.281","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"269.468","year":"2020"}],"seriesID":"CUUR0000SAH"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"270.061","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"271.040","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"270.384","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"267.606","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"268.450","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"269.724","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"269.604","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"271.391","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"273.326","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"273.579","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"276.623","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"276.687","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"272.485","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"266.638","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"262.110","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"263.375","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"267.035","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"270.027","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"272.517","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"274.220","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"270.602","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"270.146","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"268.862","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"267.402","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"261.969","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"259.712","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"257.874","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"255.993","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"264.668","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"267.979","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"266.109","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"270.334","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"278.958","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"284.644","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"274.282","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"266.892","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"264.525","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"253.150","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"248.424","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"246.499","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"245.532","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"241.042","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"236.373","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"238.333","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"239.722","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"237.701","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"229.689","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"222.547","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"215.761","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"209.054","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"205.631","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"203.560","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"202.828","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"203.086","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"202.715","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"202.386","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"200.766","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"195.609","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"191.419","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"193.732","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"203.854","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"207.772","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"208.284","year":"2020"}],"seriesID":"CUUR0000SAT"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"574.739","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"573.320","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"571.899","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"569.189","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"568.773","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"567.870","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"566.266","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"564.407","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"564.039","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"565.301","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"564.249","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"561.612","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"559.935","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"557.236","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"557.215","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"553.485","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"551.769","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"549.762","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"548.431","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"548.082","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"546.698","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"547.432","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"547.420","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"547.219","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"547.805","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"549.487","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"551.422","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"551.002","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"550.844","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"554.043","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"556.323","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"553.429","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"549.562","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"546.717","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"543.488","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"541.515","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"539.739","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"536.932","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"535.048","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"530.026","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"528.877","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"527.564","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"524.818","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"525.247","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"524.219","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"522.989","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"523.918","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"524.585","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"524.734","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"524.207","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"522.133","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"518.766","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"519.848","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"520.725","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"522.528","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"523.295","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"522.686","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"520.734","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"519.194","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"517.053","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"515.605","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"513.923","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"512.149","year":"2020"}],"seriesID":"CUUR0000SAM"},{"data":[{"footnotes":[{}],"latest":"true","period":"M03","periodName":"March","value":"306.847","year":"2025"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"306.284","year":"2025"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"305.860","year":"2025"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"305.662","year":"2024"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"305.865","year":"2024"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"305.154","year":"2024"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"304.883","year":"2024"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"301.065","year":"2024"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"298.288","year":"2024"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"297.420","year":"2024"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"296.691","year":"2024"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"295.736","year":"2024"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"295.297","year":"2024"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"295.488","year":"2024"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"294.574","year":"2024"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"294.040","year":"2023"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"293.674","year":"2023"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"294.084","year":"2023"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"294.357","year":"2023"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"292.014","year":"2023"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"290.069","year":"2023"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"289.382","year":"2023"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"288.843","year":"2023"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"288.606","year":"2023"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"288.260","year":"2023"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"287.651","year":"2023"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"287.509","year":"2023"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"287.177","year":"2022"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"286.792","year":"2022"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"286.449","year":"2022"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"286.151","year":"2022"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"283.882","year":"2022"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"280.974","year":"2022"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"280.562","year":"2022"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"279.356","year":"2022"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"278.647","year":"2022"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"278.388","year":"2022"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"278.380","year":"2022"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"278.087","year":"2022"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"277.904","year":"2021"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"278.097","year":"2021"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"278.047","year":"2021"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"277.551","year":"2021"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"275.373","year":"2021"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"273.812","year":"2021"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"273.169","year":"2021"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"272.544","year":"2021"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"271.829","year":"2021"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"271.559","year":"2021"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"272.539","year":"2021"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"272.238","year":"2021"},{"footnotes":[{}],"period":"M12","periodName":"December","value":"272.437","year":"2020"},{"footnotes":[{}],"period":"M11","periodName":"November","value":"272.359","year":"2020"},{"footnotes":[{}],"period":"M10","periodName":"October","value":"272.465","year":"2020"},{"footnotes":[{}],"period":"M09","periodName":"September","value":"272.241","year":"2020"},{"footnotes":[{}],"period":"M08","periodName":"August","value":"271.626","year":"2020"},{"footnotes":[{}],"period":"M07","periodName":"July","value":"270.659","year":"2020"},{"footnotes":[{}],"period":"M06","periodName":"June","value":"269.993","year":"2020"},{"footnotes":[{}],"period":"M05","periodName":"May","value":"269.725","year":"2020"},{"footnotes":[{}],"period":"M04","periodName":"April","value":"269.614","year":"2020"},{"footnotes":[{}],"period":"M03","periodName":"March","value":"269.450","year":"2020"},{"footnotes":[{}],"period":"M02","periodName":"February","value":"269.360","year":"2020"},{"footnotes":[{}],"period":"M01","periodName":"January","value":"268.841","year":"2020"}],"seriesID":"CUUR0000SAE1"}]},"message":[],"responseTime":229,"status":"REQUEST_SUCCEEDED"}
"""
CPI_DATA_SET_KEY_NAME = "cpi_tracker_CPIDataSetKeyName"
CPI_CON_COLORS = ["#B31942", "#FFFFFF", "#0A3161", "#B31942", "#FFFFFF"]
SELECTED_SERIES_DATA = [["CUUR0000SA0", "All Items", "#FFD700", "Gold"], ["CUUR0000SA0E", "Energy", "#FFFF00", "Yellow"], ["CUUR0000SAC", "Commodities", "#8B4513", "Earthy Brown"], ["CUUR0000SAD", "Durables", "#4682B4", "Steel Blue"], ["CUUR0000SAF1", "Food", "#32CD32", "Green"], ["CUUR0000SAH", "Housing", "#B22222", "Brick Red"], ["CUUR0000SAT", "Transportation", "#FF8C00", "Orange"], ["CUUR0000SAM", "Medical", "#FFFFFF", "White"], ["CUUR0000SAE1", "Education", "#1E90FF", "Academic Blue"]]

SCREEN_HEIGHT = 32
SCREEN_WIDTH = 64

display_type = [
    schema.Option(display = "Display The Main CPI Index", value = "CPI"),
    schema.Option(display = "Display selected categories of CPI", value = "Categories"),
]

display_time_period = [
    schema.Option(display = "3 Months", value = "3"),
    schema.Option(display = "6 Months", value = "6"),
    schema.Option(display = "1 Year", value = "12"),
    schema.Option(display = "2 Years", value = "24"),
    schema.Option(display = "3 Years", value = "36"),
    schema.Option(display = "4 Years", value = "48"),
    schema.Option(display = "5 Years", value = "60"),
]

def get_category_options(type):
    display_options = []

    # Loop through each item and print the values
    if (type == "Categories"):
        for item in SELECTED_SERIES_DATA:
            display_options.append(schema.Toggle(id = item[0], name = item[1], desc = "%s  (in %s)" % (item[1], item[3]), icon = "check", default = False))

    return display_options

def get_category_list():
    # Initialize an empty list for the results
    first_elements = []

    # Loop through the data
    for item in SELECTED_SERIES_DATA:
        first_elements.append(item[0])

    return first_elements

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    title = "Consumer Price Index (CPI) Data"
    instructions_1 = "You can select the main CPI Index, or selected categories, including the general index. Adding additional categories makes the display a little crowded, but suit yourself."
    instructions_2 = "The source for this app is the U.S. Bereau of Labor Statistics, see www.bls.gov for more information. The data presented here is not to scale, only shows relative changes over the time period. "
    instructions_3 = "In addition to categories, you may also select the time period displayed from 3 months, to 5 years. "
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(title, color = CPI_CON_COLORS[0], font = "5x8"),
                ),
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_1, color = CPI_CON_COLORS[1]),
                    offset_start = len(title) * 5,
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_2, color = CPI_CON_COLORS[2]),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_2) + len(instructions_1)) * 5,
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_3, color = CPI_CON_COLORS[3]),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_cpi_data():
    # Check for cache first
    data = json.decode(cache.get(CPI_DATA_SET_KEY_NAME)) if cache.get((CPI_DATA_SET_KEY_NAME)) != None else None

    if (data == None):
        # URL for the BLS API
        url = "https://api.bls.gov/publicAPI/v2/timeseries/data/"

        # Define headers for the request
        headers = {
            "Content-Type": "application/json",
        }

        # Always get at least 60 months of data to cach
        # We can always filter down for individual preferences
        now = time.now().in_location("UTC")
        current_year = now.year
        start_year = current_year - 5

        # Define the payload for the POST request
        payload = {
            "seriesid": get_category_list(),
            "startyear": str(start_year),
            "endyear": str(current_year),
            "registrationkey": secret.decrypt(ENCRYPTED_API_KEY),
        }

        # Convert payload to JSON
        body = json.encode(payload)

        # Make the HTTP POST request
        response = http.post(
            url = url,
            headers = headers,
            body = body,
            ttl_seconds = TIME_OUT_IN_SECONDS,
        )

        data = json.encode(response.json())
        cache.set(CPI_DATA_SET_KEY_NAME, json.encode(data), ttl_seconds = TIME_OUT_IN_SECONDS)

    return data

def plot_cpi_data(formatted_data, color, show_info_bar):
    months = []
    for i in range(len(formatted_data), 0, -1):
        months.append(i)

    # Example CPI data for the past 6 months (replace with actual data from your API response)
    cpi_values = formatted_data

    # Combine months and values into a list of data points
    data = [(month, value) for month, value in zip(months, cpi_values)]

    height = SCREEN_HEIGHT - 7 if show_info_bar else SCREEN_HEIGHT

    # Use render.plot to create a line graph
    return render.Plot(
        data = data,
        color = color,
        width = SCREEN_WIDTH,
        height = height,
    )

def get_series_data_by_name(parsed_data, series_name):
    # Loop through the series list
    for series in parsed_data["Results"]["series"]:
        # Check if the seriesID matches the desired name
        if series["seriesID"] == series_name:
            # Return the "data" for the matching series
            return series["data"]

    # Return None if the series name is not found
    return None

def extract_filtered_data(json_data, series_name, months):
    # Decode the JSON string into a Starlark dictionary
    parsed_data = json.decode(json_data)

    # Access the series data
    series_data = get_series_data_by_name(parsed_data, series_name)

    # Extract the last 6 months (assuming data is ordered with most recent first)
    relevant_dates = series_data[:months]  # Take the first 6 records

    # Format the data as a list of tuples (month, value)
    formatted_data = [
        (float(item["value"]))
        for item in relevant_dates
    ]

    return formatted_data

def get_series_item(series_id, item_number):
    # Iterate over each item in the array
    for item in SELECTED_SERIES_DATA:
        # Check if the first element matches the given series ID
        if item[0] == series_id:
            # Return the third element (color code)
            return item[item_number]

    # Return None if no match is found
    return None

def get_series_color(series_id):
    return get_series_item(series_id, 2)

def get_series_name(series_id):
    return get_series_item(series_id, 1)

def get_series_color_name(series_id):
    return get_series_item(series_id, 3)

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    show_info_bar = config.bool("info_bar", False)

    # store the items we add to the display in children
    animation_frames = []  #
    children = []  #Items that go into a stack
    messages = []  #building up the string to display

    # default to sample data
    data = SAMPLE_DATA

    # get the full CPI data, then figure out what subsets we want to display
    # Sample Data to be used in the Preview of Apps, and for the Testing on check ins
    if (secret.decrypt(ENCRYPTED_API_KEY) != None):
        data = get_cpi_data()

    #store the series to display, default it to the main CPI dataset
    series_data_sets_to_display = []
    series_data_sets_to_display.append(SELECTED_SERIES_DATA[0][0])

    if (config.get("display_type") != "CPI"):
        individual_series = []
        for item in SELECTED_SERIES_DATA:
            if (config.bool(item[0], False)):
                individual_series.append(item[0])

        if (len(individual_series) > 0):
            series_data_sets_to_display = individual_series

    # let's plot them in reverse order to make "Everything" overlap the individual items
    for item in series_data_sets_to_display[::-1]:
        plot_data = extract_filtered_data(data, item, int(config.get("display_time_period", display_time_period[0].value)))
        children.append(plot_cpi_data(plot_data, get_series_color(item), show_info_bar))

    #snapshot of just the chart display lines
    chart_display_children = children

    # I have the chart display, but I want to expose it one pixel column at a time
    current_scene = render.Box(color = "#000", width = SCREEN_WIDTH, height = SCREEN_HEIGHT)
    for i in range(SCREEN_WIDTH + 1):  #range(SCREEN_WIDTH):
        #Create animation images of the stack chart, and a box so that the animation works

        current_scene = render.Stack(
            children = [
                render.Stack(children = chart_display_children),
                add_padding_to_child_element(
                    render.Box(color = "#000", width = SCREEN_WIDTH - i, height = SCREEN_HEIGHT),
                    i,
                ),
            ],
        )

        animation_frames.append(current_scene)

    # Hold for a few frames
    for i in range(25):
        animation_frames.append(current_scene)

    #Reset Children for the overlay of info
    children = []

    # Add some generic info on the time period from the first data set
    first_item = json.decode(data)["Results"]["series"][0]["data"][0]
    year = first_item["year"]
    period_name = first_item["periodName"]

    message = "     %s months CPI data to %s %s " % (int(config.get("display_time_period", display_time_period[0].value)), period_name, year)
    messages.append(render.Text(message, color = "#fff"))

    # but let's list the selected item in order
    for item in series_data_sets_to_display:
        message = "%s in %s " % (get_series_name(item), get_series_color_name(item))
        messages.append(render.Text(message, color = get_series_color(item)))

    if show_info_bar:
        children.append(add_padding_to_child_element(render.Marquee(
            width = SCREEN_WIDTH,
            child = render.Row(messages),
            offset_start = 0,
            offset_end = 0,
            align = "start",
        ), 0, 25))
    else:
        #display some data
        message = "%s months" % (int(config.get("display_time_period", display_time_period[0].value)))
        children.append(add_padding_to_child_element(render.Text(message, color = "#666", font = "CG-pixel-3x5-mono"), SCREEN_WIDTH - (len(message) * 4), SCREEN_HEIGHT - 5))

    all_elements = [
        render.Animation(children = animation_frames),
    ]

    all_elements.append(render.Stack(children = children))

    return render.Root(
        child = render.Stack(children = all_elements),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
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
            schema.Toggle(
                id = "info_bar",
                name = "Information Bar",
                desc = "Show the Information bar across the bottom of the screen?",
                icon = "info",  #"info",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "display_time_period",
                icon = "timeline",
                name = "Time Period",
                desc = "Which time period would you like the chart to represent?",
                options = display_time_period,
                default = display_time_period[2].value,
            ),
            schema.Dropdown(
                id = "display_type",
                icon = "tv",
                name = "What to display",
                desc = "What do you want this to display?",
                options = display_type,
                default = display_type[0].value,
            ),
            schema.Generated(
                id = "generated",
                source = "display_type",
                handler = get_category_options,
            ),
        ],
    )
