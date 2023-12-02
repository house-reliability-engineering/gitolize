#!/bin/bash

LOCAL_DIRECTORY="$(mktemp -d)"

gitolize.sh \
  -l "$LOCAL_DIRECTORY" \
  -w \
  "file://$GIT_REPOSITORY" \
  bash -c "echo 'test string' > test_file"

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show "main:test_file"

want_file_contents \
  "test string" \
  "$LOCAL_DIRECTORY/test_file"

want_command_output \
  "test string" \
  gitolize.sh -l "$LOCAL_DIRECTORY" "file://$GIT_REPOSITORY" cat test_file

rm -r "$LOCAL_DIRECTORY" "$GIT_REPOSITORY"
