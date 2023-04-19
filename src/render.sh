#!/usr/bin/env bash

function set-output() {
  if [ -f "$OUTPUT" ]; then
    echo "file=$OUTPUT" >> "$GITHUB_OUTPUT"

    # @see https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings
    EOF=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)

    {
      echo "debug=<<$EOF"
      sed '2d' "$OUTPUT"
      echo "$EOF"
    } >> "$GITHUB_OUTPUT"

    # {
    #   echo "content=<<$EOF"
    #   cat "$OUTPUT"
    #   echo "$EOF"
    # } >> "$GITHUB_OUTPUT"
  else
    echo "[DEBUG] Output file not found, skipping outputs" >&2
  fi
}

function render() {
  set -eo pipefail

  # Validation

  [ -n "$TEMPLATE" ] || {
    echo "[ERROR] Template is required" >&2
    return 1
  }

  for var in Template Data Filters Tests Customize; do
    VAR="${var^^}"
    val="${!VAR}"
    [ -z "$val" ] || [ -f "$val" ] || {
      echo "[ERROR] $var file not found: $val" >&2
      return 2
    }
  done

  [ -z "$UNDEFINED" ] || [ "$UNDEFINED" = true ] || [ "$UNDEFINED" = false ] || {
    echo "[ERROR] Undefined must be 'true' or 'false' but received $UNDEFINED" >&2
    return 3
  }

  # Main
  trap set-output EXIT

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

  set -x

  which j2
  echo "[DEBUG] ${COMMAND[*]}" >&2
  "${COMMAND[@]}"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  render
  exit $?
fi
