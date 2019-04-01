#!/bin/bash
sudo apt-get update && \
sudo apt-get -y install \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg-agent \
	software-properties-common && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update && \
sudo apt-get install -y docker-ce docker-ce-cli containerd.io && \
sudo docker run hello-world
sudo usermod -aG docker $USER
echo "logout and return, you will be use docker without sudo"
