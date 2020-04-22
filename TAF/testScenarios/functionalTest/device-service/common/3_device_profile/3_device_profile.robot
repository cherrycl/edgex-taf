*** Settings ***
Resource  TAF/testCaseModules/keywords/coreMetadataAPI.robot
Resource  TAF/testCaseModules/keywords/coreDataAPI.robot
Resource  TAF/testCaseModules/keywords/commonKeywords.robot
Suite Setup     Setup Suite

*** Variables ***
${SUITE}              Device

*** Test Cases ***
DeviceProfile_TC0001 - ValueDescriptor is created after initializing device service
    [Tags]  Backward
    ${device_profile_name}=  set variable  Sample-Profile
    Then DeviceProfile "${device_profile_name}" should be created in Core Metadata
    And DS should create ValueDescriptors in Core Data according to DeviceProfile "${device_profile_name}"

*** Keywords ***
DeviceProfile "${device_profile_name}" should be created in Core Metadata
    Query device profile by name    ${device_profile_name}
    Should return status code "200"

DS should create ValueDescriptors in Core Data according to DeviceProfile "${device_profile_name}"
    ValueDescriptors created in Core Data is based on DeviceProfile "${device_profile_name}"
