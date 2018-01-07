#!/bin/bash
#set -eux
#===================================================================================================
#
# CI Event - Master Pushed
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
# main
#---------------------------------------------------------------------------------------------------
echo "$(basename $0)"

echo ""
echo "  check commit message"
commit_message="$(git log -1 --pretty=format:'%s' | head -n 1)"
if [[ "${commit_message//${MSG_PREFIX_RELEASE}/}" != "${commit_message}" ]]; then
  # releaseプリフィックスが指定されている場合、処理をスキップ
  echo "  detect ${MSG_PREFIX_RELEASE}"
  echo "$(basename $0) skip."
  exit 0
fi

echo ""
${DIR_BUILD}/product/build.sh
exit_on_fail "build product" $?
echo ""
${DIR_BUILD}/docs/build.sh
exit_on_fail "build docs" $?


#---------------------------------------------------------------------------------------------------
# teardown
#---------------------------------------------------------------------------------------------------
echo ""
echo "$(basename $0) success."
exit 0
