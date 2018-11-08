#!/bin/bash

function secondsInDays () {
    seconds=$1
    echo $((seconds / (60*60*24)))
}

reset=`tput sgr0`

function logSuccess() {
    tput setaf 2; echo "$1"; tput sgr0
}

function logWarning() {
    tput setaf 3; echo "$1"; tput sgr0
}

function logError() {
    tput setaf 1; echo "$1"; tput sgr0
}

currentTimestamp=$(/bin/date "+%s")

warningDays=${validate_certificate_days}

if [ -n "${validate_certificate_error_days}" ]; then
    errorDays=${validate_certificate_error_days}
else
    errorDays=$((warningDays/2))
fi

echo "Warning Days: $warningDays"
echo "Error Days: $errorDays"

errors=0
warnings=0

while read name; do
    certexpdate=$(/usr/bin/security find-certificate -a -c "$name" -p | /usr/bin/openssl x509 -noout -enddate| cut -f2 -d=)
    if [[ -z "$certexpdate" ]] 
    then
        continue
    fi
    timestamp=$(/bin/date -j -f "%b %d %T %Y %Z" "$certexpdate" "+%s")
    if [ "$?" -eq "1" ]
    then
        continue
    fi
    diff=$((timestamp - currentTimestamp))
    daysRemaining=$(secondsInDays diff)

    if [ "$daysRemaining" -gt "$warningDays" ]
    then
        logSuccess "$name $daysRemaining days remainig"
        continue
    fi

    if [ "$daysRemaining" -gt "$errorDays" ]
    then
        logWarning "$name $daysRemaining days remainig"
        warnings=$((warnings+1))
        continue
    fi

    logError "$name $daysRemaining days remainig"
    errors=$((errors + 1))
done < <(security find-certificate -a | grep '"alis"<blob>=' | cut -f2 -d= | sed -e 's/^"//' -e 's/"$//')

echo "$warnings warnings"
echo "$errors errors"

envman add --key VALIDATE_CERTIFICATES_WARNINGS --value "$warnings"
envman add --key VALIDATE_CERTIFICATES_ERRORS --value "$errors"

exit $errors