#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
app="$repo_root/apps/uslleagueone/usl_league_one.star"
fixtures="$repo_root/apps/uslleagueone/tests/fixtures"
pixlet_bin="${PIXLET:-$HOME/.local/bin/pixlet}"
output_dir="${TMPDIR:-/tmp}/uslleagueone-tests"
mkdir -p "$output_dir"

run_case() {
    name="$1"
    state="$2"
    result="${3:-}"
    fixture="$(tr -d '\n' < "$fixtures/$name.json")"
    "$pixlet_bin" render "$app" \
        "_fixture_json=$fixture" \
        "_expected_state=$state" \
        "_expected_result=$result" \
        -o "$output_dir/$name.webp"
}

run_case live live
run_case final_win final W
run_case final_loss final L
run_case draw final D
run_case upcoming upcoming
run_case postponed postponed
run_case canceled canceled
run_case no_event none
run_case missing_fields none

echo "USL League One fixture tests passed"
