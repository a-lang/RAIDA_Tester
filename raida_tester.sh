#!/usr/bin/env bash
# 
# Created: 2017-3-20, A-Lang
# 
# Change Logs:
#   17/10/14 - Added test for multi_detect
#   17/10/15 - Added detection for version
#   18/04/10 - JSON validation for ECHO
#   19/05/25 - Added datetime for Advanced ECHO 
#   19/06/09 - Added multi_fix
#   19/06/27 - Update _all_echo
#

# Variables
VERSION="190707"
TESTCOINFILE1="testcoin.stack"
TESTCOINFILE2="testcoin_multi.stack"
TESTCOINFILE3="testcoin_multi2.stack"
TESTCOINFILE4="testcoin_id1_x1.stack"
TESTCOINFILE5="testcoin_id2_x1.stack"
TESTCOINFILE6="testcoin_bank_x3.stack"
RAIDA_NUMS=25
MAX_LATENCY=15
MAX_POST_NOTES=400
WARN_MS=6000    # millisecond
_REST_='\033[0m'
_GREEN_='\033[32m'
_RED_='\033[31m'
_BOLD_='\033[1m'
CURL_CMD="curl"
CURL_OPT="-qSfs -m 60"
CURL_OPT_multi="-qSfs -m 60 -X POST"
JQ_CMD="jq"
HTML_DIR="html"
# for Debgugging only
DEBUG=0    # True:1 , False:0
LOG_FILE="debug.log"



# Don't change the following lines
WORKDIR="$( cd $( dirname "$0" ) && pwd )"
RUNNINGOS=$(`echo uname` | tr '[a-z]' '[A-Z]')
RUNNINGARCH=$(`echo uname -m` | tr '[a-z]' '[A-Z]')


# Strings
STRING_01="Could not Check hints because get_ticket service failed to get a ticket. Fix get_ticket first."
STRING_02=""
STRING_03="Checking ticket..."
STRING_04=""
STRING_05="HTTPS Access No Response"
STRING_06="Would you like to generate a html report for test results (y/N)?"
ERROR_01="Error: Coin Files Not Found!"
ERROR_02="Error: Invalid Command"
ERROR_03="Error:"
ERROR_04="Error:"
ERROR_05="Error: Test failed, run the echo to see more details."
ERROR_06="Error: Test failed, run the detect to see more details."
ERROR_07="Error: Test failed, run the get_ticket to see more details."


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
#                                                                           #
# You must have several authentic CloudCoin .stack files called             #
# 'testcoin*.stack' in the same folder as this program to run tests.        #
#############################################################################
[Version: ${VERSION}][Debug: `[ $DEBUG -eq 1 ] && echo "ON" || echo "OFF"`]
EOF
}

Show_menu(){
    cat <<EOF
===================================
RAIDA Tester Commands Available:
[+] echo              (e)
[+] detect            (d)
[+] get_ticket        (g)
[+] hints             (h)
[+] fix               (f)
[+] multi_detect      (md)
[+] multi_detect+     (md2)
[+] multi_get_ticket  (mg)
[+] multi_hints       (mh)
[+] multi_fix         (mf)
[+] skywallet         (sw)  *New*
[+] fix_fracked_coins (ff)  *New*
[+] advanced          (a)
[+] quit              (q)
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
 yum install curl jq
 or
 apt-get install curl jq
  
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

        elif [ "$input" == "multi_detect" -o "$input" == "md" ];then
            Process_request _multi_detect

        elif [ "$input" == "multi_detect+" -o "$input" == "md2" ];then
            Process_request _multi_detect2

        elif [ "$input" == "multi_get_ticket" -o "$input" == "mg" ];then
            Process_request _multi_get_ticket

        elif [ "$input" == "multi_hints" -o "$input" == "mh" ];then
            Process_request _multi_hints

        #elif [ "$input" == "multi_fix3" -o "$input" == "mf" ];then
        #    isFix4Mode="false"
        #    Process_request _multi_fix

        elif [ "$input" == "multi_fix4" -o "$input" == "mf" ];then
            isFix4Mode="true"
            Process_request _multi_fix      

        elif [ "$input" == "advanced" -o "$input" == "a" ];then
            Advanced

        elif [ "$input" == "skywallet" -o "$input" == "sw" ];then
            Ask_raida_node "_SkyWallet" "SKYWALLET"

        elif [ "$input" == "fix_fracked_coins" -o "$input" == "ff" ];then
            _fix_fracked_coins

        elif [ "$input" == "quit" -o "$input" == "q" ];then
            break

        else
            Error "$ERROR_02"
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
    local prompt input
    input=""
    prompt="ADVANCED"
    while true
    do
        echo "Test All RAIDA Nodes [1-7]: 1.Echo 2.Detect 3.Ticket 4.Hints 5.Fix q.Exit"
        echo "                            6.Multi_Detect  7.Multi_Ticket"
        echo "NOTE: This process may take a few mins to check all nodes please be patient until all checks done."
        echo -n "$prompt> " && read input
        if [ $input -ge 1 -a $input -le 7 ] 2>/dev/null ;then
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
                6)
                    _all_multi_detect
                    ;;
                7)
                    _all_multi_get_ticket
                    ;;
            esac

        elif [ "$input" == "q" ] 2>/dev/null ;then
            break

        else
            Error "$ERROR_02"

        fi
    done
}

Ask_raida_node(){  # Ask_raida "Call-to-Function" "Prompt-String"
    local func prompt input 
    func="$1"
    prompt="$2"
    input=""

    while [ "$input" != "$RAIDA_NUMS" ]
    do
        echo
        echo "What RAIDA# do you want to test $prompt? Enter q to end."
        echo -n "$prompt[0-$((RAIDA_NUMS - 1))]> " && read input
        if [ $input -ge 0 -a $input -lt $RAIDA_NUMS  ] 2>/dev/null;then
            $func $input

        elif [ "$input" == "q" ] 2>/dev/null;then
            return
        else
            Error "$ERROR_02"
        fi
    done
}

Ask_coin_file(){
    local prompt input 
    local n coins_list
    prompt="$1"
    input=""

    coins_list=( $(Get_coin_files) )
    coins_count=${#coins_list[@]}
    # for debug only
    #echo "coins_list-> ${coins_list[@]}"
    #echo "coins_count-> $coins_count"
    if [ $coins_count -eq 0 ];then
        Error "$ERROR_01"
        return 1
    fi

    for ((n=0;n<$coins_count;n++))
    do
        echo "[$((n+1))] ${coins_list[$n]}"
    done

    GET_COINFILE=""
    while [ "$input" != "q" ]
    do
        echo
        echo "Please select the coin file. Enter q to end."
        echo -n "$prompt[1-$coins_count]> " && read input
        if [ $input -ge 1 -a $input -le $coins_count  ] 2>/dev/null;then
            GET_COINFILE="${coins_list[$((input-1))]}"
            return 0
        elif [ "$input" != "q" ];then 
            Error "$ERROR_02"
        fi
    done
    return 1 

}

_fix_fracked_coins(){
    local coinfile input1 input2 func node_num
    local prompt1 prompt2 prompt3 prompt4
    local sn sns_list

    coinfile=""
    prompt1="FIX_COINS"
    Ask_coin_file "$prompt1"
    if [ $? -eq 0 ];then
        coinfile="$GET_COINFILE"
        prompt2="$prompt1)$coinfile"
    else
        return 1
    fi

    # Check if the coin file with over 200 notes
    sn=`$JQ_CMD -r '.cloudcoin[].sn' $coinfile`
    sns_list=( $sn )
    if [ ${#sns_list[@]} -gt 200 ];then
        Error "Error: The tester program is unable to handle more than 200 notes in the $coinfile!"
        return 1
    fi
    
    input1=""
    while [ "$input1" != "q" ]
    do
        echo "[1] multi detect"
        echo "[2] multi fix"
        echo
        echo "Please select the function. Enter q to end."
        echo -n "$prompt2)[1-2]> " && read input1
        if [ $input1 -ge 1 -a $input1 -le 2  ] 2>/dev/null;then
            case "$input1" in
                1)
                    prompt3="$prompt2)_multi_detect"
                    func="_multi_detect"
                    ;;
                2)
                    prompt3="$prompt2)_multi_fix"
                    isFix4Mode="true"
                    func="_multi_fix"
                    ;;
            esac
            input2=""
            while [ "$input2" != "q" ]
            do
                echo
                echo "Please select the RAIDA node. Enter q to go back."
                echo -n "$prompt3)[0-$((RAIDA_NUMS-1))]> " && read input2
                if [ $input2 -ge 0 -a $input2 -le $((RAIDA_NUMS-1)) ] 2>/dev/null;then
                    node_num=$input2
                    #echo "Debug: $func $node_num $coinfile"
                    $func "$node_num" "$coinfile"

                elif [ "$input2" != "q" ];then 
                    Error "$ERROR_02"
                fi
            done
        elif [ "$input1" != "q" ];then 
            Error "$ERROR_02"
        fi
    done

}

_SkyWallet() {
    local raida prompt node_num
    local input
    node_num="$1"
    raida="raida$node_num"
    prompt="RAIDA($node_num)-SW"

    while true
    do
        echo "Test functions : 1.Multi_Detect 2.Show_ID1 3.Show_ID2 4.Send_ID1 5.Send_ID2 q.Exit"
        echo "[1-11]           6.Receive_ID1 7.Receive_ID2 8.Transfer_ID1 9.Transfer_ID2 10.Rename_Tag_ID1"
        echo "                 11.Rename_Tag_ID2"
        echo -n "$prompt> " && read input
        if [ $input -ge 1 -a $input -le 11 ] 2>/dev/null;then
            case "$input" in
                1)
                     _multi_detect "$node_num" "$testcoinfile6" 
                     ;;
                2)
                    _SW_Show "$node_num" "$TESTCOINFILE4"
                    ;;
                3)
                    _SW_Show "$node_num" "$TESTCOINFILE5"
                    ;;
                4)
                    _SW_Send "$node_num" "$TESTCOINFILE4" "$TESTCOINFILE6"
                    ;;
                5)
                    _SW_Send "$node_num" "$TESTCOINFILE5" "$TESTCOINFILE6"
                    ;;
                6)
                    _SW_Receive "$node_num" "$TESTCOINFILE4" "$TESTCOINFILE6"
                    ;;
                7)
                    _SW_Receive "$node_num" "$TESTCOINFILE5" "$TESTCOINFILE6"
                    ;;
                8)
                    _SW_Transfer "$node_num" "$TESTCOINFILE4" "$TESTCOINFILE5" "$TESTCOINFILE6"
                    ;;
                9)
                    _SW_Transfer "$node_num" "$TESTCOINFILE5" "$TESTCOINFILE4" "$TESTCOINFILE6"
                    ;;
                10)
                    _SW_RenameTag "$node_num" "$TESTCOINFILE4"
                    ;;
                11)
                    _SW_RenameTag "$node_num" "$TESTCOINFILE5"
                    ;;
                #12)
                #    isFix4Mode="true"
                #    _multi_fix "$node_num" "$TESTCOINFILE6" 
                #    ;;

            esac
        elif [ "$input" == "q" ] 2>/dev/null;then
            break
        else
            Error "$ERROR_02"
        fi
    done
}

