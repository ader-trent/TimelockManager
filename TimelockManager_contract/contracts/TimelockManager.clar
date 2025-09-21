
;; title: TimelockManager
;; version: 1.0.0
;; summary: Address reputation system for timelock contract manager trustworthiness scoring
;; description: A smart contract that tracks and manages reputation scores for addresses
;;              based on their performance as timelock contract managers

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-SCORE (err u402))
(define-constant ERR-MANAGER-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INVALID-PARAMETERS (err u400))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-REPUTATION-SCORE u0)
(define-constant MAX-REPUTATION-SCORE u100)
(define-constant INITIAL-REPUTATION-SCORE u50)

;; Data variables
(define-data-var total-managers uint u0)

;; Manager reputation data structure
(define-map manager-reputation
    { manager: principal }
    {
        score: uint,
        total-locks: uint,
        successful-locks: uint,
        failed-locks: uint,
        last-activity: uint,
        is-active: bool
    }
)

;; Manager performance history
(define-map performance-history
    { manager: principal, lock-id: uint }
    {
        start-block: uint,
        end-block: uint,
        was-successful: bool,
        timestamp: uint
    }
)

;; Track lock sequence for each manager
(define-map manager-lock-counter
    { manager: principal }
    { counter: uint }
)

;; Events (using print for event logging)
(define-private (log-event (event-type (string-ascii 50)) (data (string-ascii 200)))
    (print { event: event-type, data: data, block: block-height })
)

;; Initialize a new timelock manager
(define-public (register-manager (manager principal))
    (begin
        ;; Check if manager already exists
        (asserts! (is-none (map-get? manager-reputation { manager: manager })) ERR-ALREADY-EXISTS)

        ;; Create new manager record
        (map-set manager-reputation
            { manager: manager }
            {
                score: INITIAL-REPUTATION-SCORE,
                total-locks: u0,
                successful-locks: u0,
                failed-locks: u0,
                last-activity: block-height,
                is-active: true
            }
        )

        ;; Initialize lock counter
        (map-set manager-lock-counter
            { manager: manager }
            { counter: u0 }
        )

        ;; Update total managers count
        (var-set total-managers (+ (var-get total-managers) u1))

        ;; Log event
        (log-event "MANAGER_REGISTERED" "New timelock manager registered")

        (ok manager)
    )
)

;; Record the start of a timelock operation
(define-public (start-timelock (manager principal) (duration uint))
    (let
        (
            (manager-data (unwrap! (map-get? manager-reputation { manager: manager }) ERR-MANAGER-NOT-FOUND))
            (current-counter (default-to { counter: u0 } (map-get? manager-lock-counter { manager: manager })))
            (lock-id (+ (get counter current-counter) u1))
        )

        ;; Validate inputs
        (asserts! (> duration u0) ERR-INVALID-PARAMETERS)
        (asserts! (get is-active manager-data) ERR-NOT-AUTHORIZED)

        ;; Record performance history
        (map-set performance-history
            { manager: manager, lock-id: lock-id }
            {
                start-block: block-height,
                end-block: (+ block-height duration),
                was-successful: false, ;; Will be updated when lock completes
                timestamp: block-height
            }
        )

        ;; Update manager's total locks
        (map-set manager-reputation
            { manager: manager }
            (merge manager-data {
                total-locks: (+ (get total-locks manager-data) u1),
                last-activity: block-height
            })
        )

        ;; Update lock counter
        (map-set manager-lock-counter
            { manager: manager }
            { counter: lock-id }
        )

        ;; Log event
        (log-event "TIMELOCK_STARTED" "Timelock operation initiated")

        (ok lock-id)
    )
)

