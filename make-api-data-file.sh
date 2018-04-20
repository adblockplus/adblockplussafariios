#!/bin/bash
#
# Manage API data for AdblockPlus Safari iOS.

API_DATA_ENV_VARS="ABP-Secret-API-Env-Vars.sh"
if [ -f ./$API_DATA_ENV_VARS ]
then
    source ./$API_DATA_ENV_VARS
else
    echo "warning: API data not found. The app will run but will not have access to API functions."
    exit 0
fi
sourcery --templates . --sources . --output ./Generated/ --args endpointReceive=\"$ENDPOINT_RECEIVE_DEVICE_DATA\",keyReceive=\"$KEY_API_DEVICE_DATA\"
