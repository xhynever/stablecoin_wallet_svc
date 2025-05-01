-- name: CreateWallet :one
INSERT INTO wallets (
  organization_id,
  provider_type,
  wallet_provider,
  blockchain,
  network,
  address,
  status,
  default_wallet,
  description
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9
) RETURNING *;

-- name: GetWallet :one
SELECT * FROM wallets
WHERE id = $1 LIMIT 1;

-- name: GetWalletForUpdate :one
SELECT * FROM wallets
WHERE id = $1 LIMIT 1
FOR NO KEY UPDATE;

-- name: ListWallets :many
SELECT * FROM wallets
WHERE 
  ($1::text IS NULL OR status = $1) AND
  ($2::text IS NULL OR blockchain = $2) AND
  ($3::text IS NULL OR organization_id = $3)
ORDER BY created_at DESC
LIMIT $4
OFFSET $5;

-- name: UpdateWallet :one
UPDATE wallets
SET
  description = COALESCE(sqlc.narg(description), description),
  default_wallet = COALESCE(sqlc.narg(default_wallet), default_wallet),
  updated_at = now()
WHERE id = sqlc.arg(id)
RETURNING *;

-- name: UpdateWalletStatus :one
UPDATE wallets
SET 
  status = $2,
  updated_at = now()
WHERE id = $1
RETURNING *;

-- name: GetWalletByAddress :one
SELECT * FROM wallets
WHERE blockchain = $1 AND network = $2 AND address = $3
LIMIT 1;

-- name: GetWalletsByOrganization :many
SELECT * FROM wallets
WHERE organization_id = $1
ORDER BY created_at DESC;

-- name: DeleteWallet :exec
DELETE FROM wallets
WHERE id = $1;

-- name: GetWalletBalances :many
SELECT currency, amount, available, pending
FROM balances
WHERE wallet_id = $1;

-- name: UpsertWalletBalance :one
INSERT INTO balances (
  wallet_id,
  currency,
  amount,
  available,
  pending,
  user_id
) VALUES (
  $1, $2, $3, $4, $5, $6
)
ON CONFLICT (wallet_id, currency) 
DO UPDATE SET
  amount = EXCLUDED.amount,
  available = EXCLUDED.available,
  pending = EXCLUDED.pending,
  updated_at = now()
RETURNING *;

-- name: UpdateWalletBalance :one
UPDATE balances
SET 
  amount = amount + sqlc.arg(delta),
  updated_at = now()
WHERE wallet_id = sqlc.arg(wallet_id) AND currency = sqlc.arg(currency)
RETURNING *;

-- Transaction Signature Operations

-- name: CreateTransactionSignature :one
INSERT INTO transaction_signatures (
  id,
  wallet_id,
  unsigned_tx,
  status,
  expires_at
) VALUES (
  $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetTransactionSignature :one
SELECT * FROM transaction_signatures
WHERE id = $1 LIMIT 1;

-- name: UpdateTransactionSignatureStatus :one
UPDATE transaction_signatures
SET 
  status = $2,
  updated_at = now()
WHERE id = $1
RETURNING *;

-- name: UpdateTransactionSignature :one
UPDATE transaction_signatures
SET 
  signed_tx = $2,
  status = $3,
  updated_at = now()
WHERE id = $1
RETURNING *;

-- name: ListPendingTransactionSignatures :many
SELECT * FROM transaction_signatures
WHERE status = 'pending_signature' AND (expires_at IS NULL OR expires_at > now())
ORDER BY created_at ASC
LIMIT $1;

-- name: DeleteExpiredTransactionSignatures :exec
DELETE FROM transaction_signatures
WHERE expires_at < now() AND status = 'pending_signature';
