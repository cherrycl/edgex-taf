*** Settings ***
Resource         TAF/testCaseModules/keywords/common/commonKeywords.robot
Resource         TAF/testCaseModules/keywords/core-metadata/coreMetadataAPI.robot
Suite Setup      Run keywords  Skip if  $SECURITY_SERVICE_NEEDED == 'false'
                 ...      AND  Setup Suite
                 ...      AND  Get Token
Suite Teardown   Run Teardown Keywords
Force Tags       skipped

*** Variables ***
${SUITE}         URI for files with secure credentials

*** Test Cases ***
URI004-Test UoM URI with secret credentials
    Given Update core-metadata Configuration On Consul
    And Update Service Configuration On Consul  ${path}  ${value}
    And Restart Services  core-metadata
    When Query UoM
    Then Should Contain  ${content}[uom][units][weights][values]  uritest

*** Keywords ***
Store Secret With HTTP Server To ${service_url}
    ${auth_value}  Evaluate  base64.b64encode(bytes('${HTTP_USER}:${HTTP_PASSWD}', 'UTF-8'))  modules=base64
    ${secrets_data}=  Load data file "all-services/secrets_data.json" and get variable "HTTP Server Auth"
    Set To Dictionary  ${secrets_data}  apiVersion=${API_VERSION}
    Set To Dictionary  ${secrets_data}[secretData][2]  value=Basic ${auth_value}
    Create Session  Secrets  url=${service_url}  disable_warnings=true
    ${headers}=  Create Dictionary  Authorization=Bearer ${jwt_token}
    ${resp}=  POST On Session  Secrets  api/${API_VERSION}/secret  json=${secrets_data}  headers=${headers}
    ...       expected_status=201

Update ${service} Configuration On Consul
    ${path}  Set Variable  ${CONSUL_CONFIG_BASE_ENDPOINT}/${service}/UoM/UoMFile
    ${value}  Set Variable  http://httpd-auth:80/files/uom.yaml?edgexSecretName=httpserver
    ${stored_url}  Run Keyword If  "${service}" == "core-metadata"  Set Variable  ${coreMetadataUrl}
                   ...     ELSE IF  "${service}" == "device-onvif-camera"  Set Variable  ${URI_SCHEME}://${BASE_URL}:${ONVIF_CAMERA_PORT}
    Store Secret With HTTP Server To ${stored_url}
    Update Service Configuration On Consul  ${path}  ${value}
    Restart Services  core-metadata
