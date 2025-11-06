(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_NOT_FOUND (err u101))
(define-constant ERR_PROPERTY_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_TRANSFER (err u103))
(define-constant ERR_PENDING_TRANSFER (err u104))
(define-constant ERR_NOT_OWNER (err u105))
(define-constant ERR_INVALID_PRICE (err u106))
(define-constant ERR_PROPERTY_NOT_FOR_SALE (err u107))
(define-constant ERR_INSUFFICIENT_FUNDS (err u108))
(define-constant ERR_INSPECTOR_NOT_CERTIFIED (err u109))
(define-constant ERR_INSPECTION_NOT_FOUND (err u110))
(define-constant ERR_INSPECTION_ALREADY_EXISTS (err u111))

(define-data-var property-id-nonce uint u0)
(define-data-var transfer-id-nonce uint u0)
(define-data-var inspection-id-nonce uint u0)
(define-data-var document-id-nonce uint u0)
(define-data-var escrow-id-nonce uint u0)
(define-data-var tmp-rm-id uint u0)

(define-constant EMPTY-OWNER-PROPS (list))

(define-map properties
    uint
    {
        owner: principal,
        address: (string-ascii 256),
        area: uint,
        property-type: (string-ascii 64),
        valuation: uint,
        registered-at: uint,
        is-for-sale: bool,
        sale-price: uint,
    }
)

(define-map property-transfers
    uint
    {
        property-id: uint,
        from-owner: principal,
        to-owner: principal,
        transfer-price: uint,
        initiated-at: uint,
        status: (string-ascii 32),
    }
)

(define-map property-history
    {
        property-id: uint,
        entry-id: uint,
    }
    {
        previous-owner: principal,
        new-owner: principal,
        transfer-price: uint,
        transferred-at: uint,
    }
)

(define-map property-documents
    {
        property-id: uint,
        document-id: uint,
    }
    {
        document-hash: (buff 32),
        document-type: (string-ascii 64),
        uploaded-by: principal,
        uploaded-at: uint,
    }
)

(define-map owner-properties
    principal
    (list 100 uint)
)

(define-map certified-inspectors
    principal
    {
        license-number: (string-ascii 64),
        certification-date: uint,
        specialization: (string-ascii 128),
        is-active: bool,
    }
)

(define-map property-inspections
    uint
    {
        property-id: uint,
        inspector: principal,
        inspection-type: (string-ascii 64),
        inspection-date: uint,
        status: (string-ascii 32),
        findings: (string-ascii 512),
        score: uint,
        recommendations: (string-ascii 512),
    }
)

(define-map property-inspection-history
    {
        property-id: uint,
        inspection-sequence: uint,
    }
    uint
)

(define-map inspection-seq-counters
    uint
    uint
)

(define-map escrows
    uint
    {
        property-id: uint,
        seller: principal,
        buyer: principal,
        price: uint,
        opened-at: uint,
        deadline: uint,
        status: (string-ascii 32),
    }
)

(define-read-only (get-property (property-id uint))
    (map-get? properties property-id)
)
(define-read-only (get-transfer (transfer-id uint))
    (map-get? property-transfers transfer-id)
)
(define-read-only (get-property-history
        (property-id uint)
        (entry-id uint)
    )
    (map-get? property-history {
        property-id: property-id,
        entry-id: entry-id,
    })
)
(define-read-only (get-property-document
        (property-id uint)
        (document-id uint)
    )
    (map-get? property-documents {
        property-id: property-id,
        document-id: document-id,
    })
)
(define-read-only (get-owner-properties (owner principal))
    (match (map-get? owner-properties owner)
        p
        p
        EMPTY-OWNER-PROPS
    )
)
(define-read-only (get-current-property-id)
    (var-get property-id-nonce)
)
(define-read-only (get-current-transfer-id)
    (var-get transfer-id-nonce)
)
(define-read-only (get-inspector-info (inspector principal))
    (map-get? certified-inspectors inspector)
)
(define-read-only (get-inspection (inspection-id uint))
    (map-get? property-inspections inspection-id)
)
(define-read-only (get-property-inspection-by-sequence
        (property-id uint)
        (sequence uint)
    )
    (match (map-get? property-inspection-history {
        property-id: property-id,
        inspection-sequence: sequence,
    })
        inspection-id (get-inspection inspection-id)
        none
    )
)
(define-read-only (get-current-inspection-id)
    (var-get inspection-id-nonce)
)
(define-read-only (is-certified-inspector (inspector principal))
    (match (get-inspector-info inspector)
        info (get is-active info)
        false
    )
)
(define-read-only (get-escrow (escrow-id uint))
    (map-get? escrows escrow-id)
)
(define-read-only (get-current-escrow-id)
    (var-get escrow-id-nonce)
)

