#!/bin/bash
#!utf-8

####### 1. VARIABLES #######

# Variables Usage
usageArguments="El nombre de arguments és incorrecte. No has de pasar cap argument (revisar manual de usuari)."
usageSuperUser="Has de ser root per executar aquest script"
usagePaquetcpdump="Has de tenir instalat el paquet de nmap, instala-ho amb: apt install nmap"
usagePaquetip="Has de tenir instalat el paquet de iproute, instala-ho amb: apt install iproute2"

# Variables entorn
usuari=$(whoami)
SO=$(cat /etc/*release 2>/dev/null | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-05-3"
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)
interfacelist=$(ls /sys/class/net/ | grep ^e)

####### 2. COMPROVACIONS PREVIES #######

# Comprovació de 0 arguments i help (-h)
if [ $# != 0 ]
then
    if [ $# == 1 ] && [ "$1" == "-h" ]
    then 
        echo -e " "
        echo -e "  AJUDA"
        echo -e "  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
        echo -e "  L'execució de l'script no accepta cap argument addicional.                                             "
        echo -e "  Es basa en una recopilació de dades dels dispositius connectats a la xarxa local.                      "
        echo -e "  Es mostraran la IP, la MAC, el fabricant MAC, el nom DNS i si és un equip conegut, de tots els equips. "
        echo -e "  El programa tracta les diferents subxarxes (locals), però no tindra en compte les interfícies wifi.    "
        echo -e "  El fitxer de sortida s'anomena 'log_ids' i està situat al mateix directori on s'executa l'script.      "
        echo -e "  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
        echo -e ""
        exit 0;
    else
    echo "$usageArguments" ; exit 1
    fi
fi

# Comprovació SuperUsuari
if [ "$(whoami)" != "root" ]
then
	echo "$usageSuperUser"; exit 1
fi

# Comprovació del paquet nmap
if [ "$(dpkg -l | grep -c nmap)" -eq 0 ]
then 
	echo "$usagenmap"; exit 1
fi

# Comprovació del paquet iproute2
if [ "$(dpkg -l | grep -c iproute2)" -eq 0 ]
then 
	echo "$usagePaquetip"; exit 1
fi

####### 3. CREACIÓ DE FITXERS NECESSARIS #######

# Creació de fitxers
touch .llistaEquips
touch .xarxes
touch .scanlist.log
touch equips_coneguts
touch log_ids

true > log_ids
true > .llistaEquips
true > .scanlist.log
true > .xarxes

####### 4. MAQUETACIÓ DE DADES PART 1 #######

echo -e "                                                                "
echo -e "Programa de cerca automàtica d'equips a la xarxa actual."
echo -e " Versió $scriptVersion compilada el $dataInicial."
echo -e " Iniciant-se el $dataCompilacioInici a les $horaCompilacioInici ...          [ok]"
echo -e " El fitxer log_ids sera sobrescrit...                  [ok]"
echo -ne " Detecció d'equips en curs...                          "

####### 5. TRACTAMENT DE DADES #######

for interface in $(ls /sys/class/net/ | grep ^e)
do
    # Comprovació validesa de la xarxa
    ipInterface=$(ip -4 addr show dev "$interface" | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
    if [ "$ipInterface" != "" ]
    then
        # Emmagatzematge nom de les xarxes més la seva IP
        ipXarxa=$(ip r | grep "$ipInterface" | awk '{print $1}')
        echo "$ipXarxa [$interface]" >> .xarxes
        
        # Execució comanda nmap
        nmap -sn "$ipXarxa" > .scanmap.log

        # llista neta dels equips (ip i Mac)
        cat .scanmap.log | grep -e "scan report for" -e "MAC" > .llistaEquips

        # Recopilació de Fabricant per la MAC de la màquina base 
        MACinterface="$(ip link show dev $interface | grep ether | awk '{print $2}')"
        MACinterface=${MACinterface^^}
        MACfabricant="$(echo $MACinterface | cut -d ':' -f1,2,3 |sed "s/://g")"
        Nomfabricant=$(grep "$MACfabricant" /usr/share/nmap/nmap-mac-prefixes | cut -d ' ' -f2-)
        
        # Emmagatzematge a la llista neta per posterior tractament
        echo -e "MAC Address: $MACinterface ($Nomfabricant)" >> .llistaEquips 

        # Tractament de dades Scaneig
        counter=0
        infoEquip=""
        while IFS= read -r line; do
            line_type=$(echo $line | grep -c "Nmap scan report for")
            
            # Tractament d'ips i DNS
            if [ $line_type == 1 ] 
            then
                # Tractament cas opcional
                # (un ordinador connectat per dues interfícies a la mateixa xarxa)
                if [ $counter == 1 ]
                then
                    infoEquip="$ipCorrecta|-|-|-|$dns"
                    echo "$infoEquip" >> .scanlist.log
                fi

                test_dns="$(echo $line | awk '{print $5}')"
                # Comprovació nom dns
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

            # tractament de MACs, Fabricants i Equips coneguts
            else
                mac=$(echo $line | awk '{print $3}')
                equipConegut=$(cat equips_coneguts | grep "$mac" | cut -d ' ' -f2-)
                if [ "$equipConegut" == "" ]
                then
                    equipConegut="-"
                fi
                fabricant=$(echo $line | cut -d '(' -f2 | cut -d ')' -f1)
                infoEquip="$ipCorrecta|$mac|$fabricant|$equipConegut|$dns"
                echo "$infoEquip" >> .scanlist.log
                counter=0
            fi
        done < .llistaEquips
    fi
done

####### 6. MAQUETACIÓ DE DADES #######

echo -e "[ok]"
echo -e " Processant les dades...                               [ok]"

# Maquetació de subxarxes
numEquips=$(wc -l .scanlist.log | awk '{print $1}')
subxarxes=" "
while IFS= read -r line; do
    if [ "$subxarxes" == " " ]
    then
        subxarxes="$line"
    else 
        subxarxes="$subxarxes, $line"
    fi
done < .xarxes

# Maquetació de fitxer log
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
        done < .scanlist.log
        echo -e " ---------------  -----------------  ------------------------------  -----------------  ------------------"
} >> log_ids

echo -e " Resultats de l'anàlisi en el fitxer log_ids...        [ok]"
echo -e " Finalitzat el $dataCompilacioFi a les $horaCompilacioFi               [ok]"
echo -e " "

# Neteja fitxers 
rm .xarxes
rm .scanmap.log
rm .scanlist.log
rm .llistaEquips
exit 0;
