#!/bin/bash
sudo apt install -y golang-go

git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd

sudo mv bin/cri-dockerd /usr/local/bin/

sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i 's:/usr/bin/cri-dockerd:/usr/local/bin/cri-dockerd:' \
    /etc/systemd/system/cri-docker.service

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
