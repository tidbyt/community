# VBB Berlin — Tidbyt app

Live departures from any stop in the VBB (Berlin/Brandenburg) public-transport
network on a [Tidbyt](https://tidbyt.com) display.

Each row shows the line (color-coded by mode), the direction (scrolling if it
overflows), and the ETA in minutes. The ETA itself is color-coded:

- red — `now` or ≤ 2 min (run!)
- yellow — 3 to 10 min
- green — more than 10 min

Data is fetched from the public
[v6.vbb.transport.rest](https://v6.vbb.transport.rest/api.html) API. No API key
required.

## Configuration

| Field | Description |
|-------|-------------|
| `stop_id` | VBB stop ID. In the schema UI, type a station name and pick from the autocomplete. When pushing manually, pass the raw ID (e.g. `900135001`). |
| `mode` | One of `all`, `suburban` (S-Bahn), `subway` (U-Bahn), `tram`, `bus`, `regional` (incl. express), `ferry`. Defaults to `all`. |

Find stop IDs with the locations endpoint:

```bash
curl -s "https://v6.vbb.transport.rest/locations?query=alexanderplatz&results=5&poi=false&addresses=false" \
  | jq '.[] | {id, name}'
```
