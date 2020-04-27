#!/bin/bash

# ports --> https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers

invalidarguments='El nombre de arguments és incorrecte. Han de ser 3 arguments (revisar manual de usuari)'
interfaces= basename -a /sys/class/net/*
usage='Usage: honeypot.sh'

#detecció de la correctesa dels arguments d'entrada --> ./honeypot.sh eth0 tcp 80
if [ $# == 3 ]
then
    # Comprovació del port
    if [[ ! $3 =~ ^[0-9]+$ ]] 
    then
        echo "Recorda, l'argument del port ha de contenir un nombre enter."; 
        echo $usage1; exit 1
    elif [ "$3" -gt "65535" ] || [ "$3" -lt "0" ]
    then
        echo "Compte! El port s'ha de trobar entre el 0 i el 65535 (ports disponibles).";
        echo $usage; exit 1    
    # Comprovació del protocol
    elif [ "$2" != "TCP" ] && [ "$2" !="UDP" ] && [ "$2" != "ICMP" ]
    then
        echo "El protocol escollit no està permés. Recorda que ha de ser TCP, UDP o ICMP." 
        echo $usage; exit 1
    else
        i=0
        for interface in $(ls /sys/class/net/); do # basename -a /sys/class/net/*
            if [ "$interface" == "$1" ]
            then
                ((i=i+1))
                echo $i
            fi
        done
        if [ cont != 1 ]
        then 
            echo "La interfície no és vàlida o no es troba al sistema."
            echo $usage; exit 1
        fi
        #
        #
        #
        #
        #
        # CÓDIGO DEL SCRIPT (SIN ERRORES DE ARGUMENTOS)
        #
        #
        #
        #
        #
    fi
else
    echo $invalidarguments; 
    echo $usage; exit 1
fi