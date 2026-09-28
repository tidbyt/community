# NJ Departures

Watch up to six nearby stops at once — NJ Transit buses, light rail and
NY Waterway ferries — and see the next departure from each.

Enter an address once, then pick stops from a list sorted by distance. Every
entry names its mode and its direction of travel, so the two sides of a street
are distinguishable:

```
BUS · Blvd East at 47/48th St to New York - 23, 128, 165, 166 (0.2 mi)
RAIL · Port Imperial Hblr to Tonnelle Ave - HBLR (0.2 mi)
FERRY · Port Imperial / Weehawken to Midtown / W. 39th St. (0.0 mi)
```

Four departures fit on screen; watching more pages between them. Fewer than
four and the spare rows show additional departures rather than sitting empty.

Bus times are realtime, from NJ Transit's BUSDV2 API. A bus being tracked by
GPS flashes `LIVE` in place of its route number and shows a full-brightness
countdown; a dimmed countdown means the time came from a timetable. Light rail
and ferry are always timetable, because neither publishes a realtime feed this
runtime can consume — NY Waterway's is protobuf, and Starlark has no protobuf
module.

Countdowns turn red at three minutes or fewer.

## Data

Stop geography and the light rail and ferry timetables are precomputed from
published GTFS and served as small JSON files, so the app downloads a few
kilobytes rather than parsing a 50 MB feed on the device:

- NJ Transit bus and rail GTFS (public, no registration)
- NY Waterway GTFS via Connexionz (public)

The build pipeline and the generated data live at
<https://github.com/joshbrewster42/tidbyt-nj-transit>, which is also where the
app fetches them from.

Realtime bus departures require NJ Transit developer credentials, supplied
through `secret.decrypt`.
