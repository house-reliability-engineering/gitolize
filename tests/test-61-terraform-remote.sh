#!/bin/bash

TERRAFORM_CONFIGURATION_A="$(mktemp -d)"
cp test-61-terraform-configuration-a/main.tf "$TERRAFORM_CONFIGURATION_A/main.tf"

TERRAFORM_CONFIGURATION_B="$(mktemp -d)"
cp test-61-terraform-configuration-b/main.tf "$TERRAFORM_CONFIGURATION_B/main.tf"

cd "$TERRAFORM_CONFIGURATION_A"

want_command_output_grep \
  '\+ test-output = "test value"' \
  gitolize.sh \
    -p a \
    -m "a: terraform apply" \
    -r "file://$GIT_REPOSITORY" \
    -w \
    bash -c '
      terraform init &&
      terraform apply \
        -state="$GITOLIZE_DIRECTORY/terraform-a.tfstate" \
        -no-color \
        -auto-approve
    '

cd "$TERRAFORM_CONFIGURATION_B"

want_command_output_grep \
  '\+ proxied-output = "test value"' \
  gitolize.sh \
    -p b \
    -m "b: terraform apply" \
    -r "file://$GIT_REPOSITORY" \
    -w \
    bash -c '
      terraform init &&
      terraform apply \
        -state="$GITOLIZE_DIRECTORY/terraform-b.tfstate" \
        -var=a-state-path="$GITOLIZE_DIRECTORY/terraform-a.tfstate" \
        -no-color \
        -auto-approve
    '

rm -r "$TERRAFORM_CONFIGURATION_A" "$TERRAFORM_CONFIGURATION_B" "$GIT_REPOSITORY"

