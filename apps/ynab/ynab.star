load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    access_token = config.get("access_token", None)
    displayed_categories = []
    if access_token:
        budget_endpoint = "https://api.ynab.com/v1/budgets/last-used/settings"
        response = http.get(budget_endpoint, headers = {"Authorization": "Bearer " + access_token}, ttl_seconds = 60000).body()
        currency_format = json.decode(response)["data"]["settings"]["currency_format"]

        month_endpoint = "https://api.ynab.com/v1/budgets/last-used/months/current"
        response = http.get(month_endpoint, headers = {"Authorization": "Bearer " + access_token}, ttl_seconds = 60).body()
        categories = json.decode(response)["data"]["month"]["categories"]
        displayed_categories = []
        for category in categories:
            balance = category["balance"]
            if category["balance"] < 0 or (category["activity"] < 0 and category["balance"] > 0):
                render_element = render.Row(
                    children = [
                        render.Text(str(category["name"]).strip(), color = "#ADD8E6", font = "tom-thumb"),
                    ],
                    main_align = "center",
                    cross_align = "center",
                )
                render_element_balance = render.Row(
                    children = [
                        render.Text("  " + currency_string(category["balance"], currency_format) + ":" + currency_string(category["budgeted"], currency_format), color = "#FF0000" if balance < 0 else "#FBCEB1", font = "tom-thumb"),
                    ],
                    main_align = "center",
                    cross_align = "center",
                )
                displayed_categories.append(
                    render.Column(
                        children = [
                            render_element,
                            render_element_balance,
                        ],
                    ),
                )

    else:
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

    # YNAB Title Row
    ynab_row = render.Padding(
        child = render.Row(
            children = [
                render.Text("YNAB Categories", color = "#ADD8E6", font = "tom-thumb"),
            ],
            main_align = "center",
            cross_align = "center",
        ),
        pad = 1,
    )

    # Create animation frames of the category balances
    animation_children = []
    frames = []
    if len(displayed_categories) == 0:
        frames.append(
            render.Stack(
                children = [
                    ynab_row,
                    render.Row(
                        children = [
                            render.Box(
                                color = "#0000",
                                child = render.Text("No Categories to display", color = "#f3ab3f"),
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        for i in range(0, len(displayed_categories), 2):
            if len(displayed_categories) > i + 1:
                frames.append(
                    render.Column(
                        children = [
                            ynab_row,
                            displayed_categories[i],
                            displayed_categories[i + 1],
                        ],
                    ),
                )
            else:
                frames.append(
                    render.Stack(
                        children = [
                            ynab_row,
                            displayed_categories[i],
                        ],
                    ),
                )

    split = 160 / len(frames)
    for i in range(0, 160):
        animation_children.append(frames[math.floor(i / split)])

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

def currency_string(full_number, currency_format):
    currency_symbol = currency_format["currency_symbol"]
    decimal_digits = currency_format["decimal_digits"]
    decimal_separator = currency_format["decimal_separator"]

    # YNAB pads the number with an extra decimal place
    full_number = full_number / 10
    decimal_number = full_number / (math.pow(10, decimal_digits))
    return currency_symbol + str(decimal_number).replace(".", decimal_separator) + ("0" if full_number % 10 == 0 else "")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "Auth Key",
                desc = "Auth Key supplied from YNAB",
                icon = "key",
            ),
            schema.Toggle(
                id = "categories",
                name = "Show partially spent categories",
                desc = "Toggle partially spent categories",
                icon = "dollarSign",
                default = True,
            ),
        ],
    )
