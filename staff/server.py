"""Loopback-only ClinicOS staff web application."""

import http.client
import json
import os
import re
import secrets
import time
from http.cookies import CookieError, SimpleCookie
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parent
HOST = "127.0.0.1"
PORT = 8094
HOSTS = {f"{HOST}:{PORT}", f"localhost:{PORT}"}
SUPABASE_URL = os.getenv("CLINICOS_SUPABASE_URL", "")
PUBLISHABLE_KEY = os.getenv("CLINICOS_PUBLISHABLE_KEY", "")
WEBHOOK_MODE = os.getenv("CLINICOS_WEBHOOK_MODE", "webhook")
N8N_PORT = os.getenv("CLINICOS_N8N_PORT", "8081")
COOKIE = "clinicos_staff"
SESSIONS = {}
SESSIONS_LOCK = Lock()
UPLOAD_LIMIT = 5 * 1024 * 1024 + 32 * 1024

ASSETS = {
    "/": (ROOT / "index.html", "text/html"),
    "/clinicos-mark.svg": (ROOT / "clinicos-mark.svg", "image/svg+xml"),
    "/board.css": (ROOT / "board.css", "text/css"),
    "/staff.css": (ROOT / "staff.css", "text/css"),
    "/staff.js": (ROOT / "staff.js", "text/javascript"),
}
RPCS = {
    "board": (None, "clinicos_staff_board"),
    "files": ("doctor", "clinicos_staff_visit_files"),
    "booking-change": ("admin", "clinicos_staff_booking_change"),
}
WORKFLOW_ACTIONS = {
    "availability": ("admin", "availability"),
    "check-in": ("admin", "visit-checkin"),
    "payment": ("admin", "clinicos-payment"),
    "catalog": ("admin", "clinicos-staff-catalog"),
    "daily-report": ("admin", "clinicos-daily-report"),
    "operations": ("admin", "clinicos-operations"),
    "start-visit": ("doctor", "visit-start"),
    "save-notes": ("doctor", "visit-revision-save"),
    "upload": ("doctor", "visit-file-upload"),
    "download": ("doctor", "visit-file-download"),
    "send": ("doctor", "visit-file-send"),
    "summary": ("doctor", "clinicos-summary-draft"),
    "review-summary": ("doctor", "clinicos-summary-review"),
    "follow-up": ("doctor", "clinicos-visit-followup"),
    "finalize": ("doctor", "visit-finalize"),
    "amend": ("doctor", "clinicos-visit-amend"),
}


def request(connection, path, body, headers):
    try:
        connection.request("POST", path, body, headers)
        response = connection.getresponse()
        data = response.read(UPLOAD_LIMIT + 1)
        if len(data) > UPLOAD_LIMIT:
            raise OSError("Oversize response")
        return response.status, response.getheader("Content-Type", ""), data
    finally:
        connection.close()


def db(path, payload, token=None):
    headers = {"Content-Type": "application/json", "apikey": PUBLISHABLE_KEY}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    connection = (http.client.HTTPSConnection if SUPABASE_URL.startswith("https://") else http.client.HTTPConnection)(
        urlsplit(SUPABASE_URL).netloc, timeout=15
    )
    return request(connection, path, json.dumps(payload).encode(), headers)


def n8n(path, body, token, content_type):
    connection = http.client.HTTPConnection(HOST, int(N8N_PORT), timeout=95)
    return request(connection, f"/{WEBHOOK_MODE}/{path}", body, {
        "Content-Type": content_type, "Authorization": f"Bearer {token}",
    })


def parse_json(data):
    try:
        parsed = json.loads(data)
        return parsed if isinstance(parsed, dict) else {}
    except (UnicodeError, ValueError):
        return {}


