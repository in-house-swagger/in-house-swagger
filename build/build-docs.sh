#!/bin/bash
#set -eux
#===================================================================================================
#
# Production Build for docs
#
#===================================================================================================
#---------------------------------------------------------------------------------------------------
# 設定
#---------------------------------------------------------------------------------------------------
dir_script="$(dirname $0)"
cd "$(cd ${dir_script}; cd ..; pwd)" || exit 6

DIR_BASE="$(pwd)"
DIR_SRC="${DIR_BASE}/docs/adoc"
DIR_DIST="${DIR_BASE}/docs"

version="$(cat ${DIR_BASE}/src/VERSION)"

function local.check(){
  find ${DIR_SRC} -type f -name '*.adoc' | xargs redpen -f asciidoc -c ${DIR_SRC}/redpen-conf.xml
  retcode=$?
  if [[ ${retcode} -ne 0 ]]; then
    echo "redpenでエラーが発生しました。" >&2
    exit 6
  fi

  echo ""
  echo "ビルドが完了しました。"
  exit 0
}

function local.html(){
  #-------------------------------------------------------------------------------------------------
  # acsiidoctor
  #-------------------------------------------------------------------------------------------------
  echo "acsiidoctor"
  asciidoctor                                                                                      \
    --safe-mode unsafe                                                                             \
    -a lang=ja                                                                                     \
    -b html5                                                                                       \
    -d book                                                                                        \
    --destination-dir "${DIR_DIST}"                                                                \
    --attribute source-highlighter=highlightjs                                                     \
    --attribute linkcss                                                                            \
    --attribute stylesheet=readthedocs.css                                                         \
    --attribute stylesdir=./stylesheets                                                            \
    --attribute Version=${version}                                                                 \
    --attribute imagesdir=./images                                                                 \
    "${DIR_SRC}/index.adoc"
  retcode=$?
  if [[ ${retcode} -ne 0 ]] || [[ ! -f "${DIR_DIST}/index.html" ]]; then
    echo "acsiidoctorでエラーが発生しました。" >&2
    exit 6
  fi

  echo ""
  echo "ビルドが完了しました。"
  exit 0
}

case $1 in
check)
  local.check
  ;;
*)
  local.html
  ;;
esac
