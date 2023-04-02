**About**

This app integrates with the FlightAware API, allowing users to input their FlightAware API key and track a specific flight's progress or display the recent arrivals or departures from a specified airport.

**Visual**

The top color bar changes based upon the flight status (onetime, delayed, cancelled, etc) - once a flight has taken off it also functions as a progress bar for the flight's completion.

The second section of information contains the departure and arrival cities and airport codes; as well as the scheduled time (or actual time) of departure or arrival (what time is displayed is determined based upon the current flight status; ie - if a flight has departed it won't show the scheduled departure; rather the actual).

The airline logos are sourced from the FlightAware library of logos that can be fetched utilizing the operator code provided by the API response.

The first marquee will change color based upon the current flight status; much like the top bar - and based upon the flight status it will display the next milestone in the flight's journey. (For instance after prior to takeoff it will show "Scheduled to Depart in x minutes", etc)

The lower marquee will display the flight number, aircraft registration and the aircraft type.

**Caching**

Due to the nature of tracking arrivals / departures and live flight data, the caching is currently set to just 60 seconds. Caches are stored depending upon whether or not you are viewing airport arrivals / departures or a specific flight so that if multiple users are tracking the same element the cache will be available for their use.

(Example: caches for arriving/departing flights are stored as `arrivals/KMCO` or `departures/KATL` or if you're tracking a flight it is stored as `flight/DAL093`)

![flighttracker](https://user-images.githubusercontent.com/10890289/220386169-ed6bfbd4-e745-443e-9b01-d5ad27a9ee67.GIF)
