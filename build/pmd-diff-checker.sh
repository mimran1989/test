#!/usr/bin/env bash
BRANCH=""
RULESET=""
WORKSPACE="$(dirname $BASH_SOURCE)"

get_abs_filename() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

if [ "$1" != "" ]; then
	BRANCH=$1
else
	echo "A branch to diff wasn't specified."
	exit 1
fi

if [ "$2" != "" ]; then
	RULESET=$(get_abs_filename "$2")
else
	echo "A PMD ruleset wasn't specified."
	exit 1
fi

git diff --name-only --diff-filter=d $1 | grep -- '.cls\|.trigger' | xargs | sed -e 's/ /,/g' >> pmd-diff.txt
if [[ -z $(grep '[^[:space:]]' pmd-diff.txt) ]]; then
  echo "No files to scan."
else
  # pmd v6.41.0
  $WORKSPACE/pmd/bin/run.sh pmd -filelist pmd-diff.txt -R $RULESET -f text -no-cache
  exit_code=$?
  if [[ "${exit_code}" != "0" ]]; then
    exit 1
  fi
fi

exit 0