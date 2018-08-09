#!/bin/bash
#set -euo pipefail

THISHOST=$(/bin/hostname | cut -d "." -f 1) 
startTime=$(/bin/date +%s)

GRAPHURL="${1}"
BLUEMAC="${2}"

i=0
RESPONSE=""
while [[ $RESPONSE != *"Notification handle"*  &&  $i -lt 4 ]]
do
RESPONSE=$(timeout 10 gatttool -b ${BLUEMAC}  --char-write-req --handle=0x0010 --value=0100 --listen | head -n2 | tail -n1)
i=$[$i+1]
sleep 5s
done

if [[ $RESPONSE = *"Notification handle"* ]]; then
  RESPONSE=$(echo ${RESPONSE} | cut  -d ":" -f 2-)

  ASCII=""
  for CHAR in ${RESPONSE::-2}; do
      ASCII="${ASCII}$(printf "\x${CHAR}")" 
  done
  THERM=$(echo ${ASCII} | cut -d " " -f 1)
  HYDRO=$(echo ${ASCII} | cut -d " " -f 2)

  THERMVAL=$(echo ${THERM} | cut -d "=" -f 2)
  HYDROVAL=$(echo ${HYDRO} | cut -d "=" -f 2)

  METRIK="Climate."

  GRAFANASTR="3rdparty.${THISHOST}.Climate.Temperature ${THERMVAL} ${startTime}"
  # echo ${GRAFANASTR}
  /usr/bin/curl -m 30 --silent -d "metric=${GRAFANASTR}" ${GRAPHURL}
  GRAFANASTR="3rdparty.${THISHOST}.Climate.Humidity ${HYDROVAL} ${startTime}"
  # echo ${GRAFANASTR}
  /usr/bin/curl -m 30 --silent -d "metric=${GRAFANASTR}" ${GRAPHURL}
fi
