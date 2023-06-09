// targetScope = 'subscription'
targetScope = 'resourceGroup'

// Parameters
param deploymentParams object
param identityParams object
param appConfigParams object
param storageAccountParams object
param storageQueueParams object
param logAnalyticsWorkspaceParams object
param dceParams object
param vnetParams object
param vmParams object
param cosmosDbParams object

param brandTags object


param dateNow string = utcNow('yyyy-MM-dd-hh-mm')

param tags object = union(brandTags, {last_deployed:dateNow})

// Create Resource Group
// module r_rg 'modules/resource_group/create_rg.bicep' = {
//   name: rgName
//   params: {
//     rgName: rgName
//     location: location
//     tags:tags
//   }
// }

// Create Identity
module r_usr_mgd_identity 'modules/identity/create_usr_mgd_identity.bicep' = {
  name: '${deploymentParams.enterprise_name_suffix}_${deploymentParams.global_uniqueness}_usr_mgd_identity'
  params: {
    deploymentParams:deploymentParams
    identityParams:identityParams
    tags: tags
  }
}

// // Create Key Vault
// module r_kv 'modules/keyvault/create_kv.bicep' = {
// //   name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Kv'
//   params: {
//     deploymentParams:deploymentParams
//     kvNamePrefix:'storeEventsKv'
//     tags: tags
//   }
// }


//Create App Config
module r_appConfig 'modules/app_config/create_app_config.bicep' = {

  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Config'
  params: {
    deploymentParams:deploymentParams
    appConfigParams: appConfigParams
    tags: tags
  }
}

// Create Storage Account
module r_sa 'modules/storage/create_storage_account.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Sa'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    appConfigName: r_appConfig.outputs.appConfigName
    tags: tags
  }
}


// Create Storage Account - Blob container
module r_blob 'modules/storage/create_blob.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Blob'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    storageAccountName: r_sa.outputs.saName
    appConfigName: r_appConfig.outputs.appConfigName
    tags: tags
  }
  dependsOn: [
    r_sa
  ]
}

// Create Storage Queue
module r_storageQueue 'modules/storage/create_storage_queue.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Sq'
  params: {
    deploymentParams:deploymentParams
    storageQueueParams:storageQueueParams
    storageAccountName: r_sa.outputs.saName
    appConfigName: r_appConfig.outputs.appConfigName
    tags: tags
  }
  dependsOn: [
    r_sa
  ]
}

// Crate VNets
module r_vnet 'modules/vnet/create_vnet.bicep' = {
  name: '${vnetParams.vnetNamePrefix}_${deploymentParams.global_uniqueness}_Vnet'
  params: {
    deploymentParams:deploymentParams
    vnetParams:vnetParams
    tags: tags
  }
}


// Create the Log Analytics Workspace
module r_logAnalyticsWorkspace 'modules/monitor/log_analytics_workspace.bicep' = {
  name: '${logAnalyticsWorkspaceParams.workspaceName}_${deploymentParams.global_uniqueness}_La'
  params: {
    deploymentParams:deploymentParams
    logAnalyticsWorkspaceParams: logAnalyticsWorkspaceParams
    tags: tags
  }
}

// Create Data Collection Endpoint
module r_dataCollectionEndpoint 'modules/monitor/data_collection_endpoint.bicep' = {
  name: '${dceParams.endpointNamePrefix}_${deploymentParams.global_uniqueness}_Dce'
  params: {
    deploymentParams:deploymentParams
    dceParams: dceParams
    osKind: 'linux'
    tags: tags
  }
}


// Create the Data Collection Rule
module r_dataCollectionRule 'modules/monitor/data_collection_rule.bicep' = {
  name: '${logAnalyticsWorkspaceParams.workspaceName}_${deploymentParams.global_uniqueness}_Dcr'
  params: {
    deploymentParams:deploymentParams
    osKind: 'Linux'
    tags: tags

    storeEventsRuleName: 'storeEvents_Dcr'
    storeEventsLogFilePattern: '/var/log/miztiik*.json'
    storeEventscustomTableNamePrefix: r_logAnalyticsWorkspace.outputs.storeEventsCustomTableNamePrefix

    automationEventsRuleName: 'miztiikAutomation_Dcr'
    automationEventsLogFilePattern: '/var/log/miztiik-automation-*.log'
    automationEventsCustomTableNamePrefix: r_logAnalyticsWorkspace.outputs.automationEventsCustomTableNamePrefix
    
    managedRunCmdRuleName: 'miztiikManagedRunCmd_Dcr'
    managedRunCmdLogFilePattern: '/var/log/azure/run-command-handler/*.log'
    managedRunCmdCustomTableNamePrefix: r_logAnalyticsWorkspace.outputs.managedRunCmdCustomTableNamePrefix

    linDataCollectionEndpointId: r_dataCollectionEndpoint.outputs.linDataCollectionEndpointId
    logAnalyticsPayGWorkspaceName:r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceName
    logAnalyticsPayGWorkspaceId:r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId

  }
  dependsOn: [
    r_logAnalyticsWorkspace
  ]
}

// Create Virtual Machine
module r_vm 'modules/vm/create_vm.bicep' = {
  name: '${vmParams.vmNamePrefix}_${deploymentParams.global_uniqueness}_Vm'
  params: {
    deploymentParams:deploymentParams
    r_usr_mgd_identity_name: r_usr_mgd_identity.outputs.usr_mgd_identity_name

    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName
    saPrimaryEndpointsBlob: r_sa.outputs.saPrimaryEndpointsBlob

    queueName: r_storageQueue.outputs.queueName
    appConfigName: r_appConfig.outputs.appConfigName

    vmParams: vmParams
    vnetName: r_vnet.outputs.vnetName

    logAnalyticsPayGWorkspaceId:r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId

    linDataCollectionEndpointId: r_dataCollectionEndpoint.outputs.linDataCollectionEndpointId
    storeEventsDcrId: r_dataCollectionRule.outputs.storeEventsDcrId
    automationEventsDcrId: r_dataCollectionRule.outputs.automationEventsDcrId

    cosmos_db_accnt_name: r_cosmodb.outputs.cosmos_db_accnt_name

    tags: tags
  }
  dependsOn: [
    r_vnet
  ]
}

// Create Cosmos DB
module r_cosmodb 'modules/database/cosmos.bicep' ={
  name: '${cosmosDbParams.cosmosDbNamePrefix}_${deploymentParams.global_uniqueness}_cosmos_db'
  params: {
    deploymentParams:deploymentParams
    cosmosDbParams:cosmosDbParams
    appConfigName: r_appConfig.outputs.appConfigName
    tags: tags
  }
}

// Add Delay for Cosmos DB to be ready
module r_add_delay 'modules/bootstrap/add_delay.bicep'={
  name: 'deployment_delay_${deploymentParams.global_uniqueness}'
  params: {
    deploymentParams:deploymentParams
    r_usr_mgd_identity_id: r_usr_mgd_identity.outputs.usr_mgd_identity_id
    delayInSeconds: 60
    delay_multiple: 1
    tags: tags
  }
  dependsOn: [
    r_cosmodb
  ]
}

// Deploy Script on VM
module r_deploy_managed_run_cmd 'modules/bootstrap/run_command_on_vm.bicep'= {
  name: '${vmParams.vmNamePrefix}_${deploymentParams.global_uniqueness}_run_cmd'
  params: {
    deploymentParams:deploymentParams
    vmName: r_vm.outputs.vmName
    appConfigName: r_appConfig.outputs.appConfigName
    repoName: brandTags.project
    deploy_app_script: true
    tags: tags
  }
  dependsOn: [
    r_vm
  ]
}
