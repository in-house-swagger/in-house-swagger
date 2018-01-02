#!/bin/bash

# travis スクリプトの生成
cd ~/target
/home/travis/.travis/travis-build/bin/travis compile --no-interactive > ~/build.sh.tmp
# ビルド対象はgitからのチェックアウトではなく、ローカルリソースにするためコメントアウト
cat ~/build.sh.tmp | sed -e "s/^travis_run_checkout/#travis_run_checkout/" > ~/build.sh

# ビルド対象リソースの準備
if [ -d ~/build ]; then
    rm -R ~/build
fi
# リソースをコピー
cp -r ~/target ~/build

# ローカル実行用の特別な処理
# redpenをキャッシュしておく
cd ~/
wget -c https://github.com/redpen-cc/redpen/releases/download/redpen-1.10.1/redpen-1.10.1.tar.gz -O ~/redpen-1.10.1.tar.gz

# ビルド実行
bash ~/build.sh
