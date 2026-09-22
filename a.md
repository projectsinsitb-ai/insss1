0. Preparació de l'entorn
Es recomana Ubuntu Server o Ubuntu Desktop (Kali dona problemes de repositoris).
sudo apt update && sudo apt upgrade -y
1. Fitxers EICAR
Descarregar dues còpies: una a la carpeta HOME i una altra a /mnt.
cd ~
wget https://secure.eicar.org/eicar.com
wget https://secure.eicar.org/eicar.com.txt
wget https://secure.eicar.org/eicar_com.zip
wget https://secure.eicar.org/eicarcom2.zip
 
sudo mkdir -p /mnt/eicar
sudo cp ~/eicar* /mnt/eicar/
2. Instal·lació de ClamAV
sudo apt install clamav clamav-daemon -y
sudo apt install clamtk -y   # interfície gràfica (opcional)
3. Comprovar que el servei clamav-freshclam està actiu
sudo systemctl status clamav-freshclam
sudo systemctl enable --now clamav-freshclam
sudo freshclam   # forçar actualització de signatures
4. Escaneig complet amb clamscan (excloent /home)
Cal guardar el resultat a un fitxer .log dins d'un directori d'informes.
mkdir -p ~/logs
sudo clamscan -r --exclude-dir="^/home" / --log=~/logs/clamav-$(date +%d-%m-%y).log
5. Instal·lació de Maldetect (LMD)
cd /usr/local
sudo wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
sudo tar -xvf maldetect-current.tar.gz
cd maldetect-*/
sudo ./install.sh
6. Escaneig de /home amb Maldetect
sudo maldet --update
sudo maldet --scan-all /home
# per veure l'informe detallat (substituir SCANID pel que indiqui la sortida):
sudo maldet --report SCANID
7. Integració de Maldetect amb ClamAV
Editar el fitxer de configuració:
sudo nano /usr/local/maldetect/conf.maldet
# Modificar/comprovar aquests paràmetres dins l'editor:
clam_av="1"
scan_clamscan="1"
8. Notificacions per correu (Maldetect + ssmtp)
sudo apt install ssmtp -y
sudo nano /etc/ssmtp/ssmtp.conf
# mailhub=smtp.gmail.com:587
# AuthUser=el_teu_correu@gmail.com
# AuthPass=la_teva_contrasenya_d_aplicacio
# UseSTARTTLS=YES
 
sudo nano /usr/local/maldetect/conf.maldet
email_alert="1"
email_addr="el_teu_correu@gmail.com"
 
# Prova d'enviament:
echo -e "To: perico.palotes@gmail.com\nSubject: Test ssmtp\n\nAixo es un email de test" | ssmtp -v perico.palotes@gmail.com
9. Instal·lació de les eines anti-rootkits
sudo apt install chkrootkit rkhunter unhide -y
10. Execució de les eines anti-rootkits (informes centralitzats)
ruta="$HOME/logs"
mkdir -p "$ruta"
 
sudo rkhunter -c --sk --logfile "$ruta/Informe-$(date +%d-%m-%y).log"
sudo chkrootkit -x >> "$ruta/Informe-$(date +%d-%m-%y).log"
sudo unhide proc  >> "$ruta/Informe-$(date +%d-%m-%y).log"
sudo unhide sys   >> "$ruta/Informe-$(date +%d-%m-%y).log"
sudo unhide brute >> "$ruta/Informe-$(date +%d-%m-%y).log"
sudo unhide-tcp -flov >> "$ruta/Informe-$(date +%d-%m-%y).log"
echo $?   # comprovar l'estatus de sortida (0/4/8/12)
11. AMPLIACIÓ / MILLORA — Script Bash complet i automatitzat
Crear el fitxer del script:
nano ~/RA1-P1-script.sh
Contingut complet del script (copiar tal qual):
#!/bin/bash
#############################################################
# Script: Razzouki_Barghal_Hamza-RA1-P1.sh
# Autor : Razzouki Barghal, Hamza - 2SMX
# Objectiu: Automatitzar ClamAV, Maldetect i les eines
#   anti-rootkits (chkrootkit, rkhunter, unhide, unhide-tcp),
#   centralitzant tots els informes .log a $HOME/logs
#############################################################
 
# --- Variables ---
ruta="$HOME/logs"
data=$(date +%d-%m-%y)
informe="$ruta/Informe-$data.log"
 
# --- Control de la carpeta de logs (sense duplicar codi) ---
if [ ! -d "$ruta" ]; then
    mkdir -p "$ruta"
else
    rm -f "$ruta"/*
fi
 
# --- 1) ClamAV: escaneig de tot el sistema excepte /home ---
sudo clamscan -r --exclude-dir="^/home" / >> "$informe" 2>&1
 
# --- 2) Maldetect: escaneig dels directoris d'usuari a /home ---
sudo maldet --scan-all /home >> "$informe" 2>&1
 
# --- 3) rkhunter (crea el fitxer informe) ---
sudo rkhunter -c --sk --logfile "$informe"
 
# --- 4) chkrootkit ---
sudo chkrootkit -x >> "$informe"
 
# --- 5) unhide (proc, sys, brute) ---
sudo unhide proc  >> "$informe"
sudo unhide sys   >> "$informe"
sudo unhide brute >> "$informe"
 
# --- 6) unhide-tcp + control del valor de retorn ($?) ---
sudo unhide-tcp -flov >> "$informe"
estat=$?
 
case $estat in
    0)  echo "No hidden port is found"                        >> "$informe" ;;
    4)  echo "One or more hidden TCP port(s) is(are) found"    >> "$informe" ;;
    8)  echo "One or more hidden UDP port(s) is(are) found"    >> "$informe" ;;
    12) echo "One or more hidden TCP and UDP ports are found"  >> "$informe" ;;
esac
 
echo "Informe generat a: $informe"
Donar permisos d'execució i executar-lo:
chmod +x ~/RA1-P1-script.sh
./RA1-P1-script.sh
cat ~/logs/Informe-$(date +%d-%m-%y).log   # revisar el resultat
12. (Extra) Automatitzar també la instal·lació
Script previ opcional que instal·la tots els programes abans d'executar el script del punt 11:
#!/bin/bash
sudo apt update
sudo apt install -y clamav clamav-daemon chkrootkit rkhunter unhide ssmtp wget
cd /usr/local
sudo wget -N http://www.rfxn.com/downloads/maldetect-current.tar.gz
sudo tar -xvf maldetect-current.tar.gz
cd maldetect-*/ && sudo ./install.sh
echo "Instal·lació completada. Ara executa RA1-P1-script.sh"
