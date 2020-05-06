#!/bin/bash

interfacelist=$(ls /sys/class/net/ | grep ^e)

#llistaMACs --> cat /usr/share/nmap/nmap-mac-prefixes

# MOVER AL BUENO

# --> echo de lista de inteficies, linia fabricant y creo que ya


# Creació de fitxers
touch .llistaEquips
touch .llistainterfaces
true > .llistainterfaces
true > .llistaEquips
true > test.log


for interface in $(ls /sys/class/net/ | grep ^e)
do 
    echo $interface

    ipInterface=$(ip -4 addr show dev "$interface" | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
    #echo $ipInterface
    ipXarxa=$(ip r | grep "$ipInterface" | awk '{print $1}')
    
    echo "$interface $ipXarxa" >> .llistainterfaces
    
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
    Nomfabricant=$(grep "$MACfabricant" /usr/share/nmap/nmap-mac-prefixes | cut -d ' ' -f2-)
    #echo $Nomfabricant

    echo -e "MAC Address: $MACinterface ($Nomfabricant)" >> .llistaEquips

    counter=0
    infoEquip=""

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
            equipConegut=$(cat equips_coneguts | grep "$mac" | cut -d ' ' -f2-)
            if [ "$equipConegut" == "" ]
            then 
                equipConegut="-"
            fi
            fabricant=$(echo $line | cut -d '(' -f2 | cut -d ')' -f1)
            infoEquip="$ipCorrecta|$mac|$fabricant|$equipConegut|$dns"
            echo "$infoEquip" >> test.log
            counter=0
        fi
    done < .llistaEquips
done