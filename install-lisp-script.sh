#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

LISP_BIN=$1
LISP_SCRIPT_BIN=$2

function is_sbcl() {
    LISP_TYPE=$(echo "(require 'uiop) (format t \"~A\" (uiop:implementation-type))" | \
                    $LISP_BIN --script 2>/dev/null)
    if [ "$LISP_TYPE" = "SBCL" ]; then
        return 0
    fi
    return 1
}


function is_ccl() {
    LISP_TYPE=$(echo "(format nil \"~A\" (uiop:implementation-type))" | \
                    $LISP_BIN --quiet --no-init --eval "(require 'asdf)" \
                              --batch 2>/dev/null | xargs)
    if [ "$LISP_TYPE" = "CCL" ]; then
        return 0
    fi
    return 1
}


function is_ecl() {
    LISP_TYPE=$($LISP_BIN \
                        --norc \
                        --eval "(let ((out *standard-output*)) \
                                  (setf *standard-output* (make-broadcast-stream)) \
                                  (require 'asdf) \
                                  (setf *standard-output* out))" \
                        --eval "(format t \"~A\" (uiop:implementation-type))" \
                        --eval "(uiop:quit)" \
                        --shell 2>&1)
    if [ "$LISP_TYPE" = "ECL" ]; then
        return 0
    fi
    return 1
}

LISP_SCRIPT_DIR="$(dirname "$LISP_SCRIPT_BIN")"


mkdir -p "$LISP_SCRIPT_DIR/"
cp "$SCRIPT_DIR/scripting.lisp" "$LISP_SCRIPT_DIR/"


cat "$SCRIPT_DIR/lisp-script-prologue.sh" > $LISP_SCRIPT_BIN
printf "LISP_BIN=$LISP_BIN\n" >> $LISP_SCRIPT_BIN
chmod +x $LISP_SCRIPT_BIN

if is_sbcl; then
    cat "$SCRIPT_DIR/sbcl.sh" >> $LISP_SCRIPT_BIN
    exit 0
fi

if is_ccl; then
    cat "$SCRIPT_DIR/ccl.sh" >> $LISP_SCRIPT_BIN
    exit 0
fi

if is_ecl; then
    cat "$SCRIPT_DIR/ecl.sh" >> $LISP_SCRIPT_BIN
    exit 0
fi

echo "Unrecognized Lisp: $LISP_BIN"
exit 1
