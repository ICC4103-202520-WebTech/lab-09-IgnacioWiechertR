Informe de Despliegue: Implementación de Aplicación Rails con Kamal
Proyecto: lab-09-IgnacioWiechertR Servidor: 104.248.177.200 (DigitalOcean) Tecnologías Clave: Ruby on Rails, Kamal, Docker, PostgreSQL

Introducción
Este documento detalla el proceso de despliegue de una aplicación Ruby on Rails desde un entorno de desarrollo local a un servidor de producción (Droplet de DigitalOcean) utilizando la herramienta de despliegue Kamal. El informe cubre la configuración inicial del entorno, la instalación de dependencias, la configuración de la base de datos y la resolución de varios problemas críticos que surgieron durante el proceso.

Fase 1: Configuración del Entorno Local y del Servidor
El proceso comenzó con la configuración de Kamal en la máquina de desarrollo y la preparación del servidor de destino con Docker.

1.1. Inicialización de Kamal (Local)
El primer paso fue instalar e inicializar Kamal en el proyecto local:

Bash

gem install kamal
kamal init
1.2. Instalación y Configuración de Docker (Servidor)
El servidor de destino requería Docker. La instalación inicial falló al intentar localizar el paquete docker-buildx-plugin, indicando que los repositorios estándar de Ubuntu no contenían las dependencias necesarias.

Resolución: Se agregaron los repositorios oficiales de Docker al servidor:

Bash

# 1. Instalar prerrequisitos para repositorios HTTPS
sudo apt-get install ca-certificates curl gnupg lsb-release

# 2. Agregar la clave GPG oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Configurar el repositorio "stable"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar las dependencias de Docker
sudo apt update
sudo apt install docker-buildx-plugin
1.3. Problema de Permisos de Docker (Servidor)
Tras la instalación, se verificó la conectividad con el servidor (ssh root@104.248.177.200) y se confirmó que Docker estaba instalado (docker ps). Sin embargo, surgieron problemas de permisos al intentar ejecutar comandos de Docker como usuario no-root.

Resolución: El usuario local (ignac) fue agregado al grupo docker en el servidor, eliminando la necesidad de usar sudo para cada comando de Docker.

Bash

# Se verificó si el grupo existía (getent group docker) o se creó (sudo groupadd docker)
sudo usermod -aG docker $USER
Fase 2: Aprovisionamiento de la Base de Datos PostgreSQL
La aplicación requería una base de datos PostgreSQL, que no estaba preinstalada en el servidor.

2.1. Instalación de PostgreSQL (Servidor)
Se instaló el servicio de PostgreSQL directamente en el sistema operativo del host:

Bash

sudo apt install -y postgresql
2.2. Configuración de Acceso Remoto
Por defecto, PostgreSQL solo escucha conexiones de localhost. Fue necesario configurarlo para aceptar conexiones desde el contenedor Docker de la aplicación.

Resolución: Se modificaron dos archivos de configuración clave de PostgreSQL:

postgresql.conf: Se actualizó la directiva listen_addresses para aceptar conexiones desde cualquier IP.

Archivo: /etc/postgresql/17/main/postgresql.conf

Cambio: listen_addresses = '*'

pg_hba.conf: Se agregó una regla para permitir la autenticación md5 desde todas las direcciones IP. Si bien esta configuración es altamente permisiva y no se recomienda para entornos de producción críticos, fue un paso necesario para validar la conectividad durante la depuración.

Archivo: /etc/postgresql/17/main/pg_hba.conf

Línea Agregada: host all all 0.0.0.0/0 md5

Tras los cambios, se reinició el servicio:

Bash

systemctl restart postgresql
2.3. Creación y Verificación de la Base de Datos
Se creó la base de datos de producción y se verificó el acceso localmente en el servidor:

Bash

# Creación de la base de datos y usuario (asumido desde el string de conexión)
sudo -u postgres psql
CREATE DATABASE lab09_production;
CREATE USER lab09 WITH PASSWORD '1234';
GRANT ALL PRIVILEGES ON DATABASE lab09_production TO lab09;

# Verificación de conectividad en el host
psql "postgres://lab09:1234@127.0.0.1:5432/lab09_production"
Esta verificación local en el servidor fue exitosa.

Fase 3: Configuración de la Aplicación Kamal
Con los servicios del servidor listos, la configuración se centró en el archivo config/deploy.yml de Kamal y la gestión de credenciales.

3.1. Aprovisionamiento del Servidor y SSH
Se generó un nuevo par de claves SSH (ssh-keygen) y la clave pública (~/.ssh/id_ed25519.pub) se agregó al Droplet de DigitalOcean para permitir la autenticación sin contraseña.

