#! /bin/bash

function display_usage() {
    echo "Usage: $0 -[c]"
    echo "       $0 -[p]"
    echo "       $0 -[h]"
    echo ""
    echo "Options:"
    echo "  -c: compiles prerequisites from github repo (requires git)"
    echo "  -h: displays this Help page"
    echo "  -p: downloads from package manager (supports Ubuntu and CentOS, Default)"
    echo ""
    echo "Note: Script must be ran as a super user (sudo) or under root privileges."

}

function error_input_option_c_p() {
    echo "Input Validation Error: Options -c and -p cannot be used at the same time."
    echo ""
    display_usage
    exit 9003
}

function ubuntu_install_c() {
    git clone -q https://github.com/stedolan/jq.git
    cd jq
    ./configure > /dev/null; make > /dev/null
    make install > /dev/null
    cd ..

    # Verify Installation
    if [[ ! `jq --version` == 'jq'* ]]; then 
        echo "Error: jq was not successfully installed. exiting."
        exit 9005
    fi
}

function ubuntu_install_p() {
    apt-get update -yq
    apt-get install -yqf jq
}

function centos_install_c() {

    #Install steps identical between centos and Ubuntu. As such, referencing the ubuntu install
    ubuntu_install_c
}

function centos_install_p() {

    # check if jq available in current dnf repos
    if [[ `dnf list --available jq | grep 'Error*'` == 'Error: No matching Packages to list' ]]; then 
        echo "Error: dependency 'jq' is not in the installed dnf repositories. Falling back to install via compilation."
        centos_install_c
    fi


}

if [ `id -u` ]; then
    echo "Permission Error: Script must be ran as a super user (sudo) or under root privileges. Please re-run script as a sudoer."
    exit 9004
fi

method='p'
while getopts "chp" opt; do
    case $opt in
        h)
        display_usage_short
        exit 0
        ;;

        c)
        if [ $method = "p" ]; then
            error_input_option_c_p
        fi
        method='c'
        ;;

        p)
        if [ $method = "c" ]; then
            error_input_option_c_p
        fi
        method="p"
        ;;

        \?)
        echo "Invalid option: -$OPTARG"
        display_usage_short
        exit 9001
        ;;

        :)
        echo "Option -$OPTARG requires an argument"
        display_usage_short
        exit 9002
        ;;
    esac
done

if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

if [[ $DISTRO == "Ubuntu" && $method == "p" ]]; then        # Case Ubuntu
    ubuntu_install_p
elif [[ "$ID" == "centos" && $method == "p" ]]; then        # Case CentOS
    centos_install_p
elif [[ $DISTRO == "Ubuntu" && $method == "c" ]]; then      # Case Ubuntu, compile from source
    ubuntu_install_c
elif [[ "$ID" == "centos" && $method == "c" ]]; then        # Case CentOS, compile from source
    centos_install_c
else
    echo "Platform couldn't be verified. You may still be able to install from source, but this is not tested."
    read "Would you like to attempt an installation? (Y/n) " REPLY

    if [[ $REPLY == "y" || $REPLY == "Y"]]; then
        ubuntu_install_c
    fi
fi