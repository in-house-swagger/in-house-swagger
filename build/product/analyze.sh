#!/bin/bash
#set -eux
#===================================================================================================
#
# Analyze sources
#
#===================================================================================================
#---------------------------------------------------------------------------------------------------
# env
#---------------------------------------------------------------------------------------------------
dir_script="$(dirname $0)"
cd "$(cd ${dir_script}; cd ../..; pwd)" || exit 1

readonly DIR_BASE="$(pwd)"
. "${DIR_BASE}/build/env.properties"


#---------------------------------------------------------------------------------------------------
# check
#---------------------------------------------------------------------------------------------------
if [[ "$(which shellcheck)x" = "x" ]]; then
  echo "shellcheck is not installed." >&2
  exit 1
fi


#---------------------------------------------------------------------------------------------------
# prepare
#---------------------------------------------------------------------------------------------------
echo "$(basename $0)"
DIR_ANALYZE_DIST="${DIR_DIST}/.analyze"
if [[ -d "${DIR_ANALYZE_DIST}" ]]; then rm -fr "${DIR_ANALYZE_DIST}"; fi
mkdir -p "${DIR_ANALYZE_DIST}"

path_target="${DIR_ANALYZE_DIST}/target.lst"
path_report="${DIR_ANALYZE_DIST}/report.txt"

echo "  list sources"
find "${DIR_SRC}/bin" -type f                                                                      |
grep -v "lib/binary/"                                                                              |
grep -v "lib/Tukubai/"                                                                             |
grep -v "lib/Parsrs/"                                                                              |
grep -v "lib/yaml2json"                                                                            |
grep -v "lib/json2yaml"                                                                            |
grep -v "\.DS_Store" >>"${path_target}"


#---------------------------------------------------------------------------------------------------
# analyze
#---------------------------------------------------------------------------------------------------
target_files=( $(cat "${path_target}") )
cmd=(
  shellcheck -x
    -e SC1090
    -e SC2086
    -e SC2155
    -e SC2164
    # FIXME at debian
    -e SC1091
    -e SC2001
    -e SC2002
    -e SC2003
    -e SC2004
    -e SC2005
    -e SC2006
    -e SC2010
    -e SC2012
    -e SC2013
    -e SC2034
    -e SC2038
    -e SC2044
    -e SC2046
    -e SC2068
    -e SC2115
    -e SC2119
    -e SC2120
    -e SC2145
    -e SC2166
    # FIXME latest
    -e SC1117
    -e SC2181
    "${target_files[@]}"
)

echo -n '  '
echo "${cmd[@]}"
"${cmd[@]}" >"${path_report}"
retcode=$?

if [[ ${retcode} -ne 0 ]]; then
  count=$(cat "${path_report}" | grep -- "-- SC....: " | wc -l | sed -E 's|^ +||')
  cat "${path_report}"
  (
    echo "$(basename $0) failed."
    echo "  count: ${count}"
  ) >&2
  exit ${retcode}
fi


#---------------------------------------------------------------------------------------------------
# teardown
#---------------------------------------------------------------------------------------------------
if [[ -d "${DIR_ANALYZE_DIST}" ]]; then rm -fr "${DIR_ANALYZE_DIST}"; fi

echo "$(basename $0) success."
exit 0
