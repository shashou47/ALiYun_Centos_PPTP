#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================
#   SYSTEM REQUIRED:  CentOS 6 (32bit/64bit)
#   DESCRIPTION:  Auto install pptpd for CentOS 6
#===================================================================

if [[ $EUID -ne 0 ]]; then
    echo "Error:This script must be run as root!"
    exit 1
fi

if [[ ! -e /dev/net/tun ]]; then
    echo "TUN/TAP is not available!"
    exit 1
fi


clear
echo ""
echo "#############################################################"
echo "# Auto Install PPTP for ALiYun CentOS 6.x                   #"
echo "# System Required: CentOS 6(32bit/64bit)                    #"
echo "#############################################################"
echo ""

# Remove installed pptpd & ppp
yum remove -y pptpd ppp
iptables --flush POSTROUTING --table nat
iptables --flush FORWARD
rm -f /etc/pptpd.conf
rm -rf /etc/ppp
arch=`uname -m`
IP=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`

# Download epel-release
if ! yum install epel-release -y;then
    echo "Failed to download epel-release."
    exit 1
fi
# Download pptpd
if ! yum install ppp pptpd iptables -y;then
    echo "Failed to download ppp pptpd iptables."
    exit 1
fi

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p
sed -i 's/#ms-dns 10.0.0.1/ms-dns 8.8.8.8/g' /etc/ppp/options.pptpd
sed -i 's/#ms-dns 10.0.0.2/ms-dns 4.4.4.4/g' /etc/ppp/options.pptpd
sed -i 's/#localip 192.168.0.1/localip 192.168.8.1/g' /etc/pptpd.conf
sed -i 's/#remoteip 192.168.0.234-238,192.168.0.245/remoteip 192.168.8.2-254/g' /etc/pptpd.conf



pass=`openssl rand 6 -base64`
if [ "$1" != "" ]
  then pass=$1
fi

echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
iptables -A FORWARD -p tcp --syn -s 192.168.8.0/24 -j TCPMSS --set-mss 1356
iptables -A INPUT -p gre -j ACCEPT
service iptables save
chkconfig --add pptpd
chkconfig pptpd on
service iptables restart
service pptpd start

echo ""
echo "PPTP VPN service is installed."
echo "ServerIP:${IP}"
echo "Username:vpn"
echo "Password:${pass}"
echo "Changer By shashou47"
echo ""

exit 0
