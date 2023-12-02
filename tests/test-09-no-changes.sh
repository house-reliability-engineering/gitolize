#!/bin/bash

gitolize.sh -w "file://$GIT_REPOSITORY" true

want_command_output \
  $'true\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

rm -r "$GIT_REPOSITORY"
