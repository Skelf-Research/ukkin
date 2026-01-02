# Shopping Agents

Shopping agents help you find the best deals by monitoring prices, tracking your wishlist, and alerting you when items drop to your target price.

## Supported Platforms

- Amazon
- Flipkart
- Myntra
- eBay
- And other e-commerce sites via custom agents

## Use Cases

### Price Tracking
Monitor product prices over time:

- Track current prices
- View price history
- Predict price trends
- Set target prices

### Price Drop Alerts
Get notified when:

- Items fall below your target price
- Significant price drops occur
- Flash sales start
- Limited-time deals appear

### Wishlist Monitoring
Track multiple products:

- Monitor entire wishlists
- Compare prices across sites
- Track stock availability

### Budget Tracking
Manage shopping expenses:

- Set spending limits
- Track purchases
- Monitor subscription costs

## Creating a Shopping Agent

### Using the Wizard

1. Tap **+** > **Setup Wizard** > **Shopping**
2. Follow the 7-step setup:
   - Select platform (Amazon, Flipkart, etc.)
   - Enter product URL or search term
   - Set target price
   - Choose alert threshold
   - Select categories (optional)
   - Configure check frequency
   - Review and create

### Using Conversation

Describe what you want to track:

```
Track AirPods Pro on Amazon. Let me know when the price
drops below $200 or there's a discount of more than 20%.
```

## Configuration Options

### Price Alert Settings

| Option | Description |
|--------|-------------|
| Target Price | Exact price you want to pay |
| Discount Threshold | Minimum % discount to alert |
| Price Drop Amount | Alert on drops of X or more |
| Any Change | Notify on any price change |

### Check Frequency

- Every 30 minutes (high-demand items)
- Every hour
- Every 6 hours
- Daily

### Product Categories

Filter by category for deal hunting:

- Electronics
- Fashion
- Books
- Home & Kitchen
- Sports & Outdoors
- Beauty

## Example Agents

### Single Product Tracker

```yaml
Platform: Amazon
Product: Apple AirPods Pro
URL: amazon.com/dp/B09JQMJHXY
Target Price: $199
Alert When: Price <= target OR discount >= 15%
Frequency: Every 2 hours
Notify: Push notification + sound
```

### Category Deal Finder

```yaml
Platform: Flipkart
Category: Electronics
Discount Threshold: 30%
Filter: Rating >= 4 stars
Frequency: Every 6 hours
Notify: Daily summary
```

### Wishlist Monitor

```yaml
Platform: Amazon
Source: My Wishlist
Track: All items
Alert When: Any item drops by 10%+
Frequency: Daily
Notify: On significant drops only
```

### Multi-Platform Price Compare

```yaml
Product: Samsung Galaxy S24
Platforms: Amazon, Flipkart, Samsung Store
Action: Compare prices across sites
Alert: When lowest price found
Frequency: Every 6 hours
```

## Price Tracking Features

### Price History

View historical prices for tracked products:

- 7-day price chart
- 30-day price chart
- All-time high/low
- Average price

### Price Predictions

Get insights on pricing:

- Likelihood of further drops
- Best time to buy
- Sale pattern detection

### Deal Quality Score

Each alert includes a score:

- **Excellent** - Lowest price ever seen
- **Good** - Below average price
- **Fair** - Slight discount
- **Avoid** - Above average price

## Alert Types

### Instant Alerts
For time-sensitive deals:

- Push notification immediately
- Sound alert
- SMS (if configured)

### Summary Alerts
For general monitoring:

- Daily digest
- Weekly roundup
- Only significant changes

## Viewing Results

### Price Dashboard

See all tracked items:

- Current price
- Your target price
- Last check time
- Price trend indicator

### Product Detail

Tap a product to see:

- Full price history graph
- All recorded prices
- Check history
- Alert history

## Advanced Features

### Multi-Product Tracking

Track multiple products in one agent:

```
Track these products on Amazon:
- Sony WH-1000XM5
- Kindle Paperwhite
- Anker PowerBank

Alert when any drops by 15% or more.
```

### Stock Alerts

Get notified when out-of-stock items return:

```yaml
Product: PlayStation 5
Current Status: Out of Stock
Alert: When back in stock
Check Frequency: Every 30 minutes
```

### Coupon Detection

Agents can also detect:

- Available coupons
- Promo codes
- Bundle deals

## Budget Features

### Spending Tracker

Monitor your shopping expenses:

- Set monthly budget
- Track purchases
- Receive warnings near limit

### Price Match Reminders

After purchase:

- Continue monitoring price
- Alert if price drops
- Provide price match claim info

## Limitations

!!! note "Price Accuracy"
    Prices are checked periodically and may not reflect real-time changes during flash sales.

!!! note "Platform Restrictions"
    Some platforms may limit automated price checking. Agents respect rate limits.

## Tips for Success

!!! tip "Set Realistic Targets"
    Research typical prices before setting target prices. Use price history as a guide.

!!! tip "Enable Sound Alerts"
    For limited-time deals, enable sound notifications so you don't miss them.

!!! tip "Track Multiple Sellers"
    Create separate agents for different sellers to find the best price.

!!! tip "Use Categories"
    For general deal hunting, use category-based agents rather than specific products.

## Troubleshooting

### Price Not Updating

- Verify the product URL is correct
- Check that the platform is accessible
- Ensure the product is still available

### Missing Alerts

- Check notification settings
- Verify target price isn't too low
- Review alert threshold configuration

### Wrong Price Shown

- Some sites show personalized prices
- Clear app cache and retry
- Try checking from a fresh browser
