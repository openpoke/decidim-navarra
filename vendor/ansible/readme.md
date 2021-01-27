# Ansible

## Requirements

1. Edit `inventory` file and update the IPs of the servers
2. In both servers there must exist a root user created, and it should have the SSH private key copied and authorized, because the provision step doesn't asks for password
3. In your workstation install
  - python3
  - ansible: `pip3 install ansible`
  - passlib: `pip3 install passlib`
4. Git clone this repository (TODO: repository URL)

## Steps

The installation process is divided in three steps:

- provision: executed as root, it installs base packages, setups the firewall and creates a regular user (centos)
- services: executed as centos, it installs the basic services: nginx, passenger, ruby, postgres, monit and redis
- sites: executed as centos, it prepares the server to run Decidim

### Staging server

1. `bin/decidium_staging_provision.sh`
2. `bin/decidium_staging_services.sh`
3. `bin/decidium_staging_site.sh`

### Production server

1. `bin/decidium_production_provision.sh`
2. `bin/decidium_production_services.sh`
3. `bin/decidium_production_site.sh`

## Vagrant

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