Process_request(){
    local prompt input option
    input=""
    option="$1"

    case "$option" in
        _echo)
            prompt="ECHO"
            ;;
        _detect)
            prompt="DETECT"
            ;;
        _get_ticket)
            prompt="GET_TICKET"
            ;;
        _hints)
            prompt="HINTS"
            ;;
        _fix)
            prompt="FIX"
            ;;
        _multi_detect)
            prompt="MULTI_DETECT"
            ;;
        _multi_detect2)
            prompt="MULTI_DETECT+"
            ;;
        _multi_get_ticket)
            prompt="MULTI_GET_TICKET"
            ;;
        _multi_hints)
            prompt="MULTI_HINTS"
            ;;
        _multi_fix)
            if [ "$isFix4Mode" = "true" ];then
                prompt="MULTI_FIX4"
            else
                prompt="MULTI_FIX3"
            fi
            ;;   
    esac

    Ask_raida_node "$option" "$prompt"
    
}

_all_echo(){
    local n
    local version

    #ask_html "ECHO"
    #retval=$?
    #[ $retval -eq 1 ] && return 1 # html template file not found

    echo "ECHO Results: "
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        _echo $n >/dev/null 2>&1
        run_echo=$?
        if [ $run_echo -eq 0 ];then
            result="PASS"
        else
            result="${_RED_}FAIL${_REST_}"
        fi

        version=$(Get_version $n) 
        #Output $n "v$version|time:$echo_datetime|$result" $echo_elapsed
        Output $n "v$version|time:$echo_datetime|status:$result|$echo_msg"

        if [ "$result" != "PASS" ];then
            Output2 "$echo_response"
        fi

        #if [ "$save_to_html" == "YES" ];then
        #    html_report="echotest.html"
        #    raida_node=$n
        #    get_status="$status"
        #    get_request="$raida_url"
        #    get_response="$http_response"
        #    get_ms="$elapsed"
        #    get_ver="$version"

        #    Basic_htmlreport "$html_report" "$raida_node" "$get_status" "$get_request" "$get_response" "$get_ms" "$get_ver"
        #fi
    done
    echo;echo
}

_echo()
{
    echo_response=""
    echo_elapsed=0
    echo_datetime=""
    echo_msg=""
    
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
        datetime=$(echo $http_response | $JQ_CMD -r '.time' 2>/dev/null)
        status=$(echo $http_response | $JQ_CMD -r '.status' 2>/dev/null)
        msg=$(echo $http_response | $JQ_CMD -r '.message' 2>/dev/null)
        [ -z $status ] && status="invalid json data"
    else
        status="error"
        echo_retval=1
    fi

    if [ "$status" == "ready" -o "$status" == "notready" ];then
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
    
    echo_response=$http_response
    echo_elapsed=$elapsed
    echo_datetime=$datetime
    echo_msg=$msg
    return $echo_retval
}

_all_detect(){
    local n

    # Check the local testcoin file
    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    #ask_html "DETECT"
    #retval=$?
    #[ $retval -eq 1 ] && return 1 # html template file not found

    echo "DETECT Results: "
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        _detect $n >/dev/null 2>&1
        run_detect=$?
        if [ $run_detect -eq 0 ];then
            result="PASS"
        else
            result="${_RED_}FAIL${_REST_}"
        fi 

        Output $n "$result" $detect_elapsed

        if [ "$result" != "PASS" ];then
            Output2 "$detect_response"
        fi

        #if [ "$save_to_html" == "YES" ];then
        #    html_report="detecttest.html"
        #    raida_node=$n
        #    get_status="$status"
        #    get_request="$raida_url"
        #    get_response="$http_response"
        #    get_ms="$elapsed"

        #    Basic_htmlreport "$html_report" "$raida_node" "$get_status" "$get_request" "$get_response" "$get_ms"
        #fi
    done
    echo;echo
}

_detect(){
    detect_response=""
    detect_elapsed=0
    
    # Check the local testcoin file
    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/detect"
    nn=`$JQ_CMD '.cloudcoin[].nn' $TESTCOINFILE1 | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $TESTCOINFILE1 | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $TESTCOINFILE1`
    array_an=( $string_an )
    an="${array_an[$input]}"
    denom=$(Get_denom $sn)

    # Test the Echo
    test_echo=$(_echo $input)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"
        status="ECHO Failed"
        detect_response=$status
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
    
    detect_response=$http_response
    detect_elapsed=$elapsed
    return $detect_retval

}

_all_ticket(){
    local n

    # Check the local testcoin file
    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    #ask_html "TICKET"
    #retval=$?
    #[ $retval -eq 1 ] && return 1 # html template file not found

    echo "TICKET Results: "
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        _get_ticket $n >/dev/null 2>&1
        run_ticket=$?
        if [ $run_ticket -eq 0 ];then
            result="PASS"
        else
            result="${_RED_}FAIL${_REST_}"
        fi 
        
        #printf " %.18s [%4b] (%4ims) \n" "RAIDA($n).............." "$result" $ticket_elapsed
        Output $n "$result" $ticket_elapsed

        if [ "$result" != "PASS" ];then
            #printf "  %-20b \n" "--> ${_RED_}$ticket_response${_REST_}"
            Output2 "$ticket_response"
        fi

        #if [ "$save_to_html" == "YES" ];then
        #    html_report="tickettest.html"
        #    raida_node=$n
        #    get_status="$status"
        #    get_request="$raida_url"
        #    get_response="$http_response"
        #    get_ms="$elapsed"

        #    Basic_htmlreport "$html_report" "$raida_node" "$get_status" "$get_request" "$get_response" "$get_ms"
        #fi

    done
    echo;echo

}

_get_ticket(){
    ticket_response=""
    ticket_elapsed=0
    
    # Check the local testcoin file
    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/get_ticket"
    nn=`$JQ_CMD '.cloudcoin[].nn' $TESTCOINFILE1 | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $TESTCOINFILE1 | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $TESTCOINFILE1`
    array_an=( $string_an )
    an="${array_an[$input]}"
    denom=$(Get_denom $sn)

    # Test the Detect
    test_detect=$(_detect $input)
    run_detect=$?
    if [ $run_detect -eq 1 ];then
        Error "$ERROR_06"
        status="DETECT Failed"
        ticket_response=$status
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
    
    ticket_response=$http_response
    ticket_elapsed=$elapsed
    return $get_ticket_retval

}

