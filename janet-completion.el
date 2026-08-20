;;; janet-completion.el --- Completion support for Janet -*- lexical-binding: t -*-

;; Copyright (C) 2025-2026 Seungki Kim

;; Author: Seungki Kim <tttuuu888@gmail.com>
;; URL: https://github.com/tttuuu888/janet-completion
;; Version: 0.4.0
;; Package-Requires: ((emacs "28.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides completion support by querying a running
;; `inf-janet' REPL.

;; Completion works in both the REPL buffer and Janet source files.
;;
;; Enable it globally with `janet-completion-mode'.

;; Requirements:

;; - `inf-janet'

;;; Code:
(require 'inf-janet)

(defgroup janet-completion nil
  "Symbol completion for Janet."
  :group 'janet
  :prefix "janet-completion-")

(defcustom janet-completion-timeout 0.5
  "Seconds to wait for the Janet REPL to answer a completion query."
  :type 'number)

(defcustom janet-completion-minimum-prefix-length 2
  "Minimum prefix length required to trigger Janet completion."
  :type 'integer)

(defconst janet-completion--query
  (concat "(print \"<janet-completion>\""
          " (string/join (filter |(string/has-prefix? %S $)"
          " (map string (all-bindings))) \" \")"
          " \"</janet-completion>\")\n")
  "Format string to query matching bindings from the Janet REPL.")

(defconst janet-completion--response-regexp
  "<janet-completion>\\([^\0]*?\\)</janet-completion>"
  "Regexp for the tagged answer of `janet-completion--query'.")

(defun janet-completion--fetch (prefix)
  "Fetch bindings starting with PREFIX from the Janet REPL.
Return a list of completion strings, or nil on timeout."
  (let* ((proc (inf-janet-proc))
         (original-filter (process-filter proc))
         (deadline (+ (float-time) janet-completion-timeout))
         (output "")
         (answer nil))
    (unwind-protect
        (progn
          (set-process-filter
           proc
           (lambda (_process string)
             (setq output (concat output string))))
          (process-send-string proc (format janet-completion--query prefix))
          (while (and (not answer) (< (float-time) deadline))
            (accept-process-output proc 0.05)
            (when (string-match janet-completion--response-regexp output)
              (setq answer (match-string 1 output)))))
      (set-process-filter proc original-filter))
    (when answer
      (split-string answer "[ \t\r\n]+" t))))

(defun janet-completion-completion-at-point ()
  "Return completion data for the symbol at point.
Return nil if no REPL is connected or if the symbol length is shorter than
`janet-completion-minimum-prefix-length'."
  (when-let* (((inf-janet-connected-p))
              (bounds (bounds-of-thing-at-point 'symbol))
              (prefix (buffer-substring-no-properties (car bounds) (cdr bounds)))
              ((>= (length prefix) janet-completion-minimum-prefix-length)))
    (list (car bounds) (cdr bounds)
          (completion-table-with-cache
           (lambda (_string) (janet-completion--fetch prefix)))
          :exclusive 'no)))

(define-minor-mode janet-completion-local-mode
  "Provide Janet symbol completion in the current buffer.

Completion requires a connected `inf-janet' REPL.  Use the global mode
`janet-completion-mode' to enable this mode in all Janet buffers."
  :lighter ""
  (if janet-completion-local-mode
      (add-hook 'completion-at-point-functions
                #'janet-completion-completion-at-point nil t)
    (remove-hook 'completion-at-point-functions
                 #'janet-completion-completion-at-point t)))

(defun janet-completion--turn-on ()
  "Turn on `janet-completion-local-mode' in the current buffer."
  (janet-completion-local-mode 1))

;;;###autoload
(define-globalized-minor-mode janet-completion-mode
  janet-completion-local-mode
  janet-completion--turn-on
  :predicate '(janet-mode inf-janet-mode))

(provide 'janet-completion)
;;; janet-completion.el ends here
