#!/bin/bash

gitolize.sh -r "file://$GIT_REPOSITORY" -w true

want_command_output \
  $'true\n' \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

rm -r "$GIT_REPOSITORY"
