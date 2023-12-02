#!/bin/bash

OUTPUT="$(
  parallel \
    -i \
    -j 9 \
    gitolize.sh \
      -w \
      "file://$GIT_REPOSITORY" \
      bash -c '
	sleep 1
	echo test string {} > "$GITOLIZE_DIRECTORY/test_file"
      ' \
    -- \
    $(seq 9) \
    2>&1 || \
    true
)" 

want_command_output \
  8 \
  grep --count --line-regexp --fixed-strings "locking failed" \
  <<< "$OUTPUT"

want_command_output \
  "test string n" \
  bash -c "git -C "$GIT_REPOSITORY" show main:test_file | tr [0-9] n"

rm -r "$GIT_REPOSITORY"
