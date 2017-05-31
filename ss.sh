###############################################################################
#
# Synopsis: start_scripts.sh script how_many user/password
# Purpose:	runs script how_many times in background via nohup
#
# Copyright:	Enkitec
# Author:	Kerry Osborne
#
###############################################################################

if [ $# -ne 3 ]
then
    echo " "
    echo "Usage: start_scripts.sh script how_many user/password"
    exit 1
fi

echo " "
echo "starting" $2 "copies of" $1
echo " "

rm ./nohup.out
cat >> temp_submit << MYEOF
sqlplus -s <<EOF
$3
@$1 
exit
EOF
MYEOF
chmod 777 temp_submit

i=0
while [ ${i} -lt $2 ]
do
  nohup temp_submit &
  i=`expr $i + 1`
done

sleep 2
rm ./temp_submit

echo " "
echo "started" $2 "copies of" $1
