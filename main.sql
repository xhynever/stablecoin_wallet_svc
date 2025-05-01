/*
 Navicat Premium Dump SQL

 Source Server         : stablecoin_local
 Source Server Type    : SQLite
 Source Server Version : 3045000 (3.45.0)
 Source Schema         : main

 Target Server Type    : SQLite
 Target Server Version : 3045000 (3.45.0)
 File Encoding         : 65001

 Date: 24/04/2025 14:10:31
*/

PRAGMA foreign_keys = false;

-- ----------------------------
-- Table structure for balances
-- ----------------------------
DROP TABLE IF EXISTS "balances";
CREATE TABLE balances (
        wallet_id TEXT NOT NULL,
        currency TEXT NOT NULL,
        amount REAL DEFAULT 0.0,
        available REAL DEFAULT 0.0,
        pending REAL DEFAULT 0.0,
        user_id TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (wallet_id, currency),
        FOREIGN KEY (wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
    );

-- ----------------------------
-- Table structure for balances_backup
-- ----------------------------
DROP TABLE IF EXISTS "balances_backup";
CREATE TABLE balances_backup(
  wallet_id TEXT,
  currency TEXT,
  amount REAL,
  available REAL,
  pending REAL,
  user_id TEXT,
  created_at NUM,
  updated_at NUM
);

-- ----------------------------
-- Table structure for migrations
-- ----------------------------
DROP TABLE IF EXISTS "migrations";
CREATE TABLE migrations (
            version INTEGER PRIMARY KEY,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            description TEXT
        );

-- ----------------------------
-- Table structure for minter_tokens
-- ----------------------------
DROP TABLE IF EXISTS "minter_tokens";
CREATE TABLE minter_tokens (
        id TEXT PRIMARY KEY,
        minter_id TEXT,
        token_address TEXT,
        chain_name TEXT,
        created_at TIMESTAMP,
        updated_at TIMESTAMP, wallet_id TEXT, token_name TEXT,
                   
        FOREIGN KEY (minter_id) REFERENCES minters(id)
    );

-- ----------------------------
-- Table structure for minters
-- ----------------------------
DROP TABLE IF EXISTS "minters";
CREATE TABLE minters (
    id TEXT PRIMARY KEY,
    organization_id TEXT NOT NULL UNIQUE,
    
    -- Core business fields
    supported_currencies TEXT NOT NULL,      -- JSON array ["USDC", "EUROC", "GBPT"]
    supported_countries TEXT NOT NULL,       -- JSON array ["US", "EU", "GB"]
    fees TEXT NOT NULL,                      -- JSON object for fee structure
    limits TEXT NOT NULL,                    -- JSON object for transaction limits
    status TEXT NOT NULL,                    -- "active", "inactive", "pending", "suspended"
    
    -- API integration fields
    api_type TEXT,                          -- "direct", "webhook", "manual"
    api_base_url TEXT,                      -- Base URL for API calls
    api_version TEXT,                       -- API version
    api_endpoints TEXT,                     -- JSON object with endpoint mappings
    api_authentication TEXT,                -- JSON object with auth details
    api_keys TEXT,                          -- Encrypted API keys (if applicable)
    api_status TEXT DEFAULT "inactive",     -- "active", "inactive", "testing"
    webhook_url TEXT,                       -- Callback URL for webhooks
    webhook_secret TEXT,                    -- Secret for verifying webhooks
    
    -- Additional fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Operational fields
    last_health_check TIMESTAMP,
    health_status TEXT DEFAULT "unknown", minter_name text, settlement_bank_name TEXT, settlement_account_number TEXT, settlement_routing_number TEXT, settlement_currency TEXT, settlement_method TEXT, contact_name TEXT, contact_email TEXT, contact_phone TEXT,    -- "healthy", "degraded", "down", "unknown"
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id)
);

-- ----------------------------
-- Table structure for minting_bank_deposits
-- ----------------------------
DROP TABLE IF EXISTS "minting_bank_deposits";
CREATE TABLE minting_bank_deposits (
        id TEXT PRIMARY KEY,
        minter_id TEXT,
        mint_history_id TEXT,
        bank_tx_number TEXT,
        created_at TIMESTAMP,
        updated_at TIMESTAMP,
        FOREIGN KEY (minter_id) REFERENCES minters(id),
        FOREIGN KEY (mint_history_id) REFERENCES minting_history(id)
    );

