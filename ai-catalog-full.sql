--
-- PostgreSQL database dump
--

\restrict xhsuYSn2tDlrzy3bXrv9bI8CkGqMdZEVlriEcXW8yRQybRwolSwxo60Sc4du0sa

-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)
-- Dumped by pg_dump version 17.9 (Ubuntu 17.9-1.pgdg24.04+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: duplicate_dictionary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.duplicate_dictionary (
    hash_key character varying(255) NOT NULL,
    duplicate_group_id integer NOT NULL,
    key_type character varying(20) NOT NULL,
    confidence_weight double precision NOT NULL,
    master_product_id integer,
    normalized_form text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    hit_count integer DEFAULT 0
);


--
-- Name: duplicate_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.duplicate_groups (
    group_id integer NOT NULL,
    master_product_id integer,
    normalized_master_name text,
    product_count integer DEFAULT 1,
    variations jsonb,
    confidence_avg double precision,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: duplicate_groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.duplicate_groups_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: duplicate_groups_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.duplicate_groups_group_id_seq OWNED BY public.duplicate_groups.group_id;


--
-- Name: hash_key_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hash_key_log (
    id integer NOT NULL,
    product_id integer,
    original_name text,
    normalized_name text,
    hash_keys jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: hash_key_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hash_key_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hash_key_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hash_key_log_id_seq OWNED BY public.hash_key_log.id;


--
-- Name: mro_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mro_products (
    id integer NOT NULL,
    product_name text NOT NULL,
    brand character varying(255),
    model character varying(255),
    original_category text,
    old_department character varying(255),
    old_category character varying(255),
    old_subcategory character varying(255),
    new_department_code character varying(10),
    new_department_name character varying(255),
    new_category_code character varying(10),
    new_category_name character varying(255),
    new_subcategory_code character varying(10),
    new_subcategory_name character varying(255),
    confidence_score double precision,
    classification_timestamp timestamp without time zone,
    batch_id integer,
    processing_status character varying(50) DEFAULT 'pending'::character varying,
    error_message text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mro_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mro_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mro_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mro_products_id_seq OWNED BY public.mro_products.id;


--
-- Name: normalization_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.normalization_cache (
    id integer NOT NULL,
    subcategory_code character varying(10),
    cached_context text,
    example_products text,
    token_count integer,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: normalization_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.normalization_cache_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: normalization_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.normalization_cache_id_seq OWNED BY public.normalization_cache.id;


--
-- Name: normalization_dictionary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.normalization_dictionary (
    id integer NOT NULL,
    subcategory_code character varying(10),
    original_pattern text,
    normalized_form text,
    pattern_type character varying(50) DEFAULT 'exact'::character varying,
    confidence double precision DEFAULT 1.0,
    usage_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    source character varying(50) DEFAULT 'claude'::character varying
);


--
-- Name: normalization_dictionary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.normalization_dictionary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: normalization_dictionary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.normalization_dictionary_id_seq OWNED BY public.normalization_dictionary.id;


--
-- Name: processing_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.processing_stats (
    batch_id uuid NOT NULL,
    batch_number integer,
    total_products integer,
    new_products integer,
    duplicates_found integer,
    low_confidence_count integer,
    processing_time_seconds double precision,
    api_tokens_used integer,
    gpt5_cost_estimate double precision,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: products_enhanced; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products_enhanced (
    id integer NOT NULL,
    original_name text NOT NULL,
    normalized_name text,
    category_code character varying(3),
    category_name text,
    subcategory_code character varying(4),
    subcategory_name text,
    duplicate_group_id integer,
    is_master boolean DEFAULT false,
    similarity_score double precision,
    duplicate_count integer DEFAULT 1,
    classification_confidence double precision,
    needs_review boolean DEFAULT false,
    review_notes text,
    gpt5_reasoning text,
    processed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    processing_model character varying(50) DEFAULT 'gpt-5-high-reasoning'::character varying,
    processing_batch_id uuid,
    batch_position integer
);


--
-- Name: products_enhanced_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_enhanced_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_enhanced_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_enhanced_id_seq OWNED BY public.products_enhanced.id;


--
-- Name: duplicate_groups group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_groups ALTER COLUMN group_id SET DEFAULT nextval('public.duplicate_groups_group_id_seq'::regclass);


--
-- Name: hash_key_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hash_key_log ALTER COLUMN id SET DEFAULT nextval('public.hash_key_log_id_seq'::regclass);


--
-- Name: mro_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mro_products ALTER COLUMN id SET DEFAULT nextval('public.mro_products_id_seq'::regclass);


--
-- Name: normalization_cache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.normalization_cache ALTER COLUMN id SET DEFAULT nextval('public.normalization_cache_id_seq'::regclass);


--
-- Name: normalization_dictionary id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.normalization_dictionary ALTER COLUMN id SET DEFAULT nextval('public.normalization_dictionary_id_seq'::regclass);


--
-- Name: products_enhanced id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_enhanced ALTER COLUMN id SET DEFAULT nextval('public.products_enhanced_id_seq'::regclass);


--
-- Data for Name: duplicate_dictionary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.duplicate_dictionary (hash_key, duplicate_group_id, key_type, confidence_weight, master_product_id, normalized_form, created_at, hit_count) FROM stdin;
formao olho de tigre chanfrado 9.5mm 10mm	1	exact	1	1	\N	2025-08-21 15:43:32.739374	0
formaoolhodetigrechanfrado95mm10mm	1	alpha	0.95	1	\N	2025-08-21 15:43:32.739374	0
10mm_9.5mm_chanfrado_de_formao_olho_tigre	1	sorted	0.9	1	\N	2025-08-21 15:43:32.739374	0
9.5_mm	1	dim	0.85	1	\N	2025-08-21 15:43:32.739374	0
forolhtigcha	1	phon	0.75	1	\N	2025-08-21 15:43:32.739374	0
fresa aco rapido hss 5mm 4 cortes longa	1	exact	1	2	\N	2025-08-21 15:43:32.78763	0
fresaacorapidohss5mm4corteslonga	1	alpha	0.95	2	\N	2025-08-21 15:43:32.78763	0
4_5mm_aco_cortes_fresa_hss_longa_rapido	1	sorted	0.9	2	\N	2025-08-21 15:43:32.78763	0
aco	1	core	0.85	2	\N	2025-08-21 15:43:32.78763	0
5_mm	1	dim	0.85	2	\N	2025-08-21 15:43:32.78763	0
freacoraphss	1	phon	0.75	2	\N	2025-08-21 15:43:32.78763	0
luva protecao mecanica vaqueta tamanho medio	1	exact	1	3	\N	2025-08-21 15:43:32.836832	0
luvaprotecaomecanicavaquetatamanhomedio	1	alpha	0.95	3	\N	2025-08-21 15:43:32.836832	0
luva_mecanica_medio_protecao_tamanho_vaqueta	1	sorted	0.9	3	\N	2025-08-21 15:43:32.836832	0
8a38a86b64	1	dim	0.85	3	\N	2025-08-21 15:43:32.836832	0
luvpromecvaq	1	phon	0.75	3	\N	2025-08-21 15:43:32.836832	0
condulete aluminio tipo t 25.4mm sem rosca natural sem tampa	1	exact	1	4	\N	2025-08-21 15:43:32.917381	0
conduletealuminiotipot254mmsemroscanaturalsemtampa	1	alpha	0.95	4	\N	2025-08-21 15:43:32.917381	0
25.4mm_aluminio_condulete_natural_rosca_sem_sem_t_tampa_tipo	1	sorted	0.9	4	\N	2025-08-21 15:43:32.917381	0
aluminio	1	core	0.85	4	\N	2025-08-21 15:43:32.917381	0
25.4_mm	1	dim	0.85	4	\N	2025-08-21 15:43:32.917381	0
conalutip25.	1	phon	0.75	4	\N	2025-08-21 15:43:32.917381	0
correia perfil spc 11200mm	1	exact	1	5	\N	2025-08-21 15:43:33.010393	0
correiaperfilspc11200mm	1	alpha	0.95	5	\N	2025-08-21 15:43:33.010393	0
11200mm_correia_perfil_spc	1	sorted	0.9	5	\N	2025-08-21 15:43:33.010393	0
	1	core	0.85	1	\N	2025-08-21 15:43:32.739374	2
11200_mm	1	dim	0.85	5	\N	2025-08-21 15:43:33.010393	0
corperspc112	1	phon	0.75	5	\N	2025-08-21 15:43:33.010393	0
\.


--
-- Data for Name: duplicate_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.duplicate_groups (group_id, master_product_id, normalized_master_name, product_count, variations, confidence_avg, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: hash_key_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hash_key_log (id, product_id, original_name, normalized_name, hash_keys, created_at) FROM stdin;
1	1	\N	\N	{"dim": "9.5_mm", "core": "", "phon": "forolhtigcha", "alpha": "formaoolhodetigrechanfrado95mm10mm", "exact": "formao olho de tigre chanfrado 9.5mm 10mm", "sorted": "10mm_9.5mm_chanfrado_de_formao_olho_tigre"}	2025-08-21 15:43:32.739374
2	2	\N	\N	{"dim": "5_mm", "core": "aco", "phon": "freacoraphss", "alpha": "fresaacorapidohss5mm4corteslonga", "exact": "fresa aco rapido hss 5mm 4 cortes longa", "sorted": "4_5mm_aco_cortes_fresa_hss_longa_rapido"}	2025-08-21 15:43:32.78763
3	3	\N	\N	{"dim": "8a38a86b64", "core": "", "phon": "luvpromecvaq", "alpha": "luvaprotecaomecanicavaquetatamanhomedio", "exact": "luva protecao mecanica vaqueta tamanho medio", "sorted": "luva_mecanica_medio_protecao_tamanho_vaqueta"}	2025-08-21 15:43:32.836832
4	4	\N	\N	{"dim": "25.4_mm", "core": "aluminio", "phon": "conalutip25.", "alpha": "conduletealuminiotipot254mmsemroscanaturalsemtampa", "exact": "condulete aluminio tipo t 25.4mm sem rosca natural sem tampa", "sorted": "25.4mm_aluminio_condulete_natural_rosca_sem_sem_t_tampa_tipo"}	2025-08-21 15:43:32.917381
5	5	\N	\N	{"dim": "11200_mm", "core": "", "phon": "corperspc112", "alpha": "correiaperfilspc11200mm", "exact": "correia perfil spc 11200mm", "sorted": "11200mm_correia_perfil_spc"}	2025-08-21 15:43:33.010393
\.


--
-- Data for Name: mro_products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mro_products (id, product_name, brand, model, original_category, old_department, old_category, old_subcategory, new_department_code, new_department_name, new_category_code, new_category_name, new_subcategory_code, new_subcategory_name, confidence_score, classification_timestamp, batch_id, processing_status, error_message, created_at, updated_at) FROM stdin;
27	CONECTOR JUMPER PLUGAVEL 50 POLOS 24A POLIAMIDA 5,2MM VM	PHOENIX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 15:40:42.584876	1755801598	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:40:34.818407
3	RELE SEG EXTENSAO 115-230V PARAF 4NA+1NF	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C269	Outros componentes eletrônicos	1	2025-08-21 15:36:39.335064	1755801372	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:36:39.344408
4	SUPORTE SIMATIC RF600 ANTENA 3 VIAS ACO INOX	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:36:44.663745	1755801372	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:36:44.668781
6	MODULO RELE 4S DIGITAL 120/230V ET200SP 6ES71326HD010BB1 SIEMENS	SIEMENS	6ES71326HD010BB1	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:36:56.11861	1755801373	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:36:51.732733
7	RELE DE INTERFACE INDIVIDUAL 24VCC P/UNIDADE EM 24VCA/VCC 1NAF	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C269	Outros componentes eletrônicos	1	2025-08-21 15:37:01.687543	1755801373	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:01.704001
9	MODULO EXPANSAO CLP CONTADOR/DETECTOR POSICAO (2ED/2SD) CANAL TM POSINPUT SIMAT	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:37:12.977442	1755801373	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:12.982916
10	CONECTOR PLUGAVEL 10P 3030213 VM	PHOENIX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 15:37:22.82665	1755801373	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:22.836405
11	PONTE INTERLIGACAO 8WH P/CONECTOR 1,5MM 3 POLOS	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 15:37:31.232566	1755801374	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:24.867857
13	CHAVE PART DIR 400V 1,1KW 0,9-3A 3RK13080AC000CP0 SIEMENS	SIEMENS	3RK13080AC000CP0	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:37:43.896739	1755801374	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:43.902873
14	PLACA IDENTIFICACAO BOTAO DE EMERG BOTOEIRA	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C290	Outros materiais elétricos	1	2025-08-21 15:37:49.505784	1755801374	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:49.519607
16	MODULO LUMINOSO LED CONTINUO 230V VM IP66	MOELLER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C768	Painel de LED	1	2025-08-21 15:38:01.96158	1755801375	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:57.114294
17	DISTRIBUID POTENCIA 250V 17,5A CZ/ELEMENTOS CONEX AZ 16 CONEXOES CONEX 0,14-2,5	PHOENIX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 15:38:05.900813	1755801375	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:38:05.906407
18	BASE ACO 70MM MONT HORIZONTAL P/COLUNA SL7CB100 EATON	EATON	SL7CB100	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C253	Outros componentes de partes mecânicas	1	2025-08-21 15:38:43.599396	1755801516	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:38:36.950453
20	MODULO COMUNICACAO CLP WIRELESS ETHERNET CMR2040 LOGO	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:38:52.176795	1755801516	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:38:52.187395
21	BLOCO CONTATO AUX FRONTAL 2NA+2NF 3RH29112FA22 SIEMENS	SIEMENS	3RH29112FA22	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 15:38:57.25646	1755801516	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:38:57.268082
23	CONTATOR POTENCIA TRIPOLAR 18A 100-250VCA/CC 1NF 50/60HZ	ABB	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 15:40:16.155182	1755801597	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:40:16.161247
24	BASE P/RELE PLCBPT24DC/21	PHOENIX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:40:20.852564	1755801597	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:40:20.858021
26	FRONT BOT RED BR 22MM 3SU10000AA600AA0 SIEMENS	SIEMENS	3SU10000AA600AA0	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:40:33.279301	1755801597	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:40:33.299097
39	CINTA DE LIXA 40X457X75 3PC 7427555 MTX	MTX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 21:11:52.739404	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:52.743637
40	RASPADOR DE REJUNTE 200MM LAMINA 50MM TUNGSTENIO 795609 MTX.. MTX	MTX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C165	Ferramentas para construção civil	1	2025-08-21 21:11:55.292757	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:55.296979
41	1 FOLHA LIXA NORTON FERRO K246 C120 225X275	NORTON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 21:11:58.500393	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:58.505246
43	ESCOVA INOX CIRCULAR TRANC 4.1/2" X 1/2" X 7/8" 012327612 CARBOGRAFITE	CARBOGRAFITE	12327612	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:12:04.069067	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:04.073622
44	DISCO DESBASTE P/ ACO INOX 7 45100007 TRAMONTINA PRO	TRAMONTINA PRO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:12:06.6875	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:06.691955
46	BROCA ACO RAPIDO PARA METAL 3,0MM-IRWIN IRWIN	IRWIN	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:14.19571	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:14.200378
47	Marcador Industrial TraçoForte Branco 3mm Híbrido LWB-0700 M26-BR60-3 BADEN M26-BR60-3 BADEN	BADEN	LWB-0700	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C750	Ferramentas para pintura	1	2025-08-21 21:12:16.978978	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:16.983328
48	PISTOLA ALTA PRODUCAO 1000ML CH PP-12 CHIAPERINI. CHIAPERINI	CHIAPERINI	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas automotivas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas automotivas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C750	Ferramentas para pintura	1	2025-08-21 21:12:20.826062	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:20.830278
49	TINTA CHEMICOLOR 250ML U.G.PRETO FOSCO 068.0522	CHEMICOLOR	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas automotivas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas automotivas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S74	QUÍMICOS INDUSTRIAIS	C786	Químicos orgânicos	1	2025-08-21 21:12:23.57092	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:23.57525
372	RETENTOR-23654 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:38:05.338341	1755822638	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:38:05.343146
28	CONECTOR BORNE PASSAGEM TERRA 2 CONEXOES 2,50MM VD/AM	WEG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 15:42:15.726402	1755801598	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:42:15.731699
29	GRAMPEADOR GRAMPO 90 ATE 40MM PRO-348 PDR PRO	PDR PRO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > BOMBAS E MOTORES > Chaves e compressores	MRO: MATERIAL, REPARO E OPERAÇÃO	BOMBAS E MOTORES	Chaves e compressores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 15:43:47.946482	1755801598	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:43:47.952527
30	Motor para Roçadeira à Gasolina 2 Tempos 1,7HP 42,7CC RPG 427 MGP 427 VONDER 6805000427 VONDER	VONDER	MGP 427	MRO: MATERIAL, REPARO E OPERAÇÃO > BOMBAS E MOTORES > Motores	MRO: MATERIAL, REPARO E OPERAÇÃO	BOMBAS E MOTORES	Motores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S25	BOMBAS E MOTORES	C228	Motores	1	2025-08-21 15:43:58.002031	1755801598	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:43:58.011221
32	Adesivo Instantâneo Super Cola Universal 5g 20611003302 TEKBOND 000000069957326446 TEKBOND	TEKBOND	SUPER COLA	MRO: MATERIAL, REPARO E OPERAÇÃO > ELEMENTOS DE FIXAÇÃO E VEDAÇÃO > Adesivos e fitas	MRO: MATERIAL, REPARO E OPERAÇÃO	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	Adesivos e fitas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S74	QUÍMICOS INDUSTRIAIS	C786	Químicos orgânicos	1	2025-08-21 15:44:31.005567	1755801599	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:44:26.767843
33	Adesivo Spray Cola e Descola Reposicionável 300G SPRAY 75 3M HB004539738 3M	3M	SPRAY 75	MRO: MATERIAL, REPARO E OPERAÇÃO > ELEMENTOS DE FIXAÇÃO E VEDAÇÃO > Adesivos e fitas	MRO: MATERIAL, REPARO E OPERAÇÃO	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	Adesivos e fitas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S74	QUÍMICOS INDUSTRIAIS	C786	Químicos orgânicos	1	2025-08-21 15:44:39.186311	1755801599	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:44:39.202697
34	Rebolo Copo Cônico 75mm x 50mm Grão 120 M14 G-120 62114 CORTAG 62114 CORTAG	CORTAG	M14 G-120	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Abrasivos	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Abrasivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 15:44:43.484612	1755801599	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:44:43.489942
35	Disco de Corte 4.1/2'' VDR02 1207412187 VONDER 1207412187 VONDER	VONDER	VDR12	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Abrasivos	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Abrasivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 15:44:48.761119	1755801599	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:44:48.766159
374	RETENTOR-88X110X12 HMS4 R SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:38:11.16112	1755822638	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:38:11.1661
31	TERMOMETRO DIGITAL MIRA LASER-MIRA LASER 50~800 C / TERMOPAR 50~500 MT-350A MINIPA. MINIPA	MINIPA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > BOMBAS E MOTORES > Outros componentes bombas e motores	MRO: MATERIAL, REPARO E OPERAÇÃO	BOMBAS E MOTORES	Outros componentes bombas e motores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:44:25.233687	1755801598	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:44:25.253388
36	Disco Flap 4.1/2" Grão 120 Fibra de Vidro 2608619909 BOSCH 2608619909000 BOSCH	BOSCH	2608619909	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Abrasivos	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Abrasivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 15:44:54.533748	1755801599	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:44:54.539822
375	RETENTOR-36X62X7 HMSA10 RG SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:38:15.988671	1755822639	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:38:13.680937
377	RETENTOR-8X18X7 HMSA10 RG SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:11:19.90363	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:06:53.200304
378	ROLAMENTO AUTOCOMPENSADOR DE ROLOS-231/500 CA/W33 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:19.915488	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:19.919738
379	ROLAMENTO DE ROLOS CILINDRICOS-NU 2240 ECML/C3 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:19.92692	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:19.931191
380	ROLAMENTO DE AGULHA-K 18X24X12 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:19.937889	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:19.942235
381	ROLAMENTO DE PRECISÃO-7030 CD/P4ADBB SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:19.953224	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:19.958197
382	ROLAMENTO DE PRECISÃO-7011 CEGA/HCP4A SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:19.967529	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:19.972196
383	ROLAMENTO RIGIDO DE ESFERAS-E2.6207-2Z/C3 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:19.990642	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:19.995514
384	ROLAMENTO RIGIDO DE ESFERAS-624 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:20.002472	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:20.007055
385	ROLAMENTO DE ROLOS CILINDRICOS-NU 1020 ML SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:20.014562	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:20.018839
386	ROLAMENTO DE CONTATO ANGULAR-7048 BGM SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:20.030515	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:20.035022
387	ROLAMENTO DE PRECISÃO-7213 ACD/P4ADGA SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:20.059436	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:20.06456
388	ROLAMENTO DE ROLOS CILINDRICOS-N 313 ECM SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:20.072983	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:20.077641
389	ROLAMENTO DE CONTATO ANGULAR-3203 ATN9/C3 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Rolamentos	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Rolamentos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:11:20.085311	18	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:20.09024
37	Disco de Lixa para Madeira 5'' Grão 240 5 Peças 2608900809 BOSCH 2608900809000 BOSCH	BOSCH	2608900809 EXPERT	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Abrasivos	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Abrasivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 21:11:46.935349	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:44.543285
169	SOQ EST 1/2 POL ACO CRV ENCAIXE 1394755 STELS. STELS	STELS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:18:38.128177	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:38.133796
55	Broca Aço Rápido Haste Cônica 3/8" Din 345 HTOM404 HTOM 38843 HTOM	HTOM	HTOM404-3/8"	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:40.359076	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:40.363811
57	Fresa Topo Esférica Metal Duro 3,00mm 4 Cortes 36976 HT 36976 HT	HT	36976	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:12:47.554938	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:44.919721
58	Broca Aço Rápido para Metais 5,10mm Din 338 A1222 TITEX 000000000005059493 TITEX	TITEX	A1222-5.1	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:51.187782	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:51.192717
60	Broca Centro HSS 4.00mm X 10.00mm Din 333A HT700-4.00 HT 12796 HT	HT	HT700-4.00	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:56.80796	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:56.81285
61	Broca para Metais 10.30mm DIN 338N Afiação em Cruz 2608577271 BOSCH 2608577271000 BOSCH	BOSCH	2608577271	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:13:00.987054	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:00.99203
62	Broca SDS Max 26 x 540 x 400mm para Concreto P-77958 MAKITA P-77958 MAKITA	MAKITA	P-77958	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:13:03.530926	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:03.535163
64	Fresa Chanfrar 7/16" Haste 1/4" com Rolamento 2608628416 BOSCH 2608628416000 BOSCH	BOSCH	2608628416	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:13:09.045392	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:09.049654
65	Calibrador de Boca Ajustável sem Relógio com Alavanca de Acionamento 0 a 40mm 132.010D DIGIMESS 87061 DIGIMESS	DIGIMESS	132.010D	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de medição	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de medição	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:13:12.837359	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:12.842794
66	Abraçadeira de Aço Tipo D com Cunha 4" SDC4Z SUPERA SDC4Z SUPERA	SUPERA	SDC4Z	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de medição	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de medição	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C026	Acoplamentos	1	2025-08-21 21:13:15.69519	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:15.700487
68	Moto Esmeril e Lixadeira de Cinta 370W 2 em 1 110V MLV 370 6001370127 VONDER 6001370127 VONDER	VONDER	6001370127	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:13:21.264043	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:21.268946
69	Moto Esmeril de Bancada 5" 1CV Monofásico Bivolt 42400150 TRAMONTINA MASTER 42400150 TRAMONTINA MASTER	TRAMONTINA MASTER	42400/150	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:13:23.884325	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:23.888752
71	PARAFUSADEIRA/FURADEIRA A CABO GSR 7-14E 127V 06014470D0-000BOSCH. BOSCH	BOSCH	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:13:29.70408	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:29.708848
73	Parafusadeira 1/4" 701W 110V com Maleta GSR 6-25 TE BOSCH 06014450D0000 BOSCH	BOSCH	06014450D0 GSR 6-25TE	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:13:34.912409	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:34.918272
74	FORMAO OLHO DE TIGRE CHAFRADO 3/8 POL 10 MM EMBO 245059 MTX.. MTX	MTX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas para construção civil	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas para construção civil	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:13:38.009397	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:38.014225
76	LIMA NICHOLSON FACAO / AGRO 8POL 08994E NICHOLSON.	NICHOLSON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas para pintura	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas para pintura	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:13:46.75961	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:46.764063
77	LUVA SOLDADOR AZUL CANO LONGO 342 GALZER. GALZER	GALZER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas para solda	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas para solda	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:13:50.973206	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:48.276993
78	FRESA ACO RAPIDO 5MM 4 CORTES LONGA HSS HT	CORDEIRO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:13:53.81175	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:53.816432
89	SOQUETE ALLEN 1/2  X 9MM DE IMPACTO 016.261 / 080.143 GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:14:26.906684	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:26.911848
81	DISCO ACABAMENTO AMF 50MM SF ROLOC H0001496647 - 3M	3M	H0001496647	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 21:14:02.689927	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:02.694712
83	Chave Catraca Redonda Reversível 3/8" 203mm Trabalho em Altura 44395/007 TRAMONTINA PRO 44395007 TRAMONTINA PRO	TRAMONTINA PRO	44395/007	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:14:09.19471	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:09.199041
84	MACHO MÁQUINA M4 X 0,7 ESPECÍFICO P/ALUMÍNIO DIN371 SFT-AL 169 OSG	OSG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:14:11.633641	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:11.638082
85	PAQUIMETRO DIGITAL 40  1000MM SERV. PESADO 100.182 DIGIMESS	DIGIMESS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:14:14.433913	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:14.43868
87	FITA ADESIVA EMPAC PP TRANSP 48MMX 50M TARTAN HB004741144 - 3M 7018716	3M	7018716	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S72	EMBALAGENS	C731	Fitas adesivas	1	2025-08-21 21:14:20.631674	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:20.636201
88	CHAVE COMB ACRV 8MM X8MM X125MM 1B-8MM - GEDORE 1B8MM	GEDORE	1B8MM	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:14:23.794496	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:23.799469
91	SERRA FITA P/ MADEIRA WPP 10 X 4/P  (ROLO PROD.) STARRETT	STARRETT SF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:14:32.603458	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:32.608371
92	SERRA FITA BIMET INTENSS 27X0,9MM 10-14DPP 4,48M IT27X10-14* STARRETT IT27X10-14/S-4,48	STARRETT	IT27X10-14/S-4,48	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:14:35.031159	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:35.036492
93	MACHO MN 352 M M22 X 2,5MM HSS 3PCS E100M22NO8 DORMER	DORMER	E100M22NO8	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:14:37.745914	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:37.750434
95	PONTA MONTADA B-70  PM B-70 DRV	CORDEIRO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:14:44.032286	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:44.037075
96	ALICATE CORTE DIAGONAL 44002/106 TRAMONTINA. TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C740	Alicates	1	2025-08-21 21:14:47.753952	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:47.758431
98	BROCA HELIC HSS/CO BRI CIL 18X 191MM A90018.0 DORMER	DORMER	A90018.0	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:14:55.076196	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:55.082439
99	JOGO DE CHAVE TORX VERIFICADOR PLASTICO 024.700 GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C753	Jogos de ferramentas	1	2025-08-21 21:14:57.827064	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:57.831806
100	MARTELETE ELET 220V 1700W SDS MAX GBH 12-52 D BOSCH	BOSCH	GBH 12-52 D	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:15:00.341662	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:00.346359
102	FRESA DE BORDA DIAMETRO 1/4  HASTE 1/4  D-49806	MAKITA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:15:05.816003	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:05.820956
103	R07200080 CH COMB C/CATRACA REVERSIVEL 8MM GEDORE RED.. RED	GEDORE RED	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:15:08.875941	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:08.88107
105	FITA ADESIVA DUPLA FACE ESP ACR BR 19MMX 33M VHB-4970 HB004 3M HB004671119	3M	HB004671119	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:15:15.455181	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:15.460159
106	Soquete de Impacto Sextavado em aço Cromo Molibdênio 2.1/4" - Encaixe 1'' 44918/023 TRAMONTINA PRO 44918023 TRAMONTINA PRO	TRAMONTINA PRO	44918/023	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:15:18.518041	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:18.522803
107	ESTUFA ELETRODO 220V 120G 10KG ECG10-220V CARBOGRAFITE	CARBOGRAFITE	ECG10-220V	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C290	Outros materiais elétricos	1	2025-08-21 21:15:22.136919	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:22.141649
172	SERRA COPO BI-METAL 46MM POWER CHANGE 2 608 584 633 BOSCH	BOSCH	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:18:47.176113	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:47.181876
110	CHAVE COMBINADA 5/16 42245/101 TRAMONTINA. TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:15:31.942635	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:31.947951
111	CHAVE AJUSTAVEL 18MM 6" A.FAISC 44207006 TRAMONTINA GARIBALDI	TRAMONTINA GARIBALDI	44207006	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 21:15:34.842046	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:34.846969
112	CALIBRADOR DE FOLGA EM LAMINA 12  X 1/2  X 0,001  667-1 STAR	STARRETT	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:15:37.781583	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:37.786799
114	Cabeça 16mm de Chave Fixa 13/16" para Torquímetro Estalo 8791-13/16 GEDORE 048483 GEDORE	GEDORE	8791-13/16	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C755	Torquímetro	1	2025-08-21 21:15:43.530321	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:43.535146
115	SUPORTE PARA EXTRACAO EXTERNA 1.40/5 040.952 GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C746	Ferramentas automotivas	1	2025-08-21 21:15:46.06596	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:46.070633
116	ALICATE BOMBA D'AGUA 10  1571855 SPARTA	SPARTA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C740	Alicates	1	2025-08-21 21:15:49.412348	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:49.417927
118	CHAVE DE GARRAS P/ PORCA AMORTECEDOR TEMPRA 143343 RAVEN	RAVEN	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C746	Ferramentas automotivas	1	2025-08-21 21:15:56.838382	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:56.84318
119	DESEMPENO DE GRANITO 1000 X 750 X 150 517-307MSZ MITUTOYO	MITUTOYO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:15:59.724784	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:59.729791
121	CHAVE FIXA 10 X 11MM FOSFATIZADO 1432255 SPARTA. SPARTA	SPARTA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:16:06.069391	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:06.074838
122	ARCO SERRA FIXO 12" AC ESP FECHAD 403 - GEDORE	GEDORE	403	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:16:09.785674	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:09.791033
124	CHAVE COMBINADA COM CATRACA DE 8MM ST43201ST SATA	SATA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:16:15.756891	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:15.761972
125	SABRE P/ MOTOSSERRA 25  (MS650/660/460) STIHL  3003-001-5631	STIHL 	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:16:18.428014	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:18.433491
126	CHAVE COMBINADA 2.1/4  CROMO-VANADIUM 002 580 (1B) GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:16:21.735949	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:21.74064
128	INTERRUPTOR DESLISANTE QUICK-STEP 48L480 WALTER	WALTER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:16:28.155967	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:28.161503
129	LAVADORA DE ALTA PRESSÃO A GASOLINA TPW3400T-XP 3400 PSI 4T 223CC TOYAMA	TOYAMA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S25	BOMBAS E MOTORES	C199	Motobombas	1	2025-08-21 21:16:30.995866	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:31.000991
130	SERRA COPO BI-METAL 168MM FAST CUTFCH168M-G STARRETT	STARRETT	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:16:34.092106	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:34.097124
132	Jogo de Macho Manual HSS M16x2,00mm Din 352 Esquerdo com 3 Peças 101 OSG 18888 OSG	OSG	101	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:16:40.056979	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:40.061704
133	CHAVE PARA TUBO DE 10 POL. MAYLE CRESCENT	MAYLE CRESCENT	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C742	Chave biela	1	2025-08-21 21:16:43.52193	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:43.526629
135	MORSA PARA MÁQUINA MMMI 5 100MM METALCAVA	METALCAVA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 21:16:49.610573	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:49.615466
138	BROCA COM 3 PONTAS PARA MADEIRA 8.0MM CORTAG	CORTAG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:16:58.996436	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:59.002134
139	FILTRO MALHA  60 PARA MÁQUINA DE PINTURA AIRLESS - VONDER-62.20.111.009 VONDER	VONDER	VONDER-62.20.111.009	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S46	MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS	C346	Filtros industriais	1	2025-08-21 21:17:01.856787	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:01.862249
141	CHAVE RODA CRUZ 4 BOCAS 17X19X13/16X7/8" 44710002 TRAMONTINA GARIBALDI	TRAMONTINA GARIBALDI	44710002	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C746	Ferramentas automotivas	1	2025-08-21 21:17:08.100972	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:08.105879
142	Chave Fixa 22 x 24mm ST41210SC SATA ST41210SC SATA	SATA	ST41210SC	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:17:11.819966	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:11.825325
143	SOQUETE SEXTAVADO DE IMPACTO 3/4  X 1.3/16  44892/108 TRAMO	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:17:15.053857	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:15.058788
145	PARAFUSADEIRA FURADEIRA BRUSHLESS 12V COM BOLSA E ACESSÓRIOS - KRESS-KUA12.1 KRESS	KRESS	KRESS-KUA12.1	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C745	Ferramentas a bateria	1	2025-08-21 21:17:20.873609	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:20.878596
146	ARMARIO AM-41 MARCON	MARCON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:17:24.267227	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:24.272183
147	MOTO ESMERIL 6  1/2HP MONO THOR CEL	CORDEIRO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:17:26.831038	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:26.836815
149	BICO INFLADOR DUPLO ROSCA F 1/4POL. COM PRESILHA  SCHWEERS	SCHWEERS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S46	MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS	C029	Adaptadores, conexões e terminais	1	2025-08-21 21:17:33.463843	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:33.469232
151	ESPONJA MULTIUSO 102X260MM SCOTCH-BRITE H0001629981 - 3M	3M	H0001629981	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:17:39.072587	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:39.077999
152	CHAVE ESTRELA DE BATER 55MM STELS	STELS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C746	Ferramentas automotivas	1	2025-08-21 21:17:41.970002	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:41.9754
153	TAMPO EM ANGELIN BICOLADO ENVERNIZ. 1600 X 730 X 45MM MA-2 MARCON	MARCON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:17:45.200676	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:45.205926
155	ESMERILHADEIRA ANGULA 5  125MM 1.500W 11000 RPM 220V DWE4314N-B2	DEWALT	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:17:51.057981	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:51.063365
156	SERRA TICO-TICO A BATERIA COM LÂMINA DE CORTE 18V  - WESCO-WS23059 WESCO	WESCO	WESCO-WS23059	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C745	Ferramentas a bateria	1	2025-08-21 21:17:54.127032	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:54.132658
158	CHAVE FIXA 6-36 X 41 GEDORE.. GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:18:01.449602	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:01.454782
159	CHAVE T ALLEN ACRV FOSF FIXA 5X 195MM 42T-5MM - GEDORE 42T5MM	GEDORE	42T5MM	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C741	Chave allen/hexagonal	1	2025-08-21 21:18:04.506384	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:04.511293
160	MARTELO TIPO PENA 300GRS 40443/005 TRAMONTINA MASTER	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C165	Ferramentas para construção civil	1	2025-08-21 21:18:08.840228	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:08.845327
162	PARAFUSADEIRA/FURADEIRA A BATERIA 18V 3/8 POL. SEM CARREGADOR E - DWT-6014182000 DWT	DWT	DWT-6014182000	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C745	Ferramentas a bateria	1	2025-08-21 21:18:14.038132	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:14.043911
163	SOQUETE SEXTAVADO LONGO DE 13MM COM ENCAIXE 1/4 POL. GEDORE RED	GEDORE RED	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:18:16.787693	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:16.793408
170	Martelo Alemão 42mm Cabo Fibra 1370FT BETA 013700542 BETA	BETA	1370FT	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C165	Ferramentas para construção civil	1	2025-08-21 21:18:41.324067	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:41.329599
171	CHAVE JG FENDA/PHIL 5PC AZ 1/8X3-1/4X6-8"/1/8XPH0-3/16XPH1 - GEDORE 150160S3	GEDORE	150160S3	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C744	Chave de fenda e Phillips	1	2025-08-21 21:18:43.773629	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:43.779131
173	CHAVE PHILLIPS TOCO 1/4  X 1.1/2  036.420 GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C744	Chave de fenda e Phillips	1	2025-08-21 21:18:50.396683	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:50.402133
174	ALICATE UNIVERSAL 8  ISOLADO IEC 44300/008 TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C740	Alicates	1	2025-08-21 21:18:53.321178	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:53.326668
176	DISCO DE LIXA 125MM GR150 C/VELCRO C/10PÇS D-54184	MAKITA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C027	Abrasivos	1	2025-08-21 21:19:00.088449	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:00.094701
309	Condulete Fixo 3/4" X com Rosca 56109/302 TRAMONTINA ELETRIK 56109302 TRAMONTINA ELETRIK	TRAMONTINA ELETRIK	56109/302	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C079	Conduletes	1	2025-08-21 21:33:44.205708	1755822625	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:44.210441
166	PINCA 2,4MM P/TOCHA TIG HW26ER (0705915) ESAB	ESAB	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C751	Ferramentas para solda	1	2025-08-21 21:18:27.856863	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:27.863383
167	CHAVE ALLEN JG 428P 1/16 A 1/4 C/ 8 PECAS GEDORE. GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C741	Chave allen/hexagonal	1	2025-08-21 21:18:31.4654	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:31.470987
168	MARRETA C/ CABO DE BORRACHA ALMA AÇO 6KG 050.883 GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 21:18:34.279064	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:34.28534
177	CHAVE POLIGONAL ABERTA 10 X 11MM 44635/102 TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:19:04.477824	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:01.610147
178	ANEL VEDACAO REDONDO N12 X 2  9645-948-7526  RE-98	STIHL 	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C270	Juntas de vedação	1	2025-08-21 21:19:08.359048	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:08.365403
179	Manipulo para Chave Estrela Pesada 46 a 55mm 25 x 760 mm 92/3 BETA 000920030 BETA	BETA	92/3	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:19:10.997585	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:11.003648
181	TALAB EM Y ELAST C/ABS G55MM PT/LAR WPSAN245140ADD DELTA	DELTA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C051	Conexões	1	2025-08-21 21:19:17.350425	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:17.356007
182	SOQUETE 1/2  X 27MM DE IMPACTO LONGO 44885/127 TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:19:20.434266	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:20.440584
184	PINO GRAXEIRO 65G AC 1/8" NPT 23C WASINGER	WASINGER	23C	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C325	Rebites e pinos	1	2025-08-21 21:19:25.920696	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:25.926745
185	LIXADEIRA DE PAREDE 750WTS 220V LPC750 CSM	CSM	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:19:28.424469	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:28.430121
187	CHAVE IMP PNEUM REV 1" 3138NM 3200RPM AT5190TK - PUMA EZ9F13210	PUMA	EZ9F13210	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C746	Ferramentas automotivas	1	2025-08-21 21:19:33.793202	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:33.799204
188	PROJETOR MODULAR LED - 5.000K - LENTE 90º - BIVOLT	CONEXLED	CLF-MP150FK50CF90	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Luminárias	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Luminárias	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C769	Refletores	1	2025-08-21 21:19:36.699838	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:36.706253
189	LAMPADA FLUOR TUB T10 5000K G13 40W T1040W/75750 PHILIPS	PHILIPS	T1040W/75750	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Outros objetos de iluminação	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Outros objetos de iluminação	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C761	Lâmpadas fluorescentes	1	2025-08-21 21:19:39.323607	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:39.329684
191	SINALIZ SON CAMPAINHA 220V - PIAL 41278	PIAL	41278	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Outros objetos de iluminação	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Outros objetos de iluminação	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C269	Outros componentes eletrônicos	1	2025-08-21 21:19:44.636976	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:44.642873
194	LAMPADA FLUOR TUB T5 3000K G5 28W 1191MM SMARTLUX 7009685 - LEDVANCE LUMILUXT5HE28WSL830	LEDVANCE	LUMILUXT5HE28WSL830	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Outros objetos de iluminação	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Outros objetos de iluminação	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C761	Lâmpadas fluorescentes	1	2025-08-21 21:20:12.970942	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:12.976829
195	COLA SPRAY REPOSICIONAVEL 340G/500ML 21593006200 TEKBOND	TEKBOND	 	MRO: MATERIAL, REPARO E OPERAÇÃO > LUBRIFICANTES > Aditivos	MRO: MATERIAL, REPARO E OPERAÇÃO	LUBRIFICANTES	Aditivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S74	QUÍMICOS INDUSTRIAIS	C786	Químicos orgânicos	1	2025-08-21 21:20:15.590745	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:15.596931
196	TINTA MAZA ZARCAO CINZA ESCURO 900ML 15454	MAZA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > LUBRIFICANTES > Aditivos	MRO: MATERIAL, REPARO E OPERAÇÃO	LUBRIFICANTES	Aditivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S74	QUÍMICOS INDUSTRIAIS	C788	Solventes	1	2025-08-21 21:20:18.434966	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:18.441527
198	Graxa Branca Spray 300ml/200g Lítio 5986113015 5986113015 WURTH	WURTH	5986113015	MRO: MATERIAL, REPARO E OPERAÇÃO > LUBRIFICANTES > Graxas	MRO: MATERIAL, REPARO E OPERAÇÃO	LUBRIFICANTES	Graxas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S49	LUBRIFICANTES	C103	Graxas	1	2025-08-21 21:20:25.796218	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:25.802157
200	CONVERSOR SINAL MINI 24V MCR-SL-U-U	PHOENIX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:20:32.565276	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:32.571175
201	MODULO TOMADA 1 MOD BR 2P+T 10A 250V BA PLUS+ 615038BC PIAL LEGRAND	PIAL LEGRAND	615038BC	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:20:35.902156	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:35.907844
202	PARTIDA 3RM1 DIR SAFETY 1,6-7A PARAF	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:20:39.203346	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:39.209631
204	DISJUNTOR CAIXA MOLDADA TRIPOLAR 25A 36KA 380/415V 50/60HZ	ABB	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:20:44.66218	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:44.668279
205	PLACA COMUNIC VW3A3422 VW3A3422 - SCHNEIDER	SCHNEIDER	VW3A3422	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:20:47.590337	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:47.596264
207	PLACA 3+3 POSTOS 4X4" BR PLUS+ 618516BC - PIAL LEGRAND	PIAL LEGRAND	618516BC	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:20:53.171997	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:53.178464
208	DISJUNTOR CAIXA MOLDADA TRIPOLAR 100A 18KA 380/415V 50/60HZ	WEG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:20:55.7367	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:55.742626
209	LANTERNA P/ BICICLETA VONDER. VONDER	VONDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C214	Outros objetos de iluminação	1	2025-08-21 21:20:58.433569	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:58.439549
211	MODULO TOMADA TELEFONE RJ11 (4 FIOS) 1 MOD BC COMPOSE	WEG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:21:05.450207	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:05.456288
212	INDICADOR DIG TEMP PAINEL PROG 4DIG PT 24V 4-20MA USB N1040I N1040-I - NOVUS	NOVUS	N1040-I	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:21:08.19933	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:08.205271
214	CONECTOR UNIDUT RETO AL S/V S/R 2.1/2" 56131007 56131007 - TRAMONTINA	TRAMONTINA	56131007	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C051	Conexões	1	2025-08-21 21:21:15.473927	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:15.479963
215	CHAVE PARTIDA DIRETA TRIFASICO 380V	WEG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C774	Chaves magnéticas	1	2025-08-21 21:21:39.59567	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:39.602021
217	DISJUNTOR MINI DIN TRIPOLAR 1A CURVA C 40KA 220/380V	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:21:47.807386	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:44.994038
218	LAMP LED T8 G13 6500K BIV 40W 2400MM OUROLUX SUPERLED TUBE HO	OUROLUX	SUPERLED TUBE HO 40W	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C761	Lâmpadas fluorescentes	1	2025-08-21 21:21:51.097777	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:51.103814
219	CONVERSOR CORRENTE E-12VDC S-12VDC 5A QUINT-OS/12DC/24DC/5	PHOENIX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C132	Fontes de energia	1	2025-08-21 21:21:54.506363	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:54.512553
221	DISJUNTOR MOTOR TRIPOLAR 32A 400V 100KA 400V 50/60HZ	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:22:03.925259	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:03.931067
223	VISOR REPOSICAO POLIC IPT E060093002 - WETZEL  E060093002	WETZEL	E060093002	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros componentes eletrônicos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros componentes eletrônicos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:22:22.567519	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:22.573734
224	ALPHA-QDR/S/IP43/1100X300 8GK11025KK12 - SIEMENS  8GK11025KK12	SIEMENS	8GK11025KK12	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros componentes eletrônicos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros componentes eletrônicos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:22:25.819062	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:25.825601
226	LUVA PROT MEC VAQ T M VT220	ROSA CAMPOS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:22:43.424414	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:43.430836
227	ACESSORIO FRONTAL MONOBL ANTIVANDALISMO 1 BOT INOX 333114	PIAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:22:52.775674	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:52.782003
228	Redução com Rosca 1.1/2" x 1" 56124/009 TRAMONTINA ELETRIK 56124009 TRAMONTINA ELETRIK	TRAMONTINA ELETRIK	56124/009	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C051	Conexões	1	2025-08-21 21:22:56.229089	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:56.235601
230	S8 SUP W10-8PQ9157-7AA20	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:23:02.991591	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:23:02.997408
231	PLACA REDONDA 3+3 POSTOS 4X4 SKY - PIAL LNB4826TS	PIAL	LNB4826TS	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:23:06.207609	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:23:06.214453
233	TRILHO DIN 24 MOD GEMINI 4-5 1SL0292A00	ABB ELETRIFICACAO	1SL0292A00	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:23:12.352886	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:23:12.358651
234	AS 168 68X1154MM AF ASTER SL LUMINARIA LED BRC NEUTRO 07542	INTRAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C765	Luminárias	1	2025-08-21 21:26:16.274719	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:16.281178
235	COMUTADOR KNOB LG 2POS  PT 22MM 60G 2NA+2NF NKP260/01+B22	ACE SCHMERSAL	NKP260/01+B22	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:26:19.195372	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:19.202183
236	PLUGUE IND MOV MACHO PA 3P+T 16A 690V PT N4075	STECK	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:26:22.5196	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:22.526576
238	PLUGUE IND SOB FEM 2P+T 32A 380-440V VM SN3279 STECK	STECK	SN3279	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:26:41.163193	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:41.169703
239	INTERRUPTOR UNIP 15A 14101 N1FB2FE3Q	MARGIRIUS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:26:43.945893	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:43.952581
241	SENSOR INDU MET 1,5MM SL1,58G1LPA	WEG CONTROLS	SL1,58G1LPA	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:26:49.164832	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:49.170796
242	S8 SUPORTE 8PQ9143-1AA62	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:26:52.412468	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:52.418534
243	MOTOR 3F 8P 0.16CV 71 380/660 B3D IP55 WFF2 IE2 11742459	WEG MOTOR	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S25	BOMBAS E MOTORES	C228	Motores	1	2025-08-21 21:26:59.485641	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:59.491491
313	CHAVE PART REVERSA 24VCA/VCC 2,9W 3-12A 3RA62501DB32 SIEMENS	SIEMENS	3RA62501DB32	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C774	Chaves magnéticas	1	2025-08-21 21:33:58.082503	1755822626	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:58.087225
246	SENSOR CAPAC 32MM 30MM CC  CA NF M12 CS3032P70UFJV1EX	SENSE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:27:12.311912	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:27:12.318009
247	TRANSF CORRENTE ENROLAD TAB-40 15/5	ABB ELETRIFICACAO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C360	Transformadores	1	2025-08-21 21:27:15.114442	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:27:15.120488
248	BOTAO COG 36MM VM 22MM 1NA+1NF EZ236/03+B11	ACE SCHMERSAL	EZ2 36/03+B11 10330103	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:27:17.940068	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:27:17.947344
250	CAIXA PASSAGEM SOB CZ MONT EM/REARME 14403094	ACE SCHMERSAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:30:16.944348	1755822614	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:14.422704
251	Conjunto 4x2 - 1 Pulsador Campainha 10a 250v~ 57170/007 ELETRIK 57170007 TRAMONTINA ELETRIK	TRAMONTINA ELETRIK	57170/007	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:30:19.973767	1755822614	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:19.978932
252	CAIXA DERIV MULT CZ TIPO X 2.1/2" C/ 2 TPOES, E002400080	WETZEL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C079	Conduletes	1	2025-08-21 21:30:22.650166	1755822614	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:22.655227
254	CABO FLEXIVEL 1KV 90G HEPR 4X1,5MM2 PT	CABOS DIVERSOS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C773	Cabos e fios elétricos	1	2025-08-21 21:30:29.986898	1755822614	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:29.99264
255	COMPUTADOR SIMATIC IPC527G BOX PC 6AG40250DB304AB0	SIEMENS AUTOMACAO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:30:34.937276	1755822615	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:32.50732
257	FILTRO DE LINHA 5T PLASTICOS PTO FLOWPACK 20201005111 FIOLUX	FIOLUX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C777	Extensões elétricas e filtros de linha	1	2025-08-21 21:30:41.880549	1755822615	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:41.885741
258	QUADRO CHT 01 ESTR TRIANG 3F 380VCA 30CV 25 32A 3CHT0119383	ALTRONIC	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:30:44.943895	1755822615	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:44.949088
260	S8 TAMPA PROT FASE 3VA-8PQ9138-8AA16	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:30:54.166959	1755822616	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:51.734671
261	M RELE P/PCI 1 REV 6 VDC 406170060000	FINDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:30:57.042616	1755822616	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:57.048285
262	PLAQUETA IDENTIFICACAO P/JOYSTICK 2 P M22-XCK3 290260	EATON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C269	Outros componentes eletrônicos	1	2025-08-21 21:30:59.802601	1755822616	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:59.811373
264	CONTATOR 4P 9A 110VCA 60HZ CWM90022V15	WEG CONTROLS	CWM90022V15	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:31:06.538118	1755822616	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:06.543092
265	CARTAO POTENCIA P/INVERS P500A41.06	WEG PARTES PECAS AUTOMACAO	P500A41.06	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:31:11.826904	1755822617	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:09.057572
267	PONTE SAK 2,5MM QL 4 SAK 2.5 QL 4	CONEXEL	SAK 2.5 QL 4	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 21:31:17.111855	1755822617	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:17.117255
315	ADAPTADOR ROSCA PG29 BSP 1" P/TOM IND S0151 STECK	STECK	S0151	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C051	Conexões	1	2025-08-21 21:34:05.557579	1755822627	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:03.265687
270	SENSOR IND M18 8MM NA M12 20 A 250 VCAVCC PS818GI70UAV1EX	SENSE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:31:27.59884	1755822618	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:25.274049
271	E201 ELEMENTO DE CONTATO C/RETENCAO 1NF	ACE SCHMERSAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:31:30.311808	1755822618	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:30.317668
272	BLOQUEADOR HARMONICA 4DB16,3440P14	SIEMENS	4DB163440P14	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C777	Extensões elétricas e filtros de linha	1	2025-08-21 21:31:33.464583	1755822618	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:33.46962
274	SENSOR ELETRONICO FOTOELETRICO REFLEXIVO RET FR50RNSVK4	ACE SCHMERSAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:31:39.250862	1755822618	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:39.256522
275	CONTATO AUX LATERAL P/DM2 2NA DMCL220	METALTEX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:31:44.786926	1755822619	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:41.771349
276	PROJETOR LED PT 500W 6500K 3278	OUROLUX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C769	Refletores	1	2025-08-21 21:31:47.673354	1755822619	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:47.678572
278	ABRACADEIRA U SIMPLES LINHA LEVE 3/8" S 4.000	STRINGUETO	S4000Z	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C291	Outros elementos de fixação e vedação	1	2025-08-21 21:31:53.379927	1755822619	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:53.385312
279	PLUG APT CAPA DE BORRACHA S/ ANEL 2P 30A 380V ER40T230	NAVILLE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:31:56.033119	1755822619	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:56.038635
281	MODULO EXPANSAO FUNCAO EES1 12154765	WEG DRIVES	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:32:03.764602	1755822620	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:03.770356
282	RELE POT P/PCI 3 REV.125 VDC 622391250000	FINDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:32:06.85208	1755822620	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:06.857539
283	TECLA P/BOTAO COMANDO PT M22-XDH-S 216428	EATON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:32:09.829224	1755822620	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:09.834384
285	CABO FLEXIVEL 750V 70G PVC 150MM2 PT	CABOS DIVERSOS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C773	Cabos e fios elétricos	1	2025-08-21 21:32:18.231293	1755822621	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:16.129808
286	Bucha 1.1/2" 56134/006 TRAMONTINA ELETRIK 56134006 TRAMONTINA ELETRIK	TRAMONTINA ELETRIK	56134/006	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C781	Tubos e eletrodutos	1	2025-08-21 21:32:21.571464	1755822621	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:21.576446
288	LPJ-50SP FUSIVEL CARTUCHO 50A 600V	BUSSMANN	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:32:26.975456	1755822621	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:26.980964
289	Condulete Fixo 3" Tipo "Ll" - com Tampa / sem Rosca / sem Pintura 56104/318 ELETRIK 56104318 TRAMONTINA ELETRIK	TRAMONTINA ELETRIK	56104/318	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C079	Conduletes	1	2025-08-21 21:32:29.653238	1755822621	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:29.658608
291	SERVOMOTOR 3000RPM 28NM IP64 1FT70865AF701CB0	SIEMENS DRIVES	1FT70865AF701CB0	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:32:38.267143	1755822622	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:38.272281
307	TOMADA SOB FEMEA 2P+T 16A 220-240V AZ C/BLOQ MEC IP67 SS300 STECK SS3006B	STECK	SS3006B	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:33:37.954708	1755822625	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:37.960311
308	CONEC. FEM S/ ROSCA ZN  DUTOTECFLEX  1" QTF3064	DUTOTEC	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C051	Conexões	1	2025-08-21 21:33:41.690025	1755822625	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:41.695231
310	BATENTE DE SEGURANCA SE-AL-12-2250MM AL 125405	ACE SCHMERSAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C291	Outros elementos de fixação e vedação	1	2025-08-21 21:33:48.885662	1755822626	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:46.725438
311	COMUTADOR KNOB CT 2P PT 30MM 2NA SP A3 60/01+E120 12209101	ACE SCHMERSAL	SP A3 60/01+E120 12209101	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:33:52.062273	1755822626	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:52.067339
312	CONDULETE PES AL PARAF INOX TIPO T 2 1/2" ROSCA BSP ER15T7B	NAVILLE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C079	Conduletes	1	2025-08-21 21:33:54.83966	1755822626	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:54.844387
314	CHAVE SEL MET ILUM KNOB CURT 2POS FIX 90G AM 24V 1NA	METALTEX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:34:00.740969	1755822626	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:00.74608
317	CURVA V90 INT 25 - 45 AZ R60 ITA R DT3806862	DUTOTEC	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C097	Cotovelos	1	2025-08-21 21:34:11.674549	1755822627	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:11.679853
293	KIT TAMPA PORTA TRILHO OURO BOX 05 MOD PORTA OPACA SKIT5POW	STECK	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:32:44.561149	1755822622	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:44.566553
294	CARTAO OPCIONAL P/ TPW04-2D2TBD 13001090	WEG DRIVES	TPW042D2TBD	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:32:49.474859	1755822622	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:49.479598
296	SINALIZADOR LUMINOSO QUADRO S 230V AC AMAR 21042103000	PFANNEMBERG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C290	Outros materiais elétricos	1	2025-08-21 21:32:58.567064	1755822623	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:58.57204
297	TEMPORIZADOR PROG 24VCC 1S EGZAN AP 1S	CONEXEL	EGZAN AP 1S	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:33:01.5304	1755822623	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:01.535084
298	RACK ABERTO  32U 550MM 1,5M 400MM 19" CZ 905782CZ	CEMAR	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:33:04.270094	1755822623	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:04.275432
300	SERVOMOTOR CA 22NM/2000RPM ENCA 1FK70854CC711RA0	SIEMENS DRIVES	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:33:15.344836	1755822624	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:09.833802
301	CONTATOR TRIPOLAR 95A - AC3, 42V/50-60HZ 239485 239485	EATON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:33:18.247896	1755822624	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:18.253103
303	Arruela 3/8" 56135/001 ELETRIK 56135001 TRAMONTINA ELETRIK	TRAMONTINA ELETRIK	56135/001	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C308	Parafusos, pregos, porcas, buchas e arruelas	1	2025-08-21 21:33:23.999289	1755822624	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:24.00461
304	JOELHO 90 SOLD 20MM CB 22150219	TIGRE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C152	Joelhos	1	2025-08-21 21:33:27.087803	1755822624	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:27.09335
305	BASE P/LIGACAO POR SOLDA P/RELE SERIE 55.34 9434SMA	FINDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 21:33:32.302091	1755822625	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:29.607578
316	FOTOMICROSENSOR,L-ON/D-ON,NPN,SLOT 5MM EE-SX674	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C269	Outros componentes eletrônicos	1	2025-08-21 21:34:08.349027	1755822627	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:08.3542
318	CAIXA RED. APT IP65 AL. F. 96X52 E 1/2 BSP ER10P1EB	NAVILLE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:34:14.86897	1755822627	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:14.875382
319	DISJ 3P 1000A 66KA 3WL1110-3BB64-4AN2-Z 3WL11103BB644AN2Z	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:34:17.868002	1755822627	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:17.873395
321	LUMINARIA POSTE LED 200W 23340LM 120-277V BSP EYLR6820060PS	NAVILLE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C765	Luminárias	1	2025-08-21 21:34:25.689244	1755822628	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:25.694216
322	S8 SUPORTE 8PQ9137-8AA34	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C291	Outros elementos de fixação e vedação	1	2025-08-21 21:34:30.033628	1755822628	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:30.038255
323	TOMADA EMB FEMEA 3P+T 200A 600-690V PT IP67 S4845MT STECK	STECK	S4845MT	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:34:33.215865	1755822628	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:33.220726
325	S8 DIVISORIA 8PQ9152-4AA77	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:34:41.748204	1755822629	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:39.017455
326	Cadeado de Latão 30mm com Chave Preto SM LT-30 PADO 51016396 PADO	PADO	SM LT-30 COLOR	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C291	Outros elementos de fixação e vedação	1	2025-08-21 21:34:45.217298	1755822629	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:45.222249
328	ACESSORIO 3AE1 - MANIVELA DE ACIONAMENTO	SIEMENS MEDIA TENSAO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C253	Outros componentes de partes mecânicas	1	2025-08-21 21:34:51.596672	1755822629	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:51.601386
329	TERMINAL JACK MALE 8-32 (BLACK) 73088-0	FLUKE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 21:34:54.380839	1755822629	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:54.386029
331	COMUTADOR KNOB CT 3POS VM 22MM 45G CLAA245R03	ACE SCHMERSAL	CLAA245R03	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:35:03.474962	1755822630	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:03.479484
332	DO-IT-YOURSELF 2MM STACKABLE SAFETY S 72925-2	FLUKE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:35:06.304432	1755822630	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:06.309833
333	CABO FIBRA OPTICA DIFUSO M6X90MM 2M. E32-DC200D	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:35:09.436009	1755822630	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:09.441469
335	ACOPLAMENTO FRONT RJ45 CAT6 PT IEFCMRJ45C WEIDMULLER CONEXEL	WEIDMULLER CONEXEL	IEFCMRJ45C	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:35:18.723594	1755822631	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:16.545963
336	CABO POT MOT-CON 800PLUS 15M 6FX80081BA501BF0	SIEMENS DRIVES	6FX80081BA501BF0	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C773	Cabos e fios elétricos	1	2025-08-21 21:35:21.605027	1755822631	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:21.610381
338	TRANSFORMADOR 1F E200-500V S115/230V 3500VA 350TMC4676	MINUZZI	350TMC4676	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C360	Transformadores	1	2025-08-21 21:35:27.688803	1755822631	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:27.693963
340	MODULO EXPANSAO 32 CJ1W-MD261	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:35:35.584068	1755822632	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:33.355931
342	PLACA SEPARACAO TERMOP TW SS/32	CONEXEL	TW SS/32	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S09	BARRAS E CHAPAS	C060	Chapas	1	2025-08-21 21:35:42.55444	1755822632	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:42.559568
343	DISJUNTOR CX MOLD 40A 100KA NZMH24A40 	EATON	NZMH24A40	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:35:45.768416	1755822632	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:45.77305
345	E2E-X2D1-M1G SENSOR 24VDC NPN M8X1	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:36:28.688127	1755822633	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:00.950008
346	BARRAMENTO ELET PINO 2F ISOL 110A P/16DISJ  BRF2	PIAL	BRF2	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:36:31.692515	1755822633	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:31.697645
347	AMP BM LIG DIR 90O 72X72 40A 2CNM512211R0040	ABB ELETRIFICACAO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C025	Amplificadores	1	2025-08-21 21:36:34.873761	1755822633	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:34.878604
349	BOTAO ILUM DUP MET VD/VM 22MM 120V LED 1NA+1NF - SCHNEIDER XB4BW73731G5	SCHNEIDER	XB4BW73731G5	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Tomadas e interruptores	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Tomadas e interruptores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:36:40.766766	1755822633	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:40.771864
350	TE 90GR pvc MR SOLD 60MM 22200607 TIGRE	TIGRE	22200607	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Tubos e eletrodutos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Tubos e eletrodutos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S54	TUBOS E CONEXÕES	C051	Conexões	1	2025-08-21 21:36:45.747695	1755822634	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:43.287196
352	CORREIAS-PHG SPC11200 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:36:52.09646	1755822634	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:52.100965
353	CORREIAS-PHG 3V800X5 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:36:56.339922	1755822634	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:56.344764
354	CORREIAS-PHG S8M-880-50 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:36:59.558951	1755822634	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:59.564427
355	ANEL INTERNO-IR 17X22X16 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:37:04.193723	1755822635	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:02.081745
357	CORREIAS-PHG 5V2120X3 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:10.750957	1755822635	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:10.755925
358	CORREIAS-PHG 3150-14M-170 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:13.643653	1755822635	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:13.648388
360	ANEL INTERNO-IR 50X58X40 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:37:24.302469	1755822636	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:19.582444
361	CORREIAS-PHG SPA670 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:26.903751	1755822636	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:26.909007
363	CORREIAS-PHG B63X4 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:33.92168	1755822636	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:33.926483
1	INTTR MECANICO 3TX7466-1XA1	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 15:36:26.365812	1755801372	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:36:12.968091
2	DISJUNTOR MOTOR 3P 30-36A 690V S2 3RV20314PA10 SIEMENS	SIEMENS	3RV20314PA10	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 15:36:33.260315	1755801372	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:36:33.265935
5	ELEMENTO ACUSTIC AJUSTAVEL 24V	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:36:49.704382	1755801372	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:36:49.719803
8	CONTATOR MINI POTENCIA TRIPOLAR 16A 24VCC 1NF	WEG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 15:37:07.457315	1755801373	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:07.468531
12	CABO CONEXAO SIMATIC RF600 P/ANTENA L20 PRE-MONTADA ENTRE LEITOR E ANTENA IP65 	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C716	Conexões	1	2025-08-21 15:37:36.968404	1755801374	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:36.973781
15	SERVOMOTOR CA 8NM/2000RPM ENCA 1FL60641AC612LG1	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:37:55.066686	1755801374	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:37:55.082672
19	CONTATOR POTENCIA 4P 80A 110-220VCA/VCC AF80400013 ABB ELETRIFICACAO	ABB ELETRIFICACAO	AF80400013	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 15:38:48.14433	1755801516	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:38:48.153685
38	LONA POLIETILENO LARANJA 8 X 5M 6168085000 NOVE54. VONDER	VONDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C028	Lonas e toldos	1	2025-08-21 21:11:49.69937	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:11:49.703862
42	DISCO DE CORTE FINO-METAL / INOX 7POL X 1,6MM 7/8POL DW8065-AR DEWALT	DEWALT	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:12:01.445048	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:01.449629
45	Elemento Filtrante para Filtro MDR-040 Plus EF-0070-M40 METALPLAN EF0070M4 METALPLAN	METALPLAN	EF-0070-M40	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Acessórios e consumíveis para ferramentas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Acessórios e consumíveis para ferramentas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S46	MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS	C346	Filtros industriais	1	2025-08-21 21:12:09.902034	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:09.906485
50	MOCOCA FOSFATOL 1L 25192	MOCOCA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas automotivas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas automotivas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S74	QUÍMICOS INDUSTRIAIS	C785	Químicos inorgânicos	1	2025-08-21 21:12:26.756005	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:26.761277
51	PISTOLA PINTURA C/ CAN PLASTICA SGK600BV DEVILBISS. DEVILBISS	DEVILBISS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas automotivas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas automotivas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C750	Ferramentas para pintura	1	2025-08-21 21:12:29.608871	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:29.613585
52	KIT PRATICO DE REPARO TKTK-6 JEDAL. JEDAL	JEDAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas automotivas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas automotivas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:12:32.387669	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:32.392326
53	Serra Copo Bimetal 57mm Variavel DCH0214-G STARRETT DCH0214-G STARRETT	STARRETT	DCH0214-G	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:35.549428	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:35.553842
54	Alargador Manual HSS 20.00mm Canal Helicoidal Din 206B 206200 HEINZ 206200 HEINZ	HEINZ	206200	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:37.937464	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:37.942438
56	Broca para Cerâmica/Azulejo 7,00mm 2608587163 BOSCH 2608587163000 BOSCH	BOSCH	2608587163	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:43.401632	1755821504	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:43.406009
59	Broca Metal Duro 9,80mm Din 6537L TIALN 5xD MD-5D OSG 5015D098E OSG	OSG	MD-5D	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:12:54.015422	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:12:54.020164
63	Fresa Topo Reto Metal Duro 2,00mm 4 Cortes 36900 HT 36900 HT	HT	36900	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas de corte e desbaste	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas de corte e desbaste	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:13:06.641041	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:06.645742
67	Esmerilhadeira Angular 5" 2 Baterias 18V Carregador Bivolt e Maleta PTFL-7037K PUMA PTFL-7037K PUMA	PUMA	PTFL-7037K	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C745	Ferramentas a bateria	1	2025-08-21 21:13:18.354365	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:18.359204
70	LIXADEIRA ORBTIAL 1/4 DE FOLHA 240W 127V WS4151U WESCO	WESCO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C748	Ferramentas elétricas	1	2025-08-21 21:13:27.036684	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:27.041073
72	COMPRESSOR DE AR 25L 220V CP8525-2C TEKNA. TEKNA	TEKNA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas elétricas	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas elétricas	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S46	MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS	C390	Outros materiais hidráulicos ou pneumáticos	1	2025-08-21 21:13:32.625374	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:32.629974
75	NIVEL DE ALUMINIO 24 600MM 3 BOLHAS C/REGUA VERMELHO 332239 MTX. MTX	MTX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Ferramentas para construção civil	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Ferramentas para construção civil	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:13:41.572444	1755821505	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:41.57706
79	Soquete Impacto Sextavado 15mm Encx 1/2"" Branco 720MC BETA 007202015 BETA	BETA	720MC	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:13:56.711721	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:56.716587
80	HASTE 9X9MM COMPR. 50MM P/REL. APAL. S.513 953.638 MITUTOYO	MITUTOYO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C253	Outros componentes de partes mecânicas	1	2025-08-21 21:13:59.4634	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:13:59.468096
82	Soquete Estriado em aço Cromo Vanádio 9 mm - Encaixe 1/2" 44833/109 TRAMONTINA PRO 44833109 TRAMONTINA PRO	TRAMONTINA PRO	44833/109	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:14:05.764804	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:05.769423
86	SERRA COPO AÇO INOX 35MM  HEAVY DUTY	HEAVY DUTY	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:14:17.73104	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:17.735981
90	SACA POLIA HIDR 3 GARRAS ARTIC 180MM 8567 H - GEDORE 8567H	GEDORE	8567H	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C746	Ferramentas automotivas	1	2025-08-21 21:14:29.704891	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:29.710167
94	ANEL PADRAO DE 300MM 177-312 MITUTOYO	MITUTOYO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:14:41.177953	1755821506	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:41.183362
97	GERADOR DE ENERGIA REFRIGERADO A ÁGUA TD25SGE3  4T 27,5KVA PARTIDA ELÉTRICA TOYAMA	TOYAMA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S25	BOMBAS E MOTORES	C228	Motores	1	2025-08-21 21:14:51.54598	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:14:49.27123
101	TALHA MANUAL 5,0 TON ELEVACAO 3MT 61 43 050 030 VONDER	VONDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 21:15:03.222078	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:03.227036
104	SOQUETE 1/2  X 19MM DE IMPACTO SEXTAVADO 019.014 GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:15:11.67058	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:11.675256
108	JOGO DE SOQUETE TORX ENC. 1/2  E10 A E24 (8PÇS) TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:15:25.66365	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:25.668763
109	CALIBRADOR DE FOLGA EM LAMINA 300 X 0,40MM 600.042 KINGTOOLS	KINGTOOLS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:15:29.242332	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:29.247225
113	IMPLEMENTO HT - KA MOTOPODA 1/4 30CM 12  71PM3 STIHL *	STIHL 	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C749	Ferramentas para jardim	1	2025-08-21 21:15:40.82148	1755821507	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:40.826319
117	SOQUETE SEXT DE IMPACTO 10MM CRMO 1/2 1320155 STELS. STELS	STELS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:15:53.828784	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:15:50.940973
120	APLICADOR FITA ADESIVA 50MM AFA-050 WESTERN	WESTERN	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 21:16:02.992483	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:02.997477
123	Talhadeira para Martelo SDS Plus 20x250mm 2608690144 BOSCH 2608690144000 BOSCH	BOSCH	2608690144	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:16:12.751983	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:12.757013
127	Alicate de Pressão 7" Bico Longo 1058 175 BETA 010580017 BETA	BETA	1058 175	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C740	Alicates	1	2025-08-21 21:16:24.737768	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:24.743129
131	SUPORTE P/FERRAMENTAS 35MM SM-A1 MARCON	MARCON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:16:36.867833	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:36.872478
175	Soquete Estriado em aço Cromo Vanádio 28 mm - Encaixe 3/4" 44853/128 TRAMONTINA PRO 44853128 TRAMONTINA PRO	TRAMONTINA PRO	44853/128	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C754	Jogos de soquetes	1	2025-08-21 21:18:56.625869	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:56.631807
180	CHAVE ESTRELA  SATA 12X14 MM ST42204SC SATA.	SATA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:19:14.621228	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:14.627193
183	BROCA PARA MADEIRA 3 X 61MM COM 10 UNIDADES MAKITA	MAKITA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:19:22.968439	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:22.974367
186	Bit Impacto Hexagonal 14mm Encx 16mm 727/ES16 BETA 007270114 BETA	BETA	727/ES16	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C741	Chave allen/hexagonal	1	2025-08-21 21:19:30.955342	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:30.961556
190	LUMINARIA REFLETOR LED RETANG SOBREPOR PT 30W BIVOLT 5000K LUZ DO DIA 3600LM DI	OSRAM/LEDVANCE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Outros objetos de iluminação	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Outros objetos de iluminação	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C769	Refletores	1	2025-08-21 21:19:41.974388	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:19:41.980217
192	LAMPADA FLUORESCENTE TUBULAR T8 32W G13 4100K BRANCO NEUTRO LUZ BRANCA 1200MM	PHILIPS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Outros objetos de iluminação	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Outros objetos de iluminação	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C761	Lâmpadas fluorescentes	1	2025-08-21 21:20:07.446042	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:07.452603
193	LAMPADA SINALIZ LED CL BA9S 24V - SADOKIN DBR-90	SADOKIN	DBR-90	MRO: MATERIAL, REPARO E OPERAÇÃO > ILUMINAÇÃO > Outros objetos de iluminação	MRO: MATERIAL, REPARO E OPERAÇÃO	ILUMINAÇÃO	Outros objetos de iluminação	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C760	Lâmpadas de LED	1	2025-08-21 21:20:10.208434	1755821511	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:10.213951
197	COLA BASTAO 40G BLISTER 22201040002 TEKBOND	TEKBOND	 	MRO: MATERIAL, REPARO E OPERAÇÃO > LUBRIFICANTES > Aditivos	MRO: MATERIAL, REPARO E OPERAÇÃO	LUBRIFICANTES	Aditivos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	2025-08-21 21:20:22.706108	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:19.955766
199	CONDULETE AL T 1" S/R NAT S/TP S/V S/PINT 56106313 - TRAMONTINA ELETRICA 56117007	TRAMONTINA ELETRICA	56117007	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C079	Conduletes	1	2025-08-21 21:20:29.511707	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:29.517326
203	BARRAMENTO ELET N 12F 100A 12X16MM2 AZ 928051 - CEMAR LEGRAND	CEMAR LEGRAND	928051	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 21:20:42.000058	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:42.005954
206	MANTA REPARO COBERT CABO BORR-EPR 70-185MM 35KV HB004208078 HB004208078 - 3M	3M	HB004208078	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C773	Cabos e fios elétricos	1	2025-08-21 21:20:50.416765	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:20:50.423159
210	PERFIL COBERTURA DAS BORDAS P/ BARRAS 1000MM C/10PC 9676042 9676042 - RITTAL	RITTAL	9676042	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C291	Outros elementos de fixação e vedação	1	2025-08-21 21:21:01.341588	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:01.34805
213	ANILHA PVC AM 4-16MM2 (N) MHG MHG4/9 - HELLERMANN SUPERLED 03265	HELLERMANN	SUPERLED 03265	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C340	Terminais	1	2025-08-21 21:21:10.983279	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:10.989424
216	INTERRUPTOR DIFERENCIAL RESIDUAL 3P+N 40A 30MA 10KA 400V 50HZ TIPO A	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:21:43.474793	1755821512	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:21:43.480896
220	MODULO ADAPTADOR RJ45 1 MOD BC (EMB C/2UN) REFINATTO	WEG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS DIVERSOS > Outros materiais MRO	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS DIVERSOS	Outros materiais MRO	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:22:00.680417	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:00.68688
222	TAMPA PAINEL MOD AC CZ CL 400X225X25MM 8PQ20224BA01 - SIEMENS  8PQ20224BA01	SIEMENS	8PQ20224BA01	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros componentes eletrônicos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros componentes eletrônicos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:22:08.48132	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:08.487788
225	RELE SUPERVISAO ISOL 380V C9041912000 - CONEXEL  C9041912000	CONEXEL	C9041912000	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros componentes eletrônicos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros componentes eletrônicos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:22:29.916717	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:29.922652
134	MÓDULO P/MEDIÇÃO DE PRESSÃO C/DUAS FAIXAS 15  TO 100  FLUKE-750PD6	FLUKE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:16:46.348129	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:46.353431
136	Chave Válvula Segurança 50mm Antifaiscante 965BA BETA 009650850 BETA	BETA	965BA	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	2025-08-21 21:16:52.184494	1755821508	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:52.189592
137	CHAVE ESTRELA 10X11MM 44630/103 TRAMONTINA. TRAMONTINA	TRAMONTINA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C743	Chave combinada	1	2025-08-21 21:16:55.963179	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:16:53.703039
140	GRAMPO P/ GRAMPEADOR MEDIO 51MM (AT1150) F-32139 MAKITA	MAKITA	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:17:05.123812	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:05.128833
144	ADAPTADOR TIPO CANHÃO  Ñ MAGNETICO 1/4  REF 11674-13 054 349	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C739	Acessórios e consumíveis para ferramentas	1	2025-08-21 21:17:18.042337	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:18.047371
148	INVERSOR DE SOLDA RIV 206 AC/DC COM TOCHA TIG  VONDER	VONDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C751	Ferramentas para solda	1	2025-08-21 21:17:29.778668	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:29.783828
150	TALHA MANUAL 1 TONELADA COM CORRENTE 5 METROS CSM	CSM	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S36	CORRENTES METÁLICAS E ENGRENAGENS	C042	Correntes	1	2025-08-21 21:17:36.456007	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:36.460877
154	RODIZIO FIXO DE POLIURETANO 6  CAP.280KG RM-92 MARCON	MARCON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C253	Outros componentes de partes mecânicas	1	2025-08-21 21:17:48.320293	1755821509	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:48.325546
157	PINO P/ PINADOR PNEUMATICO 25MM (CX 5000) MTX	MTX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C325	Rebites e pinos	1	2025-08-21 21:17:58.396123	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:17:55.645521
161	MICROMETRO EXTERNO DIG. S/SAIDA C/IP67 0-25MM 796.1MXRL-2	STARRETT	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C747	Ferramentas de medição	1	2025-08-21 21:18:11.468429	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:11.474543
164	CHAVE PHILLIPS 3/8  X 8  036.363 ENCARTELADA GEDORE	GEDORE	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C744	Chave de fenda e Phillips	1	2025-08-21 21:18:21.091533	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:21.097979
165	JOGO DE MACHO UNF Nº12 (7/32 ) 28 FIOS (3PÇS) AÇO LIGA WS ANSI HTOM	HTOM	 	MRO: MATERIAL, REPARO E OPERAÇÃO > FERRAMENTAS > Outras ferramentas manuais	MRO: MATERIAL, REPARO E OPERAÇÃO	FERRAMENTAS	Outras ferramentas manuais	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	2025-08-21 21:18:24.522371	1755821510	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:18:24.528135
229	FRONT BOT ILUM RED VD 22MM A22RLTRGN 	EATON	A22RLTRGN	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:22:59.24412	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:22:59.250626
232	Fusível NH 1 GL/GG Retardado 160A 120KA em 500VCA 3NA7136 SIEMENS 3NA7136 SIEMENS	SIEMENS	3NA7136	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:23:09.195332	1755821513	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:23:09.201114
237	KIT CAIXA LIGACAO 63-100 W22 15118630	WEG PARTES MOTOR	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:26:36.999328	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:24.040141
240	CHAVE FIM CURSO ACIONAMENTO TIPO ROLETE R50 WLCA2-7	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:26:46.516591	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:26:46.523208
244	BOTAO DUP VD/VM 22MM CLBD1403/05+CLP101+CLP110+C	ACE SCHMERSAL	CLBD 14 03/05+CLP101+CLP110+CL	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:27:03.133756	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:27:03.140624
245	SINALEIRO RED METAL VD 22MM 125V LED VZ222+L001+S7LS/15125V*	ACE SCHMERSAL	VZ 222+L001+S7LS/15 125VCA/CC+	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:27:06.10424	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:27:06.110693
249	FRONTAL CLB2/15 + CLP110 + CLP001 + S1LS/15 220V 14624915	ACE SCHMERSAL	14624915	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:27:20.591913	1755821514	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:27:20.598438
320	RELE ELETROMECANICO IMPULSOSAIDA DPDT,5A MM4XP DC48	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:34:22.666326	1755822628	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:20.387443
324	CHAVE SECC P125/EA/SV9BSW/HI11/HI11ZFS72 70030263 70030263	EATON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C774	Chaves magnéticas	1	2025-08-21 21:34:36.497557	1755822628	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:36.502105
253	DISJUNTOR MOTOR 56 - 80A DM280A	METALTEX	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:30:26.395307	1755822614	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:26.40056
256	CONECTOR INDUSTRIAL 32A 3P 2P+T 110-130V AMARELO 12821518	WEG INT E TOM	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:30:38.580335	1755822615	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:38.585409
259	SINALIZADOR LUMINOSO P 350 TMB-1 21398000000	PFANNEMBERG	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C214	Outros objetos de iluminação	1	2025-08-21 21:30:49.213345	1755822615	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:30:49.219301
263	1 INT TS+1 TP 10A/250V PL4X2 BR KLIN 13328421	WEG INT E TOM	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:31:03.003846	1755822616	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:03.009336
266	CONTR.TEMP.96X96 SAIDA ANALOGICA E5AC-CX3ASM-800	OMRON	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:31:14.310704	1755822617	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:14.315769
268	FRONTAL CLB2/03 40 + 2X CLP110 + 2X CLP101 1462450340	ACE SCHMERSAL	1462450340	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C240	Módulos	1	2025-08-21 21:31:19.825227	1755822617	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:19.830712
269	COMUTADOR CH YALE 2POS  PT 22MM 90G YPP290ERTECSEG15	ACE SCHMERSAL	YPP290ERTECSEG15	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:31:22.754343	1755822617	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:22.760681
273	COMUTADOR CH YALE 2POS PT 22MM 60G YPZ260DRTCSEG12	ACE SCHMERSAL	YPZ260DRTCSEG12	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:31:36.443671	1755822618	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:36.449352
277	CABO POT 21M COM CONECTORES 6FX50025DG121CB0	SIEMENS DRIVES	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C773	Cabos e fios elétricos	1	2025-08-21 21:31:50.591853	1755822619	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:50.597365
280	GUIA PONTA VARAO P/FECHADURA - TASCO 21916	TASCO	21916	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C253	Outros componentes de partes mecânicas	1	2025-08-21 21:32:01.050004	1755822620	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:31:58.552183
284	PORTA EQP SLIM  UMA TOM UNIVERSAL BRANCO DT7674100	DUTOTEC	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:32:13.610258	1755822620	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:13.615541
287	DISJ 3P 1600A 55KA 3WL1116-2AA32-4GN4	SIEMENS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:32:24.1639	1755822621	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:24.169619
290	KIT ANEL FIXACAO INPRO/SEAL IEEE ROL 319 13765767	WEG PARTES MOTOR	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C270	Juntas de vedação	1	2025-08-21 21:32:35.232102	1755822622	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:32.17271
292	CHAVE NIVEL ELETROMEC 250MM 220VCA CN1328/B - COEL 13028010	COEL	13028010	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C774	Chaves magnéticas	1	2025-08-21 21:32:41.420406	1755822622	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:41.425586
295	SERVOMOTOR 3000RPM 1,15NM IP64 1FK70322AK711QH0	SIEMENS DRIVES	1FK70322AK711QH0	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 21:32:55.811348	1755822623	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:32:51.995212
299	FUSIVEL ONE TIME NON-200	BUSSMANN	FUSIVEL ONE TIME NON-200	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:33:07.314461	1755822623	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:07.319487
302	COMUTADOR CH YALE 2POS  PT 22MM 60G YPCP260DRTESEG08	ACE SCHMERSAL	YPCP260DRTESEG08	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C350	Tomadas e interruptores	1	2025-08-21 21:33:21.417227	1755822624	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:21.422575
306	CAIXA BOTOEIRA ABS 80X230X85 CZ A2/VD/VM/EM BSP3/4 14403243	ACE SCHMERSAL	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:33:35.395399	1755822625	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:33:35.400255
327	CAPA PROT ZS 522/03 P/BS2 12024703	ACE SCHMERSAL	12024703	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C290	Outros materiais elétricos	1	2025-08-21 21:34:48.6622	1755822629	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:48.667309
330	PORTA QUADRO DISTRIBUICAO QDW02P-18 F 13293414	WEG CONTROLS	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C779	Quadros e caixas elétricas	1	2025-08-21 21:35:00.350847	1755822630	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:34:56.899844
334	KIT ROTOR COMPLETO 132 10802859	WEG PARTES MOTOR	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S25	BOMBAS E MOTORES	C311	Rotores	1	2025-08-21 21:35:14.024365	1755822630	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:14.029643
337	AMP BM LIG DIR 90O 96X96 25A 2CNM512221R0025	ABB ELETRIFICACAO	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C025	Amplificadores	1	2025-08-21 21:35:24.897535	1755822631	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:24.902626
339	PORTA EQP 2 BL DE RJ45 PANDUIT BRANCO DT6674500	DUTOTEC	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C314	Plugs e adaptadores	1	2025-08-21 21:35:30.832732	1755822631	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:30.837419
341	BOBINA DISJ ABERTURA 110-415VCA ZBHASA230	EATON	ZBHASA230	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C163	Fusíveis e disjuntores	1	2025-08-21 21:35:38.707855	1755822632	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:38.712637
344	RELE POT P/PCI 4 REV 24 VDC 564490240000	FINDER	 	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Outros materiais elétricos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Outros materiais elétricos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C775	Contatores	1	2025-08-21 21:35:58.430209	1755822632	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:35:58.434796
348	Resistência para Aquecedor Versátil 110V 5.500W 755-E LORENZETTI 7589055 LORENZETTI	LORENZETTI	755E	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS ELÉTRICOS E ELETRÔNICOS > Resistência elétrica	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS ELÉTRICOS E ELETRÔNICOS	Resistência elétrica	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C329	Resistências	1	2025-08-21 21:36:37.708261	1755822633	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:37.713006
351	Furadeira Reversível Pneumática 1/2" 700 rpm G3188/BR GAMMA G3188/BR GAMMA	GAMMA	G3188/BR	MRO: MATERIAL, REPARO E OPERAÇÃO > MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS > Outros materiais hidráulicos ou pneumáticos	MRO: MATERIAL, REPARO E OPERAÇÃO	MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS	Outros materiais hidráulicos ou pneumáticos	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S41	FERRAMENTAS	C216	Ferramentas perfuradoras	1	2025-08-21 21:36:48.733186	1755822634	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:36:48.737697
356	CORREIAS-PHG 380-XL-102 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:07.666931	1755822635	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:07.671759
359	ANEL INTERNO-IR 17X20X20.5 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C315	Rolamentos	1	2025-08-21 21:37:17.062796	1755822635	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:17.068087
362	CORREIAS-PHG C112 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:30.44594	1755822636	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:30.451308
371	RETENTOR-110X130X12 HMSA10 RG SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:38:02.520544	1755822638	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:38:02.525086
373	RETENTOR-32X47X7 HMS5 V SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:38:08.175479	1755822638	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:38:08.180473
376	RETENTOR-30X55X7 HMSA10 V SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:38:18.970096	1755822639	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:38:18.974708
364	CORREIAS-PHG 440-8M-50 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:36.772407	1755822636	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:36.782213
365	CORREIAS-PHG SPA3182 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:41.720616	1755822637	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:39.307298
366	CORREIAS-PHG 5VX1800EP SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Correias e componentes	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Correias e componentes	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	2025-08-21 21:37:45.993156	1755822637	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:45.998228
367	MANCAL COM ROLAMENTO-SYJ 60 KF SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Mancal	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Mancal	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C184	Mancal	1	2025-08-21 21:37:48.567966	1755822637	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:48.572532
368	MANCAL - SNL 524-620 V SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Mancal	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Mancal	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C184	Mancal	1	2025-08-21 21:37:51.65648	1755822637	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:51.661686
369	MANCAL COM ROLAMENTO-FYJ 55 TF SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Mancal	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Mancal	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C184	Mancal	1	2025-08-21 21:37:54.714803	1755822637	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:54.720041
370	RETENTOR-19993 SKF	SKF	 	MRO: MATERIAL, REPARO E OPERAÇÃO > PARTES MECÂNICAS, ROLAMENTOS E CORREIAS > Retentores	MRO: MATERIAL, REPARO E OPERAÇÃO	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	Retentores	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S39	ELEMENTOS DE FIXAÇÃO E VEDAÇÃO	C297	Retentores	1	2025-08-21 21:37:59.550425	1755822638	completed	\N	2025-08-21 18:35:31.706277	2025-08-22 00:37:57.234924
22	FRONT BOT RED VM 22MM 3SU10501BA200AA0 SIEMENS	SIEMENS	3SU10501BA200AA0	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S71	AUTOMAÇÃO INDUSTRIAL	C721	Outros materiais de automação industrial	1	2025-08-21 15:40:09.301958	1755801597	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:39:57.190619
25	BLOCO LUMINOSO LED BR 24V 3SU14011BB601AA0 SIEMENS	SIEMENS	3SU14011BB601AA0	MRO: MATERIAL, REPARO E OPERAÇÃO > AUTOMAÇÃO INDUSTRIAL > Outros materiais de Automação Industrial	MRO: MATERIAL, REPARO E OPERAÇÃO	AUTOMAÇÃO INDUSTRIAL	Outros materiais de Automação Industrial	D03	MRO: MATERIAL, REPARO E OPERAÇÃO	S73	ILUMINAÇÃO	C214	Outros objetos de iluminação	1	2025-08-21 15:40:28.163378	1755801597	completed	\N	2025-08-21 18:35:31.706277	2025-08-21 18:40:28.182743
\.


--
-- Data for Name: normalization_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.normalization_cache (id, subcategory_code, cached_context, example_products, token_count, last_updated) FROM stdin;
\.


--
-- Data for Name: normalization_dictionary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.normalization_dictionary (id, subcategory_code, original_pattern, normalized_form, pattern_type, confidence, usage_count, created_at, last_used, source) FROM stdin;
\.


--
-- Data for Name: processing_stats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.processing_stats (batch_id, batch_number, total_products, new_products, duplicates_found, low_confidence_count, processing_time_seconds, api_tokens_used, gpt5_cost_estimate, created_at) FROM stdin;
dc0d0c78-eddd-4bc4-928e-6bc172e43295	1	5	5	0	0	19.72498655319214	750	0.05625	2025-08-21 15:43:33.06676
\.


--
-- Data for Name: products_enhanced; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products_enhanced (id, original_name, normalized_name, category_code, category_name, subcategory_code, subcategory_name, duplicate_group_id, is_master, similarity_score, duplicate_count, classification_confidence, needs_review, review_notes, gpt5_reasoning, processed_at, processing_model, processing_batch_id, batch_position) FROM stdin;
1	FORMAO OLHO DE TIGRE CHAFRADO 3/8 POL 10 MM EMBO 245059 MTX.. MTX	formao olho de tigre chanfrado 9.5mm 10mm	S41	FERRAMENTAS	C134	Outras ferramentas manuais	1	t	1	1	0.95	f	\N	Formão é uma ferramenta manual para entalhe/corte. Normalizado: convertido 3/8 pol para 9.5mm, removida marca MTX e código, corrigido 'chafrado' para 'chanfrado'.	2025-08-21 15:43:32.536247	gpt-5-high-reasoning	dc0d0c78-eddd-4bc4-928e-6bc172e43295	0
2	FRESA ACO RAPIDO 5MM 4 CORTES LONGA HSS HT	fresa aco rapido hss 5mm 4 cortes longa	S41	FERRAMENTAS	C081	Ferramentas de corte e desbaste	1	t	1	1	1	f	\N	Fresa é claramente uma ferramenta de corte. Normalizado: reorganizado especificações, removida marca HT, mantido HSS por ser especificação técnica relevante.	2025-08-21 15:43:32.775827	gpt-5-high-reasoning	dc0d0c78-eddd-4bc4-928e-6bc172e43295	1
3	LUVA PROT MEC VAQ T M VT220	luva protecao mecanica vaqueta tamanho medio	S43	MATERIAIS DIVERSOS	C082	Outros materiais MRO	1	t	1	1	0.85	f	\N	EPI não tem categoria específica, classificado em materiais diversos. Normalizado: expandido abreviações (PROT→proteção, MEC→mecanica, T M→tamanho medio), removido código VT220.	2025-08-21 15:43:32.825109	gpt-5-high-reasoning	dc0d0c78-eddd-4bc4-928e-6bc172e43295	2
4	CONDULETE AL T 1" S/R NAT S/TP S/V S/PINT 56106313 - TRAMONTINA ELETRICA 56117007	condulete aluminio tipo t 25.4mm sem rosca natural sem tampa	S47	MATERIAIS ELÉTRICOS E ELETRÔNICOS	C079	Conduletes	1	t	1	1	1	f	\N	Condulete é claramente material elétrico. Normalizado: convertido 1" para 25.4mm, expandido AL→aluminio, removida marca e códigos, padronizado abreviações S/R→sem rosca.	2025-08-21 15:43:32.903494	gpt-5-high-reasoning	dc0d0c78-eddd-4bc4-928e-6bc172e43295	3
5	CORREIAS-PHG SPC11200 SKF	correia perfil spc 11200mm	S51	PARTES MECÂNICAS, ROLAMENTOS E CORREIAS	C151	Correias e componentes	1	t	1	1	1	f	\N	Correia tem categoria e subcategoria específicas. Normalizado: removida marca SKF, padronizado formato do modelo, adicionado 'mm' à dimensão.	2025-08-21 15:43:32.993859	gpt-5-high-reasoning	dc0d0c78-eddd-4bc4-928e-6bc172e43295	4
\.


--
-- Name: duplicate_groups_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.duplicate_groups_group_id_seq', 1, false);


--
-- Name: hash_key_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.hash_key_log_id_seq', 5, true);


--
-- Name: mro_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mro_products_id_seq', 389, true);


--
-- Name: normalization_cache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.normalization_cache_id_seq', 1, false);


--
-- Name: normalization_dictionary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.normalization_dictionary_id_seq', 1, false);


--
-- Name: products_enhanced_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_enhanced_id_seq', 5, true);


--
-- Name: duplicate_dictionary duplicate_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_dictionary
    ADD CONSTRAINT duplicate_dictionary_pkey PRIMARY KEY (hash_key);


--
-- Name: duplicate_groups duplicate_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_groups
    ADD CONSTRAINT duplicate_groups_pkey PRIMARY KEY (group_id);


--
-- Name: hash_key_log hash_key_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hash_key_log
    ADD CONSTRAINT hash_key_log_pkey PRIMARY KEY (id);


--
-- Name: mro_products mro_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mro_products
    ADD CONSTRAINT mro_products_pkey PRIMARY KEY (id);


--
-- Name: normalization_cache normalization_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.normalization_cache
    ADD CONSTRAINT normalization_cache_pkey PRIMARY KEY (id);


--
-- Name: normalization_cache normalization_cache_subcategory_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.normalization_cache
    ADD CONSTRAINT normalization_cache_subcategory_code_key UNIQUE (subcategory_code);


--
-- Name: normalization_dictionary normalization_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.normalization_dictionary
    ADD CONSTRAINT normalization_dictionary_pkey PRIMARY KEY (id);


--
-- Name: normalization_dictionary normalization_dictionary_subcategory_code_original_pattern_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.normalization_dictionary
    ADD CONSTRAINT normalization_dictionary_subcategory_code_original_pattern_key UNIQUE (subcategory_code, original_pattern);


--
-- Name: processing_stats processing_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processing_stats
    ADD CONSTRAINT processing_stats_pkey PRIMARY KEY (batch_id);


--
-- Name: products_enhanced products_enhanced_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_enhanced
    ADD CONSTRAINT products_enhanced_pkey PRIMARY KEY (id);


--
-- Name: idx_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_batch_id ON public.mro_products USING btree (batch_id);


--
-- Name: idx_dict_pattern; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dict_pattern ON public.normalization_dictionary USING btree (original_pattern);


--
-- Name: idx_dict_subcategory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dict_subcategory ON public.normalization_dictionary USING btree (subcategory_code);


--
-- Name: idx_duplicate_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_duplicate_group ON public.duplicate_dictionary USING btree (duplicate_group_id);


--
-- Name: idx_key_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_key_type ON public.duplicate_dictionary USING btree (key_type);


--
-- Name: idx_new_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_new_category ON public.mro_products USING btree (new_category_code);


--
-- Name: idx_new_subcategory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_new_subcategory ON public.mro_products USING btree (new_subcategory_code);


--
-- Name: idx_processing_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_processing_status ON public.mro_products USING btree (processing_status);


--
-- Name: idx_product_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_name ON public.mro_products USING btree (product_name);


--
-- Name: duplicate_dictionary duplicate_dictionary_master_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_dictionary
    ADD CONSTRAINT duplicate_dictionary_master_product_id_fkey FOREIGN KEY (master_product_id) REFERENCES public.products_enhanced(id);


--
-- Name: duplicate_groups duplicate_groups_master_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_groups
    ADD CONSTRAINT duplicate_groups_master_product_id_fkey FOREIGN KEY (master_product_id) REFERENCES public.products_enhanced(id);


--
-- Name: hash_key_log hash_key_log_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hash_key_log
    ADD CONSTRAINT hash_key_log_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products_enhanced(id);


--
-- PostgreSQL database dump complete
--

\unrestrict xhsuYSn2tDlrzy3bXrv9bI8CkGqMdZEVlriEcXW8yRQybRwolSwxo60Sc4du0sa

