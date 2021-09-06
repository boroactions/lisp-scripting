![tests](https://github.com/borodust/lisp-scripting/actions/workflows/test.yaml/badge.svg)

# borodust/lisp-scripting@v0

This GitHub action allows using Common Lisp in shell scripts with shebang:
```sh
#!/usr/bin/env lisps

(print 'hello)
```

SBCL, CCL and ECL are supported as host environments for scripting.
