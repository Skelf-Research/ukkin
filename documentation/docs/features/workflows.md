# Workflows

Workflows are pre-defined sequences of actions that can be executed on demand or scheduled. They're simpler than full agents and perfect for quick automation tasks.

## Workflows vs Agents

| Feature | Workflows | Agents |
|---------|-----------|--------|
| Execution | On-demand or scheduled | Continuous monitoring |
| Complexity | Simple sequences | Complex logic |
| Memory | Stateless | Maintains state |
| Best for | Quick tasks | Ongoing automation |

## Accessing Workflows

1. Open the menu
2. Select **Workflows**
3. View saved workflows and templates

## Workflow Screen Tabs

### Saved Workflows

Your created and customized workflows:

- Personal workflows you've built
- Modified templates
- Imported workflows

### Templates

Pre-built workflows ready to use:

- Common automation tasks
- One-click setup
- Customizable after creation

## Creating a Workflow

### From Template

1. Go to **Workflows** > **Templates**
2. Browse available templates
3. Tap to preview
4. Select **Use Template**
5. Customize if needed
6. Save

### From Scratch

1. Go to **Workflows** > **Builder**
2. Tap **New Workflow**
3. Add steps:
   - Select action type
   - Configure parameters
   - Set timing
4. Name your workflow
5. Save

## Workflow Builder

### Adding Steps

Each workflow consists of sequential steps:

1. Tap **Add Step**
2. Choose action type:
   - Open App
   - Tap Element
   - Type Text
   - Scroll
   - Wait
   - Extract Data
   - Take Screenshot
3. Configure the step
4. Repeat for additional steps

### Step Configuration

Each step has configurable options:

| Action | Options |
|--------|---------|
| Open App | App name, deep link URL |
| Tap | Element text, position |
| Type | Text to enter, field identifier |
| Scroll | Direction, distance |
| Wait | Duration (seconds) |
| Extract | Target element, data type |
| Screenshot | Full screen or element |

### Step Order

- Drag steps to reorder
- Use arrows to move up/down
- Delete unwanted steps

## Example Workflows

### Quick Screenshot Share

```
Steps:
1. Take screenshot
2. Open sharing menu
3. Select messaging app
4. Send to specific contact
```

### Daily Backup Check

```
Steps:
1. Open Photos app
2. Go to backup status
3. Screenshot status
4. Return home
```

### App Cleanup

```
Steps:
1. Open settings
2. Go to storage
3. Clear cache for target apps
4. Return home
```

## Running Workflows

### Manual Execution

1. Go to saved workflows
2. Tap the workflow
3. Select **Run Now**
4. Watch execution progress

### Scheduled Execution

1. Open workflow settings
2. Enable **Schedule**
3. Set frequency and time
4. Save

### Quick Access

Add frequently used workflows to:

- Home screen widget
- Quick actions menu
- Notification shortcuts

## Workflow Templates

### Productivity

- **Clear Notifications** - Dismiss all pending notifications
- **Toggle Settings** - Quick access to common toggles
- **App Switcher** - Fast switch between apps

### Social

- **Quick Post** - Post to multiple platforms
- **Story Check** - View stories across apps
- **Profile Update** - Update bio across platforms

### Utility

- **System Info** - Capture device status
- **Storage Check** - Monitor available space
- **Battery Report** - Log battery status

## Customizing Templates

After selecting a template:

1. Review the default steps
2. Modify parameters as needed
3. Add or remove steps
4. Save as new workflow

## Sharing Workflows

### Export

1. Open workflow
2. Tap **Share**
3. Select format (JSON/QR Code)
4. Send to recipient

### Import

1. Go to **Workflows**
2. Tap **Import**
3. Select source (File/QR/Link)
4. Review and save

## Workflow Variables

Use variables for flexible workflows:

### Input Variables

Prompt for input when running:

```
Step: Open browser
URL: ${input:website_url}
```

Running this workflow asks: "Enter website URL"

### Dynamic Values

Use system values:

```
Step: Type text
Text: Report for ${date:today}
```

Automatically inserts current date.

## Conditional Steps

Add basic conditions:

```
IF screen contains "Error"
  THEN screenshot
  ELSE continue
```

## Tips for Workflows

!!! tip "Keep It Simple"
    Workflows work best for straightforward, linear tasks.

!!! tip "Test First"
    Always test a workflow manually before scheduling.

!!! tip "Use Templates"
    Start with templates and customize rather than building from scratch.

!!! tip "Add Wait Steps"
    Include wait steps between actions for reliability.

## Troubleshooting

### Workflow Fails Mid-Execution

- Add longer wait times between steps
- Verify element names are correct
- Check app is installed and accessible

### Can't Find Element

- Use more specific text identifiers
- Add a wait_for step before interaction
- Verify the screen is actually displayed

### Wrong Action Taken

- Review step order
- Check step parameters
- Test individual steps

## Limitations

!!! note "Complexity"
    For complex automation with conditions and loops, use full agents instead.

!!! note "State"
    Workflows don't maintain state between runs. Each execution is independent.

## Next Steps

- [Create agents](../agents/overview.md) for more complex automation
- [Chat interface](chat-interface.md) for conversational workflow creation
- [Autonomous mode](autonomous-mode.md) for hands-free operation
