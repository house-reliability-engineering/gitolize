FROM debian:latest AS base

RUN \
  apt-get update && \
  apt-get install --yes --no-install-recommends git

COPY ./gitolize.sh /usr/bin/


FROM pulumi/pulumi-python:latest AS pulumi

FROM hashicorp/terraform:latest AS terraform

FROM base AS tests

COPY --from=pulumi /pulumi/bin/* /usr/bin/

COPY --from=terraform /bin/terraform /usr/bin/

COPY \
  tests/test-10-pulumi-program/Pulumi.yaml \
  tests/test-10-pulumi-program/pyproject.toml \
  /tmp/tests/test-10-pulumi-program/

COPY \
  tests/test-12-pulumi-program-a/Pulumi.yaml \
  tests/test-12-pulumi-program-a/pyproject.toml \
  /tmp/tests/test-12-pulumi-program-a/

COPY \
  tests/test-12-pulumi-program-b/Pulumi.yaml \
  tests/test-12-pulumi-program-b/pyproject.toml \
  /tmp/tests/test-12-pulumi-program-b/

RUN \
  apt-get install --yes --no-install-recommends \
    jq \
    moreutils \
    python3.11 \
    python3-poetry && \
  git config --global init.defaultBranch main && \
  git config --global receive.denyCurrentBranch ignore && \
  git config --global user.email tester@acme.org && \
  git config --global user.name Tester && \
  for PP in test-10-pulumi-program test-12-pulumi-program-a test-12-pulumi-program-b; \
  do \
      cd "/tmp/tests/$PP" && \
      poetry install && \
      poetry run pulumi plugin install || \
      exit 1 ; \
  done

CMD ["/tmp/tests/run.sh"]
