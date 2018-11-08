#!/bin/bash
function secondsInDays () {
    seconds=$1
    echo $((seconds / (60*60*24)))
}

function logSuccess() {
    echo -e "\033[32;1m$1\033[0m"
}

function logWarning() {
    echo -e "\033[33;1m$1\033[0m"
}

function logError() {
    echo -e "\033[31;1m$1\033[0m"
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
echo ""

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
        logWarning "$name $daysRemaining days remainig (should update)"
        warnings=$((warnings+1))
        continue
    fi

    logError "$name $daysRemaining days remainig (must update)"
    errors=$((errors + 1))
done < <(security find-certificate -a | grep '"alis"<blob>=' | cut -f2 -d= | sed -e 's/^"//' -e 's/"$//')

echo ""
echo "Results"
if [ "$warnings" -gt "0" ]
then
    logWarning "> $warnings warnings"
else
    echo "> $warnings warnings"
fi
if [ "$errors" -gt "0" ]
then
    logError "> $errors errors"
else
    echo "> $errors errors"
fi

envman add --key VALIDATE_CERTIFICATES_WARNINGS --value "$warnings"
envman add --key VALIDATE_CERTIFICATES_ERRORS --value "$errors"

exit $errors