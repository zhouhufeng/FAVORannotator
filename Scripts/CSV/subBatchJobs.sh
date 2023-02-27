## define your array 
MYFILES=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)
echo ${MYFILES[*]}
## count how many elements I have
NUM=${#MYFILES[@]}
ZBNUM=$(($NUM -1 ))

if [ $ZBNUM -ge 0 ]; then
## not very elegant workaround to the array export issue:
## package the array into a string with a specific FS
STRINGFILES=$( IFS=$','; echo "${MYFILES[*]}" )

printf "STRINGFILES =  "
echo $STRINGFILES

export STRINGFILES

## example of how to reconvert into an array inside the slurm file
#IFS=',' read -r -a MYNEWFILES  <<< "$STRINGFILES"
#myiid=2
#CURRENTFILE=${MYNEWFILES[$myiid]}
#echo "currentfile is $CURRENTFILE "

## submit job 
sbatch --array=0-$ZBNUM subBatchJobs.txt
fi

