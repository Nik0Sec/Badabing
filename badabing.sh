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


if [ $(id -u) -ne "0" ]; then
	
	echo "Tienes que ser root para ejecutar este script"
	echo "sudo ./script.sh" 
	exit

fi


regresarmenu(){


read -p "Quieres realizar otra operación?: " OP
if [ $OP == "S" ]; then
	clear
	menu
else
	echo "Adiós"
	exit

fi



}





tarjetaredmon=$(ifconfig | cut -d " " -f 1 | cut -d ":" -f 1 | xargs | awk '{print $3}' 2>/dev/null)
tarjetared=$(iwconfig wlan0 2>/dev/null | cut -d ' ' -f1 | xargs 2>/dev/null)

modomonitor(){

echo "Iniciando modo monitor..."
sleep 1
read -p "Es correcta esta tarjeta de red? ($brum) S/N: " TR
if [ $TR == "S" ]; then
	echo "Se procede con la ejecución del modo monitor"
	sleep 0.5
	sudo airmon-ng start $tarjetared 1>/dev/null
	sleep 3
	echo "Eliminando procesos conflictivos..."
	pkill dhclient && pkill wpa_supplicant
	sleep 0.5
	echo "Todo bien, verifica tu tarjeta de red con el comando iwconfig o ifconfig"
       	regresarmenu
	
else
	read -p "Especifica tu tarjeta de red: " boom
	sleep 0.5
	sudo airmon-ng start $boom
	sleep 3
	echo "Eliminando procesos conflictivos..."
	pkill dhclient && pkill wpa_supplicant
	sleep 1
	echo "Todo bien, verifica tu tarjeta de red con el comando iwconfig o ifconfig"
	regresarmenu
fi


}

killmonitor(){
echo " "	
echo "Regresando" $tarjetared "a su estado original"
	sudo airmon-ng stop $tarjetared
sleep 1
echo "Hecho..." 
}

enumclient(){

echo "Escaneando puntos de acceso"
sleep 0.6

sudo xterm -hold -title 'Cierra la ventana cuando encuentres tu objetivo' -geometry 107+0+0 -bg '#000000' -fg '#FFFFFF' -e 'airodump-ng -w "usuarios" wlan0mon'


sleep 1

echo " "

cat -n usuarios-01.csv | perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' | column -t -s, | awk -F" " '{ if ($19>1) { print } }'

#nmcli dev wifi list ifname wlan0mon

read -p "Ingresa el BSSIDi"

regresarmenu
}



menu(){

banner
echo " "
if [ "$tarjetared" != "wlan0" ]; then 
	echo "Tu tarjeta de red es: $tarjetaredmon"
       	echo " " 	
elif [ "$tarjetaredmon" != "wlan0mon" ]; then
	echo "Tu tarjeta de red es: $tarjetared"
	echo " " 
else
	echo "Tu tarjeta de red es: ¯\_(ツ)_/¯"
       	echo " " 	
fi
echo -e "${Rojo}Escoge la operación que deseas realizar:${Nada}\n"
echo "[1] Iniciar modo monitor y matar procesos conflictivos"
echo "[2] Regresar tarjeta de red a su estado original"
echo "[3] Spoofing dirección MAC"
echo "[4] De-autenticación de usuario para obtener handshake"
echo " "
read -p "Ingresa el número: " eleccion

case $eleccion in

	1)
	modomonitor;;
	2)
	killmonitor;;
	3)
	spoofmac;;
	4)
	enumclient;;
	*)
	echo "Opción inválida"
	sleep 0.5
	echo "Saliendo..."
	exit;;
esac

}

menu 


