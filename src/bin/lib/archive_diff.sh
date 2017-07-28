#!/bin/bash
#set -eux
#==================================================================================================
# アーカイブファイル内容比較
#
# 概要
#   指定した 旧アーカイブ、新アーカイブ を展開したディレクトリ構成を比較して
#   新規、削除、更新ファイルの差分一覧を表示します。
#
# 引数
#   $1: 旧アーカイブ
#   $2: 新アーカイブ
#
# オプション
#   -v: 詳細表示オプション
#       新規、削除、更新ファイルの差分一覧と合わせて
#       更新ファイル内の差分を表示します。
#
# 戻り値
#   0: 一致した場合
#   3: 差分を検出した場合
#   6: エラー発生時
#
# 出力
#   標準出力  : 比較結果
#   標準エラー: ログ
#
# 前提
#   ・dir_diff.sh と並びのディレクトリに配置されていること
#
#==================================================================================================
#--------------------------------------------------------------------------------------------------
# 環境設定
#--------------------------------------------------------------------------------------------------
# カレントディレクトリの移動
cd $(cd $(dirname $0); pwd)

CMDNAME=`basename $0`
USAGE="Usage: ${CMDNAME} [-v] PATH_OLD PATH_NEW"

# 終了コード
readonly EXITCODE_SUCCESS=0
readonly EXITCODE_WARN=3
readonly EXITCODE_ERROR=6

DIR_CUR=`pwd`
DIR_WORK=/tmp/${CMDNAME}_$$
DIR_OLD=${DIR_WORK}/old
DIR_NEW=${DIR_WORK}/new
DIR_TMP_ROOT=${DIR_WORK}/tmp

# 対応拡張子
ALLOW_EXTS=()
ALLOW_EXTS+=( zip )
ALLOW_EXTS+=( tar.gz )
ALLOW_EXTS+=( tgz )
ALLOW_EXTS+=( jar )
ALLOW_EXTS+=( war )
ALLOW_EXTS+=( ear )

#--------------------------------------------------------------------------------------------------
# 関数定義
#--------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# 拡張子取得
#
# 引数
#   $1: 対象ファイルパス
#------------------------------------------------------------------------------
function get_ext() {
  local path="$1"
  local ext="${path##*.}"

  # 変数展開結果を確認
  if [ "${ext}" = "gz" ]; then
    # gzの場合、2重拡張子を確認 ※tar.gzのみ対応
    if [ "$(basename ${path} .tar.gz)" = "$(basename ${path})" ]; then
      ext="tar.gz"
    fi

  elif [ "${ext}" = "${path}" ]; then
    # pathそのままの場合、拡張子なし
    ext=""
  fi

  echo "${ext}"
  return ${EXITCODE_SUCCESS}
}

#------------------------------------------------------------------------------
# 再帰アーカイブ展開
#
# 引数
#   $1: 対象ファイルパス
#   $2: 出力ディレクトリ ※再帰呼び出し時は指定なし＝対象ファイルを展開後に削除
#------------------------------------------------------------------------------
function recursive_expand() {
  local _path_archive="$1"
  local _dir_out_parent="$2"
  local _is_remove=false

  echo "$(date '+%Y-%m-%d %T') -- ${FUNCNAME[0]} $@"                                                 1>&2

  if [ "${_dir_out_parent}" = "" ]; then
    # 出力ディレクトリが指定されていない（再帰呼び出し）場合
    # アーカイブファイルと同名のディレクトリに出力させる
    _dir_out_parent="$(dirname ${_path_archive})"
    # アーカイブファイルを展開後に削除
    _is_remove=true
  fi

  local name_archive="$(basename ${_path_archive})"
  local dir_out="${_dir_out_parent}/${name_archive}"
  local dir_out_tmp="${dir_out}_tmp"
  local ext=$(get_ext ${_path_archive})

  # 作業ディレクトリ作成
  mkdir -p ${dir_out_tmp}

  # 拡張子に合わせたコマンドで、作業ディレクトリに展開
  local _ret_code=${EXITCODE_SUCCESS}
  cd ${dir_out_tmp}
  if [ "${ext}" = "zip" ]; then
    unzip "${_path_archive}" > /dev/null
    _ret_code=$?

  elif [ "${ext}" = "tar.gz" -o "${ext}" = "gz" ]; then
    tar -xfz "${_path_archive}" > /dev/null
    _ret_code=$?

  elif [ "${ext}" = "jar" -o "${ext}" = "war" -o "${ext}" = "ear" ]; then
    jar xf "${_path_archive}" > /dev/null
    _ret_code=$?

  fi
  cd - >/dev/null 2>&1
  if [ ${_ret_code} -ne ${EXITCODE_SUCCESS} ]; then
    return ${EXITCODE_ERROR}
  fi

  # 対応拡張子群をループ
  for cur_allow_ext in ${ALLOW_EXTS[@]}; do
    # 現在の対応拡張子のファイルをループ
    for cur_file_path in $(find ${dir_out_tmp} -name \*.${cur_allow_ext} ); do
      # 再帰呼び出し
      recursive_expand "${cur_file_path}"
      _ret_code=$?
      if [ ${_ret_code} -ne ${EXITCODE_SUCCESS} ]; then
        return ${EXITCODE_ERROR}
      fi
    done
  done

  # アーカイブ削除
  if [ "${_is_remove}" = "true" ]; then
    rm -f "${_path_archive}"
  fi

  # 出力ディレクトリにリネーム
  rm -fr "${dir_out}"
  mv "${dir_out_tmp}" "${dir_out}"

  return ${EXITCODE_SUCCESS}
}

