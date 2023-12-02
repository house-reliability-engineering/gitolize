#!/bin/bash

want_command_output \
  "Test repository" \
  gitolize.sh "file://$GIT_REPOSITORY" cat README.md

rm -r "$GIT_REPOSITORY"
