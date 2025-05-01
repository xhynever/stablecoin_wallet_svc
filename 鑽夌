-- First create a function to check if a column exists
CREATE OR REPLACE FUNCTION column_exists(t_name text, c_name text) RETURNS boolean AS $$
DECLARE
    exists boolean;
BEGIN
    SELECT count(*) > 0 INTO exists
    FROM pg_attribute a
    JOIN pg_class t ON a.attrelid = t.oid
    JOIN pg_namespace s ON t.relnamespace = s.oid
    WHERE a.attnum > 0 
      AND NOT a.attisdropped
      AND t.relname = t_name
      AND a.attname = c_name;
    RETURN exists;
END;
$$ LANGUAGE plpgsql;

-- Create organizations table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'organizations') THEN
        CREATE TABLE "organizations" (
            "id" text PRIMARY KEY,
            "name" text NOT NULL,
            "description" text,
            "logo_url" text,
            "website" text,
            "registration_number" text,
            "tax_id" text,
            "industry" text,
            "country" text,
            "address" text,
            "is_verified" boolean NOT NULL DEFAULT false,
            "verification_date" timestamptz,
            "created_at" timestamptz NOT NULL DEFAULT (now()),
            "updated_at" timestamptz NOT NULL DEFAULT (now())
        );
    END IF;
END $$;

-- Create wallet providers table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'wallet_providers') THEN
        CREATE TABLE "wallet_providers" (
            "id" text PRIMARY KEY,
            "name" text NOT NULL,
            "provider_type" text NOT NULL,
            "credentials" jsonb NOT NULL,
            "status" text NOT NULL DEFAULT 'active',
            "created_at" timestamptz NOT NULL DEFAULT (now()),
            "updated_at" timestamptz NOT NULL DEFAULT (now())
        );
        
        -- Add constraints on wallet_providers
        ALTER TABLE "wallet_providers" ADD CONSTRAINT "wallet_providers_provider_type_check" 
            CHECK (provider_type IN ('fireblocks', 'hex_trust', 'self_custody'));

        ALTER TABLE "wallet_providers" ADD CONSTRAINT "wallet_providers_status_check" 
            CHECK (status IN ('active', 'inactive'));
    END IF;
END $$;

