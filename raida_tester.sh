#!/usr/bin/env bash
# 
# Created: 2017-3-20, A-Lang
# 

# Variables
testcoin="testcoin.stack"
raida_nums=25
_REST_='\033[0m'
_GREEN_='\033[32m'
_RED_='\033[31m'
_BOLD_='\033[1m'
CURL_CMD="curl"
CURL_OPT="-qSfs -m 60"
JQ_CMD="jq"


# Don't change the following lines
WORKDIR="$( cd $( dirname "$0" ) && pwd )"
RUNNINGOS=$(`echo uname` | tr '[a-z]' '[A-Z]')
RUNNINGARCH=$(`echo uname -m` | tr '[a-z]' '[A-Z]')


# Strings
string_01="Could not Check hints because get_ticket service failed to get a ticket. Fix get_ticket first."
string_02="Loading test coin: $WORKDIR/$testcoin"
string_03="Checking ticket..."
string_04="Empty ticket"
string_05="HTTPS Access No Response"
error_01="Error: Testcoin File Not Found ($WORKDIR/$testcoin)"
error_02="Error: Invalid Command"
error_03="Error: Test Coin File seems to be Wrong Format ($WORKDIR/$testcoin)"
error_04="Error: Ticket Check Failed "
error_05="Error: Test failed, run the echo to see more details."
error_06="Error: Test failed, run the detect to see more details."
error_07="Error: Test failed, run the get_ticket to see more details."


Show_logo(){
    printf  '
              ________                ________      _
             / ____/ /___  __  ______/ / ____/___  (_)___
            / /   / / __ \/ / / / __  / /   / __ \/ / __ \
           / /___/ / /_/ / /_/ / /_/ / /___/ /_/ / / / / /
           \____/_/\____/\__,_/\__,_/\____/\____/_/_/ /_/

'
}

Show_head(){
    clear
    Show_logo
    cat <<EOF
#############################################################################
# Welcome to RAIDA Tester. A CloudCoin Consortium Opensource.               #
# The Software is provided as is, with all faults, defects and errors, and  #
# without warranty of any kind.                                             #
# You must have an authentic CloudCoin .stack file called 'testcoin.stack'  #
# in the same folder as this program to run tests.                          #
# The test coin will not be written to.                                     #
#############################################################################
EOF
}

Show_menu(){
    cat <<EOF
===================================
RAIDA Tester Commands Available:
[+] echo       (e)
[+] detect     (d)
[+] get_ticket (g)
[+] hints      (h)
[+] fix        (f)
[+] advanced   (a)
[+] quit       (q)
EOF

}

Error(){
    message="$1"
    message_color="$_RED_$message$_REST_"
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
    while [ "$input" != "quit" ]
    do
        Show_menu

        echo -n "RAIDA Tester> " && read input
        if [ "$input" == "echo" -o "$input" == "e" ];then
            Process_request _echo

        elif [ "$input" == "detect" -o "$input" == "d" ];then
            Process_request _detect

        elif [ "$input" == "get_ticket" -o "$input" == "g" ];then
            Process_request _get_ticket

        elif [ "$input" == "hints" -o "$input" == "h" ];then
            Process_request _hints

        elif [ "$input" == "fix" -o "$input" == "f" ];then
            Process_request _fix

        elif [ "$input" == "advanced" -o "$input" == "a" ];then
            Advanced

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

Timer(){
	if [ "$RUNNINGOS" == "LINUX" ];then
		seconds=`date +%s%N`
	else
		seconds=`ruby -e 'puts "%.9f" % Time.now' | tr -d '.'`
	fi
	echo $seconds 
}

Get_denom(){
    sn=$1
    denom=0
    if [ $sn -gt 0 -a $sn -lt 2097153 ];then
        denom=1
    elif [ $sn -lt 4194305 ];then
        denom=5
    elif [ $sn -lt 6291457 ];then
        denom=25
    elif [ $sn -lt 14680065 ];then
        denom=100
    elif [ $sn -lt 16777217 ];then
        denom=250
    fi
    echo $denom
}

Advanced(){
    input=""
    PROMPT="ADVANCED"
    while true
    do
        echo "Test All RAIDA Nodes [0-5]: 1.Echo 2.Detect 3.Ticket 4.Hints 5.Fix 0.Exit"
        echo "NOTE: This process may take a few mins to check all nodes please be patient until all check done."
        echo -n "$PROMPT> " && read input
        if [ $input -ge 1 -a $input -le 5 ] 2>/dev/null ;then
            case "$input" in
                1)
                     _all_echo
                     ;;
                2)
                    _all_detect
                     ;;
                3)
                    _all_ticket
                    ;;
                4)
                    _all_hints
                    ;;
                5)
                    _all_fix
                    ;;
            esac

        elif [ $input -eq 0 ] 2>/dev/null ;then
            break

        else
            Error "$error_02"

        fi
    done
}

