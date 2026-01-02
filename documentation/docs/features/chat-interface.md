# Chat Interface

The chat interface is your primary way to interact with Ukkin. Communicate naturally with your AI assistant to create agents, check status, and manage your automations.

## Overview

The chat interface combines:

- **Natural language interaction** - Talk to Ukkin like you would a human assistant
- **Real-time status** - See what your agents are doing
- **Agent creation** - Build new automations through conversation
- **Memory** - Context that persists across sessions

## Interface Elements

### Message Area

The main area displays your conversation:

- **Your messages** - Displayed on the right
- **Ukkin responses** - Displayed on the left with AI indicator
- **Status updates** - System messages about agent activity
- **Error messages** - Alerts when something needs attention

### Input Bar

At the bottom of the screen:

- Text input field
- Send button
- Attachment options (when applicable)
- Voice input toggle

### Status Bar

Shows recent agent activity:

- Last executed agent
- Execution result (success/failure)
- Quick access to agent details

## Basic Interaction

### Asking Questions

Get information about your agents:

```
You: "What agents do I have running?"
Ukkin: "You have 3 active agents:
- Instagram Tracker (checking @competitor, runs hourly)
- Email Triage (organizing inbox, runs daily at 7 AM)
- Price Watch (tracking AirPods, runs every 2 hours)"
```

### Creating Agents

Describe what you want automated:

```
You: "I want to track Bitcoin price and notify me when it drops below $40,000"
Ukkin: "I'll create a price tracking agent for you. A few questions:
- How often should I check? (every hour / every 6 hours / daily)
- Where should I check the price? (CoinGecko / Binance / CoinMarketCap)"
```

### Managing Agents

Control your agents through chat:

```
You: "Pause the Instagram tracker"
Ukkin: "Done! The Instagram Tracker agent is now paused.
Say 'resume Instagram tracker' when you want it running again."
```

## Message Types

### User Messages
Your input appears with:

- Right alignment
- Your profile indicator
- Timestamp

### Agent Responses
Ukkin's replies include:

- Left alignment
- AI indicator
- Formatted text with markdown support
- Action buttons when applicable

### Status Messages
System updates show:

- Neutral styling
- Icon indicating type (success, warning, info)
- Related agent name

### Error Messages
Alerts appear with:

- Warning styling
- Clear error description
- Suggested resolution

## Features

### Conversation Memory

Ukkin remembers:

- Previous conversations
- Your preferences
- Created agents and their configurations
- Past execution results

View memory stats by asking:
```
You: "What do you remember about me?"
```

### Chat Export

Save your conversation history:

1. Tap the menu icon
2. Select **Export Chat**
3. Choose format (Text, JSON)
4. Share or save

### Clear History

Start fresh:

1. Tap the menu icon
2. Select **Clear Chat**
3. Confirm deletion

!!! note
    Clearing chat doesn't delete your agents or their data.

## Smart Commands

### Quick Actions

Use these shortcuts:

| Command | Action |
|---------|--------|
| "Show agents" | List all agents |
| "Run [agent name]" | Execute immediately |
| "Pause [agent name]" | Pause agent |
| "Resume [agent name]" | Resume agent |
| "Delete [agent name]" | Remove agent |
| "Status" | Show overall status |

### Natural Variations

Ukkin understands variations:

- "What's the status of my agents?"
- "How are my automations doing?"
- "Any updates from my agents?"

All mean the same thing.

## Tips for Better Conversations

### Be Specific

Instead of:
```
"Make a tracker"
```

Say:
```
"Create an agent to track iPhone 15 prices on Amazon
and notify me when it drops below $800"
```

### Provide Context

Include relevant details:
```
"I want to monitor my competitor @techstartup on Instagram.
They post about twice a day, so checking every 3 hours
should be enough. Save screenshots of new posts."
```

### Ask for Clarification

If unsure, ask:
```
You: "What can you automate?"
You: "What apps do you support?"
You: "How does the price tracker work?"
```

## Conversation Flow for Agent Creation

### 1. Initial Request

You describe what you want:
```
You: "Help me manage my newsletter subscriptions"
```

### 2. Clarification

Ukkin asks for details:
```
Ukkin: "I can help with that! A few questions:
- Which email app? (Gmail / Outlook)
- What should I do with newsletters?
  (Archive / Move to folder / Keep but mark read)
- How often? (Daily / Weekly)"
```

### 3. Confirmation

Review before creating:
```
Ukkin: "Here's what I'll set up:
- Check Gmail every morning at 7 AM
- Move newsletters to 'Newsletters' folder
- Keep last 7 days, archive older
Does this look right?"
```

### 4. Creation

Agent is created:
```
You: "Yes, create it"
Ukkin: "Done! Newsletter Manager is now active.
It will run tomorrow at 7 AM. Want me to run it now?"
```

## Editing Agents via Chat

Modify existing agents:

```
You: "Change the Instagram tracker to check every 4 hours instead"
Ukkin: "Updated! Instagram Tracker now checks every 4 hours
instead of every hour."
```

```
You: "Add @another_account to the Instagram tracker"
Ukkin: "Added! Instagram Tracker now monitors both
@competitor and @another_account."
```

## Troubleshooting

### Ukkin Doesn't Understand

Try rephrasing:
```
You: "Track stuff on Insta"
Ukkin: "I'm not sure what you'd like to track. Could you be more specific?
For example: 'Track @username on Instagram for new posts'"
```

### Slow Responses

If responses are slow:

- Check your internet connection
- Restart the app
- The AI model may be processing complex requests

### Commands Not Working

Ensure:

- Agent names are spelled correctly
- The agent exists
- You have necessary permissions

## Next Steps

- [Agent Dashboard](dashboard.md) - View and manage all agents
- [Autonomous Mode](autonomous-mode.md) - Let Ukkin work independently
- [Configuration](../configuration/settings.md) - Customize chat behavior
