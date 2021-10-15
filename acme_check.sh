#!/bin/bash
#current date in epoch format
CurDate=$(date +"%s")
#debug
#CurDate="1639394914"
#30 days in epoch format 
Month="2678400"
#Path to file with non-acme domains
ExternalFile="/usr/lib64/nagios/plugins/external"
# Get domains from acme client
AcmeList=$(/root/.acme.sh/acme.sh --list | awk '{doms=$1" "$3; print doms}' | sed 's/,/\n/g' | sed 's/\s/\n/g' | sed '/^no$/d' | tail -n +3)
ExternalList=$(echo -e "\n" ; cat $ExternalFile)
AcmeList+=$ExternalList
for i in $AcmeList ; do
  ExprDate=($(echo | openssl s_client -showcerts -servername $i -connect $i:443 2>/dev/null | openssl x509 -inform pem -noout -text | egrep '(Not After : )' | sed 's/.*Not\ After\ \:\ //g' | { read gmt ; date -d "$gmt" +"%s" ; }))
#Get date in epoch when certificate must be updated
  UpdDate=$(expr $ExprDate - $Month)
#deprecated: Convert to CEST
  ExprDateCEST=`date -d @$ExprDate`
# Get days in epoch to expire date
  UntilDayEpoch=$(expr $ExprDate - $CurDate)
# Covert it to human format
  UntilDay=$(expr $UntilDayEpoch / 60 / 60 / 24)
   if (( CurDate > UpdDate )); then
      echo "$i expire in $UntilDay day(s)"
      STATUS+='1'
   else
      STATUS+='0'
   fi
done

if [[ $STATUS =~ "1"  ]]; then
#  echo "Some domain is expired soon. Check full script output"
  exit 1
else
  echo "All domains are OK"
  exit 0
fi
