#!/bin/bash -f
######################################################################
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
Help()
{
   echo "ERROR: Missing arguments"
   echo "Syntax: $ REPO_ROOT/bin/reconcile_env_tffiles.sh ENV1 CLUSTER1 ENV2 CLUSTER2"
   echo "options:"
   echo "    -h  Print this Help."
   echo "    -v  Verbose mode."
}
while getopts ":h" option; do
   case $option in
      h) Help
         exit;;
   esac
done
######################################################################
export ENVIRONMENT1="$1"
export CLUSTER1="$2"
export ENVIRONMENT2="$3"
export CLUSTER2="$4"

if [[ -z "$ENVIRONMENT1" || -z "$CLUSTER1" || -z "$ENVIRONMENT2" || -z "$CLUSTER2" ]]; then
  Help ;exit 9
fi

TFDIR1="env/$ENVIRONMENT1-env/clusters/$CLUSTER1/config/terraform"
TFDIR2="env/$ENVIRONMENT2-env/clusters/$CLUSTER2/config/terraform"
env="`echo $CLUSTER1 | awk -F "-" '{print $NF}'`-`echo $CLUSTER2 | awk -F "-" '{print $NF}'`"
TFOUT=$(mktemp -d tf-file-diff-$env)
echo "Checking the diff between environments $CLUSTER1 and $CLUSTER2"
for X in $(ls "$TFDIR1"); do                     # check each directory files
  [[ -d "$TFDIR1/$X" ]]              || continue # should be a directory...
  diff -I source --exclude=.terraform -x terraform.tfvars -x README.md -x backend.tf -x 'module-secrets.tfvars*' -x cluster-common.tfvars $TFDIR1/$X $TFDIR2/$X > "$TFOUT/$X" 2>&1 &
  dif=`grep '.tf' $TFOUT/$X| awk -F '/' '{print $NF}'`
  out=`grep '.tf' $TFOUT/$X| awk -F '/' '{print $NF}' | wc -l | awk '{print $NF}'`
  if [ $out -gt 0 ]; then
  echo "$red SERVICE=$X:  File differs which are - "; echo "$dif$reset"; else
  echo "$green SERVICE=$X:  No Changes Found, No service in $CLUSTER2$reset"
  fi
done


echo ..............................................;
ENV_TFDIR1="env/$ENVIRONMENT1-env/config/terraform"
ENV_TFDIR2="env/$ENVIRONMENT2-env/config/terraform"
for Y in $(ls "$ENV_TFDIR1"); do                     # check each directory files
  [[ -d "$ENV_TFDIR1/$Y" ]]              || continue # should be a directory...
  diff -I source --exclude=.terraform -x terraform.tfvars -x README.md -x backend.tf -x 'module-secrets.tfvars*' -x env-common.tfvars $ENV_TFDIR1/$Y $ENV_TFDIR2/$Y > "$TFOUT/provision-$Y" 2>&1 &
  dif=`grep '.tf' $TFOUT/$Y| awk -F '/' '{print $NF}'`
  out=`grep '.tf' $TFOUT/$Y| awk -F '/' '{print $NF}' | wc -l | awk '{print $NF}'`
  if [ $out -gt 0 ]; then
  echo "$red SERVICE=$Y:  File differs which are - "; echo "$dif$reset"; else
  echo "$green SERVICE=$Y:  No Changes Found, No service in $CLUSTER2$reset"
  fi
done
echo "Check Detailed differed output here: $TFOUT/SERVICE"
#
cd $TFOUT/
find . -type f -size -150c -delete
#trap "{ rm -rf '$TFOUT'; }" EXIT # Remove directory when everything is checked