#--------------------------------------------------------------------------------------------------
# 事前処理
#--------------------------------------------------------------------------------------------------
diff_finded=false
option=

# オプション解析
while :; do
  case $1 in
    -v)
      option="-v"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "$USAGE" 1>&2
      exit 1
      ;;
    *)  break
      ;;
  esac
done

# 引数チェック
if [ $# -ne 2 ]; then
  echo "$USAGE" 1>&2
  exit ${EXITCODE_ERROR}
fi

# 旧アーカイブ
path_old="$1"
if [ ! -f ${path_old} ]; then
  echo "${path_old} is NOT exist." 1>&2
  exit ${EXITCODE_ERROR}
fi

# 新アーカイブ
path_new="$2"
if [ ! -f ${path_new} ]; then
  echo "${path_new} is NOT exist." 1>&2
  exit ${EXITCODE_ERROR}
fi

# 拡張子の一致チェック
ext_old=$(get_ext ${path_old})
ext_new=$(get_ext ${path_new})
if [ "${ext_old}" != "${ext_new}" ]; then
  echo "file extension is UNMATCHED. old:${ext_old} new:${ext_new}" 1>&2
  exit ${EXITCODE_ERROR}
fi

# 対応拡張子チェック
is_allow=false
for cur_allow_ext in ${ALLOW_EXTS[@]}; do
  if [ "${ext_old}" = "${cur_allow_ext}" ]; then
    # 対象の拡張子の場合
    is_allow=true
    break
  fi
done
if [ "${is_allow}" = "false" ]; then
  echo "file extension \"${ext_old}\" is NOT allowed. allows:${ALLOW_EXTS[@]}" 1>&2
  exit ${EXITCODE_ERROR}
fi

# 作業ディレクトリの作成
mkdir -p ${DIR_TMP_ROOT}

# 強制終了時の処理定義
trap `rm -fr ${DIR_WORK}; exit ${EXITCODE_ERROR}` SIGHUP SIGINT SIGQUIT SIGTERM

#--------------------------------------------------------------------------------------------------
# 本処理
#--------------------------------------------------------------------------------------------------
# 旧アーカイブを再帰的に展開
echo "$(date '+%Y-%m-%d %T') recursive_expand \"${path_old}\" \"${DIR_OLD}\""                      1>&2
recursive_expand "${path_old}" "${DIR_OLD}"
ret_code=$?
if [ ${ret_code} -ne ${EXITCODE_SUCCESS} ]; then
  exit ${EXITCODE_ERROR}
fi

# 新アーカイブを再帰的に展開
echo "$(date '+%Y-%m-%d %T') recursive_expand \"${path_new}\" \"${DIR_NEW}\""                      1>&2
recursive_expand "${path_new}" "${DIR_NEW}"
ret_code=$?
if [ ${ret_code} -ne ${EXITCODE_SUCCESS} ]; then
  exit ${EXITCODE_ERROR}
fi

# ディレクトリ比較
dir_out_old="${DIR_OLD}/$(basename ${path_old})"
dir_out_new="${DIR_NEW}/$(basename ${path_new})"
echo "$(date '+%Y-%m-%d %T') ./dir_diff.sh \"${dir_out_old}\" \"${dir_out_new}\""                  1>&2
echo ""                                                                                            1>&2
./dir_diff.sh ${option} "${dir_out_old}" "${dir_out_new}"
ret_code=$?

#--------------------------------------------------------------------------------------------------
# 事後処理
#--------------------------------------------------------------------------------------------------
# 作業ディレクトリの削除
rm -fr ${DIR_WORK}

# 判定結果を返却
exit ${ret_code}
