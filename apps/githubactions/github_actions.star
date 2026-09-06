"""
Applet: GitHub Actions
Summary: CI status for your repos
Description: Shows GitHub Actions status for your repositories at a glance. Each row is one repo, coloured green when the last run passed, red when it failed, and amber while a run is in progress. Paste a fine-grained personal access token and the app lists the repositories that token can reach so you can tick the ones to watch. Works with private repositories.
Author: nrkramer
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_API = "https://api.github.com"

# Run status is cached briefly so a build shows up quickly; the set of
# repositories a token can see changes rarely, so it is cached for an hour.
# A handful of watched repos at this rate sits far inside GitHub's 5000/hour.
RUNS_TTL = 60
REPOS_TTL = 3600

# Saturated colours: these are read from across a room on a 64x32 LED matrix,
# where the muted tones of a desktop theme disappear.
COLOR = {
    "success": "#2fbf4f",
    "failure": "#ff3b3b",
    "running": "#ffb020",
    "queued": "#ffb020",
    "cancelled": "#5a5a6e",
    "skipped": "#5a5a6e",
    "unknown": "#5a5a6e",
    "none": "#3a3a4a",
}

# GitHub reports a run as (status, conclusion). Only completed runs carry a
# conclusion, so the two have to be collapsed into one word before display.
CONCLUSION = {
    "success": "success",
    "failure": "failure",
    "timed_out": "failure",
    "startup_failure": "failure",
    "action_required": "failure",
    "cancelled": "cancelled",
    "skipped": "skipped",
    "neutral": "skipped",
    "stale": "skipped",
}

RUNNING_STATES = ["in_progress"]
QUEUED_STATES = ["queued", "waiting", "requested", "pending"]

# Worst first: the aggregate takes the first state present.
SEVERITY = ["failure", "running", "queued", "success", "cancelled", "skipped", "unknown", "none"]

# Guard rails. The display shows a handful of rows, and the settings screen
# becomes unusable if it lists hundreds of checkboxes.
MAX_REPOS = 12
PICKER_LIMIT = 60

# The header takes 7px of the 32px display, leaving four 6px rows.
VISIBLE_ROWS = 4

# tom-thumb is 4px per glyph. A row spends 3px on the status bar and 2px on
# the gap, leaving 59px -> 14 characters before text runs off the edge.
MAX_NAME = 14

# Shown in the app store listing, where no token is configured. Deliberately
# generic: this is public, so it must not leak anybody's repository names.
PREVIEW = [
    ("api-gateway", "failure"),
    ("web-frontend", "running"),
    ("mobile-app", "success"),
    ("infra", "success"),
    ("docs", "queued"),
]

def state_of(status, conclusion):
    if status in RUNNING_STATES:
        return "running"
    if status in QUEUED_STATES:
        return "queued"
    if status == "completed":
        return CONCLUSION.get(conclusion, "unknown")
    return "unknown"

def worst(states):
    for s in SEVERITY:
        if s in states:
            return s
    return "unknown"

def gh_headers(token):
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token:
        headers["Authorization"] = "Bearer %s" % token
    return headers

def toggle_id(full_name):
    """Settings key for one repository's checkbox.

    Derived from the full name so a repository always maps to the same key:
    main() rebuilds these ids from the repo list to discover what was ticked,
    and a shifting id would silently drop a selection.
    """
    safe = full_name.replace("/", "__").replace("-", "_").replace(".", "_")
    return "repo_%s" % safe

def list_accessible_repos(token):
    """Repositories this token can see, most recently pushed first."""
    if not token:
        return []

    resp = http.get(
        "%s/user/repos?per_page=100&sort=pushed&direction=desc" % GITHUB_API,
        headers = gh_headers(token),
        ttl_seconds = REPOS_TTL,
    )
    if resp.status_code != 200:
        return []

    body = resp.json()
    if type(body) != "list":
        return []

    names = []
    for repo in body:
        full = repo.get("full_name", "")
        if full:
            names.append(full)
    return names[:PICKER_LIMIT]

def parse_repos(raw):
    """Accept 'owner/repo' entries separated by commas, spaces or newlines."""
    out = []
    for chunk in raw.replace("\n", ",").replace(" ", ",").split(","):
        name = chunk.strip()
        if name and name.count("/") == 1:
            out.append(name)
    return out

def short_name(full):
    """'Acme-Corp/AcmeEngine' -> 'engine'.

    Two shortenings, in order, because 64px is unforgiving:

    1. Drop the owner, which is identical on every row in practice.
    2. Drop the owner's first word where the repo repeats it. Org repos are
       very often named after the org, and without this every row truncates to
       the same string -- 'acmeengine' and 'acmeenginec...' are different
       repositories but look identical on the display.
    """
    owner, _, repo = full.partition("/")
    name = repo.lower()

    org_word = owner.lower().replace("-", " ").replace("_", " ").replace(".", " ").split(" ")[0]
    if len(org_word) >= 4 and name.startswith(org_word) and len(name) - len(org_word) >= 3:
        name = name[len(org_word):].lstrip("-_.")

    if len(name) > MAX_NAME:
        return name[:MAX_NAME - 1] + "…"
    return name

def fetch_repo_state(repo, token):
    """Newest run for one repo, collapsed to a single state word."""
    resp = http.get(
        "%s/repos/%s/actions/runs?per_page=5" % (GITHUB_API, repo),
        headers = gh_headers(token),
        ttl_seconds = RUNS_TTL,
    )
    if resp.status_code != 200:
        return "unknown"

    runs = resp.json().get("workflow_runs", [])
    if not runs:
        return "none"

    # An in-flight run outranks the last completed one: that is the thing you
    # are actually waiting on.
    states = []
    for run in runs:
        st = state_of(run.get("status", ""), run.get("conclusion"))
        if st in ["running", "queued"]:
            return st
        states.append(st)
    return states[0]

def selected_repos(config, token):
    """Repositories ticked in the picker, plus any typed in by hand."""
    chosen = []
    for full in list_accessible_repos(token):
        if config.bool(toggle_id(full), False):
            chosen.append(full)

    # Escape hatch: repositories past the picker's limit, or reachable by the
    # token but not returned by /user/repos.
    for full in parse_repos(config.str("extra_repos", "")):
        if full not in chosen:
            chosen.append(full)

    return chosen[:MAX_REPOS]

def row_for(name, state):
    return render.Row(
        cross_align = "center",
        children = [
            render.Box(width = 3, height = 5, color = COLOR.get(state, COLOR["unknown"])),
            render.Box(width = 2, height = 1),
            render.Text(content = name, font = "tom-thumb", color = "#c8c8d8"),
        ],
    )

def message(text):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = text,
                font = "tom-thumb",
                color = "#c8c8d8",
                align = "center",
            ),
        ),
    )

def main(config):
    token = config.str("token", "")
    repos = selected_repos(config, token)

    if not token:
        rows = [(name, state) for name, state in PREVIEW]
    elif not repos:
        return message("Pick repositories in the app settings")
    else:
        rows = []
        for repo in repos:
            rows.append((short_name(repo), fetch_repo_state(repo, token)))

    if config.bool("only_problems", False):
        filtered = [r for r in rows if r[1] not in ["success", "skipped", "cancelled", "none"]]

        # Never render an empty screen: an all-green board is information.
        if filtered:
            rows = filtered
        else:
            rows = [("all green", "success")]

    aggregate = worst([state for _, state in rows])

    # Worst first, so the repo needing attention is always on screen. A
    # vertical marquee was tried here and rejected: for part of its cycle the
    # display goes blank, which is useless for something read at a glance.
    rows = sorted(rows, key = lambda r: SEVERITY.index(r[1]) if r[1] in SEVERITY else len(SEVERITY))

    hidden = len(rows) - VISIBLE_ROWS
    body = [row_for(name, state) for name, state in rows[:VISIBLE_ROWS]]

    header_children = [
        render.Box(width = 4, height = 7, color = COLOR.get(aggregate, COLOR["unknown"])),
        render.Box(width = 2, height = 1),
        render.Text(content = "ACTIONS", font = "tom-thumb", color = "#ffffff"),
    ]
    if hidden > 0:
        header_children.append(render.Box(width = 2, height = 1))
        header_children.append(
            render.Text(content = "+%d" % hidden, font = "tom-thumb", color = "#8a8a9e"),
        )

    return render.Root(
        child = render.Column(
            children = [
                render.Row(cross_align = "center", children = header_children),
                render.Box(width = 1, height = 1),
                render.Column(children = body),
            ],
        ),
    )

def repo_picker(token):
    """One checkbox per repository the token can reach.

    Re-runs when the token field changes, so the list reflects exactly what
    that token is scoped to. Nothing to type, nothing to spell wrong.
    """
    repos = list_accessible_repos(token)
    if not repos:
        return []

    fields = []
    for full in repos:
        fields.append(
            schema.Toggle(
                id = toggle_id(full),
                name = full,
                desc = "Show %s on the display." % full,
                icon = "codeBranch",
                default = False,
            ),
        )
    return fields

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "GitHub token",
                desc = "A fine-grained personal access token with Actions: Read-only. For organization repositories set the token's resource owner to the organization, not your personal account.",
                icon = "key",
                default = "",
            ),
            schema.Generated(
                id = "repo_picker",
                source = "token",
                handler = repo_picker,
            ),
            schema.Text(
                id = "extra_repos",
                name = "Other repositories",
                desc = "Optional. Comma-separated owner/repo entries for anything not listed above.",
                icon = "plus",
                default = "",
            ),
            schema.Toggle(
                id = "only_problems",
                name = "Only show problems",
                desc = "Hide repositories whose last run passed.",
                icon = "filter",
                default = False,
            ),
        ],
    )