-- Handle wallets table - either create or modify it
DO $$ 
BEGIN
    -- Create wallets table if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'wallets') THEN
        CREATE TABLE "wallets" (
            "id" text PRIMARY KEY,
            "organization_id" text,
            "provider_type" text NOT NULL DEFAULT 'metamask',
            "wallet_provider" text,
            "blockchain" text NOT NULL,
            "network" text NOT NULL DEFAULT 'mainnet',
            "address" text NOT NULL,
            "status" text NOT NULL DEFAULT 'pending_configuration',
            "default_wallet" boolean NOT NULL DEFAULT false,
            "description" text,
            "created_at" timestamptz NOT NULL DEFAULT (now()),
            "updated_at" timestamptz NOT NULL DEFAULT (now())
        );
        
        -- Add constraints
        ALTER TABLE "wallets" ADD CONSTRAINT "wallets_provider_type_check" 
            CHECK (provider_type IN ('metamask', 'fireblocks', 'hex_trust', 'self_custody'));

        ALTER TABLE "wallets" ADD CONSTRAINT "wallets_status_check" 
            CHECK (status IN ('active', 'pending_configuration', 'inactive', 'suspended'));

        ALTER TABLE "wallets" ADD CONSTRAINT "wallets_unique_blockchain_network_address" 
            UNIQUE (blockchain, network, address);
            
        -- Add foreign keys
        ALTER TABLE "wallets" ADD FOREIGN KEY ("organization_id") REFERENCES "organizations" ("id");
        ALTER TABLE "wallets" ADD FOREIGN KEY ("wallet_provider") REFERENCES "wallet_providers" ("id");
    ELSE
        -- Wallet table exists, add missing columns if needed
        
        -- Add organization_id if it doesn't exist
        IF NOT column_exists('wallets', 'organization_id') THEN
            ALTER TABLE "wallets" ADD COLUMN "organization_id" text;
            -- Create a default organization if none exists
            IF NOT EXISTS (SELECT FROM organizations LIMIT 1) THEN
                INSERT INTO "organizations" ("id", "name", "description")
                VALUES ('org_default', 'Default Organization', 'Created during migration')
                ON CONFLICT DO NOTHING;
            END IF;
            -- Set default value for organization_id
            UPDATE "wallets" SET "organization_id" = (SELECT id FROM organizations LIMIT 1);
            -- Add foreign key constraint
            ALTER TABLE "wallets" ADD FOREIGN KEY ("organization_id") REFERENCES "organizations" ("id");
        END IF;
        
        -- Add network if it doesn't exist
        IF NOT column_exists('wallets', 'network') THEN
            ALTER TABLE "wallets" ADD COLUMN "network" text NOT NULL DEFAULT 'mainnet';
        END IF;
        
        -- Add wallet_provider if it doesn't exist
        IF NOT column_exists('wallets', 'wallet_provider') THEN
            ALTER TABLE "wallets" ADD COLUMN "wallet_provider" text;
            -- Add foreign key constraint
            ALTER TABLE "wallets" ADD FOREIGN KEY ("wallet_provider") REFERENCES "wallet_providers" ("id");
        END IF;
        
        -- Add default_wallet if it doesn't exist
        IF NOT column_exists('wallets', 'default_wallet') THEN
            ALTER TABLE "wallets" ADD COLUMN "default_wallet" boolean NOT NULL DEFAULT false;
            -- Make the oldest wallet for each user the default
            WITH oldest_wallets AS (
                SELECT DISTINCT ON (user_id) id
                FROM wallets
                ORDER BY user_id, created_at ASC
            )
            UPDATE wallets
            SET default_wallet = true
            WHERE id IN (SELECT id FROM oldest_wallets);
        END IF;
        
        -- Add or update updated_at if it doesn't exist
        IF NOT column_exists('wallets', 'updated_at') THEN
            ALTER TABLE "wallets" ADD COLUMN "updated_at" timestamptz NOT NULL DEFAULT (now());
        ELSE
            -- Ensure updated_at is current for existing records
            UPDATE "wallets" SET "updated_at" = (now()) WHERE "updated_at" IS NULL;
        END IF;
        
        -- Add provider_type if it doesn't exist
        IF NOT column_exists('wallets', 'provider_type') THEN
            ALTER TABLE "wallets" ADD COLUMN "provider_type" text NOT NULL DEFAULT 'metamask';
            -- Add constraint
            ALTER TABLE "wallets" ADD CONSTRAINT "wallets_provider_type_check" 
                CHECK (provider_type IN ('metamask', 'fireblocks', 'hex_trust', 'self_custody'));
        END IF;
        
        -- Add status constraint if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'wallets_status_check' AND conrelid = 'wallets'::regclass
        ) THEN
            ALTER TABLE "wallets" ADD CONSTRAINT "wallets_status_check" 
                CHECK (status IN ('active', 'pending_configuration', 'inactive', 'suspended'));
        END IF;
        
        -- Add unique constraint if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'wallets_unique_blockchain_network_address' AND conrelid = 'wallets'::regclass
        ) THEN
            ALTER TABLE "wallets" ADD CONSTRAINT "wallets_unique_blockchain_network_address" 
                UNIQUE (blockchain, network, address);
        END IF;
    END IF;
END $$;

-- Create wallet access controls table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'wallet_access_controls') THEN
        CREATE TABLE "wallet_access_controls" (
            "wallet_id" text NOT NULL,
            "user_id" text NOT NULL,
            "access_level" text NOT NULL,
            "daily_limit" numeric,
            "approval_required" boolean NOT NULL DEFAULT false,
            "created_at" timestamptz NOT NULL DEFAULT (now()),
            "updated_at" timestamptz NOT NULL DEFAULT (now()),
            PRIMARY KEY ("wallet_id", "user_id")
        );

        -- Add constraints
        ALTER TABLE "wallet_access_controls" ADD CONSTRAINT "wallet_access_controls_access_level_check" 
            CHECK (access_level IN ('owner', 'admin', 'operator', 'viewer'));

        -- Add foreign keys
        ALTER TABLE "wallet_access_controls" ADD FOREIGN KEY ("wallet_id") REFERENCES "wallets" ("id") ON DELETE CASCADE;
        ALTER TABLE "wallet_access_controls" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("username") ON DELETE CASCADE;
        
        -- Backfill wallet ownership for existing wallets
        INSERT INTO "wallet_access_controls" ("wallet_id", "user_id", "access_level")
        SELECT 
            w."id", 
            u."username", 
            'owner'
        FROM "wallets" w
        JOIN "users" u ON w."user_id"::text = u."username"
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Create transaction signatures table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'transaction_signatures') THEN
        CREATE TABLE "transaction_signatures" (
            "id" text PRIMARY KEY,
            "wallet_id" text NOT NULL,
            "unsigned_tx" jsonb NOT NULL,
            "signed_tx" jsonb,
            "status" text NOT NULL,
            "expires_at" timestamptz,
            "created_at" timestamptz NOT NULL DEFAULT (now()),
            "updated_at" timestamptz NOT NULL DEFAULT (now())
        );

        -- Add constraints
        ALTER TABLE "transaction_signatures" ADD CONSTRAINT "transaction_signatures_status_check" 
            CHECK (status IN ('pending_signature', 'signed', 'rejected', 'submitted', 'failed', 'confirmed'));

        -- Add foreign keys
        ALTER TABLE "transaction_signatures" ADD FOREIGN KEY ("wallet_id") REFERENCES "wallets" ("id") ON DELETE CASCADE;
    END IF;
