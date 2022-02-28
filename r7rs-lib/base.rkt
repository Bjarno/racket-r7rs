#lang racket/base

(require racket/contract
         racket/require
         racket/shared
         (for-syntax (for-syntax racket/base
                                 syntax/parse)
                     (except-in racket/base syntax-rules)
                     racket/syntax
                     syntax/parse
                     (prefix-in reader: "lang/reader.rkt")
                     (prefix-in 7: "private/syntax-rules.rkt"))
         (prefix-in r: (multi-in racket (base include math vector)))
         (prefix-in 5: r5rs)
         (prefix-in 6: (multi-in rnrs (base-6 bytevectors-6 control-6 exceptions-6 io/ports-6)))
         (prefix-in 7: (multi-in "private" ("bytevector.rkt" "case.rkt" "cond-expand.rkt"
                                            "define-values.rkt" "exception.rkt" "list.rkt" "math.rkt"
                                            "quote.rkt" "record.rkt" "string.rkt" "strip-prefix.rkt"
                                            "vector.rkt"))))

(provide
 (7:strip-colon-prefix-out
  (for-syntax 7:syntax-rules 7:_ 7:...)
  6:* 6:+ 6:- 6:/ 6:< 6:<= 6:= 6:=> 6:> 6:>= 6:abs 6:and 6:append 6:apply 7:assoc 5:assq 5:assv
  6:begin 6:binary-port? 6:boolean=? 6:boolean? 7:bytevector-copy
  6:bytevector-length 6:bytevector-u8-ref 6:bytevector-u8-set! 6:bytevector? 6:caar 6:cadr
  6:call-with-current-continuation 6:call-with-port 6:call-with-values 6:call/cc 6:car 7:case 6:cdar
  6:cddr 6:cdr 6:ceiling 6:char->integer 5:char-ready? 6:char<=? 6:char<? 6:char=? 6:char>=? 6:char>?
  6:char? 5:close-input-port 5:close-output-port 6:close-port 6:complex? 6:cond 7:cond-expand 6:cons
  r:current-error-port r:current-input-port r:current-output-port 6:define 7:define-record-type
  6:define-syntax 7:define-values 6:denominator 6:do 6:dynamic-wind 6:else 6:eof-object 6:eof-object?
  6:eq? 6:equal? 6:eqv? 7:error 7:error-object-irritants 7:error-object-message 7:error-object?
  6:even? 6:exact 6:exact-integer-sqrt r:exact-integer? 6:exact? 6:expt 7:features 6:floor
  7:floor-quotient 7:floor-remainder 7:floor/ 6:for-each 6:gcd r:get-output-string 6:guard 6:if
  include 6:inexact 6:inexact? input-port-open? 6:input-port? 6:integer->char 6:integer? 6:lambda
  6:lcm 6:length 6:let 6:let* 6:let*-values 6:let-syntax 6:let-values 6:letrec 6:letrec*
  6:letrec-syntax 6:list 6:list->string 6:list->vector 7:list-copy 6:list-ref 7:list-set! 6:list-tail
  6:list? 6:make-bytevector 7:make-list r:make-parameter 6:make-string 6:make-vector 7:map 6:max
  7:member 5:memq 5:memv 5:min 5:modulo 6:negative? 5:newline 6:not 6:null? 6:number->string 6:number?
  6:numerator 6:odd? 7:open-output-string 6:or 6:output-port? output-port-open? 6:pair? r:parameterize
  5:peek-char 6:port? 6:positive? 6:procedure? 6:quasiquote 7:quote 5:quotient 6:raise
  6:raise-continuable 6:rational? 6:rationalize 5:read-char r:read-line r:read-string 6:real?
  5:remainder 6:reverse 6:round 6:set! 5:set-car! 5:set-cdr! 6:string 7:string->list 6:string->number
  6:string->symbol 7:string->utf8 7:string->vector 6:string-append 7:string-copy r:string-copy!
  7:string-fill! 6:string-for-each 6:string-length 7:string-map 6:string-ref 5:string-set! 6:string<=?
  6:string<? 6:string=? 6:string>=? 6:string>? 6:string? 6:substring 6:symbol->string 6:symbol=?
  6:symbol? syntax-error 6:textual-port? 6:truncate 7:truncate-quotient 7:truncate-remainder
  7:truncate/ 6:unless 6:unquote 6:unquote-splicing 7:utf8->string 6:values 6:vector 7:vector->list
  7:vector->string r:vector-append r:vector-copy r:vector-copy! 7:vector-fill! 6:vector-for-each
  6:vector-length 7:vector-map 6:vector-ref 6:vector-set! 6:vector? 6:when 6:with-exception-handler
  5:write-char r:write-string 6:zero?)
 (rename-out [r:bytes bytevector]
             [r:bytes-append bytevector-append]
             [r:bytes-copy! bytevector-copy!]
             [r:get-output-bytes get-output-bytevector]
             [r:exn:fail:filesystem? file-error?]
             [r:flush-output flush-output-port]
             [r:exn:fail:read? read-error?]
             [r:open-input-bytes open-input-bytevector]
             [6:open-string-input-port open-input-string]
             [r:open-output-bytes open-output-bytevector]
             [r:peek-byte peek-u8]
             [r:read-bytes read-bytevector]
             [r:read-bytes! read-bytevector!]
             [r:read-byte read-u8]
             [r:sqr square]
             [r:byte-ready? u8-ready?]
             [r:write-bytes write-bytevector]
             [r:write-byte write-u8]))

(define-for-syntax (read-r7rs-syntax src in)
  (reader:r7rs-parameterize-read
   (λ () (read-syntax src in))))

(define-syntax (include stx)
  (syntax-parse stx
    [(_ str ...+)
     ; make sure each include form has the right lexical context
     (define/with-syntax (inc ...)
       (for/list ([path (in-list (attribute str))])
         (datum->syntax stx (list #'r:include/reader path #'read-r7rs-syntax) stx)))
     #'(begin inc ...)]))

(define/contract (input-port-open? port)
  (input-port? . -> . boolean?)
  (not (port-closed? port)))

(define (7:open-output-string)
  (let-values ([(port extract) (6:open-string-output-port)])
    port))

(define/contract (output-port-open? port)
  (output-port? . -> . boolean?)
  (not (port-closed? port)))

(define-syntax syntax-error
  (syntax-parser
    [(_ message:str args ...)
     (apply error (syntax->datum #'message)
            (syntax->datum #'(args ...)))]))
