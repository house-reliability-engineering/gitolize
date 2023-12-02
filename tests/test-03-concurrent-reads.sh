#!/bin/bash

gitolize.sh \
  -w \
  "file://$GIT_REPOSITORY" \
  bash -c 'echo "test string" > test_file'

want_command_output \
  "$(
    yes "test string" |
    head -n 10
  )" \
  parallel \
    -j 10 \
    gitolize.sh \
      "file://$GIT_REPOSITORY" \
      bash -c '
        sleep 1
        cat test_file
      ' \
    -- \
    $(seq 10)

rm -r "$GIT_REPOSITORY"