(define-private (get-contract-principal)
    (unwrap-panic (as-contract (ok tx-sender)))
)

(define-private (add-property-to-owner
        (owner principal)
        (property-id uint)
    )
    (let (
            (current (match (map-get? owner-properties owner)
                p
                p
                EMPTY-OWNER-PROPS
            ))
            (updated (unwrap-panic (as-max-len? (append current property-id) u100)))
        )
        (map-set owner-properties owner updated)
        true
    )
)

(define-private (acc-without
        (item uint)
        (acc (list 100 uint))
    )
    (if (is-eq item (var-get tmp-rm-id))
        acc
        (unwrap-panic (as-max-len? (append acc item) u100))
    )
)

(define-private (remove-property-from-owner
        (owner principal)
        (property-id uint)
    )
    (let ((current (match (map-get? owner-properties owner)
            p
            p
            EMPTY-OWNER-PROPS
        )))
        (var-set tmp-rm-id property-id)
        (map-set owner-properties owner
            (fold acc-without current EMPTY-OWNER-PROPS)
        )
        true
    )
)

(define-public (register-property
        (address (string-ascii 256))
        (area uint)
        (property-type (string-ascii 64))
        (valuation uint)
    )
    (let ((new-property-id (+ (var-get property-id-nonce) u1)))
        (asserts! (> area u0) ERR_INVALID_PRICE)
        (asserts! (> valuation u0) ERR_INVALID_PRICE)
        (map-set properties new-property-id {
            owner: tx-sender,
            address: address,
            area: area,
            property-type: property-type,
            valuation: valuation,
            registered-at: stacks-block-height,
            is-for-sale: false,
            sale-price: u0,
        })
        (add-property-to-owner tx-sender new-property-id)
        (var-set property-id-nonce new-property-id)
        (print {
            event: "property-registered",
            property-id: new-property-id,
            owner: tx-sender,
            address: address,
        })
        (ok new-property-id)
    )
)

(define-public (update-property-valuation
        (property-id uint)
        (new-valuation uint)
    )
    (let ((property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner property-data)) ERR_NOT_OWNER)
        (asserts! (> new-valuation u0) ERR_INVALID_PRICE)
        (map-set properties property-id
            (merge property-data { valuation: new-valuation })
        )
        (print {
            event: "property-valuation-updated",
            property-id: property-id,
            new-valuation: new-valuation,
        })
        (ok true)
    )
)

(define-public (list-property-for-sale
        (property-id uint)
        (sale-price uint)
    )
    (let ((property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner property-data)) ERR_NOT_OWNER)
        (asserts! (> sale-price u0) ERR_INVALID_PRICE)
        (map-set properties property-id
            (merge property-data {
                is-for-sale: true,
                sale-price: sale-price,
            })
        )
        (print {
            event: "property-listed",
            property-id: property-id,
            sale-price: sale-price,
        })
        (ok true)
    )
)

(define-public (remove-property-from-sale (property-id uint))
    (let ((property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner property-data)) ERR_NOT_OWNER)
        (map-set properties property-id
            (merge property-data {
                is-for-sale: false,
                sale-price: u0,
            })
        )
        (print {
            event: "property-delisted",
            property-id: property-id,
        })
        (ok true)
    )
)

(define-public (initiate-transfer
        (property-id uint)
        (new-owner principal)
    )
    (let (
            (property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND))
            (new-transfer-id (+ (var-get transfer-id-nonce) u1))
        )
        (asserts! (is-eq tx-sender (get owner property-data)) ERR_NOT_OWNER)
        (asserts! (not (is-eq tx-sender new-owner)) ERR_INVALID_TRANSFER)
        (map-set property-transfers new-transfer-id {
            property-id: property-id,
            from-owner: tx-sender,
            to-owner: new-owner,
            transfer-price: u0,
            initiated-at: stacks-block-height,
            status: "pending",
        })
        (var-set transfer-id-nonce new-transfer-id)
        (print {
            event: "transfer-initiated",
            transfer-id: new-transfer-id,
            property-id: property-id,
            from: tx-sender,
            to: new-owner,
        })
        (ok new-transfer-id)
    )
)

