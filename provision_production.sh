#!/bin/bash
cd provisioning
ansible-playbook -i hosts --vault-password-file=~/.cuttlefish_ansible_vault_pass.txt -u ubuntu --ask-sudo-pass playbook.yml
