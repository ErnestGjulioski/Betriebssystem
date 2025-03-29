#!/bin/bash

# Anleitung:
usage() {
    echo "Verwendung: $0 [-c | --command] [-u | --user] [-h | --help]"
    echo "  -c, --command  Zeigt nur den Command aus"
    echo "  -u, --user     Zeigt nur die Benutzer-ID mit Port"
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
    # Falls kein Argument übergeben wird, wird die Standardoption verwendet
    *) echo "Fehler: Ungültige Option '$1'"; usage ;;
esac

# Guckt ob der Benutzer Rechte hat, um Ports auszulesen
ports=$(ss -tlpn4 | awk 'NR>1 {split($4, a, ":"); print a[length(a)]}' | sort -u)

if [ -z "$ports" ]; then
    echo "Keine Ports gefunden"
    exit 0
fi

# Header
if [ "$option" == "user" ]; then
    printf "%-8s %-8s\n" "Port" "User-ID"
    echo "------------------------"
elif [ "$option" == "command" ]; then
    printf "%-8s %-50s\n" "Port" "Command"
    echo "---------------------------------------------------------------"
fi

# Ports durchgehen
for port in $ports; do
    pid=$(lsof -iTCP:$port -sTCP:LISTEN -t | head -n 1)

    if [ -z "$pid" ]; then
        if [ "$option" == "command" ]; then
            if [ "$port" == "53" ]; then
                printf "%-8s %-50s\n" "$port" "DNS-Dienst"
            else
                printf "%-8s %-50s\n" "$port" "[N/A]"
            fi
        elif [ "$option" == "user" ]; then
            printf "%-8s %-8s\n" "$port" "[N/A]"
        fi
        continue
    fi

    if [ "$option" == "command" ]; then
        cmd=$(ps -o cmd= -p "$pid" 2>/dev/null | awk '{print $1}')
        [ -z "$cmd" ] && cmd="[Prozess beendet]"
        printf "%-8s %-50s\n" "$port" "$cmd"
    elif [ "$option" == "user" ]; then
        uid=$(ps -o uid= -p "$pid" 2>/dev/null)
        [ -z "$uid" ] && uid="[N/A]"
        printf "%-8s %-8s\n" "$port" "$uid"
    fi

done
