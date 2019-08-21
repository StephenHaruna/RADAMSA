
(import 
   (owl base)
   (only (owl sys) peek-byte)
   (only (rad mutations) string->mutators default-mutations))

;; dummy for lisp only test
; (define (peek-byte ptr) 42)

(define (read-memory ptr len)
   (if (eq? len 0)
      #null
      (cons (peek-byte ptr)
         (read-memory (+ ptr 1) (- len 1)))))

(define (fuzz state)
   (λ (tuple-from-c)
      (lets ((ptr len max seed tuple-from-c))
         (if (= len 0)
            (list (band seed #xff))
            (lets
               ((rs (seed->rands seed))
                (input (read-memory ptr len))
                (rs modify-pos (rand rs len))
                (rs modify-delta (rand rs 256))
                (output 
                  (led input modify-pos
                     (λ (x) (band #xff (+ x modify-delta))))))
               (values
                  output
                  (fuzz state)))))))

(define (try entry)
   (lets 
      ((return state 
         (entry 
            (tuple 
               31337
               8 
               8
               42))))
      (print return)))

;(try (fuzz 0))

(fuzz 'not-used-atm)



