#/bin/bash

##~######################################### VERSION MARTOS ##########################################
interface=$(basename -a /sys/class/net/)
ip_maquina=$(ip route | grep -v default | awk '{print $9}')
ip_red=$(ip route | grep -v default | awk '{print $1}')
echo $interface
echo $ip_red
echo $ip_maquina

nmap -sn -oN .nmap.out $ip_red 

cat .nmap.out | grep report | awk  -F "for" '{print $2}' | cut -d'(' -f2 | cut -d' ' -f2 | cut -d')' -f1 > .lista_ip
cat .nmap.out | grep MAC | awk '{print $3}' > .lista_MAC
cat .nmap.out | grep MAC | cut -d'(' -f2 | cut -d')' -f1 > .fabricant_MAC
cat .nmap.out | grep report | awk '{print $5}' | cut -d'.' -f1 | sed "s/$(echo $ip_red | cut -d'.' -f1)/-/g" > .hostnames

echo -e "---------------------------------------------------------------------------------------------------"
echo -e "Detecció dels equips de la xarxa local realitzada per l'usuari $USER de l'equip $(echo $HOSTNAME)."
echo -e "Sistema operatiu $(cat /etc/release | grep PRETTY | cut -d '"' -f2)"
echo -e "Versió del script 1.0 compilada el $(stat $0 | grep Modify | cut -d' ' -f2)."
echo -e "Anàlisi iniciada en data TODAY a les $(cat .nmap.out | grep '#' | grep 'initiated' | cut -d' ' -f10) i finalitzada en data TODAY a les $(cat .nmap.out | grep '#' | grep 'done' | cut -d' ' -f9)."
echo -e "---------------------------------------------------------------------------------------------------"


echo -e "---------------------------------------------------------------------------------------------------"
echo -e "S'han detectat 9 equips a les subxarxes XXXX, , YYYY"
echo -e "---------------------------------------------------------------------------------------------------"
echo -e "Adreça IP   Adreça MAC         Fabricant MAC                  Equip conegut     Nom DNS"
echo -e "----------  -----------------  -----------------------------  ----------------  -------------------"

echo -e "----------  -----------------  -----------------------------  ----------------  -------------------"