;; Record the completion of a timelock operation
(define-public (complete-timelock (manager principal) (lock-id uint) (successful bool))
    (let
        (
            (manager-data (unwrap! (map-get? manager-reputation { manager: manager }) ERR-MANAGER-NOT-FOUND))
            (lock-data (unwrap! (map-get? performance-history { manager: manager, lock-id: lock-id }) ERR-MANAGER-NOT-FOUND))
        )

        ;; Validate that the caller is authorized (could be manager or contract owner)
        (asserts! (or (is-eq tx-sender manager) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

        ;; Update performance history
        (map-set performance-history
            { manager: manager, lock-id: lock-id }
            (merge lock-data { was-successful: successful })
        )

        ;; Update manager reputation based on success/failure
        (let
            (
                (new-successful (if successful (+ (get successful-locks manager-data) u1) (get successful-locks manager-data)))
                (new-failed (if successful (get failed-locks manager-data) (+ (get failed-locks manager-data) u1)))
                (new-score (calculate-reputation-score new-successful (get total-locks manager-data)))
            )

            (map-set manager-reputation
                { manager: manager }
                (merge manager-data {
                    successful-locks: new-successful,
                    failed-locks: new-failed,
                    score: new-score,
                    last-activity: block-height
                })
            )
        )

        ;; Log event
        (log-event "TIMELOCK_COMPLETED" (if successful "Timelock completed successfully" "Timelock failed"))

        (ok successful)
    )
)

;; Deactivate a manager (only owner can do this)
(define-public (deactivate-manager (manager principal))
    (let
        (
            (manager-data (unwrap! (map-get? manager-reputation { manager: manager }) ERR-MANAGER-NOT-FOUND))
        )

        ;; Only contract owner can deactivate
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

        ;; Update manager status
        (map-set manager-reputation
            { manager: manager }
            (merge manager-data { is-active: false })
        )

        ;; Log event
        (log-event "MANAGER_DEACTIVATED" "Manager has been deactivated")

        (ok true)
    )
)

;; Calculate reputation score based on success rate
(define-private (calculate-reputation-score (successful uint) (total uint))
    (if (is-eq total u0)
        INITIAL-REPUTATION-SCORE
        (let
            (
                (success-rate (/ (* successful u100) total))
            )
            ;; Score is based on success rate with some minimum baseline
            (+ u10 (/ (* success-rate u90) u100))
        )
    )
)

;; Read-only functions

;; Get manager reputation data
(define-read-only (get-manager-reputation (manager principal))
    (map-get? manager-reputation { manager: manager })
)

;; Get manager's reputation score only
(define-read-only (get-reputation-score (manager principal))
    (match (map-get? manager-reputation { manager: manager })
        manager-data (ok (get score manager-data))
        ERR-MANAGER-NOT-FOUND
    )
)

;; Check if manager is trustworthy (score above threshold)
(define-read-only (is-trustworthy-manager (manager principal) (threshold uint))
    (match (map-get? manager-reputation { manager: manager })
        manager-data
            (and
                (get is-active manager-data)
                (>= (get score manager-data) threshold)
            )
        false
    )
)

;; Get performance history for a specific lock
(define-read-only (get-lock-performance (manager principal) (lock-id uint))
    (map-get? performance-history { manager: manager, lock-id: lock-id })
)

;; Get total number of registered managers
(define-read-only (get-total-managers)
    (var-get total-managers)
)

;; Get managers with score above threshold
(define-read-only (get-top-managers (min-score uint))
    ;; Note: This is a simplified version. In practice, you might want to implement pagination
    ;; or use a more sophisticated querying mechanism
    (ok min-score) ;; Placeholder - full implementation would require iteration
)

;; Check if caller is contract owner
(define-read-only (is-contract-owner (caller principal))
    (is-eq caller CONTRACT-OWNER)
)

;; Get contract statistics
(define-read-only (get-contract-stats)
    {
        total-managers: (var-get total-managers),
        contract-owner: CONTRACT-OWNER,
        min-score: MIN-REPUTATION-SCORE,
        max-score: MAX-REPUTATION-SCORE,
        initial-score: INITIAL-REPUTATION-SCORE
    }
)
