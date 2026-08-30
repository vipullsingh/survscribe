-- SurvScribe migration 000002 (up) -- enum_types
-- All PostgreSQL ENUM types (Part A section 4, Part B section 19).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

CREATE TYPE firm_type          AS ENUM ('SOLE_PROPRIETORSHIP','PARTNERSHIP','LLP','PRIVATE_LIMITED','OTHER');
CREATE TYPE store_status       AS ENUM ('ACTIVE','SUSPENDED');

CREATE TYPE user_status        AS ENUM ('PENDING_VERIFICATION','ACTIVE','SUSPENDED','DEACTIVATED');
CREATE TYPE sla_category       AS ENUM ('Fellow','Associate','Licentiate','Trainee');
CREATE TYPE role_scope         AS ENUM ('SURVEYOR','REVIEWER','ADMIN','INSURER_VIEWER');
CREATE TYPE signup_source      AS ENUM ('SELF_SIGNUP','INVITE');
CREATE TYPE logout_reason      AS ENUM ('USER_INITIATED','TOKEN_EXPIRED','REVOKED_BY_ADMIN',
                                        'OFFLINE_GRACE_EXPIRED','PASSWORD_CHANGED','DEVICE_WIPE',
                                        'ALL_SESSIONS_REVOKED');

CREATE TYPE device_platform    AS ENUM ('IOS','ANDROID','WEB');
CREATE TYPE session_status     AS ENUM ('ACTIVE','LOGGED_OUT','EXPIRED','REVOKED','SUPERSEDED');

CREATE TYPE auth_outcome       AS ENUM ('SUCCESS','FAILURE');
CREATE TYPE auth_method        AS ENUM ('PASSWORD','PHONE_OTP','EMAIL_OTP','REFRESH_TOKEN','OFFLINE_TOKEN');
CREATE TYPE auth_event_type    AS ENUM (
    'SIGNUP','LOGIN_SUCCESS','LOGIN_FAILED',
    'OTP_REQUESTED','OTP_VERIFIED','OTP_FAILED',
    'TOKEN_REFRESHED','TOKEN_REUSE_DETECTED',
    'LOGOUT','LOGOUT_ALL','SESSION_REVOKED',
    'PASSWORD_CHANGED','PASSWORD_RESET_REQUESTED','PASSWORD_RESET_COMPLETED',
    'ACCOUNT_LOCKED','ACCOUNT_UNLOCKED',
    'ROLE_GRANTED','ROLE_REVOKED',
    'INVITE_SENT','INVITE_ACCEPTED',
    'OFFLINE_UNLOCK','OFFLINE_GRACE_EXPIRED');

CREATE TYPE invite_status      AS ENUM ('PENDING','ACCEPTED','EXPIRED','REVOKED');
CREATE TYPE otp_channel        AS ENUM ('SMS','EMAIL');
CREATE TYPE otp_purpose        AS ENUM ('LOGIN','SIGNUP_VERIFY','PASSWORD_RESET');
CREATE TYPE grant_scope        AS ENUM ('READ_ONLY');

---- Claim lifecycle ---------------------------------------------------------
-- 01_dashboard.md §6 (STATUS_DRAFT_OFFLINE), FR-1.3, 16_internal_review_submission.md §7
CREATE TYPE claim_status        AS ENUM ('DRAFT_OFFLINE','ACTIVE','ON_HOLD',
                                         'COMPLETED_SUBMITTED','CANCELLED');

---- Peril master (FR-2.1 policy classes, FR-1.2 reported nature of loss,
---- 06_cause_investigation.md §3 ReportedCauseSelect) -----------------------
CREATE TYPE peril_type          AS ENUM ('FIRE','LIGHTNING','EXPLOSION_IMPLOSION',
                                         'FLOOD_INUNDATION','STORM_CYCLONE','EARTHQUAKE',
                                         'BURGLARY_THEFT','RIOT_STRIKE_MALICIOUS_DAMAGE',
                                         'IMPACT_DAMAGE','MACHINERY_BREAKDOWN',
                                         'ELECTRONIC_EQUIPMENT_FAILURE','BURST_PIPE',
                                         'SPONTANEOUS_COMBUSTION','SHORT_CIRCUIT',
                                         'MARINE_TRANSIT','OTHER');

-- FR-2.1 policy type list
CREATE TYPE policy_type         AS ENUM ('STANDARD_FIRE_SPECIAL_PERILS','INDUSTRIAL_ALL_RISKS',
                                         'BURGLARY','MACHINERY_BREAKDOWN','ELECTRONIC_EQUIPMENT',
                                         'MARINE_CARGO','OTHER');

---- Asset heads ------------------------------------------------------------
-- FR-11.1 five heads. Also used by damage_items so Stage 6 maps 1:1 to Stage 11
-- (Stage 15 gate 6 cross-checks the two). See §38 item 4 re FR-6.1 "Electrical".
CREATE TYPE head_category       AS ENUM ('BUILDING_CIVIL','PLANT_MACHINERY',
                                         'FURNITURE_FIXTURES_FITTINGS','STOCKS',
                                         'OTHER_INSURED_PROPERTY');

