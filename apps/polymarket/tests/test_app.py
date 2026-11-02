#!/usr/bin/env python3
"""Exercise the actual Starlark with Pixlet and produce deterministic previews.

Run: python3 apps/polymarket/tests/test_app.py [--output /absolute/output/directory]
Requires the repository's pinned Pixlet and tests/requirements.txt.
Temporary harnesses replace HTTP/cache calls; production settings are untouched.
"""

import argparse
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageChops, ImageDraw


SOURCE = Path(__file__).resolve().parents[1] / "polymarket.star"


def market(name="Alice", yes="0.64", change=0.04, **kwargs):
    return dict(
        id=name,
        active=True,
        closed=False,
        archived=False,
        acceptingOrders=True,
        question=f"Will {name} win?",
        groupItemTitle=name,
        outcomes='["Yes", "No"]',
        outcomePrices=json.dumps([yes, str(round(1 - float(yes), 6))]),
        volume24hr=10000,
        oneDayPriceChange=change,
        oneWeekPriceChange=-0.025,
    ) | kwargs


def event(identifier, title, markets, **kwargs):
    return dict(
        id=str(identifier),
        title=title,
        active=True,
        closed=False,
        archived=False,
        volume24hr=100000 - identifier,
        markets=markets,
        tags=[dict(slug="politics")],
        negRisk=True,
    ) | kwargs


EVENTS = [
    event(1, "Maine Senate winner", [market("Alice Smith"), market("Bob Jones", "0.36", -0.04)]),
    event(2, "Will the central bank cut interest rates at its next meeting?", [market("Rates", "0.28", -0.06, question="Will the central bank cut interest rates at its next meeting?")], negRisk=False, tags=[dict(slug="economy")]),
    event(3, "World Cup winner", [market("Brazil", "0.34", 0.02), market("France", "0.25", -0.01)], tags=[dict(slug="sports")]),
] + [event(i, f"Example race {i}", [market(f"Candidate {i}")]) for i in range(4, 9)]

