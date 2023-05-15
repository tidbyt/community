PM2.5 and PM10 measurements from the Airly service displayed on Tidbyt

The application allows you to display measurements of PM2.5 and PM10 air pollution. These measurements come from https://airly.org/en/. This service provides an open API to download pollution data. The open API limit is 100 queries per day. The application has been designed to fit within the limit of 100 queries per day. New measurement data is downloaded every 20 minutes. The application has a counter of used requests to the API. This is helpful because the application allows the user to select the measuring station. The measuring station is selected by the user by entering the station ID. With frequent changes of monitored measuring stations, the limit may quickly run out. In order for the application to display measurement data, the user must set the ApiKey that he received after registering at https://developer.airly.org/en/api.

The main screen of the application:


Application screen with an API request counter


Values to be set in the application settings