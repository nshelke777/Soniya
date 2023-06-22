#!/bin/bash -f
######################################################################
Help()
{
   echo "ERROR: Missing arguments"
   echo "Syntax: $ REPO_ROOT/bin/check_terraform_dependancies.sh ENV CLUSTER"
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
export ENVIRONMENT="$1"
export CLUSTER="$2"

if [[ -z "$ENVIRONMENT" || -z "$CLUSTER" ]]; then
  Help ;exit 9
fi

TFDIR1="env/$ENVIRONMENT-env/clusters/$CLUSTER/config/terraform"
TFDIR2="env/$ENVIRONMENT-env/config/terraform"
env="`echo $CLUSTER | cut -d '-' -f 2-`"
repobase="$(git rev-parse --show-toplevel)"
echo "Checking the modules in $CLUSTER"
for X in $(ls "$TFDIR1"|grep -v tfvars); do
  mod1=$(grep -R 'source ' --exclude-dir=.terraform $repobase/$TFDIR1/$X/ | awk -F '"' '{print $(NF-1)}'| awk -F".git//" '{print $2}' | awk -F"?" '{print $1}')
  for i in $(echo $mod1); do
    echo "Service=$X/$i" >>${env}_service_module_structure.list
  done
done
for Y in $(ls "$TFDIR2"|grep -v tfvars); do
  mod2=$(grep -R 'source ' --exclude-dir=.terraform $repobase/$TFDIR2/$Y/ | awk -F '"' '{print $(NF-1)}'| awk -F".git//" '{print $2}' | awk -F"?" '{print $1}')
  for j in $(echo $mod2); do
    echo "Service=$Y/$j" >>${env}_service_module_structure.list
  done
done
echo -e "...................................\nCheck Service-Module structure: ${env}_service_module_structure.list"
awk 'BEGIN{FS="/"; OFS="/"}{for (i=NF; i>0; i--) {printf "%s", $i;if (i>1) {printf "%s", OFS;}}printf "\n"}'< ${env}_service_module_structure.list > ${env}_module_service_structure.list
echo -e "...................................\nCheck Module-Service structure: ${env}_module_service_structure.list"
tr -s '/' ',' <${env}_service_module_structure.list>${env}_service_module_structure.csv
#tr -s '/' ',' <${env}_module_service_structure.list>${env}_module_service_structure.csv