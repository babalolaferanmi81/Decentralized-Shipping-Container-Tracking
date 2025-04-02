;; Condition Monitoring Contract
;; Tracks environmental factors during transport

;; Condition data structure
(define-map container-conditions
  { container-id: uint }
  { condition-records: (list 1000 {
      timestamp: uint,
      temperature: int,
      humidity: int,
      shock: uint,
      reported-by: principal
    })
  }
)

;; Alert thresholds for conditions
(define-map container-thresholds
  { container-id: uint }
  {
    min-temperature: int,
    max-temperature: int,
    max-humidity: int,
    max-shock: uint
  }
)

;; Alerts for condition violations
(define-map container-alerts
  { container-id: uint }
  { alerts: (list 100 {
      timestamp: uint,
      alert-type: (string-ascii 20),
      value: int,
      threshold: int
    })
  }
)

;; Set condition thresholds for a container
(define-public (set-condition-thresholds
    (container-id uint)
    (min-temperature int)
    (max-temperature int)
    (max-humidity int)
    (max-shock uint))
  (begin
    ;; TODO: Add authorization check from container-registration contract

    (map-set container-thresholds
      { container-id: container-id }
      {
        min-temperature: min-temperature,
        max-temperature: max-temperature,
        max-humidity: max-humidity,
        max-shock: max-shock
      }
    )

    (ok true)
  )
)

;; Record container conditions
(define-public (record-condition
    (container-id uint)
    (temperature int)
    (humidity int)
    (shock uint))
  (let
    (
      (reporter tx-sender)
      (timestamp (unwrap! (get-block-info? time (- block-height u1)) (err u1)))
      (current-records (default-to { condition-records: (list) } (map-get? container-conditions { container-id: container-id })))
      (thresholds (map-get? container-thresholds { container-id: container-id }))
    )

    ;; Add condition record
    (map-set container-conditions
      { container-id: container-id }
      { condition-records: (unwrap! (as-max-len? (append
          (get condition-records current-records)
          {
            timestamp: timestamp,
            temperature: temperature,
            humidity: humidity,
            shock: shock,
            reported-by: reporter
          }
        ) u1000) (err u2))
      }
    )

    ;; Check for threshold violations and create alerts if needed
    (if (is-some thresholds)
      (begin
        (try! (check-thresholds container-id temperature humidity shock timestamp (unwrap! thresholds (err u2))))
        (ok true)
      )
      (ok true)
    )
  )
)

;; Check if conditions exceed thresholds and create alerts
(define-private (check-thresholds
    (container-id uint)
    (temperature int)
    (humidity int)
    (shock uint)
    (timestamp uint)
    (thresholds {
      min-temperature: int,
      max-temperature: int,
      max-humidity: int,
      max-shock: uint
    }))
  (let
    (
      (current-alerts (default-to { alerts: (list) } (map-get? container-alerts { container-id: container-id })))
      (min-temp (get min-temperature thresholds))
      (max-temp (get max-temperature thresholds))
      (max-hum (get max-humidity thresholds))
      (max-shk (get max-shock thresholds))
    )
    (begin
      ;; Check temperature (low)
      (if (< temperature min-temp)
        (map-set container-alerts
          { container-id: container-id }
          { alerts: (unwrap! (as-max-len? (append
              (get alerts current-alerts)
              {
                timestamp: timestamp,
                alert-type: "low-temperature",
                value: temperature,
                threshold: min-temp
              }
            ) u100) (err u3))
          }
        )
        true
      )

      ;; Check temperature (high)
      (if (> temperature max-temp)
        (map-set container-alerts
          { container-id: container-id }
          { alerts: (unwrap! (as-max-len? (append
              (get alerts current-alerts)
              {
                timestamp: timestamp,
                alert-type: "high-temperature",
                value: temperature,
                threshold: max-temp
              }
            ) u100) (err u3))
          }
        )
        true
      )

      ;; Check humidity
      (if (> humidity max-hum)
        (map-set container-alerts
          { container-id: container-id }
          { alerts: (unwrap! (as-max-len? (append
              (get alerts current-alerts)
              {
                timestamp: timestamp,
                alert-type: "high-humidity",
                value: humidity,
                threshold: max-hum
              }
            ) u100) (err u3))
          }
        )
        true
      )

      ;; Check shock
      (if (> shock max-shk)
        (map-set container-alerts
          { container-id: container-id }
          { alerts: (unwrap! (as-max-len? (append
              (get alerts current-alerts)
              {
                timestamp: timestamp,
                alert-type: "high-shock",
                value: (to-int shock),
                threshold: (to-int max-shk)
              }
            ) u100) (err u3))
          }
        )
        true
      )

      (ok true)
    )
  )
)

;; Get container condition records
(define-read-only (get-container-conditions (container-id uint))
  (map-get? container-conditions { container-id: container-id })
)

;; Get container condition thresholds
(define-read-only (get-container-thresholds (container-id uint))
  (map-get? container-thresholds { container-id: container-id })
)

;; Get container alerts
(define-read-only (get-container-alerts (container-id uint))
  (map-get? container-alerts { container-id: container-id })
)

