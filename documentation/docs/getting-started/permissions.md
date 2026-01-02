# Permissions Setup

Ukkin requires certain permissions to automate tasks on your device. This guide explains each permission and how to enable them.

## Required Permissions

### Accessibility Service (Android)

The accessibility service allows Ukkin to:

- Read screen content
- Tap on elements
- Type text
- Navigate between apps

**To enable:**

1. Open **Settings** > **Accessibility**
2. Find **Ukkin** in the list
3. Toggle it **On**
4. Confirm the permission dialog

!!! warning "Privacy Note"
    The accessibility service can see all screen content. Ukkin only reads what's necessary for your agents and never transmits data off-device.

### Overlay Permission (Android)

Allows Ukkin to display information over other apps.

**To enable:**

1. Open **Settings** > **Apps** > **Ukkin**
2. Tap **Display over other apps**
3. Toggle it **On**

### Notification Access

Required for agents that need to read or respond to notifications.

**To enable:**

1. Open **Settings** > **Notifications** > **Notification access**
2. Find **Ukkin** and toggle **On**

### Storage Access

Needed for saving screenshots, exported data, and agent results.

**To enable:**

1. Grant when prompted during first use
2. Or manually in **Settings** > **Apps** > **Ukkin** > **Permissions**

## iOS Permissions

iOS has different permission requirements:

### Shortcuts Integration

Ukkin uses iOS Shortcuts for automation on iOS devices.

1. Open **Settings** > **Shortcuts**
2. Enable **Allow Running Scripts**

### Notifications

1. Open **Settings** > **Notifications** > **Ukkin**
2. Enable notifications and configure preferences

### Background App Refresh

Required for scheduled agent execution:

1. Open **Settings** > **General** > **Background App Refresh**
2. Enable for **Ukkin**

## Permission Summary

| Permission | Purpose | Required |
|------------|---------|----------|
| Accessibility Service | Screen reading and automation | Yes |
| Overlay | Display agent status | Optional |
| Notification Access | Read/respond to notifications | For communication agents |
| Storage | Save results and exports | Optional |
| Background Refresh | Scheduled execution | Recommended |

## Troubleshooting Permissions

### Agent Not Running

If agents aren't executing:

1. Check that the accessibility service is enabled
2. Verify background app refresh is on
3. Ensure battery optimization is disabled for Ukkin

### Can't See Screen Content

If agents can't read screens:

1. Re-enable the accessibility service
2. Restart the device
3. Reinstall Ukkin if issues persist

### Notifications Not Working

If you're not receiving alerts:

1. Check notification permissions
2. Verify Do Not Disturb is off
3. Ensure Ukkin notifications aren't blocked

## Battery Optimization

For reliable background execution, disable battery optimization:

**Android:**

1. Open **Settings** > **Battery** > **Battery optimization**
2. Find **Ukkin** and select **Don't optimize**

**iOS:**

Background refresh is managed automatically, but ensure Low Power Mode is off for best results.

## Security Best Practices

- Only grant permissions you need for your agents
- Review permissions periodically
- Disable accessibility service when not using automation features
- Use the in-app privacy settings to control data access

## Next Steps

With permissions configured, you're ready to:

- [Create your first agent](quick-start.md)
- [Explore agent types](../agents/overview.md)
- [Configure settings](../configuration/settings.md)
