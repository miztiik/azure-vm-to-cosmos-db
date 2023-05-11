
param vmName string
param deploymentParams object
@secure()
param appConfigName string
param repoName string
param tags object


resource r_vm_1 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: vmName
}

var command_to_clone_repo = '''
REPO_NAME="REPO_VAR_NAME" && \\
GIT_REPO_URL="https://github.com/miztiik/$REPO_NAME.git" && \\
cd /var && \\
rm -rf /var/$REPO_NAME && \\
git clone $GIT_REPO_URL && \\
cd /var/$REPO_NAME && \\
chmod +x /var/$REPO_NAME/modules/vm/bootstrap_scripts/deploy_app.sh
./var/$REPO_NAME/modules/vm/bootstrap_scripts/deploy_app.sh
'''





resource r_deploy_script_on_vm_1 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  parent: r_vm_1
  name:   '${vmName}_${deploymentParams.global_uniqueness}_script_deployment_1'
  location: deploymentParams.location
  tags: tags
  properties: {
    asyncExecution: true
    source: {
        script: command_to_clone_repo
      }

  }
}


/*
var script_to_execute_with_vars = '''
export APP_CONFIG_NAME="APP_CONFIG_VAR_NAME" && \\
python3 /var/$REPO_NAME/app/az_producer_for_cosmos_db.py &
'''

var script_to_execute = replace(script_to_execute_with_vars, 'APP_CONFIG_VAR_NAME', appConfigName)

resource r_deploy_script_on_vm_2 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  parent: r_vm_1
  name:   '${vmName}_${deploymentParams.global_uniqueness}_script_deployment_2'
  location: deploymentParams.location
  tags: tags
  properties: {
    asyncExecution: true
    source: {
        script: script_to_execute
      }
  }
  dependsOn: [
    r_deploy_script_on_vm_1
  ]
}
*/

// Troublshooting
/*
script_location = '/var/lib/waagent/run-command-handler/download/VM_NAME_script_deployment/0/script.sh'
output_location = '/var/lib/waagent/run-command-handler/download/m-web-srv-004_004_script_deployment/0'
*/



