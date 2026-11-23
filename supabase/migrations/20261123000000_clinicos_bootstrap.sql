-- ClinicOS schema for an empty Supabase project.
-- Reconstructed from the team's schema and migration definitions. Seed and credentials are supplied per install.

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

SET search_path TO public, extensions, pg_catalog;

CREATE ROLE clinicos_identity_sync NOLOGIN INHERIT;

CREATE ROLE clinicos_identity_sync_n8n LOGIN INHERIT;

CREATE ROLE clinicos_invoice_n8n LOGIN INHERIT;

CREATE ROLE clinicos_listener_n8n LOGIN INHERIT;

CREATE ROLE clinicos_notifications_n8n LOGIN INHERIT;

CREATE ROLE clinicos_p1 NOLOGIN INHERIT;

CREATE ROLE clinicos_p1_n8n LOGIN INHERIT;

CREATE ROLE clinicos_p1_n8n_sync NOLOGIN INHERIT;

CREATE ROLE clinicos_p1_patient_writer NOLOGIN INHERIT;

CREATE ROLE clinicos_p1_reception NOLOGIN INHERIT;

CREATE ROLE clinicos_p1_scheduling NOLOGIN INHERIT;

CREATE ROLE clinicos_p1_schema NOLOGIN INHERIT;

CREATE ROLE clinicos_scheduling_n8n LOGIN INHERIT;

CREATE ROLE clinicos_showcase_listener NOLOGIN INHERIT;

CREATE ROLE clinicos_showcase_notifications NOLOGIN INHERIT;

CREATE ROLE clinicos_showcase_scheduling NOLOGIN INHERIT;

CREATE ROLE clinicos_showcase_worker NOLOGIN INHERIT;

CREATE ROLE p5_demo_runtime NOLOGIN NOINHERIT;

CREATE ROLE p5_entry_owner NOLOGIN NOINHERIT;

CREATE ROLE clinic_runtime NOLOGIN;

CREATE ROLE p4_confirmation_worker NOLOGIN;

CREATE ROLE p4_demo_runner NOLOGIN;

GRANT clinicos_identity_sync TO clinicos_identity_sync_n8n;

GRANT clinicos_identity_sync TO postgres;

GRANT clinicos_identity_sync_n8n TO postgres;

GRANT clinicos_invoice_n8n TO postgres;

GRANT clinicos_listener_n8n TO postgres;

GRANT clinicos_notifications_n8n TO postgres;

GRANT clinicos_p1 TO clinicos_p1_n8n;

GRANT clinicos_p1 TO postgres;

GRANT clinicos_p1_n8n TO postgres;

GRANT clinicos_p1_n8n_sync TO postgres;

GRANT clinicos_p1_patient_writer TO postgres;

GRANT clinicos_p1_reception TO postgres;

GRANT clinicos_p1_scheduling TO postgres;

GRANT clinicos_p1_schema TO postgres;

GRANT clinicos_scheduling_n8n TO postgres;

GRANT clinicos_showcase_listener TO clinicos_listener_n8n;

GRANT clinicos_showcase_listener TO postgres;

GRANT clinicos_showcase_notifications TO clinicos_notifications_n8n;

GRANT clinicos_showcase_notifications TO postgres;

GRANT clinicos_showcase_scheduling TO clinicos_scheduling_n8n;

GRANT clinicos_showcase_scheduling TO postgres;

GRANT clinicos_showcase_worker TO clinicos_invoice_n8n;

GRANT clinicos_showcase_worker TO postgres;

GRANT p5_demo_runtime TO authenticator;

GRANT p5_demo_runtime TO postgres;

GRANT p5_entry_owner TO postgres;

CREATE SCHEMA clinic;

CREATE SCHEMA clinicos_identity;

CREATE SCHEMA clinicos_showcase;

CREATE SCHEMA clinicos_staff_private;

CREATE SCHEMA p1_telegram;
GRANT USAGE, CREATE ON SCHEMA p1_telegram TO clinicos_p1_schema;

CREATE SCHEMA p4_demo;

CREATE SCHEMA p5_private;
GRANT USAGE, CREATE ON SCHEMA p5_private TO p5_entry_owner;

CREATE TYPE public.appointment_status AS ENUM ('booked', 'checked_in', 'completed', 'cancelled', 'no_show');

CREATE TYPE public.booking_request_status AS ENUM ('pending', 'processing', 'confirmed', 'failed', 'cancelled');

CREATE TYPE public.cancellation_request_status AS ENUM ('pending', 'processing', 'confirmed', 'failed', 'cancelled');

CREATE TYPE public.rescheduling_request_status AS ENUM ('pending', 'processing', 'confirmed', 'failed', 'cancelled');

CREATE TYPE public.waiting_offer_status AS ENUM ('pending', 'accepted', 'rejected', 'expired', 'booked', 'failed');

CREATE TYPE public.waiting_status AS ENUM ('waiting', 'offered', 'fulfilled', 'expired', 'cancelled');

-- Tables and sequences

CREATE TABLE public.appointments (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  appointment_date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  status public.appointment_status DEFAULT 'booked'::public.appointment_status,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now());

CREATE TABLE public.available_slot_events (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  source_appointment_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  appointment_date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  event_type text NOT NULL,
  event_key text NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE public.booking_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  appointment_date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  status public.booking_request_status DEFAULT 'pending'::public.booking_request_status NOT NULL,
  appointment_id uuid,
  error_message text,
  processed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  idempotency_key text,
  waiting_list_offer_id uuid);

CREATE TABLE public.cancellation_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  appointment_id uuid NOT NULL,
  reason text,
  status public.cancellation_request_status DEFAULT 'pending'::public.cancellation_request_status NOT NULL,
  error_message text,
  processed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE public.doctor_schedules (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  doctor_id uuid NOT NULL,
  day_of_week integer NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  slot_duration_minutes integer DEFAULT 30,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now());

CREATE TABLE public.notification_outbox (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  offer_id uuid NOT NULL,
  event_type text DEFAULT 'waiting_list_offer'::text NOT NULL,
  payload jsonb NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  sent_at timestamp with time zone,
  error_message text);

CREATE TABLE public.performed_services (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  visit_id uuid NOT NULL,
  revision_id uuid NOT NULL,
  service_code text NOT NULL,
  quantity integer DEFAULT 1 NOT NULL,
  finalized_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE public.rescheduling_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  appointment_id uuid NOT NULL,
  new_appointment_date date NOT NULL,
  new_start_time time without time zone NOT NULL,
  new_end_time time without time zone NOT NULL,
  reason text,
  status public.rescheduling_request_status DEFAULT 'pending'::public.rescheduling_request_status NOT NULL,
  error_message text,
  processed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE public.visit_attachments (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  visit_id uuid NOT NULL,
  revision_id uuid NOT NULL,
  storage_path text NOT NULL,
  mime_type text NOT NULL,
  checksum text NOT NULL,
  uploaded_by uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  file_name text);

CREATE TABLE public.visit_revisions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  visit_id uuid NOT NULL,
  revision_no integer NOT NULL,
  author_id uuid NOT NULL,
  content_ref text NOT NULL,
  supersedes_revision_id uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  content text);

