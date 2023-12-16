#!/bin/bash

PROJECT=something

gitolize.sh \
  -p "$PROJECT" \
  -w \
  "file://$GIT_REPOSITORY" \
  bash -c '
    mkdir "$GITOLIZE_DIRECTORY/'"$PROJECT"'" &&
    echo "test string" > "$GITOLIZE_DIRECTORY/'"$PROJECT"'/test_file"
  '

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show "main:$PROJECT/test_file"

want_command_output \
  "test string" \
  gitolize.sh \
    -p "$PROJECT" \
    "file://$GIT_REPOSITORY" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/'"$PROJECT"'/test_file"'

want_command_output \
  "test string" \
  git -C "$GIT_REPOSITORY" show "main:$PROJECT/test_file"

want_command_output \
  'bash -c
    mkdir "$GITOLIZE_DIRECTORY/'"$PROJECT"'" &&
    echo "test string" > "$GITOLIZE_DIRECTORY/'"$PROJECT"'/test_file"
' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B -- "$PROJECT/test_file"

rm -r "$GIT_REPOSITORY"
