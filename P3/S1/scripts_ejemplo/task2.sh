#!/bin/sh
#Acceso: Usuario root.
#Forma de ejecución: ./task2.sh
#Toda la información que extraemos de las páginas web será guardada en el fichero llista_webs.out una vez sea ejecutado el script.
#Aclaraciones
#Punto 2 ->
#Servicio de hosting/cloud: Un servidor cloud es una potente infraestructura virtual o física que almacena y procesa un gran número de información
#y aplicaciones. Hoy en día cualquier página web que esté medio actualizada utiliza este tipo de hosting, ya que así funciona formando un sistema
#distribuido y guarda la información de manera mucho más segura y no dependiendo solo de su propio almacenamiento. Además dispone de otras muchas
#ventajas como la rentabilidad (gastas lo que utilizas) o la escalabilidad (gran posibilidad de aumentar sin problemas tu almacenamiento).
#Son ejemplos de servidores cloud el A2 Hosting, HostGator o DreamHost.
#Punto 3 ->
#Sistema Operativo: No podemos conocer el sistema operativo de la página web ya que depende del servidor web que utiliza, y aún conociendo este,
#puede variar según la organización o usuario que lo mantenga. En los casos por ejemplo de Nginx (atenea.upc.edu, ara.cat, ...) pueden trabajar con BSD,
#HP-UX, Solaris, Windows, etc. Por otro lado google.com utiliza GWS y al no ser de dominio público no encontramos mucha información al respecto.
#Punto 4 ->
#Ultima fecha de modificacion: Para la mayoría de páginas web de hoy en día, esta fecha se encuentra restringida en la descarga de su archivo html.
#Hemos añadido una página antigua (museusdesitges.cat) donde podemos ver como se muestra esa fecha.

$(true>llista_webs.out)
echo "1. NOMBRE DE LA PAGINA" >> llista_webs.out
echo >> llista_webs.out
while IFS= read -r line
do
  echo "Servidores DNS [$line]: " >> llista_webs.out
  echo "$(dig +short ns $line)\n" >> llista_webs.out
done < llista_webs.in

echo "\n2. HOSTING" >> llista_webs.out
while IFS= read -r line
do
    echo "\nServidor Web [$line]: " >> llista_webs.out
    echo "IP real: $(dig +short $line | tail -n1)" >> llista_webs.out
    echo "Nombre real del servidor: $(dig +short ns $line | head -n 1)" >> llista_webs.out
    echo "Utiliza un servicio de hosting/cloud de terceros\n" >> llista_webs.out
done < llista_webs.in

echo "\n3. SERVIDOR WEB" >> llista_webs.out
$(touch aux.txt)
ishttps=0
while IFS= read -r l1
do
    $(true>aux.txt)
    echo "\nServidor web [$l1]: " >> llista_webs.out
    wget $l1 --server-response -o aux.txt
    echo "Sistema operativo: Not identified" >> llista_webs.out
    echo "Software del servidor: $(cat aux.txt | grep Server: | tail -1 | cut -d ' ' -f4)" >> llista_webs.out
    echo "HTTP version: $(cat aux.txt | grep '200 OK' | tail -1 | cut -d ' ' -f3)" >> llista_webs.out

    point=$(echo $l1)
    redirect=""
    echo "Redirecciones:" >> llista_webs.out
    while read -r l2
    do
        Location=$(echo $l2 | grep "Location" | wc -l)
        if [ $Location -ne 0 ];then
            redirect=$(echo "$l2" | cut -d ' ' -f2)
            echo "$point ----> $redirect" >> llista_webs.out
            point=$(echo $redirect)
            Location=$(echo $Location | grep "https" | wc -l)
            if [ $Location -ne 0 ];then
                ishttps=1
            fi
        fi
    done < aux.txt
    if [ $ishttps -ne 0 ];then
        echo "Esta pagina solo es accesible por HTTPS" >> llista_webs.out
        ishttps=0
    fi
done < llista_webs.in
# Comenta estas instrucciones para no borrar los archivos de las paginas, ni el log auxiliar usado.
$(rm aux.txt)
$(rm index.html)
$(rm *.html.*)

echo "\n\n4. CONTENIDO" >> llista_webs.out
$(touch aux.txt)
while IFS= read -r l4
do
	echo "\nPágina web < $l4 >:" >> llista_webs.out
	wget $l4 --spider --server-response -o aux.txt
	file_size=0
	file_size=$(cat aux.txt | awk '/Content-Length:/ {print $2}' | tail -1)
  if [ -z "$file_size" ]
  then
    echo "Tamaño del fichero: Not Known" >> llista_webs.out
  else
    if [ $file_size -eq 0 ]
    then
      echo "Tamaño del fichero: Not Known" >> llista_webs.out
    else
      echo "Tamaño del fichero: $file_size bytes" >> llista_webs.out
    fi
  fi
  file_type=$(cat aux.txt | awk '/Content-Type:/ {print $2, $3}' | tail -1)
  echo "Tipo de contenido: $file_type" >> llista_webs.out
  last_modified=$(cat aux.txt | awk '/Last-Modified:/ {print $3, $4, $5, $6, $7}' | tail -1)
  if [ -z "$last_modified" ]
  then
    echo "Última actualitzación: Not Especified" >> llista_webs.out
  else
    echo "Última actualitzación: $last_modified" >> llista_webs.out
  fi
  cache=$(cat aux.txt | awk '/Cache-Control:/' | cut -d : -f2 | tail -1)
  echo "Control de cache:$cache" >> llista_webs.out
	$(rm aux.txt)
done < llista_webs.in
exit
