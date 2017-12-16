#!/bin/bash

# Makefile for RedPen documentation
#

# You can set these variables from the command line.
SOURCEDIR=./docs
BUILDDIR=./build
ASCIIDOCTOR=asciidoctor
ASCIIDOCTOR_PDF=asciidoctor-pdf

function local.clean(){
  rm -rf ${BUILDDIR}/*
}

function local.html(){
  mkdir -p ${BUILDDIR}/html
  cp -R ${SOURCEDIR}/images ${SOURCEDIR}/stylesheets ${BUILDDIR}/html
  ${ASCIIDOCTOR}                      \
    -a lang=ja                        \
    -b html5                          \
    -d book                           \
    -D${BUILDDIR}/html                \
    -a source-highlighter=highlightjs \
    -a linkcss                        \
    -a stylesheet=rubygems.css        \
    -a stylesdir=./stylesheets        \
    -a Version=${VERSION}             \
    -a imagesdir=./images             \
    ${SOURCEDIR}/adoc/index.adoc
  echo "Build finished. The HTML pages are in ${BUILDDIR}/html"
}
  
function local.check(){
  find ${SOURCEDIR} -type f -name '*.adoc' | xargs redpen -f asciidoc -c redpen-conf.xml
}

case $1 in
clean)
  local.clean
  ;;
html)
  local.html
  ;;
check)
  local.check
  ;;
*)
  echo "Usage: $0 clean|html|pdf|check"
  ;;
esac

