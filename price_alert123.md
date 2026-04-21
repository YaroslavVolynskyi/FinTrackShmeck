# Plan: Price Alerts with Firebase Backend & Push Notifications

## Context
The user wants to set "desired buy price" and "required sell price" for each stock. When the market price hits those levels (checked every 30 min during market hours), the app receives a push notification. On opening, the triggered stock row blinks green (buy) or red (sell).

## Architecture
- **Backend**: Firebase (Firestore + Cloud Functions + Cloud Messaging)
- **Firestore**: stores price alerts per user/device
- **Cloud Functions (Python)**: scheduled function every 30 min during market hours, fetches prices from Yahoo Finance, compares to alerts, sends FCM push
- **FCM**: push notifications to iOS app
- **iOS app**: new columns, Firebase SDK integration, blinking animation

## Implementation Plan

### Step 1: Add Two New Columns to iOS App
**Files**: `StockPosition.swift`, `StockTrackerView.swift`, `PortfolioViewModel.swift`

- Add `desiredBuyPrice: Double?` and `requiredSellPrice: Double?` to `StockPosition`
- Add two new columns at the right end of the table: "Buy At" and "Sell At"
- Both columns are editable (`EditableCellView`), display `$` prefix, placeholder "—"
- Add to `colWidths` array: `[..., 82, 82]`
- Add header cells: "Buy At", "Sell At"
- Save to local DB on edit (already handled by `onEdit()` → `save()`)

### Step 2: Firebase Project Setup
- Create Firebase project in Firebase Console
- Add iOS app to the project (bundle ID: `com.yaroslav.FinTrackShmeck`)
- Download `GoogleService-Info.plist`, add to Xcode project
- Enable Firestore, Cloud Messaging, Cloud Functions in Firebase Console

### Step 3: Add Firebase SDK to iOS App
**Files**: `FinTrackShmeckApp.swift`, new `FirebaseService.swift`

- Add Firebase SPM dependencies: `FirebaseCore`, `FirebaseFirestore`, `FirebaseMessaging`
- Configure Firebase in app entry point (`FirebaseApp.configure()`)
- Implement `FirebaseService`:
  - Register for push notifications (APNs + FCM token)
  - Save FCM token to Firestore
  - `syncAlerts()`: upload price alerts (ticker, buyPrice, sellPrice, fcmToken) to Firestore collection `alerts`
  - `removeAlert(ticker:)`: remove when position deleted
- Call `syncAlerts()` after user edits buy/sell prices

### Step 4: Firestore Data Model
```
Collection: alerts
Document ID: {fcmToken}_{ticker}
Fields:
  - ticker: String
  - buyPrice: Double (optional)
  - sellPrice: Double (optional)
  - fcmToken: String
  - updatedAt: Timestamp
```

### Step 5: Cloud Function — Price Check Cron (Python)
**File**: `functions/main.py`

- Scheduled Cloud Function: runs every 30 min, Mon-Fri, 9:30 AM - 4:00 PM ET
- Fetches all alert documents from Firestore
- Groups tickers, fetches current prices from Yahoo Finance API
- For each alert:
  - If `currentPrice <= buyPrice` → send FCM push: "🟢 {ticker} hit buy target ${buyPrice}"
  - If `currentPrice >= sellPrice` → send FCM push: "🔴 {ticker} hit sell target ${sellPrice}"
- Mark triggered alerts (optional: add `triggered: true` field to prevent repeat notifications)

### Step 6: Push Notification Handling in iOS App
**Files**: `FinTrackShmeckApp.swift`, `PortfolioViewModel.swift`

- Handle incoming push notifications
- Parse notification payload to extract ticker and alert type (buy/sell)
- Store triggered ticker + type in ViewModel: `var triggeredAlerts: [(ticker: String, isBuy: Bool)]`
- When app opens/foregrounds with triggered alerts, activate blinking animation

### Step 7: Blinking Animation on Triggered Row
**Files**: `StockTrackerView.swift` or `TickerCell.swift`

- When a ticker is in `triggeredAlerts`:
  - Apply a blinking overlay: green (buy) or red (sell)
  - Blink 5 times over ~3 seconds, then stop
  - Remove from `triggeredAlerts` after animation completes
- Use SwiftUI `.opacity` animation with a timer

### Step 8: APNs Configuration
- Create APNs key in Apple Developer portal
- Upload APNs key to Firebase Console → Cloud Messaging settings
- Add Push Notifications capability in Xcode (Signing & Capabilities)
- Add Background Modes → Remote notifications

## Files to Create/Modify
- `FinTrackShmeck/Models/StockPosition.swift` — add buyPrice, sellPrice fields
- `FinTrackShmeck/Models/PortfolioViewModel.swift` — triggeredAlerts, alert sync
- `FinTrackShmeck/Models/FirebaseService.swift` — NEW: Firebase integration
- `FinTrackShmeck/Views/StockTrackerView.swift` — new columns, blinking
- `FinTrackShmeck/FinTrackShmeckApp.swift` — Firebase config, notification delegate
- `functions/main.py` — NEW: Cloud Function for price checking
- `functions/requirements.txt` — NEW: Python dependencies

## Verification
1. Add buy/sell prices in the app → verify they save locally and sync to Firestore
2. Set a buy price above current market price for a stock → trigger should fire on next check
3. Verify push notification received on device
4. Open app → verify the stock row blinks green/red
5. Check Cloud Function logs in Firebase Console for execution