-- FR-2.1 section-wise sums insured (finer than head_category; rolls up to it)
CREATE TYPE policy_section_head AS ENUM ('BUILDING','PLANT_MACHINERY','FURNITURE_FIXTURES',
                                         'RAW_MATERIALS','WORK_IN_PROGRESS','FINISHED_GOODS',
                                         'STOCK_IN_OPEN','OTHER');

---- Stage 3 ----------------------------------------------------------------
-- FR-3.1 contact attempt logs; SRS entity 16 outcome enum
CREATE TYPE contact_outcome     AS ENUM ('CONNECTED','NO_ANSWER','BUSY','UNREACHABLE',
                                         'WRONG_NUMBER','SITE_VISIT_CONFIRMED',
                                         'RESCHEDULE_REQUESTED','REFUSED');

-- FR-3.3 / FR-8.1 dispatch media; 16_internal_review_submission.md §4 submission_channel
CREATE TYPE dispatch_channel    AS ENUM ('WHATSAPP','EMAIL','SMS','PHONE','IN_PERSON',
                                         'COURIER','INSURER_PORTAL');
CREATE TYPE dispatch_status     AS ENUM ('PENDING','QUEUED','SENT','DELIVERED','FAILED');

---- Stage 4 / Stage 9 ------------------------------------------------------
CREATE TYPE visit_type          AS ENUM ('INITIAL','FOLLOW_UP');   -- Q2a, §17.1
-- FR-9.1 examples: dismantling, post-repair verification, salvage lifting
CREATE TYPE visit_purpose       AS ENUM ('INITIAL_SURVEY','DISMANTLING_INTERNAL_INSPECTION',
                                         'POST_REPAIR_VERIFICATION','SALVAGE_LIFTING',
                                         'STOCK_RECONCILIATION','JOINT_SURVEY',
                                         'DOCUMENT_COLLECTION','OTHER');

---- Stage 5 ----------------------------------------------------------------
-- 06_cause_investigation.md §3 EventTypeSelect — six values, verbatim
CREATE TYPE chronology_event_type AS ENUM ('PRE_INCIDENT_ACTIVITY','LOSS_OCCURRENCE',
                                           'LOSS_DISCOVERY','EMERGENCY_RESPONSE',
                                           'EXTINGUISHMENT_CONTAINMENT','POST_LOSS_ACTION');

---- Stage 6 ----------------------------------------------------------------
-- 07_damage_inspection_studio.md §4 damage_severity
CREATE TYPE damage_severity     AS ENUM ('TOTAL_LOSS','SEVERE','MODERATE','MINOR');
-- 07_damage_inspection_studio.md §4 recommendation
CREATE TYPE damage_recommendation AS ENUM ('REPAIRABLE','REPLACE','SALVAGE');
-- 07_damage_inspection_studio.md §4 "Nos, Kgs, Ltrs, Meters, SqFt, etc." — closed here
CREATE TYPE uom                 AS ENUM ('NOS','KGS','MT','LTRS','METERS','SQFT','SQM',
                                         'SETS','PAIRS','ROLLS','BAGS','LOT');

CREATE TYPE media_type          AS ENUM ('PHOTO','VIDEO','AUDIO');
-- FR-6.2 six mandatory categories, in spec order
CREATE TYPE photo_category      AS ENUM ('PANORAMIC_SITE_VIEW','AFFECTED_SECTION',
                                         'DAMAGED_ASSET','SERIAL_NAMEPLATE',
                                         'CLOSEUP_DAMAGE_DETAIL','ORIGIN_POINT');

---- Stage 7 / Stage 10 -----------------------------------------------------
-- FR-7.1, FR-10.1, FR-5.2 statutory evidence, plus generated notices
CREATE TYPE document_type       AS ENUM (
    'APPOINTMENT_LETTER','POLICY_SCHEDULE','CLAIM_INTIMATION',
    'PURCHASE_INVOICE','BILL_OF_ENTRY','DELIVERY_CHALLAN',
    'FIXED_ASSET_REGISTER','STOCK_LEDGER','STOCK_STATEMENT','PRODUCTION_LOG',
    'GST_RETURN','AUDITED_BALANCE_SHEET','HYPOTHECATION_LEASE_MORTGAGE',
    'FIR_POLICE_DIARY','FIRE_BRIGADE_REPORT','WEATHER_IMD_REPORT',
    'FACTORY_LOGBOOK','CCTV_NOTE','WITNESS_STATEMENT','FORENSIC_ENGINEER_REPORT',
    'CLAIM_BILL','REPAIR_ESTIMATE','OEM_QUOTATION','SALVAGE_OFFER',
    'SALVAGE_SALE_INVOICE','PAYMENT_PROOF',
    'PRESERVATION_NOTICE','REQUISITION_NOTICE','PSR_DOCX','FSR_DOCX',
    'SURVEYOR_SIGNATURE','OTHER');

CREATE TYPE ocr_status          AS ENUM ('NOT_APPLICABLE','PENDING','PROCESSING',
                                         'COMPLETED','FAILED');

