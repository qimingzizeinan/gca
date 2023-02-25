echo -e "---------docker Login--------"
docker login --username=$1  --password=$2
echo -e "---------docker Stop--------"
docker stop my-project
echo -e "---------docker Rm--------"
# docker rm my-project
docker rmi qimingzizeinan1/my-project
echo -e "---------docker Pull--------"
docker pull qimingzizeinan1/my-project
echo -e "---------docker Create and Start--------"
docker run --rm -d -p 80:80 --name my-project qimingzizeinan1/my-project
echo -e "---------deploy Success--------"