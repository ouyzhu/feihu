feihu
=====

FeiHu is a monitoring system, which take advantage of logstash, statsd, graphite, etc.
Script here are try best to not depend on those installed system wide, but use its own version instead.

** Precondition **
You need sudo priviledge, since some command have 'sudo', which also means it works in Debian/Ubuntu system.

** Install Shipper **
Just run `wget -q -O - https://raw.github.com/ouyzhu/feihu/master/shipper/install_shipper.sh | bash`, and you will get everything
The script will download and install logstash/statsd/nodejs, configure everything.

** Install Collector **
Run install_collector.sh, might as convenient as the install_shipper.sh, so take care :-) 
The script will download and compile apache, python, graphite, configure everything.

** Configure **
Host: For any shipper machine, you need configure /etc/hosts with "xxx.xxx.xx.x     feihu.statsd.live", which points to your collector machine.
Logstash: 1) the log path, 2) the grok matching patters. Config file path at: /data/apps/feihu/logstash/logstash_shipper.conf

** Run **
If nothing bad happens, there are start/stop/status_shipper/collector script there for you to run.
If you are lucky enough again, just go to http://host:8070

