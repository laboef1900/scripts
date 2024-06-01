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

main() {

}

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