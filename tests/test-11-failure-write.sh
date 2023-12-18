#!/bin/bash

if gitolize.sh \
  -r "file://$GIT_REPOSITORY" \
  -s \
  -w \
  bash -c '
    echo "test string 1" > "$GITOLIZE_DIRECTORY/test_file"
    exit 1
  '
then
  echo "expected exit code 1" 1>&2
  exit 1
fi


want_command_output \
  "test string 1" \
  git -C "$GIT_REPOSITORY" show main:test_file

want_command_output \
  'bash -c
    echo "test string 1" > "$GITOLIZE_DIRECTORY/test_file"
    exit 1

```

```
' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B
