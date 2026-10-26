# Sky Watch

Sky Watch displays the closest recently reported airborne aircraft within a
chosen radius. The first page shows a simple aircraft silhouette, callsign,
altitude, ground distance, and ground speed. An optional second page shows registration,
type, and heading. Altitude is in feet, speed in knots, and radius in nautical
miles. Missing identity fields use registration or transponder hex as fallbacks.

Ten original pixel silhouettes cover airliners, twin-engine widebodies,
four-engine jets, single/twin/four-engine propeller aircraft, business jets,
fighters, helicopters, and a generic fallback. Common ICAO type codes select
the family; ADS-B rotorcraft category is also recognized. These are simple
family illustrations rather than exact model drawings. Unrecognized types use
the generic silhouette, and the exact reported type code remains on the details page.

Select a location and a radius of 5, 10, 20, 30, or 50 NM in the Tidbyt phone app.
Choose whether to show the details page or hide the app when no aircraft are
nearby. The app does not require an aircraft service API key at this time.

## Data and privacy

Data is provided by [ADSB.lol](https://www.adsb.lol/), under the
[Open Database License](https://opendatacommons.org/licenses/odbl/1-0/).
See the [API documentation](https://api.adsb.lol/docs) for current service terms.
ADSB.lol asks production applications to contact the provider before relying on
the service; a public catalog release should coordinate this with the provider.

Only coordinates truncated to two decimal places are sent to ADSB.lol. The
query radius includes a 2 NM margin to cover that displacement. Selection uses
the actual configured point and radius inside the app. No precise location,
Device ID, token, callsign history, or individual aircraft selection is stored
by this source. The phone app's location remains part of the user's Tidbyt
installation configuration, and the data provider sees the coarse query.

Aircraft feed responses are cached for 60 seconds, shared by identical coarse
query URLs. This is a cache lifetime, not a guaranteed render schedule; Tidbyt
controls when hosted apps are rendered and delivered. Position reports more
than 90 seconds old, including the feed snapshot age, are ignored. Ground
aircraft and records without usable altitude or position freshness are ignored.
The rendered image expires after 120 seconds to avoid indefinitely displaying
an old aircraft during connectivity or rendering failures.

The app distinguishes empty results, old feed snapshots, and HTTP/data errors.
Pixlet raises transport errors before Starlark can handle them; on these
failures the device can retain its previous image until its expiry. There is
no unlimited stale-data fallback. Public ADS-B coverage is incomplete; distance
is across the ground, rather than the slant distance to the aircraft. This
display is intended for identifying nearby reported flights.

## Development

With Pixlet v0.34.0:

```sh
pixlet render sky_watch.star demo=true
pixlet serve sky_watch.star
pixlet check sky_watch.star
```

The `demo=true` developer parameter renders a labeled synthetic example without
network access. It is not exposed in the published phone app settings. Without
location configuration, the app renders SET LOCATION and makes no HTTP request.

The native regression tests run 47 core assertions plus aircraft-family and
silhouette checks inside Pixlet, and render seven
synthetic HTTP cases using a temporary loopback server. Python 3.10+ is needed
only to run these tests; the deployed app runs in Starlark without Python.

```sh
python run_tests.py /path/to/pixlet
```

Tests do not use a Tidbyt account, token, saved tracker configuration, or an
external API. The public catalog submission includes no user's coordinates.
