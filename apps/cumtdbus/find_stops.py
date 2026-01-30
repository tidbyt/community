#!/usr/bin/env python3
"""
Find CUMTD stop IDs near a location.

Usage:
    python find_stops.py search <name>        # Search stops by name
    python find_stops.py nearby <lat> <lon>   # Find stops near coordinates
    python find_stops.py departures <stop_id> # Get departures for a stop

Examples:
    python find_stops.py search "Green"
    python find_stops.py nearby 40.1106 -88.2284
    python find_stops.py departures IT:1
"""

import os
import sys

import requests

# Get API key from environment or use placeholder
API_KEY = os.environ.get("CUMTD_API_KEY", "YOUR_API_KEY")
BASE_URL = "https://developer.mtd.org/api/v2.2/json"


def find_stops_by_lat_lon(lat: float, lon: float, count: int = 10):
    """Find stops near a lat/lon coordinate."""
    url = f"{BASE_URL}/getstopsbylatlon?key={API_KEY}&lat={lat}&lon={lon}&count={count}"
    resp = requests.get(url, timeout=10)

    if resp.status_code != 200:
        print(f"Error: API returned status {resp.status_code}")
        return []

    data = resp.json()

    if data.get("status", {}).get("code") != 200:
        print(f"API Error: {data.get('status', {}).get('msg', 'Unknown error')}")
        return []

    stops = data.get("stops", [])
    print(f"\nStops near ({lat}, {lon}):\n")
    print(f"{'ID':<20} {'Name':<40} {'Distance'}")
    print("-" * 70)

    for stop in stops:
        distance = stop.get("distance", "N/A")
        print(f"{stop['stop_id']:<20} {stop['stop_name']:<40} {distance} mi")

    return stops


def search_stops_by_name(query: str):
    """Search stops by name."""
    url = f"{BASE_URL}/getstops?key={API_KEY}"
    resp = requests.get(url, timeout=10)

    if resp.status_code != 200:
        print(f"Error: API returned status {resp.status_code}")
        return []

    data = resp.json()

    if data.get("status", {}).get("code") != 200:
        print(f"API Error: {data.get('status', {}).get('msg', 'Unknown error')}")
        return []

    all_stops = data.get("stops", [])
    matches = [s for s in all_stops if query.lower() in s["stop_name"].lower()]

    print(f"\nStops matching '{query}' ({len(matches)} found):\n")
    print(f"{'ID':<20} {'Name'}")
    print("-" * 60)

    for stop in matches[:25]:
        print(f"{stop['stop_id']:<20} {stop['stop_name']}")

    if len(matches) > 25:
        print(f"\n... and {len(matches) - 25} more matches")

    return matches


def get_departures(stop_id: str):
    """Get upcoming departures for a stop."""
    url = f"{BASE_URL}/getdeparturesbystop?key={API_KEY}&stop_id={stop_id}&pt=60"
    resp = requests.get(url, timeout=10)

    if resp.status_code != 200:
        print(f"Error: API returned status {resp.status_code}")
        return []

    data = resp.json()

    if data.get("status", {}).get("code") != 200:
        print(f"API Error: {data.get('status', {}).get('msg', 'Unknown error')}")
        return []

    departures = data.get("departures", [])
    print(f"\nDepartures from {stop_id} (next 60 min):\n")
    print(f"{'Route':<8} {'Headsign':<25} {'Minutes':<10} {'Color'}")
    print("-" * 60)

    for dep in departures[:15]:
        route = dep.get("route", {})
        route_name = route.get("route_short_name", "?")
        headsign = dep.get("headsign", "")[:24]
        mins = dep.get("expected_mins", "?")
        color = route.get("route_color", "N/A")

        print(f"{route_name:<8} {headsign:<25} {mins:<10} #{color}")

    if len(departures) > 15:
        print(f"\n... and {len(departures) - 15} more departures")

    return departures


def print_usage():
    """Print usage information."""
    print(__doc__)
    print("\nNote: Set CUMTD_API_KEY environment variable or edit this script.")
    print("Get your API key at: https://developer.mtd.org/")


if __name__ == "__main__":
    if API_KEY == "YOUR_API_KEY":
        print("Warning: No API key set!")
        print("Set CUMTD_API_KEY environment variable or edit find_stops.py\n")

    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    cmd = sys.argv[1].lower()

    if cmd == "search" and len(sys.argv) >= 3:
        search_stops_by_name(" ".join(sys.argv[2:]))
    elif cmd == "nearby" and len(sys.argv) >= 4:
        find_stops_by_lat_lon(float(sys.argv[2]), float(sys.argv[3]))
    elif cmd == "departures" and len(sys.argv) >= 3:
        get_departures(sys.argv[2])
    elif cmd in ("help", "-h", "--help"):
        print_usage()
    else:
        print("Invalid command.")
        print_usage()
        sys.exit(1)
