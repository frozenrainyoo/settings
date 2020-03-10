(global-hl-line-mode t)

(ignore-errors (el-get-init 'grep-a-lot))
(ignore-errors (el-get-init 'switch-window))
(ignore-errors (el-get-init 'magit))
(ignore-errors (el-get-init 'lua-mode)
               (load-library "lua-mode"))
(ignore-errors (el-get-init 'cmake-mode)
               (load-library "cmake-mode")
               (setq cmake-tab-width 4))
(ignore-errors (el-get-init 'markdown-mode)
               (load-library "markdown-mode"))
(ignore-errors (el-get-init 'highlight-sexp)
               (load-library "highlight-sexp"))
(ignore-errors (el-get-init 'c-eldoc)
               (load-library "c-eldoc"))
(ignore-errors (el-get-init 'paredit)
               (load-library "paredit"))
(ignore-errors (el-get-init 'helm)
               (require "helm"))

;; slime
(ignore-errors (el-get-init 'slime)
               (setq inferior-lisp-program "/usr/bin/clisp")
               (setq slime-contribs '(slime-fancy)))

;; cmake-ide
(ignore-errors (el-get-init 's))
(ignore-errors (el-get-init 'rtags))
(ignore-errors (el-get-init 'cmake-ide)
               (require 'rtags)
               (require 'cmake-ide)
               (cmake-ide-setup))
