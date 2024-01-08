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


LONG_TEXT_LINE="this is a lot of text"
LONG_TEXT="$(mktemp)"
LONG_TEXT_CHARS="$(("$(getconf ARG_MAX)" * 2))"
LONG_TEXT_LINES="$(("$LONG_TEXT_CHARS" / "$(wc -c <<< "$LONG_TEXT_LINE")"))"

set +o pipefail
yes "$LONG_TEXT_LINE" | head -n "$LONG_TEXT_LINES" > "$LONG_TEXT"
set -o pipefail

diff -u \
  <(
    gitolize.sh \
      -r "file://$GIT_REPOSITORY" \
      -m "long text" \
      -s \
      -w \
      cat "$LONG_TEXT"
  ) \
  --label "stdout got" \
  "$LONG_TEXT" \
  --label "stdout want"

diff -u \
  <(git -C "$GIT_REPOSITORY" log -1 --pretty=%B) \
  --label "git message got" \
  <(
    echo long text
    echo
    echo '```'
    cat "$LONG_TEXT"
    echo '```'
    echo
  ) \
  --label "git message want"

rm -r "$STDERR" "$GIT_REPOSITORY"