ASSERTIONS = '''
def expect(condition, message):
    if not condition:
        fail(message)

def run_assertions():
    expect(number("NaN") == None, "NaN rejected")
    expect(number("Infinity") == None, "Infinity rejected")
    expect(number("1e999") == None, "overflow rejected")
    expect(number(True) == None, "bool is not a price")
    expect(number("bad") == None, "invalid number rejected")
    expect(number("0.64") == 0.64, "numeric string accepted")
    expect(array("[broken") == [], "invalid nested JSON rejected")
    e = TEST_EVENTS[0]
    card = make_card(e, "day")
    expect(card["favorite"] == "Alice Smith", "favorite uses candidate Yes, not rival No")
    expect(card["price"] == 0.64 and card["change"] == 0.04, "favorite probability and change")
    expect(make_card(e, "week")["change"] == -0.025, "weekly change")
    no_card = make_card(TEST_EVENTS[1], "day")
    expect(no_card["favorite"] == "No" and no_card["price"] == 0.72, "binary No favorite")
    expect(no_card["change"] == 0.06, "No outcome change sign inverted")
    tied = dict(e)
    tied["markets"] = [dict(e["markets"][0], outcomePrices='["0.5", "0.5"]'), dict(e["markets"][1], outcomePrices='["0.5", "0.5"]')]
    expect(make_card(tied, "day")["favorite"] == "Alice Smith", "ties deterministic")
    for invalid in [None, {}, "oops", dict(e["markets"][0], closed=True), dict(e["markets"][0], acceptingOrders=False), dict(e["markets"][0], outcomePrices='["1.1", "-0.1"]'), dict(e["markets"][0], outcomePrices='["0.7"]'), dict(e["markets"][0], outcomePrices='["0.7", "0.7"]'), dict(e["markets"][0], outcomes='null')]:
        expect(market_prices(invalid) == None, "bad market skipped: " + str(invalid))
    closed = dict(e)
    closed["markets"] = [dict(m, closed=True) for m in e["markets"]]
    expect(make_card(closed, "day") == None, "closed children excluded from open event")
    missing = dict(e)
    missing["markets"] = [dict(e["markets"][0], oneDayPriceChange=None)]
    expect(make_card(missing, "day")["change"] == None, "missing change not zero")
    expect(change_label(None)[0] == "--", "missing delta label")
    expect(change_label(0)[0] == "0", "zero delta label")
    expect(change_label(-0.04)[0] == "-4", "percentage points")
    expect(not allowed(e, ["politics"]), "topic exclusion")
    mixed = dict(e, tags=[{"slug":"politics"}, {"slug":"sports"}])
    expect(not allowed(mixed, ["sports"]), "overlapping topic exclusion wins")
    expect(not allowed(dict(e, tags=[]), ["other"]), "untagged uses Other")
    expect(allowed(dict(e, tags=[]), []), "all topics on includes untagged")
    repeated = [dict(v, seriesSlug="same-series") for v in TEST_EVENTS]
    expect(len(select_pool(repeated, [], "day", "trending")) == 1, "series deduplication")
    expect(len(select_pool([e, e], [], "day", "trending")) == 1, "event deduplication")
    pool = select_pool(TEST_EVENTS, [], "day", "trending")
    expect(len(pool) == 8, "eight-event pool")
    counts = [0 for _ in pool]
    for slot in range(8):
        indices = rotation(pool, slot * CACHE_SECONDS)
        expect(len(indices) == 2 and len({i:True for i in indices}) == 2, "two distinct cards")
        for i in indices:
            counts[i] += 1
    expect(counts == [2] * 8, "equal exposure over full rotation")
    expect([rotation(pool, slot * CACHE_SECONDS) for slot in range(4)] == [[0,1],[2,3],[4,5],[6,7]], "AB/CD/EF/GH rotation")
    expect(card_frame_count(make_card(TEST_EVENTS[0], "day")) == 150, "short title minimum 7.5 seconds")
    expect(card_frame_count(make_card(TEST_EVENTS[1], "day")) == 276, "long title finishes with reading hold")
    expect(favorite_lines("Alexandria Ocasio-Cortez") == ["Alexandria", "Ocasio-Cortez"], "full surname fits two rows")
    long_name = "Alexandria Ocasio-Cortez and Several Additional Candidate Names"
    wrapped = favorite_lines(long_name)
    expect(all([len(line) <= 13 for line in wrapped]), "name rows fit viewport")
    expect("".join(wrapped).replace(" ", "") == long_name.replace(" ", ""), "name wrapping loses no characters")
    long_card = dict(make_card(TEST_EVENTS[0], "day"), title="Race", favorite=long_name)
    expect(card_frame_count(long_card) >= ((len(wrapped)+1)//2)*70, "each name page gets reading time")
    for count in [1, 2, 3, 5]:
        expect(len(rotation(pool[:count], 600)) == min(2,count), "small pool rotation")
    breaking = select_pool(TEST_EVENTS, [], "week", "breaking")
    expect(breaking[0]["id"] == "2", "Breaking ranks daily change even with weekly display")
    expect(text("  A\\nB ’ “x” ") == 'A B \\' "x"', "display text normalization")
    print("PASS: parsing, favorite semantics, topic filters, deduplication, change labels, ranking, equal rotation")
'''


