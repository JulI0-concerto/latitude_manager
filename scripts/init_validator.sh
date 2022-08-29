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
  echo "Updating packages..."
  apt update
  echo "Installing ansible, curl, unzip..."
  apt install ansible curl unzip --yes

  ansible-galaxy collection install ansible.posix
  ansible-galaxy collection install community.general
}

download_latitude_manager () {
  echo "Downloading Solana validator manager version $1"
  cmd="https://github.com/JulI0-concerto/latitude_manager/archive/refs/tags/$1.zip"
  echo "starting $cmd"
  curl -fsSL "$cmd" --output latitude_manager.zip
  echo "Unpacking"
  unzip ./latitude_manager.zip -d .

  mv latitude_manager* latitude_manager
  rm ./latitude_manager.zip
  cd ./latitude_manager || exit
  cp -r ./inventory_example ./inventory
}

init_validator () {

  ansible-playbook --connection=local --inventory ./inventory/"${1}".yaml --limit localhost  playbooks/config.yaml --extra-vars "{ \
    'swap_file_size_gb': $2, \
    'ramdisk_size_gb': $3, \
    }"

}

while getopts ":c:r:s:v" options; do
 case "${options}" in
  c)
    CLUSTER=${OPTARG}
   ;;
  r)
    RAM_DISK_SIZE={OPTARG}
   ;;
  s)
    SWAP_SIZE={OPTARG}
   ;;
  v)
    VERSION={OPTARG}
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

install_ansible
download_latitude_manager $VERSION
init_validator $CLUSTER $SWAP_SIZE $RAM_DISK_SIZE
