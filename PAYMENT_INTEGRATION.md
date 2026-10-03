# Payment Server Integration Guide for FancyWorld

This document details the self-hosted UPI Payment Server integration into FancyWorld (Flutter Mobile App + Node.js/Express Backend).

---

## 1. Architecture Overview

```
 +------------------+            +---------------------+            +-----------------------+
 |                  |  1. Create |                     |  2. Create |                       |
 |  Flutter App     |----------->|  FancyWorld Backend |----------->|  UPI Payment Server   |
 |  (Mobile/Web)    |  Order     |  (Node.js / Express)|  Order     |  (Self-Hosted)        |
 |                  |            |                     |            |                       |
 |                  |<-----------|                     |<-----------|                       |
 |                  |  3. PayURL |                     |  4. PayURL |                       |
 |                  |            +---------------------+            +-----------------------+
 |                  |                       ^                                   |
 |                  |                       |  5. Signed Callback (HMAC)        |
 |                  |                       +-----------------------------------+
 |                  |                       |  6. Server-to-Server Status Check |
 |                  |---------------------->+-----------------------------------+
 +------------------+   7. Verify Status
```

1. **Client Order Creation**: App calls backend `POST /api/payments/create-order`. Backend creates order in DB with `Pending` status.
2. **Payment Server Request**: Backend calls `POST {PAYMENT_SERVER_URL}/api/create` using secret `APP_KEY`.
3. **PayURL & Random Paise**: Payment server returns `payUrl` and exact `amount` with paise (e.g. `999.37`). Backend saves `amountToPay` and `paymentServerOrderId` on the order and returns `payUrl` to client.
4. **User Payment**: App opens `payUrl` via `url_launcher` in browser / UPI app.
5. **Signed Callback**: Payment Server sends a signed `POST /api/payments/callback` to FancyWorld backend. Header `x-signature` contains HMAC-SHA256 hex string of the raw request body signed with `APP_KEY`. Backend verifies signature with constant-time compare (`crypto.timingSafeEqual`) and idempotently updates order status (`Paid`, `WRONG`, `Cancelled`).
6. **S2S Safety Net**: Mobile app calls `GET /api/payments/orders/:id/payment-status`. Backend queries payment server's `GET {PAYMENT_SERVER_URL}/api/status?id=<paymentServerOrderId>` directly (server-to-server) to handle missed callbacks.
7. **Retry Background Job**: Backend runs a background timer every 2 minutes to check pending orders older than 6 minutes.

---

## 2. Environment Variables

Set these in `backend/.env` (and documented in `backend/.env.example`):

```env
# Payment Server Settings
PAYMENT_SERVER_URL=https://REPLACE-WITH-MY-PAYMENT-SERVER
APP_KEY=your_payment_server_secret_app_key_here
RETURN_URL_APP=fancyworld://payment-done
RETURN_URL_WEB=https://REPLACE-WITH-MY-SITE/payment-result
```

> **Security Rule**: `APP_KEY` resides strictly on your backend server and is NEVER exposed in mobile app or client JavaScript.

---

## 3. How to Run Locally

### Backend:
```bash
cd backend
npm install
npm run dev
```

### Run Automated Payment Tests:
```bash
cd backend
npm test
```

### Frontend (Flutter):
```bash
cd frontend
flutter pub get
flutter run
```

---

## 4. Deep Link Configuration

- **App Deep Link Scheme**: `fancyworld://payment-done`
- **Android Manifest**: Configured in `frontend/android/app/src/main/AndroidManifest.xml`:
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="fancyworld" />
  </intent-filter>
  ```

---

## 5. How to Test with Fake Notification / Callback

To simulate a payment notification / webhook locally or on staging:

### Send Signed Webhook Callback to Backend (`POST /api/payments/callback`)
Generate the HMAC-SHA256 signature for your JSON body using `APP_KEY`:

```bash
# Example payload
PAYLOAD='{"ref":"<ORDER_ID_OR_REF>","orderId":"<PAYMENT_SERVER_ORDER_ID>","status":"SUCCESS","amount":999.37,"paid":999.37,"utr":"UTR123456789"}'

# Compute HMAC SHA256 hex signature using APP_KEY
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "your_app_key_here" | awk '{print $2}')

# Send callback
curl -X POST http://localhost:5050/api/payments/callback \
  -H "Content-Type: application/json" \
  -H "x-signature: $SIGNATURE" \
  -d "$PAYLOAD"
```

### Send Fake Notification to Payment Server (`/api/notify` using `NOTIFY_KEY`)
If you want to trigger payment server processing directly:

```bash
curl -X POST https://REPLACE-WITH-MY-PAYMENT-SERVER/api/notify \
  -H "x-notify-key: <YOUR_NOTIFY_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"utr": "UTR987654321", "amount": 999.37}'
```

---

## 6. How to Deploy Backend

1. Push backend code to your server/hosting provider (e.g. AWS, Render, DigitalOcean, Heroku).
2. Configure production environment variables (`PAYMENT_SERVER_URL`, `APP_KEY`, `MONGODB_URI`, `JWT_SECRET`).
3. Set `CALLBACK_URL` on Payment Server to: `https://your-backend-domain.com/api/payments/callback`.
4. Ensure MongoDB Atlas connection is allowed from your server's IP.
5. Start server via `npm start` or process manager (`pm2 start server.js --name "fancyworld-api"`).
