"""
Applet: GitHub Badge
Summary: GitHub badge status
Description: Displays a GitHub badge for the status of the configured action.
Author: Cavallando
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEBUG = False
TEST_RUN = """{
    "total_count": 28,
    "workflow_runs": [
        {
            "conclusion": "success",
            "updated_at": "2025-03-14T04:25:26Z",
            "head_branch": "main",
            "status": "completed"
        }
    ]
}"""

GITHUB_LOGO = base64.decode(
    """
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
""",
)
GITHUB_LOADING_ICON = base64.decode(
    """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAyELV9gAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGV7hBwAAALRJREFUGBmNULkNAjEQnPUZUqQTBZATugGqID4S6rg6iC6mChq4kJwCAOkiJB4bj9GiFRCwkuXV7GhmdgWmUoJgh6pACzxEkMz41aYW7hO0mOeQgLSI+y3qsUND7BrRyRJnnQntaEHSyKGfTjAj8TjgcIsIc5Izx/UbFFUvWJF0GnDhY6/qzP2Vi2q/6m9rz3wlcM6Sc4Zs21Ax5+tKPi4qiG8XewoFLSYK8ud2ulxY424P/gQvBFBVoqUqSQAAAABJRU5ErkJggg==
""",
)
GITHUB_NEUTRAL_ICON = base64.decode(
    """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAyELV9gAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGV7hBwAAAL1JREFUGBltT7ENwjAQxAkpkhKJPjt4FwaIpRSUMIDtQTwPleUV0kWioLSLAOYPsBVILL38uru/+2eb2YsxMq11CUhK+WCMxRn9aZVSxT+4wBIghNh1XXdCocdg4hjiEPElbF3XLQQhhIE+boy5QVOO41hZa5+c8yOJDt77ME3TvWmaPf1X59yFjLaLveC29n6iKcKSUwshOQ/klKML7IeFsQsIEpxRSQQOmpySrssANWvYm8d1fd9XKPTzoRdhW2pt9jVcwwAAAABJRU5ErkJggg==
""",
)
GITHUB_FAULT_ICON = base64.decode(
    """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAyELV9gAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGV7hBwAAAJVJREFUGBmNjzsOwjAQRJ8TxAFQDpCekgvBzbgQJQ1NTpC0kRC/GcNGlguUlWyv387+EoW9Ienb/tBTH6HKRJoKWbWwjYMGyn5dYbeFo9kdzmJTxCxyOyy6wTApz8e+mWPWNBfIVXWdOuhHmH3sR3Vp22UGZ/61ta3zfDFwvcy+XCbaWRx+vCXLFYtAiuUO8FBQ2q99AInKNumte7PwAAAAAElFTkSuQmCC
""",
)
GITHUB_FAILED_ICON = base64.decode(
    """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAyELV9gAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGV7hBwAAAJZJREFUGBl9kE0OgjAQhT/FI7HxBmw4oImJF3DneQxVVp6BRH1vYEgXSpPSefN+OhSW9YG99z8cfQl2laARbio8c5lS4DxAlwLXD7gYW3NIQuAq6+0Jx0lN12/ok49TorjqDu0Ar6ItQ2syuXX4cGx95AixkroCk5Oc7HpcZg5NJTwl4WAb659xz3No9nmp/v08lWDzwb8IgDcQ6vIG+QAAAABJRU5ErkJggg==
""",
)
GITHUB_SUCCESS_ICON = base64.decode(
    """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAyELV9gAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGV7hBwAAALdJREFUGBl9kDEKwkAQRd8m0UbBWsRbWAsewCt4DrESwXNYit5ALEK2EIu09lZewkCcnWQW02SLnZk/j78zC31nT0JN2ofA9Q+ocQbHRIWcTOODWVqwCXmiAvJA3eYBWlFxY5RWlOIwbxkJL4ZaWAyQ55N5dqrbGCKeRDyqeGfSgUoGQW9m80xltadznGWEteiXasmBAC34qkHcLmcsTu+sYKuN1qmB7LYZrLbFrO7E5nNd3L7ThB9v2CtM7SwcKwAAAABJRU5ErkJggg==
