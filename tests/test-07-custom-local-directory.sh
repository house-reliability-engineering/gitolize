#!/bin/bash

LOCAL_DIRECTORY_1="$(mktemp -d)"

git clone \
  --quiet \
  "file://$GIT_REPOSITORY" \
  "$LOCAL_DIRECTORY_1"

gitolize.sh \
  -l "$LOCAL_DIRECTORY_1" \
  -w \
  bash -c 'echo "test string 1" > "$GITOLIZE_DIRECTORY/test_file_1"'

want_command_output \
  "test string 1" \
  git -C "$GIT_REPOSITORY" show "main:test_file_1"

want_file_contents \
  "test string 1" \
  "$LOCAL_DIRECTORY_1/test_file_1"

want_command_output \
  "test string 1" \
  gitolize.sh \
    -l "$LOCAL_DIRECTORY_1" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/test_file_1"'

LOCAL_DIRECTORY_2="$(mktemp -d)"

gitolize.sh \
  -l "$LOCAL_DIRECTORY_2" \
  -r "file://$GIT_REPOSITORY" \
  -w \
  bash -c 'echo "test string 2" > "$GITOLIZE_DIRECTORY/test_file_2"'

want_command_output \
  "test string 2" \
  git -C "$GIT_REPOSITORY" show "main:test_file_2"

want_file_contents \
  "test string 2" \
  "$LOCAL_DIRECTORY_2/test_file_2"

want_command_output \
  "test string 2" \
  gitolize.sh \
    -l "$LOCAL_DIRECTORY_2" \
    -r "file://$GIT_REPOSITORY" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/test_file_2"'

rm -r "$LOCAL_DIRECTORY_1" "$LOCAL_DIRECTORY_2" "$GIT_REPOSITORY"