(define-public (complete-transfer (transfer-id uint))
    (let (
            (transfer-data (unwrap! (get-transfer transfer-id) ERR_PROPERTY_NOT_FOUND))
            (property-id (get property-id transfer-data))
            (property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND))
        )
        (asserts! (is-eq (get status transfer-data) "pending")
            ERR_INVALID_TRANSFER
        )
        (asserts!
            (or (is-eq tx-sender (get from-owner transfer-data)) (is-eq tx-sender CONTRACT_OWNER))
            ERR_UNAUTHORIZED
        )
        (map-set properties property-id
            (merge property-data {
                owner: (get to-owner transfer-data),
                is-for-sale: false,
                sale-price: u0,
            })
        )
        (map-set property-transfers transfer-id
            (merge transfer-data { status: "completed" })
        )
        (remove-property-from-owner (get from-owner transfer-data) property-id)
        (add-property-to-owner (get to-owner transfer-data) property-id)
        (print {
            event: "transfer-completed",
            transfer-id: transfer-id,
            property-id: property-id,
            new-owner: (get to-owner transfer-data),
        })
        (ok true)
    )
)

(define-public (purchase-property (property-id uint))
    (let (
            (property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND))
            (sale-price (get sale-price property-data))
            (current-owner (get owner property-data))
        )
        (asserts! (get is-for-sale property-data) ERR_PROPERTY_NOT_FOR_SALE)
        (asserts! (not (is-eq tx-sender current-owner)) ERR_INVALID_TRANSFER)
        (asserts! (>= (stx-get-balance tx-sender) sale-price)
            ERR_INSUFFICIENT_FUNDS
        )
        (try! (stx-transfer? sale-price tx-sender current-owner))
        (map-set properties property-id
            (merge property-data {
                owner: tx-sender,
                is-for-sale: false,
                sale-price: u0,
            })
        )
        (remove-property-from-owner current-owner property-id)
        (add-property-to-owner tx-sender property-id)
        (print {
            event: "property-purchased",
            property-id: property-id,
            buyer: tx-sender,
            seller: current-owner,
            price: sale-price,
        })
        (ok true)
    )
)

(define-public (add-property-document
        (property-id uint)
        (document-hash (buff 32))
        (document-type (string-ascii 64))
    )
    (let (
            (property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND))
            (new-document-id (+ (var-get document-id-nonce) u1))
        )
        (asserts! (is-eq tx-sender (get owner property-data)) ERR_NOT_OWNER)
        (map-set property-documents {
            property-id: property-id,
            document-id: new-document-id,
        } {
            document-hash: document-hash,
            document-type: document-type,
            uploaded-by: tx-sender,
            uploaded-at: stacks-block-height,
        })
        (var-set document-id-nonce new-document-id)
        (print {
            event: "document-added",
            property-id: property-id,
            document-type: document-type,
            uploaded-by: tx-sender,
        })
        (ok true)
    )
)

(define-public (certify-inspector
        (inspector principal)
        (license-number (string-ascii 64))
        (specialization (string-ascii 128))
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set certified-inspectors inspector {
            license-number: license-number,
            certification-date: stacks-block-height,
            specialization: specialization,
            is-active: true,
        })
        (print {
            event: "inspector-certified",
            inspector: inspector,
            license-number: license-number,
            specialization: specialization,
        })
        (ok true)
    )
)

(define-public (revoke-inspector-certification (inspector principal))
    (let ((inspector-info (unwrap! (get-inspector-info inspector) ERR_INSPECTOR_NOT_CERTIFIED)))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set certified-inspectors inspector
            (merge inspector-info { is-active: false })
        )
        (print {
            event: "inspector-certification-revoked",
            inspector: inspector,
        })
        (ok true)
    )
)

(define-public (conduct-property-inspection
        (property-id uint)
        (inspection-type (string-ascii 64))
        (findings (string-ascii 512))
        (score uint)
        (recommendations (string-ascii 512))
    )
    (let (
            (property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND))
            (new-inspection-id (+ (var-get inspection-id-nonce) u1))
            (current-seq (default-to u0 (map-get? inspection-seq-counters property-id)))
            (new-seq (+ current-seq u1))
        )
        (asserts! (is-certified-inspector tx-sender) ERR_INSPECTOR_NOT_CERTIFIED)
        (asserts! (and (>= score u0) (<= score u100)) ERR_INVALID_PRICE)
        (map-set property-inspections new-inspection-id {
            property-id: property-id,
            inspector: tx-sender,
            inspection-type: inspection-type,
            inspection-date: stacks-block-height,
            status: "completed",
            findings: findings,
            score: score,
            recommendations: recommendations,
        })
        (map-set property-inspection-history {
            property-id: property-id,
            inspection-sequence: new-seq,
        }
            new-inspection-id
        )
        (map-set inspection-seq-counters property-id new-seq)
        (var-set inspection-id-nonce new-inspection-id)
        (print {
            event: "property-inspection-completed",
            inspection-id: new-inspection-id,
            property-id: property-id,
            inspector: tx-sender,
            inspection-type: inspection-type,
            score: score,
        })
        (ok new-inspection-id)
    )
)

