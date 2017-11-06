#!/bin/bash
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 16126D3A3E5C1192
sudo apt-get update -o Acquire::http::No-Cache=True 
sudo apt-get update
sudo apt-get install ansible sshpass
cd provisioning
ansible-playbook -i hosts --vault-password-file=~/.cuttlefish_ansible_vault_pass.txt -u ubuntu --ask-pass --ask-sudo-pass playbook.yml
