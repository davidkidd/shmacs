# A minimal terminal Emacs launcher. No init file, builtins only.
# Source this file from Bash or paste it into your .bashrc.
#
# For quick file edits and directory operations, without loading your
# usual config. Not intended to replace a full Emacs setup.
#
# e [file ...]       Open a clean terminal Emacs session.
# d                  Open Dired in the current directory (alias for 'e .').
# D [directory]      Open two side-by-side Dired panes, like Midnight Commander.
#
# D opens the current directory in both panes unless a directory is supplied,
# in which case that directory opens in the right-hand pane.
# Within Emacs, C-c d opens the dual-pane layout too.
#
# Some keybindings may need configuration in your terminal.
# Example Ghostty settings (put these in Ghostty's config):
# -- BEGIN GHOSTTY CONFIG --
# app-notifications = no-clipboard-copy
# cursor-color = #ffffff
# cursor-text = #000000
# cursor-style = block
# shell-integration-features = no-cursor
# keybind = ctrl+,=esc:b
# keybind = ctrl+.=esc:f
# keybind = ctrl+backspace=text:\x1b\x7f
# -- END GHOSTTY CONFIG --

e() {
    local shmacs_setup
    IFS= read -r -d '' shmacs_setup <<'ELISP' || :
(progn
  ;; Basic behaviour and terminal integration.
  (mapc #'require '(dired text-mode term/xterm))
  (menu-bar-mode -1)
  (dolist (mode '(xterm-mouse-mode delete-selection-mode
                  fido-vertical-mode which-key-mode))
    (funcall mode 1))
  (setq inhibit-startup-screen t
        ring-bell-function #'ignore
        delete-by-moving-to-trash t
        use-short-answers t
        initial-scratch-message ";; scratch\n\n"
        completion-styles '(flex basic)
        dired-dwim-target t
        select-enable-clipboard t)
  (set-frame-parameter nil 'tty-color-mode 'never)
  (set-terminal-parameter nil 'xterm--set-selection t)
  (with-current-buffer "*scratch*"
    (erase-buffer)
    (insert initial-scratch-message)
    (set-buffer-modified-p nil))

  ;; Editing helpers.
  (defun shmacs-duplicate-dwim ()
    "Duplicate the current line or put a copy of the region below it."
    (interactive)
    (if (use-region-p)
        (let ((text (buffer-substring (region-beginning) (region-end))))
          (goto-char (region-end))
          (insert "\n" text))
      (save-excursion
        (let ((text (buffer-substring (line-beginning-position)
                                      (line-end-position))))
          (end-of-line)
          (insert "\n" text)))))

  (defun shmacs-move-lines (direction)
    "Move the current line or selected lines one line up or down."
    (barf-if-buffer-read-only)
    (let* ((active (use-region-p))
           (start (save-excursion
                    (when active (goto-char (region-beginning)))
                    (line-beginning-position)))
           (end (save-excursion
                  (when active (goto-char (region-end)))
                  (if (and active (bolp) (> (point) start))
                      (point) (line-beginning-position 2))))
           (offset (- (point) start))
           (mark-offset (and active (- (mark) start)))
           (add-newline (not (eq (char-before (point-max)) 10)))
           destination)
      (when (or (= start end)
                (if (< direction 0) (= start (point-min))
                  (= end (point-max))))
        (user-error "No more lines in that direction"))
      (atomic-change-group
        (when add-newline
          (save-excursion (goto-char (point-max)) (insert "\n"))
          (when (= end (1- (point-max))) (setq end (1+ end))))
        (save-excursion
          (if (< direction 0)
              (progn
                (goto-char start)
                (forward-line -1)
                (setq destination (point))
                (transpose-regions destination start start end))
            (goto-char end)
            (forward-line 1)
            (setq destination (+ start (- (point) end)))
            (transpose-regions start end end (point))))
        (when add-newline
          (save-excursion (goto-char (point-max)) (delete-char -1))))
      (goto-char (min (point-max) (+ destination offset)))
      (when active
        (set-mark (min (point-max) (+ destination mark-offset)))
        (setq deactivate-mark nil))))

  ;; One details setting for existing and future Dired buffers.
  (defvar shmacs-dired-hide-details t)
  (defun shmacs-apply-dired-details ()
    (dired-hide-details-mode (if shmacs-dired-hide-details 1 -1)))
  (add-hook 'dired-mode-hook #'shmacs-apply-dired-details)
  (defun shmacs-toggle-dired-details ()
    "Toggle details together in all Dired buffers."
    (interactive)
    (setq shmacs-dired-hide-details (not dired-hide-details-mode))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'dired-mode)
          (shmacs-apply-dired-details)))))

  (defun shmacs-dual-dired (&optional right-directory)
    "Replace the layout with side-by-side Dired windows."
    (interactive)
    (let ((left-directory default-directory))
      (delete-other-windows)
      (dired left-directory)
      (with-selected-window (split-window-right)
        (dired (or right-directory left-directory)))))

  ;; Bindings, grouped by scope.
  (dolist (binding '(("C-c [" . previous-buffer)
                     ("C-c ]" . next-buffer)
                     ("M-o" . other-window)
                     ("C-," . backward-word)
                     ("C-." . forward-word)
                     ("C-<backspace>" . backward-kill-word)
                     ("C-M-l" . shmacs-duplicate-dwim)
                     ("C-c d" . shmacs-dual-dired)))
    (global-set-key (kbd (car binding)) (cdr binding)))
  (dolist (binding '(("h" . dired-up-directory)
                     ("l" . dired-find-file)
                     ("(" . shmacs-toggle-dired-details)))
    (define-key dired-mode-map (kbd (car binding)) (cdr binding)))
  (dolist (map (list text-mode-map prog-mode-map))
    (define-key map (kbd "M-p") (lambda () (interactive) (shmacs-move-lines -1)))
    (define-key map (kbd "M-n") (lambda () (interactive) (shmacs-move-lines 1)))))
ELISP
    command emacs -Q -nw --eval "$shmacs_setup" "$@"
}

alias d="e ."

# Dual-pane Dired: current directory on the left, optional target on the right.
D() (
    if (( $# > 1 )); then
        printf 'Usage: D [directory]\n' >&2
        return 2
    fi
    EMACS_DIRED_RIGHT_DIRECTORY=$(cd -- "${1:-.}" && pwd -P) || return
    export EMACS_DIRED_RIGHT_DIRECTORY
    e --eval '(shmacs-dual-dired (getenv "EMACS_DIRED_RIGHT_DIRECTORY"))'
)
