# junos-logstash







enable Stream mode logging on SRX
=================================
set security log source-address 192.168.0.2
set security log stream ELK format sd-syslog
set security log stream ELK host 192.168.0.132
set security log stream ELK host port 5140


enable web filtering
====================
set security utm feature-profile web-filtering type juniper-enhanced
set security utm utm-policy custom-utm-policy web-filtering http-profile junos-wf-enhanced-default

set security policies from-zone Trust to-zone Untrust policy web-traffic match source-address any
set security policies from-zone Trust to-zone Untrust policy web-traffic match destination-address any
set security policies from-zone Trust to-zone Untrust policy web-traffic match application junos-http
set security policies from-zone Trust to-zone Untrust policy web-traffic then permit application-services utm-policy custom-utm-policy
set security policies from-zone Trust to-zone Untrust policy web-traffic then log session-init
set security policies from-zone Trust to-zone Untrust policy web-traffic then log session-close

