#!/bin/bash
p=0
n=0
n_d=0
last_log=0
usage1='Usage: bash_baduser42.sh [-p] or [-t]'
usage2='Usage: bash_baduser42.sh'
# detecció de opcions d'entrada: només son vàlids: sense paràmetres i -p
if [ $# -ne 0 ]; then
    if [ $1 == "-p" ]; then
        p=1
    elif [ $1 == "-t" ]
    then
        p=2
        n=$(echo $2 | tr -dc '0-9')
        n_d=$(echo $2 | tr -dc 'a-z')
    else
        echo $usage1; exit 1
    fi
else
    echo $usage2; exit 1
fi

# afegiu una comanda per llegir el fitxer de password i només agafar el 
# 3camp de # nom de l'usuari
for user in $(cat /etc/passwd | grep : | cut -d : -f1); do
    n=0
    home=`cat /etc/passwd | grep "^$user\>" | cut -d: -f6`
    if [ -d $home ] && [ $home != "/" ] && [ $home != "/proc" ]; then
        num_fich=`find $home -type f -user $user | wc -l`
    else
        num_fich=0
    fi
    
    if [ $num_fich -eq 0 ]; then
        if [ $p -eq 1 ]; then
            # afegiu una comanda per detectar si l'usuari te processos en execució, 
            # si no te ningú la variable $user_proc ha de ser 0
            user_proc=$(($(ps -u $user | wc -l)-1))
            
            if [ $user_proc -eq 0 ]; then
                  echo "$user"
            fi
        elif [ $p -eq 2 ]
        then
            user_proc=$(($(ps -u $user | wc -l)-1))
            
            if [ $user_proc -eq 0 ]; then
                if [ $n_d == "m" ]; then
                    n=$((n*30))
                fi
                last_log=`lastlog -u $user -t $n`
                if [ -z "$last_log" ] && [ $home != "/" ] && [ $home != "/proc" ]; then
                    num=`find $home -type f -user $user -mtime $n | wc -l`
                    if [ $num -eq 0 ]; then
                    usr="inactive user: $user"
                    echo $usr
                    fi
                fi
            fi
        else 
            pot="---"
            echo "$user"
        fi
    fi    
done