#!/bin/bash
#userdata for docker-compose Install

set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1


yum install docker jq -y
sudo service docker start
docker pull drone/drone:0.7
sudo usermod -a -G docker ec2-user


curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > docker-compose
sudo chown root docker-compose
sudo mv docker-compose /usr/local/bin
sudo chmod +x /usr/local/bin/docker-compose


cat >.env <<EOL
DRONE_GITHUB=true
DRONE_OPEN=true
DRONE_ADMIN=brettswift
EOL

echo DRONE_GITHUB_CLIENT=`aws ssm get-parameters --region 'us-west-2' --with-decryption --names "/drone/github_client" | jq -r '.Parameters[]  | .Value'` >> .env
echo DRONE_GITHUB_SECRET=`aws ssm get-parameters --region 'us-west-2' --with-decryption --names "/drone/github_secret" | jq -r '.Parameters[]  | .Value'` >> .env
echo DRONE_SECRET=`openssl rand -base64 32` >> .env
echo DRONE_HOST=`curl http://169.254.169.254/latest/meta-data/public-hostname/` >> .env


cat >docker-compose.yml <<EOL
version: '2'

services:
  drone-server:
    image: drone/drone:0.7
    ports:
      - 80:8000
    volumes:
      - /var/lib/drone:/var/lib/drone/
    restart: always
    environment:
      - DRONE_OPEN=true
      - DRONE_HOST=\${DRONE_HOST}
      - DRONE_GITHUB=true
      - DRONE_GITHUB_CLIENT=\${DRONE_GITHUB_CLIENT}
      - DRONE_GITHUB_SECRET=\${DRONE_GITHUB_SECRET}
      - DRONE_SECRET=\${DRONE_SECRET}

  drone-agent:
    image: drone/drone:0.7
    command: agent
    restart: always
    depends_on:
      - drone-server
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DRONE_SERVER=ws://drone-server:8000/ws/broker
      - DRONE_SECRET=\${DRONE_SECRET}
EOL

/usr/local/bin/docker-compose up -d
