load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("hash.star", "hash")

ZENHUB_REST_API_URL = "https://api.zenhub.com"
ZENHUB_GQL_API_URL = "https://api.zenhub.com/public/graphql"
ZENHUB_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAN1JREFUKFM1jjFKA2EUhL9RVjC9hlitYBHwALoRIU3wBIIQ9QQWgWittQpu4Q0SQcgRkkbBoBcQCyXZIhK0T0hWePJ+sRtm5n3zlGYVk0Ej7msry4N+Xo9Ub04NDKXZjskMA+714B4btz8gQ4AkcTOoeE5rfIctiM3OKt5sXxekZDg3T/PvT8qPNT56Z+QXe0TFkt+g7WFuEszGI5bPu8S1S952u0TFNV9BSBw1J2Hwdf8L//J4pe42jfhJOjydBoLPvJ8sBuyBVR3+N/FfaF0VlGQzc9RLvKR0kAT9C5GsVRBZZKbEAAAAAElFTkSuQmCC""")

issue_colors = [
    "#91e03a",  # ZH Green
    "#37e1fb",  # ZH Blue
    "#5c74f7",  # ZH Purple
]

def render_welcome():
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Image(src = ZENHUB_ICON),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.Marquee(
                                    width = 50,
                                    align = "start",
                                    child = render.Text("Backlog"),
                                ),
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "start",
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        font = "CG-pixel-3x5-mono",
                                        content = "0001:",
                                        color = issue_colors[0],
                                    ),
                                    render.Marquee(
                                        width = 50,
                                        offset_start = 0,
                                        child = render.Text(
                                            font = "CG-pixel-3x5-mono",
                                            content = "Get API Keys ",
                                        ),
                                    ),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        font = "CG-pixel-3x5-mono",
                                        content = "0002:",
                                        color = issue_colors[1],
                                    ),
                                    render.Marquee(
                                        width = 50,
                                        offset_start = 0,
                                        child = render.Text(
                                            font = "CG-pixel-3x5-mono",
                                            content = "Get Workspace ID",
                                        ),
                                    ),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        font = "CG-pixel-3x5-mono",
                                        content = "0003:",
                                        color = issue_colors[2],
                                    ),
                                    render.Marquee(
                                        width = 50,
                                        offset_start = 0,
                                        child = render.Text(
                                            font = "CG-pixel-3x5-mono",
                                            content = "Get Repository ID",
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_error(message, small = False):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Image(src = ZENHUB_ICON),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.Text("Zenhub APP"),
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "start",
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = message,
                                        font = "CG-pixel-3x5-mono" if small else "tb-8",
                                        color = "#f75c5c",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def main(config):
    zenhub_rest_api_key = config.str("zenhub_rest_api_key", None)
    zenhub_gql_api_key = config.str("zenhub_gql_api_key", None)
    workspace_id = config.str("workspace_id", None)
    repo_id = config.get("repo_id", None)
    selected_pipeline = config.str("selected_pipeline", None)
    selected_labels = config.str("selected_labels", "")
    selected_assignees = config.str("selected_assignees", "")

    if not zenhub_rest_api_key and not zenhub_gql_api_key:
        return render_welcome()

    if not zenhub_rest_api_key:
        return render_error("REST API Token missing")
    if not zenhub_gql_api_key:
        return render_error("GraphQL API Key missing")
    if not workspace_id:
        return render_error("Workspace ID missing")
    if not repo_id:
        return render_error("Repository ID missing")
    if not selected_pipeline:
        return render_error("Pipeline name missing")

    if repo_id:
        repo_id = int(repo_id)

    if len(selected_labels) > 0:
        selected_labels = selected_labels.split(",")

    if len(selected_assignees) > 0:
        selected_assignees = selected_assignees.split(",")

    filters = {}

    if len(selected_labels) > 0:
        filters["labels"] = {"in": selected_labels}

    if len(selected_assignees) > 0:
        filters["assignees"] = {"in": selected_assignees}

    pipeline_cache = cache.get("zenhubapp_pipeline_%s" % hash.md5(zenhub_gql_api_key))
    issues_cache = cache.get("zenhubapp_issues_%s" % hash.md5(zenhub_gql_api_key))

    if pipeline_cache != None:
        print("[ZENHUB APP] Pipeline cache hit")
        pipeline_id = pipeline_cache
    else:
        print("[ZENHUB APP] Pipeline cache miss")

        board_res = http.get(
            "%s/p2/workspaces/%s/repositories/%d/board" % (ZENHUB_REST_API_URL, workspace_id, repo_id),
            headers = {
                "X-Authentication-Token": zenhub_rest_api_key,
                "Content-Type": "application/json",
            },
        )

        if board_res.status_code != 200:
            return render_error("Invalid Zenhub config")

        board_json = board_res.json()

        pipeline_id = [
            pipeline["id"]
            for pipeline in board_json["pipelines"]
            if pipeline["name"] == selected_pipeline
        ]

        if len(pipeline_id):
            pipeline_id = pipeline_id.pop()
        else:
            return render_error("Pipeline not found")

        cache.set("zenhubapp_pipeline_%s" % hash.md5(zenhub_gql_api_key), str(pipeline_id), ttl_seconds = 120)

    if issues_cache != None:
        print("[ZENHUB APP] Issues cache hit")
        print(issues_cache)
        issues = json.decode(issues_cache)
    else:
        print("[ZENHUB APP] Issues cache miss")

        issues_res = http.post(
            ZENHUB_GQL_API_URL,
            headers = {
                "Authorization": "Bearer %s" % zenhub_gql_api_key,
                "Content-Type": "application/json",
            },
            json_body = {
                "operationName": "searchIssuesByPipeline",
                "variables": {
                    "pipelineId": pipeline_id,
                    "filters": filters,
                },
                "query": """
                    query searchIssuesByPipeline($pipelineId: ID!, $filters: IssueSearchFiltersInput!) {
                      searchIssuesByPipeline(
                        pipelineId: $pipelineId
                        filters: $filters
                      ) {
                        nodes {
                          id
                          number
                          title
                        }
                      }
                    }
                """,
            },
        )

        if issues_res.status_code != 200:
            return render_error("Invalid Zenhub config")

        issues = issues_res.json()["data"]["searchIssuesByPipeline"]["nodes"]
        cache.set("zenhubapp_issues_%s" % hash.md5(zenhub_gql_api_key), str(issues), ttl_seconds = 120)

    issue_rows = []

    if len(issues) == 0:
        issue_rows = [
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.WrappedText(
                        content = "No issues in this pipeline",
                        color = "#f75c5c",
                    ),
                ],
            ),
        ]
    else:
        issue_rows = [
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        font = "CG-pixel-3x5-mono",
                        content = "%s:" % int(issue["number"]),
                        color = issue_colors[index],
                    ),
                    render.Marquee(
                        width = 50,
                        offset_start = 0,
                        child = render.Text(
                            font = "CG-pixel-3x5-mono",
                            content = "%s" % issue["title"],
                        ),
                    ),
                ],
            )
            for index, issue in enumerate(issues[:3])
        ]

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Image(src = ZENHUB_ICON),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.Marquee(
                                    width = 50,
                                    align = "start",
                                    child = render.Text("%s" % selected_pipeline),
                                ),
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "start",
                        children = issue_rows,
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "zenhub_rest_api_key",
                name = "Zenhub REST API Token",
                desc = "Your personal Zenhub REST API Token",
                icon = "key",
            ),
            schema.Text(
                id = "zenhub_gql_api_key",
                name = "Zenhub GraphQL Personal API Key",
                desc = "Your personal Zenhub GraphQL API Key",
                icon = "key",
            ),
            schema.Text(
                id = "workspace_id",
                name = "Zenhub Workspace ID",
                desc = "Your Zenhub Workspace ID",
                icon = "key",
            ),
            schema.Text(
                id = "repo_id",
                name = "Zenhub Repository ID",
                desc = "Your Zenhub Repository ID",
                icon = "key",
            ),
            schema.Text(
                id = "selected_pipeline",
                name = "Pipeline Name",
                desc = "The Pipeline name to watch, case sensitive",
                icon = "tableColumns",
            ),
            schema.Text(
                id = "selected_labels",
                name = "Filter by Labels",
                desc = "Labels to filter the issues. Separate by comma with no spaces",
                icon = "tags",
            ),
            schema.Text(
                id = "selected_assignees",
                name = "Filter by Assignees",
                desc = "Github user to filter the issues by assignee. Separate by comma with no spaces",
                icon = "users",
            ),
        ],
    )
