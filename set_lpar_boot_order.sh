HMC=XXXXX
HMC_USER=hscroot
HMC_PASS=XXXX
CEC=XXXX
LPAR=XXXX

# get current boot order
boot_device_list=$(sshpass -p "$HMC_PASS" ssh -o StrictHostKeyChecking=no $HMC_USER@$HMC "lssyscfg -r lpar -m $CEC -Fname,boot_device_list | grep $LPAR | cut -d '\"' -f2")
# put into array
vec=($(awk -F" " '{$1=$1} 1' <<<"${boot_device_list}"))

# if only one entry in boot list, request user to fix manually
if [ ${#vec[@]} -eq 1 ]; then
	str=$(echo "${vec[0]}" | grep "lan")
	if [ ! -z "$str" ]; then
		echo "Only lan entry found, user needs to add DISK as second boot order"
		exit 1
	fi
	str=$(echo "${vec[0]}" | grep -e "vfc\|scsi")
	if [ ! -z "$str" ]; then
		echo "Only DISK found, user must add ethernet dev to boot order and re-run script"
		exit 1
	fi
	echo "Only 1 entry in boot order, missing either eth/scsi: ${vec[0]}"
	exit 1
# else find lan entry and scsi entry
else
	j=0
	for b in "${vec[@]}"
	do
		str=$(echo "$b" | grep "lan")
		if [ ! -z "$str" ]; then
			vl=$j
		fi
		str=$(echo "$b" | grep -e "vfc\|scsi")
		if [ ! -z "$str" ]; then
			sc=$j
		fi

		j=$((j+1))
	done
fi
# set correct boot order
echo "setting new boot order: ${vec[$vl]} ${vec[$sc]}"
sshpass -p "$HMC_PASS" ssh -T -o StrictHostKeyChecking=no $HMC_USER@$HMC \
				"chsyscfg -r lpar -m $CEC -i 'name=$LPAR,boot_string=\"${vec[$vl]} ${vec[$sc]}\"'"

printf "Done!\nYou need to reboot lpar: sshpass -p "$HMC_PASS" ssh -o StrictHostKeyChecking=no $HMC_USER@$HMC \"chsysstate -r lpar -o shutdown --immed --restart -m $CEC -n $LPAR\"\n"
