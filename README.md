## WebParticipacionCiudadana

Herramienta de participación ciudadana para que las ciudadanas puedan participar en los procesos de participación definidos y publicados en la Web.

En la carpeta vendor/ansible se encuentran las recetas de Ansible para instalar la aplicación. No realizar cambios manuales, los cambios se actualizan por medio de un script que obtiene los datos de otra fuente: cualquier cambio que se realice manualmente en esa carpeta y se suba con commits en este repositorio será ignorado cada vez que se ejecute el script de actualización.

Para actualizar la carpeta vendor/ansible con la versión más reciente de la fuente original ejecutar desde la raíz del proyecto ./bin/update_ansible.sh. El script elimina la carpeta, la vuelve a crear, descarga la última versión y crea un commit con los cambios
