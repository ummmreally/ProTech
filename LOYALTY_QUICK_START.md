# Loyalty Program - Quick Start Guide

## ✅ Issues Fixed

1. **✅ Loyalty tab now visible in sidebar** - Added to the "Business" section
2. **✅ Enrollment flow fixed** - Now shows proper sheet with frame size
3. **✅ Helpful error message** - If no program exists, shows clear instructions

---

## 🚀 Setup Steps (First Time)

### Step 1: Create Your Loyalty Program

1. **Click "Loyalty"** in the sidebar (under Business section)
2. You'll see: "No Loyalty Program Yet"
3. **Click "Create Loyalty Program"**
4. Program is created with default settings:
   - **Name**: "ProTech Rewards"
   - **Points per Dollar**: 1.0
   - **Points per Visit**: 10
   - **4 Default Tiers**: Bronze, Silver, Gold, Platinum

### Step 2: Customize Your Program (Optional)

#### Configure Settings:
1. Click **Settings** tab
2. Adjust:
   - Program name
   - Points per dollar spent
   - Visit bonus points
   - Point expiration (0 = never expire)
   - Enable/disable tiers
   - SMS notifications

#### Add Custom Tiers:
1. Click **Tiers** tab
2. Click **"Add Tier"**
3. Fill in:
   - Tier name (e.g., "VIP", "Elite")
   - Points required to reach
   - Points multiplier (e.g., 2.0x = double points)
   - Color for the tier badge
4. Click **Save**

#### Create Rewards:
1. Click **Rewards** tab
2. Click **"Add Reward"**
3. Fill in:
   - Reward name (e.g., "$10 Off Service")
   - Description
   - Points cost (how many points to redeem)
   - Type:
     - **Percentage Discount** (e.g., 10% off)
     - **Dollar Amount** (e.g., $15 off)
     - **Free Item**
   - Value (discount amount)
4. Click **Save**

---

## 👥 Enrolling Customers

### Method 1: From Customer Details

1. Go to **Customers** tab
2. Select a customer
3. You'll see **"Not enrolled in loyalty program"**
4. Click **"Join Now"**
5. **Enrollment modal appears** showing:
   - Program benefits
   - How it works
   - Sample rewards
   - VIP tiers
6. Click **"Join ProTech Rewards - It's Free!"**
7. ✅ Customer is enrolled!

### Method 2: During Check-In

1. Start checking in a customer (**Queue** → New Ticket)
2. Select customer
3. **Loyalty widget appears** below customer info
4. If not enrolled, click **"Join Now"**
5. Follow enrollment flow
6. Continue with check-in

### Method 3: At Point of Sale

1. Open **Point of Sale**
2. Select a customer
3. **Loyalty widget shows** below customer selection
4. If not enrolled, click **"Join Now"**
5. Enroll customer
6. Continue with sale

---

## 💰 Earning Points (Automatic)

Once enrolled, customers **automatically earn points** on every transaction:

### At Point of Sale:
1. Select enrolled customer
2. Add items to cart
3. Process payment (card/cash/UPI)
4. **Success screen shows**: "+XXX points earned!"
5. **SMS sent** (if enabled): "You earned 150 points! Balance: 450 pts"

### Point Calculation:
```
Base Points = Purchase Amount × Points per Dollar
Tier Bonus = Base Points × Tier Multiplier
Visit Bonus = Fixed bonus per transaction

Total = Base + (Tier Bonus - Base) + Visit Bonus
```

**Example:**
- Purchase: $100
- Points per Dollar: 1.0
- Customer Tier: Gold (2.0x multiplier)
- Visit Bonus: 10 points

Calculation:
- Base: 100 × 1.0 = 100 points
- With Tier: 100 × 2.0 = 200 points
- Visit Bonus: +10 points
- **Total Earned: 210 points**

---

## 🎁 Redeeming Rewards

### At Point of Sale:

1. Select enrolled customer
2. Add items to cart
3. **"X rewards available"** card appears
4. Click to browse rewards
5. **Reward picker opens** showing all redeemable rewards
6. Select a reward (e.g., "$15 Off")
7. **Discount applied** to cart total
8. Process payment
9. Points automatically deducted
10. **SMS sent**: "You redeemed $15 Off! New balance: 250 pts"

### Reward Types:

**Percentage Discount:**
- Customer has: "10% Off" reward (costs 150 points)
- Cart total: $120
- Discount: $12
- New total: $108

**Dollar Amount:**
- Customer has: "$20 Off" reward (costs 200 points)
- Cart total: $120
- Discount: $20
- New total: $100

