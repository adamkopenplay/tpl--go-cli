#!/bin/bash

DEFAULT_GIT_HOST="github.com"
DEFAULT_GO_VERSION="1.18"
DEFAULT_REGISTRY="docker.io"
NIL_VALUE="nil"

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

POSITIONAL_ARGS=()
OPT_KEYS=()
OPT_VALUES=()

RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COLOUR='\033[0;0m'

BOLD='\033[0;1m'

function __newln() {
  echo ""
}

function __errlns() {
  for var in "$@"
  do
      echo -e "$RED$var$NO_COLOUR"
  done
}

function __infolns() {
  for var in "$@"
  do
      echo -e "$NO_COLOUR$var$NO_COLOUR"
  done
}

function __successlns() {
  for var in "$@"
  do
      echo -e "$GREEN$var$NO_COLOUR"
  done
}

function __opt_exists() {
  if [ "$#" != "1" ]; then
    __errlns "Incorrect arguments to __opt_exists, got: ${@}"
    exit 1
  fi

  SEARCH="$1"

  VAL=$(__opt_by_key "$SEARCH")

  if [ "$VAL" == "$NIL_VALUE" ]; then
    return 1
  fi

  return 0
}

function __opt_by_key() {
  if [ "$#" != "1" ]; then
    __errlns "Incorrect arguments to __opt_by_key, got: ${@}"
    exit 1
  fi

  SEARCH="$1"

  for OPT_KEY_INDEX in "${!OPT_KEYS[@]}"; do 
    if [ "${OPT_KEYS[$OPT_KEY_INDEX]}" == "$SEARCH" ]; then 
      echo "${OPT_VALUES[$OPT_KEY_INDEX]}"
      return 0
    fi
  done

  echo "$NIL_VALUE"
  return 1
}


function __end_message() {
  __successlns "Done!"
  __successlns "Please check the git diff to see what has changed."
  __successlns "Delete this file if you're happy; otherwise revert the changes and rerun!"
}
function __replace_vars() {
  if [ "$#" != "3" ]; then
    __errlns "__replace_vars expects 3 args: 1=file, 2=key, 3=value"
  fi
  FILE="$1"
  KEY="$2"
  VAL="$3"

  if [ ! -f "$FILE" ]; then
    __errlns "File $FILE does not exist!"
    exit 1
  fi

  sed -i '' -e "s/<< $KEY >>/$VAL/g" "$FILE"
}

function __init_module() {
  if [ "$#" != "2" ]; then
    __errlns "__init_module expects 2 args: 1=go version, 2=repository name"
    exit 1
  fi

  GO_VERSION="$1"
  REPO="$2"
  docker run --rm -it -w "/srv" -v "$ROOT_DIR:/srv" golang:$GO_VERSION-alpine go mod init $REPO
  docker run --rm -it -w "/srv" -v "$ROOT_DIR:/srv" golang:$GO_VERSION-alpine go mod tidy
}

function __init_cobra() {
  if [ "$#" != "1" ]; then
    __errlns "__init_module expects 1 arg: 1=go version"
    exit 1
  fi

  GO_VERSION="$1"
  docker run --rm -it -w "/srv" -v "$ROOT_DIR:/srv" golang:$GO_VERSION-alpine sh -c "go install github.com/spf13/cobra-cli@latest && cobra-cli init ."
}

function __init() {
  
  ORG=`__opt_by_key "--org"`
  NAME=`__opt_by_key "--name"`
  REGISTRY=$DEFAULT_REGISTRY
  GO_VERSION=$DEFAULT_GO_VERSION
  GIT_HOST=$DEFAULT_GIT_HOST
  INIT_MODULE="true"
  INIT_COBRA="true"

  if ! __opt_exists "--org" || ! __opt_exists "--name"; then
    __errlns "--org=* and --name=* must be set"
    exit 1
  fi

  if __opt_exists "--go-version"; then
    GO_VERSION=`__opt_by_key "--go-version"`
  fi

  if __opt_exists "--registry"; then
    REGISTRY=`__opt_by_key "--registry"`
  fi

    if __opt_exists "--git-host"; then
    GIT_HOST=`__opt_by_key "--git-host"`
  fi

  if __opt_exists "--no-init"; then
    INIT_MODULE="false"
  fi

    if __opt_exists "--no-init" || __opt_exists "--no-cobra"; then
    INIT_COBRA="false"
  fi

  __infolns "      Using repo:  $GIT_HOST/$ORG/$NAME"
  __infolns "Using Go version:  $GO_VERSION"
  __infolns "Will init module:  $INIT_MODULE"
  __infolns " Will init cobra:  $INIT_COBRA" 

  echo ""

  CHOICE="$NIL_VALUE"

  while [[ ! "$CHOICE" =~ "[y|n|Y|N]" ]]
  do
    read -p "Should I continue (y/Y/n/N)?" CHOICE
    case "$CHOICE" in 
      y|Y )
        break
        ;;
      n|N )
        __errlns "Aborting..."
        exit 1
        ;;
      * )
        __errlns "Invalid choice, must be one of: y, Y, n, N"
        ;;
    esac
  done

  __replace_vars "$ROOT_DIR/Makefile" name "$NAME"
  __replace_vars "$ROOT_DIR/Makefile" git_host "$GIT_HOST"
  __replace_vars "$ROOT_DIR/Makefile" org "$ORG"
  __replace_vars "$ROOT_DIR/Makefile" docker_registry "$REGISTRY"

  __replace_vars "$ROOT_DIR/Dockerfile" name "$NAME"
  __replace_vars "$ROOT_DIR/Dockerfile" go_version "$GO_VERSION"

  __replace_vars "$ROOT_DIR/main.go" name "$NAME"

  if [ "$INIT_MODULE" != "true" ]; then
    __end_message
    exit 0
  fi

  __init_module "$GO_VERSION" "$GIT_HOST/$ORG/$NAME"

  if [ "$INIT_COBRA" != "true" ]; then
    __end_message
    exit 0
  fi

  __init_cobra "$GO_VERSION"
  __end_message
}

function main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -*=*|--*=*)
        # See: https://tldp.org/LDP/abs/html/string-manipulation.html
        # Search for "Substring Removal"
        # %=* anything matcheing =* is removed from back of string
        OPT_KEYS+=("${1%=*}") 

        # #*= anything matching *= is removed from from of string
        OPT_VALUES+=("${1#*=}")
        shift # past value
        ;;
     -*|--*)
        OPT_KEYS+=("$1")
        OPT_VALUES+=("true")
        shift # past argument
        ;;
      *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
  done

  set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

  __init "${@:2}"

  exit "$?"
}

main "${@}"
