#!/usr/bin/env bash
#===========================================================================
# push.sh  —  推送到 GitHub（SSH，走官方 443 接入点）
#
# 用法：
#   ./scripts/push.sh              # 推送当前分支
#   ./scripts/push.sh "msg"        # 先自动 add+commit 再推送
#
# 依赖：~/.ssh/config 已将 github.com 指向 ssh.github.com:443
#===========================================================================
set -e

cd "$(dirname "$0")/.."

if [ -n "$1" ]; then
    echo "==> git add -A"
    git add -A
    echo "==> git commit -m \"$1\""
    git commit -m "$1"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "==> git push origin $BRANCH"
git push origin "$BRANCH"
echo "==> PUSH DONE =="
