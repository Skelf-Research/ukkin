# Custom Agents

Custom agents let you automate any task by describing it in natural language. If you can describe it, Ukkin can automate it.

## What Can Custom Agents Do?

Custom agents can perform any combination of:

- Open apps
- Tap on buttons and text
- Type content
- Scroll and navigate
- Extract information from screens
- Save and export data
- Wait for conditions
- Make decisions based on content

## Creating a Custom Agent

### Step 1: Describe Your Task

In the conversational builder, describe what you want to automate:

```
Every morning, open Twitter, check the trending topics,
take a screenshot, and save it to my gallery.
```

### Step 2: Answer Clarifying Questions

Ukkin may ask:

- "What time in the morning should this run?"
- "Should I notify you after saving?"
- "Which Twitter account should I use?"

### Step 3: Review the Flow

Before creating, you'll see the generated steps:

1. Open Twitter app
2. Navigate to Explore
3. Wait for page to load
4. Extract trending topics
5. Take screenshot
6. Save to gallery
7. Send notification

### Step 4: Confirm and Create

Review the flow and tap **Create Agent** to save.

## Available Actions

### App Control

| Action | Description | Example |
|--------|-------------|---------|
| `open` | Launch an app | Open Instagram |
| `back` | Press back button | Go back to previous screen |
| `home` | Go to home screen | Exit app |

### Interaction

| Action | Description | Example |
|--------|-------------|---------|
| `tap` | Tap on element/text | Tap "Search" |
| `type` | Enter text | Type "hello world" |
| `scroll` | Scroll direction | Scroll down |
| `long_press` | Hold on element | Long press on image |

### Information

| Action | Description | Example |
|--------|-------------|---------|
| `extract` | Read screen text | Extract price text |
| `screenshot` | Capture screen | Save screenshot |
| `save` | Store data | Save extracted text |

### Timing

| Action | Description | Example |
|--------|-------------|---------|
| `wait` | Pause execution | Wait 3 seconds |
| `wait_for` | Wait for element | Wait for "Load complete" |

## Example Custom Agents

### Daily News Digest

```
Description: "Every morning at 8 AM, open Google News,
scroll through the top 5 stories, take screenshots of
each headline, and save them."

Generated Flow:
1. Open Google News
2. Wait for content to load
3. Extract headline 1
4. Screenshot
5. Scroll down
6. [Repeat for 5 headlines]
7. Save all screenshots
8. Notify "News digest ready"
```

### Automated Form Filling

```
Description: "Open the timesheet app, fill in 8 hours for
today, and submit. Do this every weekday at 5 PM."

Generated Flow:
1. Open Timesheet app
2. Tap on today's date
3. Tap hours field
4. Type "8"
5. Tap "Submit"
6. Wait for confirmation
7. Screenshot
8. Notify "Timesheet submitted"
```

### Social Media Cross-Post

```
Description: "When I save a new photo to my Screenshots folder,
post it to both Instagram and Twitter with the caption
'Check out my latest!'"

Generated Flow:
1. Monitor Screenshots folder
2. On new image:
   a. Open Instagram
   b. Create new post
   c. Select image
   d. Add caption
   e. Post
   f. Open Twitter
   g. Create new tweet
   h. Attach image
   i. Add caption
   j. Tweet
3. Notify "Posted to both platforms"
```

### Data Extraction

```
Description: "Check my bank app every day and extract my
account balance. Save it to a spreadsheet."

Generated Flow:
1. Open bank app
2. Authenticate (if needed)
3. Navigate to accounts
4. Wait for balance to load
5. Extract balance text
6. Open Sheets app
7. Add new row with date and balance
8. Save
```

## Flow Editing

### Edit via Chat

After creating an agent, modify it through conversation:

```
You: "Add a step to also check my savings account"

Ukkin: "I'll add a step after the current balance check.
The flow now includes:
- Tap on 'Savings'
- Extract savings balance
- Add to same spreadsheet row"
```

### Visual Flow Editor

Access the flow editor to:

- Drag and drop steps
- Edit step parameters
- Add conditions
- Remove steps
- Duplicate sections

## Conditional Logic

Custom agents can include conditions:

```
Description: "Check my portfolio value. If it's up more
than 5%, send me a notification. If it's down more than
3%, take a screenshot for review."

Generated Flow:
1. Open trading app
2. Navigate to portfolio
3. Extract total value
4. IF change > 5%:
   - Notify "Portfolio up!"
5. IF change < -3%:
   - Screenshot
   - Notify "Portfolio needs attention"
```

## Multi-App Workflows

Chain actions across multiple apps:

```
Description: "Find the cheapest price for iPhone 15 across
Amazon, Flipkart, and local stores. Compare and notify me
which has the best deal."

Generated Flow:
1. Open Amazon
2. Search "iPhone 15"
3. Extract price
4. Store as "amazon_price"
5. Open Flipkart
6. Search "iPhone 15"
7. Extract price
8. Store as "flipkart_price"
9. Compare prices
10. Notify with lowest price and source
```

## Best Practices

### Be Specific

Instead of:
```
"Check my email"
```

Say:
```
"Open Gmail, go to Primary inbox, count unread emails,
and notify me if there are more than 10"
```

### Include Timing

Instead of:
```
"Post to Instagram daily"
```

Say:
```
"Post to Instagram every day at 6 PM"
```

### Define Error Handling

Include what to do if something fails:

```
"Try to submit the form. If it fails, take a screenshot
and notify me about the error."
```

## Limitations

!!! warning "Authentication"
    Agents can't handle complex authentication like CAPTCHA or 2FA on their own. You may need to pre-authenticate.

!!! note "Screen Changes"
    If an app updates its interface, the agent may need to be updated to match new button names or layouts.

!!! note "Timing"
    Fast-loading apps work best. Agents include wait times, but extremely slow apps may cause issues.

## Tips for Success

!!! tip "Test First"
    Use "Run Now" to test your agent before scheduling it to run automatically.

!!! tip "Start Simple"
    Begin with simple flows and add complexity gradually.

!!! tip "Use Wait Steps"
    Add wait times between actions to ensure screens have time to load.

!!! tip "Enable Confirmation"
    For agents that take important actions, enable confirmation mode to review before execution.

## Troubleshooting

### Agent Gets Stuck

- Add more wait time between steps
- Check if the app layout has changed
- Verify button/text names are correct

### Wrong Element Tapped

- Be more specific with element names
- Use unique text identifiers
- Add wait_for conditions

### Data Not Extracted

- Ensure the correct screen is visible
- Check extraction area is defined
- Verify text is actually displayed
