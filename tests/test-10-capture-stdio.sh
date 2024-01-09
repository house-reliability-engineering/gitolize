#!/bin/bash

export TERM=vt100
STDERR=$(mktemp)

cd "$GIT_REPOSITORY"

touch bar
chmod 755 bar
mkdir foo

want_command_output \
  "$(ls --color=always .)" \
  bash -c "
    gitolize.sh \
      -m ls \
      -r 'file://$GIT_REPOSITORY' \
      -m ls \
      -s \
      -w \
      bash -c '
        ls --color=always .
        sleep 0.1
        ls nonexistant
     ' \
    2>$STDERR
  "

want_file_contents \
  "ls: cannot access 'nonexistant': No such file or directory" \
  "$STDERR"

check_no_ansi_escape_sequences_in_git_log

want_command_output \
  "ls

\`\`\`
$(
  ls --color=never .
  sleep 0.1
  ls nonexistant 2>&1
)
\`\`\`
" \
  git -C "$GIT_REPOSITORY" log -1 --pretty=%B

want_command_output \
  "$(ls --color=always .)" \
  bash -c "
    gitolize.sh \
      -a \
      -m ls \
      -r 'file://$GIT_REPOSITORY' \
      -s \
      -w \
      ls --color=always .
  "

want_command_output \
  "ls

\`\`\`
$(ls --color=always .)
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
