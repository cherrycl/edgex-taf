*** Settings ***
Resource  TAF/testCaseModules/keywords/coreMetadataAPI.robot

*** Variables ***
${SUITE}         Multiple Device Service


*** Keywords ***


*** Test Cases ***
MultipleDS001 - Device profiles have created from several device-services
    Given New YAML files for testing device-services  device-virtual  device-modbus
    When Deploy services  device-virtual  device-modbus
    Then Device profiles have been created for device services   device-virtual  device-modbus
    And Value descriptors have been created for device services   device-virtual  device-modbus
    [Teardown]  Remove Services  device-virtual  device-modbus
    ...         And  Delete device profile by name device-virtual_profile
    ...         And  Delete device profile by name device-modbus_profile

MultipleDS002-Send get command to the one of device when multiple device-service alive at the same time
    Given Start several device services at the same time
    And Create devices for each device service
    When Send get command to devices with different device service
    Then Device reading has been created for each device service

MultipleDS003-Set Locked to the one of device when multiple device-service alive at the same time
    Given Start several device services at the same time
    And Create devices for each device service
    When Send put command to locked devices with different device service
    Then Notification for updating the device has been created.

MultipleDS004-Device events/readings have been received when multiple device-service alive at the same time
    Given Start several device services at the same time
    When Create devices with autoevent for each device service
    sleep  60
    Then Device events/readings have been created for each device service

MultipleDS005-Multiple device profiles has been created for same device service
    Given Start device service
    And Create 3 device profiles for the device service
    when Create devices with autoevent and different device profiles
    sleep  60
    Then Device events/readings have been created


*** Keywords ***
Create YAML file of device profile for "${device_service}"
    ${profile_template}=  Get File  ${WORK_DIR}/TAF/config/${device_service}/sample_profile.template  encoding=UTF-8
    ${profile_content}=  replace string  ${profile_template}   Sample_Profile    ${device_service}_profile
    create file  ${WORK_DIR}/TAF/config/${device_service}/new_sample_profile.yaml  ${profile_content}  encoding=UTF-8

New YAML files for testing device-services
    [Arguments]  ${device_service1}  ${device_service2}
    Create YAML file of device profile for "${device_service1}"
    Create YAML file of device profile for "${device_service2}"

Device profiles have been created for device services
    [Arguments]  ${device_service1}  ${device_service2}
    @{device_services}=  create list   ${device_service1}  ${device_service2}
    :FOR    ${item}    IN    @{device_services}
    \     ${device_profile_content}=  Query device profile by name    ${item}_profile
    \     should contain  ${device_profile_content}  ${item}_profile

Value descriptors have been created for device services
    [Arguments]  ${device_service1}  ${device_service2}
    @{device_services}=  create list   ${device_service1}  ${device_service2}
    :FOR    ${item}    IN    @{device_services}
    \    ValueDescriptors created in Core Data is based on DeviceProfile "${item}_profile"

Retrieve all resource names for the device profile "${device_profile_name}"
    ${device_profile_content}=  Query device profile by name    ${device_profile_name}
    ${device_profile_json}=  evaluate  json.loads('''${device_profile_content}''')  json
    ${resource_length}=  get length  ${device_profile_json}[deviceResources]
    @{resource_names}=   create list
    :For    ${INDEX}  IN RANGE  ${resource_length}
    \   Append To List    ${resource_names}    ${device_profile_json}[deviceResources][${INDEX}][name]
    [Return]   ${resource_names}
