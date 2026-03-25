# Instalación de Docker en Ubuntu

> 🐳 Script automatizado para instalar Docker Engine en Ubuntu siguiendo la documentación oficial

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04%20%7C%2025.10-E95420?logo=ubuntu&logoColor=white)]()
[![Docker](https://img.shields.io/badge/Docker-Engine%20%2B%20Compose-2496ED?logo=docker&logoColor=white)]()

## 📋 Requisitos Previos

- **Sistema Operativo**: Ubuntu 22.04 LTS, 24.04 LTS o 25.10
- **Arquitectura**: amd64, arm64, armhf, s390x o ppc64el
- **Permisos**: Acceso `sudo`
- **Conexión**: Internet activa

## 🚀 Instalación Rápida

### Opción 1: Descargar y Ejecutar (Recomendado)

```bash
# Descargar el script
curl -fsSL https://raw.githubusercontent.com/ennerlopez/my-tools-dev/main/tools/install-docker/ubuntu/install.sh -o install-docker.sh

# Revisar el script (IMPORTANTE: siempre revisa scripts antes de ejecutarlos)
cat install-docker.sh

# Dar permisos de ejecución
chmod +x install-docker.sh

# Ejecutar con sudo
sudo ./install-docker.sh
```

### Opción 2: Ejecución Directa

⚠️ **ADVERTENCIA**: Revisa el script en GitHub antes de ejecutar

```bash
curl -fsSL https://raw.githubusercontent.com/ennerlopez/my-tools-dev/main/tools/install-docker/ubuntu/install.sh | sudo bash
```

### Opción 3: Clonar el Repositorio

```bash
# Clonar el repositorio completo
git clone https://github.com/ennerlopez/my-tools-dev.git
cd my-tools-dev/tools/install-docker/ubuntu

# Ejecutar el script
sudo ./install.sh
```

## 🎯 ¿Qué Instala Este Script?

El script instala los siguientes componentes oficiales de Docker:

| Componente | Descripción |
|------------|-------------|
| **Docker Engine** (`docker-ce`) | Motor principal de contenedores |
| **Docker CLI** (`docker-ce-cli`) | Interfaz de línea de comandos |
| **containerd** (`containerd.io`) | Runtime de contenedores (estándar de la industria) |
| **Docker Buildx Plugin** | Constructor moderno de imágenes con soporte multi-plataforma |
| **Docker Compose Plugin** | Herramienta para definir y ejecutar aplicaciones multi-contenedor |

## 📖 Uso Básico

### Instalación Estándar

```bash
# Instala la última versión estable
sudo ./install.sh
```

### Instalación con Opciones

```bash
# Ver ayuda
./install.sh --help

# Instalar versión específica
sudo ./install.sh --version 29.2.1

# Listar versiones disponibles
./install.sh --list-versions

# Instalación no interactiva (para CI/CD)
sudo ./install.sh --non-interactive

# Omitir post-instalación (no agregar usuario al grupo docker)
sudo ./install.sh --skip-postinstall
```

## 🔧 Opciones Disponibles

| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `--version <ver>` | Instala una versión específica de Docker | `--version 29.2.1` |
| `--list-versions` | Lista las versiones disponibles y sale | - |
| `--non-interactive` | No solicita confirmaciones (auto-acepta todo) | Para scripts de automatización |
| `--skip-postinstall` | No agrega el usuario al grupo docker | Para instalaciones mínimas |
| `--help` / `-h` | Muestra la ayuda completa | - |

## 📝 Proceso de Instalación

El script ejecuta los siguientes pasos en orden:

### 1. **Validaciones Iniciales**
   - ✅ Verifica que se ejecuta con `sudo` (no como root directo)
   - ✅ Confirma que el sistema es Ubuntu (versión soportada)
   - ✅ Valida la arquitectura del sistema

### 2. **Detección de Conflictos**
   - 🔍 Busca versiones conflictivas instaladas:
     - `docker.io` (versión de Ubuntu)
     - `docker-compose` (versión standalone antigua)
     - `docker-compose-v2`
     - `podman-docker`
     - Versiones anteriores de `containerd` o `runc`
   - ⚠️ Si encuentra conflictos, pregunta si desinstalar
   - 🗑️ Desinstala paquetes conflictivos si el usuario acepta

### 3. **Configuración del Repositorio Oficial**
   - 📦 Instala prerequisitos: `ca-certificates`, `curl`
   - 🔐 Descarga la llave GPG oficial de Docker
   - 📄 Configura el repositorio APT en `/etc/apt/sources.list.d/docker.sources`
   - 🔄 Actualiza el índice de paquetes

### 4. **Instalación de Docker**
   - 📥 Descarga e instala todos los componentes
   - ✅ Verifica la instalación exitosa

### 5. **Post-Instalación** (si no se usa `--skip-postinstall`)
   - 👥 Crea el grupo `docker` (si no existe)
   - ➕ Agrega tu usuario al grupo `docker`
   - 🚀 Habilita el servicio Docker para iniciar en el arranque
   - ▶️ Inicia el servicio Docker

### 6. **Verificación**
   - ✔️ Comprueba las versiones instaladas
   - ✔️ Verifica que el servicio esté corriendo
   - ✔️ Prueba ejecutar un contenedor de prueba

## ✅ Verificación Post-Instalación

Después de ejecutar el script, verifica la instalación:

### 1. Verificar Versiones Instaladas

```bash
# Versión de Docker Engine
docker --version
# Salida esperada: Docker version 29.x.x, build xxxxxx

# Versión de Docker Compose
docker compose version
# Salida esperada: Docker Compose version v2.x.x
```

### 2. Verificar Estado del Servicio

```bash
# Ver estado del servicio Docker
sudo systemctl status docker

# Debe mostrar: Active: active (running)
```

### 3. Probar Docker Sin Sudo

**IMPORTANTE**: Después de la instalación, debes **cerrar sesión y volver a entrar** para que los cambios de grupo surtan efecto.

```bash
# Opción A: Cerrar sesión y volver a entrar
logout
# Luego vuelve a iniciar sesión

# Opción B: Activar el nuevo grupo sin cerrar sesión
newgrp docker

# Ahora prueba Docker sin sudo
docker run hello-world
```

Si el comando anterior funciona, ¡la instalación fue exitosa! 🎉

### 4. Probar Docker Compose

```bash
# Crear un archivo de prueba
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  hello:
    image: hello-world
EOF

# Ejecutar con Docker Compose
docker compose up

# Limpiar
rm docker-compose.yml
```

## 🛠️ Ejemplos de Uso

### Instalar Última Versión (Producción)

```bash
sudo ./install.sh
```

### Instalar Versión Específica para Entorno de Desarrollo

```bash
# 1. Ver versiones disponibles
./install.sh --list-versions

# 2. Instalar la versión deseada
sudo ./install.sh --version 29.2.1
```

### Instalación Automatizada (CI/CD)

```bash
# Para scripts de automatización, usa --non-interactive
sudo ./install.sh --non-interactive

# Ejemplo en un pipeline de GitLab CI
script:
  - curl -fsSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/tools/install-docker/ubuntu/install.sh -o install.sh
  - chmod +x install.sh
  - sudo ./install.sh --non-interactive
```

### Instalación Mínima (Sin Post-Instalación)

```bash
# Solo instala Docker, sin configurar el grupo
sudo ./install.sh --skip-postinstall

# Luego puedes configurar manualmente
sudo usermod -aG docker $USER
```

## 📊 Códigos de Salida

El script utiliza códigos de salida estándar para integración con otros scripts:

| Código | Significado |
|--------|-------------|
| `0` | ✅ Instalación exitosa |
| `1` | ❌ Error general |
| `2` | ❌ No es Ubuntu o versión no soportada |
| `3` | ❌ No se ejecutó con sudo correctamente |
| `4` | ❌ Usuario declinó continuar |
| `5` | ❌ Docker ya está instalado (sin --force) |

Ejemplo de uso en scripts:

```bash
#!/bin/bash
sudo ./install.sh --non-interactive

if [[ $? -eq 0 ]]; then
    echo "Docker instalado correctamente"
    # Continuar con tu lógica...
else
    echo "Error al instalar Docker"
    exit 1
fi
```

## 📁 Archivos Creados/Modificados

El script crea o modifica los siguientes archivos:

| Archivo/Directorio | Descripción |
|-------------------|-------------|
| `/etc/apt/keyrings/docker.asc` | Llave GPG de Docker |
| `/etc/apt/sources.list.d/docker.sources` | Repositorio APT de Docker |
| `/var/log/docker-install.log` | Log detallado de la instalación |
| `/etc/group` | Agrega tu usuario al grupo `docker` |

## 🔒 Consideraciones de Seguridad

### Permisos del Grupo Docker

⚠️ **IMPORTANTE**: Agregar un usuario al grupo `docker` otorga privilegios equivalentes a root.

**¿Por qué?** Porque permite ejecutar contenedores que pueden montar cualquier directorio del host y ejecutar comandos con privilegios elevados.

**Recomendaciones**:
- Solo agrega usuarios confiables al grupo `docker`
- En producción, considera usar Docker en modo rootless
- Para entornos multi-usuario, evalúa usar orquestadores como Kubernetes

### Verificación de Scripts

Antes de ejecutar este (o cualquier) script con `sudo`, **siempre revísalo**:

```bash
# Opción 1: Leer el script en el terminal
curl -fsSL https://raw.githubusercontent.com/.../install.sh | less

# Opción 2: Descargarlo y revisarlo con tu editor
curl -fsSL https://raw.githubusercontent.com/.../install.sh -o install.sh
cat install.sh  # o nano install.sh, vim install.sh, etc.
```

## 🔄 Actualizar Docker

Para actualizar Docker a una versión más reciente:

```bash
# Opción 1: Ejecutar el script nuevamente
sudo ./install.sh

# Opción 2: Actualizar manualmente con apt
sudo apt update
sudo apt install --only-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 🗑️ Desinstalar Docker

Si necesitas desinstalar Docker completamente:

```bash
# 1. Detener el servicio
sudo systemctl stop docker

# 2. Desinstalar paquetes
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# 3. Eliminar datos (ADVERTENCIA: esto borra todas las imágenes, contenedores y volúmenes)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 4. Eliminar configuración del repositorio
sudo rm /etc/apt/sources.list.d/docker.sources
sudo rm /etc/apt/keyrings/docker.asc

# 5. Remover tu usuario del grupo docker
sudo deluser $USER docker
```

## 📚 Recursos Adicionales

- 📖 [Documentación Oficial de Docker](https://docs.docker.com/)
- 🐛 [Troubleshooting](TROUBLESHOOTING.md) - Solución a problemas comunes
- 🔧 [Docker Post-Installation Steps](https://docs.docker.com/engine/install/linux-postinstall/)
- 🛡️ [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- 📦 [Docker Hub](https://hub.docker.com/) - Registro público de imágenes

## 🐛 Problemas Comunes

Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para soluciones detalladas a problemas frecuentes:

- ❌ "permission denied while trying to connect to the Docker daemon socket"
- ❌ Error al descargar la llave GPG
- ❌ Conflictos con versiones anteriores
- ❌ El servicio Docker no inicia
- Y más...

## 📞 Soporte

Si encuentras problemas:

1. ✅ Revisa [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. 📋 Consulta el log: `cat /var/log/docker-install.log`
3. 🔍 Busca en [Docker Forums](https://forums.docker.com/)
4. 🐛 Reporta un issue en el repositorio

---

**Nota**: Este script NO utiliza el "convenience script" de Docker (`get.docker.com`). En su lugar, sigue el método oficial de instalación mediante el repositorio APT para mayor control y reproducibilidad.
