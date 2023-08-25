*** Settings ***
Resource         TAF/testCaseModules/keywords/common/commonKeywords.robot
Resource         TAF/testCaseModules/keywords/core-metadata/coreMetadataAPI.robot
Suite Setup      Run keywords  Skip if  $SECURITY_SERVICE_NEEDED == 'false'
                 ...      AND  Setup Suite
                 ...      AND  Get Token
Suite Teardown   Run Teardown Keywords
Force Tags       MessageBus=redis

*** Variables ***
${SUITE}         URI for files with secure credentials

*** Test Cases ***
URI004-Test UoM URI with secret credentials
    ${path}  Set Variable  ${CONSUL_CONFIG_BASE_ENDPOINT}/core-metadata/UoM/UoMFile
    ${value}  Set Variable  http://httpd-auth:80/files/uom.yaml?edgexSecretName=httpserver
    Given Store Secret With HTTP Server
    And Update Service Configuration On Consul  ${path}  ${value}
    And Restart Services  core-metadata
    When Query UoM
    Then Should Contain  ${content}[uom][units][weights][values]  uritest

*** Keywords ***
Store Secret With HTTP Server
    ${auth_value}  Evaluate  base64.b64encode(bytes('${HTTP_USER}:${HTTP_PASSWD}', 'UTF-8'))  modules=base64
    ${secrets_data}=  Load data file "all-services/secrets_data.json" and get variable "HTTP Server Auth"
    Set To Dictionary  ${secrets_data}  apiVersion=${API_VERSION}
    Set To Dictionary  ${secrets_data}[secretData][2]  value=Basic ${auth_value}
    Create Session  Secrets  url=${coreMetadataUrl}  disable_warnings=true
    ${headers}=  Create Dictionary  Authorization=Bearer ${jwt_token}
    ${resp}=  POST On Session  Secrets  api/${API_VERSION}/secret  json=${secrets_data}  headers=${headers}
    ...       expected_status=201