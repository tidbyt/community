# Temp Graph

## Overview
This app uses the [Weather API](https://www.weatherapi.com/) service to show the current temperature at a given location, along with the forecasted or actual High and Low for the day. It also shows a graph of the temperature over time, with one bar for each hour of the day. Temperatures are mapped to fill the bargraph from bottom to top using the forecasted Low and High temperatures for the day.

## API Details
We currently use two different endpoints of the v1 API:

1. [current.json endpoint](http://api.weatherapi.com/v1/current.json), which gives us the current temperature 

2. [history.json endpoint] (http://api.weatherapi.com/v1/history.json) for the daily high and low temperature forecast and the hourly temperatures to use for the bar graph when starting up.

### Authentication
WeatherAPI requires an API key to work. You can sign-up for a free account and get an API Key to enter into the configuration options. 

Note: to run the code locally you must enter an API Key in the 'API_KEY' variable.

### Rate Limiting
The API does have a limit, but it's currently 1 million calls per month, so you are unlikely to reach that limit.

## Configuration (Schema)
The app supports configuration options for the API Key, location, time format, temperature units, polling interval, and separate colors for each item on the display. There is also options to move the bar graph up or down if the temperature range in your location does not map well to the limited height of the bargraph. At the very minimum, you need to enter an API Key and your location. All the colors have default values.

## Error Handling
No real error handling is in place yet other than detecting a missing API Key.

## Future Improvements
Alternate language support.
