#!/usr/bin/env bats

# shellcheck source=../render.sh
source "$BATS_TEST_DIRNAME/../src/render.sh"

function setup() {
  export J2_CMD_FILE="$BATS_TEST_TMPDIR/j2.cmd"
  export J2_ENV_FILE="$BATS_TEST_TMPDIR/j2.env"

  # Inject a mock j2 cli
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  {
    echo 'echo "$*" > "'$J2_CMD_FILE'"'
    echo 'env > "'$J2_ENV_FILE'"'
  } > "$BATS_TEST_TMPDIR/bin/j2"
  chmod +x "$BATS_TEST_TMPDIR/bin/j2"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

  # Template is required (per action.yml)
  TEMPLATE="$BATS_TEST_TMPDIR/template.j2"
  touch "$TEMPLATE"
  export TEMPLATE

  # Output has a default (per action.yml)
  OUTPUT="$BATS_TEST_TMPDIR/output.yml"
  export OUTPUT

  # Undefined defaults to false (per action.yml), but empty also works
}

function teardown() {
  :
}

@test "it should error out if template is empty" {
  unset TEMPLATE

  run render

  [ $status -eq 1 ]
}

@test "it should error out if template is not a file" {
  rm -f "$TEMPLATE"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if data is not a file" {
  export DATA="$BATS_TEST_TMPDIR/data.yml"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if filters is not a file" {
  export FILTERS="$BATS_TEST_TMPDIR/filters.py"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if tests is not a file" {
  export TESTS="$BATS_TEST_TMPDIR/tests.py"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if customize is not a file" {
  export CUSTOMIZE="$BATS_TEST_TMPDIR/customize.py"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if undefined is not a boolean" {
  export UNDEFINED="notaboolean"

  run render

  [ $status -eq 3 ]
}

@test "it should not pass the undefined flag if undefined is false" {
  export UNDEFINED="false"

  run render

  echo "$output"

  [ $status -eq 0 ]
  [ -f "$J2_CMD_FILE" ]
  grep -vq -- '--undefined' "$J2_CMD_FILE"
}

@test "it should export environment variables to the cli" {
  export ENV_VARS='FOO=bar
  BAR=baz
  BAZ=quo'

  run render

  [ $status -eq 0 ]
  [ -f "$J2_CMD_FILE" ] && [ -f "$J2_ENV_FILE" ]
  grep -q -- '-e FOO' "$J2_CMD_FILE"
  grep -q 'FOO=bar' "$J2_ENV_FILE"
  grep -q -- '-e BAR' "$J2_CMD_FILE"
  grep -q 'BAR=baz' "$J2_ENV_FILE"
  grep -q -- '-e BAZ' "$J2_CMD_FILE"
  grep -q 'BAZ=quo' "$J2_ENV_FILE"
}

@test "it should pass all arguments to the j2 cli" {
  export FILTERS="$BATS_TEST_TMPDIR/filters.py"
  export TESTS="$BATS_TEST_TMPDIR/tests.py"
  export CUSTOMIZE="$BATS_TEST_TMPDIR/customize.py"
  export DATA="$BATS_TEST_TMPDIR/data.yml"

  touch "$FILTERS"
  touch "$TESTS"
  touch "$CUSTOMIZE"
  touch "$DATA"

  export UNDEFINED=true
  export ENV_VARS='FOO=foo'

  run render

  [ $status -eq 0 ]
  grep -q -- "--filters $FILTERS" "$J2_CMD_FILE"
  grep -q -- "--tests $TESTS" "$J2_CMD_FILE"
  grep -q -- "--customize $CUSTOMIZE" "$J2_CMD_FILE"
  grep -q -- "-e FOO" "$J2_CMD_FILE"
  grep -q -- "--undefined" "$J2_CMD_FILE"
  grep -qE "$TEMPLATE $DATA\$" "$J2_CMD_FILE"
}
