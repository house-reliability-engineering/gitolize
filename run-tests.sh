#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")"

docker build --tag gitolize-tests:latest --target tests .
docker run --rm gitolize-tests:latest