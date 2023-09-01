load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

def main(config):
    access_token = config.get("access_token", None)
    transactions_mode = config.get("transactions", None)
    displayed_items = []
    if access_token:
        budget_endpoint = "https://api.ynab.com/v1/budgets/last-used/settings"
        response = http.get(budget_endpoint, headers = {"Authorization": "Bearer " + access_token}, ttl_seconds = 60000).body()
        currency_format = json.decode(response)["data"]["settings"]["currency_format"]
        if transactions_mode:
            month_first_date_format = config.get("transaction_date_format", True)
            transaction_endpoint = "https://api.ynab.com/v1/budgets/last-used/transactions"
            response = http.get(transaction_endpoint, headers = {"Authorization": "Bearer " + access_token}, ttl_seconds = 60).body()
            transactions = json.decode(response)["data"]["transactions"]

            # Save last four transactions
            transactions = transactions[len(transactions) - 6:len(transactions)]

            for transaction in transactions:
                transaction_date = transaction["date"]
                date_array = re.split("-", transaction_date)
                date_string = date_array[1] + "-" + date_array[2] if month_first_date_format else date_array[2] + "-" + date_array[1]
                render_element_title = render.Padding(
                    render.Row(
                        children = [
                            render.Text(("YNAB " + date_string) if transactions_mode else "YNAB Categories", color = "#ADD8E6", font = "tom-thumb"),
                        ],
                        main_align = "center",
                        cross_align = "center",
                    ),
                    pad = 1,
                )
                render_element_account = render.Row(
                    children = [
                        render.Text(transaction["account_name"], color = "#7393B3", font = "tom-thumb"),
                    ],
                    main_align = "center",
                    cross_align = "center",
                )
                render_element_payee = render.Row(
                    children = [
                        render.Text("No Payee" if not transaction["payee_name"] else transaction["payee_name"], color = "FFBF00" if not transaction["payee_name"] else "#7393B3", font = "tom-thumb"),
                    ],
                    main_align = "center",
                    cross_align = "center",
                )
                render_element_category = render.Row(
                    children = [
                        render.Text("No Category" if not transaction["category_name"] else transaction["category_name"], color = "FFBF00" if not transaction["category_name"] else "#7393B3", font = "tom-thumb"),
                    ],
                    main_align = "center",
                    cross_align = "center",
                )
                render_element_amount = render.Row(
                    children = [
                        render.Text(" " + currency_string(transaction["amount"], currency_format) + (" C" if transaction["cleared"] else ""), color = "#ffffe0" if transaction["approved"] else "#ff8080", font = "tom-thumb"),
                    ],
                    main_align = "center",
                    cross_align = "center",
                )
                displayed_items.append(
                    render.Column(
                        children = [
                            render_element_title,
                            render_element_account,
                            render_element_payee,
                        ],
                    ),
                )
                displayed_items.append(
                    render.Column(
                        children = [
                            render_element_category,
                            render_element_amount,
                        ],
                    ),
                )
        else:
            month_endpoint = "https://api.ynab.com/v1/budgets/last-used/months/current"
            response = http.get(month_endpoint, headers = {"Authorization": "Bearer " + access_token}, ttl_seconds = 60).body()
            categories = json.decode(response)["data"]["month"]["categories"]
            for category in categories:
                activity = category["activity"]
                balance = category["balance"]
                budgeted = category["budgeted"]
                if balance < 0 or (activity < 0 and balance > 0):
                    render_element = render.Row(
                        children = [
                            render.Text(str(category["name"]).strip(), color = "#ADD8E6", font = "tom-thumb"),
                        ],
                        main_align = "center",
                        cross_align = "center",
                    )
                    if balance < 0:
                        render_element_balance = render.Row(
                            children = [
                                render.Text("  " + currency_string(balance, currency_format) + ":" + currency_string(budgeted, currency_format), color = "#FF2E2E", font = "tom-thumb"),
                            ],
                            main_align = "center",
                            cross_align = "center",
                        )
                    else:
                        current_time = time.now()
                        current_date = current_time.format("2006-01-02T")
                        date_string = re.split("-", current_date)

                        # Take the ratio of the amount of time remaining in the month versus the amount of money spent
                        time_ratio = int(date_string[2][0:1]) / DAYS_IN_MONTH[int(date_string[1]) - 1]
                        money_ratio = balance / budgeted if budgeted > 0 else 100
                        render_element_balance = render.Row(
                            children = [
                                render.Text("  " + currency_string(balance, currency_format) + ":" + currency_string(budgeted, currency_format), color = "#ffffe0" if money_ratio < time_ratio else "#90EE90", font = "tom-thumb"),
                            ],
                            main_align = "center",
                            cross_align = "center",
                        )
                    displayed_items.append(
                        render.Column(
                            children = [
                                render_element,
                                render_element_balance,
                            ],
                        ),
                    )

    else:
        displayed_items.append(
            render.Row(
                children = [
                    render.Box(
                        color = "#0000",
                        child = render.WrappedText("No YNAB API Key"),
                    ),
                ],
            ),
        )

    # Create animation frames of the category balances
    animation_children = []
    frames = []
    if len(displayed_items) == 0:
        frames.append(
            render.Stack(
                children = [
                    render.Row(
                        children = [
                            render.Box(
                                color = "#0000",
                                child = render.WrappedText("No YNAB Transactions" if transactions_mode else "No YNAB Categories"),
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        for i in range(0, len(displayed_items), 2):
            if len(displayed_items) > i + 1:
                frames.append(
                    render.Column(
                        children = [
                            displayed_items[i],
                            displayed_items[i + 1],
                        ],
                    ),
                )
            else:
                frames.append(
                    render.Column(
                        children = [
                            displayed_items[i],
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
                id = "transactions",
                name = "Transaction Mode",
                desc = "Show recent transactions",
                icon = "creditCard",
                default = True,
            ),
            schema.Toggle(
                id = "transaction_date_format",
                name = "Transaction Date Format",
                desc = "Show month first in date format",
                icon = "calendar",
                default = True,
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
