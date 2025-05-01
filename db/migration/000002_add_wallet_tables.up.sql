-- Add wallet_providers table
CREATE TABLE IF NOT EXISTS "wallet_providers" (
  "id" varchar PRIMARY KEY,
  "name" varchar NOT NULL,
  "provider_type" varchar NOT NULL,
  "credentials" jsonb NOT NULL,
  "status" varchar NOT NULL DEFAULT 'active',
  "created_at" timestamptz DEFAULT now(),
  "updated_at" timestamptz DEFAULT now()
);

-- Add constraints to wallet_providers
ALTER TABLE "wallet_providers" ADD CONSTRAINT "wallet_providers_provider_type_check" 
  CHECK (provider_type IN ('fireblocks','hex_trust','self_custody'));

ALTER TABLE "wallet_providers" ADD CONSTRAINT "wallet_providers_status_check" 
  CHECK (status IN ('active','inactive'));

-- Add required columns to existing wallets table
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "organization_id" varchar REFERENCES "organizations"("id");
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "provider_type" varchar NOT NULL DEFAULT 'metamask';
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "wallet_provider" varchar REFERENCES "wallet_providers"("id");
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "network" varchar NOT NULL DEFAULT 'mainnet';
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "default_wallet" boolean NOT NULL DEFAULT FALSE;
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "description" varchar;
ALTER TABLE "wallets" ADD COLUMN IF NOT EXISTS "updated_at" timestamptz DEFAULT now();

-- Add constraints to wallets table
ALTER TABLE "wallets" DROP CONSTRAINT IF EXISTS "wallets_provider_type_check";
ALTER TABLE "wallets" ADD CONSTRAINT "wallets_provider_type_check" 
  CHECK (provider_type IN ('metamask','fireblocks','hex_trust','self_custody'));

ALTER TABLE "wallets" DROP CONSTRAINT IF EXISTS "wallets_status_check";
ALTER TABLE "wallets" ADD CONSTRAINT "wallets_status_check" 
  CHECK (status IN ('active','pending_configuration','inactive','suspended'));

-- Add unique constraint if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'wallets_blockchain_network_address_key' AND conrelid = 'wallets'::regclass
  ) THEN
    ALTER TABLE "wallets" ADD CONSTRAINT "wallets_blockchain_network_address_key" 
      UNIQUE ("blockchain", "network", "address");
  END IF;
END $$;

-- Create wallet_access_controls table
CREATE TABLE IF NOT EXISTS "wallet_access_controls" (
  "wallet_id" bigint NOT NULL REFERENCES "wallets"("id") ON DELETE CASCADE,
  "user_id" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "access_level" varchar NOT NULL,
  "daily_limit" numeric,
  "approval_required" boolean DEFAULT FALSE,
  "created_at" timestamptz DEFAULT now(),
  "updated_at" timestamptz DEFAULT now(),
  PRIMARY KEY("wallet_id", "user_id")
);

-- Add constraints to wallet_access_controls
ALTER TABLE "wallet_access_controls" ADD CONSTRAINT "wallet_access_controls_access_level_check" 
  CHECK (access_level IN ('owner','admin','operator','viewer'));

-- Create transaction_signatures table
CREATE TABLE IF NOT EXISTS "transaction_signatures" (
  "id" varchar PRIMARY KEY,
  "wallet_id" bigint NOT NULL REFERENCES "wallets"("id") ON DELETE CASCADE,
  "unsigned_tx" jsonb NOT NULL,
  "signed_tx" jsonb,
  "status" varchar NOT NULL,
  "expires_at" timestamptz,
  "created_at" timestamptz DEFAULT now(),
  "updated_at" timestamptz DEFAULT now()
);

-- Add constraints to transaction_signatures
ALTER TABLE "transaction_signatures" ADD CONSTRAINT "transaction_signatures_status_check" 
  CHECK (status IN ('pending_signature','signed','rejected','submitted','failed','confirmed'));

-- Initialize wallet access for existing wallets
INSERT INTO "wallet_access_controls" ("wallet_id", "user_id", "access_level")
SELECT w."id", w."user_id", 'owner'
FROM "wallets" w
LEFT JOIN "wallet_access_controls" wac ON w."id" = wac."wallet_id" AND w."user_id" = wac."user_id"
WHERE wac."wallet_id" IS NULL;
