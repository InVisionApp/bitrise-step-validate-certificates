#!/bin/bash
function secondsInDays () {
    seconds=$1
    echo $((seconds / (60*60*24)))
}

function shouldIgnore () {
    name="$1"
    while IFS=',' read -ra parts; do
        for part in "${parts[@]}"; do
            if [[ "$name" == *"$part"* ]] ; then 
                return 1
            fi
        done
    done <<< "$2"
    return 0
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

errorDays=${validate_certificate_error_days}

if [ -n "${validate_certificate_warning_days}" ]; then
    warningDays=${validate_certificate_warning_days}    
else
    warningDays=$((errorDays*2))
fi

keyChainPath=""
if [ -n "${validate_certificate_key_chain_path}" ]; then
    eval keyChainPath="$validate_certificate_key_chain_path"
fi 

ignore=""
if [ -n "${validate_certificate_ignore}" ]; then
    ignore="$validate_certificate_ignore"
fi 


echo "Warning Days: $warningDays"
echo "Error Days: $errorDays"
echo "Keychain: $keyChainPath"
echo "Ignore: $ignore"

success=0
ignored=0
errors=0
warnings=0

while read name; do
    shouldIgnore "$name" "$ignore"
    if [ "$?" -eq "1" ] ; then
        echo "Ignoring $name"
        ignored=$((ignored+1))
        continue
    fi
    
    certexpdate=$(/usr/bin/security find-certificate -a -c "$name" -p | /usr/bin/openssl x509 -noout -enddate| cut -f2 -d=)
    if [[ -z "$certexpdate" ]] 
    then
        logWarning "Could not load certificate $name"
        warnings=$((warnings+1))
        continue
    fi
    timestamp=$(/bin/date -j -f "%b %d %T %Y %Z" "$certexpdate" "+%s")
    if [ "$?" -eq "1" ]
    then
        logWarning "Could not load expiration date for certificate $name"
        warnings=$((warnings+1))
        continue
    fi
    diff=$((timestamp - currentTimestamp))
    daysRemaining=$(secondsInDays diff)

    if [ "$daysRemaining" -gt "$warningDays" ]
    then
        logSuccess "$name $daysRemaining days remainig"
        success=$((success+1))
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
done < <(security find-certificate -a $keyChainPath | grep '"alis"<blob>=' | cut -f2 -d= | sed -e 's/^"//' -e 's/"$//')


echo ""
echo "Results"
echo "  Success:  $success"
echo "  Ignored:  $ignored"
echo "  Warnings: $warnings"
echo "  Errors:   $errors"

envman add --key VALIDATE_CERTIFICATES_SUCCESS --value "$success"
envman add --key VALIDATE_CERTIFICATES_IGNORED --value "$ignored"
envman add --key VALIDATE_CERTIFICATES_WARNINGS --value "$warnings"
envman add --key VALIDATE_CERTIFICATES_ERRORS --value "$errors"

exit $errors