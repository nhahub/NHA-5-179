\set ON_ERROR_STOP on
\if :{?admin_auth_id}
\else
  \prompt 'Confirmed demo admin Auth user UUID: ' admin_auth_id
\endif
\if :{?doctor_auth_id}
\else
  \prompt 'Confirmed demo doctor Auth user UUID: ' doctor_auth_id
\endif
\if :{?billing_auth_id}
\else
  \prompt 'Confirmed P5 billing Auth user UUID: ' billing_auth_id
\endif
\if :{?bot_id}
\else
  \prompt 'Numeric demo Telegram bot ID: ' bot_id
\endif
\if :{?owner_id}
\else
  \prompt 'Numeric Telegram user ID of the demo bot owner: ' owner_id
\endif

BEGIN;

CREATE TEMP TABLE demo_setup (
  admin_auth_id uuid NOT NULL,
  doctor_auth_id uuid NOT NULL,
  billing_auth_id uuid NOT NULL,
  bot_id bigint NOT NULL CHECK (bot_id > 0),
  owner_id bigint NOT NULL CHECK (owner_id > 0)
) ON COMMIT DROP;

INSERT INTO demo_setup VALUES (
  :'admin_auth_id', :'doctor_auth_id', :'billing_auth_id', :'bot_id', :'owner_id'
);

DO $$
DECLARE
  config demo_setup%ROWTYPE;
  owner_sync p1_telegram.staff_sync_queue%ROWTYPE;
BEGIN
  SELECT * INTO STRICT config FROM demo_setup;

  IF (SELECT count(*) FROM auth.users
      WHERE id IN (config.admin_auth_id, config.doctor_auth_id, config.billing_auth_id)
        AND email_confirmed_at IS NOT NULL
        AND (banned_until IS NULL OR banned_until < now())) <> 3 THEN
    RAISE EXCEPTION 'Create three distinct confirmed demo Auth accounts first';
  END IF;

  INSERT INTO p1_telegram.sync_scope (bot_id, test_doctor_id)
  VALUES (config.bot_id, config.doctor_auth_id)
  ON CONFLICT (singleton) DO NOTHING;

  IF NOT EXISTS (
    SELECT 1 FROM p1_telegram.sync_scope
    WHERE bot_id = config.bot_id AND test_doctor_id = config.doctor_auth_id
  ) THEN
    RAISE EXCEPTION 'This database already uses a different demo bot or doctor';
  END IF;
  IF EXISTS (
    SELECT 1 FROM p1_telegram.staff_access_owner WHERE telegram_user_id <> config.owner_id
  ) THEN
    RAISE EXCEPTION 'This demo bot already has a different owner';
  END IF;

  INSERT INTO p1_telegram.staff (bot_id, telegram_user_id, role)
  VALUES (config.bot_id, config.owner_id, 'admin')
  ON CONFLICT DO NOTHING;

  INSERT INTO p1_telegram.staff_access_owner (bot_id, telegram_user_id)
  VALUES (config.bot_id, config.owner_id)
  ON CONFLICT DO NOTHING;

  SELECT * INTO STRICT owner_sync
  FROM p1_telegram.staff_sync_queue
  WHERE bot_id = config.bot_id AND telegram_user_id = config.owner_id
    AND role = 'admin' AND is_active;

  PERFORM clinicos_identity.apply_staff_sync(jsonb_build_array(jsonb_build_object(
    'id', owner_sync.staff_id,
    'role', owner_sync.role,
    'is_active', owner_sync.is_active,
    'created_at', owner_sync.created_at,
    'sync_revision', owner_sync.revision,
    'name', 'Demo Reception',
    'telegram_user_id', owner_sync.telegram_user_id
  )));

  INSERT INTO clinicos_identity.staff (id, role, name, sync_revision)
  VALUES (config.doctor_auth_id, 'doctor', 'Dr. Samir Adel', 1)
  ON CONFLICT (id) DO NOTHING;

  IF NOT EXISTS (
    SELECT 1 FROM clinicos_identity.staff
    WHERE id = config.doctor_auth_id AND role = 'doctor' AND is_active
  ) THEN
    RAISE EXCEPTION 'The doctor Auth ID conflicts with a staff identity';
  END IF;

  INSERT INTO clinicos_showcase.staff_auth (auth_user_id, staff_id)
  VALUES (config.admin_auth_id, owner_sync.staff_id), (config.doctor_auth_id, config.doctor_auth_id)
  ON CONFLICT DO NOTHING;

  IF (SELECT count(*) FROM clinicos_showcase.staff_auth
      WHERE (auth_user_id, staff_id) IN (
        (config.admin_auth_id, owner_sync.staff_id),
        (config.doctor_auth_id, config.doctor_auth_id)
      )) <> 2 THEN
    RAISE EXCEPTION 'An existing staff Auth mapping conflicts with the seed';
  END IF;

  INSERT INTO p5_private.demo_actors (login_role, actor_id, role, auth_user_id)
  VALUES ('p5_demo_runtime', '00000000-0000-4000-8000-000000000103', 'admin', config.billing_auth_id)
  ON CONFLICT DO NOTHING;

  IF NOT EXISTS (
    SELECT 1 FROM p5_private.demo_actors
    WHERE actor_id = '00000000-0000-4000-8000-000000000103'
      AND auth_user_id = config.billing_auth_id AND role = 'admin' AND active
  ) THEN
    RAISE EXCEPTION 'An existing P5 account mapping conflicts with the seed';
  END IF;

  INSERT INTO public.doctor_schedules (
    doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active
  )
  SELECT config.doctor_auth_id, day_number, TIME '09:00', TIME '12:00', 30, true
  FROM generate_series(0, 6) AS day_number
  WHERE NOT EXISTS (
    SELECT 1 FROM public.doctor_schedules
    WHERE doctor_id = config.doctor_auth_id AND day_of_week = day_number
  );
END $$;

INSERT INTO p1_telegram.account_options (singleton, phone_edits_enabled)
VALUES (true, false) ON CONFLICT DO NOTHING;

INSERT INTO clinicos_showcase.settings (id) VALUES (true) ON CONFLICT DO NOTHING;

INSERT INTO clinic.services (service_code, name, price, active)
VALUES ('CONSULT-GENERAL', 'General consultation', 350, true),
       ('CONSULT-FOLLOWUP', 'Follow-up consultation', 200, true),
       ('LAB-CBC', 'Complete blood count', 150, true),
       ('ECG', 'Electrocardiogram', 300, true),
       ('ULTRASOUND', 'Ultrasound examination', 550, true)
ON CONFLICT (service_code) DO NOTHING;

COMMIT;
