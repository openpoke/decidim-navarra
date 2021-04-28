# Guía de instalación del entorno de Decidim

En esta guía se detallan los pasos para instalar el entorno y la app de Decidim en una máquina con Red Hat 7 desde cero. Al acabar la guía deberíamos tener instalados el servidor web (nginx), el servidor de aplicación (Phusion Passenger) y la propia aplicación de Decidim (Ruby on Rails) instalados y levantados en la máquina.

Además de esta guía manual se proporcionará un proyecto en Ansible para provisionar la máquina automáticamente. De hacerlo con Ansible no haría falta seguir esta guía.

Estos son los requisitos de la instalación:

- Va a haber dos entornos, de pre-producción (decidim-navarra-staging) y producción (decidim-navarra-production). Cada uno de ellos va a estar en una máquina cuya IP ha de ser añadida en el archivo inventory debajo de cada nombre. Por ejemplo:

```

[decidim-navarra-staging]

10.253.110.32

[decidim-navarra-staging]

10.253.110.32

```

- En cada una de las máquinas ha de existir un usuario root con una clave privada SSH copiada y autorizada para poder hacer uso de ella en el provisionamiento (el paso de provisionamiento no pide la password, es todo por medio de SSH). Estas máquinas también han de tener acceso al repositorio de decidim (https://gesfuentes.admon-cfnavarra.es/git/summary/presidencia!WebParticipacionCiudadana.git)

- En la estación de trabajo instalar python3, ansible (`pip3 install ansible`) y passlib (`pip3 install passlib`)

- Clonar en la estación de trabajo el repositorio de decidim (https://gesfuentes.admon-cfnavarra.es/git/summary/presidencia!WebParticipacionCiudadana.git). Las recetas de ansible y ficheros necesarios para la ejecución de sus tareas están en la carpeta vendor/ansible. En este documento (docs/installation_es.md) están las instrucciones para realizar el provisionamiento automático con Ansible así como un manual detallando todas las tareas que el propio Ansible automatiza.

- Antes de lanzar el playbook hay que definir el password del usuario y rellenar los valores de bases de datos. Todos esos valores están al final del playbook. Los valores pueden rellenarse en texto plano o encriptados.

Lo primero que hay que hacer es definir un password para nuestro vault. Este password se usará para encriptar valores y desencriptarlos al ejecutar cada playbook.

Para encriptar un valor hay que usar el comando `ansible-vault encrypt_string CADENA_A_ENCRIPTAR --ask-vault-pass`. Nos pedirá el password del vault que hemos definido y nos devolverá una cadena que empieza por `!vault | `. Todo eso debe ponerse en el campo del valor que hemos encriptado.

Una vez completados los datos que faltan en el playbook vamos a la carpeta del proyecto y lo lanzamos (cambiar por `decidim_navarra_staging.yml` para el entorno de staging):

```

ansible-playbook decidim_navarra_production.yml --ask-vault-pass

```

El password que pedirá es el mismo que definimos al encriptar los valores.

- Además de esto hay que generar el fichero secrets correspondiente si no está generado ya para el entorno (staging o producción). Esto se hace ejecutando el siguiente comando (el ejemplo es para producción):

```

ansible-vault create ruta/a/directorio/ansible/sites/decidim/vars/secrets_production.yml

```

Para staging el fichero deberá ser secrets_staging.yml

El contenido del fichero debe tener las siguientes claves:

```

secret_key_base:

census_webservice_address:

census_webservice_code:

census_webservice_purpose:

census_webservice_official_document_number:

census_webservice_official_name:

census_webservice_expedient_id:

census_webservice_procedure_code:

census_webservice_procedure_name:

census_webservice_processing_unit:

mailer_delivery_method:

email_webservice_address:

email_webservice_username_token_user:

email_webservice_username_token_password:

rollbar_access_token:

mailer_sender:

smtp_username:

smtp_password:

smtp_domain:

smtp_port:

geocoder_lookup_app_id:

geocoder_lookup_app_code:

```

Para saber dónde poner el valor de cada clave por favor contactad con el proveedor (Populate).

- La aplicación usará una base de datos Postgresql 11.0, pero esta estará instalada en una máquina aparte. Es necesario que la base de datos tenga instaladas las extensiones `ltree`, `pg_trgm` y `plpgsql`. En la propia máquina de la aplicación, eso sí, se instalará el cliente de Postgresql 11.0. Para poder instalar el cliente es necesario que la libreria `llvm-toolset-7` esté instalada de antemano en la máquina.

Esta instalación creará en el servidor al usuario `participa_decidim` para gestionar la app.

### Añadir repositorio EPEL

Añadir el repositorio de paquetes EPEL (URL {{ epel_repo_url }}) al sistema

```
yum install {{ epel_repo_url }}
```

### Importar la clave GPG de EPEL

```
rpm --import {{ epel_repo_gpg_key_url }}
```

### Instalar los paquetes básicos

```
yum install -y git tree htop vim psmisc gnupg zip ntp ruby-devel ImageMagick screen curl nodejs tmux libicu-devel ca-certificates npm net-tools zlib-devel readline-devel the_silver_searcher nodejs-bindings node-gyp python3-psycopg2 python3-pip
```

### Instalar yarn

```
npm install -g yarn
```

### Establecer UTC como zona horaria del servidor

```
ln -s /usr/share/zoneinfo/UTC /etc/localtime
```

### Configurar el hostname del servidor

Ejecutar este comando

```
hostname {{ hostname }}
```

Añadir localhost a /etc/hosts

```
127.0.0.1 localhost
```

Añadir el hostname a /etc/hosts

```
127.0.0.1 {{hostname}}
```

### Añadir el repositorio para fullstaq ruby en yum

```
yum-config-manager --add-repo https://yum.fullstaqruby.org/centos-7/$basearch
```

### Instalar el paquete fullstaq ruby

```
yum install -y fullstaq-ruby-common
```

### Instalar las versiones de ruby

```
yum install -y {{ ruby_versions }}
```

### Instalar el plugin de rbenv `rbenv-vars`

Este plugin permite a las aplicaciones cargar las variables de entorno definidas en el fichero `.rbenv-vars`

```
git clone https://github.com/rbenv/rbenv-vars.git /usr/lib/rbenv/plugins/rbenv-vars
```

### Activar rbenv

Añadir una entrada en /etc/bashrc para activar rbenv

```
eval "$(rbenv init -)"
```

### Activar plugin rbenv-vars

Añadir una entrada en /etc/bashrc para activar el plugin

```
"eval \"$(/usr/lib/rbenv/plugins/rbenv-vars/bin/rbenv-vars)\""
```

### Copiar una versión parcheada de rbenv para soportar plugins

Copiar en `/usr/lib/rbenv/libexec/rbenv`

```
#!/usr/bin/env bash
set -e

if [ "$1" = "--debug" ]; then
  export RBENV_DEBUG=1
  shift
fi

if [ -n "$RBENV_DEBUG" ]; then
  export PS4='+ [${BASH_SOURCE##*/}:${LINENO}] '
  set -x
fi

abort() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "rbenv: $*"
    fi
  } >&2
  exit 1
}

if enable -f "${BASH_SOURCE%/*}"/../libexec/rbenv-realpath.dylib realpath 2>/dev/null; then
  abs_dirname() {
    local path
    path="$(realpath "$1")"
    echo "${path%/*}"
  }
else
  [ -z "$RBENV_NATIVE_EXT" ] || abort "failed to load 'realpath' builtin"

  READLINK=$(type -p greadlink readlink | head -1)
  [ -n "$READLINK" ] || abort "cannot find readlink - are you missing GNU coreutils?"

  resolve_link() {
    $READLINK "$1"
  }

  abs_dirname() {
    local cwd="$PWD"
    local path="$1"

    while [ -n "$path" ]; do
      cd "${path%/*}"
      local name="${path##*/}"
      path="$(resolve_link "$name" || true)"
    done

    pwd
    cd "$cwd"
  }
fi

if [ -z "${RBENV_ROOT}" ]; then
  RBENV_ROOT="${HOME}/.rbenv"
else
  RBENV_ROOT="${RBENV_ROOT%/}"
fi
export RBENV_ROOT

if [ -z "${RBENV_DIR}" ]; then
  RBENV_DIR="$PWD"
else
  [[ $RBENV_DIR == /* ]] || RBENV_DIR="$PWD/$RBENV_DIR"
  cd "$RBENV_DIR" 2>/dev/null || abort "cannot change working directory to '$RBENV_DIR'"
  RBENV_DIR="$PWD"
  cd "$OLDPWD"
fi
export RBENV_DIR

export RBENV_SYSTEM_VERSIONS_DIR="${RBENV_SYSTEM_VERSIONS_DIR:-/usr/lib/rbenv/versions}"


shopt -s nullglob

bin_path="$(abs_dirname "$0")"
for plugin_bin in "/usr/lib/rbenv/plugins/"*/bin; do
  PATH="${plugin_bin}:${PATH}"
done
export PATH="${bin_path}:${PATH}"

RBENV_HOOK_PATH="${RBENV_HOOK_PATH}:${RBENV_ROOT}/rbenv.d"
if [ "${bin_path%/*}" != "$RBENV_ROOT" ]; then
  # Add rbenv's own `rbenv.d` unless rbenv was cloned to RBENV_ROOT
  RBENV_HOOK_PATH="${RBENV_HOOK_PATH}:${bin_path%/*}/rbenv.d"
fi
RBENV_HOOK_PATH="${RBENV_HOOK_PATH}:/usr/local/etc/rbenv.d:/etc/rbenv.d:/usr/lib/rbenv/hooks"
for plugin_hook in "/usr/lib/rbenv/plugins/"*/etc/rbenv.d; do
  RBENV_HOOK_PATH="${RBENV_HOOK_PATH}:${plugin_hook}"
done
RBENV_HOOK_PATH="${RBENV_HOOK_PATH#:}"
export RBENV_HOOK_PATH

shopt -u nullglob


command="$1"
case "$command" in
"" )
  { rbenv---version
    rbenv-help
  } | abort
  ;;
-v | --version )
  exec rbenv---version
  ;;
-h | --help )
  exec rbenv-help
  ;;
* )
  command_path="$(command -v "rbenv-$command" || true)"
  if [ -z "$command_path" ]; then
    if [ "$command" == "shell" ]; then
      abort "shell integration not enabled. Run 'rbenv init' for instructions."
    else
      abort "no such command '$command'"
    fi
  fi

  shift 1
  if [ "$1" = --help ]; then
    if [[ "$command" == "sh-"* ]]; then
      echo "rbenv help \"$command\""
    else
      exec rbenv-help "$command"
    fi
  else
    exec "$command_path" "$@"
  fi
  ;;
esac

```

## Instalar el paquete monit

Instalar el paquete monit

```
yum install -y monit
```

Arrancar monit

```
systemctl start monit
```

Copiar la configuración de los servicios de monit definidos, ej: sshd, uso de disco

```
# /etc/monit.d/sshd.monit
check process sshd with pidfile /var/run/sshd.pid
  start program "/usr/bin/systemctl start sshd"
  stop  program "/usr/bin/systemctl stop  sshd"
  if failed host 127.0.0.1 port 22 protocol ssh then restart
  if 5 restarts within 5 cycles then timeout

# /etc/monit.d/disk-usage.monit
check device root with path /
  if space usage > 70% then alert

```

Resetear monit

```
monit quit; sleep 5; monit
```

### Instalar Memcached

```
yum install -y memcached
```

### Crear carpeta para el pid

```
mkdir /var/run/memcached -o memcached -g memcached
```

### Añadir linea en /etc/sysconfig/memcached para crear el pidfile

```
OPTIONS="-l 127.0.0.1 -P /var/run/memcached/memcached.pid"
```

### Arrancar memcached

```
systemctl start memcached
```

### Habilitar memcached en monit

Añadir en `/etc/monit.d//memcached.monit`

```
check process memcached with pidfile /var/run/memcached/memcached.pid
  group system
  start program "/usr/bin/systemctl start memcached"
  stop  program "/usr/bin/systemctl stop  memcached"
  if failed host 127.0.0.1 port 11211 then restart
  if 5 restarts within 5 cycles then timeout

```

### Añadir el repositorio de passenger

```
curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
## Nginx + Passenger
```

### Añadir repositorios de CentOS necesarios para algunos paquetes

En /etc/yum.repos.d/ crear un fichero centos.repo con el contenido:

```
[base]
name=CentOS $releasever – Base
baseurl=http://mirror.centos.org/centos/7/os/$basearch/
gpgcheck=0
enabled=1

[updates]
name=CentOS $releasever – Updates
baseurl=http://mirror.centos.org/centos/7/updates/$basearch/
gpgcheck=0
enabled=1

[extras]
name=CentOS $releasever – Extras
baseurl=http://mirror.centos.org/centos/7/extras/$basearch/
gpgcheck=0
enabled=1

```

### Instalar nginx y phusion passenger

```
yum install -y nginx-mod-http-passenger || sudo yum-config-manager --enable cr && sudo yum install -y nginx-mod-http-passenger
```

### Copiar el fichero de configuración de passenger

```
##
# Phusion Passenger config
##

passenger_root /usr/share/ruby/vendor_ruby/phusion_passenger/locations.ini;
passenger_ruby /home/{{ rbenv_user }}/.rbenv/shims/ruby;
passenger_instance_registry_dir /var/run/passenger-instreg;
passenger_max_pool_size 8;
```

### Copiar el fichero de configuración de nginx

Copiar en `{{nginx_config}}/nginx.conf`

```
user {{ nginx_user }};
worker_processes auto;
pid /var/run/nginx.pid;
worker_rlimit_nofile 8192;

include /etc/nginx/modules.conf.d/*.conf;

events {
  worker_connections 8000;
}

http {

  ##
  # Basic Settings
  ##

  server_tokens off;

  server {
    return 404;
  }

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;

  server_names_hash_bucket_size 128;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  charset_types text/css text/plain text/vnd.wap.wml application/javascript application/json application/rss+xml application/xml;

  ##
  # Logging Settings
  ##

  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  ##
  # Gzip Settings
  ##

  gzip on;
  gzip_disable "msie6";
  gzip_http_version  1.1;
  gzip_comp_level    5;
  gzip_min_length    256;
  gzip_proxied       any;
  gzip_vary          on;
    gzip_types
    application/atom+xml
    application/javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rss+xml
    application/vnd.geo+json
    application/vnd.ms-fontobject
    application/x-font-ttf
    application/x-web-app-manifest+json
    application/xhtml+xml
    application/xml
    font/opentype
    image/bmp
    image/svg+xml
    image/x-icon
    text/cache-manifest
    text/css
    text/plain
    text/vcard
    text/vnd.rim.location.xloc
    text/vtt
    text/x-component
    text/x-cross-domain-policy;

  ##
  # Virtual Host Configs
  ##

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}

```

### Copiar el fichero de configuración de monit para nginx en /etc/monit.d/nginx.monit

Copiar en `/etc/monit.d/nginx.monit`

```
check process nginx with pidfile /var/run/nginx.pid
  group system
  start program "/usr/bin/systemctl start nginx"
  stop program "/usr/bin/systemctl stop nginx"
  if failed port 80 with timeout 10 seconds then restart
  if 5 restarts within 5 cycles then timeout
```

### Parar nginx antes de borrar y añadir nuevos usuarios y grupos

```
systemctl stop nginx
```

### Remove the nginx user and group

```
userdel nginx
groupdel nginx
```

### Crear grupo  {{nginx_group}}

```
groupadd {{nginx_group}}
```

### Crear usuario {{nginx_user}}

```
useradd -m -d {{nginx_home}} -g {{nginx_group}} {{nginx_user}}
```

### Dar permisos a la home del nuevo grupo

```
chmod 770 {{nginx_home}}
```

### Crear directorio de sites-enabled

```
mkdir {{nginx_config}}/sites-enabled
```

### Crear directorio de sites-available

```
mkdir {{nginx_config}}/sites-available
```

### Crear directorio de modules.conf.d

```
mkdir {{nginx_config}}/modules.conf.d
```

### Crear enlaces simbólicos para los módulos de nginx

### Arrancar nginx

```
systemctl start nginx
```

### Instalar postgres para Centos/RH

```
yum-config-manager --add-repo=https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```

### Instalar paquetes necesarios para el cliente de postgresql 9.6

```
yum install -y python-psycopg2 postgresql96-devel postgresql96-libs
```

### Instalar paquetes necesarios para el cliente de postgresql 11.0

```
yum install -y llvm-toolset-7 centos-release-scl python-psycopg2 postgresql11-devel postgresql11-libs
```

### Instalar paquetes necesarios para el cliente de postgresql 12.0

```
yum install -y centos-release-scl-rh python-psycopg2 postgresql12-devel postgresql12-libs
```

### Instalar redis

```
yum install -y redis
```

### Copiar configuración en /etc/default/redis-server

```
# redis-server configure options

# ULIMIT: Call ulimit -n with this argument prior to invoking Redis itself.
# This may be required for high-concurrency environments. Redis itself cannot
# alter its limits as it is not being run as root. (default: do not call
# ulimit)
#
ULIMIT=65536

```

### Configurar el servicio

Crear el fichero `/usr/lib/systemd/system/redis-server.service` con el contenido:

```
[Unit]
Description=Redis persistent key-value database
After=network.target

[Service]
ExecStart=/usr/bin/redis-server /etc/redis.conf --daemonize no
ExecStop=/usr/bin/redis-cli shutdown
User=redis
Group=redis

[Install]
WantedBy=multi-user.target

```

### Recargar daemons

```
systemctl daemon-reload
```

### Copiar configuración en /etc/redis.conf

```
daemonize no
dir /var/lib/redis/
pidfile /var/run/redis/redis-server.pid
logfile /var/log/redis/redis-server.log

port 6379
bind {{redis_bind_address}}
timeout 300

loglevel notice

## Default configuration options
databases 16

save 900 1
save 300 10
save 60 10000

rdbcompression yes
dbfilename dump.rdb

appendonly no

```

### Crear directorio

```
mkdir /var/run/redis/ -o redis -g redis -m #{file>mode}
```

### Habilitar redis en monit. Copiar configuración en /etc/monit.d/redis.monit

```
check process redis-server
  matching "/usr/bin/redis-server"
  group system
  start program = "/usr/bin/systemctl start redis-server"
  stop  program = "/usr/bin/systemctl stop redis-server"
  if failed host {{redis_bind_address}} port {{6379}} then restart
  if 5 restarts within 5 cycles then timeout

```

### Añadir el usuario al grupo de redis

```
usermod -a -G redis '{{redis_user}}'
```

### Habilitar la rotación de logs

Copiar en `/etc/logrotate.d/decidim`

```
{{app_base_path}}/shared/log/{{rails_env}}.log {
    daily
    rotate {{logrotate_frequency}}
    compress
    dateext
    dateformat -%Y%m%d-{{hostname}}
    missingok
    notifempty
    sharedscripts
    postrotate
        touch {{app_base_path}}/current/tmp/restart.txt
    endscript
}

{{app_base_path}}/shared/log/sidekiq.log {
    daily
    rotate {{logrotate_frequency}}
    compress
    dateext
    dateformat -%Y%m%d-{{hostname}}
    missingok
    notifempty
    sharedscripts
    postrotate
        monit restart -g {{app_id}}-sidekiq
    endscript
}

```

### Crear directorios

```
mkdir {{{app_base_path}},{{app_base_path}}/shared,{{app_base_path}}/shared/bundle,{{app_base_path}}/shared/config,{{app_base_path}}/shared/log,{{app_base_path}}/shared/public,{{app_base_path}}/shared/tmp,{{app_base_path}}/shared/vendor,{{app_base_path}}/shared/cache,{{app_base_path}}/releases,{{app_base_path}}/repo} -o {{app_user}} -g {{app_group}} -m #{file>mode}
```

### Create el fichero de configuración de base de datos para la app

Copiar en `/var/www/decidim/shared/config/database.yml`

```
{{rails_env}}:
  adapter: postgresql
  encoding: unicode
  database: {{site_db_name}}
  pool: 5
  username: {{site_db_user}}
  password: {{site_db_password}}
  host: {{site_db_host}}
  port: {{site_db_port}}

```

### Create el fichero de variables de entorno

Copiar en `/var/www/decidim/shared/.rbenv-vars`

```
## Rails
ROLLBAR_ACCESS_TOKEN={{rollbar_access_token}}
RAILS_MAX_THREADS=5
RACK_ENV={{rails_env}}
RAILS_ENV={{rails_env}}
# Use both options for full compatibility
SECRET_KEY_BASE={{secret_key_base}}

## Redis
REDIS_URL={{redis_url}}

## Geocoder
GEOCODER_LOOKUP_APP_ID={{geocoder_lookup_app_id}}
GEOCODER_LOOKUP_APP_CODE={{geocoder_lookup_app_code}}

## Language
LC_ALL=C.UTF-8
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8

## Census service integration
CENSUS_WEBSERVICE_ADDRESS={{census_webservice_address}}
CENSUS_WEBSERVICE_CODE={{census_webservice_code}}
CENSUS_WEBSERVICE_PURPOSE={{census_webservice_purpose}}
CENSUS_WEBSERVICE_OFFICIAL_DOCUMENT_NUMBER={{census_webservice_official_document_number}}
CENSUS_WEBSERVICE_OFFICIAL_NAME={{census_webservice_official_name}}
CENSUS_WEBSERVICE_EXPEDIENT_ID={{census_webservice_expedient_id}}
CENSUS_WEBSERVICE_PROCEDURE_CODE={{census_webservice_procedure_code}}
CENSUS_WEBSERVICE_PROCEDURE_NAME={{census_webservice_procedure_name}}
CENSUS_WEBSERVICE_PROCESSING_UNIT={{census_webservice_processing_unit}}

## email service integration
MAILER_DELIVERY_METHOD={{mailer_delivery_method}}
EMAIL_WEBSERVICE_ADDRESS={{email_webservice_address}}
EMAIL_WEBSERVICE_USERNAME_TOKEN_USER={{email_webservice_username_token_user}}
EMAIL_WEBSERVICE_USERNAME_TOKEN_PASSWORD={{email_webservice_username_token_password}}

```

### Habilitar sidekiq en monit

Copiar en `/etc/monit.d//monit_sidekiq.j2`

```
check process sidekiq_{{app_id}}_0
  with pidfile "{{app_base_path}}/shared/tmp/pids/sidekiq-0.pid"
  start program = "/bin/su - {{app_user}} -c 'cd {{app_base_path}}/current && $HOME/.rbenv/bin/rbenv exec bundle exec sidekiq  --index 0 --pidfile {{app_base_path}}/shared/tmp/pids/sidekiq-0.pid --environment {{rails_env}}  --logfile {{app_base_path}}/shared/log/sidekiq.log -d'" with timeout 30 seconds
  stop program = "/bin/su - {{app_user}} -c 'cd {{app_base_path}}/current && $HOME/.rbenv/bin/rbenv exec bundle exec sidekiqctl stop {{app_base_path}}/shared/tmp/pids/sidekiq-0.pid'" with timeout 20 seconds
  group {{app_id}}-sidekiq

```

### Crear directorio temporal 'current'

```
mkdir /var/www/decidim/current -o centos -g www-data -m #{file>mode}
```

### Enlace simbolico a current/public

```
ln -s /var/www/decidim/shared/public /var/www/decidim/current/public
```

### Eliminar directorio temporal 'current'

```
rm -rf /var/www/decidim/current
```

### Copiar el fichero de virtual host para la app de Rails

Copiar en `/etc/nginx/sites-available/decidim`

```
{% if https_enabled %}
server {
  listen      8081;
  server_name {% for domain in sites_domains %} {{domain}}{% endfor %};
  return       301 https://$host$request_uri;
}
{% endif %}

server {
  {% if https_enabled %}
  listen 443 default_server ssl http2;
  listen [::]:443 default_server ssl http2;

  ssl on;
  ssl_certificate {{ssl_certificate}};
  ssl_certificate_key {{ssl_certificate_key}};
  {% else %}
  listen 8081;
  {% endif %}

  server_name {% for domain in sites_domains %} {{domain}}{% endfor %};

  {% if http_auth_enabled %}
  auth_basic "Decidim";
  auth_basic_user_file {{http_auth_file}};
  {% endif %}

  passenger_enabled on;
  client_max_body_size 50M;

  access_log {{nginx_access_log}};
  error_log  {{nginx_error_log}};

  root {{app_base_path}}/current/public;

  rails_env {{rails_env}};

  location ~ ^/(assets|uploads)/ {
    try_files $uri =404;
    expires max;
    add_header Cache-Control public;
    gzip_static on;
    break;
  }

#  # Let's encrypt
#  location /.well-known {
#    auth_basic off;
#  }
}

```

### Habilitar virtual hosts

```
ln -s /etc/nginx/sites-available/decidim /etc/nginx/sites-enabled/decidim
systemctl restart nginx
```

### Copiar el crontab de la aplicación

Copiar en `/etc/cron.d/decidim`

```
# Generate open data files everydaty at 1 am
  0 1 * * * {{app_user}} /bin/bash -c 'export PATH="$HOME/.rbenv/bin:$PATH" ; eval "$(rbenv init -)"; cd {{app_base_path}}/current; RAILS_ENV={{rails_env}} bin/rails decidim:open_data:export'

# Generate stats everyday at 3am
  0 3 * * * {{app_user}} /bin/bash -c 'export PATH="$HOME/.rbenv/bin:$PATH" ; eval "$(rbenv init -)"; cd {{app_base_path}}/current; RAILS_ENV={{rails_env}} bin/rails decidim:metrics:all'

```

### Crear directorios de deploy

```
mkdir /home/{{app_user}}/deploy/{{app_id}}/config -o {{app_user}} -g {{app_group}} -m #{file>mode}
mkdir /home/{{app_user}}/deploy/{{app_id}}/log -o {{app_user}} -g {{app_group}} -m #{file>mode}
```

### Crear directorio de config/deploy

```
mkdir /home/{{app_user}}/deploy/{{app_id}}/config/deploy -o {{app_user}} -g {{app_group}} -m #{file>mode}
```

### Crear Capfile

```
# /home/{{app_user}}/deploy/{{app_id}}/Capfile
# frozen_string_literal: true

# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"
require "capistrano/passenger"
require "capistrano/rbenv"
require "capistrano/sidekiq"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
Dir.glob("lib/capistrano/tasks/*.cap").each { |r| import r }
Dir.glob("lib/capistrano/**/*.rb").each { |r| import r }

```

### Crear .ruby-version

```
# /home/{{app_user}}/deploy/{{app_id}}/.ruby-version
2.7.1

```

### Crear Gemfile

```
# /home/{{app_user}}/deploy/{{app_id}}/Gemfile
# frozen_string_literal: true

source "https://rubygems.org"

gem "capistrano", "3.8.0", require: false
gem "capistrano-bundler"
gem "capistrano-passenger"
gem "capistrano-rails"
gem "capistrano-rbenv"
gem "capistrano-sidekiq"
gem "ed25519"
gem "bcrypt_pbkdf"

```

### Lanzar bundle install

```
cd /home/{{app_user}}/deploy/{{app_id}} && bundle install --path=./vendor/bundle
```

### Crear config/deploy.rb

```
# /home/{{app_user}}/deploy/{{app_id}}/config/deploy.rb
# frozen_string_literal: true

lock "3.8.0"

set :application, "{{app_id}}"
set :repo_url, "{{app_repo_url}}"

set :linked_files, fetch(:linked_files, []).push(*%w(
  config/database.yml
  .rbenv-vars
))
set :linked_dirs, fetch(:linked_dirs, []).push(*%w(
  log
  tmp/pids
  tmp/cache
  tmp/sockets
  vendor/bundle
  public/system
  public/cache
  public/uploads
  public/assets
))
set :sidekiq_config, -> { File.join(release_path, "config", "sidekiq.yml") }
set :passenger_restart_with_touch, true

task :clean_vendor_ansible do
  run_locally { execute "rm -rf #{release_path}/vendor/ansible" }
end
before "bundler:install", "clean_vendor_ansible"

```

### Crear el archivo de entorno de la app

Usar staging.rb o production.rb según el entorno que estemos instalando

```
# /home/{{app_user}}/deploy/{{app_id}}/config/deploy/(staging|production).rb
f{environment.rb}
```

### Desplegar la app por primera vez

Usar staging o production según el entorno que estemos instalando

```
cd /home/{{app_user}}/deploy/{{app_id}} && bundle exec cap (staging|production) deploy
```