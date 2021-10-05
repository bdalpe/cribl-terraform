#!/bin/sh

# Install git
yum install -y git

# Format /dev/xvdl as xfs file system for LogStream config volume
mkfs -t xfs /dev/xvdl
echo "UUID=$(blkid -s UUID -o value /dev/xvdl)  /opt/cribl  xfs defaults,nofail 0 2" >> /etc/fstab
mkdir /opt/cribl
mount -a

# Add unprivileged user for Cribl LogStream service
adduser --system -d /opt/cribl cribl

# Grab LogStream bits
curl -Lso - $(if [[ $(uname -m) =~ ^a ]]; then curl -s https://cdn.cribl.io/dl/latest | sed 's/-x/-arm/'; else curl -s https://cdn.cribl.io/dl/latest; fi) | tar zxvf - --strip-components=1 -C /opt/cribl

# Set the default admin user password to the instance id
mkdir -p /opt/cribl/local/cribl/auth
cat << EOF > /opt/cribl/local/cribl/auth/users.json
{"username":"admin","first":"admin","last":"admin","email":"admin","roles":["admin"],"password":"$(TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"}
EOF

# Configure git repo for CodeCommit service
# TODO
# cd /opt/cribl
# git config credential.helper '!aws codecommit credential-helper $@'
# git config credential.UseHttpPath true

# Ensure permissions are correct
chown -R cribl:cribl /opt/cribl/

# Enable management of Cribl service under systemd
/opt/cribl/bin/cribl boot-start enable -u cribl

# Startup LogStream!
systemctl start cribl