_all_hints(){
    local n

    # Check the local testcoin file
    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    #ask_html "HINTS"
    #retval=$?
    #[ $retval -eq 1 ] && return 1 # html template file not found

    echo "HINTS Results: "
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        _hints $n > /dev/null 2>&1
        run_hints=$?
        if [ $run_hints -eq 0 ];then
            result="PASS"
            if [ $ret_hints_ms -gt $MAX_LATENCY -o $ret_hints_ms -lt 0 ];then
                result="${_RED_}NOT GOOD${_REST_}"
                
            fi

        else
            result="${_RED_}FAIL${_REST_}"
            
        fi 
        
        #printf " %.18s [%4b] (%4ims) %-12s \n" "RAIDA($n).............." "$result" $hints_elapsed "$hints_response"
        Output $n "$result" $hints_elapsed

        if [ "$result" != "PASS" ];then
            #printf "  %-20b \n" "--> ${_RED_}$hints_response${_REST_}"
            Output2 "$hints_response"
        fi

        #if [ "$save_to_html" == "YES" ];then
        #    html_report="hintstest.html"
        #    raida_node=$n
        #    get_status="$status"
        #    get_request="$raida_url"
        #    get_response="$http_response"
        #    get_ms="$elapsed"

        #    Basic_htmlreport "$html_report" "$raida_node" "$get_status" "$get_request" "$get_response" "$get_ms"
        #fi  

    done
    echo;echo

}

_hints(){
    local input
    local _sn
    local _ms
    hints_retval=0
    ret_hints_ms=99999999
    hints_response=""
    hints_elapsed=0

    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    # Get the ticket
    echo "$STRING_03"
    Hints_ticket_request $input
    Hints_ticket_retval=$?
    
            
    if [ $Hints_ticket_retval -eq 0 ]; then
        echo "Last ticket is: $ticket"
        raida="raida$input"
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
            if [ $_ms -ge $MAX_LATENCY -o $_ms -lt 0 ]; then
                _ms_color="$_RED_$_ms$_REST_"
                status="Error"
                status_color="$_RED_$status$_REST_"
                response_color="$_RED_$http_response$_REST_"
            else
                _ms_color="$_GREEN_$_ms$_REST_"
                status="Success, The serial number was $_sn and the ticket age was $_ms_color seconds old."
                status_color="$_GREEN_$status$_REST_"
                response_color="$_GREEN_$http_response$_REST_"
            fi
            ret_hints_ms=$_ms
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

    hints_response=$http_response
    hints_elapsed=$elapsed
    return $hints_retval
}

_all_fix(){
    local n
    local retval
    
    # Check the local testcoin file
    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    #ask_html "FIX"
    #retval=$?
    #[ $retval -eq 1 ] && return 1 # html template file not found

    echo
    #echo "FIX Results: [Fix1][Fix2][Fix3][Fix4] "
    printf " %.18s %30s \n" "FIX Results:" "[Fix1][Fix2][Fix3][Fix4]"
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        #echo -n "-> RAIDA#${n}: "
        printf " %.18s " "RAIDA($n).............."
        _fix_all_corners $n  

    done
    echo;echo

}

_fix(){
    local i
    local j
    local n
    local input
    local retval

    Coin_validation $TESTCOINFILE1
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    fixed_server=$1
    nn=`$JQ_CMD '.cloudcoin[].nn' $TESTCOINFILE | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $TESTCOINFILE1 | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $TESTCOINFILE1`
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
        echo "What RAIDA corners do you want to use? 1.Upper-Left, 2.Upper-Right, 3.Lower-Left, 4.Lower-Right"
        echo -n "Corner> " && read input
        if [ $input -gt 0 -a $input -lt 5  ];then
            array_name="array_fix_corner$input"
            array_trusted_servers=$(eval echo \${$array_name[@]})
            n=1
            Fix_ticket_retval=0

            for i in ${array_trusted_servers[@]}
            do
                an="${array_an[$i]}"
                Fix_ticket_request $i $nn $sn $fixed_server $an $denom
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
            Error "$ERROR_02"

        fi
    done

}

_fix_all_corners(){
    local c
    local i
    local j
    local n
    local k
    local retval
    local fix_retval
    local html_report
    local raida_node
    local get_status
    local get_request
    local get_response
    local get_ms
    local array_allfix_http_response

    fixed_server=$1
    nn=`$JQ_CMD '.cloudcoin[].nn' $TESTCOINFILE1 | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $TESTCOINFILE1 | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $TESTCOINFILE1`
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
            an="${array_an[$i]}"
            Fix_ticket_request $i $nn $sn $fixed_server $an $denom >/dev/null 2>&1
            retval=$?

            if [ $retval -eq 0 ];then
                fromserver[$n]="$i"
                message[$n]="$ticket"
                get_ticket_status[$n]="$status"
            else
                get_ticket_status[$n]="empty"
                Fix_ticket_retval=1 
                break  
            fi

            ((n++))
        done
        
        http_response=""
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
                array_allfix_http_response+=("$http_response")
            fi

        else
            fix_retval=1
            status="empty ticket"
            elapsed=0
            array_allfix_http_response+=("${status}") 

        fi
        
        if [ $fix_retval -eq 0 ];then
            [ $c -eq 4 ] && echo " PASS " || echo -n " PASS "
        else
            [ $c -eq 4 ] && echo -e "${_RED_}*FAIL*${_REST_}" || echo -e -n "${_RED_}*FAIL*${_REST_}"
        fi

    done

    for k in "${array_allfix_http_response[@]}"
    do
        Output2 "$k"
    done

}


_all_multi_detect(){
    local n run    

    # Check the testcoin file
    Coin_validation $TESTCOINFILE2
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    echo "MULTI_DETECT Results: "
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        _multi_detect $n >/dev/null 2>&1
        run=$?
        if [ $run -eq 0 ];then
            result="PASS"
        else
            result="${_RED_}FAIL${_REST_}"
        fi 

        Output $n "$result" $multi_detect_elapsed

        if [ "$result" != "PASS" ];then
            Output2 "$mult_detect_response"
        fi

    done
    echo;echo

}

_multi_detect(){
    unset array_nn
    unset array_sn
    unset array_an
    unset array_denom
    local s n a d 
    local input coinfile

    input="$1"
    coinfile="$2"
    mult_detect_response=""

    # If not specifying the coinfile, by default it's $testcoinfile2
    [ -z $coinfile ] && coinfile="$TESTCOINFILE2"

    # Check the testcoin file
    Coin_validation $coinfile
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/multi_detect"
    nn=`$JQ_CMD -r '.cloudcoin[].nn' $coinfile`
    sn=`$JQ_CMD -r '.cloudcoin[].sn' $coinfile`
    an=`$JQ_CMD -r ".cloudcoin[].an[$input]" $coinfile`
    array_nn=( $nn )
    array_sn=( $sn )
    array_an=( $an )

    for s in "${array_sn[@]}"
    do
        array_denom+=( "$(Get_denom $s)" )
    done

    ## for debugging only
    #echo "nn = ${array_nn[@]}"
    #echo "sn = ${array_sn[@]}"
    #echo "an = ${array_an[@]}"
    #echo "denom = ${array_denom[@]}"

    # Test the Echo
    test_echo=$(_echo $input)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"
        mult_detect_response="$ERROR_05"
        return 1
    fi 

    index=0
    for n in "${array_nn[@]}"
    do
        if [ $index -eq 0 ];then
            post_nns="nns[]=$n"
        else
            post_nns="$post_nns&nns[]=$n"
        fi
        ((index++))
    done

    index=0
    for s in "${array_sn[@]}"
    do
        if [ $index -eq 0 ];then
            post_sns="sns[]=$s"
        else
            post_sns="$post_sns&sns[]=$s"
        fi
        ((index++))
    done
    
    index=0
    for a in "${array_an[@]}"
    do
        if [ $index -eq 0 ];then
            post_ans="ans[]=$a"
            post_pans="pans[]=$a"
        else
            post_ans="$post_ans&ans[]=$a"
            post_pans="$post_pans&pans[]=$a"
        fi
        ((index++))
    done

    index=0
    for d in "${array_denom[@]}"
    do
        if [ $index -eq 0 ];then
            post_denoms="denomination[]=$d"
        else
            post_denoms="$post_denoms&denomination[]=$d"
        fi
        ((index++))
    done

    post_data="$post_nns&$post_sns&$post_ans&$post_pans&$post_denoms"

    ## for debugging only
    #echo "post_nns = $post_nns"
    #echo "post_sns = $post_sns"
    #echo "post_ans = $post_ans"
    #echo "post_pans = $post_pans"
    #echo "post_denoms = $post_denoms"
    #echo "post_data = $post_data"
    
    detect_retval=0
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))

    if [ $DEBUG -eq 1 ]; then
        Log "[_multi_detect] " "POST_URL: $raida_url "
        Log "[_multi_detect] " "POST_DATA: $post_data"
        Log "[_multi_detect] " "POST_RESPONSE: $http_response"
        Log "[_multi_detect] " "End of POST"
    fi

    if [ $http_retval -eq 0 ];then
        status=$(echo $http_response | $JQ_CMD -r '.[0].status')

        if [ "$status" == "pass" ];then
            response_color="$_GREEN_$http_response$_REST_"
        else
            response_color="$_RED_$http_response$_REST_"
            detect_retval=1
            
        fi
    else
        response_color="$_RED_$http_response$_REST_"
        detect_retval=1
    fi

    echo
    echo "Milliseconds: $elapsed"
    echo "Request: $raida_url"
    echo -e "Response: $response_color"
    echo

    mult_detect_response="$http_response"
    multi_detect_elapsed=$elapsed
    return $detect_retval
}

