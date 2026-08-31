#!/bin/bash
# Installed by Ansible over SSH after the VS Code EC2 instance is up.
set -eux
export HOME=/root
dnf install -y tar gzip curl libatomic || yum install -y tar gzip curl libatomic
CS_VERSION=4.96.4
curl -fsSL -o /tmp/code-server.tgz \
  "https://github.com/coder/code-server/releases/download/v${CS_VERSION}/code-server-${CS_VERSION}-linux-amd64.tar.gz"
mkdir -p /opt
tar -C /opt -xzf /tmp/code-server.tgz
ln -sfn "/opt/code-server-${CS_VERSION}-linux-amd64" /opt/code-server
mkdir -p /home/ec2-user/.config/code-server /home/ec2-user/project
cat > /home/ec2-user/.config/code-server/config.yaml <<'CSCONF'
bind-addr: 0.0.0.0:8080
auth: password
password: Forrest2026Demo
cert: false
CSCONF
cat > /home/ec2-user/project/README.md <<'README'
# Dev Environment
Provisioned by Ansible Automation Portal.
README
chown -R ec2-user:ec2-user /home/ec2-user/.config /home/ec2-user/project
cat > /etc/systemd/system/code-server.service <<'UNIT'
[Unit]
Description=code-server
After=network.target
[Service]
Type=simple
User=ec2-user
Environment=HOME=/home/ec2-user
ExecStart=/opt/code-server/bin/code-server --config /home/ec2-user/.config/code-server/config.yaml /home/ec2-user/project
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now code-server
