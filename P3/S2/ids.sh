#!/bin/bash

interfacelist=$(ls /sys/class/net/ | grep ^e)

usuari=$(whoami)
SO=$(cat /etc/*release 2>/dev/null | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-05-3"
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)

#llistaMACs --> cat /usr/share/nmap/nmap-mac-prefixes


# Creació de fitxers
touch .llistaEquips
touch .xarxes
touch test.log
true > .llistaEquips
true > test.log
true > .xarxes

echo -e "                                                                "
echo -e "Programa de cerca automàtica d'equips a la xarxa actual."
echo -e " Versió $scriptVersion compilada el $dataInicial."
echo -e " Iniciant-se el $dataCompilacioInici a les $horaCompilacioInici ...          [ok]"
echo -e " El fitxer log_ids sera sobrescrit...                  [ok]"
echo -e " Detecció d'equips en curs...                          "

for interface in $(ls /sys/class/net/ | grep ^e)
do 

	
    ipInterface=$(ip -4 addr show dev "$interface" | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
    if [ "$ipInterface" != "" ]
    then
        ipXarxa=$(ip r | grep "$ipInterface" | awk '{print $1}')
        echo "$ipXarxa [$interface]" >> .xarxes
        
        # comanda nmap
        nmap -sn "$ipXarxa" > .scan.log
        echo -e "[ok]"

        #llistaEquips
        cat .scan.log | grep -e "scan report for" -e "MAC" > .llistaEquips

        MACinterface="$(ip link show dev $interface | grep ether | awk '{print $2}')"
        #echo $MACinterface
        MACinterface=${MACinterface^^}
        #echo $MACinterface
        MACfabricant="$(echo $MACinterface | cut -d ':' -f1,2,3 |sed "s/://g")"
        #echo $MACfabricant
        Nomfabricant=$(grep "$MACfabricant" /usr/share/nmap/nmap-mac-prefixes | cut -d ' ' -f2-)
        #echo $Nomfabricant

        echo -e "MAC Address: $MACinterface ($Nomfabricant)" >> .llistaEquips 

        counter=0
        infoEquip=""

        while IFS= read -r line; do
            line_type=$(echo $line | grep -c "Nmap scan report for")
            if [ $line_type == 1 ] # tractament d'ips i DNS
            then
                if [ $counter == 1 ]
                then
                    infoEquip="$ipCorrecta|-|-|-|$dns"
                    echo "$infoEquip" >> test.log
                fi
                test_dns="$(echo $line | awk '{print $5}')"
                # comprovació nom dns
                test_dns=$(echo "$test_dns" | cut -d '.' -f1,2,3 | grep -c "$(echo $ipInterface | cut -d '.' -f1,2,3)")
                if [ $test_dns != 1 ]
                then
                    ipCorrecta="$(echo $line | awk '{print $6}' | cut -d '(' -f2 | cut -d ")" -f1)"
                    dns="$(echo $line | awk '{print $5}')."
                else
                    ipCorrecta="$(echo $line | awk '{print $5}')"
                    dns="."
                fi
                counter=1
            else # tractament de MACs i Fabricants
                mac=$(echo $line | awk '{print $3}')
                equipConegut=$(cat equips_coneguts | grep "$mac" | cut -d ' ' -f2-)
                if [ "$equipConegut" == "" ]
                then 
                    equipConegut="-"
                fi
                fabricant=$(echo $line | cut -d '(' -f2 | cut -d ')' -f1)
                infoEquip="$ipCorrecta|$mac|$fabricant|$equipConegut|$dns"
                echo "$infoEquip" >> test.log
                counter=0
            fi
        done < .llistaEquips
    fi
done

echo -e " Processant les dades...                               [ok]"

touch log_ids
true > log_ids

numEquips=$(wc -l test.log)
subxarxes=" "
while IFS= read -r line; do
    if [ "$subxarxes" == " " ]
    then
        subxarxes="$line"
    else 
        subxarxes="$subxarxes, $line"
    fi
done < .xarxes

dataCompilacioFi=$(date --rfc-3339=date)
horaCompilacioFi=$(date | cut -d ' ' -f5)

{
        echo -e " ---------------------------------------------------------------------------------------------------"
        echo -e " Detecció dels equips de la xarxa local realitzada per l'usuari $usuari de l'equip $host."
        echo -e " Sistema operatiu $SO."
        echo -e " Versió del script $scriptVersion compilada el $dataInicial."
        echo -e " Anàlisi iniciada en data $dataCompilacioInici a les $horaCompilacioInici i finalitzada en data $dataCompilacioFi a les $horaCompilacioFi."
        echo -e " ---------------------------------------------------------------------------------------------------"
        echo -e " "
        echo -e " "
        echo -e " ---------------------------------------------------------------------------------------------------------"
        echo -e " S'han detectat $numEquips equips a les $subxarxes"
        echo -e " ---------------------------------------------------------------------------------------------------------"
        echo -e " Adreça IP        Adreça MAC         Fabricant MAC                   Equip conegut      Nom DNS"
        echo -e " ---------------  -----------------  ------------------------------  -----------------  ------------------"
        while IFS= read -r line; do
            ip=$(echo "$line" | cut -d '|' -f1)
            mac=$(echo "$line" | cut -d '|' -f2)
            fabricant=$(echo "$line" | cut -d '|' -f3)
            equip=$(echo "$line" | cut -d '|' -f4)
            dns=$(echo "$line" | cut -d '|' -f5)
            printf "%-17.17s %-18.18s %-31.31s %-18.18s %-25.25s" " $ip" "$mac" "$fabricant" "$equip" "$dns"
            echo -e ""
        done < test.log
        echo -e " ---------------  -----------------  ------------------------------  -----------------  ------------------"
} >> log_ids

echo -e " Resultats de l'anàlisi en el fitxer log_ids...        [ok]"
echo -e " Finalitzat el $dataCompilacioFi a les $horaCompilacioFi               [ok]"
echo -e " "

rm .xarxes
#rm test.log
exit 0;
