#!/bin/bash
#!utf-8
IP=$(hostname -I | cut -d ' ' -f1)
filter_icmp="'not src "$IP" && icmp'"
filter_tcp="tcp[13]=2 && port "$3""
#array+=("10:33-10.0.0.1-22-1")
array+=("")
add=0

echo "" > test.log
if [ $# == 3 ]
then
    echo -e "ÚLTIM ACCÈS REGISTRAT" > test.log 
    if [ $2 == "TCP" ]
    then
        tcpdump -l -q -nni "$1" "$filter_tcp" 2>/dev/null >> /root/test.log &
        pidtcpdump=$!
    
    elif [ $2 == "UDP" ]
    then 
        tcpdump -l -q -nni "$1" udp port "$3" 2>/dev/null >> /root/test.log &
        pidtcpdump=$!
    elif [ $2 == "ICMP" ]
    then
        echo INSIDE
        tcpdump -l -q -nni enp0s3 '(not src 192.168.0.26) and (icmp)' 2>/dev/null >> /root/test.log &
        #$(tcpdump -l -q -nni "$1" "$filter_icmp" 2>/dev/null >> /root/test.log &)
        # tcpdump -l -q -nni enp0s3 'not src "$IP" && icmp'
        #$pidtcpdump
    else
        echo NO PROTOCOL
    fi
    quit=0
    echo -ne " I'm reading your file ...\n"
    while [ $quit != 1 ]
    do
        read -t 0.25 -N 1 input
        if [[ $input = "q" ]]
        then
            echo -e "\r"
            kill "$pidtcpdump"
        fi
        hora=$(awk '/./{if(NR==2) print $1}' test.log)
        ip_a=$(awk '/./{if(NR==2) print $3}' test.log | cut -d '.' -f1,2,3,4)
        puerto=$(awk '/./{if(NR==2) print $3}' test.log | cut -d '.' -f5)
        #acceso=$(awk '/./{if(NR==2) print $1,$3}' test.log | cut -d '.' -f1,2,3,4,5 && awk '/./{if(NR==2) print $3}' test.log | cut -d '.' -f5)
        if [ "$hora" != "" ]
        then
            acceso1="$hora-$ip_a-$puerto"
            if [ "${array[0]}" == "" ]
            then
                acceso1="$acceso1-1"
                array[0]="$acceso1"
            else
                for i in "${!array[@]}"
                do
                    ip_in=$(echo "${array[$i]}" | cut -d '-' -f2)
                    echo "$ip_a"
                    echo "$ip_in"
                    if [ "$ip_a" == "$ip_in" ]
                    then
                        aux_v=$(echo "${array[$i]}" | cut -d '-' -f1,2,3)
                        counter=$(echo "${array[$i]}" | cut -d '-' -f4 | awk '{print $0+1}')
                        new_ac="$aux_v-$counter"
                        array[$i]="$new_ac"
                        add=1
                        break
                    fi
                done
                echo $add
                if [ "$add" != 1 ]
                then
                        acceso1="$acceso1-1"
                        array+=($acceso1)
                fi
                add=0
            fi
            echo -e "ÚLTIM ACCÈS REGISTRAT" > test.log
            echo ------ARRAY-------
            for i in "${!array[@]}"
            do
                printf 'array[%s]=%s\n' "$i" "${array[$i]}"
            done
        fi
        sleep 1
    done
    for i in ${!array[@]}
    do
        printf '${array[%s]}=%s\n' "$i" "${array[$i]}"
    done
    kill "$pidtcpdump"
else
    echo No hay argumentos suficientes; exit 1
fi 