Process_request(){
    input=""
    option="$1"

    case "$option" in
        _echo)
        PROMPT="ECHO"
        ;;
        _detect)
        PROMPT="DETECT"
        ;;
        _get_ticket)
        PROMPT="GET_TICKET"
        ;;
        _hints)
        PROMPT="HINTS"
        ;;
        _fix)
        PROMPT="FIX"
        ;;
        *)
        PROMPT="XXX"
        ;;
    esac

    while [ "$input" != "$raida_nums" ]
    do
        echo "What RAIDA# do you want to test $PROMPT? Enter 25 to end."
        echo -n "$PROMPT> " && read input
        if [ $input -ge 0 -a $input -lt 25  ] 2>/dev/null;then
            $option $input

        elif [ "$input" -eq "$raida_nums" ] 2>/dev/null;then
            break

        else
            Error "$error_02"

        fi
    done
}

_all_echo(){
    echo -n "ECHO Results: "
    for ((n=0;n<$raida_nums;n++))
    do
        _echo $n >/dev/null 2>&1
        run_echo=$?
        if [ $run_echo -eq 0 ];then
            status="pass"
        else
            status="${_RED_}fail${_REST_}"
        fi 
        echo -e -n "-> RAIDA#${n}: ${status}(${elapsed}ms)  "
    done
    echo;echo
}

_echo()
{
    echo_retval=0
    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/echo"
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))

    if [ $http_retval -eq 0 ]; then
        status=$(echo $http_response | $JQ_CMD -r '.status')
    else
        status="error"
        echo_retval=1
    fi

    if [ "$status" == "ready" ];then
        status_color="$_GREEN_$status$_REST_"
        response_color="$_GREEN_$http_response$_REST_"
    else
        status_color="$_RED_$status$_REST_"
        response_color="$_RED_$http_response$_REST_"
        echo_retval=1
    fi

    echo
    echo -e "Status: $_BOLD_$status_color"
    echo "Milliseconds: $elapsed"
    echo "Request: $raida_url"
    echo -e "Response: $response_color"
    echo
    return $echo_retval
}

_all_detect(){
    # Check the local testcoin file
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    echo -n "DETECT Results: "
    for ((n=0;n<$raida_nums;n++))
    do
        _detect $n >/dev/null 2>&1
        run_detect=$?
        if [ $run_detect -eq 0 ];then
            status="pass"
        else
            status="${_RED_}fail${_REST_}"
        fi 
        echo -e -n "-> RAIDA#${n}: ${status}(${elapsed}ms)  "
    done
    echo;echo
}

_detect(){
    # Check the local testcoin file
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/detect"
    nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
    array_an=( $string_an )
    an="${array_an[$input]}"
    denom=$(Get_denom $sn)

    # Test the Echo
    test_echo=$(_echo $input)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$error_05"
        return 1
    fi 
            
    detect_retval=0
    raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=$denom"
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))

    if [ $http_retval -eq 0 ]; then
        status=$(echo $http_response | $JQ_CMD -r '.status')
    else
        status="error"
        detect_retval=1
    fi

    if [ "$status" == "pass" ];then
        status_color="$_GREEN_$status$_REST_"
        response_color="$_GREEN_$http_response$_REST_"
    else
        status_color="$_RED_$status$_REST_"
        response_color="$_RED_$http_response$_REST_"
        detect_retval=1
    fi
            
    echo
    echo -e "Status: $_BOLD_$status_color"
    echo "Milliseconds: $elapsed"
    echo "Request: $raida_url"
    echo -e "Response: $response_color"
    echo
    return $detect_retval

}

_all_ticket(){
    # Check the local testcoin file
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    echo -n "TICKET Results: "
    for ((n=0;n<$raida_nums;n++))
    do
        _get_ticket $n >/dev/null 2>&1
        run_ticket=$?
        if [ $run_ticket -eq 0 ];then
            status="pass"
        else
            status="${_RED_}fail${_REST_}"
        fi 
        echo -e -n "-> RAIDA#${n}: ${status}(${elapsed}ms)  "
    done
    echo;echo

}

