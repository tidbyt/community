# TfL Commute

Tidbyt app: the next two buses at two London bus stops, and the status of up
to three TfL lines. Data from the TfL Unified API.

## Configuration

| Field                   | Required | Notes                                                                                     |
| ----------------------- | -------- | ----------------------------------------------------------------------------------------- |
| First / second bus stop | yes      | Location picker: stops within 400m, nearest first, labelled `<letter> <name> (towards X)` |
| Status line 1–3         | no       | Tube, Overground, DLR, Elizabeth line, Tram or Thameslink.                                |

## Behaviour

- Times are minutes to arrival. `<1` under a minute.
  Orange under 2 minutes, yellow under 5. Dash when there is no bus.
- A stop with an active TfL closure shows an orange bar instead of times.
- Status: green Good, yellow Minor Delays, orange anything worse.
  A line with several statuses shows the worst. "Good Service" is shown as "Good" to save space
- Line codes: BKL CEN CIR DIS DLR ELZ H&C JUB LIB LIO MET MIL NOR PIC SUF TLK
  TRM VIC W&C WEA WIN, in the TfL Colour Standard colours (except Northern which is white).
- A failed TfL call is retried once.
  If it still fails, stops without data show dashes and the status area reads "TfL data unavailable".
- Caching: arrivals 30s, status 2m, closures 5m, stop details 1 day. `max_age` is 2 minutes.

## Development

```
pixlet serve tflcommute/                                  # config form + preview
pixlet render tflcommute/ stop1=490020255S stop2=490000173RG line1=central
pixlet render tflcommute/ fake=1                          # canned data, no network
pixlet render tflcommute/ ... fail=1                      # every TfL call 404s
pixlet render tflcommute/ ... outage=1                    # no TfL calls
pixlet check tflcommute/
```

On the command line the stop fields take TfL NaPTAN stop ids and the
line fields take TfL line ids (i.e. `central`, `mildmay`, `hammersmith-city`).

TfL API key is optional. Register at https://api-portal.tfl.gov.uk/, run
`pixlet encrypt tfl-commute <key>` and set `ENCRYPTED_APP_KEY`.
Without a key the app uses TfL's anonymous quota.

TfL returns 403 to Go's default User-Agent, so the app sets its own.