_multi_detect2(){
    unset array_nn
    unset array_sn
    unset array_an
    unset array_denom
    local node raida raida_url input
    local s n i j 
    local post_sns post_nns post_ans post_pans post_denoms
    # Check the testcoin file
    Coin_validation $TESTCOINFILE3
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    node="$1"
    nn=`$JQ_CMD -r '.cloudcoin[].nn' $TESTCOINFILE3`
    sn=`$JQ_CMD -r '.cloudcoin[].sn' $TESTCOINFILE3`
    an=`$JQ_CMD -r ".cloudcoin[].an[$node]" $TESTCOINFILE3`
    array_nn=( $nn )
    array_sn=( $sn )
    array_an=( $an )

    for s in "${array_sn[@]}"
    do
        array_denom+=( "$(Get_denom $s)" )
    done

    notes_total=${#array_sn[@]}

    while true
    do
        echo -n "How many of the notes to post once (< $MAX_POST_NOTES or ENTER)? " && read input
        if [ -z $input ];then
            notes_post=$MAX_POST_NOTES
        else
            notes_post=$input
        fi

        if [ $notes_post -gt 0 -a $notes_post -le $MAX_POST_NOTES ];then
            detect_round=$(( ($notes_total / $notes_post) + ($notes_total % $notes_post > 0) ))
            n=0
            j=0
            while [ $n -lt $notes_total ]
            do
                if [ $((($notes_total - $n + 1))) -gt $notes_post ];then
                    for ((i=0;i<$notes_post;i++))
                    do
                        if [ $i -eq 0 ];then
                            post_sns="sns[]=${array_sn[$n]}"
                            post_nns="nns[]=${array_nn[$n]}"
                            post_ans="ans[]=${array_an[$n]}"
                            post_pans="pans[]=${array_an[$n]}"
                            post_denoms="denomination[]=${array_denom[$n]}"
                            
                        else
                            post_sns="$post_sns&sns[]=${array_sn[$n]}"
                            post_nns="$post_nns&nns[]=${array_nn[$n]}"
                            post_ans="$post_ans&ans[]=${array_an[$n]}"
                            post_pans="$post_pans&pans[]=${array_an[$n]}"
                            post_denoms="$post_denoms&denomination[]=${array_denom[$n]}"
                        fi
                        ((n++))
                    done
                    #echo "-> $post_sns"
                    #echo "-> $post_nns"
                    #echo "-> $post_ans"
                    #echo "-> $post_pans"
                    #echo "-> $post_denoms"
                    post_data="$post_nns&$post_sns&$post_ans&$post_pans&$post_denoms"
                    _post_multi_detect "$node" "$post_data" $notes_post
                else
                    last_round=$((($notes_total - $n)))
                    for ((i=0;i<$last_round;i++))
                    do
                        if [ $i -eq 0 ];then
                            post_sns="sns[]=${array_sn[$n]}"
                            post_nns="nns[]=${array_nn[$n]}"
                            post_ans="ans[]=${array_an[$n]}"
                            post_pans="pans[]=${array_an[$n]}"
                            post_denoms="denomination[]=${array_denom[$n]}"
                        else
                            post_sns="$post_sns&sns[]=${array_sn[$n]}"
                            post_nns="$post_nns&nns[]=${array_nn[$n]}"
                            post_ans="$post_ans&ans[]=${array_an[$n]}"
                            post_pans="$post_pans&pans[]=${array_an[$n]}"
                            post_denoms="$post_denoms&denomination[]=${array_denom[$n]}"
                        fi
                        ((n++))
                    done
                    #echo "last-> $post_sns"
                    #echo "last-> $post_nns"
                    #echo "last-> $post_ans"
                    #echo "last-> $post_pans"
                    #echo "last-> $post_denoms"
                    post_data="$post_nns&$post_sns&$post_ans&$post_pans&$post_denoms"
                    _post_multi_detect "$node" "$post_data" $last_round 
                fi
            done
            break
        fi
        Error "$ERROR_02"
    done

}

_post_multi_detect(){
    unset array_status
    local node post_data status s pass_count fail_count
    local raida raida_url start_s end_s elapsed total_count
    node="$1"
    post_data="$2"
    post_nums=$3

    raida="raida$node"
    raida_url="https://$raida.cloudcoin.global/service/multi_detect"
    detect_retval=0
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))
    ## for debugging only
    #echo $http_response

    if [ $DEBUG -eq 1 ]; then
        Log "[_post_multi_detect] " "POST_URL: $raida_url "
        Log "[_post_multi_detect] " "POST_DATA: $post_data"
        Log "[_post_multi_detect] " "POST_RESPONSE: $http_response"
        Log "[_post_multi_detect] " "End of POST"
    fi

    if [ $http_retval -eq 0 ];then
        status=$(echo $http_response | $JQ_CMD -r '.[].status' 2>&1)
        status_retval=$?

        if [ $status_retval -eq 0 ];then
            array_status=( $status )
            #echo "status -> ${array_status[@]}"
            
            pass_count=0
            fail_count=0
            total_count=${#array_status[@]}
            if [ $total_count -eq $post_nums ];then
                for s in "${array_status[@]}"
                do
                    [ "$s" == "pass" ] && ((pass_count++))
                    [ "$s" == "fail" ] && ((fail_count++))
                done
                
                if [ $elapsed -gt $WARN_MS ];then
                    printf " -> Posted: %3d | Detected: %3d | Pass: %3d , Fail: %3d (${_RED_}%4i${_REST_}ms)\n" $post_nums $total_count $pass_count $fail_count $elapsed
                else
                    printf " -> Posted: %3d | Detected: %3d | Pass: %3d , Fail: %3d (%4ims)\n" $post_nums $total_count $pass_count $fail_count $elapsed
                fi    
                return 0

            else
                detect_retval=1
            fi
        else
            detect_retval=1
        fi
    else
        detect_retval=1
    fi

    if [ $detect_retval -eq 1 ];then
        printf " -> Posted: %3d | Detected: ${_RED_}%3d${_REST_} | Pass: ${_RED_}%3d${_REST_} , Fail: ${_RED_}%3d${_REST_}\n" $post_nums 0 0 0
    fi

}


_all_multi_get_ticket(){
    local n run    

    # Check the testcoin file
    Coin_validation $TESTCOINFILE2
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    echo "MULTI_TICKET Results: "
    for ((n=0;n<$RAIDA_NUMS;n++))
    do
        _multi_get_ticket $n >/dev/null 2>&1
        run=$?
        if [ $run -eq 0 ];then
            result="PASS"
        else
            result="${_RED_}FAIL${_REST_}"
        fi 

        Output $n "$result" $multi_tickets_elapsed

        if [ "$result" != "PASS" ];then
            Output2 "$multi_tickets_response"
        fi

    done
    echo;echo

}


_multi_get_ticket(){
    unset array_nn
    unset array_sn
    unset array_an
    unset array_denom
    local input raida raida_url
    local k n s a d 
    local post_nns post_sns post_ans post_pans post_denoms post_data 
    local node_num coinfile
    multi_tickets_response=""

    node_num="$1"
    coinfile="$2"

    # If not specifying the coinfile, by default it's $testcoinfile2
    [ -z $coinfile ] && coinfile="$TESTCOINFILE2"

    # Check the testcoin file
    Coin_validation $coinfile
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/multi_get_ticket"
    nn=`$JQ_CMD -r '.cloudcoin[].nn' $coinfile`
    sn=`$JQ_CMD -r '.cloudcoin[].sn' $coinfile`
    an=`$JQ_CMD -r ".cloudcoin[].an[$node_num]" $coinfile`
    array_nn=( $nn )
    array_sn=( $sn )
    array_an=( $an )

    for k in "${array_sn[@]}"
    do
        array_denom+=( "$(Get_denom $k)" )
    done

    ## for debugging only
    #echo "nn = ${array_nn[@]}"
    #echo "sn = ${array_sn[@]}"
    #echo "an = ${array_an[@]}"
    #echo "denom = ${array_denom[@]}"

    # Test the Echo
    test_echo=$(_echo $node_num)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"
        multi_tickets_response="$ERROR_05"
        return 1
    fi 

    index=0
    for n in "${array_nn[@]}"
    do
        if [ $index -eq 0 ];then
            post_nns="nns[]=$n"
        else
            post_nns="$post_nns&nns[]=$n"
        fi
        ((index++))
    done

    index=0
    for s in "${array_sn[@]}"
    do
        if [ $index -eq 0 ];then
            post_sns="sns[]=$s"
        else
            post_sns="$post_sns&sns[]=$s"
        fi
        ((index++))
    done
    
    index=0
    for a in "${array_an[@]}"
    do
        if [ $index -eq 0 ];then
            post_ans="ans[]=$a"
            post_pans="pans[]=$a"
        else
            post_ans="$post_ans&ans[]=$a"
            post_pans="$post_pans&pans[]=$a"
        fi
        ((index++))
    done

    index=0
    for d in "${array_denom[@]}"
    do
        if [ $index -eq 0 ];then
            post_denoms="denomination[]=$d"
        else
            post_denoms="$post_denoms&denomination[]=$d"
        fi
        ((index++))
    done

    post_data="$post_nns&$post_sns&$post_ans&$post_pans&$post_denoms"

    ## for debugging only
    #echo "post_nns = $post_nns"
    #echo "post_sns = $post_sns"
    #echo "post_ans = $post_ans"
    #echo "post_pans = $post_pans"
    #echo "post_denoms = $post_denoms"
    #echo "post_data = $post_data"

    multi_ticket_retval=0
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))

    if [ $http_retval -eq 0 ];then
        status=$(echo $http_response | $JQ_CMD -r '.[0].status')

        if [ "$status" == "ticket" ];then
            response_color="$_GREEN_$http_response$_REST_"
        else
            response_color="$_RED_$http_response$_REST_"
            multi_ticket_retval=1
            
        fi
    else
        response_color="$_RED_$http_response$_REST_"
        multi_ticket_retval=1
    fi

    echo
    echo "Milliseconds: $elapsed"
    echo "Request: $raida_url"
    echo -e "Response: $response_color"
    echo

    multi_tickets_response="$http_response"
    multi_tickets_elapsed=$elapsed
    return $multi_ticket_retval

}


