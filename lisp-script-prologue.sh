#!/bin/sh

SCRIPTING_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"


LISP_SCRIPT=$1
export LISP_SCRIPTING_SCRIPT_PATH=$LISP_SCRIPT
shift
