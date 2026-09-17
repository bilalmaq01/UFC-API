# A monthly COST budget that EMAILS you as spend climbs.
#
# IMPORTANT: this only *alerts* — AWS does not automatically switch resources
# off when you cross the limit. It's an early-warning system so a surprise bill
# can't sneak up on you. The real cost protection is the serverless design
# (near-zero cost at idle), with this as the smoke detector on top.

resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Heads-up at half the limit (actual spend).
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Louder warning near the limit (actual spend).
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Catches trouble early: alerts if AWS *forecasts* you'll exceed the limit
  # by month-end, even before you actually have.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