_multi_hints(){
    unset array_rn
    local input
    local raida
    local raida_url
    local i h
    local http_hints _ms

    # Check the testcoin file
    Coin_validation $TESTCOINFILE2
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/multi_hints"

    # _multi_get_ticket will return $multi_tickets_response
    # 
    _multi_get_ticket $input >/dev/null 2>&1
    run_multi_get_ticket=$?
    if [ $run_multi_get_ticket -eq 1 ];then
        Error "$ERROR_07"
        status="Get Ticket Failed"
        return 1
    fi 
    
    rns=$(echo $multi_tickets_response | $JQ_CMD -r '.[].message')
    array_rn=( $rns )
    #echo "rn = ${array_rn[@]}"

    index=0
    for i in "${array_rn[@]}"
    do
        if [ $index -eq 0 ];then
            post_rns="rns[]=$i"
        else
            post_rns="$post_rns&rns[]=$i"
        fi
        ((index++))
    done
    
    post_data="$post_rns"
    #echo $post_rns

    multi_hints_retval=0
    start_s=$(Timer)
    http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
    http_retval=$?
    end_s=$(Timer)
    elapsed=$(( (end_s-start_s)/1000000 ))

    if [ $http_retval -eq 0 ];then
        http_hints=$(echo $http_response | $JQ_CMD -r .[])
        array_hints=( $http_hints)

        response_color="$_GREEN_$http_response$_REST_"
        for h in "${array_hints[@]}"
        do
            _ms=$(echo $h | cut -d: -f2)
            if [ $_ms -ge $MAX_LATENCY -o $_ms -lt 0 ]; then
                response_color="$_RED_$http_response$_REST_"
            fi
        done
    else
        response_color="$_RED_$http_response$_REST_"
        multi_hints_retval=1
    fi

    echo
    echo "Milliseconds: $elapsed"
    echo "Request: $raida_url"
    echo -e "Response: $response_color"
    echo

    return $multi_hints_retval

}


_multi_fix(){
    local a i n j d input notes
    local post_pans post_messages post_nns post_fromservers post_data 
    local node_num coinfile

    unset array_fix_corner1
    unset array_fix_corner2
    unset array_fix_corner3
    unset array_fix_corner4

    node_num="$1"
    coinfile="$2"

    # If not specifying the coinfile, by default it's $testcoinfile2
    [ -z $coinfile ] && coinfile="$TESTCOINFILE2"

    # Check the testcoin file
    Coin_validation $coinfile
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    fixed_server=$node_num
    nn=`$JQ_CMD -r '.cloudcoin[].nn' $coinfile`
    sn=`$JQ_CMD -r '.cloudcoin[].sn' $coinfile`
    an=`$JQ_CMD -r ".cloudcoin[].an[$fixed_server]" $coinfile`
    array_nn=( $nn )
    array_sn=( $sn )
    array_an=( $an )

    array_fix_corner1[1]=$(( fixed_server - 6))
    array_fix_corner1[2]=$(( fixed_server - 5))
    array_fix_corner1[3]=$(( fixed_server - 1))
    array_fix_corner2[1]=$(( fixed_server - 5))
    array_fix_corner2[2]=$(( fixed_server - 4))
    array_fix_corner2[3]=$(( fixed_server + 1))
    array_fix_corner3[1]=$(( fixed_server + 5))
    array_fix_corner3[2]=$(( fixed_server + 4))
    array_fix_corner3[3]=$(( fixed_server - 1))
    array_fix_corner4[1]=$(( fixed_server + 6))
    array_fix_corner4[2]=$(( fixed_server + 5))
    array_fix_corner4[3]=$(( fixed_server + 1))

    if [ "$isFix4Mode" = "true" ];then
        array_fix_corner1[4]=$(( fixed_server + 6))
        array_fix_corner2[4]=$(( fixed_server + 4))
        array_fix_corner3[4]=$(( fixed_server - 4))
        array_fix_corner4[4]=$(( fixed_server - 6))
    fi    

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
        echo "What RAIDA corners do you want to use? 1.Upper-Left, 2.Upper-Right, 3.Lower-Left, 4.Lower-Right"
        echo -n "Corner> " && read input
        if [ $input -gt 0 -a $input -lt 5  ];then
            array_name="array_fix_corner$input"
            array_trusted_servers=$(eval echo \${$array_name[@]})
            n=1
            post_messages=""
            post_nns=""
            post_pans=""
            post_fromservers=""
            #echo "array_name = ${array_name[@]}"
            #echo "array_trusted_servers = ${array_trusted_servers[@]}"

            index=0
            for a in "${array_an[@]}"
            do
                if [ $index -eq 0 ];then
                    post_pans="pans[]=$a"
                else
                    post_pans="$post_pans&pans[]=$a"
                fi
                ((index++))
            done

            for i in ${array_trusted_servers[@]}
            do
                _multi_get_ticket "$i" "$coinfile"
                run_multi_get_ticket=$?
                if [ $run_multi_get_ticket -eq 1 ];then
                    Error "$ERROR_07"
                    status="Get Ticket Failed"
                    return 1
                fi 

                tickets=$(echo $multi_tickets_response | $JQ_CMD -r '.[].message')
                array_tickets=( $tickets )
                #echo "array_tickets = ${array_tickets[@]}"

                notes=0
                for d in "${array_tickets[@]}"
                do
                    if [ $n -eq 1 -a $notes -eq 0 ];then
                        #post_fromservers="fromserver$n[]=$i"
                        post_messages="message${n}[]=${d}"
                    else
                        #post_fromservers="$post_fromservers&fromserver$n[]=$i"
                        post_messages="${post_messages}&message${n}[]=${d}"
                    fi

                    ((notes++))
                done

                if [ $n -eq 1 ];then
                    post_fromservers="fromserver$n=$i"
                else
                    post_fromservers="$post_fromservers&fromserver$n=$i"
                fi

                ((n++))
            done

            #post_data="$post_fromservers&$post_messages&$post_pans"
            post_data="$post_fromservers&$post_messages&$post_pans"

            ## for debugging only
            #echo "post_fromservers = $post_fromservers"
            #echo "post_messages = $post_messages"
            #echo "post_pans = $post_pans"
            #echo "post_data = $post_data"

            raida="raida$fixed_server"
            raida_url="https://$raida.cloudcoin.global/service/multi_fix"
            multi_fix_retval=0
            start_s=$(Timer)
            http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
            http_retval=$?
            end_s=$(Timer)
            elapsed=$(( (end_s-start_s)/1000000 ))
            
            if [ $http_retval -eq 0 ];then
                status=$(echo $http_response | $JQ_CMD -r '.[0].status')
        
                if [ "$status" == "pass" ];then
                    response_color="$_GREEN_$http_response$_REST_"
                else
                    response_color="$_RED_$http_response$_REST_"
                    multi_fix_retval=1
                    
                fi
            else
                response_color="$_RED_$http_response$_REST_"
                multi_fix_retval=1
            fi
            
            echo
            echo "Milliseconds: $elapsed"
            echo "Request: $raida_url"
            echo "Post Data: $post_data"
            echo -e "Response: $response_color"
            echo


            break
        else
            Error "$ERROR_02"
        fi

    done

}

