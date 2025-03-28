#!/bin/bash

# Anleitung:
usage() {
    echo "Verwendung: $0 [-c | --command] [-u | --user] [-h | --help]"
    echo "  -c, --command  Zeigt den den Command selbst aus"
    echo "  -u, --user     Zeigt die Benutzer-ID "
    echo "  -h, --help     Zeigt diese Hilfemeldung an"
    exit 0
}

# Prüfen, ob die benötigten Befehle existieren
for cmd in ss lsof ps awk grep cut sort; do
    if ! command -v $cmd &> /dev/null; then
        echo "Fehler: Befehl '$cmd' nicht gefunden."
        exit 1
    fi
done

# Standardoption
option="command"


case "$1" in
    -c|--command) option="command" ;;

    -u|--user) option="user" ;;

    -h|--help) usage ;;

    "" ) ;; 
    #Falls kein Argument übergeben wird, wird die Standardoption verwendet
    *) echo "Fehler: Error'$1'"; usage ;;
esac

#Guckt ob der Benutzer rechte hat um Ports auszulesen
ports=$(ss -tlpn4 | awk 'NR>1 {split($4, a, ":"); print a[length(a)]}' | sort -u)

if [ -z "$ports" ]; then
    echo "Keine Port gefunden"
    exit 0
fi

# Header
if [ "$option" == "command" ]; then
    printf "%-8s %-8s %-50s\n" "Port" "User-ID" "Command"
    echo "---------------------------------------------------------------"
else
    printf "%-8s %-8s\n" "Port" "User-ID"
    echo "------------------------"
fi

# Ports durchgehen
for port in $ports; do
    # Guckt ob der Port eine Zahl ist
    pid=$(lsof -iTCP:$port -sTCP:LISTEN -t | head -n 1)

    if [ -z "$pid" ]; then
        if [ "$option" == "command" ]; then
        
            if [ "$port" == "53" ]; then
                printf "%-8s %-8s %-50s\n" "$port" "[system]" "DNS-Dienst"
            else
                printf "%-8s %-8s %-50s\n" "$port" "[N/A]"
            fi
        else
            printf "%-8s %-8s\n" "$port" "[N/A]"
        fi
        continue
    fi

   # Holt die User-ID des Prozesses (UID) für die gegebene PID
    uid=$(ps -o uid= -p "$pid" 2>/dev/null)
    [ -z "$uid" ] && uid="[N/A]"

    # Holt den Command des Prozesses (CMD) für die gegebene PID
    # und gibt den ersten Teil des Befehls aus
    # Wenn der Prozess nicht mehr existiert, wird "[Prozess beendet]" ausgegeben
    # und der Port wird als "[N/A]" angezeigt
    # Wenn der Port 53 ist, wird "DNS-Dienst" ausgegeben
    if [ "$option" == "command" ]; then
        cmd=$(ps -o cmd= -p "$pid" 2>/dev/null | awk '{print $1}')
        [ -z "$cmd" ] && cmd="[Prozess beendet]"
        printf "%-8s %-8s %-50s\n" "$port" "$uid" "$cmd"
    else
        printf "%-8s %-8s\n" "$port" "$uid"
    fi
done
