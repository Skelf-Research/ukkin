# Automation Settings

Control how Ukkin agents execute tasks, interact with apps, and manage system resources.

## Execution Settings

### Confirmation Mode

**Setting:** Require Confirmation

When enabled, agents ask before taking actions:

| Mode | Behavior |
|------|----------|
| **Always** | Ask before every action |
| **Important Only** | Ask for significant actions |
| **Never** | Execute without asking |

**Confirmation Timeout**

How long to wait for your response:

- 30 seconds - 5 minutes
- Default: 60 seconds
- After timeout: Skip action or cancel

### Background Execution

**Setting:** Allow Background Execution

Enable agents to run when app is closed:

| State | Behavior |
|-------|----------|
| **Enabled** | Agents run per schedule |
| **Disabled** | Only runs when app is open |

!!! note
    Requires proper permission setup. See [Permissions Guide](../getting-started/permissions.md).

### Concurrent Execution

**Setting:** Max Concurrent Agents

Number of agents that can run simultaneously:

- Range: 1-5
- Default: 3
- Higher = more battery/resource usage

## Device Conditions

### Battery Settings

**Minimum Battery Level**

Don't run agents below this level:

- Range: 10-50%
- Default: 20%

**Charging Only Mode**

Only execute when device is charging:

- Useful for heavy agents
- Extends battery life
- May delay time-sensitive tasks

### Network Settings

**WiFi Only**

Only run agents on WiFi:

| Setting | Behavior |
|---------|----------|
| **All Agents** | No agent runs on cellular |
| **Heavy Only** | Data-intensive agents need WiFi |
| **Never** | Use any connection |

**Network Quality**

Minimum connection quality for execution:

- Any - Run on any connection
- Good - Skip on poor connections
- Excellent - Only strong connections

### Time Restrictions

**Quiet Hours**

Pause all agents during set times:

```
Example: 11:00 PM - 7:00 AM
```

During quiet hours:
- No agent execution
- No notifications
- Queued for later

**Active Hours**

Preferred execution window:

```
Example: 9:00 AM - 6:00 PM
```

Agents prioritize this window when flexible.

## Execution Behavior

### Retry Settings

**Retry on Failure**

When an agent fails:

| Setting | Behavior |
|---------|----------|
| **No Retry** | Fail immediately |
| **1 Retry** | Try again once |
| **3 Retries** | Up to 3 attempts (default) |

**Retry Delay**

Time between retry attempts:

- 30 seconds
- 1 minute (default)
- 5 minutes

### Timeout Settings

**Execution Timeout**

Maximum time for agent to complete:

- Range: 1-10 minutes
- Default: 5 minutes
- Prevents stuck agents

**Step Timeout**

Maximum time for individual step:

- Range: 10-60 seconds
- Default: 30 seconds

### Error Handling

**On Error**

What to do when error occurs:

| Option | Behavior |
|--------|----------|
| **Stop** | Abort remaining steps |
| **Skip** | Continue to next step |
| **Notify** | Alert user and pause |

## App Interaction

### Tap Settings

**Tap Delay**

Pause between taps:

- Fast: 200ms
- Normal: 500ms (default)
- Careful: 1000ms

Slower is more reliable but takes longer.

**Double-Tap Prevention**

Avoid accidental double-taps:

- Enable for buttons
- Disable for scrolling

### Type Settings

**Typing Speed**

How fast to enter text:

- Instant: All at once
- Fast: 50ms per character
- Natural: 100ms per character

**Clear Before Type**

Clear field before typing:

- Always
- When not empty
- Never

### Wait Settings

**Default Wait**

Pause after each action:

- Short: 500ms
- Normal: 1000ms (default)
- Long: 2000ms

**Wait for Element**

How long to wait for screen elements:

- Range: 5-30 seconds
- Default: 10 seconds

### Screenshot Settings

**Screenshot Quality**

Image quality for captures:

| Quality | Size | Detail |
|---------|------|--------|
| Low | ~50KB | Readable |
| Medium | ~150KB | Clear (default) |
| High | ~500KB | Detailed |

**Auto Screenshot**

Automatically capture:

- On error
- After key steps
- On completion
- Never

## Resource Management

### Memory Limits

**Max Memory Usage**

Limit agent memory consumption:

- Range: 100-500MB
- Default: 200MB

### CPU Throttling

**Max CPU Usage**

Prevent overheating:

- Light: 25% CPU max
- Moderate: 50% CPU max (default)
- Heavy: 75% CPU max

### Storage Management

**Log Retention**

Keep execution logs:

- 7 days
- 30 days (default)
- 90 days
- Forever

**Screenshot Retention**

Keep captured screenshots:

- 7 days (default)
- 30 days
- Delete immediately

**Auto Cleanup**

Automatically remove old data:

- Enable/disable
- Storage threshold (e.g., clean when <1GB free)

## Advanced Settings

### Debug Mode

Enable detailed logging:

- Verbose step-by-step logs
- Performance metrics
- Network activity
- Memory usage

!!! note
    Debug mode uses more storage and battery.

### Accessibility Settings

**Screen Reader Compatibility**

Optimize for accessibility services:

- Wait longer for elements
- Use content descriptions
- Avoid coordinate-based taps

### App Compatibility

**Legacy App Mode**

For older apps:

- Slower interactions
- Alternative element detection
- Fallback methods

## Recommended Configurations

### Maximum Reliability

```
Confirmation: Always
Retry: 3 times
Timeout: 10 minutes
Tap Delay: Careful
Wait: Long
```

### Maximum Speed

```
Confirmation: Never
Retry: No retry
Timeout: 2 minutes
Tap Delay: Fast
Wait: Short
```

### Battery Optimized

```
Background: Charging only
WiFi Only: All agents
Max Concurrent: 1
CPU Throttle: Light
```

## Troubleshooting

### Agents Running Slowly

- Reduce max concurrent agents
- Lower wait times
- Disable debug mode

### Missing Taps

- Increase tap delay
- Enable double-tap prevention
- Use longer element wait

### Battery Drain

- Enable WiFi only mode
- Set charging only for heavy agents
- Reduce screenshot quality

### App Not Responding

- Increase step timeout
- Enable legacy app mode
- Add explicit wait steps

## Next Steps

- [Model Settings](model.md) - AI configuration
- [Settings Overview](settings.md) - All settings
- [Permissions](../getting-started/permissions.md) - Required permissions
