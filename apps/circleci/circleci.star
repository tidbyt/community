"""
Applet: CircleCI
Summary: CircleCI Build Statuses
Description: Status of latest execution of pipeline in CircleCI.
Author: barbosa
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CIRCLECI_LOGO_WHITE = base64.decode("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")
CIRCLECI_LOGO_GREEN = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAABEdJREFUWEfNl0toXVUUhr//pOlDQx/gC6laxBdEhWJBjc4VRZ1o0bmxWEMFsWoLzd471CiKk0LQgk50ljqw2oFTRRTbqiAGpW2cSQdqhIq2TdK7ZJ2cHc69Odc2xTRuCLnssx//+te/1l5LdBlmpkjsSUqzviRYWC00YNj9wO3AtcBlQEtoyrCfC4ojLVqfJaUTvsfPOMCBYqu2nut2j5o+jNt4T94ULGwUeh54EtjY7aDafAv43LCxpPShz++3/b3btG2mae8CAMHCiprVUWgXsLK0CDsn5BfIsLa98qm5saJ20dGCYmhYw18HC0UkmjS/rlzWdkhGutf2XjfDzEGhzdVhjr4HKC6AATPM3eJAe+cu0e6g8Fp2Sx3EPIBs+YiN3NGi9QWwFpiuDml01QWAcf046MKw95LS050gyoOzz4OFG4HvhS4H3OrSgoaRrfT/EvJzurHjrvGz3I3vRMVn6xqTK9UpcfpPcvIH4JZ/udxp9b+6nzM+v8jV7q5qYqw0SGgoKIxldytTHy2OAdsr2kvRdQynM198CvgJ+BVYBWwCbqrWZ3YcSH04QAfm329LSsdcmCXSERvZ3KL1bWXdAior9fuBk4btFToUFX/Lp/tBwJ1ugNBgNV8HnJdmt/r+R9wVJYBo8QDwOLBgU77cRRSJg1nBfmk//eX+eqKJFgeAg8AVNeB1JtyFLsq7k9JhecjNMnu8otI/zkXO3CjFUyWVIZ9w321gQ2uCCV/TchD+u59+m2DCM+d0sLBJ6DtgfQOrJQs5KlwDLwi91UXtnny+SUpbqtRcAktKGej8NmfE5/fZvlU7tONssvSwYYcaWMgM/LKOdTcrWnwRGAV+r6vbXCuwUuihqPili9Wt8UtGbfTKaaZfAbYAp4TeDwruxnJkYQcLnwo90ODaDOLe0qJgYe0a1rSFzmlOe3xPR8W/K5GVlgcL1wsdAa5ql7i9mZRecmG5SzydJ0tPGDbeAKDUmtAz581wOU/k5BEtfgQ8ZtjpiqGWYYVQT0ExMKzhr2op/YZZZo9VSSiHYdaWJ7nREoBf0k0DrvoMwpkSmnSFl29Tu1hdWCkpxQwgWOgTcoFf0yHGkgEX9/8DQDfrK32U6l5SFwQL61ezus0NZzijPvrO7tTOvxpEeBi4ugP4G1Hx5UWL0MPQsNeBqRyGubgwzB+PB7uFoWF3CXkYfnAxYVhQ3LP8iaghFdddsfSpeNkfIwdwvue4lskmhV7tpffQbu32WiCn3sU+x59ExUfL5/hiChLD/hT6EfCawIuXRRUkPfTcukd7jpcFybKXZM7hpSpKDXs7KW1vK0o7n9ClKsuBd6PiYH53cmXV2Jh4OwZ8/F81JobtSkqe7MqHr7Ex6WSirHwsBd9clWtdW7NaW+bb2lozw57z2u+CWrMMorM5BXYIPXVJmtMMorM991pviqn7OttzIW9G/vCSXejoYtvzfwB/7z6lvPpg8gAAAABJRU5ErkJggg==")
CIRCLECI_LOGO_RED = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAABElJREFUWEfNV01oHVUU/r55TZNq6A/4h1Qt4h+kCsWCGt0rirrRontjsYYIYlsbaO49IUZR3ASCFuxGd4kLq1m4VUSxrQpiUNrGnXShRmjRtC+vc+TcmTudeW+eJsXYXni892buz3e+851zzyG6DFUlvG9QpGVT1Lk+kINQfQjAdgA3ArgKQApyEao/I0mOIU0/o8ipsMb2mJ1NuGvXhW7nsO6Fzsw04iJ1bivIlwA8A2Brt41Kz1MAn0N1miIfBiCHDvVw9+7lurUdANS5dSWrPcgDANaHxaoXQNoBhFlXHqTmf9eVHh9HkgxzbOxrdS6B98qL88K0yiYRqU5M3ITl5SMgd+SbGfoGgGQFDChUzS0GtCc7haN07vXoljKIAkC0XMfH70aafgFgI4Bmvkmtq1YAxvRjoBOoHqbIc+0gwsbR5+rcrQC+B3k1ALM6s6BzRCvtmyBtn27smGtsL3Pju/T+hbLGaEo1Sox+nD79A4A7/uFwo9U+ZT9HeHaQqd1cVcdYZhA5TOemo7tZUO/9NIA9Oe2Z6KrD6IwHnwHwE4BfAfQC2Abgtnx6ZMeAlIcBNGD2/i6KnDBhZi4YH9+BNP02t66Tykz9tuECVCdAztH73wrTTeHAPcEAcih/XgYcp0a32vrHgysCAO9nATwFoHNRPFz1MLwfigoOYTUwENaXE416PwjgCIBr8rBtZ8JcaKK8jyJHGUKu1TqZU2kvw575dyaeLKkMB7CmlS1bUszP25w0gLDfAwOK+XnLnE11bhvI7wBsrmE1YyGPCtPAyyDf7qJ2Sz7fUGRnnpozi0Ui0GJZ8KdIqlNTvRwZOa8ij0F1roaFyMAv2LTpdqr3rwCYBPB7Rd2qJpr1IB+l91+aWM2acMjk5LVoNl8FsBPAGZDv0zlzYxiFsJ37FOTDNa6NIB7INODcRmzYUA2dpSWL7ya9/yv4O7dcnbsZ5DEA11U1rm9RZJ8Jy1xi6VxFnobqTA2ATGvk8/+a4Yo8kV9Q6v1HAJ6E6lLOUArVJERJkgxybOyrUkq/Ba3WiTwJxTA03DEaJjMG2i+WkmkhScVkZUyRC0HhFs9VsZqwhCK+AOBcP0gT+A1tYswYMHFfEQC6RkCmj0zda+oC5zajr6+qh3PniP7+89y7988aER4FcH0b8Dfp/f5VizCEoeobABaLMIxFg6pdHo90DUPVe0FaGH5wSWGYJPdfAYmoMxWXXbH2qfiyX0Yruo4v3pILIF9DT88cR0etFoipd7XX8Sf0/okQWZdUkKieBfkjAKsJrHhZXUHSaNzJgwdPhhC/7CVZcEFMMmtdlKq+Q5E9laK04wpdq7IceI/eD8V7J1ZW9Y2JtWPAx/9ZY6J6gCKW7MLFV9uYtDMRJos4qFprZpVv99as2m5VWzPVF632W1FrVoBob06BEZDP/i/NaQGivT2fmurF4uKDHe05ac3IH6FkJ4+vtj3/GyhyPqUErlJ5AAAAAElFTkSuQmCC")
CIRCLECI_LOGO_YELLOW = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAABAhJREFUWEfNl02IVWUYx3//O45jJWbQF2ElURlYgSRUU/uiqDYVtW+KbDCQvhTynCM2RdFGGCrITe20RdYs2hZRpFYQSaFOO2lRTmCUOY73iee873vvueeeO85Ikx4YZuac9+P//J//8yUGPGYmyIekYs6XmGUrQKNg9wK3AtcAFwNt0AzYL9A6AO3PpeJo2ONn7G1Jj58ZdI+aPpjtGUqbzLI1oOeBJ4A1gw6qvG8DX4BNSsVHAch7w9Izp5v29gEwy5ZVrM5BW4HlYbOdAfkFAreu+sjif8sqbw9Ca1za/o1Z1oLcpM66clnPIQmp2c5r4fQ+0IZ4mKMfAloLYMDA3C0OdDis1zYpez25pQqiAyBZbrbjNmh/CawCZuMhja5aABjXj4Nuge2WiqfqIMqDk8/NshuAH0CXAG51tKDvqmSl/xbIzxnEjrvGz3I3vivlz1Y1JleqU+L0w68/AjfPc7nT6j9VPyd0fpGr3V3VxFg0SONSNpncrS71+SSwKdIeRddjudOZLj4B/Az8BowAa4Eb4+rEjgOpPg7Qgfn3W6TisAszumDHBmh/F61roLJUvx84DbYTNCXlv3dMLxXO7cEAjcX3VcBpaXKr73+odEXQQL4XeBRo2JQut92QjyUFh7BaX+6vJhqzfBTYB1wew7bOhLvQRXmnVOxXCLm5I5FK/1gNzyieMqmMB7CulcvacMgvbwcQ/vd6g0OeOWfNsrWg74HVDaxGFkJUuAa2gN4eHFL2rVRsjKk5WlwkoJ1tpT9VtM12jUibT5kVD4JNNbCQGDgGl94ks/wFYAI43qtuc9EsBz0g5V+5WN2acMnEFTD7CrAROAH6QMrcjeXTFXb2Gei+BtcmEHdHDWSr4KJa6Jz0+J6V8r+Dv93Xfnl2HegAcGVN5G9JxUsuLHeJp3Oz4jGwPQ0Aotb09FkzXDdPhAJlln8MPAJ2MjLUBmuFKGmNStu/rqT062HucExCKQwdd4qGichAvbB0bQtJKiUrZ0rTQeEez52Ek4RVSEXeBZCtBLnAr66JMTJgkxcGgPmKSlfdS+qCbDWsqOnhH8HKU9KLfzWIcD9wVQ34m1L+8qJFGMLQ3gBmumGYmgYbBt0/OAztDpCH4YfnFoatuy6ERNSXiquuWPpUfN6LUQBwtnLcqZLToNdgeEra5r1ASr2LLcefSvnDZTk+t4bE/gT9BHhP4M3LIhuSoXXSq0fKED/vLVlwQUoyS92U2jtSsamnKe0voUvVlvO+lI+FvsIra8g1AwYTH8f45L8bTGyrVHiyK+fFxsGkzkRYXGRgPpp55zvPaNYzbtVGM3vOe78FjWZdEPXhlM2gJ/+X4bQLoj6e7xqBmXv6x3P5MPJHaNl1cLHj+b+bn+cZVprzmQAAAABJRU5ErkJggg==")

CIRCLECI_PIPELINES_API_URL = "https://circleci.com/api/v2/project/{}/pipeline"
CIRCLECI_WORKFLOWS_API_URL = "https://circleci.com/api/v2/pipeline/{}/workflow"

def main(config):
    if config.get("api_token") == None:
        return render_fail("Please inform API token")

    if config.get("vcs") == None:
        return render_fail("Please inform vcs type")

    if config.get("org") == None:
        return render_fail("Please inform org name")

    if config.get("repo") == None:
        return render_fail("Please inform repo name")

    latest_pipeline = fetch_latest_pipeline(config)
    if latest_pipeline == None:
        return render_fail("Can't fetch pipeline")

    latest_workflow = fetch_latest_workflow(config, pipeline_id = latest_pipeline.get("id"))
    if latest_workflow == None:
        return render_fail("Can't fetch workflow")

    return render_widget(config, latest_pipeline, latest_workflow)

def fetch_latest_pipeline(config):
    api_token = config.str("api_token")
    project_slug = "{}/{}/{}".format(config.str("vcs"), config.str("org"), config.str("repo"))

    params = {
        "circle-token": api_token,
    }

    branch = config.str("branch")
    if branch:
        params["branch"] = branch

    response = http.get(CIRCLECI_PIPELINES_API_URL.format(project_slug), params = params)

    print("{} ({})".format(project_slug, branch or "all branches"))

    if response.status_code != 200:
        return None

    pipelines = response.json()
    items = pipelines.get("items")

    if len(items) == 0:
        return None

    return items[0]

def fetch_latest_workflow(config, pipeline_id):
    api_token = config.get("api_token")

    response = http.get(CIRCLECI_WORKFLOWS_API_URL.format(pipeline_id), params = {
        "circle-token": api_token,
    })

    if response.status_code != 200:
        return None

    workflows = response.json()
    latest_workflow = workflows.get("items")[0]
    print("Workflow Status:", latest_workflow.get("status"))

    return latest_workflow

def logo_for_status(status):
    mapping = {
        "success": CIRCLECI_LOGO_GREEN,
        "running": CIRCLECI_LOGO_YELLOW,
        "failed": CIRCLECI_LOGO_RED,
        "error": CIRCLECI_LOGO_RED,
        "failing": CIRCLECI_LOGO_RED,
    }

    print("Pipeline Status:", status)

    return mapping.get(status, CIRCLECI_LOGO_WHITE)

def render_widget(config, latest_pipeline, latest_workflow):
    repo_name = config.str("repo")
    status = latest_workflow.get("status")

    author = latest_pipeline["trigger"]["actor"]["login"]
    avatar_url = latest_pipeline["trigger"]["actor"]["avatar_url"]

    avatar = None
    if avatar_url != None:
        avatar = http.get(avatar_url).body()

    stopped_at = time.parse_time(latest_workflow["stopped_at"])
    when = humanize.time(stopped_at)

    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Image(src = logo_for_status(status), width = 8, height = 8),
                            render.Box(width = 2, height = 8),
                            render.Text(repo_name),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Image(src = avatar, width = 16, height = 16) if avatar_url else render.Box(width = 16, height = 16, color = "666"),
                            render.Box(width = 2, height = 16),
                            render.Marquee(
                                width = 48,
                                child = render.Column(
                                    children = [
                                        render.Text(author),
                                        render.Text(when),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_fail(message):
    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Image(src = CIRCLECI_LOGO_RED, width = 8, height = 8),
                            render.Box(width = 2, height = 8),
                            render.Text(content = "Error", color = "f77"),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.WrappedText(content = message, width = 64, align = "left"),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "Your CircleCI Personal Token",
                icon = "key",
            ),
            schema.Dropdown(
                id = "vcs",
                name = "VCS",
                desc = "Version Control System",
                icon = "github",
                default = "gh",
                options = [
                    schema.Option(
                        display = "GitHub",
                        value = "gh",
                    ),
                    schema.Option(
                        display = "Bitbucket",
                        value = "bb",
                    ),
                ],
            ),
            schema.Text(
                id = "org",
                name = "Org",
                desc = "Organization that contains repo",
                icon = "building",
            ),
            schema.Text(
                id = "repo",
                name = "Repo",
                desc = "Repository you want to watch",
                icon = "book",
            ),
            schema.Text(
                id = "branch",
                name = "Branch",
                desc = "Filter by branch",
                icon = "codeBranch",
            ),
        ],
    )
