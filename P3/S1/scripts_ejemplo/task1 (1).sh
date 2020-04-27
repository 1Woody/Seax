#!/bin/sh

while [ 0 -ne 1 ]; do
    clear
    echo "TEST DEL ESTADO DE LA RED"
    echo "IMPORTANTE: Instalar paquete nmap y ipcalc"
    echo "IMPORTANTE: Ejecutar el script como ROOT USER"
    echo " Opciones para seleccionar: "
    echo " 1 IP y mascara del host, IP del router y de los servidores DNS"
    echo " 2 Resultado del test de conectividad con el router, con el servidor DNS y con un servidor externo"
    echo " 3 Descubrir cuantas maquinas hay en la red"
    echo " 4 Generacion del fichero de salida (output)"
    echo " 5 Finalizar con el programa/script"
    echo " 6 Automatizar el programa"

    read -p "Selecciona un num y pulsa INTRO: " opcionDeseada

    case "${opcionDeseada}"
    in
    1) clear
        IPHost=$(nmcli | grep inet4 | cut -f2 -d ' ')
        echo "IP y mascara del HOST: $IPHost"
        #echo $IPHost
        echo " "
        IPRouter=$(ip route | grep default | cut -f3 -d ' ')
        #echo $IPRouter
        echo "IP del router por defecto: $IPRouter"
        echo " "
        for DNSServer in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
              echo "IP del servidor DNS: $DNSServer "
            	#echo $DNSServer
        done
        echo " "
        read -p "Pulsa INTRO para volver al menu..." intro
    ;;
    2) clear
        echo "Resultado del test de conectividad con el router por defecto"
        iprouter=$(ip route | grep default | cut -f3 -d ' ')
        ping -w 5 $iprouter
        echo " "
        echo "Resultado del test de conectividad y servicio con servidor DNS"
        cont=1
        for DNSServers in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
                echo "Servidor DNS $cont "
                ping -w 5 $DNSServers
                cont=$((cont+1))
        done
        echo " "
        echo "Resultado del test de conectividad con un servidor externo (cualquiera)"
        read -p "Inserta un dominio o una direccion IP para poder continuar: " IPdir
        ping -w 5 $IPdir
        echo " "
        read -p "Pulsa INTRO para volver al menu..." intro
    ;;
    3) clear
        echo "Descubrir cuantas maquinas hay en la red"
        Network=$(ipcalc -b 192.168.0.1/24 | grep Network | cut -d : -f2)
        read -p "Escoge entre la opcion 1 (basica) y la 2 (exhaustiva): " numOpcion
        case "${numOpcion}"
            in
            1) sudo nmap -sn $Network
            ;;
            2) sudo nmap -sn -PA21,22,25,3389 $Network
            ;;
        esac
        echo " "
        read -p "Pulsa INTRO para volver al menu..." intro
    ;;
    4) clear
        echo "Creando el fichero un momento..."
        $(touch output1.out)
        $(true > output1.out)
        IPHost=$(nmcli | grep inet4 | cut -f2 -d ' ')
        echo "IP y mascara del HOST: $IPHost" >> output1.out
        IPRouter=$(ip route | grep default | cut -f3 -d ' ')
        echo -e "\nIP del router por defecto: $IPRouter \n" >> output1.out
        for DNSServer in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
              echo "IP del servidor DNS: $DNSServer" >> output1.out
        done
        echo -e "\nResultado del test de conectividad con el router por defecto" >> output1.out
        iprouter=$(ip route | grep default | cut -f3 -d ' ')
        ping -w 5 $iprouter >> output1.out
        echo -e "\nResultado del test de conectividad y servicio con servidor DNS" >> output1.out
        cont=1
        for DNSServers in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
                echo "Servidor DNS $cont " >> output1.out
                ping -w 5 $DNSServers >> output1.out
                echo " " >> output1.out
                cont=$((cont+1))
        done
        echo -e "\nResultado del test de conectividad con un servidor externo, este caso [www.gooogle.com]" >> output1.out
        IPdir="www.gooogle.com"
        ping -w 5 $IPdir >> output1.out
        echo -e "\nDescubrir cuantas maquinas hay en la red, utilizada la busqueda basica" >> output1.out
        Network=$(ipcalc -b 192.168.0.1/24 | grep Network | cut -d : -f2)
        sudo nmap -sn $Network >> output1.out
        echo -e "\n...su fichero se ha generado, Gracias."
        exit
    ;;
    5)  clear
        echo "Programa terminado"
        exit
    ;;
    6)
        read -p "Escoge entre la opcion 1 (añadir/actualizar) y la 2 (borrar actual)" opcion
        case "${opcion}"
            in
            1)
            clear
            read -p "Escoge el intervalo de tiempo deseado en minutos (Escribe solo un numero -> Ejemplo: 5): " num
            read -p "Escribe el path donde se encuentra el script (Script incluido -> Ejemplo: /home/Documents/script.sh): " path

            path="/home/woody/Documents/INTE/task.sh"
            #numpath="$num * * * * $path"
            $(touch crontab.fl)
            $(true > crontab.fl)
            echo "$num * * * * $path" >> crontab.fl
            #$(cat crontab.fl)
            usuario=$(echo $USER)
            $(crontab -u $usuario crontab.fl)
            #$(rm crontab.fl)
            echo "El script se ejecutara de manera automatica cada $num minutos."
            echo " "
            ;;
            2)

            echo "La automatizacion del script ha sido eliminada correctamente."
            ;;
        esac
        read -p "Pulsa INTRO para volver al menu..." intro
    ;;
    *) echo "No es una opcion viable, elige un num entre 1-5"
        echo " "
        read -p "Pulsa INTRO para volver al menu..." intro
    ;;
    esac
done
