#!/bin/bash
# CentOs 7.6 一键安装 Laf 0.8

#提示“请输入后台域名”并等待100秒，把用户的输入保存入变量consoleDomain中
while test -z "$consoleDomain"
do
  read -t 100 -p "请输入后台域名(如:console.laf.com):" consoleDomain
done
echo "后台域名为:$consoleDomain"
#提示“请输入接口域名”并等待100秒，把用户的输入保存入变量apiDomain中
while test -z "$apiDomain"
do
  read -t 100 -p "请输入接口域名(如:laf.com):" apiDomain
done
echo "接口域名为:$apiDomain"
#提示“请输入云存储域名”并等待100秒，把用户的输入保存入变量ossDomain中
while test -z "$ossDomain"
do
  read -t 100 -p "请输入云存储域名(如:oss.laf.com):" ossDomain
done
echo "接口域名为:$ossDomain"
#提示“请输入http端口号”并等待100秒，把用户的输入保存入变量httpPort中
read -t 100 -p "请输入http端口号(回车默认:80):" httpPort
httpPort=${httpPort:-80}
echo "http端口号为:$httpPort"
#提示“请输入https端口号”并等待100秒，把用户的输入保存入变量httpsPort中
read -t 100 -p "请输入https端口号(回车默认:443):" httpsPort
httpsPort=${httpsPort:-443}
echo "https端口号为:$httpsPort"
#提示“请输入默认http请求还是https请求”并等待100秒，把用户的输入保存入变量APP_SERVICE_DEPLOY_URL_SCHEMA中
# read -t 100 -p "请输入默认http请求还是https请求(回车默认:http):" APP_SERVICE_DEPLOY_URL_SCHEMA
# APP_SERVICE_DEPLOY_URL_SCHEMA=${APP_SERVICE_DEPLOY_URL_SCHEMA:-http}
# echo "默认请求方式:$APP_SERVICE_DEPLOY_URL_SCHEMA"

cd ~/
# 安装 git236以及下载laf项目
if [ "${gitV}" != "2.36.4" ]; then
echo "没有安装当前2.36.4，即将安装Git236"
yum install -y \
https://repo.ius.io/ius-release-el7.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
yum install git236 -y
fi
git clone https://gitclone.com/github.com/labring/laf
cd /root/laf/
git checkout v0.8.13

sed -i -r 's/^DEPLOY_DOMAIN=[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?/DEPLOY_DOMAIN='$(echo $apiDomain)'/g' /root/laf/deploy/docker-compose/.env
sed -i -r 's/^SYS_CLIENT_HOST=[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?/SYS_CLIENT_HOST='$(echo $consoleDomain)'/g' /root/laf/deploy/docker-compose/.env
sed -i -r 's/^OSS_DOMAIN=[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?/OSS_DOMAIN='$(echo $ossDomain)'/g' /root/laf/deploy/docker-compose/.env
sed -i -r 's/^PUBLISH_PORT=[0-9]*$/PUBLISH_PORT='$(echo $httpPort)'/g' /root/laf/deploy/docker-compose/.env
sed -i -r 's/^PUBLISH_HTTPS_PORT=[0-9]*$/PUBLISH_HTTPS_PORT='$(echo $httpsPort)'/g' /root/laf/deploy/docker-compose/.env

echo "安装Docker"
# 安装 docker
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker
# 设置docker 开机启动
systemctl enable docker.service
# 安装docker-compose 
curl -L https://get.daocloud.io/docker/compose/releases/download/v2.10.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 启动Laf 0.8
echo "正在启动 Laf 0.8"
cd /root/laf/deploy/docker-compose/
service start docker
docker network create laf_shared_network --driver bridge || true
docker-compose up -d

echo "如无报错,则控制台地址为"
echo "http://$consoleDomain"
echo "root账号密码为:password123"