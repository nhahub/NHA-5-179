"""Find a dedicated demo bot's IDs or register its ClinicOS callback."""

import argparse
import json
import re
import secrets
from getpass import getpass
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


PRODUCTION_PATH = "/webhook/clinicos-p1-telegram"


def telegram(token, method, params=None):
    request = Request(
        f"https://api.telegram.org/bot{token}/{method}",
        data=json.dumps(params or {}).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urlopen(request, timeout=20) as response:
            result = json.load(response)
    except HTTPError as error:
        raise SystemExit(f"Telegram {method} returned HTTP {error.code}.") from None
    except (URLError, OSError, ValueError):
        raise SystemExit(f"Could not complete Telegram {method}.") from None
    if not result.get("ok"):
        raise SystemExit(f"Telegram rejected {method}.")
    return result["result"]


def identify(token):
    if telegram(token, "getWebhookInfo")["url"]:
        raise SystemExit("Use a dedicated demo bot without an existing callback to identify its owner.")
    bot = telegram(token, "getMe")
    nonce = secrets.token_hex(4)
    input(f"Send /start {nonce} in a private chat with @{bot['username']}, then press Enter here. ")
    updates = telegram(token, "getUpdates", {"allowed_updates": ["message"], "timeout": 5})
    for update in updates:
        message = update.get("message", {})
        if message.get("chat", {}).get("type") == "private" and message.get("text") == f"/start {nonce}":
            print(f"Demo bot ID: {bot['id']}")
            print(f"Demo bot owner Telegram user ID: {message['from']['id']}")
            return
    raise SystemExit("The matching private message was not found. Run identify again and send the new command.")


def show_webhook(token):
    info = telegram(token, "getWebhookInfo")
    print("Callback:", info["url"] or "(unset)")
    print("Pending updates:", info.get("pending_update_count", 0))
    if info.get("last_error_message"):
        print("Last Telegram error:", info["last_error_message"])


def register(token, base):
    try:
        url = urlsplit(base)
    except ValueError:
        url = None
    if (
        not url or url.scheme != "https" or not url.hostname
        or url.username is not None or url.password is not None
        or url.path not in {"", "/"} or url.query or url.fragment
    ):
        raise SystemExit("Provide the public HTTPS tunnel origin without a path.")
    callback = base.rstrip("/") + PRODUCTION_PATH
    current = telegram(token, "getWebhookInfo")["url"]
    if current and current != callback and not current.endswith(PRODUCTION_PATH):
        raise SystemExit("This bot already has a different webhook. Use a dedicated ClinicOS test bot.")
    secret = getpass("Telegram webhook secret (same value as n8n Header Auth): ")
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,256}", secret):
        raise SystemExit("Use 1–256 letters, digits, underscores, or hyphens for the secret.")
    telegram(token, "setWebhook", {
        "url": callback,
        "secret_token": secret,
        "allowed_updates": ["message", "callback_query"],
    })
    show_webhook(token)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("identify")
    commands.add_parser("status")
    commands.add_parser("register").add_argument("https_base")
    args = parser.parse_args()
    token = getpass("Telegram bot token: ")
    if not re.fullmatch(r"[0-9]+:[A-Za-z0-9_-]+", token):
        parser.exit(1, "Enter a valid BotFather token.\n")
    if args.command == "identify":
        identify(token)
    elif args.command == "register":
        register(token, args.https_base)
    else:
        show_webhook(token)


if __name__ == "__main__":
    main()
