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
