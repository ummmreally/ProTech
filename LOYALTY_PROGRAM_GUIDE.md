# ProTech Loyalty Program Guide

## Overview

ProTech includes a **comprehensive loyalty program** that helps you reward customers, increase repeat business, and build long-term relationships. The loyalty system is **standalone** and does not require any third-party integration.

---

## Features

### 🌟 Core Features

- **Points System**: Customers earn points on every purchase
- **VIP Tiers**: Multi-level tiers with increasing rewards (Bronze, Silver, Gold, Platinum)
- **Rewards Catalog**: Create custom rewards customers can redeem
- **Automatic SMS Notifications**: Alert customers when they earn points or unlock rewards
- **Analytics Dashboard**: Track program performance and top customers
- **Customer Dashboard**: Beautiful interface for customers to view and redeem rewards

### 📊 Earning Points

Customers can earn points through:
1. **Purchase Amount**: Earn points based on dollars spent (configurable rate)
2. **Visit Bonus**: Fixed points awarded per visit
3. **Tier Multipliers**: VIP members earn bonus points (1.5x, 2x, 3x, etc.)

### 🎁 Reward Types

- **Percentage Discount**: e.g., "10% off service"
- **Dollar Amount Off**: e.g., "$15 off repair"
- **Free Items**: e.g., "Free screen protector"
- **Custom Rewards**: Create your own reward types

---

## Getting Started

### 1. Create Your Loyalty Program

1. Navigate to **Loyalty** in the main menu
2. Click **"Create Loyalty Program"**
3. Default program is created with:
   - 1 point per dollar spent
   - 10 bonus points per visit
   - 4 default tiers (Bronze, Silver, Gold, Platinum)
   - 5 sample rewards

### 2. Configure Program Settings

Go to the **Settings** tab:

- **Program Name**: Customize your program name
- **Points per Dollar**: Set how many points customers earn per $1 spent
- **Points per Visit**: Bonus points given on each visit
- **Enable Tiers**: Turn VIP tiers on/off
- **Auto Notifications**: Enable/disable SMS notifications
- **Points Expiration**: Set days until points expire (0 = never)

### 3. Customize VIP Tiers

Go to the **Tiers** tab:

- View existing tiers
- Add new tiers with custom:
  - Name (e.g., "Bronze", "VIP")
  - Points required to reach tier
  - Points multiplier (1.5x, 2x, etc.)
  - Color for visual identification
- Edit or remove tiers as needed

### 4. Create Your Rewards

Go to the **Rewards** tab:

- Add new rewards by clicking **"Add Reward"**
- Configure:
  - Reward name
  - Description
  - Points cost
  - Reward type (discount %, dollar amount, free item)
  - Active/inactive status
- Edit existing rewards
- Organize by sort order

---

## Using the Loyalty Program

### Enrolling Customers

#### Option 1: Automatic Enrollment at Checkout
When creating an invoice, the system automatically enrolls the customer and awards points.

#### Option 2: Manual Enrollment
1. Go to Customer Detail view
2. Click **"Enroll"** in the loyalty widget
3. Customer is immediately enrolled with 0 points

### Awarding Points

Points are **automatically awarded** when:
- An invoice is created and marked as paid
- The service integrates with your POS system

**Manual Points Award:**
```swift
LoyaltyService.shared.awardPointsForPurchase(
    customerId: customerId,
    amount: 99.99,
    invoiceId: invoiceId
)
```

**Points Calculation:**
```
Base Points = Purchase Amount × Points Per Dollar
Tier Bonus = Base Points × Tier Multiplier
Visit Bonus = Fixed Points Per Visit
Total Points = (Base Points × Tier Multiplier) + Visit Bonus
```

**Example:**
- Purchase: $100
- Points per dollar: 1.0
- Tier multiplier: 1.5x (Silver)
- Visit bonus: 10
- **Total awarded: (100 × 1.5) + 10 = 160 points**

### Redeeming Rewards

