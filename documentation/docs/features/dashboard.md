# Agent Dashboard

The dashboard provides a visual overview of all your agents, their status, and quick controls for management.

## Accessing the Dashboard

Tap the **Agents** tab at the bottom of the screen to access the dashboard.

## Dashboard Layout

### Quick Stats

At the top, see at-a-glance metrics:

| Stat | Description |
|------|-------------|
| **Active** | Number of agents currently running |
| **Scheduled** | Tasks queued for upcoming execution |
| **Executions** | Total runs across all agents |

### Category Tabs

Filter agents by category:

- **All Agents** - View everything
- **Social Media** - Instagram, Twitter, LinkedIn agents
- **Communication** - Email, messaging agents
- **Shopping** - Price tracking, deal alert agents

### Agent Cards

Each agent displays:

- **Name** - Agent identifier
- **Description** - What the agent does
- **Status** - Active or Paused (with toggle)
- **Schedule** - How often it runs
- **Last Run** - When it last executed
- **Execution Count** - Total successful runs

## Agent Card Actions

### Toggle Active/Paused

Tap the switch on any agent card to:

- **Pause** - Stop scheduled executions
- **Resume** - Restart scheduled executions

### View Details

Tap an agent card to see:

- Full execution history
- Detailed configuration
- Results and screenshots
- Error logs

### Quick Menu

Long-press an agent card for:

- Run Now
- Edit
- Duplicate
- Delete

## Creating New Agents

### Floating Action Button

Tap the **+** button in the bottom right to:

- **Create with Conversation** - Describe in natural language
- **Setup Wizard** - Use guided templates
- **Import** - Load from configuration file

### Quick Setup

The dashboard offers quick access to common agent types:

1. Tap **+**
2. Select a template category
3. Follow the guided setup

## Managing Agents

### Bulk Actions

Select multiple agents for bulk operations:

1. Long-press to start selection mode
2. Tap additional agents to select
3. Choose action from the toolbar:
   - Pause All
   - Resume All
   - Delete Selected

### Search and Filter

Find specific agents:

- Use the search bar at the top
- Filter by status (Active/Paused)
- Filter by category

### Sort Options

Organize the list by:

- Name (A-Z / Z-A)
- Last Run (Recent first)
- Execution Count (Most active)
- Created Date

## Agent Detail View

Tap any agent to see full details:

### Overview Tab

- Agent name and description
- Current status
- Schedule configuration
- Key settings

### History Tab

Execution log showing:

- Timestamp
- Duration
- Status (Success/Failed)
- Result summary

Tap any execution to see:

- Full step-by-step log
- Screenshots captured
- Data extracted
- Errors encountered

### Settings Tab

Modify agent configuration:

- Name and description
- Schedule and frequency
- Notification preferences
- Confirmation requirements

### Results Tab

For data-gathering agents:

- Collected data
- Charts and trends
- Export options

## Status Indicators

### Agent States

| Icon | Status | Description |
|------|--------|-------------|
| Green dot | Active | Running on schedule |
| Yellow dot | Paused | Temporarily stopped |
| Blue spinner | Running | Currently executing |
| Red dot | Failed | Last run had errors |

### Execution States

| Icon | State | Description |
|------|-------|-------------|
| Checkmark | Success | Completed successfully |
| X | Failed | Encountered an error |
| Clock | Scheduled | Waiting to run |
| Spinner | In Progress | Currently running |

## Dashboard Widgets

### Recent Activity

Shows the latest agent actions:

- Which agent ran
- What it found
- When it happened

### Upcoming Schedule

View what's scheduled:

- Next 24 hours of planned executions
- Agent names and run times

### Performance Summary

Weekly performance overview:

- Total executions
- Success rate
- Most active agents

## Tips for Dashboard Use

!!! tip "Regular Review"
    Check the dashboard daily to ensure agents are running as expected.

!!! tip "Use Categories"
    Filter by category to focus on specific types of agents.

!!! tip "Monitor Failures"
    Pay attention to failed executions and investigate promptly.

!!! tip "Archive Unused"
    Pause or delete agents you no longer need to keep the dashboard clean.

## Troubleshooting

### No Agents Showing

- Ensure you've created agents
- Check the active filter isn't hiding them
- Try refreshing the page

### Agent Not Running

- Verify it's not paused
- Check the schedule configuration
- Review device conditions (battery, WiFi)
- Ensure permissions are granted

### Stats Not Updating

- Pull down to refresh
- Check internet connection
- Restart the app if persistent

## Next Steps

- [Create your first agent](../getting-started/quick-start.md)
- [Learn about agent types](../agents/overview.md)
- [Configure settings](../configuration/settings.md)
