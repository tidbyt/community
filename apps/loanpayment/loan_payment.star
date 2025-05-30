"""
Applet: Loan Payment
Summary: Shows remaining loan
Description: Shows the amount still to be repaid from your loan.
Author: devfle
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    display_content = []

    loan_config = {
        "start": config.get("start", "2025-02-02T20:00:00Z"),
        "sum": config.str("sum", "12000"),
        "rate": config.str("rate", "120"),
        "currency": config.str("currency", "$"),
    }

    if not loan_config["sum"] or not loan_config["rate"]:
        return None

    current_time = get_current_utc_time()
    loan_start_time = time.parse_time(loan_config["start"]).in_location("UTC")

    loan_progress = math.floor(
        (get_year_from_date(current_time) - get_year_from_date(loan_start_time)) * 12 +
        (get_month_from_date(current_time) - get_month_from_date(loan_start_time)),
    )

    rest_to_pay = math.floor(
        int(loan_config["sum"]) - (loan_progress * int(loan_config["rate"])),
    )

    rest_to_pay = (
        str(rest_to_pay) + " " + loan_config["currency"] if rest_to_pay > 0 else "Loan Payed"
    )

    display_content.append(
        render.Box(
            width = 60,
            height = 14,
            child = render.Text(content = rest_to_pay, font = "6x13"),
        ),
    )

    return render.Root(
        child = render.Box(
            child = render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "center",
                children = display_content,
            ),
        ),
    )

def get_current_utc_time():
    return time.now().in_location("UTC")

def get_month_from_date(date):
    if not date:
        fail("error while getting month from datetime object")

    return int(date.month)

def get_year_from_date(date):
    if not date:
        fail("error while getting year from datetime object")

    return int(date.year)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "start",
                name = "Loan Start Date",
                desc = "The date when the loan payment started.",
                icon = "calendarDay",
            ),
            schema.Text(
                id = "sum",
                name = "Total Loan",
                desc = "The total amount of the loan.",
                icon = "buildingColumns",
                default = "12000",
            ),
            schema.Text(
                id = "rate",
                name = "Monthly Rate",
                desc = "The monthly rate.",
                icon = "fileInvoiceDollar",
                default = "120",
            ),
            schema.Text(
                id = "currency",
                name = "Currency",
                desc = "The currency sign.",
                icon = "dollarSign",
                default = "$",
            ),
        ],
    )
