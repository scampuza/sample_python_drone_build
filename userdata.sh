#!/bin/bash

yum install docker -y
sudo service docker start
docker pull drone/drone:0.7
sudo usermod -a -G docker ec2-user
mkdir /etc/drone
touch /etc/drone/dronerc

cat >/etc/drone/dronerc <<EOL
DRONE_GITHUB=true
DRONE_OPEN=true
DRONE_GITHUB_CLIENT=<enter client id>
DRONE_GITHUB_SECRET=<enter secret>
EOL


sudo docker run \
  --volume /var/lib/drone:/var/lib/drone \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --env-file /etc/drone/dronerc \
  --restart=always \
  --publish=80:8000 \
  --detach=true \
  --name=drone \
  drone/drone:0.7

