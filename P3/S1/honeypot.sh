#!/bin/bash
# Elegir bien los PERMISOS!!!
# ports --> https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers

usageInvalidArg="El nombre de arguments és incorrecte. Han de ser 3 arguments (revisar manual de usuari)."
usagePortEnter="Recorda, l'argument del port ha de contenir un nombre enter."
usagePortRang="Compte! El port s'ha de trobar entre el 0 i el 65535 (ports disponibles)."
usageProtocolInc="El protocol escollit no està permés. Recorda que ha de ser TCP, UDP o ICMP."
usageInterficieInc="La interfície no és vàlida o no es troba al sistema."
llistaInterficies=$(ls /sys/class/net/)
i=0
PR="$2"
protocolMajus=${PR^^}
protocolMinus=${PR,,}
primeraHora="primeraHora"
ultimaHora="ultimaHora"
myIP=$(hostname -I)
#detecció de la correctesa dels arguments d'entrada --> ./honeypot.sh eth0 tcp 80
if [ $# == 3 ]
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
    elif [ "$protocolMajus" != "TCP" ] && [ "$protocolMajus" != "UDP" ] && [ "$protocolMajus" != "ICMP" ]
    then
        echo "$usageProtocolInc"; exit 1
    else
        for interface in $llistaInterficies; do
            if [ "$interface" == "$1" ]
            then
                ((i+=1))
            fi
        done
        if [ "$i" != 1 ]
        then 
            echo "$usageInterficieInc"; exit 1
        fi
        echo -e ""\\n
        echo -e "-----------------------------------------------------------------------------"
        echo -e "Accesos a l'adreça $myIP port $protocolMinus $3 [$primeraHora , $ultimaHora] "
        echo -e "-----------------------------------------------------------------------------"\\n
        echo -e "------------------------------"
        echo -e "Resum dels accessos"
        echo -e "------------------------------"
        echo -e "    Adreces IP     Nº accessos"
        echo -e " ---------------   -----------"
        #CÓDIGO RESUMEN DE LOS ACCESOS
        echo -e " ---------------   -----------"\\n
        echo -e "--------------------------------------"
        echo -e "Evolució dels accessos"
        echo -e "--------------------------------------"
        echo -e "      Temps         Adreça IP     Port"
        echo -e " --------------- --------------- -----"
        #CÓDIGO EVOLUCIÓN DE LOS ACCESOS
        echo -e " --------------- --------------- -----"\\n
        echo -e "Prem [q] per sortir."\\n
        
    fi
else
    echo "$usageInvalidArg"; exit 1
fi