ELIGIBILITY_ASSERTIONS = '''
def check(condition, message):
    if not condition:
        fail(message)

def with_prices(market, yes, no):
    return dict(market, outcomePrices=json.encode([yes, no]))

def binary_event(market):
    return dict(TEST_EVENTS[1], markets=[market])

def candidate_event(markets):
    return dict(TEST_EVENTS[0], markets=markets)

def run_eligibility_tests():
    base = TEST_EVENTS[0]["markets"][0]
    for flag in [{"closed":True}, {"active":False}, {"archived":True}, {"acceptingOrders":False}, {"resolved":True}, {"automaticallyResolved":True}, {"umaResolutionStatus":"resolved"}]:
        item = dict(base, **flag)
        check(make_card(binary_event(item), "day") == None, "Ineligible market displayed: " + str(flag))
    for flag in [{"closed":True}, {"active":False}, {"archived":True}, {"resolved":True}, {"automaticallyResolved":True}, {"umaResolutionStatus":"resolved"}]:
        event = dict(TEST_EVENTS[0], **flag)
        check(make_card(event, "day") == None, "Resolved/inactive event displayed: " + str(flag))

    for flag in [{"ended":True}, {"finishedTimestamp":"2020-01-01T00:00:00Z"}, {"endDate":"2020-01-01T00:00:00Z"}]:
        item = dict(base, **flag)
        check(make_card(binary_event(item), "day") == None, "Finished market displayed: " + str(flag))
    for end_date in ["2099-01-01T00:00:00Z", "2020-99-99T00:00:00Z", "bad date", "", None]:
        item = dict(base, endDate=end_date)
        check(make_card(binary_event(item), "day") != None, "Future or malformed endDate incorrectly excluded: " + str(end_date))
    # Event end dates can precede unresolved future children; do not infer event resolution.
    event = dict(TEST_EVENTS[0], endDate="2020-01-01T00:00:00Z")
    check(make_card(event, "day") != None, "Event container endDate should not hide unfinished child questions")

    for prices in [["0.99","0.01"], ["1","0"], ["0.01","0.99"], ["0","1"], ["0.985","0.015"], ["0.015","0.985"]]:
        item = with_prices(base, prices[0], prices[1])
        check(make_card(binary_event(item), "day") == None, "Rounded 99/100 binary displayed: " + str(prices))
    boundary = make_card(binary_event(with_prices(base, "0.984", "0.016")), "day")
    check(boundary != None and boundary["price"] == 0.984, "98.4% must remain eligible")

    rival = with_prices(dict(base, id="rival", groupItemTitle="Bob Jones"), "0.36", "0.64")
    for yes, no in [["0.99","0.01"], ["1","0"], ["0.985","0.015"]]:
        winner = with_prices(base, yes, no)
        check(make_card(candidate_event([winner,rival]), "day") == None, "Decisive winner was dropped and runner-up promoted")
    winner = dict(with_prices(base, "1", "0"), closed=True, resolved=True, umaResolutionStatus="resolved")
    check(make_card(candidate_event([winner,rival]), "day") == None, "Resolved winner must suppress entire candidate event")

    # A losing candidate's near-certain No is not evidence the whole race is over.
    favorite = with_prices(base, "0.64", "0.36")
    loser = with_prices(dict(base, id="loser", groupItemTitle="Long Shot"), "0.001", "0.999")
    card = make_card(candidate_event([favorite,rival,loser]), "day")
    check(card != None and card["favorite"] == "Alice Smith" and card["price"] == 0.64, "Near-zero loser incorrectly hid a competitive event")

    # Other is sometimes a genuine competing outcome, not a disposable placeholder.
    named = with_prices(base, "0.30", "0.70")
    other = with_prices(dict(base, id="other", groupItemTitle="Other"), "0.70", "0.30")
    card = make_card(candidate_event([named,other]), "day")
    check(card != None and card["favorite"] == "Other" and card["price"] == 0.70, "Valid Other favorite incorrectly replaced by named runner-up")
    other = with_prices(other, "0.99", "0.01")
    check(make_card(candidate_event([named,other]), "day") == None, "Near-certain Other winner must hide event")

    # Defensive pool-level assertions: no eligible selection can round to 99 or 100.
    events = [binary_event(with_prices(base,"0.999","0.001")), candidate_event([favorite,rival,loser])]
    for feed in ["trending", "breaking"]:
        cards = select_pool(events, [], "day", feed)
        check(len(cards) == 1, "Pool should keep only competitive event: " + feed)
        check(all([int(math.round(c["price"]*100)) < 99 for c in cards]), "Near-certain probability escaped pool filtering")

    for value, expected in [(0.06,"+6"),(-0.06,"-6"),(0,"0"),(0.001,"0"),(None,"--")]:
        check(change_label(value)[0] == expected, "Compact change label failed: " + str(value))
    print("PASS: event/market resolution, end dates, binary 99/100 exclusions, rounding cutoff, candidate winner veto, valid Other favorite, low-probability loser handling, both feeds, compact change labels")
'''

