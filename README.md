# Seba (সেবা): Flutter app

Mobile app for **Seba**, a service booking and management platform. Customers browse services, book appointments, manage their bookings and ask an AI assistant (English, Bangla or Banglish) for recommendations.

- **Backend API:** [service-booking-backend](https://github.com/saad125862/service-booking-backend), live at https://seba-api-0062.onrender.com (Swagger: `/api/docs`)
- **Overview and plan:** [service-booking-master](https://github.com/saad125862/service-booking-master)
- **Stack:** Flutter 3.47 / Dart 3.13, Riverpod 3 (no code generation), go_router, dio, flutter_secure_storage

**Download the Android APK:** [Seba v1.0.1](https://github.com/saad125862/service-booking-app/releases/tag/v1.0.1) (built against the live API; the login screen has one-tap Customer and Admin demo buttons).

## Progress

| Feature | State |
|---|---|
| Foundation: theme, API client, secure token storage, router, reusable widgets | Done |
| Authentication: register, login, logout, validation, persistent session | Done |
| Roles: customer and admin accounts, one-tap demo sign-in, role-based routing | Done |
| Services catalog: home, search, category and price filters, sorting, featured, pagination, details | Done |
| Booking flow: date strip, live time slots, notes, confirmation (taken slots blocked, races handled) | Done |
| My bookings: upcoming and past, status chips, details, cancel pending only | Done |
| Profile: edit details and default address, change password, light/dark mode, sign out | Done |
| Admin shell (sidebar, More menu), sales dashboard with charts, bookings management (status and payment verification) | Done |
| Admin: services (search, hide / show) with a **dynamic add / edit form**: custom fields render by type and admins can add new fields on the spot; photos are chosen with the **file picker** (preview, change, remove; JPG, PNG or WebP up to 5 MB, uploaded on save); custom-field manager | Done |
| Admin: payment options (cash, card, bKash, Nagad, online gateways), discount request approvals (percent or taka, validity, note), sales reports (by day, service, category, payment; copy CSV) | Done |
| Online payment: Pay button on a booking opens the SSLCommerz / aamarPay checkout for the exact amount and waits for the server to confirm; the assistant sends the same link in chat | Done |
| AI assistant chat (English, Bangla, Banglish), recommendation cards, discount requests that wait for an admin | Done |
| Payment options at booking (cash, card, bKash, Nagad), price snapshot, one-order discounts | Done |
| Left sidebar with sign out (drawer on phones), dark/light mode, in-app notifications | Done |
| Dark premium design and motion: page transitions, fading tabs, staggered lists, press feedback, skeleton loaders, animated charts, app icon | Done |
| Release APK (v1.0.1, `kotlin.incremental=false`) published as a GitHub Release | Done |


## Screenshots

Taken on an Android emulator (Pixel 10 Pro XL) running the release build. Prices are in BDT, times in Asia/Dhaka.

### Sign in and browse

Customers and admins sign in from the same screen; the **Customer** and **Admin** buttons fill in the demo accounts. The catalog shows live prices in BDT with search, category and price filters.

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/01-login.jpg" width="190" alt="Sign in with one-tap demo accounts"><br><sub>Sign in with one-tap demo accounts</sub></td><td align="center" valign="top"><img src="docs/screenshots/02-login-validation.jpg" width="190" alt="Clear validation messages"><br><sub>Clear validation messages</sub></td><td align="center" valign="top"><img src="docs/screenshots/03-home.jpg" width="190" alt="Featured and all services"><br><sub>Featured and all services</sub></td><td align="center" valign="top"><img src="docs/screenshots/04-home-all-services.jpg" width="190" alt="Prices in BDT, durations"><br><sub>Prices in BDT, durations</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/05-search.jpg" width="190" alt="Search"><br><sub>Search</sub></td><td align="center" valign="top"><img src="docs/screenshots/06-details.jpg" width="190" alt="Service details with extra info"><br><sub>Service details with extra info</sub></td></tr>
</table>

### Booking and payment

Booking needs a date, a live time slot (taken slots are blocked), an address and a payment option. An **approved discount** is applied automatically to that customer's next booking of that service, once. Payment options (cash, card, bKash, Nagad, online gateways) are managed by admins. **Online payment** opens a gateway checkout for the exact booking amount; the server asks the gateway to confirm before marking the booking paid.

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/07-booking-form.jpg" width="190" alt="Live slots, address, discount applied"><br><sub>Live slots, address, discount applied</sub></td><td align="center" valign="top"><img src="docs/screenshots/08-booking-payment-options.jpg" width="190" alt="Payment options set by the admin"><br><sub>Payment options set by the admin</sub></td><td align="center" valign="top"><img src="docs/screenshots/09-booking-bkash-reference.jpg" width="190" alt="bKash asks for the transaction ID"><br><sub>bKash asks for the transaction ID</sub></td><td align="center" valign="top"><img src="docs/screenshots/10-booking-online-payment.jpg" width="190" alt="Online checkout selected"><br><sub>Online checkout selected</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/11-booking-confirmed-pay.jpg" width="190" alt="Confirmed, with the exact amount to pay"><br><sub>Confirmed, with the exact amount to pay</sub></td><td align="center" valign="top"><img src="docs/screenshots/12-gateway-checkout.jpg" width="190" alt="Gateway checkout (demo gateway)"><br><sub>Gateway checkout (demo gateway)</sub></td><td align="center" valign="top"><img src="docs/screenshots/13-gateway-payment-received.jpg" width="190" alt="Gateway confirms the payment"><br><sub>Gateway confirms the payment</sub></td><td align="center" valign="top"><img src="docs/screenshots/14-booking-waiting-for-payment.jpg" width="190" alt="App waits for the confirmation"><br><sub>App waits for the confirmation</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/15-booking-paid.jpg" width="190" alt="Booking marked Paid with the gateway reference"><br><sub>Booking marked Paid with the gateway reference</sub></td></tr>
</table>

### AI assistant (English, Bangla, Banglish)

Gemini answers from the live catalog in the language the customer writes in. It **never grants a discount itself**: it first asks which exact service, files a request, tells the customer an admin is processing it, and answers when the admin decides. When a customer asks to pay, the server (not the model) creates the gateway link for the booking's exact amount.

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/17-assistant-welcome.jpg" width="190" alt="Suggestions in three languages"><br><sub>Suggestions in three languages</sub></td><td align="center" valign="top"><img src="docs/screenshots/19-assistant-english.jpg" width="190" alt="Bangla and English answers with service cards"><br><sub>Bangla and English answers with service cards</sub></td><td align="center" valign="top"><img src="docs/screenshots/20-assistant-banglish.jpg" width="190" alt="Banglish"><br><sub>Banglish</sub></td><td align="center" valign="top"><img src="docs/screenshots/21-assistant-discount-which-service.jpg" width="190" alt="Discount: asks which service exactly"><br><sub>Discount: asks which service exactly</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/22-assistant-discount-waiting.jpg" width="190" alt="Waiting for an admin"><br><sub>Waiting for an admin</sub></td><td align="center" valign="top"><img src="docs/screenshots/48-assistant-discount-request.jpg" width="190" alt="Request filed for one service"><br><sub>Request filed for one service</sub></td><td align="center" valign="top"><img src="docs/screenshots/49-assistant-discount-approved.jpg" width="190" alt="Admin approved: answer written in the customer's language"><br><sub>Admin approved: answer written in the customer's language</sub></td><td align="center" valign="top"><img src="docs/screenshots/50-assistant-payment-link.jpg" width="190" alt="Payment link for the exact amount"><br><sub>Payment link for the exact amount</sub></td></tr>
</table>

### My bookings, notifications and account

Bookings can be cancelled while pending. Notifications cover bookings, payments and discount decisions. Dark mode is the default; light mode is one tap away in the sidebar.

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/16-my-bookings.jpg" width="190" alt="My bookings"><br><sub>My bookings</sub></td><td align="center" valign="top"><img src="docs/screenshots/52-my-bookings.jpg" width="190" alt="Upcoming bookings with status chips"><br><sub>Upcoming bookings with status chips</sub></td><td align="center" valign="top"><img src="docs/screenshots/53-booking-details.jpg" width="190" alt="Booking details"><br><sub>Booking details</sub></td><td align="center" valign="top"><img src="docs/screenshots/51-notifications.jpg" width="190" alt="In-app notifications"><br><sub>In-app notifications</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/54-profile.jpg" width="190" alt="Profile and default address"><br><sub>Profile and default address</sub></td><td align="center" valign="top"><img src="docs/screenshots/38-customer-sidebar.jpg" width="190" alt="Sidebar with sign out and theme"><br><sub>Sidebar with sign out and theme</sub></td><td align="center" valign="top"><img src="docs/screenshots/55-home-light-mode.jpg" width="190" alt="Light mode: home"><br><sub>Light mode: home</sub></td><td align="center" valign="top"><img src="docs/screenshots/56-assistant-light-mode.jpg" width="190" alt="Light mode: assistant"><br><sub>Light mode: assistant</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/57-my-bookings-light-mode.jpg" width="190" alt="Light mode: bookings"><br><sub>Light mode: bookings</sub></td></tr>
</table>

### Admin: dashboard, bookings and payments

Admins see sales (confirmed and completed bookings, after discounts), the pipeline of pending bookings and what needs attention. They confirm or cancel bookings and **verify manual payments** (bKash and Nagad transaction IDs).

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/23-admin-dashboard.jpg" width="190" alt="Dashboard"><br><sub>Dashboard</sub></td><td align="center" valign="top"><img src="docs/screenshots/24-admin-dashboard-charts.jpg" width="190" alt="Revenue chart and status split"><br><sub>Revenue chart and status split</sub></td><td align="center" valign="top"><img src="docs/screenshots/25-admin-bookings.jpg" width="190" alt="All bookings with filters"><br><sub>All bookings with filters</sub></td><td align="center" valign="top"><img src="docs/screenshots/26-admin-bookings-awaiting-verification.jpg" width="190" alt="Payments awaiting verification"><br><sub>Payments awaiting verification</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/27-admin-booking-detail.jpg" width="190" alt="Booking detail"><br><sub>Booking detail</sub></td><td align="center" valign="top"><img src="docs/screenshots/28-admin-booking-actions.jpg" width="190" alt="Confirm, complete, verify payment"><br><sub>Confirm, complete, verify payment</sub></td><td align="center" valign="top"><img src="docs/screenshots/29-admin-payment-verified.jpg" width="190" alt="Payment marked as received"><br><sub>Payment marked as received</sub></td><td align="center" valign="top"><img src="docs/screenshots/39-admin-sidebar.jpg" width="190" alt="Admin sidebar"><br><sub>Admin sidebar</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/47-admin-notifications.jpg" width="190" alt="Admin notifications"><br><sub>Admin notifications</sub></td></tr>
</table>

### Admin: discount requests

Requests made through the assistant arrive here. The admin approves (percent or fixed taka, validity, a note for the assistant) or declines. An approved discount belongs to that customer only and is used by one order.

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/30-admin-discount-requests.jpg" width="190" alt="Pending requests"><br><sub>Pending requests</sub></td><td align="center" valign="top"><img src="docs/screenshots/32-admin-approve-discount-amount.jpg" width="190" alt="Approve with a percent; shows the customer price"><br><sub>Approve with a percent; shows the customer price</sub></td><td align="center" valign="top"><img src="docs/screenshots/34-admin-discount-approved-tab.jpg" width="190" alt="Approved, with the assistant's reply"><br><sub>Approved, with the assistant's reply</sub></td><td align="center" valign="top"><img src="docs/screenshots/33-admin-discount-approved.jpg" width="190" alt="Queue empty after deciding"><br><sub>Queue empty after deciding</sub></td></tr>
</table>

### Admin: services, dynamic form, payment options, reports

The add / edit service form is **dynamic**: admins define custom fields (text, long text, number, yes/no, dropdown) and can add a new field right from the form. Photos are chosen with the file picker. Sales reports group by day, service, category or payment method and export as CSV.

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/35-admin-services.jpg" width="190" alt="Services (show / hide)"><br><sub>Services (show / hide)</sub></td><td align="center" valign="top"><img src="docs/screenshots/36-admin-add-service-form.jpg" width="190" alt="Add service form"><br><sub>Add service form</sub></td><td align="center" valign="top"><img src="docs/screenshots/37-admin-add-service-photo-and-fields.jpg" width="190" alt="Photo picker and custom fields"><br><sub>Photo picker and custom fields</sub></td><td align="center" valign="top"><img src="docs/screenshots/45-admin-custom-fields.jpg" width="190" alt="Custom field manager"><br><sub>Custom field manager</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/46-admin-add-custom-field.jpg" width="190" alt="Add a custom field"><br><sub>Add a custom field</sub></td><td align="center" valign="top"><img src="docs/screenshots/43-admin-payment-options.jpg" width="190" alt="Payment options"><br><sub>Payment options</sub></td><td align="center" valign="top"><img src="docs/screenshots/44-admin-add-payment-option.jpg" width="190" alt="Add a payment option"><br><sub>Add a payment option</sub></td><td align="center" valign="top"><img src="docs/screenshots/40-admin-sales-report.jpg" width="190" alt="Sales report summary"><br><sub>Sales report summary</sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/42-admin-sales-by-service.jpg" width="190" alt="Revenue by service"><br><sub>Revenue by service</sub></td><td align="center" valign="top"><img src="docs/screenshots/41-admin-sales-report-details.jpg" width="190" alt="Daily table, copy CSV"><br><sub>Daily table, copy CSV</sub></td></tr>
</table>


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

130 tests cover validators, API errors, login, routing and redirects, the catalog, booking, my bookings, the assistant (incl. discount waiting and pay links), notifications, the admin shell, dashboard, bookings, the dynamic service form, custom fields, payment options, discount approvals, sales reports and online payment. Repositories are replaced with fakes, so no server is needed.

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
