#!/bin/bash


APP_ENV="${APP_ENV:-staging}"
SERVER_IP="${SERVER_IP:-192.168.1.99}"
SSH_USER="${SSH_USER:-$(whoami)}"
KEY_USER="${KEY_USER:-$(whoami)}"

DOCKER_PULL_IMAGES=("postgres:12.2" "redis:5.0.8")
COPY_UNIT_FILES=("iptables-restore" "swap" "postgres" "redis")


function preseed_staging() {
cat << EOF
STAGING SERVER (DIRECT VIRTUAL MACHINE) DIRECTIONS:
  1. Configure a static IP address directly on the VM
     su
     <enter password>
     nano /etc/network/interfaces
     [change the last line to look like this, remember to set the correct
      gateway for your router's IP address if it's not 192.168.1.1]
iface eth0 inet static
  address ${SERVER_IP}
  netmask 255.255.255.0
  gateway 192.168.1.1

  2. Reboot the VM and ensure the Debian CD is mounted

  3. Install sudo
     apt-get update && apt-get install -y -q sudo

  4. Add the user to the sudo group
     adduser ${SSH_USER} sudo

  5. Run the commands in: ${0} --help
     Example:
       ./deploy.sh -a
EOF
}

function configure_sudo () {
  echo "Configuring passwordless sudo..."
  scp "sudo/sudoers" "${SSH_USER}@${SERVER_IP}:/tmp/sudoers"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo chmod 440 /tmp/sudoers
sudo chown root:root /tmp/sudoers
sudo mv /tmp/sudoers /etc
  '"
  echo "done!"
}

function add_ssh_key() {
  echo "Adding SSH key..."
  cat "$HOME/.ssh/id_rsa.pub" | ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
mkdir /home/${KEY_USER}/.ssh
cat >> /home/${KEY_USER}/.ssh/authorized_keys
    '"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
chmod 700 /home/${KEY_USER}/.ssh
chmod 640 /home/${KEY_USER}/.ssh/authorized_keys
sudo chown ${KEY_USER}:${KEY_USER} -R /home/${KEY_USER}/.ssh
  '"
  echo "done!"
}

function configure_secure_ssh () {
  echo "Configuring secure SSH..."
  scp "ssh/sshd_config" "${SSH_USER}@${SERVER_IP}:/tmp/sshd_config"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo chown root:root /tmp/sshd_config
sudo mv /tmp/sshd_config /etc/ssh
sudo systemctl restart ssh
  '"
  echo "done!"
}

function install_docker () {
  echo "Configuring Docker..."
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo apt-get update && sudo apt-get install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
sudo usermod -aG docker "${KEY_USER}"
  '"
  echo "done!"
}

function docker_pull () {
  echo "Pulling Docker images..."
  for image in "${DOCKER_PULL_IMAGES[@]}"
  do
    ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'docker pull ${image}'"
  done
  echo "done!"
}

function git_init () {
  echo "Initialize git repo and hooks..."
  scp "git/post-receive/mobydock" "${SSH_USER}@${SERVER_IP}:/tmp/mobydock"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo apt-get update && sudo apt-get install -y -q git
sudo rm -rf /var/git/mobydock.git /var/git/mobydock
sudo mkdir -p /var/git/mobydock.git /var/git/mobydock
sudo git --git-dir=/var/git/mobydock.git --bare init

sudo mv /tmp/mobydock /var/git/mobydock.git/hooks/post-receive
sudo chmod +x /var/git/mobydock.git/hooks/post-receive
sudo chown ${SSH_USER}:${SSH_USER} -R /var/git/mobydock.git /var/git/mobydock
  '"
  echo "done!"
}

function configure_firewall () {
  echo "Configuring iptables firewall..."
  scp "iptables/rules-save" "${SSH_USER}@${SERVER_IP}:/tmp/rules-save"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo mkdir -p /var/lib/iptables
sudo mv /tmp/rules-save /var/lib/iptables
sudo chown root:root -R /var/lib/iptables
  '"
  echo "done!"
}

