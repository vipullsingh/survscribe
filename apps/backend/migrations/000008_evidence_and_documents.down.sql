-- SurvScribe migration 000008 (down) -- evidence_and_documents
-- damage_items, media_attachments, documents, document_damage_links, document_line_items (sections 25-27).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

ALTER TABLE media_attachments DROP CONSTRAINT IF EXISTS fk_media_document;
ALTER TABLE chronology_events DROP CONSTRAINT IF EXISTS fk_chronology_document;
DROP TABLE IF EXISTS document_line_items   CASCADE;
DROP TABLE IF EXISTS document_damage_links CASCADE;
DROP TABLE IF EXISTS documents             CASCADE;
DROP TABLE IF EXISTS media_attachments     CASCADE;
DROP TABLE IF EXISTS damage_items          CASCADE;
