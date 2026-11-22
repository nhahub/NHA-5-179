"""Bind an unpublished ClinicOS workflow to credentials on a local n8n instance."""

import argparse
import json
from pathlib import Path
from urllib.parse import urlsplit
from uuid import UUID


ROOT = Path(__file__).resolve().parent.parent
EXPORT = ROOT / "workflows" / "clinicos-patient-to-payment.json"

CREDENTIAL_TYPES = {
    "p1": "postgres",
    "identity": "postgres",
    "listener": "postgres",
    "scheduling": "postgres",
    "notifications": "postgres",
    "invoices": "postgres",
    "records": "supabaseApi",
    "storage": "supabaseApi",
    "schedulingRpc": "httpTemplatedCustomAuth",
    "sessionRpc": "httpTemplatedCustomAuth",
    "billingLogin": "httpTemplatedCustomAuth",
    "telegram": "telegramApi",
    "telegramSecret": "httpHeaderAuth",
    "formLogin": "httpBasicAuth",
}


def credential_for(node):
    name = node["name"]
    kind = node["type"].removeprefix("n8n-nodes-base.")
    params = node["parameters"]
    if kind == "postgresTrigger":
        return "listener"
    if kind == "postgres":
        if name in {"P1-Telegram · Save Patient to Supabase", "P1-Telegram · Sync Staff to Supabase"}:
            return "identity"
        if name.startswith(("P1-Telegram ·", "P1-Error-Handler ·")):
            return "p1"
        if name.startswith("Waiting List "):
            return "scheduling"
        if name.startswith(("BOOK-4-", "P4-01-", "Staff files ·")):
            return "notifications"
        if name in {"Create or retry queued invoice", "Mark no-shows and queue current notifications"}:
            return "invoices"
        raise ValueError(f"No Postgres credential mapping for {name}")
    if kind == "supabase":
        return "records"
    if kind == "telegram":
        return "telegram"
    if kind == "formTrigger" and params.get("authentication") == "basicAuth":
        return "formLogin"
    if kind == "webhook" and params.get("authentication") == "headerAuth":
        return "telegramSecret"
    if kind == "httpRequest":
        auth = params.get("authentication", "none")
        if auth == "predefinedCredentialType" and params.get("nodeCredentialType") == "supabaseApi":
            return "storage"
        if auth == "genericCredentialType" and params.get("genericAuthType") == "httpTemplatedCustomAuth":
            url = params["url"]
            if "/auth/v1/token?" in url:
                return "billingLogin"
            if name.startswith(("Booking Request ·", "Cancellation Request ·", "Rescheduling Request ·")):
                return "schedulingRpc"
            if name == "Doctor Availability · Call book_appointment RPC":
                return "schedulingRpc"
            return "sessionRpc"
        if auth != "none":
            raise ValueError(f"No HTTP credential mapping for {name}")
    if node.get("credentials"):
        raise ValueError(f"No credential mapping for {name}")
    return None


def origin(value):
    url = urlsplit(value)
    if url.scheme not in {"https", "http"} or not url.hostname or url.username is not None or url.password is not None:
        raise ValueError("Use a Supabase or Ollama URL with no embedded credentials")
    if url.path not in {"", "/"} or url.query or url.fragment:
        raise ValueError("Use a base URL without a path, query, or fragment")
    return value.rstrip("/")


def configure(config):
    replacements = {
        "https://your-project.supabase.co": origin(config["supabaseUrl"]),
        "http://ollama.example.invalid:11434": origin(config["ollamaUrl"]),
        "REPLACE_WITH_P5_ACTOR_UUID": str(UUID(config["billingActorId"])),
    }
    raw = EXPORT.read_text(encoding="utf-8-sig")
    for placeholder, value in replacements.items():
        if placeholder not in raw:
            raise ValueError(f"Missing workflow placeholder {placeholder}")
        raw = raw.replace(placeholder, json.dumps(value, ensure_ascii=False)[1:-1])
    workflow = json.loads(raw)
    for node in workflow["nodes"]:
        key = credential_for(node)
        if key is None:
            continue
        ref = config["credentials"][key]
        if not all(isinstance(ref.get(field), str) and ref[field].strip() for field in ("id", "name")):
            raise ValueError(f"Enter the n8n credential ID and name for {key}")
        node["credentials"] = {CREDENTIAL_TYPES[key]: {"id": ref["id"], "name": ref["name"]}}
    workflow["active"] = False
    return workflow


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        config = json.loads(args.config.read_text(encoding="utf-8-sig"))
        if args.output.resolve() == EXPORT:
            raise ValueError("Save the configured workflow separately from the repository export")
        workflow = configure(config)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(workflow, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    except (OSError, KeyError, TypeError, ValueError) as error:
        parser.exit(1, f"Workflow setup: {error}\n")
    print(f"Import this draft into n8n: {args.output}")


if __name__ == "__main__":
    main()