_get_ticket(){
    # Check the local testcoin file
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/get_ticket"
    nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
    array_an=( $string_an )
    an="${array_an[$input]}"
    denom=$(Get_denom $sn)

    # Test the Echo
    test_echo=$(_echo $input)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$error_05"
        return 1
    fi 

    # Test the Detect
    test_detect=$(_detect $input)
    run_detect=$?
    if [ $run_detect -eq 1 ];then
        Error "$error_06"
        return 1
    fi 
    
    get_ticket_retval=0        
    raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=$denom"
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))

    if [ $http_retval -eq 0 ]; then
        status=$(echo $http_response | $JQ_CMD -r '.status')
    else
        status="error"
        get_ticket_retval=1
    fi
            
    if [ "$status" == "ticket" ];then
        status_color="$_GREEN_$status$_REST_"
        response_color="$_GREEN_$http_response$_REST_"
    else
        status_color="$_RED_$status$_REST_"
        response_color="$_RED_$http_response$_REST_"
        get_ticket_retval=1
    fi
            
    echo
    echo -e "Status: $_BOLD_$status_color"
    echo "Milliseconds: $elapsed"
    echo "Request: $raida_url"
    echo -e "Response: $response_color"
    echo
    return $get_ticket_retval

}

_all_hints(){
    # Check the local testcoin file
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    echo -n "HINTS Results: "
    for ((n=0;n<$raida_nums;n++))
    do
        _hints $n > /dev/null 2>&1
        run_hints=$?
        if [ $run_hints -eq 0 ];then
            status="pass"
        else
            status="${_RED_}fail${_REST_}"
        fi 
        echo -e -n "-> RAIDA#${n}: ${status}(${elapsed}ms)  "
    done
    echo;echo

}

_hints(){
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    raida="raida$input"
    nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
    array_an=( $string_an )
    an="${array_an[$input]}"
    denom=$(Get_denom $sn)
    raida_url="https://$raida.cloudcoin.global/service/get_ticket"
    raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=$denom"

    # Test the Echo
    test_echo=$(_echo $input)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$error_05"
        return 1
    fi 

    # Test the Detect
    test_detect=$(_detect $input)
    run_detect=$?
    if [ $run_detect -eq 1 ];then
        Error "$error_06"
        return 1
    fi 

    # Test the Get_ticket
    test_get_ticket=$(_get_ticket $input)
    run_get_ticket=$?
    if [ $run_get_ticket -eq 1 ];then
        Error "$error_07"
        return 1
    fi 

    echo "$string_03"
    Hints_ticket_request $raida_url
    Hints_ticket_retval=$?
    hints_retval=0
            
    if [ $Hints_ticket_retval -eq 0 ]; then
        echo "Last ticket is: $ticket"
        raida_url="https://$raida.cloudcoin.global/service/hints"
        raida_url="$raida_url?rn=$ticket"
        start_s=$(Timer)
        http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
        http_retval=$?
        end_s=$(Timer)
        elapsed=$(( (end_s-start_s)/1000000 ))

        if [ $http_retval -eq 0 ]; then
            _sn=$(echo $http_response | cut -d: -f1)
            _ms=$(echo $http_response | cut -d: -f2)
            status="Success, The serial number was $_sn and the ticket age was $_ms milliseconds old."
            status_color="$_GREEN_$status$_REST_"
            response_color="$_GREEN_$http_response$_REST_"
        else
            status="error"
            status_color="$_RED_$status$_REST_"
            response_color="$_RED_$http_response$_REST_"
            hints_retval=1
        fi

        echo
        echo -e "Status: $_BOLD_$status_color"
        echo "Milliseconds: $elapsed"
        echo "Request: $raida_url"
        echo -e "Response: $response_color"
        echo

    else
        hints_retval=1
    fi

    return $hints_retval
}

_all_fix(){
    local i
    local j
    local n
    
    # Check the local testcoin file
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    echo
    echo "FIX Results [Fix1,Fix2,Fix3,Fix4]: "
    for ((n=0;n<$raida_nums;n++))
    do
        echo -n "-> RAIDA#${n}: "
        _fix_all_corners $n  

    done
    echo;echo

}