def run_harness(directory, name, tail, body=None, status=200, saved=None, prefix="", mock_get=None, max_duration=15000, config=None, mock_cache_set=None):
    source = SOURCE.read_text()
    for call in ["def main(config):", "http.get(", "cache.get(", "cache.set("]:
        assert source.count(call) == 1, "Update the explicit test stub for: " + call
    source = source.replace("def main(config):", "def app_main(config):")
    source = source.replace("http.get(", "mock_get(").replace("cache.get(", "mock_cache_get(").replace("cache.set(", "mock_cache_set(")
    constants = (
        "\nTEST_EVENTS = json.decode(" + repr(json.dumps(EVENTS)) + ")\n"
        + "TEST_BODY = " + repr(json.dumps(EVENTS) if body is None else body) + "\n"
        + "TEST_STATUS = " + str(status) + "\n"
        + "TEST_CACHE = " + (repr(json.dumps(saved)) if saved is not None else "None") + "\n"
    )
    mocks = '''
def mock_body():
    return TEST_BODY
def mock_get(url, params, ttl_seconds):
    return struct(status_code=TEST_STATUS, body=mock_body)
def mock_cache_get(key):
    return TEST_CACHE
def mock_cache_set(key, value, ttl_seconds):
    return None
'''
    if mock_get:
        mocks = mocks.replace('def mock_get(url, params, ttl_seconds):\n    return struct(status_code=TEST_STATUS, body=mock_body)', mock_get)
    if mock_cache_set:
        mocks = mocks.replace('def mock_cache_set(key, value, ttl_seconds):\n    return None', mock_cache_set)
    path = directory / name
    path.mkdir()
    (path / "test.star").write_text(source + constants + mocks + prefix + tail)
    output = directory / (name + ".webp")
    command = ["pixlet", "render", str(path / "test.star")]
    command.extend(f"{key}={value}" for key, value in (config or {}).items())
    result = subprocess.run(command + ["--max_duration", str(max_duration), "-o", str(output)], capture_output=True, text=True)
    (directory / (name + ".stdout.txt")).write_text(result.stdout + result.stderr)
    if result.returncode:
        raise RuntimeError(name + ": " + result.stdout + result.stderr)
    print(result.stdout.strip() or "PASS: " + name)
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="polymarket-verify-") as tmp:
        directory = Path(tmp)
        run_harness(directory, "logic", '\ndef main(config):\n    run_assertions()\n    run_eligibility_tests()\n    return message_screen("Tests passed")\n', prefix=ASSERTIONS + ELIGIBILITY_ASSERTIONS)
        up = market("Up", "0.6", 0.4, events=[dict(id="1", active=True, closed=False)])
        down = market("Down", "0.1", -0.8, events=[dict(id="2", active=True, closed=False)])
        loader_prefix = '\nTEST_UP = ' + repr(json.dumps([up])) + '\nTEST_DOWN = ' + repr(json.dumps([down])) + '''
def up_body():
    return TEST_UP
def down_body():
    return TEST_DOWN
'''
        run_harness(directory, "breaking-loader", '\ndef main(config):\n    events = fetch_events("breaking", [])\n    if len(events) != 8:\n        fail("Expected complete event details")\n    return message_screen("Loader passed")\n', prefix=loader_prefix, mock_get='''def mock_get(url, params, ttl_seconds):
    if "/markets" in url:
        return struct(status_code=200, body=up_body if params["ascending"] == "false" else down_body)
    if not url.endswith("/events?id=2&id=1"):
        fail("Negative and positive moves must merge by magnitude: " + url)
    return struct(status_code=200, body=mock_body)''')
        entrypoint = '\ndef main(config):\n    return app_main(config)\n'
        for period, expected in [("day",0.04),("week",-0.025)]:
            run_harness(directory, "main-"+period, entrypoint, config={"period":period}, mock_cache_set='def mock_cache_set(key, value, ttl_seconds):\n    saved = json.decode(value)\n    if saved["cards"][0]["change"] != '+str(expected)+':\n        fail("Change period did not reach the data loader")\n')
        run_harness(directory, "main-topic-exclusions", entrypoint, config={"include_politics":"false","include_sports":"false","include_other":"false"}, mock_cache_set='''def mock_cache_set(key, value, ttl_seconds):
    cards = json.decode(value)["cards"]
    if [c["id"] for c in cards] != ["2"] or "politics,sports,other" not in key:
        fail("Topic exclusions did not reach selection/cache scope")
''')
        off = {"include_"+name:"false" for name in ["politics","sports","crypto","finance","world","tech","culture","weather","other"]}
        run_harness(directory, "main-all-topics-off", entrypoint, config=off, mock_get='''def mock_get(url, params, ttl_seconds):
    fail("All topics off must not make an HTTP request")
''')
        run_harness(directory, "main-breaking-week", entrypoint, config={"feed":"breaking","period":"week"}, prefix=loader_prefix, mock_get='''def mock_get(url, params, ttl_seconds):
    if "/markets" in url:
        if params["order"] != "oneDayPriceChange":
            fail("Breaking must request daily movers")
        return struct(status_code=200, body=up_body if params["ascending"] == "false" else down_body)
    return struct(status_code=200, body=mock_body)
''', mock_cache_set='''def mock_cache_set(key, value, ttl_seconds):
    cards = json.decode(value)["cards"]
    if cards[0]["id"] != "2" or cards[0]["change"] != 0.025 or "breaking:week" not in key:
        fail("Breaking or weekly setting was ignored")
''')
        for name, body, status in [("rate-limit", "{}", 429), ("server-error", "{}", 503), ("malformed-json", "<html>Unavailable</html>", 200), ("wrong-shape", "{}", 200)]:
            run_harness(directory, name, '\ndef main(config):\n    pool, stale = load_pool("trending", [], "day", 1000)\n    if pool != None or stale:\n        fail("Expected unavailable")\n    return message_screen("Data unavailable")\n', body=body, status=status)
        cached = dict(at=900, cards=[dict(id="1", title="Cached", favorite="Yes", price=0.6, change=0.02, day_change=0.02, volume=1, series="")])
        run_harness(directory, "fresh-cache", '\ndef main(config):\n    pool, stale = load_pool("trending", [], "day", 1000)\n    if len(pool) != 1 or stale:\n        fail("Expected fresh cache without HTTP")\n    return message_screen("Cache passed")\n', body="bad", status=503, saved=cached)
        cached["at"] = 500
        run_harness(directory, "stale-cache", '\ndef main(config):\n    pool, stale = load_pool("trending", [], "day", 1000)\n    if len(pool) != 1 or not stale:\n        fail("Expected stale cache")\n    return message_screen("Stale passed")\n', status=503, saved=cached)
        cached["at"] = -1000
        run_harness(directory, "expired-cache", '\ndef main(config):\n    pool, stale = load_pool("trending", [], "day", 1000)\n    if pool != None or stale:\n        fail("Expired cache must not display")\n    return message_screen("Expired passed")\n', status=503, saved=cached)
        run_harness(directory, "empty-feed", '\ndef main(config):\n    pool, stale = load_pool("trending", [], "day", 1000)\n    if pool != [] or stale:\n        fail("Successful empty data must replace older data")\n    return message_screen("No markets")\n', body="[]", saved=cached)
        for name, fetched_at in [("fresh-expired-card", 900), ("stale-expired-card", 500)]:
            saved = dict(at=fetched_at, cards=[dict(id="expired", title="Finished race", favorite="Alice Smith", price=0.64, change=0.04, day_change=0.04, volume=10000, series="", endDate="2020-01-01T00:00:00Z")])
            run_harness(directory, name, '\ndef main(config):\n    cards, stale = load_pool("trending", [], "day", 1000)\n    if cards:\n        fail("Expired market escaped cache recheck")\n    return message_screen("No expired cards")\n', status=503, saved=saved)
        preview = run_harness(directory, "preview", '\ndef main(config):\n    cards = [make_card(TEST_EVENTS[i], "day") for i in [1,0]]\n    return render.Root(child=render.Sequence(children=[card_widget(c,False) for c in cards]), delay=FRAME_DELAY, max_age=300, show_full_animation=True)\n')
        variants = run_harness(directory, "display-states", '\ndef main(config):\n    cards = [dict(make_card(TEST_EVENTS[0], "week"), price=1.0, change=-1.0), dict(make_card(TEST_EVENTS[0], "day"), change=None)]\n    return render.Root(child=render.Sequence(children=[card_widget(cards[0],True),card_widget(cards[1],False)]), delay=FRAME_DELAY, max_age=300, show_full_animation=True)\n')
        names = run_harness(directory, "name-pages", '\ndef main(config):\n    card = dict(make_card(TEST_EVENTS[0], "day"), title="Race", favorite="Alexandria Ocasio-Cortez and Several Additional Candidate Names")\n    return render.Root(child=render.Sequence(children=[card_widget(card,False),card_widget(card,True)]), delay=FRAME_DELAY, max_age=300, show_full_animation=True)\n')
        output = args.output or directory / "artifacts"
        output.mkdir(parents=True, exist_ok=True)
        (output / "preview.webp").write_bytes(preview.read_bytes())
        (output / "display-states.webp").write_bytes(variants.read_bytes())
        (output / "name-pages.webp").write_bytes(names.read_bytes())
        print("Preview:", output / "preview.webp")
        export_preview(output)


