#!/bin/bash

interfacelist=$(ls /sys/class/net/ | grep ^e)

#llistaMACs --> cat /usr/share/nmap/nmap-mac-prefixes


# Creació de fitxers
touch .llistaEquips
true > .llistaEquips



for interface in "$interfacelist"
do 

    ipInterface=$(ip -4 addr show dev "$interface" | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
    #echo $ipInterface
    ipXarxa=$(ip r | grep "$ipInterface" | awk '{print $1}')
    ##echo $ipXarxa
    
    # comanda nmap
    echo "Escanejant la xarxa ..."
    nmap -sn "$ipXarxa" > .scan.log


    #llistaEquips
    cat .scan.log | grep -e "scan report for" -e "MAC" > .llistaEquips

    MACinterface="$(ip link show dev enp0s3 | grep ether | awk '{print $2}')"
    #echo $MACinterface
    MACinterface=${MACinterface^^}
    #echo $MACinterface
    MACfabricant="$(echo $MACinterface | cut -d ':' -f1,2,3 |sed "s/://g")"
    #echo $MACfabricant
    Nomfabricant=$(grep $MACfabricant /usr/share/nmap/nmap-mac-prefixes | sed -r 's/\s+/-/' | cut -d'-' -f2)
    #echo $Nomfabricant

    echo -e "MAC Address: $MACinterface ($Nomfabricant)" >> .llistaEquips

    counter=0
    infoEquip=""
    #Nmap scan report for 192.168.0.12
    #MAC Address: 70:26:05:FA:1B:56 (Unknown)

    #llistaEquips=$(cat .llistaEquips)
    #while IFS= read -r line; do
    #    echo "Text read from file: $line"
    #done < .llistaEquips


    echo -e "INICI FOR LOOP\n"
    while IFS= read -r line; do
        if [ $counter == 0 ] # tractament d'ips i DNS
        then
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
            fabricant=$(echo $line | awk '{print $4}' | cut -d '(' -f2 | cut -d ")" -f1)
            infoEquip="$ipCorrecta|$mac|$fabricant|$dns"
            echo "$infoEquip"
            counter=0
        fi
    done < .llistaEquips
done