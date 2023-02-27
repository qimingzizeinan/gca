# github-action CI/CD

## 相关文档

除文档外，本文档的最下方有几篇参考的文章。可先阅读。

[github action基本概念与描述](https://docs.github.com/zh/actions/learn-github-actions/understanding-github-actions)

[github action上下文文档](https://docs.github.com/zh/actions/learn-github-actions/contexts)

[Github Action marketplace](https://github.com/marketplace?type=actions)

[Personal Access toke](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## 基本概念介绍

- Event：工作流要在什么事件触发后执行。类似于Vue的生命周期函数
- Job：工作流都包含哪些Jog(作业)。一个工作流包含一个或多个Job.默认并行执行，可以串行执行。串行的配置方式可阅读上方文档或者该[文章](https://q.shanyue.tech/deploy/ci-ci.html#%E4%BD%BF%E7%94%A8-github-actions-%E8%BF%9B%E8%A1%8C-ci)
- Step：Job的组成部分.定义具体是什么操作需要自动化的执行。可以访问工作区和文件系统.

## 场景化

通常新的功能开发完，需要部署上线的时候，要做如下几步.

1. 手动build
2. 打新的镜像
3. 给镜像打tag并push到Docker Hub
4. 服务登录并拉取镜像
5. 暂停然后删除旧容器、删除旧镜像
6. 基于新的镜像启动新的容器

## 本项目实现讲解

```yaml
# 显示在github action页面左侧的名称
name: GitHub Actions Build and Deploy Demo
# 监听触发工作流测事件
on:
  # 监听push事件
  # 事件监听和事件的筛选器文档: https://docs.github.com/zh/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore
  push:
    # 事件触发的筛选器
    # 这里的事件筛选器含义是发生在哪个分支触发了事件
    branches:
      # main分支 也可以写成其他形式
      - main
# 作业
# https://docs.github.com/zh/actions/using-workflows/workflow-syntax-for-github-actions#jobs
jobs:
  # 名称，定义后即为一个job(可以随意定义)
  build-and-deploy:
    # 作业在什么机器上运行
    runs-on: ubuntu-latest
    strategy:
      # 如果说需要测试功能在多系统或者多语言版本下的表现，可以使用矩阵策略。
      # https://docs.github.com/zh/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategy
      # https://docs.github.com/zh/actions/using-jobs/using-a-matrix-for-your-jobs
      matrix:
        node-version: ["14.*"]
    steps:
      # 步骤的名称,此名称将在github action页面的workflow执行时标明执行的step名称
      - name: Checkout
        # 标识此步骤将要运行. 简单理解使用了一个其他人写好的插件
        # actions/checkout@v2作用是类似于git checkout的作用，
        # 将代码拷贝到当前这个job的工作流中，以便于后续build使用
        uses: actions/checkout@v2
      - name: copy file via ssh password
        # appleboy/scp-action@master插件作用是将文件通过scp命令将文件拷贝到服务器
        uses: appleboy/scp-action@master
        # with是给插件传递参数
        with:
          # secrets是存在敏感信息(服务器访问密码登)的一个上下文。
          # secrets 项目的setting -> Actions secrets and variables -> Actions 打开后即可看到 New respository secret按钮
          # 上下文文档: https://docs.github.com/zh/actions/learn-github-actions/contexts
          host: ${{ secrets.TENCENT_CLOUD_IP }}
          username: ${{ secrets.TENCENT_CLOUD_NAME }}
          password: ${{ secrets.TENCENT_CLOUD_PASSWORD }}
          source: "./deploy.sh"
          target: "/root"
      # pnpm 命令准备,如果没有这个插件后续的pnpm install 操作会报pnpm 不存在
      - uses: pnpm/action-setup@v2
        with:
          version: 7
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'pnpm'
      # node_modules的缓存处理。如果不加缓存每次都install，工作流的时间会非常长。
      # 因此不做cache处理,将会严重影响使用体验
      - name: Cache
        id: cache-dependencies
        uses: actions/cache@v3
        with:
          path: |
            **/node_modules
          key: ${{runner.OS}}-${{hashFiles('**/pnpm-lock.yaml')}}
      # 安装依赖。命中缓存则跳过此步
      - name: Installing Dependencies
        if: steps.cache-dependencies.outputs.cache-hit != 'true'
        run: pnpm install
      # 执行vue项目中的测试命令,如果test没有跑过，则工作流执行失败
      - name: Test
        run: pnpm run test:run
      # 执行vue项目打包命令
      - name: Build
        run: |
          pnpm build
      # 登录到Docker Hub    
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      # 抽取镜像的tag和labels等信息,用于后续镜像打包时使用
      - name: Extract metadata (tags, labels) for Docker
        # 后续step获取这个step输出时使用
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: qimingzizeinan1/my-project
      # 打包并且推送镜像到Docker Hub
      - name: Build and push Docker image
        uses: docker/build-push-action@v3
        with:
          context: .
          push: true
          # steps.meta这里的meta是前面的id: meta的那个step
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
      # ssh 登录远程服务器
      # 类似于使用: ssh root@122.122.122.122    
      - name: ssh docker login
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.TENCENT_CLOUD_IP }}
          username: ${{ secrets.TENCENT_CLOUD_NAME }}
          password: ${{ secrets.TENCENT_CLOUD_PASSWORD }}
          # 登录服务器后要执行的命令
          # 这里的cd ~是切换目录到/root目录后执行deploy.sh。
          # 而deploy.sh是前面通过scp插件kcopy到/root目录的，可以看一下前面的配置
          # deploy.sh中也有着对应的讲解
          script: cd ~ && sh deploy.sh ${{ secrets.DOCKER_USERNAME }} ${{ secrets.DOCKER_PASSWORD }}

```

`deploy.sh`
```sh
echo -e "---------docker Login--------"
# 登录docker
docker login --username=$1  --password=$2
echo -e "---------docker Stop--------"
# 停止正在运行的container
docker stop my-project
echo -e "---------docker Rm--------"
# docker rm my-project
# 删除旧镜像
# Warning
# 注意这里的main。如果不写main则需要主要到github action的工作流中使用的tag是什么。
# 这两个地方的tag要一一对应，如果这里不写，服务器部署时会默认使用latest这个tag。导致上线后的文件一直没有变更.
docker rmi qimingzizeinan1/my-project:main
echo -e "---------docker Pull--------"
# 拉取新镜像从Docker Hub中
docker pull qimingzizeinan1/my-project:main
echo -e "---------docker Create and Start--------"
# 启动新容器
docker run --rm -d -p 80:80 --name my-project qimingzizeinan1/my-project:main
echo -e "---------deploy Success--------"
```

## 相关文章

[github-action + docker + 腾讯云实现自动化部署](https://juejin.cn/post/7156518122617307166#heading-13)

[作为前端，要学会用Github Action给自己的项目加上CICD](https://juejin.cn/post/7113562222852309023#heading-0)

- 实现回滚
- 邮件通知端对端测试
- 自动化发布release包到github
  
[构建功能分支测试环境发布](https://q.shanyue.tech/deploy/ci-intro.html#cicd-%E5%B7%A5%E5%85%B7%E4%B8%8E%E4%BA%A7%E5%93%81)

[结合镜像容器服务托管镜像实现不上传到Docker Hub](https://juejin.cn/post/7022092455528890399#heading-23)

[Electron、Github Action自动打包发布与更新](https://juejin.cn/post/7094865414353584164)