class StaffHandler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass  # Login, clinical records, and Telegram routing stay out of web logs.

    def respond(self, status, data, content_type="application/json", cookie=None):
        if not isinstance(data, bytes):
            data = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy",
                         "default-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'")
        if cookie is not None:
            self.send_header("Set-Cookie", cookie)
        self.end_headers()
        self.wfile.write(data)

    def error(self, status, code):
        self.respond(status, {"ok": False, "code": code})

    def trusted_host(self):
        return self.headers.get("Host") in HOSTS

    def session(self):
        try:
            cookie = SimpleCookie(self.headers.get("Cookie", "")).get(COOKIE)
        except CookieError:
            return None, None
        session_id = cookie.value if cookie else None
        with SESSIONS_LOCK:
            for key, session in list(SESSIONS.items()):
                if time.monotonic() >= session["expires"]:
                    del SESSIONS[key]
            return session_id, SESSIONS.get(session_id)

    def do_GET(self):
        if not self.trusted_host():
            return self.error(403, "FORBIDDEN")
        if self.path == "/api/session":
            _, session = self.session()
            return self.respond(200, {"role": session["role"] if session else None})
        asset = ASSETS.get(self.path)
        if not asset:
            return self.error(404, "NOT_FOUND")
        self.respond(200, asset[0].read_bytes(), asset[1] + "; charset=utf-8")

    def do_POST(self):
        if not self.trusted_host() or self.headers.get("Origin") != "http://" + self.headers.get("Host", ""):
            return self.error(403, "FORBIDDEN")
        try:
            self.handle_action()
        except (TimeoutError, OSError, http.client.HTTPException):
            self.error(502, "DELIVERY_UNCERTAIN" if self.path == "/api/send" else "UPSTREAM_UNAVAILABLE")

    def handle_action(self):
        key = self.path.removeprefix("/api/") if self.path.startswith("/api/") else ""
        route = RPCS.get(key) or WORKFLOW_ACTIONS.get(key)
        if not route and key not in ("login", "logout"):
            return self.error(404, "NOT_FOUND")
        sid, session = self.session()
        if key == "logout":
            with SESSIONS_LOCK:
                SESSIONS.pop(sid, None)
            return self.respond(200, {"ok": True}, cookie=f"{COOKIE}=; Path=/; Max-Age=0; HttpOnly; SameSite=Strict")
        if route and not session:
            return self.error(401, "SIGN_IN_REQUIRED")
        if route and route[0] and session["role"] != route[0]:
            return self.error(403, "FORBIDDEN")
        limit = UPLOAD_LIMIT if key == "upload" else 64 * 1024
        try:
            size = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.error(400, "VALIDATION_ERROR")
        if self.headers.get("Transfer-Encoding") or size < 1:
            return self.error(400, "VALIDATION_ERROR")
        if size > limit:
            return self.error(413, "FILE_TOO_LARGE")
        content_type = self.headers.get("Content-Type", "")
        body = self.rfile.read(size)
        if key == "upload":
            if not content_type.startswith("multipart/form-data; boundary="):
                return self.error(415, "FILE_TYPE")
        elif content_type.split(";")[0] != "application/json":
            return self.error(415, "VALIDATION_ERROR")
        if key == "login":
            return self.login(sid, parse_json(body))
        supplied = parse_json(body)
        if key != "upload" and not supplied and body.strip() != b"{}":
            return self.error(400, "VALIDATION_ERROR")
        if key in RPCS:
            status, kind, data = db("/rest/v1/rpc/" + route[1], supplied, session["token"])
        else:
            status, kind, data = n8n(route[1], body, session["token"], content_type)
        if key == "download" and 200 <= status < 300 and "json" not in kind:
            return self.respond(200, data, "application/octet-stream")
        result = parse_json(data)
        message = result.get("message")
        if key in WORKFLOW_ACTIONS and status == 404 and isinstance(message, str) and "not registered" in message:
            return self.error(503, "WORKFLOW_NOT_AVAILABLE")
        if status >= 500 or not result:
            return self.error(502, "DELIVERY_UNCERTAIN" if key == "send" else "UPSTREAM_UNAVAILABLE")
        code = result.get("code") or result.get("error")
        if status >= 400 or result.get("ok") is False or result.get("success") is False:
            if not isinstance(code, str) or not re.fullmatch(r"[a-zA-Z0-9_]{1,80}", code):
                code = "ACTION_FAILED"
            return self.error(status if status >= 400 else 403 if code == "FORBIDDEN" else 409, code)
        self.respond(status, result)

    def login(self, old_sid, data):
        email, password = data.get("email"), data.get("password")
        if not isinstance(email, str) or not isinstance(password, str) or not email.strip() or not password or len(email) > 254 or len(password) > 1024:
            return self.error(400, "VALIDATION_ERROR")
        status, _, raw = db("/auth/v1/token?grant_type=password", {"email": email.strip(), "password": password})
        session = parse_json(raw)
        token = session.get("access_token")
        if status >= 500 or status == 429:
            return self.error(502, "UPSTREAM_UNAVAILABLE")
        if status != 200 or not isinstance(token, str):
            return self.error(401, "INVALID_LOGIN")
        status, _, raw = db("/rest/v1/rpc/clinicos_showcase_actor", {}, token)
        role = parse_json(raw).get("role")
        if status != 200 or role not in ("admin", "doctor"):
            return self.error(403, "FORBIDDEN")
        sid = secrets.token_urlsafe(32)
        lifetime = max(1, min(int(session.get("expires_in", 3600)) - 10, 3600))
        with SESSIONS_LOCK:
            SESSIONS.pop(old_sid, None)
            SESSIONS[sid] = {"role": role, "token": token, "expires": time.monotonic() + lifetime}
        return self.respond(200, {"role": role},
                            cookie=f"{COOKIE}={sid}; Path=/; Max-Age={lifetime}; HttpOnly; SameSite=Strict")


if __name__ == "__main__":
    if WEBHOOK_MODE not in ("webhook", "webhook-test"):
        raise SystemExit("Set CLINICOS_WEBHOOK_MODE to webhook or webhook-test.")
    try:
        url = urlsplit(SUPABASE_URL)
        url.port
    except ValueError:
        raise SystemExit("Set CLINICOS_SUPABASE_URL to a valid Supabase project origin.") from None
    local_http = url.scheme == "http" and url.hostname in {"localhost", "127.0.0.1"}
    if (
        not url.hostname
        or (url.scheme != "https" and not local_http)
        or url.username is not None
        or url.password is not None
        or url.path not in ("", "/")
        or url.query
        or url.fragment
    ):
        raise SystemExit("Set CLINICOS_SUPABASE_URL to an HTTPS origin or a local Supabase HTTP origin.")
    if not PUBLISHABLE_KEY.startswith("sb_publishable_"):
        raise SystemExit("Set CLINICOS_PUBLISHABLE_KEY to the Supabase publishable key.")
    if not N8N_PORT.isascii() or not N8N_PORT.isdecimal() or not 1 <= int(N8N_PORT) <= 65535:
        raise SystemExit("Set CLINICOS_N8N_PORT to a port from 1 through 65535.")
    print(f"ClinicOS staff website: http://{HOST}:{PORT}", flush=True)
    ThreadingHTTPServer((HOST, PORT), StaffHandler).serve_forever()
