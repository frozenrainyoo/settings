;;; j-dev-assist.el --- Development Asisstant for Emacs developed by Jong-Gyu
;;
;; Copyright 2010 Lee Jong-Gyu<jglee1027@gmail.com>
;;
;; Authors: Lee Jong-Gyu<jglee1027@gmail.com>
;; Version: 0.1.0
;; Repository: git://github.com/jglee1027/settings.git
;;
;; * License
;; 	 This program is free software; you can redistribute it and/or modify
;; 	 it under the terms of the GNU General Public License as published by
;; 	 the Free Software Foundation; either version 2, or (at your option)
;; 	 any later version.
;; 
;; 	 This program is distributed in the hope that it will be useful,
;; 	 but WITHOUT ANY WARRANTY; without even the implied warranty of
;; 	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; 	 GNU General Public License for more details.
;; 
;; 	 You should have received a copy of the GNU General Public License
;; 	 along with GNU Emacs; see the file COPYING.  If not, write to the
;; 	 Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; 	 Boston, MA 02111-1307, USA.
;; 
;;; Commentary:
;; 
;; * Installation
;;   Edit your ~/.emacs file to add the line:
;;     (add-to-list 'load-path "/path/to/j-dev-assist.el")
;;     (require 'j-dev-assist)
;; 
;; * Major commands:
;;	 C-c c `j-make'
;;	 C-c j g `j-modify-header-file-for-g++'
;;	 C-c j p `j-visit-header-or-source-file'
;;	 C-c j s `j-grep-find-symbol-at-point'
;;	 C-c j f `j-grep-find-file'
;;	 C-c j i `j-ido-find-file'
;;	 C-c j m `j-ido-goto-symbol'
;;	 C-c j r `j-grep-find-set-project-root'
;;	 C-c j e `j-grep-find-set-exclusive-path'
;;	 C-c j t `j-create-tags'
;;

;;; Code:

(require 'imenu)

(ido-mode t)
(if (boundp 'ffap-bindings)
	(ffap-bindings))

;; ======================================================================
;; common functions
;; ======================================================================
(defun j-icompleting-read (prompt choices)
  (let ((iswitchb-make-buflist-hook
         (lambda ()
           (setq iswitchb-temp-buflist choices))))
    (iswitchb-read-buffer prompt)))

(defun j-read-shell-command (prompt initial-contents &optional history)
  (if (functionp 'read-shell-command)
	  (read-shell-command prompt
						  initial-contents
						  history)
	(read-from-minibuffer prompt
						  initial-contents
						  nil
						  nil
						  history)))

(defun j-is-directory(path)
  (car (file-attributes path)))

(defun j-get-super-directory(path)
  (replace-regexp-in-string "/[^/]*$"
							""
							path))

(defmacro j-set-default-directory(prompt var var-history)
  `(progn (if (null ,var)
			  (setq ,var default-directory))
		  (setq ,var
				(completing-read ,prompt
								 'ffap-read-file-or-url-internal
								 nil
								 nil
								 ,var
								 ,var-history))))

;; ======================================================================
;; utility functions
;; ======================================================================
(defun j-add-new-line-to-eof()
  "insert newline if the end of buferr is not newline."
  (interactive)
  (save-excursion
	(goto-char (point-max))
	(if (equal (looking-back "\n") nil)
		(insert "\n"))))

(defun j-is-already-exist-if-def-pragma-once()
  "check if current point is between '#ifdef OS_WIN' and '#endif' preprocessor condition or not."
  (save-excursion
	(c-up-conditional 1)
	(looking-at "#[ \t\n]*ifdef[ \t\n]*OS_WIN")))

(defun j-add-if-def-pragma-once()
  "move '#pragma' between '#ifdef OS_WIN' and '#endif'."
  (interactive)
  (save-excursion
	(goto-char (point-min))
	(while (re-search-forward "^[ \t]*#[ \t\n]*pragma[ \t\n]+once" nil t)
	  (beginning-of-line)
	  (kill-line)
	  (insert "#ifdef OS_WIN\n#\tpragma once\n#endif"))))

(defvar j-once-header-project-root-directory  nil)
(defvar j-once-header-project-root-directory-history nil)

(defun j-get-header-define-string()
  "return header definition string for include guard."
  (interactive)
  (let (define-string)
	(setq define-string (buffer-file-name (current-buffer)))
	(j-set-default-directory "Project root directory: "
							 j-once-header-project-root-directory
							 'j-once-header-project-root-directory-history)
	(setq define-string
		  (replace-regexp-in-string j-once-header-project-root-directory
									""
									define-string))
	(setq define-string
		  (upcase (replace-regexp-in-string "[/\\.]"
											"_"
											define-string)))))

(defun j-is-already-exist-if-def-header(header-define-name)
  "check if header definition string already exists or not."
  (interactive)
  (save-excursion
	(let (define-header-name-regexp)
	  (goto-char (point-min))
	  (setq define-header-name-regexp (format "^[ \t]*#[ \t\n]*define[ \t\n]+%s"
											  header-define-name))
	  (re-search-forward  define-header-name-regexp nil t))))

(defun j-add-ifndef-header-define-name()
  "if include guards don't exist, insert include guards."
  (interactive)
  (save-excursion
	(let (header-define-name new-line count-of-new-line) 
	  (setq header-define-name (j-get-header-define-string))
	  (if (equal (j-is-already-exist-if-def-header header-define-name) nil)
		  (progn
			(goto-char (point-min))
			(insert (format "#ifndef %s\n#define %s\n\n"
							header-define-name
							header-define-name))
			(goto-char (point-max))
			(setq count-of-new-line 0)
			(while (and (looking-back "\n") (not (bobp)))
			  (setq count-of-new-line (1+ count-of-new-line))
			  (forward-char -1))
			(cond ((>= count-of-new-line 2)
				   ;; delete useless newline
				   (delete-char (- count-of-new-line 2))
				   (setq new-line ""))
				  ((equal count-of-new-line 1)
				   (setq new-line "\n"))
				  (t
				   (setq new-line "\n\n")))
			(goto-char (point-max))
			(insert new-line)
			(insert (format "#endif // %s\n" header-define-name)))))))

(defun j-modify-header-file-for-g++()
  "to supress g++ warning, insert newline at the end of buffer.
use include guards."
  (interactive)
  (j-add-ifndef-header-define-name)
  (j-add-if-def-pragma-once))

(defun j-get-makefile-dir()
  "return the directory(project root directory) where Makefile exist."
  (interactive)
  (let (makefile-dir)
	(setq makefile-dir (buffer-file-name))
	(if (equal makefile-dir nil)
		(setq makefile-dir default-directory) ; not filebuffer
	  (setq makefile-dir (j-get-super-directory makefile-dir)))
	(while (and (not (equal makefile-dir ""))
				(not (file-exists-p (concat makefile-dir "/Makefile"))))
	  (setq makefile-dir (j-get-super-directory makefile-dir)))
	makefile-dir))

(defvar j-make-command-history nil)
(defun j-make ()
  "make compile-string like following if the directory in which Makefile exist is found.
ex) make -C project/root/directory"
  (interactive)
  (let (compile-string makefile-dir)
	(setq makefile-dir (j-get-makefile-dir))
	(if (equal makefile-dir "")
		(setq compile-string "make ")
	  (setq compile-string (format "make -C %s " makefile-dir)))
	(setq compile-string (read-from-minibuffer "Compile command: "
											   compile-string
											   nil
											   nil
											   'j-make-command-history))
	(compile compile-string)))

(defun j-get-sub-directory-list(dir)
  (let ((entries (directory-files dir t))
		(sub-dirs '()))
	(mapcar (lambda (entry) (if (j-is-directory entry)
								(add-to-list 'sub-dirs entry t)))
			entries)
	sub-dirs))

(defun j-get-extensions-to-visit()
  (let (extension extensions-to-visit)
	(if (null (buffer-file-name))
		(setq extensions-to-visit nil)
	  (progn
		(setq extension (file-name-extension (buffer-file-name)))
		(cond ((equal extension "c")
			   (setq extensions-to-visit '("h")))
			  ((equal extension "cpp")
			   (setq extensions-to-visit '("h")))
			  ((equal extension "m")
			   (setq extensions-to-visit '("h")))
			  ((equal extension "mm")
			   (setq extensions-to-visit '("h")))
			  ((equal extension "h")
			   (setq extensions-to-visit '("c" "cpp" "m" "mm")))
			  (t
			   (setq extensions-to-visit nil)))))))

(defun j-visit-file(file-name-sans-ext extensions)
  (let (file-name file-ext)
	(while (not (equal (setq file-ext (pop extensions)) nil))
	  (setq file-name (concat file-name-sans-ext "." file-ext))
	  (if (file-exists-p file-name)
		  (progn
			(find-file file-name)
			(throw 'visit-file-exception file-name))))))

(defun j-visit-file-in-sub-dirs(sub-dir-list file-name-non-dir extensions)
  (let (file-name-sans-ext)
	(mapcar (lambda (entry)
			  (setq file-name-sans-ext (concat entry "/" file-name-non-dir))
			  (j-visit-file file-name-sans-ext extensions))
			sub-dir-list)))

(defun j-visit-file-in-dirs(super-dir-depth sub-dir-depth)
  (let ((extensions-to-visit (j-get-extensions-to-visit))
		file-name-sans-ext
		file-name-non-dir
		current-dir
		sub-dir-list)
	
	(if (or (equal extensions-to-visit nil)
			(equal (buffer-file-name) nil))
		(throw 'visit-file-exception "Not supported!"))
	
	(setq file-name-sans-ext (file-name-sans-extension (buffer-file-name)))
	(setq file-name-non-dir (file-name-nondirectory file-name-sans-ext))
	
	;; in current directory
	;; in super directory
	;; in sub-dir of super-dir
	;; ...
	(setq current-dir (file-name-directory file-name-sans-ext))
	(setq sub-dir-list (j-get-sub-directory-list current-dir))
	(dotimes (i super-dir-depth)
	  (setq current-dir (j-get-super-directory current-dir))
	  (if (equal current-dir "")
		  (throw 'visit-file-exception "Not found!"))
	  (setq sub-dir-list (j-get-sub-directory-list current-dir))
	  (j-visit-file-in-sub-dirs sub-dir-list
								file-name-non-dir
								extensions-to-visit))
	
	;; in sub-dir of sub-dir
	;; ...
	(setq current-dir (file-name-directory file-name-sans-ext))
	(setq sub-dir-list (j-get-sub-directory-list current-dir))
	(let ((sub-dir-all-list nil))
	  (dotimes (i sub-dir-depth)
		(mapcar (lambda (entry)
				  (let ((dirs (j-get-sub-directory-list entry)))
					(mapcar (lambda (x)
							  (delq x sub-dir-all-list)
							  (add-to-list 'sub-dir-all-list x t))
							dirs))
				  entry)
				sub-dir-list)
		(setq sub-dir-list sub-dir-all-list))
	  (j-visit-file-in-sub-dirs sub-dir-all-list
								file-name-non-dir
								extensions-to-visit))
	
	(throw 'visit-file-exception "Not found!")))

(defun j-visit-header-or-source-file()
  "open the header or source file related with the current file."
  (interactive)
  (message (catch 'visit-file-exception
			 (j-visit-file-in-dirs 2 2))))

(defvar j-grep-find-symbol-history nil)
(defvar j-grep-find-symbol-command-history nil)
(defvar j-grep-find-file-history nil)
(defvar j-grep-find-file-command-history nil)
(defvar j-grep-find-project-root nil)
(defvar j-grep-find-project-root-history nil)
(defvar j-grep-find-exclusive-path "*.git* *.svn* *.cvs* *.class *.obj *.o *.a *.so *~ *# *TAGS *cscope.out")
(defvar j-grep-find-exclusive-path-history nil)

(defun j-get-find-exclusive-path-options()
  (let (path-list path-option)
	(if (equal j-grep-find-exclusive-path "")
		(setq path-option "")
	  (progn
		(setq path-list 
			  (mapcar (lambda (x) (format "-path '%s'" x))
					  (split-string j-grep-find-exclusive-path)))
		(setq path-option (pop path-list))
		(while path-list
		  (setq path-option (concat path-option " -o " (pop path-list))))
		(setq path-option (concat "! \\( " path-option " \\)"))))))

(defun j-get-find-name-options()
  (let (name-option extension)
	(if (null (buffer-file-name))
		(setq name-option "")
	  (progn
		(setq extension (file-name-extension (buffer-file-name)))
		(cond ((or (equal extension "c") (equal extension "cpp") (equal extension "h"))
			   (setq name-option "\\( -name '*.[cChH]' -o -name '*.[cC][pP][pP]' \\)"))
			  ((or (equal extension "m") (equal extension "mm"))
			   (setq name-option "\\( -name '*.[cChH]' -o -name '*.[cC][pP][pP]' -o -name '*.mm' -o -name '*.m' \\)"))
			  ((equal extension "java")
			   (setq name-option "-name '*.java'"))
			  ((equal extension "el")
			   (setq name-option "-name '*.el'"))
			  ((equal extension "rb")
			   (setq name-option "-name '*.rb'"))
			  (t
			   (setq name-option "")))))))

(defun j-grep-find-set-exclusive-path()
  (interactive)
  (setq j-grep-find-exclusive-path
		(read-from-minibuffer "Exclusive paths: "
							  j-grep-find-exclusive-path
							  nil
							  nil
							  'j-grep-find-exclusive-path-history)))

(defun j-grep-find-set-project-root()
  "set a project root directory for grep-find"
  (interactive)
  (j-set-default-directory "Project root: "
						   j-grep-find-project-root
						   'j-grep-find-project-root-history))

(defun j-grep-find-select-grep-buffer(current-buffer msg)
  (condition-case nil
	  (progn
		(select-window (get-buffer-window current-buffer))
		(forward-line 4)
		(setq compilation-finish-function nil))
	(error nil)))

(defun j-grep-find-symbol-at-point()
  "grep-find with symbol at current point."
  (interactive)
  (let (symbol)
	(j-grep-find-set-project-root)
	(setq symbol (symbol-at-point))
	(if (null symbol)
		(setq symbol ""))
	(setq symbol (read-from-minibuffer "Find symbol: "
									   (format "%s" symbol)
									   nil
									   nil
									   'j-grep-find-symbol-history))
	(setq compilation-finish-function 'j-grep-find-select-grep-buffer)
	(grep-find (j-read-shell-command "Command: "
									 (format "find -L %s -type f %s %s -print0 | xargs -0 grep -nH -e \"\\<%s\\>\""
											 j-grep-find-project-root
											 (j-get-find-name-options)
											 (j-get-find-exclusive-path-options)
											 symbol)
									 'j-grep-find-symbol-command-history))))

(defun j-grep-find-file()
  "search a file."
  (interactive)
  (let (file-name)
	(j-grep-find-set-project-root)
	(setq file-name (read-from-minibuffer "Find file: "
										  nil
										  nil
										  nil
										  'j-grep-find-file-history))
	(setq compilation-finish-function 'j-grep-find-select-grep-buffer)
	(grep-find (j-read-shell-command "Command: "
									 (format "find -L %s -type f -name '%s'"
											 j-grep-find-project-root
											 file-name)
									 'j-grep-find-file-command-history))))

(defvar j-create-tags-command nil)
(defvar j-create-tags-command-history nil)
(defvar j-create-tags-directory nil)
(defvar j-create-tags-directory-history nil)

(defun j-create-tags()
  "create TAG file."
  (interactive)
  (j-set-default-directory "Create tags: "
						   j-create-tags-directory
						   'j-create-tags-directory-history)
  (shell-command (j-read-shell-command "Command: "
									   (format "find -L %s -type f %s %s -print | etags - -o %s/TAGS"
											   j-create-tags-directory
											   (j-get-find-name-options)
											   (j-get-find-exclusive-path-options)
											   j-create-tags-directory)
									   'j-create-tags-command-history)
				 "*j-create-tag*"))


(defvar j-etags-tag-info-alist nil)

(defun j-etags-make-tag-info-alist(file)
  (goto-char (point-min))
  (when (re-search-forward (concat "\f\n" "\\(" file "\\)" ",") nil t)
    (let ((path (save-excursion (forward-line 1) (file-of-tag)))
		  tag-info)
	  (forward-line 1)
	  (while (not (or (eobp) (looking-at "\f")))
		(setq tag-info (save-excursion (etags-snarf-tag t)))
		(add-to-list 'j-etags-tag-info-alist tag-info t)
		(forward-line 1))
	  t)))

(defun j-etags-goto-tag-in-file()
  (interactive)
  (setq j-etags-tag-info-alist nil)
  (let ((file (buffer-file-name)))
	(save-excursion
	  (let ((first-time t)
			(gotany nil))
		(while (visit-tags-table-buffer (not first-time))
		  (setq first-time nil)
		  (if (j-etags-make-tag-info-alist file)
			  (setq gotany t)))
		(or gotany
			(error "File %s not in current tags tables" file))))
	(let ((tags (mapcar (lambda (x) (car x))
						j-etags-tag-info-alist))
		  line
		  tag-info)
	  (setq tag-info (assoc (j-icompleting-read "Goto tag in file: "
												tags)
							j-etags-tag-info-alist))
	  (setq line (car (cdr tag-info)))
	  (goto-line line))))

;; http://www.emacswiki.org/emacs/InteractivelyDoThings
(defun j-ido-find-file-in-tag-files ()
  (interactive)
  (save-excursion
	(let ((enable-recursive-minibuffers t))
	  (visit-tags-table-buffer))
	(find-file
	 (expand-file-name
	  (ido-completing-read
	   "Project file: " (tags-table-files) nil t)))))

;; http://www.emacswiki.org/cgi-bin/wiki/ImenuMode
(defun j-ido-goto-symbol (&optional symbol-list)
  "Refresh imenu and jump to a place in the current buffer using Ido."
  (interactive)
  (unless (featurep 'imenu)
	(require 'imenu nil t))
  (cond
   ((not symbol-list)
	(let ((ido-mode ido-mode)
		  (ido-enable-flex-matching
		   (if (boundp 'ido-enable-flex-matching)
			   ido-enable-flex-matching t))
		  name-and-pos symbol-names position)
	  (unless ido-mode
		(ido-mode 1)
		(setq ido-enable-flex-matching t))
	  (while (progn
			   (imenu--cleanup)
			   (setq imenu--index-alist nil)
			   (j-ido-goto-symbol (imenu--make-index-alist))
			   (setq selected-symbol
					 (ido-completing-read "Symbol? " symbol-names))
			   (string= (car imenu--rescan-item) selected-symbol)))
	  (unless (and (boundp 'mark-active) mark-active)
		(push-mark nil t nil))
	  (setq position (cdr (assoc selected-symbol name-and-pos)))
	  (cond
	   ((overlayp position)
		(goto-char (overlay-start position)))
	   (t
		(goto-char position)))))
   ((listp symbol-list)
	(dolist (symbol symbol-list)
	  (let (name position)
		(cond
		 ((and (listp symbol) (imenu--subalist-p symbol))
		  (j-ido-goto-symbol symbol))
		 ((listp symbol)
		  (setq name (car symbol))
		  (setq position (cdr symbol)))
		 ((stringp symbol)
		  (setq name symbol)
		  (setq position
				(get-text-property 1 'org-imenu-marker symbol))))
		(unless (or (null position) (null name)
					(string= (car imenu--rescan-item) name))
		  (add-to-list 'symbol-names name)
		  (add-to-list 'name-and-pos (cons name position))))))))

(defvar j-ido-find-file-files-alist nil)
(defvar j-ido-find-file-files-alist-root nil)

(defun j-ido-find-file()
  (interactive)
  (let (chosen-name
		find-command
		same-name-files-list
		(same-name-files-count 0))
	(j-grep-find-set-project-root)
	(setq find-command
		  (format "find -L %s -type f %s"
				  j-grep-find-project-root
				  (j-get-find-exclusive-path-options)))
	(message "Finding...")
	;; if the previous project root directory equals to the current one,
	;; use the previous j-ido-find-file-files-alist to improve speed.
	(cond ((not (equal j-grep-find-project-root
					   j-ido-find-file-files-alist-root))
		   (setq j-ido-find-file-files-alist
				 (mapcar (lambda (x)
						   (list (file-name-nondirectory x) x))
						 (split-string
						  (shell-command-to-string find-command))))
		   (setq j-ido-find-file-files-alist-root j-grep-find-project-root)))
	(setq chosen-name
		  (ido-completing-read "Project file: "
							   (mapcar (lambda (x)
										 (car x))
									   j-ido-find-file-files-alist)))
	(mapcar (lambda (x)
			  (cond ((equal chosen-name (car x))
					 (add-to-list 'same-name-files-list
								  (car (cdr x)))
					 (setq same-name-files-count
						   (1+ same-name-files-count)))))
			j-ido-find-file-files-alist)
	(cond ((equal same-name-files-count 1)
		   (find-file (car same-name-files-list)))
		  ((> same-name-files-count 1)
		   (find-file (ido-completing-read "Find file: "
										   same-name-files-list))))))

;; ======================================================================
;; Key definition
;; ======================================================================
(define-key global-map (kbd "C-c c") 'j-make)
(define-key global-map (kbd "C-c j g") 'j-modify-header-file-for-g++)
(define-key global-map (kbd "C-c j p") 'j-visit-header-or-source-file)
(define-key global-map (kbd "C-c j s") 'j-grep-find-symbol-at-point)
(define-key global-map (kbd "C-c j f") 'j-grep-find-file)
(define-key global-map (kbd "C-c j i") 'j-ido-find-file)
(define-key global-map (kbd "C-c j m") 'j-ido-goto-symbol)
(define-key global-map (kbd "C-c j r") 'j-grep-find-set-project-root)
(define-key global-map (kbd "C-c j e") 'j-grep-find-set-exclusive-path)
(define-key global-map (kbd "C-c j t") 'j-create-tags)
(define-key global-map (kbd "C-c j v") 'visit-tags-table)
(define-key global-map (kbd "C-c j .") 'tags-apropos)
(define-key global-map (kbd "C-c j h") 'hs-minor-mode)

(provide 'j-dev-assist)
;;; j-dev-assist.el ends here