CREATE TABLE public.visits (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  appointment_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  assigned_doctor_id uuid NOT NULL,
  status text DEFAULT 'open'::text NOT NULL,
  started_at timestamp with time zone,
  finalized_at timestamp with time zone,
  current_revision_id uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE public.wait_list (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  preferred_date date NOT NULL,
  status public.waiting_status DEFAULT 'waiting'::public.waiting_status,
  offer_expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  priority integer DEFAULT 0 NOT NULL,
  preferred_start_time time without time zone,
  preferred_end_time time without time zone,
  notes text,
  updated_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE public.waiting_list (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  preferred_date date NOT NULL,
  status public.waiting_status DEFAULT 'waiting'::public.waiting_status,
  offer_expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now());

CREATE TABLE public.waiting_list_offers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  slot_event_id uuid NOT NULL,
  waiting_list_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  appointment_date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  status public.waiting_offer_status DEFAULT 'pending'::public.waiting_offer_status NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  responded_at timestamp with time zone,
  booking_request_id uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinic.invoice_lines (
  invoice_id uuid NOT NULL,
  performed_service_id uuid NOT NULL,
  revision_id uuid NOT NULL,
  service_code text NOT NULL,
  name text NOT NULL,
  quantity integer NOT NULL,
  unit_price numeric NOT NULL,
  source_finalized_at timestamp with time zone NOT NULL);

CREATE TABLE clinic.invoices (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  visit_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  actor_id uuid NOT NULL,
  request_id text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  response jsonb NOT NULL);

CREATE TABLE clinic.p4_demo_faq (
  faq_id text NOT NULL,
  question text NOT NULL,
  answer text NOT NULL,
  approved_for_demo boolean DEFAULT false NOT NULL);

CREATE TABLE clinic.p4_faq_pending_handoff (
  chat_id bigint NOT NULL,
  message_id bigint NOT NULL,
  question text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinic.p4_notification_outbox (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  event_id text NOT NULL,
  event_version integer NOT NULL,
  recipient_ref text NOT NULL,
  template_key text NOT NULL,
  due_at timestamp with time zone NOT NULL,
  state text DEFAULT 'pending'::text NOT NULL,
  claimed_at timestamp with time zone,
  resolved_at timestamp with time zone,
  dispatch_started_at timestamp with time zone);

CREATE TABLE clinic.p4_waiting_offer_claims (
  offer_id uuid NOT NULL,
  decision text NOT NULL,
  claimed_at timestamp with time zone DEFAULT statement_timestamp() NOT NULL);

CREATE TABLE clinic.payments (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  invoice_id uuid NOT NULL,
  actor_id uuid NOT NULL,
  request_id text NOT NULL,
  amount numeric NOT NULL,
  method text NOT NULL,
  reference text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  response jsonb NOT NULL);

CREATE TABLE clinic.services (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  service_code text NOT NULL,
  name text NOT NULL,
  price numeric NOT NULL,
  active boolean DEFAULT true NOT NULL);

CREATE TABLE clinic.setup_probe (
  marker text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinicos_identity.patients (
  id uuid NOT NULL,
  full_name text NOT NULL,
  date_of_birth date NOT NULL,
  phone_e164 text,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  phone_revision bigint DEFAULT 0 NOT NULL,
  telegram_chat_id bigint,
  telegram_user_id bigint,
  telegram_linked_at timestamp with time zone,
  profile_sync_revision bigint DEFAULT 0 NOT NULL);

CREATE TABLE clinicos_identity.staff (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  role text NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  sync_revision bigint DEFAULT 0 NOT NULL,
  name text,
  telegram_user_id bigint);

CREATE TABLE clinicos_showcase.feedback (
  visit_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  score smallint NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinicos_showcase.followups (
  visit_id uuid NOT NULL,
  revision_id uuid NOT NULL,
  due_date date NOT NULL,
  version integer DEFAULT 1 NOT NULL,
  appointment_id uuid);

CREATE TABLE clinicos_showcase.handoffs (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  patient_id uuid NOT NULL,
  kind text NOT NULL,
  source_key text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  resolved_at timestamp with time zone,
  assigned_to uuid);

CREATE TABLE clinicos_showcase.invoice_queue (
  visit_id uuid NOT NULL,
  actor_id uuid NOT NULL,
  queued_at timestamp with time zone DEFAULT now() NOT NULL,
  invoice_id uuid,
  attempts integer DEFAULT 0 NOT NULL,
  error_code text,
  next_attempt_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinicos_showcase.patient_auth (
  auth_user_id uuid NOT NULL,
  patient_id uuid NOT NULL);

CREATE TABLE clinicos_showcase.settings (
  id boolean DEFAULT true NOT NULL,
  enabled_after timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinicos_showcase.staff_auth (
  auth_user_id uuid NOT NULL,
  staff_id uuid NOT NULL);

CREATE TABLE clinicos_showcase.summary_drafts (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  visit_id uuid NOT NULL,
  revision_id uuid NOT NULL,
  author_id uuid NOT NULL,
  model text NOT NULL,
  text text NOT NULL,
  state text DEFAULT 'draft'::text NOT NULL,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE clinicos_staff_private.file_delivery (
  attachment_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  claim uuid NOT NULL,
  claimed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
  state text NOT NULL,
  message_id bigint,
  resolved_at timestamp with time zone);

CREATE TABLE p1_telegram.account_confirmations (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  patient_id uuid NOT NULL,
  action text NOT NULL,
  expires_at timestamp with time zone NOT NULL);

CREATE TABLE p1_telegram.account_options (
  singleton boolean NOT NULL,
  phone_edits_enabled boolean DEFAULT false NOT NULL);

CREATE TABLE p1_telegram.deletion_requests (
  patient_id uuid NOT NULL,
  requested_at timestamp with time zone DEFAULT now() NOT NULL,
  reviewed_at timestamp with time zone,
  review_reference uuid DEFAULT gen_random_uuid() NOT NULL,
  reviewed_by_bot_id bigint,
  reviewed_by_telegram_id bigint,
  patient_reason text,
  review_outcome text,
  review_reason text);

CREATE TABLE p1_telegram.deletion_review_history (
  review_reference uuid NOT NULL,
  reviewed_at timestamp with time zone NOT NULL,
  reviewer_bot_id bigint,
  reviewer_user_id bigint,
  outcome text NOT NULL,
  reason text);

CREATE TABLE p1_telegram.duplicate_dispositions (
  review_reference uuid NOT NULL,
  recorded_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
  reviewer_bot_id bigint NOT NULL,
  reviewer_user_id bigint NOT NULL,
  existing_patient_id uuid,
  matched_patients uuid[] NOT NULL);

CREATE TABLE p1_telegram.inbox (
  bot_id bigint NOT NULL,
  update_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  received_at timestamp with time zone DEFAULT now() NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  payload jsonb NOT NULL,
  claim_token uuid,
  lease_until timestamp with time zone,
  replied_at timestamp with time zone,
  reply_message_id bigint,
  recovery_enabled boolean DEFAULT true,
  event_at timestamp with time zone);

CREATE TABLE p1_telegram.link_audit (
  bot_id bigint NOT NULL,
  update_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  action text NOT NULL,
  recorded_at timestamp with time zone DEFAULT now() NOT NULL);

CREATE TABLE p1_telegram.link_codes (
  bot_id bigint NOT NULL,
  code_hash bytea NOT NULL,
  patient_id uuid NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  closed_at timestamp with time zone,
  recipient_telegram_id bigint);

CREATE TABLE p1_telegram.patient_links (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  patient_id uuid NOT NULL,
  linked_at timestamp with time zone DEFAULT now(),
  profile_number bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  selected boolean DEFAULT true NOT NULL);

CREATE TABLE p1_telegram.patient_sync_queue (
  patient_id uuid NOT NULL,
  available_at timestamp with time zone DEFAULT now() NOT NULL,
  claim_token uuid,
  synced_at timestamp with time zone);

CREATE TABLE p1_telegram.patients (
  patient_id uuid DEFAULT gen_random_uuid() NOT NULL,
  full_name text NOT NULL,
  date_of_birth date NOT NULL,
  phone_e164 text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  phone_revision bigint DEFAULT 0 NOT NULL,
  profile_sync_revision bigint DEFAULT 1 NOT NULL);

CREATE TABLE p1_telegram.phone_edits (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  patient_id uuid NOT NULL,
  token uuid DEFAULT gen_random_uuid() NOT NULL,
  expires_at timestamp with time zone NOT NULL);

CREATE TABLE p1_telegram.registration_consent (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  notice_version text NOT NULL,
  decision boolean,
  decided_at timestamp with time zone);

CREATE TABLE p1_telegram.registration_drafts (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  step text NOT NULL,
  full_name text,
  date_of_birth date,
  phone_e164 text,
  review_reference uuid DEFAULT gen_random_uuid() NOT NULL);

CREATE TABLE p1_telegram.replies (
  bot_id bigint NOT NULL,
  update_id bigint NOT NULL,
  reply_text text NOT NULL,
  available_at timestamp with time zone DEFAULT now() NOT NULL,
  claim_token uuid,
  attempts integer DEFAULT 0 NOT NULL,
  sent_at timestamp with time zone,
  message_id bigint);

CREATE TABLE p1_telegram.staff (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  role text NOT NULL,
  active boolean DEFAULT true NOT NULL);

CREATE TABLE p1_telegram.staff_access_confirmation (
  bot_id bigint NOT NULL,
  owner_id bigint NOT NULL,
  target_id bigint NOT NULL,
  action text NOT NULL,
  expires_at timestamp with time zone NOT NULL);

CREATE TABLE p1_telegram.staff_access_owner (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL);

CREATE TABLE p1_telegram.staff_sync_queue (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  staff_id uuid DEFAULT gen_random_uuid() NOT NULL,
  role text NOT NULL,
  is_active boolean NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  revision bigint DEFAULT 1 NOT NULL,
  synced_revision bigint DEFAULT 0 NOT NULL,
  staff_name text,
  staff_name_seen_at timestamp with time zone);

CREATE TABLE p1_telegram.sync_scope (
  singleton boolean DEFAULT true NOT NULL,
  bot_id bigint NOT NULL,
  test_doctor_id uuid DEFAULT gen_random_uuid() NOT NULL);

CREATE TABLE p1_telegram.test_booking_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  appointment_date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  idempotency_key text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  appointment_id uuid);

CREATE TABLE p1_telegram.withdrawal_confirmations (
  bot_id bigint NOT NULL,
  telegram_user_id bigint NOT NULL,
  token uuid DEFAULT gen_random_uuid() NOT NULL,
  expires_at timestamp with time zone NOT NULL);

CREATE TABLE p1_telegram.workflow_errors (
  error_id uuid DEFAULT gen_random_uuid() NOT NULL,
  recorded_at timestamp with time zone DEFAULT now() NOT NULL,
  source text NOT NULL,
  error_code text DEFAULT 'E_INTERNAL'::text NOT NULL);

CREATE TABLE p4_demo.booking_confirmation (
  id uuid NOT NULL,
  appointment_at timestamp with time zone NOT NULL,
  booking_status text NOT NULL,
  delivery_status text DEFAULT 'pending'::text NOT NULL);

CREATE TABLE p4_demo.notification_recipient (
  recipient_ref text NOT NULL,
  chat_id text NOT NULL,
  eligible boolean DEFAULT true NOT NULL);

CREATE TABLE p5_private.demo_actors (
  login_role name NOT NULL,
  actor_id uuid NOT NULL,
  role text NOT NULL,
  active boolean DEFAULT true NOT NULL,
  auth_user_id uuid);

CREATE TABLE p5_private.requests (
  request_id text NOT NULL,
  actor_id uuid NOT NULL,
  action text NOT NULL,
  payload jsonb NOT NULL,
  before_state jsonb,
  result jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL);

-- Routines

SET check_function_bodies TO off;

CREATE OR REPLACE FUNCTION public.book_appointment(p_patient_id uuid, p_doctor_id uuid, p_date date, p_start_time time without time zone, p_end_time time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_appointment_id uuid;
    v_schedule RECORD;
BEGIN
    -- 1. Validate required inputs and time range.
    IF p_patient_id IS NULL
       OR p_doctor_id IS NULL
       OR p_date IS NULL
       OR p_start_time IS NULL
       OR p_end_time IS NULL
       OR p_start_time >= p_end_time THEN

        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid appointment details or time range.'
        );
    END IF;

    -- 2. Find an active schedule matching the requested date.
    SELECT
        start_time,
        end_time,
        slot_duration_minutes
    INTO v_schedule
    FROM public.doctor_schedules
    WHERE doctor_id = p_doctor_id
      AND day_of_week = EXTRACT(DOW FROM p_date)::integer
      AND is_active = true
      AND p_start_time >= start_time
      AND p_end_time <= end_time
      AND p_end_time - p_start_time =
          slot_duration_minutes * INTERVAL '1 minute'
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Requested time is outside the doctor schedule or has an invalid duration.'
        );
    END IF;

    -- 3. Require the appointment to align with the
    --    schedule's slot boundaries.
    IF MOD(
        EXTRACT(EPOCH FROM (p_start_time - v_schedule.start_time))::integer,
        v_schedule.slot_duration_minutes * 60
    ) <> 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Requested start time does not align with the doctor schedule.'
        );
    END IF;

    -- 4. Friendly overlap check.
    IF EXISTS (
        SELECT 1
        FROM public.appointments a
        WHERE a.doctor_id = p_doctor_id
          AND a.appointment_date = p_date
          AND a.status <> 'cancelled'
          AND p_start_time < a.end_time
          AND p_end_time > a.start_time
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Slot is no longer available. It overlaps an existing appointment.'
        );
    END IF;

    -- 5. Insert. The exclusion constraint protects against
    --    concurrent requests booking overlapping times.
    INSERT INTO public.appointments (
        patient_id,
        doctor_id,
        appointment_date,
        start_time,
        end_time,
        status
    )
    VALUES (
        p_patient_id,
        p_doctor_id,
        p_date,
        p_start_time,
        p_end_time,
        'booked'
    )
    RETURNING id INTO v_appointment_id;

    RETURN jsonb_build_object(
        'success', true,
        'appointment_id', v_appointment_id,
        'message', 'Appointment booked successfully.'
    );

EXCEPTION
    WHEN exclusion_violation OR unique_violation THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Slot is no longer available. Please choose another time.'
        );
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_appointment(p_appointment_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_id UUID;
    v_status public.appointment_status;
BEGIN
    UPDATE public.appointments
    SET
        status = 'cancelled',
        updated_at = now()
    WHERE id = p_appointment_id
      AND status = 'booked'
    RETURNING id INTO v_id;

    IF v_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true,
            'appointment_id', v_id,
            'message', 'Appointment cancelled successfully'
        );
    END IF;

    SELECT status
    INTO v_status
    FROM public.appointments
    WHERE id = p_appointment_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Appointment not found'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', false,
        'message', 'Appointment cannot be cancelled from status: '
            || COALESCE(v_status::text, 'NULL')
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.capture_released_appointment_slot()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_event_type TEXT;
    v_event_key TEXT;
BEGIN
    IF OLD.status IS DISTINCT FROM 'booked'::public.appointment_status THEN
        RETURN NEW;
    END IF;

    IF NEW.status = 'cancelled'::public.appointment_status THEN
        v_event_type := 'cancelled';

    ELSIF (
        OLD.appointment_date IS DISTINCT FROM NEW.appointment_date
        OR OLD.start_time IS DISTINCT FROM NEW.start_time
        OR OLD.end_time IS DISTINCT FROM NEW.end_time
    ) THEN
        v_event_type := 'rescheduled';

    ELSE
        RETURN NEW;
    END IF;

    -- Include the old slot and new appointment state to make
    -- the event idempotent.
    v_event_key :=
        OLD.id::TEXT || ':' ||
        OLD.appointment_date::TEXT || ':' ||
        OLD.start_time::TEXT || ':' ||
        OLD.end_time::TEXT || ':' ||
        NEW.status::TEXT || ':' ||
        NEW.appointment_date::TEXT || ':' ||
        NEW.start_time::TEXT || ':' ||
        NEW.end_time::TEXT || ':' ||
        NEW.updated_at::TEXT;

    INSERT INTO public.available_slot_events (
        source_appointment_id,
        doctor_id,
        appointment_date,
        start_time,
        end_time,
        event_type,
        event_key
    )
    VALUES (
        OLD.id,
        OLD.doctor_id,
        OLD.appointment_date,
        OLD.start_time,
        OLD.end_time,
        v_event_type,
        v_event_key
    )
    ON CONFLICT (event_key) DO NOTHING;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.claim_booking_request(p_request_id uuid)
 RETURNS SETOF public.booking_requests
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    UPDATE public.booking_requests
    SET status = 'processing'
    WHERE id = p_request_id
      AND status = 'pending'
    RETURNING *;
END;
$function$;

CREATE OR REPLACE FUNCTION public.claim_cancellation_request(p_request_id uuid)
 RETURNS SETOF public.cancellation_requests
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    UPDATE public.cancellation_requests
    SET status = 'processing'
    WHERE id = p_request_id
      AND status = 'pending'
    RETURNING *;
$function$;

CREATE OR REPLACE FUNCTION public.claim_rescheduling_request(p_request_id uuid)
 RETURNS SETOF public.rescheduling_requests
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    UPDATE public.rescheduling_requests
    SET status = 'processing'
    WHERE id = p_request_id
      AND status = 'pending'
    RETURNING *;
$function$;

CREATE OR REPLACE FUNCTION public.claim_waiting_list_entry(p_slot_event_id uuid, p_waiting_list_id uuid, p_expires_at timestamp with time zone)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_slot public.available_slot_events%ROWTYPE;
    v_claimed_id UUID;
BEGIN
    IF p_expires_at IS NULL OR p_expires_at <= now() THEN
        RETURN FALSE;
    END IF;

    -- Lock the slot so two executions cannot claim it simultaneously.
    SELECT *
    INTO v_slot
    FROM public.available_slot_events
    WHERE id = p_slot_event_id
      AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Temporarily reserve the slot.
    UPDATE public.available_slot_events
    SET status = 'processing',
        updated_at = now()
    WHERE id = v_slot.id;

    -- Reserve the selected entry in your renamed table.
    UPDATE public.wait_list w
    SET status = 'offered'::public.waiting_status,
        offer_expires_at = p_expires_at
    WHERE w.id = p_waiting_list_id
      AND w.status = 'waiting'::public.waiting_status
      AND w.doctor_id = v_slot.doctor_id
      AND w.preferred_date = v_slot.appointment_date
      AND (
          w.preferred_start_time IS NULL
          OR (
              v_slot.start_time >= w.preferred_start_time
              AND v_slot.end_time <= w.preferred_end_time
          )
      )
    RETURNING w.id INTO v_claimed_id;

    -- If the entry could not be claimed, release the slot.
    IF NOT FOUND THEN
        UPDATE public.available_slot_events
        SET status = 'pending',
            updated_at = now()
        WHERE id = v_slot.id;

        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_actor()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
 select coalesce((select jsonb_build_object('id',s.id,'role',s.role)
 from clinicos_showcase.staff_auth m join clinicos_identity.staff s on s.id=m.staff_id
 where m.auth_user_id=auth.uid() and s.is_active), '{}'::jsonb)
$function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_checkin(p_appointment uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare a public.appointments%rowtype; v public.visits%rowtype; reused boolean;
begin
 if coalesce(public.clinicos_showcase_actor()->>'role','') not in ('reception','admin') then
  return jsonb_build_object('ok',false,'status',403,'error','forbidden');
 end if;
 select * into a from public.appointments where id=p_appointment for update;
 if not found then return jsonb_build_object('ok',false,'status',404,'error','appointment_not_found'); end if;
 select * into v from public.visits where appointment_id=a.id;
 reused := found;
 if a.status not in ('booked','checked_in') and not (a.status='completed' and reused) then
  return jsonb_build_object('ok',false,'status',409,'error','invalid_appointment_state');
 end if;
 if not reused then
  insert into public.visits(appointment_id,patient_id,assigned_doctor_id,status)
  values(a.id,a.patient_id,a.doctor_id,'open') returning * into v;
 end if;
 update public.appointments set status='checked_in' where id=a.id and status='booked';
 return jsonb_build_object('ok',true,'status',case when reused then 200 else 201 end,'visit',to_jsonb(v),'reused',reused);
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_daily_report(p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb := public.clinicos_showcase_actor();
        report_date date := coalesce(p_date,(now() at time zone 'Africa/Cairo')::date);
        totals jsonb;
begin
  if coalesce(actor->>'role','') not in ('billing','admin') then
    return jsonb_build_object('ok',false,'code','FORBIDDEN');
  end if;
  with invoice_amounts as (
    select
      coalesce((select sum(l.quantity*l.unit_price) from clinic.invoice_lines l where l.invoice_id=i.id),0) billed,
      coalesce((select sum(p.amount) from clinic.payments p where p.invoice_id=i.id),0) collected
    from public.appointments a
    join public.visits v on v.appointment_id=a.id
    join clinic.invoices i on i.visit_id=v.id
    where a.appointment_date=report_date
  )
  select jsonb_build_object('billed',coalesce(sum(billed),0),'collected',coalesce(sum(collected),0),
    'outstanding',coalesce(sum(greatest(billed-collected,0)),0))
  into totals from invoice_amounts;

  return totals || jsonb_build_object('ok',true,'date',report_date,'currency','EGP',
    'appointments',(select count(*) from public.appointments where appointment_date=report_date),
    'no_shows',(select count(*) from public.appointments where appointment_date=report_date and status='no_show'),
    'pending_invoice_failures',(select count(*) from clinicos_showcase.invoice_queue q
      join public.visits v on v.id=q.visit_id
      join public.appointments a on a.id=v.appointment_id
      where a.appointment_date=report_date and q.invoice_id is null and q.error_code is not null));
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_finalize(p_visit uuid, p_services jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb := public.clinicos_showcase_actor(); v public.visits%rowtype; stamp timestamptz := statement_timestamp();
begin
 select * into v from public.visits where id=p_visit for update;
 if not found or coalesce(actor->>'role','') <> 'doctor' or v.assigned_doctor_id is distinct from (actor->>'id')::uuid then
  return jsonb_build_object('ok',false,'status',403,'error','forbidden');
 end if;
 if v.status='finalized' and exists(select 1 from clinicos_showcase.invoice_queue where visit_id=v.id) then
  return jsonb_build_object('ok',true,'status',200,'visit_id',v.id,'finalized_at',v.finalized_at,'invoice_queued',true);
 end if;
 if v.status <> 'open' or v.started_at is null or v.current_revision_id is null then
  return jsonb_build_object('ok',false,'status',409,'error','invalid_visit_state');
 end if;
 if jsonb_typeof(p_services) is distinct from 'array' then
  return jsonb_build_object('ok',false,'status',422,'error','invalid_services');
 end if;
 if jsonb_array_length(p_services) not between 1 and 50 or exists (
   select 1 from jsonb_array_elements(p_services) x
   where coalesce(btrim(x->>'service_code'),'') !~ '^[A-Za-z0-9_-]{2,40}$'
   or coalesce(x->>'quantity','') !~ '^([1-9]|[1-9][0-9]|100)$'
   or not exists(select 1 from clinic.services s where s.active and s.service_code=btrim(x->>'service_code'))
 ) then return jsonb_build_object('ok',false,'status',422,'error','invalid_services'); end if;
 perform 1 from public.appointments where id=v.appointment_id and status='checked_in' for update;
 if not found then return jsonb_build_object('ok',false,'status',409,'error','appointment_not_checked_in'); end if;
 insert into public.performed_services(visit_id,revision_id,service_code,quantity,finalized_at)
 select v.id,v.current_revision_id,btrim(x->>'service_code'),sum((x->>'quantity')::int),stamp
 from jsonb_array_elements(p_services) x group by btrim(x->>'service_code');
 update public.visits set status='finalized',finalized_at=stamp where id=v.id;
 update public.appointments set status='completed' where id=v.appointment_id;
 insert into clinicos_showcase.invoice_queue(visit_id,actor_id) values(v.id,v.assigned_doctor_id);
 return jsonb_build_object('ok',true,'status',200,'visit_id',v.id,'finalized_at',stamp,'invoice_queued',true);
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_operations(p_action text DEFAULT 'list'::text, p_handoff uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare a jsonb:=public.clinicos_showcase_actor(); r text:=coalesce(a->>'role',''); h clinicos_showcase.handoffs%rowtype;
begin
 if r not in ('admin','reception') then return jsonb_build_object('ok',false,'code','FORBIDDEN'); end if;
 if p_action in ('assign','resolve') then
  update clinicos_showcase.handoffs set assigned_to=(a->>'id')::uuid,
   resolved_at=case when p_action='resolve' then now() else null end
  where id=p_handoff and resolved_at is null and (assigned_to is null or assigned_to=(a->>'id')::uuid or r='admin')
  returning * into h;
  if not found then return jsonb_build_object('ok',false,'code','HANDOFF_UNAVAILABLE'); end if;
  return jsonb_build_object('ok',true,'handoff_id',h.id,'resolved_at',h.resolved_at);
 end if;
 if p_action is distinct from 'list' then return jsonb_build_object('ok',false,'code','VALIDATION_ERROR'); end if;
 return jsonb_build_object('ok',true,
  'handoffs',coalesce((select jsonb_agg(h) from (select id,patient_id,kind,created_at,assigned_to from clinicos_showcase.handoffs where resolved_at is null order by created_at limit 50) h),'[]'::jsonb),
  'invoice_failures',case when r='admin' then coalesce((select jsonb_agg(q) from (select visit_id,error_code,attempts,next_attempt_at from clinicos_showcase.invoice_queue where invoice_id is null and error_code is not null order by next_attempt_at limit 50) q),'[]'::jsonb) else '[]'::jsonb end,
  'workflow_failures',case when r='admin' then coalesce((select jsonb_agg(f) from (select error_id,source from p1_telegram.workflow_errors order by recorded_at desc limit 50) f),'[]'::jsonb) else '[]'::jsonb end);
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_patient()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
 select coalesce((select jsonb_build_object('id',p.id) from clinicos_showcase.patient_auth a
 join clinicos_identity.patients p on p.id=a.patient_id where a.auth_user_id=auth.uid() and p.is_active),'{}'::jsonb)
$function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_record_payment(p_request text, p_invoice uuid, p_amount text, p_method text, p_reference text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb:=public.clinicos_showcase_actor();
begin
 if coalesce(actor->>'role','') not in ('billing','admin') then return jsonb_build_object('ok',false,'code','FORBIDDEN'); end if;
 if length(p_request)>200 or length(p_method)>80 or length(p_reference)>200 then return jsonb_build_object('ok',false,'code','VALIDATION_ERROR'); end if;
 return clinic.record_payment(p_request,(actor->>'id')::uuid,p_invoice,p_amount,p_method,p_reference);
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_save_revision(p_visit uuid, p_content jsonb, p_amend boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb:=public.clinicos_showcase_actor(); v public.visits%rowtype; r public.visit_revisions%rowtype;
begin
 select * into v from public.visits where id=p_visit for update;
 if not found or coalesce(actor->>'role','')<>'doctor' or v.assigned_doctor_id is distinct from (actor->>'id')::uuid or v.started_at is null
 or (case when coalesce(p_amend,false) then v.status<>'finalized' else v.status<>'open' end) then
 return jsonb_build_object('ok',false,'status',403,'error','forbidden_or_invalid_state'); end if;
 if jsonb_typeof(p_content->'notes') is distinct from 'string' or length(btrim(p_content->>'notes'))=0 then return jsonb_build_object('ok',false,'status',422,'error','notes_required'); end if;
 select * into r from public.visit_revisions where visit_id=v.id order by revision_no desc limit 1;
 insert into public.visit_revisions(visit_id,revision_no,author_id,content_ref,content,supersedes_revision_id)
 values(v.id,coalesce(r.revision_no,0)+1,v.assigned_doctor_id,'inline',p_content::text,r.id) returning * into r;
 update public.visits set current_revision_id=r.id where id=v.id;
 return jsonb_build_object('ok',true,'status',201,'saved',true,'revision',to_jsonb(r));
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_set_followup(p_visit uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare a jsonb:=public.clinicos_showcase_actor(); v public.visits%rowtype;
begin
 select * into v from public.visits where id=p_visit for update;
 if not found or coalesce(a->>'role','')<>'doctor' or v.assigned_doctor_id is distinct from (a->>'id')::uuid then return jsonb_build_object('ok',false,'code','FORBIDDEN'); end if;
 if v.current_revision_id is null or p_date is null or p_date<(now() at time zone 'Africa/Cairo')::date then return jsonb_build_object('ok',false,'code','VALIDATION_ERROR'); end if;
 insert into clinicos_showcase.followups(visit_id,revision_id,due_date) values(v.id,v.current_revision_id,p_date)
 on conflict(visit_id) do update set revision_id=excluded.revision_id,due_date=excluded.due_date,version=followups.version+1
 where (followups.revision_id,followups.due_date) is distinct from (excluded.revision_id,excluded.due_date);
 return jsonb_build_object('ok',true,'visit_id',v.id,'due_date',p_date);
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_summary(p_visit uuid, p_action text, p_revision uuid DEFAULT NULL::uuid, p_draft uuid DEFAULT NULL::uuid, p_text text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb:=public.clinicos_showcase_actor(); v public.visits%rowtype; d clinicos_showcase.summary_drafts%rowtype; notes text;
begin
 select * into v from public.visits where id=p_visit for update;
 if not found or coalesce(actor->>'role','')<>'doctor' or v.assigned_doctor_id is distinct from (actor->>'id')::uuid then
  return jsonb_build_object('ok',false,'code','FORBIDDEN','status',403); end if;
 if v.current_revision_id is null then return jsonb_build_object('ok',false,'code','REVISION_REQUIRED','status',409); end if;
 if p_action='source' then
  select content::text into notes from public.visit_revisions where id=v.current_revision_id and visit_id=v.id;
  return jsonb_build_object('ok',true,'visit_id',v.id,'revision_id',v.current_revision_id,'notes',notes);
 elsif p_action='save' then
  if p_revision is distinct from v.current_revision_id then return jsonb_build_object('ok',false,'code','STALE_DRAFT','status',409); end if;
  if p_text is null or length(btrim(p_text)) not between 1 and 12000 then return jsonb_build_object('ok',false,'code','VALIDATION_ERROR','status',422); end if;
  insert into clinicos_showcase.summary_drafts(visit_id,revision_id,author_id,model,text)
  values(v.id,p_revision,v.assigned_doctor_id,'qwen3:4b-instruct-2507-q4_K_M',btrim(p_text)) returning * into d;
 else
  select * into d from clinicos_showcase.summary_drafts where id=p_draft and visit_id=v.id for update;
  if not found or d.state<>'draft' then return jsonb_build_object('ok',false,'code','DRAFT_UNAVAILABLE','status',409); end if;
  if p_action<>'reject' and d.revision_id is distinct from v.current_revision_id then return jsonb_build_object('ok',false,'code','STALE_DRAFT','status',409); end if;
  if p_action not in ('approve','reject','edit') or (p_action='edit' and (p_text is null or length(btrim(p_text)) not between 1 and 12000)) then
   return jsonb_build_object('ok',false,'code','VALIDATION_ERROR','status',422); end if;
  update clinicos_showcase.summary_drafts set state=case p_action when 'approve' then 'approved' when 'reject' then 'rejected' else 'draft' end,
   text=case when p_action='edit' then btrim(p_text) else text end,
   reviewed_at=case when p_action='edit' then null else now() end where id=d.id returning * into d;
 end if;
 return jsonb_build_object('ok',true,'draft',to_jsonb(d));
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_showcase_waitlist(p_doctor uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare patient uuid := (public.clinicos_showcase_patient()->>'id')::uuid; entry uuid;
begin
 if patient is null then return jsonb_build_object('ok',false,'code','FORBIDDEN'); end if;
 if p_date is null or p_date < (now() at time zone 'Africa/Cairo')::date or not exists(select 1 from public.doctor_schedules where doctor_id=p_doctor and is_active) then
 return jsonb_build_object('ok',false,'code','VALIDATION_ERROR'); end if;
 perform pg_advisory_xact_lock(hashtextextended(patient::text||':'||p_doctor||':'||p_date,0));
 select id into entry from public.wait_list where patient_id=patient and doctor_id=p_doctor and preferred_date=p_date and status::text in ('waiting','offered') limit 1;
 if entry is null then insert into public.wait_list(patient_id,doctor_id,preferred_date,status) values(patient,p_doctor,p_date,'waiting') returning id into entry; end if;
 return jsonb_build_object('ok',true,'entry_id',entry);
end $function$;

CREATE OR REPLACE FUNCTION public.clinicos_staff_board(p_date date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  select clinicos_staff_private.board(p_date)
$function$;

CREATE OR REPLACE FUNCTION public.clinicos_staff_booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'pg_catalog'
AS $function$
  select clinicos_staff_private.booking_change(p_appointment,p_action,p_date,p_start,p_end)
$function$;

CREATE OR REPLACE FUNCTION public.clinicos_staff_followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'pg_catalog'
AS $function$
  select clinicos_staff_private.followup(p_visit,p_date,p_action,p_start,p_end)
$function$;

CREATE OR REPLACE FUNCTION public.clinicos_staff_visit_files(p_visit uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  select clinicos_staff_private.visit_files(p_visit)
$function$;

CREATE OR REPLACE FUNCTION public.handle_cancellation_request_timestamps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();

    IF NEW.status IN ('confirmed', 'failed', 'cancelled')
       AND OLD.status IS DISTINCT FROM NEW.status THEN
        NEW.processed_at = now();
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_rescheduling_request_timestamps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();

    IF NEW.status IN ('confirmed', 'failed', 'cancelled')
       AND OLD.status IS DISTINCT FROM NEW.status THEN
        NEW.processed_at = now();
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_cancellation_request()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM pg_notify(
        'cancellation_requests_channel',
        json_build_object(
            'id', NEW.id,
            'status', NEW.status
        )::text
    );

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_new_booking_request()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM pg_notify(
        'booking_requests_channel',
        json_build_object(
            'id', NEW.id,
            'status', NEW.status
        )::TEXT
    );

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_rescheduling_request()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM pg_notify(
        'rescheduling_requests_channel',
        json_build_object(
            'id', NEW.id,
            'status', NEW.status
        )::text
    );

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reschedule_appointment(p_appointment_id uuid, p_new_date date, p_new_start_time time without time zone, p_new_end_time time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_appointment public.appointments%ROWTYPE;
BEGIN

    -- Find and lock the existing appointment
    SELECT *
    INTO v_appointment
    FROM public.appointments
    WHERE id = p_appointment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Appointment not found'
        );
    END IF;


    -- Only booked appointments can be rescheduled
    IF v_appointment.status IS DISTINCT FROM
       'booked'::public.appointment_status THEN

        RETURN jsonb_build_object(
            'success', false,
            'message', 'Only booked appointments can be rescheduled'
        );
    END IF;


    -- Validate requested time
    IF p_new_date IS NULL
       OR p_new_start_time IS NULL
       OR p_new_end_time IS NULL
       OR p_new_end_time <= p_new_start_time THEN

        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid requested date or time'
        );
    END IF;


    -- Serialize scheduling operations for this doctor and date
    PERFORM pg_advisory_xact_lock(
        hashtextextended(
            v_appointment.doctor_id::text || ':' || p_new_date::text,
            0
        )
    );


    -- Check that the requested slot matches an active doctor schedule
    IF NOT EXISTS (
        SELECT 1
        FROM public.doctor_schedules ds
        WHERE ds.doctor_id = v_appointment.doctor_id
          AND ds.is_active = true
          AND ds.day_of_week = EXTRACT(DOW FROM p_new_date)::INTEGER
          AND ds.slot_duration_minutes > 0
          AND p_new_start_time >= ds.start_time
          AND p_new_end_time <= ds.end_time
          AND EXTRACT(
                EPOCH FROM (p_new_end_time - p_new_start_time)
              ) / 60 = ds.slot_duration_minutes
          AND MOD(
                (
                    EXTRACT(
                        EPOCH FROM (p_new_start_time - ds.start_time)
                    ) / 60
                )::INTEGER,
                ds.slot_duration_minutes
              ) = 0
    ) THEN

        RETURN jsonb_build_object(
            'success', false,
            'message', 'Requested time is outside the doctor schedule or has an invalid duration'
        );
    END IF;


    -- Check whether another active appointment overlaps
    IF EXISTS (
        SELECT 1
        FROM public.appointments a
        WHERE a.doctor_id = v_appointment.doctor_id
          AND a.appointment_date = p_new_date
          AND a.id <> p_appointment_id
          AND a.status IN (
              'booked'::public.appointment_status,
              'checked_in'::public.appointment_status
          )
          AND a.start_time < p_new_end_time
          AND a.end_time > p_new_start_time
    ) THEN

        RETURN jsonb_build_object(
            'success', false,
            'message', 'The requested time overlaps with another appointment'
        );
    END IF;


    -- Update the existing appointment
    UPDATE public.appointments
    SET
        appointment_date = p_new_date,
        start_time = p_new_start_time,
        end_time = p_new_end_time,
        updated_at = now()
    WHERE id = p_appointment_id;


    RETURN jsonb_build_object(
        'success', true,
        'appointment_id', p_appointment_id,
        'new_date', p_new_date,
        'new_start_time', p_new_start_time,
        'new_end_time', p_new_end_time,
        'message', 'Appointment rescheduled successfully'
    );

END;
$function$;

CREATE OR REPLACE FUNCTION public.set_booking_request_processed_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.status IN ('confirmed', 'failed', 'cancelled')
       AND OLD.status IS DISTINCT FROM NEW.status THEN
        NEW.processed_at = NOW();
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_waiting_list_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_waiting_list_booking_result()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_offer_id UUID;
BEGIN
    IF NEW.waiting_list_offer_id IS NULL
       OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
        RETURN NEW;
    END IF;

    v_offer_id := NEW.waiting_list_offer_id;

    IF NEW.status = 'confirmed'::public.booking_request_status THEN
        UPDATE public.waiting_list_offers
        SET status = 'booked', updated_at = now()
        WHERE id = v_offer_id;

        UPDATE public.wait_list
        SET status = 'fulfilled'::public.waiting_status,
            offer_expires_at = NULL
        WHERE id = (
            SELECT waiting_list_id
            FROM public.waiting_list_offers
            WHERE id = v_offer_id
        );

    ELSIF NEW.status = 'failed'::public.booking_request_status THEN
        UPDATE public.waiting_list_offers
        SET status = 'failed', updated_at = now()
        WHERE id = v_offer_id;

        UPDATE public.wait_list
        SET status = 'waiting'::public.waiting_status,
            offer_expires_at = NULL
        WHERE id = (
            SELECT waiting_list_id
            FROM public.waiting_list_offers
            WHERE id = v_offer_id
        );

        UPDATE public.available_slot_events
        SET status = 'pending', updated_at = now()
        WHERE id = (
            SELECT slot_event_id
            FROM public.waiting_list_offers
            WHERE id = v_offer_id
        );

        PERFORM pg_notify(
            'available_slot_events_channel',
            json_build_object(
                'id',
                (
                    SELECT slot_event_id
                    FROM public.waiting_list_offers
                    WHERE id = v_offer_id
                )
            )::TEXT
        );
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_booking_request_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION clinic.create_invoice(p_request text, p_actor uuid, p_visit uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE v public.visits%ROWTYPE; old clinic.invoices%ROWTYPE; new_id uuid; result jsonb; total numeric;
BEGIN
 IF p_request IS NULL OR btrim(p_request)='' OR p_actor IS NULL OR p_visit IS NULL THEN RETURN jsonb_build_object('ok',false,'code','VALIDATION_ERROR','data',null,'message','Required input missing'); END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('invoice:'||p_request,0));
 SELECT * INTO old FROM clinic.invoices WHERE request_id=p_request;
 IF FOUND THEN
  IF old.actor_id<>p_actor OR old.visit_id<>p_visit THEN RETURN jsonb_build_object('ok',false,'code','REQUEST_CONFLICT','data',null,'message','Request key reused'); END IF;
  RETURN old.response;
 END IF;
 SELECT * INTO v FROM public.visits WHERE id=p_visit FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','NOT_FOUND','data',null,'message','Visit not found'); END IF;
 SELECT * INTO old FROM clinic.invoices WHERE visit_id=p_visit;
 IF FOUND THEN RETURN old.response; END IF;
 IF v.status<>'finalized' THEN RETURN jsonb_build_object('ok',false,'code','VISIT_NOT_FINALIZED','data',null,'message','Visit is not finalized'); END IF;
 PERFORM 1 FROM public.performed_services WHERE visit_id=p_visit FOR UPDATE;
 IF NOT FOUND OR EXISTS (SELECT 1 FROM public.performed_services ps LEFT JOIN public.visit_revisions r ON r.id=ps.revision_id AND r.visit_id=ps.visit_id LEFT JOIN clinic.services s ON s.service_code=ps.service_code AND s.active WHERE ps.visit_id=p_visit AND (r.id IS NULL OR s.id IS NULL OR ps.finalized_at IS NULL OR ps.quantity<=0)) THEN
  RETURN jsonb_build_object('ok',false,'code','INVALID_SERVICES','data',null,'message','Services are missing or invalid'); END IF;
 PERFORM 1 FROM clinic.services s JOIN public.performed_services ps ON ps.service_code=s.service_code WHERE ps.visit_id=p_visit FOR SHARE OF s;
 IF EXISTS (SELECT 1 FROM public.performed_services ps JOIN clinic.services s ON s.service_code=ps.service_code WHERE ps.visit_id=p_visit AND NOT s.active) THEN RETURN jsonb_build_object('ok',false,'code','INVALID_SERVICES','data',null,'message','Services are missing or invalid'); END IF;
 SELECT sum(ps.quantity*s.price) INTO total FROM public.performed_services ps JOIN clinic.services s ON s.service_code=ps.service_code WHERE ps.visit_id=p_visit;
 IF total>9999999999.99 THEN RETURN jsonb_build_object('ok',false,'code','AMOUNT_OUT_OF_RANGE','data',null,'message','Invoice total too large'); END IF;
 new_id:=gen_random_uuid();
 result:=jsonb_build_object('ok',true,'code','INVOICE_CREATED','data',jsonb_build_object('invoice_id',new_id,'visit_id',p_visit,'total',to_char(total,'FM9999999990.00'),'currency','EGP'),'message','Invoice created');
 INSERT INTO clinic.invoices(id,visit_id,patient_id,actor_id,request_id,response) VALUES(new_id,p_visit,v.patient_id,p_actor,p_request,result);
 INSERT INTO clinic.invoice_lines SELECT new_id,ps.id,ps.revision_id,ps.service_code,s.name,ps.quantity,s.price,ps.finalized_at FROM public.performed_services ps JOIN clinic.services s ON s.service_code=ps.service_code WHERE ps.visit_id=p_visit;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION clinic.get_invoice(p_invoice uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE v clinic.invoices%ROWTYPE; total numeric; paid numeric; changed boolean;
BEGIN
 SELECT * INTO v FROM clinic.invoices WHERE id=p_invoice;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','NOT_FOUND','data',null,'message','Invoice not found'); END IF;
 SELECT coalesce(sum(quantity*unit_price),0) INTO total FROM clinic.invoice_lines WHERE invoice_id=v.id;
 SELECT coalesce(sum(amount),0) INTO paid FROM clinic.payments WHERE invoice_id=v.id;
 SELECT EXISTS (
   (SELECT performed_service_id, revision_id, service_code, quantity, source_finalized_at FROM clinic.invoice_lines WHERE invoice_id=v.id
    EXCEPT SELECT id,revision_id,service_code,quantity,finalized_at FROM public.performed_services WHERE visit_id=v.visit_id)
   UNION ALL
   (SELECT id,revision_id,service_code,quantity,finalized_at FROM public.performed_services WHERE visit_id=v.visit_id
    EXCEPT SELECT performed_service_id,revision_id,service_code,quantity,source_finalized_at FROM clinic.invoice_lines WHERE invoice_id=v.id)
 ) INTO changed;
 RETURN jsonb_build_object('ok',true,'code','INVOICE_FOUND','data',jsonb_build_object('invoice_id',v.id,'visit_id',v.visit_id,'patient_id',v.patient_id,'currency','EGP','total',to_char(total,'FM9999999990.00'),'paid',to_char(paid,'FM9999999990.00'),'balance',to_char(total-paid,'FM9999999990.00'),'source_changed',changed),'message','Invoice retrieved');
END $function$;

CREATE OR REPLACE FUNCTION clinic.immutable_billing()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN RAISE EXCEPTION 'billing records are immutable'; END $function$;

CREATE OR REPLACE FUNCTION clinic.p4_claim_due_notifications(batch_size integer)
 RETURNS SETOF clinic.p4_notification_outbox
 LANGUAGE sql
AS $function$
 with candidates as (select id from clinic.p4_notification_outbox where state='pending' and due_at<=statement_timestamp() order by due_at,id limit greatest(0,least(coalesce(batch_size,0),100)) for update skip locked)
 update clinic.p4_notification_outbox o set state='claimed',claimed_at=statement_timestamp() from candidates where o.id=candidates.id returning o.*;
$function$;

CREATE OR REPLACE FUNCTION clinic.p4_expire_notification_claims()
 RETURNS void
 LANGUAGE sql
AS $function$
 update clinic.p4_notification_outbox set state=case when dispatch_started_at is null then 'pending' else 'delivery_unknown' end,resolved_at=case when dispatch_started_at is not null then statement_timestamp() end,claimed_at=case when dispatch_started_at is not null then claimed_at end where state='claimed' and greatest(claimed_at,dispatch_started_at)<=statement_timestamp()-interval '5 minutes';
$function$;

CREATE OR REPLACE FUNCTION clinic.p4_finish_notification(p_id bigint, p_claim timestamp with time zone, p_outcome text)
 RETURNS boolean
 LANGUAGE sql
AS $function$
 with recorded as (update clinic.p4_notification_outbox o set state=p_outcome,resolved_at=statement_timestamp() where o.id=p_id and o.claimed_at=p_claim and o.dispatch_started_at is not null and (o.state='claimed' or (o.state='delivery_unknown' and p_outcome<>'delivery_unknown')) and p_outcome in ('accepted','failed','delivery_unknown') returning 1) select exists(select 1 from recorded);
$function$;

CREATE OR REPLACE FUNCTION clinic.p4_prepare_notification(p_id bigint, p_claim timestamp with time zone)
 RETURNS TABLE(id text, claim_token text, chat_id text, template_key text)
 LANGUAGE plpgsql
AS $function$
 declare item clinic.p4_notification_outbox; source record; recipient record;
 begin
 select o.* into item from clinic.p4_notification_outbox o where o.id=p_id and o.claimed_at=p_claim and o.state='claimed' and o.dispatch_started_at is null and o.claimed_at>statement_timestamp()-interval '5 minutes' for update;
 if not found then return; end if;
 select e.* into source from clinic.p4_current_notification_events e where e.event_id=item.event_id and e.template_key=item.template_key;
 if not found then return; end if;
 if source.eligible is true and source.event_version=item.event_version and source.recipient_ref=item.recipient_ref then
 select r.* into recipient from clinic.p4_verified_notification_recipients r where r.recipient_ref=item.recipient_ref;
 if not found then return; end if;
 if recipient.eligible is true then
 if recipient.chat_id is null or recipient.chat_id !~ '^[1-9][0-9]*$' then return; end if;
 update clinic.p4_notification_outbox o set dispatch_started_at=statement_timestamp() where o.id=p_id;
 return query select item.id::text,item.claimed_at::text,recipient.chat_id,item.template_key;
 return;
 end if;
 end if;
 update clinic.p4_notification_outbox o set state='suppressed',resolved_at=statement_timestamp() where o.id=p_id;
 end;
$function$;

CREATE OR REPLACE FUNCTION clinic.p5_generate_invoice(p_request text, p_actor uuid, p_visit uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'pg_catalog'
AS $function$ SELECT p5_private.generate_invoice(p_request,p_actor,p_visit) $function$;

CREATE OR REPLACE FUNCTION clinic.p5_get_service(p_actor uuid, p_code text)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'pg_catalog'
AS $function$ SELECT p5_private.get_service(p_actor,p_code) $function$;

CREATE OR REPLACE FUNCTION clinic.p5_save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'pg_catalog'
AS $function$ SELECT p5_private.save_service(p_request,p_actor,p_action,p_code,p_name,p_price,p_active) $function$;

CREATE OR REPLACE FUNCTION clinic.record_payment(p_request text, p_actor uuid, p_invoice uuid, p_amount text, p_method text, p_reference text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE old clinic.payments%ROWTYPE; amount numeric; total numeric; paid numeric; new_id uuid; result jsonb;
BEGIN
 IF p_request IS NULL OR btrim(p_request)='' OR p_actor IS NULL OR p_invoice IS NULL OR p_method IS NULL OR btrim(p_method)='' OR p_amount IS NULL OR p_amount !~ '^[0-9]{1,10}(\.[0-9]{1,2})?$' THEN RETURN jsonb_build_object('ok',false,'code','VALIDATION_ERROR','data',null,'message','Invalid payment input'); END IF;
 amount:=p_amount::numeric;
 IF amount<=0 THEN RETURN jsonb_build_object('ok',false,'code','VALIDATION_ERROR','data',null,'message','Amount must be positive'); END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('payment:'||p_request,0));
 SELECT * INTO old FROM clinic.payments WHERE request_id=p_request;
 IF FOUND THEN
  IF old.actor_id<>p_actor OR old.invoice_id<>p_invoice OR old.amount<>amount OR old.method<>p_method OR old.reference IS DISTINCT FROM p_reference THEN RETURN jsonb_build_object('ok',false,'code','REQUEST_CONFLICT','data',null,'message','Request key reused'); END IF;
  RETURN old.response;
 END IF;
 PERFORM 1 FROM clinic.invoices WHERE id=p_invoice FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','NOT_FOUND','data',null,'message','Invoice not found'); END IF;
 SELECT coalesce(sum(quantity*unit_price),0) INTO total FROM clinic.invoice_lines WHERE invoice_id=p_invoice;
 SELECT coalesce(sum(p.amount),0) INTO paid FROM clinic.payments p WHERE invoice_id=p_invoice;
 IF amount>total-paid THEN RETURN jsonb_build_object('ok',false,'code','OVERPAYMENT','data',null,'message','Payment exceeds balance'); END IF;
 new_id:=gen_random_uuid();
 result:=jsonb_build_object('ok',true,'code','PAYMENT_RECORDED','data',jsonb_build_object('payment_id',new_id,'invoice_id',p_invoice,'amount',to_char(amount,'FM9999999990.00'),'balance',to_char(total-paid-amount,'FM9999999990.00'),'currency','EGP'),'message','Payment recorded');
 INSERT INTO clinic.payments(id,invoice_id,actor_id,request_id,amount,method,reference,response) VALUES(new_id,p_invoice,p_actor,p_request,amount,p_method,p_reference,result);
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION clinicos_identity.apply_staff_sync(p_batch jsonb)
 RETURNS bigint
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    WITH changed AS (
        INSERT INTO clinicos_identity.staff AS staff
            (id, role, is_active, created_at, sync_revision, name, telegram_user_id)
        SELECT id, role, is_active, created_at, sync_revision,
            CASE WHEN is_active THEN name END,
            CASE WHEN is_active THEN telegram_user_id END
        FROM jsonb_to_recordset(p_batch) AS sent(
            id uuid, role text, is_active boolean, created_at timestamptz, sync_revision bigint,
            name text, telegram_user_id bigint
        )
        ON CONFLICT (id) DO UPDATE
        SET role = EXCLUDED.role, is_active = EXCLUDED.is_active,
            sync_revision = EXCLUDED.sync_revision, name = EXCLUDED.name,
            telegram_user_id = EXCLUDED.telegram_user_id
        WHERE staff.sync_revision < EXCLUDED.sync_revision
        RETURNING id
    )
    SELECT count(*) FROM changed;
$function$;

CREATE OR REPLACE FUNCTION clinicos_showcase.linked_demo_appointment(p_appointment uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
 select exists(select 1 from public.appointments a where a.id=p_appointment and clinicos_showcase.linked_demo_recipient(a.patient_id::text))
 $function$;

CREATE OR REPLACE FUNCTION clinicos_showcase.linked_demo_offer(p_offer uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
 select exists(select 1 from public.waiting_list_offers o where o.id=p_offer and clinicos_showcase.linked_demo_recipient(o.patient_id::text))
 $function$;

CREATE OR REPLACE FUNCTION clinicos_showcase.linked_demo_recipient(p_patient text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
 select exists(select 1 from clinicos_showcase.telegram_recipients r where r.recipient_ref=p_patient and r.eligible)
 $function$;

CREATE OR REPLACE FUNCTION clinicos_showcase.process_invoice()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare q clinicos_showcase.invoice_queue%rowtype; r jsonb; code text;
begin
 select * into q from clinicos_showcase.invoice_queue where invoice_id is null and next_attempt_at<=now()
 order by next_attempt_at,queued_at limit 1 for update skip locked;
 if not found then return '{}'::jsonb; end if;
 begin
  r:=clinic.create_invoice('clinicos-final:'||q.visit_id,q.actor_id,q.visit_id);
  if coalesce((r->>'ok')::boolean,false) and (r#>>'{data,invoice_id}') is not null then
   update clinicos_showcase.invoice_queue set invoice_id=(r#>>'{data,invoice_id}')::uuid,attempts=attempts+1,error_code=null where visit_id=q.visit_id;
   return jsonb_build_object('ok',true,'visit_id',q.visit_id,'invoice_id',r#>>'{data,invoice_id}');
  end if;
  code:=coalesce(r->>'code','UNKNOWN');
 exception when others then code:='INVOICE_WORKER_ERROR';
 end;
 update clinicos_showcase.invoice_queue set attempts=attempts+1,error_code=code,next_attempt_at=now()+interval '5 minutes' where visit_id=q.visit_id;
 return jsonb_build_object('ok',false,'visit_id',q.visit_id,'code',code);
end $function$;

CREATE OR REPLACE FUNCTION clinicos_showcase.queue_notifications()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare no_shows integer; queued integer;
begin
 update public.appointments a set status='no_show',updated_at=statement_timestamp() where a.status='booked'
 and ((a.appointment_date+a.start_time) at time zone 'Africa/Cairo')+interval '15 minutes'<=now()
 and ((a.appointment_date+a.start_time) at time zone 'Africa/Cairo') >= (select enabled_after from clinicos_showcase.settings);
 get diagnostics no_shows=row_count;
 insert into clinic.p4_notification_outbox(event_id,template_key,event_version,recipient_ref,due_at)
 select e.event_id,e.template_key,e.event_version,e.recipient_ref,e.due_at from clinicos_showcase.notification_events e
 join clinicos_showcase.telegram_recipients r on r.recipient_ref=e.recipient_ref and r.eligible where e.eligible and not exists(select 1 from clinic.p4_notification_outbox o where
 (o.event_id,o.template_key,o.event_version,o.recipient_ref,o.due_at)=(e.event_id,e.template_key,e.event_version,e.recipient_ref,e.due_at))
 order by e.due_at limit 100
 on conflict(event_id,event_version,recipient_ref,template_key,due_at) do nothing;
 get diagnostics queued=row_count;
 return jsonb_build_object('no_shows',no_shows,'queued',queued);
end $function$;

CREATE OR REPLACE FUNCTION clinicos_showcase.telegram_action(bot bigint, sender bigint, update_id bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare parts text[]:=regexp_split_to_array(btrim(command),'[[:space:]]+'); patient uuid; doctor uuid; day date; slot time; end_slot time; msg text; offer public.waiting_list_offers%rowtype; request uuid;
begin
 if not exists (select 1 from p1_telegram.sync_scope scope where scope.bot_id = bot) then return null; end if;
 if parts[1] in ('/book','/bookingstatus') and parts[2] is null then
  return 'Choose a profile using /profiles, then send /book PROFILE or /bookingstatus PROFILE.';
 end if;
 select l.patient_id into patient from p1_telegram.patient_links l join p1_telegram.registration_consent c using(bot_id,telegram_user_id)
 join clinicos_identity.patients p on p.id=l.patient_id and p.is_active
 where l.bot_id=bot and l.telegram_user_id=sender and c.decision and c.notice_version='demo-v2'
 and case when parts[1] in ('/book','/bookingstatus') then l.profile_number::text=parts[2] else l.selected end;
 if patient is null then return 'Choose a synced linked profile with /profiles and accept the consent notice.'; end if;
 if parts[1]='/bookingstatus' then
  select status::text into msg from public.booking_requests where patient_id=patient order by created_at desc,id desc limit 1;
  return 'Your latest booking status: '||coalesce(msg,'no request found');
 elsif parts[1]='/offers' then
  select string_agg(id::text||' for '||appointment_date||' at '||start_time,E'\n') into msg
  from (select * from public.waiting_list_offers where patient_id=patient and status='pending' and expires_at>now() order by expires_at limit 8) o;
  return coalesce(msg||E'\nSend /offer OFFER_ID accept or /offer OFFER_ID decline.','You have no active waiting-list offers.');
 elsif parts[1]='/offer' then
  if coalesce(parts[2],'') !~* '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$' or coalesce(parts[3],'') not in ('accept','decline') then return 'Send /offers to see your active options.'; end if;
  select * into offer from public.waiting_list_offers where id=parts[2]::uuid and patient_id=patient and status='pending' and expires_at>now() for update;
  if not found then return 'The offer is unavailable or has expired.'; end if;
  if parts[3]='accept' then
   insert into public.booking_requests(patient_id,doctor_id,appointment_date,start_time,end_time,idempotency_key,waiting_list_offer_id)
   values(offer.patient_id,offer.doctor_id,offer.appointment_date,offer.start_time,offer.end_time,'waiting-list-offer:'||offer.id,offer.id)
   on conflict (idempotency_key) where idempotency_key is not null do update set updated_at=now() returning id into request;
   update public.waiting_list_offers set status='accepted',booking_request_id=request,responded_at=now(),updated_at=now() where id=offer.id;
   return 'Offer accepted. Your booking request is queued.';
  end if;
  update public.waiting_list_offers set status='rejected',responded_at=now(),updated_at=now() where id=offer.id;
  update public.wait_list set status='waiting',offer_expires_at=null,updated_at=now() where id=offer.waiting_list_id;
  update public.available_slot_events set status='pending',updated_at=now() where id=offer.slot_event_id;
  return 'Offer declined and slot released.';
 elsif parts[1]='/faq' then
  if parts[2] is null then
   select string_agg(faq_id||' — '||question,E'\n' order by faq_id) into msg from clinic.p4_demo_faq where approved_for_demo;
   return coalesce('Send /faq ID for an answer.'||E'\n'||msg,'No approved FAQ is currently available.');
  end if;
  select answer into msg from clinic.p4_demo_faq where approved_for_demo and faq_id=parts[2];
  if msg is not null then return msg; end if;
  insert into clinicos_showcase.handoffs(patient_id,kind,source_key) values(patient,'faq','telegram:'||bot||':'||update_id) on conflict do nothing;
  return 'A staff member can help. A handoff was opened. Please keep medical details out of Telegram.';
 elsif parts[1]='/feedback' then
  if coalesce(parts[2],'') !~ '^[1-5]$' then return 'Send /feedback followed by a rating from 1 to 5.'; end if;
  select id into request from public.visits where patient_id=patient and status='finalized' and finalized_at>now()-interval '30 days' order by finalized_at desc limit 1;
  if not found then return 'No recent completed visit is available for feedback.'; end if;
  insert into clinicos_showcase.feedback(visit_id,patient_id,score) values(request,patient,parts[2]::smallint) on conflict do nothing;
  if parts[2]::int<=2 then insert into clinicos_showcase.handoffs(patient_id,kind,source_key) values(patient,'feedback','feedback:'||request) on conflict do nothing; end if;
  return 'Thank you. Your feedback was received.';
 end if;
 if parts[3] is null then
  select string_agg(x.id::text||' — '||x.label,E'\n') into msg from (
   select distinct ds.doctor_id id,coalesce(st.name,'Doctor '||left(ds.doctor_id::text,8)) label
   from public.doctor_schedules ds left join clinicos_identity.staff st on st.id=ds.doctor_id where ds.is_active order by 2 limit 12
  ) x;
  return coalesce('Choose a doctor. Send /book '||parts[2]||' DOCTOR_ID YYYY-MM-DD.'||E'\n'||msg,'No doctors are available.');
 end if;
 if parts[3] !~* '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$' or coalesce(parts[4],'') !~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$' then
  return 'Send /book PROFILE DOCTOR_ID YYYY-MM-DD.';
 end if;
 doctor:=parts[3]::uuid;
 begin day:=parts[4]::date; exception when datetime_field_overflow or invalid_datetime_format then return 'Choose a valid date.'; end;
 if day not between (now() at time zone 'Africa/Cairo')::date and (now() at time zone 'Africa/Cairo')::date+90 then return 'Choose a date within the next 90 days.'; end if;
 if parts[5] is not null then
  if parts[5] !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then return 'Send a slot in HH:MM format.'; end if;
  slot:=parts[5]::time;
 end if;
 with slots as (
  select distinct t::time starts,(t+make_interval(mins=>s.slot_duration_minutes))::time ends
  from public.doctor_schedules s cross join lateral generate_series(day+s.start_time,day+s.end_time-make_interval(mins=>s.slot_duration_minutes),make_interval(mins=>greatest(s.slot_duration_minutes,1))) t
  where s.doctor_id=doctor and s.is_active and s.day_of_week=extract(dow from day) and s.slot_duration_minutes between 1 and 720
  and t>(now() at time zone 'Africa/Cairo')
  and not exists(select 1 from public.appointments a where a.doctor_id=doctor and a.appointment_date=day and a.status<>'cancelled' and a.start_time<(t+make_interval(mins=>s.slot_duration_minutes))::time and a.end_time>t::time)
 )
 select string_agg(to_char(day+starts,'HH24:MI'),'  ' order by starts),min(ends) filter(where starts=slot)
 into msg,end_slot from slots;
 if slot is null then return coalesce('Available slots: '||msg||E'\nSend the same /book command with HH:MM at the end.','No slots remain on that date.'); end if;
 if end_slot is null then return 'That slot is unavailable. Request the available slots again.'; end if;
 insert into public.booking_requests(patient_id,doctor_id,appointment_date,start_time,end_time,idempotency_key)
 values(patient,doctor,day,slot,end_slot,'telegram:'||bot||':'||update_id)
 on conflict (idempotency_key) where idempotency_key is not null do nothing;
 return 'Booking request received. Send /bookingstatus '||parts[2]||' to check it.';
end $function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.board(p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb := public.clinicos_showcase_actor();
        actor_id uuid := (actor->>'id')::uuid;
        staff_role text := actor->>'role';
        day date := coalesce(p_date, (current_timestamp at time zone 'Africa/Cairo')::date);
begin
  if coalesce(staff_role, '') not in ('admin', 'doctor') then
    return jsonb_build_object('ok', false, 'code', 'FORBIDDEN');
  end if;
  return jsonb_build_object(
    'ok', true, 'date', day,
    'appointments', coalesce((
      select jsonb_agg(row_data order by a.start_time, a.id)
      from public.appointments a
      join clinicos_identity.patients p on p.id = a.patient_id
      join clinicos_identity.staff s on s.id = a.doctor_id
      left join public.visits v on v.appointment_id = a.id
      left join clinicos_showcase.followups f on f.visit_id = v.id
      left join public.appointments next_visit on next_visit.id=f.appointment_id
      left join clinicos_showcase.followups source_followup on source_followup.appointment_id=a.id
      left join lateral (
        select i.id, coalesce((select sum(l.quantity * l.unit_price) from clinic.invoice_lines l where l.invoice_id = i.id), 0) total,
          coalesce((select sum(m.amount) from clinic.payments m where m.invoice_id = i.id), 0) paid
        from clinic.invoices i where i.visit_id = v.id
        order by i.created_at desc limit 1
      ) inv on staff_role = 'admin'
      cross join lateral (
        select jsonb_build_object('id', a.id, 'patient_id', a.patient_id, 'patient', p.full_name,
          'doctor', s.name, 'doctor_id', a.doctor_id, 'start', a.start_time, 'end', a.end_time,
          'status', a.status, 'visit_id', v.id, 'started', v.started_at, 'finalized', v.finalized_at,
          'is_followup', source_followup.visit_id is not null,
          'followup', case when f.visit_id is not null then jsonb_build_object(
            'due_date',coalesce(next_visit.appointment_date,f.due_date),
            'start',next_visit.start_time,'end',next_visit.end_time,'status',next_visit.status,
            'needs_review',f.appointment_id is null and f.revision_id is distinct from v.current_revision_id) end,
          'invoice', case when inv.id is not null then jsonb_build_object('id', inv.id, 'total', inv.total::text,
            'paid', inv.paid::text, 'balance', greatest(inv.total - inv.paid, 0)::text) end) row_data
      ) fields
      where a.appointment_date = day
        and (staff_role = 'admin' or (a.doctor_id = actor_id and (v.id is null or v.assigned_doctor_id = actor_id)))
    ), '[]'::jsonb),
    'followups', case when staff_role = 'admin' then coalesce((
      select jsonb_agg(jsonb_build_object('patient',p.full_name,'doctor',s.name,'due_date',f.due_date,
        'appointment_date',a.appointment_date,'needs_review',f.revision_id is distinct from v.current_revision_id)
        order by p.full_name,v.id)
      from clinicos_showcase.followups f
      join public.visits v on v.id=f.visit_id
      join public.appointments a on a.id=v.appointment_id
      join clinicos_identity.patients p on p.id=v.patient_id and p.is_active
      join clinicos_identity.staff s on s.id=v.assigned_doctor_id
      where f.due_date=day and f.appointment_id is null
    ),'[]'::jsonb) end,
    'services', coalesce((select jsonb_agg(jsonb_build_object('code', s.service_code, 'name', s.name,
      'price', s.price::text, 'active', s.active) order by s.name)
      from clinic.services s where staff_role = 'admin' or s.active), '[]'::jsonb),
    'doctors', case when staff_role = 'admin' then coalesce((
      select jsonb_agg(jsonb_build_object('id',s.id,'name',s.name) order by s.name)
      from clinicos_identity.staff s where s.role = 'doctor' and s.is_active
    ), '[]'::jsonb) end,
    'patients', case when staff_role = 'admin' then coalesce((
      select jsonb_agg(jsonb_build_object('id',p.id,'name',p.full_name,'dob',p.date_of_birth) order by p.full_name)
      from clinicos_identity.patients p where p.is_active
    ), '[]'::jsonb) end);
end $function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
begin
  if coalesce(public.clinicos_showcase_actor()->>'role','') <> 'admin' then
    return jsonb_build_object('ok',false,'code','FORBIDDEN');
  end if;
  if p_action = 'cancel' then return public.cancel_appointment(p_appointment); end if;
  if p_action = 'reschedule' and p_date >= (current_timestamp at time zone 'Africa/Cairo')::date
    then return public.reschedule_appointment(p_appointment,p_date,p_start,p_end); end if;
  return jsonb_build_object('ok',false,'code','VALIDATION_ERROR');
end $function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.claim_file(p_doctor text, p_visit text, p_attachment text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare attachment public.visit_attachments%rowtype; patient uuid; chat text; attempt uuid;
        existing clinicos_staff_private.file_delivery%rowtype;
        uuid_pattern constant text := '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
begin
  if coalesce(p_doctor,'') !~ uuid_pattern then return jsonb_build_object('status',403,'code','FORBIDDEN'); end if;
  if coalesce(p_visit,'') !~ uuid_pattern or coalesce(p_attachment,'') !~ uuid_pattern then
    return jsonb_build_object('status',422,'code','VALIDATION_ERROR');
  end if;
  select a.* into attachment from public.visit_attachments a
    join public.visits v on v.id=a.visit_id
    join clinicos_identity.staff s on s.id=v.assigned_doctor_id and s.is_active and s.role='doctor'
    where a.id=p_attachment::uuid and v.id=p_visit::uuid and s.id=p_doctor::uuid
    for update of a;
  if not found then return jsonb_build_object('status',404,'code','FORBIDDEN'); end if;
  if attachment.storage_path !~ ('^' || p_visit || '/[0-9]+_[0-9a-f]{12}\.(pdf|png|jpg)$')
    then return jsonb_build_object('status',409,'code','FILE_UNAVAILABLE'); end if;
  select * into existing from clinicos_staff_private.file_delivery where attachment_id=attachment.id;
  if found and existing.state <> 'failed' then
    return jsonb_build_object('status',case when existing.state='accepted' then 200 else 409 end,
      'code',case when existing.state='sending' and existing.claimed_at < statement_timestamp()-interval '2 minutes'
         then 'delivery_unknown' else existing.state end);
  end if;
  select v.patient_id into patient from public.visits v where v.id=p_visit::uuid;
  chat:=clinicos_staff_private.eligible_chat(patient);
  if chat is null then return jsonb_build_object('status',409,'code','NO_LINKED_CHAT'); end if;
  attempt:=gen_random_uuid();
  insert into clinicos_staff_private.file_delivery (attachment_id,doctor_id,claim,state)
    values(attachment.id,p_doctor::uuid,attempt,'sending')
    on conflict(attachment_id) do update set doctor_id=excluded.doctor_id,claim=excluded.claim,
      state='sending',claimed_at=clock_timestamp(),message_id=null,resolved_at=null;
  return jsonb_build_object('status',200,'code','claimed','attachment_id',attachment.id,'claim',attempt,
    'storage_path',attachment.storage_path,'mime_type',attachment.mime_type,
    'file_name',coalesce(attachment.file_name,split_part(attachment.storage_path,'/',2)),'chat_id',chat);
end $function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.eligible_chat(p_patient uuid)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  select p.telegram_chat_id::text
  from clinicos_identity.patients p
  join p1_telegram.patient_links l on l.patient_id = p.id and l.telegram_user_id = p.telegram_user_id
  join p1_telegram.sync_scope b on b.bot_id = l.bot_id
  join p1_telegram.registration_consent c on c.bot_id = l.bot_id and c.telegram_user_id = l.telegram_user_id
  where p.id = p_patient and p.is_active and p.telegram_chat_id = p.telegram_user_id
    and p.telegram_chat_id > 0 and c.decision and c.notice_version = 'demo-v2'
    and not exists (select 1 from p1_telegram.deletion_requests d
      where d.patient_id = p.id and d.reviewed_at is null)
  limit 1
$function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.finish_file(p_attachment uuid, p_claim uuid, p_state text, p_message bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
begin
  if p_state is null or p_state not in ('accepted','failed','delivery_unknown')
    or (p_state='accepted' and (p_message is null or p_message <= 0)) then
    return 'delivery_unknown';
  end if;
  update clinicos_staff_private.file_delivery set state=p_state, message_id=p_message, resolved_at=clock_timestamp()
    where attachment_id=p_attachment and claim=p_claim and state='sending';
  return case when found then p_state else 'delivery_unknown' end;
end $function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb := public.clinicos_showcase_actor();
        visit public.visits%rowtype;
        booked public.appointments%rowtype;
        first_visit_ends timestamp;
        local_now timestamp := statement_timestamp() at time zone 'Africa/Cairo';
        slots jsonb;
        booking jsonb;
        appointment_id uuid;
begin
  if coalesce(actor->>'role','') <> 'doctor' then
    return jsonb_build_object('ok',false,'code','FORBIDDEN','status',403);
  end if;
  select v.* into visit from public.visits v
    where v.id=p_visit and v.assigned_doctor_id=(actor->>'id')::uuid for update;
  if not found then
    return jsonb_build_object('ok',false,'code','FORBIDDEN','status',403);
  end if;
  if visit.current_revision_id is null then
    return jsonb_build_object('ok',false,'code','REVISION_REQUIRED','status',409);
  end if;
  select a.* into booked from clinicos_showcase.followups f join public.appointments a on a.id=f.appointment_id
    where f.visit_id=visit.id for update of a;

  if p_action is null then
    if booked.id is null then return public.clinicos_showcase_set_followup(p_visit,p_date); end if;
    return jsonb_build_object('ok',false,'code','FOLLOWUP_SLOT_REQUIRED','status',409);
  end if;
  if p_action not in ('slots','book') then
    return jsonb_build_object('ok',false,'code','VALIDATION_ERROR','status',422);
  end if;
  select a.appointment_date+a.end_time into first_visit_ends from public.appointments a where a.id=visit.appointment_id;
  if p_date is null or p_date < greatest(local_now::date,first_visit_ends::date) then
    return jsonb_build_object('ok',false,'code','FOLLOWUP_DATE','status',422);
  end if;
  if booked.id is not null and (booked.status not in ('booked','cancelled')
    or booked.doctor_id<>visit.assigned_doctor_id or booked.patient_id<>visit.patient_id) then
    return jsonb_build_object('ok',false,'code','FOLLOWUP_CLOSED','status',409);
  end if;

  select coalesce(jsonb_agg(jsonb_build_object('start_time',s.start_time,'end_time',s.end_time)
    order by s.start_time,s.end_time),'[]'::jsonb) into slots
  from (
    select distinct t::time start_time,(t+make_interval(mins=>ds.slot_duration_minutes))::time end_time
    from public.doctor_schedules ds
    cross join lateral generate_series(p_date+ds.start_time,
      p_date+ds.end_time-make_interval(mins=>ds.slot_duration_minutes),
      make_interval(mins=>greatest(ds.slot_duration_minutes,1))) t
    where ds.is_active and ds.doctor_id=visit.assigned_doctor_id and ds.day_of_week=extract(dow from p_date)
      and ds.slot_duration_minutes between 1 and 720
      and t>local_now and (first_visit_ends is null or t>=first_visit_ends)
      and not exists(select 1 from public.appointments a
        where a.doctor_id=visit.assigned_doctor_id and a.appointment_date=p_date and a.status<>'cancelled'
          and a.id is distinct from booked.id
          and a.start_time<(t+make_interval(mins=>ds.slot_duration_minutes))::time and a.end_time>t::time)
  ) s;
  if p_action='slots' then
    return jsonb_build_object('ok',true,'date',p_date,'available_slots',slots);
  end if;
  if not exists(select 1 from jsonb_array_elements(slots) s
    where (s->>'start_time')::time=p_start and (s->>'end_time')::time=p_end) then
    return jsonb_build_object('ok',false,'code','FOLLOWUP_SLOT_UNAVAILABLE','status',409);
  end if;

  if booked.status='booked' then
    appointment_id:=booked.id;
    if (booked.appointment_date,booked.start_time,booked.end_time) is distinct from (p_date,p_start,p_end) then
      booking:=public.reschedule_appointment(booked.id,p_date,p_start,p_end);
    end if;
  else
    booking:=public.book_appointment(visit.patient_id,visit.assigned_doctor_id,p_date,p_start,p_end);
    appointment_id:=(booking->>'appointment_id')::uuid;
  end if;
  if (booking is not null and booking->>'success' is distinct from 'true') or appointment_id is null then
    return jsonb_build_object('ok',false,'code','FOLLOWUP_SLOT_UNAVAILABLE','status',409);
  end if;
  insert into clinicos_showcase.followups(visit_id,revision_id,due_date,appointment_id)
    values(visit.id,visit.current_revision_id,p_date,appointment_id)
    on conflict(visit_id) do update set revision_id=excluded.revision_id,due_date=excluded.due_date,
      appointment_id=excluded.appointment_id,version=followups.version+1
    where (followups.revision_id,followups.due_date,followups.appointment_id)
      is distinct from (excluded.revision_id,excluded.due_date,excluded.appointment_id);
  return jsonb_build_object('ok',true,'appointment_id',appointment_id,'date',p_date,'start_time',p_start,'end_time',p_end);
exception when exclusion_violation or unique_violation then
  return jsonb_build_object('ok',false,'code','FOLLOWUP_SLOT_UNAVAILABLE','status',409);
end $function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.may_dispatch(p_attachment uuid, p_claim uuid, p_chat text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  select exists(
    select 1 from clinicos_staff_private.file_delivery d
    join public.visit_attachments a on a.id=d.attachment_id
    join public.visits v on v.id=a.visit_id and v.assigned_doctor_id=d.doctor_id
    join clinicos_identity.staff s on s.id=d.doctor_id and s.role='doctor' and s.is_active
    where d.attachment_id=p_attachment and d.claim=p_claim and d.state='sending'
      and d.claimed_at > statement_timestamp() - interval '2 minutes'
      and clinicos_staff_private.eligible_chat(v.patient_id)=p_chat
  )
$function$;

CREATE OR REPLACE FUNCTION clinicos_staff_private.visit_files(p_visit uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare actor jsonb := public.clinicos_showcase_actor(); patient uuid;
begin
  if coalesce(actor->>'role','') <> 'doctor' then
    return jsonb_build_object('ok',false,'code','FORBIDDEN');
  end if;
  select v.patient_id into patient from public.visits v
    where v.id = p_visit and v.assigned_doctor_id = (actor->>'id')::uuid;
  if not found then return jsonb_build_object('ok',false,'code','FORBIDDEN'); end if;
  return jsonb_build_object('ok',true,'can_send',clinicos_staff_private.eligible_chat(patient) is not null,
    'revision',(select jsonb_build_object('number',r.revision_no,'content',r.content)
      from public.visits v join public.visit_revisions r on r.id=v.current_revision_id where v.id=p_visit),
    'summary',(select jsonb_build_object('id',d.id,'text',d.text,'state',d.state)
      from clinicos_showcase.summary_drafts d join public.visits v
      on v.id=d.visit_id and v.current_revision_id=d.revision_id
      where d.visit_id=p_visit order by d.created_at desc limit 1),
    'files',coalesce((
      select jsonb_agg(jsonb_build_object('id',a.id,'name',coalesce(a.file_name,split_part(a.storage_path,'/',2)),
        'state',case when d.state = 'sending' and d.claimed_at < statement_timestamp() - interval '2 minutes'
          then 'delivery_unknown' else d.state end) order by a.created_at,a.id)
      from public.visit_attachments a left join clinicos_staff_private.file_delivery d on d.attachment_id=a.id
      where a.visit_id=p_visit
    ),'[]'::jsonb));
end $function$;

CREATE OR REPLACE FUNCTION p1_telegram.apply_account_command(actor_bot bigint, actor_user bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    linked_patient uuid;
    profile_label text;
    edit_token uuid;
    phone_input text[];
    request_reason text;
    request_reference uuid;
BEGIN
    IF command = '/cancelregistration' THEN
        DELETE FROM p1_telegram.registration_drafts WHERE bot_id = actor_bot AND telegram_user_id = actor_user;
        IF FOUND THEN
            RETURN 'Registration draft canceled. Send /profile to start again, /newprofile to add another profile, or /start for the menu.';
        END IF;
        RETURN 'You have no unfinished registration.';
    END IF;

    SELECT l.patient_id, l.profile_number || '. ' || p.full_name INTO linked_patient, profile_label
    FROM p1_telegram.patient_links l
    JOIN p1_telegram.registration_consent c USING (bot_id, telegram_user_id)
    JOIN p1_telegram.patients p USING (patient_id)
    WHERE l.bot_id = actor_bot AND l.telegram_user_id = actor_user AND l.selected
      AND c.decision IS TRUE AND c.notice_version = 'demo-v2';
    IF linked_patient IS NULL THEN
        RETURN 'Send /register to accept the current notice, then use /profiles to choose a linked profile.';
    END IF;

    IF command = '/updatephone' OR command ~ '^/savephone([[:space:]]|$)' THEN
        IF NOT (SELECT phone_edits_enabled FROM p1_telegram.account_options WHERE singleton) THEN
            RETURN 'Phone updates are unavailable.';
        END IF;
        IF command = '/updatephone' THEN
            INSERT INTO p1_telegram.phone_edits (bot_id, telegram_user_id, patient_id, expires_at)
            VALUES (actor_bot, actor_user, linked_patient, now() + interval '5 minutes')
            ON CONFLICT (bot_id, telegram_user_id) DO UPDATE SET
                patient_id = EXCLUDED.patient_id, token = EXCLUDED.token, expires_at = EXCLUDED.expires_at
            RETURNING token INTO edit_token;
            RETURN 'Update the phone for ' || profile_label || E'.\nWithin five minutes, send /savephone '
                   || edit_token || ' +NUMBER. Use a made-up international number.';
        END IF;
        phone_input := regexp_match(command, '^/savephone[[:space:]]+([0-9a-f-]{36})[[:space:]]+(\+[1-9][0-9]{7,14})$');
        IF phone_input IS NULL OR NOT pg_input_is_valid(phone_input[1], 'uuid') THEN
            RETURN 'Use /savephone TOKEN +NUMBER from the current /updatephone prompt. Enter a made-up international number.';
        END IF;
        DELETE FROM p1_telegram.phone_edits
        WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND patient_id = linked_patient
          AND token = phone_input[1]::uuid AND expires_at > now();
        IF NOT FOUND THEN RETURN 'That phone prompt is no longer active. Send /updatephone to start again.'; END IF;
        UPDATE p1_telegram.patients
        SET phone_e164 = phone_input[2], phone_revision = phone_revision + 1
        WHERE patient_id = linked_patient AND phone_e164 IS DISTINCT FROM phone_input[2];
        RETURN 'Test phone saved for ' || profile_label || '. Changes sync automatically.';
    END IF;

    IF command ~ '^/confirmdeletionrequest[[:space:]]' THEN
        request_reason := nullif(btrim(regexp_replace(
            substr(command, length('/confirmdeletionrequest') + 1), '[[:space:]]+', ' ', 'g')), '');
        IF char_length(request_reason) > 240 THEN
            RETURN 'Keep your reason to 240 characters. Send /confirmdeletionrequest on its own to skip the reason.';
        END IF;
        command := '/confirmdeletionrequest';
    END IF;

    IF command IN ('/unlinktelegram', '/requestdeletion') THEN
        INSERT INTO p1_telegram.account_confirmations VALUES (
            actor_bot, actor_user, linked_patient,
            CASE command WHEN '/unlinktelegram' THEN '/confirmunlink' ELSE '/confirmdeletionrequest' END,
            now() + interval '10 minutes')
        ON CONFLICT (bot_id, telegram_user_id) DO UPDATE
        SET patient_id = EXCLUDED.patient_id, action = EXCLUDED.action, expires_at = EXCLUDED.expires_at;
    ELSIF command IN ('/confirmunlink', '/confirmdeletionrequest') THEN
        DELETE FROM p1_telegram.account_confirmations
        WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND patient_id = linked_patient
          AND action = command AND expires_at > now();
        IF NOT FOUND THEN RETURN 'There is no active confirmation for this action. Send /commands to start again.'; END IF;
    END IF;

    CASE command
        WHEN '/unlinktelegram' THEN
            RETURN 'Send /confirmunlink within 10 minutes to disconnect Telegram from ' || profile_label ||
                   '. Your other links, clinic profile and appointments stay on file.';
        WHEN '/confirmunlink' THEN
            DELETE FROM p1_telegram.patient_links
            WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND patient_id = linked_patient;
            RETURN 'Telegram disconnected from ' || profile_label || '. Send /profiles to choose another link.';
        WHEN '/requestdeletion' THEN
            RETURN 'Send /confirmdeletionrequest within 10 minutes to ask reception to review the clinic record for ' ||
                   profile_label || '. You may add a short reason. Leave out medical details. The record stays on file during review.';
        WHEN '/confirmdeletionrequest' THEN
            INSERT INTO p1_telegram.deletion_requests (patient_id, patient_reason)
            VALUES (linked_patient, request_reason)
            ON CONFLICT (patient_id) WHERE review_outcome IS DISTINCT FROM 'closed'
            DO UPDATE SET patient_id = EXCLUDED.patient_id
            RETURNING review_reference INTO request_reference;
            RETURN 'Reception review reference ' || request_reference ||
                   '. Keep this reference for follow-up. Your clinic record stays on file.';
        ELSE RETURN NULL;
    END CASE;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.apply_link_command(p_bot_id bigint, p_update_id bigint)
 RETURNS TABLE(chat_id text, reply_text text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    entry p1_telegram.inbox%ROWTYPE;
    command text;
    argument text;
    event text;
    staff_role text;
    target_patient uuid;
    plain_code text;
    issue_parts text[];
    recipient_id bigint;
BEGIN
    SELECT * INTO entry FROM p1_telegram.inbox
    WHERE bot_id = p_bot_id AND update_id = p_update_id AND status = 'pending'
    FOR UPDATE;
    IF NOT FOUND THEN RETURN; END IF;

    command := substring(btrim(entry.payload #>> '{message,text}', E' \t\r\n') FROM '^(/[a-z]+)(?:[[:space:]]|$)');
    IF command IS NULL OR command NOT IN ('/staff','/issue','/link','/linkid') THEN RETURN; END IF;
    argument := btrim(regexp_replace(btrim(entry.payload #>> '{message,text}', E' \t\r\n'), '^/[a-z]+[[:space:]]*', ''));

    -- Serialize attempts and link changes by Telegram actor.
    PERFORM pg_advisory_xact_lock(hashtextextended(p_bot_id::text || ':link:' || entry.telegram_user_id::text, 0));
    SELECT role INTO staff_role FROM p1_telegram.staff
    WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id AND active
    FOR SHARE;

    IF command = '/linkid' THEN
        chat_id := entry.telegram_user_id::text;
        reply_text := 'Your Telegram ID is ' || chat_id || '. Share this ID privately with reception for a link code, or with the bot owner if you need staff access.';
        UPDATE p1_telegram.inbox SET status = 'done', payload = '{}'::jsonb
        WHERE bot_id = p_bot_id AND update_id = p_update_id;
        RETURN NEXT;
        RETURN;
    ELSIF command IN ('/staff', '/issue') AND coalesce(staff_role, '') NOT IN ('reception', 'admin') THEN
        event := 'staff_denied';
        reply_text := 'This command requires active reception or admin access.';
    ELSIF command = '/staff' THEN
        event := 'staff_verified';
        reply_text := 'Reception access verified. Ask the recipient to send /linkid, then use /issue PATIENT_UUID TELEGRAM_ID. Use /duplicatereviews and /deletionreviews to see open reviews.';
    ELSIF command = '/issue' THEN
        event := 'issue_denied';
        reply_text := 'Use /issue PATIENT_UUID TELEGRAM_ID. The recipient can get their ID with /linkid.';
        issue_parts := regexp_match(argument, '^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})[[:space:]]+([1-9][0-9]{0,17})$', 'i');
        IF issue_parts IS NOT NULL THEN
            recipient_id := issue_parts[2]::bigint;
            SELECT patient_id INTO target_patient FROM p1_telegram.patients WHERE patient_id = issue_parts[1]::uuid FOR NO KEY UPDATE;
            IF FOUND THEN
                UPDATE p1_telegram.link_codes SET closed_at = now()
                WHERE bot_id = p_bot_id AND patient_id = target_patient AND closed_at IS NULL;
                plain_code := replace(gen_random_uuid()::text, '-', '');
                INSERT INTO p1_telegram.link_codes (bot_id, code_hash, patient_id, expires_at, recipient_telegram_id)
                VALUES (p_bot_id, sha256(convert_to(plain_code, 'UTF8')), target_patient, now() + interval '10 minutes', recipient_id);
                event := 'code_issued';
                reply_text := 'Test code expires in 10 minutes. Give the intended test patient this command: /link ' || plain_code;
            END IF;
        END IF;
    ELSIF (SELECT count(*) FROM p1_telegram.link_audit a
           WHERE a.bot_id = p_bot_id AND a.telegram_user_id = entry.telegram_user_id
             AND a.recorded_at > now() - interval '15 minutes'
             AND a.action IN ('link_rejected','link_redeemed')) >= 5 THEN
        event := 'link_rate_limited';
        reply_text := 'Too many attempts. Wait 15 minutes and try again.';
    ELSE
        event := 'link_rejected';
        reply_text := 'That link code could not be used. Ask reception for a fresh code, then send /link followed by the new code.';
        IF argument ~* '^[0-9a-f]{32}$' AND EXISTS (
            SELECT 1 FROM p1_telegram.registration_consent
            WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
              AND notice_version = 'demo-v2' AND decision IS TRUE
            FOR UPDATE
        ) THEN
            -- Use the same patient-then-code lock order as issuance and withdrawal.
            PERFORM p.patient_id FROM p1_telegram.patients p
            JOIN p1_telegram.link_codes c USING (patient_id)
            WHERE c.bot_id = p_bot_id AND c.code_hash = sha256(convert_to(lower(argument), 'UTF8'))
              AND c.recipient_telegram_id = entry.telegram_user_id
            FOR NO KEY UPDATE OF p;
            UPDATE p1_telegram.link_codes SET closed_at = now()
            WHERE bot_id = p_bot_id AND code_hash = sha256(convert_to(lower(argument), 'UTF8'))
              AND recipient_telegram_id = entry.telegram_user_id
              AND closed_at IS NULL AND expires_at > now()
            RETURNING patient_id INTO target_patient;
            IF FOUND THEN

                INSERT INTO p1_telegram.patient_links (bot_id, telegram_user_id, patient_id, selected)
                VALUES (p_bot_id, entry.telegram_user_id, target_patient, NOT EXISTS (
                    SELECT FROM p1_telegram.patient_links
                    WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id AND selected
                ))
                ON CONFLICT (bot_id, telegram_user_id, patient_id) DO NOTHING;
                DELETE FROM p1_telegram.registration_drafts d
                WHERE d.bot_id = p_bot_id AND d.telegram_user_id = entry.telegram_user_id AND d.step = 'review'
                  AND target_patient = (
                    SELECT a.existing_patient_id FROM p1_telegram.duplicate_dispositions a
                    WHERE a.review_reference = d.review_reference ORDER BY a.recorded_at DESC LIMIT 1
                  );
                event := 'link_redeemed';
                reply_text := 'This Telegram account has access to the test profile. Send /profiles to see all linked profiles and choose which one to use.';
            END IF;
        END IF;
    END IF;

    INSERT INTO p1_telegram.link_audit (bot_id, update_id, telegram_user_id, action)
    VALUES (p_bot_id, p_update_id, entry.telegram_user_id, event);
    UPDATE p1_telegram.inbox SET status = 'done', payload = '{}'::jsonb
    WHERE bot_id = p_bot_id AND update_id = p_update_id;
    chat_id := entry.telegram_user_id::text;
    RETURN NEXT;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.apply_patient_registration(p_bot_id bigint, p_update_id bigint)
 RETURNS TABLE(chat_id text, reply_text text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    entry p1_telegram.inbox%ROWTYPE;
    draft p1_telegram.registration_drafts%ROWTYPE;
    message_text text;
    command text;
    field_value text;
    next_step text;
    new_patient_id uuid;
    matches uuid[];
    disposition p1_telegram.duplicate_dispositions%ROWTYPE;
    needs_review text;
BEGIN
    SELECT * INTO entry FROM p1_telegram.inbox
    WHERE bot_id = p_bot_id AND update_id = p_update_id AND status = 'pending'
    FOR UPDATE;
    IF NOT FOUND THEN RETURN; END IF;

    message_text := btrim(entry.payload #>> '{message,text}', E' \t\r\n');
    command := substring(message_text FROM '^(/[a-z]+)(?:[[:space:]]|$)');
    IF message_text IS NULL OR message_text = ''
        OR (left(message_text, 1) = '/' AND (command IS NULL OR
            command NOT IN ('/profile', '/newprofile', '/name', '/dob', '/phone', '/skipphone', '/confirm', '/restartprofile'))) THEN
        RETURN;
    END IF;
    field_value := btrim(regexp_replace(substr(message_text, length(command) + 1), '[[:space:]]+', ' ', 'g'));

    PERFORM 1 FROM p1_telegram.registration_consent
    WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
      AND notice_version = 'demo-v2' AND decision IS TRUE
    FOR UPDATE;

    IF left(message_text, 1) <> '/' THEN
        IF NOT FOUND THEN RETURN; END IF;
        SELECT CASE step WHEN 'name' THEN '/name' WHEN 'dob' THEN '/dob' WHEN 'phone' THEN '/phone' END
        INTO command
        FROM p1_telegram.registration_drafts
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
          AND expires_at > now();
        IF command IS NULL THEN RETURN; END IF;
        field_value := regexp_replace(message_text, '[[:space:]]+', ' ', 'g');
    END IF;

    IF NOT FOUND THEN
        reply_text := 'First send /register to read the consent notice. Then choose I agree to continue with test registration.';
    ELSIF command IS DISTINCT FROM '/newprofile'
      AND EXISTS (
        SELECT FROM p1_telegram.patient_links
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
      )
      AND NOT EXISTS (
        SELECT FROM p1_telegram.registration_drafts
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
          AND expires_at > now()
      ) THEN
        reply_text := 'Your account is already linked. Send /newprofile to register another test profile, /profiles to switch profiles, or /link followed by a code to link an existing profile.';
    ELSE
        DELETE FROM p1_telegram.registration_drafts
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
          AND expires_at <= now();

        IF command = '/restartprofile' AND field_value = '' THEN
            DELETE FROM p1_telegram.registration_drafts
            WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;
        END IF;

        IF (command IN ('/profile', '/newprofile', '/restartprofile') AND field_value = '') THEN
            INSERT INTO p1_telegram.registration_drafts (bot_id, telegram_user_id, expires_at, step)
            VALUES (p_bot_id, entry.telegram_user_id, now() + interval '30 minutes', 'name')
            ON CONFLICT (bot_id, telegram_user_id) DO NOTHING;
        END IF;

        SELECT * INTO draft FROM p1_telegram.registration_drafts
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
        FOR UPDATE;
        needs_review := 'Possible duplicate. Give reception reference ' || draft.review_reference ||
            ' to verify your identity. If it is your existing profile, use a reception link code. If reception clears this as a distinct patient, send /confirm again. Use /cancelregistration to discard the draft or /restartprofile to re-enter your details.';

        IF command = '/phone' AND field_value ~ '^01[0125][0-9]{8}$' THEN
            field_value := '+20' || substr(field_value, 2);
        END IF;

        IF NOT FOUND THEN
            reply_text := 'Send /profile to start a test profile.';
        ELSIF draft.step = 'review' AND (command <> '/confirm' OR field_value <> '') THEN
            reply_text := needs_review;
        ELSIF draft.step = 'name' AND command = '/name'
              AND char_length(field_value) BETWEEN 2 AND 100
              AND field_value !~ '^[0-9 ]+$' THEN
            draft.full_name := field_value;
            next_step := 'dob';
        ELSIF draft.step = 'dob' AND command = '/dob'
              AND field_value ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
              AND pg_input_is_valid(substr(field_value, 7, 4) || '-' || substr(field_value, 4, 2) || '-' || left(field_value, 2), 'date') THEN
            draft.date_of_birth := (substr(field_value, 7, 4) || '-' || substr(field_value, 4, 2) || '-' || left(field_value, 2))::date;
            IF draft.date_of_birth BETWEEN DATE '1900-01-01' AND (now() AT TIME ZONE 'Africa/Cairo')::date THEN
                next_step := 'phone';
            END IF;
        ELSIF draft.step = 'phone' AND (
            (command = '/phone' AND field_value ~ '^\+[1-9][0-9]{7,14}$')
            OR (command = '/skipphone' AND field_value = '')
        ) THEN
            draft.phone_e164 := nullif(field_value, '');
            next_step := 'confirm';
        ELSIF draft.step IN ('confirm', 'review') AND command = '/confirm' AND field_value = '' THEN
            -- Serialize matching with patient creation for this small test database.
            LOCK TABLE p1_telegram.patients IN SHARE ROW EXCLUSIVE MODE;
            matches := p1_telegram.draft_matches(draft);
            IF draft.step = 'review' THEN
                SELECT * INTO disposition FROM p1_telegram.duplicate_dispositions
                WHERE review_reference = draft.review_reference ORDER BY recorded_at DESC LIMIT 1;
            END IF;
            IF draft.step = 'confirm' AND cardinality(matches) > 0 THEN
                next_step := 'review';
                UPDATE p1_telegram.registration_drafts SET expires_at = now() + interval '24 hours'
                WHERE review_reference = draft.review_reference;
            ELSIF draft.step = 'review' AND (disposition.review_reference IS NULL OR
                    disposition.existing_patient_id IS NOT NULL OR disposition.matched_patients <> matches) THEN
                reply_text := needs_review;
            ELSE
                INSERT INTO p1_telegram.patients (full_name, date_of_birth, phone_e164)
                VALUES (draft.full_name, draft.date_of_birth, draft.phone_e164)
                RETURNING patient_id INTO new_patient_id;
                UPDATE p1_telegram.patient_links SET selected = false
                WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id AND selected;
                DELETE FROM p1_telegram.account_confirmations
                WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;
                DELETE FROM p1_telegram.phone_edits
                WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;
                INSERT INTO p1_telegram.patient_links (bot_id, telegram_user_id, patient_id)
                VALUES (p_bot_id, entry.telegram_user_id, new_patient_id);
                DELETE FROM p1_telegram.registration_drafts
                WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;
                reply_text := 'Your test profile is saved and selected. Send /myprofile to view it or /profiles to see all profiles linked to this Telegram account.';
            END IF;
        END IF;

        IF next_step IS NOT NULL THEN
            UPDATE p1_telegram.registration_drafts
            SET step = next_step, full_name = draft.full_name,
                date_of_birth = draft.date_of_birth, phone_e164 = draft.phone_e164
            WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;
        END IF;

        IF reply_text IS NULL THEN
            reply_text := CASE coalesce(next_step, draft.step)
                WHEN 'name' THEN 'Step 1 of 3. Type a made-up full name, such as Demo Patient. You can also send /cancelregistration to discard this draft.'
                WHEN 'dob' THEN 'Step 2 of 3. Type a made-up date of birth in day/month/year format, such as 12/04/1995.'
                WHEN 'phone' THEN 'Type a test phone number to finish step 3 of 3. Egyptian mobile numbers can start with 010, 011, 012, or 015. Tap Skip phone number or send /skipphone to continue without one.'
                WHEN 'confirm' THEN concat_ws(E'\n',
                    'Review your test profile',
                    'Name: ' || draft.full_name,
                    'Date of birth: ' || to_char(draft.date_of_birth, 'DD/MM/YYYY'),
                    'Phone: ' || coalesce('ending in ' || right(draft.phone_e164, 4), 'skipped'),
                    'If the details look right, tap Save my profile or send /confirm. Send /restartprofile to re-enter your details or /cancelregistration to discard the draft.')
                WHEN 'review' THEN needs_review
            END;
        END IF;
    END IF;

    -- The processed inbox receipt keeps its update ID for deduplication.
    UPDATE p1_telegram.inbox SET status = 'done', payload = '{}'::jsonb
    WHERE bot_id = p_bot_id AND update_id = p_update_id;
    chat_id := entry.telegram_user_id::text;
    RETURN NEXT;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.apply_registration_consent(p_bot_id bigint, p_update_id bigint)
 RETURNS TABLE(chat_id text, reply_text text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    entry p1_telegram.inbox%ROWTYPE;
    command text;
    consent_decision boolean;
BEGIN
    SELECT * INTO entry FROM p1_telegram.inbox
    WHERE bot_id = p_bot_id AND update_id = p_update_id AND status = 'pending' FOR UPDATE;
    IF NOT FOUND THEN RETURN; END IF;
    command := btrim(entry.payload #>> '{message,text}');

    IF command = '/register' THEN
        INSERT INTO p1_telegram.registration_consent AS consent
            (bot_id, telegram_user_id, notice_version)
        VALUES (p_bot_id, entry.telegram_user_id, 'demo-v2')
        ON CONFLICT (bot_id, telegram_user_id) DO UPDATE
        SET notice_version = EXCLUDED.notice_version, decision = NULL, decided_at = NULL
        WHERE consent.notice_version <> 'demo-v2' OR consent.decision IS FALSE;
        SELECT decision INTO consent_decision FROM p1_telegram.registration_consent
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;

        reply_text := CASE WHEN consent_decision IS TRUE THEN
            'Your consent for the current notice is saved. Send /commands or use /withdrawtelegram to withdraw it.'
        ELSE concat_ws(E'\n\n',
            'ClinicOS test registration',
            'Demo notice v2. Use made-up details only. Local Postgres stores Telegram links, your consent choice, test profile and booking details, and short-lived messages and receipts for retries.',
            'The worker copies your profile name, date of birth, optional phone, profile identifier, and default Telegram contact (chat ID, user ID and link time) to the shared ClinicOS Demo Supabase database. Reception can see requests it needs to review.',
            'Send /agree to enable Telegram access or /decline to stop. Existing links are paused until you accept this notice.',
            'Use /unlinktelegram for one selected profile, /withdrawtelegram to withdraw consent and remove all your links on this bot, or /requestdeletion to ask reception to review the selected clinic record. Withdrawal queues a shared contact refresh. Clinic records and appointments stay on file.')
        END;
    ELSIF command IN ('/agree', '/decline') THEN
        UPDATE p1_telegram.registration_consent
        SET decision = (command = '/agree'), decided_at = now()
        WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id
          AND notice_version = 'demo-v2' AND decision IS NULL
        RETURNING decision INTO consent_decision;
        IF NOT FOUND THEN
            reply_text := 'Send /register to check consent or /withdrawtelegram to withdraw existing consent.';
        ELSIF consent_decision THEN
            DELETE FROM p1_telegram.withdrawal_confirmations
            WHERE bot_id = p_bot_id AND telegram_user_id = entry.telegram_user_id;
            reply_text := 'Consent saved. Send /profiles for existing links, /profile to create a test profile, or /link CODE to redeem a verified reception code.';
        ELSE
            reply_text := 'Registration stopped and linked Telegram access remains paused. Use /withdrawtelegram to remove your links or /register to read the notice again.';
        END IF;
    ELSE
        RETURN;
    END IF;

    UPDATE p1_telegram.inbox SET status = 'done', payload = '{}'
    WHERE bot_id = p_bot_id AND update_id = p_update_id;
    chat_id := entry.telegram_user_id::text;
    RETURN NEXT;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.available_commands(actor_bot bigint, actor_user bigint)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    consent boolean;
    linked uuid;
    draft_step text;
    account_action text;
    staff_role text;
    patient_commands text;
    linked_draft_commands text;
    staff_commands text;
    owner_commands text;
BEGIN
    SELECT decision INTO consent FROM p1_telegram.registration_consent
    WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND notice_version = 'demo-v2';

    IF consent IS TRUE THEN
        SELECT patient_id INTO linked FROM p1_telegram.patient_links
        WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND selected;
        IF linked IS NULL THEN
            SELECT step INTO draft_step FROM p1_telegram.registration_drafts
            WHERE bot_id = actor_bot AND telegram_user_id = actor_user
              AND expires_at > now();
            patient_commands := concat_ws(E'\n',
                '/profile — start or resume a test profile',
                CASE draft_step
                    WHEN 'name' THEN '/name NAME — enter your test name'
                    WHEN 'dob' THEN '/dob DD/MM/YYYY — enter your test date of birth'
                    WHEN 'phone' THEN '/phone NUMBER or /skipphone — finish the phone step'
                    WHEN 'confirm' THEN '/confirm — save your test profile'
                    WHEN 'review' THEN 'Use /profile for your duplicate-review reference.'
                END,
                CASE WHEN draft_step IS NOT NULL THEN '/cancelregistration — discard your draft' END,
                CASE WHEN draft_step IS NOT NULL THEN '/restartprofile — start over' END);
        ELSE

            SELECT step INTO draft_step FROM p1_telegram.registration_drafts
            WHERE bot_id = actor_bot AND telegram_user_id = actor_user
              AND expires_at > now();
            IF draft_step IS NOT NULL THEN
                linked_draft_commands := concat_ws(E'\n', 'Unfinished registration',
                    CASE draft_step
                        WHEN 'name' THEN '/name NAME — enter the test name'
                        WHEN 'dob' THEN '/dob DD/MM/YYYY — enter the test date of birth'
                        WHEN 'phone' THEN '/phone NUMBER or /skipphone — finish the phone step'
                        WHEN 'confirm' THEN '/confirm — save and select the new test profile'
                        WHEN 'review' THEN 'Use /profile for your duplicate-review reference.'
                    END,
                    '/cancelregistration — discard the unfinished draft');
            END IF;
            SELECT action INTO account_action FROM p1_telegram.account_confirmations
            WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND patient_id = linked
              AND expires_at > now();
            patient_commands := concat_ws(E'\n',
                '/myprofile — view your test profile',
                '/book NUMBER — submit a local test request for that linked profile',
                '/bookingstatus NUMBER — check the latest request for that linked profile',
                CASE WHEN (SELECT phone_edits_enabled FROM p1_telegram.account_options WHERE singleton)
                    THEN '/updatephone — get a one-time phone prompt for the selected profile' END,
                '/unlinktelegram — disconnect the selected profile',
                '/requestdeletion — ask reception to review profile deletion',
                CASE account_action
                    WHEN '/confirmunlink' THEN '/confirmunlink — finish disconnecting Telegram'
                    WHEN '/confirmdeletionrequest' THEN '/confirmdeletionrequest — submit the review request'
                END);
        END IF;
    ELSE
        patient_commands := concat_ws(E'\n', '/register — open the consent notice',
            CASE WHEN consent IS NULL AND EXISTS (
                SELECT FROM p1_telegram.registration_consent WHERE bot_id = actor_bot
                AND telegram_user_id = actor_user AND notice_version = 'demo-v2'
            ) THEN '/agree or /decline — respond to the notice' END);
    END IF;

    SELECT role INTO staff_role FROM p1_telegram.staff
    WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND active;
    IF staff_role IN ('reception', 'admin') THEN
        staff_commands := concat_ws(E'\n', 'Reception',
            '/staff — verify staff access',
            '/issue PATIENT_UUID TELEGRAM_ID — issue a link code',
            '/deletionreviews — list pending and follow-up clinic-record reviews',
            '/duplicatereviews — list open duplicate registration reviews',
            '/resolveduplicate REFERENCE existing PATIENT_UUID or distinct — record a verified disposition',
            '/recordreview REFERENCE OUTCOME REASON — record a decision. Use /deletionreviews for the format.');
    END IF;
    IF staff_role = 'admin' AND EXISTS (
        SELECT FROM p1_telegram.staff_access_owner WHERE bot_id = actor_bot AND telegram_user_id = actor_user
    ) THEN
        owner_commands := concat_ws(E'\n', 'Bot owner',
            '/managestaff — open staff access instructions',
            '/stafflist — view active teammates',
            '/addstaff ID — start granting access',
            '/removestaff ID — start revoking access',
            CASE WHEN EXISTS (
                SELECT FROM p1_telegram.staff_access_confirmation WHERE bot_id = actor_bot
                AND owner_id = actor_user AND expires_at > now()
            ) THEN '/confirmstaff or /cancelstaff — finish or cancel the pending change' END);
    END IF;

    RETURN concat_ws(E'\n\n', E'Your available commands\n/start or /help — open the bot menu\n/linkid — get your Telegram ID',
        CASE WHEN consent IS TRUE THEN E'/profiles — list linked test profiles\n/useprofile NUMBER — switch profiles\n/link CODE — add access using a reception code' END,

        CASE WHEN consent IS TRUE THEN '/newprofile — register another test profile in this chat' END,
        '/withdrawtelegram — withdraw consent and disconnect all profiles on this bot',
        linked_draft_commands, patient_commands, staff_commands, owner_commands);
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.bump_phone_sync_revision()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    NEW.profile_sync_revision := OLD.profile_sync_revision + 1;
    RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.claim_patient_sync()
 RETURNS TABLE(patient_id uuid, claim_token uuid, full_name text, date_of_birth text, phone_e164 text, created_at text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    WITH next_patient AS (
        SELECT q.patient_id FROM p1_telegram.patient_sync_queue q
        WHERE q.synced_at IS NULL AND q.available_at <= now()
        ORDER BY q.available_at, q.patient_id
        LIMIT 1 FOR UPDATE SKIP LOCKED
    ), claimed AS (
        UPDATE p1_telegram.patient_sync_queue q
        SET available_at = now() + interval '2 minutes', claim_token = gen_random_uuid()
        FROM next_patient n WHERE q.patient_id = n.patient_id
        RETURNING q.patient_id, q.claim_token
    )
    SELECT c.patient_id, c.claim_token, p.full_name, to_char(p.date_of_birth, 'YYYY-MM-DD'),
           p.phone_e164, to_char(p.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
    FROM claimed c JOIN p1_telegram.patients p USING (patient_id);
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.claim_patient_sync_v2()
 RETURNS TABLE(patient_id uuid, claim_token uuid, full_name text, date_of_birth text, phone_e164 text, created_at text, phone_revision bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    WITH next_patient AS (
        SELECT q.patient_id FROM p1_telegram.patient_sync_queue q
        WHERE q.synced_at IS NULL AND q.available_at <= now()
        ORDER BY q.available_at, q.patient_id
        LIMIT 1 FOR UPDATE SKIP LOCKED
    ), claimed AS (
        UPDATE p1_telegram.patient_sync_queue q
        SET available_at = now() + interval '2 minutes', claim_token = gen_random_uuid()
        FROM next_patient n WHERE q.patient_id = n.patient_id
        RETURNING q.patient_id, q.claim_token
    )
    SELECT c.patient_id, c.claim_token, p.full_name, to_char(p.date_of_birth, 'YYYY-MM-DD'),
           p.phone_e164, to_char(p.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
           p.phone_revision
    FROM claimed c JOIN p1_telegram.patients p USING (patient_id);
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.claim_patient_sync_v3()
 RETURNS TABLE(patient_id uuid, claim_token uuid, full_name text, date_of_birth text, phone_e164 text, created_at text, phone_revision bigint, telegram_chat_id bigint, telegram_user_id bigint, telegram_linked_at text, profile_sync_revision bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    leased_patient uuid;
    leased_token uuid;
BEGIN
    WITH next_patient AS (
        SELECT q.patient_id FROM p1_telegram.patient_sync_queue q
        WHERE q.synced_at IS NULL AND q.available_at <= now()
        ORDER BY q.available_at, q.patient_id
        LIMIT 1 FOR UPDATE SKIP LOCKED
    )
    UPDATE p1_telegram.patient_sync_queue q
    SET available_at = now() + interval '2 minutes', claim_token = gen_random_uuid()
    FROM next_patient n WHERE q.patient_id = n.patient_id
    RETURNING q.patient_id, q.claim_token INTO leased_patient, leased_token;
    IF NOT FOUND THEN RETURN; END IF;

    -- Read the profile after claiming the row so a concurrent edit that won
    -- the queue lock before the claim is visible here.
    RETURN QUERY
    SELECT p.patient_id, leased_token, p.full_name, to_char(p.date_of_birth, 'YYYY-MM-DD'),
           p.phone_e164, to_char(p.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
           p.phone_revision, primary_link.telegram_user_id, primary_link.telegram_user_id,
           to_char(primary_link.linked_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
           p.profile_sync_revision
    FROM p1_telegram.patients p
    LEFT JOIN LATERAL (
        SELECT l.telegram_user_id, l.linked_at
        FROM p1_telegram.patient_links l
        JOIN p1_telegram.registration_consent c USING (bot_id, telegram_user_id)
        WHERE l.patient_id = p.patient_id AND l.bot_id = (SELECT bot_id FROM p1_telegram.sync_scope)
          AND c.decision IS TRUE AND c.notice_version = 'demo-v2'
        ORDER BY l.linked_at NULLS FIRST, l.profile_number
        LIMIT 1
    ) primary_link ON true
    WHERE p.patient_id = leased_patient;
END
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.claim_reply(p_bot_id bigint, p_update_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(chat_id text, reply_text text, delivery_token uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    entry p1_telegram.inbox%ROWTYPE;
    reply_update_id bigint;
    command text;
    immediate_text text;
    retry_text text;
    linked_patient_id uuid;
    booking_status text;
    stale_update boolean;
    profile_name text;
    booking_input text[];
BEGIN
    IF p_update_id IS NULL THEN
        PERFORM p1_telegram.cleanup_transport();
    END IF;
    SELECT r.update_id INTO reply_update_id
    FROM p1_telegram.replies r
    WHERE r.bot_id = p_bot_id AND (p_update_id IS NULL OR r.update_id = p_update_id)
      AND r.sent_at IS NULL AND r.attempts < 3 AND r.available_at <= now()
      AND EXISTS (SELECT FROM p1_telegram.inbox i
                  WHERE (i.bot_id, i.update_id) = (r.bot_id, r.update_id)
                    AND i.received_at > now() - interval '24 hours')
    ORDER BY r.available_at, r.update_id
    LIMIT 1 FOR UPDATE SKIP LOCKED;

    IF NOT FOUND THEN
        -- Ingress and both workers lock by actor before claiming an inbox row.
        SELECT * INTO entry FROM p1_telegram.inbox i
        WHERE i.bot_id = p_bot_id AND i.status = 'pending' AND i.recovery_enabled
          AND i.received_at > now() - interval '24 hours'
          AND (i.update_id = p_update_id OR
               (p_update_id IS NULL AND i.received_at <= now() - interval '30 seconds'))
        ORDER BY i.event_at, i.update_id LIMIT 1;
        IF NOT FOUND THEN RETURN; END IF;
        IF NOT pg_try_advisory_xact_lock(hashtextextended(
            p_bot_id::text || ':link:' || entry.telegram_user_id::text, 0)) THEN RETURN; END IF;

        -- A newer immediate claim waits for recovery if an earlier event is
        -- queued. An older arrival after a newer commit is rejected.
        SELECT * INTO entry FROM p1_telegram.inbox i
        WHERE i.bot_id = p_bot_id AND i.telegram_user_id = entry.telegram_user_id
          AND i.status = 'pending' AND i.recovery_enabled
          AND i.received_at > now() - interval '24 hours' AND i.event_at IS NOT NULL
        ORDER BY i.event_at, i.update_id LIMIT 1 FOR UPDATE;
        IF NOT FOUND OR (p_update_id IS NOT NULL AND entry.update_id <> p_update_id) THEN RETURN; END IF;
        IF p_update_id IS NULL AND entry.received_at > now() - interval '30 seconds' THEN RETURN; END IF;

        SELECT EXISTS (
            SELECT FROM p1_telegram.inbox i WHERE i.bot_id = p_bot_id
              AND i.telegram_user_id = entry.telegram_user_id AND i.status = 'done'
              AND i.recovery_enabled AND (i.event_at, i.update_id) > (entry.event_at, entry.update_id)
        ) INTO stale_update;
        command := btrim(entry.payload #>> '{message,text}', E' \t\r\n');
        IF command IN ('Main menu', 'Read consent notice', 'I agree', 'I decline',
                       'Create a test profile', 'Get my Telegram ID', 'Book an appointment',
                       'Check booking status', 'My profile', 'Update phone number', 'Skip phone number', 'Save my profile', 'Start over') THEN
            command := CASE command
                WHEN 'Main menu' THEN '/help'
                WHEN 'Read consent notice' THEN '/register'
                WHEN 'I agree' THEN '/agree'
                WHEN 'I decline' THEN '/decline'
                WHEN 'Create a test profile' THEN '/profile'
                WHEN 'Get my Telegram ID' THEN '/linkid'
                WHEN 'Book an appointment' THEN '/book'
                WHEN 'Check booking status' THEN '/bookingstatus' WHEN 'My profile' THEN '/myprofile' WHEN 'Update phone number' THEN '/updatephone'
                WHEN 'Skip phone number' THEN '/skipphone'
                WHEN 'Save my profile' THEN '/confirm'
                WHEN 'Start over' THEN '/restartprofile'
            END;
            -- The command functions read the same locked inbox row.
            UPDATE p1_telegram.inbox
            SET payload = jsonb_set(payload, '{message,text}', to_jsonb(command))
            WHERE bot_id = p_bot_id AND update_id = entry.update_id;
        END IF;
        IF stale_update THEN
            immediate_text := 'This message arrived out of order and was skipped. Check /profiles and send the command again.';
        ELSIF command IN ('/withdrawtelegram', '/confirmwithdrawal') OR command ~ '^/confirmwithdrawal[[:space:]]' THEN
            immediate_text := p1_telegram.telegram_withdrawal(p_bot_id, entry.telegram_user_id, command);
        ELSIF command ~ '^/(duplicatereviews|resolveduplicate)([[:space:]]|$)' THEN
            immediate_text := p1_telegram.staff_duplicate_review(p_bot_id, entry.telegram_user_id, command);
        ELSIF command IN ('Update phone number', 'Cancel registration', 'Unlink Telegram', 'Request profile deletion',
                       '/updatephone', '/cancelregistration', '/unlinktelegram', '/confirmunlink', '/requestdeletion', '/confirmdeletionrequest')
           OR command ~ '^/(savephone|confirmdeletionrequest)([[:space:]]|$)' THEN
            immediate_text := p1_telegram.apply_account_command(p_bot_id, entry.telegram_user_id,
                CASE command
                    WHEN 'Update phone number' THEN '/updatephone'
                    WHEN 'Cancel registration' THEN '/cancelregistration'
                    WHEN 'Unlink Telegram' THEN '/unlinktelegram'
                    WHEN 'Request profile deletion' THEN '/requestdeletion'
                    ELSE command END);
        ELSIF command = '/profiles' OR command ~ '^/useprofile([[:space:]]|$)' THEN
            immediate_text := p1_telegram.select_telegram_profile(p_bot_id, entry.telegram_user_id, command);
        ELSIF command = '/commands' THEN
            immediate_text := p1_telegram.available_commands(p_bot_id, entry.telegram_user_id);
        ELSIF command ~ '^/(managestaff|stafflist|addstaff|removestaff|confirmstaff|cancelstaff)([[:space:]]|$)' THEN
            immediate_text := p1_telegram.manage_staff_access(p_bot_id, entry.telegram_user_id, command);
        ELSIF command ~ '^/(deletionreviews|recordreview)([[:space:]]|$)' THEN
            immediate_text := p1_telegram.staff_deletion_review(p_bot_id, entry.telegram_user_id, command);
        ELSIF command IN ('/start', '/help', '/myprofile') THEN
            SELECT l.patient_id INTO linked_patient_id
            FROM p1_telegram.patient_links l
            JOIN p1_telegram.registration_consent c USING (bot_id, telegram_user_id)
            WHERE l.bot_id = p_bot_id AND l.telegram_user_id = entry.telegram_user_id AND l.selected
              AND c.decision IS TRUE AND c.notice_version = 'demo-v2';

            IF command IN ('/start', '/help') THEN
                immediate_text := concat_ws(E'\n',
                    'ClinicOS test bot. Use made-up details only.',
                    '',
                    CASE WHEN linked_patient_id IS NULL THEN
                        concat_ws(E'\n',
                            'Tap Read consent notice or send /register for consent. After accepting, use /profiles for existing links or /profile to register.',
                            'Tap Get my Telegram ID if reception needs it to issue a link code.',
                            '/link followed by your code to link an existing test patient.')
                    ELSE
                        concat_ws(E'\n',
                            'Tap My profile to see who is selected. Send /newprofile to register another test profile or /profiles to switch between profiles.',
                            'Send /book to choose a profile, doctor, date and slot. Send /offers to see your current offers.')
                    END,
                    'Send /commands to see every command available to you.');
            ELSIF command = '/myprofile' THEN
                SELECT concat_ws(E'\n', 'Your test profile', 'Name: ' || p.full_name,
                    CASE WHEN p.phone_e164 IS NULL THEN 'No phone number on file.'
                         ELSE 'A phone number is on file.' END)
                INTO immediate_text
                FROM p1_telegram.patients p WHERE p.patient_id = linked_patient_id;
                immediate_text := coalesce(immediate_text, 'Choose a linked test profile with /profiles, or send /commands to see how to register or link one.');
            END IF;
        ELSIF command ~ '^/(book|bookingstatus|offers|offer|faq|feedback)([[:space:]]|$)' THEN
            immediate_text := clinicos_showcase.telegram_action(p_bot_id,entry.telegram_user_id,entry.update_id,command);
        ELSIF command IN ('/register', '/agree', '/decline') THEN
            SELECT result.reply_text INTO immediate_text
            FROM p1_telegram.apply_registration_consent(p_bot_id, entry.update_id) result;
        ELSIF command ~ '^/(profile|newprofile|name|dob|phone|skipphone|confirm|restartprofile)([[:space:]]|$)'
           OR (command <> '' AND left(command, 1) <> '/') THEN
            SELECT result.reply_text INTO immediate_text
            FROM p1_telegram.apply_patient_registration(p_bot_id, entry.update_id) result;
        ELSIF command ~ '^/(staff|issue|link|linkid)([[:space:]]|$)' THEN
            SELECT result.reply_text INTO immediate_text
            FROM p1_telegram.apply_link_command(p_bot_id, entry.update_id) result;
        END IF;

        UPDATE p1_telegram.inbox SET status = 'done', payload = '{}'::jsonb
        WHERE bot_id = p_bot_id AND update_id = entry.update_id;
        IF immediate_text IS NULL THEN RETURN; END IF;

        retry_text := CASE
            WHEN command = '/updatephone' AND immediate_text LIKE 'Update the phone for %'
                THEN 'The phone prompt may have been interrupted. Send /updatephone for a new prompt.'
            WHEN command = '/withdrawtelegram'
                THEN 'Send /withdrawtelegram for a new confirmation if you missed the previous one.'
            WHEN command ~ '^/savephone([[:space:]]|$)' AND immediate_text LIKE 'Test phone saved for %'
                THEN 'Your test phone change was saved. Send /myprofile to see the selected profile.'
            WHEN linked_patient_id IS NOT NULL AND booking_input IS NOT NULL
                THEN 'Send /bookingstatus ' || booking_input[2] || ' to check the latest request for that profile.'
            WHEN command = '/profiles' THEN 'Send /profiles again to see your current linked profiles.'
            WHEN command = '/myprofile' AND linked_patient_id IS NOT NULL
                THEN 'Tap My profile again to view your test profile.'
            ELSE immediate_text END;
        IF immediate_text LIKE 'Test code expires in 10 minutes.%' THEN
            retry_text := 'The link code reply may have been interrupted. Run /issue again if you did not receive it. Issuing again replaces the earlier code.';
        ELSIF command = '/linkid' THEN
            retry_text := 'Send /linkid again to see your Telegram ID.';
        ELSIF immediate_text LIKE 'Review your test profile%' THEN
            retry_text := 'Your test profile is ready to review. Send /profile to see it again.';
        END IF;
        INSERT INTO p1_telegram.replies (bot_id, update_id, reply_text)
        VALUES (p_bot_id, entry.update_id, retry_text);
        reply_update_id := entry.update_id;
    END IF;

    RETURN QUERY
    UPDATE p1_telegram.replies r
    SET attempts = r.attempts + 1, available_at = now() + interval '1 minute',
        claim_token = gen_random_uuid()
    FROM p1_telegram.inbox i
    WHERE r.bot_id = p_bot_id AND r.update_id = reply_update_id
      AND (i.bot_id, i.update_id) = (r.bot_id, r.update_id)
    RETURNING i.telegram_user_id::text, coalesce(immediate_text, r.reply_text), r.claim_token;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.claim_welcome_update(p_bot_id bigint)
 RETURNS TABLE(chat_id text, claim_token uuid)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    WITH candidate AS (
        SELECT item.bot_id, item.update_id
        FROM p1_telegram.inbox AS item
        WHERE item.bot_id = p_bot_id
          AND item.payload #>> '{message,text}' = '/start'
          AND (item.status = 'pending'
               OR (item.status = 'processing' AND item.lease_until <= now()))
        ORDER BY item.received_at, item.update_id
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    UPDATE p1_telegram.inbox AS item
    SET status = 'processing',
        claim_token = gen_random_uuid(),
        lease_until = now() + interval '2 minutes'
    FROM candidate
    WHERE (item.bot_id, item.update_id) = (candidate.bot_id, candidate.update_id)
    RETURNING item.telegram_user_id::text, item.claim_token;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.claim_welcome_update(p_bot_id bigint, p_update_id bigint)
 RETURNS TABLE(chat_id text, claim_token uuid)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    UPDATE p1_telegram.inbox AS item
    SET status = 'processing',
        claim_token = gen_random_uuid(),
        lease_until = now() + interval '2 minutes'
    WHERE item.bot_id = p_bot_id
      AND item.update_id = p_update_id
      AND item.payload #>> '{message,text}' = '/start'
      AND item.status = 'pending'
    RETURNING item.telegram_user_id::text, item.claim_token;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.cleanup_transport()
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    -- Quarantine the old pending rows outside recovery. Keep the receipt.
    UPDATE p1_telegram.inbox
    SET status = CASE WHEN status = 'done' THEN 'done' ELSE 'failed' END,
        payload = '{}', claim_token = NULL, lease_until = NULL
    WHERE (status = 'done' AND payload <> '{}')
       OR (status = 'pending' AND recovery_enabled IS NOT TRUE)
       OR (status IN ('pending', 'processing') AND received_at <= now() - interval '24 hours');

    UPDATE p1_telegram.replies r SET reply_text = '', claim_token = NULL, attempts = greatest(r.attempts, 3)
    FROM p1_telegram.inbox i
    WHERE (i.bot_id, i.update_id) = (r.bot_id, r.update_id)
      AND r.sent_at IS NULL AND r.available_at <= now()
      AND (r.attempts >= 3 OR i.received_at <= now() - interval '24 hours')
      AND (r.reply_text <> '' OR r.claim_token IS NOT NULL);
    DELETE FROM p1_telegram.replies r USING p1_telegram.inbox i
    WHERE (r.bot_id, r.update_id) = (i.bot_id, i.update_id)
      AND i.received_at <= now() - interval '7 days';
    DELETE FROM p1_telegram.inbox WHERE received_at <= now() - interval '7 days';
    DELETE FROM p1_telegram.registration_drafts WHERE expires_at <= now();
    DELETE FROM p1_telegram.phone_edits WHERE expires_at <= now();
    DELETE FROM p1_telegram.withdrawal_confirmations WHERE expires_at <= now();
    DELETE FROM p1_telegram.account_confirmations WHERE expires_at <= now();
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.complete_patient_sync(p_patient_id uuid, p_claim_token uuid)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    WITH completed AS (
        UPDATE p1_telegram.patient_sync_queue
        SET synced_at = now(), claim_token = NULL
        WHERE patient_id = p_patient_id AND claim_token = p_claim_token AND synced_at IS NULL
        RETURNING patient_id
    )
    SELECT EXISTS (SELECT 1 FROM completed);
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.complete_reply(p_bot_id bigint, p_delivery_token uuid, p_message_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    IF p_message_id IS NULL OR p_message_id <= 0 THEN
        RAISE EXCEPTION 'Telegram reply confirmation was missing';
    END IF;
    UPDATE p1_telegram.replies
    SET sent_at = now(), message_id = p_message_id, claim_token = NULL, reply_text = ''
    WHERE bot_id = p_bot_id AND claim_token = p_delivery_token AND sent_at IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Telegram reply claim is unavailable'; END IF;
    RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.complete_staff_sync(p_batch jsonb)
 RETURNS bigint
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    WITH acknowledged AS (
        UPDATE p1_telegram.staff_sync_queue q
        SET synced_revision = q.revision
        FROM jsonb_to_recordset(p_batch) AS sent(id uuid, sync_revision bigint)
        JOIN p1_telegram.sync_scope s ON true
        WHERE q.staff_id = sent.id AND q.bot_id = s.bot_id
          AND q.revision = sent.sync_revision AND q.synced_revision < q.revision
        RETURNING q.staff_id
    )
    SELECT count(*) FROM acknowledged;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.complete_welcome_update(p_bot_id bigint, p_claim_token uuid, p_message_id bigint)
 RETURNS TABLE(update_id text, completed boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    IF p_message_id IS NULL OR p_message_id <= 0 THEN
        RAISE EXCEPTION 'A Telegram reply message ID is required';
    END IF;

    RETURN QUERY
    UPDATE p1_telegram.inbox AS item
    SET status = 'done', replied_at = now(), reply_message_id = p_message_id,
        claim_token = NULL, lease_until = NULL
    WHERE item.bot_id = p_bot_id
      AND item.status = 'processing'
      AND item.claim_token = p_claim_token
      AND item.lease_until > now()
    RETURNING item.update_id::text, true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Telegram update claim is unavailable';
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.configured_bot_id()
 RETURNS bigint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$ SELECT bot_id FROM p1_telegram.sync_scope $function$;

CREATE OR REPLACE FUNCTION p1_telegram.draft_matches(draft p1_telegram.registration_drafts)
 RETURNS uuid[]
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
    SELECT coalesce(array_agg(p.patient_id ORDER BY p.patient_id), '{}'::uuid[])
    FROM p1_telegram.patients p
    WHERE p.date_of_birth = draft.date_of_birth
      AND (lower(p.full_name) = lower(draft.full_name) OR p.phone_e164 = draft.phone_e164)
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.enqueue_patient_sync()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    INSERT INTO p1_telegram.patient_sync_queue (patient_id) VALUES (NEW.patient_id);
    RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.manage_staff_access(actor_bot bigint, actor_id bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    action text := split_part(regexp_replace(command, '[[:space:]]+', ' ', 'g'), ' ', 1);
    target_text text := btrim(substr(command, length(action) + 1));
    confirmation p1_telegram.staff_access_confirmation%ROWTYPE;
    staff_list text;
BEGIN
    PERFORM 1 FROM p1_telegram.staff_access_owner o
    JOIN p1_telegram.staff s USING (bot_id, telegram_user_id)
    WHERE o.bot_id = actor_bot AND o.telegram_user_id = actor_id
      AND s.active AND s.role = 'admin'
    FOR UPDATE OF o FOR SHARE OF s;
    IF NOT FOUND THEN RETURN 'This command is available only to the ClinicOS bot owner.'; END IF;

    CASE action
        WHEN '/managestaff' THEN
            RETURN concat_ws(E'\n', 'Manage staff', '/stafflist to view active teammates.',
                '/addstaff followed by their Telegram ID to grant reception access.',
                '/removestaff followed by their Telegram ID to revoke access.',
                'Ask teammates to use /linkid in this bot to get their ID.');
        WHEN '/stafflist' THEN
            SELECT string_agg(telegram_user_id::text || ' | ' || role, E'\n' ORDER BY telegram_user_id)
            INTO staff_list
            FROM p1_telegram.staff
            WHERE bot_id = actor_bot AND active AND telegram_user_id <> actor_id;
            RETURN coalesce('Active teammates' || E'\n' || staff_list, 'No teammates have staff access.');
        WHEN '/cancelstaff' THEN
            DELETE FROM p1_telegram.staff_access_confirmation
            WHERE bot_id = actor_bot AND owner_id = actor_id;
            RETURN 'Staff access change canceled. Send /managestaff to reopen the menu.';
        WHEN '/confirmstaff' THEN
            DELETE FROM p1_telegram.staff_access_confirmation
            WHERE bot_id = actor_bot AND owner_id = actor_id AND expires_at > now()
            RETURNING * INTO confirmation;
            IF NOT FOUND THEN RETURN 'No staff access change is awaiting confirmation. Send /managestaff to start.'; END IF;
            IF confirmation.action = '/addstaff' THEN
                INSERT INTO p1_telegram.staff (bot_id, telegram_user_id, role, active)
                VALUES (actor_bot, confirmation.target_id, 'reception', true)
                ON CONFLICT (bot_id, telegram_user_id) DO UPDATE SET active = true;
                RETURN 'Staff access is active. Ask your teammate to send /staff to verify it or /commands to see what they can do.';
            END IF;
            UPDATE p1_telegram.staff SET active = false
            WHERE bot_id = actor_bot AND telegram_user_id = confirmation.target_id AND active;
            IF NOT FOUND THEN RETURN 'That Telegram account has no active staff access.'; END IF;
            RETURN 'Staff access revoked for that account. Send /stafflist to see who still has access.';
        WHEN '/addstaff', '/removestaff' THEN
            IF target_text !~ '^[1-9][0-9]{0,15}$' THEN
                RETURN 'Send ' || action || ' followed by the numeric Telegram ID from /linkid.';
            END IF;
            IF target_text::bigint = actor_id THEN
                RETURN 'Your owner account is managed in the local database.';
            END IF;
            INSERT INTO p1_telegram.staff_access_confirmation
                (bot_id, owner_id, target_id, action, expires_at)
            VALUES (actor_bot, actor_id, target_text::bigint, action, now() + interval '5 minutes')
            ON CONFLICT (bot_id) DO UPDATE SET owner_id = EXCLUDED.owner_id,
                target_id = EXCLUDED.target_id, action = EXCLUDED.action, expires_at = EXCLUDED.expires_at;
            RETURN CASE action WHEN '/addstaff' THEN 'Activate staff access for Telegram ID '
                                ELSE 'Revoke staff access for Telegram ID ' END
                || target_text || '? Send /confirmstaff within 5 minutes, or /cancelstaff.';
        ELSE
            RETURN 'Send /managestaff for staff access options.';
    END CASE;
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.pending_staff_sync()
 RETURNS TABLE(staff_batch jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    SELECT jsonb_agg(jsonb_build_object(
        'id', q.staff_id, 'role', q.role, 'is_active', q.is_active,
        'created_at', q.created_at, 'sync_revision', q.revision,
        'name', CASE WHEN q.is_active THEN q.staff_name END,
        'telegram_user_id', CASE WHEN q.is_active AND q.telegram_user_id > 0 THEN q.telegram_user_id END
    ) ORDER BY q.staff_id)
    FROM p1_telegram.staff_sync_queue q
    JOIN p1_telegram.sync_scope s USING (bot_id)
    WHERE q.synced_revision < q.revision
    HAVING count(*) > 0;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.queue_phone_edit()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    INSERT INTO p1_telegram.patient_sync_queue (patient_id)
    VALUES (NEW.patient_id)
    ON CONFLICT (patient_id) DO UPDATE
    SET available_at = now(), synced_at = NULL, claim_token = NULL;
    RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.queue_staff_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    IF TG_OP = 'DELETE' THEN
        NEW := OLD;
        NEW.active := false;
    END IF;

    INSERT INTO p1_telegram.staff_sync_queue AS queued
        (bot_id, telegram_user_id, role, is_active)
    VALUES (NEW.bot_id, NEW.telegram_user_id, NEW.role, NEW.active)
    ON CONFLICT (bot_id, telegram_user_id) DO UPDATE
    SET role = EXCLUDED.role, is_active = EXCLUDED.is_active,
        revision = queued.revision + 1
    WHERE (queued.role, queued.is_active) IS DISTINCT FROM
          (EXCLUDED.role, EXCLUDED.is_active);
    RETURN NULL;
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.queue_telegram_link_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM p1_telegram.refresh_shared_contact(OLD.patient_id, OLD.bot_id);
    ELSE
        PERFORM p1_telegram.refresh_shared_contact(NEW.patient_id, NEW.bot_id);
    END IF;
    RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.receive_staff_aware_update(p_bot_id bigint, p_update jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    receipt jsonb := p1_telegram.receive_update(p_bot_id, p_update);
    event jsonb;
    sender jsonb;
    display_name text;
    seen_at timestamptz;
BEGIN
    IF receipt->>'inserted' IS DISTINCT FROM 'true' THEN
        RETURN receipt;
    END IF;
    event := COALESCE(p_update->'callback_query', p_update->'message');
    sender := event->'from';
    seen_at := to_timestamp((event->>'date')::bigint);
    display_name := nullif(left(btrim(regexp_replace(
        concat_ws(' ', sender->>'first_name', sender->>'last_name'),
        '[[:space:][:cntrl:]]+', ' ', 'g')), 120), '');
    IF display_name IS NOT NULL THEN
        UPDATE p1_telegram.staff_sync_queue
        SET staff_name = display_name, staff_name_seen_at = seen_at,
            revision = revision + (staff_name IS DISTINCT FROM display_name)::integer
        WHERE bot_id = p_bot_id AND telegram_user_id = (sender->>'id')::bigint
          AND is_active
          AND (staff_name_seen_at IS NULL OR staff_name_seen_at < seen_at);
    END IF;
    RETURN receipt;
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.receive_update(p_bot_id bigint, p_update jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    event jsonb;
    chat jsonb;
    update_id bigint;
    sender_id bigint;
    event_at timestamptz;
BEGIN
    IF p_bot_id IS NULL OR p_bot_id <= 0 THEN
        RAISE EXCEPTION 'Telegram bot identity is unconfigured';
    END IF;

    IF p_update ? 'callback_query' THEN
        event := p_update -> 'callback_query';
        chat := event #> '{message,chat}';
    ELSE
        event := p_update -> 'message';
        chat := event -> 'chat';
    END IF;

    IF (chat ->> 'type') IS DISTINCT FROM 'private'
        OR (event #> '{from,is_bot}') IS DISTINCT FROM 'false'::jsonb
        OR (p_update ->> 'update_id') IS NULL
        OR (p_update ->> 'update_id') !~ '^[0-9]{1,18}$'
        OR (event #>> '{from,id}') IS NULL
        OR (event #>> '{from,id}') !~ '^[1-9][0-9]{0,17}$'
        OR (chat ->> 'id') IS DISTINCT FROM (event #>> '{from,id}')
    THEN
        RETURN jsonb_build_object('accepted', false, 'inserted', false);
    END IF;

    update_id := (p_update ->> 'update_id')::bigint;
    sender_id := (event #>> '{from,id}')::bigint;
    IF event ->> 'date' IS NULL OR (event ->> 'date') !~ '^[0-9]{1,10}$'
       OR jsonb_typeof(event -> 'text') IS DISTINCT FROM 'string' THEN
        RETURN jsonb_build_object('accepted', false, 'inserted', false);
    END IF;
    event_at := to_timestamp((event ->> 'date')::bigint);
    IF event_at < now() - interval '24 hours' OR event_at > now() + interval '5 minutes' THEN
        RETURN jsonb_build_object('accepted', false, 'inserted', false);
    END IF;

    PERFORM pg_advisory_xact_lock(hashtextextended(p_bot_id::text || ':link:' || sender_id::text, 0));
    INSERT INTO p1_telegram.inbox (bot_id, update_id, telegram_user_id, event_at, payload)
    VALUES (p_bot_id, update_id, sender_id, event_at,
            jsonb_build_object('message', jsonb_build_object('text', event ->> 'text')))
    ON CONFLICT ON CONSTRAINT inbox_pkey DO NOTHING;
    RETURN jsonb_build_object('accepted', true, 'inserted', FOUND, 'update_id', update_id);
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.record_workflow_error(p_source text)
 RETURNS uuid
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
    INSERT INTO p1_telegram.workflow_errors (source)
    VALUES (CASE WHEN p_source IN ('ingress', 'smoke_test') THEN p_source ELSE 'unknown' END)
    RETURNING error_id;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.refresh_consent_contacts()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    -- Revoke the previous queue lease and publish a newer revision whenever
    -- eligibility changes, even when the link itself stays in place.
    IF (OLD.notice_version = 'demo-v2' AND OLD.decision IS TRUE)
       IS DISTINCT FROM (NEW.notice_version = 'demo-v2' AND NEW.decision IS TRUE) THEN
        PERFORM p1_telegram.refresh_shared_contact(l.patient_id, NEW.bot_id)
        FROM p1_telegram.patient_links l
        WHERE l.bot_id = NEW.bot_id AND l.telegram_user_id = NEW.telegram_user_id
        ORDER BY l.patient_id;
    END IF;
    RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.refresh_shared_contact(affected_patient uuid, affected_bot bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    IF NOT EXISTS (SELECT FROM p1_telegram.sync_scope WHERE bot_id = affected_bot) THEN
        RETURN;
    END IF;
    UPDATE p1_telegram.patients SET profile_sync_revision = profile_sync_revision + 1
    WHERE patient_id = affected_patient;
    INSERT INTO p1_telegram.patient_sync_queue (patient_id) VALUES (affected_patient)
    ON CONFLICT (patient_id) DO UPDATE
    SET available_at = now(), synced_at = NULL, claim_token = NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.select_telegram_profile(actor_bot bigint, actor_id bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    options text;
    option_number text;
    chosen_patient uuid;
BEGIN
    IF NOT EXISTS (
        SELECT FROM p1_telegram.registration_consent
        WHERE bot_id = actor_bot AND telegram_user_id = actor_id
          AND notice_version = 'demo-v2' AND decision IS TRUE
    ) THEN
        RETURN 'Send /register to read the consent notice before opening linked profiles.';
    END IF;

    IF command = '/profiles' THEN
        SELECT string_agg(profile_number::text || '. ' || full_name ||
                   CASE WHEN selected THEN ' (current)' ELSE '' END, E'\n' ORDER BY profile_number)
        INTO options
        FROM (
            SELECT l.profile_number, l.selected, p.full_name
            FROM p1_telegram.patient_links l JOIN p1_telegram.patients p USING (patient_id)
            WHERE l.bot_id = actor_bot AND l.telegram_user_id = actor_id
            ORDER BY l.profile_number LIMIT 20
        ) AS linked;
        IF options IS NULL THEN RETURN 'No test profiles are linked. Send /commands to see how to register or use a reception code.'; END IF;
        RETURN 'Your linked test profiles' || E'\n' || options ||
            E'\nSend /useprofile followed by a profile number to choose who you want to act for.';
    END IF;

    option_number := btrim(substr(command, length('/useprofile') + 1));
    IF option_number !~ '^[1-9][0-9]{0,17}$' THEN
        RETURN 'Send /profiles to see your linked profiles, then send /useprofile followed by its number.';
    END IF;
    SELECT patient_id INTO chosen_patient FROM p1_telegram.patient_links
    WHERE bot_id = actor_bot AND telegram_user_id = actor_id AND profile_number = option_number::bigint;
    IF NOT FOUND THEN RETURN 'That profile is unavailable. Send /profiles to see profiles linked to this Telegram account.'; END IF;

    UPDATE p1_telegram.patient_links SET selected = false
    WHERE bot_id = actor_bot AND telegram_user_id = actor_id AND selected AND patient_id <> chosen_patient;
    IF FOUND THEN
        DELETE FROM p1_telegram.account_confirmations WHERE bot_id = actor_bot AND telegram_user_id = actor_id;
        DELETE FROM p1_telegram.phone_edits WHERE bot_id = actor_bot AND telegram_user_id = actor_id;
    END IF;
    UPDATE p1_telegram.patient_links SET selected = true
    WHERE bot_id = actor_bot AND telegram_user_id = actor_id AND patient_id = chosen_patient AND NOT selected;
    RETURN 'Profile selected. Send /myprofile to confirm whose profile is open before you book or change account settings.';
END $function$;

CREATE OR REPLACE FUNCTION p1_telegram.staff_deletion_review(actor_bot bigint, actor_user bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    review_input text[];
    decision text;
    explanation text;
    open_list text;
    request p1_telegram.deletion_requests%ROWTYPE;
BEGIN
    PERFORM 1 FROM p1_telegram.staff
    WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND active AND role IN ('reception', 'admin')
    FOR SHARE;
    IF NOT FOUND THEN RETURN 'This command requires active reception or admin access.'; END IF;

    IF command = '/deletionreviews' THEN
        SELECT string_agg(review_reference::text || ' | ' || coalesce(review_outcome, 'pending') || ' | ' ||
            to_char(requested_at AT TIME ZONE 'Africa/Cairo', 'YYYY-MM-DD HH24:MI') ||
            E'\nPatient reason: ' || coalesce(patient_reason, 'No reason given'),
            E'\n' ORDER BY requested_at, review_reference) INTO open_list
        FROM (
            SELECT review_reference, requested_at, patient_reason, review_outcome
            FROM p1_telegram.deletion_requests WHERE review_outcome IS DISTINCT FROM 'closed'
            ORDER BY requested_at, review_reference LIMIT 10
        ) AS open_reviews;
        IF open_list IS NULL THEN RETURN 'No pending or follow-up deletion reviews.'; END IF;
        RETURN 'Open deletion reviews (first 10, Cairo time)' || E'\n' || open_list ||
               E'\nUse /recordreview REFERENCE followup REASON or /recordreview REFERENCE closed REASON. Use the same reference to close a follow-up.';
    END IF;

    review_input := regexp_match(command,
        '^/recordreview[[:space:]]+([0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12})[[:space:]]+(followup|closed)[[:space:]]+(.+)$', 'i');
    decision := lower(review_input[2]);
    explanation := btrim(regexp_replace(review_input[3], '[[:space:]]+', ' ', 'g'));
    IF explanation IS NULL OR char_length(explanation) NOT BETWEEN 1 AND 240 THEN
        RETURN 'Use /recordreview REFERENCE followup REASON or /recordreview REFERENCE closed REASON. Give a reason of 1 to 240 characters.';
    END IF;
    SELECT * INTO request FROM p1_telegram.deletion_requests WHERE review_reference = review_input[1]::uuid FOR UPDATE;
    IF NOT FOUND THEN RETURN 'No review matches that reference.'; END IF;
    IF request.review_outcome = decision THEN RETURN 'This review is already marked ' || decision || '.'; END IF;
    IF request.review_outcome = 'closed' THEN RETURN 'This review is already closed.'; END IF;
    UPDATE p1_telegram.deletion_requests
    SET reviewed_at = clock_timestamp(), reviewed_by_bot_id = actor_bot, reviewed_by_telegram_id = actor_user,
        review_outcome = decision, review_reason = explanation
    WHERE review_reference = request.review_reference RETURNING * INTO request;
    INSERT INTO p1_telegram.deletion_review_history
        (review_reference, reviewed_at, reviewer_bot_id, reviewer_user_id, outcome, reason)
    VALUES (request.review_reference, request.reviewed_at, actor_bot, actor_user, decision, explanation);
    RETURN CASE decision WHEN 'followup' THEN
        'Review marked for follow-up. Use the same reference to close it after reception follows up.'
        ELSE 'Review closed. The clinic profile and appointments stay on file.' END;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.staff_duplicate_review(actor_bot bigint, actor_user bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    review_input text[];
    draft p1_telegram.registration_drafts%ROWTYPE;
    matches uuid[];
    existing_patient uuid;
    open_list text;
BEGIN
    PERFORM 1 FROM p1_telegram.staff
    WHERE bot_id = actor_bot AND telegram_user_id = actor_user AND active AND role IN ('reception', 'admin')
    FOR SHARE;
    IF NOT FOUND THEN RETURN 'This command requires active reception or admin access.'; END IF;

    IF command = '/duplicatereviews' THEN
        SELECT string_agg(review_reference::text || ' | ' || to_char(expires_at AT TIME ZONE 'Africa/Cairo', 'YYYY-MM-DD HH24:MI'), E'\n'
                          ORDER BY expires_at, review_reference)
        INTO open_list
        FROM (
            SELECT d.review_reference, d.expires_at FROM p1_telegram.registration_drafts d
            WHERE d.bot_id = actor_bot AND d.step = 'review' AND d.expires_at > now()
            ORDER BY d.expires_at, d.review_reference LIMIT 10
        ) AS open_reviews;
        RETURN coalesce('Open duplicate reviews (first 10, expiry in Cairo time)' || E'\n' || open_list,
                        'No open duplicate reviews.') ||
            E'\nVerify identity with reception. Use /resolveduplicate REFERENCE existing PATIENT_UUID or /resolveduplicate REFERENCE distinct.';
    END IF;

    review_input := regexp_match(command, '^/resolveduplicate[[:space:]]+([0-9a-f-]{36})[[:space:]]+(existing|distinct)(?:[[:space:]]+([0-9a-f-]{36}))?$');
    IF review_input IS NULL OR NOT pg_input_is_valid(review_input[1], 'uuid') OR
       (review_input[2] = 'existing' AND (review_input[3] IS NULL OR NOT pg_input_is_valid(review_input[3], 'uuid'))) OR
       (review_input[2] = 'distinct' AND review_input[3] IS NOT NULL) THEN
        RETURN 'Use /resolveduplicate REFERENCE existing PATIENT_UUID or /resolveduplicate REFERENCE distinct.';
    END IF;
    SELECT * INTO draft FROM p1_telegram.registration_drafts
    WHERE review_reference = review_input[1]::uuid AND bot_id = actor_bot
      AND step = 'review' AND expires_at > now()
    FOR UPDATE;
    IF NOT FOUND THEN RETURN 'No open duplicate review matches that reference.'; END IF;

    matches := p1_telegram.draft_matches(draft);
    existing_patient := review_input[3]::uuid;
    IF existing_patient IS NOT NULL AND NOT (existing_patient = ANY(matches)) THEN
        RETURN 'The supplied profile is outside this draft''s current match results.';
    END IF;
    IF EXISTS (
        SELECT FROM p1_telegram.duplicate_dispositions a
        WHERE a.review_reference = draft.review_reference
          AND a.recorded_at = (SELECT max(b.recorded_at) FROM p1_telegram.duplicate_dispositions b
                               WHERE b.review_reference = draft.review_reference)
          AND a.existing_patient_id IS NOT DISTINCT FROM existing_patient AND a.matched_patients = matches
    ) THEN
        RETURN 'That disposition is already recorded.';
    END IF;

    INSERT INTO p1_telegram.duplicate_dispositions
        (review_reference, reviewer_bot_id, reviewer_user_id, existing_patient_id, matched_patients)
    VALUES (draft.review_reference, actor_bot, actor_user, existing_patient, matches);
    RETURN CASE WHEN existing_patient IS NULL THEN
        'Distinct test patient recorded. Ask them to send /confirm before the draft expires.'
        ELSE 'Existing profile recorded. Verify the recipient''s Telegram account privately and use /issue PATIENT_UUID TELEGRAM_ID. The patient must redeem the code.' END;
END;
$function$;

CREATE OR REPLACE FUNCTION p1_telegram.telegram_withdrawal(actor_bot bigint, actor_user bigint, command text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    proof text;
    confirmation uuid;
BEGIN
    IF command = '/withdrawtelegram' THEN
        INSERT INTO p1_telegram.withdrawal_confirmations AS c (bot_id, telegram_user_id, expires_at)
        VALUES (actor_bot, actor_user, now() + interval '10 minutes')
        ON CONFLICT (bot_id, telegram_user_id) DO UPDATE
        SET token = EXCLUDED.token, expires_at = EXCLUDED.expires_at
        RETURNING token INTO confirmation;
        RETURN 'This withdraws consent and disconnects every profile linked to this Telegram account on this bot. Clinic records and appointments stay on file. Send /confirmwithdrawal ' || confirmation || ' within 10 minutes.';
    END IF;
    proof := substring(command FROM '^/confirmwithdrawal[[:space:]]+([0-9a-f-]{36})$');
    IF proof IS NULL OR NOT pg_input_is_valid(proof, 'uuid') THEN
        RETURN 'Send /withdrawtelegram to get a new confirmation.';
    END IF;
    DELETE FROM p1_telegram.withdrawal_confirmations
    WHERE bot_id = actor_bot AND telegram_user_id = actor_user
      AND token = proof::uuid AND expires_at > now();
    IF NOT FOUND THEN RETURN 'That withdrawal prompt is no longer active. Send /withdrawtelegram to start again.'; END IF;

    -- Lock shared patients in UUID order before link-removal triggers run.
    PERFORM p.patient_id FROM p1_telegram.patients p
    JOIN p1_telegram.patient_links l USING (patient_id)
    WHERE l.bot_id = actor_bot AND l.telegram_user_id = actor_user
    ORDER BY p.patient_id FOR NO KEY UPDATE OF p;
    DELETE FROM p1_telegram.patient_links WHERE bot_id = actor_bot AND telegram_user_id = actor_user;
    DELETE FROM p1_telegram.registration_drafts WHERE bot_id = actor_bot AND telegram_user_id = actor_user;
    DELETE FROM p1_telegram.account_confirmations WHERE bot_id = actor_bot AND telegram_user_id = actor_user;
    UPDATE p1_telegram.link_codes SET closed_at = now()
    WHERE bot_id = actor_bot AND recipient_telegram_id = actor_user AND closed_at IS NULL;
    INSERT INTO p1_telegram.registration_consent (bot_id, telegram_user_id, notice_version, decision, decided_at)
    VALUES (actor_bot, actor_user, 'demo-v2', false, now())
    ON CONFLICT (bot_id, telegram_user_id) DO UPDATE
    SET notice_version = EXCLUDED.notice_version, decision = false, decided_at = now();
    RETURN 'Telegram consent withdrawn and all your profile links on this bot disconnected. Clinic records and appointments stay on file. Shared contact updates are queued.';
END;
$function$;

CREATE OR REPLACE FUNCTION p5_private.generate_invoice(p_request text, p_actor uuid, p_visit uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE prior p5_private.requests%ROWTYPE; payload jsonb; result jsonb;
BEGIN
 IF NOT p5_private.is_demo_admin(p_actor) THEN RETURN jsonb_build_object('ok',false,'code','FORBIDDEN','data',null,'message','Access denied'); END IF;
 IF p_request IS NULL OR btrim(p_request)='' OR length(p_request)>200 OR p_visit IS NULL THEN RETURN jsonb_build_object('ok',false,'code','VALIDATION_ERROR','data',null,'message','Required input missing'); END IF;
 payload:=jsonb_build_object('visit_id',p_visit);
 PERFORM pg_advisory_xact_lock(hashtextextended('p5-request:'||p_request,0));
 SELECT * INTO prior FROM p5_private.requests WHERE request_id=p_request;
 IF FOUND THEN
  IF prior.actor_id IS DISTINCT FROM p_actor OR prior.action <> 'invoice.create' OR prior.payload <> payload THEN RETURN jsonb_build_object('ok',false,'code','REQUEST_CONFLICT','data',null,'message','Request key reused'); END IF;
  RETURN prior.result;
 END IF;
 result:=clinic.create_invoice(p_request,p_actor,p_visit);
 INSERT INTO p5_private.requests(request_id,actor_id,action,payload,result) VALUES(p_request,p_actor,'invoice.create',payload,result);
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION p5_private.get_service(p_actor uuid, p_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE s clinic.services%ROWTYPE;
BEGIN
 IF NOT p5_private.is_demo_admin(p_actor) THEN RETURN jsonb_build_object('ok',false,'code','FORBIDDEN','data',null,'message','Access denied'); END IF;
 SELECT * INTO s FROM clinic.services WHERE service_code=p_code;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','NOT_FOUND','data',null,'message','Service not found'); END IF;
 RETURN jsonb_build_object('ok',true,'code','SERVICE_FOUND','data',jsonb_build_object('service_code',s.service_code,'name',s.name,'price',to_char(s.price,'FM9999999990.00'),'active',s.active),'message','Service found');
END $function$;

CREATE OR REPLACE FUNCTION p5_private.is_demo_admin(p_actor uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
 SELECT EXISTS (
 SELECT 1 FROM p5_private.demo_actors a
 WHERE a.actor_id=p_actor AND a.role='admin' AND a.active AND
 (a.login_role=session_user OR (
 session_user='authenticator' AND (
 (current_setting('role',true)='p5_demo_runtime'
 AND (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role')='p5_demo_runtime'
 AND (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')=p_actor::text)
 OR (current_setting('role',true)='authenticated' AND a.auth_user_id IS NOT NULL
 AND (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role')='authenticated'
 AND (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')=a.auth_user_id::text)
 ))))
$function$;

CREATE OR REPLACE FUNCTION p5_private.save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE oldrow clinic.services%ROWTYPE; prior p5_private.requests%ROWTYPE; payload jsonb; result jsonb; before_value jsonb;
BEGIN
 IF NOT p5_private.is_demo_admin(p_actor) THEN RETURN jsonb_build_object('ok',false,'code','FORBIDDEN','data',null,'message','Access denied'); END IF;
 IF p_request IS NULL OR btrim(p_request)='' OR length(p_request)>200 THEN RETURN jsonb_build_object('ok',false,'code','VALIDATION_ERROR','data',null,'message','Invalid request ID'); END IF;
 payload := jsonb_build_object('action',p_action,'code',p_code,'name',p_name,'price',p_price,'active',p_active);
 PERFORM pg_advisory_xact_lock(hashtextextended('p5-request:'||p_request,0));
 SELECT * INTO prior FROM p5_private.requests WHERE request_id=p_request;
 IF FOUND THEN
  IF prior.actor_id IS DISTINCT FROM p_actor OR prior.action <> 'service.save' OR prior.payload <> payload THEN RETURN jsonb_build_object('ok',false,'code','REQUEST_CONFLICT','data',null,'message','Request key reused'); END IF;
  RETURN prior.result;
 END IF;
 IF p_action IS NULL OR p_action NOT IN ('create','update') OR p_code IS NULL OR btrim(p_code)='' OR length(p_code)>100 OR p_name IS NULL OR btrim(p_name)='' OR length(p_name)>200 OR p_active IS NULL OR (CASE WHEN p_price ~ '^[0-9]{1,10}(\.[0-9]{1,2})?$' THEN p_price::numeric > 9999999999.99 ELSE true END) THEN
  result:=jsonb_build_object('ok',false,'code','VALIDATION_ERROR','data',null,'message','Invalid service details');
  INSERT INTO p5_private.requests(request_id,actor_id,action,payload,result) VALUES(p_request,p_actor,'service.save',payload,result);
  RETURN result;
 END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('p5-service:'||p_code,0));
 SELECT * INTO oldrow FROM clinic.services WHERE service_code=p_code FOR UPDATE;
 IF p_action='create' AND FOUND THEN result:=jsonb_build_object('ok',false,'code','ALREADY_EXISTS','data',null,'message','Service code already exists');
 ELSIF p_action='update' AND NOT FOUND THEN result:=jsonb_build_object('ok',false,'code','NOT_FOUND','data',null,'message','Service not found');
 ELSE
  IF p_action='create' THEN
   INSERT INTO clinic.services(service_code,name,price,active) VALUES(p_code,p_name,p_price::numeric,p_active) RETURNING * INTO oldrow;
  ELSE
   before_value := to_jsonb(oldrow);
   UPDATE clinic.services SET name=p_name,price=p_price::numeric,active=p_active WHERE service_code=p_code RETURNING * INTO oldrow;
  END IF;
  result:=jsonb_build_object('ok',true,'code',CASE WHEN p_action='create' THEN 'SERVICE_CREATED' ELSE 'SERVICE_UPDATED' END,'data',jsonb_build_object('service_code',oldrow.service_code,'name',oldrow.name,'price',to_char(oldrow.price,'FM9999999990.00'),'active',oldrow.active),'message','Service saved');
 END IF;
 INSERT INTO p5_private.requests(request_id,actor_id,action,payload,before_state,result) VALUES(p_request,p_actor,'service.save',payload,before_value,result);
 RETURN result;
END $function$;

RESET check_function_bodies;

-- Constraints and indexes

ALTER TABLE public.appointments ADD CONSTRAINT appointments_no_overlap EXCLUDE USING gist (doctor_id WITH =, appointment_date WITH =, tsrange(appointment_date + start_time, appointment_date + end_time, '[)'::text) WITH &&) WHERE (status <> 'cancelled'::public.appointment_status);

ALTER TABLE public.appointments ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);

ALTER TABLE public.available_slot_events ADD CONSTRAINT available_slot_events_check CHECK (end_time > start_time);

ALTER TABLE public.available_slot_events ADD CONSTRAINT available_slot_events_event_key_key UNIQUE (event_key);

ALTER TABLE public.available_slot_events ADD CONSTRAINT available_slot_events_event_type_check CHECK (event_type = ANY (ARRAY['cancelled'::text, 'rescheduled'::text]));

ALTER TABLE public.available_slot_events ADD CONSTRAINT available_slot_events_pkey PRIMARY KEY (id);

ALTER TABLE public.available_slot_events ADD CONSTRAINT available_slot_events_status_check CHECK (status = ANY (ARRAY['pending'::text, 'processing'::text, 'offered'::text, 'no_match'::text]));

ALTER TABLE public.booking_requests ADD CONSTRAINT booking_requests_pkey PRIMARY KEY (id);

ALTER TABLE public.booking_requests ADD CONSTRAINT booking_requests_valid_time CHECK (end_time > start_time) NOT VALID;

ALTER TABLE public.booking_requests ADD CONSTRAINT valid_appointment_date CHECK (appointment_date >= CURRENT_DATE);

ALTER TABLE public.booking_requests ADD CONSTRAINT valid_booking_time CHECK (end_time > start_time);

ALTER TABLE public.cancellation_requests ADD CONSTRAINT cancellation_requests_pkey PRIMARY KEY (id);

ALTER TABLE public.doctor_schedules ADD CONSTRAINT doctor_schedules_day_of_week_check CHECK (day_of_week >= 0 AND day_of_week <= 6);

ALTER TABLE public.doctor_schedules ADD CONSTRAINT doctor_schedules_pkey PRIMARY KEY (id);

ALTER TABLE public.notification_outbox ADD CONSTRAINT notification_outbox_event_type_check CHECK (event_type = 'waiting_list_offer'::text);

ALTER TABLE public.notification_outbox ADD CONSTRAINT notification_outbox_offer_id_event_type_key UNIQUE (offer_id, event_type);

ALTER TABLE public.notification_outbox ADD CONSTRAINT notification_outbox_pkey PRIMARY KEY (id);

ALTER TABLE public.notification_outbox ADD CONSTRAINT notification_outbox_status_check CHECK (status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text]));

ALTER TABLE public.performed_services ADD CONSTRAINT performed_services_pkey PRIMARY KEY (id);

ALTER TABLE public.performed_services ADD CONSTRAINT performed_services_quantity_check CHECK (quantity >= 1);

ALTER TABLE public.performed_services ADD CONSTRAINT performed_services_visit_id_service_code_key UNIQUE (visit_id, service_code);

ALTER TABLE public.rescheduling_requests ADD CONSTRAINT rescheduling_requests_pkey PRIMARY KEY (id);

ALTER TABLE public.rescheduling_requests ADD CONSTRAINT rescheduling_valid_time CHECK (new_end_time > new_start_time);

ALTER TABLE public.visit_attachments ADD CONSTRAINT visit_attachments_pkey PRIMARY KEY (id);

ALTER TABLE public.visit_attachments ADD CONSTRAINT visit_attachments_visit_id_checksum_key UNIQUE (visit_id, checksum);

ALTER TABLE public.visit_revisions ADD CONSTRAINT visit_revisions_pkey PRIMARY KEY (id);

ALTER TABLE public.visit_revisions ADD CONSTRAINT visit_revisions_revision_no_check CHECK (revision_no >= 1);

ALTER TABLE public.visit_revisions ADD CONSTRAINT visit_revisions_visit_id_revision_no_key UNIQUE (visit_id, revision_no);

ALTER TABLE public.visit_revisions ADD CONSTRAINT visit_revisions_visit_revno_unique UNIQUE (visit_id, revision_no);

ALTER TABLE public.visits ADD CONSTRAINT visits_appointment_id_key UNIQUE (appointment_id);

ALTER TABLE public.visits ADD CONSTRAINT visits_pkey PRIMARY KEY (id);

ALTER TABLE public.visits ADD CONSTRAINT visits_status_check CHECK (status = ANY (ARRAY['open'::text, 'finalized'::text]));

ALTER TABLE public.wait_list ADD CONSTRAINT waiting_list_pkey PRIMARY KEY (id);

ALTER TABLE public.wait_list ADD CONSTRAINT waiting_list_preferred_time_check CHECK (preferred_start_time IS NULL AND preferred_end_time IS NULL OR preferred_start_time IS NOT NULL AND preferred_end_time IS NOT NULL AND preferred_end_time > preferred_start_time);

ALTER TABLE public.waiting_list ADD CONSTRAINT waiting_list_pkey1 PRIMARY KEY (id);

ALTER TABLE public.waiting_list_offers ADD CONSTRAINT waiting_list_offers_check CHECK (end_time > start_time);

ALTER TABLE public.waiting_list_offers ADD CONSTRAINT waiting_list_offers_pkey PRIMARY KEY (id);

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_performed_service_id_key UNIQUE (performed_service_id);

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_quantity_check CHECK (quantity > 0);

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_unit_price_check CHECK (unit_price >= 0::numeric AND unit_price <= 9999999999.99 AND scale(unit_price) <= 2);

ALTER TABLE clinic.invoices ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);

ALTER TABLE clinic.invoices ADD CONSTRAINT invoices_request_id_check CHECK (btrim(request_id) <> ''::text);

ALTER TABLE clinic.invoices ADD CONSTRAINT invoices_request_id_key UNIQUE (request_id);

ALTER TABLE clinic.invoices ADD CONSTRAINT invoices_visit_id_key UNIQUE (visit_id);

ALTER TABLE clinic.p4_demo_faq ADD CONSTRAINT p4_demo_faq_pkey PRIMARY KEY (faq_id);

ALTER TABLE clinic.p4_faq_pending_handoff ADD CONSTRAINT p4_faq_pending_handoff_pkey PRIMARY KEY (chat_id, message_id);

ALTER TABLE clinic.p4_faq_pending_handoff ADD CONSTRAINT p4_faq_pending_handoff_question_check CHECK (char_length(question) >= 1 AND char_length(question) <= 4096);

ALTER TABLE clinic.p4_notification_outbox ADD CONSTRAINT p4_notification_outbox_event_id_event_version_recipient_ref_key UNIQUE (event_id, event_version, recipient_ref, template_key, due_at);

ALTER TABLE clinic.p4_notification_outbox ADD CONSTRAINT p4_notification_outbox_event_version_check CHECK (event_version > 0);

ALTER TABLE clinic.p4_notification_outbox ADD CONSTRAINT p4_notification_outbox_pkey PRIMARY KEY (id);

ALTER TABLE clinic.p4_notification_outbox ADD CONSTRAINT p4_notification_outbox_state_check CHECK (state = ANY (ARRAY['pending'::text, 'claimed'::text, 'suppressed'::text, 'accepted'::text, 'failed'::text, 'delivery_unknown'::text]));

ALTER TABLE clinic.p4_notification_outbox ADD CONSTRAINT p4_notification_outbox_template_key_check CHECK (template_key = ANY (ARRAY['booking_confirmed'::text, 'appointment_reminder'::text, 'no_show_follow_up'::text, 'feedback_request'::text, 'waiting_list_offer'::text, 'visit_follow_up'::text]));

ALTER TABLE clinic.p4_waiting_offer_claims ADD CONSTRAINT p4_waiting_offer_claims_decision_check CHECK (decision = ANY (ARRAY['eligible'::text, 'suppressed'::text]));

ALTER TABLE clinic.p4_waiting_offer_claims ADD CONSTRAINT p4_waiting_offer_claims_pkey PRIMARY KEY (offer_id);

ALTER TABLE clinic.payments ADD CONSTRAINT payments_amount_check CHECK (amount > 0::numeric AND amount <= 9999999999.99 AND scale(amount) <= 2 AND amount <> 'NaN'::numeric);

ALTER TABLE clinic.payments ADD CONSTRAINT payments_method_check CHECK (btrim(method) <> ''::text);

ALTER TABLE clinic.payments ADD CONSTRAINT payments_pkey PRIMARY KEY (id);

ALTER TABLE clinic.payments ADD CONSTRAINT payments_request_id_check CHECK (btrim(request_id) <> ''::text);

ALTER TABLE clinic.payments ADD CONSTRAINT payments_request_id_key UNIQUE (request_id);

ALTER TABLE clinic.services ADD CONSTRAINT services_name_check CHECK (btrim(name) <> ''::text);

ALTER TABLE clinic.services ADD CONSTRAINT services_pkey PRIMARY KEY (id);

ALTER TABLE clinic.services ADD CONSTRAINT services_price_check CHECK (price >= 0::numeric AND price <= 9999999999.99 AND scale(price) <= 2 AND price <> 'NaN'::numeric);

ALTER TABLE clinic.services ADD CONSTRAINT services_service_code_check CHECK (btrim(service_code) <> ''::text);

ALTER TABLE clinic.services ADD CONSTRAINT services_service_code_key UNIQUE (service_code);

ALTER TABLE clinic.setup_probe ADD CONSTRAINT setup_probe_marker_check CHECK (marker = 'clinicos-setup-fictional'::text);

ALTER TABLE clinic.setup_probe ADD CONSTRAINT setup_probe_pkey PRIMARY KEY (marker);

ALTER TABLE clinicos_identity.patients ADD CONSTRAINT patients_date_of_birth_check CHECK (date_of_birth >= '1900-01-01'::date);

ALTER TABLE clinicos_identity.patients ADD CONSTRAINT patients_full_name_check CHECK (char_length(btrim(full_name)) >= 2 AND char_length(btrim(full_name)) <= 100);

ALTER TABLE clinicos_identity.patients ADD CONSTRAINT patients_phone_e164_check CHECK (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'::text);

ALTER TABLE clinicos_identity.patients ADD CONSTRAINT patients_phone_revision_check CHECK (phone_revision >= 0);

ALTER TABLE clinicos_identity.patients ADD CONSTRAINT patients_pkey PRIMARY KEY (id);

ALTER TABLE clinicos_identity.staff ADD CONSTRAINT staff_name_check CHECK (char_length(btrim(name)) >= 1 AND char_length(btrim(name)) <= 120);

ALTER TABLE clinicos_identity.staff ADD CONSTRAINT staff_pkey PRIMARY KEY (id);

ALTER TABLE clinicos_identity.staff ADD CONSTRAINT staff_role_check CHECK (role = ANY (ARRAY['reception'::text, 'doctor'::text, 'billing'::text, 'admin'::text]));

ALTER TABLE clinicos_identity.staff ADD CONSTRAINT staff_sync_revision_check CHECK (sync_revision >= 0);

ALTER TABLE clinicos_identity.staff ADD CONSTRAINT staff_telegram_user_id_check CHECK (telegram_user_id > 0);

ALTER TABLE clinicos_showcase.feedback ADD CONSTRAINT feedback_pkey PRIMARY KEY (visit_id);

ALTER TABLE clinicos_showcase.feedback ADD CONSTRAINT feedback_score_check CHECK (score >= 1 AND score <= 5);

ALTER TABLE clinicos_showcase.followups ADD CONSTRAINT followups_appointment_id_key UNIQUE (appointment_id);

ALTER TABLE clinicos_showcase.followups ADD CONSTRAINT followups_pkey PRIMARY KEY (visit_id);

ALTER TABLE clinicos_showcase.handoffs ADD CONSTRAINT handoffs_pkey PRIMARY KEY (id);

ALTER TABLE clinicos_showcase.handoffs ADD CONSTRAINT handoffs_source_key_key UNIQUE (source_key);

ALTER TABLE clinicos_showcase.invoice_queue ADD CONSTRAINT invoice_queue_pkey PRIMARY KEY (visit_id);

ALTER TABLE clinicos_showcase.patient_auth ADD CONSTRAINT patient_auth_patient_id_key UNIQUE (patient_id);

ALTER TABLE clinicos_showcase.patient_auth ADD CONSTRAINT patient_auth_pkey PRIMARY KEY (auth_user_id);

ALTER TABLE clinicos_showcase.settings ADD CONSTRAINT settings_id_check CHECK (id);

ALTER TABLE clinicos_showcase.settings ADD CONSTRAINT settings_pkey PRIMARY KEY (id);

ALTER TABLE clinicos_showcase.staff_auth ADD CONSTRAINT staff_auth_pkey PRIMARY KEY (auth_user_id);

ALTER TABLE clinicos_showcase.staff_auth ADD CONSTRAINT staff_auth_staff_id_key UNIQUE (staff_id);

ALTER TABLE clinicos_showcase.summary_drafts ADD CONSTRAINT summary_drafts_pkey PRIMARY KEY (id);

ALTER TABLE clinicos_showcase.summary_drafts ADD CONSTRAINT summary_drafts_state_check CHECK (state = ANY (ARRAY['draft'::text, 'approved'::text, 'rejected'::text]));

ALTER TABLE clinicos_showcase.summary_drafts ADD CONSTRAINT summary_drafts_text_check CHECK (length(text) >= 1 AND length(text) <= 12000);

ALTER TABLE clinicos_staff_private.file_delivery ADD CONSTRAINT file_delivery_pkey PRIMARY KEY (attachment_id);

ALTER TABLE clinicos_staff_private.file_delivery ADD CONSTRAINT file_delivery_state_check CHECK (state = ANY (ARRAY['sending'::text, 'accepted'::text, 'failed'::text, 'delivery_unknown'::text]));

ALTER TABLE p1_telegram.account_confirmations ADD CONSTRAINT account_confirmations_action_check CHECK (action = ANY (ARRAY['/confirmunlink'::text, '/confirmdeletionrequest'::text]));

ALTER TABLE p1_telegram.account_confirmations ADD CONSTRAINT account_confirmations_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.account_options ADD CONSTRAINT account_options_pkey PRIMARY KEY (singleton);

ALTER TABLE p1_telegram.account_options ADD CONSTRAINT account_options_singleton_check CHECK (singleton);

ALTER TABLE p1_telegram.deletion_requests ADD CONSTRAINT deletion_requests_patient_reason_check CHECK (char_length(patient_reason) >= 1 AND char_length(patient_reason) <= 240);

ALTER TABLE p1_telegram.deletion_requests ADD CONSTRAINT deletion_requests_pkey PRIMARY KEY (review_reference);

ALTER TABLE p1_telegram.deletion_requests ADD CONSTRAINT deletion_requests_review_outcome_check CHECK (review_outcome = ANY (ARRAY['followup'::text, 'closed'::text]));

ALTER TABLE p1_telegram.deletion_requests ADD CONSTRAINT deletion_requests_review_reason_check CHECK (char_length(review_reason) >= 1 AND char_length(review_reason) <= 240);

ALTER TABLE p1_telegram.deletion_review_history ADD CONSTRAINT deletion_review_history_outcome_check CHECK (outcome = ANY (ARRAY['followup'::text, 'closed'::text]));

ALTER TABLE p1_telegram.deletion_review_history ADD CONSTRAINT deletion_review_history_pkey PRIMARY KEY (review_reference, outcome);

ALTER TABLE p1_telegram.duplicate_dispositions ADD CONSTRAINT duplicate_dispositions_pkey PRIMARY KEY (review_reference, recorded_at);

ALTER TABLE p1_telegram.inbox ADD CONSTRAINT inbox_bot_id_check CHECK (bot_id > 0);

ALTER TABLE p1_telegram.inbox ADD CONSTRAINT inbox_pkey PRIMARY KEY (bot_id, update_id);

ALTER TABLE p1_telegram.inbox ADD CONSTRAINT inbox_status_check CHECK (status = ANY (ARRAY['pending'::text, 'processing'::text, 'done'::text, 'failed'::text]));

ALTER TABLE p1_telegram.inbox ADD CONSTRAINT inbox_telegram_user_id_check CHECK (telegram_user_id > 0);

ALTER TABLE p1_telegram.inbox ADD CONSTRAINT inbox_update_id_check CHECK (update_id >= 0);

ALTER TABLE p1_telegram.link_audit ADD CONSTRAINT link_audit_pkey PRIMARY KEY (bot_id, update_id);

ALTER TABLE p1_telegram.link_codes ADD CONSTRAINT link_codes_pkey PRIMARY KEY (bot_id, code_hash);

ALTER TABLE p1_telegram.link_codes ADD CONSTRAINT link_codes_recipient_telegram_id_check CHECK (recipient_telegram_id > 0);

ALTER TABLE p1_telegram.patient_links ADD CONSTRAINT patient_links_pkey PRIMARY KEY (bot_id, telegram_user_id, patient_id);

ALTER TABLE p1_telegram.patient_links ADD CONSTRAINT patient_links_profile_number_key UNIQUE (profile_number);

ALTER TABLE p1_telegram.patient_sync_queue ADD CONSTRAINT patient_sync_queue_pkey PRIMARY KEY (patient_id);

ALTER TABLE p1_telegram.patients ADD CONSTRAINT patients_date_of_birth_check CHECK (date_of_birth >= '1900-01-01'::date);

ALTER TABLE p1_telegram.patients ADD CONSTRAINT patients_full_name_check CHECK (char_length(full_name) >= 2 AND char_length(full_name) <= 100);

ALTER TABLE p1_telegram.patients ADD CONSTRAINT patients_phone_e164_check CHECK (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'::text);

ALTER TABLE p1_telegram.patients ADD CONSTRAINT patients_pkey PRIMARY KEY (patient_id);

ALTER TABLE p1_telegram.phone_edits ADD CONSTRAINT phone_edits_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.registration_consent ADD CONSTRAINT registration_consent_check CHECK ((decision IS NULL) = (decided_at IS NULL));

ALTER TABLE p1_telegram.registration_consent ADD CONSTRAINT registration_consent_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.registration_drafts ADD CONSTRAINT registration_drafts_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.registration_drafts ADD CONSTRAINT registration_drafts_step_check CHECK (step = ANY (ARRAY['name'::text, 'dob'::text, 'phone'::text, 'confirm'::text, 'review'::text]));

ALTER TABLE p1_telegram.replies ADD CONSTRAINT replies_pkey PRIMARY KEY (bot_id, update_id);

ALTER TABLE p1_telegram.staff ADD CONSTRAINT staff_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.staff ADD CONSTRAINT staff_role_check CHECK (role = ANY (ARRAY['reception'::text, 'admin'::text, 'doctor'::text, 'billing'::text]));

ALTER TABLE p1_telegram.staff_access_confirmation ADD CONSTRAINT staff_access_confirmation_action_check CHECK (action = ANY (ARRAY['/addstaff'::text, '/removestaff'::text]));

ALTER TABLE p1_telegram.staff_access_confirmation ADD CONSTRAINT staff_access_confirmation_pkey PRIMARY KEY (bot_id);

ALTER TABLE p1_telegram.staff_access_owner ADD CONSTRAINT staff_access_owner_pkey PRIMARY KEY (bot_id);

ALTER TABLE p1_telegram.staff_sync_queue ADD CONSTRAINT staff_sync_queue_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.staff_sync_queue ADD CONSTRAINT staff_sync_queue_role_check CHECK (role = ANY (ARRAY['reception'::text, 'doctor'::text, 'billing'::text, 'admin'::text]));

ALTER TABLE p1_telegram.staff_sync_queue ADD CONSTRAINT staff_sync_queue_staff_id_key UNIQUE (staff_id);

ALTER TABLE p1_telegram.sync_scope ADD CONSTRAINT sync_scope_bot_id_check CHECK (bot_id > 0);

ALTER TABLE p1_telegram.sync_scope ADD CONSTRAINT sync_scope_pkey PRIMARY KEY (singleton);

ALTER TABLE p1_telegram.sync_scope ADD CONSTRAINT sync_scope_singleton_check CHECK (singleton);

ALTER TABLE p1_telegram.test_booking_requests ADD CONSTRAINT test_booking_requests_check CHECK (end_time > start_time);

ALTER TABLE p1_telegram.test_booking_requests ADD CONSTRAINT test_booking_requests_idempotency_key_key UNIQUE (idempotency_key);

ALTER TABLE p1_telegram.test_booking_requests ADD CONSTRAINT test_booking_requests_pkey PRIMARY KEY (id);

ALTER TABLE p1_telegram.test_booking_requests ADD CONSTRAINT test_booking_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'processing'::text, 'confirmed'::text, 'failed'::text])) AND (status = 'confirmed'::text) = (appointment_id IS NOT NULL));

ALTER TABLE p1_telegram.withdrawal_confirmations ADD CONSTRAINT withdrawal_confirmations_pkey PRIMARY KEY (bot_id, telegram_user_id);

ALTER TABLE p1_telegram.workflow_errors ADD CONSTRAINT workflow_errors_error_code_check CHECK (error_code = 'E_INTERNAL'::text);

ALTER TABLE p1_telegram.workflow_errors ADD CONSTRAINT workflow_errors_pkey PRIMARY KEY (error_id);

ALTER TABLE p1_telegram.workflow_errors ADD CONSTRAINT workflow_errors_source_check CHECK (source = ANY (ARRAY['ingress'::text, 'smoke_test'::text, 'unknown'::text]));

ALTER TABLE p4_demo.booking_confirmation ADD CONSTRAINT booking_confirmation_booking_status_check CHECK (booking_status = ANY (ARRAY['booked'::text, 'cancelled'::text]));

ALTER TABLE p4_demo.booking_confirmation ADD CONSTRAINT booking_confirmation_delivery_status_check CHECK (delivery_status = ANY (ARRAY['pending'::text, 'dispatching'::text, 'accepted'::text, 'failed'::text, 'delivery_unknown'::text]));

ALTER TABLE p4_demo.booking_confirmation ADD CONSTRAINT booking_confirmation_pkey PRIMARY KEY (id);

ALTER TABLE p4_demo.notification_recipient ADD CONSTRAINT notification_recipient_pkey PRIMARY KEY (recipient_ref);

ALTER TABLE p5_private.demo_actors ADD CONSTRAINT demo_actors_actor_id_key UNIQUE (actor_id);

ALTER TABLE p5_private.demo_actors ADD CONSTRAINT demo_actors_auth_user_id_key UNIQUE (auth_user_id);

ALTER TABLE p5_private.demo_actors ADD CONSTRAINT demo_actors_pkey PRIMARY KEY (login_role);

ALTER TABLE p5_private.demo_actors ADD CONSTRAINT demo_actors_role_check CHECK (role = 'admin'::text);

ALTER TABLE p5_private.requests ADD CONSTRAINT requests_pkey PRIMARY KEY (request_id);

CREATE INDEX idx_available_slot_events_pending ON public.available_slot_events USING btree (status, created_at);

CREATE INDEX idx_booking_requests_appointment ON public.booking_requests USING btree (appointment_id);

CREATE INDEX idx_booking_requests_created_at ON public.booking_requests USING btree (created_at);

CREATE INDEX idx_booking_requests_doctor ON public.booking_requests USING btree (doctor_id);

CREATE INDEX idx_booking_requests_patient ON public.booking_requests USING btree (patient_id);

CREATE INDEX idx_booking_requests_pending ON public.booking_requests USING btree (created_at) WHERE (status = 'pending'::public.booking_request_status);

CREATE INDEX idx_booking_requests_status ON public.booking_requests USING btree (status);

CREATE INDEX idx_cancellation_requests_appointment ON public.cancellation_requests USING btree (appointment_id);

CREATE INDEX idx_cancellation_requests_status ON public.cancellation_requests USING btree (status);

CREATE INDEX idx_notification_outbox_pending ON public.notification_outbox USING btree (status, created_at);

CREATE INDEX idx_rescheduling_requests_appointment ON public.rescheduling_requests USING btree (appointment_id);

CREATE INDEX idx_rescheduling_requests_created ON public.rescheduling_requests USING btree (created_at DESC);

CREATE INDEX idx_rescheduling_requests_status ON public.rescheduling_requests USING btree (status);

CREATE INDEX idx_waiting_list_doctor ON public.wait_list USING btree (doctor_id);

CREATE INDEX idx_waiting_list_match ON public.wait_list USING btree (doctor_id, preferred_date, status, priority DESC, created_at);

CREATE INDEX idx_waiting_list_patient ON public.wait_list USING btree (patient_id);

CREATE INDEX idx_waiting_list_preferred_date ON public.wait_list USING btree (preferred_date);

CREATE INDEX idx_waiting_list_status ON public.wait_list USING btree (status);

CREATE INDEX idx_waiting_offers_slot ON public.waiting_list_offers USING btree (slot_event_id);

CREATE INDEX idx_waiting_offers_status_expiry ON public.waiting_list_offers USING btree (status, expires_at);

CREATE UNIQUE INDEX booking_requests_idempotency_key_unique ON public.booking_requests USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);

CREATE UNIQUE INDEX idx_booking_requests_idempotency ON public.booking_requests USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);

CREATE UNIQUE INDEX idx_one_pending_offer_per_waiting_entry ON public.waiting_list_offers USING btree (waiting_list_id) WHERE (status = 'pending'::public.waiting_offer_status);

CREATE INDEX p4_pending_due ON clinic.p4_notification_outbox USING btree (due_at, id) WHERE (state = 'pending'::text);

CREATE UNIQUE INDEX p4_booking_confirmation_once ON clinic.p4_notification_outbox USING btree (event_id) WHERE (template_key = 'booking_confirmed'::text);

CREATE INDEX inbox_actor_event ON p1_telegram.inbox USING btree (bot_id, telegram_user_id, event_at, update_id) WHERE (recovery_enabled AND (event_at IS NOT NULL));

CREATE INDEX inbox_pending_recovery ON p1_telegram.inbox USING btree (bot_id, received_at, update_id) WHERE (recovery_enabled AND (status = 'pending'::text));

CREATE INDEX inbox_receipt_age ON p1_telegram.inbox USING btree (received_at);

CREATE INDEX link_audit_actor_time ON p1_telegram.link_audit USING btree (bot_id, telegram_user_id, recorded_at);

CREATE INDEX patient_links_by_patient ON p1_telegram.patient_links USING btree (patient_id, bot_id);

CREATE INDEX replies_due ON p1_telegram.replies USING btree (bot_id, available_at, update_id) WHERE ((sent_at IS NULL) AND (attempts < 3));

CREATE INDEX test_booking_requests_latest_patient ON p1_telegram.test_booking_requests USING btree (patient_id, created_at DESC, id DESC);

CREATE UNIQUE INDEX deletion_one_open_request ON p1_telegram.deletion_requests USING btree (patient_id) WHERE (review_outcome IS DISTINCT FROM 'closed'::text);

CREATE UNIQUE INDEX patient_links_one_selected ON p1_telegram.patient_links USING btree (bot_id, telegram_user_id) WHERE selected;

CREATE UNIQUE INDEX registration_draft_reference ON p1_telegram.registration_drafts USING btree (review_reference);

CREATE UNIQUE INDEX replies_claim_token ON p1_telegram.replies USING btree (claim_token) WHERE (claim_token IS NOT NULL);

ALTER TABLE public.booking_requests ADD CONSTRAINT booking_requests_appointment_fk FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE SET NULL NOT VALID;

ALTER TABLE public.booking_requests ADD CONSTRAINT booking_requests_waiting_list_offer_id_fkey FOREIGN KEY (waiting_list_offer_id) REFERENCES public.waiting_list_offers(id) ON DELETE SET NULL;

ALTER TABLE public.cancellation_requests ADD CONSTRAINT cancellation_requests_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE RESTRICT;

ALTER TABLE public.notification_outbox ADD CONSTRAINT notification_outbox_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.waiting_list_offers(id) ON DELETE RESTRICT;

ALTER TABLE public.performed_services ADD CONSTRAINT performed_services_revision_id_fkey FOREIGN KEY (revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE public.performed_services ADD CONSTRAINT performed_services_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE public.rescheduling_requests ADD CONSTRAINT rescheduling_requests_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE RESTRICT;

ALTER TABLE public.visit_attachments ADD CONSTRAINT visit_attachments_revision_id_fkey FOREIGN KEY (revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE public.visit_attachments ADD CONSTRAINT visit_attachments_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE public.visit_revisions ADD CONSTRAINT visit_revisions_supersedes_revision_id_fkey FOREIGN KEY (supersedes_revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE public.visit_revisions ADD CONSTRAINT visit_revisions_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE public.visits ADD CONSTRAINT visits_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id);

ALTER TABLE public.visits ADD CONSTRAINT visits_current_revision_fk FOREIGN KEY (current_revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE public.wait_list ADD CONSTRAINT wait_list_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinicos_identity.patients(id) ON DELETE RESTRICT;

ALTER TABLE public.waiting_list_offers ADD CONSTRAINT waiting_list_offers_slot_event_id_fkey FOREIGN KEY (slot_event_id) REFERENCES public.available_slot_events(id) ON DELETE RESTRICT;

ALTER TABLE public.waiting_list_offers ADD CONSTRAINT waiting_list_offers_waiting_list_id_fkey FOREIGN KEY (waiting_list_id) REFERENCES public.wait_list(id) ON DELETE RESTRICT;

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES clinic.invoices(id);

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_performed_service_id_fkey FOREIGN KEY (performed_service_id) REFERENCES public.performed_services(id);

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_revision_id_fkey FOREIGN KEY (revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE clinic.invoice_lines ADD CONSTRAINT invoice_lines_service_code_fkey FOREIGN KEY (service_code) REFERENCES clinic.services(service_code);

ALTER TABLE clinic.invoices ADD CONSTRAINT invoices_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE clinic.payments ADD CONSTRAINT payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES clinic.invoices(id);

ALTER TABLE clinicos_showcase.feedback ADD CONSTRAINT feedback_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE clinicos_showcase.followups ADD CONSTRAINT followups_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE SET NULL;

ALTER TABLE clinicos_showcase.followups ADD CONSTRAINT followups_revision_id_fkey FOREIGN KEY (revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE clinicos_showcase.followups ADD CONSTRAINT followups_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE clinicos_showcase.invoice_queue ADD CONSTRAINT invoice_queue_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE clinicos_showcase.patient_auth ADD CONSTRAINT patient_auth_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE clinicos_showcase.patient_auth ADD CONSTRAINT patient_auth_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES clinicos_identity.patients(id) ON DELETE CASCADE;

ALTER TABLE clinicos_showcase.staff_auth ADD CONSTRAINT staff_auth_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE clinicos_showcase.staff_auth ADD CONSTRAINT staff_auth_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES clinicos_identity.staff(id) ON DELETE CASCADE;

ALTER TABLE clinicos_showcase.summary_drafts ADD CONSTRAINT summary_drafts_revision_id_fkey FOREIGN KEY (revision_id) REFERENCES public.visit_revisions(id);

ALTER TABLE clinicos_showcase.summary_drafts ADD CONSTRAINT summary_drafts_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);

ALTER TABLE clinicos_staff_private.file_delivery ADD CONSTRAINT file_delivery_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.visit_attachments(id) ON DELETE CASCADE;

ALTER TABLE p1_telegram.account_confirmations ADD CONSTRAINT account_confirmations_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES p1_telegram.patients(patient_id);

ALTER TABLE p1_telegram.deletion_requests ADD CONSTRAINT deletion_requests_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES p1_telegram.patients(patient_id);

ALTER TABLE p1_telegram.deletion_review_history ADD CONSTRAINT deletion_review_history_review_reference_fkey FOREIGN KEY (review_reference) REFERENCES p1_telegram.deletion_requests(review_reference);

ALTER TABLE p1_telegram.duplicate_dispositions ADD CONSTRAINT duplicate_dispositions_existing_patient_id_fkey FOREIGN KEY (existing_patient_id) REFERENCES p1_telegram.patients(patient_id);

ALTER TABLE p1_telegram.link_codes ADD CONSTRAINT link_codes_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES p1_telegram.patients(patient_id);

ALTER TABLE p1_telegram.patient_links ADD CONSTRAINT patient_links_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES p1_telegram.patients(patient_id);

ALTER TABLE p1_telegram.patient_sync_queue ADD CONSTRAINT patient_sync_queue_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES p1_telegram.patients(patient_id) ON DELETE CASCADE;

ALTER TABLE p1_telegram.phone_edits ADD CONSTRAINT phone_edits_bot_id_telegram_user_id_patient_id_fkey FOREIGN KEY (bot_id, telegram_user_id, patient_id) REFERENCES p1_telegram.patient_links(bot_id, telegram_user_id, patient_id) ON DELETE CASCADE;

ALTER TABLE p1_telegram.replies ADD CONSTRAINT replies_bot_id_update_id_fkey FOREIGN KEY (bot_id, update_id) REFERENCES p1_telegram.inbox(bot_id, update_id);

ALTER TABLE p1_telegram.staff_access_confirmation ADD CONSTRAINT staff_access_confirmation_bot_id_fkey FOREIGN KEY (bot_id) REFERENCES p1_telegram.staff_access_owner(bot_id);

ALTER TABLE p1_telegram.staff_access_owner ADD CONSTRAINT staff_access_owner_bot_id_telegram_user_id_fkey FOREIGN KEY (bot_id, telegram_user_id) REFERENCES p1_telegram.staff(bot_id, telegram_user_id);

ALTER TABLE p1_telegram.test_booking_requests ADD CONSTRAINT test_booking_requests_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES p1_telegram.patients(patient_id);

-- Views and triggers

CREATE VIEW clinic.p4_appointment_confirmation_events WITH (security_invoker=true) AS  SELECT id::text AS event_id,
    'booking_confirmed'::text AS template_key,
    1 AS event_version,
    patient_id::text AS recipient_ref,
    status = 'booked'::public.appointment_status AND (appointment_date + start_time) > (statement_timestamp() AT TIME ZONE 'Africa/Cairo'::text) AS eligible
   FROM public.appointments a;

CREATE VIEW clinicos_showcase.notification_events AS  SELECT a.id::text AS event_id,
    'appointment_reminder'::text AS template_key,
    (1 + (hashtextextended(a.appointment_date::text || a.start_time::text, 0::bigint) & 2147483646::bigint))::integer AS event_version,
    a.patient_id::text AS recipient_ref,
    ((a.appointment_date + a.start_time) AT TIME ZONE 'Africa/Cairo'::text) - '24:00:00'::interval AS due_at,
    a.status = 'booked'::public.appointment_status AND ((a.appointment_date + a.start_time) AT TIME ZONE 'Africa/Cairo'::text) > now() AS eligible
   FROM public.appointments a
UNION ALL
 SELECT a.id::text AS event_id,
    'no_show_follow_up'::text AS template_key,
    1 AS event_version,
    a.patient_id::text AS recipient_ref,
    a.updated_at AS due_at,
    a.status = 'no_show'::public.appointment_status AS eligible
   FROM public.appointments a
  WHERE a.status = 'no_show'::public.appointment_status AND a.updated_at >= (( SELECT settings.enabled_after
           FROM clinicos_showcase.settings))
UNION ALL
 SELECT v.id::text AS event_id,
    'feedback_request'::text AS template_key,
    1 AS event_version,
    v.patient_id::text AS recipient_ref,
    v.finalized_at + '24:00:00'::interval AS due_at,
    v.status = 'finalized'::text AND NOT (EXISTS ( SELECT 1
           FROM clinicos_showcase.feedback f
          WHERE f.visit_id = v.id)) AS eligible
   FROM public.visits v
  WHERE v.finalized_at >= (( SELECT settings.enabled_after
           FROM clinicos_showcase.settings))
UNION ALL
 SELECT v.id::text AS event_id,
    'visit_follow_up'::text AS template_key,
    f.version AS event_version,
    v.patient_id::text AS recipient_ref,
    ((f.due_date + '09:00:00'::time without time zone) AT TIME ZONE 'Africa/Cairo'::text) AS due_at,
    f.appointment_id IS NULL AND v.status = 'finalized'::text AND v.current_revision_id = f.revision_id AS eligible
   FROM clinicos_showcase.followups f
     JOIN public.visits v ON v.id = f.visit_id
UNION ALL
 SELECT o.id::text AS event_id,
    'waiting_list_offer'::text AS template_key,
    1 AS event_version,
    o.patient_id::text AS recipient_ref,
    o.created_at AS due_at,
    o.status = 'pending'::public.waiting_offer_status AND o.expires_at > now() AS eligible
   FROM public.waiting_list_offers o
     JOIN clinic.p4_waiting_offer_claims c ON c.offer_id = o.id AND c.decision = 'eligible'::text;

CREATE VIEW clinic.p4_current_notification_events AS  SELECT source.event_id,
    source.template_key,
    source.event_version,
    source.recipient_ref,
    source.eligible
   FROM ( SELECT booking_confirmation.id::text AS event_id,
                CASE "right"(booking_confirmation.id::text, 1)
                    WHEN '5'::text THEN 'appointment_reminder'::text
                    WHEN '6'::text THEN 'no_show_follow_up'::text
                    WHEN '7'::text THEN 'feedback_request'::text
                    ELSE 'booking_confirmed'::text
                END AS template_key,
            1 AS event_version,
            'p4-full-private-demo'::text AS recipient_ref,
            booking_confirmation.booking_status = 'booked'::text AND booking_confirmation.appointment_at > statement_timestamp() AS eligible
           FROM p4_demo.booking_confirmation
          WHERE booking_confirmation.id::text = ANY (ARRAY['04010000-0000-4000-8000-000000000001'::text, '04010000-0000-4000-8000-000000000002'::text, '04010000-0000-4000-8000-000000000003'::text, '04010000-0000-4000-8000-000000000004'::text, '04010000-0000-4000-8000-000000000005'::text, '04010000-0000-4000-8000-000000000006'::text, '04010000-0000-4000-8000-000000000007'::text])
        UNION ALL
         SELECT p4_appointment_confirmation_events.event_id,
            p4_appointment_confirmation_events.template_key,
            p4_appointment_confirmation_events.event_version,
            p4_appointment_confirmation_events.recipient_ref,
            p4_appointment_confirmation_events.eligible
           FROM clinic.p4_appointment_confirmation_events) source
UNION ALL
 SELECT notification_events.event_id,
    notification_events.template_key,
    notification_events.event_version,
    notification_events.recipient_ref,
    notification_events.eligible
   FROM clinicos_showcase.notification_events;

CREATE VIEW clinicos_showcase.telegram_recipients AS  SELECT p.id::text AS recipient_ref,
    p.telegram_chat_id::text AS chat_id,
    true AS eligible
   FROM clinicos_identity.patients p
     JOIN p1_telegram.patient_links l ON l.patient_id = p.id AND l.telegram_user_id = p.telegram_user_id
     JOIN p1_telegram.sync_scope scope ON scope.bot_id = l.bot_id
     JOIN p1_telegram.registration_consent c ON c.bot_id = l.bot_id AND c.telegram_user_id = l.telegram_user_id
  WHERE p.is_active AND p.telegram_chat_id = p.telegram_user_id AND p.telegram_chat_id > 0 AND c.decision AND c.notice_version = 'demo-v2'::text;

CREATE VIEW clinic.p4_verified_notification_recipients AS  SELECT source.recipient_ref,
    source.chat_id,
    source.eligible
   FROM ( SELECT notification_recipient.recipient_ref,
            notification_recipient.chat_id,
            notification_recipient.eligible
           FROM p4_demo.notification_recipient) source
  WHERE NOT (EXISTS ( SELECT 1
           FROM clinicos_showcase.telegram_recipients r
          WHERE r.recipient_ref = source.recipient_ref))
UNION ALL
 SELECT telegram_recipients.recipient_ref,
    telegram_recipients.chat_id,
    telegram_recipients.eligible
   FROM clinicos_showcase.telegram_recipients;

CREATE TRIGGER appointments_capture_released_slot AFTER UPDATE OF status, appointment_date, start_time, end_time ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.capture_released_appointment_slot();

CREATE TRIGGER booking_request_insert_notification AFTER INSERT ON public.booking_requests FOR EACH ROW EXECUTE FUNCTION public.notify_new_booking_request();

CREATE TRIGGER booking_request_waiting_list_sync AFTER UPDATE OF status ON public.booking_requests FOR EACH ROW EXECUTE FUNCTION public.sync_waiting_list_booking_result();

CREATE TRIGGER cancellation_request_inserted AFTER INSERT ON public.cancellation_requests FOR EACH ROW EXECUTE FUNCTION public.notify_cancellation_request();

CREATE TRIGGER cancellation_request_timestamps BEFORE UPDATE ON public.cancellation_requests FOR EACH ROW EXECUTE FUNCTION public.handle_cancellation_request_timestamps();

CREATE TRIGGER rescheduling_request_inserted AFTER INSERT ON public.rescheduling_requests FOR EACH ROW EXECUTE FUNCTION public.notify_rescheduling_request();

CREATE TRIGGER rescheduling_request_timestamps BEFORE UPDATE ON public.rescheduling_requests FOR EACH ROW EXECUTE FUNCTION public.handle_rescheduling_request_timestamps();

CREATE TRIGGER set_booking_request_processed_at BEFORE UPDATE ON public.booking_requests FOR EACH ROW EXECUTE FUNCTION public.set_booking_request_processed_at();

CREATE TRIGGER set_booking_request_updated_at BEFORE UPDATE ON public.booking_requests FOR EACH ROW EXECUTE FUNCTION public.update_booking_request_timestamp();

CREATE TRIGGER waiting_list_updated_at BEFORE UPDATE ON public.wait_list FOR EACH ROW EXECUTE FUNCTION public.set_waiting_list_updated_at();

CREATE TRIGGER invoice_immutable BEFORE DELETE OR UPDATE ON clinic.invoices FOR EACH ROW EXECUTE FUNCTION clinic.immutable_billing();

CREATE TRIGGER line_immutable BEFORE DELETE OR UPDATE ON clinic.invoice_lines FOR EACH ROW EXECUTE FUNCTION clinic.immutable_billing();

CREATE TRIGGER payment_immutable BEFORE DELETE OR UPDATE ON clinic.payments FOR EACH ROW EXECUTE FUNCTION clinic.immutable_billing();

CREATE TRIGGER bump_phone_sync_revision BEFORE UPDATE OF phone_e164 ON p1_telegram.patients FOR EACH ROW WHEN (old.phone_e164 IS DISTINCT FROM new.phone_e164) EXECUTE FUNCTION p1_telegram.bump_phone_sync_revision();

CREATE TRIGGER enqueue_patient_sync AFTER INSERT ON p1_telegram.patients FOR EACH ROW EXECUTE FUNCTION p1_telegram.enqueue_patient_sync();

CREATE TRIGGER queue_phone_edit AFTER UPDATE OF phone_e164 ON p1_telegram.patients FOR EACH ROW WHEN (old.phone_e164 IS DISTINCT FROM new.phone_e164) EXECUTE FUNCTION p1_telegram.queue_phone_edit();

CREATE TRIGGER queue_staff_change AFTER INSERT OR DELETE OR UPDATE OF role, active ON p1_telegram.staff FOR EACH ROW EXECUTE FUNCTION p1_telegram.queue_staff_change();

CREATE TRIGGER queue_telegram_link_change AFTER INSERT OR DELETE ON p1_telegram.patient_links FOR EACH ROW EXECUTE FUNCTION p1_telegram.queue_telegram_link_change();

CREATE TRIGGER refresh_consent_contacts AFTER UPDATE OF notice_version, decision ON p1_telegram.registration_consent FOR EACH ROW EXECUTE FUNCTION p1_telegram.refresh_consent_contacts();

-- Row policies and access

ALTER TABLE clinic.invoice_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.invoices ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.p4_demo_faq ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.p4_faq_pending_handoff ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.p4_notification_outbox ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.p4_waiting_offer_claims ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.payments ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.services ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinic.setup_probe ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinicos_identity.patients ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinicos_identity.staff ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinicos_staff_private.file_delivery ENABLE ROW LEVEL SECURITY;

ALTER TABLE p4_demo.booking_confirmation ENABLE ROW LEVEL SECURITY;

ALTER TABLE p4_demo.notification_recipient ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.available_slot_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.booking_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.cancellation_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.performed_services ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.rescheduling_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.visit_attachments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.visit_revisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.wait_list ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.waiting_list ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.waiting_list_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY p5_owner_lines ON clinic.invoice_lines AS PERMISSIVE FOR ALL TO p5_entry_owner USING (true) WITH CHECK (true);

CREATE POLICY p5_owner_invoices ON clinic.invoices AS PERMISSIVE FOR ALL TO p5_entry_owner USING (true) WITH CHECK (true);

CREATE POLICY p4_confirmation_outbox_insert ON clinic.p4_notification_outbox AS PERMISSIVE FOR INSERT TO p4_confirmation_worker WITH CHECK ((template_key = 'booking_confirmed'::text));

CREATE POLICY p4_confirmation_outbox_read ON clinic.p4_notification_outbox AS PERMISSIVE FOR SELECT TO p4_confirmation_worker USING ((template_key = 'booking_confirmed'::text));

CREATE POLICY p4_confirmation_outbox_update ON clinic.p4_notification_outbox AS PERMISSIVE FOR UPDATE TO p4_confirmation_worker USING ((template_key = 'booking_confirmed'::text)) WITH CHECK ((template_key = 'booking_confirmed'::text));

CREATE POLICY p4_demo_read ON clinic.p4_notification_outbox AS PERMISSIVE FOR SELECT TO p4_demo_runner USING (((recipient_ref = 'p4-full-private-demo'::text) AND (event_id = ANY (ARRAY['04010000-0000-4000-8000-000000000001'::text, '04010000-0000-4000-8000-000000000002'::text, '04010000-0000-4000-8000-000000000003'::text, '04010000-0000-4000-8000-000000000004'::text, '04010000-0000-4000-8000-000000000005'::text, '04010000-0000-4000-8000-000000000006'::text, '04010000-0000-4000-8000-000000000007'::text]))));

CREATE POLICY p4_demo_update ON clinic.p4_notification_outbox AS PERMISSIVE FOR UPDATE TO p4_demo_runner USING (((recipient_ref = 'p4-full-private-demo'::text) AND (event_id = ANY (ARRAY['04010000-0000-4000-8000-000000000001'::text, '04010000-0000-4000-8000-000000000002'::text, '04010000-0000-4000-8000-000000000003'::text, '04010000-0000-4000-8000-000000000004'::text, '04010000-0000-4000-8000-000000000005'::text, '04010000-0000-4000-8000-000000000006'::text, '04010000-0000-4000-8000-000000000007'::text]))));

CREATE POLICY showcase_notify_outbox_insert ON clinic.p4_notification_outbox AS PERMISSIVE FOR INSERT TO clinicos_showcase_notifications WITH CHECK (((template_key = 'booking_confirmed'::text) AND clinicos_showcase.linked_demo_recipient(recipient_ref)));

CREATE POLICY showcase_notify_outbox_read ON clinic.p4_notification_outbox AS PERMISSIVE FOR SELECT TO clinicos_showcase_notifications USING (clinicos_showcase.linked_demo_recipient(recipient_ref));

CREATE POLICY showcase_notify_outbox_update ON clinic.p4_notification_outbox AS PERMISSIVE FOR UPDATE TO clinicos_showcase_notifications USING (clinicos_showcase.linked_demo_recipient(recipient_ref)) WITH CHECK (clinicos_showcase.linked_demo_recipient(recipient_ref));

CREATE POLICY showcase_notify_claim_read ON clinic.p4_waiting_offer_claims AS PERMISSIVE FOR SELECT TO clinicos_showcase_notifications USING (clinicos_showcase.linked_demo_offer(offer_id));

CREATE POLICY showcase_notify_claim_write ON clinic.p4_waiting_offer_claims AS PERMISSIVE FOR INSERT TO clinicos_showcase_notifications WITH CHECK (((decision = ANY (ARRAY['eligible'::text, 'suppressed'::text])) AND clinicos_showcase.linked_demo_offer(offer_id)));

CREATE POLICY p5_owner_services ON clinic.services AS PERMISSIVE FOR ALL TO p5_entry_owner USING (true) WITH CHECK (true);

CREATE POLICY setup_runtime_insert ON clinic.setup_probe AS PERMISSIVE FOR INSERT TO clinic_runtime WITH CHECK ((marker = 'clinicos-setup-fictional'::text));

CREATE POLICY setup_runtime_read ON clinic.setup_probe AS PERMISSIVE FOR SELECT TO clinic_runtime USING (true);

CREATE POLICY clinicos_showcase_sync_insert ON clinicos_identity.patients AS PERMISSIVE FOR INSERT TO clinicos_identity_sync WITH CHECK (is_active);

CREATE POLICY clinicos_showcase_sync_read ON clinicos_identity.patients AS PERMISSIVE FOR SELECT TO clinicos_identity_sync USING (is_active);

CREATE POLICY clinicos_showcase_sync_update ON clinicos_identity.patients AS PERMISSIVE FOR UPDATE TO clinicos_identity_sync USING (is_active) WITH CHECK (is_active);

CREATE POLICY patient_writer_insert_active_patients ON clinicos_identity.patients AS PERMISSIVE FOR INSERT TO clinicos_p1_patient_writer WITH CHECK (is_active);

CREATE POLICY patient_writer_read_active_ids ON clinicos_identity.patients AS PERMISSIVE FOR SELECT TO clinicos_p1_patient_writer USING (is_active);

CREATE POLICY patient_writer_update_active_phone ON clinicos_identity.patients AS PERMISSIVE FOR UPDATE TO clinicos_p1_patient_writer USING (is_active) WITH CHECK (is_active);

CREATE POLICY reception_read_patients ON clinicos_identity.patients AS PERMISSIVE FOR SELECT TO clinicos_p1_reception USING (true);

CREATE POLICY scheduling_read_active_patients ON clinicos_identity.patients AS PERMISSIVE FOR SELECT TO clinicos_p1_scheduling USING (is_active);

CREATE POLICY p4_demo_runner_read ON p4_demo.booking_confirmation AS PERMISSIVE FOR SELECT TO p4_demo_runner USING ((id = '04010000-0000-4000-8000-000000000001'::uuid));

CREATE POLICY p4_demo_runner_update ON p4_demo.booking_confirmation AS PERMISSIVE FOR UPDATE TO p4_demo_runner USING ((id = '04010000-0000-4000-8000-000000000001'::uuid)) WITH CHECK ((id = '04010000-0000-4000-8000-000000000001'::uuid));

CREATE POLICY p4_confirmation_appointment_read ON public.appointments AS PERMISSIVE FOR SELECT TO p4_confirmation_worker USING (true);

CREATE POLICY showcase_notify_appointment ON public.appointments AS PERMISSIVE FOR SELECT TO clinicos_showcase_notifications USING (clinicos_showcase.linked_demo_recipient((patient_id)::text));

CREATE POLICY showcase_scheduler_read ON public.available_slot_events AS PERMISSIVE FOR SELECT TO clinicos_showcase_scheduling USING (clinicos_showcase.linked_demo_appointment(source_appointment_id));

CREATE POLICY showcase_scheduler_update ON public.available_slot_events AS PERMISSIVE FOR UPDATE TO clinicos_showcase_scheduling USING (clinicos_showcase.linked_demo_appointment(source_appointment_id)) WITH CHECK (clinicos_showcase.linked_demo_appointment(source_appointment_id));

CREATE POLICY p4_confirmation_request_read ON public.booking_requests AS PERMISSIVE FOR SELECT TO p4_confirmation_worker USING ((status = 'confirmed'::public.booking_request_status));

CREATE POLICY showcase_notify_booking ON public.booking_requests AS PERMISSIVE FOR SELECT TO clinicos_showcase_notifications USING (((status = 'confirmed'::public.booking_request_status) AND clinicos_showcase.linked_demo_recipient((patient_id)::text)));

CREATE POLICY showcase_scheduler_read ON public.booking_requests AS PERMISSIVE FOR SELECT TO clinicos_showcase_scheduling USING ((clinicos_showcase.linked_demo_recipient((patient_id)::text) AND (waiting_list_offer_id IS NOT NULL)));

CREATE POLICY showcase_scheduler_request_insert ON public.booking_requests AS PERMISSIVE FOR INSERT TO clinicos_showcase_scheduling WITH CHECK (((status = 'pending'::public.booking_request_status) AND clinicos_showcase.linked_demo_offer(waiting_list_offer_id) AND clinicos_showcase.linked_demo_recipient((patient_id)::text)));

CREATE POLICY showcase_scheduler_update ON public.booking_requests AS PERMISSIVE FOR UPDATE TO clinicos_showcase_scheduling USING ((clinicos_showcase.linked_demo_recipient((patient_id)::text) AND (waiting_list_offer_id IS NOT NULL))) WITH CHECK ((clinicos_showcase.linked_demo_recipient((patient_id)::text) AND (waiting_list_offer_id IS NOT NULL)));

CREATE POLICY showcase_notify_inbox ON public.notification_outbox AS PERMISSIVE FOR SELECT TO clinicos_showcase_notifications USING (((event_type = 'waiting_list_offer'::text) AND clinicos_showcase.linked_demo_offer(offer_id)));

CREATE POLICY showcase_notify_inbox_lock ON public.notification_outbox AS PERMISSIVE FOR UPDATE TO clinicos_showcase_notifications USING (((event_type = 'waiting_list_offer'::text) AND clinicos_showcase.linked_demo_offer(offer_id))) WITH CHECK (((event_type = 'waiting_list_offer'::text) AND clinicos_showcase.linked_demo_offer(offer_id)));

CREATE POLICY p5_owner_performed ON public.performed_services AS PERMISSIVE FOR ALL TO p5_entry_owner USING (true) WITH CHECK (true);

CREATE POLICY p5_owner_revisions ON public.visit_revisions AS PERMISSIVE FOR ALL TO p5_entry_owner USING (true);

CREATE POLICY p5_owner_visits ON public.visits AS PERMISSIVE FOR ALL TO p5_entry_owner USING (true) WITH CHECK (true);

CREATE POLICY showcase_scheduler_read ON public.wait_list AS PERMISSIVE FOR SELECT TO clinicos_showcase_scheduling USING (clinicos_showcase.linked_demo_recipient((patient_id)::text));

CREATE POLICY showcase_scheduler_update ON public.wait_list AS PERMISSIVE FOR UPDATE TO clinicos_showcase_scheduling USING (clinicos_showcase.linked_demo_recipient((patient_id)::text)) WITH CHECK (clinicos_showcase.linked_demo_recipient((patient_id)::text));

CREATE POLICY showcase_notify_offer ON public.waiting_list_offers AS PERMISSIVE FOR SELECT TO clinicos_showcase_notifications USING (clinicos_showcase.linked_demo_recipient((patient_id)::text));

CREATE POLICY showcase_scheduler_read ON public.waiting_list_offers AS PERMISSIVE FOR SELECT TO clinicos_showcase_scheduling USING (clinicos_showcase.linked_demo_recipient((patient_id)::text));

CREATE POLICY showcase_scheduler_update ON public.waiting_list_offers AS PERMISSIVE FOR UPDATE TO clinicos_showcase_scheduling USING (clinicos_showcase.linked_demo_recipient((patient_id)::text)) WITH CHECK (clinicos_showcase.linked_demo_recipient((patient_id)::text));

REVOKE ALL ON FUNCTION public.book_appointment(p_patient_id uuid, p_doctor_id uuid, p_date date, p_start_time time without time zone, p_end_time time without time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.book_appointment(p_patient_id uuid, p_doctor_id uuid, p_date date, p_start_time time without time zone, p_end_time time without time zone) TO service_role;

REVOKE ALL ON FUNCTION public.cancel_appointment(p_appointment_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.cancel_appointment(p_appointment_id uuid) TO service_role;

REVOKE ALL ON FUNCTION public.capture_released_appointment_slot() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.capture_released_appointment_slot() TO service_role;

REVOKE ALL ON FUNCTION public.claim_booking_request(p_request_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.claim_booking_request(p_request_id uuid) TO service_role;

REVOKE ALL ON FUNCTION public.claim_cancellation_request(p_request_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.claim_cancellation_request(p_request_id uuid) TO service_role;

REVOKE ALL ON FUNCTION public.claim_rescheduling_request(p_request_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.claim_rescheduling_request(p_request_id uuid) TO service_role;

REVOKE ALL ON FUNCTION public.claim_waiting_list_entry(p_slot_event_id uuid, p_waiting_list_id uuid, p_expires_at timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.claim_waiting_list_entry(p_slot_event_id uuid, p_waiting_list_id uuid, p_expires_at timestamp with time zone) TO service_role;

REVOKE ALL ON FUNCTION public.clinicos_showcase_actor() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_actor() TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_checkin(p_appointment uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_checkin(p_appointment uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_daily_report(p_date date) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_daily_report(p_date date) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_finalize(p_visit uuid, p_services jsonb) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_finalize(p_visit uuid, p_services jsonb) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_operations(p_action text, p_handoff uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_operations(p_action text, p_handoff uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_patient() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_patient() TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_record_payment(p_request text, p_invoice uuid, p_amount text, p_method text, p_reference text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_record_payment(p_request text, p_invoice uuid, p_amount text, p_method text, p_reference text) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_save_revision(p_visit uuid, p_content jsonb, p_amend boolean) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_save_revision(p_visit uuid, p_content jsonb, p_amend boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_set_followup(p_visit uuid, p_date date) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_set_followup(p_visit uuid, p_date date) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_summary(p_visit uuid, p_action text, p_revision uuid, p_draft uuid, p_text text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_summary(p_visit uuid, p_action text, p_revision uuid, p_draft uuid, p_text text) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_showcase_waitlist(p_doctor uuid, p_date date) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_showcase_waitlist(p_doctor uuid, p_date date) TO authenticated;

REVOKE ALL ON FUNCTION public.clinicos_staff_board(p_date date) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_board(p_date date) TO authenticated;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_board(p_date date) TO service_role;

REVOKE ALL ON FUNCTION public.clinicos_staff_booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone) TO authenticated;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone) TO service_role;

REVOKE ALL ON FUNCTION public.clinicos_staff_followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone) TO authenticated;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone) TO service_role;

REVOKE ALL ON FUNCTION public.clinicos_staff_visit_files(p_visit uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_visit_files(p_visit uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.clinicos_staff_visit_files(p_visit uuid) TO service_role;

REVOKE ALL ON FUNCTION public.handle_cancellation_request_timestamps() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.handle_cancellation_request_timestamps() TO service_role;

REVOKE ALL ON FUNCTION public.handle_rescheduling_request_timestamps() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.handle_rescheduling_request_timestamps() TO service_role;

REVOKE ALL ON FUNCTION public.notify_cancellation_request() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.notify_cancellation_request() TO service_role;

REVOKE ALL ON FUNCTION public.notify_new_booking_request() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.notify_new_booking_request() TO service_role;

REVOKE ALL ON FUNCTION public.notify_rescheduling_request() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.notify_rescheduling_request() TO service_role;

REVOKE ALL ON FUNCTION public.reschedule_appointment(p_appointment_id uuid, p_new_date date, p_new_start_time time without time zone, p_new_end_time time without time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.reschedule_appointment(p_appointment_id uuid, p_new_date date, p_new_start_time time without time zone, p_new_end_time time without time zone) TO service_role;

REVOKE ALL ON FUNCTION public.set_booking_request_processed_at() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.set_booking_request_processed_at() TO service_role;

REVOKE ALL ON FUNCTION public.set_waiting_list_updated_at() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.set_waiting_list_updated_at() TO service_role;

REVOKE ALL ON FUNCTION public.sync_waiting_list_booking_result() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.sync_waiting_list_booking_result() TO service_role;

REVOKE ALL ON FUNCTION public.update_booking_request_timestamp() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.update_booking_request_timestamp() TO service_role;

GRANT USAGE ON SCHEMA public TO p5_entry_owner;

GRANT USAGE ON SCHEMA public TO p4_confirmation_worker;

REVOKE ALL ON TABLE public.appointments FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.appointments TO service_role;

REVOKE ALL ON TABLE public.available_slot_events FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.available_slot_events TO service_role;

GRANT SELECT ON TABLE public.available_slot_events TO clinicos_showcase_scheduling;

REVOKE ALL ON TABLE public.booking_requests FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.booking_requests TO service_role;

REVOKE ALL ON TABLE public.cancellation_requests FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.cancellation_requests TO service_role;

REVOKE ALL ON TABLE public.doctor_schedules FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.doctor_schedules TO service_role;

REVOKE ALL ON TABLE public.notification_outbox FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.notification_outbox TO service_role;

REVOKE ALL ON TABLE public.performed_services FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.performed_services TO service_role;

GRANT SELECT ON TABLE public.performed_services TO p5_entry_owner;

REVOKE ALL ON TABLE public.rescheduling_requests FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.rescheduling_requests TO service_role;

REVOKE ALL ON TABLE public.visit_attachments FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.visit_attachments TO service_role;

REVOKE ALL ON TABLE public.visit_revisions FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.visit_revisions TO service_role;

REVOKE ALL ON TABLE public.visits FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.visits TO service_role;

GRANT SELECT ON TABLE public.visits TO p5_entry_owner;

REVOKE ALL ON TABLE public.wait_list FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.wait_list TO service_role;

GRANT SELECT ON TABLE public.wait_list TO clinicos_showcase_scheduling;

REVOKE ALL ON TABLE public.waiting_list FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.waiting_list TO service_role;

REVOKE ALL ON TABLE public.waiting_list_offers FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.waiting_list_offers TO service_role;

GRANT SELECT ON TABLE public.waiting_list_offers TO clinicos_showcase_scheduling;

REVOKE ALL ON FUNCTION clinic.create_invoice(p_request text, p_actor uuid, p_visit uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.create_invoice(p_request text, p_actor uuid, p_visit uuid) TO p5_entry_owner;

REVOKE ALL ON FUNCTION clinic.get_invoice(p_invoice uuid) FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION clinic.immutable_billing() FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION clinic.p4_claim_due_notifications(batch_size integer) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p4_claim_due_notifications(batch_size integer) TO p4_demo_runner;

GRANT EXECUTE ON FUNCTION clinic.p4_claim_due_notifications(batch_size integer) TO p4_confirmation_worker;

GRANT EXECUTE ON FUNCTION clinic.p4_claim_due_notifications(batch_size integer) TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinic.p4_expire_notification_claims() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p4_expire_notification_claims() TO p4_demo_runner;

GRANT EXECUTE ON FUNCTION clinic.p4_expire_notification_claims() TO p4_confirmation_worker;

GRANT EXECUTE ON FUNCTION clinic.p4_expire_notification_claims() TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinic.p4_finish_notification(p_id bigint, p_claim timestamp with time zone, p_outcome text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p4_finish_notification(p_id bigint, p_claim timestamp with time zone, p_outcome text) TO p4_demo_runner;

GRANT EXECUTE ON FUNCTION clinic.p4_finish_notification(p_id bigint, p_claim timestamp with time zone, p_outcome text) TO p4_confirmation_worker;

GRANT EXECUTE ON FUNCTION clinic.p4_finish_notification(p_id bigint, p_claim timestamp with time zone, p_outcome text) TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinic.p4_prepare_notification(p_id bigint, p_claim timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p4_prepare_notification(p_id bigint, p_claim timestamp with time zone) TO p4_demo_runner;

GRANT EXECUTE ON FUNCTION clinic.p4_prepare_notification(p_id bigint, p_claim timestamp with time zone) TO p4_confirmation_worker;

GRANT EXECUTE ON FUNCTION clinic.p4_prepare_notification(p_id bigint, p_claim timestamp with time zone) TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinic.p5_generate_invoice(p_request text, p_actor uuid, p_visit uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p5_generate_invoice(p_request text, p_actor uuid, p_visit uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION clinic.p5_generate_invoice(p_request text, p_actor uuid, p_visit uuid) TO p5_demo_runtime;

REVOKE ALL ON FUNCTION clinic.p5_get_service(p_actor uuid, p_code text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p5_get_service(p_actor uuid, p_code text) TO authenticated;

GRANT EXECUTE ON FUNCTION clinic.p5_get_service(p_actor uuid, p_code text) TO p5_demo_runtime;

REVOKE ALL ON FUNCTION clinic.p5_save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinic.p5_save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION clinic.p5_save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) TO p5_demo_runtime;

REVOKE ALL ON FUNCTION clinic.record_payment(p_request text, p_actor uuid, p_invoice uuid, p_amount text, p_method text, p_reference text) FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON SCHEMA clinic FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA clinic TO authenticated;

GRANT USAGE ON SCHEMA clinic TO service_role;

GRANT USAGE ON SCHEMA clinic TO clinic_runtime;

GRANT USAGE ON SCHEMA clinic TO p5_entry_owner;

GRANT USAGE ON SCHEMA clinic TO p5_demo_runtime;

GRANT USAGE ON SCHEMA clinic TO p4_demo_runner;

GRANT USAGE ON SCHEMA clinic TO p4_confirmation_worker;

GRANT USAGE ON SCHEMA clinic TO clinicos_showcase_notifications;

REVOKE ALL ON SEQUENCE clinic.p4_notification_outbox_id_seq FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinic.invoice_lines FROM PUBLIC, anon, authenticated, service_role;

GRANT INSERT, SELECT ON TABLE clinic.invoice_lines TO p5_entry_owner;

REVOKE ALL ON TABLE clinic.invoices FROM PUBLIC, anon, authenticated, service_role;

GRANT INSERT, SELECT ON TABLE clinic.invoices TO p5_entry_owner;

REVOKE ALL ON TABLE clinic.p4_appointment_confirmation_events FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE clinic.p4_appointment_confirmation_events TO p4_confirmation_worker;

REVOKE ALL ON TABLE clinic.p4_current_notification_events FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE clinic.p4_current_notification_events TO p4_demo_runner;

GRANT SELECT ON TABLE clinic.p4_current_notification_events TO p4_confirmation_worker;

GRANT SELECT ON TABLE clinic.p4_current_notification_events TO clinicos_showcase_notifications;

REVOKE ALL ON TABLE clinic.p4_demo_faq FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinic.p4_faq_pending_handoff FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinic.p4_notification_outbox FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE clinic.p4_notification_outbox TO p4_demo_runner;

GRANT SELECT ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT SELECT ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

REVOKE ALL ON TABLE clinic.p4_verified_notification_recipients FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE clinic.p4_verified_notification_recipients TO p4_demo_runner;

GRANT SELECT ON TABLE clinic.p4_verified_notification_recipients TO p4_confirmation_worker;

GRANT SELECT ON TABLE clinic.p4_verified_notification_recipients TO clinicos_showcase_notifications;

REVOKE ALL ON TABLE clinic.p4_waiting_offer_claims FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE clinic.p4_waiting_offer_claims TO clinicos_showcase_notifications;

REVOKE ALL ON TABLE clinic.payments FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinic.services FROM PUBLIC, anon, authenticated, service_role;

GRANT INSERT, SELECT, UPDATE ON TABLE clinic.services TO p5_entry_owner;

REVOKE ALL ON TABLE clinic.setup_probe FROM PUBLIC, anon, authenticated, service_role;

GRANT INSERT, SELECT, UPDATE ON TABLE clinic.setup_probe TO service_role;

GRANT INSERT, SELECT ON TABLE clinic.setup_probe TO clinic_runtime;

REVOKE ALL ON FUNCTION clinicos_identity.apply_staff_sync(p_batch jsonb) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_identity.apply_staff_sync(p_batch jsonb) TO clinicos_p1_n8n_sync;

GRANT EXECUTE ON FUNCTION clinicos_identity.apply_staff_sync(p_batch jsonb) TO clinicos_identity_sync;

REVOKE ALL ON SCHEMA clinicos_identity FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA clinicos_identity TO clinicos_p1_reception;

GRANT USAGE ON SCHEMA clinicos_identity TO clinicos_p1_scheduling;

GRANT USAGE ON SCHEMA clinicos_identity TO clinicos_p1_patient_writer;

GRANT USAGE ON SCHEMA clinicos_identity TO clinicos_identity_sync;

REVOKE ALL ON TABLE clinicos_identity.patients FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_identity.staff FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION clinicos_showcase.linked_demo_appointment(p_appointment uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_showcase.linked_demo_appointment(p_appointment uuid) TO clinicos_showcase_scheduling;

GRANT EXECUTE ON FUNCTION clinicos_showcase.linked_demo_appointment(p_appointment uuid) TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinicos_showcase.linked_demo_offer(p_offer uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_showcase.linked_demo_offer(p_offer uuid) TO clinicos_showcase_scheduling;

GRANT EXECUTE ON FUNCTION clinicos_showcase.linked_demo_offer(p_offer uuid) TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinicos_showcase.linked_demo_recipient(p_patient text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_showcase.linked_demo_recipient(p_patient text) TO clinicos_showcase_scheduling;

GRANT EXECUTE ON FUNCTION clinicos_showcase.linked_demo_recipient(p_patient text) TO clinicos_showcase_notifications;

REVOKE ALL ON FUNCTION clinicos_showcase.process_invoice() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_showcase.process_invoice() TO clinicos_showcase_worker;

REVOKE ALL ON FUNCTION clinicos_showcase.queue_notifications() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_showcase.queue_notifications() TO clinicos_showcase_worker;

REVOKE ALL ON FUNCTION clinicos_showcase.telegram_action(bot bigint, sender bigint, update_id bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_showcase.telegram_action(bot bigint, sender bigint, update_id bigint, command text) TO clinicos_p1_schema;

REVOKE ALL ON SCHEMA clinicos_showcase FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA clinicos_showcase TO clinicos_p1_schema;

GRANT USAGE ON SCHEMA clinicos_showcase TO clinicos_showcase_worker;

GRANT USAGE ON SCHEMA clinicos_showcase TO clinicos_showcase_scheduling;

GRANT USAGE ON SCHEMA clinicos_showcase TO clinicos_showcase_notifications;

REVOKE ALL ON TABLE clinicos_showcase.feedback FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.followups FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.handoffs FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.invoice_queue FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.notification_events FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.patient_auth FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.settings FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.staff_auth FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.summary_drafts FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON TABLE clinicos_showcase.telegram_recipients FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION clinicos_staff_private.board(p_date date) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.board(p_date date) TO authenticated;

REVOKE ALL ON FUNCTION clinicos_staff_private.booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.booking_change(p_appointment uuid, p_action text, p_date date, p_start time without time zone, p_end time without time zone) TO authenticated;

REVOKE ALL ON FUNCTION clinicos_staff_private.claim_file(p_doctor text, p_visit text, p_attachment text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.claim_file(p_doctor text, p_visit text, p_attachment text) TO clinicos_notifications_n8n;

REVOKE ALL ON FUNCTION clinicos_staff_private.eligible_chat(p_patient uuid) FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION clinicos_staff_private.finish_file(p_attachment uuid, p_claim uuid, p_state text, p_message bigint) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.finish_file(p_attachment uuid, p_claim uuid, p_state text, p_message bigint) TO clinicos_notifications_n8n;

REVOKE ALL ON FUNCTION clinicos_staff_private.followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.followup(p_visit uuid, p_date date, p_action text, p_start time without time zone, p_end time without time zone) TO authenticated;

REVOKE ALL ON FUNCTION clinicos_staff_private.may_dispatch(p_attachment uuid, p_claim uuid, p_chat text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.may_dispatch(p_attachment uuid, p_claim uuid, p_chat text) TO clinicos_notifications_n8n;

REVOKE ALL ON FUNCTION clinicos_staff_private.visit_files(p_visit uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION clinicos_staff_private.visit_files(p_visit uuid) TO authenticated;

REVOKE ALL ON SCHEMA clinicos_staff_private FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA clinicos_staff_private TO authenticated;

GRANT USAGE ON SCHEMA clinicos_staff_private TO clinicos_notifications_n8n;

REVOKE ALL ON TABLE clinicos_staff_private.file_delivery FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.apply_account_command(actor_bot bigint, actor_user bigint, command text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.apply_account_command(actor_bot bigint, actor_user bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.apply_link_command(p_bot_id bigint, p_update_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.apply_link_command(p_bot_id bigint, p_update_id bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.apply_patient_registration(p_bot_id bigint, p_update_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.apply_patient_registration(p_bot_id bigint, p_update_id bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.apply_registration_consent(p_bot_id bigint, p_update_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.apply_registration_consent(p_bot_id bigint, p_update_id bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.available_commands(actor_bot bigint, actor_user bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.available_commands(actor_bot bigint, actor_user bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.bump_phone_sync_revision() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.bump_phone_sync_revision() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.claim_patient_sync() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.claim_patient_sync() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.claim_patient_sync_v2() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.claim_patient_sync_v2() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.claim_patient_sync_v3() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.claim_patient_sync_v3() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.claim_patient_sync_v3() TO clinicos_p1;

ALTER FUNCTION p1_telegram.claim_reply(p_bot_id bigint, p_update_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.claim_reply(p_bot_id bigint, p_update_id bigint) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.claim_reply(p_bot_id bigint, p_update_id bigint) TO clinicos_p1;

ALTER FUNCTION p1_telegram.claim_welcome_update(p_bot_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.claim_welcome_update(p_bot_id bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.claim_welcome_update(p_bot_id bigint, p_update_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.claim_welcome_update(p_bot_id bigint, p_update_id bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.cleanup_transport() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.cleanup_transport() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.complete_patient_sync(p_patient_id uuid, p_claim_token uuid) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.complete_patient_sync(p_patient_id uuid, p_claim_token uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.complete_patient_sync(p_patient_id uuid, p_claim_token uuid) TO clinicos_p1;

ALTER FUNCTION p1_telegram.complete_reply(p_bot_id bigint, p_delivery_token uuid, p_message_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.complete_reply(p_bot_id bigint, p_delivery_token uuid, p_message_id bigint) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.complete_reply(p_bot_id bigint, p_delivery_token uuid, p_message_id bigint) TO clinicos_p1;

ALTER FUNCTION p1_telegram.complete_staff_sync(p_batch jsonb) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.complete_staff_sync(p_batch jsonb) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.complete_staff_sync(p_batch jsonb) TO clinicos_p1;

ALTER FUNCTION p1_telegram.complete_welcome_update(p_bot_id bigint, p_claim_token uuid, p_message_id bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.complete_welcome_update(p_bot_id bigint, p_claim_token uuid, p_message_id bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.configured_bot_id() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.configured_bot_id() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.configured_bot_id() TO clinicos_p1;

ALTER FUNCTION p1_telegram.draft_matches(draft p1_telegram.registration_drafts) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.draft_matches(draft p1_telegram.registration_drafts) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.enqueue_patient_sync() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.enqueue_patient_sync() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.manage_staff_access(actor_bot bigint, actor_id bigint, command text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.manage_staff_access(actor_bot bigint, actor_id bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.pending_staff_sync() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.pending_staff_sync() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.pending_staff_sync() TO clinicos_p1;

ALTER FUNCTION p1_telegram.queue_phone_edit() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.queue_phone_edit() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.queue_staff_change() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.queue_staff_change() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.queue_telegram_link_change() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.queue_telegram_link_change() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.receive_staff_aware_update(p_bot_id bigint, p_update jsonb) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.receive_staff_aware_update(p_bot_id bigint, p_update jsonb) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.receive_staff_aware_update(p_bot_id bigint, p_update jsonb) TO clinicos_p1;

ALTER FUNCTION p1_telegram.receive_update(p_bot_id bigint, p_update jsonb) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.receive_update(p_bot_id bigint, p_update jsonb) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.record_workflow_error(p_source text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.record_workflow_error(p_source text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p1_telegram.record_workflow_error(p_source text) TO clinicos_p1;

ALTER FUNCTION p1_telegram.refresh_consent_contacts() OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.refresh_consent_contacts() FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.refresh_shared_contact(affected_patient uuid, affected_bot bigint) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.refresh_shared_contact(affected_patient uuid, affected_bot bigint) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.select_telegram_profile(actor_bot bigint, actor_id bigint, command text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.select_telegram_profile(actor_bot bigint, actor_id bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.staff_deletion_review(actor_bot bigint, actor_user bigint, command text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.staff_deletion_review(actor_bot bigint, actor_user bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.staff_duplicate_review(actor_bot bigint, actor_user bigint, command text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.staff_duplicate_review(actor_bot bigint, actor_user bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p1_telegram.telegram_withdrawal(actor_bot bigint, actor_user bigint, command text) OWNER TO clinicos_p1_schema;

REVOKE ALL ON FUNCTION p1_telegram.telegram_withdrawal(actor_bot bigint, actor_user bigint, command text) FROM PUBLIC, anon, authenticated, service_role;

ALTER SCHEMA p1_telegram OWNER TO clinicos_p1_schema;

REVOKE ALL ON SCHEMA p1_telegram FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA p1_telegram TO clinicos_p1;

REVOKE ALL ON SEQUENCE p1_telegram.patient_links_profile_number_seq FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.account_confirmations OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.account_confirmations FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.account_options OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.account_options FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.deletion_requests OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.deletion_requests FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.deletion_review_history OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.deletion_review_history FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.duplicate_dispositions OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.duplicate_dispositions FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.inbox OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.inbox FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.link_audit OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.link_audit FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.link_codes OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.link_codes FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.patient_links OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.patient_links FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.patient_sync_queue OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.patient_sync_queue FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.patients OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.patients FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.phone_edits OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.phone_edits FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.registration_consent OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.registration_consent FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.registration_drafts OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.registration_drafts FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.replies OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.replies FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.staff OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.staff FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.staff_access_confirmation OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.staff_access_confirmation FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.staff_access_owner OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.staff_access_owner FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.staff_sync_queue OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.staff_sync_queue FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.sync_scope OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.sync_scope FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.test_booking_requests OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.test_booking_requests FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.withdrawal_confirmations OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.withdrawal_confirmations FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p1_telegram.workflow_errors OWNER TO clinicos_p1_schema;

REVOKE ALL ON TABLE p1_telegram.workflow_errors FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON SCHEMA p4_demo FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA p4_demo TO p4_demo_runner;

REVOKE ALL ON TABLE p4_demo.booking_confirmation FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT ON TABLE p4_demo.booking_confirmation TO p4_demo_runner;

REVOKE ALL ON TABLE p4_demo.notification_recipient FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p5_private.generate_invoice(p_request text, p_actor uuid, p_visit uuid) OWNER TO p5_entry_owner;

REVOKE ALL ON FUNCTION p5_private.generate_invoice(p_request text, p_actor uuid, p_visit uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p5_private.generate_invoice(p_request text, p_actor uuid, p_visit uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION p5_private.generate_invoice(p_request text, p_actor uuid, p_visit uuid) TO p5_demo_runtime;

ALTER FUNCTION p5_private.get_service(p_actor uuid, p_code text) OWNER TO p5_entry_owner;

REVOKE ALL ON FUNCTION p5_private.get_service(p_actor uuid, p_code text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p5_private.get_service(p_actor uuid, p_code text) TO authenticated;

GRANT EXECUTE ON FUNCTION p5_private.get_service(p_actor uuid, p_code text) TO p5_demo_runtime;

ALTER FUNCTION p5_private.is_demo_admin(p_actor uuid) OWNER TO p5_entry_owner;

REVOKE ALL ON FUNCTION p5_private.is_demo_admin(p_actor uuid) FROM PUBLIC, anon, authenticated, service_role;

ALTER FUNCTION p5_private.save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) OWNER TO p5_entry_owner;

REVOKE ALL ON FUNCTION p5_private.save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION p5_private.save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION p5_private.save_service(p_request text, p_actor uuid, p_action text, p_code text, p_name text, p_price text, p_active boolean) TO p5_demo_runtime;

ALTER SCHEMA p5_private OWNER TO p5_entry_owner;

REVOKE ALL ON SCHEMA p5_private FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE ON SCHEMA p5_private TO authenticated;

GRANT USAGE ON SCHEMA p5_private TO p5_demo_runtime;

ALTER TABLE p5_private.demo_actors OWNER TO p5_entry_owner;

REVOKE ALL ON TABLE p5_private.demo_actors FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE p5_private.requests OWNER TO p5_entry_owner;

REVOKE ALL ON TABLE p5_private.requests FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.claim_waiting_list_entry(uuid, uuid, timestamptz) TO clinicos_showcase_scheduling;

GRANT INSERT (event_id) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT INSERT (event_id) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT INSERT (event_version) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT INSERT (event_version) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT INSERT (recipient_ref) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT INSERT (recipient_ref) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT INSERT (template_key) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT INSERT (template_key) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT INSERT (due_at) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT INSERT (due_at) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT UPDATE (state) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT UPDATE (state) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT UPDATE (state) ON TABLE clinic.p4_notification_outbox TO p4_demo_runner;

GRANT UPDATE (claimed_at) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT UPDATE (claimed_at) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT UPDATE (claimed_at) ON TABLE clinic.p4_notification_outbox TO p4_demo_runner;

GRANT UPDATE (resolved_at) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT UPDATE (resolved_at) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT UPDATE (resolved_at) ON TABLE clinic.p4_notification_outbox TO p4_demo_runner;

GRANT UPDATE (dispatch_started_at) ON TABLE clinic.p4_notification_outbox TO clinicos_showcase_notifications;

GRANT UPDATE (dispatch_started_at) ON TABLE clinic.p4_notification_outbox TO p4_confirmation_worker;

GRANT UPDATE (dispatch_started_at) ON TABLE clinic.p4_notification_outbox TO p4_demo_runner;

GRANT INSERT (offer_id) ON TABLE clinic.p4_waiting_offer_claims TO clinicos_showcase_notifications;

GRANT INSERT (decision) ON TABLE clinic.p4_waiting_offer_claims TO clinicos_showcase_notifications;

GRANT INSERT (id) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (id) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (id) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT SELECT (id) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (id) ON TABLE clinicos_identity.patients TO clinicos_p1_reception;

GRANT SELECT (id) ON TABLE clinicos_identity.patients TO clinicos_p1_scheduling;

GRANT INSERT (full_name) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (full_name) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (full_name) ON TABLE clinicos_identity.patients TO clinicos_p1_reception;

GRANT INSERT (date_of_birth) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (date_of_birth) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (date_of_birth) ON TABLE clinicos_identity.patients TO clinicos_p1_reception;

GRANT INSERT (phone_e164) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (phone_e164) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (phone_e164) ON TABLE clinicos_identity.patients TO clinicos_p1_reception;

GRANT UPDATE (phone_e164) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT UPDATE (phone_e164) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (is_active) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT SELECT (is_active) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (is_active) ON TABLE clinicos_identity.patients TO clinicos_p1_reception;

GRANT SELECT (is_active) ON TABLE clinicos_identity.patients TO clinicos_p1_scheduling;

GRANT INSERT (created_at) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (created_at) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT INSERT (phone_revision) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (phone_revision) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (phone_revision) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT SELECT (phone_revision) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT UPDATE (phone_revision) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT UPDATE (phone_revision) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT INSERT (telegram_chat_id) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (telegram_chat_id) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT UPDATE (telegram_chat_id) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT UPDATE (telegram_chat_id) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT INSERT (telegram_user_id) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (telegram_user_id) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT UPDATE (telegram_user_id) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT UPDATE (telegram_user_id) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT INSERT (telegram_linked_at) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (telegram_linked_at) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT UPDATE (telegram_linked_at) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT UPDATE (telegram_linked_at) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT INSERT (profile_sync_revision) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT INSERT (profile_sync_revision) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT SELECT (profile_sync_revision) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT SELECT (profile_sync_revision) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT UPDATE (profile_sync_revision) ON TABLE clinicos_identity.patients TO clinicos_identity_sync;

GRANT UPDATE (profile_sync_revision) ON TABLE clinicos_identity.patients TO clinicos_p1_patient_writer;

GRANT UPDATE (delivery_status) ON TABLE p4_demo.booking_confirmation TO p4_demo_runner;

GRANT SELECT (id) ON TABLE public.appointments TO clinicos_showcase_notifications;

GRANT SELECT (id) ON TABLE public.appointments TO p4_confirmation_worker;

GRANT SELECT (patient_id) ON TABLE public.appointments TO clinicos_showcase_notifications;

GRANT SELECT (patient_id) ON TABLE public.appointments TO p4_confirmation_worker;

GRANT SELECT (appointment_date) ON TABLE public.appointments TO clinicos_showcase_notifications;

GRANT SELECT (appointment_date) ON TABLE public.appointments TO p4_confirmation_worker;

GRANT SELECT (start_time) ON TABLE public.appointments TO clinicos_showcase_notifications;

GRANT SELECT (start_time) ON TABLE public.appointments TO p4_confirmation_worker;

GRANT SELECT (status) ON TABLE public.appointments TO clinicos_showcase_notifications;

GRANT SELECT (status) ON TABLE public.appointments TO p4_confirmation_worker;

GRANT UPDATE (status) ON TABLE public.available_slot_events TO clinicos_showcase_scheduling;

GRANT UPDATE (updated_at) ON TABLE public.available_slot_events TO clinicos_showcase_scheduling;

GRANT SELECT (id) ON TABLE public.booking_requests TO clinicos_showcase_notifications;

GRANT SELECT (id) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT SELECT (id) ON TABLE public.booking_requests TO p4_confirmation_worker;

GRANT INSERT (patient_id) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT SELECT (patient_id) ON TABLE public.booking_requests TO clinicos_showcase_notifications;

GRANT SELECT (patient_id) ON TABLE public.booking_requests TO p4_confirmation_worker;

GRANT INSERT (doctor_id) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT INSERT (appointment_date) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT INSERT (start_time) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT INSERT (end_time) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT INSERT (status) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT SELECT (status) ON TABLE public.booking_requests TO clinicos_showcase_notifications;

GRANT SELECT (status) ON TABLE public.booking_requests TO p4_confirmation_worker;

GRANT SELECT (appointment_id) ON TABLE public.booking_requests TO clinicos_showcase_notifications;

GRANT SELECT (appointment_id) ON TABLE public.booking_requests TO p4_confirmation_worker;

GRANT SELECT (updated_at) ON TABLE public.booking_requests TO clinicos_showcase_notifications;

GRANT SELECT (updated_at) ON TABLE public.booking_requests TO p4_confirmation_worker;

GRANT UPDATE (updated_at) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT INSERT (idempotency_key) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT SELECT (idempotency_key) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT INSERT (waiting_list_offer_id) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT SELECT (waiting_list_offer_id) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT UPDATE (waiting_list_offer_id) ON TABLE public.booking_requests TO clinicos_showcase_scheduling;

GRANT SELECT (id) ON TABLE public.notification_outbox TO clinicos_showcase_notifications;

GRANT SELECT (offer_id) ON TABLE public.notification_outbox TO clinicos_showcase_notifications;

GRANT SELECT (event_type) ON TABLE public.notification_outbox TO clinicos_showcase_notifications;

GRANT SELECT (payload) ON TABLE public.notification_outbox TO clinicos_showcase_notifications;

GRANT SELECT (status) ON TABLE public.notification_outbox TO clinicos_showcase_notifications;

GRANT UPDATE (status) ON TABLE public.notification_outbox TO clinicos_showcase_notifications;

GRANT UPDATE (id) ON TABLE public.performed_services TO p5_entry_owner;

GRANT SELECT (id) ON TABLE public.visit_revisions TO p5_entry_owner;

GRANT SELECT (visit_id) ON TABLE public.visit_revisions TO p5_entry_owner;

GRANT UPDATE (id) ON TABLE public.visits TO p5_entry_owner;

GRANT UPDATE (status) ON TABLE public.wait_list TO clinicos_showcase_scheduling;

GRANT UPDATE (offer_expires_at) ON TABLE public.wait_list TO clinicos_showcase_scheduling;

GRANT UPDATE (updated_at) ON TABLE public.wait_list TO clinicos_showcase_scheduling;

GRANT SELECT (id) ON TABLE public.waiting_list_offers TO clinicos_showcase_notifications;

GRANT SELECT (patient_id) ON TABLE public.waiting_list_offers TO clinicos_showcase_notifications;

GRANT SELECT (status) ON TABLE public.waiting_list_offers TO clinicos_showcase_notifications;

GRANT UPDATE (status) ON TABLE public.waiting_list_offers TO clinicos_showcase_scheduling;

GRANT SELECT (expires_at) ON TABLE public.waiting_list_offers TO clinicos_showcase_notifications;

GRANT UPDATE (responded_at) ON TABLE public.waiting_list_offers TO clinicos_showcase_scheduling;

GRANT UPDATE (booking_request_id) ON TABLE public.waiting_list_offers TO clinicos_showcase_scheduling;

GRANT UPDATE (updated_at) ON TABLE public.waiting_list_offers TO clinicos_showcase_scheduling;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('visit-files', 'visit-files', false, 5242880, ARRAY['application/pdf', 'image/png', 'image/jpeg']);

RESET search_path;
