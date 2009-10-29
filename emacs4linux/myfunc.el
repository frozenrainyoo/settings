(defun j-add-new-line-to-eof()
  "���� �������� new line�� ������ �߰��Ѵ�."
  (interactive)
  (save-excursion
	(goto-char (point-max))
	(if (equal (looking-back "\n") nil)
		  (insert "\n"))))

(defun j-is-already-exist-if-def-pragma-once()
  "#pragma once�� �̹� #ifdef OS_WIN ~ #endif�ȿ� �ִ��� üũ�Ѵ�."
  (save-excursion
	(c-up-conditional 1)
	(looking-at "#[ \t\n]*ifdef[ \t\n]*OS_WIN")))

(defun j-add-if-def-pragma-once()
  "#pragma once�� #ifdef OS_WIN ~ #endif�ȿ� �ֵ��� �����Ѵ�."
  (interactive)
  (save-excursion
	(goto-char (point-min))
	(while (re-search-forward "^[ \t]*#[ \t\n]*pragma[ \t\n]+once" nil t)
	  (beginning-of-line)
	  (kill-line)
	  (insert "#ifdef OS_WIN\n#\tpragma once\n#endif"))))

(defun j-get-header-define-string()
  "header define ���ڿ��� �����Ͽ� �����Ѵ�."
  (interactive)
  (let (define-string)
	(setq define-string (buffer-file-name (current-buffer)))
	(setq define-string (replace-regexp-in-string "^.+/HOffice8/Common/" "" define-string))
	(setq define-string (replace-regexp-in-string "^.+/HOffice8/Hwp8/" "" define-string))
	(setq define-string (replace-regexp-in-string "^.+/HOffice8/HNexcel8/" "" define-string))
	(setq define-string (replace-regexp-in-string "^.+/HOffice8/HSlide8/" "" define-string))
	(setq define-string (replace-regexp-in-string "[/\\.]" "_" define-string))))

(defun j-is-already-exist-if-def-header(header-define-name)
  "#define header-define-name �� �����ϴ��� üũ�Ѵ�. �����ϸ� t �׷��� ������ nil�����Ѵ�."
  (interactive)
  (save-excursion
	(let (define-header-name-regexp)
	  (goto-char (point-min))
	  (setq define-header-name-regexp (format "^[ \t]*#[ \t\n]*define[ \t\n]+%s" header-define-name))
	  (re-search-forward  define-header-name-regexp nil t))))

(defun j-add-ifndef-header-define-name()
  "#ifndef header_file_h #define header_file_h ~ #endif�� ������ �߰��Ѵ�."
  (interactive)
  (save-excursion
	(let (header-define-name new-line count-of-new-line) 
	  (setq header-define-name (j-get-header-define-string))
	  (if (equal (j-is-already-exist-if-def-header header-define-name) nil)
		  (progn
			(goto-char (point-min))
			(insert (format "#ifndef %s\n#define %s\n\n" header-define-name header-define-name))
			(goto-char (point-max))
			(setq count-of-new-line 0)
			(while (and (looking-back "\n") (not (bobp)))
			  (setq count-of-new-line (+ 1 count-of-new-line))
			  (forward-char -1))
			(cond ((>= count-of-new-line 2)
				   ;; new line�� �ʿ���� ��� �����Ѵ�.
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
  "g++ warning�����ϱ� ���� �������ٿ� new line, #ifndef ~, #ifdef OS_WIN #pragma once ~�� header file�� �߰��Ѵ�."
  (interactive)
  (j-add-ifndef-header-define-name)
  (j-add-if-def-pragma-once))

(defun j-get-makefile-dir()
  "���� ������ ��ġ�� �������� Makefile�� �����ϴ��� �������� ������ ���� ���丮���� �����Ͽ� root���� �����Ѵ�. Makefile�� �߰��ϸ� �߰��� ���丮�� ���� �׷��� ������ nil�����Ѵ�."
  (interactive)
  (let (makefile-dir point-of-directory)
	(setq makefile-dir (buffer-file-name))
	;; filebuffer�� �ƴѰ�� ó��
	(if (equal makefile-dir nil)
		(setq makefile-dir ""))
	(while (and (not (equal makefile-dir ""))
				(not (file-exists-p (concat makefile-dir "/Makefile"))))
	  (setq makefile-dir (replace-regexp-in-string "/[^/]+$" "" makefile-dir)))
	(if (equal makefile-dir "")
		""
	  makefile-dir)))

(defun j-make ()
  "Makefile���� ��ġ�� �ڵ����� ã�� ������ ��� ���ڿ��� �ڵ����� �����Ѵ�.��) make -C <DIR>"
  (interactive)
  (let (compile-string makefile-dir)
	(setq makefile-dir (j-get-makefile-dir))
	(if (equal makefile-dir "")
		(setq compile-string "make ")
	  (setq compile-string (format "make -C %s " (j-get-makefile-dir))))
	(setq compile-string (read-from-minibuffer "Compile command: " compile-string))
	(compile compile-string)))

(put 'narrow-to-region 'disabled nil)
(fset 'ifdef-os-win
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ("#ifdef OS_WIN#endif" 0 "%d")) arg)))
(fset 'ifdef-os-unix
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ("#ifdef OS_UNIX#endif" 0 "%d")) arg)))
(setq compilation-scroll-output t)

(define-key global-map (kbd "C-c m w") 'ifdef-os-win)
(define-key global-map (kbd "C-c m u") 'ifdef-os-unix)
(define-key global-map (kbd "C-c m m") 'j-modify-header-file-for-g++)
(define-key global-map (kbd "C-c c") 'j-make)
