# PurpleAir for Tidbyt

PurpleAir displays an estimate of the air quality index (AQI) using the specified [PurpleAir](https://www.purpleair.com) sensor. The US EPA method is used to calculate the index. It is updated every 60 minutes. The estimate should be very close or exactly match the index shown for the sensor on the [PurpleAir map](https://map.purpleair.com/1/mAQI/a0/p604800/cC5?select=33997#15.38/37.828489/-122.42342).

An API key is required to fetch sensor data and the list of sensors from the PurpleAir API. Please get your API key from the [PurpleAir develop site](https://develop.purpleair.com/sign-in?redirectURL=%2Fkeys).

Note that only the US EPA calculation method is supported right now but I hope to support other methods in the future.

![PurpleAir for Tidbyt](screenshot.png)