END $$;

-- Create wallet connection history table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'wallet_connection_history') THEN
        CREATE TABLE "wallet_connection_history" (
            "id" text PRIMARY KEY,
            "wallet_id" text NOT NULL,
            "user_id" text NOT NULL,
            "action" text NOT NULL,
            "context" jsonb,
            "created_at" timestamptz NOT NULL DEFAULT (now())
        );

        -- Add constraints
        ALTER TABLE "wallet_connection_history" ADD CONSTRAINT "wallet_connection_history_action_check" 
            CHECK (action IN ('connected', 'disconnected', 'reconnected'));

        -- Add foreign keys
        ALTER TABLE "wallet_connection_history" ADD FOREIGN KEY ("wallet_id") REFERENCES "wallets" ("id") ON DELETE CASCADE;
        ALTER TABLE "wallet_connection_history" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("username");
        
        -- Record initial connection for existing wallets
        INSERT INTO "wallet_connection_history" ("id", "wallet_id", "user_id", "action", "context")
        SELECT 
            'wch_' || md5(random()::text || clock_timestamp()::text)::text,
            w."id", 
            u."username", 
            'connected',
            jsonb_build_object('migration', true, 'migration_date', now()::text)
        FROM "wallets" w
        JOIN "users" u ON w."user_id"::text = u."username";
    END IF;
END $$;

-- Drop the temporary function
DROP FUNCTION IF EXISTS column_exists(text, text);



配置：
GRPC_SERVER_ADDRESS=0.0.0.0:9090
TOKEN_SYMMETRIC_KEY=12345678901234567890123456789012
ACCESS_TOKEN_DURATION=1m
REFRESH_TOKEN_DURATION=24h
REDIS_ADDRESS=0.0.0.0:6379
EMAIL_SENDER_NAME=Simple Bank
EMAIL_SENDER_ADDRESS=simplebanktest@gmail.com
EMAIL_SENDER_PASSWORD=jekfcygyenvzekke


mysql:
	docker run --name mysql8 -p 3306:3306  -e MYSQL_ROOT_PASSWORD=123456 -d mysql:8

createdb:
	docker exec -it postgres createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres dropdb simple_bank

migrateup:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migrateup1:
	migrate -path db/migration -database "$(DB_URL)" -verbose up 1

migratedown:
	migrate -path db/migration -database "$(DB_URL)" -verbose down

migratedown1:
	migrate -path db/migration -database "$(DB_URL)" -verbose down 1

new_migration:
	migrate create -ext sql -dir db/migration -seq $(name)

db_docs:
	dbdocs build doc/db.dbml

db_schema:
	dbml2sql --postgres -o doc/schema.sql doc/db.dbml

sqlc:
	sqlc generate

test:
	go test -v -cover -short ./...

server:
	go run main.go

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/tanghu116/stablecoin_wallet_svc/db/sqlc Store
	mockgen -package mockwk -destination worker/mock/distributor.go github.com/tanghu116/stablecoin_wallet_svc/worker TaskDistributor

proto:
	rm -f pb/*.go
	rm -f doc/swagger/*.swagger.json
	protoc --proto_path=proto --go_out=pb --go_opt=paths=source_relative \
	--go-grpc_out=pb --go-grpc_opt=paths=source_relative \
	--grpc-gateway_out=pb --grpc-gateway_opt=paths=source_relative \
	--openapiv2_out=doc/swagger --openapiv2_opt=allow_merge=true,merge_file_name=simple_bank \
	proto/*.proto
	statik -src=./doc/swagger -dest=./doc

evans:
	evans --host localhost --port 9090 -r repl

redis:
	docker run --name redis -p 6379:6379 -d redis:7-alpine

.PHONY: network postgres createdb dropdb migrateup migratedown migrateup1 migratedown1 new_migration db_docs db_schema sqlc test server mock proto evans redis
