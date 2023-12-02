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

want_file_contents() {
  diff \
    -u \
    "$2" \
    - \
    --label "want" \
    <<< "$1"
}

GIT_REPOSITORY="$(mktemp -d)"
git init --quiet "$GIT_REPOSITORY"
echo 'Test repository' > "$GIT_REPOSITORY/README.md"
git -C "$GIT_REPOSITORY" add README.md
git -C "$GIT_REPOSITORY" commit --quiet --message "initial commit"
