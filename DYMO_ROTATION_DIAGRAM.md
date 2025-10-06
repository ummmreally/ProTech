# DYMO Label Rotation - Visual Explanation

## Understanding the 90° Rotation Fix

### Physical Label Dimensions (DYMO 30252)
```
    1.125 inches
   ←─────────→
  ┌───────────┐  ↑
  │           │  │
  │           │  │
  │           │  │ 3.5 inches
  │           │  │
  │           │  │
  │           │  │
  │           │  │
  └───────────┘  ↓
  
  This is how the label
  is physically loaded
  in the DYMO printer.
```

### The Problem (Before Fix)

**What we tried:**
```
Landscape Orientation (WRONG)
Paper: 252pt × 81pt

     252 points (3.5")
   ←──────────────────→
  ┌────────────────────┐  ↑
  │ ProTech | $19.99   │  │ 81pt (1.125")
  │ 3 in 1 Charger     │  │
  └────────────────────┘  ↓

Problem: Prints sideways on physical label! ❌
```

### The Solution (After Fix)

**Step 1: Portrait Orientation**
```
Paper: 81pt × 252pt (Portrait)

   81pt (1.125")
   ←──────→
  ┌────────┐  ↑
  │        │  │
  │        │  │
  │        │  │
  │        │  │ 252pt (3.5")
  │        │  │
  │        │  │
  │        │  │
  └────────┘  ↓

This matches physical label! ✅
```

**Step 2: Rotate Content 90° Clockwise**
```
Drawing Space After Rotation:
(Now we draw as if in landscape, but it prints portrait)

Inside RotatedLabelView:
1. Start with portrait view (81 × 252)
2. Apply transformation:
   context.translateBy(x: 81, y: 0)
   context.rotate(by: π/2)
3. Now drawing space is 252 × 81 (rotated)
4. Draw text horizontally
5. Result prints vertically on label!
```

## Visual Transformation

### Coordinate System Transformation

**Before Rotation:**
```
  (0,252) ────────────── (81,252)
     │                      │
     │    Portrait View     │
     │     81 × 252         │
     │                      │
  (0,0) ──────────────── (81,0)
```

**After 90° Clockwise Rotation:**
```
The canvas rotates, new drawing space:

  Origin moves to (81,0)
  
  (0,81) ─────────────────────── (252,81)
     │                              │
     │    Rotated Drawing Space     │
     │         252 × 81              │
     │                              │
  (0,0) ───────────────────────── (252,0)
  
  Now we can draw "landscape" content
  that will print "portrait" on the label!
```

## Content Layout

### Drawing Space (After Rotation)
```
     252 points (3.5" becomes horizontal in drawing space)
   ←─────────────────────────────────────────→
  ┌───────────────────────────────────────────┐  ↑
  │                                           │  │
  │         ProTech | $19.99                  │  │
  │                                           │  │ 81pt
  │    3 in 1 Magnetic Charger                │  │ (1.125")
  │                                           │  │
  │         SKU: S889384                      │  │
  │                                           │  │
  │         ▐███▌███▌███▌███                  │  │
  └───────────────────────────────────────────┘  ↓
  
  This is how we DRAW the content
```

### Physical Output (What Prints)
```
   81pt (1.125")
   ←──────→
  ┌────────┐  ↑
  │ ProTch │  │
  │   |    │  │
  │ $19.99 │  │
  │        │  │
  │3 in 1  │  │
  │Magnetic│  │
  │Charger │  │ 252pt (3.5")
  │        │  │
  │  SKU:  │  │
  │S889384 │  │
  │        │  │
  │ ▐███▌  │  │
  │ ███▌█  │  │
  └────────┘  ↓
  
  This is what PRINTS on the label
  (90° rotation applied)
```

## Code Breakdown

### The Magic Transformation

```swift
override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    
    // Save current state
    context.saveGState()
    
    // ┌────────────────────────────────────────┐
    // │ STEP 1: Move origin to top-right      │
    // └────────────────────────────────────────┘
    context.translateBy(x: labelWidth, y: 0)
    
    // Before:           After translation:
    //  0,h ─── w,h       w,h ─── 2w,h
    //   │       │         │       │
    //  0,0 ─── w,0   →   w,0 ─── 2w,0
    //                     ↑
    //                  New origin
    
    // ┌────────────────────────────────────────┐
    // │ STEP 2: Rotate 90° clockwise          │
    // └────────────────────────────────────────┘
    context.rotate(by: .pi / 2)  // 90° = π/2 radians
    
    // After rotation:
    // The canvas rotates, making:
    // - Previous "height" → now "width"
    // - Previous "width" → now "height"
    
    // ┌────────────────────────────────────────┐
    // │ STEP 3: Draw in rotated space         │
    // └────────────────────────────────────────┘
    let rotatedWidth = labelHeight   // 252pt (was height)
    let rotatedHeight = labelWidth   // 81pt (was width)
    
    // Draw text, barcodes, etc. in this space
    // They appear landscape but print portrait!
    
    // ┌────────────────────────────────────────┐
    // │ STEP 4: Restore original state        │
    // └────────────────────────────────────────┘
    context.restoreGState()
}
```

## Why This Works

### DYMO's Expectation
DYMO label printers expect:
1. **Paper size**: Physical dimensions (1.125" × 3.5")
2. **Text rotation**: Applied to content, not paper
3. **Orientation**: Portrait (match physical label)

This matches their XML specification:
```xml
<DieCutLabel>
  <PaperOrientation>Landscape</PaperOrientation>  
  <!-- Paper is landscape in XML coordinate space -->
  
  <TextObject>
    <Rotation>Rotation90</Rotation>
    <!-- But text rotates 90° to fit portrait print -->
  </TextObject>
</DieCutLabel>
```

### Our Implementation
We replicate this by:
1. **Paper**: Portrait orientation (81pt × 252pt)
2. **Content**: Rotated 90° via Core Graphics
3. **Result**: Perfect match! ✅

## Comparison Table

| Aspect | Before (Broken) | After (Fixed) |
|--------|----------------|---------------|
| **Paper Orientation** | Landscape | Portrait |
| **Paper Size** | 252pt × 81pt | 81pt × 252pt |
| **Content Rotation** | None | 90° clockwise |
| **Margins** | 5pt all sides | 0pt (zero) |
| **Scaling** | Default (varies) | 1.0 (none) |
| **Drawing Space** | 252 × 81 | 252 × 81 (after rotation) |
| **Physical Output** | Sideways ❌ | Correct ✅ |

## Real-World Analogy

Think of it like writing on a notecard:

### Wrong Way (Before):
```
1. Take a notecard (1.125" × 3.5")
2. Hold it horizontally (landscape)
3. Write text horizontally
4. Try to read it vertically
→ Text is sideways! ❌
```

### Right Way (After):
```
1. Take a notecard (1.125" × 3.5")
2. Hold it vertically (portrait)
3. Rotate your writing hand 90°
4. Write (it feels horizontal to you)
5. Look at card normally
→ Text reads perfectly! ✅
```

## Summary

The fix is simple but crucial:
1. ✅ Use portrait paper size (matches physical label)
2. ✅ Rotate drawing context 90°
3. ✅ Draw content in rotated space
4. ✅ Result: Perfect labels!

**The key insight**: 
- Paper orientation = Physical reality
- Content rotation = Drawing transformation
- Keep them separate!

---

**Visual debugging tip:**
If labels print wrong:
- Check: Is paper portrait? (81 × 252)
- Check: Is content rotated? (π/2 radians)
- Check: Are margins zero?
- Check: Is scaling 1.0?

All yes? Labels will print correctly! 🎉