#### Customer Self-Service
1. Customer navigates to their loyalty dashboard
2. Views available rewards (they have enough points)
3. Clicks **"Redeem Now"**
4. Points are deducted automatically

#### Staff Redemption
1. View customer's loyalty widget in POS
2. Click **"View Rewards"**
3. Help customer select and redeem reward
4. Apply discount to current transaction

### Tier Upgrades

Tiers are **automatically upgraded** based on lifetime points:
- System checks tier eligibility after each points award
- Customer is moved to highest tier they qualify for
- SMS notification sent (if enabled)

---

## Customer Experience

### Customer Loyalty Dashboard

Customers see:

1. **Loyalty Card**
   - Current available points
   - Tier status
   - Points multiplier

2. **Available Rewards**
   - Rewards they can redeem now
   - One-click redemption

3. **Locked Rewards**
   - Rewards they're working towards
   - Points needed to unlock

4. **Activity History**
   - Points earned
   - Rewards redeemed
   - Visit count and total spend

### SMS Notifications

When auto-notifications are enabled, customers receive SMS:

- **Points Earned**: "You earned 150 points! Your balance: 620 points"
- **Reward Redeemed**: "You redeemed: $15 Off Service! Remaining points: 470"
- **Tier Upgrade**: "Congratulations! You've reached Silver tier! 1.5x points on future visits!"

---

## Analytics & Reporting

### Overview Tab

Track key metrics:
- **Total Members**: Number of enrolled customers
- **Total Points Issued**: All-time points awarded
- **Average Points per Member**: Program engagement
- **Top Members**: Your most loyal customers
- **Program Details**: Current configuration

### Members Tab

- View all enrolled members
- Sort by lifetime points
- Search for specific customers
- Click to view detailed member profile

### Member Detail View

See individual customer data:
- Current and lifetime points
- Visit count and total spend
- Tier status
- Complete transaction history

---

## Best Practices

### Setting Up Your Program

1. **Start Conservative**: Begin with lower points-per-dollar (0.5-1.0) and adjust based on profit margins
2. **Make Rewards Attainable**: Ensure customers can reach first reward within 2-3 visits
3. **Create Tiers Early**: Even if starting simple, set up tier structure for future growth
4. **Communicate Value**: Display points value clearly (e.g., "100 points = $5 off")

### Promoting Your Program

1. **In-Store Signage**: Post loyalty benefits prominently
2. **At Checkout**: Always mention points earned
3. **SMS Marketing**: Remind customers of their points
4. **Email Campaigns**: Send reward unlock notifications
5. **Social Media**: Share tier upgrades and special rewards

### Reward Structure

#### Recommended Points Cost
- **Small Reward (100-250 points)**: $5-10 off, free add-on
- **Medium Reward (250-500 points)**: $15-25 off, 10-15% discount
- **Large Reward (500-1000 points)**: $30-50 off, 20-25% discount
- **Premium Reward (1000+ points)**: Free service, major discounts

#### Reward Mix
- **70% Value-Based**: Dollar discounts, percentage off
- **20% Experience**: Free upgrades, priority service
- **10% Special**: Exclusive items, VIP perks

### Managing Tiers

#### Suggested Tier Structure

| Tier | Lifetime Points | Multiplier | Benefits |
|------|----------------|------------|----------|
| Bronze | 0 | 1.0x | Base rewards |
| Silver | 500 | 1.5x | 50% bonus points |
| Gold | 1500 | 2.0x | Double points |
| Platinum | 3000 | 3.0x | Triple points + exclusive rewards |

### Preventing Abuse

1. **Points Expiration**: Consider 365-day expiration to encourage regular visits
2. **Limit Redemptions**: One reward per transaction
3. **Monitor Accounts**: Check for unusual patterns in member tab
4. **Clear Terms**: Post loyalty program terms and conditions

---

## Troubleshooting

### Customer Not Earning Points

