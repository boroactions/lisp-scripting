![tests](https://github.com/boroactions/lisp-scripting/actions/workflows/test.yaml/badge.svg)

# boroactions/lisp-scripting@v0

This GitHub action allows using Common Lisp in shell scripts with shebang:
```sh
#!/usr/bin/env lisps

(print 'hello)
```

SBCL, CCL and ECL are supported as host environments for scripting.

## Installation

You can use this utility for scripting on your personal machine too:
```sh
# if /usr/local/bin/ is in PATH and writable by a user
./install-lisp-script.sh sbcl /usr/local/bin/lisps
```
