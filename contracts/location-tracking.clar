;; Location Tracking Contract
;; Monitors movement through ports and facilities

;; Define contract deployer
(define-constant DEPLOYER tx-sender)

(define-data-var last-location-id uint u0)

;; Location data structure
(define-map locations
  { location-id: uint }
  {
    name: (string-ascii 50),
    location-type: (string-ascii 20),
    latitude: int,
    longitude: int,
    authorized-reporters: (list 20 principal)
  }
)

;; Container location history
(define-map container-locations
  { container-id: uint }
  { location-history: (list 100 {
      location-id: uint,
      timestamp: uint,
      status: (string-ascii 20),
      reported-by: principal
    })
  }
)

;; Register a new location
(define-public (register-location
    (name (string-ascii 50))
    (location-type (string-ascii 20))
    (latitude int)
    (longitude int)
    (authorized-reporters (list 20 principal)))
  (let
    (
      (new-id (+ (var-get last-location-id) u1))
    )
    ;; Update last location ID
    (var-set last-location-id new-id)

    ;; Add location to locations map
    (map-set locations
      { location-id: new-id }
      {
        name: name,
        location-type: location-type,
        latitude: latitude,
        longitude: longitude,
        authorized-reporters: authorized-reporters
      }
    )

    (ok new-id)
  )
)

;; Check if principal is authorized for a location
(define-private (is-authorized (reporter principal) (location-id uint))
  (let
    (
      (location (unwrap! (map-get? locations { location-id: location-id }) false))
      (authorized-list (get authorized-reporters location))
    )
    (or
      (is-some (index-of authorized-list reporter))
      (is-eq reporter tx-sender)
    )
  )
)

;; Record container arrival at a location
(define-public (record-container-arrival
    (container-id uint)
    (location-id uint)
    (status (string-ascii 20)))
  (let
    (
      (reporter tx-sender)
      (timestamp (unwrap! (get-block-info? time (- block-height u1)) (err u1)))
      (current-history (default-to { location-history: (list) } (map-get? container-locations { container-id: container-id })))
    )

    ;; Check if reporter is authorized
    (asserts! (is-authorized reporter location-id) (err u2))

    ;; Add location to container's history
    (map-set container-locations
      { container-id: container-id }
      { location-history: (unwrap! (as-max-len? (append
          (get location-history current-history)
          {
            location-id: location-id,
            timestamp: timestamp,
            status: status,
            reported-by: reporter
          }
        ) u100) (err u3))
      }
    )

    (ok true)
  )
)

;; Get location details
(define-read-only (get-location (location-id uint))
  (map-get? locations { location-id: location-id })
)

;; Get container location history
(define-read-only (get-container-location-history (container-id uint))
  (map-get? container-locations { container-id: container-id })
)

;; Get container's current location (most recent in history)
(define-read-only (get-container-current-location (container-id uint))
  (let
    (
      (history (default-to { location-history: (list) } (map-get? container-locations { container-id: container-id })))
      (history-length (len (get location-history history)))
    )
    (if (> history-length u0)
      (ok (unwrap! (element-at (get location-history history) (- history-length u1)) (err u1)))
      (err u1)
    )
  )
)

;; Add authorized reporter to a location
(define-public (add-authorized-reporter (location-id uint) (reporter principal))
  (let
    (
      (location (unwrap! (map-get? locations { location-id: location-id }) (err u1)))
      (current-reporters (get authorized-reporters location))
    )

    ;; Only contract owner can add reporters
    (asserts! (is-eq tx-sender DEPLOYER) (err u3))

    ;; Update authorized reporters list
    (map-set locations
      { location-id: location-id }
      (merge location { authorized-reporters: (unwrap! (as-max-len? (append current-reporters reporter) u20) (err u4)) })
    )

    (ok true)
  )
)

