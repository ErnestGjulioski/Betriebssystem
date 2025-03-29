#!/bin/bash

BLUE='\e[34m'
RESET='\e[0m'
RED='\e[31m'


# Anleitung:
usage() {
    echo "---------------------------------------------------------------------------"
    echo -e "Verwendung: $0 ${BLUE}[-c | --command] [-u | --user] [-h | --help]${RESET}"
    echo "---------------------------------------------------------------------------"
    echo
    echo "  -c |--command  Zeigt nur den Command aus"
    echo
    echo "  -u |--user     Zeigt nur die Benutzer-ID mit Port"
    echo
    echo "  -h |--help     Zeigt diese Hilfemeldung an"
    echo
    echo "---------------------------------------------------------------------------"
    exit 0
}





# Standardoption
option="command"

case "$1" in

    -c|--command) option="command" ;;

    -u|--user) option="user" ;;

    -h|--help) usage ;;

    "" ) ;; 
    # Falls kein Argument übergeben wird, wird die Standardoption verwendet
    *) echo -e "${RED}Fehler: Ungültige Option '$1'${RESET}";
    
     usage ;;
esac


# Extrahiert die eindeutigen TCP-Ports aus der Ausgabe von ss -tuln 
# indem nur die Verbindungen mit tcp gefiltert werden, die Ports aus der 
# Spalte Local Address:Port extrahiert und Duplikate entfernt werden.
ports=$(ss -tuln | grep -w 'tcp' | awk 'NR>1 {split($5, a, ":"); print a[length(a)]}' | sort -u)




if [ -z "$ports" ]; then
    echo "Keine Ports gefunden"
    exit 0
fi



# Header
if [ "$option" == "user" ]; then
    echo "------------------------"
    printf "${BLUE}%-8s %-8s\n${RESET}" "Port" "User-ID"
    echo "------------------------"
elif [ "$option" == "command" ]; then
    echo "---------------------------------------------------------------"
    printf "${BLUE}%-8s %-50s\n${RESET}" "Port" "Command"
    echo "---------------------------------------------------------------"
fi




# Ports durchgehen
for port in $ports; do
    pid=$(lsof -iTCP:$port -sTCP:LISTEN -t | head -n 1)

#Print für Command -c und User -u
    if [ -z "$pid" ]; then
        if [ "$option" == "command" ]; then
            printf "%-8s %-50s\n" "$port" "root"
            echo "---------------------------------------------------------------"
        elif [ "$option" == "user" ]; then
            printf "%-8s %-8s\n" "$port" "0"
            echo "------------------------"
        fi
        continue
    fi

# Holt die User-ID des Prozesses mit der angegebenen PID. 
# Falls der Prozess nicht existiert, wird die UID auf "0" gesetzt.
    uid=$(ps -o uid= -p "$pid" 2>/dev/null)
    [ -z "$uid" ] && uid="0"


#Sobald die UID 0 ist, wird sie auf "root" gesetzt.
    if [ "$option" == "command" ]; then
        cmd=$(ps -o cmd= -p "$pid" 2>/dev/null | awk '{print $1}')
        [ -z "$cmd" ] && cmd="Prozess beendet"
        printf "%-8s %-50s\n" "$port" "$cmd"
        echo "---------------------------------------------------------------"
    elif [ "$option" == "user" ]; then
        if [ "$uid" == "0" ]; then
            uid="root"
        fi
        printf "%-8s %-8s\n" "$port" "$uid"
        echo "------------------------"
    fi

done