function copy_units () {
  echo "Copying systemd unit files..."
  for unit in "${COPY_UNIT_FILES[@]}"
  do
    scp "units/${unit}.service" "${SSH_USER}@${SERVER_IP}:/tmp/${unit}.service"
    ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo mv /tmp/${unit}.service /etc/systemd/system
sudo chown ${SSH_USER}:${SSH_USER} /etc/systemd/system/${unit}.service
sudo systemctl daemon-reload
  '"
  done
  echo "done!"
}

function enable_base_units () {
  echo "Enabling base systemd units..."
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
docker network create mobydock &> /dev/null || true
sudo systemctl enable iptables-restore.service
sudo systemctl start iptables-restore.service
sudo systemctl enable swap.service
sudo systemctl start swap.service
sudo systemctl enable postgres.service
sudo systemctl start postgres.service
sudo systemctl enable redis.service
sudo systemctl start redis.service
  '"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'sudo systemctl restart docker'"
  echo "done!"
}

function provision_server () {
  configure_sudo
  echo "---"
  add_ssh_key
  echo "---"
  configure_secure_ssh
  echo "---"
  install_docker
  echo "---"
  docker_pull
  echo "---"
  git_init
  echo "---"
  configure_firewall
  echo "---"
  copy_units
  echo "---"
  enable_base_units
}


function help_menu () {
cat << EOF
Usage: ${0} (-h | -S | -u | -k | -s | -d | -l | -g | -f | -c | -b | -a)

ENVIRONMENT VARIABLES:
   SERVER_IP        IP address to work on, ie. staging or production
                    Defaulting to ${SERVER_IP}

   SSH_USER         User account to ssh and scp in as
                    Defaulting to ${SSH_USER}

   KEY_USER         User account linked to the SSH key
                    Defaulting to ${KEY_USER}

OPTIONS:
   -h|--help                 Show this message
   -S|--preseed-staging      Preseed intructions for the staging server
   -u|--sudo                 Configure passwordless sudo
   -k|--ssh-key              Add SSH key
   -s|--ssh                  Configure secure SSH
   -d|--docker               Install Docker
   -l|--docker-pull          Pull necessary Docker images
   -g|--git-init             Install and initialize git
   -f|--firewall             Configure the iptables firewall
   -c|--copy--units          Copy systemd unit files
   -b|--enable-base-units    Enable base systemd unit files
   -a|--all                  Provision everything except preseeding

EXAMPLES:
   Configure passwordless sudo:
        $ deploy -u

   Add SSH key:
        $ deploy -k

   Configure secure SSH:
        $ deploy -s

   Install Docker:
        $ deploy -d

  Pull necessary Docker images:
        $ deploy -l

   Install and initialize git:
        $ deploy -g

   Configure the iptables firewall:
        $ deploy -f

   Copy systemd unit files:
        $ deploy -c

   Enable base systemd unit files:
        $ deploy -b

   Configure everything together:
        $ deploy -a
EOF
}


while [[ $# > 0 ]]
do
case "${1}" in
  -S|--preseed-staging)
  preseed_staging
  shift
  ;;
  -u|--sudo)
  configure_sudo
  shift
  ;;
  -k|--ssh-key)
  add_ssh_key
  shift
  ;;
  -s|--ssh)
  configure_secure_ssh
  shift
  ;;
  -d|--docker)
  install_docker
  shift
  ;;
  -l|--docker-pull)
  docker_pull
  shift
  ;;
  -g|--git-init)
  git_init
  shift
  ;;
  -f|--firewall)
  configure_firewall
  shift
  ;;
  -c|--copy-units)
  copy_units
  shift
  ;;
  -b|--enable-base-units)
  enable_base_units
  shift
  ;;
  -a|--all)
  provision_server
  shift
  ;;
  -h|--help)
  help_menu
  shift
  ;;
  *)
  echo "${1} is not a valid flag, try running: ${0} --help"
  ;;
esac
shift
done
