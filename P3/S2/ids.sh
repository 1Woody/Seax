#!/bin/bash
#!utf-8

usuari=$(whoami)
SO=$(cat /etc/*release 2>/dev/null | grep 'PRETTY_NAME' | cut -d '"' -f2)
host=$(hostname)
scriptVersion="1.0"
dataInicial="2020-04-30"
dataCompilacioInici=$(date --rfc-3339=date)
horaCompilacioInici=$(date | cut -d ' ' -f5)

echo -e ""
echo -e "Programa de cerca automàtica d'equips a la xarxa actual"
echo -e " Versió $scriptVersion compilada el $dataInicial."
echo -e " Iniciant-se el $dataCompilacioInici a les $horaCompilacioInici ...          [ok]"
echo -e " El fitxer log_ids sera sobrescrit...                  [ok]"

echo -e " Detecció d'equips en curs...                          [ok]"

echo -e " Processant les dades...                               [ok]"

dataCompilacioFi=$(date --rfc-3339=date)
horaCompilacioFi=$(date | cut -d ' ' -f5)

echo -e " Resultats de l'anàlisi en el fitxer log_ids           [ok]"
echo -e " Finalitzat el $dataCompilacioFi a les $horaCompilacioFi             [ok]"
echo -e ""

{
echo -e "----------------------------------------------------------------------------------------------------------"
echo -e "Detecció dels equips de la xarxa local realitzada per l'usuari $usuari de l'equip $host."
echo -e "Sistema operatiu $SO."
echo -e "Versió del script $scriptVersion compilada el $dataInicial."
echo -e "Monitorització iniciada en data $dataCompilacioInici a les $horaCompilacioInici i finalitzada en data $dataCompilacioFi a les $horaCompilacioFi."
echo -e "----------------------------------------------------------------------------------------------------------"

echo -e "---------------------------------------------------------------------------------------------------------"
echo -e "S'han detectat $$ equips a les subxarxes $$ "
echo -e "---------------------------------------------------------------------------------------------------------"
echo -e " Adreça IP   Adreça MAC         Fabricant MAC                  Equip conegut     Nom DNS"
} >> log_ids





