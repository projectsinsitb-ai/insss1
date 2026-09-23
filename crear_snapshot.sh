#!/bin/bash
#
# crear_snapshot.sh
# Crea una copia de seguridad ("snapshot") de la configuración de red/DHCP
# actual, ANTES de tocar nada, dentro de una carpeta en tu home.
#
# Si luego la lías, ejecuta regenerar.sh para volver atrás.

set -e

# --- Configuración ---
CARPETA_BASE="$HOME/salva_vidas_antes_del_DHCP"
FECHA=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_DIR="$CARPETA_BASE/snapshot_$FECHA"

# Fichero que siempre apunta al último snapshot creado (lo usa regenerar.sh)
ULTIMO_LINK="$CARPETA_BASE/ultimo_snapshot"

# --- Ficheros y carpetas que se van a respaldar ---
# Añade o quita rutas según lo que vayas a tocar en tu práctica.
RUTAS_A_RESPALDAR=(
    "/etc/netplan"
    "/etc/network/interfaces"
    "/etc/dhcp/dhcpd.conf"
    "/etc/default/isc-dhcp-server"
    "/etc/hosts"
    "/etc/hostname"
    "/etc/resolv.conf"
    "/etc/systemd/resolved.conf"
    "/etc/NetworkManager/system-connections"
)

echo "==> Creando carpeta de snapshot en: $SNAPSHOT_DIR"
mkdir -p "$SNAPSHOT_DIR"

echo "==> Copiando ficheros de configuración (puede pedirte contraseña de sudo)..."
for ruta in "${RUTAS_A_RESPALDAR[@]}"; do
    if [ -e "$ruta" ]; then
        # --parents conserva la estructura de carpetas (ej: etc/netplan/...)
        sudo cp -a --parents "$ruta" "$SNAPSHOT_DIR" 2>/dev/null || \
            echo "   (aviso: no se pudo copiar $ruta, se ignora)"
        echo "   [OK] $ruta"
    else
        echo "   [omitido] $ruta no existe en este sistema"
    fi
done

echo "==> Guardando estado actual de red para referencia (no restaurable, solo informativo)..."
{
    echo "--- ip a ---"
    ip a
    echo
    echo "--- ip route ---"
    ip route
    echo
    echo "--- estado isc-dhcp-server (si existe) ---"
    systemctl status isc-dhcp-server --no-pager 2>/dev/null || echo "servicio no encontrado"
} > "$SNAPSHOT_DIR/estado_red.txt"

# Actualiza el enlace al "último snapshot"
ln -sfn "$SNAPSHOT_DIR" "$ULTIMO_LINK"

echo
echo "✅ Snapshot creado correctamente en:"
echo "   $SNAPSHOT_DIR"
echo
echo "Si la lías con el DHCP, ejecuta:  ./regenerar.sh"
