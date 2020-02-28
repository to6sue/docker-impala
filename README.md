# docker-impala

# 0. Build
docker build -t ksk124/impala ./

# 1. Docker compose

- up

docker-compose -f docker-compose.yml up -d

- down

docker-compose -f docker-compose.yml down

- scale change

docker-compose -f docker-compose.yml up --scale impala-server=3 --scale kudu-tserver=3 -d

- NOTICE

docker-entrypoint.sh 에서 impala-server 쪽 waiting.sh 는 kubernetes를 위한 docker image 생성시 주석처리

단순 docker-compose 사용할때만 수행
