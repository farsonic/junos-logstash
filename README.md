# junos-logstash

The install.sh file will take a current Ubuntu server to be a fully operational ELK stack with all the needed plugins and filters to accept SRX flow, web filtering and application logs. 

Download the install.sh file and execute it as root.

    bash install.sh 



## Enable stream-mode logging on SRX
    set security log source-address <ip address of SRX source> 
    set security log stream ELK format sd-syslog
    set security log stream ELK host <ip address of ELK server> 
    set security log stream ELK host port 5140


## Enable web-filtering
    set security utm feature-profile web-filtering type juniper-enhanced
    set security utm utm-policy custom-utm-policy web-filtering http-profile junos-wf-enhanced-default
    
    set security policies from-zone Trust to-zone Untrust policy web-traffic match source-address any
    set security policies from-zone Trust to-zone Untrust policy web-traffic match destination-address any
    set security policies from-zone Trust to-zone Untrust policy web-traffic match application junos-http
    set security policies from-zone Trust to-zone Untrust policy web-traffic then permit application-services utm-policy custom-utm-policy
    set security policies from-zone Trust to-zone Untrust policy web-traffic then log session-init
    set security policies from-zone Trust to-zone Untrust policy web-traffic then log session-close

## Screenshots (to follow) 
