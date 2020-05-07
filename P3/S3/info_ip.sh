#!/bin/bash
#!utf-8

####### 1. VARIABLES #######

# Variables usage
usageInvalidArg="El nombre de arguments és incorrecte. Ha de ser 1 argument (revisar manual de usuari)."
usagePaquetNmap="Has de tenir instalat el paquet de nmap, instala-ho amb: apt-get install nmap"
usagePaquetDig="Has de tenir instalat el paquet de dnsutils, instala-ho amb: apt-get install dnsutils"
usagePaquetWhois="Has de tenir instalat el paquet de whois, instala-ho amb: apt-get install -y whois"
usageSuperUser="Has de ser root per executar aquest script"
usageIP="Sembla que no has escrit la IP correctament, revisa el teu paràmetre"
usagePaquetCurl="Has de tenir instalat el paquet de curl, instala-ho amb: apt-get install curl"

# Variables entorn
usuari=$(whoami)
SO=$(cat /etc/*release 2>/dev/null | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-04-30"
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)

####### 2. COMPROVACIONS PREVIES #######

# Captura i comprovació arguments
if [ $# != 1 ] 
then
    echo "$usageInvalidArg"; exit 1
fi

IP="$1"
# Comprovació paràmetre Ip correcte
if [[ ! "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "$usageIP"; exit 1
fi

# Comprovació SuperUsuari
if [ "$(whoami)" != "root" ]
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

# Comprovació del paquet whois
if [ "$(dpkg -l | grep -c whois)" -eq 0 ]
then 
	echo "$usagePaquetWhois"; exit 1
fi

# Comprovació del paquet curl
if [ "$(dpkg -l | grep -c curl)" -eq 0 ]
then 
	echo "$usagePaquetCurl"; exit 1
fi

####### 3. MAQUETACIÓ DE DADES PART 1 #######

echo -e "                                                                "
echo -e "Programa de geolocalització i anàlisi automàtic d'una adreça IP."
echo -e " Versió $scriptVersion compilada el $dataInicial."
echo -e " Iniciant-se el $dataCompilacioInici a les $horaCompilacioInici ...          [ok]"
echo -e " El fitxer log_ip sera sobrescrit...                   [ok]"
espaiBlanc=" ";
x=0;
trobat=0;
while (( x <= 17 )) && (( trobat == 0))
do
    # Tractament de l'espai assignat a la IP
    if [ "${#IP}" == "$x" ]
    then
        num=17-$x;
        for ((y=0; y<num; y++))
        do
            espaiBlanc=" $espaiBlanc";
        done
        trobat=1;
    else
        ((x+=1))
    fi
done
echo -ne " Iniciant l'escanneig de l'adreça $IP...$espaiBlanc"

####### 4. RECOPILACIÓ DE DADES PART 1 #######

# Extracció del nom DNS
dnsNom=$(dig -x "$IP" +short | head -n 1)
if [ -z "$dnsNom" ]
then
    equipIP="$IP (DNS desconegut)"
else
    equipIP="$IP ($dnsNom)"
fi

# Creació i emplenament del fitxer de tractament de xarxes
touch .infowhois.log
whois "$IP" > .infowhois.log

xarxaNoMasc=$(grep "NetRange:" .infowhois.log | awk '{print $2}')
if [ -z "$xarxaNoMasc" ]
then
    xarxaNoMasc=$(grep "inetnum:" .infowhois.log | awk '{print $2}')
fi
xarxaMasc=$(grep "route:" .infowhois.log | awk '{print $2}')
if [ -z "$xarxaMasc" ]
then
    xarxaMasc=$(grep "CIDR:" .infowhois.log | cut -d ' ' -f12-)
fi
xarxaBroadcast=$(grep "NetRange:" .infowhois.log | awk '{print $4}')
if [ -z "$xarxaBroadcast" ]
then
    xarxaBroadcast=$(grep "inetnum:" .infowhois.log | awk '{print $4}')
fi
xarxaNom=$(grep "netname:" .infowhois.log | awk '{print $2}' | head -n 1)
if [ -z "$xarxaNom" ]
then
    xarxaNom=$(grep "OrgId:" .infowhois.log | awk '{print $2}')
fi
xarxaEquip="$xarxaMasc [$xarxaNoMasc - $xarxaBroadcast] ($xarxaNom)"
entitatEquip=$(grep "descr:" .infowhois.log | cut -d ' ' -f11- | head -n 1)
if [ -z "$entitatEquip" ]
then
    entitatEquip=$(grep "Organization:" .infowhois.log | cut -d ' ' -f4-)
fi
paisEquip=$(grep "country" .infowhois.log | awk '{print $2}')
if [ -z "$paisEquip" ]
then
    paisEquip=$(grep "Country:" .infowhois.log | awk '{print $2}')
fi
entitatEquip="$entitatEquip ($paisEquip)"

echo -e "[ok]"
echo -ne " Iniciant la localització de l'adreça...               "

####### 5. CREACIÓ DE FITXERS NECESSARIS #######

touch log_ip
touch .dades.log
touch .infonmap.log
touch .ports.log
true > log_ip
true > .dades.log
true > .infonmap.log
true > .ports.log

####### 6. RECOPILACIÓ DE DADES PART 2 #######

# Recollim les dades principals de localització de la IP
curl -s ipinfo.io/"$IP" > .dades.log
gestorASN=$(grep "org" .dades.log | cut -d '"' -f4)
if [ -z "$gestorASN" ]
then
    gestorASN="Desconegut"
fi
ciutat=$(grep "city" .dades.log | cut -d '"' -f4)
if [ -z "$ciutat" ]
then
    localitzacio="Desconeguda"
else
    CP=$(grep "postal" .dades.log | cut -d '"' -f4)
    provincia=$(grep "region" .dades.log | cut -d '"' -f4)
    pais=$(grep "country" .dades.log | cut -d '"' -f4)
    localitzacio="$ciutat ($CP), $provincia, $pais"
fi
latitud=$(grep "loc" .dades.log | cut -d '"' -f4 | cut -d ',' -f1)
if [ -z "$latitud" ]
then
    coordenades="Desconegudes"
else
    longitud=$(grep "loc" .dades.log | cut -d '"' -f4 | cut -d ',' -f2)
    zonaHoraria=$(grep "timezone" .dades.log | cut -d '"' -f4)
    coordenades="Latitud $latitud i longitud $longitud, amb zona horària $zonaHoraria"
fi

nmap -O "$IP" >> .infonmap.log

# Cerquem SO
SOequip=$(grep "OS details" .infonmap.log | cut -d' ' -f3-)
if [ "$SOequip" == "" ]
then
    SOequip="Desconegut"
fi

# Cerquem els ports
grep -e "tcp" -e "udp" .infonmap.log | awk '{print $1, $3}' > .ports.log

####### 7. MAQUETACIÓ DE DADES PART 2 #######

echo -e "[ok]"
echo -ne " Processant les dades...                               "

dataCompilacioFi=$(date --rfc-3339=date)
horaCompilacioFi=$(date | cut -d ' ' -f5)

{
    echo -e " ---------------------------------------------------------------------------------------------------"
    echo -e " Cerca i anàlisi d'una adreça IP realitzada per l'usuari $usuari de l'equip $host."
    echo -e " Sistema operatiu $SO."
    echo -e " Versió del script $scriptVersion compilada el $dataInicial."
    echo -e " Anàlisi iniciada en data $dataCompilacioInici a les $horaCompilacioInici i finalitzada en data $dataCompilacioFi a les $horaCompilacioFi."
    echo -e " ---------------------------------------------------------------------------------------------------"
    echo -e ""
    echo -e ""
    echo -e "--------------------------------------------------------------------------------"
    echo -e "Informació de l'adreça IP"
    echo -e " Equip:        $equipIP"
    echo -e " Xarxa:        $xarxaEquip"
    echo -e " Entitat:      $entitatEquip"
    echo -e " Gestor ASN:   $gestorASN"
    echo -e " Localització: $localitzacio"
    echo -e " Coordenades:  $coordenades"
    echo -e " S. Operatiu:  $SOequip"
    primera=0
    if [ "$(wc -l .ports.log | awk '{print $1}')" == 0 ]
    then
        echo -e " Ports:        Desconeguts"
    fi
    while IFS= read -r line; do
        protocolWeb=$(echo "$line" | awk '{print $2}')
        protocolTrans=$(echo "$line" | awk '{print $1}' | cut -d '/' -f2)
        numPort=$(echo "$line" | awk '{print $1}' | cut -d '/' -f1)
        if [ $primera == 0 ] 
        then
            echo -e " Ports:        $protocolTrans/$numPort\\t($protocolWeb)"
            primera=1
        else
            echo -e "               $protocolTrans/$numPort\\t($protocolWeb)"
        fi
    done < .ports.log
    echo -e "--------------------------------------------------------------------------------"
} >> log_ip


echo -e "[ok]"
echo -e " Resultats de l'anàlisi en el fitxer log_ip            [ok]"
echo -e " Finalitzat el $dataCompilacioFi a les $horaCompilacioFi               [ok]"
echo -e "                                                                           "

####### 8. NETEJA DE FITXERS AUXILIARS #######
rm .infowhois.log
rm .ports.log
rm .infonmap.log
rm .dades.log
exit 0;

