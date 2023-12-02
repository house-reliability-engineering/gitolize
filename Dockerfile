FROM debian:latest AS base

RUN \
  apt-get update && \
  apt-get install --yes --no-install-recommends git

COPY ./gitolize.sh /usr/bin/


FROM pulumi/pulumi-python:latest AS pulumi

FROM base AS tests

COPY --from=pulumi /pulumi/bin/* /usr/bin/

COPY \
  tests/test-10-pulumi-program/Pulumi.yaml \
  tests/test-10-pulumi-program/pyproject.toml \
  /tmp/tests/test-10-pulumi-program/

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
  cd /tmp/tests/test-10-pulumi-program && \
  poetry install && \
  poetry run pulumi plugin install

CMD ["/tmp/tests/run.sh"]
