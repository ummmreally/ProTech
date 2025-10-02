# Inventory System - Quick Reference

## 🚀 Quick Start

### Access Inventory
Navigate to: **Inventory Dashboard** from main menu

### Add New Item
```
Dashboard → Add Item → Fill Form → Add Item
```

### Adjust Stock
```
Item Details → Custom Stock Adjustment → Select Type → Save
```

### Create Purchase Order
```
Purchase Orders → Create PO → Select Supplier → Add Items
```

---

## 📦 Common Tasks

### Check Low Stock
Dashboard shows count → Click "View" on alert banner

### Search for Item
Inventory List → Search bar → Enter name/part#/SKU

### Use Part in Repair
```swift
InventoryService.shared.usePartForTicket(
    itemId: UUID,
    quantity: 1,
    ticketNumber: 1234
)
```

### View Stock History
Item Details → Scroll to "Recent Stock Changes"

### Export Inventory
Inventory List → Export button → Choose location

---

## 🏷️ Categories

| Category | Icon | Common Items |
|----------|------|--------------|
| Screens | iphone | LCD, OLED, Digitizers |
| Batteries | battery.100 | Li-ion, Li-Po cells |
| Cables | cable.connector | USB, Lightning, HDMI |
| Chargers | powerplug | Wall adapters, wireless |
| Cases | square.on.square | Protective cases |
| Tools | wrench.and.screwdriver | Screwdrivers, pry tools |
| Adhesives | drop.fill | Tape, glue, sealant |
| Components | cpu | Chips, connectors |
| Accessories | headphones | Misc accessories |
| Other | shippingbox | Uncategorized |

---

## 📊 Adjustment Types

| Type | When to Use |
|------|-------------|
| **Add** | Receiving stock, restocking |
| **Remove** | Removing from inventory |
| **Recount** | Physical inventory count |
| **Damaged** | Marking damaged/defective |
| **Return** | Customer returns, unused parts |
| **Sale** | Direct customer sales |
| **Usage** | Parts used in repairs |

---

## ⚡ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘F | Focus search bar |
| ⌘N | Add new item |
| ⌘E | Export inventory |
| Esc | Close sheets/modals |

---

## 🔔 Alert Thresholds

- **Low Stock:** quantity ≤ minQuantity
- **Out of Stock:** quantity ≤ 0
- **Reorder Point:** Customizable per item

---

## 💡 Pro Tips

1. **Set realistic min quantities** based on usage rate
2. **Use consistent part numbering** (e.g., IP14-SCR-001)
3. **Add SKUs** for barcode scanning (future)
4. **Track supplier part numbers** for easy reordering
5. **Use locations** (e.g., "Shelf 3, Bin 12") for warehouse
6. **Regular recounts** ensure accuracy
7. **Reference ticket numbers** when using parts
8. **Export weekly** for backup

---

## 📈 Dashboard Metrics

### Total Items
Count of all active inventory items

### Total Value
Sum of (quantity × cost price) for all items

### Low Stock
Items with quantity ≤ min quantity

### Out of Stock
Items with quantity ≤ 0

---

## 🔍 Search Tips

Search matches:
- Item name
- Part number
- SKU

Use filters to narrow by:
- Category
- Low stock only
- Sort options

---

## 📝 Required Fields

### Adding Item
- ✅ Item Name
- ✅ Part Number
- ✅ Category
- ✅ Cost Price
- ✅ Selling Price

### Stock Adjustment
- ✅ Type
- ✅ Quantity
- ✅ Reason

---

## 🆘 Quick Troubleshooting

**Can't find item?**
→ Check search spelling, verify item is active

**Stock not updating?**
→ Ensure adjustment is saved, check Core Data

**Low stock not showing?**
→ Verify minQuantity is set correctly

**Export failing?**
→ Check write permissions for save location

---

## 🔗 Integration

### With Tickets
```swift
// Deduct part used in repair
InventoryService.shared.usePartForTicket(
    itemId: item.id,
    quantity: 1,
    ticketNumber: ticket.ticketNumber
)

// Return unused part
InventoryService.shared.returnPartFromTicket(
    itemId: item.id,
    quantity: 1,
    ticketNumber: ticket.ticketNumber
)
```

### With Invoices
- Pull prices from inventory
- Auto-deduct on sale
- Track inventory turnover

---

## 📊 Sample Data Structure

```json
{
  "name": "iPhone 14 Pro Screen",
  "partNumber": "IP14P-SCR-001",
  "sku": "738291847362",
  "category": "screens",
  "quantity": 12,
  "minQuantity": 3,
  "maxQuantity": 20,
  "costPrice": 89.99,
  "sellingPrice": 149.99,
  "location": "Warehouse A",
  "binLocation": "Shelf 3, Bin 12"
}
```

---

## 🎯 Best Practices

### Stock Management
- Count physical inventory monthly
- Adjust min/max based on sales
- Keep safety stock (min qty)
- Use consistent naming

### Suppliers
- Track multiple suppliers per item
- Record lead times accurately
- Maintain contact information
- Rate supplier performance

### Purchase Orders
- Create POs for all purchases
- Track delivery dates
- Receive items promptly
- Verify quantities

### Pricing
- Update costs when prices change
- Review margins regularly
- Set competitive selling prices
- Track MSRP for reference

---

## 📞 Support

For detailed information, see:
- `INVENTORY_SYSTEM_COMPLETE.md`
- Code comments in files
- Apple Core Data documentation

---

**Quick Reference v1.0**  
**Last Updated:** October 1, 2025
