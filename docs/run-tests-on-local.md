# How To Run Functional Test And Integration Test On Local
Run tests using python command or edgex-taf-common image depend on install the required libraries for robotframework on testing machine or not. If user don't like to install libraries for testing, the edgex-taf-common image is useful.
### Prerequisites
Clone the edgex-taf project from EdgeX Foundry as a template:
``` bash
cd ${HOME}
git clone https://github.com/edgexfoundry/edgex-taf.git
```

`Run tests either edgeX-taf-common Container or python comman`

### Using The edgeX-taf-common Container To Run Testing
---
####  Variables configuration
Export the following variables that depend on running environment
``` 
# Required variables
export WORK_DIR=${HOME}/edgex-taf
```

#### Run test by shell script with arguments
```
cd ${WORK_DIR}/TAF/utils/scripts/docker
sh run-tests.sh ${ARCH} ${SECURITY_SERVICE_NEEDED} ${TEST_STRATEGY}
# ex. sh run-tests.sh x86_64 false 1

# Variable values
${ARCH}: x86_64 | arm64
${SECURITY_SERVICE_NEEDED}: false | true
${TEST_STRATEGY}: 1 (functional) | 2 (integration)
```

#### Test report
Open the report file by browser: ${WORK_DIR}/TAF/testArtifacts/reports/cp-edgex/v2-api-test.html



### Using Python Command To Run Testing
---
#### Setup required library
1. Install pre-request packages:
    Download pip3 and run this command:
    ``` bash
    sudo apt-get install python3-pip
    ```
2. Install TAF common:
    ``` bash
    cd ${HOME}/edgex-taf
    git clone https://github.com/edgexfoundry/edgex-taf-common.git
    
    # Install dependency lib
    pip3 install -r ./edgex-taf-common/requirements.txt

    # Install edgex-taf-common as lib
    pip3 install ./edgex-taf-common
    ```
3. Prepare test environment:
    ``` bash
    # Fetch the latest docker-compose file
    cd ${HOME}/edgex-taf/TAF/utils/scripts/docker
    sh get-compose-file.sh ${USE_DB} ${ARCH} ${USE_SECURITY}
    # ex. sh get-compose-file.sh -redis x86_64 -
    
    # Variables for get-compose-file.sh
    ${USE_DB}: -redis | -mongo (mongo is not supported from hanoi release)
    ${ARCH}: x86_64 | arm64
    ${USE_SECURITY}: - (false) | -security- (true)

    # export the environment variables that depend on your environment.
    export ARCH=x86_64
    export SECURITY_SERVICE_NEEDED=false
    export COMPOSE_IMAGE=nexus3.edgexfoundry.org:10003/edgex-devops/edgex-compose:latest
    ```
#### Run Tests
Run tests under ${HOME}/edgex-taf
1. Deploy edgex:
    ``` bash
    # This step may take for a while if the edgex images don't exist on the machine
    python3 -m TUC --exclude Skipped --include deploy-base-service -u deploy.robot -p default
    ```
2. Run Test
    ###### Deploy and run device service tests using v1 API:
    ``` bash
    python3 -m TUC --exclude Skipped --include deploy-device-service -u deploy.robot -p device-virtual
    python3 -m TUC --exclude Skipped -u functionalTest/device-service/common -p device-virtual
    python3 -m TUC --exclude Skipped --include shutdown-device-service -u shutdown.robot -p device-virtual
    ```
    ###### Run V2 API Functional testing:
    ``` bash
    python3 -m TUC --exclude Skipped --include v2-api -u functionalTest/V2-API -p device-virtual
    ```
    ###### Run Integration testing:
    ``` bash
    python3 -m TUC --exclude Skipped -u integrationTest -p device-virtual
    ```
   
3. Open the Test Reports
   ###### Open the test reports in the browser. For example, to open the testing report, enter the following URL in the browser:
    ``` bash
    ${HOME}/edgex-taf/TAF/testArtifacts/reports/edgex/log.html
    ```
4. Shutdown edgex:
    ``` bash
    python3 -m TUC --exclude Skipped --include shutdown-edgex -u shutdown.robot -p default
    ```

## Test Report Example

**Suite level example**

![image](./images/test_report_suite.png)

**Test case level example**

![image](./images/test_report_testcase.png)

**Keyword level example**

![image](./images/test_report_keyword.png)
