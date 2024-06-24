#!/usr/bin/env bash

# Variables
user="steam"
steamcmd_dir="/home/${user}/steamcmd"

# 32 or 64 bit Operating System
# If BITS environment variable is not set, try determine it
if [ -z "$BITS" ]; then
    # Determine the operating system architecture
    architecture=$(uname -m)

    # Set OS_BITS based on the architecture
    if [[ $architecture == *"64"* ]]; then
        export BITS=64
    elif [[ $architecture == *"i386"* ]] || [[ $architecture == *"i686"* ]]; then
        export BITS=32
    else
        echo "Unknown architecture: $architecture"
        exit 1
    fi
fi

if [[ -z $IP ]]; then
    IP_ARGS=""
else
    IP_ARGS="-ip ${IP}"
fi

# Get the free space on the root filesystem in GB
FREE_SPACE=$(df / --output=avail -BG | tail -n 1 | tr -d 'G')

echo "With $FREE_SPACE Gb free space..."

PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -z "$PUBLIC_IP" ]; then
	echo "ERROR: Cannot retrieve your public IP address..."
	exit 1
fi

# Update DuckDNS with our current IP
if [ ! -z "$DUCK_TOKEN" ]; then
    echo url="http://www.duckdns.org/update?domains=$DUCK_DOMAIN&token=$DUCK_TOKEN&ip=$PUBLIC_IP" | curl -k -o /duck.log -K -
fi

echo "Getting latest version of steamcmd ..."
cd ${steamcmd_dir}
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xvzf steamcmd_linux.tar.gz
cd /home/${user}

echo "outputting file info ..."
find . -maxdepth 2 -type d -exec ls -ld "{}" \;

echo "Downloading any updates for CS2..."
# https://developer.valvesoftware.com/wiki/Command_line_options
${steamcmd_dir}/steamcmd.sh \
  +api_logging 1 1 \
  +@sSteamCmdForcePlatformType linux \
  +@sSteamCmdForcePlatformBitness $BITS \
  +force_install_dir /home/${user}/cs2 \
  +login anonymous \
  +app_update 730 \
  +quit

cd /home/${user}
echo "/home/user !!!!!!!"

mkdir -p /home/${user}/.steam/sdk32/
ln -sf ${steamcmd_dir}/linux32/steamclient.so /home/${user}/.steam/sdk32/
mkdir -p /home/${user}/.steam/sdk64/
ln -sf ${steamcmd_dir}/linux64/steamclient.so /home/${user}/.steam/sdk64/

echo "Installing mods"
cp -R /home/${user}/game/ /home/${user}/cs2/

echo "Merging in custom files"
cp -RT /home/${user}/custom_files/ /home/${user}/cs2/game/csgo/

chown -R ${user}:${user} /home/${user}/cs2

cd /home/${user}/cs2

# Define the file name
FILE="game/csgo/gameinfo.gi"

# Define the pattern to search for and the line to add
PATTERN="Game_LowViolence[[:space:]]*csgo_lv // Perfect World content override"
LINE_TO_ADD="\t\t\tGame\tcsgo/addons/metamod"

# Use a regular expression to ignore spaces when checking if the line exists
REGEX_TO_CHECK="^[[:space:]]*Game[[:space:]]*csgo/addons/metamod"

# Check if the line already exists in the file, ignoring spaces
if grep -qE "$REGEX_TO_CHECK" "$FILE"; then
    echo "$FILE already patched for Metamod."
else
    # If the line isn't there, use awk to add it after the pattern
    awk -v pattern="$PATTERN" -v lineToAdd="$LINE_TO_ADD" '{
        print $0;
        if ($0 ~ pattern) {
            print lineToAdd;
        }
    }' "$FILE" > tmp_file && mv tmp_file "$FILE"
    echo "$FILE successfully patched for Metamod."
fi

echo "Starting server on $PUBLIC_IP:$PORT"
# https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers#Command-Line_Parameters
arguments="-dedicated \
    -console \
    -usercon \
    -autoupdate \
    -tickrate $TICKRATE \
	$IP_ARGS \
    -port $PORT \
    +map de_dust2 \
    -maxplayers $MAXPLAYERS \
    -authkey $API_KEY \
	+sv_setsteamaccount $STEAM_ACCOUNT \
    +game_type 0 \
    +game_mode 0 \
    +mapgroup mg_active \
    +sv_lan $LAN \
	+sv_password $SERVER_PASSWORD \
	+rcon_password $RCON_PASSWORD \
	+exec $EXEC"
echo "arguments: $arguments"

/home/${user}/cs2/game/bin/linuxsteamrt64/cs2 $arguments
