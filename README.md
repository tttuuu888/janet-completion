# janet-completion

`janet-completion.el` provides completion support for Janet by communicating
with the running `inf-janet` REPL.

Candidates are generated using Janet's built-in `all-bindings` function.

Completion works in the REPL buffer and in Janet source files.

## Requirements

- `inf-janet`
- A Janet version that has the `all-bindings` function

## Installation

Install `janet-completion.el` manually, or via `vc-use-package` (Emacs 30+).
Then enable `janet-completion-mode`:

```emacs-lisp
(use-package janet-completion
  :vc
  (:url "https://github.com/tttuuu888/janet-completion" :branch "main" :rev :newest)
  :config
  (janet-completion-mode 1))

```

`janet-completion-mode` is a global minor mode that enables completion in
`janet-mode` and `inf-janet` REPL buffers.
