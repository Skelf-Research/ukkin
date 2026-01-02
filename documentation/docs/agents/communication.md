# Communication Agents

Communication agents help you manage the constant flow of emails, messages, and notifications, keeping your inbox organized without manual effort.

## Supported Apps

- Gmail
- Outlook
- WhatsApp
- SMS
- Telegram

## Use Cases

### Email Triage
Automatically organize incoming emails:

- Sort by sender importance
- Categorize by content type
- Archive newsletters
- Flag urgent messages

### Spam Management
Keep your inbox clean:

- Filter promotional emails
- Archive subscription content
- Mark spam patterns

### Auto-Replies
Respond automatically:

- Out-of-office messages
- Common inquiry responses
- Acknowledgment messages

### Message Organization
Organize messaging apps:

- Archive old conversations
- Prioritize important contacts
- Mute group chats

## Creating a Communication Agent

### Using the Wizard

1. Tap **+** > **Setup Wizard** > **Communication**
2. Follow the 7-step setup:
   - Select app (Gmail, WhatsApp, etc.)
   - Choose action type (triage, filter, auto-reply)
   - Configure important senders
   - Set filtering rules
   - Define actions
   - Configure notifications
   - Review and create

### Using Conversation

Describe your communication need:

```
Organize my Gmail inbox every morning. Move all newsletters to
the Newsletters folder, flag emails from my boss, and archive
anything older than a week that I haven't read.
```

## Configuration Options

### Email Triage Settings

| Option | Description |
|--------|-------------|
| Important Senders | Email addresses to prioritize |
| Newsletter Patterns | Identify and sort newsletters |
| Auto-Archive Rules | When to archive old emails |
| Label/Folder Assignment | Where to move emails |

### Message Settings

| Option | Description |
|--------|-------------|
| Priority Contacts | Contacts to highlight |
| Mute Patterns | Groups/contacts to silence |
| Auto-Reply Text | Response message template |
| Reply Delay | Wait time before auto-responding |

### Action Types

- **Read** - Just read and report status
- **Move** - Transfer to specific folder/label
- **Archive** - Remove from inbox
- **Flag** - Mark as important
- **Reply** - Send automatic response
- **Delete** - Remove permanently

## Example Agents

### Email Triage Agent

```yaml
App: Gmail
Schedule: Every morning at 7 AM
Actions:
  - Flag emails from: boss@company.com, vip-list
  - Move newsletters to: Newsletters
  - Archive unread older than: 7 days
  - Mark read older than: 30 days
Notify: On VIP emails only
```

### WhatsApp Auto-Reply

```yaml
App: WhatsApp
Schedule: During work hours (9 AM - 5 PM)
Trigger: New message received
Exclude: Family group, Close friends
Auto-Reply: "I'm at work and will respond later.
             For urgent matters, please call."
Delay: 5 minutes
```

### Newsletter Cleanup

```yaml
App: Gmail
Schedule: Weekly on Sunday
Filter: Subject contains "newsletter", "digest", "weekly"
Action: Archive all, Keep most recent
Summary: Send count of archived newsletters
```

### SMS Organizer

```yaml
App: SMS
Schedule: Daily
Actions:
  - Archive: OTP messages older than 24 hours
  - Flag: Messages from bank, important services
  - Report: Unknown sender count
```

## Smart Features

### Sender Learning

Communication agents can learn from your behavior:

- Track which emails you read first
- Note which messages you reply to quickly
- Identify patterns in your organization

### Priority Scoring

Emails are scored based on:

- Sender relationship
- Content urgency
- Past interaction history
- Time sensitivity

### Natural Language Rules

Define rules in plain English:

```
Archive anything from "no-reply@" addresses
Flag emails with "urgent" in subject
Move receipts to the Receipts folder
```

## Viewing Results

### Activity Summary

After each run, see:

- Emails processed
- Actions taken
- Flagged items requiring attention
- Error count

### Execution History

Review past runs:

- Timestamp
- Items processed
- Actions performed
- Any failures

## Advanced Configuration

### Conditional Actions

Create complex rules:

```
IF sender is from company.com
  AND subject contains "meeting"
  AND date is today
THEN flag and notify immediately
```

### Scheduled vs. Real-Time

Choose when agents run:

- **Scheduled**: Run at specific times
- **Real-Time**: Respond to incoming messages immediately
- **Hybrid**: Scheduled cleanup + real-time priority alerts

## Limitations

!!! warning "Reply Limitations"
    Auto-reply features work best for acknowledgments. Complex responses should be handled manually.

!!! note "Account Access"
    Agents can only access accounts you're logged into on your device.

## Tips for Success

!!! tip "Start Conservative"
    Begin with read-only actions (triage, flag) before enabling actions that modify content (archive, delete).

!!! tip "Whitelist Important Contacts"
    Always add important senders to your priority list to ensure their messages aren't accidentally filtered.

!!! tip "Review Regularly"
    Check agent results weekly to refine rules and catch any incorrect actions.

## Troubleshooting

### Emails Not Being Processed

- Verify Gmail/Outlook accessibility
- Check that email app is logged in
- Ensure accessibility service is enabled

### Auto-Reply Not Working

- Confirm WhatsApp is accessible
- Check the delay setting
- Verify the reply template is set

### Wrong Emails Filtered

- Review your filter rules
- Add exceptions for important senders
- Narrow the matching criteria
