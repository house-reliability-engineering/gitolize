#!/bin/bash

# A script wrapping a shell command so that it runs with a directory populated from a git repository.
# In the write mode, the repository is locked using a temporary branch on a per-project basis and
# changes made in that directory by the shell command get pushed back to the repository.

set -o errexit
set -o nounset
set -o pipefail

usage() {
  echo "Usage: $0 [-b <branch>] [-l <local_directory>] [-m message] [-p project] [-r repository] [-v] [-w] [command...]" 1>&2
  exit 1
}

git() {
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
    echo "running $GIT -C "$LOCAL_DIRECTORY" $COMMAND $EXTRA_FLAGS $@" 1>&2
  fi
  $GIT -C "$LOCAL_DIRECTORY" $COMMAND $EXTRA_FLAGS "$@"
}

LOCK_FILE=gitolize.lock

EXIT_CODE=0

GIT="$(which git)"
GIT_QUIET_FLAG=--quiet
GIT_VERBOSE_FLAG=

BRANCH=main
LOCAL_DIRECTORY=
CLEANUP_LOCAL_DIRECTORY=
COMMIT_MESSAGE=
PROJECT=
GIT_REPOSITORY=
VERBOSE=
WRITE=


while getopts b:l:m:p:r:vw OPTION
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
  git checkout "$BRANCH"
  git pull
else
  git clone \
    --branch "$BRANCH" \
    --depth 1 \
    "$GIT_REPOSITORY" \
    "$LOCAL_DIRECTORY"
fi

if [[ "$WRITE" ]]
then
  git checkout -b "$LOCK_BRANCH"
  LOCK_MESSAGE="Locking for $COMMIT_MESSAGE"
  echo "$LOCK_MESSAGE" >> "$LOCAL_DIRECTORY/$LOCK_FILE"
  git add "$LOCK_FILE"
  git commit --message "$LOCK_MESSAGE"
  git push --set-upstream origin "$LOCK_BRANCH" || {
    EXIT_CODE=$?
    echo "locking failed" 1>&2
    exit "$EXIT_CODE"
  }
  git checkout "$BRANCH"
fi

GITOLIZE_DIRECTORY="$LOCAL_DIRECTORY" "$@"
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
  git add .
  git commit --allow-empty --message "$COMMIT_MESSAGE"
  if ! git push 2>/dev/null
  then
    # in case something has been written for another project in the meantime
    git pull --rebase
    git push
  fi
  git branch --delete --force "$LOCK_BRANCH"
  git push origin --delete "$LOCK_BRANCH"
fi

if [[ "$CLEANUP_LOCAL_DIRECTORY" ]]
then
  rm -r "$LOCAL_DIRECTORY"
fi

exit "$EXIT_CODE"
