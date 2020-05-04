#!/bin/bash
#!utf-8
# Elegir bien los PERMISOS!!!
# COMPROBAR LO QUE NECESITA EL USUARIO (PAQUETES, ROOT ...)

####### 1. VARIABLES #######

# Variables usage per les notificacions d'error
usageInvalidArg="El nombre de arguments és incorrecte. Han de ser 2 o 3 arguments (revisar manual de usuari)."
usagePortEnter="Recorda, l'argument del port ha de contenir un nombre enter."
usagePortRang="Compte! El port s'ha de trobar entre el 0 i el 65535 (ports disponibles)."
usageProtocolInc="El protocol escollit no està permés. Recorda que ha de ser TCP, UDP ."
usageInterficieInc="La interfície no és vàlida o no es troba al sistema."
usageICMP="En cas d'escriure dos arguments, recorda que el protocol ha de ser l'ICMP."
usageTCPUDP="Recorda que en cas de seleccionar el protocol TCP o UDP has d'especificar un port."
usageSuperUser="Has de ser root per executar aquest script"
usagePaquetcpdump="Has de tenir instalat el paquet de tcpdump, instala-ho amb: apt install tcpdump"
usagePaquetip="Has de tenir instalat el paquet de iproute, instala-ho amb: apt install iproute2"
usageExecucio="No s'ha pogut inicialitzar la captura de paquets. Sembla que el sistema operatiu té algún tipus d'incompatibilitat amb tcpdump."
usageIP="Sembla que no tens cap IP(v4) assignada en aquesta interfície."

# Variables per les comprovacions dels paràmetres inicials
i=0
quit=0
PR="$2"
protocolMajus=${PR^^}
protocolMinus=${PR,,}
interfaceActual="$1"
interfacesLlista=$(ls /sys/class/net/)

