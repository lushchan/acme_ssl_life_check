#!/bin/bash
#current date in epoch format
CurDate=$(date +"%s")
#debug
#CurDate="1639394914"

#Path to file with non-acme domains
ExternalFile="/usr/lib64/nagios/plugins/external"

#Create file for non-acme domainns if not exist
if [[ ! -e $ExternalFile ]]; then
    touch $ExternalFile
fi

# Get domains from acme client
AcmeList=$(/root/.acme.sh/acme.sh --list | awk '{doms=$1" "$3; print doms}' | sed 's/,/\n/g' | sed 's/\s/\n/g' | sed '/^no$/d' | sed -e '/\*\./d' | sed -e '/www\./d' | tail -n +3)
# Get domains from external list
ExternalList=$(echo -e "\n" ; cat $ExternalFile | sed -e 's/\,/\n/g' | sed -e 's/\s/\n/g' | sed -e '/^$/d')
# Concat two lists
AcmeList+=$ExternalList
# help func
Help() {
echo "Help"
echo "Options:"
echo "-h - help"
echo "-w - set warning threshold in days"
echo "-c - set critical threshold in days"
echo "If you wanna check non-acme certs, place domains in $ExternalFile"
}
# Get opts for script
while getopts ":w:c:h" options; do
  case "${options}" in
    w)
       WARNING=${OPTARG}
       ;;
    c)
       CRITICAL=${OPTARG}
       ;;
    h) Help
       exit 0
       ;;
    :)
      echo "Error: -${OPTARG} is empty.Please set threshhold in days for -w as warning and -c as critical"
      Help
      exit 3
      ;;
    *)
      echo "Unknown argument -${OPTARG}"
      Help
      exit 3
      ;;
  esac
done

if [ -z "$WARNING" ] ; then
        echo "WARNING threshold is missing. Check -h for help"
        echo ""
        Help
        exit 3
elif [ -z "$CRITICAL" ] ; then
        echo "CRITICAL threshold is missing. Check -h for help"
        echo ""
        Help
        exit 3
fi
#main
for i in $AcmeList ; do
# Get expire date
  ExprDate=($(echo | openssl s_client -showcerts -servername $i -connect $i:443 2>/dev/null | openssl x509 -inform pem -noout -text | egrep '(Not After : )' | sed 's/.*Not\ After\ \:\ //g' | { read gmt ; date -d "$gmt" +"%s" ; }))
# Get days in epoch to expire date
  UntilDayEpoch=$(expr $ExprDate - $CurDate)
# Covert it to human format
  UntilDay=$(expr $UntilDayEpoch / 60 / 60 / 24)
  if (( $UntilDay <= $CRITICAL )); then
    echo "$i expire in $UntilDay day(s)"
    STATUS+='2'
  elif (( $UntilDay <= $WARNING )); then
    echo "$i expire in $UntilDay day(s)"
    STATUS+='1'
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