""",
)
BADGE_BACKGROUND = base64.decode(
    """
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
""",
)

DEFAULT_BRANCH = "main"

def should_show_jobs(repos, dwell_time):
    print("dwell time is " + str(dwell_time))
    if dwell_time == 0:
        return True

    now = time.now().in_location("UTC")
    for repo in repos:
        if "data" not in repo:
            continue
        job = repo["data"]
        if job.get("conclusion", "unknown") != "success":
            return True
        updated_at = time.parse_time(job["updated_at"], format = "2006-01-02T15:04:05Z").in_location("UTC")
        duration = now - updated_at
        print("comparing " + str(duration.seconds) + " and " + str(dwell_time * 60))
        if duration.seconds <= dwell_time * 60:
            return True
        else:
            print("all successes are old")
    return False

def get_status_icon(status):
    """Gets the decoded icon string for a given Workflow Status from github

    Args:
        status: The status of the workflow, can be anyone of the statuses found here
            https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow

    Returns:
    The appropriate icon string
    """
    if status == "completed" or status == "success":
        return GITHUB_SUCCESS_ICON
    elif status == "failed" or status == "timed_out":
        return GITHUB_FAILED_ICON
    elif (
        status == "cancelled" or
        status == "skipped" or
        status == "stale" or
        status == "neutral"
    ):
        return GITHUB_NEUTRAL_ICON
    elif status == "action_required":
        return GITHUB_FAULT_ICON
    else:
        return GITHUB_LOADING_ICON

def fetch_workflow_data(repos, access_token):
    """Fetches the workflow data from GitHub

    Args:
        config: The schema config from TidByt

    Returns:
        The workflow data if it can be found or an error message from the request
    """
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if access_token:
        headers["Authorization"] = "Bearer {}".format(access_token)

    modified_repos = []
    print("repos are " + str(repos))
    for repo in repos:
        owner_name, repo_name, branch_name, workflow_id = repo["str"].split("/")
        if not DEBUG:
            resp = http.get(
                "https://api.github.com/repos/{}/{}/actions/workflows/{}/runs".format(
                    owner_name,
                    repo_name,
                    workflow_id,
                ),
                params = {"branch": branch_name, "per_page": "1", "page": "1"},
                headers = headers,
                ttl_seconds = 60,
            )
            data = resp.json()
            if (resp.status_code != 200):
                print("status_code : " + str(resp.status_code))
                print(data)
                return ("error", data.get("message"))
        else:
            data = json.decode(TEST_RUN)
        if data and data.get("workflow_runs"):
            repo_copy = {
                "owner": repo["owner"],
                "name": repo["name"],
                "branch": repo["branch"],
                "workflow": repo["workflow"],
                "str": repo["str"],
                "data": data.get("workflow_runs")[0],
            }
            modified_repos.append(repo_copy)
    return modified_repos, None

# def get_display_text(repo):
#     return config.get("display_text") or "{}/{}".format(repo[0], repo[1])

def render_status_badge(status, repos):
    # workflow_data is an array
    rows = []
    print(type(repos))
    if type(repos) == "list":
        for repo in repos:
            status = repo["data"]["status"]
            print("appending row " + status)
            rows.append(
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 37,
                            child = render.Text(
                                content = repo["name"],
                                font = "tom-thumb",
                            ),
                        ),
                        render.Image(src = get_status_icon(status)),
                    ],
                ),
            )
    else:
        print("error, got no data from github")
        rows.append(
            render.Row(
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 37,
                        child = render.Text(
                            content = repos,
                            font = "tom-thumb",
                        ),
                    ),
                    render.Image(src = get_status_icon(status)),
                ],
            ),
        )
    return render.Root(
        child = render.Stack(
            children = [
                # render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = BADGE_BACKGROUND, width = 64, height = 30)),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (1, 9, 2, 10),
                            child = render.Image(
                                width = 13,
                                height = 13,
                                src = GITHUB_LOGO,
                            ),
                        ),
                        render.Column(
                            expanded = True,
                            children = rows,
                        ),
                    ],
                ),
            ],
        ),
    )

def main(config):
    """Main render function for the App

    Args:
        config: The schema config from TidByt

    Returns:
        A Root view to render to the app
    """
    repo1 = config.str("repo1", "owner/repo/branch/workflow")
    repo2 = config.str("repo2", "owner/repo/branch/workflow")
    repo3 = config.str("repo3", "owner/repo/branch/workflow")
    repos_strs = [repo1, repo2, repo3]
    repos = []
    for repo in repos_strs:
        if (
            repo == "owner/repo/branch/workflow" or
            repo == ""
            # or len(repo.split("/")) < 4
        ):
            continue
        else:
            owner, name, branch, workflow = repo.split("/")
            repos.append(
                {
                    "owner": owner,
                    "name": name,
                    "branch": branch,
                    "workflow": workflow,
                    "str": repo,
                },
            )
    workflow_data = []
    workflow_data, err = fetch_workflow_data(repos, config.get("access_token", None))

    if err:
        return render_status_badge("failed", err)
        # elif len(workflow_data) == 0 and access_token == None:
        #     return render_status_badge("success", "no data")

    elif workflow_data and type(workflow_data) != "string":
        if not should_show_jobs(workflow_data, int(config.get("timeout", "0"))):
            return []

        return render_status_badge("success", workflow_data)
    elif workflow_data:
        return render_status_badge("failed", workflow_data)
    else:
        return render_status_badge("failed", "Could not connect to GitHub")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "GitHub Personal Access Token",
                desc = "Personal Access token (optional, only required for private repos)",
                icon = "lock",
            ),
            schema.Text(
                id = "repo1",
                name = "Repo 1",
                desc = "Repo 1",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "repo2",
                name = "Repo 2",
                desc = "Repo 2",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "repo3",
                name = "Repo 3",
                desc = "Repo 3",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "timeout",
                name = "All Success Timeout",
                desc = "How long to show all green",
                icon = "clock",
                default = "0",
            ),
        ],
    )
