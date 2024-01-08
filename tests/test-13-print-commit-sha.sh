#!/bin/bash

OUTPUT="$(
  gitolize.sh \
    -c \
    -r "file://$GIT_REPOSITORY" \
    -w \
    true \
  2>&1
)"

want_command_output \
  "$OUTPUT" \
  bash -c "echo 'gitolize.sh: commit: $(git -C "$GIT_REPOSITORY" rev-parse HEAD)'"

rm -r "$GIT_REPOSITORY"
