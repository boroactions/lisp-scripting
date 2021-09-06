exec $LISP_BIN \
     --norc \
     --eval "(progn (defparameter %%stdout%% *standard-output*) \
                    (setf *standard-output* (make-broadcast-stream)))" \
     --load "$SCRIPTING_DIR/scripting.lisp" \
     --eval "(setf *standard-output* %%stdout%%)" \
     --shell "$LISP_SCRIPT" \
     -- $@
