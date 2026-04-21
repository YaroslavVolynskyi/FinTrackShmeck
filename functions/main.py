"""
Cloud Function: Check stock prices against user alerts and send push notifications.
Runs every 30 minutes during US market hours (Mon-Fri 9:30 AM - 4:00 PM ET).
"""

import requests
from datetime import datetime, timezone, timedelta
from firebase_functions import scheduler_fn
from firebase_admin import initialize_app, firestore, messaging

initialize_app()

ET = timezone(timedelta(hours=-4))  # Eastern Time (EDT)


def is_market_open() -> bool:
    """Check if US stock market is currently open."""
    now = datetime.now(ET)
    # Weekday: Mon=0, Fri=4
    if now.weekday() > 4:
        return False
    market_open = now.replace(hour=9, minute=30, second=0, microsecond=0)
    market_close = now.replace(hour=16, minute=0, second=0, microsecond=0)
    return market_open <= now <= market_close


def fetch_price(ticker: str) -> float | None:
    """Fetch current price from Yahoo Finance."""
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?interval=1d&range=1d"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        resp = requests.get(url, headers=headers, timeout=10)
        data = resp.json()
        return data["chart"]["result"][0]["meta"]["regularMarketPrice"]
    except Exception:
        return None


@scheduler_fn.on_schedule(schedule="every 30 minutes", region="us-central1")
def check_price_alerts(event: scheduler_fn.ScheduledEvent) -> None:
    """Check all price alerts and send push notifications for triggered ones."""
    if not is_market_open():
        print("Market is closed, skipping.")
        return

    db = firestore.client()
    alerts = db.collection("alerts").stream()

    # Group alerts by ticker
    ticker_alerts: dict[str, list] = {}
    for doc in alerts:
        alert = doc.to_dict()
        ticker = alert.get("ticker", "")
        if ticker:
            ticker_alerts.setdefault(ticker, []).append({**alert, "_doc_id": doc.id})

    if not ticker_alerts:
        print("No alerts configured.")
        return

    # Fetch prices for all unique tickers
    for ticker, alert_list in ticker_alerts.items():
        price = fetch_price(ticker)
        if price is None:
            print(f"Failed to fetch price for {ticker}")
            continue

        print(f"{ticker}: ${price:.2f}")

        for alert in alert_list:
            fcm_token = alert.get("fcmToken")
            if not fcm_token:
                continue

            buy_price = alert.get("buyPrice")
            sell_price = alert.get("sellPrice")
            doc_id = alert["_doc_id"]

            # Check buy alert
            if buy_price and price <= buy_price:
                send_notification(
                    fcm_token,
                    title=f"Buy Alert: {ticker}",
                    body=f"{ticker} dropped to ${price:.2f} (target: ${buy_price:.2f})",
                    ticker=ticker,
                    alert_type="buy",
                )
                # Mark as triggered to avoid repeat
                db.collection("alerts").document(doc_id).update(
                    {"buyTriggered": True}
                )

            # Check sell alert
            if sell_price and price >= sell_price:
                send_notification(
                    fcm_token,
                    title=f"Sell Alert: {ticker}",
                    body=f"{ticker} reached ${price:.2f} (target: ${sell_price:.2f})",
                    ticker=ticker,
                    alert_type="sell",
                )
                db.collection("alerts").document(doc_id).update(
                    {"sellTriggered": True}
                )


def send_notification(
    token: str, title: str, body: str, ticker: str, alert_type: str
) -> None:
    """Send FCM push notification."""
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={"ticker": ticker, "alertType": alert_type},
        token=token,
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default", badge=1)
            )
        ),
    )
    try:
        messaging.send(message)
        print(f"Notification sent: {title}")
    except Exception as e:
        print(f"Failed to send notification: {e}")
