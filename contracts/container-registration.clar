;; Container Registration Contract
;; Records details of shipping containers

(define-data-var last-container-id uint u0)

;; Container data structure
(define-map containers
  { container-id: uint }
  {
    owner: principal,
    container-number: (string-ascii 11),
    container-type: (string-ascii 10),
    dimensions: {
      length: uint,
      width: uint,
      height: uint
    },
    max-weight: uint,
    manufacturing-date: uint,
    status: (string-ascii 20)
  }
)

;; Owner to container IDs mapping
(define-map owner-containers
  { owner: principal }
  { container-ids: (list 100 uint) }
)

;; Register a new container
(define-public (register-container
    (container-number (string-ascii 11))
    (container-type (string-ascii 10))
    (length uint)
    (width uint)
    (height uint)
    (max-weight uint)
    (manufacturing-date uint))
  (let
    (
      (new-id (+ (var-get last-container-id) u1))
      (owner tx-sender)
      (current-containers (default-to { container-ids: (list) } (map-get? owner-containers { owner: owner })))
    )
    ;; Update last container ID
    (var-set last-container-id new-id)

    ;; Add container to containers map
    (map-set containers
      { container-id: new-id }
      {
        owner: owner,
        container-number: container-number,
        container-type: container-type,
        dimensions: {
          length: length,
          width: width,
          height: height
        },
        max-weight: max-weight,
        manufacturing-date: manufacturing-date,
        status: "registered"
      }
    )

    ;; Update owner's container list
    (map-set owner-containers
      { owner: owner }
      { container-ids: (unwrap! (as-max-len? (append (get container-ids current-containers) new-id) u100) (err u4)) }
    )

    (ok new-id)
  )
)

;; Get container details
(define-read-only (get-container (container-id uint))
  (map-get? containers { container-id: container-id })
)

;; Get containers owned by a principal
(define-read-only (get-owner-containers (owner principal))
  (map-get? owner-containers { owner: owner })
)

;; Transfer container ownership
(define-public (transfer-container (container-id uint) (new-owner principal))
  (let
    (
      (container (unwrap! (map-get? containers { container-id: container-id }) (err u1)))
      (current-owner (get owner container))
      (sender-containers (unwrap! (map-get? owner-containers { owner: tx-sender }) (err u2)))
      (recipient-containers (default-to { container-ids: (list) } (map-get? owner-containers { owner: new-owner })))
    )

    ;; Check if sender is the owner
    (asserts! (is-eq current-owner tx-sender) (err u3))

    ;; Update container owner
    (map-set containers
      { container-id: container-id }
      (merge container { owner: new-owner })
    )

    ;; Remove from current owner's list
    (map-set owner-containers
      { owner: tx-sender }
      { container-ids: (filter (lambda (id) (not (is-eq id container-id))) (get container-ids sender-containers)) }
    )

    ;; Add to new owner's list
    (map-set owner-containers
      { owner: new-owner }
      { container-ids: (unwrap! (as-max-len? (append (get container-ids recipient-containers) container-id) u100) (err u4)) }
    )

    (ok true)
  )
)

;; Update container status
(define-public (update-container-status (container-id uint) (new-status (string-ascii 20)))
  (let
    (
      (container (unwrap! (map-get? containers { container-id: container-id }) (err u1)))
      (current-owner (get owner container))
    )

    ;; Check if sender is the owner
    (asserts! (is-eq current-owner tx-sender) (err u3))

    ;; Update container status
    (map-set containers
      { container-id: container-id }
      (merge container { status: new-status })
    )

    (ok true)
  )
)

