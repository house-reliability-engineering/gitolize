#!/bin/bash

TERRAFORM_CONFIGURATION="$(mktemp -d)"
cp test-60-terraform-configuration/main.tf "$TERRAFORM_CONFIGURATION/main.tf"
cd "$TERRAFORM_CONFIGURATION"

TEST_FILE="$(mktemp)"

want_command_output_grep \
  "Apply complete! Resources: 1 added, 0 changed, 0 destroyed." \
  gitolize.sh \
    -m "first terraform apply" \
    -r "file://$GIT_REPOSITORY" \
    -s \
    -w \
    bash -c '
      terraform init &&
      terraform apply \
        -state="$GITOLIZE_DIRECTORY/terraform.tfstate" \
        -auto-approve \
        -var=content="test string 1" \
        -var=filename="'"$TEST_FILE"'"
    '

check_no_ansi_escape_sequences_in_git_log

FIRST_COMMIT="$(git -C "$GIT_REPOSITORY" rev-parse main)"

want_command_output \
  "test string 1" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:terraform.tfstate |
    jq -r '.resources[0].instances[0].attributes.content'
  "

want_command_output_grep \
  "Apply complete! Resources: 1 added, 0 changed, 1 destroyed." \
  gitolize.sh \
    -m "second terraform apply" \
    -r "file://$GIT_REPOSITORY" \
    -s \
    -w \
    bash -c '
      terraform init &&
      terraform apply \
        -state="$GITOLIZE_DIRECTORY/terraform.tfstate" \
        -auto-approve \
        -var=content="test string 2" \
        -var=filename="'"$TEST_FILE"'"
    '

check_no_ansi_escape_sequences_in_git_log

want_command_output \
  "test string 2" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:terraform.tfstate |
    jq -r '.resources[0].instances[0].attributes.content'
  "

SECOND_COMMIT="$(git -C "$GIT_REPOSITORY" rev-parse main)"

want_command_output \
  "$FIRST_COMMIT" \
  bash -c "
    git -C '$GIT_REPOSITORY' blame -l main terraform.tfstate |
    grep '\"source\": null$' |
    cut -d ' ' -f 1
  "

want_command_output \
  "$SECOND_COMMIT" \
  bash -c "
    git -C '$GIT_REPOSITORY' blame -l main terraform.tfstate |
    grep '\"content\": \"test string 2\",$' |
    cut -d ' ' -f 1
  "

want_command_output_grep \
  "Destroy complete! Resources: 1 destroyed." \
  gitolize.sh \
    -m "terraform destroy" \
    -r "file://$GIT_REPOSITORY" \
    -s \
    -w \
    bash -c '
      terraform init &&
      terraform destroy \
        -state="$GITOLIZE_DIRECTORY/terraform.tfstate" \
        -auto-approve \
        -var=content="test string 2" \
        -var=filename="'"$TEST_FILE"'"
    '

check_no_ansi_escape_sequences_in_git_log

want_command_output \
  "0" \
  bash -c "
    git -C '$GIT_REPOSITORY' show main:terraform.tfstate |
    jq '.resources | length'
  "

rm -r "$TERRAFORM_CONFIGURATION" "$GIT_REPOSITORY"
