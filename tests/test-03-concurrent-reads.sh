#!/bin/bash

gitolize.sh \
  -w \
  "file://$GIT_REPOSITORY" \
  bash -c 'echo "test string" > "$GITOLIZE_DIRECTORY/test_file"'

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
        cat "$GITOLIZE_DIRECTORY/test_file"
      ' \
    -- \
    $(seq 10)

rm -r "$GIT_REPOSITORY"
