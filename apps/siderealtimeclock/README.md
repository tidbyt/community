# Sidereal Time Clock

## Overview

This app displays the current time using [Sidereal Time](https://en.wikipedia.org/wiki/Sidereal_time) calculations.

The implementation is ported from the JavaScript code found on https://www.localsiderealtime.com/.

No APIs are used by this app, all the calculations happen inside the app itself using the `math` module.

## Configuration (Schema)

The app supports many configuration options. Since this is a geolocation based service, the user needs to provide a location via the `Location` schema field.

There are options to display the time using a blinking colon, to use 24h notation and to also display the local (standard) time along with the solar time. All colors are also configurable.

## Future Improvements

As a clock app, there isn't much to be done, but here are some suggestions:

- Add option to also display the greenwich sidereal time instead of only the local sidereal time.
- Add option to display the location name, useful for users that have multiple installations of the app to monitor the time in different locations.
- The clock only displays the current hours and minutes. It could be improved to display seconds like the `ClockWithSeconds` app.
