#!/bin/bash
#set -eux
#===================================================================================================
#
# Post Release
#
# env
#   GITHUB_TOKEN
#
#===================================================================================================
#---------------------------------------------------------------------------------------------------
# env
#---------------------------------------------------------------------------------------------------
dir_script="$(dirname $0)"
cd "$(cd ${dir_script}; cd ../..; pwd)" || exit 1

readonly DIR_BASE="$(pwd)"
. "${DIR_BASE}/build/env.properties"
. "${DIR_BUILD_LIB}/common.sh"


#---------------------------------------------------------------------------------------------------
# check
#---------------------------------------------------------------------------------------------------
if [[ "${GITHUB_TOKEN}x" = "x" ]]; then
  echo "GITHUB_TOKEN is not defined." >&2
  exit 1
fi


#---------------------------------------------------------------------------------------------------
# main
#---------------------------------------------------------------------------------------------------
echo "$(basename $0)"

echo "  clone"
rm -rf versiron_work
git clone -b "${BRANCH_MASTER}" "${GIT_URL}" versiron_work
exit_on_fail "clone" $?

echo "  update version file"
released_version=$(cat "${PATH_VERSION}")
# shellcheck disable=SC2034
next_version=$(
  echo ${released_version}                                                                         |
  ( IFS=".$IFS" ; read major minor bugfix && echo ${major}.$(( minor + 1 )).0-SNAPSHOT )
)
echo "    ${released_version} -> ${next_version}"
before_dir="$(pwd)"
cd versiron_work
echo "${next_version}" >"${RELPATH_VERSION}"

add_git_config

echo "  staging"
git add --all .
exit_on_fail "staging" $?

echo "  commit"
git commit -m "${MSG_PREFIX_RELEASE}start ${next_version}"
exit_on_fail "commit" $?

echo "  push"
git push origin "${BRANCH_MASTER}"
exit_on_fail "push" $?

echo "  clear clone dir"
cd "${before_dir}"
rm -rf versiron_work/


#---------------------------------------------------------------------------------------------------
# teardown
#---------------------------------------------------------------------------------------------------
echo "$(basename $0) success."
exit 0
