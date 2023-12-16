#!/bin/bash

want_command_output \
  "Test repository" \
  gitolize.sh \
    -r "file://$GIT_REPOSITORY" \
    bash -c 'cat "$GITOLIZE_DIRECTORY/README.md"'

rm -r "$GIT_REPOSITORY"
