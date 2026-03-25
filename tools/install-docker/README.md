# Docker Installation Tool

> 🐳 Herramienta comunitaria para instalar Docker Engine en múltiples distribuciones Linux

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04%20%7C%2025.10-E95420?logo=ubuntu&logoColor=white)](ubuntu/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)

## 📋 Descripción

Scripts de instalación automatizada de Docker Engine siguiendo la documentación oficial para cada distribución. Diseñados para ser **idempotentes**, **seguros** y **fáciles de usar**.

## 🚀 Distribuciones Soportadas

| Distribución | Estado | Versiones | Guía |
|--------------|--------|-----------|------|
| **Ubuntu** | ✅ Soportado | 22.04, 24.04, 25.10 | [Ver guía](ubuntu/) |
| **Debian** | 🚧 Próximamente | - | - |
| **Fedora** | 🚧 Próximamente | - | - |
| **CentOS/RHEL** | 🚧 Próximamente | - | - |

## ⚡ Instalación Rápida

### Ubuntu

```bash
# Opción 1: Descargar y ejecutar
curl -fsSL https://raw.githubusercontent.com/ennerlopez/my-tools-dev/main/tools/install-docker/ubuntu/install.sh -o install-docker.sh
chmod +x install-docker.sh
sudo ./install-docker.sh
```

**Opción 2: Ejecución directa** ⚠️ *Revisar el script en GitHub antes de ejecutar*

```bash
curl -fsSL https://raw.githubusercontent.com/ennerlopez/my-tools-dev/main/tools/install-docker/ubuntu/install.sh | sudo bash
```

📖 **[Ver instrucciones detalladas para Ubuntu →](ubuntu/README.md)**

## 🎯 Características

- ✅ **Idempotente**: Puede ejecutarse múltiples veces sin causar problemas
- 🔒 **Seguro**: Sigue las mejores prácticas de seguridad de Docker
- 📦 **Completo**: Instala Docker Engine + Docker Compose Plugin
- 🎨 **Interactivo**: Mensajes claros con colores y confirmaciones
- 🔧 **Configurable**: Soporta argumentos para personalizar la instalación
- 📝 **Logs**: Guarda registros detallados para debugging
- ⚙️ **Post-instalación**: Configura usuario y systemd automáticamente

## 📚 ¿Qué se Instala?

Cada script instala los componentes oficiales de Docker:

- **Docker Engine** - Motor de contenedores
- **Docker CLI** - Interfaz de línea de comandos
- **containerd** - Runtime de contenedores
- **Docker Buildx Plugin** - Constructor avanzado de imágenes
- **Docker Compose Plugin** - Orquestación multi-contenedor

## 🛠️ Uso Avanzado

Todos los scripts soportan argumentos comunes:

```bash
# Instalar versión específica
sudo ./install.sh --version 29.2.1

# Listar versiones disponibles
./install.sh --list-versions

# Modo no interactivo (para CI/CD)
sudo ./install.sh --non-interactive

# Omitir post-instalación (no agregar usuario al grupo docker)
sudo ./install.sh --skip-postinstall

# Ver ayuda completa
./install.sh --help
```

## ✅ Verificación Post-Instalación

Después de instalar, verifica que todo funcione:

```bash
# Verificar versiones instaladas
docker --version
docker compose version

# Probar sin sudo (requiere re-login o newgrp docker)
docker run hello-world

# Ver estado del servicio
sudo systemctl status docker

# Ver logs de instalación
cat /var/log/docker-install.log
```

## 🐛 Problemas Comunes

Cada distribución tiene su guía de troubleshooting:

- [Troubleshooting Ubuntu](ubuntu/TROUBLESHOOTING.md)

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Para agregar soporte a una nueva distribución:

1. Crea una carpeta con el nombre de la distribución (ej: `debian/`)
2. Agrega los archivos:
   - `install.sh` - Script de instalación
   - `README.md` - Guía de uso específica
   - `TROUBLESHOOTING.md` - Soluciones a problemas comunes
3. Sigue la estructura y estándares de los scripts existentes
4. Envía un Pull Request

### Estructura de Carpetas

```
tools/install-docker/
├── README.md                 # Este archivo
├── ubuntu/
│   ├── install.sh
│   ├── README.md
│   └── TROUBLESHOOTING.md
└── [nueva-distro]/
    ├── install.sh
    ├── README.md
    └── TROUBLESHOOTING.md
```

## 📄 Licencia

MIT License - Ver archivo LICENSE para más detalles.

## 🔗 Referencias

- [Docker Engine Installation (Official)](https://docs.docker.com/engine/install/)
- [Docker Post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/)

---

**Nota**: Estos scripts NO utilizan el "convenience script" de Docker (`get.docker.com`). En su lugar, siguen el método oficial del repositorio APT/YUM para mayor control y reproducibilidad.
