#! /bin/bash

# --- 1. Verify the input ---

function display_usage() {
    echo "Usage: $0 -[vs]"
    echo "       $0 -[qs]"
    echo "Options:"
    echo "  -h: displays this Help page"
    echo "  -q: silences (Quiet) output"
    echo "  -s: Skips reporting to HTTP Endpoint"
    echo "  -v: increases Verbosity of output"
}

function error_input_option_q_v() {
    echo "Input Validation Error: Options -q and -v cannot be used at the same time."
    echo ""
    display_usage
    exit 1003
}

# Parse Input
verbosity="1"
while getopts "hqsv" opt; do
    case $opt in
        h)
        display_usage_short
        exit 0
        ;;

        q)
        if [ $verbosity = "2" ]; then
            error_input_option_q_v
        fi
        verbosity="0"
        ;;

        s)
        action=$OPTARG
        ;;

        v)
        if [ $verbosity = "0" ]; then
            error_input_option_q_v
        fi
        verbosity="2"
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

# Check if required files exist
if [ ! -f "./Config.json" ]; then
    echo "Configuration Error: config file could not be found. Please ensure Config.json exists within your present working directory, then run again."
    exit 2001
fi

if [ ! -f "./keys.txt" ]; then
    echo "Configuration Error: the keys file does not exist. Please reinstall this script file and ensure a valid ./keys.txt file is generated."
    exit 2002
fi

# Input and test configuration
CONFIG=$(cat ./Config.json)
NUMBER_OF_KEYS=""
Test_Case=$(grep -E '\"Number_Of_Keys\":[0-9]{1,}' $CONFIG)
if [[ -v $Test_Case ]]; then
    cat $CONFIG | jq -r '.Properties.Number_Of_Keys'
else
    echo "foo"
fi

KEY_TYPES=$(echo $CONFIG | jq -r '.Properties.Key_Types' > /dev/null) # Get key number to key type correlation

# --- 2. Call one or more grading scripts ---
function compare_hashes() {
    ALGORITHM=$1; HASH=$2; SALT=$3; COMPARISONCLEARTEXT=$4

    if $3; then   # If salt was input
        key="$COMPARISONCLEARTEXT$SALT"
    else
        key=$COMPARISONCLEARTEXT
    fi

    hash_resultant=$(echo $key | $ALGORITHM | awk '{print $1}')

    if [[ $HASH == $hash_resultant ]]; then
        return 0    # hashes match
    else
        return 1    # hashes don't match
    fi
}

# if decryption key not in library, import decryption key
if [[ ! -v $(gpg --list-public-keys | grep `cat ./Crypto/decrypt.key.pub.fingerprint`) ]]; then 
    gpg --import `cat ./Crypto/decrypt.key.pub`
fi

# setting up comparison variables
CRYPTO_HASHES=$(gpg --decrypt ./Crypto/comparison-scripts-hashes.json.gpg)
KEYHASH=$(echo $CRYPTO_HASHES | jq -r '.key.key_hash')
KEYFPHASH=$(echo $CRYPTO_HASHES | jq -r '.key.key_fingerprint_hash')
SCRIPT_SALT=$(echo $CRYPTO_HASHES | jq -r '.salt')
SCRIPT_NAMES=('hash.sh', 'key.sh', 'line.sh', 'not-my-problem.sh')
ALGORITHM=(echo $CRYPTO_HASHES | jq -r '.hash_program')

# verify bash scripts are unaltered

if $?; then

fi
for script_name in $SCRIPT_NAMES; do

done

# --- 3. Calculate grade based on rubric ---




# --- 4. Send results to HTTP Server after-action-actions ---

