dashboard "guardrails_dashboard" {

  title = "Workspace Summary"

  tags = {
    service  = "Guardrails"
    plugin   = "guardrails"
    type     = "Report"
    category = "Summary"
  }

  # Analysis
  container {

    card {
      sql   = query.workspace_count.sql
      width = 3
    }

    card {
      sql   = query.total_te_installations.sql
      width = 3
    }
  }

  # Analysis
  container {
    table {
      width = 12
      sql   = query.workspace_stats.sql
    }
  }

}

query "workspace_version" {
  sql = <<-EOQ
    select
      workspace as "Workspace URL",
      value as "TE Version"
    from
      guardrails_policy_setting
    where
      policy_type_uri = 'tmod:@turbot/turbot#/policy/types/workspaceVersion'
    order by
      value;
  EOQ
}

query "total_te_installations" {
  sql = <<-EOQ
    select
      COUNT(DISTINCT value) as "TE Installations"
    from
      guardrails_policy_setting
    where
      policy_type_uri = 'tmod:@turbot/turbot#/policy/types/workspaceVersion'
  EOQ
}

query "workspace_count" {
  sql = <<-EOQ
    select
      count(workspace) as "Workspaces"
    from
      guardrails_resource
    where
      resource_type_uri = 'tmod:@turbot/turbot#/resource/types/turbot';
  EOQ
}


query "workspace_stats" {
  sql = <<-EOQ

  select
    to_char(current_timestamp, 'YYYY-MM-DD') AS "Date",
    workspace as "Workspace",
    output -> 'teVersion' ->> 'value' as "TE Version",
    output -> 'accounts' -> 'metadata' -> 'stats' ->> 'total' as "Accounts",
    output -> 'resources' -> 'metadata' -> 'stats' ->> 'total' as "Resources",
    output -> 'total_controls' -> 'metadata' -> 'stats' ->> 'total' as "Controls",
    output -> 'alerts' -> 'metadata' -> 'stats' ->> 'total' as "Alerts"
  from
    guardrails_query
  where
    query = '{
      teVersion: policySetting(uri: "tmod:@turbot/turbot#/policy/types/workspaceVersion" resourceId: "tmod:@turbot/turbot#/") {
        value
      }

      accounts: resources(filter: "resourceTypeId:tmod:@turbot/turbot#/resource/interfaces/accountable level:self") {
        metadata {
          stats {
            total
          }
        }
      }

      resources: resources(filter: "resourceTypeId:tmod:@turbot/aws#/resource/types/aws,tmod:@turbot/azure#/resource/types/azure,tmod:@turbot/gcp#/resource/types/gcp") {
        metadata {
          stats {
            total
          }
        }
      }

      alerts: controls(filter:"state:alarm,invalid,error") {
        metadata {
          stats {
            total
          }
        }
      }

      total_controls: controls {
        metadata {
          stats {
            total
          }
        }
      }

    }'
  order by "Workspace"
  EOQ
}
