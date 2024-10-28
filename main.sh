#! /bin/bash

# --- 1. Verify the input ---

function display_usage() {
    echo "Usage: $0 -[f|F sv]"
    echo "       $0 -[f|F qs]"
    echo "       $0 -[f|F g|G v]"
    echo "       $0 -[f|F g|G q]"
    echo "Options:"
    echo "  -f: Force continuation of script upon warning(s)"
    echo "  -F: Force continuation of script upon warnings and silences warning(s) (same as -f -q)"
    echo "  -g: skips local Grading step, relying on HTTP Endpoint to calculate the grade"
    echo "  -G: skips local Grading step, relying on HTTP Endpoint to calculate the grade, ignoring 'nmp' warning(s) (not implemented)"
    echo "  -h: displays this Help page"
    echo "  -q: silences (Quiet) output"
    echo "  -s: Skips reporting to HTTP Endpoint"
    echo "  -s: Skips reporting to HTTP Endpoint, ignoring 'nmp' warning(s) (not implemented)"
    echo "  -v: increases Verbosity of output"
    echo "      if -F is defined, replaces with -f"
}

function error_input_option_q_v() {
    echo "Input Validation Error: Options -q and -v cannot be used at the same time."
    echo ""
    display_usage
    exit 1003
}

function error_input_option_g_s() {
    echo "Input Validation Error: Options -g and -s cannot be used at the same time."
    echo ""
    display_usage
    exit 1004
}

# Parse Input
verbosity=1
suppress_http=0
suppress_local_grading=0
force=0
while getopts "fFgGhqsv" opt; do
    case $opt in
        f)
        if [[ ! $force == 2 ]]; then
            force=1
        fi
        ;;

        F)
        force=2
        ;;

        g)
        if [ $suppress_http = 1 ]; then
            error_input_option_g_s
        fi
        if [[ ! $suppress_local_grading = 2 ]]; then
            suppress_local_grading=1
        fi
        ;;

        G)
        if [ $suppress_http = 1 ]; then
            error_input_option_g_s
        fi
        suppress_local_grading=2
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
        if $suppress_local_grading; then
            error_input_option_g_s
        fi
        suppress_http=1
        ;;

        S)

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

if [[ $verbosity == 2 ]]; then echo "----- (1) Validating Input ------------------"; fi

# Guarantee Verbosity Presedence
if [[ $force == 1 && $verbosity == 0 ]]; then 
    force=2
elif [[ $force == 2 && $verbosity == 2 ]]; then
    echo "Warning: Ignoring -F and applying -f. Verbosity takes precedence over force options."
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
    NUMBER_OF_KEYS=$(cat $CONFIG | jq -r '.Properties.Number_Of_Keys')
fi

# Get key number to key type correlation
KEY_TYPES_JSON=$(cat $CONFIG | jq -r '.Properties.Key_Types') 
noquote=$(echo $KEY_TYPES_JSON | tr -d \"\,[])
KEY_TYPES=($noquote)
noquote=""

# Get rubric information
RUBRIC_WEIGHTS_JSON=$(cat $CONFIG | jq -r '.Rubric.Weights') 
noquote=$(echo $RUBRIC_WEIGHTS_JSON | tr -d \"\,[])
RUBRIC_WEIGHTS=($noquote)
noquote=""

PASSING_SCORE=$(cat $CONFIG | jq -r '.Rubric.Passing_Score')

if [[ ! $? && $suppress_http ]]; then
    case $force in
        0)
        echo "Configuration Error: Rubric passing score couldn't be found or extracted from $CONFIG. Cannot utilize rubric for grading."
        echo "                     Continuing will not report grades locally, but solely rely on the http server rubric, disabling -s."
        read -p "                      Do you wish to continue? (Y/n) " REPLY
        if [[ $REPLY == "y" || $REPLY == "Y" ]]; then
            echo "Continuing exectuion..."
            suppress_http=0
            suppress_local_grading=1
        else
            echo "exiting..."
            exit 2005
        fi
        ;;

        1|2)
        echo "Configuration Error: Rubric weight value count does not line up with key count. Cannot produce accurate grade. Exiting..."
        exit 2005
        ;;

        *)
        echo 'Internal Error: $force variable out of scope. Exiting...'
        exit 3031
        ;;
    esac
elif [[ ! $? && $suppress_local_grading == 0 && $verbosity ]]; then
    echo "Configuration Error: Rubric passing score couldn't be found or extracted from $CONFIG. Cannot utilize rubric for grading."
    echo "                     Falling back on HTTP server rubric for grading. Grade will not be calculated locally. enabling -g."
    suppress_local_grading=1
elif [[ ! $? && $suppress_local_grading == 0 && $verbosity == 0 ]]; then
    suppress_local_grading=1
