;; Retention Strategy Contract
;; Develops and manages customer retention strategies

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_STRATEGY_NOT_FOUND (err u401))
(define-constant ERR_INVALID_CUSTOMER (err u402))

;; Data structures
(define-map retention-strategies
  { strategy-id: (string-ascii 30) }
  {
    strategy-name: (string-ascii 50),
    target-segment: (string-ascii 20),
    intervention-type: (string-ascii 30),
    expected-improvement: uint,
    cost-per-customer: uint,
    active: bool,
    created-date: uint
  }
)

(define-map customer-interventions
  { customer-id: (string-ascii 50) }
  {
    strategy-applied: (string-ascii 30),
    intervention-date: uint,
    pre-retention-score: uint,
    post-retention-score: uint,
    success: bool
  }
)

(define-map strategy-performance
  { strategy-id: (string-ascii 30) }
  {
    customers-targeted: uint,
    successful-retentions: uint,
    total-cost: uint,
    roi: uint,
    effectiveness-rate: uint
  }
)

;; Initialize default strategies
(map-set retention-strategies
  { strategy-id: "discount-offer" }
  {
    strategy-name: "Personalized Discount Offer",
    target-segment: "medium-value",
    intervention-type: "promotional",
    expected-improvement: u25,
    cost-per-customer: u50,
    active: true,
    created-date: block-height
  }
)

(map-set retention-strategies
  { strategy-id: "loyalty-program" }
  {
    strategy-name: "VIP Loyalty Program",
    target-segment: "high-value",
    intervention-type: "engagement",
    expected-improvement: u35,
    cost-per-customer: u100,
    active: true,
    created-date: block-height
  }
)

;; Public functions
(define-public (create-retention-strategy
  (strategy-id (string-ascii 30))
  (strategy-name (string-ascii 50))
  (target-segment (string-ascii 20))
  (intervention-type (string-ascii 30))
  (expected-improvement uint)
  (cost-per-customer uint)
)
  (begin
    (map-set retention-strategies
      { strategy-id: strategy-id }
      {
        strategy-name: strategy-name,
        target-segment: target-segment,
        intervention-type: intervention-type,
        expected-improvement: expected-improvement,
        cost-per-customer: cost-per-customer,
        active: true,
        created-date: block-height
      }
    )
    (map-set strategy-performance
      { strategy-id: strategy-id }
      {
        customers-targeted: u0,
        successful-retentions: u0,
        total-cost: u0,
        roi: u0,
        effectiveness-rate: u0
      }
    )
    (ok true)
  )
)

(define-public (apply-retention-strategy
  (customer-id (string-ascii 50))
  (strategy-id (string-ascii 30))
  (pre-retention-score uint)
)
  (let (
    (strategy (unwrap! (map-get? retention-strategies { strategy-id: strategy-id }) ERR_STRATEGY_NOT_FOUND))
    (current-performance (unwrap! (map-get? strategy-performance { strategy-id: strategy-id }) ERR_STRATEGY_NOT_FOUND))
  )
    (map-set customer-interventions
      { customer-id: customer-id }
      {
        strategy-applied: strategy-id,
        intervention-date: block-height,
        pre-retention-score: pre-retention-score,
        post-retention-score: u0,
        success: false
      }
    )
    (map-set strategy-performance
      { strategy-id: strategy-id }
      {
        customers-targeted: (+ (get customers-targeted current-performance) u1),
        successful-retentions: (get successful-retentions current-performance),
        total-cost: (+ (get total-cost current-performance) (get cost-per-customer strategy)),
        roi: (get roi current-performance),
        effectiveness-rate: (get effectiveness-rate current-performance)
      }
    )
    (ok true)
  )
)

(define-public (update-intervention-result
  (customer-id (string-ascii 50))
  (post-retention-score uint)
  (success bool)
)
  (let (
    (intervention (unwrap! (map-get? customer-interventions { customer-id: customer-id }) ERR_INVALID_CUSTOMER))
    (strategy-id (get strategy-applied intervention))
    (current-performance (unwrap! (map-get? strategy-performance { strategy-id: strategy-id }) ERR_STRATEGY_NOT_FOUND))
    (new-successful (if success (+ (get successful-retentions current-performance) u1) (get successful-retentions current-performance)))
    (new-effectiveness (/ (* new-successful u100) (get customers-targeted current-performance)))
  )
    (map-set customer-interventions
      { customer-id: customer-id }
      (merge intervention {
        post-retention-score: post-retention-score,
        success: success
      })
    )
    (map-set strategy-performance
      { strategy-id: strategy-id }
      (merge current-performance {
        successful-retentions: new-successful,
        effectiveness-rate: new-effectiveness
      })
    )
    (ok new-effectiveness)
  )
)

;; Read-only functions
(define-read-only (get-retention-strategy (strategy-id (string-ascii 30)))
  (map-get? retention-strategies { strategy-id: strategy-id })
)

(define-read-only (get-customer-intervention (customer-id (string-ascii 50)))
  (map-get? customer-interventions { customer-id: customer-id })
)

(define-read-only (get-strategy-performance (strategy-id (string-ascii 30)))
  (map-get? strategy-performance { strategy-id: strategy-id })
)
