echo "" | exec $LISP_BIN \
               --quiet --no-init \
               --load "$SCRIPTING_DIR/scripting.lisp" \
               --eval "(skip-next-shebang)" \
               --load "$LISP_SCRIPT" \
               --batch \
               -- $@
