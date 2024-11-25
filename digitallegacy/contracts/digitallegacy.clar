;; DigitalLegacy - Cross-Chain Decentralized Will Executor
;; Manages the distribution of digital assets across multiple blockchains

;; Define traits locally
(define-trait nft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-owner (uint) (response principal uint))
  )
)

(define-trait ft-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-balance (principal) (response uint uint))
  )
)

(define-trait bridge-trait
  (
    (initiate-transfer ((string-ascii 64) principal uint) (response bool uint))
    (verify-transfer ((buff 32)) (response bool uint))
    (get-bridge-fee ((string-ascii 64)) (response uint uint))
  )
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-INVALID-BENEFICIARY (err u102))
(define-constant ERR-INSUFFICIENT-GUARDIANS (err u103))
(define-constant ERR-NOT-ACTIVE (err u104))
(define-constant ERR-INVALID-CHAIN (err u105))
(define-constant ERR-BRIDGE-ERROR (err u106))
(define-constant ERR-LIST-FULL (err u107))
(define-constant ERR-NO-BRIDGE-CONTRACT (err u108))
(define-constant REQUIRED_GUARDIANS u2)

;; Data Variables
(define-data-var last-activity-height uint u0)
(define-data-var inactivity-threshold uint u0)
(define-data-var is-initialized bool false)
(define-data-var transfer-nonce uint u0)

;; Data Maps
(define-map beneficiaries principal 
  {
    distributions: (list 200 {asset: (string-ascii 64), percentage: uint}),
    cross-chain-addresses: (list 10 {chain: (string-ascii 32), address: (string-ascii 64)})
  })
(define-map guardians principal bool)
(define-map guardian-approvals principal uint)
(define-map supported-chains 
  (string-ascii 32)
  {
    bridge-contract: principal,
    active: bool,
    confirmation-blocks: uint
  })
(define-map cross-chain-transfers 
  (buff 32) 
  {
    beneficiary: principal,
    chain: (string-ascii 32),
    amount: uint,
    status: (string-ascii 16)
  })

;; Private Functions
(define-private (is-guardian (account principal))
  (default-to false (map-get? guardians account)))

(define-private (check-activity)
  (let ((current-height block-height))
    (if (> (- current-height (var-get last-activity-height)) (var-get inactivity-threshold))
      true
      false)))

(define-private (validate-beneficiary (beneficiary principal))
  (match (map-get? beneficiaries beneficiary)
    beneficiary-data true
    false))

(define-private (validate-chain (chain (string-ascii 32)))
  (match (map-get? supported-chains chain)
    chain-data true
    false))

(define-private (get-bridge-contract (chain (string-ascii 32)))
  (match (map-get? supported-chains chain)
    chain-data (ok (get bridge-contract chain-data))
    (err ERR-NO-BRIDGE-CONTRACT)))

(define-private (generate-transfer-id)
  (let ((current-nonce (var-get transfer-nonce)))
    (begin
      (var-set transfer-nonce (+ current-nonce u1))
      (sha256 (concat (hash160 (print current-nonce)) (hash160 block-height))))))

;; Chain Management Functions
(define-public (add-or-update-supported-chain 
    (chain (string-ascii 32)) 
    (bridge-contract principal) 
    (confirmation-blocks uint)
    (active bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (ok (map-set supported-chains chain {
      bridge-contract: bridge-contract,
      active: active,
      confirmation-blocks: confirmation-blocks
    }))))

;; Cross-Chain Distribution Functions
(define-public (add-cross-chain-beneficiary 
    (beneficiary principal) 
    (chain (string-ascii 32)) 
    (address (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (validate-chain chain) ERR-INVALID-CHAIN)
    (let ((existing-data (map-get? beneficiaries beneficiary)))
      (match existing-data
        data-value 
          (let ((new-address {chain: chain, address: address})
                (updated-addresses (unwrap! (as-max-len? 
                  (append (get cross-chain-addresses data-value) new-address) 
                  u10) 
                  ERR-LIST-FULL)))
            (ok (map-set beneficiaries beneficiary
              (merge data-value 
                {cross-chain-addresses: updated-addresses}))))
        ERR-INVALID-BENEFICIARY))))

(define-public (confirm-cross-chain-transfer (transfer-id (buff 32)))
  (match (map-get? cross-chain-transfers transfer-id)
    transfer-data
      (ok (map-set cross-chain-transfers transfer-id
        (merge transfer-data {status: "completed"})))
    (err ERR-BRIDGE-ERROR)))

;; Original Contract Functions
(define-public (initialize (threshold uint))
  (begin
    (asserts! (not (var-get is-initialized)) ERR-ALREADY-INITIALIZED)
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (var-set inactivity-threshold threshold)
    (var-set last-activity-height block-height)
    (var-set is-initialized true)
    (ok true)))

(define-public (add-guardian (guardian principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (ok (map-set guardians guardian true))))

(define-public (add-beneficiary (beneficiary principal) (distribution (list 200 {asset: (string-ascii 64), percentage: uint})))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (ok (map-set beneficiaries beneficiary 
      {
        distributions: distribution,
        cross-chain-addresses: (list)
      }))))

(define-public (record-activity)
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set last-activity-height block-height))))

(define-public (approve-distribution (beneficiary principal))
  (begin
    (asserts! (is-guardian tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-beneficiary beneficiary) ERR-INVALID-BENEFICIARY)
    (asserts! (check-activity) ERR-NOT-ACTIVE)
    (ok (map-set guardian-approvals tx-sender (+ (default-to u0 (map-get? guardian-approvals tx-sender)) u1)))))

(define-public (execute-distribution (beneficiary principal))
  (let ((approvals (default-to u0 (map-get? guardian-approvals beneficiary))))
    (begin
      (asserts! (>= approvals REQUIRED_GUARDIANS) ERR-INSUFFICIENT-GUARDIANS)
      (asserts! (check-activity) ERR-NOT-ACTIVE)
      (asserts! (validate-beneficiary beneficiary) ERR-INVALID-BENEFICIARY)
      (ok true))))

;; Asset Transfer Functions
(define-public (transfer-stx (beneficiary principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (try! (stx-transfer? amount tx-sender beneficiary))
    (ok true)))

(define-public (transfer-ft (token <ft-trait>) (beneficiary principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (try! (contract-call? token transfer amount tx-sender beneficiary none))
    (ok true)))

(define-public (transfer-nft (token <nft-trait>) (beneficiary principal) (token-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (try! (contract-call? token transfer token-id tx-sender beneficiary))
    (ok true)))

;; Read-Only Functions
(define-read-only (get-last-activity)
  (ok (var-get last-activity-height)))

(define-read-only (get-beneficiary-distribution (beneficiary principal))
  (ok (map-get? beneficiaries beneficiary)))

(define-read-only (get-guardian-status (account principal))
  (ok (is-guardian account)))

(define-read-only (get-chain-status (chain (string-ascii 32)))
  (ok (map-get? supported-chains chain)))

(define-read-only (get-transfer-status (transfer-id (buff 32)))
  (ok (map-get? cross-chain-transfers transfer-id)))

(define-read-only (check-distribution-ready (beneficiary principal))
  (ok (and 
    (check-activity)
    (validate-beneficiary beneficiary)
    (>= (default-to u0 (map-get? guardian-approvals beneficiary)) REQUIRED_GUARDIANS))))

