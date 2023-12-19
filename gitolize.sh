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

BRANCH=()
BRANCH_CLONE=()
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
      BRANCH=("$OPTARG")
      BRANCH_CLONE=("--branch" "$OPTARG")
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
  wgit checkout "${BRANCH[@]}"
  wgit pull
else
  wgit clone \
    "${BRANCH_CLONE[@]}" \
    --depth 1 \
    "$GIT_REPOSITORY" \
    "$LOCAL_DIRECTORY"
fi

if [[ "$WRITE" ]]
then
  CURRENT_BRANCH="$(wgit branch --show-current)"
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
  wgit checkout "$CURRENT_BRANCH"
fi

set +o errexit

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
  EXIT_CODE=$?
  COMMIT_MESSAGE="
$COMMIT_MESSAGE

\`\`\`
$STDIO
\`\`\`
"

else
    GITOLIZE_DIRECTORY="$LOCAL_DIRECTORY" "$@"
    EXIT_CODE=$?
fi

set -o errexit

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
    if ! wgit push
    then
      BACKUP_BRANCH="$CURRENT_BRANCH-$(wgit rev-parse HEAD)"
      echo \
        ERROR: could not push to branch "$CURRENT_BRANCH", \
        pushing to "$BACKUP_BRANCH" instead \
        and leaving the '"$LOCK_BRANCH"' lock in place 1>&2
      wgit branch "$BACKUP_BRANCH"
      wgit push --set-upstream origin "$BACKUP_BRANCH"
      exit 1
    fi
  fi
  wgit branch --delete --force "$LOCK_BRANCH"
  wgit push origin --delete "$LOCK_BRANCH"
fi

if [[ "$CLEANUP_LOCAL_DIRECTORY" ]]
then
  rm -r "$LOCAL_DIRECTORY"
fi

exit "$EXIT_CODE"
