
param vmName string
param deploymentParams object
param tags object


resource r_vm_1 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: vmName
}

resource r_deploy_script_on_vm 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  parent: r_vm_1
  name:   '${vmName}_${deploymentParams.global_uniqueness}_script_deployment'
  location: deploymentParams.location
  tags: tags
  properties: {
    asyncExecution: true
    source: {
        script: '''
python3 /var/azure-vm-to-cosmos-db/app/azure_vm_to_cosmos_db.py &
'''
      }
  }
}
