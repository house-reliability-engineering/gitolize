#!/bin/bash

gitolize.sh -w -m "message 1" "file://$GIT_REPOSITORY" bash -c 'echo "test string 1" > test_file'

want_command_output \
  $'message 1\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

gitolize.sh -w -m "message 2" "file://$GIT_REPOSITORY" bash -c 'echo "test string 2" >> test_file'

want_command_output \
  $'message 2\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

rm -r "$GIT_REPOSITORY"
