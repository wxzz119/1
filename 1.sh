#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

CHATGPT_BASE_URL="https://oa.api2d.net"
DOCKER_IMG_NAME="yidadaa/chatgpt-next-web"
TAG="latest"
PULL_IMAGE=true
HAS_CONTAINER=false
CHATGPT_PORT=3000
log() {
  echo -e "\e[32m\n$1 \e[0m\n"
}

inp() {
  echo -e "\e[33m\n$1 \e[0m\n"
}

opt() {
  echo -n -e "\e[36m输入您的选择->\e[0m"
}

warn() {
  echo -e "\e[31m$1 \e[0m\n"
}

#判断机器是否安装docker
docker_install() {
  echo "检测 Docker......"
  if [ -x "$(command -v docker)" ]; then
    echo "检测到 Docker 已安装!"
  else
    if [ -r /etc/os-release ]; then
      lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi
    if [ $lsb_dist == "openwrt" ]; then
      echo "openwrt 环境请自行安装 docker"
      exit 1
    else
      echo "安装 docker 环境..."
      bash <(curl -sSL http://js.kengro.cn/DockerInstallation.sh)
      echo "安装 docker 环境...安装完成!"
      systemctl enable docker
      systemctl start docker
    fi
  fi
}
docker_install

copyright() {
  clear
  echo -e "
—————————————————————————————————————————————————————————————
        ChatGPT-Next-Web一键安装脚本
 ${green}
—————————————————————————————————————————————————————————————
"
}
quit() {
  exit
}

while [[ -z "$openaikey" ]]; do
  read -p "1.请输入你的openaikey（必填）: " openaikey
done
read -p "2.请输入希望使用的CODE（授权码，可为空）: " codeinfo

modify_port() {
  inp "3.是否修改端口[默认 3000]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_port
  if [ "$change_port" = "1" ]; then
    echo -n -e "\e[36m输入您想修改的端口->\e[0m"
    read CHATGPT_PORT
  fi
}
modify_port

# 端口存在检测
check_port() {
  echo "正在检测端口:$1"
  netstat -tlpn | grep "\b$1\b"
}
if [ "$port" != "2" ]; then
  while check_port $CHATGPT_PORT; do
    echo -n -e "\e[31m端口:$CHATGPT_PORT 被占用，请重新输入端口：\e[0m"
    read CHATGPT_PORT
  done
  echo -e "\e[34m恭喜，端口:$CHATGPT_PORT 可用\e[0m"
  MAPPING_ChatGPT_PORT="-p $CHATGPT_PORT:3000"
fi

input_container_name() {
  echo -n -e "\e[33m\n4.请输入要创建的 Docker 容器名称[默认为：ChatGPT-Next-Web]->\e[0m"
  read container_name
  if [ -z "$container_name" ]; then
    CONTAINER_NAME="ChatGPT-Next-Web"
  else
    CONTAINER_NAME=$container_name
  fi

  if [ ! -z "$(docker ps -a | grep $CONTAINER_NAME 2>/dev/null)" ]; then
    inp "检测到先前已经存在的容器，是否删除先前的容器：\n1) 删除[默认]\n2) 不删除"
    opt
    read update
    if [ "$update" = "2" ]; then
      inp "您选择了不删除之前的容器，需要重新输入容器名称"
      input_container_name
    fi
    if [ "$update" = "1" ]; then
      PULL_IMAGE=true
      log "停止并删除容器: $CONTAINER_NAME"
      docker stop $CONTAINER_NAME >/dev/null
      docker rm $CONTAINER_NAME >/dev/null
    fi
  fi
}
input_container_name

log "5.开始创建容器并执行"

docker run -dit \
  -e OPENAI_API_KEY=${openaikey} \
  -e CODE=${codeinfo} \
  -e BASE_URL=${CHATGPT_BASE_URL} \
  --name ${CONTAINER_NAME} \
  $MAPPING_ChatGPT_PORT \
  --restart always \
  $DOCKER_IMG_NAME:$TAG

log "6.下面列出所有容器"
docker ps

if docker ps -a | grep -q "$CONTAINER_NAME"; then
  log "容器 $CONTAINER_NAME 已创建成功"
else
  log "容器 $CONTAINER_NAME 创建失败"
fi