-- ----------------------------
-- Table structure for minting_history
-- ----------------------------
DROP TABLE IF EXISTS "minting_history";
CREATE TABLE minting_history (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        status TEXT NOT NULL,
        minter_id TEXT NOT NULL,
        minter_name TEXT NOT NULL,
        amount TEXT NOT NULL,
        currency TEXT NOT NULL,
        transaction_hash TEXT,
        fees TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL,
        completed_at TIMESTAMP,
        destination_wallet_id TEXT,
        destination_network TEXT,
        destination_address TEXT,
        source_wallet_id TEXT,
        source_network TEXT,
        source_address TEXT, token_address TEXT NOT NULL DEFAULT '', updated_at timestamp, creator_organization_id TEXT NOT NULL DEFAULT '', creator_organization_name TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (user_id) REFERENCES users (id)
    );

-- ----------------------------
-- Table structure for organization_banks
-- ----------------------------
DROP TABLE IF EXISTS "organization_banks";
CREATE TABLE organization_banks (
        id TEXT PRIMARY KEY,
        organization_id TEXT,
        settlement_bank_name TEXT,
        settlement_account_number TEXT,
        settlement_routing_number TEXT, created_at timestamp, updated_at timestamp,
        FOREIGN KEY (organization_id) REFERENCES organizations(id)
    );

-- ----------------------------
-- Table structure for organizations
-- ----------------------------
DROP TABLE IF EXISTS "organizations";
CREATE TABLE organizations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    website TEXT,
    registration_number TEXT,
    tax_id TEXT,
    industry TEXT,
    country TEXT,
    address TEXT,
    is_verified BOOLEAN DEFAULT 0,
    verification_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------
-- Table structure for otc_quotes
-- ----------------------------
DROP TABLE IF EXISTS "otc_quotes";
CREATE TABLE otc_quotes (
            id TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            source_currency TEXT NOT NULL,
            destination_currency TEXT NOT NULL,
            amount TEXT NOT NULL,
            side TEXT NOT NULL,
            rate TEXT NOT NULL,
            counter_amount TEXT NOT NULL,
            fee TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            client_reference_id TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL,
            source_network TEXT,
            target_network TEXT,
            price_type TEXT,
            provider_id TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
        );

-- ----------------------------
-- Table structure for recipients
-- ----------------------------
DROP TABLE IF EXISTS "recipients";
CREATE TABLE recipients (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        blockchain TEXT NOT NULL,
        network TEXT NOT NULL,
        address TEXT NOT NULL,
        status TEXT NOT NULL,
        reference TEXT,
        risk_score TEXT DEFAULT '0',
        last_transfer TEXT,
        transfer_count INTEGER DEFAULT 0,
        is_contract BOOLEAN DEFAULT FALSE,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );

-- ----------------------------
-- Table structure for sqlite_sequence
-- ----------------------------
DROP TABLE IF EXISTS "sqlite_sequence";
CREATE TABLE sqlite_sequence(name,seq);

-- ----------------------------
-- Table structure for transfers
-- ----------------------------
DROP TABLE IF EXISTS "transfers";
CREATE TABLE transfers (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        recipient_id TEXT NOT NULL,
        amount TEXT NOT NULL,
        source_currency TEXT NOT NULL,
        destination_currency TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        source_wallet_id TEXT NOT NULL,
        reference TEXT, source_network TEXT, destination_network TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );

-- ----------------------------
-- Table structure for user_profiles
-- ----------------------------
DROP TABLE IF EXISTS "user_profiles";
CREATE TABLE user_profiles (
        user_id TEXT PRIMARY KEY,
        first_name TEXT,
        last_name TEXT,
        phone TEXT,
        country TEXT,
        date_of_birth TEXT,
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS "users";
CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        kyc_status TEXT DEFAULT 'verified'
    , "role" TEXT DEFAULT ('user') NOT NULL, organization_id string, external_reference TEXT, status TEXT, kyc_verified_at TIMESTAMP, notification_email BOOLEAN DEFAULT TRUE, notification_sms BOOLEAN DEFAULT FALSE, created_at TIMESTAMP, updated_at TIMESTAMP);

-- ----------------------------
-- Table structure for wallets
-- ----------------------------
DROP TABLE IF EXISTS "wallets";
CREATE TABLE wallets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            blockchain TEXT NOT NULL,
            address TEXT NOT NULL,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL,
            details TEXT, organization_id text,
            FOREIGN KEY (user_id) REFERENCES users (id)
        );

-- ----------------------------
-- Auto increment value for users
-- ----------------------------
UPDATE "main"."sqlite_sequence" SET seq = 5 WHERE name = 'users';

-- ----------------------------
-- Auto increment value for wallets
-- ----------------------------
UPDATE "main"."sqlite_sequence" SET seq = 19 WHERE name = 'wallets';

PRAGMA foreign_keys = true;
