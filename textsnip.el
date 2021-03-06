;;; testsnip.el --- Posts text to textsnip for sharing.
;; Copyright (C) 2011 Jason Duncan

;; Author: Jason Duncan <jasond496 @ msn.com>
;; Keywords: comm tools
;; Version: 1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;;; Commentary:
;; This file adds a command called "post-to-textsnip".  When invoked, it will
;; post text to textsnip.com for simple/formatted sharing.  If invoked with an
;; active region, it will use the text within that region, else it will use the
;; entirety of the text within the current buffer.  The resulting url from
;; textsnip will then be placed in the kill-ring, as well as the os clipboard
;; where applicable.  If the current major mode is listed in
;; textsnip/mode-alist, the url will be ammended with the corresponding
;; textsnip mode for convenience (saves a mouse click or two).

;; This package depends on the package http-post-simple, which can be attained
;; at http://www.emacswiki.org/emacs/http-post-simple.el

;; To install, copy this file to a path accessible by emacs (specified in
;; load-path), and require it using:
;; (require 'textsnip)

;; To use, invoke with M-x "post-to-textsnip".  This can optionally be bound to
;; a key sequence.

;;; Code:

(require 'http-post-simple)

(defconst textsnip/mode-alist
  '(("html-mode" . "html")
    ("css-mode" . "css")
    ("nxml-mode" . "xml")
    ("js-mode" . "jscript")
    ;; I don't even have a php mode to test this with
    ;; ("". "php")
    ("sql-mode" . "sql")
    ("ruby-mode" . "ruby")
    ("python-mode" . "python")
    ("csharp-mode" . "csharp")
    ;; I don't have a vb mode currently either
    ;; ("" . "vb")
    ("java-mode" . "java"))
  "Alist of major mode names and the equivalent string that should be tacked
onto the end of the url generated by posting to textsnip.  Multiple major mode
names can be added for the same type of file, should any modes differ from the
ones listed (js2-mode for javascript, for example), but none should be removed.")

(defconst textsnip/url "http://textsnip.com/create.php")

(defconst textsnip/submit-name "get my url&nbsp;&gt;")

(defun textsnip/determine-and-append-mode (url)
  "Determine current buffer's major mode, look it up from the mode alist and
append it to the end of the given url (with an extra slash)."
  (let
      ((to-append
        (cdr (assoc (textsnip/current-major-mode-as-string)
                    textsnip/mode-alist))))
    (if to-append (concat url "/" to-append) url)))

(defun textsnip/current-major-mode-as-string ()
  "Determine and return the name of the current buffer's major mode."
  (symbol-name (with-current-buffer (buffer-name) major-mode)))

(defun textsnip/kill-url-and-notify (url)
  "Kill the given url and notify the user."
  (kill-new url)
  (message (concat "Url \"" url "\" copied to kill-ring and os clipboard.")))

(defun textsnip/get-textsnip-url ()
  "Gather the current region or buffer string and post it to textsnip, returning
the resulting url."
  (let ((str (car (textsnip/post-to-textsnip (textsnip/gather-text-to-post)))))
    (if (string-match "a href=\"\\(http:\/\/textsnip.com\/[^\"]+\\)\"" str)
        (match-string 1 str))))

(defun textsnip/post-to-textsnip (str)
  "Post the given url to textsnip and return a string containing the resulting
html page."
  (http-post-simple textsnip/url
                    (list
                     (cons 'url str)
                     (cons 'submit textsnip/submit-name))))

(defun textsnip/gather-text-to-post ()
  "Gather the current region or whole buffer string if no region is active."
  (if (region-active-p)
      (buffer-substring (mark) (point))
    (buffer-string)))

(defun post-to-textsnip (bool)
  "Post the current region (or current buffer-string, if no selection) to
textsnip.com, and copy the resulting url to the kill-ring/clipboard."
  (interactive
   (list (y-or-n-p "Post the current region or buffer string to textsnip.com?")))
  (if bool
      (let ((url (textsnip/get-textsnip-url)))
        (if url (textsnip/kill-url-and-notify
                 (textsnip/determine-and-append-mode url))
          (message "Textsnip url could not be retrieved.")))))

(provide 'textsnip)
