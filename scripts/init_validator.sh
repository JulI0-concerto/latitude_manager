#!/bin/bash
#set -x -e

echo "############### Latitude.sh for Solana #################"
echo "###  This script will init a Solana validator node   ###"
echo "########################################################"

usage() {
  echo "Usage: $0 [ -c CLUSTER ] [ -r RAM_DISK_SIZE ] [ -s SWAP_SIZE ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

install_ansible () {

  echo "install_ansible" >> install_ansible.t

  echo "Updating packages..."
  apt update
  echo "Installing ansible, curl, unzip..."
  apt install ansible --yes

  ansible-galaxy collection install ansible.posix
  ansible-galaxy collection install community.general
}

init_validator () {

  SOLANA_VERSION="--extra-vars {\"solana_version\":\"1.11.6\"}"

  echo "install_ansible ${1} ${2} ${3}" >> init_validator.t

  ansible-playbook --connection=local --inventory ./playbooks/inventory/"${1}".yaml --limit localhost  playbooks/config.yaml --extra-vars "{ \
    'swap_file_size_gb': ${2}, \
    'ramdisk_size_gb': ${3}, \
    }"

  ansible-playbook --connection=local --inventory ./playbooks/inventory/"${1}".yaml --limit localhost  playbooks/bootstrap_validator.yaml --extra-vars "@/etc/latitude_manager/latitude_manager.conf" $SOLANA_VERSION

}

while getopts ":c:r:s:v:" options; do
 case "${options}" in
  c)
    CLUSTER=${OPTARG}
    ;;
  r)
    RAM_DISK_SIZE=${OPTARG}
    ;;
  s)
    SWAP_SIZE=${OPTARG}
    ;;
  v)
    VERSION=${OPTARG}
    ;;
  :)
    echo "Error: -${OPTARG} requires an argument."
    exit_abnormal
    ;;
  *)
    exit_abnormal
    ;;
 esac
done

echo "Latitude manager version ${VERSION}"

install_ansible
init_validator "$CLUSTER" "$SWAP_SIZE" "$RAM_DISK_SIZE"