_fix(){
    Load_testcoin
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    fixed_server=$1
    nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
    array_an=( $string_an )
    denom=$(Get_denom $sn)
     
    array_fix_corner1[1]=$(( fixed_server - 1))
    array_fix_corner1[2]=$(( fixed_server - 5))
    array_fix_corner1[3]=$(( fixed_server - 6))
    array_fix_corner2[1]=$(( fixed_server + 1))
    array_fix_corner2[2]=$(( fixed_server - 4))
    array_fix_corner2[3]=$(( fixed_server - 5))
    array_fix_corner3[1]=$(( fixed_server - 1))
    array_fix_corner3[2]=$(( fixed_server + 4))
    array_fix_corner3[3]=$(( fixed_server + 5))
    array_fix_corner4[1]=$(( fixed_server + 1))
    array_fix_corner4[2]=$(( fixed_server + 5))
    array_fix_corner4[3]=$(( fixed_server + 6))

    for ((i=1;i<=4;i++))
    do
        array_name="array_fix_corner$i"
        n=1
        for j in $(eval echo \${$array_name[@]})
        do
            if [ $j -lt 0 ];then
                eval $array_name[$n]=$(( $j + 25))
            elif [ $j -gt 24 ];then
                eval $array_name[$n]=$(( $j - 25))
            fi
            ((n++))
        done
    done

    input=""
    while true
    do
        echo "What RAIDA triad do you want to use? 1.Upper-Left, 2.Upper-Right, 3.Lower-Left, 4.Lower-Right"
        read input
        if [ $input -gt 0 -a $input -lt 5  ];then
            array_name="array_fix_corner$input"
            array_trusted_servers=$(eval echo \${$array_name[@]})
            n=1
            Fix_ticket_retval=0

            for i in ${array_trusted_servers[@]}
            do
                raida="raida$i"
                an="${array_an[$i]}"
                raida_url="https://$raida.cloudcoin.global/service/get_ticket"
                raida_url="$raida_url?nn=$nn&sn=$sn&toserver=$fixed_server&an=$an&pan=$an&denomination=$denom"
                
                Fix_ticket_request $raida_url
                retval=$?

                if [ $retval -eq 0 ];then
                    fromserver[$n]="$i"
                    message[$n]="$ticket"
                    get_ticket_status[$n]="$status"
                else
                    get_ticket_status[$n]="empty"
                    Fix_ticket_retval=1   
                fi

                ((n++))
            done
            
            if [ $Fix_ticket_retval -eq 0 ]; then
                raida="raida$fixed_server"
                an="${array_an[$fixed_server]}"
                raida_url="https://$raida.cloudcoin.global/service/fix"
                raida_url="$raida_url?fromserver1=${fromserver[1]}&message1=${message[1]}&fromserver2=${fromserver[2]}&message2=${message[2]}&fromserver3=${fromserver[3]}&message3=${message[3]}&pan=$an"
                start_s=$(Timer)
                http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
                http_retval=$?
                end_s=$(Timer)
                elapsed=$(( (end_s-start_s)/1000000 ))

                if [ $http_retval -eq 0 ]; then
                    status=$(echo $http_response | sed 's/\\/\//g' | sed 's/.* \({.*}\)$/\1/' | $JQ_CMD -r '.status')
                else
                    status="error"
                    fix_retval=1
                fi

                if [ "$status" == "success" ];then
                    echo
                    echo -e "Status: $_BOLD_$_GREEN_$status$_REST_"
                    echo "Milliseconds: $elapsed"
                    echo "Request: $raida_url"
                    echo -e "Response: $_GREEN_$http_response$_REST_"
                    echo

                else
                    echo
                    echo -e "Status: $_BOLD_$_RED_$status$_REST_"
                    echo "Milliseconds: $elapsed"
                    echo "Request: $raida_url"
                    echo -e "Response: $_RED_$http_response$_REST_"
                    echo
                fi
            else
                echo
                echo "Ticket Status Results: ${get_ticket_status[@]}"
                echo -e "${_RED_}Trusted Servers failed to vouch for RAIDA$fixed_server. Fix may still work with another triad of trusted servers.${_REST_}"
                echo

            fi

            break

        else
            Error "$error_02"

        fi
    done

}

