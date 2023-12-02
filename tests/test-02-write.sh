#!/bin/bash

gitolize.sh -w "file://$GIT_REPOSITORY" bash -c 'echo "test string 1" > test_file'

want_command_output \
  "test string 1" \
  git -C "$GIT_REPOSITORY" show main:test_file

want_command_output \
  $'bash -c echo "test string 1" > test_file\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

gitolize.sh -w "file://$GIT_REPOSITORY" bash -c 'echo "test string 2" >> test_file'

want_command_output \
  $'test string 1\ntest string 2' \
  git -C "$GIT_REPOSITORY" show main:test_file

want_command_output \
  $'bash -c echo "test string 2" >> test_file\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

rm -r "$GIT_REPOSITORY"