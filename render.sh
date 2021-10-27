#!/usr/bin/env bash

function render() {
  set -exo pipefail

  local TEMPLATE="$INPUT_TEMPLATE"
  local DATA="$INPUT_DATA"
  local FORMAT="$INPUT_FORMAT"
  local ENV_VARS="$INPUT_ENV_VARS"
  local FILTERS="$INPUT_FILTERS"
  local TESTS="$INPUT_TESTS"
  local CUSTOMIZE="$INPUT_CUSTOMIZE"
  local UNDEFINED="$INPUT_UNDEFINED"
  local OUTPUT="$INPUT_OUTPUT"

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

  function set_output() {
    if [ -f "$OUTPUT" ]; then
      echo "::set-output name=file::$OUTPUT"
    fi
  }
  trap set_output EXIT

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

  which j2
  echo "[DEBUG] ${COMMAND[*]}" >&2
  exec "${COMMAND[@]}"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  render
  exit $?
fi
