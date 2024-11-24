;; DigitalLegacy - Decentralized Will Executor
;; Manages the distribution of digital assets according to predefined rules

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

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-INVALID-BENEFICIARY (err u102))
(define-constant ERR-INSUFFICIENT-GUARDIANS (err u103))
(define-constant ERR-NOT-ACTIVE (err u104))
(define-constant REQUIRED_GUARDIANS u2)

;; Data Variables
(define-data-var last-activity-height uint u0)
(define-data-var inactivity-threshold uint u0)
(define-data-var is-initialized bool false)

;; Data Maps
(define-map beneficiaries principal (list 200 {asset: (string-ascii 64), percentage: uint}))
(define-map guardians principal bool)
(define-map guardian-approvals principal uint)
(define-map assets {type: (string-ascii 64), id: uint} 
  {owner: principal, beneficiary: principal, amount: uint})

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

;; Public Functions
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
    (map-set guardians guardian true)
    (ok true)))

(define-public (add-beneficiary (beneficiary principal) (distribution (list 200 {asset: (string-ascii 64), percentage: uint})))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (map-set beneficiaries beneficiary distribution)
    (ok true)))

(define-public (record-activity)
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (var-set last-activity-height block-height)
    (ok true)))

(define-public (approve-distribution (beneficiary principal))
  (begin
    (asserts! (is-guardian tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-beneficiary beneficiary) ERR-INVALID-BENEFICIARY)
    (asserts! (check-activity) ERR-NOT-ACTIVE)
    (map-set guardian-approvals tx-sender (+ (default-to u0 (map-get? guardian-approvals tx-sender)) u1))
    (ok true)))

(define-public (execute-distribution (beneficiary principal))
  (let ((approvals (default-to u0 (map-get? guardian-approvals beneficiary))))
    (begin
      (asserts! (>= approvals REQUIRED_GUARDIANS) ERR-INSUFFICIENT-GUARDIANS)
      (asserts! (check-activity) ERR-NOT-ACTIVE)
      (asserts! (validate-beneficiary beneficiary) ERR-INVALID-BENEFICIARY)
      (ok true))))

;; Transfer Functions for Different Asset Types
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
  (var-get last-activity-height))

(define-read-only (get-beneficiary-distribution (beneficiary principal))
  (map-get? beneficiaries beneficiary))

(define-read-only (get-guardian-status (account principal))
  (is-guardian account))

(define-read-only (check-distribution-ready (beneficiary principal))
  (and 
    (check-activity)
    (validate-beneficiary beneficiary)
    (>= (default-to u0 (map-get? guardian-approvals beneficiary)) REQUIRED_GUARDIANS)))