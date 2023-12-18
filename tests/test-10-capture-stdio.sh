#!/bin/bash

STDERR=$(mktemp)

want_command_output \
  "this is stdout" \
  bash -c "
    gitolize.sh \
      -r 'file://$GIT_REPOSITORY' \
      -s \
      -w \
      bash -c \"
        echo 'this is stdout'
        sleep 0.1
        echo 'this is stderr' 1>&2
      \" \
      2>$STDERR
  "

want_file_contents \
  "this is stderr" \
  "$STDERR"

want_command_output \
  "bash -c
        echo 'this is stdout'
        sleep 0.1
        echo 'this is stderr' 1>&2

\`\`\`
this is stdout
this is stderr
\`\`\`
" \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

rm -r "$STDERR" "$GIT_REPOSITORY"
