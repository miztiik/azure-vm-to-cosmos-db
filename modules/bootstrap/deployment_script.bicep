param deploymentParams object
param tags object

resource deploymentUser 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'getDeploymentUser'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentityName)}': {}
    }
  }
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.2.1'
    arguments: ' -ResourceGroupID ${resourceGroupID} -DeploymentName ${deployment} -StartTime ${logStartMinsAgo}'
    scriptContent: loadTextContent('../bicep/loadTextContext/setCDNServicesCertificates.ps1')
    forceUpdateTag: now
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    timeout: 'PT${logStartMinsAgo}M'
  }
}




resource r_deploy_scripts_1 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'vm-bootstrapper-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.37.0'
    timeout: 'PT2H'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    scriptContent: loadTextContent('../bicep/loadTextContext/setCDNServicesCertificates.ps1')
  }
}
