#!/bin/sh

# Install git
yum install -y git

# Format /dev/xvdl as xfs file system for LogStream config volume
mkfs -t xfs ${CONFIG_VOLUME_PATH}
echo "UUID=$(blkid -s UUID -o value ${CONFIG_VOLUME_PATH})  ${CRIBL_INSTALL_DIR}  xfs defaults,nofail 0 2" >> /etc/fstab
mkdir ${CRIBL_INSTALL_DIR}
mount -a

# Add unprivileged user for Cribl LogStream service
adduser --system -d ${CRIBL_INSTALL_DIR} cribl

# Grab LogStream bits
curl -Lso - $(if [[ $(uname -m) =~ ^a ]]; then curl -s https://cdn.cribl.io/dl/latest | sed 's/-x/-arm/'; else curl -s https://cdn.cribl.io/dl/latest; fi) | tar zxvf - --strip-components=1 -C ${CRIBL_INSTALL_DIR}

# Set the default admin user password to the instance id
mkdir -p ${CRIBL_INSTALL_DIR}/local/cribl/auth
cat << EOF > ${CRIBL_INSTALL_DIR}/local/cribl/auth/users.json
{"username":"admin","first":"admin","last":"admin","email":"admin","roles":["admin"],"password":"$(TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"}
EOF

# Configure Leader information
mkdir -p ${CRIBL_INSTALL_DIR}/local/_system
cat <<-EOF > ${CRIBL_INSTALL_DIR}/local/_system/instance.yml
distributed:
  mode: master
  master:
    host: ${LEADER_CONFIG.CRIBL_LEADER_HOST}
    port: ${LEADER_CONFIG.CRIBL_LEADER_PORT}
    authToken: ${LEADER_CONFIG.CRIBL_AUTH_TOKEN}
    tls:
      disabled: true
EOF

%{ if can(LICENSES) ~}
cat <<-EOF > ${CRIBL_INSTALL_DIR}/local/cribl/licenses.yml
licenses:
%{ for license in LICENSES ~}
  - ${license}
%{ endfor ~}
EOF
%{ endif ~}

# Configure git repo for CodeCommit service
# TODO
# cd ${CRIBL_INSTALL_DIR}
# git config credential.helper '!aws codecommit credential-helper $@'
# git config credential.UseHttpPath true

# Ensure permissions are correct
chown -R cribl:cribl ${CRIBL_INSTALL_DIR}

# Enable management of Cribl service under systemd
${CRIBL_INSTALL_DIR}/bin/cribl boot-start enable -u cribl

# Startup LogStream!
systemctl start cribl