_fix_all_corners(){
    local c
    local i
    local j
    local n

    fixed_server=$1
    nn=`$JQ_CMD '.cloudcoin[].nn' $testcoin | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $testcoin | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $testcoin`
    array_an=( $string_an )
    denom=$(Get_denom $sn)
     
    array_fix_corner1[1]=$(( fixed_server - 1))
    array_fix_corner1[2]=$(( fixed_server - 5))
    array_fix_corner1[3]=$(( fixed_server - 6))
    array_fix_corner2[1]=$(( fixed_server + 1))
    array_fix_corner2[2]=$(( fixed_server - 4))
    array_fix_corner2[3]=$(( fixed_server - 5))
    array_fix_corner3[1]=$(( fixed_server - 1))
    array_fix_corner3[2]=$(( fixed_server + 4))
    array_fix_corner3[3]=$(( fixed_server + 5))
    array_fix_corner4[1]=$(( fixed_server + 1))
    array_fix_corner4[2]=$(( fixed_server + 5))
    array_fix_corner4[3]=$(( fixed_server + 6))

    for ((i=1;i<=4;i++))
    do
        array_name="array_fix_corner$i"
        n=1
        for j in $(eval echo \${$array_name[@]})
        do
            if [ $j -lt 0 ];then
                eval $array_name[$n]=$(( $j + 25))
            elif [ $j -gt 24 ];then
                eval $array_name[$n]=$(( $j - 25))
            fi
            ((n++))
        done
    done

    
    for ((c=1;c<=4;c++))
    do
        array_name="array_fix_corner$c"
        array_trusted_servers=$(eval echo \${$array_name[@]})
        n=1
        Fix_ticket_retval=0

        for i in ${array_trusted_servers[@]}
        do
            raida="raida$i"
            an="${array_an[$i]}"
            raida_url="https://$raida.cloudcoin.global/service/get_ticket"
            raida_url="$raida_url?nn=$nn&sn=$sn&toserver=$fixed_server&an=$an&pan=$an&denomination=$denom"
                
            Fix_ticket_request $raida_url >/dev/null 2>&1
            retval=$?

            if [ $retval -eq 0 ];then
                fromserver[$n]="$i"
                message[$n]="$ticket"
                get_ticket_status[$n]="$status"
            else
                get_ticket_status[$n]="empty"
                Fix_ticket_retval=1   
            fi

            ((n++))
        done
        
        if [ $Fix_ticket_retval -eq 0 ]; then
            sleep 1
            raida="raida$fixed_server"
            an="${array_an[$fixed_server]}"
            raida_url="https://$raida.cloudcoin.global/service/fix"
            raida_url="$raida_url?fromserver1=${fromserver[1]}&message1=${message[1]}&fromserver2=${fromserver[2]}&message2=${message[2]}&fromserver3=${fromserver[3]}&message3=${message[3]}&pan=$an"
            start_s=$(Timer)
            http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
            http_retval=$?
            end_s=$(Timer)
            elapsed=$(( (end_s-start_s)/1000000 ))

            if [ $http_retval -eq 0 ]; then
                status=$(echo $http_response | sed 's/\\/\//g' | sed 's/.* \({.*}\)$/\1/' | $JQ_CMD -r '.status')
                fix_retval=0
            else
                status="error"
                fix_retval=1
            fi

            if [ "$status" != "success" ];then
                fix_retval=1
            fi

        else
            fix_retval=1

        fi
        
        if [ $fix_retval -eq 0 ];then
            [ $c -eq 4 ] && echo "pass" || echo -n "pass, "
        else
            [ $c -eq 4 ] && echo -e "${_RED_}fail${_REST_}" || echo -e -n "${_RED_}fail${_REST_}, "
        fi
    done

}


Hints_ticket_request(){
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
            echo -e "$_RED_$string_01$_REST_"
            echo -e "Status: $_BOLD_$_RED_$status$_REST_"
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
        echo -e "$_BOLD_$_RED_$string_05$_REST_"
        echo "Request: $raida_url"
        echo
        return 1

    fi
}

Fix_ticket_request(){
    raida_url="$1"
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    is_raida=$(echo $http_response | grep -c "server")
    ticket=""

    if [ "$is_raida" == "1" ];then
        message="$(echo $http_response | $JQ_CMD -r '.message')"
        status="$(echo $http_response | $JQ_CMD -r '.status')"

        if [ $status != "ticket" ];then
            echo
            echo $raida_url
            echo
            echo -e "$_RED_$http_response$_REST_"
            return 1

        else
            echo
            echo $raida_url
            echo
            echo -e "$_GREEN_$http_response$_REST_"
            ticket="$message"
            return 0

        fi
    else
        echo
        echo -e "$_BOLD_$_RED_$string_05$_REST_"
        echo "Request: $raida_url"
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