**Free Item:**
- Custom implementation based on your inventory

---

## 📊 Managing Your Program

### View Analytics:

1. Click **Loyalty** in sidebar
2. **Overview tab** shows:
   - Total members enrolled
   - Total points issued
   - Average points per member
   - Top 10 loyalty customers

### View Members:

1. Click **Members** tab
2. See all enrolled customers
3. Search by name
4. Click member to see:
   - Total points
   - Current tier
   - Lifetime points
   - Visit count
   - Total spent
   - Recent transactions

### Edit Tiers/Rewards:

1. Click **Tiers** or **Rewards** tab
2. Click **pencil icon** on any item
3. Edit details
4. Click **Save**

---

## 📱 SMS Notifications

### Automatic Messages Sent:

**On Enrollment:**
```
Welcome to ProTech Rewards! You've been enrolled in our loyalty program.
Start earning points on every purchase!
```

**On Points Earned:**
```
You earned 150 points from your $98.50 purchase!
Current balance: 450 points
```

**On Reward Redemption:**
```
You redeemed $15 Off Service for 200 points!
New balance: 250 points
```

**On Tier Upgrade:**
```
Congratulations! You've reached Gold tier and now earn 2.0x points!
Current balance: 1,250 points
```

### Setup SMS:
1. Requires **Pro subscription**
2. Configure Twilio in **Settings → Square Integration**
3. See `TWILIO_INTEGRATION_GUIDE.md`

---

## 🎯 Customer Experience

### What Customers See:

**In Store (via staff):**
- Points balance on every screen
- Current tier and multiplier
- Available rewards
- "Join Now" prompts if not enrolled

**Enrollment Benefits Shown:**
- ✓ Earn on every purchase
- ✓ Exclusive rewards
- ✓ VIP tier benefits
- ✓ Instant SMS notifications

**After Purchase:**
- Success screen shows points earned
- SMS confirmation
- Running balance

**Customer Dashboard:**
(Accessible via **Customer Detail** → **View Rewards**)
- Loyalty card with points/tier
- Available rewards to redeem
- Locked rewards (not enough points)
- Recent activity history

---

## 💡 Best Practices

### Program Design:

**Conservative (High Margin Business):**
```
Points per Dollar: 0.5
Visit Bonus: 5
Reward Cost: High (e.g., 500 pts for $10 off)
Result: Lower point liability, slower accumulation
```

**Moderate (Standard):**
```
Points per Dollar: 1.0
Visit Bonus: 10
Reward Cost: Medium (e.g., 250 pts for $10 off)
Result: Balanced engagement and costs
```

**Aggressive (Growth Mode):**
```
Points per Dollar: 2.0
Visit Bonus: 25
Reward Cost: Low (e.g., 150 pts for $10 off)
Result: Fast accumulation, high redemption, max engagement
```

### Staff Training:

1. **Always mention loyalty** during checkout
2. **Enroll proactively** - "Would you like to join our rewards?"
3. **Check for rewards** before finalizing payment
4. **Celebrate milestones** - "You just reached Silver tier!"
5. **Promote next reward** - "Only 50 more points for $10 off!"

### Marketing:

- **In-store signage** displaying point values
- **Email campaigns** about new rewards
- **Social media** posts about tier benefits
- **Receipt messaging** with balance
- **Welcome packet** explaining program

---

## ⚠️ Troubleshooting

### "Join Now" button doesn't work:
- ✅ **Fixed!** Loyalty program must be created first
- Go to **Loyalty** → **Create Loyalty Program**

### Loyalty tab not in sidebar:
- ✅ **Fixed!** Now appears under "Business" section

### No rewards showing in POS:
- Check if customer is enrolled
- Verify customer has enough points
- Ensure rewards are marked as "Active"

### Points not awarded:
- Verify program is active (Settings tab)
- Check points configuration (Settings tab)
- Ensure customer selected during checkout

### SMS not sending:
- Requires Pro subscription
- Twilio must be configured
- Check Settings → SMS Notifications enabled

---

## 🎊 You're Ready!

Your loyalty program is now **fully operational**:

✅ Visible in navigation
✅ Enrollment flow working
✅ Automatic points awarding
✅ POS reward redemption
✅ Points display on receipts
✅ SMS notifications
✅ Complete admin dashboard

**Next Steps:**
1. Create your loyalty program (Loyalty → Create)
2. Add custom rewards
3. Adjust tier multipliers
4. Train staff on enrollment
5. Start enrolling customers!

---

**Questions or Issues?**
See `LOYALTY_FEATURES_COMPLETE.md` for detailed feature documentation.
