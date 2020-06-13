#!/bin/bash
#!utf-8

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
                if [ "$protocolMajus" == "ICMP" ]
                then
                    arrayICMPAtacs[0]="$ipNouAtac"
                fi
            # Cas bucle
            else
                # Cas ICMP recollir repetits en un timestamp de 1s
                if [ "$protocolMajus" == "ICMP" ]
                then 
                    if [ "${arrayICMPAtacs[0]}" == "" ]
                    then
                        arrayICMPAtacs[0]="$ipNouAtac"
                    else 
                        for pos in "${!arrayICMPAtacs[@]}"
                        do
                            if [ "${arrayICMPAtacs[$pos]}" == "$ipNouAtac" ]
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
                if [ $tractament == 1 ]
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
        clear
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
        ipAcces=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f2 )
        numAccessos=$( echo "${arrayAtacs[$each]}" |cut -d '-' -f4 )
        {
            printf "%16.16s %13.13s \\n" " $ipAcces" "$numAccessos"
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
        horaAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f1 )
        ipAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f2 )
        portAcces=$( echo "${arrayFullAtacs[$each]}" |cut -d '-' -f3 )
        printf "%16.16s %15.15s %5.5s \\n" " $horaAcces" "$ipAcces" "$portAcces"  >> log_honeypot
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

        clear
        cat log_honeypot

        if [ "${arrayFullAtacs[0]}" != "" ]
        then
            # Elecció de temps en funció del protocol
            if [ "$protocolMajus" == "ICMP" ]
            then
                sleep 3;
            else
                sleep 1;
            fi
        fi
    fi
done
exit 0