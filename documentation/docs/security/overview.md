# Security & Privacy Overview

Ukkin is built with privacy as a core principle. All AI processing happens on your device, and you have complete control over your data.

## Privacy by Design

### On-Device Processing

Everything runs locally on your phone:

- **AI Model** - Runs entirely on-device
- **Data Storage** - All data stays on your device
- **No Cloud** - Nothing is sent to external servers
- **Works Offline** - Full functionality without internet

### Zero Data Collection

Ukkin does not:

- Collect usage analytics
- Send data to cloud servers
- Track user behavior
- Store data remotely

## Security Features

### Data Encryption

All sensitive data is encrypted:

- Agent configurations
- Extracted data
- Chat history
- Saved screenshots

Encryption uses AES-256 with device-specific keys.

### Biometric Authentication

Protect sensitive actions:

- Require fingerprint/face for agent execution
- Lock settings behind biometrics
- Secure access to sensitive agents

### Permission Controls

Granular permission management:

- Per-agent permission settings
- App-specific access controls
- Audit logging for all actions

## Privacy Levels

Choose your privacy level:

| Level | Description |
|-------|-------------|
| **Minimal** | Basic protection, maximum features |
| **Standard** | Balanced security and usability (default) |
| **Strict** | Enhanced protection, some limitations |
| **Paranoid** | Maximum security, manual approvals |

### Minimal

- Data stored unencrypted for speed
- No biometric requirements
- All features enabled

### Standard (Default)

- Sensitive data encrypted
- Optional biometric protection
- Normal agent execution

### Strict

- All data encrypted
- Biometric for sensitive agents
- Detailed audit logging
- Auto-lock after inactivity

### Paranoid

- Everything encrypted
- Biometric required for all agents
- Manual approval for all actions
- No background execution
- Session timeouts

## What Data Ukkin Accesses

### When Agents Run

Agents may access:

- Screen content (to read information)
- App interfaces (to perform actions)
- Notifications (if configured)
- Files (for screenshots and exports)

### What's Stored

Ukkin stores:

- Agent configurations
- Execution history
- Extracted data
- Chat history
- Settings preferences

### What's Never Accessed

Ukkin never:

- Reads your passwords
- Accesses banking apps without permission
- Monitors when agents aren't running
- Stores sensitive credentials

## Controlling Access

### Per-Agent Permissions

Each agent has specific permissions:

1. Open agent settings
2. Go to **Permissions**
3. Configure:
   - Which apps it can access
   - What actions it can perform
   - Data it can extract

### App Blocklist

Prevent agents from accessing certain apps:

1. **Settings** > **Privacy** > **Blocked Apps**
2. Add apps to blocklist
3. Agents cannot interact with blocked apps

### Sensitive Data Protection

Configure sensitive data handling:

- **Auto-Detect** - Recognize credit cards, passwords
- **Redact** - Hide sensitive data in logs
- **Alert** - Warn when accessing sensitive data

## Data Management

### View Your Data

See everything Ukkin has stored:

1. **Settings** > **Privacy** > **My Data**
2. Browse by category:
   - Chat history
   - Agent data
   - Screenshots
   - Execution logs

### Export Your Data

Download all your data:

1. **Settings** > **Privacy** > **Export All**
2. Choose format (JSON/ZIP)
3. Data is packaged for download

### Delete Your Data

Remove specific or all data:

- **Delete Agent Data** - Remove specific agent's data
- **Clear History** - Remove execution logs
- **Full Wipe** - Remove all Ukkin data

## Audit Logging

Track all agent activity:

### Enable Logging

1. **Settings** > **Privacy** > **Audit Log**
2. Enable logging
3. Choose detail level

### Log Contents

Logs include:

- Timestamp
- Agent name
- Action performed
- Data accessed
- Result

### Review Logs

1. **Settings** > **Privacy** > **View Audit Log**
2. Filter by:
   - Date range
   - Agent
   - Action type
3. Export if needed

## Security Best Practices

!!! tip "Use Biometric Protection"
    Enable biometric authentication for agents that access sensitive apps.

!!! tip "Review Permissions Regularly"
    Check agent permissions monthly to ensure they only access what's needed.

!!! tip "Enable Audit Logging"
    Keep audit logs to understand what agents are doing.

!!! tip "Use Confirmation Mode"
    For sensitive agents, require confirmation before actions.

!!! tip "Block Sensitive Apps"
    Add banking and password manager apps to the blocklist.

## Related Topics

- [Data Protection](data-protection.md) - Detailed encryption information
- [Permissions Guide](permissions.md) - Permission setup and management
- [Settings](../configuration/settings.md) - Configure privacy settings
