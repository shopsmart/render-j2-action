#!/usr/bin/env bash

function set-output() {
  if [ -f "$OUTPUT" ]; then
    echo "file=$OUTPUT" >> "$GITHUB_OUTPUT"

    # @see https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings
    EOF=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)
    {
      echo "content<<$EOF"
      cat "$OUTPUT"
      echo "$EOF"
    } >> "$GITHUB_OUTPUT"
  else
    echo "[DEBUG] Output file not found, skipping outputs" >&2
  fi

  rm -rf "$TEMP_DIRECTORY"
}

function render() {
  set -eo pipefail

  if [ "${DEBUG:-false}" = 'true' ]; then
    set -x
  fi

  # Validation

  [ -n "$TEMPLATE" ] || {
    echo "[ERROR] Template is required" >&2
    return 1
  }

  for var in Template Filters Tests Customize; do
    VAR="${var^^}"
    val="${!VAR}"
    if [ -n "$val" ] && ! [ -f "$val" ]; then
      echo "[ERROR] $var file not found: $val" >&2
      return 2
    fi
  done

  [ -z "$UNDEFINED" ] || [ "$UNDEFINED" = true ] || [ "$UNDEFINED" = false ] || {
    echo "[ERROR] Undefined must be 'true' or 'false' but received $UNDEFINED" >&2
    return 3
  }

  TEMP_DIRECTORY="$(mktemp -d)"
  export TEMP_DIRECTORY

  if [ -n "$DATA" ]; then
    local ext=''
    local data_files=()
    while read -r file; do
      [ -n "$file" ] || continue
      [ -n "$ext"  ] || ext="${file##*.}"
      [ -f "$file" ] || {
        echo "[ERROR] Data file not found: $file" >&2
        return 2
      }
      data_files+=("$file")
    done <<< "$DATA"

    if [ ${#data_files[@]} -gt 1 ]; then
      DATA="$TEMP_DIRECTORY/data.$ext"
      echo "[DEBUG] Merging ${data_files[*]} to $DATA" >&2
      confmerge "${data_files[@]}" "$DATA"
    fi
  fi

  # Main
  trap set-output EXIT

  echo "[DEBUG] $(j2 --version)" >&2
  echo "[DEBUG] $(confmerge --version)" >&2

  local COMMAND=(j2 -o "$OUTPUT")

  [ "$UNDEFINED" != "true" ] || COMMAND+=(--undefined)

  [ -z "$FORMAT"    ] || COMMAND+=(-f "$FORMAT")
  [ -z "$FILTERS"   ] || COMMAND+=(--filters "$FILTERS")
  [ -z "$TESTS"     ] || COMMAND+=(--tests "$TESTS")
  [ -z "$CUSTOMIZE" ] || COMMAND+=(--customize "$CUSTOMIZE")

  [ -z "$ENV_VARS" ] || {
    while IFS= read -r env_var; do
      # Remove blank space around the string
      env_var="$(echo "${env_var?}" | xargs)"
      var="${env_var%=*}"

      [ -n "${env_var?}" ] || continue

      # Export for the j2 cli
      export "${env_var?}"

      COMMAND+=(-e "$var")
    done <<<"$ENV_VARS"
  }

  COMMAND+=("$TEMPLATE")
  [ -z "$DATA" ] || COMMAND+=("$DATA")

  echo "[DEBUG] ${COMMAND[*]}" >&2
  "${COMMAND[@]}"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  render
  exit $?
fi
