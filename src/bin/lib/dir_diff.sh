#!/bin/bash
#set -eux
#==================================================================================================
# ディレクトリ比較
#
# 概要
#   指定した 旧ディレクトリ、新ディレクトリ 配下のファイル群を比較して
#   新規、削除、更新ファイルの差分一覧を表示します。
#
# 引数
#   $1: 旧ディレクトリ
#   $2: 新ディレクトリ
#
# オプション
#   -v: 詳細表示オプション
#       新規、削除、更新ファイルの差分一覧と合わせて
#       更新ファイル内の差分を表示します。
#
# 戻り値
#    0: 一致した場合
#    3: 差分を検出した場合
#    6: エラー発生時
#
#==================================================================================================
#--------------------------------------------------------------------------------------------------
# 環境設定
#--------------------------------------------------------------------------------------------------
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [-v] DIR_OLD DIR_NEW"

# 終了コード
readonly EXITCODE_SUCCESS=0
readonly EXITCODE_WARN=3
readonly EXITCODE_ERROR=6

DIR_CUR=`pwd`
DIR_WORK=/tmp/${CMDNAME}_$$
PATH_OLD_FILES=${DIR_WORK}/files_old
PATH_NEW_FILES=${DIR_WORK}/files_new
PATH_ALL_FILES=${DIR_WORK}/files_all
PATH_COMMON_FILES=${DIR_WORK}/files_common
PATH_TMP=${DIR_WORK}/tmp
PATH_OUT_TMP=${DIR_WORK}/output

diff_finded=false
verbose=false


#--------------------------------------------------------------------------------------------------
# 事前処理
#--------------------------------------------------------------------------------------------------
# 強制終了時の処理定義
trap `rm -fr ${DIR_WORK}; exit ${EXITCODE_ERROR}` SIGHUP SIGINT SIGQUIT SIGTERM

# オプション解析
while :; do
  case $1 in
    -v) verbose=true
      shift
      ;;
    --) shift
      break
      ;;
    -*) echo "$USAGE" 1>&2
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

# 旧ディレクトリ
DIR_OLD="$1"
if [ ! -d ${DIR_OLD} ]; then
  echo "${DIR_OLD} is NOT a directory." 1>&2
  exit ${EXITCODE_ERROR}
fi

# 新ディレクトリ
DIR_NEW="$2"
if [ ! -d $DIR_NEW ]; then
  echo "${DIR_NEW} is NOT a directory." 1>&2
  exit ${EXITCODE_ERROR}
fi


#--------------------------------------------------------------------------------------------------
# 本処理
#--------------------------------------------------------------------------------------------------
# 作業ディレクトリの作成
mkdir -p ${DIR_WORK}

# 旧ファイルリスト
cd $DIR_OLD
find . \( -type f -o -type l \) -print | sort > ${PATH_OLD_FILES}
cd $DIR_CUR

# 新ファイルリスト
cd $DIR_NEW
find . \( -type f -o -type l \) -print | sort > ${PATH_NEW_FILES}
cd $DIR_CUR

# 新旧を含めた全ファイルリスト
cat ${PATH_OLD_FILES} ${PATH_NEW_FILES} | sort | uniq    > ${PATH_ALL_FILES}
# 新旧どちらにも存在するファイルリスト
cat ${PATH_OLD_FILES} ${PATH_NEW_FILES} | sort | uniq -d > ${PATH_COMMON_FILES}

# 新規ファイルの検出
cat ${PATH_OLD_FILES} ${PATH_ALL_FILES} | sort | uniq -u > ${PATH_TMP}
if [ -s ${PATH_TMP} ]; then
  diff_finded=true
  for cur_file_path in `cat ${PATH_TMP}`; do
    cur_file_path=`expr ${cur_file_path} : '..\(.*\)'`
    echo "A ${cur_file_path}" >> ${PATH_OUT_TMP}
  done
fi

# 削除ファイルの検出
cat ${PATH_NEW_FILES} ${PATH_ALL_FILES} | sort | uniq -u > ${PATH_TMP}
if [ -s ${PATH_TMP} ]; then
  diff_finded=true
  for cur_file_path in `cat $PATH_TMP`; do
    cur_file_path=`expr ${cur_file_path} : '..\(.*\)'`
    echo "D $cur_file_path" >> ${PATH_OUT_TMP}
  done
fi

# 更新チェック
for cur_file_path in `cat ${PATH_COMMON_FILES}`; do
  cmp -s ${DIR_OLD}/${cur_file_path} ${DIR_NEW}/${cur_file_path}
  if [ $? -ne 0 ]; then
    diff_finded=true
    cur_file_path=`expr ${cur_file_path} : '..\(.*\)'`
    if [ "$verbose" = "true" ]; then
      echo "M ${cur_file_path}" >> ${PATH_OUT_TMP}
      diff ${DIR_OLD}/${cur_file_path} ${DIR_NEW}/${cur_file_path} >> ${PATH_OUT_TMP}
    else
      echo "M ${cur_file_path}" >> ${PATH_OUT_TMP}
    fi
  fi
done


#--------------------------------------------------------------------------------------------------
# 事後処理
#--------------------------------------------------------------------------------------------------
# 結果判定
if [ "${diff_finded}" = "true" ]; then
  # 差分を検出した場合
  exit_code=${EXITCODE_WARN}

  if [ "${verbose}" = "true" ]; then
    # 詳細出力モードの場合、ソートせずに結果を表示 ※ソートすると崩れるため
    cat ${PATH_OUT_TMP}

  else
    # 詳細出力モード以外の場合、パスでソートして表示
    cat ${PATH_OUT_TMP} | sort -k 2
  fi

else
  # 一致していた場合
  exit_code=${EXITCODE_SUCCESS}
fi

# 作業ディレクトリの削除
rm -fr ${DIR_WORK}

# 判定結果を返却
exit ${exit_code}
