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
#===========================================================
# IMPLEMENTATION
#    version         ${SCRIPT_NAME} 0.0.1
#    author          Simon
#    license         GNU GENERAL PUBLIC LICENSE Version 3
############################################################
# Help                                                     #
############################################################
hlp() {
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-g|h|v|V]"
   echo "options:"
   echo "g     Print the GPL license notification."
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "V     Print software version and exit."
   echo
}

############################################################
# Main program                                             #
############################################################



############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         help
         exit;;
   esac
done

echo "Hello world!"