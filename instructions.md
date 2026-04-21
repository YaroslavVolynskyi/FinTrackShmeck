# FinTrackShmeck — Stock Portfolio Tracker

## Overview

A single-screen iOS app for tracking stock portfolio positions with live price updates, editable cells, and server-side price alerts with push notifications.

## Links

| Resource | URL |
|----------|-----|
| **GitHub Repo** | https://github.com/YaroslavVolynskyi/FinTrackShmeck |
| **Firebase Console** | https://console.firebase.google.com/project/trackershmecker/overview |
| **Google Cloud Console** | https://console.cloud.google.com/home/dashboard?project=trackershmecker |
| **Cloud Functions** | https://console.cloud.google.com/functions/list?project=trackershmecker |
| **Firestore Database** | https://console.firebase.google.com/project/trackershmecker/firestore |
| **Cloud Function Logs** | https://console.cloud.google.com/functions/details/us-central1/check_price_alerts?project=trackershmecker |
| **FCM / Cloud Messaging** | https://console.firebase.google.com/project/trackershmecker/messaging |

## Tech Stack

- **iOS App**: SwiftUI, iOS 17+, Xcode (xcodegen for project generation)
- **Backend**: Firebase (Firestore, Cloud Functions, Cloud Messaging)
- **Cloud Function**: Python 3.12, deployed on Google Cloud (us-central1)
- **Price Data**: Yahoo Finance API (unofficial, free)
- **Bundle ID**: `com.yaroslav.FinTrackShmeck`
- **Firebase Project ID**: `trackershmecker`
- **Apple Team ID**: (see project.yml, gitignored)

## How It Works

### App Features

1. **Portfolio Table** — spreadsheet-like table with sticky header row and sticky ticker column
2. **Live Prices** — fetches current prices from Yahoo Finance on launch and after every edit
3. **Editable Cells** — tap any cell to edit (ticker, price, quantity, description, etc.)
4. **Day's Gain/Loss** — calculated as `(currentPrice - yesterdayClose) * shares`
5. **Auto-Sort** — positions sorted by total value (highest first) after every price refresh
6. **Add/Remove** — "+ NEW" row to add tickers, long-press to delete, empty ticker deletes row
7. **Ticker Validation** — entering a ticker checks Yahoo Finance; shows error popup if not found
8. **Local Persistence** — positions saved to `Documents/positions.json`, survives app restarts
9. **Buy At / Sell At** — editable columns for setting desired buy and required sell prices

### Price Alert System

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│   iOS App   │────▶│   Firestore  │────▶│ Cloud Function  │────▶│  FCM Push    │
│ (set alert) │     │ (store alert)│     │ (check prices)  │     │ (notify app) │
└─────────────┘     └──────────────┘     └─────────────────┘     └──────┬───────┘
                                                                        │
                                                                        ▼
                                                                 ┌──────────────┐
                                                                 │   iOS App    │
                                                                 │ (row blinks) │
                                                                 └──────────────┘
```

1. **User sets buy/sell price** in the app → synced to Firestore via `FirebaseService`
2. **Cloud Function** (`check_price_alerts`) runs every 30 minutes during US market hours (Mon-Fri, 9:30 AM - 4:00 PM ET)
3. Function fetches all alerts from Firestore, groups by ticker, fetches current prices from Yahoo Finance
4. If `currentPrice <= buyPrice` → sends FCM push notification (buy alert)
5. If `currentPrice >= sellPrice` → sends FCM push notification (sell alert)
6. App receives push → triggered ticker row **blinks green** (buy) or **red** (sell) for ~3 seconds

### Firestore Data Model

```
Collection: alerts
Document ID: {fcmToken}_{ticker}
Fields:
  - ticker: String
  - buyPrice: Double (optional)
  - sellPrice: Double (optional)
  - fcmToken: String
  - updatedAt: Timestamp
  - buyTriggered: Boolean (set after notification sent)
  - sellTriggered: Boolean (set after notification sent)
```

## Project Structure

```
FinTrackShmeck/
├── FinTrackShmeck.xcodeproj/
├── FinTrackShmeck/
│   ├── FinTrackShmeckApp.swift          # App entry, Firebase config, notification delegate
│   ├── FinTrackShmeck.entitlements       # Push notification entitlement
│   ├── GoogleService-Info.plist          # Firebase config (gitignored)
│   ├── seed_data.json                    # Initial portfolio data (gitignored)
│   ├── Models/
│   │   ├── StockPosition.swift           # Data model (Codable, Identifiable)
│   │   ├── PortfolioViewModel.swift      # State management, persistence, sorting
│   │   ├── StockService.swift            # Yahoo Finance API client
│   │   └── FirebaseService.swift         # Firestore sync, FCM token management
│   ├── Views/
│   │   ├── StockTrackerView.swift        # Main screen with table layout
│   │   ├── EditableCellView.swift        # Tap-to-edit cell component
│   │   ├── TickerCell.swift              # Ticker cell with edit/delete/focus
│   │   ├── ObservableScrollView.swift    # UIScrollView wrapper for offset tracking
│   │   ├── BlinkModifier.swift           # Green/red blink animation for alerts
│   │   └── SparklineView.swift           # Mini chart (unused currently)
│   ├── Theme/
│   │   └── Theme.swift                   # Light/dark color palette
│   └── Assets.xcassets/
├── functions/
│   ├── main.py                           # Cloud Function: price check + FCM push
│   ├── requirements.txt                  # Python dependencies
│   └── venv/                             # Virtual environment (gitignored)
├── project.yml                           # xcodegen project definition
├── firebase.json                         # Firebase deployment config
├── .firebaserc                           # Firebase project link (gitignored)
├── .gitignore
├── instructions.md                       # This file
└── price_alert123.md                     # Original implementation plan
```

## Sensitive Files (gitignored)

- `FinTrackShmeck/GoogleService-Info.plist` — Firebase API keys
- `FinTrackShmeck/seed_data.json` — personal portfolio data
- `.firebaserc` — Firebase project link
- `functions/venv/` — Python virtual environment

## Development Commands

```bash
# Generate Xcode project
xcodegen generate

# Build for simulator
xcodebuild -project FinTrackShmeck.xcodeproj -scheme FinTrackShmeck \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for device
xcodebuild -project FinTrackShmeck.xcodeproj -scheme FinTrackShmeck \
  -destination 'id=<YOUR_DEVICE_UDID>' -allowProvisioningUpdates build

# Deploy Cloud Function
firebase deploy --only functions --force

# View Cloud Function logs
firebase functions:log

# Install on simulator
xcrun simctl install booted FinTrackShmeck.app
xcrun simctl launch booted com.yaroslav.FinTrackShmeck

# Install on device
xcrun devicectl device install app --device <YOUR_DEVICE_UDID> FinTrackShmeck.app
xcrun devicectl device process launch --device <YOUR_DEVICE_UDID> com.yaroslav.FinTrackShmeck
```

## Sticky Header/Column Implementation

The table uses a 4-part approach since SwiftUI doesn't natively support frozen panes:

1. **Header row** sits outside the vertical `ScrollView` (always visible at top)
2. **Header's scrollable part** is inside a `GeometryReader` with `.offset(x: hOffset)` and `.clipped()`
3. **Data columns** use `ObservableHScrollView` (a `UIViewRepresentable` wrapping `UIScrollView`) that reports `contentOffset.x` via a `@Binding`
4. **Ticker column** and data are in the same vertical `ScrollView` (synced vertically)

This was the only reliable approach — SwiftUI-native methods (GeometryReader, coordinateSpace, LazyVStack pinnedViews) all failed for combined horizontal+vertical freeze.
