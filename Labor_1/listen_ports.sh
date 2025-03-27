#!/bin/bash

# Funktion zur Anzeige der Hilfs-/Usage-Informationen
usage() {
    echo "Usage: $0 [-c | --command] [-u | --user] [-h | --help]"
    echo "  -c, --command  Display the command of the process using the port"
    echo "  -u, --user     Display the user ID of the process using the port"
    echo "  -h, --help     Display this help message"
    exit 0
}

# Prüfen, ob 'ss' vorhanden ist
if ! command -v ss &> /dev/null; then
    echo "Error: 'ss' command not found. Please install it to use this script."
    exit 1
fi

# Standardoption setzen
option="command"

# Verarbeitung der Kommandozeilenargumente
case "$1" in
    -c|--command)
        option="command"
        ;;
    -u|--user)
        option="user"
        ;;
    -h|--help)
        usage
        ;;
    "" ) # Kein Argument angegeben
        ;;
    *)
        echo "Error: Invalid argument '$1'"
        usage
        ;;
esac

# Verwendung von ss, um alle lauschenden TCP und UDP Sockets anzuzeigen
ports=$(ss -tuln | awk 'NR>1 {split($5, a, ":"); print a[length(a)]}' | sort -u)

# Prüfen, ob Ports gefunden wurden
if [ -z "$ports" ]; then
    echo "No open ports found."
    exit 0
fi

# Header für die Ausgabe
if [ "$option" == "command" ]; then
    printf "%-8s %-8s %-50s\n" "Port" "User-ID" "Command"
    echo "---------------------------------------------------------------"
else
    printf "%-8s %-8s\n" "Port" "User-ID"
    echo "------------------------"
fi

# Ports durchgehen
for port in $ports; do
    
 # PID des Prozesses ermitteln, der den Port verwendet
pid=$(ss -tulnp | awk -v p=":$port" '$5 ~ p"$" {gsub("pid=", "", $NF); split($NF, a, ","); print a[1]; exit}')

# Wenn keine PID gefunden wurde, überspringen
if [ -z "$pid" ]; then
    if [ "$option" == "command" ]; then
        printf "%-8s %-8s %-50s\n" "$port" "[N/A]" "not found"
    else
        printf "%-8s %-8s\n" "$port" "[N/A]"
    fi
    continue
fi


    # User-ID über ps ermitteln
    uid=$(ps -o uid= -p "$pid" 2>/dev/null)
    [ -z "$uid" ] && uid="[N/A]"

    # Falls Option 'command' gewählt wurde, den Befehl ermitteln
    if [ "$option" == "command" ]; then
        cmd=$(ps -o cmd= -p "$pid" 2>/dev/null)
        [ -z "$cmd" ] && cmd="[process exited]"
        printf "%-8s %-8s %-50s\n" "$port" "$uid" "$cmd"
    else
        printf "%-8s %-8s\n" "$port" "$uid"
    fi
done
