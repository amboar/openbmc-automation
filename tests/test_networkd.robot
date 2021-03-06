*** Settings ***
Documentation		This suite will verifiy the Network Configuration Rest Interfaces
...					Details of valid interfaces can be found here...
...					https://github.com/openbmc/docs/blob/master/rest-api.md

Resource		../lib/rest_client.robot



*** Test Cases ***                                

Get the Mac address

    [Documentation]   This test case is to get the mac address
    [Tags]   GOOD-PATH
    @{arglist}=   Create List   eth0
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=   Call Method    /org/openbmc/NetworkManager/Interface/    GetHwAddress    data=${args}
    should not be empty    ${resp.content}


Get IP Address with invalid interface

    [Documentation]   This test case tries to get the ip addrees with the invalid
    ...               interface,Expectation is it should get error.
    [Tags]   GOOD-PATH

    @{arglist}=   Create List   lo01
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=    Call Method    /org/openbmc/NetworkManager/Interface/   GetAddress4    data=${args}
    should not be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error


Get IP Address with valid interface

    [Documentation]   This test case tries to get the ip addrees with the invalid
    ...               interface,Expectation is it should get error.
    [Tags]   GOOD-PATH

    @{arglist}=   Create List   eth0
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=    Call Method    /org/openbmc/NetworkManager/Interface/   GetAddress4    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok

Set the IP address on invalid Interface            lo01     1.1.1.1        255.255.255.0     1.1.1.1     error

   [Tags]   BAD-PATH
   [Template]    AddNetworkInfo
   [Documentation]    This test case tries to set the ip addrees with the invalid
    ...               interface,Expectation is it should get error

Set invalid IP address on the valid interface      eth0     ab.cd.ef.gh    255.255.255.0     1.1.1.1     error

   [Tags]   BAD-PATH
   [Template]    AddNetworkInfo
   [Documentation]    This test case tries to set the invalid ip addrees on  the interface
    ...               Expectation is it should get error.


Set IP address with invalid subnet mask            eth0       2.2.2.2        av.ih.jk.lm       1.1.1.1     error

   [Tags]   BAD-PATH
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the ip addrees on  the interface
   ...               with invalid subnet mask,Expectation is it should get error.

Set empty IP address                              eth0     ${EMPTY}       255.255.255.0     1.1.1.1     error

   [Tags]   BAD-PATH
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the NULL ip addrees on  the interface
   ...               Expectation is it should get error.

Set empty subnet mask                             eth0       2.2.2.2        ${EMPTY}          1.1.1.1     error

   [Tags]   BAD-PATH
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the ip addrees on  the interface
   ...               with empty subnet mask,Expectation is it should get error.

Set empty gateway                                 eth0       2.2.2.2        255.255.255.0     ${EMPTY}    error

   [Tags]   BAD-PATH
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the ip addrees on  the interface
   ...               with empty gateway,Expectation is it should get error.


Set IP address on valid Interface
    [Tags]   GOOD-PATH

    [Documentation]   This test case sets the ip  on the interface and validates
    ...               that ip address has been set or not.
    ...               Expectation is the ip address should get added.

    ${NEW_BMC_IP}=        Get Environment Variable    NEW_BMC_IP
    ${NEW_SUBNET_MASK}=   Get Environment Variable    NEW_SUBNET_MASK
    ${NEW_GATEWAY}=       Get Environment Variable      NEW_GATEWAY
    ${arglist}=    Create List    eth0    ${NEW_BMC_IP}   ${NEW_SUBNET_MASK}   ${NEW_GATEWAY}
    ${args}=     Create Dictionary   data=@{arglist}
    run keyword and ignore error    Call Method    /org/openbmc/NetworkManager/Interface/   SetAddress4    data=${args}
    Sleep   10sec
    Set Suite Variable       ${AUTH_URI}       https://${NEW_BMC_IP}
    log     ${AUTH_URI}
    Is ip/gateway on the interface    eth0    ${NEW_BMC_IP}    ${NEW_GATEWAY}


Set invalid Mac address     eth0     gg:hh:jj:kk:ll:mm    error
    [Tags]   BAD-PATH
    [Template]  SetMacAddress_bad
    [Documentation]   This test case tries to set the invalid mac address 
    ...               on the eth0 interface.
    ...               Expectation is that it should throw error.


Set valid Mac address     eth0     00:21:cc:73:91:dd   ok
    [Tags]   GOOD-PATH
    [Template]  SetMacAddress_good
    [Documentation]   ***GOOD PATH***
    ...               This test case add the ip addresson the  interface and validates
    ...               that ip address has been added or not.
    ...               Expectation is the ip address should get added.
     


***keywords***

Is ip/gateway on the interface

    [Documentation]   This keyword is used to match the given ip with the configured one.  
    ...               returns true if match successfull else false
    ...               eg:- Outout of getAddress4
    ...               NewFormat:-{"data": [ 2,25,"9.3.164.147","9.3.164.129"],"message": "200 OK","status": "ok"}
    ...               OldFormat:-
    ...               {"data": [[[2,25,0,128,"9.3.164.177"],[2,8,254,128,"127.0.0.1"]],"9.3.164.129"],
    ...                "message": "200 OK", "status": "ok"}

    [arguments]    ${intf}    ${i_ipaddress}   ${i_gateway}
    @{arglist}=    Create List   ${intf}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method    /org/openbmc/NetworkManager/Interface/   GetAddress4    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    log to console   ${json['data'][2]}
    log to console   ${json['data'][3]}
    ${ipaddress}=      set variable    ${json['data'][2]}
    ${gateway}=        set variable    ${json['data'][3]}
    log to console   ${i_ipaddress}   ${i_gateway}
    ${isgatewayfound} =    Set Variable If   '${gateway}'=='${i_gateway}'  true    false
    log to console   ${isgatewayfound}
    ${isIPfound}=    Set Variable if    '${ipaddress}' == '${i_ipaddress}'    true   false
    should be true   '${isIPfound}' == 'true' and '${isgatewayfound}' == 'true' 

AddNetworkInfo
    [Arguments]    ${intf}      ${address}    ${mask}   ${gateway}  ${result}

    ${arglist}=    Create List    ${intf}    ${address}  ${mask}   ${gateway}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method    /org/openbmc/NetworkManager/Interface/   SetAddress4    data=${args}
    should not be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ${result}


SetMacAddress_bad
    [Arguments]    ${intf}      ${address}    ${result}
    ${arglist}=    Create List    ${intf}    ${address}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method    /org/openbmc/NetworkManager/Interface/   SetHwAddress    data=${args}
    should not be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ${result}


SetMacAddress_good
    [Arguments]    ${intf}      ${address}   ${result}
    ${arglist}=    Create List    ${intf}    ${address}  
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method    /org/openbmc/NetworkManager/Interface/   SetHwAddress    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ${result}
    @{arglist}=   Create List   ${intf}
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=   Call Method    /org/openbmc/NetworkManager/Interface/    GetHwAddress    data=${args}
    ${json} =   to json         ${resp.content}
    should be equal as strings   ${json['data']}    ${address}
 

