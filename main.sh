#! /bin/bash

# --- 1. Verify the input ---

function display_usage() {
    echo "Usage: $0 -[fFsv]"
    echo "       $0 -[fFqs]"
    echo "Options:"
    echo "  -f: Force continuation of script upon warning(s)"
    echo "  -F: Force continuation of script upon warnings and silences warning(s) (same as -F -q)"
    echo "  -h: displays this Help page"
    echo "  -q: silences (Quiet) output"
    echo "  -s: Skips reporting to HTTP Endpoint"
    echo "  -v: increases Verbosity of output"
    echo "      if -F is defined, replaces with -f"
}

function error_input_option_q_v() {
    echo "Input Validation Error: Options -q and -v cannot be used at the same time."
    echo ""
    display_usage
    exit 1003
}

# Parse Input
verbosity=1
suppress_http=0
force=0
while getopts "fFhqsv" opt; do
    case $opt in
        f)
        if [[ ! $force == 2 ]]; then
            force=1
        fi
        ;;

        F)
        force=2
        ;;

        h)
        display_usage
        exit 0
        ;;

        q)
        if [ $verbosity = 2 ]; then
            error_input_option_q_v
        fi
        verbosity=0
        ;;

        s)
        suppress_http=1
        ;;

        v)
        if [ $verbosity = 0 ]; then
            error_input_option_q_v
        fi
        verbosity=2
        ;;

        \?)
        echo "Invalid option: -$OPTARG"
        display_usage_short
        exit 1001
        ;;

        :)
        echo "Option -$OPTARG requires an argument"
        display_usage_short
        exit 1002
        ;;
    esac
done

if [[ $force == 1 && $verbosity == 0 ]]; then force=2
elif [[ $force == 2 && $verbosity == 2 ]]; then
    echo "Warning: Ignoring -F and applying -f. Verbosity takes precedence over force options"
    force=1
fi

# Check if required files exist
if [ ! -f "./Config.json" ]; then
    echo "Configuration Error: config file could not be found. Please ensure Config.json exists within your present working directory, then run again."
    exit 2001
fi

if [ ! -f "./Keys.txt" ]; then
    echo "Configuration Error: the keys file does not exist. Please reinstall this script file and ensure a valid ./keys.txt file is generated."
    exit 2002
fi

# Input and test configuration
CONFIG='./Config.json'
NUMBER_OF_KEYS=""
if [[ ! -z $(grep -E '\"Number_Of_Keys\":[0-9]{1,}' $CONFIG) ]]; then
    cat $CONFIG | jq -r '.Properties.Number_Of_Keys'
fi

# Get key number to key type correlation
KEY_TYPES_JSON=$(cat $CONFIG | jq -r '.Properties.Key_Types') 
noquote=$(echo $KEY_TYPES_JSON | tr -d \"\,[])
KEY_TYPES=($noquote)


# --- 2. Call one or more grading scripts ---

#function compare_hashes() {
#    ALGORITHM=$1; HASH=$2; SALT=$3; COMPARISONCLEARTEXT=$4

#    if $3; then   # If salt was input
#        key="$COMPARISONCLEARTEXT$SALT"
#    else
#        key=$COMPARISONCLEARTEXT
#    fi

#    hash_resultant=$(echo $key | $ALGORITHM | awk '{print $1}')

#    if [[ $HASH == $hash_resultant ]]; then
#        return 0    # hashes match
#    else
#        return 1    # hashes don't match
#    fi
#}

# if decryption key not in library, import decryption key
#if [[ ! -v $(gpg --list-public-keys | grep `cat ./Crypto/decrypt.key.pub.fingerprint`) ]]; then 
#    gpg --import `cat ./Crypto/decrypt.key.pub`
#fi

# setting up comparison variables
#CRYPTO_HASHES=$(gpg --decrypt ./Crypto/comparison-scripts-hashes.json.gpg)
#SCRIPT_SALT=$(echo $CRYPTO_HASHES | jq -r '.salt')
#SCRIPT_NAMES=('hash.sh', 'key.sh', 'line.sh', 'not-my-problem.sh')
#ALGORITHM=(echo $CRYPTO_HASHES | jq -r '.hash_program')

# verify bash scripts are unaltered
#for script_name in $SCRIPT_NAMES; do
#    cleartext_file=$(cat ./Crypto/$script_name)
#    curr_hash=$(echo $CRYPTO_HASHES | jq -r .Files.$script_name)

#    compare_hashes $ALGORITHM $curr_hash $SCRIPT_SALT $cleartext_file
#    if $?; then
#        echo "File Integrity Error: the script $script_name failed it's integrity check. Stopping!"
#        exit 3001
#    fi
#done

counter=1
analysis_file_paths=''
nmp_present=0

if [[ $verbosity == 1 ]]; then echo "----- output ----"; fi

for type in ${KEY_TYPES[@]}; do
    if [[ $type == 'nmp' && $suppress_http == 1 ]]; then
        case $force in
            0)
            echo "Warning: http reporting is disabled, but rubric relies on http reporting for full score."
            read -p "         Your local grade report may not be accurate. Continue? (Y/n) " REPLY
            if [[ $REPLY == "y" || $REPLY == "Y" ]]; then
                echo "Continuing exectuion..."
            else
                echo "exiting..."
                exit 2003
            fi
            ;;

            1)
            echo "Warning: http reporting is disabled, but rubric relies on http reporting for full score. Your grade will not be accurate."
            ;;

            2)
            # do nothing
            ;;

            *)
            echo 'Internal Error: $force variable out of scope. Exiting...'
            exit 3031
        esac
        
    fi

    beginline='^Start\sKey\sDir\s'$counter'$'
    endline='^End\sKey\sDir\s'$counter'$'
    sedline1='/'$beginline'/,/'$endline$'/{/'$beginline'/!p}'
    sedline2='/'$endline'/!p'

    analysis_file_path=$(sed -nE $sedline1 ./Keys.txt | sed -nE $sedline2)
    #echo $type

    if [[ ! $type == 'nmp' ]]; then
        beginline='^Start\sKey\s'$counter'$'
        endline='^End\sKey\s'$counter'$'
        sedline1='/'$beginline'/,/'$endline$'/{/'$beginline'/!p}'
        sedline2='/'$endline'/!p'

        key=$(sed -nE $sedline1 ./Keys.txt | sed -nE $sedline2)

        if [[ $verbosity == 2 ]]; then 
            echo ""
            echo "----- input -----"
            echo "iteration = $counter"
            echo "key type  = $type"
            echo "key       = $key"
            echo "filepath  = $analysis_file_path"
            echo ""
            echo "----- output ----"
        fi

        if [ $verbosity -ge 1 ]; then
            bash "./Comparison-Scripts/$type.sh" "$key" $analysis_file_path
        else
            bash "./Comparison-Scripts/$type.sh" "$key" $analysis_file_path >> /dev/null
        fi

    elif [[ $type == 'nmp' && $verbosity == 2 ]]; then
        echo ""
        echo "----- input -----"
        echo "iteration = $counter"
        echo "key type  = $type"
        echo "filepath  = $analysis_file_path"
        echo ""
        echo "----- output ----"
        echo "not graded locally - nmp"

    elif [[ $type == 'nmp' && $verbosity == 1 ]]; then
        echo "not graded locally - nmp"
    fi

    analysis_file_paths+=$analysis_file_path
    
    ((counter=$counter+1))
done

# --- 3. Calculate grade based on rubric ---




# --- 4. Send results to HTTP Server ---

