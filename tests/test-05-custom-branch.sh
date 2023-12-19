#!/bin/bash

git -C "$GIT_REPOSITORY" branch dragons

gitolize.sh \
  -b dragons \
  -r "file://$GIT_REPOSITORY" \
  -w \
  bash -c 'echo "test string" > "$GITOLIZE_DIRECTORY/test_file"'

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show dragons:test_file

want_command_output \
  "test string" \
  gitolize.sh \
    -b dragons \
    -r "file://$GIT_REPOSITORY" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/test_file"'

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show dragons:test_file

want_command_output \
  $'bash -c echo "test string" > "$GITOLIZE_DIRECTORY/test_file"\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B dragons

rm -r "$GIT_REPOSITORY"
