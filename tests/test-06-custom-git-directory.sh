#!/bin/bash

GIT_DIRECTORY=something

gitolize.sh \
  -d "$GIT_DIRECTORY" \
  -w \
  "file://$GIT_REPOSITORY" \
  bash -c '
    mkdir "$GITOLIZE_DIRECTORY/'"$GIT_DIRECTORY"'" &&
    echo "test string" > "$GITOLIZE_DIRECTORY/'"$GIT_DIRECTORY"'/test_file"
  '

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show "main:$GIT_DIRECTORY/test_file"

want_command_output \
  "test string" \
  gitolize.sh \
    -d "$GIT_DIRECTORY" \
    "file://$GIT_REPOSITORY" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/'"$GIT_DIRECTORY"'/test_file"'

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show "main:$GIT_DIRECTORY/test_file"

want_command_output \
  'bash -c
    mkdir "$GITOLIZE_DIRECTORY/'"$GIT_DIRECTORY"'" &&
    echo "test string" > "$GITOLIZE_DIRECTORY/'"$GIT_DIRECTORY"'/test_file"
' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B -- "$GIT_DIRECTORY/test_file"

rm -r "$GIT_REPOSITORY"
