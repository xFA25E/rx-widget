;;; rx-widget.el --- Customize regexp widget with rx syntax  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Valeriy Litkovskyy

;; Author: Valeriy Litkovskyy <vlr.ltkvsk@protonmail.com>
;; Keywords: data
;; Version: 0.0.1
;; URL: https://github.com/xFA25E/rx-widget
;; Package-Requires: ((emacs "27.1") (xr "1.22"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'cl-lib)
(require 'cus-edit)
(require 'seq)
(require 'xr)

(defconst rx-widget-simple-patterns
  ;; PATTERN      TAG
  '((seq          "Sequence")
    (or           "Or")
    (zero-or-more "Zero or more (greedy)")
    (*?           "Zero or more (non-greedy)")
    (one-or-more  "One or more (greedy)")
    (+?           "One or more (non-greedy)")
    (opt          "Optional (greedy)")
    (??           "Optional (non-greedy)")
    (group        "Submatch"))
  "RX patterns with form: (PATTERN RX...).")

(defconst rx-widget-numeric-patterns
  ;; PATTERN TAG                      Ns
  '((=       "Repeat N times"         1)
    (>=      "Repeat N or more times" 1)
    (repeat  "Repeat N to M times"    2)
    (group-n "Submatch N"             1))
  "RX patterns with form (TAG N.. RX...).")

(defconst rx-widget-literal-patterns
  '(any syntax category not backref)
   "RX patterns that should not be converted back to external.")

(defconst rx-widget-character-classes
  '(alpha alnum digit xdigit cntrl blank space lower upper graph print punct)
  "RX character classes symbols.")

(defconst rx-widget-syntaxes
  '(whitespace punctuation word symbol open-parenthesis close-parenthesis
    expression-prefix string-quote paired-delimiter escape character-quote
    comment-start comment-end string-delimiter comment-delimiter)
  "RX syntaxes symbols.")

(defconst rx-widget-categories
  '(space-for-indent base consonant base-vowel upper-diacritical-mark
    lower-diacritical-mark tone-mark symbol digit
    vowel-modifying-diacritical-mark vowel-sign semivowel-lower
    not-at-end-of-line not-at-beginning-of-line alpha-numeric-two-byte
    chinese-two-byte greek-two-byte japanese-hiragana-two-byte indian-two-byte
    japanese-katakana-two-byte strong-left-to-right korean-hangul-two-byte
    strong-right-to-left cyrillic-two-byte combining-diacritic ascii arabic
    chinese ethiopic greek korean indian japanese japanese-katakana latin lao
    tibetan japanese-roman thai vietnamese hebrew cyrillic can-break)
  "RX categories symbols.")

(defconst rx-widget-symbols
  '(nonl anything unmatchable bol eol bos eos point bow eow word-boundary
    not-word-boundary symbol-start symbol-end)
  "RX various symbols.")

(defun rx-widget-regexp-opt (strings &optional paren)
  "Simplified version of `regexp-opt' without compression.
STRINGS and PAREN are the same as in `regexp-opt'"
  (let ((parens
         (cond ((stringp paren)       (cons paren "\\)"))
               ((eq paren 'words)    '("\\<\\(" . "\\)\\>"))
               ((eq paren 'symbols) '("\\_<\\(" . "\\)\\_>"))
               ((null paren)          '("\\(?:" . "\\)"))
               (t                       '("\\(" . "\\)")))))
    (concat (car parens) (mapconcat 'regexp-quote strings "\\|") (cdr parens))))

(defun rx-widget-rx-to-string (form)
  "Like `rx-to-string', but with simplified `regexp-opt'.
FORM is first argument for `rx-to-string'"
  (cl-letf (((symbol-function 'regexp-opt)
             (symbol-function 'rx-widget-regexp-opt)))
    (rx-to-string form t)))

(defun rx-widget-rxs-to-strings (rxs)
  "Convert RXS to strings using `rx-widget-rx-to-string'."
  (seq-map #'rx-widget-rx-to-string rxs))

(defun rx-widget-to-external (_widget value)
  "Convert WIDGET's internal VALUE to string."
  (rx-widget-rx-to-string value))

(defun rx-widget-to-internal (_widget value)
  "Convert WIDGET's external VALUE to internal form."
  (if (string= regexp-unmatchable value)
      'unmatchable
    (pcase (xr value)
      ((and (pred stringp) literal) literal)
      ((and (pred symbolp) symbol) symbol)
      (`(,pattern . ,body)
       (cond ((memq pattern rx-widget-literal-patterns)
              (cons pattern body))
             ((assq pattern rx-widget-simple-patterns)
              (cons pattern (rx-widget-rxs-to-strings body)))
             ((assq pattern rx-widget-numeric-patterns)
              (seq-let (_ _ n) (assq pattern rx-widget-numeric-patterns)
                (append (list pattern)
                        (seq-take body n)
                        (rx-widget-rxs-to-strings (seq-drop body n))))))))))

(defun rx-widget-make-simple-patterns ()
  "Make simple custom type patterns."
  (seq-map
   (pcase-lambda ((seq pattern tag))
     `(cons :tag ,tag (const :format "" ,pattern) (repeat :format "%v%i\n" rx)))
   rx-widget-simple-patterns))

(defun rx-widget-make-numeric-patterns ()
  "Make numeric custom type patterns."
  (seq-map
   (pcase-lambda ((seq pattern tag n))
     `(cons :tag ,tag (const :format "" ,pattern)
            ,(cl-loop repeat (1+ n)
                      for form = '(repeat :format "%v%i\n" rx)
                      then `(cons :format "%v" integer ,form)
                      finally return form)))
   rx-widget-numeric-patterns))

(defun rx-widget-make-consts (consts)
  "Make CONSTS choice."
  (seq-map (lambda (entry)
             `(const :tag ,(custom-unlispify-menu-entry entry t) ,entry))
           consts))

(define-widget 'rx 'lazy
  "A regular expression in rx form."
  :tag "RX"
  :type `(choice :format "%[Value Menu%] %v"
                 (string :tag "Literal")
                 ,@(rx-widget-make-simple-patterns)
                 ,@(rx-widget-make-numeric-patterns)
                 #1=(cons :tag "Any" (const :format "" any)
                          (repeat :format "%v%i\n"
                                  (choice :format "%[Value Menu%] %v"
                                          (string :tag "Range")
                                          ,@(rx-widget-make-consts
                                             rx-widget-character-classes))))
                 #2=(list :tag "Syntax" :format "%{%t%}: %v"
                          (const :format "" syntax)
                          (choice :format "%[Value Menu%] %v"
                                  ,@(rx-widget-make-consts rx-widget-syntaxes)))
                 #3=(list :tag "Category" :format "%{%t%}: %v"
                          (const :format "" category)
                          (choice :format "%[Value Menu%] %v"
                                  ,@(rx-widget-make-consts rx-widget-categories)))
                 (list :tag "Not" :format "%{%t%}: %v"
                       (const :format "" not)
                       (choice :format "%[Value Menu%] %v" #1# #2# #3#))
                 (list :tag "Backref" :format "%{%t%}: %v"
                       (const :format "" backref)
                       (integer :format "%v"))
                 ,@(rx-widget-make-consts rx-widget-symbols))
  :value-to-external #'rx-widget-to-external
  :value-to-internal #'rx-widget-to-internal)

(provide 'rx-widget)
;;; rx-widget.el ends here
