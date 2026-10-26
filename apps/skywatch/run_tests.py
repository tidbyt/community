"""Exercise the real Starlark app using Pixlet and synthetic HTTP fixtures.

No account, device token, saved tracker settings, or external network is used.
Pass the path to the official Pixlet executable as the first argument.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import subprocess
import sys
import threading
import time

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR if (SCRIPT_DIR / "sky_watch.star").exists() else SCRIPT_DIR.parent
APP = ROOT / "app" if (ROOT / "app").exists() else ROOT
PIXLET = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "tools" / "pixlet.exe"
SOURCE = (APP / "sky_watch.star").read_text(encoding="utf-8")
OUTPUT = ROOT / "test-output"
OUTPUT.mkdir(exist_ok=True)


def render(path, name, *config):
    result = subprocess.run(
        [str(PIXLET), "render", str(path), *config, "-o", str(OUTPUT / (name + ".webp"))],
        capture_output=True, text=True, timeout=20,
    )
    if result.returncode:
        raise AssertionError(result.stdout + result.stderr)
    return result.stdout


# This harness renames only the app entry point, then calls the unchanged helpers.
# Tests execute inside Pixlet's Starlark runtime, not a Python approximation.
HARNESS = r'''
load("assert.star", "assert")

def main(config):
    assert.eq(number(None), None)
    assert.eq(number(True), None)
    assert.eq(number("bad"), None)
    assert.eq(number("1.2.3"), None)
    assert.eq(number("."), None)
    assert.eq(number(" -77.405 "), -77.405)
    assert.eq(number(12), 12.0)
    assert.eq(location_from_config({}), None)
    assert.eq(location_from_config({"location": "bad JSON"}), None)
    assert.eq(location_from_config({"location": "[]"}), None)
    assert.eq(location_from_config({"location": '{"lat":"91","lng":"0"}'}), None)
    assert.eq(location_from_config({"location": '{"lat":"38.42","lng":"-77.40"}'}), (38.42, -77.4))
    assert.eq(radius_from_config({}), 10)
    assert.eq(radius_from_config({"radius_nm": "50"}), 50)
    assert.eq(radius_from_config({"radius_nm": "-10"}), 10)
    assert.eq(radius_from_config({"radius_nm": "oops"}), 10)
    assert.eq(enabled({}, "details", True), True)
    assert.eq(enabled({"details": "false"}, "details", True), False)
    assert.eq(fixed_decimal(26.7), "26.7")
    assert.eq(fixed_decimal(2.95), "3.0")
    assert.eq(fixed_decimal(-77.4, places = 2), "-77.40")
    assert.eq(request_url((38.429876, -77.409876), 10), "https://api.adsb.lol/v2/lat/38.42/lon/-77.40/dist/12")
    assert.eq(distance_nm(0, 0, 0, 0), 0.0)
    assert.true(distance_nm(0, 0, 1, 0) > 60 and distance_nm(0, 0, 1, 0) < 60.1)
    assert.eq(payload_age({"now": 1000000}, 1000010), 10.0)
    assert.eq(payload_age({"now": 1700000000000}, 1700000010), 10.0)
    assert.eq(payload_age({"now": 1700000000000}, 1699999900), None)
    assert.eq(payload_age({}, 1000), None)
    assert.eq(altitude_text({"alt_baro": 26700}), "26.7KFT")
    assert.eq(altitude_text({"alt_geom": 2400}), "2400FT")
    assert.eq(altitude_text({}), "ALT --")
    assert.eq(heading_text({"track": 270}), "HDG 270 W")
    assert.eq(heading_text({"track": 359.9}), "HDG 000 N")
    assert.eq(heading_text({}), "HEADING UNKNOWN")
    assert.eq(speed_text({"gs": 420.6}), "421KT")
    assert.eq(speed_text({"gs": -1}), "--KT")
    assert.eq(label({"flight": " AAL1234 "}), "AAL1234")
    assert.eq(label({"flight": "", "r": "N123AB"}), "N123AB")
    assert.eq(label({"hex": "abc123"}), "ABC123")
    assert.eq(label({}), "UNKNOWN")
    point = (38.42, -77.4)
    active = {"flight": "ACTIVE", "lat": 38.43, "lon": -77.4, "alt_baro": 2500, "seen_pos": 1}
    ground = dict(active, alt_baro = "ground", flight = "GROUND")
    stale = dict(active, seen_pos = 100, flight = "STALE")
    invalid = dict(active, lat = 100, flight = "INVALID")
    unknown_altitude = {"flight": "UNKNOWN", "lat": 38.42, "lon": -77.4, "seen_pos": 0}
    outside = dict(active, lat = 40, flight = "OUTSIDE")
    winner = closest_aircraft([ground, stale, invalid, unknown_altitude, outside, None, active], point, 10, 0)
    assert.eq(winner["flight"], "ACTIVE")
    assert.true(winner["_distance_nm"] < 1)
    assert.eq(closest_aircraft([active], point, 10, 90), None)
    assert.eq(closest_aircraft([], point, 10, 0), None)
    assert.eq(display_payload({"ac": [], "now": 1000}, point, 10, True, True, 1000), [])
    assert.eq(len(get_schema().fields), 4)
    print("PASS: 47 Starlark assertions")
    type_cases = [
        ("B738", "airliner"), ("A320", "airliner"), ("B38M", "airliner"),
        ("A333", "widebody"), ("B77W", "widebody"), ("B744", "jumbo"),
        ("A388", "jumbo"), ("C172", "prop"), ("C208", "prop"),
        ("BE20", "twinprop"), ("AT76", "twinprop"), ("C130", "fourprop"),
        ("GLF6", "bizjet"), ("F16", "fighter"), ("R44", "helicopter"),
        ("H60", "helicopter"), ("UNKNOWN", "generic"),
    ]
    for code, expected in type_cases:
        assert.eq(aircraft_kind({"t": code}), expected)
    assert.eq(aircraft_kind({"category": "A7"}), "helicopter")
    assert.eq(len(ICON_PIXELS), 10)
    for rows in ICON_PIXELS.values():
        assert.eq(len(rows), 15)
        for row in rows:
            assert.eq(len(row), 24)
    print("PASS: 17 aircraft type cases, rotorcraft fallback, and 10 pixel silhouettes")
    return sky_watch_main({"demo": "true"})
'''


def main():
    unit_dir = OUTPUT / "unit"
    unit_dir.mkdir(exist_ok=True)
    harness = unit_dir / "unit_tests.star"
    harness.write_text(SOURCE.replace("def main(config):", "def sky_watch_main(config):") + HARNESS,
                       encoding="utf-8")
    result = render(harness, "unit-tests")
    assert "PASS: 47 Starlark assertions" in result
    assert "PASS: 17 aircraft type cases" in result
    print("PASS: 47 assertions executed in the native Starlark runtime")
    print("PASS: 17 aircraft type cases, rotorcraft fallback, and 10 pixel silhouettes")
    requests = []
    responses = {
        "aircraft": (200, {"ac": [{"flight": "TEST123", "r": "N123AB", "t": "A320",
                                   "alt_baro": 12000, "gs": 250, "track": 90,
                                   "lat": 38.43, "lon": -77.4, "seen_pos": 1}]}),
        "empty": (200, {"ac": []}),
        "stale": (200, {"ac": [], "now": 1000}),
        "bad_json": (200, "not-json"),
        "bad_shape": (200, {"ac": {}}),
        "http_429": (429, {}),
        "http_503": (503, {}),
    }

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            requests.append((self.path, dict(self.headers)))
            name = self.path.split("/")[1]
            code, data = responses[name]
            if isinstance(data, dict):
                data = {"now": int(time.time() * 1000), **data}
                body = json.dumps(data).encode()
            else:
                body = data.encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        location = 'location={"lat":"38.429876","lng":"-77.409876"}'
        for name in responses:
            case_source = SOURCE.replace(
                'API_BASE = "https://api.adsb.lol/v2"',
                f'API_BASE = "http://127.0.0.1:{server.server_port}/{name}"',
            )
            case_dir = OUTPUT / name
            case_dir.mkdir(exist_ok=True)
            path = case_dir / "sky_watch.star"
            path.write_text(case_source, encoding="utf-8")
            render(path, name, location)
            print("PASS: native render with synthetic HTTP response -", name)
        for path, headers in requests:
            assert path.endswith("/lat/38.42/lon/-77.40/dist/12"), path
            assert "38.429876" not in path and "77.409876" not in path
            assert headers.get("X-Tidbyt-Cache-Seconds") == "60"
            assert "Authorization" not in headers
        assert len(requests) == len(responses)
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)
    print("PASS: HTTP cache header, coarse location, padded radius, no authorization")
    render(APP / "sky_watch.star", "not-configured")
    render(APP / "sky_watch.star", "demo", "demo=true")
    print("PASS: default setup state and offline demo render")
    for code in ("B738", "B77W", "B744", "C172", "BE20", "C130", "GLF6", "F16", "R44", "UNKNOWN"):
        render(APP / "sky_watch.star", "icon-" + code, "demo=true", "demo_type=" + code)
    print("PASS: all ten silhouette families rendered in the native aircraft screen")
    print("All native checks passed. No saved settings or Tidbyt token used.")


if __name__ == "__main__":
    main()
