#! /bin/bash

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

