*** Settings ***
Resource     TAF/testCaseModules/keywords/common/commonKeywords.robot
Resource     TAF/testCaseModules/keywords/core-metadata/coreMetadataAPI.robot
Suite Setup  Run Keywords  Setup Suite
...                        AND  Run Keyword if  $SECURITY_SERVICE_NEEDED == 'true'  Get Token
Suite Teardown  Run Keyword if  $SECURITY_SERVICE_NEEDED == 'true'  Remove Token
Force Tags      taf

*** Variables ***
${SUITE}          Core Metadata Ping GET Test Cases
${LOG_FILE_PATH}  ${WORK_DIR}/TAF/testArtifacts/logs/core-metadata-ping.log
${url}            ${coreMetadataUrl}
${api_version}    v2

*** Test Cases ***
InfoGET001 - Query ping
    FOR  ${INDEX}  IN RANGE  0  200
        log to console  Ping time: ${INDEX}
        sleep  500ms
        Query Ping
    END
