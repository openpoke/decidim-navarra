# Ansible

## Requirements

1. Edit `inventory` file and update the IPs of the servers
2. In both servers there must exist a root user created, and it should have the SSH private key copied and authorized, because the provision step doesn't asks for password
3. In your workstation install
  - python3
  - ansible: `pip3 install ansible`
  - passlib: `pip3 install passlib`
4. Git clone decidim repository (https://gesfuentes.admon-cfnavarra.es/git/summary/presidencia!WebParticipacionCiudadana.git). The ansible recipes and support files necessary for their execution are in vendor/ansible folder. Review the documentation at docs/installation_es.md

### Staging server

`ansible-playbook decidim_navarra_staging.yml --ask-vault-pass`

### Production server

`ansible-playbook decidim_navarra_production.yml --ask-vault-pass`

## Vagrant

For development purposes we recommend the use of Vagrant

- Install vagrant from https://www.vagrantup.com/downloads
- Install VirtualBox https://www.virtualbox.org/wiki/Downloads

In the project root, run:

```bash
> vagrant up --provision
```

To access the machine via ssh, you can get the id with:

```bash
> vagrant global-status
id       name    provider   state   directory
-------------------------------------------------------------------------------
1963b36  default virtualbox running /.../ansible-decidim-navarra
```

And then access via:

```bash
> vagrant ssh 1963b36
```