Hints_ticket_request(){
    local input
    local raida
    local raida_url

    input="$1"
    raida="raida$input"
    raida_url="https://$raida.cloudcoin.global/service/get_ticket"
    nn=`$JQ_CMD '.cloudcoin[].nn' $TESTCOINFILE1 | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $TESTCOINFILE1 | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $TESTCOINFILE1`
    array_an=( $string_an )
    an="${array_an[$input]}"
    denom=$(Get_denom $sn)
    raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=$denom"
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    is_raida=$(echo $http_response | grep -c "server")

    if [ "$is_raida" == "1" ];then
        message="$(echo $http_response | $JQ_CMD -r '.message')"
        status="$(echo $http_response | $JQ_CMD -r '.status')"

        if [ $status != "ticket" ];then
            ticket=""
            echo "Last ticket is: empty"
            echo
            echo -e "$_RED_$STRING_01$_REST_"
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
        echo -e "$_BOLD_$_RED_$STRING_05$_REST_"
        echo "Request: $raida_url"
        echo
        return 1

    fi
}


Fix_ticket_request(){
    local raida raida_url
    local nn sn toserver an denom

    raida="raida$1"
    nn="$2"
    sn="$3"
    toserver="$4"
    an="$5"
    denom="$6"
    raida_url="https://$raida.cloudcoin.global/service/get_ticket"
    raida_url="$raida_url?nn=$nn&sn=$sn&an=$an&pan=$an&denomination=$denom"

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
        echo -e "$_BOLD_$_RED_$STRING_05$_REST_"
        echo "Request: $raida_url"
        return 1

    fi

}

_SW_Show(){
    local node_num coinfile
    node_num=$1
    coinfile="$2"

    # Check the local testcoin file
    Coin_validation $coinfile
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/show"
    nn=`$JQ_CMD '.cloudcoin[].nn' $coinfile | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $coinfile | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $coinfile`
    array_an=( $string_an )
    an="${array_an[$node_num]}"
    denom=$(Get_denom $sn)
    # for debug only
    #echo "nn-> $nn"
    #echo "sn-> $sn"
    #echo "an-> $an"
    #echo "denom-> $denom"

    # Test the Echo
    test_echo=$(_echo $node_num)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"    # Echo Failed
        return 1
    else
        raida_url="$raida_url?sn=$sn&an=$an&pan=$an&denomination=$denom"
        start_s=$(Timer)
        http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
        http_retval=$?
        end_s=$(Timer)
        elapsed=$(( (end_s-start_s)/1000000 ))

        if [ $http_retval -eq 0 ]; then
            status=$(echo $http_response | $JQ_CMD -r '.status')
            if [ "$status" == "pass" ];then
                http_sn=$(echo $http_response | $JQ_CMD -r '.message[].sn')
                http_array_sn=( $http_sn )
                if [ -z "$http_sn" ]; then
                    status_color="$_GREEN_ No coins in transfer pool!$_REST_"
                else
                    status_color="$_GREEN_$status (${http_array_sn[@]})$_REST_"
                fi
                response_color="$_GREEN_$http_response$_REST_"
            else
                status_color="$_RED_$status$_REST_"
                response_color="$_RED_$http_response$_REST_"
            fi

        else
            status="http-error"
            status_color="$_RED_$status$_REST_"
            response_color="$_RED_$http_response$_REST_"
        fi
        
        echo
        echo "[Show_ID]"
        echo "SN ID: $sn"
        echo -e "Status: $_BOLD_$status_color"
        echo "Milliseconds: $elapsed"
        echo "Request: $raida_url"
        echo -e "Response: $response_color"
        echo
    
    fi 
}

