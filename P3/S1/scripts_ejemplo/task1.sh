#!/bin/sh

# Creadores: DANIEL BENAVENTE GARCIA Y CÉSAR GUTIÉRREZ BELMAR

#Acciones previas: Instalaccion tool ---> nmap
#Acceso: Usuario root.
#Forma de ejecución: ./task1.sh (si hay algún problema hay que darle permisos al archivo: chmod 777 task1.sh)
#Toda la información que extraemos del test del estado de la red será guardada en el fichero output1.out una vez sea ejecutado el punto 4 del menu del script.
#El fichero output1.out ya contiene un ejemplo de la ejecución.


#Este script está basado en 6 puntos, que explicaremos a continuación.
# OBJETIVOS OBLIGATORIOS
#1-En el primer punto printaremos la IP y mascara del host, la IP del router y los todos los servidores DNS en uso.
#2-En el segundo punto mostraremos el test de conectividad con el router, el servidor DNS y con un servidor externo a nuestra elección (en el ejemplo de ejecución
#encontramos la pagina web: www.google.com)

#OBJETIVO EXTRA
#3-En el tercer punto mostramos las maquinas que estan conecatadas actualmente a la red del host, en este punto podemos conseguirlo de dos formas,la básica,que trabaja
#solo con acks en la red, y en el modo avanzado, que trabaja además con las conexiones UPD, TCP y FTP. En los dos casos no conseguiremos solo las IPs de los host conectados
# sino que tambien veremos la direccion MAC de cada uno.

#MEJORAS
#4-En el cuarto punto tratamos toda la información del script y la guardamos el archivo output1.out como hemos dicho anteriormente.
#6-Por último, el punto 6 automatiza el script para que se ejecute cada x minutos en el sistema.



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
        echo " "
        IPRouter=$(ip route | grep default | cut -f3 -d ' ')
        echo "IP del router por defecto: $IPRouter"
        echo " "
        for DNSServer in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
              echo "IP del servidor DNS: $DNSServer "
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
        IP_router=$(ip route | grep default | cut -f3 -d ' ')
        Network=$(ipcalc -b $IP_router | grep Network | cut -d : -f2)
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
        echo "1 ---> IP Y MASCARA DEL HOST, IP DEL ROUTER Y DE LOS SERVIDORES DNS <--- 1" >> output1.out
        IPHost=$(nmcli | grep inet4 | cut -f2 -d ' ')
        echo "IP y mascara del HOST: $IPHost" >> output1.out
        IPRouter=$(ip route | grep default | cut -f3 -d ' ')
        echo "\nIP del router por defecto: $IPRouter \n" >> output1.out
        for DNSServer in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
              echo "IP del servidor DNS: $DNSServer" >> output1.out
        done
        echo " \n2 ---> RESULTADO DEL TEST DE CONECTIVIDAD CON EL ROUTER POR DEFECTO <--- 2" >> output1.out
        iprouter=$(ip route | grep default | cut -f3 -d ' ')
        ping -w 5 $iprouter >> output1.out
        echo " \n2 ---> RESULTADO DEL TEST DE CONECTIVIDAD Y SERVICIO CON EL SERVIDOR DNS<--- 2" >> output1.out
        cont=1
        for DNSServers in $(nmcli dev show | grep IP4.DNS | cut -d : -f2);do
                echo "Servidor DNS $cont " >> output1.out
                ping -w 5 $DNSServers >> output1.out
                echo " " >> output1.out
                cont=$((cont+1))
        done
        echo "\n2 ---> RESULTADO DEL TEST DE CONECTIVIDAD CON UN SERVIDOR EXTERNO, ESTE CASO [www.gooogle.com] <--- 2" >> output1.out
        IPdir="www.gooogle.com"
        ping -w 5 $IPdir >> output1.out
        echo "\n3 ---> DESCUBRIR CUANTAS MAQUINAS HAY EN LA RED, UTILIZADA LA BUSQUEDA BASICA <--- 3" >> output1.out
        Network=$(ipcalc -b $IPRouter | grep Network | cut -d : -f2)
        nmap -sn $Network >> output1.out
        echo "\n...su fichero se ha generado, Gracias."
        exit
    ;;
    5)  clear
        echo "Programa terminado"
        exit
    ;;
    6)  clear
        read -p "Escoge entre la opcion 1 (añadir/actualizar) y la 2 (borrar actual): " opcion
        case "${opcion}"
            in
            1)
            read -p "Escoge el intervalo de tiempo deseado en minutos (Escribe solo un numero -> Ejemplo: 5): " num
            read -p "Escribe el path donde se encuentra el script (Ejemplo: /home/Documents): " path
            $(touch crontab.fl)
            $(true > crontab.fl)
            echo "*/$num * * * * $path/task.sh >/dev/pts/1" >> crontab.fl
            usuario=$(echo $USER)
            $(crontab -u $usuario crontab.fl)
            $(rm crontab.fl)
            echo "El script se ejecutara de manera automatica cada $num minutos."
            echo " "
            ;;
            2)
            echo "La automatizacion del script ha sido eliminada correctamente."
            ;;
        esac
        read -p "Pulsa INTRO para volver al menu..." intro
    ;;
    *) echo "Error, elige un num entre 1-6"
        echo " "
        read -p "Pulsa INTRO..." intro
    ;;
    esac
done
exit
