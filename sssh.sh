#!/bin/bash

#############################################################
# Script: RA1-P1-script.sh
# Autor: Razzouki Barghal, Hamza - 2SMX
# Objetivo: Automatitzar les eines de seguretat
#############################################################

# Variables
ruta="$HOME/logs"
data=$(date +%d-%m-%y)
informe="$ruta/Informe-$data.log"

# Crear carpeta de logs
mkdir -p "$ruta"

# Limpiar logs anteriores
rm -f "$ruta"/*

echo "========================================" >> "$informe"
echo "        INFORME DE SEGURETAT RA1-P1" >> "$informe"
echo "========================================" >> "$informe"
echo "Data: $(date)" >> "$informe"
echo "Equip: $(hostname)" >> "$informe"
echo "Usuari: $USER" >> "$informe"
echo "========================================" >> "$informe"


# 1. CLAMAV
echo "" >> "$informe"
echo "========== CLAMAV ==========" >> "$informe"

sudo clamscan -r \
--exclude-dir="^/home" \
/ >> "$informe" 2>&1


# 2. MALDETECT
echo "" >> "$informe"
echo "========== MALDETECT ==========" >> "$informe"

sudo maldet --scan-all /home >> "$informe" 2>&1


# 3. RKHUNTER
echo "" >> "$informe"
echo "========== RKHUNTER ==========" >> "$informe"

sudo rkhunter -c --sk >> "$informe" 2>&1


# 4. CHKROOTKIT
echo "" >> "$informe"
echo "========== CHKROOTKIT ==========" >> "$informe"

sudo chkrootkit -x >> "$informe" 2>&1


# 5. UNHIDE
echo "" >> "$informe"
echo "========== UNHIDE ==========" >> "$informe"

sudo unhide proc >> "$informe" 2>&1
sudo unhide sys >> "$informe" 2>&1
sudo unhide brute >> "$informe" 2>&1


# 6. UNHIDE-TCP
echo "" >> "$informe"
echo "========== UNHIDE-TCP ==========" >> "$informe"

sudo unhide-tcp -flov >> "$informe" 2>&1

estat=$?

case $estat in
    0)
        echo "No hidden port is found" >> "$informe"
        ;;
    4)
        echo "One or more hidden TCP port(s) is(are) found" >> "$informe"
        ;;
    8)
        echo "One or more hidden UDP port(s) is(are) found" >> "$informe"
        ;;
    12)
        echo "One or more hidden TCP and UDP ports are found" >> "$informe"
        ;;
esac


# FINAL
echo "" >> "$informe"
echo "========================================" >> "$informe"
echo "Escaneig finalitzat." >> "$informe"
echo "Informe: $informe"
echo "========================================"

cat "$informe"
