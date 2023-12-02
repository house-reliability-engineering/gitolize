#!/bin/bash

git -C "$GIT_REPOSITORY" checkout --quiet -b dragons

gitolize.sh \
  -b dragons \
  -w \
  "file://$GIT_REPOSITORY" \
  bash -c 'echo "test string" > test_file'

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show dragons:test_file

want_command_output \
  "test string" \
  gitolize.sh -b dragons "file://$GIT_REPOSITORY" cat test_file

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show dragons:test_file

want_command_output \
  $'bash -c echo "test string" > test_file\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

rm -r "$GIT_REPOSITORY"
