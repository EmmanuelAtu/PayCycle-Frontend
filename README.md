# PayCycle — Flutter Frontend

> Set it once. Get paid on your schedule.

PayCycle is a recurring payment management app built for the Nigerian market, powered by Nomba's payment infrastructure. This repository contains the Flutter frontend.

---

## Table of contents

- [Overview](#overview)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Environment setup](#environment-setup)
- [Running the app](#running-the-app)
- [App flow](#app-flow)
- [Key screens](#key-screens)
- [API integration](#api-integration)
- [Packages used](#packages-used)
- [Subscriber payment page](#subscriber-payment-page)
- [Known placeholders](#known-placeholders)

---

## Overview

PayCycle lets service providers — tutors, gym owners, consultants, and anyone who bills periodically — create recurring payment plans, share a one-time payment link with each subscriber, and automatically charge their saved card on the defined schedule. Subscribers can also track and manage their own subscriptions inside the same app.

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Routing | go_router |
| HTTP client | Dio |
| Secure storage | flutter_secure_storage |
| Animations | Lottie (dotLottie format) |
| Icons | font_awesome_flutter |
| Payment checkout | Nomba Checkout (WebView) |
| Backend | FastAPI (separate repo) |

---

## Project structure

```
lib/
├── core/
│   ├── api_client.dart        # All HTTP calls — screens never touch Dio directly
│   └── theme.dart             # Brand colors, text styles, app theme
├── models/
│   └── plan.dart              # Plan, Subscriber, BillingCycle, SubscriberStatus enums
├── screens/
│   ├── onboarding/
│   │   ├── splash_screen.dart
│   │   └── onboarding_screen.dart
│   ├── auth/
│   │   ├── auth_widgets.dart  # Shared HeroBand and TrustBadges widgets
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── provider/
│   │   ├── dashboard_screen.dart
│   │   ├── subscribers_screen.dart
│   │   └── create_plan_screen.dart
│   └── subscriptions/
│       ├── my_subscriptions_screen.dart
│       └── pay_screen.dart    # Nomba Checkout WebView — opened via deep link
├── widgets/
│   └── bottom_nav.dart        # Shared 4-tab bottom nav bar
├── main.dart                  # Entry point, ApiClient.init(), go_router config
web/
└── pay.html                   # Standalone subscriber payment page (served by backend)
```

---

## Getting started

### Prerequisites

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`
- Android Studio or VS Code with Flutter extension
- A running instance of the PayCycle backend (see backend repo)

### Installation

```bash
git clone https://github.com/your-org/paycycle-flutter.git
cd paycycle-flutter
flutter pub get
```

---

## Environment setup

The backend base URL is **never hardcoded** in source. It is injected at build/run time using `--dart-define`:

```bash
# Development (ngrok tunnel)
flutter run --dart-define=API_BASE_URL=https://your-ngrok-url.ngrok-free.app

# Production
flutter run --dart-define=API_BASE_URL=https://your-backend.onrender.com
```

If `API_BASE_URL` is not provided, the app falls back to the ngrok development URL set in `api_client.dart`. Update that default for your own environment.

> **Never commit a real production URL or API key into source code.**

---

## Running the app

```bash
# Debug on connected device or emulator
flutter run --dart-define=API_BASE_URL=https://your-backend-url

# Build release APK
flutter build apk --dart-define=API_BASE_URL=https://your-backend.onrender.com

# Build release iOS
flutter build ios --dart-define=API_BASE_URL=https://your-backend.onrender.com
```

---

## App flow

```
Splash (2.2s)
    └── Onboarding (3 slides, first launch only)
            └── Login / Signup
                    └── Dashboard (Home tab)
                            ├── Subscribers tab  →  Subscriber status board
                            ├── New Plan tab     →  Create plan screen
                            └── My Subs tab      →  My subscriptions screen

Payment link (external)
    └── pay.html (browser) or PayScreen (deep link)
            └── Nomba Checkout (WebView)
                    └── Success screen
```

---

## Key screens

### Splash screen
Animated loading bar on navy background. Auto-navigates to onboarding on first launch, or dashboard if already logged in (requires SharedPreferences check — see [Known placeholders](#known-placeholders)).

### Onboarding
Three slides with Lottie animations (`finance.lottie`, `link.lottie`, `analytics.lottie`). Dot indicator, skip button, and a "Get started" CTA on the final slide.

Animation files must be placed at:
```
assets/animations/finance.lottie
assets/animations/link.lottie
assets/animations/analytics.lottie
```

And declared in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/animations/finance.lottie
    - assets/animations/link.lottie
    - assets/animations/analytics.lottie
    - assets/animations/Share.json
    - assets/animations/links.json
```

### Dashboard
Fetches plans from `GET /plans` and summary stats from `GET /dashboard`. User name is loaded from `GET /auth/me` on every open, with a local storage fallback so the topbar never shows blank.

### Subscribers screen
Per-plan subscriber list. Filterable by status (All / Active / Failed / Overdue). Failed and overdue rows show retry charge and WhatsApp send-link action buttons.

### Create plan screen
Live preview card that updates as the provider types. Billing cycle selector (Daily / Weekly / Monthly / Quarterly). Billing day picker shown for Monthly and Quarterly. Generates and displays the payment link after saving.

### My subscriptions screen
Shows all plans the logged-in user is subscribed to as a payer. Estimated monthly spend, next charge dates, and a cancel flow with confirmation dialog.

---

## API integration

All network calls go through `lib/core/api_client.dart`. Screens never import Dio directly.

### Auth

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/login` | Returns `{ access_token, token_type }` |
| POST | `/auth/signup` | Creates account, returns user object |
| GET | `/auth/me` | Returns `{ name, email, phone_number }` |

The JWT token is stored in `flutter_secure_storage` under the key `jwt` and automatically attached to every request via a Dio interceptor. The user's name is stored under `user_name`.

### Plans

| Method | Endpoint | Description |
|---|---|---|
| GET | `/plans` | List all provider's plans |
| POST | `/plans` | Create a new plan |

### Subscribers

| Method | Endpoint | Description |
|---|---|---|
| GET | `/plans/:id/subscribers` | List subscribers for a plan |
| POST | `/charge/:subscriberId` | Retry a failed charge |
| PATCH | `/subscribers/:id/status` | Manual status override |

### Subscriptions (as a payer)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/pay/:token` | Get plan details from a payment link token |
| GET | `/my-subscriptions` | List plans the user is subscribed to |

---

## Packages used

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^14.0.0
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  webview_flutter: ^4.0.0
  lottie: ^3.1.0
  font_awesome_flutter: ^10.7.0
```

---

## Subscriber payment page

`web/pay.html` is a standalone HTML page served by the backend at `/pay/:token`. It:

1. Fetches plan details from `GET /pay/:token`
2. Shows the provider name, plan name, amount, billing cycle, and charge schedule
3. Collects the subscriber's name, email, and phone number
4. Collects card details (to be replaced with Nomba Checkout — see below)
5. Shows a success screen with a receipt and an app download prompt

> **Important:** The card input form in `pay.html` is a UI placeholder. Raw card data must never be sent to your own server. Before going live, replace the `handleSubscribe()` function with a call to `POST /pay/:token/initiate` which returns a Nomba-hosted checkout URL, then redirect the subscriber there. Confirm the exact flow with your backend teammate.

---

## Known placeholders

These items are marked `// PLACEHOLDER` in the code and need to be completed before production:

| Location | What's needed |
|---|---|
| `splash_screen.dart` | SharedPreferences check — skip onboarding for returning users, go straight to dashboard if token exists |
| `onboarding_screen.dart` | Mark onboarding as seen in SharedPreferences after "Get started" |
| `login_screen.dart` | Forgot password flow |
| `subscribers_screen.dart` | WhatsApp deep link launch for send-link button |
| `create_plan_screen.dart` | System share sheet for payment link |
| `pay_screen.dart` | Nomba Checkout redirect URL detection — update the success URL to match your backend's return URL |
| `my_subscriptions_screen.dart` | Cancel subscription API call and card update flow |
| `web/pay.html` | Replace card form with Nomba Checkout redirect |
| `main.dart` | go_router redirect guard — check token on every navigation, redirect to `/login` if expired |

---

## Brand colors

| Name | Hex | Usage |
|---|---|---|
| Navy | `#0B1F3A` | Primary background, topbars |
| Navy Mid | `#1A3358` | Stats band |
| Emerald | `#00A86B` | CTAs, active states, success |
| Emerald Dark | `#008055` | Hover, links |
| Emerald Light | `#E6F7F1` | Badges, avatar backgrounds |
| Fail Red | `#A32D2D` | Error states, failed payments |
| Warn Amber | `#92600A` | Overdue states |

---

## Team

| Role | Name |
|---|---|
| Flutter Developer | Ezeugbana Prince Franklyn |
| Backend Developer | Atu Emmanuel Agbor|
| Backend Developer | Irom Jude Achina|

---

*Built for the Tech Hackathon — PayCycle, June 2025.*