# Exercise 08: Broken Ansible Playbook

## Scenario

A junior admin wrote an Ansible playbook to deploy a new configuration, but it's failing with multiple errors. The playbook is in `/exercises/08-ansible-broken/broken-playbook.yml`. Your task is to fix all the issues and successfully run the playbook.

## Symptoms

```bash
# Try to run the playbook
make shell-ansible
ansible-playbook -i /ansible/inventory/hosts /exercises/08-ansible-broken/broken-playbook.yml

# Various errors:
# - YAML syntax errors
# - Module parameter errors
# - Permission errors
# - Missing handlers
```

## What to Investigate

1. **YAML syntax**: Indentation and structure
2. **Module parameters**: Are they correct?
3. **Privilege escalation**: Does the task need `become: yes`?
4. **Handlers**: Are they defined and notified correctly?
5. **Variables**: Are all variables defined?

## Useful Commands

```bash
# SSH into ansible-control
make shell-ansible

# Check playbook syntax
ansible-playbook --syntax-check /exercises/08-ansible-broken/broken-playbook.yml

# Run with verbose output
ansible-playbook -i /ansible/inventory/hosts /exercises/08-ansible-broken/broken-playbook.yml -vvv

# Check Ansible documentation for modules
ansible-doc yum
ansible-doc copy
ansible-doc service
```

## The Playbook

Take a look at the broken playbook:
```bash
cat /exercises/08-ansible-broken/broken-playbook.yml
```

## Hints

<details>
<summary>Hint 1</summary>
YAML is very sensitive to indentation. All items at the same level must have the same indentation.
</details>

<details>
<summary>Hint 2</summary>
The `yum` module uses `state: present` or `state: latest`, not `state: install`.
</details>

<details>
<summary>Hint 3</summary>
Installing packages requires root privileges. You need `become: yes` for those tasks.
</details>

<details>
<summary>Hint 4</summary>
Handlers must be notified by name. Check if the handler name matches the notify statement.
</details>

## Ask Copilot

Try asking Copilot:
- "Fix the YAML syntax errors in this playbook: [paste playbook]"
- "What parameters does the Ansible yum module accept?"
- "When do I need to use become: yes in Ansible?"
- "How do Ansible handlers work?"
- "Review this Ansible playbook for errors"
