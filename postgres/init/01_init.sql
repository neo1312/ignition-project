-- PostgreSQL init script for Ignition
-- Runs ONCE on first container start (empty volume)

-- Useful extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------
-- Tag history table (basic historian alternative)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS tag_history (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tag_path    TEXT NOT NULL,
    value       DOUBLE PRECISION,
    quality     INT,
    t_stamp     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tag_history_path_time
    ON tag_history (tag_path, t_stamp DESC);

-- -----------------------------------------------
-- Audit log table (track operator actions)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    actor       TEXT NOT NULL,
    action      TEXT NOT NULL,
    target      TEXT,
    old_value   TEXT,
    new_value   TEXT,
    t_stamp     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------
-- Alarm journal table
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS alarm_journal (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    source      TEXT NOT NULL,
    display_path TEXT,
    event_type  TEXT,
    priority    INT,
    t_stamp     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Confirm init ran
DO $$
BEGIN
    RAISE NOTICE 'Ignition DB init complete: %, %',
        current_database(), now();
END $$;
