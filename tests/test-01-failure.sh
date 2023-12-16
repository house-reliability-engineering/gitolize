#!/bin/bash

if gitolize.sh -r "file://$GIT_REPOSITORY" false
then
  echo "expected failure" 1>&2
  exit 1
fi

rm -r "$GIT_REPOSITORY"
