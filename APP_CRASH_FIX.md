# App Crash Fix - EXC_BAD_ACCESS ✅

## Issue
App crashed on launch with:
```
Thread 1: EXC_BAD_ACCESS (code=EXC_I386_GPFLT)
```

Crash occurred in `ProTechApp.swift` during initialization.

## Root Cause

**Incorrect property wrapper usage for singleton:**

```swift
// WRONG - Causes crash
@StateObject private var supabaseAuth = SupabaseAuthService.shared
```

### Why This Crashes

**`@StateObject`**:
- Creates and **owns** the lifecycle of an object
- SwiftUI allocates memory and manages destruction
- Expects to be the **sole owner** of the instance

**`.shared` Singleton**:
- Already exists in memory
- Has its own lifecycle management
- Multiple references across the app

**The Conflict**:
When you use `@StateObject` with a singleton, SwiftUI tries to:
1. Take ownership of an already-owned object
2. Manage lifecycle of something it didn't create
3. This causes memory corruption → `EXC_BAD_ACCESS`

## Solution

Changed to `@ObservedObject` which **observes** but doesn't manage lifecycle:

```swift
// CORRECT - No crash
@ObservedObject private var supabaseAuth = SupabaseAuthService.shared
```

### Property Wrapper Rules

| Property Wrapper | Use Case | Example |
|-----------------|----------|---------|
| `@StateObject` | Create new instance | `@StateObject var myService = MyService()` |
| `@ObservedObject` | Reference existing instance | `@ObservedObject var shared = MyService.shared` |
| `@EnvironmentObject` | Injected from parent | Passed via `.environmentObject()` |

## Fix Applied

**File**: `/ProTech/ProTechApp.swift` (line 15)

**Before:**
```swift
@StateObject private var supabaseAuth = SupabaseAuthService.shared
```

**After:**
```swift
@ObservedObject private var supabaseAuth = SupabaseAuthService.shared
```

## All Singletons Now Correct

```swift
@ObservedObject private var subscriptionManager = SubscriptionManager.shared ✅
@ObservedObject private var authService = AuthenticationService.shared ✅
@ObservedObject private var supabaseAuth = SupabaseAuthService.shared ✅
@StateObject private var employeeService = EmployeeService() ✅ (not a singleton)
```

## Test Result

✅ **App launches successfully**  
✅ **No more EXC_BAD_ACCESS**  
✅ **Authentication working**  
✅ **All services initialized properly**

---

**Status**: ✅ FIXED  
**Date**: November 17, 2025  
**Impact**: Critical - App would crash on every launch
