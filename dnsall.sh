#!/bin/bash

apt-get install sudo -y

sudo apt-get install dnsutils -y

sudo apt-get update -y

sudo apt-get upgrade -y

sudo apt-get install bind9 -y

seehost=$(hostnamectl | grep "Static hostname:")

host=${seehost:20}

echo "Enter your domain name like toto.fr"

read vardomain


zonefile=db.$vardomain

echo "Enter your IP"

read ip

cd /etc/bind

echo "zone "\""$vardomain"\"" {" >> named.conf.local
echo "        type master;" >> named.conf.local
echo "        file "\""$zonefile"\"";" >> named.conf.local
echo "        allow-transfer{none;};" >> named.conf.local
echo "};" >> named.conf.local



cd /var/cache/bind

touch $zonefile


echo "\$TTL 3h" >> $zonefile
echo "$vardomain. IN SOA $host.$vardomain. moi.$vardomain.(" >> $zonefile
echo "0000001 ; Serial" >> $zonefile
echo "4h ; Refresh after 3 hours" >> $zonefile
echo "1h ; Retry after 1 hour" >> $zonefile
echo "1w ; Expire after 1 week" >> $zonefile
echo "1h) ; Negative caching TTL of 1 hour" >> $zonefile
echo "$vardomain. IN NS $host.$vardomain." >> $zonefile
echo "$host.$vardomain. IN A $ip" >> $zonefile

echo "Do you want AAAA NS records ? (y/n)"

read aaaansyn

if [ $aaaansyn == "y" ] || [ $aaaansyn == "n" ]
then

	if [ $aaaansyn == "y" ]
	then

		echo "Enter your IPv6"

		read ipv6

		echo "$host.$vardomain. IN A $ipv6" >> $zonefile
	fi
else

echo "Errors of caractere"

exit

fi

echo "Do you want other AAAA record ? (y/n)"

read aaaarcyn

if [ $aaaarcyn == "y" ] || [ $aaaarcyn == "n" ]
then

	if [ $aaaarcyn == "y" ]
	then
        	echo "How many ? "

            read aaaarvbs

				if [[ ! $anbs =~ ^[0-9]+$ ]] ; then
			    	echo "No good enter number"
			    	exit
				fi

                i=1

                while [ $i -le $aaaarvbs ]
                do

                	echo "Name of AAAA record |space| ipv6"

                	read aaaarec aaipv6

                	echo "$aaaarec. IN AAAA $aaipv6" >> $zonefile

					i=$((i+1))	

                done
	fi

else

echo "Errors of caractere"

exit

fi

echo "Do you want reverse zone ? (y/n)"

read rvs

if [ $rvs == "y" ] || [ $rvs == "n" ]
then

	if [ $rvs == "y" ]
	then

		echo "Enter your IP inverse exemple if your ip was 192.168.1.11 enter 11.1.168.192"

		read invip

		zonefileinv=db.$invip

		cd /etc/bind

		echo "zone "\"$invip.in-addr.arpa"\" {" >> named.conf.local
		echo "        type master;" >> named.conf.local
		echo "        file "\""$zonefileinv"\"";" >> named.conf.local
		echo "        allow-transfer{none;};" >> named.conf.local
		echo "};" >> named.conf.local

		cd /var/cache/bind

		touch $zonefileinv

		echo "\$TTL 3h" >> $zonefileinv
		echo "$invip.in-addr.arpa. IN SOA $host.$vardomain. moi.$vardomain.(" >> $zonefileinv
		echo "0000001 ; Serial" >> $zonefileinv
		echo "4h ; Refresh after 3 hours" >> $zonefileinv
		echo "1h ; Retry after 1 hour" >> $zonefileinv
		echo "1w ; Expire after 1 week" >> $zonefileinv
		echo "1h) ; Negative caching TTL of 1 hour" >> $zonefileinv
		echo "$invip.in-addr.arpa. IN NS $host.$vardomain." >> $zonefileinv
		echo "$invip.in-addr.arpa. IN PTR $vardomain." >> $zonefileinv

	fi
else

echo "Errors of caractere"

exit

fi

echo "Do you want MX record ? (y/n)"

read mxyn

if [ $mxyn == "y" ] || [ $mxyn == "n" ]
then

	if [ $mxyn == "y" ]
	then
        	echo "Name of MX record exemple mail.toto.fr"

                	read mx

                	echo "$vardomain. IN MX 10 $mx.">> $zonefile
					echo "$mx. IN A $ip" >> $zonefile
				

	fi
else

echo "Errors of caractere"

exit

fi

echo "Do you want other A record ? (y/n)"

read ayn

if [ $ayn == "y" ] || [ $ayn == "n" ]
then

	if [ $ayn == "y" ]
	then
        	echo "How many ? "

            read anbs

				if [[ ! $anbs =~ ^[0-9]+$ ]] ; then
			    	echo "No good enter number"
			    	exit
				fi

                i=1

                while [ $i -le $anbs ]
                do

                	echo "Name of A record "

                	read arec

                	echo "$arec. IN A $ip" >> $zonefile

					i=$((i+1))	

                done
	fi

else

echo "Errors of caractere"

exit

fi

echo "Do you want other CNAME record ? (y/n)"

read cnameyn


if [ $cnameyn == "y" ] || [ $cnameyn == "n" ]
then

	if [ $cnameyn == "y" ]
	then
        	echo "How many ? "

            read cnamenbs

				if [[ ! $cnamenbs =~ ^[0-9]+$ ]] ; then
			    	echo "No good enter number"
			    	exit
				fi

                i=1

                while [ $i -le $cnamenbs ]
                do

                	echo "Name of CNAME record (Record name) |space| Where ? (exemple www.toto.fr toto.fr ) "

                	read cname where

                	echo "$cname. IN CNAME $where." >> $zonefile

					i=$((i+1))

                done
	fi

else

echo "Errors of caractere"

exit

fi

echo "Do you want activate NSEC3 ? (y/n)"

read nsec

if [ $nsec == "y" ] || [ $nsec == "n" ]
then

	if [ $nsec == "y" ]
	then

		cd /etc/bind/

		sudo sed -i '5s/^/dnssec-enable yes;\n/' named.conf.options
		sudo sed -i '6s/^/dnssec-lookaside auto;\n/' named.conf.options
		sudo sed -i '11s/^/file "'"${zonefile}"'.signed";\n#/' named.conf.local

		cd /var/cache/bind

		sudo dnssec-keygen -a  ED25519 -n ZONE $vardomain

		sudo dnssec-keygen -f KSK -a  ED25519 -n ZONE $vardomain

		for key in `ls K$vardomain*.key`
		do
			echo "\$INCLUDE $key">> $zonefile
		done

		sudo dnssec-signzone -A -3 $(head -c 1000 /dev/sda1 | sha1sum | cut -b 1-16) -N INCREMENT -o $vardomain -t $zonefile

	fi

else

echo "Errors of caractere"

exit

fi

sudo named-checkconf -z

echo "If no errors use '' sudo service bind9 reload '' to finish the installation"