elif [[ ${#RUBRIC_WEIGHTS[@]} != $NUMBER_OF_KEYS && $suppress_http ]]; then
    case $force in
        0)
        echo "Configuration Error: Rubric weight value count does not line up with key count. Cannot utilize rubric for grading."
        echo "                     Continuing will not report grades locally, but solely rely on the http server rubric, disabling -s."
        read -p "                      Do you wish to continue? (Y/n) " REPLY
        if [[ $REPLY == "y" || $REPLY == "Y" ]]; then
            echo "Continuing exectuion..."
            suppress_http=0
            suppress_local_grading=1
        else
            echo "exiting..."
            exit 2004
        fi
        ;;

        1|2)
        echo "Configuration Error: Rubric weight value count does not line up with key count. Cannot produce accurate grade. Exiting..."
        exit 2004
        ;;

        *)
        echo 'Internal Error: $force variable out of scope. Exiting...'
        exit 3031
        ;;
    esac
elif [[ ${#RUBRIC_WEIGHTS[@]} != $NUMBER_OF_KEYS && $suppress_local_grading == 0 && $verbosity ]]; then
    echo "Configuration Error: Rubric weight value count does not line up with key count. Cannot utilize rubric for grading."
    echo "                     Falling back on HTTP server rubric for grading. Grade will not be calculated locally. enabling -g."
    suppress_local_grading=1
elif [[ ${#RUBRIC_WEIGHTS[@]} != $NUMBER_OF_KEYS && $suppress_local_grading == 0 && $verbosity == 0 ]]; then
    suppress_local_grading=1
fi

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

if [[ $verbosity == 2 ]]; then echo "----- (2) Calling Grading Scripts ----------"; fi

counter=1
icounter=0
analysis_file_paths=''
pass_fail_list='' # nmp present if value is '2'

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

        pass_fail_list[$icounter]=$?
        #echo "Test $counter: "${pass_fail_list[$icounter]}

    elif [[ $type == 'nmp' && $verbosity == 2 ]]; then
        echo ""
        echo "----- input -----"
        echo "iteration = $counter"
        echo "key type  = $type"
        echo "filepath  = $analysis_file_path"
        echo ""
        echo "----- output ----"
        echo "not graded locally - nmp"

        pass_fail_list[$icounter]=2

    elif [[ $type == 'nmp' && $verbosity == 1 ]]; then
        echo "not graded locally - nmp"

        pass_fail_list[$icounter]=2
    
    elif [[ $type == 'nmp' ]]; then
        pass_fail_list[$icounter]=2
    fi

    analysis_file_paths+=$analysis_file_path
    
    icounter=$counter
    ((counter=$counter+1))
done

# --- 3. Calculate grade based on rubric ---
if [ $suppress_local_grading ]; then
    if [[ $verbosity == 2 ]]; then echo "----- (3) Calculating Grade ---------------"; fi

    accurate_grade=1
    score=0
    possible_score=0
    counter=0

    for pfscore in ${pass_fail_list[@]}; do
        if [[ $pfscore == 2 && $accurate_grade && $verbosity ]]; then
            accurate_grade=0
            echo "Warning: some items on the rubric are configured for remote grading. Local grade will not be accurate."
        elif [[ $pfscore == 2 && $accurate_grade == 1 && $verbosity == 0 ]]; then
            accurate_grade=0
        fi

        if [[ $pfscore == 2 ]]; then   # not calculated locally
            ((possible_score=$possible_score+${RUBRIC_WEIGHTS[$counter]}))
            if [[ $verbosity == 2 ]]; then echo "test $counter: Grade not calculated"; fi
        elif [[ $pfscore == 0 ]]; then # calculated locally (pass)
            ((score=$score+${RUBRIC_WEIGHTS[$counter]}))
            ((possible_score=$possible_score+${RUBRIC_WEIGHTS[$counter]}))
            if [[ $verbosity == 2 ]]; then echo "test $counter: Passed"; fi
        elif [[ $pfscore == 1 && $verbosity == 2 ]]; then
            echo "test $counter: Failed"
        fi

        ((counter=$counter+1))

    done

    if [[ $accurate_grade == 1 && $PASSING_SCORE -le $score && $verbosity ]]; then
        echo "Score: PASS"
        echo "Passing Score: $PASSING_SCORE"
        echo "Score Achieved: $score"
    elif [[ $PASSING_SCORE -le $score && $verbosity ]]; then
        echo "Score: PASS"
        echo "Passing Score: $PASSING_SCORE"
        echo "Score Range Achieved: $score (verified) - $possible_score (possible)"
    elif [[ $PASSING_SCORE -le $possible_score && $verbosity ]]; then
        echo "Score: PASS OR FAIL"
        echo "Passing Score: $PASSING_SCORE"
        echo "Score Range Achieved: $score (verified) - $possible_score (possible)"
        echo "NOTE: Depending on HTTP Server grading, you may or may not have passed."
    elif [[ $PASSING_SCORE -le $score ]]; then
        echo "Score: PASS"
    elif [[ $PASSING_SCORE -le $possible_score ]]; then
        echo "Score: PASS OR FAIL"
        echo "NOTE: Depending on HTTP Server grading, you may or may not have passed."
    elif [ $verbosity ]; then
        echo "Score: PASS OR FAIL"
        echo "Passing Score: $PASSING_SCORE"
        echo "Score Range Achieved: $score (verified) - $possible_score (possible)"
    else
        echo "Score: FAIL"
    fi

fi



# --- 4. Send results to HTTP Server ---

