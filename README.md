# Ukkin

**Create AI agents on your phone that automate your daily tasks.**

Your phone is always on, always with you. Ukkin lets you build personal AI agents that work in the background - checking prices, monitoring social media, triaging emails, or running any workflow you describe in plain English.

## The Idea

Tell Ukkin what you want automated:

> "Watch for price drops on items in my Amazon wishlist and notify me"

> "Every morning, summarize my unread emails and flag anything urgent"

> "Monitor my Instagram mentions and draft responses for review"

Ukkin converts your description into a working agent that runs on your device, respecting battery life and network conditions.

## Key Features

**Conversational Agent Builder**
Describe what you want in natural language. Ukkin extracts the workflow, shows you the steps, and creates the agent.

**Device-Aware Scheduling**
Agents run when conditions are right - on WiFi, while charging, at specific times, or when the app you need is available.

**Deep App Integration**
Automate across WhatsApp, Email, Instagram, Amazon, Calendar, and more. Agents can read screens, tap buttons, and move data between apps.

**On-Device Processing**
All AI runs locally. Your data never leaves your phone.

## Agent Types

- **Social Media**: Monitor mentions, auto-engage, track followers
- **Communication**: Email triage, message drafting, contact management
- **Shopping**: Price watching, deal alerts, wishlist monitoring
- **Custom**: Build anything from a conversation

## Getting Started

```bash
git clone https://github.com/anthropics/ukkin.git
cd ukkin
flutter pub get
flutter run
```

Requires Flutter 3.1.5+, Android API 21+ or iOS 11+.

## Architecture

Ukkin uses [AgentLib](../agentlib/), a standalone SDK for mobile AI agents. The core abstractions:

- `RepetitiveTaskAgent`: Background tasks that run on schedule
- `TaskScheduler`: Coordinates agents based on device state
- `AppPluginSystem`: Modular integrations for each app
- `RealAutomation`: Accessibility service bridge for screen interaction

## Current Status

**Working:**
- Android Accessibility Service for screen automation
- Real screen reading and element finding
- Tap, type, scroll, swipe operations
- App launching and navigation
- Price extraction and tracking with history
- Instagram post/follower monitoring
- Email classification and organization

**Requires:**
- Accessibility service enabled in Android Settings
- Target apps installed on device

## Roadmap

### Phase 1: Core Automation (Current)
- Screen scraping via accessibility service
- Basic agents: Instagram, Email, Price watching
- Local storage for tracking data

### Phase 2: Intelligence
- On-device LLM for natural language understanding
- Smarter element matching using context
- Agent composition (chain multiple agents)

### Phase 3: Advanced Agents
- Calendar integration and scheduling
- Cross-app workflows (e.g., email → calendar → reminder)
- Voice-triggered agent creation
- Notification-based triggers

### Phase 4: Platform Expansion
- iOS automation support
- Desktop companion app
- Agent marketplace/sharing

## Contributing

This is an experimental project exploring on-device AI agents. Contributions welcome for:
- New agent implementations
- App handler improvements
- Accessibility service enhancements
- iOS support

## License

MIT