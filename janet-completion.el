;;; janet-completion.el --- Provide Janet symbol completion via janet-complete -*- lexical-binding: t -*-

;; Copyright (C) 2025 Seungki Kim

;; Author: Seungki Kim <tttuuu888@gmail.com>
;; URL: https://github.com/tttuuu888/janet-completion
;; Version: 0.3.0
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

;; This package provides completion support by communicating with the
;; `janet-complete` module (a Janet module) running in an `inf-janet` REPL.

;; Completion candidates are retrieved from the REPL and can be used in both
;; the REPL buffer and in Janet source files connected to the REPL.

;; Requirements:

;; - `janet-complete` (Janet module)
;; - `inf-janet`

;;; Code:

(defvar janet-completion-completion-cache nil
  "Cache for Janet completion results.")

(defun janet-completion--remove-ansi-escape-sequences (str)
  "Remove ANSI escape sequences from STR."
  (replace-regexp-in-string
   "\x1b\\[[0-9;]*m" "" str))

(defun janet-completion--completion-fetch (prefix)
  "Send (complete \"PREFIX\") to Janet REPL and return candidate list."
  (let* ((proc (inf-janet-proc))
         (output-buffer (get-buffer-create "*janet-completion-output*"))
         (cmd (format "(complete %S)\n" prefix))
         (output ""))
    (with-current-buffer output-buffer
      (erase-buffer))
    (let ((original-filter (process-filter proc)))
      (unwind-protect
          (progn
            (set-process-filter
             proc
             (lambda (proc string)
               (with-current-buffer output-buffer
                 (insert string))))
            (process-send-string proc cmd)
            (accept-process-output proc 0.2)
            (setq output
                  (janet-completion--remove-ansi-escape-sequences
                   (with-current-buffer output-buffer
                     (buffer-string)))))

        (set-process-filter proc original-filter)))
    (when (string-match "\\[\\(.*?\\)\\]" output)
      (let* ((raw (match-string 1 output))
             (cands (split-string raw "\"" t "\" *, *")))
        (cl-remove-if (lambda (s) (string-match-p "\\`[ \t\r\n]*\\'" s))
                      cands)))))

(defun janet-completion-completion-table ()
  "Return a completion table that fetches completions from Janet."
  (completion-table-dynamic
   (lambda (prefix)
     (or (cdr (assoc prefix janet-completion-completion-cache))
         (let ((comps (janet-completion--completion-fetch prefix)))
           (push (cons prefix comps) janet-completion-completion-cache)
           comps)))))

(defun janet-completion-completion-at-point ()
  "Determine the region at point to complete, and return completion data."
  (let* ((beg (save-excursion (skip-syntax-backward "w_") (point)))
         (end (save-excursion (skip-syntax-forward "w_") (point)))
         (prefix (buffer-substring-no-properties beg end)))
    (when (and (inf-janet-connected-p)
               (> end beg))
      (list beg end (janet-completion-completion-table)))))

(add-hook 'inf-janet-mode-hook
          (lambda ()
            (add-hook 'completion-at-point-functions
                      #'janet-completion-completion-at-point nil t)))

(add-hook 'janet-mode-hook
          (lambda ()
            (add-hook 'completion-at-point-functions
                      #'janet-completion-completion-at-point nil t)))

(provide 'janet-completion)
;;; janet-completion.el ends here
