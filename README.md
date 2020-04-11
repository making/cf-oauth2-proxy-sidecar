# Example Cloud Foundy Sidecar with OAuth2 Proxy

* https://docs.cloudfoundry.org/devguide/sidecars.html
* https://oauth2-proxy.github.io/oauth2-proxy

![image](https://user-images.githubusercontent.com/106908/79045833-4415f280-7c48-11ea-894b-23e8164bd24c.png)

## How to deploy

### Install CF CLI 7

```
CF7_CLI_VERSION=7.0.0-beta.30
wget -q -O cf.tgz "https://packages.cloudfoundry.org/stable?release=macosx64-binary&version=${CF7_CLI_VERSION}&source=github-rel" && \
    tar xzf cf.tgz && \
    sudo install cf7 /usr/local/bin/ && \
    rm -f cf* LICENSE NOTICE
```

### Download OAuth2 Proxy

```
curl -Ls https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v5.1.0/oauth2_proxy-v5.1.0.linux-amd64.go1.14.tar.gz | tar xzv
mv oauth2_proxy-*/oauth2_proxy ./
rm -rf oauth2_proxy-*
```

### Deploy app with OAuth2 Proxy sidecar


1. Create a new OAuth App: https://github.com/settings/developers
1. Under Authorization callback URL enter the correct url ie `https://${TARGET_SUBDOMAIN}.${APPS_DOMAIN}/oauth2/callback`
1. Create an user provided service with information you created above as follows:
```
cf7 create-user-provided-service github-oauth-app -p '{"github_org": "YOUR-ORG", "github_client_id": "YOUR-CLIENT-ID", "github_client_secret": "YOUR-CLIENT-SECRET"}'
```
1. Deploy with following steps:
```
APP_NAME=hello
APPS_DOMAIN=$(cf7 curl "/v2/shared_domains" | jq -r ".resources[0].entity.name")
TARGET_SUBDOMAIN=demo-oauth2-proxy

cf7 create-app ${APP_NAME}
APP_GUID=$(cf7 app ${APP_NAME} --guid)
cf7 curl "/v2/apps/${APP_GUID}" -X PUT -d "{\"ports\": [8080, 4180]}"

cf7 create-route ${APPS_DOMAIN} --hostname ${TARGET_SUBDOMAIN}
ROUTE_GUID=$(cf7 curl "/v2/routes?q=host:${TARGET_SUBDOMAIN}" | jq -r ".resources[0].metadata.guid")
cf7 curl /v2/route_mappings -X POST -d "{\"app_guid\": \"${APP_GUID}\", \"route_guid\": \"${ROUTE_GUID}\", \"app_port\": 4180}"

cf7 apply-manifest
cf7 push
```

> Note: `Authorization callback URL` of the OAuth2 Apps must be `https://${TARGET_SUBDOMAIN}.${APPS_DOMAIN}/oauth2/callback`

or you can use `deploy.sh` instead as follows:

```
./deploy hello demo-oauth2-proxy
```

Go to `https://${TARGET_SUBDOMAIN}.${APPS_DOMAIN}`
