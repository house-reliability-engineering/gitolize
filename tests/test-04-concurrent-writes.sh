#!/bin/bash

OUTPUTS="$(mktemp -d)"

parallel \
  -i \
  -j 9 \
  bash -c "
    gitolize.sh \
      -r 'file://$GIT_REPOSITORY' \
      -w \
      bash -c '
        sleep 1
        echo test string {} >> \"\$GITOLIZE_DIRECTORY/test_file\"
        echo test_file updated
      ' \
      &> $OUTPUTS/{}.out
  " \
  -- \
  $(seq -w 9) ||
true

OUTPUT="$(cat "$OUTPUTS"/*.out)"

want_command_output \
  1 \
  grep --count --line-regexp --fixed-strings "test_file updated" \
  <<< "$OUTPUT"

want_command_output \
  8 \
  grep --count --line-regexp --fixed-strings "locking failed" \
  <<< "$OUTPUT"

want_command_output \
  "test string n" \
  bash -c "git -C "$GIT_REPOSITORY" show main:test_file | tr [0-9] n"

rm -r "$OUTPUTS" "$GIT_REPOSITORY"
