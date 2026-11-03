-- Create raw staging schema
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.payment_events (
    raw_id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(32) NOT NULL,
    merchant_id VARCHAR(32) NOT NULL,
    payment_method VARCHAR(32) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create analytical warehouse schema (Star Schema)
CREATE SCHEMA IF NOT EXISTS analytics;

-- Dimension 1: Merchants (Built for Slowly Changing Dimension Type 2)
CREATE TABLE IF NOT EXISTS analytics.dim_merchants (
    merchant_key SERIAL PRIMARY KEY,
    merchant_id VARCHAR(32) NOT NULL,
    merchant_name VARCHAR(100),
    category VARCHAR(50),
    risk_level VARCHAR(10),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

-- Dimension 2: Users
CREATE TABLE IF NOT EXISTS analytics.dim_users (
    user_id VARCHAR(32) PRIMARY KEY,
    user_tier VARCHAR(20),
    country VARCHAR(3),
    signup_date TIMESTAMP
);

-- Central Fact Table
CREATE TABLE IF NOT EXISTS analytics.fact_payment_transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(32) REFERENCES analytics.dim_users(user_id),
    merchant_key INT REFERENCES analytics.dim_merchants(merchant_key),
    payment_method VARCHAR(32) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) NOT NULL,
    transaction_timestamp TIMESTAMP NOT NULL,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index foreign keys for rapid analytical aggregations
CREATE INDEX IF NOT EXISTS idx_fact_merchant_key ON analytics.fact_payment_transactions(merchant_key);
CREATE INDEX IF NOT EXISTS idx_fact_user_id ON analytics.fact_payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_fact_status ON analytics.fact_payment_transactions(status);