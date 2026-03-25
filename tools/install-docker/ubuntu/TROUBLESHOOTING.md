# Troubleshooting - Docker en Ubuntu

> 🔧 Soluciones a problemas comunes al instalar y usar Docker en Ubuntu

## 📑 Índice de Problemas

- [Problemas de Instalación](#problemas-de-instalación)
- [Problemas de Permisos](#problemas-de-permisos)
- [Problemas de Red](#problemas-de-red)
- [Problemas con el Servicio Docker](#problemas-con-el-servicio-docker)
- [Problemas con Contenedores](#problemas-con-contenedores)
- [Problemas de Espacio en Disco](#problemas-de-espacio-en-disco)

---

## Problemas de Instalación

### ❌ Error: "This script must be run with sudo"

**Síntoma**:
```
[ERROR] This script must be run with sudo or as root
[ERROR] Usage: sudo ./install.sh
```

**Causa**: El script no se ejecutó con privilegios de superusuario.

**Solución**:
```bash
# ✅ Correcto
sudo ./install.sh

# ❌ Incorrecto
./install.sh
```

---

### ❌ Error: "This script must be run with 'sudo', not as root directly"

**Síntoma**:
```
[ERROR] This script must be run with 'sudo', not as root directly
[ERROR] Reason: Cannot detect user to add to docker group
```

**Causa**: Te logueaste directamente como root (`su -` o login root) en lugar de usar `sudo`.

**Solución**:
```bash
# ❌ Incorrecto (como root directo)
su -
./install.sh

# ✅ Correcto (como usuario normal con sudo)
exit  # Salir de la sesión root
sudo ./install.sh
```

**Explicación**: El script necesita saber qué usuario agregar al grupo `docker`. Cuando usas `sudo`, la variable `$SUDO_USER` contiene tu nombre de usuario. Si estás como root directo, esa variable está vacía.

---

### ❌ Error: "Failed to download Docker GPG key"

**Síntoma**:
```
[ERROR] Failed to download Docker GPG key
```

**Causas posibles**:
1. Sin conexión a Internet
2. Firewall bloqueando la descarga
3. Problemas con el DNS

**Soluciones**:

```bash
# 1. Verificar conectividad a Internet
ping -c 3 google.com

# 2. Verificar acceso al servidor de Docker
curl -I https://download.docker.com

# 3. Probar descargar la llave manualmente
curl -fsSL https://download.docker.com/linux/ubuntu/gpg

# 4. Verificar configuración de DNS
cat /etc/resolv.conf

# 5. Si usas proxy, configurar variables de entorno
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
sudo -E ./install.sh
```

---

### ❌ Error: Conflicto con Versiones Antiguas

**Síntoma**:
```
[WARN] Conflicting Docker packages detected:
  - docker.io (20.10.12)
  - docker-compose (1.29.2)
```

**Causa**: Tienes versiones de Docker de los repositorios de Ubuntu instaladas.

**Solución**: El script te preguntará si deseas desinstalarlas. Si respondiste "no" por error:

```bash
# Desinstalar manualmente las versiones conflictivas
sudo apt remove docker.io docker-compose docker-compose-v2 docker-doc podman-docker

# Ejecutar el script nuevamente
sudo ./install.sh
```

---

### ❌ Error: "Ubuntu version is not officially tested"

**Síntoma**:
```
[WARN] Ubuntu 23.04 is not officially tested
[WARN] Supported versions: 22.04 24.04 25.10
Continue anyway? [y/N]:
```

**Causa**: Estás usando una versión de Ubuntu que no está en la lista oficial de Docker.

**Solución**:
- **Opción 1** (recomendada): Actualizar a una versión LTS soportada (22.04 o 24.04)
- **Opción 2**: Continuar bajo tu propio riesgo escribiendo `y`

```bash
# Ver tu versión de Ubuntu
lsb_release -a
```

---

## Problemas de Permisos

### ❌ Error: "permission denied while trying to connect to the Docker daemon socket"

**Síntoma**:
```bash
$ docker run hello-world
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

**Causa**: Tu usuario no está en el grupo `docker` o no has reiniciado la sesión después de agregarlo.

**Soluciones**:

```bash
# 1. Verificar si estás en el grupo docker
groups
# Si no ves "docker" en la lista:

# 2. Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER

# 3. Aplicar los cambios (elige UNA opción):

# Opción A: Cerrar sesión y volver a entrar (recomendado)
logout
# Vuelve a iniciar sesión

# Opción B: Activar el grupo sin cerrar sesión
newgrp docker

# Opción C: Reiniciar el sistema
sudo reboot

# 4. Verificar que ahora estás en el grupo
groups
# Deberías ver "docker" en la lista

# 5. Probar Docker
docker run hello-world
```

---

### ❌ Error: "~/.docker/config.json: permission denied"

**Síntoma**:
```
WARNING: Error loading config file: /home/user/.docker/config.json -
stat /home/user/.docker/config.json: permission denied
```

**Causa**: Ejecutaste comandos Docker con `sudo` antes de agregar tu usuario al grupo `docker`, y ahora el directorio `~/.docker/` pertenece a root.

**Solución**:

```bash
# Opción 1: Cambiar el propietario del directorio (recomendado)
sudo chown "$USER":"$USER" "$HOME/.docker" -R
sudo chmod g+rwx "$HOME/.docker" -R

# Opción 2: Eliminar el directorio (se recreará automáticamente)
sudo rm -rf ~/.docker

# Probar Docker
docker run hello-world
```

---

## Problemas de Red

### ❌ Contenedores Sin Acceso a Internet

**Síntoma**:
```bash
$ docker run alpine ping -c 3 google.com
# No response o "Network unreachable"
```

**Soluciones**:

```bash
# 1. Verificar que el servicio Docker está corriendo
sudo systemctl status docker

# 2. Verificar configuración de red de Docker
docker network ls

# 3. Reiniciar el servicio Docker
sudo systemctl restart docker

# 4. Verificar iptables (puede estar bloqueando)
sudo iptables -L -n

# 5. Si usas UFW, verificar reglas
sudo ufw status

# 6. Configurar DNS manualmente en Docker
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF

sudo systemctl restart docker
```

---

### ❌ Error: "Conflict. The container name is already in use"

**Síntoma**:
```bash
$ docker run --name myapp nginx
Error response from daemon: Conflict. The container name "/myapp" is already in use
```

**Soluciones**:

```bash
# Ver todos los contenedores (incluyendo detenidos)
docker ps -a

# Opción 1: Eliminar el contenedor existente
docker rm myapp

# Opción 2: Eliminar y recrear en un comando
docker rm myapp && docker run --name myapp nginx

# Opción 3: Usar un nombre diferente
docker run --name myapp2 nginx

# Opción 4: No especificar nombre (Docker genera uno aleatorio)
docker run nginx
```

---

## Problemas con el Servicio Docker

### ❌ Error: "Failed to start docker.service"

**Síntoma**:
```bash
$ sudo systemctl start docker
Job for docker.service failed because the control process exited with error code.
```

**Diagnóstico y Soluciones**:

```bash
# 1. Ver logs detallados del servicio
sudo journalctl -xeu docker.service

# 2. Verificar estado completo
sudo systemctl status docker.service

# 3. Verificar que containerd está corriendo
sudo systemctl status containerd

# Si containerd no está corriendo:
sudo systemctl start containerd
sudo systemctl start docker

# 4. Verificar archivo de configuración
sudo dockerd --validate

# 5. Reiniciar el daemon de systemd
sudo systemctl daemon-reload
sudo systemctl restart docker

# 6. Si nada funciona, reinstalar Docker
sudo apt purge docker-ce docker-ce-cli containerd.io
sudo apt autoremove
sudo ./install.sh
```

---

### ❌ Docker se Detiene Automáticamente

**Síntoma**: El servicio Docker se detiene solo después de un tiempo.

**Soluciones**:

```bash
# 1. Verificar logs del sistema
sudo journalctl -fu docker

# 2. Verificar límites de recursos
ulimit -a

# 3. Asegurar que está habilitado para iniciar en boot
sudo systemctl enable docker
sudo systemctl enable containerd

# 4. Verificar espacio en disco (puede causar que Docker se detenga)
df -h
```

---

## Problemas con Contenedores

### ❌ Contenedor Se Detiene Inmediatamente

**Síntoma**:
```bash
$ docker run nginx
$ docker ps
# El contenedor no aparece
```

**Soluciones**:

```bash
# 1. Ver contenedores detenidos
docker ps -a

# 2. Ver logs del contenedor
docker logs <container-id>

# 3. Ejecutar en modo interactivo para ver errores
docker run -it nginx /bin/bash

# 4. Verificar que la imagen se descargó correctamente
docker images
```

---

### ❌ No Puedo Acceder a los Puertos Expuestos

**Síntoma**:
```bash
$ docker run -p 8080:80 nginx
# Navegador en localhost:8080 no funciona
```

**Soluciones**:

```bash
# 1. Verificar que el contenedor está corriendo
docker ps

# 2. Verificar que el puerto está mapeado correctamente
docker port <container-id>

# 3. Verificar que el puerto no está en uso por otro proceso
sudo lsof -i :8080
# o
sudo netstat -tuln | grep 8080

# 4. Verificar firewall
sudo ufw status
sudo ufw allow 8080/tcp

# 5. Si estás en una VM o servidor remoto, verificar reglas de firewall externo
# (ej: Security Groups en AWS, firewall del router, etc.)

# 6. Probar con curl localmente
curl localhost:8080
```

---

## Problemas de Espacio en Disco

### ❌ Error: "no space left on device"

**Síntoma**:
```
Error response from daemon: no space left on device
```

**Soluciones**:

```bash
# 1. Verificar espacio en disco
df -h

# 2. Ver cuánto espacio usa Docker
docker system df

# Salida ejemplo:
# TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
# Images          10        5         2.5GB     1.2GB (48%)
# Containers      20        3         500MB     400MB (80%)
# Local Volumes   5         2         1.5GB     800MB (53%)
# Build Cache     0         0         0B        0B

# 3. Limpiar contenedores detenidos
docker container prune

# 4. Limpiar imágenes no usadas
docker image prune -a

# 5. Limpiar volúmenes no usados
docker volume prune

# 6. Limpiar TODO (CUIDADO: esto elimina todo lo que no esté en uso)
docker system prune -a --volumes

# 7. Ver qué contenedores ocupan más espacio
docker ps -as

# 8. Ver logs grandes (pueden llenar el disco)
sudo du -sh /var/lib/docker/containers/*/

# 9. Configurar límite de tamaño de logs
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

---

### ❌ Logs de Contenedor Muy Grandes

**Síntoma**: Los logs de un contenedor están ocupando mucho espacio.

**Soluciones**:

```bash
# 1. Ver tamaño de logs de un contenedor
docker inspect --format='{{.LogPath}}' <container-id> | xargs sudo du -sh

# 2. Truncar logs de un contenedor (CUIDADO: esto borra los logs)
docker inspect --format='{{.LogPath}}' <container-id> | xargs sudo truncate -s 0

# 3. Configurar rotación de logs globalmente (recomendado)
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker

# 4. Configurar rotación de logs para un contenedor específico
docker run \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  nginx
```

---

## Comandos Útiles para Diagnóstico

```bash
# Información del sistema Docker
docker info

# Versión de Docker
docker version

# Ver logs del daemon de Docker
sudo journalctl -fu docker

# Ver logs de un contenedor
docker logs <container-id>

# Ver procesos dentro de un contenedor
docker top <container-id>

# Inspeccionar un contenedor (configuración completa)
docker inspect <container-id>

# Ver estadísticas de recursos en tiempo real
docker stats

# Ver eventos de Docker en tiempo real
docker events

# Verificar salud de un contenedor
docker inspect --format='{{.State.Health.Status}}' <container-id>

# Ver redes de Docker
docker network ls
docker network inspect bridge

# Ver volúmenes
docker volume ls

# Espacio usado por Docker
docker system df

# Ejecutar shell dentro de un contenedor corriendo
docker exec -it <container-id> /bin/bash
# o si no tiene bash:
docker exec -it <container-id> /bin/sh
```

---

## Limpiar Instalación Fallida

Si la instalación falló a mitad del proceso y quieres empezar de cero:

```bash
# 1. Detener servicios
sudo systemctl stop docker containerd || true

# 2. Desinstalar paquetes
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true

# 3. Eliminar todos los datos
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker

# 4. Eliminar repositorio
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc

# 5. Limpiar paquetes huérfanos
sudo apt autoremove -y
sudo apt autoclean

# 6. Actualizar índice de paquetes
sudo apt update

# 7. Ejecutar el script nuevamente
sudo ./install.sh
```

---

## Obtener Ayuda Adicional

Si ninguna de estas soluciones funciona:

1. **Revisa los logs**:
   ```bash
   cat /var/log/docker-install.log
   sudo journalctl -xeu docker.service
   ```

2. **Busca en la documentación oficial**:
   - https://docs.docker.com/engine/install/troubleshoot/
   
3. **Comunidad Docker**:
   - [Docker Forums](https://forums.docker.com/)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/docker)
   
4. **Reporta un issue** en el repositorio con:
   - Versión de Ubuntu: `lsb_release -a`
   - Logs del script: `/var/log/docker-install.log`
   - Logs de Docker: `sudo journalctl -xeu docker.service`
   - Salida de: `docker info`

---

**¿Encontraste un problema que no está aquí?** ¡Contribuye! Abre un Pull Request agregando la solución a este documento.
