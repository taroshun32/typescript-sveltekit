#!/bin/bash

base64url() {
  openssl enc -base64 -A | tr '+/' '-_' | tr -d '='
}

sign() {
  openssl dgst -binary -sha256 -sign <(printf '%s' "${PRIVATE_KEY}")
}

header="$(printf '{"alg":"RS256","typ":"JWT"}' | base64url)"

now="$(date '+%s')"
iat="$((now - 60))"
exp="$((now + (3 * 60)))"
template='{"iss":"%s","iat":%s,"exp":%s}'
payload="$(printf "${template}" "${APP_ID}" "${iat}" "${exp}" | base64url)"

signature="$(printf '%s' "${header}.${payload}" | sign | base64url)"
jwt="${header}.${payload}.${signature}"

installation_id="$(curl -X GET \
  -H "Authorization: Bearer ${jwt}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations" \
  | jq -r '.[0] | .id'
)"

token="$(curl --location --silent --request POST \
  --url "https://api.github.com/app/installations/${installation_id}/access_tokens" \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: Bearer ${jwt}" \
  | jq -r '.token'
)"
echo "${token}"
