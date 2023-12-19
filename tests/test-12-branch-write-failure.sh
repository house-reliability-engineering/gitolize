#!/bin/bash

LOCAL_DIRECTORY="$(mktemp -d)"

git clone \
  --quiet \
  "file://$GIT_REPOSITORY" \
  "$LOCAL_DIRECTORY"

cat > "$LOCAL_DIRECTORY/.git/hooks/pre-push" <<EOF
#!/bin/bash
awk '\$1 == "refs/heads/main" { exit 1 }'
EOF
chmod 755 "$LOCAL_DIRECTORY/.git/hooks/pre-push"

if gitolize.sh \
  -l "$LOCAL_DIRECTORY" \
  -w \
  bash -c 'echo "test string 1" > "$GITOLIZE_DIRECTORY/test_file"' 2>/dev/null
then
  echo "expected exit code 1" 1>&2
  exit 1
fi

HEAD_SHA="$(git -C "$LOCAL_DIRECTORY" rev-parse HEAD)"

want_command_output \
  "test string 1" \
  git -C "$GIT_REPOSITORY" show "main-$HEAD_SHA:test_file"

rm -r "$LOCAL_DIRECTORY" "$GIT_REPOSITORY"