_SW_Send(){
    local node_num id_coinfile bank_coinfile
    local f s1 s2 a d
    local array_denom
    node_num=$1
    id_coinfile="$2"
    bank_coinfile="$3"

    # Check the local testcoin file
    for f in $id_coinfile $bank_coinfile
    do
        Coin_validation $f
        is_testcoin=$?
        [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format
    done

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/send"
    nn=`$JQ_CMD -r '.cloudcoin[].nn' $bank_coinfile`
    sn=`$JQ_CMD -r '.cloudcoin[].sn' $bank_coinfile`
    an=`$JQ_CMD -r ".cloudcoin[].an[$node_num]" $bank_coinfile`
    array_nn=( $nn )
    array_sn=( $sn )
    array_an=( $an )

    for s1 in "${array_sn[@]}"
    do
        array_denom+=( "$(Get_denom $s1)" )
    done

    ## for debugging only
    #echo "nn = ${array_nn[@]}"
    #echo "sn = ${array_sn[@]}"
    #echo "an = ${array_an[@]}"
    #echo "denom = ${array_denom[@]}"

    # Test the Echo
    test_echo=$(_echo $node_num)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"    # Echo Failed
        return 1
    else
        index=0
        post_sns=""
        for s2 in "${array_sn[@]}"
        do
            if [ $index -eq 0 ];then
                post_sns="sns[]=$s2"
            else
                post_sns="$post_sns&sns[]=$s2"
            fi
            ((index++))
        done

        index=0
        post_ans=""
        for a in "${array_an[@]}"
        do
            if [ $index -eq 0 ];then
                post_ans="ans[]=$a"
                post_pans="pans[]=$a"
            else
                post_ans="$post_ans&ans[]=$a"
                post_pans="$post_pans&pans[]=$a"
            fi
            ((index++))
        done

        index=0
        post_denoms=""
        for d in "${array_denom[@]}"
        do
            if [ $index -eq 0 ];then
                post_denoms="denomination[]=$d"
            else
                post_denoms="$post_denoms&denomination[]=$d"
            fi
            ((index++))
        done

        to_sn=`$JQ_CMD -r '.cloudcoin[].sn' $id_coinfile`
        post_to_sn="to_sn=$to_sn"
        post_tag="tag=SendTo$to_sn"
        post_data="$post_sns&$post_ans&$post_pans&$post_denoms&$post_to_sn&$post_tag"

        ## for debugging only
        #echo "post_nns = $post_nns"
        #echo "post_sns = $post_sns"
        #echo "post_ans = $post_ans"
        #echo "post_pans = $post_pans"
        #echo "post_denoms = $post_denoms"
        #echo "post_data = $post_data"

        start_s=$(Timer)
        http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
        http_retval=$?
        end_s=$(Timer)
        elapsed=$(( (end_s-start_s)/1000000 ))

        if [ $DEBUG -eq 1 ]; then
            Log "[_SW_Send] " "POST_URL: $raida_url "
            Log "[_SW_Send] " "POST_DATA: $post_data"
            Log "[_SW_Send] " "POST_RESPONSE: $http_response"
            Log "[_SW_Send] " "End of POST"
        fi

        if [ $http_retval -eq 0 ]; then
            http_sn=$(echo $http_response | $JQ_CMD -r '.[].sn')
            http_status=$(echo $http_response | $JQ_CMD -r '.[].status')
            http_array_sn=( $http_sn )
            http_array_status=( $http_status )

            status_color=""
            notpass=0
            for ((i=0;i<${#http_array_sn[@]};i++))
            do
                if [ "${http_array_status[$i]}" == "pass" ];then
                    status_color+="$_GREEN_${http_array_sn[$i]}->${http_array_status[$i]}$_REST_ "
                else
                    notpass=1
                    status_color+="$_RED_${http_array_sn[$i]}->${http_array_status[$i]}$_REST_ "
                fi
            done

            if [ $notpass -eq 1 ];then
                response_color="$_RED_$http_response$_REST_"
            else
                response_color="$_GREEN_$http_response$_REST_"
            fi
        else
            status="http-error"
            status_color="$_RED_$status$_REST_"
            response_color="$_RED_$http_response$_REST_"
        fi

        echo
        echo "[Send]"
        echo "To ID: $to_sn"
        echo -e "Status: $status_color"
        echo "Milliseconds: $elapsed"
        echo "Request: $raida_url"
        echo -e "Response: $response_color"
        echo

    fi

}

_SW_Receive(){
    local node_num id_coinfile bank_coinfile
    local s i
    node_num=$1
    id_coinfile="$2"
    bank_coinfile="$3"

    # Check the local testcoin file
    for f in $id_coinfile $bank_coinfile
    do
        Coin_validation $f
        is_testcoin=$?
        [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format
    done

    [ -w $bank_coinfile ] || {
        Error "Error: The testcoin file $bank_coinfile hasn't the permission of write!"
        return 1
    }

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/receive"
    nn=`$JQ_CMD '.cloudcoin[].nn' $id_coinfile | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $id_coinfile | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $id_coinfile`
    array_an=( $string_an )
    an="${array_an[$node_num]}"
    denom=$(Get_denom $sn)
    # for debug only
    #echo "nn-> $nn"
    #echo "sn-> $sn"
    #echo "an-> $an"
    #echo "denom-> $denom"

    bank_sn=`$JQ_CMD -r '.cloudcoin[].sn' $bank_coinfile`
    bank_sns=( $bank_sn )

    # Test the Echo
    test_echo=$(_echo $node_num)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"    # Echo Failed
        return 1
    else
        index=0
        post_sns=""
        for s in "${bank_sns[@]}"
        do
            if [ $index -eq 0 ];then
                post_sns="sns[]=$s"
            else
                post_sns="$post_sns&sns[]=$s"
            fi
            ((index++))
        done
        
        post_data="sn=$sn&an=$an&pan=$an&denomination=$denom&$post_sns"
        #echo $post_data

        start_s=$(Timer)
        http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
        http_retval=$?
        end_s=$(Timer)
        elapsed=$(( (end_s-start_s)/1000000 ))

        if [ $DEBUG -eq 1 ]; then
            Log "[_SW_Receive] " "POST_URL: $raida_url "
            Log "[_SW_Receive] " "POST_DATA: $post_data"
            Log "[_SW_Receive] " "POST_RESPONSE: $http_response"
            Log "[_SW_Receive] " "End of POST"
        fi

        if [ $http_retval -eq 0 ]; then
            http_sn=$(echo $http_response | $JQ_CMD -r '.[].sn')
            http_status=$(echo $http_response | $JQ_CMD -r '.[].status')
            http_msg=$(echo $http_response | $JQ_CMD -r '.[].message')

            http_array_sn=( $http_sn )
            http_array_status=( $http_status )
            http_array_msg=( $http_msg )
            ## for debugging only
            #echo "http_array_sn = ${http_array_sn[@]}"
            #echo "http_array_status = ${http_array_status[@]}"
            #echo "http_array_msg = ${http_array_msg[@]}"

            status_color=""
            notpass=0
            for ((i=0;i<${#http_array_sn[@]};i++))
            do
                if [ "${http_array_status[$i]}" == "pass" ];then
                    new_an=${http_array_msg[$i]}
                    $JQ_CMD ".cloudcoin[$i].an[$node_num] = \"$new_an\"" $bank_coinfile > $bank_coinfile.tmp && mv $bank_coinfile.tmp $bank_coinfile
                    status_color+="$_GREEN_${http_array_sn[$i]}->${http_array_status[$i]}$_REST_ "
                else
                    notpass=1
                    status_color+="$_RED_${http_array_sn[$i]}->${http_array_status[$i]}$_REST_ "
                fi
            done

            if [ $notpass -eq 1 ];then
                response_color="$_RED_$http_response$_REST_"
            else
                response_color="$_GREEN_$http_response$_REST_"
            fi

        else
            status="http-error"
            status_color="$_RED_$status$_REST_"
            response_color="$_RED_$http_response$_REST_"
        fi

        echo
        echo "[Receive]"
        echo "From ID: $sn"
        echo -e "Status: $status_color"
        echo "Milliseconds: $elapsed"
        echo "Request: $raida_url"
        echo -e "Response: $response_color"
        echo

    fi
}

_SW_GetTag(){
    local node_num coinfile tag
    node_num=$1
    coinfile="$2"

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/show"
    nn=`$JQ_CMD '.cloudcoin[].nn' $coinfile | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $coinfile | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $coinfile`
    array_an=( $string_an )
    an="${array_an[$node_num]}"
    denom=$(Get_denom $sn)

    raida_url="$raida_url?sn=$sn&an=$an&pan=$an&denomination=$denom"
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    http_retval=$?

    if [ $http_retval -eq 0 ]; then
        status=$(echo $http_response | $JQ_CMD -r '.status')
    else
        status="http-error"
    fi
    
    tag=""
    if [ "$status" == "pass" ];then
        tag="$(echo $http_response | $JQ_CMD -r '.message[0].tag')"
    fi

    if [ -z "$tag" -o "$tag" == "null" ];then
        echo "NoTagName"
    else
        echo "$tag"
    fi
}

urlencode() {
    local data
    if [[ $# != 1 ]]; then
        echo "Error: No string to urlencode"
        return 1
    fi
    data="$($CURL_CMD -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
    if [[ $? != 3 ]]; then
        echo "Unexpected error" 1>&2
    else
        echo "${data##/?}"
    fi
    return 0
}

_SW_RenameTag(){
    local node_num coinfile tag new_tag
    local input
    node_num=$1
    coinfile="$2"

    # Check the local testcoin file
    Coin_validation $coinfile
    is_testcoin=$?
    [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/rename_tag"
    nn=`$JQ_CMD '.cloudcoin[].nn' $coinfile | tr -d '"'`
    sn=`$JQ_CMD '.cloudcoin[].sn' $coinfile | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $coinfile`
    array_an=( $string_an )
    an="${array_an[$node_num]}"
    denom=$(Get_denom $sn)
    # for debug only
    #echo "nn-> $nn"
    #echo "sn-> $sn"
    #echo "an-> $an"
    #echo "denom-> $denom"

    # Test the Echo
    test_echo=$(_echo $node_num)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"    # Echo Failed
        return 1
    else
        tag=$(_SW_GetTag $node_num $coinfile)
        #echo $tag
        if [ "$tag" == "NoTagName" ];then
            echo
            echo "[Rename_Tag]"
            echo "SN ID: $sn"
            echo -e "Status:$_GREEN_ No coins in transfer pool!$_REST_"
            echo
        else 
            post_tag="$(urlencode "$tag")"
            echo -n "The TAG is currently \"$tag\", would you like to rename it to ? " && read input
            if [ -z "$input" ];then
                new_tag="Test00000"
            else
                new_tag="$(urlencode "$input")"
            fi
            #echo "Debug: new_tag-> $new_tag"
            raida_url="$raida_url?sn=$sn&an=$an&pan=$an&denomination=$denom&tag=$post_tag&new_tag=$new_tag"
            start_s=$(Timer)
            http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
            http_retval=$?
            end_s=$(Timer)
            elapsed=$(( (end_s-start_s)/1000000 ))

            if [ $http_retval -eq 0 ]; then
                status=$(echo $http_response | $JQ_CMD -r '.status')
            else
                status="http-error"
            fi

            if [ "$status" == "pass" ];then
                status_color="$_GREEN_$status$_REST_"
                response_color="$_GREEN_$http_response$_REST_"
            else
                status_color="$_RED_$status$_REST_"
                response_color="$_RED_$http_response$_REST_"
            fi

            echo
            echo "[Rename_Tag]"
            echo "SN ID: $sn"
            echo -e "Status: $_BOLD_$status_color"
            echo "Milliseconds: $elapsed"
            echo "Request: $raida_url"
            echo -e "Response: $response_color"
            echo
        fi

    fi
}

_SW_Transfer(){
    local node_num from_id_coinfile to_id_coinfile bank_coinfile
    local s i
    node_num=$1
    from_id_coinfile="$2"
    to_id_coinfile="$3"
    bank_coinfile="$4"

    # Check the local testcoin file
    for f in $from_id_coinfile $to_id_coinfile $bank_coinfile
    do
        Coin_validation $f
        is_testcoin=$?
        [ $is_testcoin -eq 1 ] && return 1  # testcoin file not found or with wrong format
    done

    raida="raida$node_num"
    raida_url="https://$raida.cloudcoin.global/service/transfer"
    sn=`$JQ_CMD '.cloudcoin[].sn' $from_id_coinfile | tr -d '"'`
    string_an=`$JQ_CMD -r '.cloudcoin[].an[]' $from_id_coinfile`
    array_an=( $string_an )
    an="${array_an[$node_num]}"
    denom=$(Get_denom $sn)
    # for debug only
    #echo "sn-> $sn"
    #echo "an-> $an"
    #echo "denom-> $denom"

    to_sn=`$JQ_CMD '.cloudcoin[].sn' $to_id_coinfile | tr -d '"'`
    bank_sn=`$JQ_CMD -r '.cloudcoin[].sn' $bank_coinfile`
    bank_sns=( $bank_sn )
    # for debug only
    #echo "to_sn-> $to_sn"
    #echo "bank_sns-> ${bank_sns[@]}"

    # Test the Echo
    test_echo=$(_echo $node_num)
    run_echo=$?
    if [ $run_echo -eq 1 ];then
        Error "$ERROR_05"    # Echo Failed
        return 1
    else
        index=0
        post_sns=""
        for s in "${bank_sns[@]}"
        do
            if [ $index -eq 0 ];then
                post_sns="sns[]=$s"
            else
                post_sns="$post_sns&sns[]=$s"
            fi
            ((index++))
        done
        
        post_tag="tag=TransferTo$to_sn"
        post_data="sn=$sn&an=$an&pan=$an&denomination=$denom&to_sn=$to_sn&tag=$post_tag&$post_sns"
        #echo $post_data

        start_s=$(Timer)
        http_response=$($CURL_CMD $CURL_OPT_multi -d "$post_data" $raida_url 2>&1)
        http_retval=$?
        end_s=$(Timer)
        elapsed=$(( (end_s-start_s)/1000000 ))

        if [ $DEBUG -eq 1 ]; then
            Log "[_SW_Transfer] " "POST_URL: $raida_url "
            Log "[_SW_Transfer] " "POST_DATA: $post_data"
            Log "[_SW_Transfer] " "POST_RESPONSE: $http_response"
            Log "[_SW_Transfer] " "End of POST"
        fi

        if [ $http_retval -eq 0 ]; then
            http_status=$(echo $http_response | $JQ_CMD -r '.[].status')
            http_array_status=( $http_status )
            ## for debugging only
            #echo "http_array_status = ${http_array_status[@]}"

            status_color=""
            notpass=0
            for ((i=0;i<${#http_array_status[@]};i++))
            do
                if [ "${http_array_status[$i]}" == "pass" ];then
                    status_color+="$_GREEN_${bank_sns[$i]}->${http_array_status[$i]}$_REST_ "
                else
                    notpass=1
                    status_color+="$_RED_${bank_sns[$i]}->${http_array_status[$i]}$_REST_ "
                fi
            done

            if [ $notpass -eq 1 ];then
                response_color="$_RED_$http_response$_REST_"
            else
                response_color="$_GREEN_$http_response$_REST_"
            fi

        else
            status="http-error"
            status_color="$_RED_$status$_REST_"
            response_color="$_RED_$http_response$_REST_"
        fi

        echo
        echo "[Transfer]"
        echo "From ID: $sn"
        echo "To ID: $to_sn"
        echo -e "Status: $status_color"
        echo "Milliseconds: $elapsed"
        echo "Request: $raida_url"
        echo -e "Response: $response_color"
        echo

    fi

}

Coin_validation(){
    local file
    file="$1"

    if [ -f $file ];then
        $JQ_CMD '.cloudcoin' $file >/dev/null 2>&1
        is_json=$? 
        if [ $is_json -eq 0 ];then # Is JSON
            echo -e "Loading test coins: $WORKDIR/$file"
            return 0
        else # Not JSON
            Error "Error: Test Coin File seems to be Wrong Format ($WORKDIR/$file)"
            return 1
        fi
    else
        Error "Error: Testcoin File Not Found ($WORKDIR/$file)"
        return 1
    fi
}


Check_html_template(){
    local html_template
    local html_report

    now=$(date +"%F %T")
    html_template="$1"
    if [ ! -r $html_template ];then
        return 1
    fi 
    html_report="$( echo $html_template | sed 's/template/test/g' )"
    [ -d $HTML_DIR ] || mkdir $HTML_DIR
    cp -f $html_template $HTML_DIR/$html_report
    sed -i "s/\[TIME\]/$now/g" $HTML_DIR/$html_report 
    return 0
}

ask_html(){
    local input
    local opt
    local retval
    
    opt="$1"
    save_to_html="NO"
    echo -n "$STRING_06 " && read input
    echo
    [ -z $input ] && input="N"
    if [ "$input" == "y" -o "$input" == "Y" ];then
        save_to_html="YES"

        case "$opt" in 
            FIX)
                for ((i=1;i<=4;i++))
                do
                    html_template="fix${i}template.html"
                    Check_html_template "$html_template"
                    retval=$?
                    if [ $retval -eq 1 ];then
                        Error "Error: The file $WORKDIR/$html_template Not Found."
                        return 1
                    fi
                done
                ;;
            
            HINTS)
                html_template="hintstemplate.html"
                ;;

            TICKET)
                html_template="tickettemplate.html"
                ;;

            DETECT)
                html_template="detecttemplate.html"
                ;;

            ECHO)
                html_template="echotemplate.html"
                ;; 

        esac

        if [ "$opt" != "FIX" ]; then
            Check_html_template "$html_template"
            retval=$?
            if [ $retval -eq 1 ];then
                Error "Error: The file $WORKDIR/$html_template Not Found."
                return 1
            fi
        fi

    fi
    return 0
}

Basic_htmlreport(){
    local html_report
    local raida_node
    local get_status
    local get_request
    local get_response
    local get_ms
    local html_ms
    local html_request
    local html_response
    local html_status

    html="$1"
    raida_node="$2"
    get_status="$3"
    get_request="$4"
    get_response="$5"
    get_ms="$6"
    get_ver="$7"

    html_report="$HTML_DIR/$html"
    key_status="\[${raida_node}RAIDASTATUS\]"
    key_ms="\[${raida_node}RAIDAMS\]"
    key_ver="\[${raida_node}RAIDAVER\]"
    key_request="\[${raida_node}RAIDAREQUEST\]"
    key_response="\[${raida_node}RAIDARESPONSE\]"
    html_ms="Milliseconds: $get_ms"
    html_ver="Version: $get_ver"

    html_request="$(echo $get_request | sed -e 's/\&/\\&/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\;/\\;/g')"
    html_response="$(echo $get_response | sed -e 's/\&/\\&/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\;/\\;/g')"

    case "$html" in
        hintstest.html)
            is_success=$(echo "$get_status" | grep -i success | wc -l)
            if [ "$is_success" == "1" ];then
                html_status="<span style='color:green;'>${get_status}</span>"
            else
                html_status="<span style='color:red;'>${get_status}</span>"
            fi
            ;;

        tickettest.html)
            is_success=$(echo "$get_status" | grep -w ticket | wc -l)
            if [ "$is_success" == "1" ];then
                html_status="<span style='color:green;'>${get_status}</span>"
            else
                html_status="<span style='color:red;'>${get_status}</span>"
            fi
            ;;

        detecttest.html)
            is_success=$(echo "$get_status" | grep -w pass | wc -l)
            if [ "$is_success" == "1" ];then
                html_status="<span style='color:green;'>${get_status}</span>"
            else
                html_status="<span style='color:red;'>${get_status}</span>"
            fi
            ;;

        echotest.html)
            is_success=$(echo "$get_status" | grep -w ready | wc -l)
            if [ "$is_success" == "1" ];then
                html_status="<span style='color:green;'>${get_status}</span>"
            else
                html_status="<span style='color:red;'>${get_status}</span>"
            fi
            ;;

    esac

    sed -i "s|$key_status|$html_status|g" $html_report
    sed -i "s|$key_ms|$html_ms|g" $html_report
    sed -i "s|${key_request}|${html_request}|g" $html_report
    sed -i "s|$key_response|$html_response|g" $html_report
    sed -i "s|$key_ver|$html_ver|g" $html_report
}

Fix_htmlreport(){
    local html_report
    local raida_node
    local fix_corner
    local get_status
    local get_request
    local get_response
    local get_ms
    local html_ms
    local html_request
    local html_response
    local html_status

    html_report="$1"
    raida_node="$2"
    fix_corner="$3"
    get_status="$4"
    get_request="$5"
    get_response="$6"
    get_ms="$7"

    html_report="$HTML_DIR/$html_report"
    key_status="\[${raida_node}RAIDASTATUS\]"
    key_ms="\[${raida_node}RAIDAMS\]"
    key_request="\[${raida_node}RAIDAREQUEST\]"
    key_response="\[${raida_node}RAIDARESPONSE\]"
    html_ms="Milliseconds: $get_ms"
    
    html_request="$(echo $get_request | sed -e 's/\&/\\&/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\;/\\;/g')"
    html_response="$(echo $get_response | sed -e 's/\&/\\&/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\;/\\;/g')"

    if [ "$get_status" != "success" ];then
        html_status="<span style='color:red;'>${get_status}</span>"
    else
        html_status="<span style='color:green;'>${get_status}</span>"
    fi
    
    sed -i "s|$key_status|$html_status|g" $html_report
    sed -i "s|$key_ms|$html_ms|g" $html_report
    sed -i "s|${key_request}|${html_request}|g" $html_report
    sed -i "s|$key_response|$html_response|g" $html_report

}

Output(){
    local node status ms
    node=$1
    status="$2"
    ms=$3
    printf " %.18s [%4b] \n" "RAIDA($node).............." "$status"
}

Output2(){
    local msg
    msg=$1
    printf "   %-20b \n" "[!]:${_RED_}$msg${_REST_}"
}

Get_version(){
    local node
    local version
    node=$1
    raida="raida$node"
    raida_url="https://$raida.cloudcoin.global/service/version"
    http_response=$($CURL_CMD $CURL_OPT $raida_url 2>&1)
    http_retval=$?

    if [ $http_retval -eq 0 ]; then
        version=$(echo $http_response | $JQ_CMD -r '.version')
    else
        version="---"
    fi

    echo "$version"
}

Get_coin_files(){
    local files coinfile coins_list
    coinfile=""
    coins_list=""
    files="$(ls *.stack 2>/dev/null)"
    for coinfile in $files
    do
        Coin_validation $coinfile >/dev/null
        [ $? -eq 0 ] && coins_list+=("$coinfile")
    done
    echo "${coins_list[@]}"
    return
}

Log() {  # classic logger
    local prefix="[$(date +%Y/%m/%d\ %H:%M:%S)]: "
    echo "${prefix} $@" >> $LOG_FILE 2>&1
}




cd $WORKDIR
[ -f $LOG_FILE ] && cat /dev/null > $LOG_FILE
Check_requirement
Show_head
Main

exit
