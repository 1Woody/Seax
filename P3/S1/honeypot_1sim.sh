#!/bin/bash
# Elegir bien los PERMISOS!!!
# ports --> https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers

# Variables de usage per els avisos de error
usageInvalidArg="El nombre de arguments és incorrecte. Han de ser 3 arguments (revisar manual de usuari)."
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
arrayAtacs+=("")
repetit=0
primeraHora="primeraHora"
ultimaHora="ultimaHora"
arrayResum=("      10.1.1.105             2" "      10.1.1.108             2" "      10.1.1.105             2" "      10.1.1.105             2")
arrayProva=("18:30:12.5432-192.168.0.27-22-1" "12:31:12.5531-192.168.0.28-50000-2" "08:59:00.5432-192.168.0.33-123-1" "18:30:12.5432-192.168.0.27-6543-1" "18:30:12.5432-192.168.0.27-88-4")
#arrayEvol=(" 17:33:30.806049      10.1.1.108 51006" " 17:33:41.596338      10.1.1.105 40690" " 17:33:43.926395      10.1.1.105 40692" " 17:33:50.541803      10.1.1.108 51008")

####### PROGRAMA #######

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
touch test.log
true >  test.log

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
    tcpdump -l -q -nni enp0s3 '(not src 192.168.0.26) and (icmp)' 2>/dev/null >> /root/atacs.log &
    # hay un error en tcpdump
    pidtcpdump=$! # no va el pid kill
fi

# Bucle infinit del programa 
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)
tput sc; 
while [ $quit != 1 ]
do
    
    hora=$(awk '/./{if(NR==2) print $1}' atacs.log)
    ipNouAtac=$(awk '/./{if(NR==2) print $3}' atacs.log | cut -d '.' -f1,2,3,4)
    port=$(awk '/./{if(NR==2) print $3}' atacs.log | cut -d '.' -f5)
    if [ "$hora" != "" ] && [ "$ipNouAtac" != "" ]
    then 
        atacActual="$hora-$ipNouAtac-$port"
        if [ "${arrayAtacs[0]}" == "" ]
        then
            atacActual="$atacActual-1"
            arrayAtacs[0]="$atacActual"
        else
            for pos in "${!arrayAtacs[@]}"
            do  
                ipAtac=$(echo "${arrayAtacs[$pos]}" | cut -d '-' -f2)
                echo "$ipNouAtac" >> test.log
                echo "$ipAtac" >> test.log
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
            echo $repetit
            if [ "$repetit" != 1 ]
            then
                atacActual="$atacActual-1"
                arrayAtacs+=($atacActual)
            fi
            repetit=0
        fi
        echo -e "ÚLTIM ACCÈS REGISTRAT" > atacs.log 
        echo ------ARRAY------- >> test.log
        for i in "${!arrayAtacs[@]}"
        do
            printf 'arrayAtacs[%s]=%s\n' "$i" "${arrayAtacs[$i]}" >> test.log
        done
    fi
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
    for each in "${!arrayAtacs[@]}"
    do
        horaAcces=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f1 )
        ipAcces=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f2 )
        portAcces=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f3 )
        stringResum="$ $horaAcces   $ipAcces   $portAcces"
        echo "$stringResum"
    done
    echo -e " --------------- --------------- -----"
    if [ $quit != 1 ] 
    then
        echo -e "Prem [q] per sortir." 
        echo -e ""
        sleep 1;
        tput rc;
    fi
done
kill "$pidtcpdump"
exit 0