def export_preview(output):
    """Required image assertions and GIF/PNG proofs."""
    image = Image.open(output / "preview.webp")
    frames, durations, times = [], [], []
    elapsed = 0
    for index in range(image.n_frames):
        image.seek(index)
        image.load()  # WebP timestamps/durations become current only after load.
        times.append(elapsed)
        frames.append(image.convert("RGB"))
        duration = image.info["duration"]
        durations.append(duration)
        elapsed += duration
    intervals = [13800, 7500]
    assert image.size == (64, 32) and elapsed == sum(intervals), (image.size, elapsed)
    start = 0
    for interval in intervals:
        selected = [f for f, t in zip(frames, times) if start <= t < start + interval]
        baseline = selected[0].crop((0, 8, 64, 32))
        assert all(ImageChops.difference(baseline, f.crop((0, 8, 64, 32))).getbbox() is None for f in selected), "Numbers moved during title scroll"
        end = max(i for i, t in enumerate(times) if t < start + interval)
        hold = max(i for i, t in enumerate(times) if t <= start + interval - 1000)
        assert ImageChops.difference(frames[end].crop((0,0,64,8)), frames[hold].crop((0,0,64,8))).getbbox() is None, "Title ending needs a one-second reading hold"
        start += interval
    assert any(ImageChops.difference(frames[0].crop((0, 0, 64, 8)), f.crop((0, 0, 64, 8))).getbbox() for f, t in zip(frames, times) if t < intervals[0]), "Title must scroll"
    proof = Image.new("RGB", (800, 448), "#151b27")
    draw = ImageDraw.Draw(proof)
    for column in range(2):
        for row in range(2):
            target = (intervals[0] if column else 0) + row * (intervals[column] - 1000)
            index = max(i for i, t in enumerate(times) if t <= target)
            frame = frames[index].resize((384, 192), Image.Resampling.NEAREST)
            x, y = 8 + column * 396, 8 + row * 224
            proof.paste(frame, (x, y))
            draw.text((x, y + 198), f"{target / 1000:.1f}s", fill="white")
            if row == 0:
                frame.save(output / f"card-{column + 1}.png")
    proof.save(output / "preview-contact-sheet.png")
    enlarged = [f.resize((512, 256), Image.Resampling.NEAREST) for f in frames]
    enlarged[0].save(output / "preview.gif", save_all=True, append_images=enlarged[1:], duration=durations, loop=0, optimize=False)
    image = Image.open(output / "name-pages.webp")
    samples = []
    elapsed = 0
    for index in range(image.n_frames):
        image.seek(index)
        image.load()
        assert image.size == (64,32)
        samples.append((elapsed, image.convert("RGB")))
        elapsed += image.info["duration"]
    assert elapsed == 21000, "All three name pages need reading time on each card"
    for start in [0, 10500]:
        group = [f for t,f in samples if start <= t < start+10500]
        fixed = group[0].crop((0,19,64,32))
        assert all(ImageChops.difference(fixed,f.crop((0,19,64,32))).getbbox() is None for f in group), "Name paging moved metrics"
        assert len({f.crop((0,8,64,19)).tobytes() for f in group}) == 3, "Every favorite page must appear"
    assert ImageChops.difference(samples[0][1].crop((0,19,64,32)), next(f for t,f in samples if t == 10500).crop((0,19,64,32))).getbbox(), "OLD indicator must remain visible"
    print("PASS: three complete favorite pages, stationary metrics, visible OLD indicator")
    print("PASS: 64x32, 21.3 seconds, complete title scrolls, end holds, stationary metrics; PNG/GIF proofs exported")


if __name__ == "__main__":
    main()
