#!/bin/bash
# 注 dockerの利用には、 root 権限が必要かもしれません。

function local.start(){
  # docker内部のディレクトリ参照は -v で指定可能。
  # bg起動のため、結果は logs で確認
  docker run -d -p 9700:9700 -p 9701:9701 --name in-house-swagger in-house-swagger:test
}
function local.stop(){
  # 停止＆イメージ削除
  docker stop in-house-swagger
  docker rm in-house-swagger
}
function local.logs(){
  docker logs in-house-swagger
}
function local.update(){
  # dockerイメージ更新
  local.stop
  docker build --no-cache -t in-house-swagger:test .
}
function local.ps(){
  docker ps
}
function local.shell(){
  docker exec -it in-house-swagger /bin/bash
}
function local.usage(){
  echo "$0 start|stop|logs|update|ps|shell|usage"
}

case "$1" in
  start)
    local.start
	  ;;
  stop)
    local.stop
	  ;;
  logs)
    local.logs
	  ;;
  update)
    local.update
    ;;
  ps)
    local.ps
	  ;;
  shell)
    local.shell
	  ;;
  *)
    local.usage
    exit 1
    ;;
esac

exit 0
