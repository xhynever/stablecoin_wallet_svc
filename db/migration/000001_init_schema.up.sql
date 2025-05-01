-- 000001_init_schema.up.sql

-- Table structure for users
CREATE TABLE "users" (
  "id" bigserial PRIMARY KEY,
  "email" varchar UNIQUE NOT NULL,
  "password" varchar NOT NULL,
  "kyc_status" varchar DEFAULT 'verified',
  "role" varchar DEFAULT 'user' NOT NULL,
  "organization_id" varchar,
  "external_reference" varchar,
  "status" varchar,
  "kyc_verified_at" timestamptz,
  "notification_email" boolean DEFAULT TRUE,
  "notification_sms" boolean DEFAULT FALSE,
  "created_at" timestamptz DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now())
);

-- Table structure for organizations
CREATE TABLE "organizations" (
  "id" varchar PRIMARY KEY,
  "name" varchar NOT NULL,
  "description" varchar,
  "logo_url" varchar,
  "website" varchar,
  "registration_number" varchar,
  "tax_id" varchar,
  "industry" varchar,
  "country" varchar,
  "address" varchar,
  "is_verified" boolean DEFAULT FALSE,
  "verification_date" timestamptz,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

-- Table structure for wallets
CREATE TABLE "wallets" (
  "id" bigserial PRIMARY KEY,
  "user_id" bigint NOT NULL,
  "blockchain" varchar NOT NULL,
  "address" varchar NOT NULL,
  "status" varchar DEFAULT 'active',
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "details" varchar,
  "organization_id" varchar,
  FOREIGN KEY ("user_id") REFERENCES "users" ("id"),
  FOREIGN KEY ("organization_id") REFERENCES "organizations" ("id")
);

-- Table structure for balances
CREATE TABLE "balances" (
  "wallet_id" bigint NOT NULL,
  "currency" varchar NOT NULL,
  "amount" decimal DEFAULT 0.0,
  "available" decimal DEFAULT 0.0,
  "pending" decimal DEFAULT 0.0,
  "user_id" bigint NOT NULL,
  "created_at" timestamptz DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now()),
  PRIMARY KEY ("wallet_id", "currency"),
  FOREIGN KEY ("wallet_id") REFERENCES "wallets" ("id"),
  FOREIGN KEY ("user_id") REFERENCES "users" ("id")
);

-- Table structure for minters
CREATE TABLE "minters" (
  "id" varchar PRIMARY KEY,
  "organization_id" varchar NOT NULL UNIQUE,
  "supported_currencies" jsonb NOT NULL,
  "supported_countries" jsonb NOT NULL,
  "fees" jsonb NOT NULL,
  "limits" jsonb NOT NULL,
  "status" varchar NOT NULL,
  "api_type" varchar,
  "api_base_url" varchar,
  "api_version" varchar,
  "api_endpoints" jsonb,
  "api_authentication" jsonb,
  "api_keys" varchar,
  "api_status" varchar DEFAULT 'inactive',
  "webhook_url" varchar,
  "webhook_secret" varchar,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "last_health_check" timestamptz,
  "health_status" varchar DEFAULT 'unknown',
  "minter_name" varchar,
  "settlement_bank_name" varchar,
  "settlement_account_number" varchar,
  "settlement_routing_number" varchar,
  "settlement_currency" varchar,
  "settlement_method" varchar,
  "contact_name" varchar,
  "contact_email" varchar,
  "contact_phone" varchar,
  FOREIGN KEY ("organization_id") REFERENCES "organizations" ("id")
);

-- Table structure for minter_tokens
CREATE TABLE "minter_tokens" (
  "id" varchar PRIMARY KEY,
  "minter_id" varchar,
  "token_address" varchar,
  "chain_name" varchar,
  "created_at" timestamptz DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now()),
  "wallet_id" bigint,
  "token_name" varchar,
  FOREIGN KEY ("minter_id") REFERENCES "minters" ("id"),
  FOREIGN KEY ("wallet_id") REFERENCES "wallets" ("id")
);

-- Table structure for minting_history
CREATE TABLE "minting_history" (
  "id" varchar PRIMARY KEY,
  "type" varchar NOT NULL,
  "user_id" bigint NOT NULL,
  "status" varchar NOT NULL,
  "minter_id" varchar NOT NULL,
  "minter_name" varchar NOT NULL,
  "amount" varchar NOT NULL,
  "currency" varchar NOT NULL,
  "transaction_hash" varchar,
  "fees" varchar NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "completed_at" timestamptz,
  "destination_wallet_id" bigint,
  "destination_network" varchar,
  "destination_address" varchar,
  "source_wallet_id" bigint,
  "source_network" varchar,
  "source_address" varchar,
  "token_address" varchar NOT NULL DEFAULT '',
  "updated_at" timestamptz DEFAULT (now()),
  "creator_organization_id" varchar NOT NULL DEFAULT '',
  "creator_organization_name" varchar NOT NULL DEFAULT '',
  FOREIGN KEY ("user_id") REFERENCES "users" ("id"),
  FOREIGN KEY ("minter_id") REFERENCES "minters" ("id"),
  FOREIGN KEY ("source_wallet_id") REFERENCES "wallets" ("id"),
  FOREIGN KEY ("destination_wallet_id") REFERENCES "wallets" ("id")
);

