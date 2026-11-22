# Local setup details

Start with the [quickstart](../README.md#run-clinicos-on-your-device). Use a fresh demo Supabase project, its own n8n volume, and a separate Telegram bot from BotFather.

## Database and demo accounts

1. From the Supabase dashboard, open **Connect** and copy the PostgreSQL connection URI. Use a direct connection from an IPv6-capable network or the session pooler from IPv4. Replace the password placeholder with your database password, percent-encoding reserved characters in the URI. Open a terminal at the repo root to apply the schema and set the six runtime passwords.

   **PowerShell**

   ```powershell
   $env:CLINICOS_DB_URL = Read-Host "Supabase PostgreSQL URI" -MaskInput
   npx --yes supabase@2 db push --db-url $env:CLINICOS_DB_URL
   psql $env:CLINICOS_DB_URL -f deploy/set-role-passwords.psql
   ```

   **Bash**

   ```bash
   read -rsp 'Supabase PostgreSQL URI: ' CLINICOS_DB_URL
   printf '\n'
   npx --yes supabase@2 db push --db-url "$CLINICOS_DB_URL"
   psql "$CLINICOS_DB_URL" -f deploy/set-role-passwords.psql
   ```

2. In **Integrations → Data API**, enable the API and add `clinic` to the exposed schemas alongside the defaults. ClinicOS uses that schema for its billing RPCs. Keep the `visit-files` Storage bucket private. The migration creates it with a 5 MiB limit for PDF, PNG, and JPEG.
3. In **Authentication → Users**, create and confirm three separate email/password users for the demo admin, doctor, and P5 billing login. Copy each user's UUID. The billing account signs in from n8n and the other two sign in to Care Board.
4. Run `python -B deploy/telegram-webhook.py identify`. Follow the prompt to send the one-time `/start` command in a private chat to your new bot. Copy the two numeric IDs printed by the script.
5. Run the fictional seed and paste the three Auth UUIDs and the two Telegram IDs when prompted. It maps the accounts, adds a doctor with 30-minute slots from 09:00 to 12:00 Cairo time, and creates the demo price list.

   ```powershell
   psql $env:CLINICOS_DB_URL -f supabase/seed.sql
   ```

   ```bash
   psql "$CLINICOS_DB_URL" -f supabase/seed.sql
   ```

   Close the terminal or unset `CLINICOS_DB_URL` after setup.

## n8n credentials

Create the credentials under **Credentials** in the n8n editor. Use the names in the [config template](../deploy/workflow-config.example.json), or enter your chosen names and the saved credential IDs in the config. The IDs are specific to your n8n instance. Open each saved credential from the Credentials page and copy the ID from its URL.

For the six **Postgres** credentials, use the direct or session-pooled host and port from **Connect**, database `postgres`, SSL **Require**, and the password set by the script. With the session pooler, enter `ROLE.PROJECT_REF` in the **User** field. With the direct endpoint, enter the role name by itself.

| Template key | Postgres role | Used by |
| --- | --- | --- |
| `p1` | `clinicos_p1_n8n` | Telegram intake, replies, and sync queues |
| `identity` | `clinicos_identity_sync_n8n` | Patient and staff sync writes |
| `listener` | `clinicos_listener_n8n` | Booking, cancellation, and rescheduling listeners |
| `scheduling` | `clinicos_scheduling_n8n` | Wait-list matching, expiry, and responses |
| `notifications` | `clinicos_notifications_n8n` | Notification jobs and file delivery |
| `invoices` | `clinicos_invoice_n8n` | Invoice and appointment lifecycle jobs |

| Template key | n8n type | Configuration |
| --- | --- | --- |
| `records`, `storage` | Supabase API | Set **Host** to your project origin and **Secret Key** to the server-side service-role key. Use the legacy `service_role` JWT key for these built-in n8n nodes. |
| `schedulingRpc`, `sessionRpc` | Simplified Custom Auth | Use the service-role and publishable templates below. |
| `billingLogin` | Simplified Custom Auth | Use the billing sign-in template below with the publishable key and the P5 Auth user's email and password. |
| `telegram`, `telegramSecret` | Telegram API, Header Auth | Set the bot's **Access Token**. For Header Auth, set **Name** to `X-Telegram-Bot-Api-Secret-Token` and **Value** to a random value using letters, digits, underscores, or hyphens. |
| `formLogin` | Basic Auth | Choose a separate username and password for the two local n8n billing forms. |

In Simplified Custom Auth, put this JSON in **Template** for an API-key-only credential.

```json
{"headers":{"apikey":"{{api_key}}"}}
```

Use the publishable key in that template for `sessionRpc`. For `schedulingRpc`, use the legacy `service_role` key with both headers.

```json
{"headers":{"apikey":"{{api_key}}","Authorization":"Bearer {{api_key}}"}}
```

For the billing sign-in credential, use this template.

```json
{"headers":{"apikey":"{{api_key}}"},"body":{"email":"{{email}}","password":"{{password}}"}}
```

In **Placeholders**, describe each included placeholder. For example, the API-key-only credential uses the following JSON.

```json
[{"name":"api_key","title":"Supabase API key","type":"password"}]
```

Use the same format for `email` and `password` in the billing credential. Put the actual values in **Placeholder Values** as a JSON object keyed by those names. Keep the secrets in n8n credentials.

Copy the config template to `.local/workflow-config.json` and fill in `supabaseUrl` plus each credential ID. Keep `billingActorId` as seeded and use `http://ollama:11434` when using the Compose profile. The workflow configuration contains credential references only.

**PowerShell**

```powershell
New-Item -ItemType Directory -Force .local | Out-Null
Copy-Item deploy/workflow-config.example.json .local/workflow-config.json
# Edit .local/workflow-config.json, then run:
python -B deploy/configure-workflow.py .local/workflow-config.json .local/clinicos-import.json
```

**Bash**

```bash
mkdir -p .local
cp deploy/workflow-config.example.json .local/workflow-config.json
# Edit .local/workflow-config.json, then run:
python3 -B deploy/configure-workflow.py .local/workflow-config.json .local/clinicos-import.json
```

## Publish and register the bot

1. In a separate terminal, run `cloudflared tunnel --url http://127.0.0.1:8095` and copy the generated HTTPS origin. The tunnel ends when you close that process. Caddy forwards only the Telegram callback to n8n.
2. Copy [`.env.example`](../.env.example) to `.env`, set `CLINICOS_WEBHOOK_URL` to the generated origin with a trailing slash, and run `docker compose up -d`. If you already use port 8081, set `CLINICOS_N8N_PORT` in the Compose `.env` and the terminal that launches Care Board.
3. In n8n, open **ClinicOS — Patient to Payment** and choose **Publish**. Wait until the editor says **Published**. The schedules and PostgreSQL listeners start at publication.
4. Run `python -B deploy/telegram-webhook.py register https://YOUR_TUNNEL.trycloudflare.com`. Enter the bot token and the same webhook secret used in n8n when prompted. Verify the script prints an HTTPS callback ending in `/webhook/clinicos-p1-telegram`.
5. Open a private chat with the bot and send `/start`. Continue with the [fictional demo](../README.md#fictional-demo). If the tunnel hostname changes, update `.env`, run `docker compose up -d`, then register the new callback.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Care Board shows a setup error | Set the Supabase project origin and `sb_publishable_…` key in the same terminal as the Python server. |
| Staff sign-in returns Forbidden | Run the seed with the confirmed Auth UUIDs. Verify the doctor matches the doctor in schedules. |
| The board opens, but actions return 404 or 502 | Publish the workflow and check the n8n port used by Care Board. |
| Telegram reports 401, 403, or 404 | Check that the registered URL uses the current HTTPS tunnel, the secret exactly matches Header Auth, and the workflow is published. |
| The booking request stays pending, or a summary never appears | Check the listener's Postgres role and session-mode connection for bookings. For summaries, verify the `summary` profile, model download, and private Ollama URL. |

Stop the local services with `docker compose --profile summary down` when the demo is finished. This keeps the project volumes.
