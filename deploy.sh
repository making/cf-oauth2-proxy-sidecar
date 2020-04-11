#!/bin/bash
set -e

$(which cf7 > /dev/null) || {
	echo "'cf7' is not installed!"
	exit 1
}
$(which jq > /dev/null) || {
	echo "'jq' is not installed!"
	exit 1
}

if [ ! -f oauth2_proxy ];then
	curl -Ls https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v5.1.0/oauth2_proxy-v5.1.0.linux-amd64.go1.14.tar.gz | tar xzv
	mv oauth2_proxy-*/oauth2_proxy ./
	rm -rf oauth2_proxy-*
fi

APP_NAME=$1
TARGET_SUBDOMAIN=$2

if [ "${APP_NAME}" = "" ];then
	echo -n "APP_NAME > "
	read APP_NAME
fi

if [ "${TARGET_SUBDOMAIN}" = "" ];then
	echo -n "TARGET_SUBDOMAIN > "
	read TARGET_SUBDOMAIN
fi


APPS_DOMAIN=$(cf7 curl "/v2/shared_domains" | jq -r ".resources[0].entity.name")

cf7 create-app ${APP_NAME}
APP_GUID=$(cf7 app ${APP_NAME} --guid)
cf7 curl "/v2/apps/${APP_GUID}" -X PUT -d "{\"ports\": [8080, 4180]}"

cf7 create-route ${APPS_DOMAIN} --hostname ${TARGET_SUBDOMAIN}
ROUTE_GUID=$(cf7 curl "/v2/routes?q=host:${TARGET_SUBDOMAIN}" | jq -r ".resources[0].metadata.guid")
cf7 curl /v2/route_mappings -X POST -d "{\"app_guid\": \"${APP_GUID}\", \"route_guid\": \"${ROUTE_GUID}\", \"app_port\": 4180}"

cf7 apply-manifest
cf7 push --strategy rolling