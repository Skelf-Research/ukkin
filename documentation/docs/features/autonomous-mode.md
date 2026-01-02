# Autonomous Mode

Autonomous mode lets Ukkin work independently, making decisions and taking actions without requiring your constant input.

## What is Autonomous Mode?

When enabled, Ukkin can:

- Interpret high-level objectives
- Plan and execute multi-step tasks
- Make decisions based on context
- Learn from outcomes
- Adapt strategies over time

## Enabling Autonomous Mode

### From Chat Interface

1. Tap the **Autonomous** toggle in the chat header
2. Confirm you understand the capabilities
3. Mode becomes active

### Setting Objectives

When autonomous mode is enabled, set objectives:

```
You: "Monitor my investment portfolio and alert me to any
     significant changes. Use your judgment on what's significant."

Ukkin: "Autonomous mode active. I'll monitor your portfolio
       with these guidelines:
       - Alert on changes > 3%
       - Daily summary of all movements
       - Immediate alert on unusual activity"
```

## How It Works

### Objective Interpretation

Ukkin breaks down your high-level goals:

```
Objective: "Keep my inbox under control"

Interpreted as:
1. Check inbox regularly
2. Archive old, unread emails
3. Flag potentially important items
4. Notify about urgent messages
5. Provide weekly summary
```

### Decision Making

Ukkin makes autonomous decisions:

- Prioritizes tasks based on importance
- Chooses optimal execution times
- Handles errors and retries
- Adjusts strategies based on results

### Learning

Over time, Ukkin learns:

- Your preferences
- What you consider important
- Optimal times to notify you
- Patterns in your digital life

## Use Cases

### Portfolio Monitoring

```
Objective: "Watch my investments"

Ukkin will:
- Track your portfolio daily
- Identify significant changes
- Alert on unusual movements
- Provide market context
- Suggest when to check in
```

### Inbox Management

```
Objective: "Manage my email so I only see what matters"

Ukkin will:
- Triage incoming emails
- Filter based on learned preferences
- Highlight truly important items
- Archive noise automatically
- Summarize what you missed
```

### Social Monitoring

```
Objective: "Keep me informed about my brand online"

Ukkin will:
- Monitor mentions across platforms
- Assess sentiment
- Prioritize by reach and importance
- Alert on negative trends
- Summarize positive engagement
```

### Life Organization

```
Objective: "Help me stay on top of things"

Ukkin will:
- Track deadlines from emails
- Monitor bills and subscriptions
- Remind about important dates
- Organize incoming information
- Suggest actions when needed
```

## Autonomous Features

### Proactive Suggestions

Ukkin may suggest actions:

```
Ukkin: "I noticed you often check Twitter around 9 AM.
       Should I create a morning summary of relevant tweets?"
```

### Automatic Adjustments

Adapts to your behavior:

```
Ukkin: "Your price alert threshold of 10% resulted in
       many notifications. I've adjusted to 15% for less
       important items. Let me know if you prefer otherwise."
```

### Context Awareness

Considers broader context:

```
Ukkin: "It's Black Friday week. I'm checking prices more
       frequently and lowering alert thresholds for items
       on your wishlist."
```

## Control and Oversight

### Activity Log

View everything Ukkin does:

1. Go to **Settings** > **Autonomous Log**
2. See all actions taken
3. Review decisions made
4. Understand reasoning

### Approval Levels

Configure what requires your approval:

| Level | Description |
|-------|-------------|
| **Full Autonomy** | Ukkin acts independently |
| **Notify Only** | Actions taken, but you're notified |
| **Ask First** | Confirmation before significant actions |
| **Supervised** | All actions require approval |

### Override Actions

Correct Ukkin when needed:

```
You: "Don't archive emails from my mom, even if they look like forwards"

Ukkin: "Understood. I'll never archive emails from contacts
       you consider family, regardless of content."
```

## Safety Features

### Action Limits

Autonomous mode has built-in limits:

- Maximum actions per hour
- Cool-down periods for repeated actions
- Escalation to user for unusual patterns

### Undo Capability

Most autonomous actions can be undone:

- Archived emails can be restored
- Paused agents can be resumed
- Changes are logged for review

### Emergency Stop

Disable autonomous mode instantly:

1. Say "Stop autonomous mode"
2. Or tap the toggle in chat
3. Or use the notification quick action

## Best Practices

!!! tip "Start Broad"
    Begin with general objectives and refine based on results.

!!! tip "Review Regularly"
    Check the activity log weekly to understand decisions.

!!! tip "Provide Feedback"
    Tell Ukkin when it makes good or bad decisions.

!!! tip "Set Boundaries"
    Be clear about what should never be automated.

## Example Configurations

### Conservative

```
Approval: Ask First
Notifications: All actions
Learning: Slow
Actions: Monitoring only
```

### Balanced

```
Approval: Notify Only
Notifications: Significant actions
Learning: Normal
Actions: Monitoring + organization
```

### Full Trust

```
Approval: Full Autonomy
Notifications: Summaries only
Learning: Aggressive
Actions: All permitted
```

## Limitations

!!! warning "Financial Actions"
    Autonomous mode cannot make purchases or financial transactions.

!!! warning "Account Changes"
    Cannot change passwords, security settings, or account information.

!!! warning "Destructive Actions"
    Cannot permanently delete data without explicit permission.

## Troubleshooting

### Too Many Notifications

```
You: "You're notifying me too often"
Ukkin: "I'll raise my thresholds. You'll only hear about
       truly significant events now."
```

### Missing Important Items

```
You: "You missed an important email from my boss"
Ukkin: "I'll prioritize all emails from that sender.
       Do you want immediate alerts for them?"
```

### Unexpected Actions

Review the activity log and provide feedback:

```
You: "Why did you archive that email?"
Ukkin: "It matched your 'promotional' pattern. I'll ask
       before archiving emails from new senders."
```

## Next Steps

- [Configure settings](../configuration/settings.md) for autonomous mode
- [Security overview](../security/overview.md) for safety features
- [Chat interface](chat-interface.md) for manual control
