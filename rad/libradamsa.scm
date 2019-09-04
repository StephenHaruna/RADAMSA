
(import 
   (owl base)
   (only (owl sys) peek-byte)
   (only (rad main) urandom-seed)
   (only (rad mutations) 
      mutators->mutator
      string->mutators default-mutations)
   (only (rad generators)
      rand-block-size))
       

(import 
   (only (owl syscall) library-exit)) ;; library call return/resume

;; todo: add a proper read primop
(define (read-memory-simple ptr len)
   (if (eq? len 0)
      #null
      (cons (peek-byte ptr)
         (read-memory-simple (+ ptr 1) (- len 1)))))

(define (read-memory source len)
   (if (string? source)
      (take (string->bytes source) len)
      (read-memory-simple source len)))

; (define (read-memory ptr len) (string->bytes "Hello <foo arg=42>"))
   
(define mutas 
   (lets ((rs mutas 
            (mutators->mutator 
               (seed->rands 42)
               (string->mutators default-mutations))))
      mutas))

(define (mutate-simple mutator byte-list seed)
   (lets
      ((mutator rs chunks meta
         (mutator
            (seed->rands seed)
            (list (list->bytevector byte-list))
            #empty)))
      (values
         mutator
         (foldr
            (λ (bvec out)
               (append (bytevector->list bvec) out))
            '()
            chunks))))
            
(define (fuzz muta)
   (λ (tuple-from-c)
      ;(print "-> radamsa: " tuple-from-c)
      (lets ((ptr len max seed tuple-from-c))
         (if (= len 0)
            ((fuzz muta)
               (library-exit (list (band seed #xff))))
            (lets
               ((rs (seed->rands seed))
                (input (read-memory ptr len))
                (muta output (mutate-simple muta input seed))
                ;(output (cons 10 input))
                ;(output '(42 42 42))
               )
               ;(print "<- output is " output)
               ((fuzz muta)
                  (library-exit output)))))))

(define (try entry)
   (let loop ((entry entry)
              (samples 
                 '("Hello <b>HAL</b> 9000" 
                   "Hello, world!" 
                   ))
              (n 1))
      (if (= n 100)
         12
         (lets 
            ((return entry
               (entry 
                  (tuple 
                     (car samples)
                     100
                     100
                     n))))
            (print n " -> " (list->string return))
            (loop entry (append (cdr samples) (list (car samples))) (+ n 1))))))

;; Entry test
;(define (wait arg)
;   (print "radamsa: i got something")
;   (wait (library-exit '(42 42 42))))
;wait

;; load-time test
; (try (fuzz mutas))

;; fasl test
; (λ (args) (try (fuzz mutas)))

;; C test
(fuzz mutas)


