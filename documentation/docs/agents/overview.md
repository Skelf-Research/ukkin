# Agent Overview

Agents are the core of Ukkin. They're intelligent automations that run on your device, performing tasks in the background without requiring your constant attention.

## What is an Agent?

An agent is an automated workflow that:

- Runs on a schedule you define
- Interacts with apps on your device
- Monitors for specific conditions
- Takes actions when conditions are met
- Reports results back to you

## Agent Categories

Ukkin provides four main categories of agents:

### Social Media Agents
Monitor and track activity across social platforms like Instagram, Twitter, LinkedIn, and Facebook.

[Learn more about Social Media Agents](social-media.md)

### Communication Agents
Manage your inbox, organize messages, and automate responses across email and messaging apps.

[Learn more about Communication Agents](communication.md)

### Shopping Agents
Track prices, find deals, and monitor your wishlist across e-commerce platforms.

[Learn more about Shopping Agents](shopping.md)

### Custom Agents
Create any automation using natural language descriptions for unique workflows.

[Learn more about Custom Agents](custom.md)

## Agent Lifecycle

### 1. Creation
Create agents using either:
- **Conversational Builder** - Describe in natural language
- **Setup Wizard** - Follow guided templates

### 2. Configuration
Set up:
- **Schedule** - When and how often to run
- **Conditions** - Requirements like WiFi, battery level
- **Notifications** - How to be alerted of results

### 3. Execution
Agents run automatically based on your schedule:
- Background execution without opening the app
- Respects device conditions
- Captures results and screenshots

### 4. Reporting
View results in:
- Dashboard statistics
- Agent detail screens
- Notification alerts

## Agent States

| State | Description |
|-------|-------------|
| **Active** | Running on schedule |
| **Paused** | Temporarily stopped, can be resumed |
| **Running** | Currently executing |
| **Failed** | Last execution had an error |
| **Completed** | Successfully finished last run |

## Scheduling Options

Configure how often agents run:

- **Hourly** - Every hour
- **Daily** - Once per day at preferred time
- **Weekly** - Specific days of the week
- **On Demand** - Manual execution only

### Smart Scheduling

Agents can be configured to only run when:

- Device is on WiFi
- Battery is above a threshold
- Specific apps are not in use
- During quiet hours

## Creating Your First Agent

### Method 1: Conversational Builder

1. Tap **+** on the Agents tab
2. Select **Create with Conversation**
3. Describe your automation:
   ```
   Check my Instagram competitor @brand every morning
   and save their new posts
   ```
4. Answer clarifying questions
5. Review and confirm the flow

### Method 2: Setup Wizard

1. Tap **+** on the Agents tab
2. Select **Setup Wizard**
3. Choose a category
4. Follow the step-by-step configuration
5. Review and create

## Managing Agents

### From the Dashboard

- **Toggle Active/Paused** - Tap the switch on agent cards
- **Run Now** - Manually trigger an agent
- **View Details** - Tap the card to see history
- **Edit** - Modify agent configuration
- **Delete** - Remove the agent

### Agent Settings

Each agent has configurable settings:

- **Name** - Display name in dashboard
- **Description** - What the agent does
- **Schedule** - When to run
- **Confirmation** - Require approval before actions
- **Notifications** - Alert preferences

## Execution Limits

To protect device performance:

- Maximum concurrent agents: 3 (configurable)
- Execution timeout: 5 minutes per agent
- Retry on failure: 3 attempts

## Best Practices

!!! tip "Keep Agents Focused"
    Create separate agents for different tasks rather than one complex agent.

!!! tip "Start with Monitoring"
    Begin with agents that only read/monitor before creating ones that take actions.

!!! tip "Use Confirmation Mode"
    Enable confirmation for agents that take important actions so you can review before execution.

!!! tip "Monitor Battery Usage"
    Check agent execution history if you notice unusual battery drain.

## Next Steps

- [Social Media Agents](social-media.md)
- [Communication Agents](communication.md)
- [Shopping Agents](shopping.md)
- [Custom Agents](custom.md)
