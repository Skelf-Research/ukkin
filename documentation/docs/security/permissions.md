# Permissions Guide

This guide explains every permission Ukkin requests and how to manage them effectively.

## Permission Philosophy

Ukkin follows the principle of least privilege:

- Only request what's necessary
- Allow granular control
- Explain why each permission is needed
- Work with reduced permissions when possible

## System Permissions

### Accessibility Service

**Purpose:** Read screen content and perform automated actions

**Used for:**
- Reading text from apps
- Tapping buttons and links
- Typing text
- Navigating between screens

**Without it:**
- Agents cannot interact with apps
- Only chat functionality works

**Privacy note:** Can see all screen content, but Ukkin only processes what agents need.

### Display Over Other Apps

**Purpose:** Show status indicators and confirmations

**Used for:**
- Floating status indicator
- Confirmation dialogs
- Quick action buttons

**Without it:**
- Must open Ukkin to see status
- Confirmations require app switch

### Notifications

**Purpose:** Send alerts about agent activity

**Used for:**
- Execution complete alerts
- Error notifications
- Result summaries
- Action reminders

**Without it:**
- No proactive alerts
- Must check app manually

### Storage

**Purpose:** Save screenshots and export data

**Used for:**
- Saving captured screenshots
- Exporting agent data
- Storing large files

**Without it:**
- Cannot save screenshots
- Cannot export data

### Background Activity

**Purpose:** Run agents when app is closed

**Used for:**
- Scheduled agent execution
- Continuous monitoring
- Background processing

**Without it:**
- Agents only run when app is open
- No scheduled execution

## App-Specific Permissions

### Per-Agent App Access

Each agent has specific app permissions:

1. Open agent settings
2. Go to **App Access**
3. See which apps the agent can access
4. Toggle individual app access

### Adding App Access

When creating an agent:

1. Specify which apps it needs
2. Review requested access
3. Approve or deny

### Revoking App Access

Remove access anytime:

1. Go to agent settings
2. **App Access** > Select app
3. Toggle off
4. Agent can no longer access that app

## Permission Levels

### Read Only

Agent can:
- View screen content
- Extract text
- Take screenshots

Agent cannot:
- Tap elements
- Type text
- Navigate

### Read and Interact

Agent can:
- Everything in Read Only
- Tap buttons and links
- Scroll content
- Type text

### Full Control

Agent can:
- Everything in Read and Interact
- Navigate between apps
- Use hardware buttons
- Manage notifications

## Blocked Apps

### Setting Up Blocklist

Prevent any agent from accessing certain apps:

1. **Settings** > **Privacy** > **Blocked Apps**
2. Tap **Add App**
3. Select apps to block
4. Confirm

### Recommended Blocks

Consider blocking:

| App Type | Examples | Reason |
|----------|----------|--------|
| Banking | Chase, PayPal | Financial security |
| Password Managers | 1Password, Bitwarden | Credential protection |
| Health | Health apps | Medical privacy |
| Private Messaging | Signal | Encrypted communication |

### Bypass Protection

Blocked apps cannot be accessed even if:

- Agent is in autonomous mode
- You ask Ukkin to access them
- Configuration requests it

Must manually remove from blocklist first.

## Permission Requests

### When Permissions Are Requested

Ukkin requests permissions:

- On first launch (core permissions)
- When creating agents that need new access
- When features require additional permissions

### Handling Requests

When prompted:

1. **Review** - Understand why it's needed
2. **Decide** - Grant or deny
3. **Adjust Later** - Can change in settings

### Denying Permissions

If you deny:

- Feature may not work
- Agent may be limited
- Ukkin will explain the impact

## Auditing Permissions

### View Current Permissions

See all granted permissions:

1. **Settings** > **Privacy** > **Permission Audit**
2. View by:
   - System permissions
   - App permissions
   - Agent permissions

### Permission History

Track permission changes:

1. **Settings** > **Privacy** > **Permission History**
2. See when permissions were:
   - Granted
   - Revoked
   - Changed

### Recommendations

Ukkin may suggest:

- Removing unused permissions
- Blocking sensitive apps
- Reducing agent access

## Managing Permissions

### System Settings

Access Android/iOS settings:

1. **Settings** > **Privacy** > **System Permissions**
2. Opens device settings for Ukkin
3. Manage at system level

### In-App Settings

Configure within Ukkin:

1. **Settings** > **Privacy**
2. Manage:
   - Blocked apps
   - Default permission levels
   - Audit preferences

### Per-Agent Settings

Configure individual agents:

1. Open agent
2. **Settings** > **Permissions**
3. Customize access for this agent

## Permission Best Practices

!!! tip "Start Minimal"
    Grant minimum permissions initially, add more as needed.

!!! tip "Review Regularly"
    Check permissions monthly and revoke unused ones.

!!! tip "Use Read-Only"
    When possible, use read-only agents before granting full control.

!!! tip "Block Sensitive Apps"
    Add banking and security apps to blocklist proactively.

!!! tip "Audit New Agents"
    Review permissions carefully when creating new agents.

## Troubleshooting

### Permission Denied Errors

If agents fail due to permissions:

1. Check which permission is missing
2. Review why it's needed
3. Grant if appropriate
4. Retry agent

### Can't Access App

If an agent can't interact with an app:

1. Check if app is on blocklist
2. Verify agent has app access
3. Ensure accessibility service is enabled
4. Check if app requires special handling

### Permissions Reset

If permissions unexpectedly reset:

1. Re-enable in system settings
2. Restart Ukkin
3. May need to reconfigure agents

## Next Steps

- [Privacy Overview](overview.md) - General privacy information
- [Data Protection](data-protection.md) - How data is secured
- [Getting Started Permissions](../getting-started/permissions.md) - Initial setup
