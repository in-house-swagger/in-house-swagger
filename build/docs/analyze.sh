#!/bin/bash
#set -eux
#===================================================================================================
#
# Analyze Documents
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
if [[ "$(which redpen)x" = "x" ]]; then
  echo "redpen is not installed." >&2
  exit 1
fi


#---------------------------------------------------------------------------------------------------
# prepare
#---------------------------------------------------------------------------------------------------
echo "$(basename $0)"

DIR_ANALYZE_DIST="${DIR_DOCS}/.analyze"
if [[ -d "${DIR_ANALYZE_DIST}" ]]; then rm -fr "${DIR_ANALYZE_DIST}"; fi
mkdir -p "${DIR_ANALYZE_DIST}"

path_conf="${dir_script}/redpen-conf.xml"
path_target="${DIR_ANALYZE_DIST}/target.lst"
path_report="${DIR_ANALYZE_DIST}/report.txt"

echo "  list sources"
find "${DIR_DOCS_SRC}" -type f -name '*.adoc' >>"${path_target}"


#---------------------------------------------------------------------------------------------------
# analyze
#---------------------------------------------------------------------------------------------------
target_files=( $(cat "${path_target}") )
cmd=(
  redpen
    --format asciidoc
    --conf "${path_conf}"
    --limit 0
    "${target_files[@]}"
)

echo -n '  '
echo "${cmd[@]}"
"${cmd[@]}" >"${path_report}"
retcode=$?

if [[ ${retcode} -ne 0 ]]; then
  count=$(cat "${path_report}" | grep " ValidationError" | wc -l | sed -E 's|^ +||')
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
