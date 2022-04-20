#!/bin/bash

#Font Colors

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
ENDCOLOR="\e[0m"

clear

#public ip

pub_ip=$(wget -qO- https://ipecho.net/plain ; echo)

#root check

if ! [ $(id -u) = 0 ]; then
   echo -e "${RED}Plese run the script with root privilages!${ENDCOLOR}"
   exit 1
fi

spinner()
{
    #Loading spinner
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr" 
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
pre_req()
{
        #installing pre-requirements and adding port rules to ubuntu firewall
		
	apt update -y && apt upgrade -y

        apt-get install -y dropbear && apt-get install -y stunnel4 && apt-get install -y squid && apt-get install -y cmake && apt-get install -y python3 && apt-get install -y screenfetch && apt-get install -y openssl
        ufw allow 443/tcp
	ufw allow 444/tcp
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 110/tcp
        ufw allow 8080/tcp
        ufw allow 7300/tcp
        ufw allow 7300/udp
}
mid_conf()
{

#configuring openssh

sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#Banner none/Banner \/etc\/banner/' /etc/ssh/sshd_config

#configuring dropbear

mv /etc/default/dropbear /etc/default/dropbear.backup
cat << EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=80
DROPBEAR_EXTRA_ARGS="-p 110"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

#Adding the banner

cat << EOF > /etc/banner
<h4>&#9734; <font color="#FF6347">Premium Server</font> &#9734;</h4><b><font color="#2E86C1">===============================</font></b><br><b><span style="color:#BA55D3">╔═══════*.·:·.✧ ✦ ✧.·:·.*═══════╗</span></b><br> <b><h2><span style="color:#1f15e9;">&nbsp;&nbsp;꧁ &#127473&#127472 SL EHI BOT &#127473&#127472 ꧂</b></h2></span><b><span style="color:#BA55D3">╚═══════*.·:·.✧ ✦ ✧.·:·.*═══════╝</span></b><br><br><b><span style="color:#8A2BE2">&#187; NO SPAM !!! &#171;</span><br><span style="color:#A52A2A">&#187; NO DDOS !!! &#171;</span><br><span style="color:#6495ED">&#187; NO HACKING !!! &#171;</span><br><span style="color:#008B8B">&#187; NO CARDING !!! &#171;</span><br><span style="color:#9932CC">&#187; NO TORRENT !!! &#171;</span><br><span style="color:#1E90FF">&#187; NO OVER DOWNLOADING !!! &#171;</span></b><br><br><b><font color="#2E86C1">===============================</font></b><br><b><font color="#D35400">&#127473&#127472 &#187; SL EHI BOT&trade; &#171; &#127473&#127472</font> Auto Script</b><br><br><b>Create By: <font color="#138D75">Lakmal Sandaru</font><font color="#A52A2A">&nbsp;&nbsp;&#187; InfinityJE&trade;&#171;</font></b><br><b>Join Channel:<font color="#2E86C1">https://t.me/slehiteam  </font></b><br><br><b><font color="#2E86C1">===============================</font></b>
EOF

#Configuring stunnel

mkdir /etc/stunnel
cat << EOF > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
sslVersion = all
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 443
connect = 110

[openssh]
accept = 444
connect = 22
EOF

#Genarating a self signed certificate for stunnel

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -out stunnel.pem  -keyout stunnel.pem

cp stunnel.pem /etc/stunnel/stunnel.pem
chmod 644 /etc/stunnel/stunnel.pem

#Enable overide stunnel default

cp /etc/default/stunnel4 /etc/default/stunnel4.backup
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

# Configuring squid

mv /etc/squid/squid.conf /etc/squid/squid.conf.backup
cat << EOF > /etc/squid/squid.conf
acl url1 dstdomain -i 127.0.0.1
acl url2 dstdomain -i localhost
acl url3 dstdomain -i $pub_ip
acl url4 dstdomain -i /REZOTHSSSH?
acl payload url_regex -i "/etc/squid/payload.txt"

http_access allow url1
http_access allow url2
http_access allow url3
http_access allow url4
http_access allow payload
http_access deny all

http_port 8080
visible_hostname REZOTHSSSH
via off
forwarded_for off
pipeline_prefetch off
EOF
cat << EOF > /etc/squid/payload.txt
.whatsapp.net/
.facebook.net/
.twitter.com/
.speedtest.net/
EOF
}
fun_udpgw()
{
#build and install badvpn-udpgw

git clone https://github.com/ambrop72/badvpn
cd badvpn
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install

#creating badvpn systemd service unit

cat << EOF > /etc/systemd/system/udpgw.service
[Unit]
Description=UDP forwarding for badvpn-tun2socks
After=nss-lookup.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000
User=udpgw

[Install]
WantedBy=multi-user.target
EOF
}
fun_panel()
{
mkdir /etc/slehibot-vps-auto-script
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/ChangeUser.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/ChangePorts.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/UserManager.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/Banner.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/DelUser.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/ListUsers.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/RemoveScript.sh
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/menu
mv ChangeUser.sh /etc/slehibot-vps-auto-script/ChangeUser.sh
mv ChangePorts.sh /etc/slehibot-vps-auto-script/ChangePorts.sh
mv UserManager.sh /etc/slehibot-vps-auto-script/UserManager.sh
mv Banner.sh /etc/slehibot-vps-auto-script/Banner.sh
mv DelUser.sh /etc/slehibot-vps-auto-script/DelUser.sh
mv ListUsers.sh /etc/slehibot-vps-auto-script/ListUsers.sh
mv RemoveScript.sh /etc/slehibot-vps-auto-script/RemoveScript.sh
mv speedtest-cli /etc/slehibot-vps-auto-script/speedtest-cli
mv menu /usr/local/bin/menu
chmod +x /etc/slehibot-vps-auto-script/ChangeUser.sh
chmod +x /etc/slehibot-vps-auto-script/ChangePorts.sh
chmod +x /etc/slehibot-vps-auto-script/UserManager.sh
chmod +x /etc/slehibot-vps-auto-script/Banner.sh
chmod +x /etc/slehibot-vps-auto-script/DelUser.sh
chmod +x /etc/slehibot-vps-auto-script/ListUsers.sh
chmod +x /etc/slehibot-vps-auto-script/RemoveScript.sh
chmod +x /etc/slehibot-vps-auto-script/speedtest-cli
chmod +x /usr/local/bin/menu
}
fun_service_start()
{
#enabling and starting all services

useradd -m udpgw

systemctl restart sshd
systemctl enable dropbear
systemctl restart dropbear
systemctl enable stunnel4
systemctl restart stunnel4
systemctl enable squid
systemctl restart squid
sudo systemctl enable udpgw
sudo systemctl restart udpgw
}
echo -ne "${YELLOW}=============================================\n"
echo -ne "${YELLOW}>>>>>>>>SLEHIBOT VPS Script Installing<<<<<<<\n\n\n"
echo -ne "${GREEN}Installing SLEHIBOT Script required packages ......."
pre_req >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${BLUE}Configuring Stunnel, Openssh, Dropbear and Squid ......."
mid_conf >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${YELLOW}Compiling and installing Badvpn UDP Gateway ......."
fun_udpgw >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${CYAN}Installing SLEHIBOT Script Panel ........"
fun_panel >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${RED}Starting All The Services ......."
fun_service_start >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -e "${ENDCOLOR}"

#configure user shell to /bin/false
echo /bin/false >> /etc/shells
clear

#Adding the default user
echo -ne "${GREEN}Enter the default username : "; read username
while true; do
    read -p "Do you want to genarate a random password ? (Y/N) " yn
    case $yn in
        [Yy]* ) password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-9};echo;); break;;
        [Nn]* ) echo -ne "Enter password (please use a strong password) : "; read password; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo -ne "Enter No. of Days till expiration : ";read nod
exd=$(date +%F  -d "$nod days")
useradd -e $exd -M -N -s /bin/false $username && echo "$username:$password" | chpasswd &&
clear &&
echo -e "${RED}============================" &&
echo -e "${GREEN}Default User Details" &&
echo -e "${RED}============================" &&
echo -e "${GREEN}\nUsername :${YELLOW} $username" &&
echo -e "${GREEN}\nPassword :${YELLOW} $password" &&
echo -e "${GREEN}\nExpire Date :${YELLOW} $exd ${ENDCOLOR}" ||
echo -e "${RED}\nFailed to add default user $username please try again.${ENDCOLOR}"

#exit script
echo -e "\n${CYAN}SLEHIBOT Auto Script installed. You can access the panel using 'menu' command. ${ENDCOLOR}\n"
echo -e "\nPress Enter key to exit"; read
