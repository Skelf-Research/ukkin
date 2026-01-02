# Social Media Agents

Social media agents help you monitor and track activity across popular social platforms without constantly checking them yourself.

## Supported Platforms

- Instagram
- Twitter/X
- LinkedIn
- Facebook

## Use Cases

### Competitor Monitoring
Track what your competitors are posting:

- New posts and stories
- Follower count changes
- Engagement metrics
- Content themes

### Hashtag Tracking
Monitor specific hashtags:

- New posts using your tracked hashtags
- Trending content
- Competitor mentions

### Mention Alerts
Get notified when:

- Your brand is mentioned
- Specific keywords appear
- Influencers post about relevant topics

### Engagement Tracking
Monitor your own accounts:

- New followers
- Comment activity
- Post performance

## Creating a Social Media Agent

### Using the Wizard

1. Tap **+** > **Setup Wizard** > **Social Media**
2. Follow the 6-step setup:
   - Select platform (Instagram, Twitter, etc.)
   - Enter account/hashtag to monitor
   - Choose what to track
   - Set keywords (optional)
   - Configure frequency
   - Enable screenshot saving

### Using Conversation

Describe what you want to monitor:

```
Monitor @competitor_brand on Instagram and notify me whenever
they post something new. Check every 2 hours.
```

## Configuration Options

### Tracking Targets

| Option | Description |
|--------|-------------|
| Account Handle | @username to monitor |
| Hashtag | #hashtag to track |
| Keywords | Specific words to watch for |
| Multiple Targets | Track several accounts/hashtags |

### Check Frequency

- Every hour
- Every 3 hours
- Every 6 hours
- Daily
- Weekly

### What to Track

- New posts
- Stories
- Follower count
- Following count
- Bio changes
- Profile picture changes

### Output Options

- Notification alerts
- Screenshot capture
- Data export
- Dashboard summary

## Example Agents

### Instagram Competitor Tracker

```yaml
Platform: Instagram
Account: @competitor
Track: New posts, Story updates
Frequency: Every 2 hours
Screenshots: Enabled
Notify: On new content
```

### Twitter Hashtag Monitor

```yaml
Platform: Twitter
Hashtags: #yourproduct, #yourbrand
Track: All tweets
Frequency: Every hour
Keywords: "review", "recommendation"
Notify: On keyword match
```

### LinkedIn Job Monitor

```yaml
Platform: LinkedIn
Search: "Product Manager" in San Francisco
Track: New job postings
Frequency: Daily at 9 AM
Notify: On new listings
```

## Viewing Results

### Dashboard View

Social media agents appear in the dashboard with:

- Last check time
- Number of new items found
- Quick status indicator

### Detail View

Tap an agent to see:

- Full execution history
- Saved screenshots
- Extracted data
- Trend graphs

## Advanced Features

### Keyword Filtering

Add keywords to filter results:

- Only notify when specific words appear
- Exclude certain content types
- Prioritize by keyword relevance

### Screenshot Archives

Enable automatic screenshot saving:

- Full post screenshots
- Timestamped archives
- Organized by date

### Data Export

Export monitoring data:

- CSV format
- JSON format
- Share via email

## Limitations

!!! note "Platform Restrictions"
    Social media agents work by viewing public content. Private accounts require you to be logged in and following.

!!! note "Rate Limiting"
    Checking too frequently may trigger platform rate limits. Recommended minimum: 1 hour between checks.

## Tips for Success

!!! tip "Use Multiple Agents"
    Create separate agents for different platforms or purposes for easier management.

!!! tip "Set Specific Keywords"
    Narrow your tracking with keywords to reduce noise and find relevant content faster.

!!! tip "Review Weekly"
    Check your agent results weekly to refine tracking and remove irrelevant targets.

## Troubleshooting

### Agent Not Finding Content

- Verify the account/hashtag exists
- Check that the account is public
- Ensure you're logged into the platform

### Too Many Notifications

- Add keyword filters
- Reduce check frequency
- Narrow your tracking targets

### Screenshots Not Saving

- Check storage permissions
- Verify available storage space
- Enable screenshot option in agent settings
