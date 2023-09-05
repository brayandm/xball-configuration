#!/bin/bash

#Setting environment variables
source .env

#Updating the packages
apt-get update

#Making swap space
sudo fallocate -l $SCRIPT_ENV_SWAP_SIZE /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

#Installing docker engine
sudo apt-get -y remove docker docker-engine docker.io containerd runc
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

#Creating the docker network
docker network create $SCRIPT_ENV_DOCKER_NETWORK

#Adding github-runner user
sudo useradd -m github-runner

#Adding github-runner user to docker group
sudo usermod -aG docker github-runner

#Downloading and Configuring the github runner
su - github-runner -c "mkdir frontend"
su - github-runner -c "cd frontend && curl -o actions-runner-linux-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-x64-2.304.0.tar.gz"
su - github-runner -c "cd frontend && echo "292e8770bdeafca135c2c06cd5426f9dda49a775568f45fcc25cc2b576afc12f  actions-runner-linux-x64-2.304.0.tar.gz" | shasum -a 256 -c"
su - github-runner -c "cd frontend && tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz"
su - github-runner -c "cd frontend && ./config.sh --url $SCRIPT_ENV_RUNNER_URL_FRONTEND --token $SCRIPT_ENV_RUNNER_TOKEN_FRONTEND --unattended"
cd /home/github-runner/frontend
./svc.sh install github-runner
sudo ./svc.sh start

su - github-runner -c "mkdir backend"
su - github-runner -c "cd backend && curl -o actions-runner-linux-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-x64-2.304.0.tar.gz"
su - github-runner -c "cd backend && echo "292e8770bdeafca135c2c06cd5426f9dda49a775568f45fcc25cc2b576afc12f  actions-runner-linux-x64-2.304.0.tar.gz" | shasum -a 256 -c"
su - github-runner -c "cd backend && tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz"
su - github-runner -c "cd backend && ./config.sh --url $SCRIPT_ENV_RUNNER_URL_BACKEND --token $SCRIPT_ENV_RUNNER_TOKEN_BACKEND --unattended"
cd /home/github-runner/backend
./svc.sh install github-runner
sudo ./svc.sh start