;; BitVault Pro: Next-Generation Bitcoin-Backed Stablecoin Infrastructure
;; 
;; Title: BitVault Pro - Decentralized Bitcoin Collateral Management System
;;
;; Summary: 
;; A sophisticated DeFi protocol that enables Bitcoin holders to unlock liquidity by minting
;; USD-pegged stablecoins against their BTC collateral while maintaining bitcoin exposure.
;;
;; Description:
;; BitVault Pro revolutionizes Bitcoin utility by creating a secure bridge between HODLing
;; and active DeFi participation. Through intelligent collateral management and real-time
;; risk assessment, users can generate sustainable yield from their Bitcoin holdings without
;; selling their position. The protocol implements advanced liquidation protection,
;; automated interest calculations, and oracle-powered price feeds to ensure system stability.

;; SYSTEM ERROR DEFINITIONS & PROTOCOL CONSTANTS

;; Core System Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1001))
(define-constant ERR-POSITION-NOT-FOUND (err u1002))
(define-constant ERR-UNDERCOLLATERALIZED (err u1003))
(define-constant ERR-MINIMUM-LOAN-REQUIRED (err u1004))
(define-constant ERR-INSUFFICIENT-DEBT (err u1005))
(define-constant ERR-PRICE-EXPIRED (err u1006))
(define-constant ERR-PROTOCOL-PAUSED (err u1007))
(define-constant ERR-INVALID-AMOUNT (err u1008))
(define-constant ERR-NO-PRICE-DATA (err u1009))

;; Protocol Risk Management Parameters
(define-constant COLLATERAL-RATIO u150)           ;; 150% minimum collateralization ratio
(define-constant LIQUIDATION-THRESHOLD u120)      ;; 120% liquidation trigger threshold
(define-constant LIQUIDATION-PENALTY u10)         ;; 10% liquidation penalty fee
(define-constant MINIMUM_LOAN_AMOUNT u100000000)  ;; 100 BVLT minimum loan (8 decimals)
(define-constant PRICE_EXPIRY u86400)             ;; 24-hour price feed validity period
(define-constant INTEREST_RATE_PER_BLOCK u5)      ;; 0.0005% per block interest rate
(define-constant INTEREST_RATE_DENOMINATOR u1000000) ;; Interest calculation precision

;; PROTOCOL STATE MANAGEMENT & DATA STRUCTURES  

;; Administrative Control Variables
(define-data-var protocol-owner principal tx-sender)
(define-data-var protocol-paused bool false)

;; Global Protocol Metrics Tracking
(define-data-var total-debt uint u0)              ;; Total outstanding BVLT debt
(define-data-var total-collateral uint u0)        ;; Total locked BTC collateral
(define-data-var stability-fee uint u0)           ;; Accumulated protocol fees
(define-data-var last-accrual-block uint stacks-block-height) ;; Last interest update block

;; Oracle Price Feed Management
(define-data-var btc-price-in-usd (optional {price: uint, timestamp: uint}) none)
(define-data-var current-time uint u0)            ;; Testing environment timestamp

;; User Collateral Position Mapping
(define-map positions principal {
  collateral: uint,        ;; BTC collateral amount in satoshis
  debt: uint,             ;; Outstanding BVLT debt amount
  last-update-block: uint ;; Last position interest update block
})

;; BitVault Liquid Token (BVLT) - USD-Pegged Stablecoin
(define-fungible-token bitvault-token)

;; PROTOCOL ADMINISTRATION & GOVERNANCE FUNCTIONS

;; Transfer protocol ownership with authorization check
(define-public (set-protocol-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-owner new-owner))
  )
)

;; Emergency protocol pause mechanism for crisis management
(define-public (pause-protocol (paused bool))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-paused paused))
  )
)

;; Oracle price feed update from authorized source
(define-public (update-btc-price (price uint) (timestamp uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-AMOUNT)
    (var-set btc-price-in-usd (some {price: price, timestamp: timestamp}))
    (ok true)
  )
)

;; Development environment timestamp control
(define-public (set-current-time (time uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set current-time time))
  )
)

;; MATHEMATICAL UTILITIES & RISK CALCULATION FUNCTIONS

