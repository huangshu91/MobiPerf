#!/bin/bash
#Compile and deploy for MLab servers
if [ $1 = "-c" ]; then
	mkdir mlab

	cd bin

	for i in Downlink Uplink KeepAlive
	do
		#-e: backslash-escaped characters is enabled
		echo -e "Main-Class: servers."$i"\n" > manifest
		jar cvfm $i.jar manifest servers/$i*.class  common/*.class
		mv $i.jar ../mlab/
	done

	rm manifest

	cd ..

elif [ $1 = "-d" ]; then
	for n in `cat nodeList`
	do
	#	if [ $n = "mlab3.atl01.measurement-lab.org" ];then
	#		echo "this one"
	#	else
	#		continue
	#	fi
		
		if [ $n = "mobiperf.com" ]; then
			user="hjx"
			port=22
		else
			user="michigan_1"
			port=806
		fi

		ping=`ping -c 2 -W 2 $n | grep " 0.0\% packet loss" | wc -l`
		if [ $ping = "1" ]; then
			echo $n " on"
		else
			echo $n " off"
			continue
		fi
		echo "Deploy"
		if [ $2 = "-e" ]; then
			ssh -o "StrictHostKeyChecking no" -p $port -l $user $n 'cd ~/mobiperf;bash end.sh'
		elif [ $2 = "-i" ]; then
			ssh -o "StrictHostKeyChecking no" -p $port -l $user $n 'sudo yum -y install java' &
		else
			#ssh -o "StrictHostKeyChecking no" -p $port -l $user $n 'mkdir ~/mobiperf' &
			scp -o "StrictHostKeyChecking no" -P $port  mlab/* $user@$n:~/mobiperf
			#first terminate
			ssh -o "StrictHostKeyChecking no" -p $port -l $user $n 'cd ~/mobiperf;bash end.sh'
			ssh -o "StrictHostKeyChecking no" -p $port -l $user $n 'cd ~/mobiperf;bash start.sh &' &
		fi
		echo $n " done"
	done
elif [ $1 = "-t" ];then
        ps aux | grep "measurement-lab.org" | awk '{system("sudo kill -9 " $2);}'
else
	echo "Usage: compile -c; deploy -d; terminate remotely -d -e; install java -d -i; kill all local process -t"
fi