exec $LISP_BIN \
     --noinform --disable-ldb --lose-on-corruption --end-runtime-options \
     --load "$SCRIPTING_DIR/scripting.lisp" \
     --script "$LISP_SCRIPT" \
     $@
