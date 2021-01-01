#lang racket

;; Hash of dictionary words
(define dict (for/hash ([ word (file->lines "./dictionary.txt") ])
               (values word #t)))

;; (password-strength username password dictionary-word?) -> (cons symbol? (or/c string? #f))
;; username : string?
;; password : string?
;; dictionary-word? : (string? -> boolean?)
;;
;; Returns two values, a symbol indicating the strength of the
;; password, and an optional error message which will be #f if no
;; error message.
(define (password-strength username password dictionary-word?)
  (let* ([ bits          (entropy-bits password)                                    ]
         [ error-message (failed-password? username password bits dictionary-word?) ])
    (if error-message
        (cons 'fail error-message)
        (cons (cond [ (< bits 66)  'weak   ]
                    [ (< bits 99)  'fair   ]
                    [ (< bits 132) 'good   ]
                    [ else         'strong ])
              #f))))

;; (character-set-size str) -> exact-integer?
;; str : string?
;;
;; Returns the character set size for a string.
;;
;; This function, while much longer, is more than 10x faster than
;; repeated regexp-match calls.
(define (character-set-size str)
  (let ([ len (string-length str) ])
    (let loop ([ i 0 ][ digits #f ][ lower #f ][ upper #f ][ sym #f ])
      (if (or (>= i len) (and digits lower upper sym))
          (+ (if digits 10 0)
             (if lower  26 0)
             (if upper  26 0)
             (if sym    32 0))
          (let ([ c (string-ref str i) ]
                [ i (add1 i)           ])
            (cond [ (char-lower-case? c) (loop i digits #t upper sym)    ]
                  [ (char-upper-case? c) (loop i digits lower #t sym)    ]
                  [ (char-numeric? c)    (loop i #t lower upper sym)     ]
                  [ (char-whitespace? c) (loop i digits lower upper sym) ]
                  [ else                 (loop i digits lower upper #t)  ]))))))

;; (entropy-bits str) -> exact-integer?
;; str : string?
;;
;; Returns the number of bits required to represent the specified
;; string.
(define (entropy-bits str)
  (inexact->exact (ceiling (* (string-length str)
                              (log (character-set-size str) 2)))))

;; (failed-password? username password bits) -> (or/c string? #f)
;; username : string?
;; password : string?
;; bits : exact-integer?
;; dictionary-word? : (string? -> boolean?)
;;
;; Returns either an error string for a failed password, or #f for a
;; valid password.
(define (failed-password? username password bits dictionary-word?)
  (let ([ user (string-downcase username) ]
        [ pswd (string-downcase password) ])
    ;; Helper functions -----------------------------------------------------------------------
    (define (check-entropy) ; Must have at least 48 entropy bits
      (if (< bits 48)
          (format "Entropy bits (~a) < 48" bits)
          #f))

    (define (check-username) ; May not contain the username (irrespective of case)
      (if (string-contains? pswd user)
          (format "Contains username (~a)" username)
          #f))

    (define (check-dictionary) ; May not contain any dictionary words of length 3+
      (let loop ([ words (sub-words pswd 3) ][ dwords '() ])
        (if (null? words)
            (if (null? dwords)
                #f
                (format "Contains dictionary words: ~a"
                        (string-join (sort dwords string<?) ", ")))
            (loop (cdr words)
                  (let ([ word (car words) ])
                    (if (dictionary-word? word)
                        (cons word dwords)
                        dwords))))))
    ;; ----------------------------------------------------------------------------------------

  (let ([ errors (filter identity (list (check-entropy)
                                        (check-username)
                                        (check-dictionary))) ])
    (if (null? errors)
        #f
        (string-join errors "; ")))))

;; (sub-words str n) -> (listof? string?)
;; str : string?
;; n : exact-integer?
;;
;; Returns a list of all subwords within str that are at least n
;; characters long.
(define (sub-words str n)
  ;; Removing non alpha characters greatly reduces the number of
  ;; subwords we need to check!
  (let* ([ str (string-replace str #px"[^A-Za-z]+" "") ]
         [ len (string-length str) ])
    (for*/list ([ beg (in-range 0 (add1 (- len n))) ]
                [ end (in-range (+ beg n) (add1 len)) ])
      (substring str beg end))))

;; Benchmark
(time
 (let ([ lookup? (λ (word) (hash-ref dict word #f)) ])
   (let loop ([n 100000])
     (when (> n 0)
       (password-strength "jsmith" "aKwirkdcICOYuHd03iDcje>ZzVAG}T" lookup?)
       (loop (sub1 n))))))

;; --------------------------------------------------------------------------------------------
;; Tests
;; --------------------------------------------------------------------------------------------

(module+ test
  (require rackunit)

  ;; password-strength ------------------------------------------------------------------------
  (let ([ lookup? (λ (word) (hash-ref dict word #f)) ])

    (check-equal? (password-strength "jsmith" "Pswd1" lookup?)
                  (cons 'fail "Entropy bits (30) < 48"))

    (check-equal? (password-strength "jsmith" "FgKMsFqEjsmithZ4UIMw7pkmT4e4" lookup?)
                  (cons 'fail "Contains username (jsmith); Contains dictionary words: mit, smit, smith"))

    (check-equal? (password-strength "jsmith" "abate" lookup?)
                  (cons 'fail "Entropy bits (24) < 48; Contains dictionary words: abate, ate, bat, bate"))

    (check-equal? (password-strength "jsmith" "a4df8az2wq" lookup?)
                  (cons 'weak #f))

    (check-equal? (password-strength "jsmith" "A4dF8aZ2wQ5" lookup?)
                  (cons 'fair #f))

    (check-equal? (password-strength "jsmith" "Ab@hY#iU*qw!fv$z" lookup?)
                  (cons 'good #f))

    (check-equal? (password-strength "jsmith" "!1Qa@2Ws#3Ed$4Rf%5Tg" lookup?)
                  (cons 'strong #f))
    )

  ;; character-set-size -----------------------------------------------------------------------
  (check-equal? (character-set-size "34") 10)
  (check-equal? (character-set-size "ab") 26)
  (check-equal? (character-set-size "AB") 26)
  (check-equal? (character-set-size "@#") 32)
  (check-equal? (character-set-size "3a") 36)
  (check-equal? (character-set-size "3Z") 36)
  (check-equal? (character-set-size "3@") 42)
  (check-equal? (character-set-size "Aa") 52)
  (check-equal? (character-set-size "A^") 58)
  (check-equal? (character-set-size "a^") 58)
  (check-equal? (character-set-size "Aa7") 62)
  (check-equal? (character-set-size "3a&") 68)
  (check-equal? (character-set-size "3A&") 68)
  (check-equal? (character-set-size "aA%") 84)
  (check-equal? (character-set-size "1aA!") 94)

  ;; dictionary -------------------------------------------------------------------------------
  (check-not-false (hash-ref dict "abate" #f))
  (check-false (hash-ref dict "qwertyasdf" #f))

  ;; entropy-bits -----------------------------------------------------------------------------
  (check-equal? (character-set-size "Open-Sesame") 84)
  (check-equal? (entropy-bits "Open-Sesame") 71)

  ;; failed-password? -------------------------------------------------------------------------
  (let ([ lookup? (λ (word) (hash-ref dict word #f)) ])
    (let ([ pswd "Pswd1" ])
      (check-equal? (failed-password? "jsmith" pswd (entropy-bits pswd) lookup?)
                    "Entropy bits (30) < 48"))

    (let ([ pswd "FgKMsFqEjsmithZ4UIMw7pkmT4e4" ])
      (check-equal? (failed-password? "jsmith" pswd (entropy-bits pswd) lookup?)
                    "Contains username (jsmith); Contains dictionary words: mit, smit, smith"))

    (let ([ pswd "abate" ])
      (check-equal? (failed-password? "jsmith" pswd (entropy-bits pswd) lookup?)
                    "Entropy bits (24) < 48; Contains dictionary words: abate, ate, bat, bate")))

  ;; sub-words --------------------------------------------------------------------------------
  (for ([ pair (in-list '( (("abc" 3) ("abc"))
                           (("abc" 2) ("ab" "abc" "bc"))
                           (("abcde" 3) ("abc" "abcd" "abcde" "bcd" "bcde" "cde"))
                           (("abc" 4) ()))) ])
    (check-equal? (apply sub-words (first pair)) (second pair)))
  )
