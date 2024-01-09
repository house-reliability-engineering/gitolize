set -o errexit
set -o nounset
set -o pipefail

want_command_output() {
  local WANT="$1"
  shift
  diff \
    -u \
    <("$@") \
    - \
    --label "<($*)" \
    --label "want" \
    <<< "$WANT"
   
}

want_command_output_grep() {
  local WANT="$1"
  shift
  local GOT="$("$@")"
  grep -q "$WANT" <<< "$GOT" || {
    echo "output of: $*
  want: $WANT
  got: $GOT" 1>&2
    return 1
  }
}

want_file_contents() {
  diff \
    -u \
    "$2" \
    - \
    --label "want" \
    <<< "$1"
}

check_no_ansi_escape_sequences_in_git_log() {
  NON_ASCII="$(
    git -C "$GIT_REPOSITORY" log -1 --pretty=%B |
    grep '[^[:print:]]' ||
    true
  )"
  if [[ "$NON_ASCII" ]]
  then
    echo "commit message contains non-ascii characters:"
    cat <<< "$NON_ASCII"
    return 1
  fi
}

GIT_REPOSITORY="$(mktemp -d)"
git init --quiet "$GIT_REPOSITORY"
echo 'Test repository' > "$GIT_REPOSITORY/README.md"
git -C "$GIT_REPOSITORY" add README.md
git -C "$GIT_REPOSITORY" commit --quiet --message "initial commit"
