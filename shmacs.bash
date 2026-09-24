# Basic, no init shell launcher for a minimal emacs setup.
# Source it directly or add to your .bashrc
#
# Just run 'e' to launch streamlined Emacs session.
#
# To jump straignt into dired, you can call 'd', which is just an alias to 'e .'
#
# To launch into a dual-pane, MC-style dired, call capital D.
# This will launch two dired buffers, side-by-side, with the current directory in both panes.
# If you supply a path (eg, D ~/another/directory), then the specified path will be in the right
# hand pane.
e() {
    command emacs -Q -nw --eval \
        '(progn
           (menu-bar-mode -1)
           (xterm-mouse-mode 1)
           (set-frame-parameter nil (quote tty-color-mode) (quote never))
           (setq inhibit-startup-screen t
                 initial-scratch-message ";; scratch\n\n"
                 dired-dwim-target t)
           (with-current-buffer "*scratch*"
             (erase-buffer)
             (insert initial-scratch-message)
             (set-buffer-modified-p nil))
           (global-set-key (kbd "C-c [") (quote previous-buffer))
           (global-set-key (kbd "C-c ]") (quote next-buffer))
           (global-set-key (kbd "M-o") (quote other-window))
           (fido-vertical-mode 1)
           (which-key-mode 1)
           (require (quote term/xterm))
           (set-terminal-parameter nil (quote xterm--set-selection) t)
           (setq select-enable-clipboard t)
           (require (quote dired))
           (define-key dired-mode-map (kbd "h") (quote dired-up-directory))
           (define-key dired-mode-map (kbd "l") (quote dired-find-file))
           (defun my/terminal-dual-dired (&optional right-directory)
             "Replace the layout with side-by-side Dired windows."
             (interactive)
             (let ((left-directory default-directory))
               (delete-other-windows)
               (dired left-directory)
               (let ((right (split-window-right)))
                 (with-selected-window right
                   (dired (or right-directory left-directory))))))
           (global-set-key (kbd "C-c d") (quote my/terminal-dual-dired)))' "$@"
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
    e --eval '(my/terminal-dual-dired (getenv "EMACS_DIRED_RIGHT_DIRECTORY"))'
)