-- Table structure for minting_bank_deposits
CREATE TABLE "minting_bank_deposits" (
  "id" varchar PRIMARY KEY,
  "minter_id" varchar,
  "mint_history_id" varchar,
  "bank_tx_number" varchar,
  "created_at" timestamptz DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now()),
  FOREIGN KEY ("minter_id") REFERENCES "minters" ("id"),
  FOREIGN KEY ("mint_history_id") REFERENCES "minting_history" ("id")
);

-- Table structure for organization_banks
CREATE TABLE "organization_banks" (
  "id" varchar PRIMARY KEY,
  "organization_id" varchar,
  "settlement_bank_name" varchar,
  "settlement_account_number" varchar,
  "settlement_routing_number" varchar,
  "created_at" timestamptz DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now()),
  FOREIGN KEY ("organization_id") REFERENCES "organizations" ("id")
);

-- Table structure for transfers
CREATE TABLE "transfers" (
  "id" varchar PRIMARY KEY,
  "user_id" bigint NOT NULL,
  "recipient_id" varchar NOT NULL,
  "amount" varchar NOT NULL,
  "source_currency" varchar NOT NULL,
  "destination_currency" varchar NOT NULL,
  "status" varchar NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "source_wallet_id" bigint NOT NULL,
  "reference" varchar,
  "source_network" varchar,
  "destination_network" varchar,
  FOREIGN KEY ("user_id") REFERENCES "users" ("id"),
  FOREIGN KEY ("source_wallet_id") REFERENCES "wallets" ("id")
);

-- Table structure for recipients
CREATE TABLE "recipients" (
  "id" varchar PRIMARY KEY,
  "user_id" bigint NOT NULL,
  "name" varchar NOT NULL,
  "blockchain" varchar NOT NULL,
  "network" varchar NOT NULL,
  "address" varchar NOT NULL,
  "status" varchar NOT NULL,
  "reference" varchar,
  "risk_score" varchar DEFAULT '0',
  "last_transfer" varchar,
  "transfer_count" integer DEFAULT 0,
  "is_contract" boolean DEFAULT FALSE,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now()),
  FOREIGN KEY ("user_id") REFERENCES "users" ("id")
);

-- Table structure for otc_quotes
CREATE TABLE "otc_quotes" (
  "id" varchar PRIMARY KEY,
  "user_id" bigint NOT NULL,
  "source_currency" varchar NOT NULL,
  "destination_currency" varchar NOT NULL,
  "amount" varchar NOT NULL,
  "side" varchar NOT NULL,
  "rate" varchar NOT NULL,
  "counter_amount" varchar NOT NULL,
  "fee" varchar NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "client_reference_id" varchar,
  "status" varchar DEFAULT 'active',
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "source_network" varchar,
  "target_network" varchar,
  "price_type" varchar,
  "provider_id" varchar,
  FOREIGN KEY ("user_id") REFERENCES "users" ("id")
);

-- Table structure for user_profiles
CREATE TABLE "user_profiles" (
  "user_id" bigint PRIMARY KEY,
  "first_name" varchar,
  "last_name" varchar,
  "phone" varchar,
  "country" varchar,
  "date_of_birth" varchar,
  "address" varchar,
  "created_at" timestamptz DEFAULT (now()),
  "updated_at" timestamptz DEFAULT (now()),
  FOREIGN KEY ("user_id") REFERENCES "users" ("id")
);

-- Table structure for migrations
CREATE TABLE "migrations" (
  "version" integer PRIMARY KEY,
  "applied_at" timestamptz DEFAULT (now()),
  "description" varchar
);

-- Create indexes
CREATE INDEX ON "wallets" ("user_id");
CREATE INDEX ON "wallets" ("organization_id");
CREATE INDEX ON "transfers" ("user_id");
CREATE INDEX ON "transfers" ("source_wallet_id");
CREATE INDEX ON "minting_history" ("user_id");
CREATE INDEX ON "minting_history" ("minter_id");
CREATE INDEX ON "minter_tokens" ("minter_id");
CREATE INDEX ON "minter_tokens" ("wallet_id");
CREATE INDEX ON "recipients" ("user_id");
