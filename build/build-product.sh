#!/bin/bash
#set -eux
#===================================================================================================
#
# Production Build
#
#===================================================================================================
#---------------------------------------------------------------------------------------------------
# 設定
#---------------------------------------------------------------------------------------------------
dir_script="$(dirname $0)"
cd "$(cd ${dir_script}; cd ..; pwd)" || exit 6

DIR_BASE="$(pwd)"
DIR_SRC="${DIR_BASE}/src"
DIR_DIST="${DIR_BASE}/dist"

product="$(basename ${DIR_BASE})"
version="$(cat ${DIR_SRC}/VERSION)"

archive_name="${product}-${version}"
archive_name_with_dpend="${product}-with-depends-${version}"

dir_cur_dist="${DIR_DIST}/${archive_name_with_dpend}"


#---------------------------------------------------------------------------------------------------
# build
#---------------------------------------------------------------------------------------------------
echo "出力ディレクトリのクリア"
if [[ -d ${DIR_DIST} ]]; then
  rm -fr "${DIR_DIST}"
fi
mkdir -p "${dir_cur_dist}"

echo "ソースのコピー"
cp -pr "${DIR_SRC}"/* ${dir_cur_dist}/

echo "不要ファイルの削除"
find ${dir_cur_dist} -type f -name ".gitkeep"  | xargs -I{} bash -c 'rm -f {}'
find ${dir_cur_dist} -type f -name ".DS_Store" | xargs -I{} bash -c 'rm -f {}'

#---------------------------------------------------------------------------------------------------
# test
#---------------------------------------------------------------------------------------------------
echo "インストールスクリプトの動作確認"
${dir_cur_dist}/bin/install
retcode=$?
if [[ ${retcode} -ne 0 ]]; then
  echo "インストールスクリプトでエラーが発生しました。" >&2
  exit 6
fi

#---------------------------------------------------------------------------------------------------
# 配布アーカイブ作成
#---------------------------------------------------------------------------------------------------
echo "配布アーカイブに不要なファイルの削除"
rm -fr ${dir_cur_dist}/config/templates/_default


echo "依存を含めた配布アーカイブの作成"
rm -fr ${dir_cur_dist}/lib/
rm -fr ${dir_cur_dist}/module/
cd ${DIR_DIST}
tar czf ./${archive_name_with_dpend}.tar.gz ./${archive_name_with_dpend}

echo "配布アーカイブの作成"
rm -fr ${dir_cur_dist}/archive/
mv ${archive_name_with_dpend} ${archive_name}
tar czf ./${archive_name}.tar.gz ./${archive_name}


echo "ビルドが完了しました。"
exit 0
