#!/usr/bin/env bash
# 
# Created: 2017-3-20, A-Lang
# Updated: 2017-3-21
#

# Variables
testcoin="testcoin.stack"
exit1="quit"
exit2="25"
COLOR_REST='\e[0m'
COLOR_GREEN='\e[92m'
COLOR_RED='\e[0;31m'
CURL_CMD="curl"
CURL_OPT="-qSfs"
JQ_CMD="jq"


# Don't change the following lines
WORKDIR="$( cd $( dirname "$0" ) && pwd )"
RUNNINGOS=$(`echo uname` | tr '[a-z]' '[A-Z]')
RUNNINGARCH=$(`echo uname -m` | tr '[a-z]' '[A-Z]')


# Strings
string_01="Could not Check hints because get_ticket service failed to get a ticket. Fix get_ticket first."
string_02="Loading test coin : $WORKDIR/$testcoin"
string_03="Checking ticket..."
string_04="Empty ticket"
string_05="HTTPS Access No Response"
error_01="Error: Test Coin File Not Found ($WORKDIR/$testcoin)"
error_02="Error: Invalid Command"
error_03="Error: Test Coin File seems to be Wrong Format ($WORKDIR/$testcoin)"
error_04="Error: Ticket Check Failed "



Show_head(){
    clear
    cat <<EOF
Welcome to RAIDA Tester. A CloudCoin Consortium Opensource.
The Software is provided as is, with all faults, defects and errors, and 
without warranty of any kind.
You must have an authentic CloudCoin .stack file called 'testcoin.stack' 
in the same folder as this program to run tests.
The test coin will not be written to.
EOF
}

Show_menu(){
    cat <<EOF
=========================================
RAIDA Tester Commands Available:
[+] echo       (e)
[+] detect     (d)
[+] get_ticket (g)
[+] hints      (h)
[+] quit       (q)
EOF

}

Error(){
    message="$1"
    message_color="$COLOR_RED$message$COLOR_REST"
    echo -e "$message_color\n"
}

