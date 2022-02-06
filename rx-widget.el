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

;; This package defines a rx-widget to edit regular expression in rx form.  It
;; can be used in :type property of defcustom definitions.

;; To use rx-widget in all existing regexp widgets, use this:
;; (define-widget 'regexp 'rx-widget "A regular expression in rx form.")

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'wid-edit)

(declare-function xr "ext:xr")
(declare-function xr-pp-rx-to-str "ext:xr")

(defun rx-widget-regexp-opt (strings &optional paren)
  "Simplified version of `regexp-opt' without compression.
STRINGS and PAREN are the same as in `regexp-opt'"
  (let ((parens
         (cond ((stringp paren)       (cons paren "\\)"))
               ((eq paren 'words)    '("\\<\\(" . "\\)\\>"))
               ((eq paren 'symbols) '("\\_<\\(" . "\\)\\_>"))
               ((null paren)          '("\\(?:" . "\\)"))
               (t                       '("\\(" . "\\)")))))
    (concat (car parens) (mapconcat #'regexp-quote strings "\\|") (cdr parens))))

(defun rx-widget-rx-to-string (form)
  "Like `rx-to-string', but with simplified `regexp-opt'.
FORM is first argument for `rx-to-string'"
  (cl-letf (((symbol-function 'regexp-opt)
             (symbol-function 'rx-widget-regexp-opt)))
    (rx-to-string form t)))

(defun rx-widget-to-external (_widget value)
  "Convert WIDGET's internal VALUE to string."
  (rx-widget-rx-to-string (read value)))

(defun rx-widget-to-internal (_widget value)
  "Convert WIDGET's external VALUE to internal form."
  (let ((internal (string-trim-right (xr-pp-rx-to-str (xr value 'brief)))))
    (if (cl-find ?\n internal)
        (concat "\n" internal)
      internal)))

(define-widget 'rx-widget 'sexp
  "A regular expression in rx form."
  :tag "Rx form"
  :value ""
  :match #'widget-regexp-match
  :value-to-external #'rx-widget-to-external
  :value-to-internal #'rx-widget-to-internal)

(provide 'rx-widget)
;;; rx-widget.el ends here
