#!/bin/bash

LOCAL_DIRECTORY="$(mktemp -d)"

gitolize.sh \
  -l "$LOCAL_DIRECTORY" \
  -r "file://$GIT_REPOSITORY" \
  -w \
  bash -c 'echo "test string" > "$GITOLIZE_DIRECTORY/test_file"'

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show "main:test_file"

want_file_contents \
  "test string" \
  "$LOCAL_DIRECTORY/test_file"

want_command_output \
  "test string" \
  gitolize.sh \
    -l "$LOCAL_DIRECTORY" \
    -r "file://$GIT_REPOSITORY" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/test_file"'

rm -r "$LOCAL_DIRECTORY" "$GIT_REPOSITORY"
