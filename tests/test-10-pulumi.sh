#!/bin/bash

export PULUMI_CONFIG_PASSPHRASE=secret

cp ../examples/gitignore-pulumi-state "$GIT_REPOSITORY/.gitignore"
git -C "$GIT_REPOSITORY" add .gitignore
git -C "$GIT_REPOSITORY" commit --quiet --message ".gitignore"

cd test-10-pulumi-program

want_command_output_grep \
  "Created stack 'test'" \
  gitolize.sh \
    -w \
    -m "init stack" \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" pulumi stack init test'

want_command_output \
  "organization/test/test" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq -r .checkpoint.stack
  "

export PULUMI_TEST_STRING="test string 1"

want_command_output_grep \
  "command:local:Command echo created" \
  gitolize.sh \
    -w \
    -m "first pulumi up" \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" poetry run pulumi up --skip-preview'

want_command_output \
  "$PULUMI_TEST_STRING" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq -r '.checkpoint.latest.resources[-1].outputs.stdout'
  "

FIRST_COMMIT="$(git -C "$GIT_REPOSITORY" rev-parse main)"

PULUMI_TEST_STRING="test string 2"

want_command_output_grep \
  "command:local:Command echo updated" \
  gitolize.sh \
    -w \
    -m "second pulumi up" \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" poetry run pulumi up --skip-preview'

want_command_output \
  "$PULUMI_TEST_STRING" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq -r '.checkpoint.latest.resources[-1].outputs.stdout'
  "

SECOND_COMMIT="$(git -C "$GIT_REPOSITORY" rev-parse main)"

want_command_output \
  "$FIRST_COMMIT" \
  bash -c "
    git -C '$GIT_REPOSITORY' blame -l main .pulumi/stacks/test/test.json |
    grep '\"stderr\": \"\",$' |
    cut -d ' ' -f 1
  "

want_command_output \
  "$SECOND_COMMIT" \
  bash -c "
    git -C '$GIT_REPOSITORY' blame -l main .pulumi/stacks/test/test.json |
    grep '\"stdout\": \"test string 2\"$' |
    cut -d ' ' -f 1
  "

want_command_output_grep \
  "command:local:Command echo deleted" \
  gitolize.sh \
    -w \
    -m "pulumi destroy" \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" poetry run pulumi destroy --skip-preview'

want_command_output \
  "null" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq .checkpoint.latest.resources
  "

rm -r "$GIT_REPOSITORY"
