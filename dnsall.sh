apt-get install sudo -y

sudo apt-get install dnsutils -y

sudo apt-get update -y

sudo apt-get upgrade -y

sudo apt-get install bind9 -y

echo "How many zone do you want (exclude reverse zone) ?"

read zonenbs

zi=1

if [[ ! $zonenbs =~ ^[0-9]+$ ]] ; then
	echo "No good enter number"
	exit	
fi

while [ $zi -le $zonenbs ]
do

	zi=$((zi+1))

	echo "Do you want Slave or Master (s/m)?"	

	read smyn

	if [ $smyn == "s" ] || [ $smyn == "m" ]
	then

		if [ $smyn == "m" ]
		then

			seehost=$(hostnamectl | grep "Static hostname:")

			host=${seehost:20}

			echo "Enter your domain name like toto.fr"

			read vardomain


			zonefile=db.$vardomain

			echo "Enter your IP"

			read ip

			echo "Do you want ipv6 (y/n)?"

			read aaaansyn

			if [ $aaaansyn == "y" ] || [ $aaaansyn == "n" ]
			then

				if [ $aaaansyn == "y" ]
				then

					echo "Enter your IPv6"

					read ipv6

				fi
			fi


			cd /etc/bind

			echo "zone "\""$vardomain"\"" {" >> named.conf.local
			echo "        type master;" >> named.conf.local
			echo "        file "\""$zonefile"\"";" >> named.conf.local
			echo "};" >> named.conf.local
			sudo sed -i '5s/^/allow-transfer{none;};\n/' named.conf.options



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

			if [ $aaaansyn == "y" ]
			then

				echo "$host.$vardomain. IN AAAA $ipv6" >> $zonefile
			fi



			echo "Do you want reverse zone ? (y/n)"

			read rvs

			if [ $rvs == "y" ] || [ $rvs == "n" ]
			then

				if [ $rvs == "y" ]
				then

					echo "Enter your IP inverse exemple if your ip was 192.168.1.11 enter 11.1.168.192 |space| and invip -1 exemple if your ip was 192.168.1.11 enter 1.168.192"

					read invip invip3

					zonefileinv=db.$invip

					cd /etc/bind/

					echo "zone "\"$invip3.in-addr.arpa"\" {" >> named.conf.local
					echo "        type master;" >> named.conf.local
					echo "        file "\""$zonefileinv"\"";" >> named.conf.local
					echo "};" >> named.conf.local



					cd /var/cache/bind

					touch $zonefileinv

					echo "\$TTL 3h" >> $zonefileinv
					echo "$invip3.in-addr.arpa. IN SOA $host.$vardomain. moi.$vardomain.(" >> $zonefileinv
					echo "0000001 ; Serial" >> $zonefileinv
					echo "4h ; Refresh after 3 hours" >> $zonefileinv
					echo "1h ; Retry after 1 hour" >> $zonefileinv
					echo "1w ; Expire after 1 week" >> $zonefileinv
					echo "1h) ; Negative caching TTL of 1 hour" >> $zonefileinv
					echo "$invip3.in-addr.arpa. IN NS $host.$vardomain." >> $zonefileinv
					echo "$invip.in-addr.arpa. IN PTR $vardomain." >> $zonefileinv



					if [ $aaaansyn == "y" ]
					then

						echo "Enter your IPv6 inverse exemple for 2001:db8:42:abba::1/64 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0 |space| and ipv6 -1 exemple for 2001:db8:42:abba::1/64 a.b.b.a.2.4.0.0.8.b.d.0.1.0.0.2"

						read invipv6 invipv63

						echo "$invipv6.ip6.arpa. IN NS $host.$vardomain." >> $zonefileinv
						echo "$invipv63.$invipv6.ip6.arpa. IN PTR $vardomain." >> $zonefileinv
					fi
				fi

			else

				echo "Errors of caractere"

				exit

			fi

			echo "Do you want allow transfert ? (y/n)"

			read transyn

			cd /etc/bind/

			if [ $transyn == "y" ] || [ $transyn == "n" ]
			then

				if [ $transyn == "y" ]
				then

			        echo "How many ip? (0 = all) "

			        read transbs

					if [[ ! $transbs =~ ^[0-9]+$ ]] ; then
						echo "No good enter number"
						exit
					fi

			        i=1
					cd /etc/bind/

					if [ $transbs -eq 0 ]
					then
				
						sudo sed -i '5s/^/#\n/' named.conf.options

					else

						sudo sed -i '14s/^/};\n/' named.conf.local
						if [ $rvs == "y" ]
						then
						
							sudo sed -i '19s/^/};\n/' named.conf.local
					
						fi

			        	while [ $i -le $transbs ]
			       		do

				    		echo " Enter ip allow transfer"

			            	read transip

			            	sudo sed -i '14s/^/'${transip}';/' named.conf.local

							if [ $rvs == "y" ]
							then
						
								sudo sed -i '19s/^/'${transip}';/' named.conf.local
					
							fi

				    		i=$((i+1))

			        	done

						sudo sed -i '14s/^/allow-transfer{/' named.conf.local

						if [ $rvs == "y" ]
						then
						
							sudo sed -i '19s/^/allow-transfer{/' named.conf.local
					
						fi
					fi
				fi

			else

			echo "Errors of caractere"

			exit

			fi
			cd /var/cache/bind
			echo "Do you want other NS record ? (y/n)"

			read nsyn

			if [ $nsyn == "y" ] || [ $nsyn == "n" ]
			then

				if [ $nsyn == "y" ]
				then
			        	echo "How many ? "

			            read nsbs

					if [[ ! $nsbs =~ ^[0-9]+$ ]] ; then
						echo "No good enter number"
						exit
						fi

			                i=1

			                while [ $i -le $nsbs ]
			                do

			                	echo "Name of NS record (hostname) |space| ip"

			                	read nsrec ip2

			                	echo "$vardomain. IN NS $nsrec.$vardomain." >> $zonefile
								echo "$nsrec. IN A $ip2" >> $zonefile

								if [ $aaaansyn == "y" ]
								then
						
									echo "Enter IPv6"

									read ipv62

									echo "$nsrec.$vardomain. IN AAAA $ipv62" >> $zonefile

								fi


								if [ $rvs == "y" ]
								then
									echo "Inverse IP |space| invip -1 exemple if your ip was 192.168.1.11 enter 1.168.192"

									read invip2 invip22
									echo "$invip22.in-addr.arpa. IN NS $nsrec.$vardomain." >> $zonefileinv
									echo "$invip2.in-addr.arpa. IN PTR $vardomain." >> $zonefileinv	
							

									if [ $aaaansyn == "y" ]
									then

										echo "Enter your IPv6 inverse exemple for 2001:db8:42:abba::1/64 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0 |space| and ipv6 -1 exemple for 2001:db8:42:abba::1/64 a.b.b.a.2.4.0.0.8.b.d.0.1.0.0.2"

										read invipv62 invipv622

										echo "$invipv62.ip6.arpa. IN NS $host.$vardomain." >> $zonefileinv
										echo "$invipv622.$invipv62.ip6.arpa. IN PTR $vardomain." >> $zonefileinv
									fi

								fi 		

								i=$((i+1))	

			            	done
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

			if [ $aaaansyn == "y" ]
			then

				echo "Do you want other AAAA record ? (y/n)"

				read aaaarcyn

				if [ $aaaarcyn == "y" ] || [ $aaaarcyn == "n" ]
				then

					if [ $aaaarcyn == "y" ]
					then
				        echo "How many ? "

				        read aaaarvbs

						if [[ ! $aaaarvbs =~ ^[0-9]+$ ]] ; then
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

			echo "Do you want other PTR record ? (y/n)"

			read ptryn


			if [ $ptryn == "y" ] || [ $ptryn == "n" ]
			then

				if [ $ptryn == "y" ]
				then
			        echo "How many ? "

			        read ptrbs

					if [[ ! $ptrbs =~ ^[0-9]+$ ]] ; then
						echo "No good enter number"
						exit
					fi

			        i=1

			        while [ $i -le $ptrbs ]
			        do

				    	echo "Name of PTR record (Record name) |space| Inverse IP "

			            read ptr ptrinvip

			            echo "$ptrinvip.in-addr.arpa. IN ptr $ptr." >> $zonefileinv

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



		else



		echo "C'est pas encore fais ça arrive soon"

		exit




		fi
	else

		echo "Errors of caractere"

		exit

	fi
done


sudo named-checkconf -z

echo "If no errors use '' sudo service bind9 reload '' to finish the installation"
