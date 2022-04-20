#!/bin/bash

#font colors

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

clear

#public ip

pub_ip=$(wget -qO- https://ipecho.net/plain ; echo)


#add users

echo -ne "${YELLOW}Enter the username : "; read username
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
IP=$(wget -qO- ipv4.icanhazip.com)
echo -e "${YELLOW}===================" &&
echo -e "${GREEN}꧁SLEHIBOT-SSH꧂      "    &&
echo -e "${YELLOW}===================" &&
echo -e "${GREEN}\nIP :${YELLOW} $pub_ip" 
echo -e "${GREEN}\nUsername :${YELLOW} $username" 
echo -e "${GREEN}\nPassword :${YELLOW} $password" 
echo -e "${GREEN}\nExpire Date :${YELLOW} $exd ${ENDCOLOR}" &&

echo -e "${GREEN}෴Default  Server Ports෴     "  
echo -e "${GREEN} ★ OpenSSH Port : 22     " 
echo -e "${GREEN} ★ SSL Port : 443     " 
echo -e "${GREEN} ★ Dropbear Port : 80     " 
echo -e "${GREEN} ★ Proxy Port : 8080     " 
echo -e "${GREEN} ▰▱▰▱▰▱▰▱▰▱▰▱     " 
echo -e "${GREEN} ★ Badvpn : 7300     " 
echo -e "${GREEN} ▰▱▰▱▰▱▰▱▰▱▰▱     " 
echo -e "${GREEN} ☬[⍣]  SL EHI BOT [⍣]☬     "  ||
echo -e "${RED}\nFailed to add user $username please try again.${ENDCOLOR}"

#return to panel 

echo -e "\nPress Enter key to return to main menu"; read
menu
