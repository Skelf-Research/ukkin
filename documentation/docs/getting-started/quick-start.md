# Quick Start Guide

Create your first Ukkin agent in under 5 minutes.

## Your First Agent

Let's create a simple price monitoring agent that tracks a product on Amazon.

### Step 1: Open the Agent Builder

1. Open Ukkin and go to the **Agents** tab
2. Tap the **+** floating action button
3. Select **Create with Conversation**

### Step 2: Describe Your Agent

In the chat interface, describe what you want:

```
I want to track the price of AirPods Pro on Amazon and notify me when the price drops below $200
```

Ukkin will understand your request and ask clarifying questions like:

- How often should it check? (hourly, daily, weekly)
- Which notification method do you prefer?

### Step 3: Review the Flow

Before creating the agent, Ukkin shows you a preview of the steps:

1. Open Amazon app
2. Search for "AirPods Pro"
3. Extract current price
4. Compare with target price ($200)
5. If lower, send notification

Tap **Create Agent** to confirm.

### Step 4: Activate Your Agent

Your new agent appears in the dashboard. It will:

- Run automatically on the schedule you set
- Send notifications when the price drops
- Show execution history in the agent details

## Using Template Agents

For common tasks, use pre-built templates:

1. Go to **Agents** tab
2. Tap **+** button
3. Select **Setup Wizard**
4. Choose a category:
   - **Social Media** - Instagram, Twitter, LinkedIn monitoring
   - **Communication** - Email triage, message management
   - **Shopping** - Price tracking, deal alerts

Follow the wizard steps to configure your agent.

## Quick Actions

### Start an Agent Manually
Tap the agent card, then tap **Run Now** to execute immediately.

### Pause an Agent
Toggle the switch on any agent card to pause/resume it.

### View Results
Tap an agent to see its execution history and results.

## Example Agent Ideas

Here are some agents you can create:

| Agent | Description |
|-------|-------------|
| **Competitor Tracker** | Monitor a competitor's Instagram for new posts |
| **Email Triage** | Automatically sort emails into folders |
| **Deal Finder** | Alert when items on your wishlist go on sale |
| **Newsletter Cleanup** | Archive all newsletter emails weekly |
| **Price History** | Track and log prices of products over time |

## Tips for Success

!!! tip "Be Specific"
    The more specific your description, the better. Include app names, exact actions, and desired outcomes.

!!! tip "Start Simple"
    Begin with simple, single-app agents before creating complex multi-app workflows.

!!! tip "Check Permissions"
    Ensure you've granted the necessary [permissions](permissions.md) for app automation.

## Next Steps

- [Set up permissions](permissions.md) for full automation capabilities
- Explore [agent types](../agents/overview.md) in detail
- Learn about [autonomous mode](../features/autonomous-mode.md)