;; Calculate USD value of BTC collateral at current price
(define-private (collateral-value (collateral-amount uint) (price uint))
  (* collateral-amount price)
)

;; Determine minimum BTC collateral required for debt position
(define-private (required-collateral (debt-amount uint) (price uint))
  (/ (* debt-amount COLLATERAL-RATIO) (/ price u100))
)

;; Assess position safety against liquidation threshold
(define-private (is-position-safe (user principal) (btc-price uint))
  (let (
    (position (unwrap! (map-get? positions user) false))
    (debt (get debt position))
    (collateral (get collateral position))
    (collateral-value-usd (collateral-value collateral btc-price))
    (min-collateral-value-usd (/ (* debt COLLATERAL-RATIO) u100))
  )
  (>= collateral-value-usd min-collateral-value-usd))
)

;; Calculate accrued interest for debt over block duration
(define-private (calculate-interest (debt uint) (blocks-passed uint))
  (/ (* debt (* blocks-passed INTEREST_RATE_PER_BLOCK)) INTEREST_RATE_DENOMINATOR)
)

;; Retrieve current BTC price with staleness validation
(define-read-only (get-current-price)
  (match (var-get btc-price-in-usd)
    price-data (let (
      (price (get price price-data))
      (timestamp (get timestamp price-data))
      (current-timestamp (var-get current-time))
    )
      (if (>= (- current-timestamp timestamp) PRICE_EXPIRY)
        ERR-PRICE-EXPIRED
        (if (<= price u0)
          ERR-PRICE-EXPIRED
          (ok price)
        )
      ))
    ERR-NO-PRICE-DATA)
)

;; AUTOMATED INTEREST ACCRUAL & DEBT MANAGEMENT SYSTEM

;; Update global protocol interest accumulation
(define-private (accrue-global-interest)
  (let (
    (current-block stacks-block-height)
    (last-block (var-get last-accrual-block))
    (blocks-passed (- current-block last-block))
    (total-system-debt (var-get total-debt))
    (interest-accrued (calculate-interest total-system-debt blocks-passed))
  )
    (begin
      (if (> blocks-passed u0)
        (begin
          (var-set stability-fee (+ (var-get stability-fee) interest-accrued))
          (var-set total-debt (+ total-system-debt interest-accrued))
          (var-set last-accrual-block current-block)
        )
        false
      )
      true
    )
  )
)

;; Update individual position with accrued interest
(define-private (accrue-position-interest (user principal))
  (let (
    (position (unwrap! (map-get? positions user) {debt: u0, collateral: u0, last-update-block: stacks-block-height}))
    (debt (get debt position))
    (collateral (get collateral position))
    (last-update (get last-update-block position))
    (blocks-passed (- stacks-block-height last-update))
    (interest-accrued (calculate-interest debt blocks-passed))
    (new-debt (+ debt interest-accrued))
    (updated-position {
      collateral: collateral,
      debt: new-debt,
      last-update-block: stacks-block-height
    })
  )
    (begin
      (if (> blocks-passed u0)
        (map-set positions user updated-position)
        false
      )
      updated-position
    )
  )
)

;; CORE USER INTERACTION FUNCTIONS - POSITION MANAGEMENT

;; Open new collateralized debt position or expand existing position
(define-public (open-position (btc-amount uint) (bvlt-amount uint))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
    (asserts! (>= btc-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= bvlt-amount MINIMUM_LOAN_AMOUNT) ERR-MINIMUM-LOAN-REQUIRED)
    
    ;; Validate current BTC price feed availability
    (let (
      (btc-price (try! (get-current-price)))
      (user tx-sender)
      (existing-position (map-get? positions user))
    )
      (begin
        ;; Execute global interest accrual update
        (accrue-global-interest)
        
        ;; Process existing position or initialize new position
        (let (
          (current-position 
            (if (is-some existing-position)
              (accrue-position-interest user)
              {collateral: u0, debt: u0, last-update-block: stacks-block-height}
            )
          )
        )
        
        ;; Calculate new position parameters after expansion
        (let (
          (old-collateral (get collateral current-position))
          (old-debt (get debt current-position))
          (new-collateral (+ old-collateral btc-amount))
          (new-debt (+ old-debt bvlt-amount))
          (min-required-collateral (required-collateral new-debt btc-price))
        )
          (begin
            ;; Enforce minimum collateralization requirements
            (asserts! (>= (collateral-value new-collateral btc-price) min-required-collateral) ERR-INSUFFICIENT-COLLATERAL)
            
            ;; Update user position record
            (map-set positions user {
              collateral: new-collateral,
              debt: new-debt,
              last-update-block: stacks-block-height
            })
            
            ;; Update global protocol accounting
            (var-set total-collateral (+ (var-get total-collateral) btc-amount))
            (var-set total-debt (+ (var-get total-debt) bvlt-amount))
            
            ;; Mint BVLT tokens to user wallet
            (ft-mint? bitvault-token bvlt-amount user)
          )
        ))
      )
    )
  )
)

