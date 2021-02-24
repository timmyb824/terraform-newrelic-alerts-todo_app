terraform {
  # Require Terraform version 0.13.x (recommended)
  required_version = "~> 0.14.0"

  # Require the latest 2.x version of the New Relic provider
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 2.12"
    }
  }
}

provider "newrelic" {
  account_id = var.account_id 
  api_key = var.api_key 
  region = var.region        
}

data "newrelic_entity" "todo_app" {
  name = "flask-todo-app"
  domain = var.domain 
  type = var.type
}

resource "newrelic_alert_policy" "golden_signal_policy" {
  name = "Golden Signals - ${data.newrelic_entity.todo_app.name}"
}

# Response time
resource "newrelic_alert_condition" "response_time_web" {
  policy_id       = newrelic_alert_policy.golden_signal_policy.id
  name            = "High Response Time (Web) - ${data.newrelic_entity.todo_app.name}"
  type            = "apm_app_metric"
  entities        = [data.newrelic_entity.todo_app.application_id]
  metric          = "response_time_web"
  condition_scope = "application"

  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = "5"
    time_function = "all"
  }
}

# Low throughput
resource "newrelic_alert_condition" "throughput_web" {
  policy_id       = newrelic_alert_policy.golden_signal_policy.id
  name            = "High Throughput (Web)"
  type            = "apm_app_metric"
  entities        = [data.newrelic_entity.todo_app.application_id]
  metric          = "throughput_web"
  condition_scope = "application"

  # Define a critical alert threshold that will
  # trigger after 5 minutes above 10 requests per minute.
  term {
    priority      = "critical"
    duration      = 5
    operator      = "above"
    threshold     = "10"
    time_function = "all"
  }
}

# Error percentage
resource "newrelic_alert_condition" "error_percentage" {
  policy_id       = newrelic_alert_policy.golden_signal_policy.id
  name            = "High Error Percentage"
  type            = "apm_app_metric"
  entities        = [data.newrelic_entity.todo_app.application_id]
  metric          = "error_percentage"
  condition_scope = "application"

  # Define a critical alert threshold that will trigger after 5 minutes above a 10% error rate.
  term {
    duration      = 5
    operator      = "above"
    threshold     = "10"
    time_function = "all"
  }
}

# High CPU usage
resource "newrelic_infra_alert_condition" "high_cpu" {
  policy_id   = newrelic_alert_policy.golden_signal_policy.id
  name        = "High CPU usage"
  type        = "infra_metric"
  event       = "SystemSample"
  select      = "cpuPercent"
  comparison  = "above"
  where       = "(`applicationId` = '${data.newrelic_entity.todo_app.application_id}')"

  # Define a critical alert threshold that will trigger after 5 minutes above 50% CPU utilization.
  critical {
    duration      = 5
    value         = 50
    time_function = "all"
  }
}

# Slack notification channel
resource "newrelic_alert_channel" "slack_notification" {
  name = "todo-app-slack"
  type = "slack"

  config {
    # Use the URL provided in your New Relic Slack integration
    url     = var.slack_url
    channel = "todo-app"
  }
}

resource "newrelic_alert_policy_channel" "ChannelSubs" {
  policy_id  = newrelic_alert_policy.slack_notification.id
  channel_ids = [
    newrelic_alert_channel.slack_notification.id
  ]
}