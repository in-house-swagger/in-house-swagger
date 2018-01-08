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
    # FIXME at 0.4.4
    -e SC1091 # Not following: ./setenv: openFile: does not exist (No such file or directory)
    -e SC2001 # See if you can use ${variable//search/replace} instead. echo ${_first_date} | sed -e 's|/||g' -> echo ${_first_date////}
    -e SC2003 # expr is antiquated. Consider rewriting this using $((..)), ${} or [[ ]].
    -e SC2005 # Useless echo? Instead of 'echo $(cmd)', just use 'cmd'
    -e SC2010 # Don't use ls | grep. Use a glob or a for loop with a condition to allow non-alphanumeric filenames.
    -e SC2012 # Use find instead of ls to better handle non-alphanumeric filenames
    -e SC2013 # To read lines rather than words, pipe/redirect to a 'while read' loop.
    -e SC2034 # DIR_CUR appears unused. Verify it or export it.
    -e SC2038 # Use -print0/-0 or -exec + to allow for non-alphanumeric filenames.
    -e SC2044 # For loops over find output are fragile. Use find -exec or a while read loop.
    -e SC2046 # Quote this to prevent word splitting.
    -e SC2068 # Double quote array expansions to avoid re-splitting elements.
    -e SC2119 # Use log.add_indent "$@" if function's $1 should mean script's $1
    -e SC2120 # log.add_indent references arguments, but none are ever passed.
    -e SC2145 # Argument mixes string and array. Use * or separate argument.
    -e SC2166 # Prefer [ p ] || [ q ] as [ p -o q ] is not well defined.
    # FIXME latest
    -e SC1117 # Backslash is literal in "\n". Prefer explicit escaping: "\\n".
    -e SC2181 # Check exit code directly with e.g. 'if mycmd;', not indirectly with $?.
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
