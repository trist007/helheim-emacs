;;; config.el -*- lexical-binding: t; -*-

;; Hooks
(defun my/c-indent-settings ()
  (setq-local c-basic-offset 2
              tab-width 2
              indent-tabs-mode nil)
  (c-set-offset 'inclass 2)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'inline-open 0)
  (c-set-offset 'block-open 0)
  (c-set-offset 'brace-list-open 0)
  (setq c-hanging-braces-alist
        '((substatement-open before after)
          (brace-list-open before after)
          (block-open before after)
          (defun-open before after)
          (class-open before after)
          (inline-open before after))))

(add-hook 'c-mode-hook #'my/c-indent-settings)
(add-hook 'c++-mode-hook #'my/c-indent-settings)

;; Disable elpaca from overwritting initial buffer choice
(add-hook 'elpaca-after-init-hook
          (lambda ()
            (bookmark-load "C:/Users/Tristan/.config/helheim-emacs/var/bookmarks" t t)
            (condition-case err
                (bookmark-jump "wing-code")
              (error (message "wing-code bookmark failed: %s" err)))))

;; Enable modules
(elpaca centaur-tabs
        (centaur-tabs-mode 1))

;; Global Keybinds
(keymap-global-set "C-," #'other-frame)
(keymap-global-set "C-c o f" #'make-frame)

;; OS Specific Keybinds
(cond
 ((eq system-type 'windows-nt)
  (keymap-global-set "C-<tab>" #'centaur-tabs-forward)
  (keymap-global-set "C-S-<tab>" #'centaur-tabs-backward))
 ((eq system-type 'gnu/linux)
  (keymap-global-set "C-<tab>" #'centaur-tabs-forward)
  (keymap-global-set "C-S-<tab>" #'centaur-tabs-backward)
  (keymap-global-set "C-<iso-lefttab>" #'centaur-tabs-backward)
  (keymap-global-set "C-S-<iso-lefttab>" #'centaur-tabs-backward))
 ((eq system-type 'darwin)
  (keymap-global-set "C-<tab>" #'centaur-tabs-forward)
  (keymap-global-set "C-S-<tab>" #'centaur-tabs-backward)))

;; C Keybinds
(with-eval-after-load 'cc-mode
   (define-key c-mode-map (kbd "C-S-a") #'align))

;; Themes
(elpaca doom-themes
  (load-theme 'doom-tokyo-night t))
(which-function-mode 1)

(add-to-list 'major-mode-remap-alist '(c-mode . c-mode))
(add-to-list 'major-mode-remap-alist '(c++-mode . c++-mode))
(add-to-list 'auto-mode-alist '("\\.c\\'" . c-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-mode))

(setq major-mode-remap-defaults
      (seq-remove (lambda (e) (memq (car e) '(c-mode c++-mode)))
                  major-mode-remap-defaults))
;; Emacs config
(setq display-line-numbers-type t)
(setq woman-manpath '("//wsl$/CentOS/usr/share/man"
                      "//wsl$/CentOS/usr/local/share/man"
                      "//wsl$/CentOS/usr/share/locale/man"))

(defun my-woman (topic)
  "Look up TOPIC with woman in one shot."
  (interactive "sWoman topic: ")
  (woman topic))

(keymap-global-set "C-c w" #'my-woman)

;; C-k kill-line will work in minibuffer
(keymap-set minibuffer-local-map "C-k" #'delete-minibuffer-contents)

;; Doxyfile
(add-to-list 'auto-mode-alist '("Doxyfile\\'" . conf-unix-mode))
(add-to-list 'auto-mode-alist '("\\.doxyfile\\'" . conf-unix-mode))

;; Compilation window
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.25)))

(defun my/escape ()
  "Close popup-style windows at the bottom, otherwise quit."
  (interactive)
  (let ((closed nil))
    (dolist (name '("*compilation*" "*wing-run*" "*Warnings*" "*Messages*"))
      (when-let ((win (get-buffer-window name)))
        (ignore-errors (delete-window win))
        (setq closed t)))
    (unless closed (keyboard-quit))))

;; (defun my/close-compilation ()
;;   (interactive)
;;   (if-let ((win (get-buffer-window "*compilation*")))
;;       (delete-window win)
;;     (message "No compilation window")))

(with-eval-after-load 'hel
  (keymap-set hel-normal-state-map "<escape>" #'my/escape))

;; Wing
(defun my/wing-root ()
"Find the wing project's code/ dir by walking up from the current buffer."
(or (locate-dominating-file default-directory "build.bat")
    "C:/dev/wing/wing/code/")) ;; fallback

(defun my/wing-bin ()
  "Find the wing project's code/ dir by walking up from the current buffer."
  (or (locate-dominating-file default-directory "wing.exe")
      "C:/dev/wing/wing/bin/")) ;; fallback

(defun my/wing-compile (cmd)
  (let ((default-directory (my/wing-root)))
    (compile cmd)))

(defun my/piso-root ()
  "Find the wing project's code/ dir by walking up from the current buffer."
  (or (locate-dominating-file default-directory "piso.csproj")
      "C:/dev/wing/wing/tools/piso")) ;; fallback

(defvar my/devenv-path
  "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/devenv.exe")

(defconst my/wing-build-keys
'(("M-m"      . "build game")
  ("M-M"      . "build game2")
  ("C-M-m"    . "build game3")
  ("<f4>"     . "build engine")
  ("S-<f4>"   . "build engine2")
  ("S-<f5>"   . "build engine3")
  ("<f3>"     . "build main")
  ("S-<f3>"   . "build main2")
  ("<f1>"     . "clean")
  ("<f2>"     . "run")
  ("<f5>"     . "build platano")))

(with-eval-after-load 'cc-mode
  (dolist (map (list c-mode-map c++-mode-map))
    (pcase-dolist (`(,key . ,cmd) my/wing-build-keys)
      (keymap-set map key
                  (lambda () (interactive) (my/wing-compile cmd))))))

;; Startup
(setq initial-buffer-choice
      (lambda ()
        (or (ignore-errors
              (bookmark-jump "wing-code")
              (current-buffer))
            (get-scratch-buffer-create))))

;; Org Mode
(with-eval-after-load 'org
  (setq org-directory
        (if (eq system-type 'windows-nt) "C:/dev/org/" "~/dev/org/"))
  (setq org-src-fontify-natively t
        org-src-tab-acts-natively t)

  (let* ((dir (expand-file-name "gamedev/" org-directory))
         (default "* %?\n%U\n%a\n")
         (notes
          '(("e" "DoomEmacs note" "doomemacs")
            ("b" "Blender note" "blender")
            ("p" "SubstancePainter note" "substancepainter")
            ("x" "Graphics note" "graphics")
            ("P" "Performance note" "performance")
            ("c" "Collision note" "collision")
            ("f" "Phantom note" "phantom")
            ("r" "Reverse Engineering note" "reverseengineering")
            ("F" "Formulas note" "formulas")
            ("i" "MicroUI note" "microui")
            ("s" "Shader note" "shaders")
            ("t" "Troubleshooting note" "troubleshooting")
            ("G" "OpenGL note" "opengl")
            ("v" "Vulkan note" "vulkan")
            ("d" "D3D11 note" "d3d11")
            ("n" ".NET note" "dotnet")
            ("m" "Math note" "math")
            ("D" "DOS note" "dosdev")
            ("o" "Org note" "orgmode")
            ("w" "Wing note" "wing"
             "* %?\n%U\n%a\n**Tasks:** [/]\n  - [ ] ")
            ("C" "C note" "c")
            ("A" "Advanced C note" "advanced-c")
            ("+" "C++ note" "cpp")
            ("#" "C# note" "c-sharp")
            ("a" "Assembly note" "assembly")
            ("h" "Git note" "git")
            ("g" "Gotcha" "gotchas"))))
    (setq org-capture-templates
          (cons '("g" "Gamedev note...")
                (mapcar
                 (pcase-lambda (`(,key ,title ,file ,tmpl))
                   `(,(concat "g" key) ,title entry
                     (file+headline ,(concat dir file ".org") "Inbox")
                     ,(or tmpl default)))
                 notes)))))

(with-eval-after-load 'dired
  (remove-hook 'dired-mode-hook #'dired-omit-mode))

;; Notes
(defvar my/fixme-modes '(c++-mode c-mode asm-mode emacs-lisp-mode))

(defface font-lock-fixme-face     '((t :foreground "Yellow" :weight bold :underline t)) "TODO face.")
(defface font-lock-study-face     '((t :foreground "Yellow" :weight bold :underline t)) "STUDY face.")
(defface font-lock-important-face '((t :foreground "Yellow" :weight bold :underline t)) "IMPORTANT face.")
(defface font-lock-note-face      '((t :foreground "Red"    :weight bold :underline t)) "NOTE face.")

(dolist (mode my/fixme-modes)
  (font-lock-add-keywords
   mode
   '(("\\<\\(TODO\\)"      1 'font-lock-fixme-face t)
     ("\\<\\(STUDY\\)"     1 'font-lock-study-face t)
     ("\\<\\(IMPORTANT\\)" 1 'font-lock-important-face t)
     ("\\<\\(NOTE\\)"      1 'font-lock-note-face t))))

(with-eval-after-load 'hl-todo
  (setq hl-todo-keyword-faces
        (cons '("NOTE" . "Red")
              (assoc-delete-all "NOTE"
                                (assoc-delete-all "TODO" hl-todo-keyword-faces)))))

(defun my/insert-note-comment ()
  (interactive)
  (insert "// NOTE(trist007): "))

(defun my/insert-todo-comment ()
  "Insert a TODO tag."
  (interactive)
  (insert "// TODO(trist007): "))

(keymap-global-set "M-y" #'my/insert-note-comment)
(keymap-global-set "M-t" #'my/insert-todo-comment)

(add-hook 'eglot-managed-mode-hook
          (lambda () (eglot-inlay-hints-mode -1)))

;; Custom faces syntax highlighting
(custom-set-faces
 ;; eglot
 '(eglot-semantic-defaultLibrary ((t :foreground "#ba55d3")))
 '(eglot-semantic-readonly       ((t :foreground "#adff2f")))

 ;; dired
 '(diredfl-number     ((t :foreground "#ba55d3")))
 '(diredfl-read-priv  ((t :foreground "#1e90ff")))
 '(diredfl-write-priv ((t :foreground "#a020f0")))
 '(diredfl-exec-priv  ((t :foreground "#00ff00")))

 ;; marginalia
 '(marginalia-file-priv-read  ((t :foreground "#1e90ff")))
 '(marginalia-file-priv-write ((t :foreground "#a020f0")))
 '(marginalia-file-priv-exec  ((t :foreground "#00ff00")))
 '(marginalia-number          ((t :foreground "#ba55d3")))
 '(marginalia-size            ((t :foreground "#ba55d3")))

 ;; doxygen keywords
 '(font-lock-doc-markup-face ((t :foreground "#ff0000")))

 ;; magit
 '(magit-branch-remote  ((t :foreground "#9370db")))
 '(magit-branch-current ((t :foreground "#9370db")))
 '(magit-branch-local   ((t :foreground "#ff0000"))))

;; Shader file syntax highlighting
(add-to-list 'auto-mode-alist '("\\.spvasm\\'" . asm-mode))
(display-time-mode 1)

(elpaca (hlsl-mode :host github :repo "xeechou/hlsl-mode.el")
  (dolist (pattern '("\\.hlsl\\'" "\\.fx\\'" "\\.fxh\\'" "\\.vs\\'" "\\.ps\\'"
                     "\\.hs\\'" "\\.ds\\'" "\\.cs\\'" "\\.ms\\'" "\\.as\\'"))
    (add-to-list 'auto-mode-alist (cons pattern 'hlsl-mode))))

(elpaca (slang-mode :host github :repo "k1ngst0m/slang-mode")
  (dolist (pattern '("\\.slang\\'" "\\.sl\\'" "\\.slangh\\'"))
    (add-to-list 'auto-mode-alist (cons pattern 'slang-mode))))

(elpaca (glsl-mode :host github :repo "jimhourihan/glsl-mode")
  (dolist (pattern '("\\.glsl\\'" "\\.vert\\'" "\\.frag\\'" "\\.geom\\'"
                     "\\.comp\\'" "\\.tesc\\'" "\\.tese\\'"))
    (add-to-list 'auto-mode-alist (cons pattern 'glsl-mode))))
