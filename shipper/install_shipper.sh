#!/bin/sh

# Prepare Feihu Dir
feihu=/data/apps/feihu
feihu_install=/data/apps/feihu_install
[ ! -e $feihu ] && sudo mkdir $feihu && sudo chown $(whoami):$(whoami) $feihu
[ ! -e $feihu_install ] && sudo mkdir $feihu_install && sudo chown $(whoami):$(whoami) $feihu_install

# Setup nodejs
node_url=http://nodejs.org/dist/v0.10.24/node-v0.10.24-linux-x64.tar.gz
node_pkg=$feihu_install/node-v0.10.24-linux-x64.tar.gz
node_src=$feihu_install/node-v0.10.24-linux-x64
node_target=$feihu/node-v0.10.24-linux-x64
if [ ! -e $node_target ] ; then
	[ ! -e $node_pkg ] && wget $node_url -O $node_pkg
	cd $feihu && tar zxvf $node_pkg
else
	echo "INFO: $node_target already exist, skip"
fi

# Setup stats
statsd_url=https://github.com/etsy/statsd
statsd_src=$feihu_install/statsd_-GIT-
statsd_target=$feihu/statsd
statsd_conf_url=https://raw.github.com/ouyzhu/feihu/master/shipper/statsd_shipper.conf
statsd_conf_target=$statsd_target/statsd_shipper.conf
if [ ! -e $statsd_target ] ; then
	[ ! -e $statsd_src ] && cd $feihu_install && git clone $statsd_url $statsd_src

	mkdir -p $statsd_target
	cp -R $statsd_src/* $statsd_target

	wget $statsd_conf_url -O $statsd_conf_target
	#cp conf_example/statsd_shipper.conf $statsd_target/statsd_shipper.conf
else
	echo "INFO: $statsd_target already exist, skip"
fi

# Setup logstash
logstash_url=https://download.elasticsearch.org/logstash/logstash/logstash-1.3.2-flatjar.jar
logstash_pkg=$feihu_install/logstash-1.3.2-flatjar.jar
logstash_target=$feihu/logstash/
logstash_conf_url=https://raw.github.com/ouyzhu/feihu/master/shipper/logstash_shipper.conf
logstash_conf_target=$statsd_target/logstash_shipper.conf
if [ ! -e $statsd_target ] ; then
if [ ! -e $logstash_target ] ; then
	[ ! -e $logstash_pkg ] && wget $logstash_url -O $logstash_pkg
	
	mkdir -p $logstash_target
	cp $logstash_pkg $logstash_target

	local_ip=$(/sbin/ifconfig | sed -n -e '/inet addr:\(127\|172\|192\|10\)/d;/inet addr/s/.*inet6* addr:\s*\([.:a-z0-9]*\).*/\1/p' | head -1)
	wget $logstash_conf_url -O $logstash_conf_target
	sed -i -e "s/\"local_ip\"[, ]*\"[0-9\.]*\"/\"local_ip\", \"${local_ip:-IP_ADDRESS_UNKONW}\"/" $logstash_conf_target
else
	echo "INFO: $logstash_target already exist, skip"
fi

# check host
collector_host=feihu.statsd.live
(( $(grep -c "$collector_host" /etc/hosts) < 1 )) && echo "WARN: $collector_host not set in /etc/hosts, pls set it!"

# Final Setup
stop_script=$feihu/shipper_stop.sh
start_script=$feihu/shipper_start.sh
status_script=$feihu/shipper_status.sh
if [ ! -e $stop_script ] ; then
	cat > $stop_script <<-EOF
		#!/bin/bash

		statsd_pid=\$(ps -ef | grep statsd | grep -v grep | awk '{print \$2}' | uniq)
		echo kill \$statsd_pid
		kill \$statsd_pid

		logstash_pid=\$(ps -ef | grep logstash | grep -v grep | awk '{print \$2}' | uniq)
		echo kill \$logstash_pid
		kill \$logstash_pid
	EOF
fi
if [ ! -e $start_script ] ; then
	cat > $start_script <<-EOF
		#!/bin/bash
		
		echo nohup $node_target/bin/node $statsd_target/stats.js $statsd_target/statsd_shipper.conf >> $statsd_target/statsd_shipper.log 2>&1 &
		nohup $node_target/bin/node $statsd_target/stats.js $statsd_target/statsd_shipper.conf >> $statsd_target/statsd_shipper.log 2>&1 &

		echo nohup java -jar $logstash_target/$(basename $logstash_pkg) agent -f $logstash_target/logstash_shipper.conf -l $logstash_target/logstash_shipper.log >> $logstash_target/logstash_shipper.log 2>&1 &
		nohup java -jar $logstash_target/$(basename $logstash_pkg) agent -f $logstash_target/logstash_shipper.conf -l $logstash_target/logstash_shipper.log >> $logstash_target/logstash_shipper.log 2>&1 &
	EOF
fi
if [ ! -e $status_script ] ; then
	cat > $status_script <<-EOF
		#!/bin/bash
		echo "INFO: checking ports"
		netstat -an | grep ":8125\|:8126"

		echo "INFO: checking process"
		ps -ef | grep "logstash\|statsd" | grep -v grep
	EOF
fi
