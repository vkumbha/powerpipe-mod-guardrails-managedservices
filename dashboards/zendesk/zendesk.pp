dashboard "zendesk_dashboard" {
  # title = "Ticket Summary"

  tags = {
    service  = "Zendesk"
    plugin   = "zendesk"
    type     = "Dashboard"
    category = "Summary"
  }

  container {

    card {
      width = "12"
      sql   = query.zendesk_organization_name.sql
      args  = [var.organization_id]
    }
  }

  container {

    card {
      width = "3"
      sql   = query.zendesk_ticket_total_age.sql
      args  = [var.organization_id]
    }

    card {
      width = "3"
      sql   = query.zendesk_oldest_unsolved_ticket.sql
      args  = [var.organization_id]
    }

    card {
      width = "3"
      sql   = query.zendesk_unsolved_tickets_count.sql
      args  = [var.organization_id]
    }
  }
  container {
    card {
      width = "3"
      type  = "info"
      sql   = query.zendesk_open_tickets_count.sql
      args  = [var.organization_id]
    }

    card {
      width = "3"
      type  = "info"
      sql   = query.zendesk_awaiting_your_reply_tickets_count.sql
      args  = [var.organization_id]
    }

    card {
      width = "3"
      type  = "info"
      sql   = query.zendesk_awaiting_your_action_tickets_count.sql
      args  = [var.organization_id]
    }

    card {
      width = "3"
      type  = "info"
      sql   = query.zendesk_hold_tickets_count.sql
      args  = [var.organization_id]
    }


    # chart {
    #   width    = 4
    #   type     = "donut"
    #   grouping = "compare"
    #   title    = "Unsolved Tickets by Status"
    #   sql      = query.tickets_by_status.sql
    #   args     = [var.organization_id]
    # }

    #   chart "issue_age_stats" {
    #     type  = "column"
    #     title = "Issue Age Stats:"
    #     width = 4
    #     args  = [var.organization_id]

    #     sql = <<-EOQ
    #   WITH age_counts AS (
    #     SELECT
    #       CASE
    #         WHEN now()::date - created_at::date > 42 THEN '>6 Weeks'
    #         WHEN now()::date - created_at::date > 21 THEN '>3 Weeks'
    #         WHEN now()::date - created_at::date > 7 THEN '>1 Week'
    #       END AS age_group,
    #       1 AS issue_count
    #     FROM
    #       zendesk_ticket
    #     WHERE
    #       status IN ('new', 'open', 'pending', 'hold')
    #       and organization_id = $1
    #   )
    #   SELECT
    #     age_group,
    #     COUNT(issue_count) AS count_of_issues
    #   FROM
    #     age_counts
    #   WHERE
    #     age_group IS NOT NULL
    #   GROUP BY
    #     age_group
    #   ORDER BY
    #     age_group;
    # EOQ
    #   }

    table {
      column "Ticket" {
        href = <<-EOT
          https://support.turbot.com/hc/en-us/requests/{{.Ticket | @uri}}
        EOT
      }
      title = "Open Tickets"
      sql   = query.new_and_open_tickets_report.sql
      args  = [var.organization_id]
    }

    table {
      column "Ticket" {
        href = <<-EOT
          https://support.turbot.com/hc/en-us/requests/{{.'Ticket' | @uri}}
        EOT
      }
      title = "All Unsolved Tickets"
      sql   = query.all_unsolved_tickets_report.sql
      args  = [var.organization_id]
    }

  }
}

query "zendesk_ticket_total_age" {
  sql = <<-EOQ
  select
      sum(date_part('day', now() - t.created_at)) as "Total Tickets Age (days)"
    from
      zendesk_ticket as t
    where
      t.status in ('new', 'open', 'pending')
      and organization_id = $1
  EOQ
}

query "zendesk_oldest_unsolved_ticket" {
  sql = <<-EOQ
    SELECT
      date_part('day', now() - t.created_at) as "Oldest Ticket Age (days)"
    FROM
      zendesk_ticket as t
    WHERE
      t.status IN ('new', 'open', 'pending')
      and organization_id = $1
    ORDER BY
      t.created_at ASC
    LIMIT 1
  EOQ
}

query "zendesk_unsolved_tickets_count" {
  sql = <<-EOQ
    select count(*) as "Unsolved Tickets" from zendesk_ticket where status not in ('closed','solved', 'hold') and organization_id = $1
  EOQ
}

query "zendesk_open_tickets_count" {
  sql = <<-EOQ
    select count(*) as "Open" from zendesk_ticket where status in ('open', 'new') and organization_id = $1
  EOQ
}

query "zendesk_awaiting_your_reply_tickets_count" {
  sql = <<-EOQ
SELECT count(*) as "Awaiting Your Reply"
 FROM
   zendesk_ticket 
 WHERE
   status = 'pending'
   AND NOT EXISTS 
   (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action')
   AND organization_id = $1
  EOQ
}

query "zendesk_awaiting_your_action_tickets_count" {
  sql = <<-EOQ
SELECT count(*) as "Awaiting Your Action"
 FROM
   zendesk_ticket 
 WHERE
   status = 'pending'
   AND EXISTS 
   (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action')
   AND organization_id = $1
  EOQ
}

query "zendesk_hold_tickets_count" {
  sql = <<-EOQ
    select count(*) as "Feature Requests" from zendesk_ticket where status = 'hold' and organization_id = $1
  EOQ
}

query "new_and_open_tickets_report" {
  sql = <<-EOQ
    select
      t.id as "Ticket",
      substring(t.subject for 100) as "Subject",
      date_part('day', now() - t.created_at) as "Age (Days)",
      -- date_part('day', now() - t.updated_at) as "Last Update (Days)",
      t.status as "Status",
      t.priority as "Priority"
    from
      zendesk_ticket as t
    where
      t.status in ('new', 'open')
      and t.organization_id = $1
    order by
      "Ticket" asc
  EOQ
}

query "all_unsolved_tickets_report" {
  sql = <<-EOQ
  SELECT
    t.id AS "Ticket",
    SUBSTRING(t.subject FOR 100) AS "Subject",
    date_part('day', now() - t.created_at) as "Age (Days)",
    -- date_part('day', now() - t.updated_at) as "Last Update (Days)",
    CASE
      WHEN t.status = 'pending' AND EXISTS (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action') THEN 'customer_action'
      WHEN t.status = 'pending' AND NOT EXISTS (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action') THEN 'customer_reply'
      ELSE t.status 
    END AS "Status",
    t.priority as "Priority"
  FROM
    zendesk_ticket AS t
  WHERE
    t.status IN ('new', 'open', 'pending', 'hold')
    AND t.organization_id = $1
  ORDER BY
    "Ticket" asc
  EOQ
}

# query "tickets_by_status" {
#   sql = <<-EOQ
#     select
#     CASE
#       WHEN t.status = 'pending' AND EXISTS (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action') THEN 'customer_action'
#       WHEN t.status = 'pending' AND NOT EXISTS (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action') THEN 'customer_reply'
#       ELSE t.status 
#     END AS "Status",
#       count(Status)
#     from
#       zendesk_ticket as t
#     where
#       status in ('new','open','pending','hold')
#       and organization_id = $1
#     group by
#       "Status"
#   EOQ
# }

query "zendesk_organization_name" {
  sql = <<-EOQ
    SELECT 'Ticket Summary - ' || name as " " FROM zendesk_organization  WHERE id = $1;
  EOQ  
}
