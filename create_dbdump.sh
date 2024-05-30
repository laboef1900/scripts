#!/bin/bash
# SYNOPSIS
#    Create a DB Backup with mysqldump
# DESCRIPTION
#   Creates a DB Backup of MySQL or MariaDB with mysqldump
#   and checks if old backups shuld deleted. This script
#   should be run periodically through a crontab job.
#
# OPTIONS
#
# EXAMPLES
#    ${SCRIPT_NAME} -o DEFAULT arg1 arg2
#
#===========================================================
# IMPLEMENTATION
#    version         ${SCRIPT_NAME} 0.0.1
#    author          Simon
#    license         GNU GENERAL PUBLIC LICENSE Version 3
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-g|h|v|V]"
   echo "options:"
   echo "u      Set the backup user"
   echo "p      Set the password for the backup user"
   echo "c      Add the script to crontab"
   echo "g      Print the GPL license notification."
   echo "h      Print this Help."
   echo "v      Verbose mode."
   echo "V      Print software version and exit."
   echo
}
############################################################
# Main program                                             #
############################################################
# Set default values for variables
user="backup"
password="AddYourStrongPassword"
host="localhost"
db_name="all"

# Other options
backup_path="/mnt/backup"
date=$(date +"%Y%m%d_%H%M")
recipients="backup@domain.com"
from="dbserver@domain.com"

# Set default file permissions
umask 177

# Dump database into SQL file
mysqldump --user=$user --password=$password --host=$host --single-transaction --skip-lock-tables --flush-privileges --all-databases > $backup_path/$db_name-$date.sql

# Delete files older than 1 dayas, 14 days storage snapshots
find $backup_path/* -mtime +1 -maxdepth 1 -exec rm {} \;

#check if backup existsi
if [[ -s $backup_path/$db_name-$date.sql ]] 
then
    subject="Backup success"
    body="SQL Dump on $(hostname) finished"
else
    subject="Backup failed"
    body="SQL Dump on $(hostname) failed"
fi
mail="subject:$subject\nfrom:$from\n$body"
echo -e $mail | /sbin/sendmail "$recipients"

create_crontab() {
    
}

main () {

}

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":h" option; do
    case $option in
        u) # set the backup user


        c) # setup a crontab job
    

        h) # display Help
            help
            exit;;
   esac
done

echo "Hello world!"