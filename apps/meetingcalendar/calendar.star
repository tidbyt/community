"""Bounded RFC 5545 calendar ingestion; errors never contain calendar content."""

load("time.star", "time")

_MAX_BYTES = 10000000
_MAX_SCAN = 100000
_MAX_OCCURRENCES = 2000
_DAY = 86400
_WEEKDAYS = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}
_WINDOWS = {
    "UTC": "UTC",
    "Dateline Standard Time": "Etc/GMT+12",
    "UTC-11": "Etc/GMT+11",
    "Hawaiian Standard Time": "Pacific/Honolulu",
    "Alaskan Standard Time": "America/Anchorage",
    "Pacific Standard Time": "America/Los_Angeles",
    "US Mountain Standard Time": "America/Phoenix",
    "Mountain Standard Time": "America/Denver",
    "Central Standard Time": "America/Chicago",
    "Eastern Standard Time": "America/New_York",
    "US Eastern Standard Time": "America/Indianapolis",
    "Atlantic Standard Time": "America/Halifax",
    "Newfoundland Standard Time": "America/St_Johns",
    "SA Pacific Standard Time": "America/Bogota",
    "Argentina Standard Time": "America/Argentina/Buenos_Aires",
    "E. South America Standard Time": "America/Sao_Paulo",
    "GMT Standard Time": "Europe/London",
    "Greenwich Standard Time": "Atlantic/Reykjavik",
    "W. Europe Standard Time": "Europe/Berlin",
    "Central Europe Standard Time": "Europe/Budapest",
    "Romance Standard Time": "Europe/Paris",
    "Central European Standard Time": "Europe/Warsaw",
    "GTB Standard Time": "Europe/Bucharest",
    "FLE Standard Time": "Europe/Kyiv",
    "Israel Standard Time": "Asia/Jerusalem",
    "South Africa Standard Time": "Africa/Johannesburg",
    "Turkey Standard Time": "Europe/Istanbul",
    "Russian Standard Time": "Europe/Moscow",
    "Arabian Standard Time": "Asia/Dubai",
    "India Standard Time": "Asia/Kolkata",
    "China Standard Time": "Asia/Shanghai",
    "Singapore Standard Time": "Asia/Singapore",
    "Tokyo Standard Time": "Asia/Tokyo",
    "Korea Standard Time": "Asia/Seoul",
    "W. Australia Standard Time": "Australia/Perth",
    "Cen. Australia Standard Time": "Australia/Adelaide",
    "AUS Central Standard Time": "Australia/Darwin",
    "E. Australia Standard Time": "Australia/Brisbane",
    "AUS Eastern Standard Time": "Australia/Sydney",
    "Tasmania Standard Time": "Australia/Hobart",
    "New Zealand Standard Time": "Pacific/Auckland",
}

def _err(message):
    return {"error": message}

def resolve_timezone(name):
    name = _WINDOWS.get(name, name)

    # Apple commonly prefixes IANA identifiers with a tzdb vendor/version path.
    if name.startswith("/"):
        parts = name.split("/")
        for i in range(1, len(parts)):
            candidate = "/".join(parts[i:])
            if time.is_valid_timezone(candidate):
                return {"timezone": candidate, "error": ""}
    if not name or name == "Local" or not time.is_valid_timezone(name):
        return {"timezone": "", "error": "Unknown calendar timezone"}
    return {"timezone": name, "error": ""}

def local_day_bounds(now_unix, timezone):
    zone = resolve_timezone(timezone)
    if zone["error"]:
        return dict(zone, start = 0, end = 0)
    d = time.from_timestamp(now_unix).in_location(zone["timezone"])
    return {
        "start": time.time(year = d.year, month = d.month, day = d.day, location = zone["timezone"]).unix,
        "end": time.time(year = d.year, month = d.month, day = d.day + 1, location = zone["timezone"]).unix,
        "error": "",
    }

def _number(value, low, high):
    digits = value[1:] if value.startswith("-") or value.startswith("+") else value
    if not digits or not all([c in "0123456789" for c in digits.elems()]):
        return None
    number = int(value)
    return number if low <= number and number <= high else None