Show_requirement(){
    cat <<EOF
NOTE: The following packages must be already installed on the system.
 * Curl
 * Jq (see more details on https://stedolan.github.io/jq/)

Recommend: To install these packages, you can run the commands:
 yum install curl
 or
 apt-get install curl
  
EOF
}

Main()
{
    input=""
    while [ "$input" != "exit" ]
    do
        Show_menu

        echo -n "RAIDA Tester> " && read input
        if [ "$input" == "echo" -o "$input" == "e" ];then
            Echo

        elif [ "$input" == "detect" -o "$input" == "d" ];then
            Detect

        elif [ "$input" == "get_ticket" -o "$input" == "g" ];then
            Get_ticket

        elif [ "$input" == "hints" -o "$input" == "h" ];then
            Hints

        elif [ "$input" == "quit" -o "$input" == "q" ];then
            break

        else
            Error "$error_02"
        fi
    done
}


Check_requirement(){
    is_pass=1
    
    [ $(which $JQ_CMD) ] || is_pass=0

    if [ $is_pass -eq 0 ];then
        Show_requirement
        exit 1
    fi
}


Echo()
{
    input=""
    while [ "$input" != "$exit2" ]
    do
        echo "What RAIDA# do you want to test echo? Enter 25 to end."
        echo -n "echo> " && read input
        if [ $input -ge 0 -a $input -lt 25  ];then
            raida="raida$input"
            raida_url="https://$raida.cloudcoin.global/service/echo"
            start_s=`date +%s%N`
            http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
            http_retval=$?
            end_s=`date +%s%N`
            elapsed=$(( (end_s-start_s)/1000000 ))

            if [ $http_retval -eq 0 ]; then
                status=$(echo $http_response | $JQ_CMD -r '.status')
            else
                status="error"
            fi

            if [ "$status" == "ready" ];then
                status_color="$COLOR_GREEN$status$COLOR_REST"
            else
                status_color="$COLOR_RED$status$COLOR_REST"
            fi

            echo
            echo -e "Status: $status_color"
            echo "Milliseconds: $elapsed"
            echo "Request: $raida_url"
            echo "Response: $http_response"
            echo

        elif [ "$input" = "$exit2" ];then
            break

        else
            Error "$error_02"
        fi
    done
}

Detect(){
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input=""
    while [ "$input" != "$exit2" ]
    do
        echo "What RAIDA# do you want to test detect? Enter 25 to end."
        echo -n "detect> " && read input
        if [ $input -ge 0 -a $input -lt 25  ];then
            raida="raida$input"
            raida_url="https://$raida.cloudcoin.global/service/detect"
            nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
            sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
            string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
            array_an=( $string_an )
            an="${array_an[$input]}"
            
            raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=250"
            start_s=`date +%s%N`
            http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
            http_retval=$?
            end_s=`date +%s%N`
            elapsed=$(( (end_s-start_s)/1000000 ))

            if [ $http_retval -eq 0 ]; then
                status=$(echo $http_response | $JQ_CMD -r '.status')
            else
                status="error"
            fi

            if [ "$status" == "pass" ];then
                status_color="$COLOR_GREEN$status$COLOR_REST"
            else
                status_color="$COLOR_RED$status$COLOR_REST"
            fi
            
            echo
            echo -e "Status: $status_color"
            echo "Milliseconds: $elapsed"
            echo "Request: $raida_url"
            echo "Response: $http_response"
            echo

        elif [ "$input" = "$exit2" ];then
            break

        else
            Error "$error_02"

        fi
    done
}

Get_ticket(){
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input=""
    while [ "$input" != "$exit2" ]
    do
        echo "What RAIDA# do you want to get ticket for? Enter 25 to end."
        echo -n "detect> " && read input
        if [ $input -ge 0 -a $input -lt 25  ];then
            raida="raida$input"
            raida_url="https://$raida.cloudcoin.global/service/get_ticket"
            nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
            sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
            string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
            array_an=( $string_an )
            an="${array_an[$input]}"
            
            raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=250"
            start_s=`date +%s%N`
            http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
            http_retval=$?
            end_s=`date +%s%N`
            elapsed=$(( (end_s-start_s)/1000000 ))

            if [ $http_retval -eq 0 ]; then
                status=$(echo $http_response | $JQ_CMD -r '.status')
            else
                status="error"
            fi
            
            if [ "$status" == "ticket" ];then
                status_color="$COLOR_GREEN$status$COLOR_REST"
            else
                status_color="$COLOR_RED$status$COLOR_REST"
            fi
            
            echo
            echo -e "Status: $status_color"
            echo "Milliseconds: $elapsed"
            echo "Request: $raida_url"
            echo "Response: $http_response"
            echo

        elif [ "$input" = "$exit2" ];then
            break

        else
            Error "$error_02"
            
        fi
    done
}

Hints(){
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input=""
    while [ "$input" != "$exit2" ]
    do
        echo "What RAIDA# do you want to test hints? Enter 25 to end."
        echo -n "test hints> " && read input
        if [ $input -ge 0 -a $input -lt 25  ];then
            raida="raida$input"
            nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
            sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
            string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
            array_an=( $string_an )
            an="${array_an[$input]}"
            raida_url="https://$raida.cloudcoin.global/service/get_ticket"
            raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=250"

            echo "$string_03"
            Check_ticket $raida_url
            Check_ticket_retval=$?
            
            if [ $Check_ticket_retval -eq 0 ]; then
                echo "Last ticket is: $ticket"
                raida_url="https://$raida.cloudcoin.global/service/hints"
                raida_url="$raida_url?rn=$ticket"
                start_s=`date +%s%N`
                http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
                http_retval=$?
                end_s=`date +%s%N`
                elapsed=$(( (end_s-start_s)/1000000 ))

                if [ $http_retval -eq 0 ]; then
                    _sn=$(echo $http_response | cut -d: -f1)
                    _ms=$(echo $http_response | cut -d: -f2)
                    status="Success, The serial number was $_sn and the ticket age was $_ms milliseconds old."
                    status_color="$COLOR_GREEN$status$COLOR_REST"
                else
                    status="error"
                    status_color="$COLOR_RED$status$COLOR_REST"
                fi

                echo
                echo -e "Status: $status_color"
                echo "Milliseconds: $elapsed"
                echo "Request: $raida_url"
                echo "Response: $http_response"
                echo

            fi

        elif [ "$input" = "$exit2" ];then
            break

        else
            Error "$error_02"
            
        fi
    done
}


Check_ticket(){
    raida_url="$1"
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    is_raida=$(echo $http_response | grep -c "server")

    if [ "$is_raida" == "1" ];then
        message="$(echo $http_response | $JQ_CMD -r '.message')"
        status="$(echo $http_response | $JQ_CMD -r '.status')"

        if [ $status != "ticket" ];then
            ticket=""
            echo "Last ticket is: empty"
            echo
            echo -e "$COLOR_RED$string_01$COLOR_REST"
            echo -e "Status: $COLOR_RED$status$COLOR_REST"
            echo "Request: $raida_url"
            echo "Response: $http_response"
            echo
            return 1

        else
            ticket="$message"
            return 0

        fi
    else
        echo
        echo -e "$COLOR_RED$string_05$COLOR_REST"
        echo "Request: $raida_url"
        echo
        return 1

    fi
}


Load_testcoin(){
    if [ -f $testcoin ];then
        $JQ_CMD '.cloudcoin' $testcoin >/dev/null 2>&1
        is_json=$? 
        if [ $is_json -eq 0 ];then # Is JSON
            echo -e "$string_02"
            return 0
        else # Not JSON
            Error "$error_03"
            return 1
        fi
    else
        Error "$error_01"
        return 1
    fi
}


cd $WORKDIR
Check_requirement
Show_head
Main

exit
