*** Settings ***
Documentation    URIs were set on compose file
Resource         TAF/testCaseModules/keywords/common/commonKeywords.robot
Resource         TAF/testCaseModules/keywords/core-metadata/coreMetadataAPI.robot
Suite Setup      Run keywords   Setup Suite
...                             AND  Skip if  $SECURITY_SERVICE_NEEDED == 'true'
Suite Teardown   Run Teardown Keywords
Force Tags       MessageBus=redis

*** Variables ***
${SUITE}         URI for files with username-passward in URI

*** Test Cases ***
URI001-Test UoM URI with username-passward in URI
    When Query UoM
    Then Should Contain  ${content}[uom][units][weights][values]  uritest

URI002-Test configuration file, device profiles, devices and provision watchers with username-password in URI
    ${metadata_list}  Create List  profile  device  proWatchers
    ${name_list}  Create List  onvif-camera  Camera001  Generic-Onvif-Provision-Watcher
    FOR  ${metadata}  ${name}  IN ZIP  ${metadata_list}  ${name_list}
        When Run Keyword If  '${metadata}' == 'profile'  Query Device Profile By Name  ${name}
             ...    ELSE IF  '${metadata}' == 'device'  Query Device By Name  ${name}
             ...    ELSE IF  '${metadata}' == 'proWatchers'  Query Provision Watchers By Name  ${name}
        Then Should Contain  ${content}  uritest
    END

#URI003-Test Common configuration file with username-password in URI


