# Solar Time Clock

## Overview

This app displays the current time using [Solar Time](https://en.wikipedia.org/wiki/Solar_time) calculations.

The implementation is based on the JavaScript code found on https://koch-tcm.ch/en/uhrzeit-sonnenzeit-rechner/.

No APIs are used by this app, all the calculations happen inside the app itself using the `math` module.

## Configuration (Schema)

The app supports many configuration options. Since this is a geolocation based service, the user needs to provide a location via the `Location` widget.

There are options to display the time using a blinking colon, to use 24h notation and to also display the local (standard) time along with the solar time.

## Future Improvements

As a clock app, there isn't much to be done, but here are some suggestions:

- Add options to customize the colors.
- Add option to display the location name, useful for users that have multiple installations of the app to monitor the time in different locations.
- The clock only displays the current hours and minutes. It could be improved to display seconds like the `ClockWithSeconds` app.
