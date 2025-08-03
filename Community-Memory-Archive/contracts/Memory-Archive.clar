;; Community Memory Archive Smart Contract
;; A decentralized archive for storing and preserving community memories and historical records

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))

;; Data Variables
(define-data-var next-memory-id uint u1)
(define-data-var archive-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var total-memories uint u0)
(define-data-var contract-balance uint u0)

;; Data Maps
(define-map memories
  { memory-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    content-hash: (string-ascii 64), ;; IPFS hash or similar
    category: (string-ascii 50),
    timestamp: uint,
    verification-count: uint,
    is-verified: bool,
    tags: (list 10 (string-ascii 20))
  }
)

(define-map memory-verifications
  { memory-id: uint, verifier: principal }
  { verified: bool, timestamp: uint }
)

(define-map user-profiles
  { user: principal }
  {
    username: (string-ascii 50),
    reputation: uint,
    memories-created: uint,
    verifications-made: uint,
    join-date: uint
  }
)

(define-map memory-comments
  { memory-id: uint, comment-id: uint }
  {
    commenter: principal,
    content: (string-ascii 300),
    timestamp: uint
  }
)

(define-map memory-comment-counts
  { memory-id: uint }
  { count: uint }
)

;; Read-only functions
(define-read-only (get-memory (memory-id uint))
  (map-get? memories { memory-id: memory-id })
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-memory-verification (memory-id uint) (verifier principal))
  (map-get? memory-verifications { memory-id: memory-id, verifier: verifier })
)

(define-read-only (get-memory-comment (memory-id uint) (comment-id uint))
  (map-get? memory-comments { memory-id: memory-id, comment-id: comment-id })
)

(define-read-only (get-memory-comment-count (memory-id uint))
  (default-to { count: u0 } (map-get? memory-comment-counts { memory-id: memory-id }))
)

(define-read-only (get-total-memories)
  (var-get total-memories)
)

(define-read-only (get-archive-fee)
  (var-get archive-fee)
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

(define-read-only (get-next-memory-id)
  (var-get next-memory-id)
)

;; Private functions
(define-private (is-valid-string (str (string-ascii 500)))
  (> (len str) u0)
)

(define-private (increment-user-reputation (user principal) (amount uint))
  (let ((current-profile (default-to 
    { username: "", reputation: u0, memories-created: u0, verifications-made: u0, join-date: block-height }
    (map-get? user-profiles { user: user }))))
    (map-set user-profiles { user: user }
      (merge current-profile { reputation: (+ (get reputation current-profile) amount) }))
  )
)

;; Public functions
(define-public (create-user-profile (username (string-ascii 50)))
  (let ((caller tx-sender))
    (asserts! (is-valid-string username) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? user-profiles { user: caller })) ERR-ALREADY-EXISTS)
    (ok (map-set user-profiles { user: caller }
      {
        username: username,
        reputation: u0,
        memories-created: u0,
        verifications-made: u0,
        join-date: block-height
      }))
  )
)

(define-public (submit-memory 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (content-hash (string-ascii 64))
  (category (string-ascii 50))
  (tags (list 10 (string-ascii 20))))
  (let ((memory-id (var-get next-memory-id))
        (caller tx-sender)
        (fee (var-get archive-fee)))
    (asserts! (is-valid-string title) ERR-INVALID-INPUT)
    (asserts! (is-valid-string description) ERR-INVALID-INPUT)
    (asserts! (is-valid-string content-hash) ERR-INVALID-INPUT)
    (asserts! (is-valid-string category) ERR-INVALID-INPUT)
    (asserts! (>= (stx-get-balance caller) fee) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer fee to contract
    (try! (stx-transfer? fee caller (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) fee))
    
    ;; Create memory record
    (map-set memories { memory-id: memory-id }
      {
        creator: caller,
        title: title,
        description: description,
        content-hash: content-hash,
        category: category,
        timestamp: block-height,
        verification-count: u0,
        is-verified: false,
        tags: tags
      })
    
    ;; Update counters
    (var-set next-memory-id (+ memory-id u1))
    (var-set total-memories (+ (var-get total-memories) u1))
    
    ;; Update user profile
    (let ((current-profile (default-to 
      { username: "", reputation: u0, memories-created: u0, verifications-made: u0, join-date: block-height }
      (map-get? user-profiles { user: caller }))))
      (map-set user-profiles { user: caller }
        (merge current-profile { 
          memories-created: (+ (get memories-created current-profile) u1),
          reputation: (+ (get reputation current-profile) u10)
        })))
    
    (ok memory-id)
  )
)

(define-public (verify-memory (memory-id uint))
  (let ((caller tx-sender)
        (memory-data (unwrap! (map-get? memories { memory-id: memory-id }) ERR-NOT-FOUND)))
    (asserts! (not (is-eq caller (get creator memory-data))) ERR-UNAUTHORIZED)
    (asserts! (is-none (map-get? memory-verifications { memory-id: memory-id, verifier: caller })) ERR-ALREADY-EXISTS)
    
    ;; Record verification
    (map-set memory-verifications { memory-id: memory-id, verifier: caller }
      { verified: true, timestamp: block-height })
    
    ;; Update memory verification count
    (let ((new-count (+ (get verification-count memory-data) u1)))
      (map-set memories { memory-id: memory-id }
        (merge memory-data { 
          verification-count: new-count,
          is-verified: (>= new-count u3) ;; Verified after 3 confirmations
        })))
    
    ;; Update verifier profile
    (let ((current-profile (default-to 
      { username: "", reputation: u0, memories-created: u0, verifications-made: u0, join-date: block-height }
      (map-get? user-profiles { user: caller }))))
      (map-set user-profiles { user: caller }
        (merge current-profile { 
          verifications-made: (+ (get verifications-made current-profile) u1),
          reputation: (+ (get reputation current-profile) u5)
        })))
    
    ;; Reward memory creator if verified
    (if (>= (+ (get verification-count memory-data) u1) u3)
      (increment-user-reputation (get creator memory-data) u20)
      true)
    
    (ok true)
  )
)

(define-public (add-comment (memory-id uint) (content (string-ascii 300)))
  (let ((caller tx-sender)
        (memory-data (unwrap! (map-get? memories { memory-id: memory-id }) ERR-NOT-FOUND))
        (comment-count (get count (get-memory-comment-count memory-id)))
        (new-comment-id (+ comment-count u1)))
    (asserts! (is-valid-string content) ERR-INVALID-INPUT)
    
    ;; Add comment
    (map-set memory-comments { memory-id: memory-id, comment-id: new-comment-id }
      {
        commenter: caller,
        content: content,
        timestamp: block-height
      })
    
    ;; Update comment count
    (map-set memory-comment-counts { memory-id: memory-id }
      { count: new-comment-id })
    
    ;; Small reputation boost for engagement
    (increment-user-reputation caller u2)
    
    (ok new-comment-id)
  )
)

(define-public (update-archive-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set archive-fee new-fee)
    (ok true)
  )
)

(define-public (withdraw-funds (amount uint) (recipient principal))
  (let ((current-balance (var-get contract-balance)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (<= amount current-balance) ERR-INSUFFICIENT-BALANCE)
    (try! (as-contract (stx-transfer? amount tx-sender recipient)))
    (var-set contract-balance (- current-balance amount))
    (ok true)
  )
)