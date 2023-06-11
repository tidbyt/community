load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("math.star", "math")

access_token = "ts9soG1aI5m1TLz_QrLgsCbyVnBoa-mFacq0QD8P86Q"

def main(config):
    key = access_token or config.get("key", None)
    displayed_categories = []
    if key:
        endpoint = "https://api.ynab.com/v1/budgets/last-used/months/current"
        response = http.get(endpoint, headers = {"Authorization": "Bearer " + access_token}, ttl_seconds = 60).body()
        categories = json.decode(response)["data"]["month"]["categories"]
        print(categories)
        displayed_categories = []
        for category in categories:
            balance = category["balance"]
            if category["balance"] < 0 or (category["activity"] < 0 and category["budgeted"] > 0):
                render_element = render.Row(
                        children = [
                            render.Text(str(category["name"]), color = "#ffffff", font = "tom-thumb")
                        ],
                        main_align = "center",
                        cross_align = "center",
                    )
                
                render_element_balance = render.Row(
                        children = [
                            render.Text(currency_string(str(category["balance"])), color = "#FF0000" if balance < 0 else "#FBCEB1", font = "tom-thumb")
                        ],
                        main_align = "center",
                        cross_align = "center",
                    )
                print(category)
                displayed_categories.append(render.Column(
                    children = [
                        render_element,
                        render_element_balance,
                    ])
                )
    
    else:
        stop_name = "YNAB"
        displayed_categories.append(
            render.Row(
                children = [
                    render.Box(
                        color = "#0000",
                        child = render.Text("No API Key", color = "#f3ab3f"),
                    ),
                ],
            ),
        )

    #Create animation frames of the stop info
    animation_children = []
    frames = []
    for i in range(0,len(displayed_categories),2):
        if len(displayed_categories) > i + 1:
            frames.append(
                render.Column(
                    children = [
                        displayed_categories[i],
                        displayed_categories[i+1],
                    ]
                )
            )
        else:  
            frames.append(
                render.Stack(
                    children = [
                        displayed_categories[i]
                    ]
                )
            )
    split = 160 / len(frames)
    for i in range(0, 160):
        animation_children.append(frames[math.floor(i/split)])

    return render.Root(
        child = render.Column(
            children = [
                render.Sequence(
                    children = [
                        render.Animation(
                            children = animation_children,
                        ),
                    ],
                ),
            ],
        ),
    )

def currency_string(full_string):
    return full_string[0:len(full_string)-3] + "." + full_string[len(full_string)-3:len(full_string)-1]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
