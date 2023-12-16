#!/bin/bash

export PULUMI_CONFIG_PASSPHRASE=secret

cp ../examples/gitignore-pulumi-state "$GIT_REPOSITORY/.gitignore"
git -C "$GIT_REPOSITORY" add .gitignore
git -C "$GIT_REPOSITORY" commit --quiet --message ".gitignore"

cd test-12-pulumi-program-a

want_command_output_grep \
  "Created stack 'test'" \
  gitolize.sh \
    -w \
    -p a \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" pulumi stack init test'

want_command_output_grep \
  'test-output: "test value"' \
  gitolize.sh \
    -w \
    -p a \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" poetry run pulumi up --skip-preview'


cd ../test-12-pulumi-program-b

want_command_output_grep \
  "Created stack 'test'" \
  gitolize.sh \
    -w \
    -p b \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" pulumi stack init test'


want_command_output_grep \
  'proxied-output: "test value"' \
  gitolize.sh \
    -w \
    "file://$GIT_REPOSITORY" \
    bash -c 'PULUMI_BACKEND_URL="file://$GITOLIZE_DIRECTORY" poetry run pulumi up --skip-preview'

rm -r "$GIT_REPOSITORY"
