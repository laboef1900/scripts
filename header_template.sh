#!/bin/bash
# SYNOPSIS
#    
# DESCRIPTION
#    This is a script template
#    to start any good shell script.
#
# OPTIONS
#
# EXAMPLES
#    ${SCRIPT_NAME} -o DEFAULT arg1 arg2
#
#================================================================
# IMPLEMENTATION
#    version         ${SCRIPT_NAME} 0.0.1
#    author          Simon
#    license         GNU GENERAL PUBLIC LICENSE Version 3
#################################################################
# Help                                                          #
#################################################################
help() {
cat << EOF
Template
Usage: ./tool.sh [-g|h|v|V]
This is a template

-h     Print this Help

EOF
}

#################################################################
# Main program                                                  #
#################################################################


#######################################
# Check that the required tools are available, if not exit the script.
# Arguments:
#   None
# Outputs:
#   Error with the names of tools that are not installed
#######################################
pre_check(){
  local check_pass='true'

  if ! command -v parted &> /dev/null; then
    echo -e "\e[31m"
    echo "parted is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if ! command -v pvresize &> /dev/null; then
    echo -e "\e[31m"
    echo "pvresize is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if ! command -v lsblk &> /dev/null; then
    echo -e "\e[31m"
    echo "lsblk is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if ! command -v lvs &> /dev/null; then
    echo -e "\e[31m"
    echo "lvs is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if ! command -v pvs &> /dev/null; then
    echo -e "\e[31m"
    echo "pvs is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if ! command -v lvresize &> /dev/null; then
    echo -e "\e[31m"
    echo "lvresize is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if ! command -v resize2fs &> /dev/null; then
    echo -e "\e[31m"
    echo "resize2fs is NOT installed!"
    echo -en "\e[39m"
    check_pass='false'
  fi

  if [[ $check_pass == 'false' ]]; then
    echo "Exiting Script, install missed tools!"
    echo -en "\e[39m"
    exit 1
  fi
}

