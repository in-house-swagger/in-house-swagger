#!/bin/bash
#===================================================================================================
#
# 共通設定
#
# 前提:
#   - DIR_BASE が定義されていること
#
#===================================================================================================
#---------------------------------------------------------------------------------------------------
# 前提チェック
#---------------------------------------------------------------------------------------------------
# 環境変数
if [[ "${DIR_BASE}x" = "x" ]]; then
  echo "DIR_BASE is NOT defined." >&2
  exit 1
fi


#--------------------------------------------------------------------------------------------------
# 定数
#--------------------------------------------------------------------------------------------------
# 終了コード
readonly EXITCODE_SUCCESS=0
readonly EXITCODE_WARN=3
readonly EXITCODE_ERROR=6

# ログレベル
readonly LOGLEVEL_TRACE="TRACE"
readonly LOGLEVEL_DEBUG="DEBUG"
readonly LOGLEVEL_INFO="INFO "
readonly LOGLEVEL_WARN="WARN "
readonly LOGLEVEL_ERROR="ERROR"

# ディレクトリ
readonly DIR_BIN="${DIR_BASE}/bin"
readonly DIR_BIN_LIB="${DIR_BIN}/lib"
readonly DIR_CONFIG="${DIR_BASE}/config"
readonly DIR_LOG="${DIR_BASE}/log"
readonly DIR_ARCHIVE="${DIR_BASE}/archive"
readonly DIR_LIB="${DIR_BASE}/lib"
readonly DIR_DATA="${DIR_BASE}/data"

# プロセスファイル
readonly PATH_PID=${DIR_DATA}/pid

# プロジェクト毎の上書き設定ファイル
readonly PATH_PROJECT_ENV="${DIR_CONFIG}/project.properties"


#--------------------------------------------------------------------------------------------------
# 共通関数読込み
#--------------------------------------------------------------------------------------------------
. ${DIR_BIN_LIB}/common_utils.sh


#--------------------------------------------------------------------------------------------------
# 変数
#
# ここでの変数定義はデフォルト値です。
# PATH_PROJECT_ENV、PATH_ACCESS_INFO で自プロジェクト向けの設定に上書きして下さい。
#
#--------------------------------------------------------------------------------------------------
# ログレベル
LOGLEVEL=${LOGLEVEL_TRACE}

# ダウンロードURL
DOWNLOAD_URL_JETTY="http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.4.6.v20170531/jetty-distribution-9.4.6.v20170531.tar.gz"
DOWNLOAD_URL_GROOVY="https://dl.bintray.com/groovy/maven/apache-groovy-binary-2.4.12.zip"
DOWNLOAD_URL_GENERATOR="http://central.maven.org/maven2/io/swagger/swagger-generator/2.2.3/swagger-generator-2.2.3.war"
DOWNLOAD_URL_CODEGEN_CLI="http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.3/swagger-codegen-cli-2.2.3.jar"
DOWNLOAD_URL_EDITOR="https://github.com/suwa-sh/swagger-editor/files/1180366/local-swagger-editor-3.0.17.tar.gz"
DOWNLOAD_URL_UI="https://github.com/suwa-sh/swagger-ui/files/1180373/local-swagger-ui-3.0.21.tar.gz"


#--------------------------------------------------------------------------------------------------
# OS依存設定
#--------------------------------------------------------------------------------------------------
# mac
if [ $(is_mac) = "true" ]; then
  export JAVA_HOME="`/usr/libexec/java_home`"
  export _JAVA_OPTIONS="-Dfile.encoding=UTF-8"
fi

# linux
#if [ $(is_linux) = "true" ]; then
#fi

# cygwin
#if [ $(is_cygwin) = "true" ]; then
#fi


#--------------------------------------------------------------------------------------------------
# プロジェクト毎の上書き設定読込み
#--------------------------------------------------------------------------------------------------
if [ -f ${PATH_PROJECT_ENV} ]; then
  . ${PATH_PROJECT_ENV}
else
  echo "ERROR ${PATH_PROJECT_ENV} が存在しません。デプロイ結果が正しいか確認して下さい。" >&2
  exit 1
fi
