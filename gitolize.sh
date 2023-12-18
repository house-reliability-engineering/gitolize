#!/bin/bash

# A script wrapping a shell command so that it runs with a directory populated from a git repository.
# In the write mode, the repository is locked using a temporary branch on a per-project basis and
# changes made in that directory by the shell command get pushed back to the repository.

set -o errexit
set -o nounset
set -o pipefail

usage() {
  echo "Usage: $0 [-b <branch>] [-l <local_directory>] [-m message] [-p project] [-r repository] [-s] [-v] [-w] [command...]" 1>&2
  exit 1
}

wgit() {
  COMMAND="$1"
  shift
  EXTRA_FLAGS=
  case "$COMMAND" in
    add)
      EXTRA_FLAGS="$GIT_VERBOSE_FLAG"
      ;;
    *)
      EXTRA_FLAGS="$GIT_QUIET_FLAG"
      ;;
  esac
  if [[ "$VERBOSE" ]]
  then
    echo "running git -C "$LOCAL_DIRECTORY" $COMMAND $EXTRA_FLAGS $@" 1>&2
  fi
  git -C "$LOCAL_DIRECTORY" $COMMAND $EXTRA_FLAGS "$@"
}

LOCK_FILE=gitolize.lock

EXIT_CODE=0

GIT_QUIET_FLAG=--quiet
GIT_VERBOSE_FLAG=

BRANCH=main
LOCAL_DIRECTORY=
CLEANUP_LOCAL_DIRECTORY=
COMMIT_MESSAGE=
PROJECT=
GIT_REPOSITORY=
CAPTURE_STDIO=
VERBOSE=
WRITE=


while getopts b:l:m:p:r:svw OPTION
do
  case $OPTION in
    b)
      BRANCH="$OPTARG"
      ;;
    l)
      LOCAL_DIRECTORY="$OPTARG"
      ;;
    m)
      COMMIT_MESSAGE="$OPTARG"
      ;;
    p)
      PROJECT="$OPTARG"
      ;;
    r)
      GIT_REPOSITORY="$OPTARG"
      ;;
    s)
      CAPTURE_STDIO=true
      ;;
    v)
      VERBOSE=true
      ;;
    w)
      WRITE=true
      ;;
    *)
      usage
      ;;
  esac
done

shift $((OPTIND-1))

if [[ "$#" < 1 ]]
then
  usage
fi

if [[ ! "$LOCAL_DIRECTORY" ]]
then
  LOCAL_DIRECTORY="$(mktemp -d)"
  CLEANUP_LOCAL_DIRECTORY=true
fi

if [[ "$PROJECT" ]]
then
   LOCK_BRANCH="lock/${PROJECT}"
else
   LOCK_BRANCH="lock"
fi

if [[ "$VERBOSE" ]]
then
  GIT_QUIET_FLAG=
  GIT_VERBOSE_FLAG=--verbose
fi

if [[ ! "$COMMIT_MESSAGE" ]]
then
  COMMIT_MESSAGE="$*"
  if [[ "$PROJECT" ]]
  then
    COMMIT_MESSAGE="$PROJECT: $*"
  fi
fi

if [[ -d "$LOCAL_DIRECTORY/.git" ]]
then
  wgit checkout "$BRANCH"
  wgit pull
else
  wgit clone \
    --branch "$BRANCH" \
    --depth 1 \
    "$GIT_REPOSITORY" \
    "$LOCAL_DIRECTORY"
fi

if [[ "$WRITE" ]]
then
  wgit checkout -b "$LOCK_BRANCH"
  LOCK_MESSAGE="Locking for $COMMIT_MESSAGE"
  echo "$LOCK_MESSAGE" >> "$LOCAL_DIRECTORY/$LOCK_FILE"
  wgit add "$LOCK_FILE"
  wgit commit --message "$LOCK_MESSAGE"
  wgit push --set-upstream origin "$LOCK_BRANCH" || {
    EXIT_CODE=$?
    echo "locking failed" 1>&2
    exit "$EXIT_CODE"
  }
  wgit checkout "$BRANCH"
fi

if [[ "$CAPTURE_STDIO" ]]
then
  {
    STDIO="$(
      (
        GITOLIZE_DIRECTORY="$LOCAL_DIRECTORY" "$@" \
        2> >(tee /dev/fd/4 >&2) |
        tee /dev/fd/4 1>&3
      ) 4>&1
    )"
  } 3>&1
  COMMIT_MESSAGE="
$COMMIT_MESSAGE

\`\`\`
$STDIO
\`\`\`
"

else
    GITOLIZE_DIRECTORY="$LOCAL_DIRECTORY" "$@"
fi

EXIT_CODE=$?
if [[ "$EXIT_CODE" != 0 ]]
then
  CLEANUP_LOCAL_DIRECTORY=
  if [[ "$VERBOSE" ]]
  then
    echo "failed with exit code $EXIT_CODE: $@" 1>&2
  fi
fi

if [[ "$WRITE" ]]
then
  wgit add .
  wgit commit --allow-empty --message "$COMMIT_MESSAGE"
  if ! wgit push 2>/dev/null
  then
    # in case something has been written for another project in the meantime
    wgit pull --rebase
    wgit push
  fi
  wgit branch --delete --force "$LOCK_BRANCH"
  wgit push origin --delete "$LOCK_BRANCH"
fi

if [[ "$CLEANUP_LOCAL_DIRECTORY" ]]
then
  rm -r "$LOCAL_DIRECTORY"
fi

exit "$EXIT_CODE"
