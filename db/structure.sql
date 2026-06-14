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
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
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
    status character varying DEFAULT 'draft'::character varying NOT NULL,
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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


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
-- Name: source_datasets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_datasets ALTER COLUMN id SET DEFAULT nextval('public.source_datasets_id_seq'::regclass);


--
-- Name: source_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_records ALTER COLUMN id SET DEFAULT nextval('public.source_records_id_seq'::regclass);


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
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


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
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


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
-- Name: idx_on_containing_place_id_source_record_id_bec21fb831; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_containing_place_id_source_record_id_bec21fb831 ON public.place_containments USING btree (containing_place_id, source_record_id);


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
-- Name: place_source_links fk_rails_29f07f7057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_source_links
    ADD CONSTRAINT fk_rails_29f07f7057 FOREIGN KEY (source_record_id) REFERENCES public.source_records(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


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
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: place_containments fk_rails_cd76e4a36b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place_containments
    ADD CONSTRAINT fk_rails_cd76e4a36b FOREIGN KEY (containing_place_id) REFERENCES public.places(id);


--
-- Name: park_units fk_rails_db3afa0887; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.park_units
    ADD CONSTRAINT fk_rails_db3afa0887 FOREIGN KEY (place_id) REFERENCES public.places(id);


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
('20260613230000'),
('20260613213000'),
('20260613204500'),
('20260613203000'),
('20260613202820');

