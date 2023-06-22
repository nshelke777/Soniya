#!/bin/bash

usage() { cat <<-__USAGE__
	Usage: $0 <Tenant ID>
	  where <Tenant ID> is a Account ID associated with SFDC account ID of customer account.
	Examples:
	  $0  abcdefgh-ijklmnop-qrstuvwx
	__USAGE__
  exit 1;
}

if [ $# -lt 1 ]; then
  usage;
fi

export CDP_PROFILE=prod
export tenant_id=$1

cdp coreadmin get-account --account-id $tenant_id 2>/tmp/out| jq '.account.entitlements[].entitlementName' > ent.txt
sed -e 's/\"//g' ent.txt > entitlements.list
for i in $(cat entitlements.list)
do
  cdp coreadmin revoke-entitlement --entitlement-name $i --account-id $tenant_id | grep 'entitlementName' 2>/tmp/out | wc -l
  echo "Entitlement revoked = $i"
done
rm ent.txt entitlements.list