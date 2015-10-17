#lang racket/base

;; TODO
;; 1) spin up a thread to send to IRC - main program writes to thread mailbox

;; 2) use sync/timeout for listening and timeout after N seconds, where N
;;    > than the time between pings from IRC

;; ircbot.rkt
;;
;; Simple IRC bot

; Copyright (c) 2015 Brian Adkins
; MIT License: http://opensource.org/licenses/MIT
; Permission is hereby granted, free of charge, to any person obtaining
; a copy of this software and associated documentation files (the
; "Software"), to deal in the Software without restriction, including
; without limitation the rights to use, copy, modify, merge, publish,
; distribute, sublicense, and/or sell copies of the Software, and to
; permit persons to whom the Software is furnished to do so, subject to
; the following conditions:
; The above copyright notice and this permission notice shall be
; included in all copies or substantial portions of the Software.
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

; https://tools.ietf.org/html/rfc2812

;  :badkins!~badkins@adsl-070-154-097-089.sip.rmo.bellsouth.net PRIVMSG #GospelSoftware :command
;  :badkins!~badkins@adsl-070-154-097-089.sip.rmo.bellsouth.net PRIVMSG RacketBot8 :this is a direct msg
;  PING :hobana.freenode.net
;  :badkins!~badkins@adsl-070-154-097-089.sip.rmo.bellsouth.net PRIVMSG #GospelSoftware :!uptime
;  :badkins!~badkins@cpe-107-15-212-104.nc.res.rr.com PART ##trinomad
;  :badkins!~badkins@cpe-107-15-212-104.nc.res.rr.com JOIN ##trinomad
;  :atomgian_!~atomgiant@2606:a000:4422:de00:c98b:4fcf:3be9:efc0 NICK :atomgiant

(require racket/tcp)
(require racket/string)
(require racket/match)
(require racket/format)
(require racket/date)

(define chan            "#GospelSoftware")
;(define chan            "##trinomad")
;(define histfile        "/home/deploy/vmls/current/public/trinomad.html")
(define histfile        "trinomad.html")
(define logfile         "ircbot.log")
(define nick            "RacketBot1c")
(define port            6667)
(define server          "irc.freenode.org")
(define start-seconds   (current-seconds))
(define current-version "0.0.2")

(struct context (c-in c-out hist-out log-out))

; Start the bot
(define (run)
  (let-values ([(c-in c-out) (connect server port)])
    (let* ([hist-out (open-output-file histfile #:exists 'append)]
           [log-out (open-output-file logfile #:exists 'append)]
           [context (context c-in c-out hist-out log-out)])
      (prolog context)
      (listen context))))

; Connect to IRC host
(define (connect host port)
  (let-values ([(c-in c-out) (tcp-connect host port)])
    (file-stream-buffer-mode c-out 'line)
    (values c-in c-out)))

(define (prolog context)
  (write context (format "NICK ~a" nick))
  (write context (format "USER ~a 0 * :tutorial bot" nick))
  (write context (format "JOIN ~a" chan))
  (write context (format "PRIVMSG ~a :started" chan))
  (log context "RacketBot started"))
  
; Main bot loop
(define (listen context)
  (let ([line (read-line (context-c-in context))])
    (cond [(eof-object? line) '()]
          [else (handle-line context line)
                (listen context)])))

(define (handle-line context line)
  (dispatch context (string-split line))
  (log context line))

(define (dispatch context terms)
  (match terms
    [ (list "PING" host)
      (pong context host) ]
    [ (list user "PRIVMSG" (== chan) ":!uptime")
      (uptime context user) ]
    [ (list user "PRIVMSG" (== chan) ":!version")
      (version context user) ]
    [ (list user "PRIVMSG" (== chan) ":!private" _ ...)
      '() ]
    [ (list-rest user "PRIVMSG" (== chan) msg)
      (message context user msg) ]
    [ _
      '() ]))

; Support Functions

(define (format-username user)
  (define result (regexp-match #rx"^:([^!]+)!" user))
  (if (= 2 (length result))
      (cadr result)
      user))

(define (hist context user message)
  (define username (format-username user)) 
  (write-log (context-hist-out context) 
             (format "~a ~a ~a."
                     (date->string (current-date) #t)
                     username
                     message)))

(define (log context message)
  (write-log (context-log-out context) message))

(define (write-log out message)
  (fprintf out "~a\n" message)
  (flush-output out))

; Write message to IRC host
(define (write context msg)
  (fprintf (context-c-out context) "~a\r\n" msg))

;; Commands

(define (message context user msg-terms)
  (hist context user (string-join msg-terms)))

; Respond to IRC PING command with PONG
(define (pong context host)
  (write context (format "PONG ~a" host)))

; Report the uptime of the IRC bot in hours
(define (uptime context user)
  (let* ([secs  (- (current-seconds) start-seconds)]
         [hours (/ secs 3600.0)]
         [msg   (format ":uptime ~a hours" (~r hours #:precision '(= 2)))])
    (write context (format "PRIVMSG ~a ~a" chan msg))
    (hist context user msg)))

(define (version context user)
  (define version-string (format ":version = ~a" current-version))
  (write context (format "PRIVMSG ~a ~a" chan version-string))
  (hist context user version-string))

; Main Module

(module* main #f
  (run))
