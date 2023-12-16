#!/bin/bash

PROJECTS="first second"

# these two should not fight over a lock
parallel \
  -i \
  -j 2 \
    bash -c "
      gitolize.sh \
        -m 'updated project {}' \
        -p '{}' \
        -r 'file://$GIT_REPOSITORY' \
        -w \
        bash -c '
          sleep 0.5
          mkdir \"\$GITOLIZE_DIRECTORY/{}\" &&
          echo test string {} >> \"\$GITOLIZE_DIRECTORY/{}/test_file\"
        '
    " \
  -- \
  $PROJECTS


for PROJECT in $PROJECTS
do

  want_command_output \
    "test string $PROJECT" \
    git -C "$GIT_REPOSITORY" show "main:$PROJECT/test_file"

  want_command_output \
    "updated project $PROJECT
" \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B -- "$PROJECT/test_file"

done

rm -r "$GIT_REPOSITORY"