3.2. Configuración de deploy.yml
Se realizaron varias modificaciones clave en config/deploy.yml:

Se configuró la IP del servidor: servers: web: - 104.248.177.200

Se deshabilitó SSL: proxy: ssl: false

Se configuró el host del proxy a la IP: host: 104.248.177.200

Se actualizaron las credenciales del registry para apuntar a un repositorio de Docker Hub (registry.hub.docker.com).

3.3. Problema de Contexto del Dockerfile
Durante los intentos iniciales de kamal setup, la compilación de la imagen fallaba, reportando que no podía localizar el Dockerfile, a pesar de que existía en la raíz del proyecto.

Resolución: El problema se resolvió especificando explícitamente las rutas de contexto y del Dockerfile en config/deploy.yml, forzando a Kamal a reconocerlas:

YAML

builder:
  context: .
  dockerfile: ./Dockerfile
3.4. Gestión de Credenciales (Secrets)
Las credenciales (RAILS_MASTER_KEY, DATABASE_URL, y las credenciales de Docker Hub) se gestionaron utilizando el sistema de "secrets" de Kamal. La RAILS_MASTER_KEY se obtuvo con bin/rails credentials:show.

Fase 4: Despliegue y Resolución de Problemas Críticos
El comando kamal deploy se ejecutó, pero la aplicación fallaba al arrancar, lo que llevó a una fase intensiva de depuración.

Problema 1: Error de DATABASE_URL (Connection Refused)
Aunque el despliegue inicial parecía funcionar, los logs de la aplicación mostraron que el contenedor web no podía conectarse a la base de datos y entraba en un bucle de reinicio.

Diagnóstico: El análisis de las credenciales reveló que el DATABASE_URL configurado localmente (y enviado al servidor) era: postgres://lab09:1234@127.0.0.1:5432/lab09_production

Análisis del Problema: Este es un error común de redes en contenedores. El host 127.0.0.1 (localhost) dentro del contenedor de la aplicación se refiere al propio contenedor, no al servidor host donde reside el servicio de PostgreSQL.

Resolución: El DATABASE_URL se corrigió en el archivo .env local para que apuntara a la IP pública del servidor, permitiendo que el contenedor resolviera la dirección correctamente:

export DATABASE_URL="postgres://lab09:1234@104.248.177.200:5432/lab09_production"

Tras un kamal env push y kamal deploy, la aplicación pudo conectarse a la base de datos.

Problema 2: Fallo de Formularios POST (InvalidAuthenticityToken)
La aplicación se desplegó y era accesible en http://104.248.177.200. Sin embargo, todos los formularios que utilizaban POST (específicamente "Log In" y "Sign Up" de Devise) fallaban.

Diagnóstico: El análisis de los logs de Rails (kamal app logs -f) reveló el error subyacente: ActionController::InvalidAuthenticityToken (HTTP Origin header (http://104.248.177.200) didn't match request.base_url (https://104.248.177.200))

Análisis del Problema: La configuración de producción por defecto de Rails (config/environments/production.rb) incluye config.assume_ssl = true. Esto le indica a Rails que asuma que está detrás de un proxy SSL, haciendo que genere su base_url como https://....

El navegador, accediendo vía http://..., enviaba un Origin header de http://.... Cuando Rails comparaba el Origin (http) con su base_url (https), el desajuste provocaba que la protección CSRF bloqueara la solicitud.

Resolución: Dado que este despliegue no utilizaba SSL, fue necesario alinear la configuración de Rails con la realidad del entorno. Se modificó config/environments/production.rb para deshabilitar los supuestos de SSL:

Ruby

# config/environments/production.rb

# Se cambió de 'true' a 'false'
config.assume_ssl = false

# Se confirmó que esta línea también estaba en 'false'
config.force_ssl = false
Nota Importante: Todos los cambios en los archivos de configuración debían ser confirmados (commiteados) en el repositorio local antes de ejecutar kamal deploy para asegurar que Kamal compilara una nueva imagen con los cambios aplicados.

Conclusión
Tras modificar la configuración de SSL en el entorno de producción y redesplegar, la discrepancia entre el Origin y el base_url fue resuelta. Los formularios de autenticación comenzaron a funcionar correctamente, y la aplicación quedó totalmente operativa en el servidor.

El proceso completo subraya la importancia crítica de la configuración de red (IPs públicas vs. localhost) y la necesidad de una configuración de SSL coherente en todo el stack (Proxy, Kamal y Rails) para evitar conflictos de seguridad CSRF.

Recurso Adicional
Durante la fase de depuración, el siguiente recurso fue fundamental para identificar y resolver varios de los problemas encontrados:

https://www.youtube.com/watch?v=sPUk9-1WVXI