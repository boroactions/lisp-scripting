#!/bin/sh

SCRIPTING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

LISP_SCRIPT=$1
export LISP_SCRIPTING_SCRIPT_PATH=$LISP_SCRIPT
shift
