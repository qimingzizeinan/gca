echo -e "---------docker Login--------"
# 登录docker
docker login --username=$1  --password=$2
echo -e "---------docker Stop--------"
# 暂停服务上正在运行的container
docker stop my-project
echo -e "---------docker Rm--------"
# docker rm my-project
# 删除旧镜像
# Warning
# 注意这里的main。如果不写main则需要主要到github action的工作流中使用的tag是什么。
# 这两个地方的tag要一一对应，否则这里不写，服务器部署时会默认使用latest这个tag。导致上线后的文件一直没有变更.
docker rmi qimingzizeinan1/my-project:main
echo -e "---------docker Pull--------"
# 拉取新镜像从Docker Hub中
docker pull qimingzizeinan1/my-project:main
echo -e "---------docker Create and Start--------"
# 启动新容器
docker run --rm -d -p 80:80 --name my-project qimingzizeinan1/my-project:main
echo -e "---------deploy Success--------"