# Variables de característiques necessaries per l'script
usuari=$(whoami)
SO=$(cat /etc/*release 2>/dev/null | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-04-25"
myIP=""
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)

# Variables filtre tcpdump
filter_tcp="tcp[13]=2 and port $3"

# Variables utilitzades en el core del programa
revisat=0
tractament=1
primerCop=1
numAccesosSimultanis=11 # Establiment dels accessos màxims (X accessos + 1 de capçalera)
comptLinia=2
arrayAtacs+=("") # Array amb comptador de repetició
arrayFullAtacs+=("") # Array amb tots els atacs (sense tenir en compte repeticions)
arrayICMPAtacs+=("") # Array amb les ips repetides dels atacs en una lectura (cas ICMP)
repetit=0
primeraHora="0 atacs rebuts"
ultimaHora="0 atacs rebuts"

####### 2. COMPROVACIONS PREVIES #######

# Comprovació del superusuari
if [ "$(whoami)" != "root" ]
then
	echo "$usageSuperUser"; exit 1
fi

# Comprovació del paquet tcpdump
if [ "$(dpkg -l | grep -c tcpdump)" -eq 0 ]
then 
	echo "$usagePaquetcpdump"; exit 1
fi

# Comprovació del paquet iproute2
if [ "$(dpkg -l | grep -c iproute2)" -eq 0 ]
then 
	echo "$usagePaquetip"; exit 1
fi

# Detecció de la correctesa dels arguments d'entrada
if [ $# == 2 ]
then 
    #cas ICMP sense port
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
# Comprovació interfície
for interface in $interfacesLlista; do
    if [ "$interface" == "$interfaceActual" ]
    then
        ((i+=1))
    fi
done
if [ "$i" != 1 ]
then 
    echo "$usageInterficieInc"; exit 1
else
    # Comprovació de si l'usuari té una IP assiganda a l'interfície
    myIP=$(ip -4 addr show dev "$1" | grep inet | awk '{print $2}' | cut -d '/' -f1 | head -n 1)
    if [ -z "$myIP" ]
    then 
        echo "$usageIP"; exit 1
    fi
fi

####### 3. CREACIÓ DE FITXERS NECESSARIS #######

touch log_honeypot
touch atacs.log

#inicialització capçalera del fitxer d'atacs
true > log_honeypot
echo -e "ÚLTIM ACCÈS REGISTRAT" > atacs.log


####### 4. MONITORITZACIÓ DE PAQUETS #######

if [ "$protocolMajus" == "TCP" ]
then
    tcpdump -l -q -nni "$interfaceActual" dst "$myIP" and "$filter_tcp" 2>log_honeypot >> atacs.log &
    pidtcpdump=$!
elif [ "$protocolMajus" == "UDP" ]
then 
    tcpdump -l -q -nni "$interfaceActual" dst "$myIP" and port "$3" and udp 2>log_honeypot >> atacs.log &
    pidtcpdump=$!
else
    tcpdump -l -q -nni "$interfaceActual" dst "$myIP" and icmp 2>log_honeypot >> atacs.log &
    pidtcpdump=$!
fi
# Comprovació d'errors en l'execució de la comanda tcpdump
sleep 0.3
tcpdumpgood=$(grep -c -e "tcpdump: verbose output suppressed, use -v or -vv for full protocol decode" -e "listening on $1" log_honeypot)
true > log_honeypot
if [ "$tcpdumpgood" -ne 2 ]
then
    echo "$usageExecucio"; exit 1
fi

####### 5. TRACTAMENT D'ATACS #######

while [ $quit != 1 ]
do
    # Bucle de lectura del fitxer d'atacs
    while [ "$comptLinia" -le "$numAccesosSimultanis" ]
    do
        # Recollida de dades dels atacs
        hora=$(awk -v line=$comptLinia '/./{if(NR==line) print $1}' atacs.log)
        ipNouAtac=$(awk -v line=$comptLinia '/./{if(NR==line) print $3}' atacs.log | cut -d '.' -f1,2,3,4)
        port=$(awk -v line=$comptLinia '/./{if(NR==line) print $3}' atacs.log | cut -d '.' -f5)
        # Inici tractament de dades
        if [ "$hora" != "" ] && [ "$ipNouAtac" != "" ]
        then
            atacActual="$hora-$ipNouAtac-$port"
            # Cas inicial
            if [ "${arrayAtacs[0]}" == "" ] && [ "${arrayFullAtacs[0]}" == "" ]
            then
                # Guardat de l'hora del primer accés
                primeraHora=$hora
                ultimaHora=$hora
                arrayFullAtacs[0]="$atacActual"
                atacActual="$atacActual-1"
                arrayAtacs[0]="$atacActual"
            # Cas bucle
            else
                if [ "$protocolMajus" == "ICMP" ]
                then 
                    if [ "${arrayICMPAtacs[0]}" == "" ]
                    then
                        arrayICMPAtacs[0]="$ipNouAtac"
                    else 
                        for pos in "${!arrayICMPAtacs[@]}"
                        do
                            if [ "${arrayAtacs[$pos]}" == "$ipNouAtac" ]
                            then
                                revisat=1
                                break
                            fi
                        done
                        if [ $revisat == 0 ]
                        then
                            arrayICMPAtacs+=("$ipNouAtac")
                        else 
                            tractament=0;
                        fi
                        revisat=0
                    fi
                fi
                # Guardat de l'hora de l'últim accés
                if [ $tractament ]
                then
                    ultimaHora=$hora
                    arrayFullAtacs+=("$atacActual")

                    # Bucle de verificació d'atacs repetits
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
                        arrayAtacs+=("$atacActual")
                    fi
                    repetit=0
                fi
                tractament=1 
            fi
            ((comptLinia+=1))
        else
            # Finalització de la lectura, ja que no hi ha res al fitxer 
            comptLinia=$((numAccesosSimultanis + 2))
        fi
    done
    unset arrayICMPAtacs # buidem l'array d'IP per la seguent lectura del fitxer
    
    # Inicialització de lectura de línia (2 per tenir en compte la capçalera) i neteja del fitxer
    comptLinia=2
    echo -e "ÚLTIM ACCÈS REGISTRAT" > atacs.log 

    ####### 6. MAQUETACIÓ DE DADES #######

    true > log_honeypot
    read -r -t 0.01 -N 1 input
    if [[ $input = "q" ]]
    then
        # Tractament del cas de que l'usuari polsi la 'q' (tancar el programa)
        kill "$pidtcpdump"
        true > log_honeypot
        dataCompilacioFi=$(date --rfc-3339=date)
        horaCompilacioFi=$(date | cut -d ' ' -f5)
        quit=1
        exec 1<>log_honeypot
        echo -e "----------------------------------------------------------------------------------------------------------"
        echo -e "Monitorització realitzada per l'usuari $usuari de l'equip $host."
        echo -e "Sistema operatiu $SO."
        echo -e "Versió del script $scriptVersion compilada el $dataInicial."
        echo -e "Monitorització iniciada en data $dataCompilacioInici a les $horaCompilacioInici i finalitzada en data $dataCompilacioFi a les $horaCompilacioFi."
        echo -e "----------------------------------------------------------------------------------------------------------"
    fi
    {
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
    } >> log_honeypot
    for each in "${!arrayAtacs[@]}"
    do 
        # Tractament del format d'escriptura del resum dels accessos
        espaiBlancIP=" ";
        ipAcces=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f2 )
        numAccessos=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f4 )
        x=7;
        trobat=0;
        while (( x <= 15 )) && (( !trobat ))
        do
            # Tractament de l'espai assignat a les adreces IP
            if [ "${#ipAcces}" == "$x" ] 
            then
                num=15-$x;
                for ((y=0; y<num; y++))
                do
                    espaiBlancIP=" $espaiBlancIP"; 
                done
                trobat=1;
            else
                ((x+=1))
            fi
        done
        stringResum="$espaiBlancIP$ipAcces"
        espaiBlancAccessos="   ";
        x=0;
        trobat=0;
        while (( x <= 11 )) && (( !trobat))
        do
            # Tractament de l'espai assignat al número d'accessos
            if [ "${#numAccessos}" == "$x" ]
            then
                num=11-$x;
                for ((y=0; y<num; y++))
                do
                    espaiBlancAccessos=" $espaiBlancAccessos";
                done
                trobat=1;
            else
                ((x+=1))
            fi
        done
        stringResum="$stringResum$espaiBlancAccessos$numAccessos"
        {
            echo "$stringResum"
        } >> log_honeypot
    done
    {
        echo -e " ---------------   -----------        "
        echo -e "                                      "
        echo -e "--------------------------------------"
        echo -e "Evolució dels accessos                "
        echo -e "--------------------------------------"
        echo -e "      Temps         Adreça IP     Port"
        echo -e " --------------- --------------- -----"
    } >> log_honeypot
    for each in "${!arrayFullAtacs[@]}"
    do
        # Tractament del format d'escriptura de la evolució dels accessos
        espaiBlancIP=" ";
        horaAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f1 )
        ipAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f2 )
        portAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f3 )
        x=7;
        trobat=0;
        while (( x <= 15 )) && (( !trobat ))
        do
            # Tractament de l'espai assignat a les adreces IP
            if [ "${#ipAcces}" == "$x" ] 
            then
                num=15-$x;
                for ((y=0; y<num; y++))
                do
                    espaiBlancIP=" $espaiBlancIP"; 
                done
                trobat=1;
            else
                ((x+=1))
            fi
        done
        stringResum=" $horaAcces$espaiBlancIP$ipAcces"
        espaiBlancPort=" ";
        x=0;
        trobat=0;
        while (( x <= 5 )) && (( !trobat))
        do
            # Tractament de l'espai assignat als ports
            if [ "${#portAcces}" == "$x" ]
            then
                num=5-$x;
                for ((y=0; y<num; y++))
                do
                    espaiBlancPort=" $espaiBlancPort";
                done
                trobat=1;
            else
                ((x+=1))
            fi
        done
        stringResum="$stringResum$espaiBlancPort$portAcces"
        echo "$stringResum" >> log_honeypot
    done
    {
        echo -e " --------------- --------------- -----"
        echo -e "                    "
    } >> log_honeypot
    if [ $quit != 1 ] 
    then
        # Accions a realitzar en cas de que l'usuari no vulgui tancar el programa.
        echo -e "Prem [q] per sortir." >> log_honeypot
        echo -e " " >> log_honeypot
        if [ $primerCop == 1 ]
        then
            primerCop=0
        else
            sleep 1;
            clear
        fi
        cat log_honeypot
    fi
done
rm atacs.log
exit 0
