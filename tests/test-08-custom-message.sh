#!/bin/bash

gitolize.sh \
  -m "message 1" \
  -r "file://$GIT_REPOSITORY" \
  -w \
  bash -c 'echo "test string 1" > "$GITOLIZE_DIRECTORY/test_file"'

want_command_output \
  $'message 1\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

gitolize.sh \
  -m "message 2" \
  -r "file://$GIT_REPOSITORY" \
  -w \
  bash -c 'echo "test string 2" >> "$GITOLIZE_DIRECTORY/test_file"'

want_command_output \
  $'message 2\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B -- test_file

rm -r "$GIT_REPOSITORY"
