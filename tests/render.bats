#!/usr/bin/env bats

# shellcheck source=../render.sh
source "$BATS_TEST_DIRNAME/../render.sh"

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
  INPUT_TEMPLATE="$BATS_TEST_TMPDIR/template.j2"
  touch "$INPUT_TEMPLATE"
  export INPUT_TEMPLATE

  # Output has a default (per action.yml)
  INPUT_OUTPUT="$BATS_TEST_TMPDIR/output.yml"
  export INPUT_OUTPUT

  # Undefined defaults to false (per action.yml), but empty also works
}

function teardown() {
  :
}

@test "it should error out if template is empty" {
  unset INPUT_TEMPLATE

  run render

  [ $status -eq 1 ]
}

@test "it should error out if template is not a file" {
  rm -f "$INPUT_TEMPLATE"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if data is not a file" {
  export INPUT_DATA="$BATS_TEST_TMPDIR/data.yml"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if filters is not a file" {
  export INPUT_FILTERS="$BATS_TEST_TMPDIR/filters.py"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if tests is not a file" {
  export INPUT_TESTS="$BATS_TEST_TMPDIR/tests.py"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if customize is not a file" {
  export INPUT_CUSTOMIZE="$BATS_TEST_TMPDIR/customize.py"

  run render

  [ $status -eq 2 ]
}

@test "it should error out if undefined is not a boolean" {
  export INPUT_UNDEFINED="notaboolean"

  run render

  [ $status -eq 3 ]
}

@test "it should not pass the undefined flag if undefined is false" {
  export INPUT_UNDEFINED="false"

  run render

  echo "$output"

  [ $status -eq 0 ]
  [ -f "$J2_CMD_FILE" ]
  grep -vq -- '--undefined' "$J2_CMD_FILE"
}

@test "it should export environment variables to the cli" {
  export INPUT_ENV_VARS='FOO=bar
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
  export INPUT_FILTERS="$BATS_TEST_TMPDIR/filters.py"
  export INPUT_TESTS="$BATS_TEST_TMPDIR/tests.py"
  export INPUT_CUSTOMIZE="$BATS_TEST_TMPDIR/customize.py"
  export INPUT_DATA="$BATS_TEST_TMPDIR/data.yml"

  touch "$INPUT_FILTERS"
  touch "$INPUT_TESTS"
  touch "$INPUT_CUSTOMIZE"
  touch "$INPUT_DATA"

  export INPUT_UNDEFINED=true
  export INPUT_ENV_VARS='FOO=foo'

  run render

  [ $status -eq 0 ]
  grep -q -- "--filters $INPUT_FILTERS" "$J2_CMD_FILE"
  grep -q -- "--tests $INPUT_TESTS" "$J2_CMD_FILE"
  grep -q -- "--customize $INPUT_CUSTOMIZE" "$J2_CMD_FILE"
  grep -q -- "-e FOO" "$J2_CMD_FILE"
  grep -q -- "--undefined" "$J2_CMD_FILE"
  grep -qE "$INPUT_TEMPLATE $INPUT_DATA\$" "$J2_CMD_FILE"
}
