#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Ocean.sh"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 检查并安装 Docker 和 Docker Compose
function install_docker_and_compose() {
    # 检查是否已安装 Docker
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."

        # 安装 Docker 和依赖
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "Docker 已安装，跳过安装步骤。"
    fi

    # 验证 Docker 状态
    echo "Docker 状态:"
    sudo systemctl status docker --no-pager

    # 检查是否已安装 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose 未安装，正在安装 Docker Compose..."
        DOCKER_COMPOSE_VERSION="2.20.2"
        sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose 已安装，跳过安装步骤。"
    fi

    # 输出 Docker Compose 版本
    echo "Docker Compose 版本:"
    docker-compose --version
}

# 设置并启动节点
function setup_and_start_node() {
    # 创建目录并进入
    mkdir -p ocean
    cd ocean || { echo "无法进入目录"; exit 1; }

    # 下载节点脚本并赋予执行权限
    curl -fsSL -O https://raw.githubusercontent.com/zhanglonglongSH/Ocean/refs/heads/main/ocean-node-quickstart.sh
    chmod +x ocean-node-quickstart.sh

    # 提示用户
    echo "即将运行节点脚本。请按照以下步骤操作："
    echo "1. 在安装过程中，选择 'Y' 并按 Enter。"
    echo "2. 输入你的 EVM 钱包的私钥，注意在私钥前添加 '0x' 前缀。"
    echo "3. 输入与私钥对应的 EVM 钱包地址。"
    echo "4. 连续按 5 次 Enter。"
    echo "5. 输入服务器的 IP 地址。"

    # 执行节点脚本
    ./ocean-node-quickstart.sh

    # 启动节点
    echo "启动节点..."
    docker-compose up -d

    echo "节点启动完成！"
}

function view_logs() {
    echo "查看 Docker 日志..."
    if [ -d "/root/ocean" ]; then
        cd /root/ocean && docker-compose logs -f || { echo "无法查看 Docker 日志"; exit 1; }
    else
        echo "请先启动节点，目录 '/root/ocean' 不存在。"
    fi
}

install_docker_and_compose
setup_and_start_node
