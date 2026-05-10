# FinTrack iOS

FinTrack is a SwiftUI iOS app for personal finance management: accounts, transactions, budgets, reports, savings goals, transfers, and CSV import/export.

## Features

- Onboarding and sign-in flow
- Home dashboard with recent transactions
- Accounts list, details, and account creation
- Add transaction flow with validation and budget warning support
- Budget management and report views
- Savings goals management
- Transfers between accounts
- CSV import/export tools
- Category management

## Tech stack

- Swift 5
- SwiftUI + Observation
- Async/await networking
- Xcode test plan with unit and UI test targets

## Project structure

```text
FinTrackIOS/
├─ FinTrackIOS/                 # App source
│  ├─ Core/                     # Networking, models, auth, design system
│  ├─ Features/                 # Feature modules (Home, Accounts, Budgets, etc.)
│  ├─ Navigation/               # Root and tab navigation
│  └─ Resources/
├─ FinTrackIOSTests/            # Unit tests
├─ FinTrackIOSUITests/          # UI tests
├─ Configs/                     # Build configuration files
│  ├─ Debug.xcconfig
│  └─ Release.xcconfig
└─ FinTrackIOS.xcodeproj
```

## Configuration

`API_BASE_URL` is injected from build configuration files via `Info.plist`.

- `Configs/Debug.xcconfig`: `http://localhost:8080`
- `Configs/Release.xcconfig`: `https://api.fintrack.example.com` (placeholder)

Update these values as needed for your backend environments.

## Getting started

1. Open `FinTrackIOS.xcodeproj` in Xcode.
2. Select the **FinTrackIOS** scheme.
3. Run on an iOS simulator/device.
4. Ensure your backend is reachable at the configured `API_BASE_URL`.

## Build and test

- Build from terminal:

```bash
xcodebuild -project FinTrackIOS.xcodeproj -scheme FinTrackIOS -destination 'platform=iOS Simulator,name=iPhone 17' build
```

- Run tests from Xcode using the shared `FinTrackIOS.xctestplan` (Product → Test).
