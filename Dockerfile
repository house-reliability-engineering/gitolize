FROM debian:latest AS base

RUN \
  apt-get update && \
  apt-get install --yes --no-install-recommends git

COPY ./gitolize.sh /usr/bin/


FROM base AS tests

RUN \
  apt-get install --yes --no-install-recommends moreutils && \
  git config --global init.defaultBranch main && \
  git config --global receive.denyCurrentBranch ignore && \
  git config --global user.email tester@acme.org && \
  git config --global user.name Tester
COPY tests /tmp/tests

CMD ["/tmp/tests/run.sh"]