def _wall(year, month, day):
    return time.time(year = year, month = month, day = day, location = "UTC").unix

def _parts(wall):
    return time.from_timestamp(wall).in_location("UTC")

def _month_days(year, month):
    return (_wall(year, month + 1, 1) - _wall(year, month, 1)) // _DAY

def _weekday(wall):
    return (wall // _DAY + 3) % 7

def _date(value):
    """Parse a validated wall clock without letting Go normalize malformed input."""
    zulu = value.endswith("Z")
    value = value[:-1] if zulu else value
    if len(value) not in [8, 15] or (len(value) == 15 and value[8] != "T"):
        return _err("Invalid calendar date")
    y, m, d = _number(value[:4], 1, 9998), _number(value[4:6], 1, 12), _number(value[6:8], 1, 31)
    if y == None or m == None or d == None or d > _month_days(y, m):
        return _err("Invalid calendar date")
    h, minute, sec = 0, 0, 0
    if len(value) == 15:
        h, minute, sec = _number(value[9:11], 0, 23), _number(value[11:13], 0, 59), _number(value[13:15], 0, 59)
        if h == None or minute == None or sec == None:
            return _err("Invalid calendar date")
    elif zulu:
        return _err("Invalid calendar date")
    return {"wall": _wall(y, m, d) + h * 3600 + minute * 60 + sec, "date": len(value) == 8, "zulu": zulu, "error": ""}

def _unescape(text):
    output = []
    escaped = False
    for c in text.elems():
        if escaped:
            output.append("\n" if c in ["n", "N"] else c)
            escaped = False
        elif c == "\\":
            escaped = True
        else:
            output.append(c)
    if escaped:
        output.append("\\")
    return "".join(output)

def _property(line):
    # Locate separators outside quoted parameter values (TZID may contain ':').
    quoted, colon = False, -1
    for i in range(len(line)):
        if line[i] == '"':
            quoted = not quoted
        elif line[i] == ":" and not quoted:
            colon = i
            break
    if colon < 1 or quoted:
        return _err("Malformed calendar content")
    fields, field, quoted = [], "", False
    for c in line[:colon].elems():
        if c == '"':
            quoted = not quoted
        if c == ";" and not quoted:
            fields.append(field)
            field = ""
        else:
            field += c
    fields.append(field)
    params = {}
    for param in fields[1:]:
        pair = param.split("=", 1)
        if len(pair) != 2:
            return _err("Malformed calendar parameter")
        if pair[0].upper() in params:
            return _err("Duplicate calendar parameter")
        params[pair[0].upper()] = pair[1].strip('"')
    return {"name": fields[0].upper(), "params": params, "value": line[colon + 1:], "error": ""}

def _read(source):
    if len(source) > _MAX_BYTES:
        return _err("Calendar exceeds size limit")
    unfolded = []
    for line in source.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if line.startswith(" ") or line.startswith("\t"):
            if not unfolded:
                return _err("Malformed calendar content")
            unfolded[-1] += line[1:]
        elif line:
            unfolded.append(line)
        if len(unfolded) > _MAX_SCAN:
            return _err("Calendar exceeds processing limit")
    stack, events, zones, event, zone, observance = [], [], [], None, None, None
    seen_calendar = False
    for line in unfolded:
        prop = _property(line)
        if prop.get("error"):
            return prop
        name, value = prop["name"], prop["value"]
        if name == "BEGIN":
            value = value.upper()
            parents = {"VCALENDAR": [""], "VEVENT": ["VCALENDAR"], "VTIMEZONE": ["VCALENDAR"], "STANDARD": ["VTIMEZONE"], "DAYLIGHT": ["VTIMEZONE"], "VALARM": ["VEVENT", "VTODO"], "VTODO": ["VCALENDAR"], "VJOURNAL": ["VCALENDAR"], "VFREEBUSY": ["VCALENDAR"]}
            parent = stack[-1] if stack else ""
            if parent not in parents.get(value, []):
                return _err("Malformed calendar nesting")
            if value == "VCALENDAR":
                if seen_calendar:
                    return _err("Multiple calendar containers")
                seen_calendar = True
            stack.append(value)
            if len(stack) > 8:
                return _err("Malformed calendar nesting")
            if value == "VEVENT":
                event = {}
            elif value == "VTIMEZONE":
                zone = {"observances": []}
            elif value in ["STANDARD", "DAYLIGHT"] and zone != None:
                observance = {}
        elif name == "END":
            if not stack or stack[-1] != value.upper():
                return _err("Malformed calendar nesting")
            if value.upper() == "VEVENT":
                events.append(event)
                event = None
            elif value.upper() == "VTIMEZONE":
                zones.append(zone)
                zone = None
            elif value.upper() in ["STANDARD", "DAYLIGHT"] and observance != None:
                zone["observances"].append(observance)
                observance = None
            stack.pop()
        elif stack:
            target = event if stack[-1] == "VEVENT" else observance if stack[-1] in ["STANDARD", "DAYLIGHT"] else zone if stack[-1] == "VTIMEZONE" else None
            if target != None:
                if name not in target:
                    target[name] = []
                target[name].append(prop)
        else:
            return _err("Calendar property outside container")
    if stack or not unfolded or unfolded[0].upper() != "BEGIN:VCALENDAR" or unfolded[-1].upper() != "END:VCALENDAR":
        return _err("Incomplete calendar subscription")
    return {"events": events, "zones": zones, "error": ""}

def _one(props, key, default = ""):
    return props[key][0]["value"] if props.get(key) else default

def _offset(value):
    if len(value) not in [5, 7] or value[0] not in ["+", "-"]:
        return None
    hours, minutes = _number(value[1:3], 0, 23), _number(value[3:5], 0, 59)
    seconds = _number(value[5:7], 0, 59) if len(value) == 7 else 0
    if hours == None or minutes == None or seconds == None:
        return None
    return (hours * 3600 + minutes * 60 + seconds) * (-1 if value[0] == "-" else 1)

def _rule(value):
    rule = {}
    for item in value.upper().split(";"):
        pair = item.split("=", 1)
        if len(pair) != 2 or pair[0] in rule:
            return _err("Invalid recurrence rule")
        rule[pair[0]] = pair[1]
    if rule.get("FREQ") not in ["DAILY", "WEEKLY", "MONTHLY", "YEARLY"]:
        return _err("Unsupported recurrence frequency")
    for key in rule:
        if key not in ["FREQ", "INTERVAL", "COUNT", "UNTIL", "BYDAY", "BYMONTHDAY", "BYMONTH", "BYSETPOS", "WKST"]:
            return _err("Unsupported recurrence rule")
    interval = _number(rule.get("INTERVAL", "1"), 1, 10000)
    count = _number(rule.get("COUNT", "1"), 1, 100000000)
    if interval == None or count == None or ("COUNT" in rule and "UNTIL" in rule):
        return _err("Invalid recurrence rule")
    rule["INTERVAL"] = interval
    rule["COUNT"] = count if "COUNT" in rule else None
    if rule.get("WKST", "MO") not in _WEEKDAYS:
        return _err("Invalid recurrence weekday")
    rule["WKST"] = _WEEKDAYS[rule.get("WKST", "MO")]
    for key, bound in [("BYMONTHDAY", 31), ("BYMONTH", 12), ("BYSETPOS", 366)]:
        values = []
        for part in rule.get(key, "").split(",") if rule.get(key) else []:
            number = _number(part, 1 if key == "BYMONTH" else -bound, bound)
            if number == None or number == 0:
                return _err("Invalid recurrence selector")
            values.append(number)
        rule[key] = values
    days = []
    for part in rule.get("BYDAY", "").split(",") if rule.get("BYDAY") else []:
        day = part[-2:]
        ordinal = _number(part[:-2], -53, 53) if len(part) > 2 else None
        if day not in _WEEKDAYS or (len(part) > 2 and (ordinal == None or ordinal == 0)):
            return _err("Invalid recurrence weekday")
        if ordinal != None and rule["FREQ"] not in ["MONTHLY", "YEARLY"]:
            return _err("Unsupported recurrence weekday")
        days.append((_WEEKDAYS[day], ordinal))
    rule["BYDAY"] = days
    if rule["FREQ"] == "WEEKLY" and rule["BYMONTHDAY"]:
        return _err("Invalid weekly recurrence")
    if rule["BYSETPOS"] and not (days or rule["BYMONTHDAY"] or rule["BYMONTH"]):
        return _err("Invalid positional recurrence")
    rule["error"] = ""
    return rule

def _period(rule, initial, index):
    d, n = _parts(initial), index * rule["INTERVAL"]
    if rule["FREQ"] == "DAILY":
        start = initial // _DAY * _DAY + n * _DAY
        return (start, start + _DAY)
    if rule["FREQ"] == "WEEKLY":
        start = initial // _DAY * _DAY - ((_weekday(initial) - rule["WKST"]) % 7) * _DAY + n * 7 * _DAY
        return (start, start + 7 * _DAY)
    if rule["FREQ"] == "MONTHLY":
        start = _wall(d.year, d.month + n, 1)
        end = _wall(d.year, d.month + n + 1, 1)
        return (start, end)
    return (_wall(d.year + n, 1, 1), _wall(d.year + n + 1, 1, 1))

def _candidates(rule, initial, start, end):
    original, selected = _parts(initial), []
    for date in range(start, end, _DAY):
        d = _parts(date)
        if rule["BYMONTH"] and d.month not in rule["BYMONTH"]:
            continue
        if rule["BYMONTHDAY"] and d.day not in rule["BYMONTHDAY"] and d.day - _month_days(d.year, d.month) - 1 not in rule["BYMONTHDAY"]:
            continue
        if rule["BYDAY"]:
            matched = False
            for weekday, ordinal in rule["BYDAY"]:
                if weekday != _weekday(date):
                    continue
                if ordinal == None:
                    matched = True
                else:
                    # YEARLY ordinal BYDAY is relative to year unless BYMONTH is specified.
                    a, b = (_wall(d.year, 1, 1), _wall(d.year + 1, 1, 1)) if rule["FREQ"] == "YEARLY" and not rule["BYMONTH"] else (_wall(d.year, d.month, 1), _wall(d.year, d.month + 1, 1))
                    if ordinal == (date - a) // (7 * _DAY) + 1 or ordinal == -((b - _DAY - date) // (7 * _DAY) + 1):
                        matched = True
            if not matched:
                continue
        if rule["FREQ"] == "WEEKLY" and not rule["BYDAY"] and _weekday(date) != _weekday(initial):
            continue
        if rule["FREQ"] in ["MONTHLY", "YEARLY"] and not rule["BYDAY"] and not rule["BYMONTHDAY"] and d.day != original.day:
            continue
        if rule["FREQ"] == "YEARLY" and not rule["BYMONTH"] and not rule["BYDAY"] and not rule["BYMONTHDAY"] and d.month != original.month:
            continue
        selected.append(date + initial % _DAY)
    if rule["BYSETPOS"]:
        selected = sorted({selected[p - 1 if p > 0 else p]: True for p in rule["BYSETPOS"] if -len(selected) <= p and p <= len(selected)}.keys())
    return selected

def _zones(raw_zones):
    result = {}
    for raw in raw_zones:
        if len(raw.get("TZID", [])) != 1:
            return _err("Invalid calendar timezone identifier")
        name = _one(raw, "TZID")
        if not name or name in result:
            return _err("Invalid calendar timezone")

        # Embedded observances take precedence, including Windows/vendor identifiers.
        observances = []
        for raw_obs in raw["observances"]:
            if any([len(raw_obs.get(key, [])) > 1 for key in ["DTSTART", "TZOFFSETFROM", "TZOFFSETTO", "RRULE"]]) or raw_obs.get("EXDATE") or raw_obs.get("EXRULE"):
                return _err("Unsupported calendar timezone rule")
            start = _date(_one(raw_obs, "DTSTART"))
            before, after = _offset(_one(raw_obs, "TZOFFSETFROM")), _offset(_one(raw_obs, "TZOFFSETTO"))
            if start.get("error") or start["date"] or start["zulu"] or before == None or after == None:
                return _err("Invalid calendar timezone")
            rule = _rule(_one(raw_obs, "RRULE")) if raw_obs.get("RRULE") else None
            if rule and (rule.get("error") or rule["FREQ"] != "YEARLY" or rule["COUNT"] != None):
                return _err("Unsupported calendar timezone rule")
            dates = []
            for prop in raw_obs.get("RDATE", []):
                for text in prop["value"].split(","):
                    date = _date(text)
                    if date.get("error") or date["date"] or date["zulu"]:
                        return _err("Invalid calendar timezone date")
                    dates.append(date["wall"])
            until = None
            if rule and rule.get("UNTIL"):
                until = _date(rule["UNTIL"])
                if until.get("error"):
                    return until
                until = until["wall"] if until["zulu"] else until["wall"] - before
                if until < start["wall"] - before:
                    return _err("Invalid calendar timezone rule")
            observances.append({"start": start["wall"], "before": before, "after": after, "rule": rule, "dates": dates, "until": until})
        if not observances:
            return _err("Missing calendar timezone rules")
        result[name] = {"observances": observances, "transitions": {}}
    return {"zones": result, "error": ""}

def _transitions(observances, year):
    transitions = []
    for obs in observances:
        dates = [obs["start"]] + obs["dates"]
        if obs["rule"]:
            first_year = _parts(obs["start"]).year
            interval = obs["rule"]["INTERVAL"]
            target_year = min(year, _parts(obs["until"]).year) if obs["until"] != None else year
            aligned = first_year + max(0, (target_year - first_year) // interval) * interval
            for y in [aligned - interval, aligned, aligned + interval]:
                if y < first_year:
                    continue
                dates.extend(_candidates(obs["rule"], obs["start"], _wall(y, 1, 1), _wall(y + 1, 1, 1)))
        for date in dates:
            at = date - obs["before"]
            if date >= obs["start"] and (obs["until"] == None or at <= obs["until"]):
                transitions.append((at, obs["before"], obs["after"]))
    return sorted(transitions)

def _epoch(wall, zone, zones):
    """First occurrence in folds; RFC's pre-gap offset for explicit gap dates."""
    if zone in ["UTC", "Etc/UTC", "Etc/GMT", "GMT"]:
        return {"unix": wall, "gap": False}
    d = _parts(wall)
    if zone in zones:
        custom = zones[zone]
        if d.year not in custom["transitions"]:
            custom["transitions"][d.year] = _transitions(custom["observances"], d.year)
        transitions = custom["transitions"][d.year]
        if not transitions:
            return _err("Unresolved calendar timezone")
        offsets = {obs["before"]: True for obs in custom["observances"]}
        offsets.update({obs["after"]: True for obs in custom["observances"]})
        candidates = []
        for offset in offsets:
            unix = wall - offset
            actual = transitions[0][1]
            for at, before, after in transitions:
                if at > unix:
                    break
                actual = after
            if actual == offset:
                candidates.append(unix)
        if candidates:
            return {"unix": min(candidates), "gap": False}
        for at, before, after in transitions:
            if before < after and at + before <= wall and wall < at + after:
                return {"unix": wall - before, "gap": True}
        return {"unix": wall, "error": "Unresolved calendar timezone"}
    stamp = time.time(year = d.year, month = d.month, day = d.day, hour = d.hour, minute = d.minute, second = d.second, location = zone).unix
    offsets = {}
    for probe in [stamp - _DAY, stamp, stamp + _DAY]:
        local = time.from_timestamp(probe).in_location(zone)
        local_wall = _wall(local.year, local.month, local.day) + local.hour * 3600 + local.minute * 60 + local.second
        offsets[local_wall - probe] = True
    candidates = []
    for offset in offsets:
        probe = wall - offset
        local = time.from_timestamp(probe).in_location(zone)
        if (local.year, local.month, local.day, local.hour, local.minute, local.second) == (d.year, d.month, d.day, d.hour, d.minute, d.second):
            candidates.append(probe)
    return {"unix": min(candidates) if candidates else wall - min(offsets.keys()), "gap": not candidates}

def _datetime(prop, timezone, zones):
    date = _date(prop["value"])
    if date.get("error"):
        return date
    kind = prop["params"].get("VALUE", "DATE" if date["date"] else "DATE-TIME")
    if (kind == "DATE") != date["date"] or kind not in ["DATE", "DATE-TIME"]:
        return _err("Invalid calendar date type")
    if prop["params"].get("TZID") and (date["zulu"] or date["date"]):
        return _err("Invalid calendar timezone parameter")
    zone = "UTC" if date["zulu"] else prop["params"].get("TZID", timezone)
    if zone not in zones:
        resolved = resolve_timezone(zone)
        if resolved["error"]:
            return resolved
        zone = resolved["timezone"]
    date["zone"] = zone
    stamp = _epoch(date["wall"], zone, zones)
    if stamp.get("error"):
        return stamp
    date["unix"] = stamp["unix"]
    return date

def _duration(value):
    if not value.startswith("P") or value.endswith("T") or ("W" in value and ("D" in value or "T" in value)):
        return None
    total, digits, clock_part, last = 0, "", False, 0
    for c in value[1:].elems():
        if c in "0123456789":
            digits += c
        elif c == "T" and not clock_part and not digits:
            clock_part = True
        else:
            order = {"W": 1, "D": 2, "H": 3, "M": 4, "S": 5}.get(c, 0)
            if not digits or order <= last or (c in ["H", "M", "S"]) != clock_part:
                return None
            number = _number(digits, 0, 315360000)
            if number == None:
                return None
            total += number * {"W": 604800, "D": 86400, "H": 3600, "M": 60, "S": 1}[c]
            digits, last = "", order
    return total if last and not digits else None

def _event(raw, timezone, zones):
    if raw.get("EXRULE"):
        return _err("Unsupported recurrence exclusion rule")
    for name in ["UID", "DTSTART", "DTEND", "DURATION", "RRULE", "RECURRENCE-ID"]:
        if len(raw.get(name, [])) > 1:
            return _err("Duplicate calendar property")
    if not _one(raw, "UID"):
        return _err("Calendar event missing identifier")
    if _one(raw, "STATUS").upper() == "CANCELLED" and not raw.get("DTSTART"):
        return {"cancelled": True, "uid": _one(raw, "UID"), "raw": raw, "error": ""}
    if not raw.get("DTSTART"):
        return _err("Calendar event missing start")
    start = _datetime(raw["DTSTART"][0], timezone, zones)
    if start.get("error"):
        return start
    duration = 0
    if raw.get("DTEND") and raw.get("DURATION"):
        return _err("Conflicting calendar duration")
    nominal_days, exact_seconds = 0, 0
    if raw.get("DTEND"):
        end = _datetime(raw["DTEND"][0], timezone, zones)
        if end.get("error"):
            return end
        if end["date"] != start["date"]:
            return _err("Conflicting calendar date types")
        duration = end["unix"] - start["unix"]
        exact_seconds = duration
    elif raw.get("DURATION"):
        duration = _duration(_one(raw, "DURATION"))
        if duration == None:
            return _err("Invalid calendar duration")

        # Weeks/days are nominal across DST; hours/minutes/seconds are exact.
        text = _one(raw, "DURATION")
        date_duration = text.split("T")[0]
        nominal = _duration(date_duration) if date_duration != "P" else 0
        nominal_days = nominal // _DAY if nominal != None else 0
        exact_seconds = duration - nominal_days * _DAY
    if duration < 0:
        return _err("Invalid calendar duration")
    return {
        "uid": _one(raw, "UID"),
        "start": start,
        "duration": duration,
        "nominal_days": nominal_days,
        "exact_seconds": exact_seconds,
        "cancelled": _one(raw, "STATUS").upper() == "CANCELLED",
        "raw": raw,
        "error": "",
    }

def _period_index(rule, initial, lower):
    a, b = _parts(initial), _parts(lower)
    n = (lower - initial) // _DAY if rule["FREQ"] == "DAILY" else (lower - initial) // (7 * _DAY) if rule["FREQ"] == "WEEKLY" else (b.year - a.year) * 12 + b.month - a.month if rule["FREQ"] == "MONTHLY" else b.year - a.year
    return max(0, n // rule["INTERVAL"] - 1)

def _occurrences(event, lower, upper, timezone, zones, budget):
    start, raw = event["start"], event["raw"]
    stamps = {start["unix"]: start["wall"]}
    if raw.get("RRULE"):
        rule = _rule(_one(raw, "RRULE"))
        if rule.get("error"):
            return rule
        until = None
        if rule.get("UNTIL"):
            parsed = _date(rule["UNTIL"])
            if parsed.get("error"):
                return parsed
            if parsed["date"] != start["date"]:
                return _err("Invalid recurrence end date")
            until = parsed["wall"] if parsed["zulu"] else _epoch(parsed["wall"], start["zone"], zones)["unix"]
        count = 1
        begin = 0 if rule["COUNT"] != None else _period_index(rule, start["wall"], lower - event["duration"] - 2 * _DAY)
        finished = False
        for index in range(begin, begin + _MAX_SCAN):
            a, b = _period(rule, start["wall"], index)
            if a > upper + 2 * _DAY or (rule["COUNT"] != None and count >= rule["COUNT"]):
                finished = True
                break
            budget["scans"] += (b - a) // _DAY
            if budget["scans"] > _MAX_SCAN:
                return _err("Calendar exceeds recurrence limit")
            for wall in _candidates(rule, start["wall"], a, b):
                if wall <= start["wall"]:
                    continue
                stamp = _epoch(wall, start["zone"], zones)
                if stamp.get("error"):
                    return stamp
                if stamp["gap"]:
                    continue  # RFC 5545: generated nonexistent local times are ignored, not counted.
                unix = stamp["unix"]
                if until != None and unix > until:
                    finished = True
                    break
                if rule["COUNT"] != None and count >= rule["COUNT"]:
                    finished = True
                    break
                count += 1
                if lower - event["duration"] - _DAY <= unix and unix < upper:
                    stamps[unix] = wall
                    if len(stamps) > _MAX_OCCURRENCES:
                        return _err("Calendar exceeds occurrence limit")
            if finished:
                break
        if not finished:
            return _err("Calendar exceeds recurrence limit")
    for prop in raw.get("RDATE", []):
        if prop["params"].get("VALUE") == "PERIOD":
            return _err("Unsupported recurrence period")
        for value in prop["value"].split(","):
            date = _datetime(dict(prop, value = value), timezone, zones)
            if date.get("error"):
                return date
            if date["date"] != start["date"]:
                return _err("Conflicting recurrence date types")
            stamps[date["unix"]] = date["wall"]
    for prop in raw.get("EXDATE", []):
        for value in prop["value"].split(","):
            date = _datetime(dict(prop, value = value), timezone, zones)
            if date.get("error"):
                return date
            if date["date"] != start["date"]:
                return _err("Conflicting recurrence date types")
            stamps.pop(date["unix"], None)
    if len(stamps) > _MAX_OCCURRENCES:
        return _err("Calendar exceeds occurrence limit")
    return {"stamps": stamps, "error": ""}

def _normalized(event, unix, wall, occurrence, zones):
    raw = event["raw"]
    end = unix + event["exact_seconds"]
    if event["nominal_days"]:
        final = _epoch(wall + event["nominal_days"] * _DAY, event["start"]["zone"], zones)
        if final.get("error"):
            return final
        end = final["unix"] + event["exact_seconds"]
    return {
        "uid": event["uid"],
        "occurrenceId": event["uid"] + ":" + str(occurrence),
        "title": _unescape(_one(raw, "SUMMARY", "Untitled event")),
        "start": unix,
        "end": end,
        "busy": _one(raw, "TRANSP", "OPAQUE").upper() != "TRANSPARENT",
        "url": _unescape(_one(raw, "URL")),
        "location": _unescape(_one(raw, "LOCATION")),
        "description": _unescape(_one(raw, "DESCRIPTION")),
        "conference": " ".join([p["value"] for k in ["CONFERENCE", "X-GOOGLE-CONFERENCE", "X-MICROSOFT-SKYPETEAMSMEETINGURL", "X-MICROSOFT-SKYPETEAMS-PROPERTIES", "X-APPLE-STRUCTURED-LOCATION"] for p in raw.get(k, [])]),
    }

def parse_calendar(source, start_unix, end_unix, timezone):
    """Return timed events intersecting [start_unix,end_unix), or a safe error."""
    zone = resolve_timezone(timezone)
    if zone["error"]:
        return {"events": [], "error": zone["error"]}
    parsed = _read(source)
    if parsed.get("error"):
        return {"events": [], "error": parsed["error"]}
    zones = _zones(parsed["zones"])
    if zones.get("error"):
        return {"events": [], "error": zones["error"]}
    return _expand(parsed["events"], start_unix, end_unix, zone["timezone"], zones["zones"])

def _expand(raw_events, lower, upper, timezone, zones):
    masters, overrides, output, budget = {}, {}, [], {"scans": 0}
    for raw in raw_events:
        if any([p["params"].get("RANGE") for p in raw.get("RECURRENCE-ID", [])]):
            return {"events": [], "error": "Unsupported recurring range edit"}
        event = _event(raw, timezone, zones)
        if event.get("error"):
            return {"events": [], "error": event["error"]}
        uid = event["uid"]
        if raw.get("RECURRENCE-ID"):
            original = _datetime(raw["RECURRENCE-ID"][0], timezone, zones)
            if original.get("error"):
                return {"events": [], "error": original["error"]}
            key = (uid, original["unix"])
            if key in overrides:
                return {"events": [], "error": "Duplicate recurring exception"}
            event["recurrence_date"] = original["date"]
            overrides[key] = event
        else:
            if uid in masters:
                return {"events": [], "error": "Duplicate calendar event"}
            masters[uid] = event
    for key, event in overrides.items():
        master = masters.get(key[0])
        if master and master.get("start") and event["recurrence_date"] != master["start"]["date"]:
            return {"events": [], "error": "Conflicting recurrence identifier type"}
    for uid, event in masters.items():
        if event["cancelled"] or event["start"]["date"]:
            continue
        expanded = _occurrences(event, lower, upper, timezone, zones, budget)
        if expanded.get("error"):
            return {"events": [], "error": expanded["error"]}
        for unix, wall in expanded["stamps"].items():
            if (uid, unix) in overrides:
                continue
            item = _normalized(event, unix, wall, unix, zones)
            if item.get("error"):
                return {"events": [], "error": item["error"]}
            if item["end"] > item["start"] and item["end"] > lower and item["start"] < upper:
                output.append(item)

    # Detached overrides may move into the horizon from an occurrence outside it.
    for key, event in overrides.items():
        if event["cancelled"] or event["start"]["date"] or (key[0] in masters and masters[key[0]]["cancelled"]):
            continue
        item = _normalized(event, event["start"]["unix"], event["start"]["wall"], key[1], zones)
        if item.get("error"):
            return {"events": [], "error": item["error"]}
        if item["end"] > item["start"] and item["end"] > lower and item["start"] < upper:
            output.append(item)
    if len(output) > 10000:
        return {"events": [], "error": "Calendar exceeds event limit"}
    return {"events": sorted(output, key = _event_key), "error": ""}

def _event_key(event):
    return (event["start"], event["end"], event["title"], event["occurrenceId"])
