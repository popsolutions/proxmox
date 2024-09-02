#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: Enieber (pop.coop)
# License: MIT
# https://github.com/popsolutions/proxmox/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
 _   _      _   ____                                                                                                    
| \ | | ___| |_| __ )  _____  __                                                                                       
|  \| |/ _ \ __|  _ \ / _ \ \/ /                                                                                        
| |\  |  __/ |_| |_) | (_) >  <                                                                                         
|_| \_|\___|\__|____/ \___/_/\_\                                                                                        
EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
BFR="\\r\\033[K"
HOLD="-"

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

header_info

whiptail --backtitle "Proxmox VE Helper Scripts" --title "NetBox Installer" --yesno "This Will Install NetBox on this LXC Container. Proceed?" 10 58 || exit

msg_info "Installing Prerequisites"
apt update &>/dev/null
apt-get -y install git python3 python3-pip python3-venv postgresql libpq-dev &>/dev/null
msg_ok "Installed Prerequisites"

msg_info "Cloning NetBox Repository"
git clone -b master https://github.com/netbox-community/netbox.git /opt/netbox &>/dev/null
msg_ok "Cloned NetBox Repository"

msg_info "Creating Python Virtual Environment"
cd /opt/netbox
python3 -m venv venv &>/dev/null
source venv/bin/activate
msg_ok "Created Python Virtual Environment"

msg_info "Installing Python Requirements"
pip install -r requirements.txt &>/dev/null
msg_ok "Installed Python Requirements"

msg_info "Setting Up Database"
sudo -u postgres psql -c "CREATE DATABASE netbox;" &>/dev/null
sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD 'netbox';" &>/dev/null
sudo -u postgres psql -c "ALTER ROLE netbox SET client_encoding TO 'utf8';" &>/dev/null
sudo -u postgres psql -c "ALTER ROLE netbox SET default_transaction_isolation TO 'read committed';" &>/dev/null
sudo -u postgres psql -c "ALTER ROLE netbox SET timezone TO 'UTC';" &>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;" &>/dev/null
msg_ok "Set Up Database"

msg_info "Applying Database Migrations"
./manage.py migrate &>/dev/null
msg_ok "Applied Database Migrations"

msg_info "Creating Superuser"
./manage.py createsuperuser --no-input --username admin --email admin@example.com &>/dev/null
msg_ok "Created Superuser"

msg_info "Collecting Static Files"
./manage.py collectstatic --no-input &>/dev/null
msg_ok "Collected Static Files"

msg_info "Starting NetBox Service"
./manage.py runserver 0.0.0.0:8000 &>/dev/null &
msg_ok "Started NetBox Service"

IP=$(hostname -I | cut -f1 -d ' ')
echo -e "Successfully Installed!! NetBox should be reachable by going to ${BL}http://${IP}:8000${CL}"