;; Deposit additional BTC collateral to strengthen position
(define-public (deposit-collateral (btc-amount uint))
  (let (
    (user tx-sender)
    (position (unwrap! (map-get? positions user) ERR-POSITION-NOT-FOUND))
  )
    (begin
      (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
      (asserts! (> btc-amount u0) ERR-INVALID-AMOUNT)
      
      ;; Execute global interest accrual update
      (accrue-global-interest)
      
      ;; Update position with accumulated interest
      (let (
        (updated-position (accrue-position-interest user))
        (current-debt (get debt updated-position))
        (current-collateral (get collateral updated-position))
        (new-collateral (+ current-collateral btc-amount))
      )
        (begin
          ;; Update position with additional collateral
          (map-set positions user {
            collateral: new-collateral,
            debt: current-debt,
            last-update-block: stacks-block-height
          })
          
          ;; Update global collateral tracking
          (var-set total-collateral (+ (var-get total-collateral) btc-amount))
          
          (ok true)
        )
      )
    )
  )
)

;; Repay BVLT debt to reduce position liability
(define-public (repay-debt (amount uint))
  (let (
    (user tx-sender)
    (position (unwrap! (map-get? positions user) ERR-POSITION-NOT-FOUND))
  )
    (begin
      (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
      (asserts! (> amount u0) ERR-INVALID-AMOUNT)
      
      ;; Execute global interest accrual update
      (accrue-global-interest)
      
      ;; Update position with accumulated interest
      (let (
        (updated-position (accrue-position-interest user))
        (current-debt (get debt updated-position))
        (collateral (get collateral updated-position))
        (repay-amount (if (> amount current-debt) current-debt amount))
        (new-debt (- current-debt repay-amount))
      )
        (begin
          (asserts! (<= repay-amount current-debt) ERR-INSUFFICIENT-DEBT)
          
          ;; Burn BVLT tokens from user balance
          (try! (ft-burn? bitvault-token repay-amount user))
          
          ;; Handle complete or partial debt repayment
          (if (is-eq new-debt u0)
            ;; Full repayment: close position and return collateral
            (begin
              (map-delete positions user)
              (var-set total-collateral (- (var-get total-collateral) collateral))
            )
            ;; Partial repayment: update position with reduced debt
            (map-set positions user {
              collateral: collateral,
              debt: new-debt,
              last-update-block: stacks-block-height
            })
          )
          
          ;; Update global debt tracking
          (var-set total-debt (- (var-get total-debt) repay-amount))
          
          (ok true)
        )
      )
    )
  )
)

;; Withdraw BTC collateral while maintaining safe collateralization
(define-public (withdraw-collateral (btc-amount uint))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
    (asserts! (> btc-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Validate current BTC price feed availability
    (let (
      (btc-price (try! (get-current-price)))
      (user tx-sender)
    )
      (begin
        ;; Execute global interest accrual update
        (accrue-global-interest)
        
        ;; Update position with accumulated interest
        (let (
          (updated-position (accrue-position-interest user))
          (current-debt (get debt updated-position))
          (current-collateral (get collateral updated-position))
          (new-collateral (- current-collateral btc-amount))
          (min-required-collateral (required-collateral current-debt btc-price))
        )
          (begin
            (asserts! (<= btc-amount current-collateral) ERR-INSUFFICIENT-COLLATERAL)
            (asserts! (>= (collateral-value new-collateral btc-price) min-required-collateral) ERR-UNDERCOLLATERALIZED)
            
            ;; Update position with reduced collateral
            (map-set positions user {
              collateral: new-collateral,
              debt: current-debt,
              last-update-block: stacks-block-height
            })
            
            ;; Update global collateral tracking
            (var-set total-collateral (- (var-get total-collateral) btc-amount))
            
            (ok true)
          )
        )
      )
    )
  )
)

;; LIQUIDATION ENGINE - PROTOCOL SOLVENCY PROTECTION

;; Execute liquidation of undercollateralized position
(define-public (liquidate-position (target-user principal))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
    (let (
      (position (unwrap! (map-get? positions target-user) ERR-POSITION-NOT-FOUND))
      (liquidator tx-sender)
    )
      (begin
        (asserts! (not (is-eq target-user liquidator)) ERR-NOT-AUTHORIZED)
        
        ;; Validate current BTC price feed availability
        (let ((btc-price (try! (get-current-price))))
          (begin
            ;; Execute global interest accrual update
            (accrue-global-interest)
            
            ;; Update target position and verify liquidation eligibility
            (let (
              (updated-position (accrue-position-interest target-user))
              (debt (get debt updated-position))
              (collateral (get collateral updated-position))
              (collateral-value-usd (collateral-value collateral btc-price))
              (liquidation-threshold-value (/ (* debt LIQUIDATION-THRESHOLD) u100))
            )
              (begin
                ;; Verify position qualifies for liquidation
                (asserts! (< collateral-value-usd liquidation-threshold-value) ERR-NOT-AUTHORIZED)
                
                ;; Liquidator covers outstanding debt
                (try! (ft-burn? bitvault-token debt liquidator))
                
                ;; Calculate liquidation rewards and penalties
                (let (
                  (liquidation-bonus (/ (* collateral LIQUIDATION-PENALTY) u100))
                  (liquidator-reward (- collateral liquidation-bonus))
                )
                  (begin
                    ;; Update global protocol accounting
                    (var-set total-collateral (- (var-get total-collateral) collateral))
                    (var-set total-debt (- (var-get total-debt) debt))
                    
                    ;; Remove liquidated position from registry
                    (map-delete positions target-user)
                    
                    ;; Accumulate liquidation penalty as protocol revenue
                    (var-set stability-fee (+ (var-get stability-fee) liquidation-bonus))
                    
                    (ok true)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

;; READ-ONLY PROTOCOL QUERY & ANALYTICS FUNCTIONS

;; Retrieve detailed user position information
(define-read-only (get-user-position (user principal))
  (map-get? positions user)
)

;; Calculate current position collateralization ratio
(define-read-only (get-collateralization-ratio (user principal))
  (match (map-get? positions user)
    position (match (var-get btc-price-in-usd)
      price-data (let (
        (price (get price price-data))
        (collateral (get collateral position))
        (debt (get debt position))
      )
        (if (is-eq debt u0)
          none
          (some (/ (* (collateral-value collateral price) u100) debt))
        ))
      none)
    none)
)

;; Retrieve comprehensive protocol health metrics
(define-read-only (get-protocol-metrics)
  {
    total-debt: (var-get total-debt),
    total-collateral: (var-get total-collateral),
    stability-fee: (var-get stability-fee),
    protocol-paused: (var-get protocol-paused),
    btc-price: (var-get btc-price-in-usd),
    last-accrual-block: (var-get last-accrual-block)
  }
)

;; Check if position is eligible for liquidation
(define-read-only (is-liquidatable (user principal))
  (match (map-get? positions user)
    position (match (var-get btc-price-in-usd)
      price-data (let (
        (price (get price price-data))
        (collateral (get collateral position))
        (debt (get debt position))
        (collateral-value-usd (collateral-value collateral price))
        (liquidation-threshold-value (/ (* debt LIQUIDATION-THRESHOLD) u100))
      )
        (< collateral-value-usd liquidation-threshold-value))
      false)
    false)
)

;; PROTOCOL INITIALIZATION & DEPLOYMENT SETUP

;; Initialize protocol with deployer as initial administrator
(define-private (initialize-protocol)
  (var-set protocol-owner tx-sender)
)

;; Execute protocol initialization sequence
(initialize-protocol)