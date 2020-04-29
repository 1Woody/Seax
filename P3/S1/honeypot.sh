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
arrayResum=("      10.1.1.105             2" "      10.1.1.108             2" "      10.1.1.105             2" "      10.1.1.105             2")
arrayEvol=(" 17:33:30.806049      10.1.1.108 51006" " 17:33:41.596338      10.1.1.105 40690" " 17:33:43.926395      10.1.1.105 40692" " 17:33:50.541803      10.1.1.108 51008")
quit=0

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
        tput sc; 
        while [ $quit != 1 ]
        do
            echo -n "" > log_honeypot
            tput ed;
            read -r -t 0.01 -N 1 input
            if [[ $input = "q" ]]
            then
                quit=1
                exec 1<>log_honeypot
                echo -n ""
                echo -e "----------------------------------------------------------------------------------------------------------"
                echo -e "Monitorització realitzada per l'usuari root de l'equip raspberrypi."
                echo -e "Sistema operatiu Raspbian GNU/Linux 10 (buster)."
                echo -e "Versió del script 0.112 compilada el 22/03/2020."
                echo -e "Monitorització iniciada en data 2020-03-25 a les 17:32:21 i finalitzada en data 2020-03-25 a les 17:55:00."
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
            for each in "${arrayResum[@]}"
            do 
                echo "$each"
            done
            echo -e " ---------------   -----------"
            echo -e ""
            echo -e "--------------------------------------"
            echo -e "Evolució dels accessos"
            echo -e "--------------------------------------"
            echo -e "      Temps         Adreça IP     Port"
            echo -e " --------------- --------------- -----"
            for each in "${arrayEvol[@]}"
            do
                echo "$each"
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
    fi
else
    echo "$usageInvalidArg"; exit 1
fi
exit 0