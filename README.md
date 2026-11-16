# Seba (সেবা): Flutter app

Mobile app for **Seba**, a service booking and management platform. Customers browse services, book appointments, manage their bookings and ask an AI assistant (English, Bangla or Banglish) for recommendations.

- **Backend API:** [service-booking-backend](https://github.com/saad125862/service-booking-backend), live at https://seba-api-0062.onrender.com (Swagger: `/api/docs`)
- **Overview and plan:** [service-booking-master](https://github.com/saad125862/service-booking-master)
- **Stack:** Flutter 3.47 / Dart 3.13, Riverpod 3 (no code generation), go_router, dio, flutter_secure_storage

## Progress

| Feature | State |
|---|---|
| Foundation: theme, API client, secure token storage, router, reusable widgets | Done |
| Authentication: register, login, logout, validation, persistent session | Done |
| Roles: customer and admin accounts, one-tap demo sign-in, role-based routing | Done |
| Services catalog: home, search, category and price filters, sorting, featured, pagination, details | Done |
| Booking flow: date strip, live time slots, notes, confirmation (taken slots blocked, races handled) | Done |
| My bookings: upcoming and past, status chips, details, cancel pending only | Done |
| Profile: edit details, change password | Planned |
| Admin: add services with a dynamic form (custom fields), dashboard, sales reports | Planned |
| AI assistant (English, Bangla, Banglish) | Planned |

## Run it

Requires the Flutter SDK. By default the app talks to the **live API** (the first request after idle can take 30-60 s on Render's free tier).

```bash
flutter pub get
flutter run                      # uses the live API
```

Use the local Docker backend instead (see the backend README):

```bash
# Android emulator (10.0.2.2 is the host machine)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# Browser / desktop
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Demo accounts (the login screen has one-tap **Customer** and **Admin** quick sign-in buttons):

| Role | Email | Password |
|---|---|---|
| Customer | `demo@example.com` | `Demo@1234` |
| Admin | `admin@example.com` | `Admin@1234` |

Admins are routed to their own area; customers cannot open it. All prices are in **BDT** (Bangladeshi taka, ৳).

## Tests

```bash
flutter analyze
flutter test
```

Covers the form validators (mirroring the backend rules), API error parsing and the login screen's validation.

## Architecture

Feature-first, with clear layers and no business logic in widgets:

```
lib/
  core/
    config/      build-time config (API base URL)
    network/     Dio ApiClient (JWT header, response envelope, 401 handling), ApiException
    storage/     TokenStorage (secure storage)
    router/      go_router with auth-driven redirects and a tabbed shell
    theme/       Material 3 theme from the Seba brand colour
    widgets/     reusable widgets: AppButton, AppTextField, StatusBanner, Loading/Empty/Error views, SebaLogo
    utils/       validators
  features/
    auth/        domain (User), data (AuthRepository), presentation (AuthController, screens)
    services/ bookings/ profile/ assistant/ shell/
```

- **State management:** Riverpod `AsyncNotifier`s. `authProvider` restores the saved session on launch, which is what makes the login persistent.
- **Routing:** the router listens to `authProvider`. Restoring the session shows a splash, signed-out users go to login, signed-in users get the tabs. A 401 from any protected call signs the user out.
- **Errors:** every failure becomes an `ApiException` with a user-friendly message (network down, server waking up, validation details from the API).
- **Responsive:** auth screens are width-constrained, and the shell switches from a bottom bar to a navigation rail on wide screens.