(define-public (update-inspection-status
        (inspection-id uint)
        (new-status (string-ascii 32))
    )
    (let ((inspection-data (unwrap! (get-inspection inspection-id) ERR_INSPECTION_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get inspector inspection-data))
            ERR_UNAUTHORIZED
        )
        (map-set property-inspections inspection-id
            (merge inspection-data { status: new-status })
        )
        (print {
            event: "inspection-status-updated",
            inspection-id: inspection-id,
            new-status: new-status,
        })
        (ok true)
    )
)

(define-public (open-escrow
        (property-id uint)
        (buyer principal)
        (price uint)
        (duration uint)
    )
    (let (
            (property-data (unwrap! (get-property property-id) ERR_PROPERTY_NOT_FOUND))
            (new-escrow-id (+ (var-get escrow-id-nonce) u1))
        )
        (asserts! (is-eq tx-sender (get owner property-data)) ERR_NOT_OWNER)
        (asserts! (> price u0) ERR_INVALID_PRICE)
        (map-set escrows new-escrow-id {
            property-id: property-id,
            seller: tx-sender,
            buyer: buyer,
            price: price,
            opened-at: stacks-block-height,
            deadline: (+ stacks-block-height duration),
            status: "awaiting-deposit",
        })
        (var-set escrow-id-nonce new-escrow-id)
        (print {
            event: "escrow-opened",
            escrow-id: new-escrow-id,
            property-id: property-id,
            seller: tx-sender,
            buyer: buyer,
            price: price,
        })
        (ok new-escrow-id)
    )
)

(define-public (fund-escrow (escrow-id uint))
    (let ((e (unwrap! (get-escrow escrow-id) ERR_PROPERTY_NOT_FOUND)))
        (asserts! (is-eq (get status e) "awaiting-deposit") ERR_INVALID_TRANSFER)
        (asserts! (is-eq tx-sender (get buyer e)) ERR_UNAUTHORIZED)
        (asserts! (<= stacks-block-height (get deadline e)) ERR_INVALID_TRANSFER)
        (try! (stx-transfer? (get price e) tx-sender (get-contract-principal)))
        (map-set escrows escrow-id (merge e { status: "funded" }))
        (print {
            event: "escrow-funded",
            escrow-id: escrow-id,
            buyer: tx-sender,
            amount: (get price e),
        })
        (ok true)
    )
)

(define-public (settle-escrow (escrow-id uint))
    (let (
            (e (unwrap! (get-escrow escrow-id) ERR_PROPERTY_NOT_FOUND))
            (pid (get property-id e))
            (pd (unwrap! (get-property pid) ERR_PROPERTY_NOT_FOUND))
        )
        (asserts! (is-eq (get status e) "funded") ERR_INVALID_TRANSFER)
        (asserts! (is-eq tx-sender (get seller e)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get owner pd) (get seller e)) ERR_NOT_OWNER)
        (let ((result (as-contract (stx-transfer? (get price e) tx-sender (get seller e)))))
            (match result
                ok-val (begin
                    (map-set properties pid
                        (merge pd {
                            owner: (get buyer e),
                            is-for-sale: false,
                            sale-price: u0,
                        })
                    )
                    (remove-property-from-owner (get seller e) pid)
                    (add-property-to-owner (get buyer e) pid)
                    (map-set escrows escrow-id (merge e { status: "settled" }))
                    (print {
                        event: "escrow-settled",
                        escrow-id: escrow-id,
                        property-id: pid,
                        seller: (get seller e),
                        buyer: (get buyer e),
                        price: (get price e),
                    })
                    (ok true)
                )
                err-code
                ERR_INSUFFICIENT_FUNDS
            )
        )
    )
)

(define-public (cancel-escrow (escrow-id uint))
    (let ((e (unwrap! (get-escrow escrow-id) ERR_PROPERTY_NOT_FOUND)))
        (asserts! (is-eq (get status e) "funded") ERR_INVALID_TRANSFER)
        (asserts! (> stacks-block-height (get deadline e)) ERR_INVALID_TRANSFER)
        (asserts! (is-eq tx-sender (get buyer e)) ERR_UNAUTHORIZED)
        (let ((refund (as-contract (stx-transfer? (get price e) tx-sender (get buyer e)))))
            (match refund
                ok-val (begin
                    (map-set escrows escrow-id (merge e { status: "canceled" }))
                    (print {
                        event: "escrow-canceled",
                        escrow-id: escrow-id,
                        buyer: (get buyer e),
                        amount: (get price e),
                    })
                    (ok true)
                )
                err-code
                ERR_INSUFFICIENT_FUNDS
            )
        )
    )
)
