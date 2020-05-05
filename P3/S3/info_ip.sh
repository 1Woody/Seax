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

usageInvalidArg="El nombre de arguments és incorrecte. Han de ser 2 o 3 arguments (revisar manual de usuari)."
usagePaquetNmap="Has de tenir instalat el paquet de nmap, instala-ho amb: apt-get install nmap"
usagePaquetDig="Has de tenir instalat el paquet de dnsutils, instala-ho amb: apt-get install dnsutils"
usagePaquetCurl="Has de tenir instalat el paquet de curl, instala-ho amb: apt-get install curl jq"

if [ $usuari != "root" ]
then
	echo "$usageSuperUser"; exit 1
fi

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

# Comprovació del paquet curl
if [ "$(dpkg -l | grep -c curl)" -eq 0 ]
then 
	echo "$usagePaquetCurl"; exit 1
fi

if [ $# == 1 ] 
then
    echo -e "                                                                "
    echo -e "Programa de geolocalització i anàlisi automàtic d'una adreça IP."
    echo -e " Versió $scriptVersion compilada el $dataInicial."
    echo -e " Iniciant-se el $dataCompilacioInici a les $horaCompilacioInici ...          [ok]"
    echo -e " El fitxer log_ip sera sobrescrit...                  [ok]"

    echo -e " Iniciant l'escanneig de l'adreça $IP...      [ok]"

    equipIP="$IP "
    xarxaNoMasc=$(whois $IP | grep 'inetnum' | awk '{print $2}')
    xarxaMasc=$(whois $IP | grep 'route' | awk '{print $2}')
    xarxaBroadcast=$(whois $IP | grep 'inetnum' | awk '{print $4}')
    xarxaNom=$(whois $IP | grep 'netname' | awk '{print $2}')
    xarxaEquip="$xarxaMasc [$xarxaNoMasc - $xarxaBroadcast] ($xarxaNom)"
    entitatEquip=$(whois $IP | grep 'descr' | cut -d ' ' -f11-)
    paisEquip=$(whois $IP | grep 'country' | awk '{print $2}')
    entitatEquip="$entitatEquip ($paisEquip)"
    gestorASN=

    echo -e " Iniciant la localització de l'adreça...               [ok]"

    localitzacio=
    Coordenades=
    SOequip=
    ports=$(nmap $IP)

    echo -e " Processant les dades...                               [ok]"

    dataCompilacioFi=$(date --rfc-3339=date)
    horaCompilacioFi=$(date | cut -d ' ' -f5)

    echo -e " Resultats de l'anàlisi en el fitxer log_ip           [ok]"
    echo -e " Finalitzat el $dataCompilacioFi a les $horaCompilacioFi               [ok]"
    echo -e "                                                                           "

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
    echo -e " Equip:        $$"
    echo -e " Xarxa:        $$"
    echo -e " Entitat:      $$"
    echo -e " Gestor ASN:   $$"
    echo -e " Localització: $$"
    echo -e " Coordenades:  $$"
    echo -e " S. Operatiu:  $$"
    echo -e " Ports:        $$"
    echo -e "---------------------------------------------------------------------------------------------------------"
    } >> log_ip

else
    echo "$usageSuperUser"; exit 1
fi