**Check:**
1. Is customer enrolled in loyalty program?
2. Is loyalty program active? (Settings → Program Active)
3. Was invoice properly saved and marked as paid?
4. Are points configured correctly? (Settings → Points Earning)

### SMS Notifications Not Sending

**Check:**
1. Is auto-notifications enabled? (Settings → Auto SMS Notifications)
2. Is Twilio configured? (Settings → Twilio Settings)
3. Does customer have valid phone number?
4. Check Twilio account balance

### Tier Not Upgrading

**Check:**
1. Are tiers enabled? (Settings → Enable VIP Tiers)
2. Does customer have enough lifetime points?
3. View tier requirements in Tiers tab

### Rewards Not Appearing

**Check:**
1. Is reward active? (Edit reward → Active toggle)
2. Does customer have enough available points?
3. Is reward associated with correct program?

---

## Integration Points

### Customer Detail View

Add the loyalty widget:
```swift
if let customer = customer {
    LoyaltyWidget(customer: customer)
}
```

### Point of Sale (POS)

After creating an invoice:
```swift
if let invoiceId = invoice.id,
   let customerId = invoice.customerId,
   let totalAmount = invoice.totalAmount {
    LoyaltyService.shared.awardPointsForPurchase(
        customerId: customerId,
        amount: totalAmount,
        invoiceId: invoiceId
    )
}
```

### Customer Self-Service

Navigate to customer loyalty view:
```swift
NavigationLink(destination: CustomerLoyaltyView(customer: customer)) {
    Text("My Rewards")
}
```

---

## API Reference

### LoyaltyService

#### Enrollment
```swift
LoyaltyService.shared.enrollCustomer(_ customerId: UUID) -> LoyaltyMember?
```

#### Award Points
```swift
LoyaltyService.shared.awardPointsForPurchase(
    customerId: UUID,
    amount: Double,
    invoiceId: UUID?
)
```

#### Redeem Reward
```swift
LoyaltyService.shared.redeemReward(
    memberId: UUID,
    rewardId: UUID
) -> Bool
```

#### Get Member Data
```swift
LoyaltyService.shared.getMember(for customerId: UUID) -> LoyaltyMember?
```

#### Get Available Rewards
```swift
LoyaltyService.shared.getAvailableRewards(
    for member: LoyaltyMember
) -> [LoyaltyReward]
```

#### Analytics
```swift
LoyaltyService.shared.getTopMembers(limit: Int) -> [LoyaltyMember]
LoyaltyService.shared.getLoyaltyStats() -> (memberCount, totalPoints, avgPoints)
```

---

## Data Models

### LoyaltyProgram
- Program configuration
- Points earning rules
- Feature toggles

### LoyaltyMember
- Customer enrollment
- Points balance (total, available, lifetime)
- Visit count and spend tracking
- Current tier

### LoyaltyTier
- VIP level definition
- Points threshold
- Multiplier rate
- Visual styling

### LoyaltyReward
- Reward details
- Points cost
- Reward type and value
- Active status

### LoyaltyTransaction
- Points history
- Earned vs. redeemed
- Related invoices/rewards
- Expiration dates

---

## Tips for Success

### Week 1: Setup
- Create program with default settings
- Customize tiers and rewards for your business
- Train staff on loyalty features
- Create in-store signage

### Week 2-4: Launch
- Enroll existing customers
- Announce program via SMS/email
- Award points retroactively (optional)
- Monitor first redemptions

### Month 2+: Optimize
- Review analytics monthly
- Adjust points rates based on profitability
- Add seasonal rewards
- Promote top tiers for aspirational value

### Ongoing
- Recognize top members
- Create limited-time bonus point events
- Survey customers about desired rewards
- Expand tier benefits over time

---

## Support

For additional help:
- Check the Analytics tab for program health
- Review transaction history for specific issues
- Test with a dummy customer account first
- Document your program rules for staff reference

---

**Remember**: A successful loyalty program balances customer value with business profitability. Start simple, monitor results, and iterate based on what works for your customer base!
