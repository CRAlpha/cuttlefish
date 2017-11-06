#!/bin/bash

echo "Updating Ansible galaxy roles"
ansible-galaxy install -f ANXS.postgresql --roles-path=provisioning/roles/
ansible-galaxy install -f DavidWittman.redis --roles-path=provisioning/roles/
ansible-galaxy install -f abtris.nginx-passenger --roles-path=provisioning/roles/
ansible-galaxy install -f rvm_io.ruby --roles-path=provisioning/roles/

echo "Provisioning"
cd provisioning
ansible-playbook -i hosts --vault-password-file=~/.cuttlefish_ansible_vault_pass.txt -u ubuntu --ask-pass --ask-sudo-pass playbook.yml
