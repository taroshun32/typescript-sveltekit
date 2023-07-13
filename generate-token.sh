#!/bin/bash

base64url() {
  openssl enc -base64 -A | tr '+/' '-_' | tr -d '='
}

sign() {
  openssl dgst -binary -sha256 -sign <(printf '%s' "${PRIVATE_KEY}")
}

echo "${PRIVATE_KEY}"

header="$(printf '{"alg":"RS256","typ":"JWT"}' | base64url)"
echo header=${header}

now="$(date '+%s')"
iat="$((now - 60))"
exp="$((now + (3 * 60)))"
template='{"iss":"%s","iat":%s,"exp":%s}'
payload="$(printf "${template}" "${APP_ID}" "${iat}" "${exp}" | base64url)"
echo payload=${payload}

signature="$(printf '%s' "${header}.${payload}" | sign | base64url)"
echo ${signature}
jwt="${header}.${payload}.${signature}"
echo ${jwt}

installation_id="$(curl --location --silent --request GET \
  --url "https://api.github.com/app/installations" \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: Bearer ${jwt}" \
  | jq -r '.[0] | .id'
)"

token="$(curl --location --silent --request POST \
  --url "https://api.github.com/app/installations/${installation_id}/access_tokens" \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: Bearer ${jwt}" \
  | jq -r '.token'
)"
echo "${token}"
