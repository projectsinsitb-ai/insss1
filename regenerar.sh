#!/bin/bash
#
# regenerar.sh
# Restaura la configuración de red/DHCP desde el snapshot creado con
# crear_snapshot.sh. Úsalo si la has liado tocando el DHCP.
#
# Uso:
#   ./regenerar.sh                -> restaura desde el ÚLTIMO snapshot creado
#   ./regenerar.sh /ruta/al/snap  -> restaura desde un snapshot concreto

set -e

CARPETA_BASE="$HOME/salva_vidas_antes_del_DHCP"
ULTIMO_LINK="$CARPETA_BASE/ultimo_snapshot"

# --- Determinar qué snapshot restaurar ---
if [ -n "$1" ]; then
    SNAPSHOT_DIR="$1"
else
    if [ -L "$ULTIMO_LINK" ]; then
        SNAPSHOT_DIR=$(readlink -f "$ULTIMO_LINK")
    else
        echo "❌ No se encontró ningún snapshot previo en $CARPETA_BASE"
        echo "   Ejecuta primero crear_snapshot.sh"
        exit 1
    fi
fi

if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "❌ La carpeta de snapshot no existe: $SNAPSHOT_DIR"
    exit 1
fi

echo "==> Vas a restaurar la configuración desde:"
echo "    $SNAPSHOT_DIR"
echo
echo "⚠️  Esto SOBREESCRIBIRÁ tu configuración actual de red/DHCP."
read -p "¿Seguro que quieres continuar? Escribe SI para confirmar: " CONFIRMACION

if [ "$CONFIRMACION" != "SI" ]; then
    echo "Cancelado. No se ha tocado nada."
    exit 0
fi

echo "==> Restaurando ficheros (puede pedirte contraseña de sudo)..."
# Copiamos todo lo que hay dentro de $SNAPSHOT_DIR/etc de vuelta a /etc
if [ -d "$SNAPSHOT_DIR/etc" ]; then
    sudo cp -a "$SNAPSHOT_DIR/etc/." /etc/
    echo "   [OK] Ficheros restaurados en /etc"
else
    echo "   (aviso: no se encontró carpeta 'etc' dentro del snapshot)"
fi

echo "==> Reiniciando servicios de red..."
sudo netplan apply 2>/dev/null || echo "   (aviso: netplan apply falló o no aplica)"
sudo systemctl restart isc-dhcp-server 2>/dev/null || echo "   (aviso: isc-dhcp-server no reiniciado, revisa si está instalado)"
sudo systemctl restart systemd-networkd 2>/dev/null || true
sudo systemctl restart NetworkManager 2>/dev/null || true

echo
echo "✅ Restauración completada desde: $SNAPSHOT_DIR"
echo "   Revisa con 'ip a' y 'ip route' que todo esté como esperabas."
