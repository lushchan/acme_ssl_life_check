#!/bin/bash
#current date in epoch format
CurDate=$(date +"%s")
#debug
#CurDate="1639394914"
#30 days in epoch format 
MonthEpoch="2678400"
#Path to file with non-acme domains
ExternalFile="/usr/lib64/nagios/plugins/external"
# Get domains from acme client
AcmeList=$(/root/.acme.sh/acme.sh --list | awk '{doms=$1" "$3; print doms}' | sed 's/,/\n/g' | sed 's/\s/\n/g' | sed '/^no$/d' | sed -e '/\*\./d' | tail -n +3)
ExternalList=$(echo -e "\n" ; cat $ExternalFile)
AcmeList+=$ExternalList
while getopts ":w:c:h" options; do
  case "${options}" in
    w)
       WARNING=${OPTARG}
       ;;
    c)
       CRITICAL=${OPTARG}
       ;;
    h) echo "Help"
       echo "Options:"
       echo "-h - help"
       echo "-w - set warning threshold in days"
       echo "-c - set critical threshold in days" 
       exit 0
       ;;
    :)
      echo "Error: -${OPTARG} is empty.Please set threshhold in days for -w as warning and -c as critical"
      exit 3
      ;;
    *)
      echo "Unknown argument -${OPTARG}"                                    
      exit 3
      ;;
  esac
done

if [ -z "$WARNING" ] ; then
        echo "Warning threshold is missing. Check -h for help"
        exit 3
elif [ -z "$CRITICAL" ] ; then
        echo "CRITICAL threshold is missing. Check -h for help"
        exit 3
fi

#main
for i in $AcmeList ; do
  ExprDate=($(echo | openssl s_client -showcerts -servername $i -connect $i:443 2>/dev/null | openssl x509 -inform pem -noout -text | egrep '(Not After : )' | sed 's/.*Not\ After\ \:\ //g' | { read gmt ; date -d "$gmt" +"%s" ; }))
#Get date in epoch when certificate must be updated
  UpdDate=$(expr $ExprDate - $MonthEpoch)
#deprecated: Convert to CEST
  ExprDateCEST=`date -d @$ExprDate`
# Get days in epoch to expire date
  UntilDayEpoch=$(expr $ExprDate - $CurDate)
# Covert it to human format
  UntilDay=$(expr $UntilDayEpoch / 60 / 60 / 24)
   if (( CurDate > UpdDate )); then
      if (( $UntilDay > $CRITICAL )); then
         echo "$i expire in $UntilDay day(s)"
         STATUS+='1'
      elif (( $UntilDay < $CRITICAL )); then
         echo "$i expire in $UntilDay day(s)"
         STATUS+='2'
      fi
   else
      STATUS+='0'
   fi
done

#set nagios status
#set critical
if [[ $STATUS =~ "2"  ]]; then
  echo "Check ASAP some domain expires soon"
  exit 2
#set warning
elif [[ $STATUS != *"2"* && $STATUS =~ "1" ]]; then
  exit 1
#set OK
elif [[ $STATUS != *"2"* && $STATUS != *"1"* && $STATUS =~ "0" ]]; then
  echo "All domains are OK"
  exit 0
fi