initializeParition(){
    echo "No partition detected on $device."

    read -p "Create a new GPT parition ? [Y/n] " new_partition
    new_partition=${new_partition:-Y}

    if [[ $new_partition == "Y" || $new_partition == "y"  ]]; then
        # Create GPT partition
        parted --script $device mklabel gpt
        parted --script $device mkpart primary 1M 100%
        #new_disk = true

        echo "GPT Parition created"

        read -p "Create a PV for LVM ? [Y/n] " new_pv
        new_pv=${new_pv:-Y}

        if [[ $new_pv == "Y" || $new_pv == "y" ]]; then
            # Create a PV
            pvcreate "${device}1"
            echo "New PV created"
            pvs

            echo ""
            read -p "Add PV to existing VG ? [y/N] " add_pv2vg
            add_pv2vg=${add_pv2vg:-N}

           if  [[ $add_pv2vg == "N" || $add_pv2vg == "n" ]]; then
                # Create a new VG
                read -p "Add PV to a new VG ? [Y/n] " create_vg
                create_vg=${create_vg:-Y}

                if [[ $create_vg == "Y" || $create_vg == "y" ]]; then
                    # Create a new VG
                    read -p "Define new VG Name: " vg_name
                    vgcreate $vg_name "${device}1"
                    echo "New VG created"
                    vgs

                    echo -e "\e[33m--- Create a nev LV ---"
                    echo -en "\e[39m"
                    options=("LV with 100% of Free space" "Set size in GB" "Quit")

                    select opt in "${options[@]}"
                    do
                        case $opt in
                            "LV with 100% of Free space")
                                read -p "Define new LV Name " lv_name
                                lvcreate -n $lv_name -l 100%FREE $vg_name
                                echo "LV created"
                                echo "Add mountpoint to /etc/fstab manualy!"
                                lvs
                                ;;
                            "Set size in GB")
                                read -p "Define new LV Name " lv_name
                                read -p "Set LV size in GB (eg. 25G): " lv_size
                                lvcreate -n $lv_name -L $lv_size $vg_name
                                echo "LV created"
                                echo "Add mountpoint to /etc/fstab manualy!"
                                lvs
                                ;;
                            "Quit")
                                echo "Exiting script!"
                                sleep 5
                                exit 0
                                break
                                ;;
                            *) echo "invalid option $REPLY";;
                        esac
                    done
                else
                    # Abort
                    echo -e "\e[31m"
                    echo "Exiting script! Just PV created"
                    echo -en "\e[39m"
                    sleep 5
                    exit 1
                fi
            else
                # Add PV to an existing VG
                read -p "Which vg should be expanded? (vg_name) " vg_expand
                vgextend $vg_expand "${device}1"
                vgs

                echo "Task finished! Exiting skript"
                echo -en "\e[39m"
                sleep 5
                exit 0
            fi
        else
            # No PV should be created
            # Option 2 Format disk and create a mount point
            echo "Create a Filesystem!"
            read -p "Define Filesystem: [ext4|xfs] " fs

            echo "Format the disk as following?"
            volumePartition="${volume}1"
            echo -e "Volume: ${volumePartition} \nFilesystem: $fs"

            read -p "Format Filesystem ? [y/N] " formating
            formating=${formating:-N}

            if  [[ $formating == "Y" || $formating == "y" ]]; then
                sudo mkfs -t $fs $volumePartition

                echo -e "\e[33m--- Formating finished, exiting script ---"
                echo -en "\e[39m"
                sleep 5
                exit 0
            else
                echo -e "\e[31m"
                echo "Aboart formating, exitign script!"
                echo -en "\e[39m"
                sleep 5
                exit 1
            fi
        fi

    else
        # Abort no Parition should be created
        echo -e "\e[31m"
        echo "Exiting script! Creat partition first."
        echo -en "\e[39m"
        sleep 5
        exit 1
    fi
}
main(){
    # Main
    pre_check

    for x in /sys/class/scsi_disk/*; do echo '1' > "$x/device/rescan"; done

    echo -e "\e[33m--- ALL DEVICES ---"
    echo ""
    echo -en "\e[39m"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

    read -rp "Volume to expand [/dev/sda2]: " volume
    volume=${volume:-/dev/sda2}
    device=$(echo $volume |  cut -b -8)
    deviceNumber=$(echo $volume |  cut -b 9)

    if [[ $deviceNumber == "" ]]; then
        initializeParition
    fi

    clear
    echo -e "\e[33m--- ALL PARTITIONS AND FREE SIZE ---"
    echo -en "\e[39m"
    parted --script $device print free
    echo ""
    read -p "Select partition to expand [$deviceNumber]: " partition
    partition=${partition:-${deviceNumber}}

    #read -p 'Set end size of parition with unit e.g. "60GB": ' endSize
    parted --script $device resizepart $partition 100% quit

    volume2check=$(lsblk $volume -o MOUNTPOINT)
    result_volume2check=$(echo $volume2check | cut '-d ' "-f2")

    #Check if the volume a lvm
    check_lvm=$(pvs $volume 2>&1)
    is_umounted=0
    if [ $? -ne 0 ]; then
        # Not a LVM
        lv=$volume

        # Check if voume is mounted
        if [ $result_volume2check == "MOUNTPOINT" ]; then
            # Volume is not mounted
            echo 'Volume is not mounted'
        else
            # Volume is mounted
            echo -e "\e[31m"
            echo "Volume is not LVM! And has to be unmounted "
            echo -en "\e[39m"

            # Unmount volume if user agres
            read -p "Unmount "$result_volume2check" ? [Y/n] " volume_unmount
            volume_unmount=${volume_unmount:-Y}
            if [ $volume_unmount == "Y" ]; then
                umount $result_volume2check
                is_umounted=1
            else
                echo -e "\e[31m"
                echo "Exiting script unmount the volume first."
                echo -en "\e[39m"
                sleep 5
                exit 1
            fi
        fi

    else
        # Volume is a LVM
        pvresize  $volume
        clear

        echo -e "\e[33m--- New PV Size ---"
        echo -en "\e[39m"
        pvs
        echo ""

        echo -e "\e[33m--- All LVs ---"
        echo -en "\e[39m"
        lvs
        echo ""

        read -p "Select VG [vg_root]" selecteVG
        selecteVG=${selecteVG:-vg_root}

        read -p "Select LV to expand [var]" lvToExpand
        lvToExpand=${lvToExpand:-var}

        lv="/dev/mapper/${selecteVG}-${lvToExpand}"
        echo $lv

        read -p "Expand by e.g. (5G):" resizeby
        resizeby=${resizeby:-5G}
        lvresize -L +$resizeby $lv
    fi

    #Chedk Filesystem
    fileSystemCheck=$(udevadm info --query=property $lv | egrep "ID_FS_TYPE")
    fileSystem=$(echo $fileSystemCheck | cut '-d=' "-f2")
    if [ $is_umounted -eq 1 ]; then
        echo -e "\e[33m--- Remount Volumes ---"
        echo -en "\e[39m"
        echo ""
        mount -a
    fi

    if [ "$fileSystem" == "xfs" ]; then
        xfs_growfs $lv
        clear
        echo -e "\e[33m--- XFS resize finished! ---"
        echo -en "\e[39m"
    elif [ "$fileSystem" == "ext4" ]; then
        e2fsck -f $lv
        resize2fs $lv
        clear
        echo -e "\e[33m--- EXT4 resize finished! ---"
        echo -en "\e[39m"
    fi

    df -h
}

clear
main "$@"



#################################################################
# Process the input options. Add options as needed.             #
#################################################################
# Get the options
while getopts ":h" option; do
    case $option in
        h) # display Help
            help
            exit;;
        *) # Invalid option
            help
            exit
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${k}" ] || [ -z "${p}" ]; then
  help
else
  main "$@"
fi