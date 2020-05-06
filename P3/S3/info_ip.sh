#!/bin/bash
#!utf-8

usuari=$(whoami)
SO=$(cat /etc/*release 2>/dev/null | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-04-30"
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)

IP="$1"

usageInvalidArg="El nombre de arguments és incorrecte. Ha de ser 1 argument (revisar manual de usuari)."
usagePaquetNmap="Has de tenir instalat el paquet de nmap, instala-ho amb: apt-get install nmap"
usagePaquetDig="Has de tenir instalat el paquet de dnsutils, instala-ho amb: apt-get install dnsutils"
usagePaquetWhois="Has de tenir instalat el paquet de whois, instala-ho amb: apt-get install -y whois"

# Comprovació del paquet nmap
if [ "$(dpkg -l | grep -c nmap)" -eq 0 ]
then 
	echo "$usagePaquetNmap"; exit 1
fi

# Comprovació del paquet dig
if [ "$(dpkg -l | grep -c dnsutils)" -eq 0 ]
then 
	echo "$usagePaquetDig"; exit 1
fi

# Comprovació del paquet whois
if [ "$(dpkg -l | grep -c whois)" -eq 0 ]
then 
	echo "$usagePaquetWhois"; exit 1
fi

if [ $# == 1 ] 
then
    echo -e "                                                                "
    echo -e "Programa de geolocalització i anàlisi automàtic d'una adreça IP."
    echo -e " Versió $scriptVersion compilada el $dataInicial."
    echo -e " Iniciant-se el $dataCompilacioInici a les $horaCompilacioInici ...          [ok]"
    echo -e " El fitxer log_ip sera sobrescrit...                   [ok]"

    echo -e " Iniciant l'escanneig de l'adreça $IP...      [ok]"

    dnsNom=$(dig -x $IP +short | head -n 1)
    equipIP="$IP ($dnsNom)"
    xarxaNoMasc=$(whois $IP | grep "NetRange:" | awk '{print $2}')
    xarxaMasc=$(whois $IP | grep "route:" | awk '{print $2}')
    if [ -z "$xarxaMasc" ]
    then
        xarxaMasc=$(whois $IP | grep "CIDR:" | cut -d ' ' -f12-)
    fi
    xarxaBroadcast=$(whois $IP | grep "NetRange:" | awk '{print $4}')
    xarxaNom=$(whois $IP | grep "netname:" | awk '{print $2}' | head -n 1)
    if [ -z "$xarxaNom" ]
    then
        xarxaNom=$(whois $IP | grep "OrgId:" | awk '{print $2}')
    fi
    xarxaEquip="$xarxaMasc [$xarxaNoMasc - $xarxaBroadcast] ($xarxaNom)"
    entitatEquip=$(whois $IP | grep "descr:" | cut -d ' ' -f11- | head -n 1)
    if [ -z "$entitatEquip" ]
    then
        entitatEquip=$(whois $IP | grep "Organization:" | cut -d ' ' -f4-)
    fi
    paisEquip=$(whois $IP | grep 'country' | awk '{print $2}')
    if [ -z "$paisEquip" ]
    then
        paisEquip=$(whois $IP | grep "Country:" | awk '{print $2}')
    fi
    entitatEquip="$entitatEquip ($paisEquip)"


    echo -e " Iniciant la localització de l'adreça...               [ok]"

    touch log_ip
    touch dades.log
    true > log_ip
    true > dades.log
    curl -s ipinfo.io/$IP > dades.log
    gestorASN=$(cat dades.log | grep org | cut -d '"' -f4)
    ciutat=$(cat dades.log | grep city | cut -d '"' -f4)
    CP=$(cat dades.log | grep postal | cut -d '"' -f4)
    provincia=$(cat dades.log | grep region | cut -d '"' -f4)
    pais=$(cat dades.log | grep country | cut -d '"' -f4)
    localitzacio="$ciutat ($CP), $provincia, $pais"
    latitud=$(cat dades.log | grep loc | cut -d '"' -f4 | cut -d ',' -f1)
    longitud=$(cat dades.log | grep loc | cut -d '"' -f4 | cut -d ',' -f2)
    zonaHoraria=$(cat dades.log | grep timezone | cut -d '"' -f4)
    coordenades="Latitud $latitud i longitud $longitud, amb zona horària $zonaHoraria"
    #SOequip=
    nmap $IP | awk '/PORT/,0' | sed '1d;$d;' | sed '$d' >> ports.log


    echo -e " Processant les dades...                               [ok]"

    dataCompilacioFi=$(date --rfc-3339=date)
    horaCompilacioFi=$(date | cut -d ' ' -f5)

    {
        echo -e " ---------------------------------------------------------------------------------------------------"
        echo -e " Cerca i anàlisi d'una adreça IP realitzada per l'usuari $usuari de l'equip $host."
        echo -e " Sistema operatiu $SO."
        echo -e " Versió del script $scriptVersion compilada el $dataInicial."
        echo -e " Anàlisi iniciada en data $dataCompilacioInici a les $horaCompilacioInici i finalitzada en data $dataCompilacioFi a les $horaCompilacioFi."
        echo -e " ----------------------------------------------------------------------------------------------------------"
        echo -e ""
        echo -e ""
        echo -e "---------------------------------------------------------------------------------------------------------"
        echo -e "Informació de l'adreça IP"
        echo -e " Equip:        $equipIP"
        echo -e " Xarxa:        $xarxaEquip"
        echo -e " Entitat:      $entitatEquip"
        echo -e " Gestor ASN:   $gestorASN"
        echo -e " Localització: $localitzacio"
        echo -e " Coordenades:  $coordenades"
        echo -e " S. Operatiu:  "
        primera=0
        while IFS= read -r line; do
            protocolWeb=$(echo "$line" | awk '{print $3}')
            protocolTrans=$(echo "$line" | awk '{print $1}' | cut -d '/' -f2)
            numPort=$(echo "$line" | awk '{print $1}' | cut -d '/' -f1)
            if [ $primera == 0 ] 
            then
                echo -e " Ports:        $protocolTrans/$numPort\t($protocolWeb)"
                primera=1
            else
                echo -e "               $protocolTrans/$numPort\t($protocolWeb)"
            fi
        done < ports.log
        echo -e "---------------------------------------------------------------------------------------------------------"
    } >> log_ip

    dataCompilacioFi=$(date --rfc-3339=date)
    horaCompilacioFi=$(date | cut -d ' ' -f5)

    echo -e " Resultats de l'anàlisi en el fitxer log_ip            [ok]"
    echo -e " Finalitzat el $dataCompilacioFi a les $horaCompilacioFi               [ok]"
    echo -e "                                                                           "

else
    echo "$usageInvalidArg"; exit 1
fi
rm ports.log
rm dades.log
exit 0;
