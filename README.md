# nephelaiio.playbooks-awx

[![Build Status](https://travis-ci.org/nephelaiio/ansible-playbooks-awx.svg?branch=master)](https://travis-ci.org/nephelaiio/ansible-playbooks-awx)

A set of ansible playbooks to install and configure [Ansible AWX](https://github.com/ansible/awx).

## Playbook descriptions

The following lists the group targets and descriptions for every playbook

| playbook      | description                            | target    |
| ---           | ---                                    | ---       |
| local.yml     | perform a local install of awx         | awx_app   |
| configure.yml | configure awx projects/templates/...   | awx_proxy |
| nginx.yml     | install an ngnix reverse proxy for awx | awx_proxy |

## Playbook variables

The following parameters are available/required for playbook invocation

### [local.yml](local.yml):
| required | variable          | description                    | default |
| ---      | ---               | ---                            | ---     |
| no       | awx_release       | target awx release             | '6.1.0' |
| no       | awx_pg_user       | postgresql connection user     | 'awx'   |
| *yes*    | awx_pg_pass       | postgresql connection password | n/a     |
| no       | awx_admin_user    | awx administrator user         | 'admin' |
| *yes*    | awx_admin_pass    | awx administrator password     | n/a     |
| no       | awx_rabbitmq_user | awx administrator user         | 'awx    |
| *yes*    | awx_rabbitmq_pass | awx administrator password     | n/a     |

### [configure.yml](configure.yml):
| required | variable      | description                                  | default |
| *yes*    | awx_url       | target awx url                               | n/a     |
| *no*     | awx_users     | [list of awx users](#Users)                  | []      |
| *no*     | awx_schedules | [list of awx template schedules](#Schedules) | []      |
| *no*     | awx_templates | [list of awx template](#Templates)           | []      |
| *no*     | awx_organizations | [list of awx template](#Organizations) | []      |

## Data Formats

### Users
```{yaml}
awx_users:
  - first_name: First Name
    last_name: Last Name
    username: testuser
    password: supersecret
    superuser: yes
```

### Templates
```{yaml}
awx_templates:
  - name: ping
    state: absent
    job_type: run
    project: awx
    inventory: awx
    playbook: ping.yml
    credentials:
      - name: awx.ssh
        kind: ssh
```

### Schedules
```{yaml}
awx_schedules:
  - name: ping.daily
    job_template: ping
    enabled: true
    rrule: "DTSTART:20190705T002000Z RRULE:FREQ=DAILY;INTERVAL=1"
  - name: ping.fortnight
    job_template: ping
    enabled: true
    rrule: "DTSTART:20190705T002000Z RRULE:FREQ=WEEKLY;INTERVAL=2"
  - name: ping.monthly
    job_template: ping
    enabled: true
    rrule: "DTSTART:20190705T002000Z RRULE:FREQ=MONTHLY;INTERVAL=1"
```

### Organizations
```{yaml}
awx_organizations:

  - name: Demo Organization
    state: absent

  - name: nephelai.io
    state: present

    credentials:
      - name: awx.github
        kind: scm
        username: "{{ awx_github_user }}"
        password: "{{ awx_github_pass }}"
      - name: awx.vault
        kind: vault
        vault_password: "{{ awx_vault_awx_pass }}"
      - name: awx.ssh
        kind: ssh
        username: "{{ awx_machine_user }}"
        ssh_key_data: "{{ awx_machine_key }}"

    projects:
      - name: Demo Project
        state: absent
      - name: awx
        scm_type: git
        scm_url: https://github.com/nephelaiio/ansible-playbooks-awx.git
        scm_branch: master
        scm_delete_on_update: false
        scm_credential: awx.github
        scm_update_on_launch: false
        scm_update_cache_timeout: 60
        scm_clean: false
      - name: inventory
        scm_type: git
        scm_url: https://github.com/nephelaiio/ansible-playbooks.git
        scm_branch: master
        scm_delete_on_update: false
        scm_credential: awx.github
        scm_update_on_launch: false
        scm_update_cache_timeout: 60
        scm_clean: false

    inventories:
      - name: Demo Inventory
        state: absent
      - name: awx
        source: scm
        source_project: inventory
        source_path: inventory/awx
        overwrite: true
        overwrite_vars: true
        update_on_launch: false
        update_on_project_update: true

    workflows: []
```

## Dependencies

This playbook has the following git submodule dependencies:

* [submodules/awx](https://github.com/ansible/awx)

And the following role dependencies by play (no dependencies if play is not listed):

### [local.yml](local.yml):
* [nephelaiio.plugins](https://galaxy.ansible.com/nephelaiio/plugins)
* [nephelaiio.docker](https://galaxy.ansible.com/nephelaiio/docker)
* [nephelaiio.pip](https://galaxy.ansible.com/nephelaiio/pip)

### [nginx.yml](nginx.yml):
* [nginxinc.nginx](https://galaxy.ansible.com/nginxinc/nginx)
* [nephelaiio.acme_certificate_route53](https://galaxy.ansible.com/nephelaiio/acme_certificate_route53)

See the [requirements](https://raw.githubusercontent.com/nephelaiio/ansible-role-requirements/master/requirements.txt) and [meta](meta.yml) files for more details

## Example Invocation

```
git checkout https://galaxy.ansible.com/nephelaiio/ansible-playbooks-awx awx
ansible-playbook -i inventory/ awx/local.yml
```

## Testing (TODO)

Please make sure your environment has [docker](https://www.docker.com) installed in order to run role validation tests. Additional python dependencies are listed in the [requirements](https://raw.githubusercontent.com/nephelaiio/ansible-role-requirements/master/requirements.txt)

This role is tested automatically against the following distributions (docker images):

  * Ubuntu Bionic
  * Ubuntu Xenial

You can test the role directly from sources using command ` molecule test `

## License

This project is licensed under the terms of the [MIT License](/LICENSE)
