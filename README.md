# nephelaiio.playbook-awx

[![Build Status](https://travis-ci.org/nephelaiio/ansible-playbook-awx.svg?branch=master)](https://travis-ci.org/nephelaiio/ansible-playbook-awx)

A set of [ansible playbooks](https://galaxy.ansible.com/nephelaiio/ansible-playbook-awx-local) to install and configure [Ansible AWX](https://github.com/ansible/awx).

## Playbook Variables

The following parameters are available/required for playbook invocation

| required | variable | description | default |
| --- | --- | --- | --- |
| *yes* | acme_certificate_domain | the fqdn to generate an acme certificate for | ansible_fqdn |
| *yes* | acme_certificate_aws_accesskey_id | an ec2 key id with route53 management rights | lookup('env', 'AWS_ACCESS_KEY_ID') |
| *yes* | acme_certificate_aws_accesskey_secret  | an ec2 key secret | lookup('env', 'AWS_SECRET_ACCESS_KEY') |

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
git checkout https://galaxy.ansible.com/nephelaiio/ansible-playbook-awx awx
ansible-playbook -i inventory/ awx/local.yml
```

## Testing

Please make sure your environment has [docker](https://www.docker.com) installed in order to run role validation tests. Additional python dependencies are listed in the [requirements](https://raw.githubusercontent.com/nephelaiio/ansible-role-requirements/master/requirements.txt)

This role is tested automatically against the following distributions (docker images):

  * Ubuntu Bionic
  * Ubuntu Xenial

You can test the role directly from sources using command ` molecule test `

## License

This project is licensed under the terms of the [MIT License](/LICENSE)