-- D34 / 08_ownership_document_locker.md §4 — Title Case, rendered into the FSR
CREATE TYPE insurable_interest_status AS ENUM ('Established','Under Verification',
                                               'Incomplete Documentation','Disputed');

-- 11_document_verification_audit.md §4 audit_status; FR-10.2 flag vocabulary
CREATE TYPE audit_status        AS ENUM ('VERIFIED','RATE_INFLATED','DUPLICATE',
                                         'NOT_DAMAGED_IN_INCIDENT','OBSOLETE_ITEM',
                                         'BETTERMENT','PARTIALLY_ALLOWED','DISALLOWED',
                                         'PENDING_REVIEW');

---- Discrepancy flags (ADDITION — §16) -------------------------------------
CREATE TYPE discrepancy_code    AS ENUM (
    'LOCATION_DISCREPANCY_DETECTED',            -- FR-4.3
    'CHRONOLOGY_GAP_DETECTED',                  -- FR-5.3 / AC 5.1.3 (> 2 h)
    'DUPLICATE_CLAIM_ITEM',                     -- FR-10.2 / AC 10.1.x
    'RATE_INFLATION_DETECTED',                  -- FR-10.2 / AC 10.1.x (> 20 %)
    'ITEM_NOT_IN_DAMAGE_REGISTER',              -- FR-10.2
    'OBSOLETE_ITEM_CLAIMED',                    -- FR-10.2
    'BETTERMENT_DETECTED',                      -- FR-10.2
    'UNDERINSURANCE_DETECTED',                  -- FR-11.2 step 6
    'REPAIRABLE_VS_TOTAL_LOSS_CONTRADICTION',   -- FR-15.1 gate 6
    'METADATA_MISMATCH',                        -- FR-15.1 gate 2
    'ARITHMETIC_MISMATCH',                      -- FR-15.1 gate 1
    'MISSING_DEDUCTION_REMARK',                 -- FR-15.1 gate 3
    'PHOTO_ANNEXURE_INCOMPLETE',                -- FR-15.1 gate 4
    'MANDATORY_DOCUMENT_MISSING',               -- FR-15.1 gate 5
    'NARRATIVE_CONTRADICTION');                 -- FR-15.1 gate 6

-- Design System §12.3: green = verified, amber = warning, red = critical blocker. Nothing else.
CREATE TYPE discrepancy_severity AS ENUM ('INFO','WARNING','CRITICAL');
CREATE TYPE discrepancy_status   AS ENUM ('OPEN','RESOLVED','ACCEPTED','DISMISSED');
CREATE TYPE detected_by          AS ENUM ('SYSTEM_RULE','AI_ASSISTANT','SURVEYOR');

---- Stage 12 ---------------------------------------------------------------
-- FR-12.2 Modes A / B / C
CREATE TYPE disposal_mode       AS ENUM ('RETAINED_BY_INSURED','SOLD_TO_SCRAP_BUYER',
                                         'INSURER_TENDER');

---- Stage 13 ---------------------------------------------------------------
-- 14_coverage_liability_opinion.md §4 — Title Case, rendered into FSR Section I
CREATE TYPE peril_admissibility AS ENUM ('Admissible','Inadmissible','Disputed');
CREATE TYPE warranty_compliance_status AS ENUM ('All Complied','Material Breach');
-- FR-13.2 verbatim, four values
CREATE TYPE surveyor_recommendation AS ENUM (
    'Admissible as Assessed',
    'Subject to Insurer Liability Determination',
    'Non-Admissible',
    'Repudiation Recommended');

---- Stages 8 / 14 / 15 -----------------------------------------------------
CREATE TYPE report_status       AS ENUM ('DRAFT','AI_DRAFTED','UNDER_REVIEW','APPROVED',
                                         'GENERATED','SUBMITTED','SUPERSEDED');
-- FR-15.1 seven gates, in spec order (D36)
CREATE TYPE audit_gate_code     AS ENUM ('ARITHMETIC_CHECK','METADATA_CONSISTENCY',
                                         'DEDUCTION_REMARKS','PHOTO_ANNEXURE_COMPLIANCE',
                                         'DOCUMENT_COMPLETENESS','CONTRADICTION_SCANNER',
                                         'HUMAN_APPROVAL_AI_GATE');
CREATE TYPE audit_gate_result   AS ENUM ('PASS','FAIL','NOT_RUN');

---- Cross-cutting ----------------------------------------------------------
-- SRS entity 14 audit_log action; §5.1 governance rule 3 requires VIEW and DOWNLOAD
CREATE TYPE audit_action        AS ENUM ('CREATE','UPDATE','DELETE','VIEW','DOWNLOAD',
                                         'EXPORT','APPROVE','SUBMIT','SIGN_OFF','RESTORE');

-- SRS entity 15 sync_queue
CREATE TYPE sync_operation      AS ENUM ('CREATE','UPDATE','DELETE');
CREATE TYPE sync_status         AS ENUM ('PENDING','IN_FLIGHT','SYNCED','CONFLICT',
                                         'FAILED','ABANDONED');
