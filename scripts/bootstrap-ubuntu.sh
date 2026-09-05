#!/usr/bin/env bash
# Ubuntu 22.04 首次部署：安装 Docker，准备 /opt/knowledge-hub
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/knowledge-hub}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "请用 root 或 sudo 执行"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-jammy}")"
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

mkdir -p "${DEPLOY_DIR}/volumes/postgres" "${DEPLOY_DIR}/volumes/mongo"
# 数据目录需让容器内进程可写（postgres uid 999、mongo uid 999）
chown -R 999:999 "${DEPLOY_DIR}/volumes/postgres" "${DEPLOY_DIR}/volumes/mongo" || true

echo "Docker 已安装。接下来："
echo "1. 把 docker-compose.prod.yml、init-scripts、.env 放到 ${DEPLOY_DIR}"
echo "2. docker login ghcr.io"
echo "3. cd ${DEPLOY_DIR} && docker compose -f docker-compose.prod.yml up -d"
