#!/bin/bash
# Script to print the # of minutes until filesystem fills up
# Based on the following one-liner:
# echo "`df / | tail -n1 | awk '{print $4}'` / (`df / | tail -n1 | awk '{print $4}' ; sleep 60` - `df /| tail -n1 | awk '{print $4}'`)" | bc

# How many seconds to sleep between df pools
# The more time you can use here, the more stable your sample will be.
# 300 seconds (5 mins) is best.

# Helpful usage function
usage() {
    echo "Usage: $(basename $0) [OPTIONS]"
    echo ""
    echo "Options:"
    echo "--path=/path/to/filesystem ('/' used by default)"
    echo "--seconds=N Seconds to wait ('300' used by default)"
    exit 1
}

# Handle our args
while [ $# -gt 0 ]; do

    # Make sure we got a valid argument like --seconds=10
    arg="$(echo $1 | grep '\-\-' | grep '=')"
    if [ -z "${arg}" ]; then
        echo "Invalid Argument: '$1'" >&2
        usage >&2
        exit 1
    fi
    
    # Figure out which option was passed
    opt="$(echo $1 | cut -d '=' -f -1)"
    if [ -z "${opt}" ]; then
        echo "Invalid Argument: '$1'" >&2
        usage >&2
        exit 1
    fi
    
    # Setup our variables
    if [ "${opt}" == '--seconds' ]; then
        sleepTime="$(echo ${arg} | cut -d '=' -f 2- | sed '/[^0-9]/d')"
        if [ -z "${sleepTime}" ]; then
            echo "Invalid number of seconds: '${arg}'"
            usage >&2
            exit 1
        fi
    elif [ "${opt}" == '--path' ]; then
        ourMount="$(echo ${arg} | cut -d '=' -f 2-)"
        if [ -z "${ourMount}" ]; then
            echo "Invalid path given: '${arg}'"
            usage >&2
            exit 1
        fi
    else
        echo "Unknown option: '${opt}'" >&2
        usage >&2
        exit 1
    fi

    shift

done

# Fill in defaults if needed.
[ -z "${sleepTime}" ] && sleepTime='300'
[ -z "${ourMount}" ] && ourMount='/'


# Used to poll df for available blocks
mountAvailable() {

    df ${ourMount} | tail -n1 | awk '{print $4}' | sed '/[^0-9]/d'

}

########
# MAIN #
########

echo -n "Getting first number of available blocks for '${ourMount}'..."
firstMount="$(mountAvailable)"
if [ -z "${firstMount}" ]; then
    echo 'failed.' >&2
    exit 1
fi
echo 'done.'
echo "Number of available blocks: ${firstMount}"

echo "Sleeping for ${sleepTime} seconds."
sleep ${sleepTime}

echo -n "Getting second number of available blocks for '${ourMount}'..."
secondMount="$(mountAvailable)"
if [ -z "${secondMount}" ]; then
    echo 'failed.' >&2
    exit 1
fi
echo 'done.'
echo "Number of available blocks: ${secondMount}"

# Build string
string="${firstMount} / ( ${firstMount} - ${secondMount} )"

# Make sure we have work to do
if [ "${firstMount}" -lt "${secondMount}" ]; then
    echo "The number of blocks available went up, not down."
    echo "Something is freeing up space on ${ourMount}"
    exit 1
elif [ "${firstMount}" -eq "${secondMount}" ]; then
    echo "The number of available blocks has not moved."
    echo "The free space on ${ourMount} is stagnant."
    exit 1
fi

result="$(echo "${string}" | bc)"
resultType='minutes'

# Move up to hours
if [ "${result}" -gt '60' ]; then
    lastNum="${result}"
    lastType="${resultType}"
    result="$((result/60))"
    resultType='hours'
fi

# Move up to days
if [ "${result}" -gt '24' ]; then
    lastNum="${result}"
    lastType="${resultType}"
    result="$((result/24))"
    resultType='days'
fi

# Print our summary
echo -n "Our mount point ${ourMount} will fill up in ${result} ${resultType} "
echo "(${lastNum} ${lastType})"
exit 0
