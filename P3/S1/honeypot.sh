#!/bin/bash
#!utf-8
# Elegir bien los PERMISOS!!!
# COMPROBAR LO QUE NECESITA EL USUARIO (PAQUETES, ROOT ...)
# ports --> https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers

# Variables de usage per els avisos de error
usageInvalidArg="El nombre de arguments és incorrecte. Han de ser 2 o 3 arguments (revisar manual de usuari)."
usagePortEnter="Recorda, l'argument del port ha de contenir un nombre enter."
usagePortRang="Compte! El port s'ha de trobar entre el 0 i el 65535 (ports disponibles)."
usageProtocolInc="El protocol escollit no està permés. Recorda que ha de ser TCP, UDP."
usageInterficieInc="La interfície no és vàlida o no es troba al sistema."
usageICMP="En cas d'escriure dos arguments, recorda que el protocol ha de ser l'ICMP."
usageTCPUDP="Recorda que en cas de seleccionar el protocol TCP o UDP has d'especificar un port."

# Varibales per les comprovacions
llistaInterficies=$(ls /sys/class/net/)
i=0
quit=0
PR="$2"
protocolMajus=${PR^^}
protocolMinus=${PR,,}
interfaceActual="$1"

# Variables de característiques 
usuari=$(whoami)
SO=$(cat /etc/*release | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-04-25"

# Variables filtres tcpdump
myIP=$(hostname -I | cut -d ' ' -f1)
filter_icmp="'not src "$myIP" && icmp'"
filter_tcp="tcp[13]=2 && port "$3""

#Variables de loop
numAccesosSimultanis=11 #10 accesos, agafem 11 per evitar agafar la capçalera
comptLinia=2
arrayAtacs+=("") # array amb comptador de repetició
arrayFullAtacs+=("") # array amb tots els atacs (sense tenir en compte repeticions)
repetit=0
primeraHora=" 0 atacs rebuts"
ultimaHora=" 0 atacs rebuts"

####### PROGRAMA #######

#detecció dels progrmas necessaris
if [ $(whoami) != "root" ]; then #has de ser root (whoami et diu si ho executes com root)
	echo "Has de ser root per executar aquest script"
	exit 1
fi

#man que este instalado

if [ $(man tcpdump 2>&1 | wc -l) -eq 1 ]; then #Si busquem el manual de tcpdump i no trobem res significa que no tenim instalat aquesta comanda
	echo "Has de tenir instalat el paquet de tcpdump, instala amb: apt install tcpdump"
	exit 1
fi


#detecció de la correctesa dels arguments d'entrada
if [ $# == 2 ]
then 
    if [ "$protocolMajus" != "ICMP" ]
    then
        if [ "$protocolMajus" == "TCP" ] || [ "$protocolMajus" == "UDP" ]
        then
            echo "$usageTCPUDP"; exit 1
        else
            echo "$usageICMP"; exit 1
        fi
    fi 
elif [ $# == 3 ]
then
    # Comprovació del port
    if [[ ! $3 =~ ^[0-9]+$ ]] 
    then 
        echo "$usagePortEnter"; 
        exit 1
    elif [ "$3" -gt "65535" ] || [ "$3" -lt "0" ]
    then
        echo "$usagePortRang"; exit 1    
    # Comprovació del protocol
    elif [ "$protocolMajus" != "TCP" ] && [ "$protocolMajus" != "UDP" ]
    then
        echo "$usageProtocolInc"; exit 1
    fi
else
    echo "$usageInvalidArg"; exit 1
fi
for interface in $llistaInterficies; do
    if [ "$interface" == "$interfaceActual" ]
    then
        ((i+=1))
    fi
done
if [ "$i" != 1 ]
then 
    echo "$usageInterficieInc"; exit 1
fi

# Creació de fitxers necessaris
touch log_honeypot
touch atacs.log

# Activació del procés de tcpdump en funció del paràmetres establerts
echo -e "ÚLTIM ACCÈS REGISTRAT" > atacs.log
if [ "$protocolMajus" == "TCP" ]
then
    tcpdump -l -q -nni "$interfaceActual" "$filter_tcp" 2>/dev/null >> /root/atacs.log &
    pidtcpdump=$!
elif [ "$protocolMajus" == "UDP" ]
then 
    tcpdump -l -q -nni "$interfaceActual" udp port "$3" 2>/dev/null >> /root/atacs.log &
    pidtcpdump=$!
else
    tcpdump -l -q -nni enp0s3 dst $myIP and icmp 2>/dev/null >> /root/atacs.log &
    pidtcpdump=$!
fi

# Bucle infinit del programa 
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)
tput sc; 
while [ $quit != 1 ]
do
    while [ "$comptLinia" -le "$numAccesosSimultanis" ]
    do
        hora=$(awk -v line=$comptLinia '/./{if(NR==line) print $1}' atacs.log)
        ipNouAtac=$(awk -v line=$comptLinia '/./{if(NR==line) print $3}' atacs.log | cut -d '.' -f1,2,3,4)
        port=$(awk -v line=$comptLinia '/./{if(NR==line) print $3}' atacs.log | cut -d '.' -f5)
        if [ "$hora" != "" ] && [ "$ipNouAtac" != "" ]
        then 
            atacActual="$hora-$ipNouAtac-$port"
            if [ "${arrayAtacs[0]}" == "" ] && [ "${arrayFullAtacs[0]}" == "" ]
            then
                primeraHora=$hora #guardem l'hora del primer acces
                arrayFullAtacs[0]="$atacActual"
                atacActual="$atacActual-1"
                arrayAtacs[0]="$atacActual"
            else
                ultimaHora=$hora #guardem l'hora de l'últim accés
                arrayFullAtacs+=($atacActual)
                for pos in "${!arrayAtacs[@]}"
                do  
                    ipAtac=$(echo "${arrayAtacs[$pos]}" | cut -d '-' -f2)
                    if [ "$ipNouAtac" == "$ipAtac" ]
                    then
                        auxValors=$(echo "${arrayAtacs[$pos]}" | cut -d '-' -f1,2,3)
                        comptAtacs=$(echo "${arrayAtacs[$pos]}" | cut -d '-' -f4 | awk '{print $0+1}')
                        nouAtac="$auxValors-$comptAtacs"
                        arrayAtacs[$pos]="$nouAtac"
                        repetit=1
                        break
                    fi
                done
                if [ "$repetit" != 1 ]
                then
                    atacActual="$atacActual-1"
                    arrayAtacs+=($atacActual)
                fi
                repetit=0
            fi
            ((comptLinia+=1))
        else
            comptLinia=12  # acabem la lectura ja que no hi ha res al fitxer
        fi
    done
    comptLinia=2
    echo -e "ÚLTIM ACCÈS REGISTRAT" > atacs.log 

    ####################INICI FORMAT####################
    tput ed;
    read -r -t 0.01 -N 1 input
    if [[ $input = "q" ]]
    then
        dataCompilacioFi=$(date --rfc-3339=date)
        horaCompilacioFi=$(date | cut -d ' ' -f5)
        quit=1
        true > log_honeypot
        exec 1<>log_honeypot
        echo -n ""
        echo -e "----------------------------------------------------------------------------------------------------------"
        echo -e "Monitorització realitzada per l'usuari $usuari de l'equip $host."
        echo -e "Sistema operatiu $SO."
        echo -e "Versió del script $scriptVersion compilada el $dataInicial."
        echo -e "Monitorització iniciada en data $dataCompilacioInici a les $horaCompilacioInici i finalitzada en data $dataCompilacioFi a les $horaCompilacioFi."
        echo -e "----------------------------------------------------------------------------------------------------------"
    fi
    echo -e ""
    echo -e ""
    echo -e "-----------------------------------------------------------------------------"
    echo -e "Accesos a l'adreça $myIP port $protocolMinus $3 [$primeraHora , $ultimaHora] "
    echo -e "-----------------------------------------------------------------------------"
    echo -e ""
    echo -e "------------------------------"
    echo -e "Resum dels accessos"
    echo -e "------------------------------"
    echo -e "    Adreces IP     Nº accessos"
    echo -e " ---------------   -----------"
    for each in "${!arrayAtacs[@]}"
    do 
        ipAcces=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f2 )
        numAccessos=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f4 )
        stringResum="    $ipAcces             $numAccessos"
        echo "$stringResum"
    done
    echo -e " ---------------   -----------"
    echo -e ""
    echo -e "--------------------------------------"
    echo -e "Evolució dels accessos"
    echo -e "--------------------------------------"
    echo -e "      Temps         Adreça IP     Port"
    echo -e " --------------- --------------- -----"
    for each in "${!arrayFullAtacs[@]}"
    do
        horaAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f1 )
        ipAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f2 )
        portAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f3 )
        stringResum=" $horaAcces   $ipAcces   $portAcces"
        echo "$stringResum"
    done
    echo -e " --------------- --------------- -----"
    if [ $quit != 1 ] 
    then
        echo -e "Prem [q] per sortir." 
        echo -e " "
        sleep 1;
        tput rc;
    fi
done
kill "$pidtcpdump"
exit 0