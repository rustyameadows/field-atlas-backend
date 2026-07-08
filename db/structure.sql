SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: api_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    device_id uuid,
    access_token_digest character varying NOT NULL,
    refresh_token_digest character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    refresh_expires_at timestamp(6) without time zone NOT NULL,
    last_used_at timestamp(6) without time zone,
    revoked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: asset_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asset_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    attachable_type character varying NOT NULL,
    attachable_id character varying,
    attachable_ref jsonb DEFAULT '{}'::jsonb NOT NULL,
    role character varying DEFAULT 'gallery'::character varying NOT NULL,
    caption text,
    sort_order double precision DEFAULT 0.0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    revision integer DEFAULT 1 NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    uploaded_by_user_id uuid NOT NULL,
    client_id character varying,
    asset_kind character varying NOT NULL,
    mime_type character varying NOT NULL,
    original_filename character varying,
    byte_size bigint DEFAULT 0 NOT NULL,
    checksum character varying,
    storage_provider character varying DEFAULT 'r2'::character varying NOT NULL,
    storage_key character varying NOT NULL,
    width integer,
    height integer,
    duration_ms integer,
    status character varying DEFAULT 'awaiting_upload'::character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    revision integer DEFAULT 1 NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_operations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    operation_id character varying NOT NULL,
    device_id uuid NOT NULL,
    user_id uuid NOT NULL,
    entity_type character varying NOT NULL,
    entity_id character varying NOT NULL,
    action character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    base_revision integer,
    client_created_at timestamp(6) without time zone,
    received_at timestamp(6) without time zone NOT NULL,
    processed_at timestamp(6) without time zone,
    status character varying,
    result jsonb DEFAULT '{}'::jsonb NOT NULL,
    error_code character varying,
    message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: deleted_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deleted_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_type character varying NOT NULL,
    entity_id uuid NOT NULL,
    trip_id uuid,
    user_id uuid,
    deleted_at timestamp(6) without time zone NOT NULL,
    revision integer DEFAULT 1 NOT NULL,
    deleted_by_user_id uuid,
    deleted_by_device_id uuid,
    reason character varying DEFAULT 'deleted'::character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    client_device_id character varying NOT NULL,
    name character varying,
    platform character varying DEFAULT 'ios'::character varying NOT NULL,
    app_version character varying,
    build_number character varying,
    push_token character varying,
    push_environment character varying,
    last_seen_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: drive_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drive_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    trip_id uuid,
    route_snapshot_id uuid,
    client_id character varying,
    started_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    encoded_session jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: favorite_places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_places (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    client_id character varying,
    place_id character varying NOT NULL,
    name character varying,
    favorited_at timestamp(6) without time zone,
    encoded_place jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: memory_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memory_assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    trip_id uuid,
    drive_session_id uuid,
    client_id character varying,
    kind character varying NOT NULL,
    title character varying,
    local_file_name character varying,
    transcript text,
    transcript_status character varying,
    encoded_asset jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: park_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.park_units (
    id bigint NOT NULL,
    place_id bigint NOT NULL,
    agency character varying NOT NULL,
    designation character varying,
    states character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    official_code character varying,
    source_provider character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: park_units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.park_units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: park_units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.park_units_id_seq OWNED BY public.park_units.id;


--
-- Name: place_containments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.place_containments (
    id bigint NOT NULL,
    containing_place_id bigint NOT NULL,
    source_record_id bigint NOT NULL,
    relationship_type character varying DEFAULT 'contains'::character varying NOT NULL,
    confidence numeric(5,4) DEFAULT 0.0 NOT NULL,
    review_status character varying DEFAULT 'auto'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: place_containments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.place_containments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: place_containments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.place_containments_id_seq OWNED BY public.place_containments.id;


--
-- Name: place_external_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.place_external_identifiers (
    id bigint NOT NULL,
    place_id bigint NOT NULL,
    provider character varying NOT NULL,
    identifier character varying NOT NULL,
    identifier_kind character varying DEFAULT 'primary'::character varying NOT NULL,
    review_status character varying DEFAULT 'verified'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: place_external_identifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.place_external_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: place_external_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.place_external_identifiers_id_seq OWNED BY public.place_external_identifiers.id;


--
-- Name: place_list_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.place_list_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_list_id uuid NOT NULL,
    client_id character varying,
    place_id character varying NOT NULL,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    added_at timestamp(6) without time zone,
    encoded_place jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: place_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.place_lists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    client_id character varying,
    name character varying NOT NULL,
    marker_shape character varying,
    marker_color_red double precision,
    marker_color_green double precision,
    marker_color_blue double precision,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: place_source_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.place_source_links (
    id bigint NOT NULL,
    place_id bigint NOT NULL,
    source_record_id bigint NOT NULL,
    match_type character varying NOT NULL,
    confidence numeric(5,4) DEFAULT 0.0 NOT NULL,
    review_status character varying DEFAULT 'auto'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: place_source_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.place_source_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: place_source_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.place_source_links_id_seq OWNED BY public.place_source_links.id;


--
-- Name: places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    kind character varying NOT NULL,
    status character varying DEFAULT 'published'::character varying NOT NULL,
    primary_category character varying,
    geometry public.geography(Geometry,4326),
    centroid public.geography(Point,4326),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.places_id_seq OWNED BY public.places.id;


--
-- Name: route_legs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_legs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    route_snapshot_id uuid NOT NULL,
    source_stop_id uuid,
    destination_stop_id uuid,
    client_id character varying,
    name character varying,
    label character varying,
    distance_meters double precision DEFAULT 0.0 NOT NULL,
    expected_travel_time double precision DEFAULT 0.0 NOT NULL,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    encoded_polyline jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_snapshot_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_snapshot_stops (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    route_snapshot_id uuid NOT NULL,
    trip_stop_id uuid,
    client_id character varying,
    kind character varying NOT NULL,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    latitude double precision,
    longitude double precision,
    title character varying NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_snapshots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_id uuid NOT NULL,
    trip_segment_id uuid,
    created_by_user_id uuid,
    created_by_device_id uuid,
    client_id character varying,
    provider character varying DEFAULT 'apple-mapkit'::character varying NOT NULL,
    stale boolean DEFAULT false NOT NULL,
    total_distance_meters double precision DEFAULT 0.0 NOT NULL,
    expected_travel_time double precision DEFAULT 0.0 NOT NULL,
    routing_signature jsonb DEFAULT '{}'::jsonb NOT NULL,
    encoded_route jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_steps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    route_leg_id uuid NOT NULL,
    client_id character varying,
    instructions text NOT NULL,
    notice text,
    distance_meters double precision DEFAULT 0.0 NOT NULL,
    transport_type character varying,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    encoded_polyline jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: search_history_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.search_history_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    client_id character varying,
    query character varying NOT NULL,
    searched_at timestamp(6) without time zone,
    latitude double precision,
    longitude double precision,
    encoded_entry jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: search_result_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.search_result_snapshots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_type character varying NOT NULL,
    owner_id uuid NOT NULL,
    client_id character varying,
    place_id character varying NOT NULL,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    encoded_place jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: search_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.search_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    search_history_entry_id uuid,
    client_id character varying,
    query character varying NOT NULL,
    encoded_session jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_cable_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_cable_messages (
    id bigint NOT NULL,
    channel bytea NOT NULL,
    payload bytea NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    channel_hash bigint NOT NULL
);


--
-- Name: solid_cable_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_cable_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_cable_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_cable_messages_id_seq OWNED BY public.solid_cable_messages.id;


--
-- Name: solid_cache_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_cache_entries (
    id bigint NOT NULL,
    key bytea NOT NULL,
    value bytea NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    key_hash bigint NOT NULL,
    byte_size integer NOT NULL
);


--
-- Name: solid_cache_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_cache_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_cache_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_cache_entries_id_seq OWNED BY public.solid_cache_entries.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: source_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source_datasets (
    id bigint NOT NULL,
    provider character varying NOT NULL,
    name character varying NOT NULL,
    source_url character varying,
    freshness_mode character varying NOT NULL,
    last_checked_at timestamp(6) without time zone,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: source_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.source_datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.source_datasets_id_seq OWNED BY public.source_datasets.id;


--
-- Name: source_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source_records (
    id bigint NOT NULL,
    source_dataset_id bigint NOT NULL,
    provider character varying NOT NULL,
    record_type character varying NOT NULL,
    source_id character varying NOT NULL,
    name character varying NOT NULL,
    normalized_name character varying NOT NULL,
    geometry public.geography(Geometry,4326),
    centroid public.geography(Point,4326),
    raw_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    normalized_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload_hash character varying NOT NULL,
    fetched_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: source_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.source_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.source_records_id_seq OWNED BY public.source_records.id;


--
-- Name: sync_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_events (
    id bigint NOT NULL,
    event_uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_type character varying NOT NULL,
    entity_id uuid NOT NULL,
    trip_id uuid,
    user_id uuid,
    actor_user_id uuid,
    actor_device_id uuid,
    action character varying NOT NULL,
    record_revision integer NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sync_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sync_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sync_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sync_events_id_seq OWNED BY public.sync_events.id;


--
-- Name: trip_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_invites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_id uuid NOT NULL,
    invited_by_user_id uuid NOT NULL,
    accepted_by_user_id uuid,
    token character varying NOT NULL,
    url character varying,
    role character varying DEFAULT 'editor'::character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    expires_at timestamp(6) without time zone,
    accepted_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_id uuid NOT NULL,
    user_id uuid NOT NULL,
    display_name character varying,
    role character varying DEFAULT 'viewer'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    joined_at timestamp(6) without time zone NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_segments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_id uuid NOT NULL,
    client_id character varying,
    title character varying NOT NULL,
    container_type character varying,
    segment_kind character varying,
    auto_day_index integer,
    parent_segment_id uuid,
    start_date date,
    end_date date,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    color_token_id character varying,
    encoded_segment jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_stop_option_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_stop_option_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_id uuid NOT NULL,
    client_id character varying,
    group_id character varying NOT NULL,
    parent_stop_id uuid NOT NULL,
    candidate_stop_id uuid NOT NULL,
    group_title character varying,
    role character varying,
    status character varying,
    is_selected boolean DEFAULT false NOT NULL,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_stops (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_id uuid NOT NULL,
    trip_segment_id uuid,
    created_by_user_id uuid,
    created_by_device_id uuid,
    canonical_place_id bigint,
    client_id character varying,
    item_id character varying,
    placement_id character varying,
    kind character varying NOT NULL,
    title character varying NOT NULL,
    subtitle character varying,
    notes text,
    sort_key double precision DEFAULT 0.0 NOT NULL,
    place_title character varying,
    place_subtitle character varying,
    address character varying,
    latitude double precision,
    longitude double precision,
    source character varying,
    source_identifier character varying,
    provider character varying,
    provider_id character varying,
    source_ids jsonb DEFAULT '{}'::jsonb NOT NULL,
    location_target jsonb DEFAULT '{}'::jsonb NOT NULL,
    encoded_item jsonb DEFAULT '{}'::jsonb NOT NULL,
    encoded_placement jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_user_id uuid NOT NULL,
    created_by_device_id uuid,
    client_id character varying,
    title character varying NOT NULL,
    start_date date,
    end_date date,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    encoded_workspace jsonb DEFAULT '{}'::jsonb NOT NULL,
    client_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_auth_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_auth_identities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider character varying NOT NULL,
    provider_subject character varying NOT NULL,
    email character varying,
    email_verified boolean DEFAULT false NOT NULL,
    display_name character varying,
    raw_claims jsonb DEFAULT '{}'::jsonb NOT NULL,
    last_verified_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    key character varying NOT NULL,
    value text,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    display_name character varying,
    email character varying,
    email_verified boolean DEFAULT false NOT NULL,
    time_zone character varying,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp(6) without time zone,
    revision integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    username character varying,
    bio text,
    profile_photo_asset_id uuid
);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: park_units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.park_units ALTER COLUMN id SET DEFAULT nextval('public.park_units_id_seq'::regclass);


--
-- Name: place_containments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_containments ALTER COLUMN id SET DEFAULT nextval('public.place_containments_id_seq'::regclass);


--
-- Name: place_external_identifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_external_identifiers ALTER COLUMN id SET DEFAULT nextval('public.place_external_identifiers_id_seq'::regclass);


--
-- Name: place_source_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_source_links ALTER COLUMN id SET DEFAULT nextval('public.place_source_links_id_seq'::regclass);


--
-- Name: places id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places ALTER COLUMN id SET DEFAULT nextval('public.places_id_seq'::regclass);


--
-- Name: solid_cable_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cable_messages ALTER COLUMN id SET DEFAULT nextval('public.solid_cable_messages_id_seq'::regclass);


--
-- Name: solid_cache_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cache_entries ALTER COLUMN id SET DEFAULT nextval('public.solid_cache_entries_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: source_datasets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_datasets ALTER COLUMN id SET DEFAULT nextval('public.source_datasets_id_seq'::regclass);


--
-- Name: source_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_records ALTER COLUMN id SET DEFAULT nextval('public.source_records_id_seq'::regclass);


--
-- Name: sync_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events ALTER COLUMN id SET DEFAULT nextval('public.sync_events_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: api_sessions api_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_sessions
    ADD CONSTRAINT api_sessions_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: asset_links asset_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_links
    ADD CONSTRAINT asset_links_pkey PRIMARY KEY (id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: client_operations client_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_operations
    ADD CONSTRAINT client_operations_pkey PRIMARY KEY (id);


--
-- Name: deleted_records deleted_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_records
    ADD CONSTRAINT deleted_records_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: drive_sessions drive_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drive_sessions
    ADD CONSTRAINT drive_sessions_pkey PRIMARY KEY (id);


--
-- Name: favorite_places favorite_places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_places
    ADD CONSTRAINT favorite_places_pkey PRIMARY KEY (id);


--
-- Name: memory_assets memory_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_assets
    ADD CONSTRAINT memory_assets_pkey PRIMARY KEY (id);


--
-- Name: park_units park_units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.park_units
    ADD CONSTRAINT park_units_pkey PRIMARY KEY (id);


--
-- Name: place_containments place_containments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_containments
    ADD CONSTRAINT place_containments_pkey PRIMARY KEY (id);


--
-- Name: place_external_identifiers place_external_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_external_identifiers
    ADD CONSTRAINT place_external_identifiers_pkey PRIMARY KEY (id);


--
-- Name: place_list_items place_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_list_items
    ADD CONSTRAINT place_list_items_pkey PRIMARY KEY (id);


--
-- Name: place_lists place_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_lists
    ADD CONSTRAINT place_lists_pkey PRIMARY KEY (id);


--
-- Name: place_source_links place_source_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_source_links
    ADD CONSTRAINT place_source_links_pkey PRIMARY KEY (id);


--
-- Name: places places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id);


--
-- Name: route_legs route_legs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_legs
    ADD CONSTRAINT route_legs_pkey PRIMARY KEY (id);


--
-- Name: route_snapshot_stops route_snapshot_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshot_stops
    ADD CONSTRAINT route_snapshot_stops_pkey PRIMARY KEY (id);


--
-- Name: route_snapshots route_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshots
    ADD CONSTRAINT route_snapshots_pkey PRIMARY KEY (id);


--
-- Name: route_steps route_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_steps
    ADD CONSTRAINT route_steps_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: search_history_entries search_history_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_history_entries
    ADD CONSTRAINT search_history_entries_pkey PRIMARY KEY (id);


--
-- Name: search_result_snapshots search_result_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_result_snapshots
    ADD CONSTRAINT search_result_snapshots_pkey PRIMARY KEY (id);


--
-- Name: search_sessions search_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sessions
    ADD CONSTRAINT search_sessions_pkey PRIMARY KEY (id);


--
-- Name: solid_cable_messages solid_cable_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cable_messages
    ADD CONSTRAINT solid_cable_messages_pkey PRIMARY KEY (id);


--
-- Name: solid_cache_entries solid_cache_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cache_entries
    ADD CONSTRAINT solid_cache_entries_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: source_datasets source_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_datasets
    ADD CONSTRAINT source_datasets_pkey PRIMARY KEY (id);


--
-- Name: source_records source_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_records
    ADD CONSTRAINT source_records_pkey PRIMARY KEY (id);


--
-- Name: sync_events sync_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events
    ADD CONSTRAINT sync_events_pkey PRIMARY KEY (id);


--
-- Name: trip_invites trip_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_invites
    ADD CONSTRAINT trip_invites_pkey PRIMARY KEY (id);


--
-- Name: trip_members trip_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_members
    ADD CONSTRAINT trip_members_pkey PRIMARY KEY (id);


--
-- Name: trip_segments trip_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_segments
    ADD CONSTRAINT trip_segments_pkey PRIMARY KEY (id);


--
-- Name: trip_stop_option_links trip_stop_option_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_option_links
    ADD CONSTRAINT trip_stop_option_links_pkey PRIMARY KEY (id);


--
-- Name: trip_stops trip_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT trip_stops_pkey PRIMARY KEY (id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (id);


--
-- Name: user_auth_identities user_auth_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_auth_identities
    ADD CONSTRAINT user_auth_identities_pkey PRIMARY KEY (id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_asset_links_attachable_role_deleted_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asset_links_attachable_role_deleted_sort ON public.asset_links USING btree (attachable_type, attachable_id, role, deleted_at, sort_order);


--
-- Name: idx_auth_identities_provider_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_auth_identities_provider_subject ON public.user_auth_identities USING btree (provider, provider_subject);


--
-- Name: idx_on_containing_place_id_source_record_id_bec21fb831; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_containing_place_id_source_record_id_bec21fb831 ON public.place_containments USING btree (containing_place_id, source_record_id);


--
-- Name: idx_option_links_trip_group_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_option_links_trip_group_sort ON public.trip_stop_option_links USING btree (trip_id, group_id, sort_key);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_api_sessions_on_access_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_sessions_on_access_token_digest ON public.api_sessions USING btree (access_token_digest);


--
-- Name: index_api_sessions_on_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_sessions_on_device_id ON public.api_sessions USING btree (device_id);


--
-- Name: index_api_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_sessions_on_expires_at ON public.api_sessions USING btree (expires_at);


--
-- Name: index_api_sessions_on_refresh_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_sessions_on_refresh_token_digest ON public.api_sessions USING btree (refresh_token_digest);


--
-- Name: index_api_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_sessions_on_user_id ON public.api_sessions USING btree (user_id);


--
-- Name: index_asset_links_on_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_links_on_asset_id ON public.asset_links USING btree (asset_id);


--
-- Name: index_asset_links_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_links_on_created_by_user_id ON public.asset_links USING btree (created_by_user_id);


--
-- Name: index_asset_links_on_created_by_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_links_on_created_by_user_id_and_created_at ON public.asset_links USING btree (created_by_user_id, created_at);


--
-- Name: index_asset_links_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_links_on_deleted_at ON public.asset_links USING btree (deleted_at);


--
-- Name: index_assets_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_deleted_at ON public.assets USING btree (deleted_at);


--
-- Name: index_assets_on_status_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_status_and_created_at ON public.assets USING btree (status, created_at);


--
-- Name: index_assets_on_storage_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assets_on_storage_key ON public.assets USING btree (storage_key);


--
-- Name: index_assets_on_uploaded_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_uploaded_by_user_id ON public.assets USING btree (uploaded_by_user_id);


--
-- Name: index_assets_on_uploaded_by_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assets_on_uploaded_by_user_id_and_client_id ON public.assets USING btree (uploaded_by_user_id, client_id) WHERE (client_id IS NOT NULL);


--
-- Name: index_assets_on_uploaded_by_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_uploaded_by_user_id_and_created_at ON public.assets USING btree (uploaded_by_user_id, created_at);


--
-- Name: index_client_operations_on_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_operations_on_device_id ON public.client_operations USING btree (device_id);


--
-- Name: index_client_operations_on_device_id_and_operation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_operations_on_device_id_and_operation_id ON public.client_operations USING btree (device_id, operation_id);


--
-- Name: index_client_operations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_operations_on_user_id ON public.client_operations USING btree (user_id);


--
-- Name: index_deleted_records_on_deleted_by_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deleted_records_on_deleted_by_device_id ON public.deleted_records USING btree (deleted_by_device_id);


--
-- Name: index_deleted_records_on_deleted_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deleted_records_on_deleted_by_user_id ON public.deleted_records USING btree (deleted_by_user_id);


--
-- Name: index_deleted_records_on_entity_type_and_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deleted_records_on_entity_type_and_entity_id ON public.deleted_records USING btree (entity_type, entity_id);


--
-- Name: index_deleted_records_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deleted_records_on_trip_id ON public.deleted_records USING btree (trip_id);


--
-- Name: index_deleted_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deleted_records_on_user_id ON public.deleted_records USING btree (user_id);


--
-- Name: index_devices_on_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_devices_on_last_seen_at ON public.devices USING btree (last_seen_at);


--
-- Name: index_devices_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_devices_on_user_id ON public.devices USING btree (user_id);


--
-- Name: index_devices_on_user_id_and_client_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_devices_on_user_id_and_client_device_id ON public.devices USING btree (user_id, client_device_id);


--
-- Name: index_drive_sessions_on_route_snapshot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drive_sessions_on_route_snapshot_id ON public.drive_sessions USING btree (route_snapshot_id);


--
-- Name: index_drive_sessions_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drive_sessions_on_trip_id ON public.drive_sessions USING btree (trip_id);


--
-- Name: index_drive_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drive_sessions_on_user_id ON public.drive_sessions USING btree (user_id);


--
-- Name: index_drive_sessions_on_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drive_sessions_on_user_id_and_client_id ON public.drive_sessions USING btree (user_id, client_id);


--
-- Name: index_favorite_places_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_places_on_user_id ON public.favorite_places USING btree (user_id);


--
-- Name: index_favorite_places_on_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_places_on_user_id_and_client_id ON public.favorite_places USING btree (user_id, client_id);


--
-- Name: index_memory_assets_on_drive_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memory_assets_on_drive_session_id ON public.memory_assets USING btree (drive_session_id);


--
-- Name: index_memory_assets_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memory_assets_on_trip_id ON public.memory_assets USING btree (trip_id);


--
-- Name: index_memory_assets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memory_assets_on_user_id ON public.memory_assets USING btree (user_id);


--
-- Name: index_memory_assets_on_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memory_assets_on_user_id_and_client_id ON public.memory_assets USING btree (user_id, client_id);


--
-- Name: index_park_units_on_agency_and_official_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_park_units_on_agency_and_official_code ON public.park_units USING btree (agency, official_code);


--
-- Name: index_park_units_on_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_park_units_on_place_id ON public.park_units USING btree (place_id);


--
-- Name: index_place_containments_on_containing_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_containments_on_containing_place_id ON public.place_containments USING btree (containing_place_id);


--
-- Name: index_place_containments_on_relationship_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_containments_on_relationship_type ON public.place_containments USING btree (relationship_type);


--
-- Name: index_place_containments_on_review_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_containments_on_review_status ON public.place_containments USING btree (review_status);


--
-- Name: index_place_containments_on_source_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_containments_on_source_record_id ON public.place_containments USING btree (source_record_id);


--
-- Name: index_place_external_identifiers_on_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_external_identifiers_on_place_id ON public.place_external_identifiers USING btree (place_id);


--
-- Name: index_place_external_identifiers_on_place_id_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_external_identifiers_on_place_id_and_provider ON public.place_external_identifiers USING btree (place_id, provider);


--
-- Name: index_place_external_identifiers_on_provider_and_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_place_external_identifiers_on_provider_and_identifier ON public.place_external_identifiers USING btree (provider, identifier);


--
-- Name: index_place_external_identifiers_on_review_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_external_identifiers_on_review_status ON public.place_external_identifiers USING btree (review_status);


--
-- Name: index_place_list_items_on_place_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_list_items_on_place_list_id ON public.place_list_items USING btree (place_list_id);


--
-- Name: index_place_lists_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_lists_on_user_id ON public.place_lists USING btree (user_id);


--
-- Name: index_place_lists_on_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_lists_on_user_id_and_client_id ON public.place_lists USING btree (user_id, client_id);


--
-- Name: index_place_source_links_on_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_source_links_on_place_id ON public.place_source_links USING btree (place_id);


--
-- Name: index_place_source_links_on_place_id_and_source_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_place_source_links_on_place_id_and_source_record_id ON public.place_source_links USING btree (place_id, source_record_id);


--
-- Name: index_place_source_links_on_review_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_source_links_on_review_status ON public.place_source_links USING btree (review_status);


--
-- Name: index_place_source_links_on_source_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_place_source_links_on_source_record_id ON public.place_source_links USING btree (source_record_id);


--
-- Name: index_places_on_centroid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_centroid ON public.places USING gist (centroid);


--
-- Name: index_places_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_geometry ON public.places USING gist (geometry);


--
-- Name: index_places_on_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_kind ON public.places USING btree (kind);


--
-- Name: index_places_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_places_on_slug ON public.places USING btree (slug);


--
-- Name: index_places_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_status ON public.places USING btree (status);


--
-- Name: index_route_legs_on_destination_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_legs_on_destination_stop_id ON public.route_legs USING btree (destination_stop_id);


--
-- Name: index_route_legs_on_route_snapshot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_legs_on_route_snapshot_id ON public.route_legs USING btree (route_snapshot_id);


--
-- Name: index_route_legs_on_source_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_legs_on_source_stop_id ON public.route_legs USING btree (source_stop_id);


--
-- Name: index_route_snapshot_stops_on_route_snapshot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshot_stops_on_route_snapshot_id ON public.route_snapshot_stops USING btree (route_snapshot_id);


--
-- Name: index_route_snapshot_stops_on_trip_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshot_stops_on_trip_stop_id ON public.route_snapshot_stops USING btree (trip_stop_id);


--
-- Name: index_route_snapshots_on_created_by_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshots_on_created_by_device_id ON public.route_snapshots USING btree (created_by_device_id);


--
-- Name: index_route_snapshots_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshots_on_created_by_user_id ON public.route_snapshots USING btree (created_by_user_id);


--
-- Name: index_route_snapshots_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshots_on_trip_id ON public.route_snapshots USING btree (trip_id);


--
-- Name: index_route_snapshots_on_trip_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshots_on_trip_id_and_client_id ON public.route_snapshots USING btree (trip_id, client_id);


--
-- Name: index_route_snapshots_on_trip_id_and_trip_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshots_on_trip_id_and_trip_segment_id ON public.route_snapshots USING btree (trip_id, trip_segment_id);


--
-- Name: index_route_snapshots_on_trip_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_snapshots_on_trip_segment_id ON public.route_snapshots USING btree (trip_segment_id);


--
-- Name: index_route_steps_on_route_leg_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_steps_on_route_leg_id ON public.route_steps USING btree (route_leg_id);


--
-- Name: index_search_history_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_search_history_entries_on_user_id ON public.search_history_entries USING btree (user_id);


--
-- Name: index_search_history_entries_on_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_search_history_entries_on_user_id_and_client_id ON public.search_history_entries USING btree (user_id, client_id);


--
-- Name: index_search_sessions_on_search_history_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_search_sessions_on_search_history_entry_id ON public.search_sessions USING btree (search_history_entry_id);


--
-- Name: index_search_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_search_sessions_on_user_id ON public.search_sessions USING btree (user_id);


--
-- Name: index_search_sessions_on_user_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_search_sessions_on_user_id_and_client_id ON public.search_sessions USING btree (user_id, client_id);


--
-- Name: index_solid_cable_messages_on_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cable_messages_on_channel ON public.solid_cable_messages USING btree (channel);


--
-- Name: index_solid_cable_messages_on_channel_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cable_messages_on_channel_hash ON public.solid_cable_messages USING btree (channel_hash);


--
-- Name: index_solid_cable_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cable_messages_on_created_at ON public.solid_cable_messages USING btree (created_at);


--
-- Name: index_solid_cache_entries_on_byte_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cache_entries_on_byte_size ON public.solid_cache_entries USING btree (byte_size);


--
-- Name: index_solid_cache_entries_on_key_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_cache_entries_on_key_hash ON public.solid_cache_entries USING btree (key_hash);


--
-- Name: index_solid_cache_entries_on_key_hash_and_byte_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cache_entries_on_key_hash_and_byte_size ON public.solid_cache_entries USING btree (key_hash, byte_size);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_source_datasets_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_source_datasets_on_provider ON public.source_datasets USING btree (provider);


--
-- Name: index_source_datasets_on_provider_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_source_datasets_on_provider_and_name ON public.source_datasets USING btree (provider, name);


--
-- Name: index_source_records_on_centroid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_source_records_on_centroid ON public.source_records USING gist (centroid);


--
-- Name: index_source_records_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_source_records_on_geometry ON public.source_records USING gist (geometry);


--
-- Name: index_source_records_on_normalized_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_source_records_on_normalized_name ON public.source_records USING btree (normalized_name);


--
-- Name: index_source_records_on_provider_and_record_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_source_records_on_provider_and_record_type ON public.source_records USING btree (provider, record_type);


--
-- Name: index_source_records_on_provider_and_record_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_source_records_on_provider_and_record_type_and_source_id ON public.source_records USING btree (provider, record_type, source_id);


--
-- Name: index_source_records_on_source_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_source_records_on_source_dataset_id ON public.source_records USING btree (source_dataset_id);


--
-- Name: index_sync_events_on_actor_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_events_on_actor_device_id ON public.sync_events USING btree (actor_device_id);


--
-- Name: index_sync_events_on_actor_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_events_on_actor_user_id ON public.sync_events USING btree (actor_user_id);


--
-- Name: index_sync_events_on_entity_type_and_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_events_on_entity_type_and_entity_id ON public.sync_events USING btree (entity_type, entity_id);


--
-- Name: index_sync_events_on_event_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sync_events_on_event_uuid ON public.sync_events USING btree (event_uuid);


--
-- Name: index_sync_events_on_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_events_on_occurred_at ON public.sync_events USING btree (occurred_at);


--
-- Name: index_sync_events_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_events_on_trip_id ON public.sync_events USING btree (trip_id);


--
-- Name: index_sync_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_events_on_user_id ON public.sync_events USING btree (user_id);


--
-- Name: index_trip_invites_on_accepted_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_invites_on_accepted_by_user_id ON public.trip_invites USING btree (accepted_by_user_id);


--
-- Name: index_trip_invites_on_invited_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_invites_on_invited_by_user_id ON public.trip_invites USING btree (invited_by_user_id);


--
-- Name: index_trip_invites_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_invites_on_token ON public.trip_invites USING btree (token);


--
-- Name: index_trip_invites_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_invites_on_trip_id ON public.trip_invites USING btree (trip_id);


--
-- Name: index_trip_invites_on_trip_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_invites_on_trip_id_and_status ON public.trip_invites USING btree (trip_id, status);


--
-- Name: index_trip_members_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_members_on_trip_id ON public.trip_members USING btree (trip_id);


--
-- Name: index_trip_members_on_trip_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_members_on_trip_id_and_user_id ON public.trip_members USING btree (trip_id, user_id);


--
-- Name: index_trip_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_members_on_user_id ON public.trip_members USING btree (user_id);


--
-- Name: index_trip_members_on_user_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_members_on_user_id_and_status ON public.trip_members USING btree (user_id, status);


--
-- Name: index_trip_segments_on_parent_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_segments_on_parent_segment_id ON public.trip_segments USING btree (parent_segment_id);


--
-- Name: index_trip_segments_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_segments_on_trip_id ON public.trip_segments USING btree (trip_id);


--
-- Name: index_trip_segments_on_trip_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_segments_on_trip_id_and_client_id ON public.trip_segments USING btree (trip_id, client_id);


--
-- Name: index_trip_segments_on_trip_id_and_sort_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_segments_on_trip_id_and_sort_key ON public.trip_segments USING btree (trip_id, sort_key);


--
-- Name: index_trip_stop_option_links_on_candidate_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_option_links_on_candidate_stop_id ON public.trip_stop_option_links USING btree (candidate_stop_id);


--
-- Name: index_trip_stop_option_links_on_parent_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_option_links_on_parent_stop_id ON public.trip_stop_option_links USING btree (parent_stop_id);


--
-- Name: index_trip_stop_option_links_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_option_links_on_trip_id ON public.trip_stop_option_links USING btree (trip_id);


--
-- Name: index_trip_stop_option_links_on_trip_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_option_links_on_trip_id_and_client_id ON public.trip_stop_option_links USING btree (trip_id, client_id);


--
-- Name: index_trip_stops_on_canonical_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_canonical_place_id ON public.trip_stops USING btree (canonical_place_id);


--
-- Name: index_trip_stops_on_created_by_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_created_by_device_id ON public.trip_stops USING btree (created_by_device_id);


--
-- Name: index_trip_stops_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_created_by_user_id ON public.trip_stops USING btree (created_by_user_id);


--
-- Name: index_trip_stops_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_trip_id ON public.trip_stops USING btree (trip_id);


--
-- Name: index_trip_stops_on_trip_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_trip_id_and_client_id ON public.trip_stops USING btree (trip_id, client_id);


--
-- Name: index_trip_stops_on_trip_id_and_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_trip_id_and_kind ON public.trip_stops USING btree (trip_id, kind);


--
-- Name: index_trip_stops_on_trip_id_and_sort_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_trip_id_and_sort_key ON public.trip_stops USING btree (trip_id, sort_key);


--
-- Name: index_trip_stops_on_trip_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_trip_segment_id ON public.trip_stops USING btree (trip_segment_id);


--
-- Name: index_trips_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_client_id ON public.trips USING btree (client_id);


--
-- Name: index_trips_on_created_by_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_created_by_device_id ON public.trips USING btree (created_by_device_id);


--
-- Name: index_trips_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_deleted_at ON public.trips USING btree (deleted_at);


--
-- Name: index_trips_on_owner_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_owner_user_id ON public.trips USING btree (owner_user_id);


--
-- Name: index_user_auth_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_auth_identities_on_user_id ON public.user_auth_identities USING btree (user_id);


--
-- Name: index_user_settings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_settings_on_user_id ON public.user_settings USING btree (user_id);


--
-- Name: index_user_settings_on_user_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_settings_on_user_id_and_key ON public.user_settings USING btree (user_id, key);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_lower_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_lower_username ON public.users USING btree (lower((username)::text)) WHERE (username IS NOT NULL);


--
-- Name: index_users_on_profile_photo_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_profile_photo_asset_id ON public.users USING btree (profile_photo_asset_id);


--
-- Name: index_users_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_status ON public.users USING btree (status);


--
-- Name: assets fk_rails_01f7653cb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_rails_01f7653cb3 FOREIGN KEY (uploaded_by_user_id) REFERENCES public.users(id);


--
-- Name: route_steps fk_rails_033331659c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_steps
    ADD CONSTRAINT fk_rails_033331659c FOREIGN KEY (route_leg_id) REFERENCES public.route_legs(id);


--
-- Name: deleted_records fk_rails_05c29335af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_records
    ADD CONSTRAINT fk_rails_05c29335af FOREIGN KEY (deleted_by_user_id) REFERENCES public.users(id);


--
-- Name: sync_events fk_rails_060f716ee8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events
    ADD CONSTRAINT fk_rails_060f716ee8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: favorite_places fk_rails_1186e174ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_places
    ADD CONSTRAINT fk_rails_1186e174ed FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: route_snapshots fk_rails_179d19fe0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshots
    ADD CONSTRAINT fk_rails_179d19fe0b FOREIGN KEY (trip_segment_id) REFERENCES public.trip_segments(id);


--
-- Name: trip_segments fk_rails_1873a9470c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_segments
    ADD CONSTRAINT fk_rails_1873a9470c FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: place_source_links fk_rails_29f07f7057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_source_links
    ADD CONSTRAINT fk_rails_29f07f7057 FOREIGN KEY (source_record_id) REFERENCES public.source_records(id);


--
-- Name: route_legs fk_rails_2db74aeaf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_legs
    ADD CONSTRAINT fk_rails_2db74aeaf1 FOREIGN KEY (source_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: users fk_rails_3121aedea9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_3121aedea9 FOREIGN KEY (profile_photo_asset_id) REFERENCES public.assets(id);


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: trip_stop_option_links fk_rails_323bdc357e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_option_links
    ADD CONSTRAINT fk_rails_323bdc357e FOREIGN KEY (parent_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: search_sessions fk_rails_3586ae3863; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sessions
    ADD CONSTRAINT fk_rails_3586ae3863 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trips fk_rails_387207a73b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_387207a73b FOREIGN KEY (owner_user_id) REFERENCES public.users(id);


--
-- Name: trip_stops fk_rails_38c774e0f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_38c774e0f1 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: sync_events fk_rails_3a05e05ee9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events
    ADD CONSTRAINT fk_rails_3a05e05ee9 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: drive_sessions fk_rails_3f14203514; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drive_sessions
    ADD CONSTRAINT fk_rails_3f14203514 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: client_operations fk_rails_400b96fddb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_operations
    ADD CONSTRAINT fk_rails_400b96fddb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: route_legs fk_rails_4015f24a07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_legs
    ADD CONSTRAINT fk_rails_4015f24a07 FOREIGN KEY (destination_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: devices fk_rails_410b63ef65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT fk_rails_410b63ef65 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: deleted_records fk_rails_432dd4d70e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_records
    ADD CONSTRAINT fk_rails_432dd4d70e FOREIGN KEY (deleted_by_device_id) REFERENCES public.devices(id);


--
-- Name: trip_stops fk_rails_49eb5c0714; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_49eb5c0714 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: route_snapshot_stops fk_rails_4aaeef2d45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshot_stops
    ADD CONSTRAINT fk_rails_4aaeef2d45 FOREIGN KEY (route_snapshot_id) REFERENCES public.route_snapshots(id);


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: memory_assets fk_rails_4ff48538b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_assets
    ADD CONSTRAINT fk_rails_4ff48538b0 FOREIGN KEY (drive_session_id) REFERENCES public.drive_sessions(id);


--
-- Name: asset_links fk_rails_5019fa73c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_links
    ADD CONSTRAINT fk_rails_5019fa73c6 FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: place_list_items fk_rails_561365e757; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_list_items
    ADD CONSTRAINT fk_rails_561365e757 FOREIGN KEY (place_list_id) REFERENCES public.place_lists(id);


--
-- Name: route_snapshots fk_rails_57c6a45a63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshots
    ADD CONSTRAINT fk_rails_57c6a45a63 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: route_snapshots fk_rails_5e71fc4243; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshots
    ADD CONSTRAINT fk_rails_5e71fc4243 FOREIGN KEY (created_by_device_id) REFERENCES public.devices(id);


--
-- Name: route_snapshots fk_rails_5ea888a7e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshots
    ADD CONSTRAINT fk_rails_5ea888a7e2 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: trip_invites fk_rails_5fd24bb8ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_invites
    ADD CONSTRAINT fk_rails_5fd24bb8ec FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id);


--
-- Name: route_legs fk_rails_704082684f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_legs
    ADD CONSTRAINT fk_rails_704082684f FOREIGN KEY (route_snapshot_id) REFERENCES public.route_snapshots(id);


--
-- Name: memory_assets fk_rails_759b96ba83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_assets
    ADD CONSTRAINT fk_rails_759b96ba83 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: drive_sessions fk_rails_7a8b4a4f93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drive_sessions
    ADD CONSTRAINT fk_rails_7a8b4a4f93 FOREIGN KEY (route_snapshot_id) REFERENCES public.route_snapshots(id);


--
-- Name: sync_events fk_rails_7c740bf253; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events
    ADD CONSTRAINT fk_rails_7c740bf253 FOREIGN KEY (actor_user_id) REFERENCES public.users(id);


--
-- Name: sync_events fk_rails_7fd6910a98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_events
    ADD CONSTRAINT fk_rails_7fd6910a98 FOREIGN KEY (actor_device_id) REFERENCES public.devices(id);


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: api_sessions fk_rails_891ac05812; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_sessions
    ADD CONSTRAINT fk_rails_891ac05812 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trip_stop_option_links fk_rails_8f8dae472d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_option_links
    ADD CONSTRAINT fk_rails_8f8dae472d FOREIGN KEY (candidate_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: search_history_entries fk_rails_904e7f61dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_history_entries
    ADD CONSTRAINT fk_rails_904e7f61dc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trip_invites fk_rails_95c99cb8cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_invites
    ADD CONSTRAINT fk_rails_95c99cb8cb FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: memory_assets fk_rails_964dc8b74d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_assets
    ADD CONSTRAINT fk_rails_964dc8b74d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: asset_links fk_rails_9d3cd9b5dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_links
    ADD CONSTRAINT fk_rails_9d3cd9b5dc FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: drive_sessions fk_rails_9fc52a1b76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drive_sessions
    ADD CONSTRAINT fk_rails_9fc52a1b76 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: trip_members fk_rails_a2e4144f8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_members
    ADD CONSTRAINT fk_rails_a2e4144f8f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: client_operations fk_rails_acc22f27f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_operations
    ADD CONSTRAINT fk_rails_acc22f27f8 FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- Name: search_sessions fk_rails_ae2ca5d6d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sessions
    ADD CONSTRAINT fk_rails_ae2ca5d6d2 FOREIGN KEY (search_history_entry_id) REFERENCES public.search_history_entries(id);


--
-- Name: deleted_records fk_rails_af34692d8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_records
    ADD CONSTRAINT fk_rails_af34692d8a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: deleted_records fk_rails_b2fd0f8047; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_records
    ADD CONSTRAINT fk_rails_b2fd0f8047 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: source_records fk_rails_b9a75326aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_records
    ADD CONSTRAINT fk_rails_b9a75326aa FOREIGN KEY (source_dataset_id) REFERENCES public.source_datasets(id);


--
-- Name: place_containments fk_rails_ba3a4ad1c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_containments
    ADD CONSTRAINT fk_rails_ba3a4ad1c9 FOREIGN KEY (source_record_id) REFERENCES public.source_records(id);


--
-- Name: place_source_links fk_rails_bac7c042a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_source_links
    ADD CONSTRAINT fk_rails_bac7c042a6 FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: trip_stops fk_rails_bd4200581d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_bd4200581d FOREIGN KEY (created_by_device_id) REFERENCES public.devices(id);


--
-- Name: api_sessions fk_rails_c15faba5df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_sessions
    ADD CONSTRAINT fk_rails_c15faba5df FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: trip_stop_option_links fk_rails_c7c18f56ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_option_links
    ADD CONSTRAINT fk_rails_c7c18f56ea FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: place_containments fk_rails_cd76e4a36b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_containments
    ADD CONSTRAINT fk_rails_cd76e4a36b FOREIGN KEY (containing_place_id) REFERENCES public.places(id);


--
-- Name: user_settings fk_rails_d1371c6356; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT fk_rails_d1371c6356 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_auth_identities fk_rails_d99ad7dd6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_auth_identities
    ADD CONSTRAINT fk_rails_d99ad7dd6b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: park_units fk_rails_db3afa0887; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.park_units
    ADD CONSTRAINT fk_rails_db3afa0887 FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: route_snapshot_stops fk_rails_db3f777bb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_snapshot_stops
    ADD CONSTRAINT fk_rails_db3f777bb4 FOREIGN KEY (trip_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: trip_stops fk_rails_deff064a29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_deff064a29 FOREIGN KEY (trip_segment_id) REFERENCES public.trip_segments(id);


--
-- Name: trip_members fk_rails_ea64d876a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_members
    ADD CONSTRAINT fk_rails_ea64d876a7 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: place_lists fk_rails_eba410e90f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_lists
    ADD CONSTRAINT fk_rails_eba410e90f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trip_segments fk_rails_ec412074ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_segments
    ADD CONSTRAINT fk_rails_ec412074ac FOREIGN KEY (parent_segment_id) REFERENCES public.trip_segments(id);


--
-- Name: trip_stops fk_rails_ecddf14eb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_ecddf14eb0 FOREIGN KEY (canonical_place_id) REFERENCES public.places(id);


--
-- Name: trips fk_rails_efbbf0e973; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_efbbf0e973 FOREIGN KEY (created_by_device_id) REFERENCES public.devices(id);


--
-- Name: trip_invites fk_rails_f30939d9f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_invites
    ADD CONSTRAINT fk_rails_f30939d9f9 FOREIGN KEY (accepted_by_user_id) REFERENCES public.users(id);


--
-- Name: place_external_identifiers fk_rails_f9c35174f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_external_identifiers
    ADD CONSTRAINT fk_rails_f9c35174f0 FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260707010000'),
('20260704010000'),
('20260702030000'),
('20260702020000'),
('20260702010000'),
('20260702000000'),
('20260630010000'),
('20260614010000'),
('20260613230000'),
('20260613213000'),
('20260613204500'),
('20260613203000'),
('20260613202820');

