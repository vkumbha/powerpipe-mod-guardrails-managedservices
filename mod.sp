mod "guardrails_managedservices" {
  # hub metadata
  title       = "Turbot Guardrails Managed Services"
  description = "Create dashboards and reports for your Turbot Guardrails resources using Steampipe."
  # color         = "#0089D6"
  # documentation = file("./docs/index.md")
  # icon          = "/images/mods/turbot/kubernetes-insights.svg"
  categories = ["guardrails", "dashboard", "security"]

  opengraph {
    title       = "Steampipe Mod for Turbot Guardrails Managed Services"
    description = "Create dashboards and reports for your Turbot Guardrails resources using Steampipe."
    # image        = "/images/mods/turbot/kubernetes-insights-social-graphic.png"
  }

  require {
    steampipe = "0.22.0"
    plugin "guardrails" {
      min_version = "0.16.0"
    }
    plugin "zendesk" {
      min_version = "0.8.0"
    }
  }

}
