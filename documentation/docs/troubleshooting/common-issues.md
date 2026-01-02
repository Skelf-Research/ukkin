# Common Issues

Solutions to frequently encountered problems with Ukkin.

## Installation Issues

### APK Won't Install

**Symptoms:** "App not installed" or "Installation blocked" error

**Solutions:**
1. Enable "Install from unknown sources" in settings
2. Ensure you have enough storage (need 2GB free)
3. Uninstall any previous version first
4. Try downloading the APK again (may be corrupted)

### App Crashes on First Launch

**Symptoms:** App closes immediately or shows "Ukkin has stopped"

**Solutions:**
1. Restart your device
2. Clear app cache and data
3. Ensure you have at least 4GB RAM available
4. Check Android version is 8.0 or higher

### Model Fails to Load

**Symptoms:** "Failed to initialize AI model" error

**Solutions:**
1. Wait a few minutes (first load can take time)
2. Ensure 2GB free storage
3. Close other apps to free memory
4. Restart the app
5. Re-download if model is corrupted

## Agent Issues

### Agent Not Running

**Symptoms:** Agent shows as active but never executes

**Solutions:**
1. Check accessibility service is enabled
2. Disable battery optimization for Ukkin
3. Ensure background activity is allowed
4. Check if quiet hours are active
5. Verify schedule is set correctly

### Agent Gets Stuck

**Symptoms:** Agent starts but never completes

**Solutions:**
1. Add longer wait times between steps
2. Check if target app is updated (UI may have changed)
3. Verify the element text/buttons still exist
4. Increase step timeout in settings
5. Run manually to observe where it fails

### Agent Taps Wrong Element

**Symptoms:** Agent clicks something other than intended

**Solutions:**
1. Use more specific element identifiers
2. Add wait_for conditions before tapping
3. Use text-based targeting instead of position
4. Check for overlapping elements

### Agent Can't Find Element

**Symptoms:** "Element not found" errors

**Solutions:**
1. Verify the text/element exists on screen
2. Increase wait time before looking for element
3. Check if element is hidden behind a menu
4. Update element identifier if app was updated

### Agent Actions Have No Effect

**Symptoms:** Agent runs but nothing happens in the target app

**Solutions:**
1. Re-enable accessibility service
2. Check if app is on the blocklist
3. Verify agent has permission for that app
4. Restart device
5. Try longer tap duration

## Chat Issues

### AI Responses Are Slow

**Symptoms:** Takes more than 10 seconds to respond

**Solutions:**
1. Reduce context length in settings
2. Close background apps
3. Use CPU instead of GPU (may be more stable)
4. Reduce max tokens
5. Restart the app

### AI Doesn't Understand

**Symptoms:** Irrelevant or confused responses

**Solutions:**
1. Be more specific in your request
2. Use simpler language
3. Break complex requests into smaller parts
4. Clear chat history and try again

### Chat History Lost

**Symptoms:** Previous messages disappeared

**Solutions:**
1. Check if auto-cleanup deleted old messages
2. Verify storage permissions
3. History may be in different conversation
4. Database may need repair (try clearing cache)

## Permission Issues

### Accessibility Service Keeps Disabling

**Symptoms:** Service turns off randomly

**Solutions:**
1. Disable battery optimization for Ukkin
2. Lock Ukkin in recent apps
3. Enable auto-start permission
4. Check security apps that may be interfering

### Can't Enable Accessibility Service

**Symptoms:** Toggle doesn't work or resets

**Solutions:**
1. Restart device
2. Clear system settings cache
3. Check if parental controls are blocking
4. Try in Safe Mode

### Permission Dialogs Don't Appear

**Symptoms:** No prompt when permission is needed

**Solutions:**
1. Go to system settings manually
2. Clear app data and retry
3. Check if permission was previously denied
4. Reinstall the app

## Notification Issues

### Not Receiving Notifications

**Symptoms:** Agents run but no alerts

**Solutions:**
1. Check system notification settings
2. Verify Ukkin has notification permission
3. Disable Do Not Disturb
4. Check quiet hours in Ukkin settings
5. Ensure notifications aren't grouped/silent

### Too Many Notifications

**Symptoms:** Overwhelmed by alerts

**Solutions:**
1. Change to summary mode
2. Set up quiet hours
3. Reduce check frequency on agents
4. Adjust per-agent notification settings

## Performance Issues

### High Battery Drain

**Symptoms:** Battery depletes quickly when using Ukkin

**Solutions:**
1. Reduce number of active agents
2. Increase check intervals
3. Enable battery saver mode
4. Use WiFi-only mode
5. Reduce max concurrent agents

### Device Gets Hot

**Symptoms:** Phone heats up during agent execution

**Solutions:**
1. Switch from GPU to CPU processing
2. Reduce concurrent agents to 1
3. Add longer waits between actions
4. Let device cool between executions

### App Using Too Much Storage

**Symptoms:** Low storage warnings

**Solutions:**
1. Clear old screenshots
2. Reduce log retention period
3. Delete unused agents
4. Clear app cache
5. Export and delete old data

## Data Issues

### Can't Export Data

**Symptoms:** Export fails or produces empty file

**Solutions:**
1. Check storage permissions
2. Ensure enough free space
3. Try smaller export (single agent)
4. Check if data exists to export

### Import Fails

**Symptoms:** Can't import configuration file

**Solutions:**
1. Verify file format is correct JSON
2. Check file isn't corrupted
3. Ensure compatible version
4. Try importing smaller pieces

### Data Seems Corrupted

**Symptoms:** Strange behavior, missing data, errors

**Solutions:**
1. Clear app cache (preserves data)
2. Export important data
3. Clear app data (loses data)
4. Reinstall as last resort

## Recovery Steps

### Basic Reset

If experiencing general issues:

1. Force close Ukkin
2. Clear app cache
3. Restart device
4. Open Ukkin

### Advanced Reset

If basic reset doesn't help:

1. Export your data first
2. Clear all app data
3. Restart device
4. Open Ukkin fresh
5. Import your data

### Full Reinstall

As a last resort:

1. Export all data
2. Uninstall Ukkin
3. Restart device
4. Reinstall Ukkin
5. Import your data

## Getting More Help

If your issue isn't listed:

1. Check the [FAQ](faq.md)
2. Search existing GitHub issues
3. Open a new issue with:
   - Device model
   - Android/iOS version
   - Steps to reproduce
   - Error messages
   - Screenshots if helpful
