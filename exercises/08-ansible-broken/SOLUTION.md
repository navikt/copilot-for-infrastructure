# Solution: Exercise 08 - Broken Ansible Playbook

## The Broken Playbook Issues

The original playbook has multiple issues:

1. **YAML indentation error**: Task is indented incorrectly
2. **Wrong module parameter**: `state: install` should be `state: present`
3. **Missing `become: yes`**: Package installation needs root
4. **Handler name mismatch**: Notify uses wrong handler name
5. **Undefined variable**: References `{{ package_name }}` but it's not defined

## Investigation Steps

### 1. Check syntax

```bash
ansible-playbook --syntax-check /exercises/08-ansible-broken/broken-playbook.yml
```

Shows YAML syntax error.

### 2. Run with verbose output

```bash
ansible-playbook -i /ansible/inventory/hosts /exercises/08-ansible-broken/broken-playbook.yml -vvv
```

Shows detailed error messages for each issue.

## The Broken Playbook

```yaml
---
- hosts: webservers
  tasks:
  - name: Install Apache
    yum:
      name: httpd
      state: install  # ERROR: Wrong state value

   - name: Copy config  # ERROR: Wrong indentation
     copy:
       src: httpd.conf
       dest: /etc/httpd/conf/httpd.conf
     # ERROR: Missing notify for handler

  - name: Start Apache
    service:
      name: httpd
      state: started
      enabled: yes
    # ERROR: Missing become: yes

  handlers:
    - name: restart apache  # Note: lowercase
      service:
        name: httpd
        state: restarted
```

## The Fixed Playbook

```yaml
---
- name: Configure Apache Web Server
  hosts: webservers
  become: yes  # Run all tasks as root

  tasks:
    - name: Install Apache
      yum:
        name: httpd
        state: present  # FIXED: correct state value

    - name: Copy Apache config  # FIXED: correct indentation
      copy:
        src: httpd.conf
        dest: /etc/httpd/conf/httpd.conf
        owner: root
        group: root
        mode: '0644'
      notify: restart apache  # FIXED: added handler notification

    - name: Ensure Apache is started and enabled
      service:
        name: httpd
        state: started
        enabled: yes

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
```

## Issues Explained

### 1. YAML Indentation

YAML requires consistent indentation. All tasks must be at the same level:

```yaml
# Wrong
  tasks:
  - name: Task 1
    ...
   - name: Task 2  # One space too many!

# Correct
  tasks:
    - name: Task 1
      ...
    - name: Task 2
```

### 2. Module Parameters

Each Ansible module has specific parameter values:

```yaml
# Wrong
yum:
  state: install  # Not a valid value

# Correct
yum:
  state: present  # Valid values: present, latest, absent
```

### 3. Privilege Escalation

System tasks usually need root:

```yaml
# At play level (applies to all tasks)
- hosts: webservers
  become: yes

# Or per task
- name: Install package
  yum:
    name: httpd
    state: present
  become: yes
```

### 4. Handlers

Handlers run when notified and only once at the end:

```yaml
tasks:
  - name: Update config
    copy:
      src: config.conf
      dest: /etc/app/config.conf
    notify: restart app  # Must match handler name exactly

handlers:
  - name: restart app  # Name must match notify
    service:
      name: app
      state: restarted
```

## What Copilot Could Help With

1. **Syntax**: "Fix the YAML syntax in this Ansible playbook"
2. **Module docs**: "What parameters does the yum module accept?"
3. **Best practices**: "Review this playbook for best practices"
4. **Debugging**: "Why is this Ansible task failing?"

## Prevention

1. Use a YAML linter: `yamllint playbook.yml`
2. Use ansible-lint: `ansible-lint playbook.yml`
3. Always run `--syntax-check` before applying
4. Use IDE with YAML/Ansible support for real-time feedback
5. Keep playbooks simple and modular
