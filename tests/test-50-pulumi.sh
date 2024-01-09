#!/bin/bash

export PULUMI_CONFIG_PASSPHRASE=secret

cp ../examples/gitignore-pulumi-state "$GIT_REPOSITORY/.gitignore"
git -C "$GIT_REPOSITORY" add .gitignore
git -C "$GIT_REPOSITORY" commit --quiet --message ".gitignore"

cd test-50-pulumi-program

want_command_output_grep \
  "Created stack 'test'" \
  gitolize.sh \
    -m "init stack" \
    -r "file://$GIT_REPOSITORY" \
    -s \
    -w \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" pulumi stack init test'

want_command_output \
  "organization/test/test" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq -r .checkpoint.stack
  "

check_no_ansi_escape_sequences_in_git_log

export PULUMI_TEST_STRING="test string 1"

want_command_output_grep \
  "command:local:Command echo .*created " \
  gitolize.sh \
    -m "first pulumi up" \
    -r "file://$GIT_REPOSITORY" \
    -s \
    -w \
    bash -c '
      export PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY"
      poetry run \
        pulumi up \
          --color always \
          --skip-preview
      '

want_command_output \
  "$PULUMI_TEST_STRING" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq -r '.checkpoint.latest.resources[-1].outputs.stdout'
  "

check_no_ansi_escape_sequences_in_git_log

FIRST_COMMIT="$(git -C "$GIT_REPOSITORY" rev-parse main)"

PULUMI_TEST_STRING="test string 2"

want_command_output_grep \
  "command:local:Command echo .*updated " \
  gitolize.sh \
    -m "second pulumi up" \
    -r "file://$GIT_REPOSITORY" \
    -s \
    -w \
    bash -c '
      export PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY"
      poetry run \
        pulumi up \
          --color always \
          --skip-preview
    '

want_command_output \
  "$PULUMI_TEST_STRING" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq -r '.checkpoint.latest.resources[-1].outputs.stdout'
  "

check_no_ansi_escape_sequences_in_git_log

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
  "command:local:Command echo .*deleted " \
  gitolize.sh \
    -m "pulumi destroy" \
    -r "file://$GIT_REPOSITORY" \
    -w \
    bash -c '
      export PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY"
      poetry run \
        pulumi destroy \
          --color always \
          --skip-preview
    '

want_command_output \
  "null" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:.pulumi/stacks/test/test.json |
    jq .checkpoint.latest.resources
  "

check_no_ansi_escape_sequences_in_git_log

rm -r "$GIT_REPOSITORY"
