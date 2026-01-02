# Settings Overview

Ukkin offers comprehensive settings to customize how the app and your agents behave. This guide covers all available configuration options.

## Accessing Settings

1. Tap the menu icon
2. Select **Settings**
3. Browse setting categories

## Settings Categories

### Model Settings
Configure the on-device AI model behavior.
[Learn more](model.md)

### Automation Settings
Control how agents execute and interact with your device.
[Learn more](automation.md)

### Privacy Settings
Manage data protection and privacy controls.
[Learn more](../security/overview.md)

### Notification Settings
Customize alerts and notifications.

### Agent Defaults
Set default behaviors for new agents.

### UI Preferences
Customize the app appearance.

## Quick Settings

### Notification Settings

| Setting | Options | Description |
|---------|---------|-------------|
| **Frequency** | Immediate / Batched / Summary | How often to receive alerts |
| **Alert Types** | Important / All / Summary | What to notify about |
| **Quiet Hours** | Time range | When to suppress notifications |
| **Grouping** | By agent / By type / None | How to group notifications |
| **Sound** | On / Off | Notification sounds |
| **Vibration** | On / Off | Haptic feedback |

### Agent Defaults

| Setting | Options | Description |
|---------|---------|-------------|
| **Require Confirmation** | Yes / No | Ask before executing actions |
| **Default Schedule** | Hourly / Daily / Weekly | New agent frequency |
| **WiFi Only** | Yes / No | Only run on WiFi |
| **Battery Threshold** | 15-50% | Minimum battery to run |
| **Max Concurrent** | 1-5 | Agents running simultaneously |

### UI Preferences

| Setting | Options | Description |
|---------|---------|-------------|
| **Theme** | Light / Dark / System | App appearance |
| **Language** | Various | Interface language |
| **Font Size** | Small / Medium / Large | Text size |
| **Animations** | On / Reduced / Off | Motion effects |

## Export and Import

### Export Settings

Save your configuration:

1. Go to **Settings** > **Export**
2. Choose what to include:
   - App settings
   - Agent configurations
   - Workflows
3. Select format (JSON)
4. Share or save file

### Import Settings

Restore configuration:

1. Go to **Settings** > **Import**
2. Select configuration file
3. Preview changes
4. Apply

!!! warning
    Importing will override existing settings. Back up current settings first.

## Reset Options

### Reset to Defaults

Restore factory settings:

1. Go to **Settings** > **Reset**
2. Choose reset scope:
   - **Settings Only** - Keep agents, reset preferences
   - **Agents Only** - Keep settings, remove agents
   - **Full Reset** - Start completely fresh
3. Confirm reset

### Clear Data

Remove specific data types:

- Chat history
- Execution logs
- Screenshots
- Cached data

## Settings Sync

### Backup to Cloud

Enable cloud backup (optional):

1. **Settings** > **Backup**
2. Sign in with account
3. Enable automatic backup
4. Choose what to backup

### Restore from Backup

1. **Settings** > **Backup** > **Restore**
2. Select backup date
3. Preview what will be restored
4. Confirm

## Per-Agent Settings

Each agent has individual settings accessible from its detail view:

- Schedule override
- Notification preferences
- Confirmation requirements
- Execution conditions

## Troubleshooting Settings

### Settings Not Saving

- Check storage permissions
- Restart the app
- Verify available storage space

### Import Failed

- Verify file format is correct
- Check file isn't corrupted
- Ensure compatible version

### Notifications Not Working

- Check system notification settings
- Verify Ukkin has permission
- Disable battery optimization

## Next Steps

- [Model Settings](model.md) - Configure AI behavior
- [Automation Settings](automation.md) - Control execution
- [Privacy Settings](../security/overview.md) - Manage data protection
