# janet-completion

`janet-completion.el` provides completion support for Janet by communicating with the `janet-complete` module in a running `inf-janet` REPL.

Completion candidates are retrieved from the REPL and can be used in both the REPL buffer and in Janet source files connected to the REPL.

## Requirements

1. Install the `janet-complete` module for Janet:

```sh
[sudo] jpm install https://github.com/tttuuu888/janet-complete.git
```

2. Ensure the REPL has loaded the module by evaluating `(use complete)`.

You can automate this by setting the Janet profile:

```sh
export JANET_PROFILE=$HOME/.config/janet/init.janet
```

And adding the following to your init.janet:

```
(use complete)
```

## Installation

Install `janet-completion.el` manually or via vc-use-package (Emacs 30+):

```emacs-lisp
(use-package janet-completion
  :vc
  (:url "https://github.com/tttuuu888/janet-completion" :branch "main" :rev :newest))

```
