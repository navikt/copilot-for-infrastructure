#!/bin/bash
# Exercise 08: Broken Ansible Playbook
# The playbook is already broken - just point them to it

echo "Exercise 08: Broken Ansible Playbook"
echo ""
echo "This exercise is different - there's no 'break' step."
echo "The playbook at /exercises/08-ansible-broken/broken-playbook.yml"
echo "is already broken with multiple issues."
echo ""
echo "Your task:"
echo "1. SSH into the ansible-control container: make shell-ansible"
echo "2. Try to run the playbook and observe the errors"
echo "3. Fix the issues one by one"
echo "4. Successfully run the playbook"
echo ""
echo "Commands to try:"
echo "  ansible-playbook --syntax-check /exercises/08-ansible-broken/broken-playbook.yml"
echo "  ansible-playbook -i /ansible/inventory/hosts /exercises/08-ansible-broken/broken-playbook.yml"
echo ""
echo "Tip: Copy the playbook to a working location before editing:"
echo "  cp /exercises/08-ansible-broken/broken-playbook.yml /ansible/my-fixed-playbook.yml"
