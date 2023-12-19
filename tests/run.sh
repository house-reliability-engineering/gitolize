#!/bin/bash

set -o nounset

log() {
	echo "$(date --utc --iso-8601=ns) $@" 1>&2
}

count() {
 tail -n +2 <<< "$@" | wc -l
}

cd "$(dirname "$0")"

TESTS=
FAILED_TESTS=

export BASH_ENV="./init.sh"

for TEST_SCRIPT in ./test-*.sh
do
  TESTS="$TESTS"$'\n'"$TEST_SCRIPT"
  log "starting $TEST_SCRIPT"
  bash "$TEST_SCRIPT"
  EXIT_CODE=$?
  log "$TEST_SCRIPT completed with exit code $EXIT_CODE"
  if [[ "$EXIT_CODE" -ne 0 ]]
    then
      FAILED_TESTS="$FAILED_TESTS"$'\n'"$TEST_SCRIPT"
    fi
  done

if [[ "$FAILED_TESTS" ]]
then
  log "$(count "$FAILED_TESTS") of $(count "$TESTS") tests failed:$FAILED_TESTS"
  exit 1
else
  log "$(count "$TESTS") tests successful"
fi
